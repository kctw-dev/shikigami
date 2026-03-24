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
| PO 巡邏指引 | [po-patrol.md](./po-patrol.md) | Issue 掃描、處置決策表、Sprint 觸發、安全邊界 |
| SRE 巡檢指引 | [sre-inspection.md](./sre-inspection.md) | CI/CD 狀態、Runner 健康、VM 查證、Issue 建立 |
| Auto-shoot 派遣 | [auto-shoot.md](./auto-shoot.md) | 連續 shoot 派遣邏輯、失敗升級、log 類型 |

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

Cruise 支援兩種模式，啟動時自動偵測：

| 模式 | 偵測條件 | 行為 |
|------|---------|------|
| **單一 repo** | 當前目錄含 `.git` | 與原行為完全相同（向後相容） |
| **多 repo** | 當前目錄不含 `.git`，但第一層子目錄有含 `.git` 的 | 對每個子 repo 分別執行 PO 巡邏 + SRE 巡檢 |

多 repo 模式的典型目錄結構：

```
~/workspace/group-a/      ← cd 到這層，執行 /cruise
├── shikigami/            ← 自動偵測（有 .git）
├── project-x/            ← 自動偵測（有 .git）
└── project-y/            ← 自動偵測（有 .git）
```

---

## 啟動流程

### 1. 解析參數

```bash
# 解析 --once flag、strict flag 與間隔（位置無關）
STRICT_MODE=false
ONCE_MODE=false
INTERVAL="30m"
for ARG in "$@"; do
  if [[ "$ARG" == "--once" ]]; then
    ONCE_MODE=true
  elif [[ "$ARG" == "strict" ]]; then
    STRICT_MODE=true
  elif [[ "$ARG" =~ ^[0-9]+m$ ]]; then
    INTERVAL="$ARG"
  fi
done

# 設定閾值（THRESHOLD_DAYS）
if [[ "$STRICT_MODE" == "true" ]]; then
  THRESHOLD_DAYS=0
else
  THRESHOLD_DAYS=3
fi

# 轉換間隔為秒數（Loop Mode 用）
INTERVAL_SECONDS=$(echo "$INTERVAL" | sed 's/m$//' | awk '{print $1 * 60}')

# 輸出模式提示
if [[ "$ONCE_MODE" == "true" ]]; then
  echo "[CRUISE] Once Mode 啟動（--once）：執行一輪後退出"
else
  echo "[CRUISE] Loop Mode 啟動：間隔 ${INTERVAL}"
fi
```

### 2. 偵測 Repo 列表（AC-1 / AC-2）

```bash
REPOS=()
MULTI_REPO=false

if [[ -d ".git" ]]; then
  # 當前目錄本身是 repo → 單一 repo 模式（向後相容）
  REPOS+=("$(pwd)")
else
  # 掃描第一層子目錄（maxdepth 1）
  for dir in */; do
    if [[ -d "${dir}.git" ]]; then
      REPOS+=("$(realpath "$dir")")
    fi
  done
  if [[ ${#REPOS[@]} -gt 0 ]]; then
    MULTI_REPO=true
  fi
fi

# 無 repo 可巡 → 終止
if [[ ${#REPOS[@]} -eq 0 ]]; then
  echo "[CRUISE] 錯誤：當前目錄無 .git，子目錄也無 repo，無法啟動巡航"
  exit 1
fi

# 推導各 repo 的 owner/repo 字串（AC-4）
declare -A REPO_REMOTES
for REPO_PATH in "${REPOS[@]}"; do
  REMOTE_URL=$(git -C "$REPO_PATH" remote get-url origin 2>/dev/null || echo "")
  if [[ -n "$REMOTE_URL" ]]; then
    # 支援 SSH (git@github.com:owner/repo.git) 與 HTTPS (https://github.com/owner/repo.git)
    OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's#^(https?://[^/]+/|git@[^:]+:)##; s#\.git$##')
    REPO_REMOTES["$REPO_PATH"]="$OWNER_REPO"
  else
    REPO_REMOTES["$REPO_PATH"]="local:$(basename "$REPO_PATH")"
  fi
done
```

### 2.5 驗證 Repo Remote（排除無效 repo）

