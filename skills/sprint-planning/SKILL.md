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

- [ ] 執行框架健康檢查（<!-- Claude Code -->invoke shikigami:health-check<!-- /Claude Code --><!-- OpenCode -->使用 health-check skill<!-- /OpenCode -->）*(慢想)*
- [ ] 角色權重調整檢查（詳見 §7）*(慢想)*
- [ ] **PO** 掃描 GitHub open issues，對未分類 issues 執行 Triage（<!-- Claude Code -->invoke shikigami:issue-management Triage<!-- /Claude Code --><!-- OpenCode -->使用 issue-management skill<!-- /OpenCode -->）
- [ ] **Pre-flight Backlog 健康度檢查**：執行 `gh issue list --label "sprint-candidate" --state open --json number | jq length` 取得 `BACKLOG_COUNT`；若 `BACKLOG_COUNT < 5`，輸出 `[BACKLOG-WARN] sprint-candidate 不足 (N < 5)，建議先執行 backlog-management` 並自動觸發 `/backlog-management` skill 補充；若 `BACKLOG_COUNT >= 5`，輸出 `[BACKLOG-OK] sprint-candidate: N 個，健康度正常` 並繼續
- [ ] **Pre-flight Model Routing 健康度掃描**（ADR-039 決策 2.6，#854，Sprint 166）：執行 `bash scripts/routing-stats.sh 2>/dev/null | grep -q "\[OVER-ROUTING-WARN\]"` 判斷是否存在 routing 警告；若存在 `[OVER-ROUTING-WARN]`，輸出提示 `[ROUTING-SCAN-TRIGGER] 檢測到 haiku 比例偏低，本次 Planning 啟動 haiku 適用場景擴充掃描`，PO 在 Story 選取後額外執行 RICE Score 與 Routing Tier 交叉審查（詳見 po-prompt.md §haiku 交叉審查）；若無警告或腳本不存在，靜默略過（非阻塞）
- [ ] 記錄 Sprint Planning 開始時間：`START_TIME=$(date '+%Y-%m-%dT%H:%M+08:00')`
- [ ] **PO** 執行 Backlog 排序與 Story 選取（詳見 [po-prompt.md](./references/po-prompt.md) Round 1）
- [ ] **PO Round 1 ADR 自動納入**（#456）：PO 選取 Story 後，掃描 Architect 技術評估的 ADR 欄位；若有標注「已補建 #N（RESEARCH）」的 ADR Story，自動將該 ADR RESEARCH Story 一併選入同一 Sprint（AC2）
- [ ] 檢查選入 Story 是否標注「需要 ADR」— 若需要，ADR 必須已 Accepted 或已在本 Sprint 納入 ADR RESEARCH Story
- [ ] **複雜度影響評估**（#462）：對每個新增功能 Story，執行 `bash scripts/measure-complexity.sh` 評估複雜度影響；若預計新增 Skill/Agent，須同步評估是否刪減等量舊功能（見 §13 複雜度預算）
- [ ] 確認 INFRA Story 涉及的 CI Actions 版本升級已完成人工審核確認（未完成者須退回 Backlog 或延至下一 Sprint）
- [ ] **Architect** 技術評估（詳見 [architect-prompt.md](./references/architect-prompt.md)）— 輸出技術評估表 / Schema / ADR Issue body 前須執行軟性字樣自檢（#1002，含禁用字樣時標 `[NEEDS_REVISION]` 並打回重寫）
- [ ] **QA** 驗收標準確認（詳見 [qa-prompt.md](./references/qa-prompt.md)）— 輸出 AC 補捉表 / Challenge 訊息前須執行軟性字樣自檢（#1002，含禁用字樣時標 `[NEEDS_REVISION]` 並打回重寫）
- [ ] 上個 Sprint 的 Retro Action Items 自動列入 Backlog（若有未完成項目）
- [ ] **Retro-Action Grooming 偵測**（#493）：掃描 `retro-action` label 的 open Issues，對 Sprint Review 觸發的 `[RETRO-GROOMING-TRIGGER]` Issues 執行 Backlog Grooming 重評估（詳見 `skills/sprint-review/references/retro-grooming.md`）
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

<HARD-GATE>
Sprint Planning 建立任何 GitHub Issue 一律透過 `bash scripts/gh-issue-create.sh`，禁止直接呼叫 `gh issue create --body "..."`。
</HARD-GATE>

依 CLAUDE.md 紅線 #13 與 Sprint 182 retro action #1001：直接以 `--body "..."` 傳入含冒號（`:`）、星號（`*`）、引號等字元的多行內容會被截斷或破壞 YAML/shell 解譯（Sprint 135 #597、Sprint 182 #994/#995/#996 已有歷史案例）。helper script 會強制走 `--body-file` 模式並自動清理暫存檔。

```bash
bash scripts/gh-issue-create.sh \
  --title "RESEARCH: ADR — 決策主題" \
  --body  "$BODY" \
  --repo  "$OWNER_REPO" \
  --label "RESEARCH,size:S,story-points:1"
```

支援 `--body` / `--body-file` / stdin (`-`) 三種來源；不熟悉的情境先以 `--dry-run` 檢視將寫入的內容。詳見 `scripts/gh-issue-create.sh -h`。

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

