# Tutorial 目錄

**最後更新**：2026-03-11（US-196 Sprint 74）

本目錄包含 Shikigami 的外部使用者導向文件，協助首次使用者從安裝到第一個 Sprint 完整上手。

---

## 文件清單

| 文件 | 用途 | 適合時機 |
|------|------|---------|
| [GETTING_STARTED.md](./GETTING_STARTED.md) | 入門教學：從安裝到第一個 Sprint 的端對端步驟指引，含指令範例與預期輸出摘要 | 首次安裝、第一次走完整 Sprint 循環 |
| [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) | 常見問題排查指南：6 個常見失敗情境，含症狀描述、根因說明與解決步驟 | 遇到問題、安裝卡關、功能異常 |
| [CDP_TUNNEL_GUIDE.md](./CDP_TUNNEL_GUIDE.md) | CDP 穿隧教學手冊：Chrome remote debugging 啟動 → SSH reverse tunnel → Playwright connectOverCDP，含快速驗證指令與 Troubleshooting | Sprint Review 時需用本地 Chrome 進行探索性 E2E 驗證 |

---

## 快速導覽

**剛安裝完 Shikigami？** → 從 [GETTING_STARTED.md](./GETTING_STARTED.md) 開始

**遇到問題？** → 查看 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

**需要用本地 Chrome 進行 E2E 驗證？** → 查看 [CDP_TUNNEL_GUIDE.md](./CDP_TUNNEL_GUIDE.md)

---

## 模型選用建議

Shikigami 框架會在派遣 subagent 時**自動指定適當模型**，使用者無需手動切換：

| 環節 | 自動選用模型 | 理由 |
|------|------------|------|
| **Sprint Planning** | Opus（自動） | Planning subagent（PO / Architect / QA）派遣時自動指定 `model: "opus"`，用於多步策略推理 |
| **Story Execution（開發）** | Sonnet（自動） | Story-Lifecycle subagent 派遣時自動指定 `model: "sonnet"`，兼顧速度與成本 |
| **Sprint Review** | Sonnet（自動） | Review subagent 使用 Sonnet，常規指標計算與通過標準核對已足夠 |

> 框架透過 Agent tool 的 `model` 參數自動分層，使用者不需要執行 `/model` 切換。詳細策略說明請參閱 [模型分層策略文件](../km/MODEL_TIERING_STRATEGY.md)。

---

## 常見卡關點

本章節針對首次執行 Sprint 時最容易遇到的卡關情境，提供快速排除指引。
若問題屬於安裝環境層面（CLI 認證、Plugin 掛載等），請查閱 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)。

---

### 卡關點 1：Onboarding 完成但後續 Sprint 執行品質異常

**問題描述**

執行 `幫我初始化 Shikigami` 後，CLAUDE.md 雖然建立，但內容只有預設骨架（專案名稱、技術棧未填寫），導致 Sprint Planning 時 PO subagent 無法正確理解專案情境，產出的 User Story 或 AC 品質偏低。

**排除步驟**

1. 確認 CLAUDE.md 已建立：`ls CLAUDE.md`
2. 開啟 CLAUDE.md 確認「專案目標」和「技術棧」欄位是否已填寫（非佔位符）
3. 若欄位空白，對 Claude 說：「請協助我補全 CLAUDE.md 的專案資訊」
4. 填寫完成後重新執行 standup 確認健康狀態正常：說「standup」
5. 重新開始 Sprint Planning，PO subagent 會讀取更新後的 CLAUDE.md

---

### 卡關點 2：Sprint Execution 中 Subagent 停滯或無回應

**問題描述**

執行 Sprint Execution 時，Developer 或 QA subagent 在處理中途停止回應，或輸出截斷後不繼續，尤其在執行大型 Story 或 context 積累多個 Sprint 後容易發生。這是 context window 接近上限的表現。

**排除步驟**

1. 等候 30 秒確認 subagent 確實停滯（非正常思考延遲）
2. 對 Claude 說：「subagent 停滯了，請從上次中斷的地方繼續」
3. 若仍無回應，開啟新 Session 後說：「請繼續執行 US-#N，從 [停滯的 AC 編號] 開始」
4. 若問題持續發生，將大型 Story（M/L size）拆分為多個 S size Story 後重新 Planning
5. 定期執行 Sprint Review 清理 context，避免累積過多歷史資訊

---

### 卡關點 3：Sprint 文件無法被 Sprint Review 正確讀取

