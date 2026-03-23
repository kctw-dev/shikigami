# Claude Code GitHub App 安裝操作指引

## 背景

`new-issue-intake.yml` workflow 使用 `anthropics/claude-code-action@v1`，此 Action 需要
Claude Code GitHub App 安裝在目標 repo 上，才能完成 OIDC token exchange。
若 App 未安裝，CI 會出現以下錯誤並中止：

```
App token exchange failed: 401 Unauthorized - Claude Code is not installed on this repository.
Please install the Claude Code GitHub App at https://github.com/apps/claude
```

## 所需權限

workflow job 層級需要宣告以下 permissions（`new-issue-intake.yml` 已正確設定）：

| Permission    | Level  | 用途                              |
|---------------|--------|-----------------------------------|
| `issues`      | write  | 改寫 Issue body、套用 labels       |
| `contents`    | read   | checkout repo                     |
| `id-token`    | write  | OIDC token exchange（App 認證）    |

## 安裝步驟

### Step 1：前往 GitHub App 頁面

開啟瀏覽器，前往：

```
https://github.com/apps/claude
```

### Step 2：點擊 Install

點擊頁面上的 **Install** 按鈕（若已安裝其他 org，選擇 **Configure** → 加入 repo）。

### Step 3：選擇安裝目標

- **Account**：選擇 `kctw-dev`（Organization）
- **Repository access**：選擇 **Only select repositories** → 選取 `kctw-dev/shikigami`

> 最小權限原則：僅授予 shikigami repo，不選 All repositories。

### Step 4：授權並完成安裝

點擊 **Install & Authorize**，確認 GitHub 完成安裝流程，頁面跳回 repo 設定頁。

## 驗證方法

安裝完成後，使用以下 `gh api` 指令確認 App 已安裝：

```bash
# 列出 kctw-dev org 底下所有已安裝的 GitHub App installation
gh api /orgs/kctw-dev/installations --jq '.installations[] | {app_slug: .app_slug, id: .id, target_type: .target_type}'
```

預期輸出應包含：

```json
{
  "app_slug": "claude",
  "id": <installation_id>,
  "target_type": "Organization"
}
```

若需確認 App 是否可存取特定 repo：

```bash
# 取得 claude App 的 installation ID
INSTALL_ID=$(gh api /orgs/kctw-dev/installations --jq '.installations[] | select(.app_slug=="claude") | .id')

# 列出該 installation 可存取的 repos
gh api /user/installations/${INSTALL_ID}/repositories --jq '.repositories[].full_name'
```

預期輸出應包含：

```
kctw-dev/shikigami
```

## 驗證 CI 恢復正常

安裝完成後，手動觸發 New Issue Intake workflow 確認修復：

```bash
# 開一個測試 issue 觸發 workflow
gh issue create -R kctw-dev/shikigami --title "CI 驗證測試" --body "測試 Claude Code GitHub App 安裝後 CI 是否恢復正常"

# 觀察 workflow 執行結果
gh run list -R kctw-dev/shikigami --workflow=new-issue-intake.yml --limit 3
```

CI run status 應由 `failure` 轉為 `success`。

## 相關資源

- Claude Code GitHub App：https://github.com/apps/claude
- Workflow 定義：`.github/workflows/new-issue-intake.yml`
- 觸發此 runbook 的 SRE Issue：[#423](https://github.com/kctw-dev/shikigami/issues/423)
- Root Cause：commit `191538d` 遷移至 `claude_code_oauth_token` 後未完成 App 安裝

## 更新紀錄

| 日期       | 變更說明                  | 作者            |
|------------|---------------------------|-----------------|
| 2026-03-23 | 初版建立（Story #423）    | Story-Lifecycle |
