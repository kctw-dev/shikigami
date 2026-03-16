# Product Brief：統一 Ship 管線（Unified Ship Pipeline）

---

## 基本資訊

| 欄位 | 內容 |
|------|------|
| Brief ID | PB-2026-03-15-unified-ship-pipeline |
| 功能名稱 | 統一 Ship 管線（Unified Ship Pipeline） |
| 作者 | PO |
| 建立日期 | 2026-03-15 |
| 狀態 | **草稿** |
| 觸發來源 | Issue #271 — gstack vs Shikigami 競品分析（第 5 章，中價值項目） |
| 關聯 Skill | shoot、sprint-execution、sprint-review、git-workflow |

---

## Discovery Phase — Step 1：背景分析

### 核心發現（來自 Issue #271）

Issue #271 競品分析指出，gstack 的 `/ship` 指令一鍵串完完整的 Ship 管線：

```
test → review → version bump → changelog → commit → push → PR
```

使用者執行一個命令，框架自動完成從測試到建立 PR 的全部流程，中間不需要手動切換工具或記憶步驟順序。

相比之下，Shikigami 目前的相同工作流程分散在多個 Skill 中：

| 步驟 | 在 Shikigami 的對應機制 |
|------|----------------------|
| test | `sprint-execution` 中的 TDD 流程、`quality-gate` |
| review | `quality-gate`、`shoot` 的 QA Post-check |
| version bump | 無自動化 Skill，需手動執行或在 `shoot` / `sprint-review` 中提及 |
| changelog | `sprint-review` 產出 CHANGELOG.md 更新 |
| commit | `shoot` 的 `shoot:` 前綴 commit、`git-workflow` |
| push | 散落在各 Skill 的流程說明中 |
| PR | 無標準化 PR 建立流程 |

Issue #271 識別出「全自動 Ship 管線」是 Shikigami 相對 gstack 的一個差距，建議透過協調現有多個 Skill 的串接來縮小此差距。

### 與現有 Skill 的關係

查閱現有 Skill 後確認：

- `/shoot` 已實作 commit + push，但沒有 version bump 和 changelog 步驟
- `sprint-review` 負責 changelog 更新，但在 Sprint 結束時才觸發，不在單一 Story 完成後觸發
- `git-workflow` 定義了 commit 規範，但沒有 PR 建立邏輯
- 目前沒有任何 Skill 負責版號 bump 的觸發邏輯

---

## Discovery Phase — Step 2：假設外顯化（三問機制）

### 候選需求：統一 Ship 管線

**問題 1：這個需求解決了什麼問題？**

使用者在完成一個功能後，需要記憶並手動執行多個步驟才能把工作交付出去（commit、push、bump 版號、更新 changelog、建 PR）。這些步驟分散在不同 Skill 中，沒有統一的觸發點。使用者容易遺漏步驟（如忘記 bump 版號、忘記更新 changelog），或在工具切換間浪費認知資源。

**問題 2：我們假設哪些事情是真的？**

| # | 假設 | 標籤 |
|---|------|------|
| A1 | 使用者確實在意「version bump + changelog」的自動化，而非只關心 commit + push | [UNCERTAIN] |
| A2 | 存在一個明確的「Ship 觸發點」——即使用者能明確區分「這個工作已完成，現在要 Ship」的時機 | [UNCERTAIN] |
| A3 | Shikigami 框架的使用者使用 GitHub（或 gh CLI 可用的 Git hosting）建立 PR | [UNCERTAIN] |
| A4 | 統一的 Ship 管線與現有 `/shoot` 的定位可以共存，不造成功能重疊混淆 | [UNCERTAIN] |
| A5 | Version bump 規則（major/minor/patch 的觸發條件）在框架層面可以統一定義，不需要每個專案自訂 | [UNCERTAIN] |
| A6 | Changelog 格式統一為 `CHANGELOG.md`（Keep a Changelog 格式），不需要支援多種格式 | 假設成立（框架目前使用此格式） |

**問題 3：如果假設是錯的，會怎樣？**

- A1 為假：若使用者只需要 commit + push，版號 bump 和 changelog 是過度工程，gstack 的差距實際上不重要。
- A2 為假：若「Ship 時機」不明確（如 Sprint 中間完成部分功能），統一管線可能在不適當時機觸發 version bump。
- A3 為假：若使用者用 GitLab 或不使用 gh CLI，PR 建立步驟無法執行，管線在最後一步失敗。
- A4 為假：統一管線與 `/shoot` 定位重疊，使用者不知道何時用哪個，造成混淆。
- A5 為假：若每個用 Shikigami 的專案的版號規則不同，框架層面的統一定義無效。

---

## 1. 問題陳述（Problem Statement）

