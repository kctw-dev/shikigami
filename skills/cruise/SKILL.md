---
name: cruise
description: "Use when enabling periodic PO patrol + SRE inspection in the current session"
requiredTools:
  - Read
  - Glob
  - Grep
  - Bash
---

# Cruise Mode Skill — PO 巡邏 + SRE 巡檢自動巡航

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
  else:
    寫入錯誤 log entry：
      {"type":"error","repo":"<OWNER_REPO>","cycle":1,"timestamp":"<ISO8601>","summary":"subagent failed: <reason>","mode":"once"}
    echo "[CRUISE] WARNING: ${OWNER_REPO} 巡邏/巡檢失敗，見 log"

# ── Auto-shoot（與 Loop Mode 相同，依 project_level 控制）──
# [AUTO-CONTINUE] project_level=low → 自動派 auto-shoot，不停
ACTIONABLE_ISSUES = PO 巡邏結果.actionable_issues
if PROJECT_LEVEL != "high":
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

# ── Once Mode 完成 log entry ──
寫入 log：{"type":"once-mode-complete","timestamp":"<ISO8601>","session_id":"<SESSION_ID>","repos":[<OWNER_REPO>,...]}
echo "[CRUISE] Once Mode 執行完成，寫入 log：${CRUISE_LOG}"

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
while 檢查 flag file 存在:
  CYCLE += 1
  # #449 AC1：每個 cycle 開始時 touch flag file，重置 mtime，避免 systemd-tmpfiles-clean 清除
  touch "$CRUISE_FLAG"
  if [[ -f "$SHOOT_FLAG" ]]; then touch "$SHOOT_FLAG"; fi
  for REPO_PATH in REPOS:
    OWNER_REPO = REPO_REMOTES[REPO_PATH]
    平行派遣：
      - PO-patrol（帶入 REPO_PATH, OWNER_REPO, STRICT_MODE, THRESHOLD_DAYS）
      - SRE-inspection（帶入 REPO_PATH, OWNER_REPO）
  等待所有 task 完成
  for each subagent result:
    if subagent 成功:
      寫入正常 log entry（JSONL append，含 "repo" 欄位）
    else:
      寫入錯誤 log entry：
        {"type":"error","repo":"<OWNER_REPO>","cycle":<N>,"timestamp":"<ISO8601>","summary":"subagent failed: <reason>"}
      echo "[CRUISE] WARNING: ${OWNER_REPO} 巡邏/巡檢失敗，見 log"

  # ── SHOOT_FLAG 殘留防護 ──────────────────────
  if SHOOT_FLAG 存在:
    SHOOT_FLAG_AGE = (now - SHOOT_FLAG mtime) in minutes
    if SHOOT_FLAG_AGE > 30:
      echo "[CRUISE] SHOOT_FLAG 殘留超過 30 分鐘，強制清除"
      rm -f SHOOT_FLAG
      寫入 log entry：
        {"type":"auto-shoot-stale-cleared","repo":"<OWNER_REPO>","cycle":<N>,"timestamp":"<ISO8601>"}

  # ── Auto-shoot 連續派遣（#343 AC-2，#348 project_level 控制）──
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

## PO 巡邏指引（AC-1）

**觸發**：每個 cruise cycle 由 Task tool 派遣 PO Agent 執行
**Repo context**：subagent 接收 `REPO_PATH` 與 `OWNER_REPO` 參數，所有 `gh` 指令加 `-R ${OWNER_REPO}`

### 掃描 Open Issues

```bash
# 列出所有 open issues（含 comments 欄位）
# 單一 repo 與多 repo 模式均使用 -R ${OWNER_REPO}，統一行為
gh issue list -R ${OWNER_REPO} --state open --limit 50 --json number,title,labels,assignees,updatedAt,comments
```

掃描重點：
- 逾期 Issue（`updatedAt` 超過 7 天未更新且無 assignee）
- 無回應 Issue（已開超過 3 天**且無任何留言**且無 assignee）
- 標記為 `blocked` 或 `needs-triage` 的 Issue
- 有新回覆的 Issue（`comments` 較上次 cycle 增加）

### 留言掃描步驟

對 `comments > 0` 的 Issue，讀取實際留言內容：

```bash
# 讀取有留言的 Issue 完整留言
gh issue view <issue_number> -R ${OWNER_REPO} --json comments
```

**「無回應」判斷標準**（#320 教訓）：

Issue 同時滿足以下條件才視為「無回應」：
1. 無 assignee（`assignees` 為空陣列）
2. 最近 3 天內無任何留言（不論留言者是誰）

```bash
# 判斷邏輯（偽碼）
# THRESHOLD_DAYS：預設 3，strict 模式為 0
for each issue in issues:
  has_assignee = issue.assignees.length > 0
  comment_data = gh issue view issue.number -R ${OWNER_REPO} --json comments
  latest_comment_at = comment_data.comments[-1].createdAt  # 若有留言
  days_since_comment = (now - latest_comment_at) in days

  if not has_assignee and (no comments OR days_since_comment > THRESHOLD_DAYS):
    mark as "無回應"

  # Stakeholder 留言優先標記
  for comment in comment_data.comments:
    if "[PRIORITY]" in comment.body:
      mark issue as "PRIORITY"
      alert PO immediately
```

### 關聯 PR comments 掃描步驟（#389）

對 Issue 掃描完留言後，**若存在關聯 PR**，額外讀取 PR comments，以確保不遺漏 stakeholder 在 PR 上留下的工作指示。

```bash
# 透過 issue timeline 取得關聯 PR（ConnectedEvent / CrossReferencedEvent）
PR_LIST=$(gh issue view ${ISSUE_NUMBER} -R ${OWNER_REPO} \
  --json timelineItems \
  --jq '[.timelineItems.nodes[] | select(.__typename=="ConnectedEvent" or .__typename=="CrossReferencedEvent") | .source | select(.number != null) | {number:.number,state:.state}]' \
  2>/dev/null || echo "[]")

# 對每個關聯 PR，讀取其 comments（含 review comments）
for pr_number in $(echo "$PR_LIST" | jq -r '.[].number // empty'); do
  PR_COMMENT_DATA=$(gh pr view "${pr_number}" -R ${OWNER_REPO} \
    --json comments,reviews,reviewRequests \
    2>/dev/null || echo "{}")
  # 篩選 LAST_PATROL_TIME 之後的新留言，避免重複處理
  NEW_PR_COMMENTS=$(echo "$PR_COMMENT_DATA" | jq --arg since "${LAST_PATROL_TIME}" \
    '[.comments[] | select(.createdAt > $since)]')
done
```

**PR comments 解析規則**：

| 解析項目 | 說明 |
|---------|------|
| 識別 stakeholder / PO 指示 | 留言者為 PO 帳號（如 `KCTW`），或留言內容包含工作指令語義（「按 Issue 切開」、「拆分」、「不要混」等） |
| 時間戳篩選 | 僅處理 `createdAt > LAST_PATROL_TIME` 的新留言，避免重複處理舊指示 |
| 指示方向萃取 | 若留言包含明確動作指令，提取並記錄為 `pr_instruction` |

**PR comments 與 Issue comments 衝突時的優先級規則**（#389 核心修復）：

> **以 PR comments 為準**。PR 是工作實作的直接脈絡，stakeholder 在 PR 上留下的指示通常是對 Issue 描述的細化或修正，時間上更接近實際工作狀態。

```bash
# 優先級偽碼
if pr_instruction 與 issue_instruction 方向矛盾:
  EFFECTIVE_INSTRUCTION = pr_instruction  # PR comments 優先
  log action: "pr-instruction-overrides-issue #${ISSUE_NUMBER} PR#${PR_NUMBER}"
  # 在巡邏留言中說明以 PR 指示為準，避免重複矛盾指令
else:
  EFFECTIVE_INSTRUCTION = merge(issue_instruction, pr_instruction)  # 無矛盾則合併
```

**回歸測試場景（#389 case）**：

- Issue #25 / #28 關聯 PR #29（LinGeorge2/AIO-System）
- PR #29 comment（PO KCTW 留言）：「不要混在一起 按 Issue 把工作切開, 再一一送 PR 來」
- 預期 PO Agent 行為：掃描 PR #29 comments → 識別「拆分」指示 → 留言要求拆分 PR，不催促合併
- 修復前錯誤行為：只看 Issue comments，持續催促合併