```bash
# 驗證 OWNER_REPO 格式為 owner/repo，排除無效 repo
VALID_REPOS=()
for REPO_PATH in "${REPOS[@]}"; do
  OWNER_REPO="${REPO_REMOTES[$REPO_PATH]}"
  if [[ "$OWNER_REPO" == local:* ]]; then
    echo "[CRUISE] WARNING: ${REPO_PATH} 無 GitHub remote，跳過（gh 指令需要 owner/repo 格式）"
  elif [[ ! "$OWNER_REPO" =~ ^[^/]+/[^/]+$ ]]; then
    echo "[CRUISE] WARNING: ${REPO_PATH} remote URL 解析失敗（${OWNER_REPO}），跳過"
  else
    VALID_REPOS+=("$REPO_PATH")
  fi
done
REPOS=("${VALID_REPOS[@]}")

# 驗證後無有效 repo → 終止
if [[ ${#REPOS[@]} -eq 0 ]]; then
  echo "[CRUISE] 錯誤：所有偵測到的 repo 均無有效 GitHub remote，無法啟動巡航"
  exit 1
fi
```

### 3. 列出偵測結果（AC-7）

```bash
echo "[CRUISE] 偵測到 ${#REPOS[@]} 個有效 repo："
for REPO_PATH in "${REPOS[@]}"; do
  echo "  - ${REPO_REMOTES[$REPO_PATH]} (${REPO_PATH})"
done
if [[ "$MULTI_REPO" == "true" ]]; then
  echo "[CRUISE] 多 repo 模式：Log 統一寫入 $(pwd)/cruise-logs/"
fi
```

### 4. 建立 Flag File

```bash
# ── Flag 路徑常數（SSOT — 唯一定義處，#449 AC4）────────────────────
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
CRUISE_FLAG="/tmp/shikigami-cruise-${SESSION_ID}.active"
SHOOT_FLAG="/tmp/shikigami-cruise-shoot-${SESSION_ID}.active"  # Auto-shoot 併發控制
touch "$CRUISE_FLAG"
echo "[CRUISE] 巡航模式已啟動（Session: ${SESSION_ID}，間隔: ${INTERVAL}）"
echo "[CRUISE] Flag file: $CRUISE_FLAG"
echo "[CRUISE] 停止指令：/cruise stop"
```

### 4.2 建立 Task List（#469）

<!-- #469 Cruise/Sprint 執行時建立 Task List — 防止 compact 後跳步 -->

Cruise 啟動後立即建立 Task List，記錄本次巡航的所有 phase。compact 後可透過 TaskList 查詢恢復進度，跳過已完成的 phase，防止跳步或重複執行。

```
# 建立 Cruise Task List（多 session 隔離：以 SESSION_ID 命名）
TASK_LIST_ID="cruise-${SESSION_ID}"

TaskCreate 以下 tasks（依執行順序）：
  1. "cruise-init-${SESSION_ID}"        — 初始化（參數解析、repo 偵測、flag file）
  2. "po-patrol-${SESSION_ID}"          — PO 巡邏（每個 cycle 更新）
  3. "sre-inspection-${SESSION_ID}"     — SRE 巡檢（每個 cycle 更新）
  4. "auto-shoot-${SESSION_ID}"         — Auto-shoot 派遣（有 actionable issue 時）
  5. "cruise-cleanup-${SESSION_ID}"     — 清理（flag 清除、退出）

# 恢復進度：compact 後重啟時先查詢 TaskList（#469 AC4）
# 若 task 狀態為 completed → 跳過
# 若 task 狀態為 failed    → 從該 task 重試
# 若 task 狀態為 pending   → 正常執行
EXISTING_TASKS=$(TaskList --filter "cruise-${SESSION_ID}")
if [[ -n "$EXISTING_TASKS" ]]; then
  echo "[CRUISE] 偵測到既有 Task List，恢復進度（compact 後重啟）"
  # 讀取各 phase 狀態，跳過已完成的 phase
fi
```

**Task 狀態轉換規則**（#469 AC2 / AC6）：

| 事件 | TaskUpdate 動作 |
|------|----------------|
| phase 開始執行 | `TaskUpdate id="<task_id>" status=in-progress` |
| phase 成功完成 | `TaskUpdate id="<task_id>" status=completed` |
| phase 執行失敗 | `TaskUpdate id="<task_id>" status=failed` |
| compact 後重啟 | 查詢 TaskList，從第一個非 completed 的 task 繼續 |

