---
name: sprint-planning
description: "Use when starting a new sprint, selecting stories from backlog, or beginning sprint planning ceremony"
---

# Sprint Planning — Sprint 週期起點

## 1. 概述

Sprint Planning 是每個 Sprint 週期的起點儀式。由 **PO** 主持，**Architect** 與 **QA** 共同參與，確保選入 Sprint 的 Stories 在需求、技術可行性、驗收標準三方面皆已就緒。

**目標**：從 Product Backlog 頂部選取符合 Sprint Goal 的 Stories，經技術評估與驗收確認後，正式納入 Sprint Backlog。

---

## 1.1 快思/慢想模式

| 模式 | 觸發方式 | 跳過項目 |
|------|---------|---------|
| **快思**（預設） | 直接執行 Sprint Planning | 健康檢查、Token 消耗測量、角色權重調整 |
| **慢想** | `--deep` 或「完整檢查」 | 無（執行完整流程） |

## 模型選用建議

| Subagent | 模型 | 理由 |
|----------|------|------|
| PO Round 1 | `sonnet` | Backlog 分析與 Story 選取，Sonnet 已足夠且更穩定 |
| Architect | `opus` | 技術可行性評估與 ADR 檢查需要高層次策略推理 |
| QA | `opus` | 驗收標準確認與 AC 驗證策略需要深度分析 |
| PO Round 2 | `opus` | Sprint 文件產出與最終確認需要完整推理能力 |

> 派遣 subagent 時依上表指定 `model`，主 session 模型不受影響。

---

## 2. 流程 Checklist

> **模式選擇**：預設為**快思模式**，跳過標記 *(慢想)* 的項目。使用者傳入 `--deep` 時執行完整流程。

- [ ] 執行框架健康檢查（<!-- Claude Code -->invoke shikigami:health-check<!-- OpenCode -->使用 health-check skill<!-- /OpenCode -->）*(慢想)*
- [ ] 角色權重調整檢查（詳見 §7）*(慢想)*
- [ ] **PO** 掃描 GitHub open issues，對未分類 issues 執行 Triage（<!-- Claude Code -->invoke shikigami:issue-management Triage<!-- OpenCode -->使用 issue-management skill<!-- /OpenCode -->）
- [ ] 記錄 Sprint Planning 開始時間：`START_TIME=$(date '+%Y-%m-%dT%H:%M+08:00')`
- [ ] **PO** 執行 Backlog 排序與 Story 選取（詳見 [po-prompt.md](./po-prompt.md) Round 1）
- [ ] **PO Round 1 ADR 自動納入**（#456）：PO 選取 Story 後，掃描 Architect 技術評估的 ADR 欄位；若有標注「已補建 #N（RESEARCH）」的 ADR Story，自動將該 ADR RESEARCH Story 一併選入同一 Sprint（AC2）
- [ ] 檢查選入 Story 是否標注「需要 ADR」— 若需要，ADR 必須已 Accepted 或已在本 Sprint 納入 ADR RESEARCH Story
- [ ] **複雜度影響評估**（#462）：對每個新增功能 Story，執行 `bash scripts/measure-complexity.sh` 評估複雜度影響；若預計新增 Skill/Agent，須同步評估是否刪減等量舊功能（見 §13 複雜度預算）
- [ ] **Architect** 技術評估（詳見 [architect-prompt.md](./architect-prompt.md)）
- [ ] **QA** 驗收標準確認（詳見 [qa-prompt.md](./qa-prompt.md)）
- [ ] 上個 Sprint 的 Retro Action Items 自動列入 Backlog（若有未完成項目）
- [ ] **PO** 建立 `docs/sprints/sprint_N.md`、更新 `docs/PROJECT_BOARD.md`、GitHub label/milestone 操作（詳見 [po-prompt.md](./po-prompt.md) Round 2）
- [ ] 記錄 Token 消耗至 `docs/km/Metrics_Log.md` *(慢想)*<!-- OpenCode -->（OpenCode 暫填 N/A）<!-- /OpenCode -->
- [ ] 寫入 Sprint Planning 會議紀錄至 `docs/meetings/YYYY-MM-DD-sprint-planning.md`（詳見 §5.1 會議紀錄格式）
- [ ] 完成 Sprint 狀態文件修改後，立即 git commit + git push（範圍見 §5）