Shikigami 的交付流程（test → version → changelog → commit → push → PR）分散在多個 Skill 中，沒有統一的觸發點。當使用者完成一個功能準備交付時，需要記憶步驟順序、手動觸發多個 Skill，容易遺漏版號 bump 或 changelog 更新等步驟。

競品 gstack 的 `/ship` 指令一鍵串完相同流程，減少使用者的認知負擔。Shikigami 目前在此點存在可見的用戶體驗差距。

然而，與其他兩個 Brief 不同，本需求的商業假設不確定性較高——核心問題是「Shikigami 的使用者是否真的遇到此痛點」，以及「統一管線與現有 `/shoot` 如何劃分邊界」。

---

## 2. 目標使用者（Target Users）

**主要使用者：使用 Shikigami 框架交付 Sprint Story 或單次修復的工程師**

- 在 Sprint Execution 完成後需要交付的使用者
- 在 `/shoot` 完成後需要 bump 版號和更新 changelog 的使用者

**排除**：
- 在 CI/CD 全自動化環境中工作、不需要手動觸發 Ship 步驟的使用者
- 不使用 GitHub / gh CLI 的使用者（PR 建立步驟依賴 gh CLI）

---

## 3. 商業假設（Business Assumptions）

| # | 假設 | 標籤 | 驗證方式 |
|---|------|------|---------|
| A1 | 使用者在意 version bump + changelog 的自動化 | [UNCERTAIN] | 向活躍使用者調查：「完成功能後，你的版號 bump 和 changelog 更新是手動還是自動？」 |
| A2 | 存在明確的 Ship 觸發點，使用者能區分「這個工作已完成，現在要 Ship」 | [UNCERTAIN] | 調查使用者的實際工作流程，確認 Ship 時機的清晰度 |
| A3 | 主要使用者使用 GitHub 並有 gh CLI 可用 | [UNCERTAIN] | 從 GitHub repo 的 issue 討論和安裝說明推斷；若有使用者反應 PR 建立失敗，可確認 |
| A4 | 統一管線與 /shoot 可以清晰劃分邊界（如：/shoot 聚焦單一 Story 快速交付，ship 聚焦 Sprint 完成後的完整發布流程） | [UNCERTAIN] | 設計邊界定義，讓 Architect 和使用者確認無歧義 |

---

## 4. 提案解決方向（Proposed Direction）

### 設計選項評估

在設計統一 Ship 管線前，有兩個方向需要決策：

**選項 A：強化現有 `/shoot`**
- 在 `/shoot` 完成後，新增可選的 `--ship` 參數，觸發 version bump + changelog + PR 建立
- 優點：不引入新概念，與現有 `/shoot` 使用者習慣相容
- 缺點：`/shoot` 的職責邊界擴大，可能造成定義膨脹

**選項 B：新建獨立 `/ship` Skill**
- 建立 `skills/ship/SKILL.md`，定義完整的 Ship 管線
- `/ship` 假設前置工作（實作、QA）已完成，只負責交付流程（version → changelog → commit → push → PR）
- 優點：職責清晰，不干擾現有 `/shoot`
- 缺點：需要使用者理解新的 Skill，可能與 `/shoot` 混淆

**本 Brief 初步傾向選項 B**，但最終設計方向需要 Architect 評估後確認。

### 4.1 Ship 管線定義（選項 B 方向）

```
/ship
  |
  v
[步驟 1] 確認前置狀態
  - 確認 git status（無未追蹤的修改）
  - 確認 Quality Gate 已通過（查閱最近一次審查記錄）
  |
  v
[步驟 2] Version Bump
  - 詢問 bump 類型：patch / minor / major
  - 更新版號（CLAUDE.md、plugin.json、marketplace.json 等，依框架 bump 規則）
  |
  v
[步驟 3] Changelog 更新
  - 讀取本次 commit 範圍（自上一個版號 tag 以來）
  - 產出 CHANGELOG.md 更新條目
  |
  v
[步驟 4] Commit + Push
  - git add（相關版號與 changelog 文件）
  - git commit（`chore: bump v{version}`）
  - git push
  |
  v
[步驟 5] PR 建立（條件觸發）
  - 若當前 branch 非 main，建立 PR
  - 若在 main，跳過 PR 建立
```

### 4.2 與現有 Skill 的邊界

| Skill | 職責 | Ship 管線中的角色 |
|-------|------|-----------------|
| `/shoot` | 單一 Story 快速交付（含 QA 審查） | Ship 前置（已完成的 Story） |
| `/sprint-review` | Sprint 週期性 changelog 更新 | Ship 的 Changelog 步驟參考此格式 |
| `git-workflow` | Commit 規範 | Ship 的 commit 格式遵循此規範 |
| `/ship`（新） | 交付管線串接（version + changelog + commit + push + PR） | 新職責 |

---

## 5. 成功指標（Success Metrics）

