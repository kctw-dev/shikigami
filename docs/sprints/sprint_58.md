# Sprint 58

**狀態**：進行中
**期間**：2026-03-08 ~ 2026-03-14
**Sprint Goal**：精簡 Sprint Review 執行流程，降低每次 Review 的時間成本與認知負荷，使 Velocity 恢復正向趨勢。
**ADR 依賴**：無
**總計**：2 Stories / 3 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | doc-only | 狀態 |
|----------|---------|------|------|--------|----------|------|
| US-155 | #154 | Sprint Review 執行時間過長 — 流程精簡化 | M | 2 | 是 | 完成 |
| US-156 | #106 | 模型分層策略：Planning 用高階模型、Coding 用合適模型 | S | 1 | 是 | 完成 |

**Sprint 容量**：3 Points（2 Stories）

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1（並行） | US-155 + US-156 | 兩者皆獨立，無前置依賴，無檔案衝突，可完全並行執行。無 Phase 2。 |

---

## Story 詳細 AC

---

### US-155：Sprint Review 執行時間過長 — 流程精簡化

**來源**：Sprint 57 使用者回饋
**Issue**：#154
**Size**：M / 2 Points
**QA doc-only 判定**：Yes（純文件更新）
**前置依賴**：無（Phase 1，可並行）

**User Story**

As a Product Owner executing Sprint Review, I want the Sprint Review skill to support a fast-thinking mode with clearly defined shortcuts, so that I can complete the Review with lower time cost and cognitive load when velocity is low or time is constrained.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 快思/慢想模式段落存在 | `skills/sprint-review/SKILL.md` 新增快思模式與慢想模式專屬段落，明確列出快思模式跳過或縮短的步驟清單（至少列出 2 個具體步驟） |
| AC2 | 靜態 | DORA Metrics 與 Retrospective Analytics 平行化描述 | SKILL.md 中 DORA Metrics 計算與 Retrospective Analytics 兩步驟的描述改為可平行執行，並以「平行」或「同時」等語意明確標示 |
| AC3 | 靜態 | 觸發條件明確定義 | 快思模式與慢想模式各有明確觸發條件定義（例如：快思模式 — Velocity < 3 pts 或 /fast flag；慢想模式 — Velocity >= 3 pts 或明確要求深度分析） |

**Done 定義**

- [x] `skills/sprint-review/SKILL.md` 已新增快思/慢想模式段落，包含跳過或縮短的步驟清單（AC1）
- [x] DORA Metrics 計算與 Retrospective Analytics 描述已改為平行執行（AC2）
- [x] 快思模式與慢想模式的觸發條件已有明確定義（AC3）

---

### US-156：模型分層策略：Planning 用高階模型、Coding 用合適模型

**來源**：長期 Backlog — 成本效益最佳化
**Issue**：#106
**Size**：S / 1 Point
**QA doc-only 判定**：Yes（純文件產出）
**前置依賴**：無（Phase 1，可並行）

**User Story**

As a developer managing Shikigami operating costs, I want a documented model tiering strategy that recommends appropriate models per sprint phase, so that I can make informed decisions about model selection to balance quality and token cost.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 策略文件存在且包含三環節表格 | `docs/km/MODEL_TIERING_STRATEGY.md` 存在，且包含 Planning、Execution、Review 三環節的模型層級建議表格（欄位至少含：環節、建議模型層級、理由） |
| AC2 | 靜態 | Agent tool model 參數可行性調查結論 | 文件包含對 Claude Code Agent tool `model` 參數的可行性調查結論，明確說明是否支援、限制為何，以及替代方案（如有） |
| AC3 | 靜態 | 成本效益估算段落 | 文件包含分層策略 vs. 統一模型的 token 成本差異估算，至少提供概估數字或比率，並給出採用建議 |

**Done 定義**

- [x] `docs/km/MODEL_TIERING_STRATEGY.md` 已建立，包含三環節模型層級建議表格（AC1）
- [x] 文件已包含 Claude Code Agent tool `model` 參數可行性調查結論（AC2）
- [x] 文件已包含分層 vs. 統一模型 token 成本差異估算（AC3）

---

## Sprint Notes

- **Velocity 目標**：3 pts（Sprint 57 Velocity 2 pts，本 Sprint 以小步前進為原則，避免過度承諾）
- **Backlog 背景**：兩個 Stories 均為長期 Backlog items，AC 已在 Sprint 58 Planning Round 2 補全，可直接執行。
- **快思模式適用性**：本 Sprint 總點數僅 3 pts，屬輕量 Sprint，執行時可視情況搭配快思模式。
