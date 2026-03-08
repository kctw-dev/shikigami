# Sprint 60

**狀態**：進行中
**期間**：2026-03-08 ~ 2026-03-14
**Sprint Goal**：輕量化與實踐 — 精簡 Sprint 流程步驟（減法）、完成模型分層 Phase 1 落地、優化 Metrics 分析視窗，鞏固框架持續改善能力。
**ADR 依賴**：無
**總計**：3 Stories / 3 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | doc-only | 狀態 |
|----------|---------|------|------|--------|----------|------|
| US-158 | #155 | Sprint Review / Planning 流程精簡化 — Token Baseline 與 Beta 檢查降級 | S | 1 | 是 | 待開始 |
| US-159 | #156 | 模型分層策略 Phase 1 落地 — SKILL.md + tutorial 新增模型切換提示 | S | 1 | 是 | 待開始 |
| US-160 | #157 | Metrics 計算視窗限制 — 趨勢分析僅讀取最近 30 個 Sprint | S | 1 | 是 | 待開始 |

**Sprint 容量**：3 Points（3 Stories）

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1 | US-158 | 先行執行，修改 sprint-planning/SKILL.md 與 sprint-review/SKILL.md（流程精簡） |
| Phase 2 | US-159, US-160 | US-158 完成後平行執行。US-159 修改 SKILL.md 開頭提示 + tutorial，US-160 修改 SKILL.md §2.7 步驟 4 與 Metrics 計算指引。兩者修改位置不重疊。 |

---

## Story 詳細 AC

---

### US-158：Sprint Review / Planning 流程精簡化 — Token Baseline 與 Beta 檢查降級

**來源**：Architect 減法評估 + 使用者「不只加法也要減法」方向（2026-03-08）
**Issue**：#155
**Size**：S / 1 Point
**QA doc-only 判定**：Yes（純 SKILL.md 修改）
**前置依賴**：無（Phase 1，先行執行）

**User Story**

As a framework user, I want Sprint Review/Planning flow to have fewer unnecessary steps, so that each Sprint cycle is faster and less cognitively demanding.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | sprint-planning SKILL.md §2 Token Baseline Snapshot | 該 checkbox 項目末尾標注 *(慢想模式限定)*，與同節 Token 消耗記錄項目標注格式一致 |
| AC2 | 靜態 | sprint-review SKILL.md §7 Beta 狀態檢查 | Beta 狀態檢查 checkbox 項目已從 §7 執行檢查清單移除 |
| AC3 | 一致性 | sprint-review SKILL.md §1.1 快思模式說明 | §1.1 與 §7 對 Beta 檢查描述一致（已移除或修正） |

**Done 定義**

- [ ] `skills/sprint-planning/SKILL.md` §2 第一項 Token Baseline Snapshot 已標注 *(慢想模式限定)*（AC1）
- [ ] `skills/sprint-review/SKILL.md` §7 Beta 狀態檢查 checkbox 已移除（AC2）
- [ ] `skills/sprint-review/SKILL.md` §1.1 快思模式說明與 §7 對 Beta 檢查描述一致（AC3）

---

### US-159：模型分層策略 Phase 1 落地 — SKILL.md + tutorial 新增模型切換提示

**來源**：US-156 後續 Phase 1 行動（MODEL_TIERING_STRATEGY.md §五）
**Issue**：#156
**Size**：S / 1 Point
**QA doc-only 判定**：Yes（純文件修改）
**前置依賴**：US-158（Phase 2，US-158 完成後執行）

**User Story**

As a framework user, I want to see model recommendations in Sprint Planning/Review skills and tutorial, so that I can choose the optimal model for each task without guessing.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | sprint-planning SKILL.md 開頭 | 存在建議切換至 Opus 模型的提示，位於 §2 之前，含模型名稱與建議原因 |
| AC2 | 靜態 | sprint-review SKILL.md 開頭 | 存在建議切換至 Opus 模型的提示，位於 §2 之前，含模型名稱與建議原因 |
| AC3 | 靜態 | docs/tutorial/README.md | 存在「模型選用建議」段落，含 Planning/Review 建議用 Opus 與切換操作提示 |
| AC4 | 一致性 | AC1 與 AC2 的提示文字 | 兩個 SKILL.md 模型提示格式一致 |

**Done 定義**

- [ ] `skills/sprint-planning/SKILL.md` 開頭新增 Opus 模型切換提示（AC1）
- [ ] `skills/sprint-review/SKILL.md` 開頭新增 Opus 模型切換提示（AC2）
- [ ] `docs/tutorial/README.md` 新增「模型選用建議」段落（AC3）
- [ ] 兩個 SKILL.md 的模型提示格式一致（AC4）

---

### US-160：Metrics 計算視窗限制 — 趨勢分析僅讀取最近 30 個 Sprint

**來源**：使用者 Sprint 59 Review 建議（2026-03-08）
**Issue**：#157
**Size**：S / 1 Point
**QA doc-only 判定**：Yes（純文件修改）
**前置依賴**：US-158（Phase 2，US-158 完成後執行）

**User Story**

As a framework user, I want Metrics trend analysis to only scan the most recent 30 Sprints, so that analytics are faster, less noisy, and context-efficient.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | sprint-review SKILL.md §2.7 步驟 4 趨勢判定演算法 | 明確包含「僅讀取最近 30 個 Sprint 記錄」的視窗限制（數字 30 必須出現） |
| AC2 | 靜態 | sprint-review SKILL.md Sprint Metrics 計算指引步驟 4 | 明確包含相同的 30 Sprint 視窗限制，與既有「取最近三筆 Velocity」邏輯不矛盾 |
| AC3 | 一致性 | AC1 與 AC2 的視窗定義 | 兩處視窗數字均為 30，語意相同 |

**Done 定義**

- [ ] `skills/sprint-review/SKILL.md` §2.7 步驟 4 加入 30 Sprint 視窗限制（AC1）
- [ ] `skills/sprint-review/SKILL.md` Sprint Metrics 計算指引步驟 4 加入 30 Sprint 視窗限制（AC2）
- [ ] 兩處視窗定義一致（AC3）

---

## Sprint Notes

- **策略方向**：使用者明確指示框架演進方向為「輕量化、品質確保、好上手、人機協作」，並強調「不只加法也要減法」（2026-03-08）
- **Backlog 狀態**：Backlog 枯竭持續。本 Sprint 3 個 Story 全部為新建（Sprint 59 Retro 建議 + Architect 減法評估 + 使用者建議），非來自既有 Backlog
- **減法佔比**：3 Stories 中 2 個為減法（US-158 流程精簡化、US-160 Metrics 視窗限制），1 個為加法（US-159 模型分層落地）
- **CLI UX 研究**：使用者建議研究框架 CLI 輸出是否符合 CLI UX 趨勢。記錄為 Backlog 候選，下次 Grooming 評估