---

## 3. Hard Gate

<HARD-GATE>
沒有 ADR 的技術選型 Story 不能進 Sprint。
</HARD-GATE>

任何涉及技術選型的 Story 必須先完成 ADR 並獲得 Accepted 狀態。未通過此門禁的 Story 退回 Backlog。

---

## 3.1 排程模式（Scheduled Mode）

排程模式由 cron 自動觸發，透過環境變數 `SHIKIGAMI_SCHEDULED=true` 偵測。

| 環境變數 | 值 | 意義 |
|----------|----|------|
| `SHIKIGAMI_SCHEDULED` | `true` | 排程模式 |
| `SHIKIGAMI_SCHEDULED` | 未設定或其他值 | 手動模式 |

<HARD-GATE>
排程模式下，M/L Stories 不得選入 Sprint Backlog，僅 S size Stories 可納入。
</HARD-GATE>

**違規處理**：若 PO 在排程模式下選入 M/L Stories，Sprint Planning **必須中止**並輸出 `[SCHEDULED-MODE-GATE]` 告警。

**非排程模式不受影響**：M/L Stories 仍可依原有流程選入。

---

## 4. Sprint 週期

**週期長度：1 週**（小團隊、MVP 階段、高頻反饋）

---

## 5. 產出文件

| 文件 / 操作 | 說明 |
|------------|------|
| `docs/sprints/sprint_N.md` | 新建。Sprint Goal、Stories 清單、T-shirt size、驗收標準摘要 |
| `docs/PROJECT_BOARD.md` | 更新。將選入 Stories 移至「Sprint Backlog」欄位 |
| GitHub Issues labels/milestone | `status: in-sprint` label + Sprint Milestone |
| `docs/meetings/YYYY-MM-DD-sprint-planning.md` | 新建。Sprint Planning 會議紀錄（frontmatter + 結論） |

### 5.1 Sprint Planning 會議紀錄格式

`docs/meetings/` 目錄若不存在，執行 `mkdir -p docs/meetings` 建立。

檔名規則：`docs/meetings/$(date '+%Y-%m-%d')-sprint-planning.md`

時間取得方式：開始時間在流程第一步（記錄 `START_TIME`）取得，結束時間在寫入紀錄時取得。

```yaml
---
type: sprint-planning
sprint: <N>
date: "<YYYY-MM-DD>"
start_time: "<START_TIME>"
end_time: "<date '+%Y-%m-%dT%H:%M+08:00'>"
participants:
  - role: PO
    rounds: [1, 2]
  - role: Architect
  - role: QA
---

# Sprint <N> Planning 會議紀錄

## 結論
- Sprint Goal: <goal>
- 選入 Stories: <story list>

## 決議事項
1. <decisions>
```

### 並行衝突防護

PO Round 2 建立 `sprint_N.md` 前，必須執行 **git pull + 檔案存在性檢查 + 自動遞增** 機制，防止多 session 同時執行 Sprint Planning 時產生重複編號。衝突發生時輸出 `[SPRINT-CONFLICT]` WARN 日誌並自動遞增編號。完整流程見 [po-prompt.md](./po-prompt.md) § 並行衝突防護流程。

### Sprint Planning Claim/Release（US-312）

PO Round 2 開始（建立 `sprint_N.md`）前，執行 Sprint Planning claim：

```bash
bash hooks/claim-issue.sh "sprint-${N}-planning"
# [CLAIM-OK]      → 繼續 Sprint Planning
# [CLAIM-BLOCKED] → 已有其他 session 正在 Planning，輸出 WARN 後繼續（不阻塞）
```

Sprint Planning 完成（git commit + push）後，執行 release：

