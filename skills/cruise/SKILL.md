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
/cruise              — 啟動巡航（預設間隔 30 分鐘）
/cruise 10m          — 啟動巡航，指定間隔（例：10m, 15m, 60m）
/cruise strict     — 嚴格模式（0 天閾值，無回應立即標記）
/cruise 10m strict — 自訂間隔 + 嚴格模式
/cruise strict 10m — 同上（flag 位置無關）
/cruise stop         — 停止巡航
```

## 概覽

Cruise Mode 在當前 Session 內持續執行 PO 巡邏與 SRE 巡檢，每隔指定間隔自動觸發一次，直到收到 `/cruise stop` 或 Session 結束為止。

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
# 解析 strict flag 與間隔（位置無關）
STRICT_MODE=false
INTERVAL="30m"
for ARG in "$@"; do
  if [[ "$ARG" == "strict" ]]; then
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

# 轉換間隔為秒數
INTERVAL_SECONDS=$(echo "$INTERVAL" | sed 's/m$//' | awk '{print $1 * 60}')
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
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
CRUISE_FLAG="/tmp/shikigami-cruise-${SESSION_ID}.active"
touch "$CRUISE_FLAG"
echo "[CRUISE] 巡航模式已啟動（Session: ${SESSION_ID}，間隔: ${INTERVAL}）"
echo "[CRUISE] Flag file: $CRUISE_FLAG"
echo "[CRUISE] 停止指令：/cruise stop"
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

### 6. 進入 Loop

每個 cycle 對**每個 repo** 分別執行 PO 巡邏 + SRE 巡檢（平行派遣），完成後由主 loop 彙整寫 log，然後 sleep。

```
while 檢查 flag file 存在:
  CYCLE += 1
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

### 自動行動決策表

**發現即處理**：PO 巡邏不再只回報，針對 4 種情境直接採取行動。

**安全前置檢查**（每個 Issue 行動前必先執行）：
- 若 Issue 帶有 `stakeholder` label → 跳過所有行動，記錄 `"skipped": "stakeholder-issue"` 至 cruise log
- 詳見下方「安全邊界」段落

| 情境 | 判斷條件 | 自動行動 | log action 類型 |
|------|----------|----------|-----------------|
| **新回覆 — 需排入 Backlog** | Issue 有新回覆 + 內容涉及新需求 / 問題回報 | invoke `backlog-management`，將需求排入 Backlog | `"reply"` |
| **新回覆 — 內部 Issue 直接回覆** | Issue 有新回覆 + 屬於內部 Issue（無外部 stakeholder 參與）+ 可直接回應 | `gh issue comment` 直接回覆 | `"reply"` |
| **無 label — 自動 Triage** | Issue 無任何 label（`labels` 為空陣列）| invoke `issue-management` triage；已有 label 的 Issue 不重複 triage（triage 冪等）| `"triage"` |
| **awaiting-reply 超時 — 催促** | Issue 帶有 `awaiting-reply` label + 最後一則留言超過 24h | 自動留言催促；每 Issue 每天最多 1 次（催促冪等）| `"nudge"` |

**情境 3 詳細邏輯（無 label 自動 Triage）**：

```bash
# 偽碼：無 label Issue → 觸發 issue-management triage（冪等）
for each issue in issues:
  if issue.labels is empty:           # 無 label → 需要 triage
    # triage 冪等：避免重複觸發
    invoke issue-management skill with action=triage, issue_number=issue.number
    log action: "triage #<issue.number>"
  # else: 已有 label，labels exist → skip triage，label.*exist.*skip.*triage 防護
```

**情境 4 詳細邏輯（awaiting-reply 超時催促）**：

```bash
# 偽碼：awaiting-reply 超時 → 催促（冪等，24h 上限）
for each issue in issues:
  if "awaiting-reply" in issue.labels:
    comment_data = gh issue view issue.number -R ${OWNER_REPO} --json comments
    last_comment = comment_data.comments[-1]   # 最後一則留言
    hours_since_last = (now - last_comment.createdAt) in hours

    # 冪等：最後一則留言若已是自動催促留言 → 重複催促跳過
    if "[自動催促]" in last_comment.body:
      skip  # 已是自動催促，不重複

    # 頻率上限：每 Issue 每天最多催 1 次（最多 1 次，每 24h 重置）
    if hours_since_last >= 24:
      gh issue comment <issue.number> -R ${OWNER_REPO} --body "## [自動催促]

此 Issue 標記為 awaiting-reply，超過 24h 未收到回覆，請確認狀態。

- 催促時間：$(date '+%Y-%m-%dT%H:%M:%S')
- Session: ${SESSION_ID}"
      log action: "nudge #<issue.number>"
```

### 留言追蹤

對逾期或無回應的 Issue 留言提醒：

```bash
# 對逾期 Issue 留言
gh issue comment <issue_number> -R ${OWNER_REPO} --body "## 巡邏留言（自動）

此 Issue 已逾期未更新，請相關負責人確認狀態。

- 巡邏時間：$(date '+%Y-%m-%dT%H:%M:%S')
- Session: ${SESSION_ID}"
```

