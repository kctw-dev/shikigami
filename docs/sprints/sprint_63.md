# Sprint 63

**狀態**：進行中
**期間**：2026-03-08 ~ 2026-03-14
**Sprint Goal**：流程修正與技術債清理 — 修復 Sprint Review Issue 自動關閉問題（#166），評估開源 CLI Adapter 替代方案（#167），清理 50+ Sprint 懸而未決的 Retro Action Items（#168）。
**ADR 依賴**：無
**總計**：3 Stories / 3 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | doc-only | 狀態 |
|----------|---------|------|------|--------|----------|------|
| US-168 | #166 | Sprint Review Issue 關閉邏輯修正 — 區分內部/外部 Issue 關閉策略 | S | 1 | 是 | 完成 |
| US-169 | #167 | 多模型 CLI 路由 Phase 2 — 開源 Adapter 評估與決策 | S | 1 | 是 | 完成 |
| US-170 | #168 | Retro Action Items 批次處理 — Sprint 11-12 懸而未決項目清理 | S | 1 | 是 | 完成 |

**Sprint 容量**：3 Points（3 Stories）

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1 | US-168, US-169, US-170 | 三者完全獨立，可同時平行執行。US-168 修改 sprint-review SKILL.md，US-169 產出評估文件，US-170 處理 Retrospective_Log.md。 |

---

## 方法論適用性評估

| Story ID | BDD 適用 | DDD 適用 | 說明 |
|----------|----------|----------|------|
| US-168 | 不適用 | 不適用 | doc-only，修改流程規格，無行為規格需求 |
| US-169 | 不適用 | 不適用 | 調查型任務，產出評估文件 |
| US-170 | 不適用 | 不適用 | Retro 管理操作，非功能開發 |

---

## Story 詳細 AC

---

### US-168：Sprint Review Issue 關閉邏輯修正 — 區分內部/外部 Issue 關閉策略

**來源**：Issue #166（使用者回饋）
**Issue**：#166
**Size**：S / 1 Point
**QA doc-only 判定**：Yes（修改 SKILL.md 流程規格）
**前置依賴**：無

**User Story**

As a framework user, I want Sprint Review to not automatically close Issues created by external stakeholders, so that Issue creators can verify fixes before closure.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 流程規格更新 | `skills/sprint-review/SKILL.md` §2.6 修改為區分 Issue 建立者：內部自動建立的 Issue 維持自動關閉，外部建立者的 Issue 僅加 `done` label + 留言通知，保持 Open |
| AC2 | 靜態 | 判斷邏輯明確 | §2.6 包含明確的 if/else 判斷規則（內部 vs 外部 Issue 建立者的定義） |
| AC3 | 一致性 | sprint-execution 同步 | `skills/sprint-execution/SKILL.md` 相關 Issue 狀態更新邏輯與 §2.6 一致 |

**Done 定義**

- [ ] sprint-review SKILL.md §2.6 區分內部/外部 Issue 關閉策略（AC1）
- [ ] 包含明確的判斷規則（AC2）
- [ ] sprint-execution SKILL.md 同步更新（AC3）

---

### US-169：多模型 CLI 路由 Phase 2 — 開源 Adapter 評估與決策

**來源**：Issue #167（Sprint 62 使用者提問延伸）
**Issue**：#167
**Size**：S / 1 Point
**QA doc-only 判定**：Yes（產出評估文件）
**前置依賴**：US-167（Sprint 62，cli-adapter.sh 已完成）

**User Story**

As a framework developer, I want to evaluate existing open-source multi-model CLI adapters against our custom cli-adapter.sh, so that I can decide whether to adopt, fork, or keep the current implementation.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 評估報告存在 | `docs/km/CLI_ADAPTER_EVALUATION.md` 檔案存在 |
| AC2 | 靜態 | 評估維度完整 | 報告涵蓋功能覆蓋、維護活躍度、整合難度、Shikigami 適配性四個維度 |
| AC3 | 靜態 | 決策建議 | 報告含明確建議（採用/fork/維持自建）+ 理由 |

**Done 定義**

- [ ] `docs/km/CLI_ADAPTER_EVALUATION.md` 檔案存在（AC1）
- [ ] 報告涵蓋四個評估維度（AC2）
- [ ] 報告含明確決策建議（AC3）

---

### US-170：Retro Action Items 批次處理 — Sprint 11-12 懸而未決項目清理

**來源**：Issue #168（Sprint 62 Retro Analytics 揭露）
**Issue**：#168
**Size**：S / 1 Point
**QA doc-only 判定**：Yes（修改 Retrospective_Log.md + GitHub Issue 操作）
**前置依賴**：無

**User Story**

As a Scrum Master, I want to resolve the 5 long-standing Retro Action Items (open since Sprint 11-12), so that the Retrospective process maintains credibility.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 逐項審查 | 5 個 Action Items 逐一審查，判定為「已落地」或「仍需處理」 |
| AC2 | 靜態 | 關閉記錄 | 已落地的 Items 在 Retrospective_Log.md 對應 Sprint 記錄中標記 Closed |
| AC3 | 靜態 | 轉換記錄 | 仍需處理的 Items 建立為 GitHub Issue |

**Done 定義**

- [ ] 5 個 Action Items 逐一審查並判定（AC1）
- [ ] 已落地的 Items 標記 Closed（AC2）
- [ ] 仍需處理的 Items 建立為 GitHub Issue（AC3）

---

## Sprint Notes

- **#166 優先級最高**（Must）：直接影響外部使用者體驗的流程缺陷
- **#5/#4/#59 未選入**：#5（Marketplace）和 #4（Cursor）均為明確延後狀態（前置條件未滿足），#59（Beta 回饋）為追蹤型 Issue 非實作 Story
- **全平行**：三個 Story 完全獨立，可同時執行