**多 session 隔離**（#469 AC5）：

- Task List 名稱含 SESSION_ID（`cruise-${SESSION_ID}`），每個 session 獨立，互不干擾
- 不同 session 的 Task List 不會互相覆蓋或干擾

---

### 4.5 讀取 project_level（#348）

```bash
# 讀取 .claude/shikigami.local.md 的 YAML frontmatter
CONFIG_FILE=".claude/shikigami.local.md"
if [[ -f "$CONFIG_FILE" ]]; then
  # 從 YAML frontmatter 提取 project_level（支援 shikigami.project_level 或頂層 project_level）
  PROJECT_LEVEL=$(grep -A5 'shikigami:' "$CONFIG_FILE" | grep 'project_level:' | awk '{print $2}' | head -1)
  if [[ -z "$PROJECT_LEVEL" ]]; then
    PROJECT_LEVEL="medium"  # AC-4：YAML 存在但無 project_level → fallback medium
  fi
else
  PROJECT_LEVEL="medium"  # AC-4：無設定檔 → fallback medium
fi
echo "[CRUISE] project_level: ${PROJECT_LEVEL}"
```

**project_level 行為矩陣**（#348 AC-2 / AC-3）：

| 行為 | low | medium（預設） | high |
|------|-----|---------------|------|
| auto-shoot | 自動派遣 invoke shikigami:shoot，事後通知 | 自動派遣 | 只標記 actionable，PO 留言等人確認 |
| Sprint Planning | sprint-candidate 達標 → 自動 invoke shikigami:sprint-planning | 達標 → PO 留言通知，等使用者確認再觸發 | 只標記 sprint-candidate，不觸發 |
| Issue close | 自動 close | 自動 close | PO 留言建議 close，等人確認 |
| CI/CD 變更 | 自動走 shoot 流程 | 自動走 shoot 流程 | PO 留言通知，必須人工確認 |

### 4.6 讀取 close_policy 與 delivery_chain（#338）

```bash
# 讀取 close_policy（向下相容：無設定 → 預設行為）
CONFIG_FILE=".claude/shikigami.local.md"
REQUIRE_CREATOR_APPROVAL="false"        # 預設：直接 close（現有行為）
CLOSE_DEFAULT_TIMEOUT="2h"             # 預設 timeout

if [[ -f "$CONFIG_FILE" ]]; then
  # 讀取 require_creator_approval
  _VAL=$(grep 'require_creator_approval:' "$CONFIG_FILE" | awk '{print $2}' | head -1)
  if [[ -n "$_VAL" ]]; then
    REQUIRE_CREATOR_APPROVAL="$_VAL"
  fi
  # 讀取 default_timeout
  _TIMEOUT=$(grep 'default_timeout:' "$CONFIG_FILE" | awk '{print $2}' | head -1)
  if [[ -n "$_TIMEOUT" ]]; then
    CLOSE_DEFAULT_TIMEOUT="$_TIMEOUT"
  fi
fi
echo "[CRUISE] close_policy.require_creator_approval: ${REQUIRE_CREATOR_APPROVAL}（timeout: ${CLOSE_DEFAULT_TIMEOUT}）"

# 讀取 delivery_chain（向下相容：無設定 → production 完整鏈）
DELIVERY_CHAIN_DEFAULT="production"     # 預設：完整交付鏈

if [[ -f "$CONFIG_FILE" ]]; then
  _DC_DEFAULT=$(grep -A2 'delivery_chain:' "$CONFIG_FILE" | grep 'default:' | awk '{print $2}' | head -1)
  if [[ -n "$_DC_DEFAULT" ]]; then
    DELIVERY_CHAIN_DEFAULT="$_DC_DEFAULT"
  fi
fi
echo "[CRUISE] delivery_chain.default: ${DELIVERY_CHAIN_DEFAULT}"

# 讀取 per-repo delivery_chain 覆蓋（在每個 repo 的 loop 內使用）
# 函式：取得指定 repo 的 delivery_chain 設定
get_delivery_chain() {
  local OWNER_REPO="$1"
  local REPO_OVERRIDE
  if [[ -f "$CONFIG_FILE" ]]; then
    # 限定搜尋 delivery_chain: 區段（避免 match 到 close_policy.per_repo）
    REPO_OVERRIDE=$(awk '/delivery_chain:/,/^[^ ]/' "$CONFIG_FILE" \
      | grep "^    ${OWNER_REPO}:" | awk '{print $2}' | head -1)
  fi
  echo "${REPO_OVERRIDE:-$DELIVERY_CHAIN_DEFAULT}"
}

# 讀取 per-repo close_policy timeout 覆蓋
get_close_timeout() {
  local OWNER_REPO="$1"
  local REPO_TIMEOUT
  if [[ -f "$CONFIG_FILE" ]]; then
    # 讀取 close_policy.per_repo 區段
    REPO_TIMEOUT=$(awk '/close_policy:/,/delivery_chain:|^[^ ]/' "$CONFIG_FILE" \
      | grep "^    ${OWNER_REPO}:" | awk '{print $2}' | head -1)
  fi
  echo "${REPO_TIMEOUT:-$CLOSE_DEFAULT_TIMEOUT}"
}
```