```bash
bash hooks/release-issue.sh "sprint-${N}-planning"
# [CLAIM-RELEASE] refs/claims/sprint-${N}-planning
```

claim/release 失敗不阻塞 Sprint Planning（gh CLI 不可用時同樣降級容錯）。完整 claim 機制定義見 `skills/sprint-execution/SKILL.md` §2.11。

### Commit + Push 規範

```bash
git add docs/PROJECT_BOARD.md docs/sprints/sprint_N.md docs/meetings/
git commit -m "docs: Sprint N Planning — 更新看板與 Sprint 文件"
git push
```

> **範圍限制**：僅適用 Sprint 狀態文件（`PROJECT_BOARD.md`、`sprint_N.md`、`Metrics_Log.md`、`Retrospective_Log.md`、`docs/meetings/*.md`）。

### 自動啟動 Sprint Execution（#354）

Sprint Planning commit + push 完成後，依 `project_level` 決定是否自動啟動 Sprint Execution：

```bash
# 讀取 project_level（同 Cruise 步驟 4.5 讀取方式）
CONFIG_FILE=".claude/shikigami.local.md"
PROJECT_LEVEL=$(grep -A5 'shikigami:' "$CONFIG_FILE" 2>/dev/null | grep 'project_level:' | awk '{print $2}' | head -1)
PROJECT_LEVEL="${PROJECT_LEVEL:-medium}"

if PROJECT_LEVEL == "low":
  # low：自動啟動，不問人
  invoke shikigami:sprint-execution
elif PROJECT_LEVEL == "medium":
  # medium：通知等確認
  echo "[SPRINT] Sprint Planning 完成。請確認是否啟動 Sprint Execution。"
else:  # high
  # high：只記錄
  echo "[SPRINT] Sprint Planning 完成。Sprint Execution 需手動啟動。"
```

---

## 6. Subagent 派遣順序

| 步驟 | 角色 | 職責 | 模型 | 角色 Prompt |
|------|------|------|------|------------|
| 0 | 健康檢查 | 完整 4 項檢查 | — | *(慢想)* |
| 0.5 | 角色權重調整 | 讀取 Retro Log，執行關鍵字比對（§7） | — | *(慢想)* |
| 0.9 | Issue 快掃 | `/issue-management` 批次模式 | — | — |
| R1–R3 | Refinement | M/L Story 前置門禁（詳見 [architect-prompt.md](./architect-prompt.md)） | opus | [architect-prompt.md](./architect-prompt.md) |
| 1 | PO Round 1 | Backlog 分析、Story 選取、獨立性評估 | sonnet | [po-prompt.md](./po-prompt.md) |
| 2 | Architect | 技術評估、ADR 檢查、平行分群、方法論評估 | opus | [architect-prompt.md](./architect-prompt.md) |
| 3 | QA | AC 驗收確認、路徑驗證、DoR/DoD 檢查 | opus | [qa-prompt.md](./qa-prompt.md) |
| 4 | PO Round 2 | Sprint 文件產出、GitHub label/milestone 操作 | opus | [po-prompt.md](./po-prompt.md) |

> **主 session 不讀取 Backlog/PROJECT_BOARD.md/ROADMAP.md**，僅接收 subagent 回傳的摘要表格。
> Issue 快掃降級指引：gh 指令失敗時靜默略過，不阻塞 Planning。

---

## 7. 角色權重調整檢查（US-22 / ADR-004）

**觸發時機**：健康檢查完成後、PO 第一輪開始前 *(慢想模式限定)*。

**執行步驟**：

1. 讀取 `docs/km/Retrospective_Log.md`
2. 少於 3 個 Sprint 記錄 → 輸出「歷史資料不足」→ 寫入 sprint_N.md → 結束
3. 提取最近 2 個已完成 Sprint 的 `### Problem` 區塊，比對 QA 關鍵字清單：

```yaml
qa_keywords: ["QA", "審查", "Review", "Code Quality", "Spec Compliance", "雙階段", "品質"]
```

**觸發後調整規則**：