<HARD-GATE>
project_level=low 時，Sprint Planning commit + push 完成後，必須自動 invoke shikigami:sprint-execution，禁止詢問使用者確認。
</HARD-GATE>

---

## 6. Subagent 派遣順序

| 步驟 | 角色 | 職責 | 模型 | 角色 Prompt |
|------|------|------|------|------------|
| 0 | 健康檢查 | 完整 4 項檢查 | — | *(慢想)* |
| 0.5 | 角色權重調整 | 讀取 Retro Log，執行關鍵字比對（§7） | — | *(慢想)* |
| 0.9 | Issue 快掃 | `/issue-management` 批次模式 | — | — |
| 0.95 | Backlog 健康度 Pre-flight | `sprint-candidate` open Issues 計數；< 5 → `[BACKLOG-WARN]` + `/backlog-management`；≥ 5 → `[BACKLOG-OK]` | — | — |
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

## 9. D3 Debate Protocol — Architect vs QA 技術辯論（#777）

D3（Design Disagreement Debate）是 **選擇性觸發** 的結構化辯論機制，**僅在 Architect 與 QA 對同一 Story 意見不同（disagree）產生分歧時啟動**。

### 觸發條件

- Architect 技術評估與 QA 驗收確認對同一 Story 的技術方案出現明確衝突
- 非強制——若雙方無分歧，跳過 D3 直接進入 PO Round 2

### 三輪結構（3-round structure）

| 輪次 | 角色 | 職責 |
|------|------|------|
| Round 1 | **Advocate（Architect）** | 提出技術方案立場，說明設計理由與技術可行性 |
| Round 2 | **Challenge（QA）** | 針對 Architect 方案提出挑戰：測試難度、邊界條件、AC 覆蓋風險 |
| Round 3 | **Cost-aware rebuttal（Architect）** | 考量實作成本後回應 QA 挑戰，可接受部分讓步 |
| 裁決 | **Judge decision（SM）** | Scrum Master 綜合三輪輸出，給出最終技術方向裁決 |

> **最多 3 輪（3 rounds maximum）**，禁止無限循環。若 3 輪後仍無共識，SM 強制裁決，記錄 `[D3-UNRESOLVED]` 並升級至 Architect 複審。

### 記錄規則（AC2）

D3 決策必須記錄至 `docs/km/d3-decisions.md`，欄位包含：

- Date、Sprint、Story
- Round 1 Advocate Position（Architect 立場）
- Round 2 Challenge（QA 挑戰）
- Round 3 Rebuttal（Architect Cost-aware 回應）
- Judge Rationale（SM 裁決理由）
- Final Decision（最終決策）

### Sprint Planning 文件整合（AC3）

當 D3 被觸發時，Sprint Planning 會議紀錄（§5.1）必須包含 `## D3 Record` 段落，格式如下：

```markdown
## D3 Record

**Story**: #NNN Story Title
**觸發原因**: Architect 與 QA 分歧摘要
**Final Decision**: 最終決策結果
**Judge Rationale**: SM 裁決理由（簡述）
**完整記錄**: 見 docs/km/d3-decisions.md
```

---

## 10. SBE 範例體系（Specification by Example）

Sprint Planning 流程中的業務規則以 SBE 範例作為 ground truth，格式標準與相關文件：

- `docs/definition/sbe-examples/SBE_FORMAT.md`：Given/When/Then 標準格式
- `docs/definition/sbe-examples/SBE_TO_TEST_RULES.md`：SBE → 測試案例轉換規則
- `docs/definition/sbe-examples/sprint-lifecycle/sprint_planning_scheduled_mode.sbe.md`：§3.1 排程模式 HARD-GATE
- `docs/definition/sbe-examples/sprint-lifecycle/sprint_planning_refinement_gate.sbe.md`：§9.2 Refinement 觸發條件

---

## 11. Compliance Audit（強制輸出）

<HARD-GATE>
Sprint Planning 結束前必須輸出 [COMPLIANCE-AUDIT] 區塊。無論步驟是否完整執行，都不得省略此輸出。
</HARD-GATE>

Sprint Planning 完成（或中止）前，**最後一個動作**必須是輸出以下格式的 Compliance Audit：

```
[COMPLIANCE-AUDIT] sprint-planning Sprint N
✅ PO Round 1    — N 個 Stories 選入（#XXX, #XXX, ...）
✅ Architect     — 技術評估表已輸出
✅ QA            — AC 驗收表已確認
✅ PO Round 2    — docs/sprints/sprint_N.md 已建立
✅ commit + push — 完成
⏭ 健康檢查      — 跳過（快思模式）
⏭ Token 記錄    — 跳過（快思模式）

Artifact: docs/sprints/sprint_N.md ✅
```

**符號規則**：
- `✅` 已執行且有對應 artifact 或可驗證結果
- `⏭` 跳過，必須附上原因（快思模式 / 排程模式 / 條件不符）
- `❌` 應執行但未執行或失敗，必須附上原因

每個列出的項目對應 §2 流程 Checklist 的一個主要步驟。**不得合併、不得省略**。
