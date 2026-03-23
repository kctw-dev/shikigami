# Product Brief: Agent Skills 開放標準對齊評估

**Issue 來源：** #342 研究報告 Issue #5
**優先級：** 中
**日期：** 2026-03-23
**PB 狀態：** Draft

---

## 1. 問題陳述

Shikigami 的 8 個角色定義（PO、Architect、Developer、QA、Security、SRE、UI/UX、Stakeholder）目前採用框架內部格式（YAML frontmatter + Markdown body），未對齊 Anthropic 於 2025 年 12 月發佈的 Agent Skills 開放標準（agentskills.io）。

隨著此標準獲得 Canva、Notion、Figma、Atlassian 等 16+ 主要工具採用，Shikigami 的內部格式形成孤島。若未來有跨平台移植需求（例如：將 Developer 角色移植至 Notion AI 或 Atlassian Rovo）、或吸引社群貢獻，現有格式將造成明顯摩擦。此 Issue 的核心不是「立刻遷移」，而是「先做 Gap Analysis，再決定是否遷移及如何遷移」。

---

## 2. 目標使用者

**主要使用者：** Shikigami 框架維護者與核心貢獻者
- 需要評估框架長期演進路線，決定是否跟進開放標準
- 需要一份客觀的差距分析作為架構決策依據

**次要使用者：** 希望將 Shikigami 角色移植至其他 AI 工具的進階使用者
- 希望角色定義與業界工具有良好相容性
- 希望能直接使用 agentskills.io 上的第三方 Skills 擴充 Shikigami 團隊能力

---

## 3. 商業假設

**假設外顯化（三問）：**

1. **我們假設對齊開放標準能降低社群貢獻門檻** — 若 Shikigami 角色格式與 agentskills.io 相容，更多社群開發者能直接貢獻新角色，而不需學習專屬格式。[UNCERTAIN] 若 Shikigami 的核心使用者本就不期待社群貢獻，此假設的商業價值可能被高估。需確認目前 GitHub 上是否有外部 PR 或 issue 提及格式相容性需求。

2. **我們假設遷移不會破壞現有框架功能** — 格式對齊後，8 個角色的行為表現與現有版本一致，不因格式轉換引入 regression。[UNCERTAIN] 若開放標準的三層資訊階層（metadata → 核心指令 → 動態載入資源）與 Shikigami 的 YAML frontmatter 有結構性衝突，遷移成本可能遠高於預期。

3. **我們假設 Gap Analysis 能在一個 Sprint 內完成** — 一名 Architect 角色可以在一個 Sprint 內完成所有 8 個角色格式與標準的差距分析，輸出可操作的遷移計劃。[UNCERTAIN] 若標準文件本身不夠清晰或頻繁更新，分析工作量可能超出預期。

---

## 4. 提案解決方向

此 PB 為 Discovery 性質，輸出為分析報告與決策建議，而非直接實作遷移。執行步驟：

1. **閱讀標準規格：** 研讀 agentskills.io 完整規格，重點理解三層資訊階層結構及必要 / 選用欄位
2. **現有格式盤點：** 列出 Shikigami 8 個角色定義中所有使用的 YAML 欄位及 Markdown 慣例
3. **Gap Analysis：** 製作對照表，識別：
   - 直接相容（無需修改即可對齊）的部分
   - 需要小幅調整的部分（例如欄位名稱重新命名）
   - 框架特化需求（Shikigami 特有，需擴充標準或保留內部格式）
4. **PoC 遷移：** 選擇 Developer 角色作為 PoC，遷移至標準格式並執行完整測試確認功能無 regression
5. **決策建議：** 基於 PoC 結果，向 Stakeholder 提出「全量遷移 / 部分對齊 / 維持現狀」的決策建議及理由

---

## 5. 成功指標

**Discovery 階段指標（此 PB 範圍）：**
- 完成現有格式 vs. Agent Skills 標準的 Gap Analysis 文件（完成即達標）
- Developer 角色 PoC 遷移完成，且所有現有測試通過（Zero regression）
- 產出包含「建議採用的遷移策略」的決策建議文件

**後續遷移階段指標（本 PB 不含，取決於決策結果）：**
- 若決定全量遷移：8 個角色均對齊標準格式，agentskills.io 相容性驗證通過
- 若決定部分對齊：明確文件化「哪些部分遵循標準、哪些為框架擴充」

---

## 6. 排除範圍

- **不含實際全量遷移：** 此 PB 僅完成 Gap Analysis 與一個角色的 PoC，全量遷移為後續 Issue
- **不含標準以外的新 Skill 開發：** 不在此次評估範圍內新增角色或 Skill
- **不含跨工具整合測試：** 不在 Canva / Notion 等第三方工具上實際測試相容性，此為 PoC 後的可選步驟
- **不含舊格式自動轉換工具：** 若決定遷移，轉換腳本為另一個獨立 Issue

---

## 7. 依賴與風險

**依賴：**
- agentskills.io 標準規格文件必須可公開取得且版本穩定，若標準在評估期間有重大修訂，分析需重做
- Architect 角色負責執行技術 Gap Analysis
- 現有角色測試（`tests/test-*.sh`）必須在 PoC 前確保全部通過，作為基準

**技術風險：**
- **標準鎖定風險：** 若 Shikigami 全量對齊後，agentskills.io 標準出現 breaking change，遷移成本倒流
- **功能退化風險：** 開放標準的設計以通用性為優先，可能無法完整表達 Shikigami 的框架特化需求（如角色間協作協議），需在 PoC 中驗證

**商業風險：**
- **時機風險：** 標準現在仍在快速演進（16+ 夥伴但標準相對年輕），過早全量遷移可能踩到不穩定的規格。Gap Analysis 的建議應反映「等待標準成熟」的可能性
- **社群期待管理：** 若 Gap Analysis 結果公開，使用者可能期待遷移即將發生，需謹慎管理外部溝通
