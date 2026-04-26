---
name: sprint
description: "Use when running a complete sprint lifecycle end-to-end, or when someone says 'run sprint', 'start sprint', 'full sprint', 'go'. Chains planning → execution → review as isolated Agent sessions with artifact verification between stages."
---

# Sprint Pipeline — 端到端 Sprint 執行

## 概述

一個指令跑完整個 Sprint 生命週期。每個階段是**獨立的 Agent session**，完成後驗證 artifact 存在，才進入下一階段。

**關鍵原則：沒有 artifact，視同沒有執行。**

---

## 觸發語法

```
/sprint          — 自動偵測目前狀態，從需要的階段開始
/sprint plan     — 只跑 Planning
/sprint exec     — 只跑 Execution（假設 Planning 已完成）
/sprint review   — 只跑 Review（假設 Execution 已完成）
```

---

## Step 0：狀態偵測

執行前先偵測目前 Sprint 狀態，決定從哪個階段開始：

```bash
# 取得最新 Sprint 編號
SPRINT_N=$(ls docs/sprints/sprint_*.md 2>/dev/null | grep -oE 'sprint_([0-9]+)' | grep -oE '[0-9]+' | sort -n | tail -1)
TODAY=$(date '+%Y-%m-%d')
```

| 狀態 | 判斷條件 | 從哪開始 |
|------|---------|---------|
| 無 Sprint | `docs/sprints/sprint_N.md` 不存在 | Planning |
| Planning 完成 | sprint doc 存在，但無 `status: in-sprint` 的 open issues | Execution |
| Execution 進行中 | 有 `status: in-sprint` 的 open issues | Execution（繼續） |
| Execution 完成 | 所有 in-sprint stories 已有 PR，無 retro doc | Review |
| Sprint 完成 | retro doc 存在 | 輸出完成訊息，停止 |

```bash
# 偵測 Planning 狀態
SPRINT_DOC="docs/sprints/sprint_${SPRINT_N}.md"
PLANNING_DONE=$(test -f "$SPRINT_DOC" && echo "yes" || echo "no")

# 偵測 Execution 狀態（有無 in-sprint open stories）
IN_SPRINT_COUNT=$(gh issue list --label "status: in-sprint" --state open --json number 2>/dev/null | jq length 2>/dev/null || echo "0")

# 偵測 Review 狀態（有無 retro doc）
RETRO_DOC=$(ls docs/meetings/*retro* 2>/dev/null | grep "$(date '+%Y-%m')" | tail -1)
REVIEW_DONE=$([ -n "$RETRO_DOC" ] && echo "yes" || echo "no")
```

---

## Stage 1：Sprint Planning

**跳過條件**：`docs/sprints/sprint_N.md` 已存在且有效

**輸出開始標記**：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[1/3] 🗓 Sprint Planning
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**執行**：派遣 sprint-planning Agent（<!-- Claude Code -->invoke shikigami:sprint-planning<!-- /Claude Code --><!-- OpenCode -->使用 sprint-planning skill<!-- /OpenCode -->）

**Artifact 驗證**（Planning 結束後立即執行）：

```bash
# 驗證 1：sprint doc 存在
test -f "docs/sprints/sprint_${SPRINT_N}.md" \
  || PIPELINE_HALT "Stage 1" "docs/sprints/sprint_${SPRINT_N}.md 未產出"

# 驗證 2：planning 會議紀錄存在
ls docs/meetings/*sprint*planning* 2>/dev/null | grep -q "." \
  || PIPELINE_HALT "Stage 1" "Sprint Planning 會議紀錄未產出"

# 驗證 3：有 in-sprint stories
IN_SPRINT=$(gh issue list --label "status: in-sprint" --state open --json number | jq length)
[ "$IN_SPRINT" -gt 0 ] \
  || PIPELINE_HALT "Stage 1" "無 in-sprint stories（Sprint Backlog 為空）"
```

**成功輸出**：
```
✅ docs/sprints/sprint_N.md 已建立
✅ Sprint Planning 會議紀錄已建立
✅ Sprint Backlog: N 個 stories
```

---

## Stage 2：Sprint Execution

