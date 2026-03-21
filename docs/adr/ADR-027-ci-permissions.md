# ADR-027：CI 權限 — Claude Code Headless 模式授權策略

**日期**：2026-03-21
**狀態**：Accepted
**相關 Issue**：#323
**提案者**：Architect Agent

---

## 背景

GitHub Actions 動態派遣 Sprint（US-#323）需要在 CI Runner 上執行 Claude Code，處理以下三個問題：

1. **Claude Code 工具授權**：CI 環境中 Claude Code 無法互動式確認工具使用，需要 headless 授權機制
2. **MCP Server 處置**：CI 環境是否啟動 MCP Server（context-hub、quality-observer 等）
3. **Git Token**：CI 環境中 Claude Code 執行 git push 或 gh issue comment 需要的 token 來源

---

## 選項評估

### 選項 A：--dangerouslySkipPermissions

允許所有工具操作，無任何限制。

**優點**：最簡單，零配置
**缺點**：安全風險極高，任何 Bash 指令皆不受控

**結論**：否決（安全考量）

### 選項 B：互動式確認 + CI 環境偵測

在 CI 環境自動 approve 所有工具請求。

**優點**：保留互動式框架
**缺點**：實作複雜，需要額外的 approve daemon，維護成本高

**結論**：否決（複雜度過高）

### 選項 C：--allowedTools 白名單（本 ADR 決策）

顯式列出允許的工具集，只允許 Sprint 執行所需的工具：
```
Bash,Read,Write,Edit,Grep,Glob,WebSearch,WebFetch
```

**優點**：
- 明確的工具白名單，安全可控
- 最小權限原則（Principle of Least Privilege）
- 不需要額外 daemon 或特殊配置
- 符合 Claude Code CLI 原生設計

**缺點**：
- 若未來新增 Skill 需要新工具，需更新 workflow YAML

**結論**：採用

### 選項 D：GitHub App Token + Fine-grained PAT

使用 GitHub App 產生的短效 token，授予最小 repo 權限。

**優點**：token 有效期短，安全性高
**缺點**：需要 GitHub App 設定，運維複雜度增加

**結論**：輔助採用（GH_TOKEN 作為 secret 傳入，不影響 --allowedTools 決策）

---

## 決策

### 決策 1：工具授權 — --allowedTools（選項 C）

**採用 `--allowedTools` 白名單機制**：

```bash
claude \
  --allowedTools "Bash,Read,Write,Edit,Grep,Glob,WebSearch,WebFetch" \
  --no-mcp \
  -p "$INPUT_SPRINT_COMMAND"
```

白名單工具集覆蓋 Sprint 執行所有必要操作：
- `Bash`：執行驗證腳本、git 操作、gh CLI
- `Read`：讀取 Sprint 文件、AC、ADR、SDD
- `Write`：建立新檔案（測試、新 Skill 等）
- `Edit`：修改現有檔案
- `Grep`：搜尋程式碼
- `Glob`：檔案發現
- `WebSearch`：技術調查（若需要）
- `WebFetch`：API 文件取得（Knowledge Ingestion fallback）

### 決策 2：MCP Server 降級（不啟動）

**CI 環境不啟動 MCP Server**，使用 `--no-mcp` 旗標：

- `quality-observer`：CI 環境 stdio transport 無法連接，降級略過品質指標查詢
- `context-hub`：Knowledge Ingestion 步驟偵測到 `CI=true` 環境變數，自動跳過 MCP 查詢（參照 story-lifecycle-prompt.md §Knowledge Ingestion 步驟 7.5）
- `talk-to-figma`：DESIGN Story 在 CI 環境中觸發降級告警，不阻塞流程

**理由**：
- CI Runner 無 MCP Socket 連線環境
- MCP 失敗時已有 fallback 機制（WebFetch、靜默略過）
- 降低 CI Runner 設定複雜度

### 決策 3：Git Token — GH_TOKEN Secret

- GitHub Actions 環境使用 `secrets.GH_TOKEN` 傳入
- Runner 執行環境透過 `GH_TOKEN` 環境變數供 `gh` CLI 使用
- `git push` 使用 checkout 時的 `GITHUB_TOKEN` 或傳入的 PAT

---

## 影響

1. **新增**：`.github/workflows/sprint-dispatch.yml` — 含 `--allowedTools` 配置
2. **文件**：MCP 降級行為已記錄於 story-lifecycle-prompt.md §Knowledge Ingestion 步驟 7.5
3. **安全**：所有 workflow inputs 透過 `env:` 傳遞，不直接插值至 `run:` 指令（防 injection）

---

## 替代方案考量

| 方案 | 優點 | 缺點 | 決策 |
|------|------|------|------|
| --dangerouslySkipPermissions | 最簡單 | 安全風險極高 | 否決 |
| 互動式確認 + CI 偵測 | 保留框架 | 實作複雜 | 否決 |
| --allowedTools 白名單 | 安全可控，最小權限 | 需維護白名單 | **採用** |
| GitHub App Fine-grained Token | Token 最小權限 | 運維複雜度高 | 輔助（GH_TOKEN secret） |
