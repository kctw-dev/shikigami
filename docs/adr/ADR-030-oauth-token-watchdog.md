# ADR-030：Claude OAuth Token Watchdog — 偵測+告警策略

**日期**：2026-03-23
**狀態**：Accepted
**相關 Issue**：#330
**提案者**：Architect Agent

---

## 背景

Claude Code OAuth token 有 `expiresAt` 有效期（數小時），儲存於 `~/.claude/.credentials.json`。
CI 環境使用 `CLAUDE_CODE_OAUTH_TOKEN` GitHub Secret 執行 headless sprint dispatch（ADR-027）。
Token 過期後 CI job 會靜默失敗或拋出認證錯誤，難以追蹤。

Issue #330 原始需求包含三步驟：讀取 token → 偵測過期 → `gh secret set` 自動更新 GitHub Secret。

---

## 選項評估

### 選項 A：偵測+告警（本 ADR 決策）

SessionStart hook 執行 watchdog：讀取 `~/.claude/.credentials.json`，檢查 `expiresAt`，即將過期時輸出告警訊息，提示使用者手動執行 `claude auth login`。

**優點**：
- 實作簡單，無外部依賴
- 不依賴未公開 API
- 靜默跳過（檔案不存在 → 不阻塞 session 啟動）
- 符合最小驚訝原則（只告警，不自動改寫憑證）

**缺點**：
- 需要人工介入執行 `claude auth login`
- 每次 SessionStart 都執行一次小額 I/O

**結論**：採用

### 選項 B：自動 refresh（否決）

讀取 `~/.claude/.credentials.json` 中的 `refreshToken`，呼叫 Claude OAuth refresh 端點取得新 `accessToken`，回寫至 `credentials.json`。

**優點**：
- 全自動，無人工介入
- token 永不過期

**缺點**：
- Claude Code OAuth refresh 端點**未公開**（non-public API）
- 端點 URL、request body schema、response 結構隨時可能變動
- 非公開 API 依賴屬於高風險技術債
- `credentials.json` 格式為 Claude Code 內部格式，非公開規格

**結論**：否決（依賴非公開 API）

### 選項 C：cron 定期檢查（否決）

系統 cron job 每 30 分鐘執行 watchdog，而非 SessionStart hook。

**優點**：
- 不需要開啟 Claude Code session 即可偵測

**缺點**：
- 需要使用者手動設定 cron（安裝成本高）
- Shikigami 設計為 Claude Code Plugin，hook 機制更原生
- 背景 cron 難以在 Claude Code session 內顯示告警

**結論**：否決（SessionStart hook 更符合 Plugin 設計原則）

### 選項 D：偵測+自動更新 GitHub Secret（否決）

偵測過期後自動執行 `gh secret set CLAUDE_CODE_OAUTH_TOKEN`，將新 token 寫入 GitHub Secret。

**優點**：
- CI 環境 token 自動保持最新

**缺點**：
- 需要 repo secrets write 權限（`GH_TOKEN` 需要 `secrets` scope）
- 本地開發環境不一定有此權限
- 自動 refresh（選項 B）被否決，無法取得新 token，此選項前提不成立

**結論**：否決（前提條件不成立）

---

## 決策

**採用選項 A：偵測+告警，不主動 refresh**

### 實作規格

1. **腳本位置**：`hooks/oauth-token-watchdog.sh`
2. **觸發時機**：SessionStart hook（透過 `hooks/session-start` 呼叫）
3. **告警門檻**：`expiresAt` 距現在 < 24 小時
4. **告警格式**：
   ```
   [OAUTH-WARN] Claude OAuth token 即將過期（剩餘 Xh），請執行 claude auth login 更新
   ```
5. **靜默跳過條件**：
   - `~/.claude/.credentials.json` 不存在
   - `expiresAt` 欄位不存在
   - JSON 解析失敗

---

## 替代方案考量

| 方案 | 優點 | 缺點 | 決策 |
|------|------|------|------|
| 偵測+告警（SessionStart hook） | 簡單、無外部依賴、符合 Plugin 設計 | 需人工介入 | **採用** |
| 自動 refresh（非公開 API） | 全自動 | 依賴非公開 API，高風險 | 否決 |
| cron 定期檢查 | 不需 session | 安裝成本高，不原生 | 否決 |
| 偵測+自動更新 GitHub Secret | CI 自動化 | 前提條件（refresh）不成立 | 否決 |

---

## 影響

1. **新增**：`hooks/oauth-token-watchdog.sh` — token 過期偵測與告警
2. **修改**：`hooks/session-start` — 於 checkin 完成後呼叫 watchdog
3. **不修改**：`hooks/hooks.json` — SessionStart hook 入口已透過 `session-start` 腳本轉發

---

## 未來考量

- 若 Claude Code 官方公開 OAuth refresh API，可升級為選項 B（自動 refresh）
- 若需 CI 端自動更新 Secret，待 refresh 機制公開後可追加 `gh secret set` 步驟