| 指標 | 基線 | 目標 | 量測方式 |
|------|------|------|---------|
| Ship 流程步驟數（使用者手動操作） | 5-7 步（手動） | 1 步（/ship 觸發） | 設計確認 |
| Changelog 遺漏率 | 未量測 | 趨近 0%（自動更新） | 使用後檢查 CHANGELOG.md 是否更新 |
| Version bump 遺漏率 | 未量測 | 趨近 0%（自動更新） | 使用後檢查版號文件是否同步 |
| 使用者主觀流暢度評分 | 未量測 | >= 4/5 | 使用者訪談，N >= 3 |

---

## 6. 排除範圍（Out of Scope）

- **取代或修改 `/shoot` 現有功能**：兩者職責互補，不合併
- **自動化 major version bump 的觸發邏輯**：major bump 涉及破壞性變更判定，需人工決策，不自動化
- **非 GitHub 平台的 PR 建立**（GitLab、Bitbucket 等）：初期只支援 gh CLI（GitHub）
- **CI/CD 狀態監控（CI Gate）**：`/shoot` 已有 CI Gate，`/ship` 初期不重複建立
- **多 branch 策略的 merge 管理**：不處理 GitFlow 等複雜 branch 策略

---

## 7. 依賴與風險（Dependencies & Risks）

### 依賴

| 依賴項目 | 類型 | 說明 |
|---------|------|------|
| `gh` CLI 可用 | 技術前提 | PR 建立步驟依賴 gh CLI，若不可用需降級處理 |
| CLAUDE.md bump 規則 | 定義依賴 | 版號同步的目標文件清單（plugin.json、marketplace.json 等）已在 CLAUDE.md 中定義，Ship 管線應遵循此定義為 SSOT |
| `skills/git-workflow/SKILL.md` | 格式依據 | Commit 格式遵循現有規範 |

### 風險

| 風險 | 可能性 | 影響 | 緩解措施 |
|------|-------|------|---------|
| 使用者實際上不遇到此痛點（A1 + A2 不成立） | 高 | 高 | **此風險建議 Gate 1 前先驗證**：在推進設計前，收集使用者對現有流程的明確痛點佐證 |
| 與 /shoot 定位重疊造成使用者混淆（A4 不成立） | 中 | 中 | Gate 2 必須清楚定義兩者邊界，並設計「何時用 /shoot，何時用 /ship」的決策樹 |
| 版號 bump 規則跨專案不一致（A5 不成立） | 中 | 中 | 初期只針對 Shikigami 框架自身的 bump 規則設計，不試圖通用化 |
| gh CLI 不可用（A3 不成立） | 中 | 低 | PR 建立設計降級行為（無 gh CLI 時跳過 PR 建立，輸出 WARN） |

### 優先級建議

本 Brief 的商業假設不確定性在三個 Brief 中最高（A1、A2 均為 [UNCERTAIN] 且影響高）。建議在 Gate 1 補充使用者佐證後再決定是否推進至 Gate 2。若使用者佐證不足，本 Brief 應降低優先級，讓 Browser Automation（高價值）和互動式審查模式（中價值、設計更明確）優先推進。

---

### Architect 技術可行性評估

**評估日期**：2026-03-15
**判斷**：有條件可行（需 ADR）

#### 技術可行性分析

1. **版號 bump 目標文件清單存在常數層級錯置風險**
   CLAUDE.md 中定義了版號 bump 必須同時更新的文件清單（`plugin.json`、`marketplace.json`、`gemini-extension.json`、`CLAUDE.md`、`README.md` badge）。若 `/ship` Skill 在自身的 SKILL.md 中重複定義這份清單，將違反 Single Source of Truth 原則，是語意常數重複定義的典型違規。**架構要求**：`/ship` Skill 必須以「引用 CLAUDE.md 定義」的方式描述 bump 目標，而非在 Skill 中硬編碼文件清單。

2. **/shoot 與 /ship 的邊界問題比 Brief 描述的更複雜**
   分析現有 `/shoot/SKILL.md` 後，shoot 已包含完整的 QA 審查、git commit、git push、CI Gate。若 `/ship` 定義的 Ship 管線從「前置狀態確認」開始，則其與 shoot 的邊界是「shoot 的終點 = ship 的起點」還是「ship 包含 shoot 的 commit + push 步驟」？這兩種邊界定義對 Skill 架構的影響截然不同：
   - 若 ship 從 shoot 結束後接手（CHANGELOG + version bump + PR），職責清晰，不重疊
   - 若 ship 重新執行 commit + push，則與 shoot 在 §7 步驟 6 重疊，違反 Single Responsibility

   本 Brief 的「步驟 4 Commit + Push」設計傾向於後者，**Architect 建議修正為前者**：ship 只負責 version bump + changelog + PR，不重複 commit + push 步驟。

