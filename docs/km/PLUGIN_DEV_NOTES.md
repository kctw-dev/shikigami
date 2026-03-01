# Plugin 開發注意事項

開發 shikigami plugin 時踩過的坑，記錄在此避免重蹈覆轍。

---

## plugin.json 格式

`.claude-plugin/plugin.json` **不需要**指定 `skills`、`agents`、`commands`、`hooks` 的路徑。Claude Code 會自動偵測目錄結構。

```json
// ✗ 錯誤 — 加了反而會 validation error
{
  "skills": "./skills/",
  "agents": "./agents/",
  "commands": "./commands/",
  "hooks": "./hooks/hooks.json"
}

// ✓ 正確 — 只放 metadata
{
  "name": "shikigami",
  "description": "...",
  "version": "1.0.0",
  "author": { "name": "KCTW" },
  "homepage": "https://github.com/KCTW/shikigami",
  "repository": "https://github.com/KCTW/shikigami",
  "license": "MIT",
  "keywords": [...]
}
```

---

## Agent Frontmatter

Agent `.md` 檔的 YAML frontmatter 必須用 `description`，不能用 `purpose`。`model` 必須是具體值（如 `sonnet`），不支援 `inherit`。

```yaml
# ✗ 錯誤
---
name: developer
purpose: "..."
model: inherit
---

# ✓ 正確
---
name: developer
description: "..."
model: sonnet
---
```

---

## marketplace.json

`.claude-plugin/marketplace.json` 中的 plugin `source` 使用 `"./"` 指向自身（plugin 內容在 repo 根目錄）。

```json
{
  "plugins": [
    {
      "name": "shikigami",
      "source": "./"
    }
  ]
}
```

---

## 安裝流程

使用者安裝 shikigami 需要兩步：

```bash
# 1. 加入 marketplace（首次）
/plugin marketplace add KCTW/shikigami

# 2. 安裝 plugin
claude plugin install shikigami
```

`claude plugin install github:KCTW/shikigami` 一步到位的方式有 bug，不推薦。

---

## 開發 → 測試循環

本地修改後的測試流程：

```bash
# 1. commit + push
git add ... && git commit -m "..." && git push

# 2. 更新 marketplace clone
cd ~/.claude/plugins/marketplaces/shikigami && git pull

# 3. 重新安裝
claude plugin install shikigami

# 4. 開新 session 測試
```

---

## Plan Mode 與 Shikigami 的互斥關係

### 問題

Claude Code 的 Plan Mode 啟用時，Shikigami 的 Skill 調度會被完全封印。所有 `invoke shikigami:*` 的觸發都不會執行，式神團隊形同癱瘓。

Sprint 1 曾因 Session 開始時進入 Plan Mode，導致 Scrum Master 無法調度任何角色，浪費了探索時間。

### 原因

Plan Mode 是 Claude Code 的內建機制，進入後主 Agent 只能使用有限的工具（Read、Glob、Grep 等探索工具）。Skill 調度和 Agent 派遣都被禁用，因此 Shikigami 的整個治理流程無法運作。

### 避免方式

1. **不要在 Session 開始時主動進入 Plan Mode**。如果 Claude Code 提示是否進入 Plan Mode，選擇拒絕
2. **需要規劃時使用 Shikigami 自己的流程**：`sprint-planning`（Sprint 規劃）、`architecture-decision`（技術決策）、`backlog-management`（需求管理）都有內建的規劃流程
3. **如果已經在 Plan Mode 中**：使用 `ExitPlanMode` 工具退出，然後重新讓 Scrum Master 接管調度

---

## 環境注意

- `~/.bashrc` 不要放 `GITHUB_TOKEN`（過期 token 會干擾 git push）
- 依賴 `gh auth login` 做 GitHub 認證即可
