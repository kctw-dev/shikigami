---
name: cruise
description: "Use when starting cruise mode, automated patrol, periodic issue scanning, or background monitoring — enables PO patrol + SRE inspection loops"
requiredTools:
  - Read
  - Glob
  - Grep
  - Bash
---

# Cruise Mode Skill — PO 巡邏 + SRE 巡檢自動巡航

## 子模組索引

| 子模組 | 路徑 | 內容 |
|--------|------|------|
| PO 巡邏指引 | [references/po-patrol.md](./references/po-patrol.md) | Issue 掃描、處置決策表、Sprint 觸發、安全邊界 |
| SRE 巡檢指引 | [references/sre-inspection.md](./references/sre-inspection.md) | CI/CD 狀態、Runner 健康、VM 查證、Issue 建立 |
| Auto-shoot 派遣 | [references/auto-shoot.md](./references/auto-shoot.md) | 連續 shoot 派遣邏輯、失敗升級、log 類型 |
| Stop 機制 | [references/stop-mechanism.md](./references/stop-mechanism.md) | /cruise stop 指令、SessionEnd cleanup |
| Log 格式範例 | [references/log-format.md](./references/log-format.md) | JSONL 完整範例（單一 repo / 多 repo） |

## 觸發語法

```
/cruise              — 啟動巡航（Loop Mode，預設間隔 30 分鐘）
/cruise 10m          — 啟動巡航，指定間隔（例：10m, 15m, 60m）
/cruise strict     — 嚴格模式（0 天閾值，無回應立即標記）
/cruise 10m strict — 自訂間隔 + 嚴格模式
/cruise strict 10m — 同上（flag 位置無關）
/cruise --once       — Once Mode：跑一輪 PO+SRE 後自動退出（不進入 sleep loop）
/cruise --once strict — Once Mode + 嚴格模式
/cruise stop         — 停止巡航（Loop Mode 用）
```

### 模式說明

| 模式 | 觸發語法 | 行為 |
|------|---------|------|
| **Loop Mode**（預設） | `/cruise`、`/cruise 10m` | 長駐 loop，每隔指定間隔執行，直到 `/cruise stop` 或 Session 結束 |
| **Once Mode** | `/cruise --once` | 執行一輪 PO 巡邏 + SRE 巡檢，寫入 log，清除 flag，自動退出（不進入 sleep loop） |

**向後相容**：不帶 `--once` 的語法行為不變（Loop Mode）。

## 概覽

Cruise Mode 支援兩種執行模式：

- **Loop Mode**（`/cruise`）：在當前 Session 內持續執行 PO 巡邏與 SRE 巡檢，每隔指定間隔自動觸發一次，直到收到 `/cruise stop` 或 Session 結束為止。
- **Once Mode**（`/cruise --once`）：執行一輪 PO 巡邏與 SRE 巡檢後自動退出，不進入 sleep loop，適合搭配外部排程工具（如 cron）使用。

**參與 Agent**：PO Agent（巡邏）、SRE Agent（巡檢）
**執行模式**：Session 內 loop（sleep + flag file），參見 ADR-026
**Log**：per-session JSONL（`<LOG_BASE>/cruise-logs/YYYY-MM-DD-session-<SESSION_ID>.jsonl`）

### Multi-Repo 支援（#333）

| 模式 | 偵測條件 | 行為 |
|------|---------|------|
| **單一 repo** | 當前目錄含 `.git` | 與原行為完全相同（向後相容） |
| **多 repo** | 當前目錄不含 `.git`，但第一層子目錄有含 `.git` 的 | 對每個子 repo 分別執行 PO 巡邏 + SRE 巡檢 |

---

## 啟動流程

### 1. 解析參數

```bash
STRICT_MODE=false; ONCE_MODE=false; INTERVAL="30m"
for ARG in "$@"; do
  [[ "$ARG" == "--once" ]] && ONCE_MODE=true
  [[ "$ARG" == "strict" ]] && STRICT_MODE=true
  [[ "$ARG" =~ ^[0-9]+m$ ]] && INTERVAL="$ARG"
done
THRESHOLD_DAYS=$([[ "$STRICT_MODE" == "true" ]] && echo 0 || echo 3)
INTERVAL_SECONDS=$(echo "$INTERVAL" | sed 's/m$//' | awk '{print $1 * 60}')
```

### 2. 偵測 Repo 列表（AC-1 / AC-2）

```bash
REPOS=(); MULTI_REPO=false
if [[ -d ".git" ]]; then
  REPOS+=("$(pwd)")
else
  for dir in */; do
    [[ -d "${dir}.git" ]] && REPOS+=("$(realpath "$dir")")
  done
  [[ ${#REPOS[@]} -gt 0 ]] && MULTI_REPO=true
fi
[[ ${#REPOS[@]} -eq 0 ]] && { echo "[CRUISE] 錯誤：無可巡 repo"; exit 1; }

declare -A REPO_REMOTES
for REPO_PATH in "${REPOS[@]}"; do
  REMOTE_URL=$(git -C "$REPO_PATH" remote get-url origin 2>/dev/null || echo "")
  if [[ -n "$REMOTE_URL" ]]; then
    OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's#^(https?://[^/]+/|git@[^:]+:)##; s#\.git$##')
    REPO_REMOTES["$REPO_PATH"]="$OWNER_REPO"
  else
    REPO_REMOTES["$REPO_PATH"]="local:$(basename "$REPO_PATH")"
  fi
done
```