**跳過條件**：所有 `status: in-sprint` stories 已有對應 PR（`IN_SPRINT_COUNT = 0`）

**輸出開始標記**：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[2/3] ⚙️ Sprint Execution
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**取得 Story 清單**：

```bash
STORIES=$(gh issue list --label "status: in-sprint" --state open --json number,title --jq '.[] | "\(.number) \(.title)"')
```

**逐 Story 執行**：對每個 story，派遣獨立的 sprint-execution Agent：

```
→ Story #1001「Feature A」：派遣執行 agent...
```

（<!-- Claude Code -->invoke shikigami:sprint-execution<!-- /Claude Code --><!-- OpenCode -->使用 sprint-execution skill<!-- /OpenCode -->）

**每個 Story 的 Artifact 驗證**：

```bash
# 驗證：該 story 有對應 PR（open 或 merged 均可）
PR_COUNT=$(gh pr list --search "Closes #${STORY_N} OR close #${STORY_N}" --state all --json number | jq length)
[ "$PR_COUNT" -gt 0 ] \
  || PIPELINE_HALT "Stage 2" "Story #${STORY_N} 無對應 PR（執行可能未完成）"
```

**每個 Story 成功輸出**：
```
✅ Story #1001: PR #88 已開啟
```

**所有 Stories 完成後**：
```
✅ Sprint Execution 完成：N 個 stories，N 個 PRs
```

---

## Stage 3：Sprint Review

**跳過條件**：retro doc 已存在（本月內）

**輸出開始標記**：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[3/3] 📋 Sprint Review
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**執行**：派遣 sprint-review Agent（<!-- Claude Code -->invoke shikigami:sprint-review<!-- /Claude Code --><!-- OpenCode -->使用 sprint-review skill<!-- /OpenCode -->）

**Artifact 驗證**（Review 結束後立即執行）：

```bash
# 驗證 1：retro 會議紀錄存在
RETRO=$(ls docs/meetings/*retro* 2>/dev/null | tail -1)
[ -n "$RETRO" ] \
  || PIPELINE_HALT "Stage 3" "Retro 會議紀錄未產出"

# 驗證 2：review 會議紀錄存在
REVIEW=$(ls docs/meetings/*review* 2>/dev/null | tail -1)
[ -n "$REVIEW" ] \
  || PIPELINE_HALT "Stage 3" "Sprint Review 會議紀錄未產出"
```

**成功輸出**：
```
✅ Sprint Review 會議紀錄已建立
✅ Retro 會議紀錄已建立
✅ Action Items 已轉為 GitHub Issues
```

---

## 完成

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Sprint N 完成 ✅
Planning → Execution (N stories) → Review 全部通過
下一步：說「/sprint」開始 Sprint N+1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## PIPELINE-HALT 機制

<HARD-GATE>
任何 Stage 的 Artifact 驗證失敗，必須立即 HALT，禁止繼續執行下一 Stage。
</HARD-GATE>

HALT 時輸出：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[PIPELINE-HALT] Stage: Sprint Planning
原因：docs/sprints/sprint_N.md 未產出
行動：手動檢查後，執行 /sprint exec 從下一階段繼續
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**HALT 後禁止自動重試**。等待使用者介入後，用指定語法繼續（`/sprint exec`、`/sprint review`）。

---

## project_level 行為

| project_level | 行為 |
|---|---|
| `low` | 全自動，三個 Stage 連續執行，不停頓 |
| `medium` | Stage 1 結束後停頓，顯示 Sprint Backlog 清單，等使用者確認後繼續 |
| `high` | 每個 Stage 前均需使用者確認 |

---

## 與其他 Skill 的關係

| Skill | 角色 |
|---|---|
| `sprint-planning` | Stage 1 的執行體，被 pipeline 派遣 |
| `sprint-execution` | Stage 2 的執行體，被 pipeline 逐 story 派遣 |
| `sprint-review` | Stage 3 的執行體，被 pipeline 派遣 |
| `cruise` | 背景排程版本，適合全自動無人值守 |
| `sprint`（本 skill） | 前景 pipeline，適合人機協作或夥伴操作 |
