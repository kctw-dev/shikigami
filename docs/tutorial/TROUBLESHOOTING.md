# Troubleshooting 指南

**適合對象**：安裝或使用 Shikigami 時遇到問題的使用者
**對應版本**：v0.3.8+

---

## 目錄

1. [Claude Code CLI 未認證](#1-claude-code-cli-未認證)
2. [GitHub CLI 未認證](#2-github-cli-未認證)
3. [Plugin 掛載失敗](#3-plugin-掛載失敗)
4. [Plugin 間歇性載入失敗（Shallow Clone SHA 不匹配）](#4-plugin-間歇性載入失敗shallow-clone-sha-不匹配)
5. [Standup 健康快篩 CRITICAL](#5-standup-健康快篩-critical)
6. [Sprint Planning QA Hard Gate 失敗](#6-sprint-planning-qa-hard-gate-失敗)
7. [README 前置條件未說明導致安裝卡關](#7-readme-前置條件未說明導致安裝卡關)

---

## 1. Claude Code CLI 未認證

### 情境描述

使用者安裝 Claude Code CLI 後，嘗試啟動 Shikigami 但遇到認證錯誤，導致所有 Skill 無法執行。

### 症狀（錯誤訊息或異常行為）

- Claude Code 開啟後立即顯示錯誤，無法正常對話
- 嘗試觸發任何 Skill 時出現：`Error: 401 Unauthorized` 或 `Authentication required`
- Claude 無法回應任何問題，或持續詢問帳號資訊

### 根因說明

Claude Code CLI 需要有效的 Anthropic 帳號並完成 OAuth 認證流程才能運作。如果認證 token 過期、從未完成認證，或在不同環境間切換（如 Docker 容器、CI 環境）時，Claude Code 無法取得有效憑證。

### 解決步驟

**步驟 1**：確認 Claude Code CLI 已正確安裝

```bash
claude --version
```

預期看到版本號（如 `claude 1.x.x`）。若出現「command not found」，需先完成安裝。

**步驟 2**：重新完成認證

在終端機執行：
```bash
claude auth login
```

按照畫面指示完成 OAuth 認證流程（通常會開啟瀏覽器）。

**步驟 3**：驗證認證狀態

```bash
claude auth status
```

預期看到：`Logged in as: your-email@example.com`

**步驟 4**：重啟 Claude Code 並測試

重新開啟 Claude Code，輸入任意問題確認可正常對話。

> **注意**：認證 token 有效期限有限，定期需要重新認證（通常每 30 天）。如果你在共用環境或 CI/CD Pipeline 中使用，請改用 API Key 方式認證（參閱 [Claude Code 官方文件](https://docs.anthropic.com/en/docs/claude-code)）。

---

## 2. GitHub CLI 未認證

### 情境描述

使用者嘗試使用 Shikigami 的 Issue 管理、PR 建立等 GitHub 相關功能，但 GitHub CLI（`gh`）未認證，導致 GitHub 操作靜默失敗或出現錯誤。

### 症狀（錯誤訊息或異常行為）

- Sprint Execution 中 Issue 快掃顯示：`gh: To get started, authenticate by running: gh auth login`
- 嘗試建立 PR 或留言時出現：`Error: HTTP 401: Bad credentials`
- PO subagent 回報「GitHub CLI 未認證，跳過 Issue 操作」

### 根因說明

Shikigami 的多個 Skill 使用 GitHub CLI（`gh`）執行 GitHub 操作（如 `gh issue list`、`gh pr create`）。`gh` 需要有效的 GitHub Personal Access Token 或 OAuth 認證才能存取 GitHub API。如果未認證，相關操作會失敗，但部分 Skill 設計為「靜默跳過」（不阻塞主流程）。

### 解決步驟

**步驟 1**：確認 `gh` 已安裝

```bash
gh --version
```

若出現「command not found」，先安裝：
```bash
# macOS
brew install gh

# Ubuntu/Debian
sudo apt install gh

# 或參閱官方文件：https://cli.github.com/
```

**步驟 2**：執行認證

```bash
gh auth login
```

選擇認證方式（建議選 HTTPS + 登入 GitHub.com），按指示完成認證。

**步驟 3**：驗證認證狀態

```bash
gh auth status
```

預期看到：
```
github.com
  ✓ Logged in to github.com as your-username
  ✓ Git operations for github.com configured to use https protocol.
```

**步驟 4**：確認 repo 權限

確認你的帳號對目標 repo 有 Issue 和 PR 的存取權限（若是自己的 repo，預設有全部權限）。

> **補充說明**：若你的專案不使用 GitHub，或不需要 GitHub 相關功能，`gh` 未認證不影響 Shikigami 的核心 Scrum 流程（Sprint Planning、Sprint Execution 的代碼實作部分）。Issue 快掃失敗時，sprint-execution SKILL.md 設計為靜默跳過，不阻塞 Story 執行。

---

## 3. Plugin 掛載失敗

### 情境描述

使用者完成 Plugin 安裝步驟後，開啟新 Session 時 Shikigami 未被載入，或 Claude 不認識 Shikigami 的 Skills。

### 症狀（錯誤訊息或異常行為）

- 詢問「你有 shikigami superpowers 嗎？」時，Claude 回答不知道或否認有 Shikigami
- 說「幫我初始化 Shikigami」時，沒有觸發 onboarding，而是 Claude 直接回答（沒有 Subagent 派遣）
- 系統提示中看不到 `shikigami:` 前綴的 Skills

### 根因說明

常見原因有三種：
1. **Plugin 安裝後未開啟新 Session**：Plugin 需要在新 Session 才會載入到系統提示
2. **安裝未完成**：Marketplace 加入成功但 `install` 步驟未執行
3. **Plugin 被停用**：Plugin 安裝後可能被手動停用，或因版本衝突自動停用

### 解決步驟

**步驟 1**：確認已開啟新 Session

關閉當前 Claude Code Session，重新開啟，這樣 Plugin 才會載入。

**步驟 2**：確認 Plugin 安裝狀態

在 Claude Code 中執行：
```
/plugin
```

查看 Plugin UI，確認 shikigami 顯示在列表中且狀態為「Active」（非 Disabled）。

**步驟 3**：若 Plugin 不在列表中，重新執行安裝

```
/plugin marketplace add KCTW/shikigami
/plugin install shikigami
```

執行後**關閉並重新開啟 Session**。

**步驟 4**：驗證 Skills 已載入

```
> 你有哪些 shikigami skills？
```

預期看到 Claude 列出 Shikigami 的 17 個 Skills。

**步驟 5**：若問題仍在，清除 Plugin 快取後重裝

```
/plugin uninstall shikigami
/plugin install shikigami
```

> **已知問題**：Plan Mode（Claude Code 的 `/plan` 功能）啟用時，Plugin 會被「封印」— Scrum Master 雖然已載入，但無法派遣 Subagent 執行寫入操作。如果你進入了 Plan Mode，請退出 Plan Mode 後再使用 Shikigami。

---

## 4. Plugin 間歇性載入失敗（Shallow Clone SHA 不匹配）

### 情境描述

Plugin 已正確安裝，但開啟新 Session 後偶爾出現載入失敗錯誤，且此問題在 `git push` 後特別容易觸發。

### 症狀（錯誤訊息或異常行為）

- 執行 `/plugin` 時出現：
  ```
  Plugin Errors
    ❯ shikigami@shikigami
       Plugin 'shikigami' not found in marketplace 'shikigami'
       → Plugin may not exist in marketplace 'shikigami'
  ```
- `.claude-plugin/plugin.json` 與 `marketplace.json` 版號正確且一致，但 Plugin 仍無法載入
- 問題具有間歇性——有時能正常載入，有時失敗

### 根因說明

**根本原因：Claude Code marketplace mirror 採用 depth=1 shallow clone。**

Claude Code 平台在 mirror shikigami marketplace 時，使用 `--depth=1` 的 shallow clone 模式。這意味著：

1. 每次你執行 `git push` 後，平台的 mirror 會更新到最新 commit
2. 但因為是 shallow clone，**舊的 commit SHA 在 mirror 中消失**
3. 你本機的 Plugin 安裝記錄仍指向舊的 `gitCommitSha`
4. 平台嘗試用舊 SHA lookup Plugin 時找不到，導致「not found in marketplace」錯誤

這是 Claude Code 平台的已知 bug（Issue #101），不是 Shikigami 本身的問題。

### 觸發條件

**git push 後開啟新 Session 時觸發。** 具體來說：

- 推送新 commit 到 GitHub 後，平台 mirror 更新，舊 installed SHA 消失
- 下一次開啟 Claude Code 新 Session 時，平台用已消失的舊 SHA lookup 失敗

### 操作 SOP（Workaround）

發生此錯誤時，執行以下指令重新對齊 SHA：

```
/plugin install shikigami
```

**效果**：重新執行 install 會讀取 mirror 的最新 SHA，並更新本機安裝記錄，使兩端重新對齊。執行後開啟新 Session 即可正常使用。

完整流程：
1. 在 Claude Code 中執行 `/plugin install shikigami`
2. 關閉並重新開啟 Session
3. 執行 `/plugin` 確認 shikigami 狀態為 Active

### 預防建議

**採用里程碑式版號更新，降低 `git push` 頻率。**

每次 push 都可能觸發此問題。減少非必要的推送可以降低發生頻率：

- 避免連續衝刺每個 Sprint 都 bump version 並推送
- 只在對外發布節點（里程碑）才 push 版號更新
- 日常開發可以累積多個 commit 後一次推送

> **平台 Bug 追蹤**：此問題已記錄於 [Issue #101](https://github.com/KCTW/shikigami/issues/101)。若 Claude Code 平台修復 shallow clone 問題，此 workaround 將不再必要。

---

## 5. Standup 健康快篩 CRITICAL

### 情境描述

使用者執行 `standup`（站立會議）指令後，健康快篩輸出 CRITICAL 狀態，但不確定原因或如何修復。

### 症狀（錯誤訊息或異常行為）

- Standup 輸出包含：`🔴 CRITICAL：CLAUDE.md 缺失`
- Standup 報告顯示：`健康狀態：CRITICAL`，並列出一或多個「CRITICAL」問題
- 若問題為逾期 Action Items，報告顯示：`🔴 CRITICAL：X 個 Action Item 逾期超過 14 天`

### 根因說明

健康快篩 CRITICAL 通常由以下原因觸發：

| 原因 | 說明 |
|------|------|
| CLAUDE.md 缺失 | 專案根目錄缺少 CLAUDE.md 配置檔案，代表尚未完成 onboarding |
| Retrospective_Log.md 缺失 | KM 目錄缺少 Retrospective 記錄，代表文件結構不完整 |
| 逾期 Action Items | `docs/km/Retrospective_Log.md` 中有超過 14 天未關閉的 Action Item |
| Sprint 文件缺失 | 當前 Sprint 文件不存在或不完整 |

> **框架 repo 特例**：若你在 Shikigami 框架 repo 本身（含 `.claude-plugin/plugin.json`）執行 standup，CLAUDE.md 缺失的 CRITICAL 會自動略過，顯示「（框架 Repo，CLAUDE.md 檢查略過）」— 這是正常行為（US-S02 修正）。

### 解決步驟

**情況 A：CLAUDE.md 缺失**

執行 onboarding 建立 CLAUDE.md：
```
> 幫我初始化 Shikigami
```

onboarding 完成後，CLAUDE.md 會自動建立在專案根目錄。

**情況 B：逾期 Action Items**

1. 查看逾期的 Action Items：
```bash
cat docs/km/Retrospective_Log.md
```

2. 針對每個逾期 Action Item，執行對應工作或說明為何關閉：
```
> 幫我處理逾期的 Action Item：[Action Item 描述]
```

3. 在 `Retrospective_Log.md` 中將對應 Action Item 標記為已關閉（`[x]`）

**情況 C：文件結構不完整**

若 KM 文件缺失，重新執行 onboarding 補建結構：
```
> 幫我重新初始化 Shikigami 的文件目錄
```

**情況 D：確認修復後再執行 standup**

```
> standup
```

預期看到：`健康狀態：HEALTHY` 或 WARNING 級別（表示有警告但無 CRITICAL 問題）。

---

## 6. Sprint Planning QA Hard Gate 失敗

### 情境描述

執行 Sprint Planning 時，QA subagent 審查 Acceptance Criteria 後輸出 Hard Gate 失敗，導致 Sprint Planning 中止，無法建立 Sprint 文件。

### 症狀（錯誤訊息或異常行為）

- Sprint Planning 輸出：`QA Hard Gate：FAIL`
- QA subagent 列出一或多個 AC 的問題，如：
  ```
  🔴 FAIL：US-#N AC2 不可測試
     問題：AC2「系統應該更好」缺乏明確的可測試標準
     建議：改為「系統回應時間 < 200ms（以 p95 為準）」
  ```
- Sprint Planning 停在 QA 審查步驟，未繼續到 PO 建立 Sprint 文件

### 根因說明

QA Hard Gate 的設計目的是確保每個進入 Sprint 的 Story，其 Acceptance Criteria 都是「可測試的、明確的、完整的」。

常見的 AC 問題：

| 問題類型 | 範例（不合格） | 建議修正 |
|---------|--------------|---------|
| 太模糊 | 「系統應該更快」 | 「API 回應時間 < 200ms（p95）」 |
| 缺乏完成標準 | 「新增報表功能」 | 「報表含 X、Y、Z 欄位，且可匯出為 CSV」 |
| 不可驗證 | 「使用者體驗要好」 | 「SUS 評分 > 70」或具體 UI 行為描述 |
| 缺少邊界條件 | 「處理錯誤」 | 「輸入非數字時回傳 400 錯誤並附錯誤訊息」 |

### 解決步驟

**步驟 1**：讀取 QA Hard Gate 的具體失敗原因

查看 Sprint Planning 輸出中 QA subagent 的說明，確認哪些 AC 不合格及原因。

**步驟 2**：請 PO subagent 修正問題的 AC

```
> 請修正 US-#N 的 AC2，讓它符合可測試標準
```

或者直接描述你的期望行為，讓 PO 重新撰寫 AC：
```
> US-#N AC2 的目標是「使用者登入失敗時看到錯誤提示」，請重寫成可測試的 AC
```

**步驟 3**：確認 PRODUCT_BACKLOG.md 已更新

```bash
cat docs/prd/PRODUCT_BACKLOG.md
```

確認問題的 AC 已修正。

**步驟 4**：重新執行 Sprint Planning

```
> 重新開始 Sprint Planning
```

QA subagent 會重新審查修正後的 AC。

> **說明**：QA Hard Gate 失敗不代表你的需求有問題，而是 AC 的描述方式需要更具體。大多數情況下，讓 PO subagent 協助重寫 AC 即可解決。

---

## 7. README 前置條件未說明導致安裝卡關

### 情境描述

首次安裝 Shikigami 的外部使用者，直接按照 README「快速開始」的步驟執行 `/plugin marketplace add`，但 Claude Code 無法正常運作或回應認證錯誤，因為 README 早期版本未明確說明前置條件。

> **注意**：此問題來自 US-15 安裝驗證報告的發現問題（P1、P2）。README v0.3.8 已修正，在「快速開始」前新增了「前置條件」區段。此條目保留於 Troubleshooting 作為歷史記錄與保底指引。

### 症狀（錯誤訊息或異常行為）

- 執行 `/plugin marketplace add KCTW/shikigami` 後 Claude Code 無法回應
- Claude Code 開啟後出現「401 Unauthorized」或帳號認證相關錯誤
- 安裝指令正確執行但 Plugin 功能無法使用

### 根因說明

README 早期版本（< v0.3.8）未在「快速開始」區段明確說明兩個前置條件：
1. **需先安裝 Claude Code CLI**（不是每個開發者都已安裝）
2. **需先完成 Claude Code 帳號認證**（認證狀態未確認就安裝 Plugin，後續會碰壁）

這兩個條件是 Shikigami 正常運作的基礎，但屬於「隱含假設」，對首次使用 Claude Code 的使用者不明顯。

### 解決步驟

**步驟 1**：確認 Claude Code CLI 已安裝

```bash
claude --version
```

若未安裝：
1. 前往 [Claude Code 官方文件](https://docs.anthropic.com/en/docs/claude-code) 下載安裝
2. 完成安裝後確認 `claude --version` 有輸出版本號

**步驟 2**：確認 Claude Code 帳號認證

```bash
claude auth status
```

預期看到：`Logged in as: your-email@example.com`

若未認證：
```bash
claude auth login
```

按照畫面指示完成 OAuth 認證。

**步驟 3**：重新執行 Plugin 安裝

認證完成後，在 Claude Code 互動介面執行：
```
/plugin marketplace add KCTW/shikigami
/plugin install shikigami
```

**步驟 4**：開啟新 Session 驗證

關閉並重新開啟 Claude Code Session，執行驗證：
```
> 你有 shikigami superpowers 嗎？
```

預期 Claude 確認已載入 Shikigami Skills。

> **相關文件**：US-15 安裝驗證報告（`docs/km/INSTALL_VERIFICATION.md`）記錄了完整的驗證過程和發現問題清單，可作為更詳細的診斷參考。

---

## 通用排查原則

遇到問題時，建議依序嘗試：

1. **確認是否開啟新 Session**：許多問題在重開 Session 後自動解決
2. **確認前置條件**：Claude Code CLI 認證、GitHub CLI 認證（如需要）
3. **查看 Standup 健康快篩**：執行 `> standup` 獲取系統自我診斷報告
4. **查看相關文件**：`docs/km/Retrospective_Log.md`、`docs/sprints/sprint_N.md`
5. **問 Claude 發生了什麼**：直接描述你觀察到的症狀，Claude 會協助診斷

---

## 回報問題

若本文件未涵蓋你遇到的問題，歡迎：

1. 在 GitHub repo 建立 Issue，描述症狀、錯誤訊息、和你嘗試的步驟
2. 附上 `docs/km/INSTALL_VERIFICATION.md` 的對應步驟審查結果（如適用）

---

## 相關文件

- [GETTING_STARTED.md](./GETTING_STARTED.md) — 入門教學（安裝到第一個 Sprint）
- [安裝驗證報告](../km/INSTALL_VERIFICATION.md) — US-15 安裝流程驗證記錄
- [README.md（專案入口）](../../README.md) — 完整功能說明與 FAQ