### 5. 準備 Log 目錄

```bash
# LOG_BASE：單一 repo 模式用 repo 內路徑；多 repo 模式用 group 目錄（SSOT，僅此處定義一次）
if [[ "$MULTI_REPO" == "true" ]]; then
  LOG_BASE="$(pwd)"
else
  LOG_BASE="${REPOS[0]}"
fi
LOG_DIR="${LOG_BASE}/cruise-logs"
mkdir -p "$LOG_DIR"
LOG_TODAY=$(date '+%Y-%m-%d')
CRUISE_LOG="${LOG_DIR}/${LOG_TODAY}-session-${SESSION_ID}.jsonl"
CYCLE=0
```

### 6. 選擇執行模式

根據 `ONCE_MODE` flag 決定進入 Loop Mode 或 Once Mode：

```bash
if [[ "$ONCE_MODE" == "true" ]]; then
  # ── Once Mode：執行一輪後退出（AC1：不進入 sleep loop）──
  # [AUTO-CONTINUE] project_level=low 時，phase 自動推進，不停下來等確認
  _cruise_run_once  # 執行單輪邏輯（見下方 Once Mode 段落）
  # ── Once Mode 清除 flag 並退出（AC1）──
  rm -f "$CRUISE_FLAG"
  rm -f "$SHOOT_FLAG" 2>/dev/null || true
  echo "[CRUISE] Once Mode 完成，flag 已清除，退出"
  exit 0
fi
# Loop Mode：繼續進入下方 while loop
```

### 6a. Once Mode 執行流程（`/cruise --once`）

Once Mode 執行單輪 PO 巡邏 + SRE 巡檢，寫入 log 後自動退出，不進入 sleep loop。

**觸發條件**：`--once` flag 存在。

**執行步驟**：