### Stakeholder 回覆處置表（#422）

<!-- #422 新增 Stakeholder 回覆處置表 — 明確指示應立即觸發執行 -->

**執行時機**：在 Issue 處置決策表之前執行。對有 comments 的 Issue，先掃描最新 comments 判斷是否有 Stakeholder 回覆。

**Stakeholder 識別**：Issue author 或帶有 MEMBER/OWNER association 的留言者。

| Stakeholder 回覆類型 | 識別關鍵字 | PO 處置 | log action |
|---------------------|-----------|---------|-----------|
| **明確指示** | `先做X`、`改成Y`、`加上Z`、`先規劃`、`先不實作`、直接描述待辦事項 | **立即執行**：依指示內容分流（auto-shoot 或 sprint-candidate），不標 awaiting-reply | `"stakeholder-instruction"` |
| **確認/同意** | `OK`、`好`、`同意`、`approve`、`LGTM`、`merge`、`可以` | **推進**：移至下一階段（merge PR、close Issue、繼續開發） | `"stakeholder-confirm"` |
| **提問/澄清** | `?`、`為什麼`、`能不能`、`怎麼做`、問句格式 | **回答**：PO 嘗試回答；無法回答則標記需人工處理 | `"stakeholder-question"` |
| **拒絕/修改** | `不要`、`不行`、`改成`、`重做`、`不是這樣` | **調整**：依拒絕內容修改方向，重新分流 | `"stakeholder-reject"` |
| **無回覆** | 無新 comments | 走 Issue 處置決策表正常流程 | — |

**冪等規則**：同一 Stakeholder 回覆不重複處理。以 comment ID 判斷是否已處理過。

**優先順序**：Stakeholder 回覆處置表 > Issue 處置決策表。若 Stakeholder 有明確指示，直接依指示執行，不再進入 Issue 處置決策表的判斷。

---

### PO Issue 處置決策表（#343，取代 #340 actionable 判斷）

**全覆蓋強制處置**：每個 open Issue **必須**落入以下其中一格。PO **禁止自行加排除條件**。不允許「掃描完跳過」或「已留言所以跳過」。

**安全前置檢查**（每個 Issue 行動前必先執行）：
- 若 Issue 帶有 `stakeholder` label → 跳過所有行動，記錄 `"skipped": "stakeholder-issue"` 至 cruise log
- George 的 issues 不能代關
- 詳見下方「安全邊界」段落

| 判斷 | 處置 | 行動 | log action 類型 |
|------|------|------|-----------------|
| **無 label** | **Triage** | `gh issue edit --add-label <label>` 自主加分類 label（AC-6），然後重新判斷此 Issue | `"triage"` |
| **帶 `cruise-feedback` label** | **Feedback Routing** | 讀取 `feedback_routing` 設定，依 `project_level` 決定自動轉送（low）或留言確認（medium/high）（#339） | `"cruise-feedback-routed"` / `"cruise-feedback-pending-confirm"` / `"cruise-feedback-skip"` |
| **Size=S，改動明確** | **auto-shoot** | 標記為 actionable，回傳給主 loop 派 `/shoot` | `"auto-shoot"` |
| **Size=M+，需設計或跨模組** | **排入 Sprint** | `gh issue edit --add-label sprint-candidate` | `"sprint-candidate"` |
| **交付物為規劃/設計文件** | **直接開始** | 識別為「規劃類」Issue（見交付物類型識別），標記為 actionable 或 sprint-candidate（依 Size），**不標記 awaiting-reply** | `"deliverable-planning"` |
| **缺資訊，無法判斷**（交付物類型識別後仍不明確） | **等待回覆** | `gh issue edit --add-label awaiting-reply` + 留言問誰要補什麼 | `"awaiting-reply"` |
| **明確暫停** | **暫停** | `gh issue edit --add-label pending` + 留言說明暫停原因 | `"pending"` |
| **已修復但未關** | **結案** | `require_creator_approval: false`（預設）→ `gh issue close`；`true` → 留言建議關閉 + `awaiting-reply`（PO 自建 Issue 豁免，直接 close） | `"close"` / `"close-pending-approval"` |
| **stakeholder Issue** | **跳過** | 只記錄至 cruise log | `"skipped"` |

**Size 判斷標準**：
- **Size=S**：單一檔案或少數檔案修改、修復方向明確、無需跨模組協調
- **Size=M+**：需要 ADR、跨多個模組、涉及架構變更、需要多人討論

### 交付物類型識別（#412）

<!-- #412 PO 巡邏未正確解讀 Issue 交付物 — 交付物識別邏輯 -->

PO 在判斷 Issue 處置前，**必須**先解析 Issue body 判斷交付物類型。此步驟在 Size 判斷之前執行。

| 交付物類型 | 關鍵字 | 正確處置 |
|-----------|--------|---------|
| **實作類**（需要程式碼） | `實作`、`開發`、`新增功能`、`修復`、`fix`、`feat` | 依 Size 判斷 auto-shoot 或 sprint-candidate |
| **規劃類**（需要文件） | `規劃`、`設計`、`先規劃`、`審查後再實作`、`先不實作`、`plan` | **不標記 awaiting-reply**。交付物已明確（規劃文件），直接開始撰寫規劃 |
| **調查類**（需要分析報告） | `調查`、`分析`、`評估`、`research`、`POC` | **不標記 awaiting-reply**。交付物已明確（調查報告），直接開始調查 |

**`awaiting-reply` 使用限制**（#412 根因修正）：

`awaiting-reply` **僅適用於**以下情境：
- Issue 描述本身存在歧義，無法確定範圍
- 缺少必要的技術前提資訊
- 需要 stakeholder 確認優先順序衝突

**不應**用於交付物已明確定義的情況。當 Issue body 包含「先規劃再實作」、「先規劃給我審查」等明確指示時，交付物為**規劃文件**，無需澄清，應直接開始作業。

**PO 自主加分類 label（AC-6）**：除了流程性 label（`stakeholder`）需人工決定，其餘分類 label（`research`、`enhancement`、`bug`、`feature-request` 等）PO 直接 `gh issue edit --add-label` 加上，不需「建議」等人操作。

### 處置決策偽碼（AC-1）