3. **選項 A vs 選項 B 的架構意涵**
   Brief 初步傾向選項 B（新建獨立 /ship Skill）。Architect 同意此方向，理由如下：
   - 若採選項 A（在 /shoot 加 `--ship` 參數），shoot 的職責邊界將超出「單一 Story 快速交付」的定義，違反 Single Responsibility
   - 選項 B 的新 Skill 可以明確定義依賴關係（前置：shoot 或 quality-gate PASS），職責邊界清晰
   - 但選項 B 引入新的 Skill 命名與觸發語法，需要 ADR 記錄設計決策

4. **Changelog 讀取邏輯的技術約束**
   Brief 的步驟 3 定義「讀取本次 commit 範圍（自上一個版號 tag 以來）」。此步驟依賴 `git log` 與 `git tag` 的輸出，在 Claude Code Agent 環境中可透過 Bash tool 執行。技術上可行，但需在 Skill 中定義：若 repo 無任何 tag（首次 ship），changelog 讀取範圍的 fallback 規則是什麼。

#### 提案方向技術評語（第 4 區段）

- **設計選項評估**：選項 B（獨立 /ship Skill）架構更健全。但 Brief 中的管線定義（步驟 4 Commit + Push）需要修正：ship 不應重複執行 commit + push，而應以「確認最近一次 commit 已 push」作為前置條件，自身只負責 version bump + changelog + PR 建立。

- **4.1 Ship 管線定義（選項 B 方向）**：步驟 1 的「確認 Quality Gate 已通過（查閱最近一次審查記錄）」設計值得肯定，但「查閱最近一次審查記錄」需定義讀取的來源（Shoot_Log.md？quality-gate 產出的記錄？），否則 Agent 無法執行此步驟。

- **4.2 與現有 Skill 的邊界**：邊界表格的「Ship 管線中的角色」欄位定義有助於釐清職責，方向正確。需要在 Gate 2 輸出更精確的「觸發前置條件」定義，特別是「ship 假設前置工作已完成」的「已完成」如何被 Agent 驗證。

#### 是否需要 ADR

**需要 ADR**。核心決策包含：
- 選項 A vs 選項 B 的架構選擇（新建 Skill vs 擴充 shoot）
- /ship 與 /shoot 的邊界定義（commit + push 在哪個 Skill 執行）
- 版號 bump 規則的引用方式（引用 CLAUDE.md 定義 vs Skill 自定義）

建議在 Gate 2 範圍收斂完成後，實作前先完成 ADR。

#### 補充技術風險

| 風險 | 可能性 | 影響 | Architect 評語 |
|------|-------|------|---------------|
| /ship Skill 中硬編碼版號 bump 文件清單，違反 Single Source of Truth（與 CLAUDE.md 定義重複） | 高 | 中 | **Layer Compliance 違規風險**：此為語意常數重複定義，Architect 審查 Gate 將攔截；設計時必須以 CLAUDE.md 為 SSOT，Skill 引用而不複製 |
| ship 步驟 4（Commit + Push）與 shoot 步驟 6 職責重疊，違反 Single Responsibility | 高 | 中 | 建議 Gate 2 修正管線設計，ship 不執行 commit + push，只在已 push 的狀態上進行 bump + changelog + PR |
| 「Quality Gate 已通過」的驗證來源未定義，Agent 無法執行步驟 1 前置確認 | 中 | 中 | Gate 2 需定義驗證來源（建議讀取 Shoot_Log.md 的最近 PASS 記錄，確認 commit hash 與當前 HEAD 一致） |

---

## Gate Checklist

### Gate 1：問題理解（PO 確認）

- [x] 問題陳述基於 Issue #271 競品分析，現有缺口有依據（多 Skill 分散）
- [x] 目標使用者已識別
- [x] 所有 [UNCERTAIN] 假設已列出
- [ ] **使用者痛點佐證收集**（驗證 A1、A2）— 此項為 Gate 1 解除阻塞的關鍵條件

### Gate 2：範圍收斂（PO + Architect 確認）

- [ ] /shoot 與 /ship 邊界定義通過 Architect 確認（驗證 A4）
- [ ] 選項 A vs 選項 B 設計方向決策完成
- [ ] 版號 bump 規則 SSOT 確認
- [ ] gh CLI 降級行為設計完成
- [x] **Architect 技術可行性評估完成**：判定「有條件可行（需 ADR）」，已識別版號 bump SSOT 違規風險、/ship 與 /shoot 職責重疊問題、Quality Gate 驗證來源未定義三項需在 Gate 2 修正的設計問題，ADR 需求已標注

### Gate 3：Ready for Sprint（PO + QA 確認）

- [ ] User Story 已撰寫
- [ ] AC 已定義，每條 AC 可測試
- [ ] RICE Score 已計算
- [ ] Size 估算已與 Developer/Architect 確認
