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
/cruise           — 啟動巡航（預設間隔 30 分鐘）
/cruise 10m       — 啟動巡航，指定間隔（例：10m, 15m, 60m）
/cruise stop      — 停止巡航
```

## 概覽

Cruise Mode 在當前 Session 內持續執行 PO 巡邏與 SRE 巡檢，每隔指定間隔自動觸發一次，直到收到 `/cruise stop` 或 Session 結束為止。

**參與 Agent**：PO Agent（巡邏）、SRE Agent（巡檢）
**執行模式**：Session 內 loop（sleep + flag file），參見 ADR-026
**Log**：per-session JSONL（`docs/cruise-logs/YYYY-MM-DD-session-<SESSION_ID>.jsonl`）

---

## 啟動流程

### 1. 解析參數

```bash
# 解析間隔（預設 30m）
INTERVAL="${1:-30m}"
# 轉換為秒數
INTERVAL_SECONDS=$(echo "$INTERVAL" | sed 's/m$//' | awk '{print $1 * 60}')
```

### 2. 建立 Flag File

```bash
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
CRUISE_FLAG="/tmp/shikigami-cruise-${SESSION_ID}.active"
touch "$CRUISE_FLAG"
echo "[CRUISE] 巡航模式已啟動（Session: ${SESSION_ID}，間隔: ${INTERVAL}）"
echo "[CRUISE] Flag file: $CRUISE_FLAG"
echo "[CRUISE] 停止指令：/cruise stop"
```

### 3. 準備 Log 目錄

```bash
LOG_DIR="docs/cruise-logs"
mkdir -p "$LOG_DIR"
LOG_TODAY=$(date '+%Y-%m-%d')
CRUISE_LOG="${LOG_DIR}/${LOG_TODAY}-session-${SESSION_ID}.jsonl"
CYCLE=0
```

### 4. 進入 Loop

每個 cycle 執行：PO 巡邏 + SRE 巡檢（平行派遣），完成後寫 log，然後 sleep。

```
while 檢查 flag file 存在:
  CYCLE += 1
  平行派遣 PO-patrol 與 SRE-inspection（Task tool）
  等待兩個 task 完成
  彙整結果寫入 CRUISE_LOG（JSONL append）
  echo "[CRUISE] Cycle ${CYCLE} 完成，下次執行：${INTERVAL} 後"
  sleep ${INTERVAL_SECONDS}
  if flag file 不存在: break
echo "[CRUISE] 巡航模式已停止"
```

---

## PO 巡邏指引（AC-1）

**觸發**：每個 cruise cycle 由 Task tool 派遣 PO Agent 執行

### 掃描 Open Issues

```bash
# 列出所有 open issues（含 comments 欄位）
gh issue list --state open --limit 50 --json number,title,labels,assignees,updatedAt,comments
```

掃描重點：
- 逾期 Issue（`updatedAt` 超過 7 天未更新且無 assignee）
- 無回應 Issue（已開超過 3 天**且無任何留言**且無 assignee）
- 標記為 `blocked` 或 `needs-triage` 的 Issue

### 留言掃描步驟

對 `comments > 0` 的 Issue，讀取實際留言內容：

```bash
# 讀取有留言的 Issue 完整留言
gh issue view <issue_number> --json comments
```

**「無回應」判斷標準**（#320 教訓）：

Issue 同時滿足以下條件才視為「無回應」：
1. 無 assignee（`assignees` 為空陣列）
2. 最近 3 天內無任何留言（不論留言者是誰）

```bash
# 判斷邏輯（偽碼）
for each issue in issues:
  has_assignee = issue.assignees.length > 0
  comment_data = gh issue view issue.number --json comments
  latest_comment_at = comment_data.comments[-1].createdAt  # 若有留言
  days_since_comment = (now - latest_comment_at) in days

  if not has_assignee and (no comments OR days_since_comment > 3):
    mark as "無回應"

  # Stakeholder 留言優先標記
  for comment in comment_data.comments:
    if "[PRIORITY]" in comment.body:
      mark issue as "PRIORITY"
      alert PO immediately
```

### 留言追蹤

對逾期或無回應的 Issue 留言提醒：

```bash
# 對逾期 Issue 留言
gh issue comment <issue_number> --body "## 巡邏留言（自動）

此 Issue 已逾期未更新，請相關負責人確認狀態。