### 2.5 驗證 Repo Remote（排除無效 repo）

```bash
VALID_REPOS=()
for REPO_PATH in "${REPOS[@]}"; do
  OWNER_REPO="${REPO_REMOTES[$REPO_PATH]}"
  if [[ "$OWNER_REPO" == local:* ]] || [[ ! "$OWNER_REPO" =~ ^[^/]+/[^/]+$ ]]; then
    echo "[CRUISE] WARNING: ${REPO_PATH} 無有效 GitHub remote，跳過"
  else
    VALID_REPOS+=("$REPO_PATH")
  fi
done
REPOS=("${VALID_REPOS[@]}")
[[ ${#REPOS[@]} -eq 0 ]] && { echo "[CRUISE] 錯誤：所有 repo 均無有效 GitHub remote"; exit 1; }
```

### 3. 列出偵測結果（AC-7）

```bash
echo "[CRUISE] 偵測到 ${#REPOS[@]} 個有效 repo："
for REPO_PATH in "${REPOS[@]}"; do
  echo "  - ${REPO_REMOTES[$REPO_PATH]} (${REPO_PATH})"
done
```

### 4. 建立 Flag File（SSOT — #449 AC4）

```bash
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
CRUISE_FLAG="/tmp/shikigami-cruise-${SESSION_ID}.active"
SHOOT_FLAG="/tmp/shikigami-cruise-shoot-${SESSION_ID}.active"
touch "$CRUISE_FLAG"
echo "[CRUISE] Loop Mode 啟動（Session: ${SESSION_ID}，間隔: ${INTERVAL}）"
echo "[CRUISE] 停止指令：/cruise stop"
```

### 4.2 建立 Sprint Stories Task List（#513）

為當前 Sprint 中每個 Story 建立一個 Task，追蹤其在 Cruise 期間的進度。

```
# 查詢當前 Sprint 的 Stories
SPRINT_STORIES=$(gh issue list -R ${OWNER_REPO} --label "status: in-sprint" --json number,title)

# 每個 Story 建立一個 Task（task 數量上限：取決於 Claude Task 工具上限，通常 50 個）
for STORY in SPRINT_STORIES:
  TaskCreate subject="Story #${STORY.number}: ${STORY.title}" status="pending"

# 若無 Story，建立一個 placeholder Task 避免 TaskList 為空
if SPRINT_STORIES is empty:
  TaskCreate subject="cruise-session-${SESSION_ID}" status="in-progress"
```

**Task 狀態對應**：

| Story 狀態 | Task status |
|-----------|-------------|
| 等待派工 | `pending` |
| auto-shoot 進行中 | `in-progress` |
| shoot 成功完成 | `completed` |
| shoot 失敗升級 | `failed` |

**compact 後恢復**：查詢 TaskList，找出所有 `in-progress` 或 `pending` 的 Story Task，從中繼續執行。

```
# compact 恢復邏輯
PENDING_STORIES=$(TaskList | filter status in ["pending", "in-progress"])
ACTIONABLE_ISSUES = PENDING_STORIES.map(task => extract story_number from task.subject)
```

**Cruise phase 追蹤改用 JSONL log entries**（不佔用 TaskCreate）：

| 事件 | JSONL log entry type |
|------|----------------------|
| cruise 初始化 | `"cruise-init"` |
| PO 巡邏開始 | `"po-patrol-start"` |
| PO 巡邏完成 | `"po-patrol-complete"` |
| SRE 巡檢開始 | `"sre-inspection-start"` |
| SRE 巡檢完成 | `"sre-inspection-complete"` |
| auto-shoot 開始 | `"auto-shoot-start"` |
| cruise 清理完成 | `"cruise-cleanup"` |

### 4.5 讀取 project_level（#348）

```bash
CONFIG_FILE=".claude/shikigami.local.md"
PROJECT_LEVEL=$(grep -A5 'shikigami:' "$CONFIG_FILE" 2>/dev/null | grep 'project_level:' | awk '{print $2}' | head -1)
PROJECT_LEVEL="${PROJECT_LEVEL:-medium}"
```

<HARD-GATE>
project_level=low 的所有自動行為（auto-shoot、auto-close、auto-sprint-planning、auto-sprint-execution）為強制執行，Agent 禁止加入額外確認步驟。
</HARD-GATE>

| 行為 | low | medium（預設） | high |
|------|-----|---------------|------|
| auto-shoot | 自動派遣 invoke shikigami:shoot | 自動派遣 | 只標記，等人確認 |
| Sprint Planning | 自動 invoke shikigami:sprint-planning | 留言通知等確認 | 只標記 sprint-candidate |
| Issue close | 自動 close | 自動 close | 留言建議，等人確認 |