```bash
# 偽碼：每個 open Issue 必須有處置結果，禁止跳過
ACTIONABLE_ISSUES=()
SPRINT_CANDIDATES=()

for each issue in issues:
  # ── 安全前置 ──
  if "stakeholder" in issue.labels:
    log action: "skipped #<issue.number>: stakeholder-issue"
    continue

  # ── Step 0.5：讀取關聯 PR comments（#389），取得 EFFECTIVE_INSTRUCTION ──
  # 執行「關聯 PR comments 掃描步驟」段落的邏輯
  # PR comments 與 Issue comments 有矛盾時，以 PR comments 為準
  EFFECTIVE_INSTRUCTION = merge_with_pr_priority(issue_comments, pr_comments)
  # log 若有覆蓋：log action: "pr-instruction-overrides-issue #<issue.number> PR#<pr.number>"

  # ── Step 0.7：Stakeholder 回覆處置（#422，在 Issue 處置決策表之前執行）──
  if issue.comments > 0:
    latest_stakeholder_comment = get_latest_stakeholder_comment(issue)
    if latest_stakeholder_comment is not None AND not already_processed(latest_stakeholder_comment.id):
      reply_type = classify_stakeholder_reply(latest_stakeholder_comment)
      if reply_type == "instruction":
        # 明確指示 → 立即執行，不進入 Issue 處置決策表
        log action: "stakeholder-instruction #<issue.number>"
        # 依指示內容分流（auto-shoot 或 sprint-candidate）
        continue
      elif reply_type == "confirm":
        log action: "stakeholder-confirm #<issue.number>"
        # 推進至下一階段
        continue
      elif reply_type == "question":
        log action: "stakeholder-question #<issue.number>"
        # PO 嘗試回答
      elif reply_type == "reject":
        log action: "stakeholder-reject #<issue.number>"
        # 調整方向後重新分流

  # ── Step 1：無 label → 先 Triage（PO 自主加 label）──
  if issue.labels is empty:
    # PO 判斷 Issue 類型，直接加 label（AC-6）
    gh issue edit issue.number -R ${OWNER_REPO} --add-label <判斷的 label>
    log action: "triage #<issue.number>"
    # 加完 label 後繼續判斷此 Issue（不跳過）

  # ── Step 1.5：cruise-feedback label → Feedback Routing（#339）──
  if "cruise-feedback" in issue.labels:
    # 讀取 feedback_routing 設定（.claude/shikigami.local.md）
    FEEDBACK_DEFAULT=$(grep -A10 'feedback_routing:' "$CONFIG_FILE" 2>/dev/null \
      | grep 'default:' | awk '{print $2}' | head -1)
    FEEDBACK_TARGET="${FEEDBACK_DEFAULT:-kctw-dev/shikigami}"

    if [[ "$PROJECT_LEVEL" == "low" ]]; then
      # low：自動建 Issue 到目標 repo，事後通知
      FEEDBACK_TITLE="[Cruise Feedback] ${issue.title}"
      EXISTING_FEEDBACK=$(gh issue list -R "${FEEDBACK_TARGET}" \
        --search "\"${FEEDBACK_TITLE}\"" --state all --json number,title \
        2>/dev/null || echo "[]")
      if echo "$EXISTING_FEEDBACK" | jq -e '. | length > 0' &>/dev/null; then
        log action: "cruise-feedback-skip #<issue.number>: duplicate in ${FEEDBACK_TARGET}"
      else
        gh issue create -R "${FEEDBACK_TARGET}" \
          --title "${FEEDBACK_TITLE}" \
          --body "## [Cruise Feedback] 自動轉送

原始 Issue：${OWNER_REPO}#${issue.number}
標題：${issue.title}

---

${issue.body}

---
> 此 Issue 由 Cruise Feedback Routing 自動建立。
> 來源：${OWNER_REPO}#${issue.number}，Session: ${SESSION_ID}" \
          --label "cruise-feedback,feature-request"
        log action: "cruise-feedback-routed #<issue.number> → ${FEEDBACK_TARGET}"
        # 轉送成功後移除 label，避免下一 cycle 重複處理
        gh issue edit issue.number -R ${OWNER_REPO} --remove-label cruise-feedback
      fi
    else
      # medium / high：PO 留言確認，不自動建 Issue（冪等：已有 [巡邏狀態：Feedback Routing] 留言則跳過）
      gh issue comment issue.number -R ${OWNER_REPO} --body "## [巡邏狀態：Feedback Routing]

此 Issue 標有 \`cruise-feedback\` label，判斷屬於框架層級改善建議。

建議回報至：**${FEEDBACK_TARGET}**

project_level=${PROJECT_LEVEL}，請確認是否轉送。

- 巡邏時間：$(date '+%Y-%m-%dT%H:%M:%S')
- Session: ${SESSION_ID}
- Cycle: ${CYCLE}"
      log action: "cruise-feedback-pending-confirm #<issue.number>: notify only (project_level=${PROJECT_LEVEL})"
    fi
    continue

  # ── Step 2：超時自動關閉（AC-4）──
  if "awaiting-reply" in issue.labels OR "pending" in issue.labels:
    label_added_at = issue.updatedAt  # 以最後更新時間近似
    hours_since = (now - label_added_at) in hours
    if hours_since >= 2:
      gh issue close issue.number -R ${OWNER_REPO} \
        --comment "## [自動關閉]

此 Issue 標記為 $(label)，超過 2 小時未回應，自動關閉。
如需重新開啟，請留言說明。

- 關閉時間：$(date '+%Y-%m-%dT%H:%M:%S')
- Session: ${SESSION_ID}"
      log action: "auto-close #<issue.number>"
      continue
    else:
      # 未超時，維持等待狀態（AC-1：仍須記錄處置結果，不靜默跳過）
      log action: "waiting #<issue.number>: <hours_since>h elapsed"
      continue

  # ── Step 3：已修復未關 → 結案（#338：close_policy 控制）──
  # 檢查是否有關聯 PR 已 merged
  if issue 有關聯 PR 且 PR 已 merged:
    if issue 非 George 的 Issue:
      # 讀取此 repo 的 close_policy 設定
      # 豁免條件：PO 自建（issue.author == 當前 PO / bot）→ 直接 close
      IS_PO_ISSUE = (issue.author is PO agent or system bot)

      if REQUIRE_CREATOR_APPROVAL == "true" AND NOT IS_PO_ISSUE:
        # 需要發 Issue 人同意 → 留言建議關閉 + awaiting-reply
        REPO_TIMEOUT=$(get_close_timeout "${OWNER_REPO}")
        gh issue edit issue.number -R ${OWNER_REPO} --add-label awaiting-reply
        gh issue comment issue.number -R ${OWNER_REPO} --body "## [巡邏狀態：已修復] 建議關閉

關聯 PR 已合併，此 Issue 看起來已修復。

如無異議，將在 ${REPO_TIMEOUT} 後自動關閉。如需保持開啟，請回覆說明。

- 巡邏時間：$(date '+%Y-%m-%dT%H:%M:%S')
- Session: ${SESSION_ID}
- Cycle: ${CYCLE}"
        log action: "close-pending-approval #<issue.number>"
        # 留言後交由 Step 2 超時機制統一處理（awaiting-reply label）
        continue
      else:
        # require_creator_approval == false，或 PO 自建 Issue → 直接 close
        gh issue close issue.number -R ${OWNER_REPO} \
          --comment "## [巡邏狀態：已修復] 關聯 PR 已合併，結案。"
        log action: "close #<issue.number>"
        continue

  # ── Step 3.5：交付物類型識別（#412）──
  # 在 Size 判斷前，先解析 Issue body 判斷交付物類型
  DELIVERABLE_TYPE = identify_deliverable_type(issue.body)
  # 關鍵字匹配：「先規劃」「審查後再實作」「先不實作」→ planning
  #              「調查」「評估」「research」「POC」→ research
  #              其他 → implementation（預設）
  if DELIVERABLE_TYPE == "planning" OR DELIVERABLE_TYPE == "research":
    # 交付物已明確，不標記 awaiting-reply，依 Size 直接分流
    log action: "deliverable-${DELIVERABLE_TYPE} #<issue.number>"

  # ── Step 4：判斷 Size 決定 auto-shoot 或 sprint-candidate ──
  if Size=S（單檔修改、修復方向明確、無需跨模組）:
    ACTIONABLE_ISSUES += issue.number
    log action: "auto-shoot #<issue.number>"
  else:  # Size=M+
    gh issue edit issue.number -R ${OWNER_REPO} --add-label sprint-candidate
    SPRINT_CANDIDATES += issue.number
    log action: "sprint-candidate #<issue.number>"

# 回傳結果（#346：close 與 auto-shoot 分開回傳）
# close_issues: PO 已直接 close 的 Issue（不走 shoot）
# actionable_issues: 供主 loop invoke shikigami:shoot 派遣（必須走完整 shoot 流程）

# ── Step 5：Sprint Planning 觸發（#352：PO 直接執行，不經主 loop）──
# PO 巡邏完所有 Issue 後，自己檢查 sprint-candidate 觸發條件
# 讀取 project_level 從 .claude/shikigami.local.md（步驟 4.5 已定義讀取方式）
CONFIG_FILE=".claude/shikigami.local.md"
PROJECT_LEVEL=$(grep -A5 'shikigami:' "$CONFIG_FILE" 2>/dev/null | grep 'project_level:' | awk '{print $2}' | head -1)
PROJECT_LEVEL="${PROJECT_LEVEL:-medium}"

SPRINT_CANDIDATE_COUNT = gh issue list -R ${OWNER_REPO} --label sprint-candidate --state open --json number | jq length
OLDEST_CANDIDATE_AGE = 最早的 sprint-candidate Issue 的 updatedAt 距今分鐘數
SHOULD_TRIGGER = (SPRINT_CANDIDATE_COUNT >= 3) OR (SPRINT_CANDIDATE_COUNT >= 1 AND OLDEST_CANDIDATE_AGE >= 30)

if SHOULD_TRIGGER:
  if PROJECT_LEVEL == "low":
    # low：PO 直接觸發，不等人
    invoke shikigami:sprint-planning
    log action: "trigger-sprint-planning (project_level=low, count=${SPRINT_CANDIDATE_COUNT})"
  elif PROJECT_LEVEL == "medium":
    # medium：PO 留言通知，等使用者確認
    gh issue comment <最新 sprint-candidate Issue> -R ${OWNER_REPO} --body "## [Sprint Planning 觸發通知]
Sprint candidate 已累積 ${SPRINT_CANDIDATE_COUNT} 個，達到觸發條件。
project_level=medium，請確認是否啟動 Sprint Planning。"
    log action: "sprint-planning-notify (project_level=medium, count=${SPRINT_CANDIDATE_COUNT})"
  else:  # high
    # high：只標記，不觸發不通知
    log action: "sprint-planning-marked (project_level=high, count=${SPRINT_CANDIDATE_COUNT})"

# ── Step 5.5：Sprint 實質完成偵測（#434）──
# 條件：Sprint 中所有 Story 均帶 blocked label → 判定 Sprint 實質完成，允許推進
# 目的：避免外部依賴阻塞時 Sprint 名義進行中卻無法推進 backlog 的問題
BLOCKED_SPRINT_STORIES=$(gh issue list -R ${OWNER_REPO} --label "status: in-sprint" --label "blocked" --state open --json number | jq length)
TOTAL_SPRINT_STORIES=$(gh issue list -R ${OWNER_REPO} --label "status: in-sprint" --state open --json number | jq length)
EFFECTIVELY_COMPLETE=$(( TOTAL_SPRINT_STORIES > 0 && BLOCKED_SPRINT_STORIES == TOTAL_SPRINT_STORIES ))

if [[ "$EFFECTIVELY_COMPLETE" -eq 1 ]]; then
  # Sprint 實質完成：所有 in-sprint Story 均 blocked，允許 bypass
  if [[ "$PROJECT_LEVEL" == "low" ]]; then
    # low：自動觸發 Sprint Review，將 blocked Story 回流 backlog
    invoke shikigami:sprint-review
    log action: "sprint-effectively-complete-bypass (project_level=low, blocked=${BLOCKED_SPRINT_STORIES}, total=${TOTAL_SPRINT_STORIES})"
  elif [[ "$PROJECT_LEVEL" == "medium" ]]; then
    # medium：留言通知等使用者確認是否觸發 Sprint Review
    FIRST_BLOCKED_ISSUE=$(gh issue list -R ${OWNER_REPO} --label "status: in-sprint" --label "blocked" --state open --json number --jq '.[0].number')
    gh issue comment ${FIRST_BLOCKED_ISSUE} -R ${OWNER_REPO} --body "## [巡邏狀態：Sprint 實質完成]

Sprint 中所有 ${TOTAL_SPRINT_STORIES} 個 Story 均被外部依賴阻塞（blocked）。

Sprint 已實質完成，建議觸發 Sprint Review 將阻塞 Story 回流 backlog，推進下一個 Sprint。

project_level=medium，請確認是否觸發 Sprint Review。

- 阻塞 Story 數：${BLOCKED_SPRINT_STORIES} / ${TOTAL_SPRINT_STORIES}
- 巡邏時間：$(date '+%Y-%m-%dT%H:%M:%S')
- Session: ${SESSION_ID}
- Cycle: ${CYCLE}"
    log action: "sprint-effectively-complete-notify (project_level=medium, blocked=${BLOCKED_SPRINT_STORIES}, total=${TOTAL_SPRINT_STORIES})"
  else:  # high
    # high：只標記，不觸發不通知
    log action: "sprint-effectively-complete-marked (project_level=high, blocked=${BLOCKED_SPRINT_STORIES}, total=${TOTAL_SPRINT_STORIES})"
  fi
fi

# ── Step 6：閒置偵測（#331-子2）──
# 條件：無進行中 Sprint + 無進行中 Shoot + Backlog 有 open issues → 觸發 Sprint Planning
IN_SPRINT_COUNT = gh issue list -R ${OWNER_REPO} --label "status: in-sprint" --state open --json number | jq length
BACKLOG_COUNT   = gh issue list -R ${OWNER_REPO} --state open --json number | jq length

if [[ "$IN_SPRINT_COUNT" -eq 0 && ! -f "$SHOOT_FLAG" && "$BACKLOG_COUNT" -gt 0 ]]; then
  # 閒置狀態：無 Sprint、無 Shoot、backlog 有東西
  if [[ "$PROJECT_LEVEL" == "low" ]]; then
    # low：直接觸發 Sprint Planning
    invoke shikigami:sprint-planning
    log action: "idle-trigger-sprint-planning (project_level=low, backlog=${BACKLOG_COUNT})"
  elif [[ "$PROJECT_LEVEL" == "medium" ]]; then
    # medium：留言通知，等使用者確認
    FIRST_BACKLOG_ISSUE=$(gh issue list -R ${OWNER_REPO} --state open --json number --jq '.[0].number')
    gh issue comment ${FIRST_BACKLOG_ISSUE} -R ${OWNER_REPO} --body "## [巡邏狀態：閒置偵測]

目前無進行中 Sprint 且無進行中 Shoot，但 Backlog 有 ${BACKLOG_COUNT} 個 open issues。

project_level=medium，請確認是否啟動 Sprint Planning。

- 巡邏時間：$(date '+%Y-%m-%dT%H:%M:%S')
- Session: ${SESSION_ID}
- Cycle: ${CYCLE}"
    log action: "idle-detected-notify (project_level=medium, backlog=${BACKLOG_COUNT})"
  else:  # high
    # high：只記錄，不觸發
    log action: "idle-detected-marked (project_level=high, backlog=${BACKLOG_COUNT})"
fi
```