```
# [AUTO-CONTINUE] 以下各步驟在 project_level=low 時自動執行，不停下來詢問
CYCLE=1

# ── Task List 狀態更新：cruise-init 完成（#469 AC2）──
TaskUpdate id="cruise-init-${SESSION_ID}" status=completed
# ── Task List 狀態更新：po-patrol / sre-inspection 開始（#469 AC2）──
TaskUpdate id="po-patrol-${SESSION_ID}" status=in-progress
TaskUpdate id="sre-inspection-${SESSION_ID}" status=in-progress

for REPO_PATH in REPOS:
  OWNER_REPO = REPO_REMOTES[REPO_PATH]
  平行派遣：
    - PO-patrol（帶入 REPO_PATH, OWNER_REPO, STRICT_MODE, THRESHOLD_DAYS）
    - SRE-inspection（帶入 REPO_PATH, OWNER_REPO）
等待所有 task 完成

for each subagent result:
  if subagent 成功:
    寫入正常 log entry（JSONL append，含 "repo" 欄位）
    # log entry 格式與 Loop Mode 一致（AC4：格式統一）
    # ── Task List 狀態更新：phase 完成（#469 AC2）──
    TaskUpdate id="po-patrol-${SESSION_ID}" status=completed
    TaskUpdate id="sre-inspection-${SESSION_ID}" status=completed
  else:
    寫入錯誤 log entry：
      {"type":"error","repo":"<OWNER_REPO>","cycle":1,"timestamp":"<ISO8601>","summary":"subagent failed: <reason>","mode":"once"}
    echo "[CRUISE] WARNING: ${OWNER_REPO} 巡邏/巡檢失敗，見 log"
    # ── Task List 狀態更新：phase 失敗（#469 AC6）──
    TaskUpdate id="po-patrol-${SESSION_ID}" status=failed
    TaskUpdate id="sre-inspection-${SESSION_ID}" status=failed

# ── Auto-shoot（與 Loop Mode 相同，依 project_level 控制）──
# [AUTO-CONTINUE] project_level=low → 自動派 auto-shoot，不停
ACTIONABLE_ISSUES = PO 巡邏結果.actionable_issues
if PROJECT_LEVEL != "high":
  # ── Task List 狀態更新：auto-shoot 開始（#469 AC2）──
  TaskUpdate id="auto-shoot-${SESSION_ID}" status=in-progress
  while ACTIONABLE_ISSUES is not empty:
    ISSUE = ACTIONABLE_ISSUES.shift()
    echo "$ISSUE" > SHOOT_FLAG
    invoke shikigami:shoot with args=#${ISSUE}
    if shoot 成功:
      rm -f SHOOT_FLAG
      寫入 log：{"type":"auto-shoot-completed","issue":ISSUE,"result":"success","mode":"once",...}
    else:
      rm -f SHOOT_FLAG
      寫入 log：{"type":"auto-shoot-completed","issue":ISSUE,"result":"failed","mode":"once",...}
  # ── Task List 狀態更新：auto-shoot 完成（#469 AC2）──
  TaskUpdate id="auto-shoot-${SESSION_ID}" status=completed

# ── Once Mode 完成 log entry ──
寫入 log：{"type":"once-mode-complete","timestamp":"<ISO8601>","session_id":"<SESSION_ID>","repos":[<OWNER_REPO>,...]}
echo "[CRUISE] Once Mode 執行完成，寫入 log：${CRUISE_LOG}"

# ── Task List 狀態更新：cruise-cleanup 完成（#469 AC2）──
TaskUpdate id="cruise-cleanup-${SESSION_ID}" status=completed

# ── 清除 flag 並退出（AC1：不進入 sleep loop）──
rm -f "$CRUISE_FLAG"
rm -f "$SHOOT_FLAG" 2>/dev/null || true
echo "[CRUISE] Once Mode 完成，flag 已清除，自動退出"
exit 0
```

**Once Mode Log 格式**（AC4：與 Loop Mode 格式一致）：

```jsonl
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-23T10:30:00+0800","type":"po-patrol","repo":"KCTW/shikigami","strict":false,"threshold_days":3,"mode":"once","summary":"掃描 15 個 open issues，處置完畢","actions":[...],"actionable_issues":[...],"sprint_candidates":[...]}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-23T10:30:05+0800","type":"sre-inspection","repo":"KCTW/shikigami","mode":"once","summary":"檢查 10 筆 CI run，無異常","actions":[]}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-23T10:30:10+0800","type":"once-mode-complete","session_id":"abc123","repos":["KCTW/shikigami"]}
```

**`[AUTO-CONTINUE]` 提醒機制**（AC5）：

Once Mode 各 phase 轉換點均加入 `[AUTO-CONTINUE]` 備注，指示 `project_level=low` 時自動推進，不停下來等確認：

| Phase 轉換點 | `[AUTO-CONTINUE]` 說明 |
|------------|----------------------|
| 啟動 → 執行巡邏 | `project_level=low` 時自動執行，不詢問 |
| 巡邏完成 → auto-shoot | `project_level=low` 時自動派工，不停 |
| auto-shoot → 退出 | 所有 actionable 處理完後自動退出 |

---

### 6b. 進入 Loop（Loop Mode）

每個 cycle 對**每個 repo** 分別執行 PO 巡邏 + SRE 巡檢（平行派遣），完成後由主 loop 彙整寫 log，然後 sleep。

