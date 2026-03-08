# Sprint 57

**狀態**：進行中
**期間**：2026-03-08 ~ 2026-03-14
**Sprint Goal**：鞏固 ADR-015 Phase 1 文件一致性 — 同步 Vision Critic SKILL.md 至 Figma 架構、標記舊 UX/UI Agent 文件為 Deprecated。
**ADR 依賴**：ADR-015（Accepted）
**總計**：2 Stories / 2 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | doc-only | 狀態 |
|----------|---------|------|------|--------|----------|------|
| US-153 | #153 | Vision Critic SKILL.md 同步 ADR-015 Figma 架構更新 | S | 1 | 是 | 進行中 |
| US-154 | #152 | UX Agent / UI Agent SKILL.md 標記 Deprecated | S | 1 | 是 | 進行中 |

**Sprint 容量**：2 Points（2 Stories）

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1（並行） | US-153 + US-154 | 兩者皆獨立，無前置依賴，可完全並行執行。無 Phase 2。 |

---

## Story 詳細 AC

---

### US-153：Vision Critic SKILL.md 同步 ADR-015 Figma 架構更新

**來源**：ADR-015 Phase 1 文件一致性補全
**Issue**：#153
**Size**：S / 1 Point
**QA doc-only 判定**：Yes（純文件更新）
**前置依賴**：無（Phase 1，可並行）

**User Story**

As an Architect maintaining the UIUX pipeline skill documentation, I want Vision Critic SKILL.md to be updated to reflect the ADR-015 Figma-based architecture, so that the skill documentation accurately describes the current Figma MCP screenshot review workflow instead of the deprecated SSD-based approach.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | SKILL.md 架構描述更新 | Vision Critic SKILL.md 中的架構描述段落改為反映 ADR-015 Figma 架構：(1) 移除對 SSD/三層管線的引用、(2) 新增 Figma Frame 截圖審查工作流程說明、(3) 標注依賴 ADR-015 |
| AC2 | 靜態 | MCP 工具參照更新 | SKILL.md 中的工具呼叫說明改為反映 Figma MCP 工具（export_node_as_image 或 get_screenshot），移除舊有 SSD 截圖工具參照 |
| AC3 | 靜態 | 評分模型描述對齊 | SKILL.md 中的評分模型描述與 `docs/design/vision-critic-poc-spec.md` 中定義的三維度評分模型一致（佈局一致性、Design Token 符合度、元件規範符合度） |

**Done 定義**

- [ ] Vision Critic SKILL.md 架構描述已移除 SSD 引用並改為 Figma 架構（AC1）
- [ ] MCP 工具參照已更新為 Figma MCP 工具（AC2）
- [ ] 評分模型描述與 vision-critic-poc-spec.md 一致（AC3）

---

### US-154：UX Agent / UI Agent SKILL.md 標記 Deprecated

**來源**：ADR-015 Phase 1 文件一致性補全
**Issue**：#152
**Size**：S / 1 Point
**QA doc-only 判定**：Yes（純文件標記）
**前置依賴**：無（Phase 1，可並行）

**User Story**

As a developer consulting the UIUX pipeline skill documentation, I want UX Agent and UI Agent SKILL.md files to be clearly marked as Deprecated, so that I understand these skills reflect the superseded ADR-014 three-layer pipeline and should not be used for new development.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | UX Agent SKILL.md Deprecated 標記 | UX Agent SKILL.md 頂部新增 Deprecated 警告區塊，內容包含：(1) 廢棄聲明（此文件反映 ADR-014 架構，已被 ADR-015 取代）、(2) 替代方案指引（指向 Figma 管線相關文件）、(3) 廢棄生效日期（2026-03-08） |
| AC2 | 靜態 | UI Agent SKILL.md Deprecated 標記 | UI Agent SKILL.md 頂部新增 Deprecated 警告區塊，內容與 AC1 相同結構，包含廢棄聲明、替代方案指引、廢棄生效日期 |
| AC3 | 備注（Out-of-Scope） | 實際移除或封存檔案 | 非本 Sprint 交付物。標記 Deprecated 即為本 Sprint Done 標準；物理移除或 archive 留待後續 Sprint 評估。 |

**Done 定義**

- [ ] UX Agent SKILL.md 頂部已新增 Deprecated 警告區塊（AC1）
- [ ] UI Agent SKILL.md 頂部已新增 Deprecated 警告區塊（AC2）
- [ ] AC3（物理移除）確認為 Out-of-Scope，不納入本 Sprint Done 判定

---

## 被退回的 Stories

| Story ID | Issue # | 退回原因 | 後續動作 |
|----------|---------|---------|---------|
| US-120 | #124 | 已在 Sprint 54 完成，Issue 已關閉 | 無需處理 |
| US-118 | #142 | 與 ADR-015 架構衝突，AC 基於舊管線設計，需完整重寫 | 回 Backlog，下 Sprint AC 精化後重選 |
| US-143 | #143 | AC 基於 ADR-014，架構衝突，需精化後才可執行 | 回 Backlog，下 Sprint AC 精化後重選 |

---

## Sprint Notes

- **Velocity**：2 pts，低於歷史平均（5-8 pts）。反映 ADR-014 → ADR-015 架構轉型期 Backlog 淨化代價：多個 Backlog items 的 AC 過時，無法直接選入。
- **下 Sprint 建議**：優先處理 Backlog AC 精化（特別是 #142、#143），將過時 AC 對齊 ADR-015 後方可正常選入。
- **Phase 2 說明**：本 Sprint 僅執行 Phase 1（文件一致性補全），Phase 2（深度架構文件重寫）視 Backlog 精化結果排入後續 Sprint。
