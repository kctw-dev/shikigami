# Cruise Mode — 啟動流程與執行細節

本文件包含 Cruise Mode 啟動流程的詳細實作步驟，由 `SKILL.md` 引用。

---

## §1 解析參數

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

## §2 偵測 Repo 列表（AC-1 / AC-2）

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

## §2.5 驗證 Repo Remote（排除無效 repo）

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

## §3 列出偵測結果（AC-7）

```bash
echo "[CRUISE] 偵測到 ${#REPOS[@]} 個有效 repo："
for REPO_PATH in "${REPOS[@]}"; do
  echo "  - ${REPO_REMOTES[$REPO_PATH]} (${REPO_PATH})"
done
```

## §3.5 自動清理 Stale Worktree（#697）

在建立 Flag File 之前，對所有偵測到的 repo 執行 worktree 清理，釋放被 prunable worktree 佔用的 `SHIKIGAMI_MAX_PARALLEL` 額度，防止 auto-shoot 永遠被 OOM 擋住的死循環（#697 歷史案例）。

```bash
# §3.5 Stale Worktree 自動清理（#697）
for REPO_PATH in "${REPOS[@]}"; do
  # AC2: 對所有 REPOS 執行 git worktree prune
  git -C "$REPO_PATH" worktree prune 2>/dev/null || true  # AC4: 失敗不阻塞 cruise

  # AC3: 移除超過 1 小時的 orphan worktree 目錄
  WORKTREE_DIR="${REPO_PATH}/.claude/worktrees"
  if [[ -d "$WORKTREE_DIR" ]]; then
    find "$WORKTREE_DIR" -maxdepth 1 -mindepth 1 -type d -mmin +60 | while read -r orphan_dir; do
      git -C "$REPO_PATH" worktree remove --force "$orphan_dir" 2>/dev/null || true  # AC4: 失敗不阻塞
    done
  fi
done
echo "[CRUISE] §3.5 worktree prune 完成"
```

**適用範圍**：每次 cruise 啟動時（Loop Mode 與 Once Mode 均執行）。
**AC1**：本步驟位於 §4 之前，確保建立 Flag File 前額度已釋放。
**AC5**：驗證方式 — 執行後 `git worktree list` 不應出現 prunable 條目。

---

## §4 建立 Flag File（SSOT — #449 AC4）

```bash
# 解析 Session ID（#572 fallback chain）
source hooks/lib/resolve-session-id.sh
SESSION_ID="${SHIKIGAMI_SESSION_ID}"
CRUISE_FLAG="/tmp/shikigami-cruise-${SESSION_ID}.active"
SHOOT_FLAG="/tmp/shikigami-cruise-shoot-${SESSION_ID}.active"
touch "$CRUISE_FLAG"
echo "[CRUISE] Loop Mode 啟動（Session: ${SESSION_ID}，間隔: ${INTERVAL}）"
echo "[CRUISE] 停止指令：/cruise stop"
```

## §4.2 建立 Sprint Stories Task List（#513 / #538）

為當前 Cruise Cycle 建立 Task，追蹤進度並支援 compact 後恢復。

**Task 命名格式（#538 AC1）**：`{repo}/cruise-cycle-{N}`

```
# 清理上一 cycle 的殘留 Task（#538 AC5）
PREV_CYCLE=$((CYCLE - 1))
if [[ $PREV_CYCLE -gt 0 ]]; then
  OLD_TASKS=$(TaskList | filter subject matches "${OWNER_REPO}/cruise-cycle-${PREV_CYCLE}")
  for OLD_TASK in OLD_TASKS:
    TaskUpdate id=OLD_TASK.id status="completed"
fi

# 建立本 cycle 的 Cruise Task
TaskCreate subject="${OWNER_REPO}/cruise-cycle-${CYCLE}" status="in-progress"

# 查詢當前 Sprint 的 Stories
SPRINT_STORIES=$(gh issue list -R ${OWNER_REPO} --label "status: in-sprint" --json number,title)
for STORY in SPRINT_STORIES:
  TaskCreate subject="${OWNER_REPO}/cruise-cycle-${CYCLE}/#${STORY.number}" status="pending"
```

**Task 狀態對應**：

| Story 狀態 | Task status |
|-----------|-------------|
| 等待派工 | `pending` |
| auto-shoot 進行中 | `in-progress` |
| shoot 成功完成 | `completed` |
| shoot 失敗升級 | `failed` |

**compact 後恢復（#538 AC4）**：

```
ACTIVE_CYCLE_TASK=$(TaskList | filter subject starts_with "${OWNER_REPO}/cruise-cycle-" AND status="in-progress" | first)
CYCLE=$(extract N from ACTIVE_CYCLE_TASK.subject)
PENDING_STORIES=$(TaskList | filter subject starts_with "${OWNER_REPO}/cruise-cycle-${CYCLE}/#" AND status in ["pending", "in-progress"])
ACTIONABLE_ISSUES = PENDING_STORIES.map(task => extract story_number from task.subject)
```