### 交付推進自動化

**交付鏈**：`staging → E2E → tag → production → close`

PR merge 後若交付鏈卡住，自動推進下一步：

```bash
# 偽碼：PR merge → 自動推進交付鏈
SPRINT_FILE=$(ls ${REPO_PATH}/docs/sprints/sprint_*.md 2>/dev/null | sort -V | tail -1)
# 讀取 Sprint Backlog，找出狀態為「PR merged / 待部署」的 Story

for each story in backlog:
  pr_status = gh pr view <pr_number> -R ${OWNER_REPO} --json merged,mergedAt,state
  if pr_status.merged == true:
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
  "summary": "掃描 <X> 個 open issues，發現 <Y> 個逾期，<Z> 個無回應",
  "actions": ["reply #<N1>", "triage #<N2>", "nudge #<N3>", "push-delivery #<N4> → staging", "skipped #<N5>: stakeholder-issue"]
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
| Issue 無 `stakeholder` label | 正常執行自動行動決策表 |

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
  "actions": ["create-issue-with-debug #<N1>", "create-issue-deploy #<N2>", "create-issue-runner #<N3>", "跳過重複 Issue: <title>"]
}
```

**SRE 巡檢 actions 行動類型說明**：

| 類型 | 說明 |
|------|------|
| `"create-issue-with-debug"` | CI failure 建 Issue + `/systematic-debugging` 指引（松耦合，不同步 debug） |
| `"create-issue-deploy"` | Deploy failure 建 Issue + @mention PO |
| `"create-issue-runner"` | Runner offline 建 Issue |

---

## Stop 機制

### /cruise stop 指令

```bash
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
CRUISE_FLAG="/tmp/shikigami-cruise-${SESSION_ID}.active"

if [[ -f "$CRUISE_FLAG" ]]; then
  rm -f "$CRUISE_FLAG"
  echo "[CRUISE] 巡航模式停止指令已送出，loop 將在當前 cycle 完成後退出"
else
  echo "[CRUISE] 巡航模式未啟動（flag file 不存在）"
fi
```

### SessionEnd Hook 自動清理

`hooks/session-end-release.sh` 在 Session 結束時自動清除 cruise flag file，確保無殘留：

```bash
CRUISE_FLAG="/tmp/shikigami-cruise-${SESSION_ID}.active"
rm -f "$CRUISE_FLAG" 2>/dev/null || true
echo "[CRUISE] SessionEnd cleanup: cruise flag file 已清除"
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
- Log 以 SESSION_ID 命名（per-session JSONL）
- Issue 重複防護確保同一問題不會被多個 Session 重複建立（覆蓋所有新 Issue 類型：CI failure / deploy failure / runner offline）
- 多 runner 同時發現同一 failure → 只建一個 Issue（search 防護，冪等性覆蓋所有新 Issue 類型）
- **多 repo 場景**：同一 session 巡邏多個 repo，Issue 重複防護已含 `-R` 指定 repo，跨 repo 不會誤判重複

---

## Log 格式完整範例

**單一 repo 模式**（`"repo"` 欄位仍存在，值為該 repo 的 owner/repo）：

```jsonl
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:00+0800","type":"po-patrol","repo":"KCTW/shikigami","strict":false,"threshold_days":3,"summary":"掃描 15 個 open issues，發現 2 個逾期，1 個無回應","actions":["reply #301","triage #310","nudge #312"]}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:05+0800","type":"sre-inspection","repo":"KCTW/shikigami","summary":"檢查 10 筆 CI run，發現 1 個 CI failure，建立 1 個 Issue","actions":["create-issue-with-debug #321"]}
```

**多 repo 模式**（每個 repo 各一筆 log entry）：

```jsonl
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:00+0800","type":"po-patrol","repo":"KCTW/shikigami","strict":false,"threshold_days":3,"summary":"掃描 15 個 open issues，發現 2 個逾期","actions":["reply #301","triage #310"]}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:02+0800","type":"sre-inspection","repo":"KCTW/shikigami","summary":"檢查 10 筆 CI run，無異常","actions":[]}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:04+0800","type":"po-patrol","repo":"KCTW/project-x","strict":false,"threshold_days":3,"summary":"掃描 8 個 open issues，無異常","actions":[]}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:06+0800","type":"sre-inspection","repo":"KCTW/project-x","summary":"檢查 5 筆 CI run，發現 1 個 failure","actions":["create-issue-with-debug #45"]}
```

**PO 巡邏 actions 行動類型說明**：

| 類型 | 說明 |
|------|------|
| `"reply"` | 新回覆判斷後執行（排入 Backlog 或直接回覆） |
| `"triage"` | 無 label Issue 觸發 issue-management triage |
| `"nudge"` | awaiting-reply 超時自動催促 |
| `"push-delivery"` | PR merge 後推進交付鏈下一步 |
| `"skipped"` | Stakeholder Issue 跳過自動行動（含 reason） |