**問題描述**

執行 Sprint Review 時，PO subagent 回報「找不到本 Sprint 的完成 Stories」或 Velocity 計算結果為 0，即使 Developer 已完成 Story 實作。通常是 Sprint 文件中 Story 狀態欄位格式不一致所致。

**排除步驟**

1. 確認 Sprint 文件存在：`ls docs/sprints/`
2. 開啟目前 Sprint 文件，確認完成的 Story 狀態標記為 `done` 或 `完成`（而非其他格式）
3. 若狀態格式不一致，對 Claude 說：「請更新 sprint_N.md 中 US-#N 的狀態為完成」
4. 確認 Sprint 文件的 Story 列表包含正確的 Story ID（US-#N 格式）
5. 重新執行 Sprint Review：說「執行 Sprint Review」

> 若問題涉及 Sprint 文件結構損壞，可參閱 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)。

---

### 卡關點 4：第一個 Story 的 AC 過多導致 Developer 無法完成

**問題描述**

第一個 Sprint 的 Story 被規劃了 6 個以上的 AC，Developer subagent 嘗試完整實作時 context 耗盡或輸出不完整，Sprint Execution 無法順利走完。這通常是需求粒度過大的問題。

**排除步驟**

1. 查看 Sprint 文件確認該 Story 的 AC 數量和複雜度
2. 若 AC 超過 5 個或有複雜的外部依賴，對 Claude 說：「請協助拆分 US-#N 為更小的 Stories」
3. Architect subagent 會建議合理的拆分方式（每個子 Story 建議 3-5 個 AC）
4. 拆分後重新執行 Sprint Planning，讓 QA Hard Gate 審查新的 AC
5. 從拆分後的第一個子 Story 開始執行 Sprint Execution

> 經驗法則：首次 Sprint 建議每個 Story 以 S size（1-2pt）為主，AC 控制在 3-5 個。

---

### 卡關點 5：Backlog 空了但不知道如何繼續下一個 Sprint

**問題描述**

第一個 Sprint 完成後，準備開始下一個 Sprint 時發現 PRODUCT_BACKLOG.md 中沒有待執行的 Story，或所有 Story 都已標記為完成，導致 Sprint Planning 無 Story 可選。

**排除步驟**

1. 確認 Backlog 現況：說「查看目前的 Backlog 優先順序」
2. 若 Backlog 為空，向 Claude 說明你的下一個功能目標：「我想增加 [功能描述] 功能」
3. PO subagent 會分析需求並產出新的 User Stories，加入 PRODUCT_BACKLOG.md
4. 確認新 Stories 已加入後，開始 Sprint Planning：說「開始下一個 Sprint Planning」
5. 若有待優化的既有功能，也可說：「我想重構 [模組名稱] 的 [問題描述]」

> 持續補充 Backlog 是健康 Scrum 流程的一部分，建議在每個 Sprint Review 後就思考下一個 Sprint 的方向。

---

### 卡關點 6：git commit 失敗導致 TDD 循環中斷

**問題描述**

Developer subagent 在 TDD 循環的 commit 步驟時，因為 pre-commit hook 失敗（如 linting 錯誤、測試失敗）導致 commit 被拒絕，Developer 停滯在 Green 或 Refactor 階段，Sprint Execution 無法繼續。

**排除步驟**

1. 查看 Developer 輸出中的錯誤訊息，確認是 pre-commit hook 觸發的哪個錯誤
2. 對 Claude 說：「pre-commit hook 失敗，錯誤是 [錯誤訊息]，請修正後重新 commit」
3. Developer 會針對錯誤修正代碼（如修正 lint 問題、補全失敗測試），並重新 commit
4. 若 hook 是測試失敗，確認是新寫的測試設計問題還是既有測試回歸問題
5. 修正後確認 commit 成功：說「確認最近的 git log 是否有正確的 commit 記錄」

> 注意：絕不跳過 pre-commit hook（`--no-verify`）。hook 失敗代表有真實問題需要修正，跳過會累積技術債。

---

## 相關文件

- [README.md（專案入口）](../../README.md) — 完整功能說明、7 個角色介紹、22 個 Skills
- [安裝驗證報告](../km/INSTALL_VERIFICATION.md) — 安裝流程系統性驗證記錄（US-15）
- [Project Board](../PROJECT_BOARD.md) — Sprint 進度看板與工件導覽
