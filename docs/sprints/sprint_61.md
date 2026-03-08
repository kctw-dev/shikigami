# Sprint 61

**狀態**：完成
**期間**：2026-03-08 ~ 2026-03-14
**Sprint Goal**：Backlog 健康化與框架減法持續 — 補充 Backlog 候選 Story 池（解決連續 3 Sprint 枯竭問題），並延續「不只加法也要減法」方向，評估框架流程與文件的進一步精簡機會。
**ADR 依賴**：無
**總計**：3 Stories / 3 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | doc-only | 狀態 |
|----------|---------|------|------|--------|----------|------|
| US-162 | #160 | 框架流程減法審查 — SKILL.md 冗餘步驟與重複內容清理 | S | 1 | 是 | 完成 |
| US-163 | #161 | 多模型 CLI 路由 Phase 0 — Gemini CLI 呼叫介面調查（Issue #159 拆分） | S | 1 | 是 | 完成 |
| US-164 | #162 | Backlog Grooming — 現有 Issues RICE 評分補齊 + 新候選 Story 提案 | S | 1 | 是 | 完成 |

**Sprint 容量**：3 Points（3 Stories）

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1 | US-162, US-163, US-164 | 三者完全獨立，可同時平行執行。US-162 審查 SKILL.md 冗餘（不修改），US-163 調查 Gemini CLI 介面（產出文件），US-164 操作 GitHub Issues（不修改本地檔案）。 |

---

## 方法論適用性評估

| Story ID | BDD 適用 | DDD 適用 | 說明 |
|----------|----------|----------|------|
| US-162 | 不適用 | 不適用 | 純審查報告產出，無行為規格需求 |
| US-163 | 不適用 | 不適用 | 調查型任務，產出技術文件，無領域模型 |
| US-164 | 不適用 | 不適用 | Backlog 管理操作，非功能開發 |

---

## Story 詳細 AC

---

### US-162：框架流程減法審查 — SKILL.md 冗餘步驟與重複內容清理

**來源**：使用者「不只加法也要減法」方向延續（2026-03-08）
**Issue**：#160
**Size**：S / 1 Point
**QA doc-only 判定**：Yes（純審查報告，不修改 SKILL.md）
**前置依賴**：無（Phase 1，可平行）

**User Story**

As a framework maintainer, I want a structured review identifying redundant steps and duplicated content across SKILL.md files, so that I have a clear action list for future simplification Sprints.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 審查報告內容 | 產出審查報告，識別至少 3 處 SKILL.md 中的冗餘/重複項目 |
| AC2 | 靜態 | 識別項目結構 | 每處識別項目包含 (a) 所在檔案路徑 (b) 具體段落引用 (c) 冗餘理由說明 |
| AC3 | 靜態 | 不修改 SKILL.md | 本 Sprint 不修改任何 SKILL.md（git diff 對 skills/*/SKILL.md 無變更） |

**Done 定義**

- [ ] 審查報告識別至少 3 處 SKILL.md 冗餘/重複項目（AC1）
- [ ] 每處項目含檔案路徑、段落引用、冗餘理由（AC2）
- [ ] `skills/*/SKILL.md` 無任何變更（AC3）

---

### US-163：多模型 CLI 路由 Phase 0 — Gemini CLI 呼叫介面調查（Issue #159 拆分）

**來源**：Issue #159 拆分，Phase 0 調查階段
**Issue**：#161
**Size**：S / 1 Point
**QA doc-only 判定**：Yes（純調查文件產出）
**前置依賴**：無（Phase 1，可平行）

**User Story**

As a framework developer, I want a documented investigation of Gemini CLI's invocation interface, output format, and prompt constraints, so that I can design a reliable multi-model routing mechanism in subsequent phases.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | 調查文件存在 | `docs/km/GEMINI_CLI_INVESTIGATION.md` 檔案存在 |
| AC2 | 靜態 | 文件結構完整 | 文件包含三個章節（呼叫方式、輸出格式、Prompt 限制），每章有結論或標注「待確認（原因）」 |
| AC3 | 靜態 | 結論充足性 | 至少 2 個章節有明確結論（非全部「待確認」） |
| AC4 | 一致性 | 調查 metadata | 文件記錄調查日期與 CLI 版本 |

**Done 定義**

- [x] `docs/km/GEMINI_CLI_INVESTIGATION.md` 檔案存在（AC1）
- [x] 文件包含呼叫方式、輸出格式、Prompt 限制三章節（AC2）
- [x] 至少 2 個章節有明確結論（AC3）
- [x] 文件記錄調查日期與 CLI 版本（AC4）

---

### US-164：Backlog Grooming — 現有 Issues RICE 評分補齊 + 新候選 Story 提案

**來源**：連續 3 Sprint Backlog 枯竭問題
**Issue**：#162
**Size**：S / 1 Point
**QA doc-only 判定**：Yes（GitHub Issue 操作，不修改本地框架檔案）
**前置依賴**：無（Phase 1，可平行）

**User Story**

As a product owner, I want existing backlog issues scored with RICE and new candidate stories proposed, so that the next Sprint Planning has a healthy pool of prioritized items to choose from.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | RICE 評分覆蓋 | GitHub 上至少 5 個 `status: backlog` Issue 有 RICE Score |
| AC2 | 靜態 | MoSCoW 標籤 | 上述 Issue 均帶 MoSCoW priority label |
| AC3 | 靜態 | 新建 Issue 入庫 | 新建 Issue 帶 `backlog-intake-done` label |
| AC4 | 靜態 | 不修改本地檔案 | 不修改本地框架檔案 |

**Done 定義**

- [ ] 至少 5 個 `status: backlog` Issue 有 RICE Score（AC1）
- [ ] 上述 Issue 均帶 MoSCoW priority label（AC2）
- [ ] 新建 Issue 帶 `backlog-intake-done` label（AC3）
- [ ] 本地框架檔案無變更（AC4）

---

## Sprint Notes

- **Backlog 健康化**：連續 3 Sprint（59-61）Backlog 枯竭，US-164 直接處理此問題，補充候選 Story 池
- **減法延續**：US-162 延續「不只加法也要減法」方向，但本 Sprint 僅審查不修改，為後續精簡 Sprint 建立行動清單
- **多模型路由**：US-163 是 Issue #159 的 Phase 0 拆分，先調查再設計，降低後續實作風險
- **全平行**：三個 Story 完全獨立，無依賴關係，可同時執行以最大化效率