### 背景 Agent 進度追蹤（#331-子3）

PO 巡邏在每個 cycle 偵測 subagent 是否有新產出，避免背景工作完成但無人推進。

```bash
# ── 背景 Agent 進度偵測 ──
# fallback 視窗：從 .claude/shikigami.local.md 讀取 cruise.progress_fallback_window（預設 30m）
LOCAL_CONFIG="${REPO_PATH}/.claude/shikigami.local.md"
FALLBACK_WINDOW_RAW=$(grep 'progress_fallback_window:' "${LOCAL_CONFIG}" 2>/dev/null | awk '{print $2}' | head -1)
FALLBACK_MINUTES=30
if [[ -n "$FALLBACK_WINDOW_RAW" ]]; then
  # 支援 30m / 60m / 1h 格式
  if [[ "$FALLBACK_WINDOW_RAW" =~ ^([0-9]+)h$ ]]; then
    FALLBACK_MINUTES=$(( ${BASH_REMATCH[1]} * 60 ))
  elif [[ "$FALLBACK_WINDOW_RAW" =~ ^([0-9]+)m$ ]]; then
    FALLBACK_MINUTES="${BASH_REMATCH[1]}"
  fi
fi

# 上次巡邏時間：從 JSONL log 讀取，取最近一筆 timestamp；首次 cycle 用 fallback 視窗前
LAST_PATROL_TIME=$(jq -r 'select(.type=="po-patrol") | .timestamp' "${CRUISE_LOG}" 2>/dev/null \
  | sort | tail -1)
if [[ -z "$LAST_PATROL_TIME" ]]; then
  LAST_PATROL_TIME=$(date -d "${FALLBACK_MINUTES} minutes ago" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null \
    || date -v-${FALLBACK_MINUTES}M '+%Y-%m-%dT%H:%M:%S' 2>/dev/null \
    || date '+%Y-%m-%dT%H:%M:%S')
fi

# 1. 偵測 git log 新 commit（自上次巡邏以來）
NEW_COMMITS=$(git -C "${REPO_PATH}" log --since="${LAST_PATROL_TIME}" --oneline 2>/dev/null)

# 2. 偵測 docs/sprints/subagent-results/ 新增檔案（自上次巡邏以來）
SUBAGENT_RESULTS_DIR="${REPO_PATH}/docs/sprints/subagent-results"
NEW_RESULT_FILES=""
if [[ -d "$SUBAGENT_RESULTS_DIR" ]]; then
  NEW_RESULT_FILES=$(find "$SUBAGENT_RESULTS_DIR" -newer "${CRUISE_LOG}" -name "*.md" 2>/dev/null \
    | sort | tr '\n' ' ')
fi

# 3. 有新進度 → 對相關 Issue 留言更新狀態
if [[ -n "$NEW_COMMITS" || -n "$NEW_RESULT_FILES" ]]; then
  # 從新 commit message 或 result 檔名推導 issue number（格式 US-NNN.md 或 #NNN）
  PROGRESS_ISSUES=()
  if [[ -n "$NEW_RESULT_FILES" ]]; then
    for FILE in $NEW_RESULT_FILES; do
      ISSUE_NUM=$(basename "$FILE" | grep -oE '[0-9]+' | head -1)
      if [[ -n "$ISSUE_NUM" ]]; then
        PROGRESS_ISSUES+=("$ISSUE_NUM")
      fi
    done
  fi
  if [[ -n "$NEW_COMMITS" ]]; then
    while IFS= read -r COMMIT_LINE; do
      ISSUE_NUM=$(echo "$COMMIT_LINE" | grep -oE '#([0-9]+)' | tr -d '#' | head -1)
      if [[ -n "$ISSUE_NUM" ]]; then
        PROGRESS_ISSUES+=("$ISSUE_NUM")
      fi
    done <<< "$NEW_COMMITS"
  fi

  # 對每個有新進度的 Issue 留言（冪等：若已有「進度回報」留言且進度未變，不重複）
  for ISSUE_NUM in $(echo "${PROGRESS_ISSUES[@]}" | tr ' ' '\n' | sort -u); do
    ISSUE_EXISTS=$(gh issue view "${ISSUE_NUM}" -R ${OWNER_REPO} --json state \
      --jq '.state' 2>/dev/null || echo "")
    if [[ "$ISSUE_EXISTS" == "OPEN" ]]; then
      gh issue comment "${ISSUE_NUM}" -R ${OWNER_REPO} --body "## [巡邏狀態：進度回報]

背景 subagent 偵測到新產出：

$(if [[ -n "$NEW_COMMITS" ]]; then echo "**新 commit**："; echo '```'; echo "$NEW_COMMITS"; echo '```'; fi)
$(if [[ -n "$NEW_RESULT_FILES" ]]; then echo "**新結果檔案**：\`${NEW_RESULT_FILES}\`"; fi)

- 巡邏時間：$(date '+%Y-%m-%dT%H:%M:%S')
- Session: ${SESSION_ID}
- Cycle: ${CYCLE}"
      log action: "progress-report #${ISSUE_NUM}"
    fi
  done

  log action: "background-progress-detected (commits=${NEW_COMMITS:-none}, files=${NEW_RESULT_FILES:-none})"
fi
```