```
# [AUTO-CONTINUE] project_level=low 時 cycle 間自動推進，不停
# ── Task List 狀態更新：cruise-init 完成（#469 AC2）──
TaskUpdate id="cruise-init-${SESSION_ID}" status=completed

while 檢查 flag file 存在:
  CYCLE += 1
  # #449 AC1：每個 cycle 開始時 touch flag file，重置 mtime，避免 systemd-tmpfiles-clean 清除
  touch "$CRUISE_FLAG"
  if [[ -f "$SHOOT_FLAG" ]]; then touch "$SHOOT_FLAG"; fi

  # ── Task List 狀態更新：po-patrol / sre-inspection 開始（#469 AC2）──
  TaskUpdate id="po-patrol-${SESSION_ID}" status=in-progress
  TaskUpdate id="sre-inspection-${SESSION_ID}" status=in-progress

  for REPO_PATH in REPOS:
    OWNER_REPO = REPO_REMOTES[REPO_PATH]
    平行派遣：
      - PO-patrol（帶入 REPO_PATH, OWNER_REPO, STRICT_MODE, THRESHOLD_DAYS）— 詳見 po-patrol.md
      - SRE-inspection（帶入 REPO_PATH, OWNER_REPO）— 詳見 sre-inspection.md
  等待所有 task 完成
  for each subagent result:
    if subagent 成功:
      寫入正常 log entry（JSONL append，含 "repo" 欄位）
      # ── Task List 狀態更新：phase 完成（#469 AC2）──
      TaskUpdate id="po-patrol-${SESSION_ID}" status=completed
      TaskUpdate id="sre-inspection-${SESSION_ID}" status=completed
    else:
      寫入錯誤 log entry：
        {"type":"error","repo":"<OWNER_REPO>","cycle":<N>,"timestamp":"<ISO8601>","summary":"subagent failed: <reason>"}
      echo "[CRUISE] WARNING: ${OWNER_REPO} 巡邏/巡檢失敗，見 log"
      # ── Task List 狀態更新：phase 失敗（#469 AC6）──
      TaskUpdate id="po-patrol-${SESSION_ID}" status=failed
      TaskUpdate id="sre-inspection-${SESSION_ID}" status=failed

  # ── SHOOT_FLAG 殘留防護 ──────────────────────
  if SHOOT_FLAG 存在:
    SHOOT_FLAG_AGE = (now - SHOOT_FLAG mtime) in minutes
    if SHOOT_FLAG_AGE > 30:
      echo "[CRUISE] SHOOT_FLAG 殘留超過 30 分鐘，強制清除"
      rm -f SHOOT_FLAG
      寫入 log entry：
        {"type":"auto-shoot-stale-cleared","repo":"<OWNER_REPO>","cycle":<N>,"timestamp":"<ISO8601>"}

  # ── Auto-shoot 連續派遣（#343 AC-2，#348 project_level 控制）— 詳見 auto-shoot.md ──
  # PO 回傳 actionable_issues，主 loop 依 project_level 決定行為
  ACTIONABLE_ISSUES = PO 巡邏結果.actionable_issues
  if PROJECT_LEVEL == "high":
    # high：只標記，PO 留言等人確認，不自動派 shoot
    for ISSUE in ACTIONABLE_ISSUES:
      echo "[CRUISE] project_level=high，#${ISSUE} 標記為 actionable 但不自動派工，等人確認"
      寫入 log：{"type":"auto-shoot-pending-approval","issue":ISSUE,"project_level":"high",...}
  else:
    # low / medium：自動派遣 invoke shikigami:shoot
    while ACTIONABLE_ISSUES is not empty AND CRUISE_FLAG 存在:
      if SHOOT_FLAG 不存在:
        ISSUE = ACTIONABLE_ISSUES.shift()
        echo "$ISSUE" > SHOOT_FLAG
        echo "[CRUISE] Auto-shoot 派遣：#${ISSUE}（project_level=${PROJECT_LEVEL}）"
        invoke shikigami:shoot with args=#${ISSUE}  # 完整 shoot 流程（#346）
      if shoot 成功:
        rm -f SHOOT_FLAG
        SHOOT_FAIL_COUNT[ISSUE] = 0
        寫入 log：{"type":"auto-shoot-completed","issue":ISSUE,"result":"success",...}
      else:
        rm -f SHOOT_FLAG
        SHOOT_FAIL_COUNT[ISSUE] += 1
        if SHOOT_FAIL_COUNT[ISSUE] >= 2:  # AC-5：連續 2 次 fail → 升級
          gh issue edit ISSUE -R ${OWNER_REPO} --add-label sprint-candidate
          寫入 log：{"type":"auto-shoot-escalated","issue":ISSUE,"reason":"2 consecutive failures",...}
          echo "[CRUISE] #${ISSUE} 連續 2 次 shoot fail，升級為 sprint-candidate"
        else:
          寫入 log：{"type":"auto-shoot-completed","issue":ISSUE,"result":"failed",...}
      # 立即繼續下一個（不 sleep）

  # ── Sprint Planning 觸發已移至 PO 巡邏直接執行（#352）──
  # PO Agent 在巡邏結束時自己檢查 sprint-candidate count + project_level，
  # 直接 invoke shikigami:sprint-planning（low）或留言通知（medium）。
  # 主 loop 不再負責 Sprint Planning 觸發，避免被跳過。

  echo "[CRUISE] Cycle ${CYCLE} 完成（${#REPOS[@]} repos），下次執行：${INTERVAL} 後"
  sleep ${INTERVAL_SECONDS}
  if flag file 不存在: break
echo "[CRUISE] 巡航模式已停止"
```

