# Sprint 79

**Sprint Goal**：ADR-016 落地 Phase 2 — 解決 UI/UX Designer 5 個 Open Questions，清除 DESIGN Story 進 Sprint 的前置障礙

**期間**：2026-03-11 ~ 2026-03-18
**狀態**：進行中
**ADR 依賴**：ADR-016（Accepted）

---

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 | 備註 |
|-------|-------|------|--------|------|------|
| US-209：ADR-016 OQ-4：Figma MCP 環境健康檢查 Runbook | #212 | S | 1 | 待辦 | doc-only, FEATURE |
| US-210：ADR-016 OQ-2：DESIGN Story Sprint 內排序規則 | #210 | S | 1 | 待辦 | doc-only, FEATURE |
| US-211：ADR-016 OQ-1：Design Foundation Skill 歸屬 | #209 | S | 1 | 待辦 | doc-only, FEATURE |
| US-212：ADR-016 OQ-5：VRR 報告長期儲存策略 | #213 | S | 1 | 待辦 | doc-only, FEATURE |
| US-213：ADR-016 OQ-3：UI/UX Designer Provider 路由 | #211 | S | 1 | 待辦 | doc-only, FEATURE |

**Sprint 容量**：5 points

---

## Story 定義

### US-209：ADR-016 OQ-4：Figma MCP 環境健康檢查 Runbook（S, 1pt, doc-only, FEATURE）

**來源**：ADR-016 OQ-4（優先級：高）

**AC1**：Figma MCP Health Check Runbook 已建立，涵蓋 4 個依賴項檢查序列（Figma Desktop、Plugin 連接、CLI Server、MCP 連接）+ 各依賴失敗的恢復步驟

**AC2**：Runbook 整合至 `skills/uiux-designer/SKILL.md` 或獨立文件

**AC3**：`story-lifecycle-prompt.md` DESIGN path 新增 Health Check pre-flight 步驟

### US-210：ADR-016 OQ-2：DESIGN Story Sprint 內排序規則（S, 1pt, doc-only, FEATURE）

**來源**：ADR-016 OQ-2（優先級：高）

**AC1**：Sprint Execution `SKILL.md` 補充 DESIGN ↔ FEATURE 排序規則（DESIGN Story 是否必須在同 Sprint 的 FEATURE Story 之前完成）

**AC2**：未完成 DESIGN Story 的處理程序已定義（回流 Backlog / 拆分 / 延期）

**AC3**：`story-lifecycle-prompt.md` 補充 DESIGN blocker 檢查邏輯

### US-211：ADR-016 OQ-1：Design Foundation Skill 歸屬（S, 1pt, doc-only, FEATURE）

**來源**：ADR-016 OQ-1（優先級：中）

**AC1**：決策結論已記錄（獨立 `design-foundation` Skill 或整合進 `skills/uiux-designer/SKILL.md`）+ 理由

**AC2**：若整合 — 確認 `skills/uiux-designer/SKILL.md` §3 Design Foundation 流程已完整定義觸發機制；若獨立 — 建立 `skills/design-foundation/SKILL.md`

### US-212：ADR-016 OQ-5：VRR 報告長期儲存策略（S, 1pt, doc-only, FEATURE）

**來源**：ADR-016 OQ-5（優先級：低）

**AC1**：決策結論已記錄（保留期限 / .gitignore / 外部儲存）

**AC2**：實作方案已落地（更新 `.gitignore` 或建立清理腳本）

**AC3**：`skills/vision-critic/SKILL.md` 報告路徑說明已更新

### US-213：ADR-016 OQ-3：UI/UX Designer Provider 路由（S, 1pt, doc-only, FEATURE）

**來源**：ADR-016 OQ-3（優先級：低）

**AC1**：調查結論已記錄 — Figma MCP 在 Gemini CLI 環境的可用性

**AC2**：若可用 — `sprint-execution SKILL.md` §2.1 Provider 路由表新增 designer 角色；若不可用 — 記錄限制，Designer 固定為 claude provider

---

## 平行分群建議

### Phase 1（可平行執行）
| Story | Size | 說明 |
|-------|------|------|
| US-209 | S | OQ-4 Health Check Runbook，獨立文件 |
| US-211 | S | OQ-1 Skill 歸屬決策，獨立議題 |
| US-212 | S | OQ-5 VRR 儲存策略，獨立議題 |
| US-213 | S | OQ-3 Provider 路由調查，獨立議題 |

### Phase 2（需序列執行）
| Story | Size | 衝突原因 |
|-------|------|---------|
| US-210 | S | OQ-2 排序規則依賴 Phase 1 完成後的 DESIGN Story 完整定義，需修改 sprint-execution / story-lifecycle-prompt 共用檔案 |

---

## 權重調整記錄

快思模式，跳過權重調整