### Auto-shoot 連續派遣（AC-2，修正 #340）

SHOOT_FLAG **只防併發，不防連續**。shoot 完成後立即檢查下一個 actionable，不等下一 cycle：

```bash
# 偽碼：shoot 完成後立即 re-check（在主 loop 內）
#
# 重要（#346）：auto-shoot 與 close 的區分
#   - auto-shoot（有程式碼修改）→ 必須 invoke shikigami:shoot（完整 QA gates）
#   - close（已修復結案）→ 直接 gh issue close，不走 shoot
#   - 禁止直接派 Developer Agent 跳過 shoot 流程

# Step 1：先處理 close 處置（不走 shoot，直接關閉）
for ISSUE in CLOSE_ISSUES:
  gh issue close ${ISSUE} -R ${OWNER_REPO} --comment "<結案理由>"
  log: "close #${ISSUE}"

# Step 2：連續 auto-shoot（走完整 /shoot 流程）
while ACTIONABLE_ISSUES is not empty:
  if SHOOT_FLAG 不存在:
    ISSUE = ACTIONABLE_ISSUES.shift()  # 取出第一個
    echo "$ISSUE" > SHOOT_FLAG
    # !! 必須 invoke shikigami:shoot，不是派 Developer Agent !!
    invoke shikigami:shoot with args=#${ISSUE}  # 完整 QA + Architect + PR + CI Gate
    等待 shoot 完成
    if shoot 成功:
      rm -f SHOOT_FLAG
      SHOOT_FAIL_COUNT[ISSUE] = 0
      log: "auto-shoot-completed #${ISSUE} success"
    else:
      rm -f SHOOT_FLAG
      SHOOT_FAIL_COUNT[ISSUE] += 1
      if SHOOT_FAIL_COUNT[ISSUE] >= 2:  # AC-5：連續 2 次 fail → 升級
        gh issue edit ${ISSUE} -R ${OWNER_REPO} --add-label sprint-candidate
        log: "auto-shoot-escalated #${ISSUE} → sprint-candidate (2 consecutive failures)"
      else:
        log: "auto-shoot-completed #${ISSUE} failed (attempt ${SHOOT_FAIL_COUNT[ISSUE]})"
  # 立即繼續下一個，不 sleep
```

**actionable 優先序**（從 ACTIONABLE_ISSUES 中排序）：
1. `sre-auto-debug` label（CI failure，最緊急）
2. `bug` label
3. 其餘 Size=S Issue

### 留言語意狀態表（#340）

PO 巡邏每 cycle 判斷 Issue 當前所處狀態，選擇對應語意模板留言。此表**取代**原有的固定催促留言模板（SSOT）。

| 狀態 | 判斷依據 | 留言語意 | 留言範例 |
|------|---------|---------|---------|
| **未處理** | 無 assignee + 無留言或留言超過 threshold | 催促/提醒 | 「此 Issue 已逾期未更新，請相關負責人確認狀態」 |
| **等待回覆** | `awaiting-reply` label | 告知等待對象 | 「等待 @someone 補充環境資訊」 |
| **排隊中** | Issue 為 actionable + `SHOOT_FLAG` 存在（另一 shoot 進行中） | 告知排序 | 「已排入修復佇列，前方有 1 個修復進行中」 |
| **處理中** | Issue 為當前 auto-shoot 目標（`SHOOT_FLAG` 內容 = 此 issue number） | 進度回報 | 「已派工修復，shoot 執行中…」 |
| **PR 已開** | 關聯 PR 存在且 state=open | 交付追蹤 | 「PR #N 已開，待 review」 |
| **已修復** | 關聯 PR merged + CI passing | 結案確認 | 「修復已合併，CI 恢復正常」 |

**狀態判斷順序**（優先高→低）：
1. 已修復（PR merged + CI pass）→ 留言結案
2. PR 已開 → 留言追蹤 PR
3. 處理中（SHOOT_FLAG 內容 = issue number）→ 留言進度
4. 排隊中（actionable + SHOOT_FLAG 存在）→ 留言排序
5. 等待回覆（`awaiting-reply` label）→ 留言等待對象
6. 未處理（default）→ 催促/提醒

**冪等規則**：同一狀態下，若上一則留言已是該狀態的自動留言，不重複留言。狀態轉換時（如「排隊中」→「處理中」），留一則新狀態留言。

**留言操作選擇規則（#409）**：每次巡邏前，先判斷 Issue 最後一則留言的作者是否為當前巡邏 bot。若是，則**編輯既有留言**追加本次巡邏資訊，而非發新留言（避免通知噪音）。只有在其他人於上次巡邏後回應過，才發新留言。

| 情境 | 操作 | 指令 |
|------|------|------|
| 最後留言作者 = 巡邏 bot 且狀態未變 | 編輯既有留言（PATCH） | `gh api -X PATCH repos/{owner}/{repo}/issues/comments/{comment_id} -f body="..."` |
| 最後留言作者 = 巡邏 bot 且狀態改變 | 編輯既有留言，更新狀態標題 | `gh api -X PATCH repos/{owner}/{repo}/issues/comments/{comment_id} -f body="..."` |
| 最後留言作者 ≠ 巡邏 bot（他人已回應） | 發新留言（POST） | `gh issue comment <issue_number> -R ${OWNER_REPO} --body "..."` |
| Issue 尚無任何留言 | 發新留言（POST） | `gh issue comment <issue_number> -R ${OWNER_REPO} --body "..."` |

```bash
# 留言操作邏輯（#409：編輯優先）
COMMENTS=$(gh issue view <issue_number> -R ${OWNER_REPO} --json comments -q '.comments')
LAST_COMMENT_AUTHOR=$(echo "$COMMENTS" | jq -r '.[-1].author.login // empty')
LAST_COMMENT_ID=$(echo "$COMMENTS" | jq -r '.[-1].databaseId // empty')
BOT_ACTOR="${GITHUB_ACTOR:-github-actions[bot]}"  # 巡邏 bot 的 login

PATROL_BODY="## [巡邏狀態：<狀態名稱>]

<對應語意的留言內容>

- 巡邏時間：$(date '+%Y-%m-%dT%H:%M:%S')
- Session: ${SESSION_ID}
- Cycle: ${CYCLE}"

if [[ -n "$LAST_COMMENT_ID" && "$LAST_COMMENT_AUTHOR" == "$BOT_ACTOR" ]]; then
  # 最後留言是自己的巡邏留言 → 編輯（不發新通知）
  gh api -X PATCH "repos/${OWNER_REPO}/issues/comments/${LAST_COMMENT_ID}" \
    -f body="${PATROL_BODY}"
else
  # 尚無留言，或他人已回應 → 發新留言
  gh issue comment <issue_number> -R ${OWNER_REPO} --body "${PATROL_BODY}"
fi
```

