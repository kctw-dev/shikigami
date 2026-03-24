# §5 腳本生成模板（AC3）

腳本自動生成至 `scripts/<skill-name>_cron.sh`，由 `templates/schedule_cron.sh.tmpl` 填入以下佔位符：

## 佔位符說明

| 佔位符 | 說明 |
|--------|------|
| `{{SKILL_NAME}}` | Skill 名稱（如 `sprint-execution`） |
| `{{INTERVAL}}` | 人類可讀 interval（如 `5m`） |
| `{{CRON_EXPR}}` | cron 表達式（如 `*/5 * * * *`） |
| `{{PROJECT_DIR}}` | 專案根目錄絕對路徑 |
| `{{PROJECT_HASH}}` | 專案目錄路徑 MD5 前 8 碼 |
| `{{TIMESTAMP}}` | 生成時間戳（ISO 8601） |
| `{{ALLOWED_TOOLS}}` | 從 SKILL.md frontmatter `requiredTools` 讀取 |
| `{{REQUIRED_TOOLS_HASH}}` | `requiredTools` 清單 MD5，供版本追蹤用 |

## allowedTools 白名單（ADR-005 決策域三）

從目標 Skill 的 `SKILL.md` frontmatter 使用 awk 解析 `requiredTools` YAML 清單，組裝為 `--allowedTools` 參數。

**預設白名單**（Skill 無 `requiredTools` 聲明時使用）：

```
Read Glob Grep Edit Write Bash
```

MCP 工具（如 `mcp__github__*`）不納入預設白名單，必須在 Skill 的 SKILL.md 中明確聲明。

## 排程 PR 建立規範（US-54 AC3）

排程腳本執行完成後，若有需要建立 PR（例如 sprint-execution 產生變更），**必須**在 PR 建立指令中附加 `--label "scheduled"` label，以便 Scrum Master 在互動 Session 啟動時能夠偵測並提醒審核。

**規則**：
- 所有由排程腳本（`*_cron.sh`）觸發的 PR 建立操作，必須帶有 `--label "scheduled"`
- `scheduled` label 為固定必填，不得省略
- label 不存在時先建立：`gh label create "scheduled" --color "#0075ca" --description "排程自動執行產生的 PR"`

**設計理由**：`scheduled` label 是 Scrum Master §5.3 排程 PR 偵測的依據。若排程 PR 缺少此 label，偵測機制將無法找到待審 PR，破壞 Issue #46 的完整性。

## 鎖檔案命名（ADR-005 決策域二）

鎖檔案路徑格式（含 project-hash，防止多專案撞名）：

```
/tmp/shikigami-schedule-<project-hash>-<skill-name>.lock
```

`<project-hash>` 為專案目錄路徑 MD5 前 8 碼。

**設計理由**：同一台機器上的不同 Shikigami 專案排程相同 Skill 時，因 project-hash 不同而使用不同鎖，互不干涉（ADR-005 Stakeholder Review 修訂一）。