| 條件 | 調整 |
|------|------|
| 連續 2 Sprint 有 QA 相關 Problem | QA Review 升為 Hard Gate（Must） |
| 連續 2 Sprint 無 QA 相關 Problem（升級中） | QA Review 恢復為 Should |
| 連續 2 Sprint 無任何 Problem | Bypass 門檻從 S 放寬至 M |

結果（無論調整與否）持久化至 `docs/sprints/sprint_N.md`「## 權重調整記錄」區塊。

關鍵字清單更新時機：Sprint Review Retrospective 環節，SQA 識別漏判 → 提議新關鍵字 → Architect 確認。

---

## 13. 複雜度預算機制（#462）

### 背景

Sprint 121–123 連續三個 Sprint 出現「框架過於複雜」的 Retro Problem。為防止框架無限膨脹，建立量化的複雜度預算機制，在 Sprint Planning 時強制評估新增功能對整體複雜度的影響。

### 度量指標

| 指標 | 說明 | 預設門檻 | 環境變數覆蓋 |
|------|------|---------|-------------|
| `SKILL_COUNT` | `skills/` 子目錄數量 | 40 | `COMPLEXITY_SKILL_BUDGET` |
| `AGENT_COUNT` | `agents/*.md` 數量 | 15 | `COMPLEXITY_AGENT_BUDGET` |
| `HOOK_COUNT` | `hooks/**/*.sh` 數量 | 35 | `COMPLEXITY_HOOK_BUDGET` |
| `TOTAL_LINES` | SKILL.md + Agent + Hook 總行數 | 25000 | `COMPLEXITY_LINES_BUDGET` |

### 度量腳本

```bash
# 輸出當前基線
bash scripts/measure-complexity.sh

# 與基線比較（PR 複雜度變化報告）
bash scripts/measure-complexity.sh --diff docs/complexity-baseline.txt

# 超出門檻時輸出 WARNING（stderr），exit 0 不阻塞流程
COMPLEXITY_SKILL_BUDGET=30 bash scripts/measure-complexity.sh
```

### Sprint Planning 執行步驟（#462 AC3）

1. Sprint Planning 開始時，執行 `bash scripts/measure-complexity.sh` 取得當前複雜度基線
2. 對每個新增 Skill/Agent 的 Story，評估對 `SKILL_COUNT`/`AGENT_COUNT` 的影響
3. 若新功能會導致某指標超出預算門檻，**必須**同步評估刪減等量舊功能（Replace, not Add）
4. Sprint Planning 結束時，記錄當次複雜度數值至 Sprint 文件

### PR 複雜度變化報告（#462 AC4）

每個新增功能 PR 的 description 應包含：

```
## 複雜度變化
SKILL_COUNT: +N / -M（當前 X，門檻 40）
AGENT_COUNT: ±0（當前 Y，門檻 15）
HOOK_COUNT:  +N（當前 Z，門檻 35）
TOTAL_LINES: +N（當前 W，門檻 25000）
```

可用 `bash scripts/measure-complexity.sh --diff <baseline>` 自動產生此報告。

### 向後相容保證

- 腳本不修改任何現有 Skill/Agent/Hook 定義
- 超出門檻僅輸出 WARNING，不阻塞 CI（exit 0）
- 現有框架結構（29 Skills / 8 Agents / 21 Hooks）均在預設門檻內

---

## 12. SBE 範例體系（Specification by Example）

Sprint Planning 流程中的業務規則以 SBE 範例作為 ground truth，格式標準與相關文件：

- `docs/definition/sbe-examples/SBE_FORMAT.md`：Given/When/Then 標準格式
- `docs/definition/sbe-examples/SBE_TO_TEST_RULES.md`：SBE → 測試案例轉換規則
- `docs/definition/sbe-examples/sprint-lifecycle/sprint_planning_scheduled_mode.sbe.md`：§3.1 排程模式 HARD-GATE
- `docs/definition/sbe-examples/sprint-lifecycle/sprint_planning_refinement_gate.sbe.md`：§9.2 Refinement 觸發條件
