# Sprint 47

**狀態**：進行中
**期間**：2026-03-05 ~ 2026-03-11
**Sprint Goal**：為 shikigami:diagram 技能建立架構決策基礎 — 起草 ADR-013，評估 MCP 整合架構（部署形態、transport 選型、CI 整合、安全考量），為 Issue #89 實作提供可信的技術前提。
**總計**：1 Story / 1 Point

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | Phase | 狀態 |
|----------|---------|------|------|--------|-------|------|
| US-96 | #95 | ADR-013 起草 — shikigami:diagram MCP 整合架構決策 | S | 1 | Phase 1 | 進行中 |

**Sprint 容量**：1 Point

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1 | US-96 | 單一 Story，無並行需求 |

---

## Story 詳細 AC

---

### US-96：ADR-013 起草 — shikigami:diagram MCP 整合架構決策

**來源**：Issue #95（Issue #89 前置 ADR）
**Size**：S / 1 Point
**Owner**：Architect
**QA doc-only 判定**：Yes（純 ADR 文件）
**ADR 參考**：ADR-006、ADR-011、ADR-012

**User Story**

As an Architect, I want a formal Architecture Decision Record evaluating the MCP integration architecture for the shikigami:diagram skill, so that Issue #89 implementation has a validated technical foundation covering deployment model, transport protocol, CI integration, and security considerations.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | ADR-013 文件建立 | `docs/adr/ADR-013-diagram-skill-mcp-integration.md` 存在，包含 Status、Context、Decision Drivers、Options、Decision Outcome |
| AC2 | [靜態] | 四個決策域涵蓋 | 涵蓋：部署形態（Cloud Run vs stdio local）、MCP transport（HTTP+SSE vs stdio）、CI 整合策略、安全考量 |
| AC3 | [靜態] | 選項比較矩陣 | 每個決策域至少列出 2 個選項並以優缺點矩陣比較 |
| AC4 | [靜態] | ADR 引用 | 明確引用 ADR-006（Injection 防護）、ADR-011（GitHub Actions）、ADR-012（GCE 認證） |
| AC5 | [靜態] | ADR Status | Status 設為 Proposed 或 Accepted |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 2 | 影響 diagram 技能及未來 MCP 整合決策 |
| Impact | 3 | 解鎖 Issue #89（L-size），提供架構決策基礎 |
| Confidence | 0.9 | ADR 起草格式成熟，決策域已識別 |
| Effort | 1 | S-size；純文件工作 |
| **RICE Score** | **5.4** | R×I×C/E |

**Done 定義**

- [ ] ADR-013 文件建立於 `docs/adr/` 下（AC1）
- [ ] 涵蓋四個決策域（AC2）
- [ ] 每個決策域含選項比較矩陣（AC3）
- [ ] 引用 ADR-006、ADR-011、ADR-012（AC4）
- [ ] Status 為 Proposed 或 Accepted（AC5）

---

## ADR 觸發清單

| Story | ADR | 觸發原因 | 動作 |
|-------|-----|----------|------|
| US-96 | ADR-013 | Story 本身即為 ADR 起草 | 建立 ADR-013 |

---

## Sprint Planning 簽核記錄

| 角色 | 確認項目 | 狀態 |
|------|----------|------|
| Product Owner | Sprint Goal 對齊 Issue #89 前置工作，Backlog 狀態已評估 | 已確認 |
| Architect | S-size 合理（純文件），四個決策域識別完成 | 已確認 |
| QA | doc-only 判定，AC 可測試 | 已確認 |
| Developer | Story 清晰度確認 | 待確認 |

**Sprint Planning 決策記錄**

- Sprint 47 選入 1 Story（US-96 #95），共 1 Point
- Backlog 接近耗盡，僅剩 Issue #89（L-size），本 Sprint 執行前置 ADR 以解鎖後續實作
- 目標 Velocity：1 Point