**subagent 派遣約定**（AC-3 / AC-4）：

- 每個 subagent prompt 帶入 `REPO_PATH`（絕對路徑）與 `OWNER_REPO`（`owner/repo` 字串）
- PO 巡邏的 `gh` 指令加 `-R ${OWNER_REPO}`（如 `gh issue list -R ${OWNER_REPO}`）
- SRE 巡檢的 `gh` 指令同理（如 `gh run list -R ${OWNER_REPO}`）
- 交付追蹤用 `${REPO_PATH}/docs/sprints/` 絕對路徑讀取 Sprint file（AC-5）
- subagent 回傳結果，**不自行寫入 log**（DM-4：log 由主 loop 統一寫入）

---

## Stop 機制

### /cruise stop 指令

```bash
# Flag 路徑沿用啟動階段 SSOT 定義（Section 4，#449 AC4）
# CRUISE_FLAG="/tmp/shikigami-cruise-${SESSION_ID}.active"
# SHOOT_FLAG="/tmp/shikigami-cruise-shoot-${SESSION_ID}.active"

if [[ -f "$CRUISE_FLAG" ]]; then
  rm -f "$CRUISE_FLAG"
  rm -f "$SHOOT_FLAG" 2>/dev/null || true  # 同步清除 auto-shoot flag
  echo "[CRUISE] 巡航模式停止指令已送出，loop 將在當前 cycle 完成後退出"
else
  echo "[CRUISE] 巡航模式未啟動（flag file 不存在）"
fi
```

### SessionEnd Hook 自動清理

`hooks/session-end-release.sh` 在 Session 結束時自動清除 cruise flag file 與 shoot flag file，確保無殘留：

```bash
# Flag 路徑與啟動階段 SSOT 一致（Section 4，#449 AC4）
# CRUISE_FLAG="/tmp/shikigami-cruise-${SESSION_ID}.active"
# SHOOT_FLAG="/tmp/shikigami-cruise-shoot-${SESSION_ID}.active"
rm -f "$CRUISE_FLAG" 2>/dev/null || true
rm -f "$SHOOT_FLAG" 2>/dev/null || true  # 清除 auto-shoot flag（殘留防護）
echo "[CRUISE] SessionEnd cleanup: cruise + shoot flag files 已清除"
```

---

## 跨機器考量（AC-5）

### per-session Log 隔離

每個 Session 寫入自己的 JSONL 檔案，避免多 session 同時 append 造成 git conflict：

**單一 repo 模式**：
```
<repo>/docs/cruise-logs/
├── 2026-03-21-session-abc123.jsonl   ← Session A 的 log
└── 2026-03-22-session-def456.jsonl   ← 另一天的 log
```

**多 repo 模式**（log 統一在 group 目錄，不寫入各 repo）：
```
<group-dir>/cruise-logs/
├── 2026-03-21-session-abc123.jsonl   ← Session A（巡邏 3 個 repo）
├── 2026-03-21-session-def456.jsonl   ← Session B 的 log（同一天）
└── 2026-03-22-session-ghi789.jsonl   ← 另一天的 log
```