### 交付推進自動化（#338：per-repo delivery_chain）

**交付鏈深度**由 `delivery_chain` per-repo 設定控制（詳見 ADR-029）：

| `delivery_chain` 值 | 交付終點 |
|--------------------|---------|
| `production`（預設） | `staging → E2E → tag → production → close`（完整鏈） |
| `pr` | PR merge 即視為交付完成，直接 close Issue |
| `none` | 跳過交付追蹤，不推進交付步驟 |

PR merge 後若交付鏈卡住，自動推進下一步：

```bash
# 偽碼：PR merge → 自動推進交付鏈（per-repo delivery_chain）
SPRINT_FILE=$(ls ${REPO_PATH}/docs/sprints/sprint_*.md 2>/dev/null | sort -V | tail -1)
# 讀取 Sprint Backlog，找出狀態為「PR merged / 待部署」的 Story

# 取得此 repo 的 delivery_chain 設定（步驟 4.6 定義的 get_delivery_chain 函式）
REPO_DELIVERY_CHAIN=$(get_delivery_chain "${OWNER_REPO}")

if [[ "$REPO_DELIVERY_CHAIN" == "none" ]]; then
  # none → 跳過交付追蹤
  log: "skip delivery-chain for ${OWNER_REPO}：delivery_chain=none"
else:
  for each story in backlog:
    pr_status = gh pr view <pr_number> -R ${OWNER_REPO} --json merged,mergedAt,state
    if pr_status.merged == true:
      if [[ "$REPO_DELIVERY_CHAIN" == "pr" ]]; then
        # pr → PR merge 即完成，直接結案
        gh issue close <story.issue> -R ${OWNER_REPO} \
          --comment "## [交付完成] PR 已合併，delivery_chain=pr，結案。"
        log action: "delivery-close #<story.issue>（delivery_chain=pr）"
      else:  # production（預設）→ 完整交付鏈
        # 前置條件檢查（推進前檢查，避免跳步）
        # 1. staging：確認 PR merge 已完成 + CI 狀態為 passing
        # 2. E2E：確認 staging 部署成功
        # 3. tag：確認 E2E 通過
        # 4. production：確認 tag 建立
        # 5. close：確認 production 部署完成

        next_step = determine_next_delivery_step(story)
        if next_step and precondition_met(next_step):
          execute_delivery_step(next_step)
          log action: "push-delivery #<story.issue> → <next_step>"
        else:
          log: "skip push-delivery #<story.issue>：precondition not met for <next_step>"
```

### 交付追蹤

確認 in-sprint Story 進度：

```bash
# 搜尋當前 Sprint 的 Story
SPRINT_FILE=$(ls ${REPO_PATH}/docs/sprints/sprint_*.md 2>/dev/null | sort -V | tail -1)
# 讀取 Sprint Backlog，確認各 Story 狀態
# 對「進行中」超過預期天數的 Story 留言確認
```

### PO 巡邏結果格式

```json
{
  "session_id": "<SESSION_ID>",
  "cycle": <N>,
  "timestamp": "<ISO8601>",
  "type": "po-patrol",
  "repo": "<OWNER_REPO>",
  "strict": true,
  "threshold_days": <THRESHOLD_DAYS>,
  "project_level": "<PROJECT_LEVEL>",
  "summary": "掃描 <X> 個 open issues，發現 <Y> 個逾期，<Z> 個無回應",
  "actions": ["triage #<N1>", "auto-shoot #<N2>", "sprint-candidate #<N3>", "awaiting-reply #<N4>", "pending #<N5>", "close #<N6>", "close-pending-approval #<N7>", "auto-close #<N8>", "waiting #<N9>: Xh elapsed", "skipped #<N10>: stakeholder-issue"],
  "actionable_issues": [<issue_numbers>],
  "sprint_candidates": [<issue_numbers>]
}
```

> **嚴格模式備注**：`strict` 時 `"strict": true`，`threshold_days: 0`；預設模式 `"strict": false`，`threshold_days: 3`。

---

## 安全邊界

### Stakeholder Issue — 不自動行動

**判斷標準**：Issue 帶有 `stakeholder` label → 視為 Stakeholder Issue。

**行為規則**：

| 條件 | 行動 |
|------|------|
| Issue 有 `stakeholder` label | **只記錄**至 cruise log，不執行任何自動行動 |
| Issue 無 `stakeholder` label | 正常執行 PO Issue 處置決策表 |

**Log 格式**：

```json
{
  "actions": ["skipped #<N>: stakeholder-issue"]
}
```

即 `"skipped"` 欄位標注 `"stakeholder-issue"`，標示 Stakeholder Issue 已被掃描但跳過自動行動。

**設計理由**：Stakeholder Issue 涉及外部關係，由 PO 人工判斷後介入，避免自動行動造成不當回覆或影響關係管理。

---

## SRE 巡檢指引（AC-2）

**觸發**：每個 cruise cycle 由 Task tool 派遣 SRE Agent 執行
**Repo context**：subagent 接收 `REPO_PATH` 與 `OWNER_REPO` 參數，所有 `gh` 指令加 `-R ${OWNER_REPO}`

### cruise-feedback label 標註規則（#339）

SRE 建立 Issue 時，若判斷問題**屬於框架層級**（非 repo 特定，而是 Cruise Skill 本身的限制或設計缺陷），在 `--label` 參數中加入 `cruise-feedback`。

判斷依據：

| 情境 | 加 `cruise-feedback`？ | 說明 |
|------|----------------------|------|
| Cruise Skill 行為有缺陷（如 routing 邏輯錯誤） | 是 | 屬於框架層級，需回報 kctw-dev/shikigami |
| 某 repo CI 設定問題 | 否 | Repo 特定問題，不屬框架層級 |
| 某 runner offline | 否 | 基礎設施問題，非 Cruise Skill 問題 |
| Cruise 對某類 Issue 誤判（如誤標 sprint-candidate） | 是 | 屬於框架層級判斷邏輯問題 |

加上 `cruise-feedback` label 後，PO 巡邏在下一個 cycle 會透過 Feedback Routing 機制（Step 1.5）自動轉送或留言確認。

### CI/CD 狀態檢查

```bash
# 列出最近 10 筆 GitHub Actions run
gh run list -R ${OWNER_REPO} --limit 10 --json status,conclusion,name,databaseId,createdAt
# 篩選 failure / cancelled
FAILED_RUNS=$(gh run list -R ${OWNER_REPO} --limit 10 --json status,conclusion,name,databaseId \
  | jq '[.[] | select(.conclusion == "failure" or .conclusion == "cancelled")]')
```

### Runner 健康檢查

> **前置條件**：查詢 org-level runner 需要 `admin:org` scope（`gh auth refresh -s admin:org`）。若缺少此 scope 將自動 fallback 至 repo-level。

```bash
# Step 1：偵測 owner 類型（org vs user）
# OWNER_REPO 由主 loop 帶入（如 "KCTW/shikigami"）
OWNER=$(echo "${OWNER_REPO}" | cut -d'/' -f1)
REPO=$(echo "${OWNER_REPO}" | cut -d'/' -f2)
OWNER_TYPE=$(gh api /orgs/${OWNER} --jq '.type' 2>/dev/null || echo "User")

if [[ "$OWNER_TYPE" == "User" ]]; then
  # 個人帳號 repo — 直接走 repo-level，不嘗試 org API
  echo "[SRE] owner 為 User，使用 repo-level runner API"
  gh api /repos/${OWNER}/${REPO}/actions/runners --jq '.runners[] | {name, status, busy}' 2>/dev/null || true
else
  # Step 2：org-level API 優先（需 admin:org scope）
  RUNNERS=$(gh api /orgs/${OWNER}/actions/runners --jq '.runners[] | {name, status, busy}' 2>/dev/null)
  ORG_EXIT=$?

  if [[ $ORG_EXIT -ne 0 ]]; then
    # Step 3：fallback 至 repo-level（403 或 404）
    echo "[SRE] org-level API 不可用，fallback 至 repo-level（可能缺少 admin:org scope）"
    gh api /repos/${OWNER}/${REPO}/actions/runners --jq '.runners[] | {name, status, busy}' 2>/dev/null || true
  else
    echo "$RUNNERS"
  fi
fi
```

