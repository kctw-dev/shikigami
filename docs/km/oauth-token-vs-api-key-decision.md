# OAuth Token vs ANTHROPIC_API_KEY — CI 認證方案評估

**日期**：2026-03-24
**觸發 Issue**：#600（SRE CI 持續失敗：New Issue Intake 401）
**Sprint**：136
**相關歷史**：#551、#557、#583（重複發生的 OAuth token 過期問題）

---

## 問題背景

`claude-code-action@v1` 支援兩種認證方式：

| 參數 | 類型 | 描述 |
|------|------|------|
| `claude_code_oauth_token` | OAuth Token | `claude auth login` 產生，有效期有限 |
| `anthropic_api_key` | API Key | Anthropic Console 建立，無自動過期 |

OAuth Token 過期問題已在同一 Sprint 內重複出現 3 次以上（#551、#557、#583），每次均需手動 `claude auth login` 重新產生並更新 Secret，根本問題未解決。

---

## 選項評估

### Option A：繼續使用 OAuth Token（現狀）

**優點**：
- 目前已在使用，無需更改 workflow
- OAuth Token 支援 Claude Code 的完整功能（session management 等）

**缺點**：
- OAuth Token 有效期有限（約 30 天），需定期手動刷新
- 問題重複出現（#551、#557、#583、#600），維護成本高
- CI 中斷期間所有新 Issue 無法自動 triage

---

### Option B：遷移至 ANTHROPIC_API_KEY

**優點**：
- API Key 無自動過期機制（只需在 Anthropic Console 建立一次）
- 消除重複性的 CI 中斷問題
- `claude-code-action@v1` 原生支援 `anthropic_api_key` 參數

**缺點**：
- 需要在 Anthropic Console 建立 API Key 並更新 GitHub Secret
- 從 `claude_code_oauth_token` 改為 `anthropic_api_key` 需修改 workflow（1 行變更）

---

## 決策

**採用 Option B：遷移至 ANTHROPIC_API_KEY**

### 理由

1. OAuth Token 重複過期已造成可量化的業務影響（3 次以上中斷，每次需人工介入）
2. `anthropic_api_key` 無自動過期，根本消除此類中斷
3. `claude-code-action@v1` 對兩種認證方式的功能支援相同（prompt 執行能力無差異）
4. 遷移成本極低（workflow 1 行變更 + Secret 更新）

### 遷移步驟

1. 在 [Anthropic Console](https://console.anthropic.com/settings/keys) 建立新的 API Key
2. 在 GitHub Repository Settings → Secrets → Actions 中新增 `ANTHROPIC_API_KEY`
3. 更新 `new-issue-intake.yml`：將 `claude_code_oauth_token` 替換為 `anthropic_api_key`
4. 可選：保留 `CLAUDE_CODE_OAUTH_TOKEN` secret（不刪除），以備降級使用
5. 觸發一次手動 workflow run 驗證認證正常

---

## 影響

- `new-issue-intake.yml` 需更新（已在本 PR 完成）
- `ANTHROPIC_API_KEY` 需由人工在 GitHub Secrets 新增（無法自動完成）
- `oauth-token-monitor.yml` 繼續運作（監控 OAuth Token，但 New Issue Intake 不再依賴它）

---

*此文件由 Sprint 136 Story #600 SRE subagent 自動產出（AC3：決策記錄）*
