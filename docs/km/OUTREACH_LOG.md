# Shikigami — 推廣行動記錄（Outreach Log）

**用途**：記錄所有外部社群推廣行動的完整細節，供團隊追蹤推廣進展與累積效果。
**建立日期**：2026-03-03
**負責角色**：Developer（依 Sprint Story 指派更新）

---

## 與 M5_COMPLETION_ASSESSMENT.md 的分工

| 文件 | 職責範圍 |
|------|----------|
| **OUTREACH_LOG.md（本文件）** | 記錄每一次推廣行動的完整細節（日期、管道、行動內容、結果量化數據）；作為推廣行動的原始台帳 |
| **M5_COMPLETION_ASSESSMENT.md** | 僅追蹤 M5 條件 (a) 的達成狀態；引用本文件的累積回饋數作為達成判斷依據，不重複記錄行動細節 |

**原則**：任何推廣行動細節僅在本文件記錄一次，M5 文件透過「累積回饋數」單一指標判斷條件是否達成。

---

## 推廣行動記錄

### 欄位說明

| 欄位 | 說明 |
|------|------|
| **推廣日期** | 行動執行日期（YYYY-MM-DD） |
| **管道** | 推廣管道（如：GitHub README、Issue、社群論壇、技術文章、直接邀請等） |
| **行動摘要** | 本次行動的具體內容描述 |
| **累積回饋數** | 截至該行動後，從外部使用者收到的有效回饋總數（Issue #59 留言數） |
| **負責角色** | 執行或提案本行動的角色（Owner） |

---

### 行動記錄表

| # | 推廣日期 | 管道 | 行動摘要 | 累積回饋數 | 負責角色 |
|---|----------|------|----------|------------|----------|
| 1 | 2026-03-03 | GitHub README | 新增「Beta 使用者招募」區段（US-53，Sprint 29）：邀請文案、試用對象說明（Claude Code / OpenCode）、Issue #59 直連連結 | 0 | Developer |
| 2 | 2026-03-03 | GitHub Issue | 建立 Issue #59「Beta 回饋收集」（US-53，Sprint 29）：已 pin、已套用 beta-feedback label；包含結構化回饋模板（OS/版本、安裝結果、Sprint 完成度、問題描述、1-5 評分） | 0 | Developer |
| 3 | 2026-03-03 | GitHub README | 新增「5 分鐘快速試用」5 步驟指引（US-61，Sprint 32）：從安裝到第一次執行的最低摩擦路徑，降低試用門檻 | 0 | Developer |
| 4 | 2026-03-03 | 安裝指南優化 | GETTING_STARTED.md 修正 2 處高摩擦步驟（US-61，Sprint 32）：Claude Code CLI 安裝指令內嵌、gh auth 認證前置說明 | 0 | Developer |
| 5 | 2026-03-03 | 安裝指南優化 | INSTALL_OPENCODE.md 修正 2 處高摩擦步驟（US-61，Sprint 32）：OpenCode 安裝一行指令內嵌、symlink 三行指令精簡為單行 | 0 | Developer |
| 6 | 2026-03-03 | GitHub README | 新增 version badge 與 license badge（US-64，Sprint 33）：提升專案可信度視覺信號；Shield.io 格式，位於 H1 標題之後 | 0 | Developer |

---

## 累積統計

| 指標 | 數值 | 最後更新 |
|------|------|----------|
| 推廣行動總數 | 6 | 2026-03-03 |
| 累積外部回饋數 | 0 | 2026-03-03 |
| M5 條件 (a) 達成狀態 | 未達成（需 >= 1） | 2026-03-03 |

---

## 更新指引

每次執行新的推廣行動後：

1. 在「行動記錄表」新增一列，填入所有欄位
2. 更新「累積統計」中的推廣行動總數與最後更新日期
3. 確認 Issue #59（`gh issue view 59 --comments`）最新回饋數，更新累積外部回饋數
4. 若累積回饋數 >= 1，更新 M5 條件 (a) 達成狀態為「已達成」，並同步更新 `docs/prd/M5_COMPLETION_ASSESSMENT.md`
5. 提交 commit，格式：`docs: 更新 OUTREACH_LOG — [行動摘要]（Sprint XX）`