### VM 數量變化查證

> 發現 GCP VM 數量與上次巡檢不同時，必須查證原因，**禁止推測**。

```bash
# 前置判斷：確認 gcloud 可用
if ! gcloud version 2>/dev/null; then
  echo "[SRE] gcloud 不可用，跳過 MIG 查證"
  # 不阻塞後續流程，直接跳過
else
  # 查詢 MIG autoscaler 狀態（MIG_NAME 由環境變數或 SRE config 帶入）
  MIG_INFO=$(gcloud compute instance-groups managed describe "${MIG_NAME}" \
    --format="yaml(autoscaler.recommendedSize,targetSize)" 2>/dev/null)

  if [[ $? -ne 0 ]]; then
    echo "[SRE] gcloud 不可用，跳過 MIG 查證"
  else
    RECOMMENDED_SIZE=$(echo "$MIG_INFO" | grep 'recommendedSize' | awk '{print $2}')
    TARGET_SIZE=$(echo "$MIG_INFO" | grep 'targetSize' | awk '{print $2}')
    PREVIOUS_VM_COUNT="${PREVIOUS_VM_COUNT:-$TARGET_SIZE}"  # fallback 至 targetSize

    if [[ "$RECOMMENDED_SIZE" -lt "$PREVIOUS_VM_COUNT" ]]; then
      # autoscaler 主動縮減 — 正常行為
      echo "[SRE] VM 數量變化原因：autoscaler 縮減（正常）recommendedSize=${RECOMMENDED_SIZE} < 之前=${PREVIOUS_VM_COUNT}"
      VM_HEALTH_STATUS="autoscaler-scale-in"
      VM_HEALTH_NOTE="autoscaler 縮減（正常）：recommendedSize=${RECOMMENDED_SIZE}，之前 VM 數=${PREVIOUS_VM_COUNT}"
    elif [[ "$RECOMMENDED_SIZE" -eq "$PREVIOUS_VM_COUNT" ]]; then
      # recommendedSize 未變但 VM 少了 — SPOT 回收或故障（異常）
      echo "[SRE] VM 數量變化原因：SPOT 回收或故障（異常）recommendedSize=${RECOMMENDED_SIZE} = 之前=${PREVIOUS_VM_COUNT}，但 VM 實際減少"
      VM_HEALTH_STATUS="spot-preemption-or-failure"
      VM_HEALTH_NOTE="SPOT 回收或故障（異常）：recommendedSize=${RECOMMENDED_SIZE}，之前 VM 數=${PREVIOUS_VM_COUNT}，實際 VM 數減少"
      # 建立 Issue（異常情況）
      ISSUE_TITLE="[SRE] VM 異常減少：${MIG_NAME}"
      EXISTING=$(gh issue list -R ${OWNER_REPO} \
        --search "\"${ISSUE_TITLE}\"" \
        --state all \
        --json number,title \
        2>/dev/null || echo "[]")
      if echo "$EXISTING" | jq -e '. | length > 0' &>/dev/null; then
        echo "[SRE] 跳過重複 Issue：$ISSUE_TITLE"
        log action: "跳過重複 Issue: ${ISSUE_TITLE}"
      else
        gh issue create -R ${OWNER_REPO} \
          --title "$ISSUE_TITLE" \
          --body "## SRE 巡檢發現 VM 異常減少

**發現時間**：$(date '+%Y-%m-%dT%H:%M:%S')
**Session**：${SESSION_ID}
**MIG**：${MIG_NAME}
**recommendedSize**：${RECOMMENDED_SIZE}
**之前 VM 數**：${PREVIOUS_VM_COUNT}

### 判斷依據
- recommendedSize = 之前 VM 數 → autoscaler 未主動縮減
- 但實際 VM 數減少 → 推測為 SPOT 回收或 VM 故障

### 建議排查
1. 確認 GCP Console MIG 事件記錄（preemption / health check fail）
2. 確認 SPOT VM 回收通知
3. 執行 \`/systematic-debugging\` 進行系統性排查

> 此 Issue 由 SRE Cruise Agent 自動建立。請勿重複建立。" \
          --label "sre,vm-anomaly,needs-triage"
        log action: "create-issue-vm-anomaly #<new_issue_number>"
      fi
    fi
  fi
fi
```

**VM 查證結論分類**：

| 情況 | 判斷條件 | 結論 | 行動 |
|------|----------|------|------|
| autoscaler 縮減 | `recommendedSize < 之前 VM 數` | 正常（autoscaler scale-in） | 記錄，不建 Issue |
| SPOT 回收或故障 | `recommendedSize = 之前 VM 數` 但 VM 實際減少 | 異常 | 記錄 + 建 Issue |
| gcloud 不可用 | `gcloud version` 失敗 | 跳過（不阻塞） | 記錄 `[SRE] gcloud 不可用，跳過 MIG 查證` |

### Warnings 掃描

```bash
# 掃描最近 commit 的 CI logs 是否有 WARNING
gh run view <run_id> -R ${OWNER_REPO} --log 2>/dev/null | grep -i 'warning\|WARN\|deprecated' | head -20
```

### 自動行動決策表（SRE）

**發現即處理**：SRE 巡檢發現問題時自動建立 Issue + 附加指引，不在 cruise loop 內同步執行修復（保持 cruise 輕量、松耦合）。

| 情境 | 判斷條件 | 自動行動 | label | log action 類型 |
|------|----------|----------|-------|-----------------|
| **CI failure** | CI run 結果為 failure / cancelled | 建 Issue + body 含 `/systematic-debugging` 指引 | `sre,sre-auto-debug,needs-triage` | `"create-issue-with-debug"` |
| **Deploy failure** | deploy job 失敗（conclusion=failure，job name 含 deploy） | 建 Issue + body 含 @mention PO | `sre,deploy-failure,needs-triage` | `"create-issue-deploy"` |
| **Runner offline** | runner status=offline（repo-level fallback） | 建 Issue | `sre,runner-offline,needs-triage` | `"create-issue-runner"` |
| **VM 異常減少** | `recommendedSize = 之前 VM 數` 但 VM 實際減少 | 建 Issue + 記錄原因 + 證據 | `sre,vm-anomaly,needs-triage` | `"create-issue-vm-anomaly"` |

### CI failure → Issue + /systematic-debugging 指引

```bash
# Issue 重複防護：建 Issue 前先搜尋（跨機器冪等）
ISSUE_TITLE="[SRE] CI failure: ${RUN_NAME}"
EXISTING=$(gh issue list -R ${OWNER_REPO} \
  --search "\"${ISSUE_TITLE}\"" \
  --state all \
  --json number,title \
  2>/dev/null || echo "[]")

if echo "$EXISTING" | jq -e '. | length > 0' &>/dev/null; then
  echo "[SRE] 跳過重複 Issue：$ISSUE_TITLE"
  log action: "跳過重複 Issue: ${ISSUE_TITLE}"
else
  gh issue create -R ${OWNER_REPO} \
    --title "$ISSUE_TITLE" \
    --body "## SRE 巡檢發現 CI failure

**發現時間**：$(date '+%Y-%m-%dT%H:%M:%S')
**Session**：${SESSION_ID}
**Repo**：${OWNER_REPO}
**問題描述**：CI pipeline 執行失敗

### 詳情
- Run ID: ${RUN_ID}
- Run Name: ${RUN_NAME}
- 狀態: failure

### 建議排查
執行 \`/systematic-debugging\` 進行系統性排查。

> 此 Issue 由 SRE Cruise Agent 自動建立（松耦合 — 不在 cruise loop 內同步執行 debugging）。請勿重複建立。" \
    --label "sre,sre-auto-debug,needs-triage"
  log action: "create-issue-with-debug #<new_issue_number>"
fi
```

### Deploy failure → Issue + 通知 PO

