# Sprint 76

**Sprint Goal**：建立 Story 分類與精化機制基礎 — 落地 Story Type 分類系統與 Refinement Chair 制度
**期間**：2026-03-11 ~ 2026-03-18
**ADR 依賴**：無

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-201：Story Type 分類系統定義 | #201 | S | 1 | 完成 |
| US-202：Refinement 機制 | #202 | M | 2 | 完成 |
| US-204：Story Template 更新 | #203 | M | 2 | 完成 |

**總計**：5 points（2M + 1S）

**權重調整記錄**：歷史趨勢穩定（Sprint 73-75 完成率均 100%），無需調整。

**Architect 平行分群建議**：
- 全序列執行：US-201 (S) → US-202 (M) → US-204 (M)
- 原因：三者共用 sprint-planning/SKILL.md，且 US-202/US-204 依賴 US-201 的 Story Type 定義

---

## 各 Story 詳情

### US-201：Story Type 分類系統定義

**Issue**：#201
**MoSCoW**：Must
**Size**：S（1pt）
**doc-only**：YES

**User Story**：As a PO/Architect，I want 每個 Story 都有明確的 Type 分類，so that 不同類型的 Story 能套用適當的 Contract Owner、TDD 策略與 Review 規則。

**修改範圍**：`skills/sprint-planning/SKILL.md` + `skills/sprint-execution/SKILL.md`

**Acceptance Criteria**：

| # | 類型 | 條件 | 通過標準 |
|---|------|------|---------|
| AC1 | [靜態] | sprint-planning/SKILL.md 包含 Story Type 分類定義表格 | 表格定義 6 種 Type（FEATURE/DESIGN/INFRA/SECURITY/INTEGRATION/RESEARCH），每種含定義描述、典型範例、Contract Owner 對照 |
| AC2 | [靜態] | sprint-planning/SKILL.md 包含分類判斷規則 | 決策流程圖或決策表，覆蓋邊界情況（至少 2 個邊界範例） |
| AC3 | [靜態] | sprint-execution/SKILL.md 引用 Story Type 分類 | 說明不同 Type 對 TDD 豁免、Review 策略的影響，且與現有 doc-only 規則（§5）的關係明確 |
| AC4 | [靜態] | Contract Owner 對照表完整且無衝突 | 每種 Type 對應 Owner 無重疊歧義，與現有角色職責一致 |
| AC5 | [靜態] | Story Type 與現有 doc-only 識別規則的關係明確 | 定義 Type 系統與 doc-only 判定的優先順序，無矛盾 |

**Done 定義**：
- [ ] AC1-AC5 全部通過
- [ ] QA Review PASS

---

### US-202：Refinement 機制

**Issue**：#202
**MoSCoW**：Must
**Size**：M（2pt）
**doc-only**：YES

**User Story**：As a PO，I want M/L size 的 Story 在進入 Sprint 前經過結構化的 Refinement 流程，so that 依賴與風險能在開發前被識別，減少 Sprint 中的意外阻塞。

**修改範圍**：`skills/sprint-planning/SKILL.md` + `skills/architect/SKILL.md`

**Acceptance Criteria**：

| # | 類型 | 條件 | 通過標準 |
|---|------|------|---------|
| AC1 | [靜態] | sprint-planning/SKILL.md 定義 Refinement Chair 角色 | Architect 擔任，職責範圍明確，與 §6 Architect subagent 職責區分 |
| AC2 | [靜態] | sprint-planning/SKILL.md 包含 Refinement 觸發條件 | 可判定規則（M/L 須經 Refinement，S 可免除），含豁免例外說明 |
| AC3 | [靜態] | architect/SKILL.md 新增跨領域依賴分析 Checklist | 至少 4 項，每項含判斷條件與處置 |
| AC4 | [靜態] | Refinement 流程與現有 Sprint Planning 銜接 | 與 §2 Checklist 和 §6 派遣順序無矛盾，插入位置明確 |
| AC5 | [靜態] | Refinement 輸出格式定義 | 含 Story Type 確認、依賴分析結果、READY/NOT_READY 結論 |
| AC6 | [靜態] | Refinement 與排程模式（§3.1）互動明確 | 排程模式僅 S-size，S 免除 Refinement，排程模式下完全跳過 Refinement |

**Done 定義**：
- [ ] AC1-AC6 全部通過
- [ ] QA Review PASS

---

### US-204：Story Template 更新

**Issue**：#203
**MoSCoW**：Must
**Size**：M（2pt）
**doc-only**：YES

**User Story**：As a Developer，I want Story Template 包含 story_type 與 Contract 資訊，so that 開發時能依據 Type 套用正確的 DoR/DoD 條件。

**修改範圍**：`skills/sprint-execution/story-lifecycle-prompt.md` + `skills/sprint-planning/SKILL.md`

**Acceptance Criteria**：

| # | 類型 | 條件 | 通過標準 |
|---|------|------|---------|
| AC1 | [靜態] | story-lifecycle-prompt.md 輸入 Schema 新增 story_type 欄位 | 必填，值域為 6 種 Type（FEATURE/DESIGN/INFRA/SECURITY/INTEGRATION/RESEARCH） |
| AC2 | [靜態] | story-lifecycle-prompt.md 新增 Contract 區塊 | 含 Contract Owner、Contract 狀態（Draft/Reviewed/Accepted）、API 契約引用 |
| AC3 | [靜態] | sprint-planning/SKILL.md 定義 Type-specific DoR | 每種 Type 至少 3 項 DoR 條件，以表格呈現 |
| AC4 | [靜態] | sprint-planning/SKILL.md 定義 Type-specific DoD | 與 sprint-execution/SKILL.md §6 DoD 自檢對照表一致，差異項以 [Type-specific] 標記 |
| AC5 | [靜態] | 向後相容 | story_type 缺失時 fallback 至 FEATURE type，行為明確 |
| AC6 | [靜態] | story_type 與 doc_only 欄位關係明確 | 定義哪些 Type 隱含 doc_only=true（如 RESEARCH），衝突組合的處理規則 |

**Done 定義**：
- [x] AC1-AC6 全部通過
- [x] QA Review PASS
