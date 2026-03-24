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
- [ ] **PO** 執行 Backlog 排序與 Story 選取（詳見 [po-prompt.md](./references/po-prompt.md) Round 1）
- [ ] **PO Round 1 ADR 自動納入**（#456）：PO 選取 Story 後，掃描 Architect 技術評估的 ADR 欄位；若有標注「已補建 #N（RESEARCH）」的 ADR Story，自動將該 ADR RESEARCH Story 一併選入同一 Sprint（AC2）
- [ ] 檢查選入 Story 是否標注「需要 ADR」— 若需要，ADR 必須已 Accepted 或已在本 Sprint 納入 ADR RESEARCH Story
- [ ] **複雜度影響評估**（#462）：對每個新增功能 Story，執行 `bash scripts/measure-complexity.sh` 評估複雜度影響；若預計新增 Skill/Agent，須同步評估是否刪減等量舊功能（見 §13 複雜度預算）
- [ ] **Architect** 技術評估（詳見 [architect-prompt.md](./references/architect-prompt.md)）
- [ ] **QA** 驗收標準確認（詳見 [qa-prompt.md](./references/qa-prompt.md)）
- [ ] 上個 Sprint 的 Retro Action Items 自動列入 Backlog（若有未完成項目）
- [ ] **PO** 建立 `docs/sprints/sprint_N.md`、更新 `docs/PROJECT_BOARD.md`、GitHub label/milestone 操作（詳見 [po-prompt.md](./references/po-prompt.md) Round 2）
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

### 5.1 會議紀錄、Claim/Release、Commit 與自動啟動

詳見 [references/commit-and-trigger.md](./references/commit-and-trigger.md)。

---

## 6. Subagent 派遣順序

| 步驟 | 角色 | 職責 | 模型 | 角色 Prompt |
|------|------|------|------|------------|
| 0 | 健康檢查 | 完整 4 項檢查 | — | *(慢想)* |
| 0.5 | 角色權重調整 | 讀取 Retro Log，執行關鍵字比對（§7） | — | *(慢想)* |
| 0.9 | Issue 快掃 | `/issue-management` 批次模式 | — | — |
| R1–R3 | Refinement | M/L Story 前置門禁（詳見 [architect-prompt.md](./references/architect-prompt.md)） | opus | [architect-prompt.md](./references/architect-prompt.md) |
| 1 | PO Round 1 | Backlog 分析、Story 選取、獨立性評估 | sonnet | [po-prompt.md](./references/po-prompt.md) |
| 2 | Architect | 技術評估、ADR 檢查、平行分群、方法論評估 | opus | [architect-prompt.md](./references/architect-prompt.md) |
| 3 | QA | AC 驗收確認、路徑驗證、DoR/DoD 檢查 | opus | [qa-prompt.md](./references/qa-prompt.md) |
| 4 | PO Round 2 | Sprint 文件產出、GitHub label/milestone 操作 | opus | [po-prompt.md](./references/po-prompt.md) |

> **主 session 不讀取 Backlog/PROJECT_BOARD.md/ROADMAP.md**，僅接收 subagent 回傳的摘要表格。
> Issue 快掃降級指引：gh 指令失敗時靜默略過，不阻塞 Planning。

---

## 7. 角色權重調整檢查（US-22 / ADR-004）

詳見 [references/weight-adjustment.md](./references/weight-adjustment.md)。

---

## 8. 複雜度預算機制（#462）

詳見 [references/complexity-budget.md](./references/complexity-budget.md)。

---

## 9. SBE 範例體系（Specification by Example）

Sprint Planning 流程中的業務規則以 SBE 範例作為 ground truth，格式標準與相關文件：

- `docs/definition/sbe-examples/SBE_FORMAT.md`：Given/When/Then 標準格式
- `docs/definition/sbe-examples/SBE_TO_TEST_RULES.md`：SBE → 測試案例轉換規則
- `docs/definition/sbe-examples/sprint-lifecycle/sprint_planning_scheduled_mode.sbe.md`：§3.1 排程模式 HARD-GATE
- `docs/definition/sbe-examples/sprint-lifecycle/sprint_planning_refinement_gate.sbe.md`：§9.2 Refinement 觸發條件