```bash
# deploy failure：偵測 job name 含 deploy 且 conclusion=failure
DEPLOY_FAILED_RUNS=$(gh run list -R ${OWNER_REPO} --limit 10 --json status,conclusion,name,databaseId \
  | jq '[.[] | select(.conclusion == "failure") | select(.name | test("deploy"; "i"))]')

for run in $(echo "$DEPLOY_FAILED_RUNS" | jq -r '.[].databaseId'); do
  RUN_INFO=$(gh run view "$run" -R ${OWNER_REPO} --json name,databaseId,createdAt)
  RUN_NAME=$(echo "$RUN_INFO" | jq -r '.name')
  ISSUE_TITLE="[SRE] Deploy failure: ${RUN_NAME}"

  # Issue 重複防護：建立前搜尋（EXISTING deploy）
  EXISTING=$(gh issue list -R ${OWNER_REPO} \
    --search "\"${ISSUE_TITLE}\"" \
    --state all \
    --json number,title \
    2>/dev/null || echo "[]")

  if echo "$EXISTING" | jq -e '. | length > 0' &>/dev/null; then
    echo "[SRE] 跳過重複 Issue：$ISSUE_TITLE"
    log action: "跳過重複 Issue: ${ISSUE_TITLE}"
  else
    # PO_MENTION：從 CODEOWNERS 或 team 設定讀取，預設 @po
    PO_MENTION="${PO_GITHUB_LOGIN:-@po}"
    gh issue create -R ${OWNER_REPO} \
      --title "$ISSUE_TITLE" \
      --body "## SRE 巡檢發現 Deploy failure

**發現時間**：$(date '+%Y-%m-%dT%H:%M:%S')
**Session**：${SESSION_ID}
**Repo**：${OWNER_REPO}
**問題描述**：Deploy pipeline 執行失敗，需 PO 確認

### 詳情
- Run ID: ${RUN_ID}
- Run Name: ${RUN_NAME}
- 狀態: failure

### 通知
${PO_MENTION} 請確認此次部署失敗情況並決定後續行動。

> 此 Issue 由 SRE Cruise Agent 自動建立。請勿重複建立。" \
      --label "sre,deploy-failure,needs-triage"
    log action: "create-issue-deploy #<new_issue_number>"
  fi
done
```

### Runner offline → Issue

```bash
# runner offline：偵測 runner status=offline
OFFLINE_RUNNERS=$(echo "$RUNNERS" | jq '[.[] | select(.status == "offline")] // []')

for runner_name in $(echo "$OFFLINE_RUNNERS" | jq -r '.[].name'); do
  ISSUE_TITLE="[SRE] Runner offline: ${runner_name}"

  # Issue 重複防護：建立前搜尋（EXISTING runner）
  EXISTING=$(gh issue list -R ${OWNER_REPO} \
    --search "\"${ISSUE_TITLE}\"" \
    --state all \
    --json number,title \
    2>/dev/null || echo "[]")

  if echo "$EXISTING" | jq -e '. | length > 0' &>/dev/null; then
    echo "[SRE] 跳過重複 Issue：$ISSUE_TITLE"
    log action: "跳過重複 Issue: ${ISSUE_TITLE}"
  else
    gh issue create -R ${OWNER_REPO} \
      --title "$ISSUE_TITLE" \
      --body "## SRE 巡檢發現 Runner offline

**發現時間**：$(date '+%Y-%m-%dT%H:%M:%S')
**Session**：${SESSION_ID}
**Repo**：${OWNER_REPO}
**Runner 名稱**：${runner_name}

### 建議處理
請確認 runner 狀態並重新啟動（已有權限防護：repo-level fallback）。

> 此 Issue 由 SRE Cruise Agent 自動建立。請勿重複建立。" \
      --label "sre,runner-offline,needs-triage"
    log action: "create-issue-runner #<new_issue_number>"
  fi
done
```

### 跨機器冪等性（所有 Issue 類型）

多台機器同時執行 cruise 時，可能同時發現同一 failure。每種 Issue 類型在建立前均執行 `gh issue list -R ${OWNER_REPO} --search` 搜尋，確保同一問題只建一個 Issue：

- CI failure：`EXISTING` 搜尋防護 → 已存在則跳過
- Deploy failure：`EXISTING` 搜尋防護 → 已存在則跳過
- Runner offline：`EXISTING` 搜尋防護 → 已存在則跳過

**設計理由**：多 runner 同時發現同一 failure，因 GitHub Issue search 存在毫秒級競態，實務上極罕見建立重複；search 防護為主要冪等機制，已覆蓋所有新 Issue 類型。

### SRE 巡檢結果格式

```json
{
  "session_id": "<SESSION_ID>",
  "cycle": <N>,
  "timestamp": "<ISO8601>",
  "type": "sre-inspection",
  "repo": "<OWNER_REPO>",
  "summary": "檢查 <X> 筆 CI run，發現 <Y> 個 failure，建立 <Z> 個 Issue",
  "vm_health": {
    "status": "autoscaler-scale-in | spot-preemption-or-failure | no-change | skipped",
    "note": "<原因說明 + 證據>",
    "previous_vm_count": <N>,
    "current_vm_count": <N>,
    "recommended_size": <N>
  },
  "actions": ["create-issue-with-debug #<N1>", "create-issue-deploy #<N2>", "create-issue-runner #<N3>", "create-issue-vm-anomaly #<N4>", "跳過重複 Issue: <title>"]
}
```

**SRE 巡檢 actions 行動類型說明**：

| 類型 | 說明 |
|------|------|
| `"create-issue-with-debug"` | CI failure 建 Issue + `/systematic-debugging` 指引（松耦合，不同步 debug） |
| `"create-issue-deploy"` | Deploy failure 建 Issue + @mention PO |
| `"create-issue-runner"` | Runner offline 建 Issue |
| `"create-issue-vm-anomaly"` | VM 異常減少（SPOT 回收或故障）建 Issue + 原因 + 證據 |

**vm_health.status 說明**：

| 值 | 說明 |
|---|------|
| `"autoscaler-scale-in"` | autoscaler 主動縮減（正常），`recommendedSize < 之前 VM 數` |
| `"spot-preemption-or-failure"` | SPOT 回收或 VM 故障（異常），`recommendedSize = 之前 VM 數` 但 VM 減少 |
| `"no-change"` | VM 數量無變化，跳過查證 |
| `"skipped"` | gcloud 不可用，跳過 MIG 查證（`[SRE] gcloud 不可用，跳過 MIG 查證`） |

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

**PO 巡邏 actions 行動類型說明**（#343）：

| 類型 | 說明 |
|------|------|
| `"triage"` | 無 label Issue，PO 自主加分類 label |
| `"cruise-feedback-routed"` | 帶 `cruise-feedback` label 的 Issue，自動轉送建 Issue 至目標 repo（project_level=low）（#339） |
| `"cruise-feedback-pending-confirm"` | 帶 `cruise-feedback` label 的 Issue，留言確認後等人轉送（project_level=medium/high）（#339） |
| `"cruise-feedback-skip"` | 帶 `cruise-feedback` label 的 Issue，目標 repo 已有相同 Issue，跳過重複建立（#339） |
| `"auto-shoot"` | Size=S Issue 標記為 actionable，供主 loop 連續派工 |
| `"sprint-candidate"` | Size=M+ Issue，加 `sprint-candidate` label |
| `"awaiting-reply"` | 缺資訊，加 `awaiting-reply` label + 留言 |
| `"pending"` | 暫停，加 `pending` label + 留言 |
| `"close"` | 已修復未關，結案 |
| `"auto-close"` | `awaiting-reply`/`pending` 超過 2h 未回應，自動關閉（AC-4） |
| `"waiting"` | `awaiting-reply`/`pending` 未超時，維持等待（AC-1 全覆蓋） |
| `"skipped"` | Stakeholder Issue 跳過（含 reason） |

**主 loop 寫入的 log entry 類型**（#343 修正 #340）：

| 類型 | 說明 |
|------|------|
| `"auto-shoot-completed"` | shoot 完成，含 result（success/failed） |
| `"auto-shoot-escalated"` | 同一 Issue 連續 2 次 shoot fail，升級為 sprint-candidate（AC-5） |
| `"auto-shoot-stale-cleared"` | SHOOT_FLAG 殘留超過 30 分鐘，強制清除 |
| `"trigger-sprint-planning"` | sprint-candidate ≥ 3 或 1 個超過 30min，觸發 Sprint Planning（AC-3） |