### Issue 重複防護

SRE 建立 Issue 前必須執行 `gh issue list -R ${OWNER_REPO} --search` 搜尋：

```bash
# 搜尋包含 issue_title 的所有 Issue（含已關閉）
EXISTING=$(gh issue list -R ${OWNER_REPO} \
  --search "\"${ISSUE_TITLE}\"" \
  --state all \
  --json number,title \
  2>/dev/null || echo "[]")

if echo "$EXISTING" | jq -e '. | length > 0' &>/dev/null; then
  echo "[SRE] 跳過重複 Issue：$ISSUE_TITLE"
else
  gh issue create -R ${OWNER_REPO} ...
fi
```

### 多 Session 同時 Cruise

- 每個 Session 各自獨立執行 loop，互不干擾
- Flag file 以 SESSION_ID 命名（`/tmp/shikigami-cruise-<SESSION_ID>.active`）
- Shoot flag 以 SESSION_ID 命名（`/tmp/shikigami-cruise-shoot-<SESSION_ID>.active`），per-session 互斥，不影響其他 session 的 auto-shoot
- Log 以 SESSION_ID 命名（per-session JSONL）
- Issue 重複防護確保同一問題不會被多個 Session 重複建立（覆蓋所有新 Issue 類型：CI failure / deploy failure / runner offline）
- 多 runner 同時發現同一 failure → 只建一個 Issue（search 防護，冪等性覆蓋所有新 Issue 類型）
- **多 repo 場景**：同一 session 巡邏多個 repo，Issue 重複防護已含 `-R` 指定 repo，跨 repo 不會誤判重複

---

## Log 格式完整範例

**單一 repo 模式**（`"repo"` 欄位仍存在，值為該 repo 的 owner/repo）：

```jsonl
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:00+0800","type":"po-patrol","repo":"KCTW/shikigami","strict":false,"threshold_days":3,"summary":"掃描 15 個 open issues，處置完畢","actions":["triage #301","auto-shoot #310","sprint-candidate #312","auto-close #315","waiting #320: 1h elapsed","skipped #321: stakeholder-issue"],"actionable_issues":[310],"sprint_candidates":[312]}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:05+0800","type":"sre-inspection","repo":"KCTW/shikigami","summary":"檢查 10 筆 CI run，發現 1 個 CI failure，建立 1 個 Issue","actions":["create-issue-with-debug #321"]}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:10+0800","type":"auto-shoot-completed","repo":"KCTW/shikigami","cycle":1,"issue":310,"result":"success"}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:31:00+0800","type":"trigger-sprint-planning","repo":"KCTW/shikigami","reason":"count=3"}
```

**多 repo 模式**（每個 repo 各一筆 log entry）：

```jsonl
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:00+0800","type":"po-patrol","repo":"KCTW/shikigami","strict":false,"threshold_days":3,"summary":"掃描 15 個 open issues，處置完畢","actions":["triage #301","auto-shoot #310"],"actionable_issues":[310],"sprint_candidates":[]}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:02+0800","type":"sre-inspection","repo":"KCTW/shikigami","summary":"檢查 10 筆 CI run，無異常","actions":[]}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:04+0800","type":"po-patrol","repo":"KCTW/project-x","strict":false,"threshold_days":3,"summary":"掃描 8 個 open issues，處置完畢","actions":["sprint-candidate #50"],"actionable_issues":[],"sprint_candidates":[50]}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:06+0800","type":"sre-inspection","repo":"KCTW/project-x","summary":"檢查 5 筆 CI run，發現 1 個 failure","actions":["create-issue-with-debug #45"]}
```

**主 loop 寫入的 log entry 類型**（#343 修正 #340）：

| 類型 | 說明 |
|------|------|
| `"auto-shoot-completed"` | shoot 完成，含 result（success/failed） |
| `"auto-shoot-escalated"` | 同一 Issue 連續 2 次 shoot fail，升級為 sprint-candidate（AC-5） |
| `"auto-shoot-stale-cleared"` | SHOOT_FLAG 殘留超過 30 分鐘，強制清除 |
| `"trigger-sprint-planning"` | sprint-candidate ≥ 3 或 1 個超過 30min，觸發 Sprint Planning（AC-3） |