- 巡邏時間：$(date '+%Y-%m-%dT%H:%M:%S')
- Session: ${SESSION_ID}"
```

### 交付追蹤

確認 in-sprint Story 進度：

```bash
# 搜尋當前 Sprint 的 Story
SPRINT_FILE=$(ls docs/sprints/sprint_*.md 2>/dev/null | sort -V | tail -1)
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
  "summary": "掃描 <X> 個 open issues，發現 <Y> 個逾期，<Z> 個無回應",
  "actions": ["留言 #<N1>", "留言 #<N2>"]
}
```

---

## SRE 巡檢指引（AC-2）

**觸發**：每個 cruise cycle 由 Task tool 派遣 SRE Agent 執行

### CI/CD 狀態檢查

```bash
# 列出最近 10 筆 GitHub Actions run
gh run list --limit 10 --json status,conclusion,name,databaseId,createdAt
# 篩選 failure / cancelled
FAILED_RUNS=$(gh run list --limit 10 --json status,conclusion,name,databaseId \
  | jq '[.[] | select(.conclusion == "failure" or .conclusion == "cancelled")]')
```

### Runner 健康檢查

```bash
# 列出 self-hosted runner 狀態（若有）
gh api /repos/{owner}/{repo}/actions/runners --jq '.runners[] | {name, status, busy}'
```

### Warnings 掃描

```bash
# 掃描最近 commit 的 CI logs 是否有 WARNING
gh run view <run_id> --log 2>/dev/null | grep -i 'warning\|WARN\|deprecated' | head -20
```

### 建立 Issue（不修）

SRE 發現問題時只建 Issue，不自行修復：

```bash
# Issue 重複防護：建 Issue 前先搜尋
ISSUE_TITLE="[SRE] CI/CD failure: ${RUN_NAME}"
EXISTING=$(gh issue list --search "$ISSUE_TITLE" --state all --json number,title 2>/dev/null)
if [[ -z "$EXISTING" || "$EXISTING" == "[]" ]]; then
  gh issue create \
    --title "$ISSUE_TITLE" \
    --body "## SRE 巡檢發現問題

**發現時間**：$(date '+%Y-%m-%dT%H:%M:%S')
**Session**：${SESSION_ID}
**問題描述**：CI/CD pipeline 執行失敗

### 詳情
- Run ID: ${RUN_ID}
- Run Name: ${RUN_NAME}
- 狀態: failure

### 建議處理
請相關工程師確認並修復。

> 此 Issue 由 SRE Cruise Agent 自動建立，請勿重複建立。" \
    --label "sre,needs-triage"
else
  echo "[SRE] Issue 已存在，跳過建立：$ISSUE_TITLE"
fi
```

### SRE 巡檢結果格式

```json
{
  "session_id": "<SESSION_ID>",
  "cycle": <N>,
  "timestamp": "<ISO8601>",
  "type": "sre-inspection",
  "summary": "檢查 <X> 筆 CI run，發現 <Y> 個 failure，建立 <Z> 個 Issue",
  "actions": ["建立 Issue #<N1>", "跳過重複 Issue: <title>"]
}
```

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

```
docs/cruise-logs/
├── 2026-03-21-session-abc123.jsonl   ← Session A 的 log
├── 2026-03-21-session-def456.jsonl   ← Session B 的 log（同一天）
└── 2026-03-22-session-ghi789.jsonl   ← 另一天的 log
```

### Issue 重複防護

SRE 建立 Issue 前必須執行 `gh issue list --search` 搜尋：

```bash
# 搜尋包含 issue_title 的所有 Issue（含已關閉）
EXISTING=$(gh issue list \
  --search "\"${ISSUE_TITLE}\"" \
  --state all \
  --json number,title \
  2>/dev/null || echo "[]")

if echo "$EXISTING" | jq -e '. | length > 0' &>/dev/null; then
  echo "[SRE] 跳過重複 Issue：$ISSUE_TITLE"
else
  gh issue create ...
fi
```

### 多 Session 同時 Cruise

- 每個 Session 各自獨立執行 loop，互不干擾
- Flag file 以 SESSION_ID 命名（`/tmp/shikigami-cruise-<SESSION_ID>.active`）
- Log 以 SESSION_ID 命名（per-session JSONL）
- Issue 重複防護確保同一問題不會被多個 Session 重複建立

---

## Log 格式完整範例

```jsonl
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:00+0800","type":"po-patrol","summary":"掃描 15 個 open issues，發現 2 個逾期，1 個無回應","actions":["留言 #301","留言 #305"]}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:05+0800","type":"sre-inspection","summary":"檢查 10 筆 CI run，發現 1 個 failure，建立 1 個 Issue","actions":["建立 Issue #321"]}
{"session_id":"abc123","cycle":2,"timestamp":"2026-03-21T11:00:00+0800","type":"po-patrol","summary":"掃描 15 個 open issues，無異常","actions":[]}
```