**Cruise phase 追蹤改用 JSONL log entries**：

| 事件 | JSONL log entry type |
|------|----------------------|
| cruise 初始化 | `"cruise-init"` |
| PO 巡邏開始 | `"po-patrol-start"` |
| PO 巡邏完成 | `"po-patrol-complete"` |
| SRE 巡檢開始 | `"sre-inspection-start"` |
| SRE 巡檢完成 | `"sre-inspection-complete"` |
| auto-shoot 開始 | `"auto-shoot-start"` |
| cruise 清理完成 | `"cruise-cleanup"` |

## §4.5 讀取 project_level（#348）

```bash
CONFIG_FILE=".claude/shikigami.local.md"
PROJECT_LEVEL=$(grep -A5 'shikigami:' "$CONFIG_FILE" 2>/dev/null | grep 'project_level:' | awk '{print $2}' | head -1)
PROJECT_LEVEL="${PROJECT_LEVEL:-medium}"
```

## §4.55 讀取 cruise.patrol（#590）

```bash
PATROL_MODE=$(grep -A10 'cruise:' "$CONFIG_FILE" 2>/dev/null | grep 'patrol:' | awk '{print $2}' | head -1)
PATROL_MODE="${PATROL_MODE:-both}"
```

| 值 | 行為 |
|----|------|
| `po` | 只派 PO-patrol subagent，跳過 SRE-inspection |
| `sre` | 只派 SRE-inspection subagent，跳過 PO-patrol |
| `both`（預設） | 同時派 PO + SRE（向後相容，未設定時 fallback） |

## §4.6 讀取 close_policy 與 delivery_chain（#338）

```bash
CONFIG_FILE=".claude/shikigami.local.md"
REQUIRE_CREATOR_APPROVAL="false"; CLOSE_DEFAULT_TIMEOUT="2h"
DELIVERY_CHAIN_DEFAULT="production"
# 若 CONFIG_FILE 存在，從中讀取 require_creator_approval / default_timeout / delivery_chain.default
# get_delivery_chain() / get_close_timeout() 函式：讀 per-repo 覆蓋值，fallback 至 DEFAULT
```

## §5 準備 Log 目錄

```bash
LOG_BASE=$([[ "$MULTI_REPO" == "true" ]] && echo "$(pwd)" || echo "${REPOS[0]}")
LOG_DIR="${LOG_BASE}/cruise-logs"
mkdir -p "$LOG_DIR"
CRUISE_LOG="${LOG_DIR}/$(date '+%Y-%m-%d')-session-${SESSION_ID}.jsonl"
CYCLE=0
```

## §6a Once Mode 執行流程（`/cruise --once`）

```
CYCLE=1
寫入 {"type":"cruise-init",...} log entry
for REPO_PATH in REPOS:
  if PATROL_MODE == "po" or PATROL_MODE == "both":
    派遣 PO-patrol subagent（帶入 REPO_PATH, OWNER_REPO）
  if PATROL_MODE == "sre" or PATROL_MODE == "both":
    派遣 SRE-inspection subagent（帶入 REPO_PATH, OWNER_REPO）
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

## §6b Loop Mode

```
寫入 {"type":"cruise-init",...} log entry
while 檢查 flag file 存在:
  CYCLE += 1; touch "$CRUISE_FLAG"
  寫入 {"type":"po-patrol-start",...} / {"type":"sre-inspection-start",...} log entry
  for REPO_PATH in REPOS:
    if PATROL_MODE == "po" or PATROL_MODE == "both":
      派遣 PO-patrol subagent（詳見 references/po-patrol.md）
    if PATROL_MODE == "sre" or PATROL_MODE == "both":
      派遣 SRE-inspection subagent（詳見 references/sre-inspection.md）
  等待完成，寫入 log
  寫入 {"type":"po-patrol-complete",...} / {"type":"sre-inspection-complete",...} log entry

  # SHOOT_FLAG 殘留防護：>30 分鐘強制清除，寫 auto-shoot-stale-cleared log
  # Auto-shoot（依 project_level）— 詳見 references/auto-shoot.md
  # Sprint Planning 觸發已移至 PO 巡邏直接執行（#352）
  # Step 5（Sprint Planning 觸發）必須由 PO subagent 自行 Read `references/po-patrol.md` Step 5 執行，
  # 主 session prompt 中禁止包含觸發條件描述（HARD-GATE，見 po-patrol.md Step 5）

  sleep ${INTERVAL_SECONDS}
  if flag file 不存在: break
echo "[CRUISE] 巡航模式已停止"
```

**subagent 派遣約定**：
- 每個 subagent 帶入 `REPO_PATH`（絕對路徑）與 `OWNER_REPO`（`owner/repo`）
- 所有 `gh` 指令加 `-R ${OWNER_REPO}`
- subagent **不自行寫入 log**（DM-4：log 由主 loop 統一寫入）
