# 歸檔目錄索引

本目錄存放 Sprint 歷史記錄歸檔文件。歸檔機制由 `skills/sprint-review/SKILL.md` 定義，Sprint Review 完成時若歷史 Sprint 區塊超過 5 個則觸發歸檔。

---

## 歸檔文件清單

| 文件 | 說明 | 歸檔範圍 | 最後更新 |
|------|------|----------|----------|
| [PROJECT_BOARD_ARCHIVE.md](PROJECT_BOARD_ARCHIVE.md) | PROJECT_BOARD.md 歷史 Sprint 區塊歸檔 | Sprint 1–84 | 2026-03-12 |
| [RETRO_ARCHIVE.md](RETRO_ARCHIVE.md) | Retrospective_Log.md 歷史 Sprint 記錄歸檔 | Sprint 1–84 | 2026-03-12 |
| [BACKLOG_DONE_ARCHIVE.md](BACKLOG_DONE_ARCHIVE.md) | BACKLOG_DONE.md 歷史 Sprint 完成記錄歸檔 | Sprint 1–84 | 2026-03-12 |

---

## 歸檔規則說明

- **觸發時機**：Sprint Review 完成時
- **觸發條件**：PROJECT_BOARD.md 歷史 Sprint 區塊超過 5 個，或 Retrospective_Log.md Sprint 記錄超過 5 個，或 BACKLOG_DONE.md Sprint 區塊超過 5 個
- **保留策略**：主文件保留當前 Sprint + 最近 2 個 Sprint，超出範圍的歷史記錄移至本目錄歸檔文件
- **歸檔路徑**：
  - PROJECT_BOARD 歸檔 → `docs/km/archive/PROJECT_BOARD_ARCHIVE.md`
  - Retrospective_Log 歸檔 → `docs/km/archive/RETRO_ARCHIVE.md`
  - BACKLOG_DONE 歸檔 → `docs/km/archive/BACKLOG_DONE_ARCHIVE.md`
