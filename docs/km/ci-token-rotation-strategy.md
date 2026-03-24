# CI Token 輪換自動化策略

**日期**：2026-03-24
**觸發 Issue**：#637（retro: CI Token 輪換自動化 — CLAUDE_CODE_OAUTH_TOKEN 持續過期根本解決）
**Sprint**：140
**歷史根因**：Sprint 136 #600、#616、#618、#622 — OAuth Token 每 1-2 週過期，CI 持續 401 失敗

---

## 問題陳述（AC1：研究結果）

`claude-code-action@v1` 的 `claude_code_oauth_token` 參數使用 Claude Code CLI 的 OAuth Token，此 token 每約 1-2 週自動失效，導致 New Issue Intake CI 持續出現 `401 Invalid bearer token`。

Sprint 136 已評估並決策遷移至 `ANTHROPIC_API_KEY`（見 `docs/km/oauth-token-vs-api-key-decision.md`），但 workflow 從未完成遷移（仍使用 `claude_code_oauth_token`）。

**根本問題**：Sprint 136 的決策未完整落地，workflow 修改被推遲但沒有追蹤機制。

---

## 方案評估（AC2：替代認證方式評估）

### 方案 A：ANTHROPIC_API_KEY（推薦）

| 項目 | 說明 |
|------|------|
| 有效期 | 無自動過期（由 Anthropic Console 管理） |
| 設定方式 | Anthropic Console 建立 → GitHub Secret 設定一次 |
| Workflow 變更 | 1 行：`claude_code_oauth_token` 改為 `anthropic_api_key` |
| 功能等同性 | `claude-code-action@v1` 兩種認證方式功能完全相同 |
| 維護成本 | 近零（只有 API Key 被手動撤銷時需更新） |
| 自動化可行性 | 高（一次性設定，之後無需定期更新） |

**結論**：最優方案。已有先例決策（Sprint 136），只需完成 workflow 遷移。

### 方案 B：OAuth Token 自動輪換（Cron Job）

| 項目 | 說明 |
|------|------|
| 有效期 | OAuth Token 仍每 1-2 週過期 |
| 設定方式 | Cron workflow + PAT + `claude auth login --headless` |
| Workflow 變更 | 需新增 oauth-token-rotator.yml，複雜度高 |
| 功能等同性 | 與現狀相同，但自動化刷新 |
| 維護成本 | 中（需維護 rotator workflow，PAT 也有過期風險） |
| 風險 | PAT 過期會導致 rotator 失效，問題轉移而非消除 |

**結論**：治標不治本。自動輪換機制本身也有 PAT 過期風險，不推薦。

### 方案 C：Service Account API Key

| 項目 | 說明 |
|------|------|
| 有效期 | 無自動過期（需手動撤銷） |
| 設定方式 | 建立 Service Account → 產生 API Key → GitHub Secret |
| Workflow 變更 | 與方案 A 相同（使用 `anthropic_api_key`） |
| 功能等同性 | 完全相同 |
| 成本差異 | Service Account 可能有獨立 billing，需確認 Anthropic 政策 |

**結論**：與方案 A 等效，但增加 Service Account 管理複雜度。個人帳號 API Key 已足夠。

---

## 決策（AC3：替換策略）

**採用方案 A：遷移至 ANTHROPIC_API_KEY**

### 理由
1. Sprint 136 已完成評估並做出相同決策（文件：`oauth-token-vs-api-key-decision.md`），本次是落地執行
2. 零維護成本，根本消除定期輪換問題
3. Workflow 變更最小（1 行），風險極低
4. Sprint 136 以來已發生 4 次以上中斷（#600、#616、#618、#622、#637），成本已量化

### 必要的人工操作（無法自動化）

以下步驟**必須由人工在 CI 之外執行**，因為 GitHub Secret 新增需要 Repo Admin 權限，且 Anthropic API Key 需要在 Console 手動建立：

1. 在 [Anthropic Console](https://console.anthropic.com/settings/keys) 建立新的 API Key
   - 命名建議：`shikigami-ci-new-issue-intake`
   - 記錄建立日期（建議每年 rotate 一次）

2. 在 GitHub → Settings → Secrets → Actions 新增 Secret：
   - Name: `ANTHROPIC_API_KEY`
   - Value: 步驟 1 建立的 API Key

3. 確認 workflow 修改已部署（本 PR 完成）

4. 觸發測試 run（手動建立一個 test issue 或 re-run 最新失敗的 run）

### Workflow 自動化部分（本 PR 完成）
- `new-issue-intake.yml`：將 `claude_code_oauth_token` 替換為 `anthropic_api_key`
- 更新 workflow 內的說明 comment，移除過期的 Sprint 138 hotfix 說明

---

## 成功指標（AC4 後續驗證）

| 指標 | 目標 | 驗證方式 |
|------|------|---------|
| New Issue Intake CI 失敗率（因 token 過期） | 0% | 連續 2 週 CI 通過 |
| 人工 token 更新頻率 | 0 次 / 年（除年度 rotate） | 觀察 Sprint Retro |

---

## 相關文件

- `docs/km/oauth-token-vs-api-key-decision.md` — Sprint 136 原始決策
- `docs/km/sop-claude-oauth-token-refresh.md` — 舊 SOP（OAuth token 手動刷新，已過時）
- `.github/workflows/new-issue-intake.yml` — 受影響的 workflow

---

*此文件由 Sprint 140 Story #637 Developer subagent 自動產出*