### 4.6 讀取 close_policy 與 delivery_chain（#338）

```bash
CONFIG_FILE=".claude/shikigami.local.md"
REQUIRE_CREATOR_APPROVAL="false"; CLOSE_DEFAULT_TIMEOUT="2h"
DELIVERY_CHAIN_DEFAULT="production"
# 若 CONFIG_FILE 存在，從中讀取 require_creator_approval / default_timeout / delivery_chain.default
# get_delivery_chain() / get_close_timeout() 函式：讀 per-repo 覆蓋值，fallback 至 DEFAULT
```

### 5. 準備 Log 目錄

```bash
LOG_BASE=$([[ "$MULTI_REPO" == "true" ]] && echo "$(pwd)" || echo "${REPOS[0]}")
LOG_DIR="${LOG_BASE}/cruise-logs"
mkdir -p "$LOG_DIR"
CRUISE_LOG="${LOG_DIR}/$(date '+%Y-%m-%d')-session-${SESSION_ID}.jsonl"
CYCLE=0
```

### 6. 選擇執行模式

- **Once Mode**（`--once`）：呼叫 `_cruise_run_once`，完成後清除 flag 並 `exit 0`
- **Loop Mode**（預設）：進入 while loop（見 6b）

### 6a. Once Mode 執行流程（`/cruise --once`）

```
CYCLE=1
寫入 {"type":"cruise-init",...} log entry
for REPO_PATH in REPOS:
  平行派遣 PO-patrol + SRE-inspection（帶入 REPO_PATH, OWNER_REPO）
等待完成，寫入 JSONL log（格式見 references/log-format.md）
寫入 {"type":"po-patrol-complete",...} / {"type":"sre-inspection-complete",...} log entry

# [AUTO-CONTINUE] project_level=low → 自動派 auto-shoot，不停
if PROJECT_LEVEL != "high": auto-shoot ACTIONABLE_ISSUES（見 references/auto-shoot.md）
寫入 {"type":"once-mode-complete",...} log entry
寫入 {"type":"cruise-cleanup",...} log entry
rm -f "$CRUISE_FLAG" "$SHOOT_FLAG"; exit 0
```

**`[AUTO-CONTINUE]` Phase 轉換點**（AC5）：

| Phase 轉換點 | 說明 |
|------------|------|
| 啟動 → 執行巡邏 | `project_level=low` 時自動執行，不詢問 |
| 巡邏完成 → auto-shoot | `project_level=low` 時自動派工，不停 |
| auto-shoot → 退出 | 所有 actionable 處理完後自動退出 |

### 6b. Loop Mode

```
寫入 {"type":"cruise-init",...} log entry
while 檢查 flag file 存在:
  CYCLE += 1; touch "$CRUISE_FLAG"
  寫入 {"type":"po-patrol-start",...} / {"type":"sre-inspection-start",...} log entry
  for REPO_PATH in REPOS:
    平行派遣 PO-patrol（詳見 references/po-patrol.md）+ SRE-inspection（詳見 references/sre-inspection.md）
  等待完成，寫入 log
  寫入 {"type":"po-patrol-complete",...} / {"type":"sre-inspection-complete",...} log entry

  # SHOOT_FLAG 殘留防護：>30 分鐘強制清除，寫 auto-shoot-stale-cleared log
  # Auto-shoot（依 project_level）— 詳見 references/auto-shoot.md
  # Sprint Planning 觸發已移至 PO 巡邏直接執行（#352）

  sleep ${INTERVAL_SECONDS}
  if flag file 不存在: break
echo "[CRUISE] 巡航模式已停止"
```

**subagent 派遣約定**：
- 每個 subagent 帶入 `REPO_PATH`（絕對路徑）與 `OWNER_REPO`（`owner/repo`）
- 所有 `gh` 指令加 `-R ${OWNER_REPO}`
- subagent **不自行寫入 log**（DM-4：log 由主 loop 統一寫入）

---

## Stop 機制

詳見 [references/stop-mechanism.md](./references/stop-mechanism.md)。

- `/cruise stop`：刪除 `$CRUISE_FLAG`（+ `$SHOOT_FLAG`），loop 在當前 cycle 完成後退出
- SessionEnd Hook：`hooks/session-end-release.sh` 自動清除兩個 flag file

---

## 跨機器考量（AC-5）

- **per-session Log 隔離**：每個 Session 寫入自己的 JSONL（`cruise-logs/YYYY-MM-DD-session-<ID>.jsonl`），避免 git conflict
- **多 repo 模式**：Log 統一寫入 group 目錄，不寫入各子 repo
- **Issue 重複防護**：SRE 建立 Issue 前先 `gh issue list --search`，冪等性覆蓋所有 Issue 類型
- **多 Session 同時 Cruise**：Flag file 以 SESSION_ID 命名，互不干擾

---

## Log 格式

Log JSONL 存放於 `<LOG_BASE>/cruise-logs/YYYY-MM-DD-session-<SESSION_ID>.jsonl`。

完整格式範例與 log entry 類型定義詳見 [references/log-format.md](./references/log-format.md)。
