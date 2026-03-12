---
title: Decision Journal — 衝突決策思考過程與價值觀取捨記錄
created: 2026-03-12
last_updated: 2026-03-12
maintainer: Developer（手動維護，每次新增決策記錄時同步更新本文件與 Decision_KB_Index.md）
---

# Decision Journal

本文件記錄在 Shikigami 專案中面對衝突面向時的決策思考過程與價值觀取捨。
每筆記錄採用結構化格式，協助未來回顧決策脈絡、審視一致性，並作為團隊學習素材。

**關聯索引**：[Decision_KB_Index.md](./Decision_KB_Index.md) — `## Decision Journal 索引` 區段
**命名規則**：`DJ-NNN`（三位數字流水號，從 001 起）

---

### DJ-001

**日期**：2026-03-12

**情境**：
Sprint 82 需同時執行 US-218（Metrics Dashboard 擴充）與 US-219（Decision Journal 建立）兩個文件型 Story。兩者共用 `docs/km/` 目錄下的索引文件（`Decision_KB_Index.md`），且都需要在同一份索引中新增區段。必須決定是循序執行（降低衝突風險）還是平行執行（縮短 Sprint 週期時間）。

**衝突面向**：

- **選項 A：循序執行**
  US-218 完成後再啟動 US-219，Subagent 不會同時寫入 `Decision_KB_Index.md`，衝突機率趨近於零。但 Sprint 週期時間拉長，無法充分利用平行效能。

- **選項 B：平行執行 + 共用文件保護**
  US-218 與 US-219 同時執行，但明確禁止各自修改 `docs/PROJECT_BOARD.md` 和 `docs/sprints/sprint_82.md` 等共用協調文件；各 Story 只操作自身負責的目標文件（`Decision_Journal.md`、`Metrics_Dashboard.md`），由 Sprint 協調層負責最終合併索引。短期內各 Subagent 看到的 `Decision_KB_Index.md` 是未含對方修改的版本，需在執行後手動對齊。

**決策結果**：
採用 **選項 B（平行執行 + 共用文件保護）**。

**取捨依據**：
- 本 Sprint（Sprint 82）採用 Shikigami 框架的平行 Subagent 模式，縮短交付週期是核心價值。
- US-218 和 US-219 均為 doc-only Story，實際衝突範圍可透過明確的「禁止修改清單」（`PROJECT_BOARD.md`、`sprint_82.md`）隔離，風險可控。
- 選項 A 的機會成本（循序等待）高於選項 B 的合併成本（事後手動對齊索引）。
- 決策優先順序：**交付速度 > 操作便利性 > 零衝突保證**。

**後續追蹤**：
- [ ] Sprint 82 結束後，確認 `Decision_KB_Index.md` 已正確包含 US-218 與 US-219 雙方新增的區段。
- [ ] 若日後平行 Story 數量增加，考慮引入「索引鎖定機制」或拆分索引文件，以降低手動合併成本（可作為 ADR 候選主題）。
- 關聯：Sprint 82 執行紀錄、US-218、US-219

---
