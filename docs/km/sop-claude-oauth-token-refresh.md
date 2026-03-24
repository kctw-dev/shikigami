# SOP：Claude OAuth Token 更新

**版本**：v1.0
**建立日期**：2026-03-24
**適用情境**：CI workflow 因 401 authentication_error 失敗，原因為 CLAUDE_CODE_OAUTH_TOKEN 過期

---

## 問題描述

GitHub Actions CI workflow（New Issue Intake 等）使用 `CLAUDE_CODE_OAUTH_TOKEN` 作為 Claude CLI 的認證憑證。此 token 具有效期限，過期後所有依賴 Claude CLI 的 workflow 步驟會回傳：

```
Error: 401 authentication_error
```

**影響範圍**：所有 `.github/workflows/` 中使用 `claude` CLI 指令的 workflow。

**長期解**：Issue #539（watchdog 自動同步）。本 SOP 為短期人工修復程序。

---

## 前置條件

- 執行者需有 GitHub Repository 的 **Settings > Secrets and variables** 寫入權限
- 執行者的本機需已登入 Claude Code CLI（`claude` 指令可用）

---

## 步驟

### 步驟 1：取得有效 OAuth Token

在**已登入 Claude Code CLI 的機器**上執行：

```bash
# 取得目前有效的 OAuth token
cat ~/.claude/.credentials.json
```

若上述路徑不存在，嘗試：

```bash
# 列出 Claude CLI 認證相關檔案
ls -la ~/.claude/
```

取得 token 值（通常為 `oauth_token` 或 `access_token` 欄位的值）。

> 注意：若本機 token 也已過期，先執行 `claude login` 重新登入，再取得 token。

---

### 步驟 2：更新 GitHub Secret

1. 前往 GitHub Repository 設定頁面：
   ```
   https://github.com/kctw-dev/shikigami/settings/secrets/actions
   ```

2. 找到 `CLAUDE_CODE_OAUTH_TOKEN`，點擊「Update」

3. 貼上步驟 1 取得的 token 值

4. 點擊「Update secret」確認儲存

---

### 步驟 3：Re-run 最新失敗的 Workflow

1. 前往 GitHub Actions 頁面：
   ```
   https://github.com/kctw-dev/shikigami/actions
   ```

2. 找到最新失敗的「New Issue Intake」workflow run

3. 點擊「Re-run all jobs」

4. 等待 workflow 完成

---

### 步驟 4：確認恢復

確認以下指標全部通過：

- [ ] Re-run 的 workflow 狀態為綠色（pass）
- [ ] 無 `401 authentication_error` 錯誤訊息
- [ ] 後續新 issue 觸發的 workflow 也正常執行

若仍失敗，檢查：

1. token 是否複製完整（無多餘空白或換行）
2. token 是否為正確格式（通常以 `sk-` 或特定前綴開頭）
3. 是否有其他 secret 名稱需同步更新

---

## 驗證指令

可使用以下指令確認最近的 workflow 狀態：

```bash
# 列出最近 10 次 workflow 執行結果
gh run list --repo kctw-dev/shikigami --limit 10

# 查看特定 run 的詳細日誌
gh run view <run-id> --repo kctw-dev/shikigami --log
```

---

## 相關資源

- Issue #524：本次 token 過期事件記錄
- Issue #539：長期自動化解（watchdog 自動同步）
- GitHub Actions 設定：`.github/workflows/`

---

## 更新紀錄

| 日期 | 版本 | 說明 |
|------|------|------|
| 2026-03-24 | v1.0 | 初版建立（對應 Issue #524） |
