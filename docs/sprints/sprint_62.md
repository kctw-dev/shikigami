# Sprint 62

**狀態**：進行中
**期間**：2026-03-08 ~ 2026-03-14
**Sprint Goal**：新手體驗提升與框架減法落地 — 系統化整理首次 Sprint 常見卡關點指引（M5 條件 (a) 前提），並執行 SKILL.md 冗餘內容合併精簡（延續減法策略）。
**ADR 依賴**：無
**總計**：3 Stories / 4 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | doc-only | 狀態 |
|----------|---------|------|------|--------|----------|------|
| US-165 | #164 | Tutorial 新手體驗改善 — 首次 Sprint 成功率提升（錯誤訊息說明 + 常見卡關點指引） | S | 1 | 是 | 完成 |
| US-166 | #163 | 框架文件精簡 — SKILL.md 重複指引合併與冗餘步驟移除 | S | 1 | 是 | 完成 |
| US-167 | #165 | 多模型 CLI 路由 Phase 1 — Adapter 介面設計與 Gemini CLI 整合實作 | M | 2 | 否 | 待開始 |

**Sprint 容量**：4 Points（3 Stories）

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1 | US-165, US-166 | 兩者完全獨立，可同時平行執行。US-165 修改 `docs/tutorial/` 下文件，US-166 修改 `skills/*/SKILL.md`，檔案零重疊。 |
| Phase 2 | US-167 | 依賴 US-163（Sprint 61）調查報告，與 Phase 1 無檔案衝突，但因 M-size 建議在 Phase 1 完成後執行以保留修復空間。 |

---

## 方法論適用性評估

| Story ID | BDD 適用 | DDD 適用 | 說明 |
|----------|----------|----------|------|
| US-165 | 不適用 | 不適用 | doc-only，所有 AC 為 [靜態]，無行為規格需求 |
| US-166 | 不適用 | 不適用 | doc-only，所有 AC 為 [靜態]，AC4 約束不改變行為語意 |
| US-167 | 不適用 | 不適用 | Adapter 介面為技術實作，無多執行路徑分支、無狀態轉換、無領域模型 |

---

## Story 詳細 AC

---

### US-165：Tutorial 新手體驗改善 — 首次 Sprint 成功率提升（錯誤訊息說明 + 常見卡關點指引）

**來源**：Issue #164（US-164 Backlog Grooming 提案）
**Issue**：#164
**Size**：S / 1 Point
**QA doc-only 判定**：Yes（修改 Tutorial 文件）
**前置依賴**：無（Phase 1，可平行）

**User Story**

As a new user trying Shikigami for the first time, I want a "Common Pitfalls" guide in the Tutorial that covers at least 5 typical first-Sprint blockers with step-by-step resolution, so that I can resolve issues within 5 minutes and complete my first Sprint successfully.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 卡關點識別 | 至少識別 5 個首次 Sprint 常見卡關點，每個含問題描述 + 排除步驟 |
| AC2 | 靜態 | Tutorial 章節新增 | `docs/tutorial/README.md` 新增「常見卡關點」章節 |
| AC3 | 靜態 | 排除步驟簡潔性 | 每個卡關點的排除步驟不超過 5 個步驟（代理判定：步驟數 ≤ 5 視為可在 5 分鐘內完成） |
| AC4 | 一致性 | 與 TROUBLESHOOTING.md 互補 | 與 `docs/tutorial/TROUBLESHOOTING.md` 互補不重複，有交叉引用連結 |

**Done 定義**

- [ ] 至少識別 5 個首次 Sprint 常見卡關點，每個含問題描述 + 排除步驟（AC1）
- [ ] `docs/tutorial/README.md` 新增「常見卡關點」章節（AC2）
- [ ] 每個卡關點的排除步驟不超過 5 個步驟（AC3）
- [ ] 與 TROUBLESHOOTING.md 互補不重複，有交叉引用連結（AC4）

---

### US-166：框架文件精簡 — SKILL.md 重複指引合併與冗餘步驟移除

**來源**：Issue #163（US-164 Backlog Grooming 提案，承接 US-162 審查報告）
**Issue**：#163
**Size**：S / 1 Point
**QA doc-only 判定**：Yes（修改 SKILL.md 文件）
**前置依賴**：US-162 審查報告已完成（`docs/km/SKILL_REDUCTION_REVIEW.md`）

**User Story**

As a framework maintainer, I want to consolidate duplicated instructions across SKILL.md files by merging redundant content and removing obsolete sections, so that the framework documentation is leaner and easier to maintain.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 冗餘合併數量 | 至少合併 3 處 SKILL.md 冗餘內容（依 `docs/km/SKILL_REDUCTION_REVIEW.md` 行動清單） |
| AC2 | 靜態 | QA 審查通過 | QA subagent Spec Compliance review 通過 |
| AC3 | 靜態 | 行數減少 | 被修改的 SKILL.md 檔案行數總和減少至少 5% |
| AC4 | 靜態 | 語意不變 | 合併不改變原有行為語意（功能指引不遺漏） |

**Done 定義**

- [ ] 至少合併 3 處 SKILL.md 冗餘內容（AC1）
- [ ] QA subagent Spec Compliance review 通過（AC2）
- [ ] 被修改的 SKILL.md 檔案行數總和減少至少 5%（AC3）
- [ ] 合併不改變原有行為語意（AC4）

---

### US-167：多模型 CLI 路由 Phase 1 — Adapter 介面設計與 Gemini CLI 整合實作

**來源**：Issue #165（Issue #159 拆分，Phase 1 實作）
**Issue**：#165
**Size**：M / 2 Points
**QA doc-only 判定**：No（涉及 Bash function/script 實作）
**前置依賴**：US-163（Sprint 61，Gemini CLI 調查報告已完成）

**User Story**

As a framework developer, I want a standardized adapter interface for invoking third-party CLI tools (Gemini CLI) as subagents, so that the framework can leverage the best available model for each task without being locked into a single provider.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | Adapter 介面定義 | 建立統一的 CLI adapter 呼叫模板（Bash function 或 markdown 規格），定義 prompt-in / result-out 標準格式 |
| AC2 | 動態 | Gemini CLI 整合 | 至少一個 subagent 角色（如 Developer）可透過配置切換為 Gemini CLI 執行 |
| AC3 | 動態 | 降級策略 | Gemini CLI 失敗時自動 fallback 回 Claude，並記錄失敗原因 |
| AC4 | 動態 | 不破壞現有流程 | 修改後預設行為維持 Claude，現有 Sprint 流程不受影響 |

**Done 定義**

- [ ] 建立統一的 CLI adapter 呼叫模板（AC1）
- [ ] 至少一個 subagent 角色可透過配置切換為 Gemini CLI 執行（AC2）
- [ ] Gemini CLI 失敗時自動 fallback 回 Claude（AC3）
- [ ] 預設行為維持 Claude，現有流程不受影響（AC4）

---

## Sprint Notes

- **加法 + 減法平衡**：US-165 做加法（Tutorial 新手體驗改善），US-166 做減法（SKILL.md 精簡），呼應框架方向「輕量化、好上手、不只加法也要減法」
- **前置產出延續**：US-166 直接承接 Sprint 61 US-162 的減法審查報告（5 處冗餘行動清單）
- **容量提升**：使用者要求排入所有可用 backlog Story，容量從 2pt 擴增至 4pt
- **Phase 1 平行**：US-165 + US-166 修改檔案零重疊（`docs/tutorial/*` vs `skills/*`），可同時平行執行
- **Phase 2 序列**：US-167 為 M-size 實作型 Story，建議在 Phase 1 完成後執行
