# Sprint 77

**Sprint Goal**：延續 Issue #199 Epic 完成 + E2E 測試管理規範建立 — 完成角色 Refinement 職責定義並建立 E2E Test Case 分層管理標準
**期間**：2026-03-11 ~ 2026-03-18
**ADR 依賴**：無

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-203：角色定義更新 — 7 個角色 Refinement 職責 | #205 | M | 2 | 待開發 |
| US-205：E2E Test Case 管理規範 — 建立分層標記與目錄結構標準 | #200 | M | 2 | 待開發 |

**總計**：4 points（2M）

**權重調整記錄**：歷史趨勢穩定（Sprint 73-76 完成率均 100%），無需調整。

**Architect 平行分群建議**：
- 全序列執行：US-203 (M) → US-205 (M)
- 原因：潛在 qa-engineer/SKILL.md 衝突

---

## 各 Story 詳情

### US-203：角色定義更新 — 7 個角色 Refinement 職責

**Issue**：#205
**MoSCoW**：Must
**Size**：M（2pt）
**doc-only**：NO（skills/ path，ADR-003 applies）

**User Story**：As a Scrum Master，I want 每個角色的 SKILL.md 都包含其在 Refinement 流程中的職責定義，so that 角色在 Refinement 會議中能各司其職，提升精化效率。

**修改範圍**：
- `skills/architect/SKILL.md`
- `skills/sprint-planning/SKILL.md`（PO 職責）
- `skills/sprint-execution/SKILL.md`（Developer 職責）
- `skills/qa-engineer/SKILL.md`
- `skills/security-review/SKILL.md`
- `skills/scrum-master/SKILL.md`（SRE/Scrum Master）
- `agents/stakeholder.md`

**Acceptance Criteria**：

| # | 類型 | 條件 | 通過標準 |
|---|------|------|---------|
| AC1 | [靜態] | 每個角色 SKILL.md 包含 Refinement 職責區塊 | 7 個角色均有 Refinement 職責描述，與 sprint-planning/SKILL.md §9 定義一致 |
| AC2 | [靜態] | Refinement Chair（Architect）職責與 §9 對齊 | architect/SKILL.md §8 跨領域依賴分析 Checklist 已在 Sprint 76 完成，本 Story 補充 Refinement 會議主持職責 |
| AC3 | [靜態] | 各角色 Refinement 輸出格式定義 | 每個角色在 Refinement 時的輸出貢獻明確（如 QA 確認 AC 可測試性、Security 評估安全風險） |
| AC4 | [靜態] | 與現有角色職責無重疊衝突 | 新增的 Refinement 職責不與角色現有職責矛盾 |

**Done 定義**：
- [ ] AC1-AC4 全部通過
- [ ] QA Review PASS

---

### US-205：E2E Test Case 管理規範 — 建立分層標記與目錄結構標準

**Issue**：#200
**MoSCoW**：Must
**Size**：M（2pt）
**doc-only**：YES（output to docs/ only，TDD exempt）

**User Story**：身為開發者，我希望有明確的 E2E test case 管理規範（目錄結構、標記分層、執行策略），以便團隊能一致地撰寫、分類與執行 E2E 測試，避免測試混亂或遺漏關鍵路徑。

**輸出路徑**：`docs/guides/E2E-TEST-MANAGEMENT.md`（new file）

**Acceptance Criteria**：

| # | 類型 | 條件 | 通過標準 |
|---|------|------|---------|
| AC1 | [靜態] | E2E 目錄結構規範 | 定義 `tests/e2e/` 目錄結構標準（按功能模組分類），並記錄於文件 |
| AC2 | [靜態] | 測試分層標記 | 定義 `@smoke`、`@regression`、`@critical` 標記規範，每個標記有明確的選擇標準與執行時機 |
| AC3 | [靜態] | Test Case 篩選標準 | 建立 Risk-based 篩選框架，定義哪些業務流程必須有 E2E 覆蓋（Critical Path 清單） |
| AC4 | [靜態] | CI/CD 整合策略 | 定義 CI 管線中 E2E 的執行策略：部署後 Smoke Suite 自動跑、完整 Regression Suite 排程執行 |
| AC5 | [靜態] | Flaky Test 管理機制 | 定義不穩定測試的隔離（quarantine）、retry 與修復追蹤流程 |
| AC6 | [靜態] | Page Object / Fixture 規範 | 定義 UI 元素封裝（POM 或等效模式）與測試資料管理（fixture/factory）的標準 |

**Done 定義**：
- [ ] AC1-AC6 全部通過
- [ ] QA Review PASS
