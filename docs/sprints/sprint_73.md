# Sprint 73

**Sprint Goal**：落地延期 2 Sprint 的 Retro Action（PO R1 Sonnet 預設）+ 補強部署驗證模板
**期間**：2026-03-11 ~ 2026-03-18
**ADR 依賴**：無

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-192：sprint-planning SKILL.md PO R1 模型改為 Sonnet 預設 | #186 | S | 1 | 完成 |
| US-193：deployment-readiness SKILL.md 新增 L2 API 驗證步驟模板 | #190 | M | 2 | 完成 |

**總計**：3 points

**權重調整記錄**：歷史趨勢穩定（Sprint 68-72 完成率均 100%），無需調整（快思模式）。

**Architect 平行分群建議**：US-192 與 US-193 完全獨立（修改不同 SKILL.md），可完全平行執行，無 ADR 需求。

---

## 各 Story 詳情

### US-192：sprint-planning SKILL.md PO R1 模型改為 Sonnet 預設

**Issue**：#186
**MoSCoW**：Must（已延期 2 Sprint，Retro 連續追蹤）
**Size**：S（1pt）

**User Story**：As a Scrum Master，I want sprint-planning SKILL.md 明確指定 PO Round 1 使用 Sonnet 模型，so that 避免 Opus 超時導致 Planning 流程中斷（Sprint 71 Problem #1 實際發生過）。

**Acceptance Criteria**：

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | SKILL.md §6 步驟 1 model 更新 | `skills/sprint-planning/SKILL.md` 步驟 1（PO Round 1）的 model 指定從 `"opus"` 改為 `"sonnet"` |
| AC2 | 其他步驟 model 不變 | 步驟 2-4（Architect / QA / PO Round 2）維持 `"opus"` 不變 |
| AC3 | 模型策略說明新增 | §0「模型選用建議」區塊新增說明：PO R1 使用 Sonnet，因 Backlog 分析任務 Sonnet 已足夠且更穩定 |
| AC4 | 實際執行確認 | 下次 Sprint Planning 執行時確認 PO R1 實際使用 Sonnet |

---

### US-193：deployment-readiness SKILL.md 新增 L2 API 驗證步驟模板

**Issue**：#190
**MoSCoW**：Should
**Size**：M（2pt）

**User Story**：As a 消費端專案使用者，I want deployment-readiness SKILL.md 提供 L2 API 整合驗證步驟模板，so that 版本 tag 前能自動驗證關鍵 API 端點的 response schema，避免「unit test 過但 Production API 壞了」的情況。

**Acceptance Criteria**：

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | L2 API 驗證步驟區塊新增 | `skills/deployment-readiness/SKILL.md` 新增 L2 API 驗證步驟區塊，插入於 §5 Deployment Checklist 之後（新 §5.1） |
| AC2 | 模板格式設計 | L2 步驟為模板格式（消費端專案自行填入端點清單），非硬編碼特定 API |
| AC3 | Hard Gate 整合 | L2 驗證失敗時阻擋 Release tag（與現有 Hard Gate 機制整合） |
| AC4 | 範例提供 | 提供至少 1 個範例（curl + jq 驗證 response schema 的 snippet） |
