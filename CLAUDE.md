# Shikigami — Claude Code Plugin 開發指南

## 專案資訊

- **專案名稱**：Shikigami（式神）
- **性質**：Claude Code Plugin — AI Agent Scrum Team 框架
- **目前版本**：v0.91.0
- **授權**：MIT
- **Repository**：https://github.com/KCTW/shikigami

## 技術棧

- **Plugin 格式**：Claude Code Plugin（`.claude-plugin/plugin.json`）
- **Agent 定義**：YAML frontmatter + Markdown body（`agents/*.md`）
- **Skill 定義**：Markdown（`skills/*/SKILL.md`）
- **Hook**：JSON 配置 + Shell script（`hooks/`）
- **MCP Server**：Node.js（`mcp-servers/`）
- **驗證腳本**：Bash（`scripts/validate-*.sh`）
- **測試**：Shell script（`tests/test-*.sh`）
- **多平台支援**：Claude Code / OpenCode / Gemini CLI / Cursor

## 開發紅線

1. **版號同步**：bump 版本時必須同時更新 `plugin.json`、`marketplace.json`、`gemini-extension.json`、`CLAUDE.md`、`README.md` badge
2. **語言慣例**：Skill / Agent 內容使用中文，檔名使用英文 kebab-case
3. **Agent model**：所有 agent 統一使用 `model: sonnet`
4. **禁止幻覺**：非發散階段（Discovery 以外）禁止生成未定義內容，遇未定義情況應回退詢問
5. **TDD 雙重驗證**：寫不出測試代表需求不清，必須回退釐清而非強行實作
6. **日期來源**：所有日期時間必須用 `date` 指令取得系統時間，不可靠 agent 推斷
7. **.md 受眾**：`.md` 文件是給 agent 消費的，其他格式（PDF、HTML）才是給人看的
8. **跨機器多團隊**：所有新功能必須考慮「多台機器各開一個 session 同時工作」的場景。共用檔案 append 會 git conflict — 改用 per-session 檔案 + 結算機制。取號用 GitHub Issue `#N` 或 claim 鎖，不可自行編號。
9. **project_level 行為紀律**：各等級行為如下，嚴格遵守，不得混淆：
   - `project_level=low`：**所有操作自動執行，禁止停下來問使用者**。包括但不限於：Sprint Planning 完成後自動 Sprint Execution、Sprint Execution 完成後自動 Sprint Review、auto-shoot 發現 actionable 自動派工、Feedback Routing 自動轉送、需要 compact 直接 compact 再繼續。
   - `project_level=medium`：高風險操作（Sprint Planning 啟動、Sprint Execution 啟動）留言通知等使用者確認；日常低風險操作自動執行。
   - `project_level=high`：每個重要步驟都必須等人確認，只標記不自動觸發。
10. **CI Actions 版本釘定**：所有 GitHub Actions 統一使用 `@v4`，升級需先確認 self-hosted runner 相容性，並經人工審核後才能更新版本號。新增或修改 workflow 時執行 `bash scripts/validate-ci-versions.sh` 驗證。**升級確認時機**：INFRA Story 涉及 CI Actions 版本升級時，確認須在 Sprint Planning 前完成，避免 Sprint 中途因版本不相容而阻塞。
11. **GitHub URL 可讀取**：遇到 GitHub URL（含 attachment），帶 `gh auth token` 認證直接讀取，不要報「無法讀取」。
12. **平行 Worktree OOM 防護**：平行 worktree subagent 過多會 OOM（Sprint 127 歷史案例：4 個 worktree 觸發 core dump）。`SHIKIGAMI_MAX_PARALLEL` 預設 2，**未設定時亦視為 2，不得無限平行**。派遣前必須執行 `git worktree list` 計算現存數量；重派前必須確認同任務 agent 是否還在跑，避免重複派遣。詳見 `skills/sprint-execution/references/parallel-safety.md`。
13. **Workflow issue body 一律使用 `--body-file` 模式**：GitHub Actions workflow 中建立或更新 Issue body 時，禁止直接以 `--body "..."` 傳入多行字串。body 內容必須寫入暫存檔案後以 `--body-file <file>` 引用，避免 body 含冒號（`:`）、星號（`*`）、引號等 YAML 特殊字符導致 workflow YAML parse error（Sprint 135 歷史案例：#597）。範例：
    ```bash
    # 正確（--body-file 模式）
    printf '%s\n' "Issue body content" "可安全使用：冒號、*星號*" > /tmp/issue-body.txt
    gh issue create --title "..." --body-file /tmp/issue-body.txt
    # 錯誤（直接 --body，禁止）
    gh issue create --title "..." --body "含冒號：或 *星號* 的內容"
    ```

## 目錄結構

```
.claude-plugin/
├── plugin.json              # Plugin manifest（版號 source of truth）
└── marketplace.json         # Marketplace 發布資訊

agents/                      # 8 個角色定義
skills/                      # 29 個 Skill
hooks/                       # Hook 配置（hooks.json + session-start/）
commands/                    # 4 個 slash command
mcp-servers/                 # MCP server（quality-observer：品質指標查詢，stdio transport）
templates/                   # CLAUDE.md / GEMINI.md / SDD 模板
scripts/                     # 驗證腳本（validate-*.sh）
tests/                       # 測試腳本（test-*.sh）
docs/
├── adr/                     # 架構決策紀錄
├── sdd/                     # 系統設計文件
├── sprints/                 # Sprint 紀錄
├── km/                      # 知識管理
└── tutorial/                # 教學文件
```

## Commit 慣例

使用 Conventional Commits：

- `feat:` — 新功能（新 Skill、新 Agent、新流程）
- `fix:` — Bug 修復
- `chore:` — 版本 bump、維護
- `docs:` — 文件更新
- `shoot:` — Shoot 模式快速交付

## 驗證

修改後執行驗證腳本確認一致性：

```bash
bash scripts/validate-version.sh    # 版號一致性
bash scripts/validate-agents.sh     # Agent 定義
bash scripts/validate-skills.sh     # Skill 結構
bash scripts/validate-json.sh       # JSON 格式
bash scripts/validate-xrefs.sh      # 交叉引用
bash scripts/validate-commands.sh   # Command 定義
bash scripts/validate-gemini.sh     # Gemini 配置
bash scripts/validate-orphans.sh    # 孤立檔案偵測
```

## 常用工作流

```bash
# 跑全部測試
bash tests/test-*.sh

# 跑單一測試
bash tests/test-shoot-skill.sh

# 跑全部驗證
for f in scripts/validate-*.sh; do bash "$f"; done
```

- **新增 Skill**：透過 `/shoot` 或 `/sprint-execution` 流程，不可手動直接建立
- **新增 Agent**：同上，走團隊流程
- **Bump 版號**：同時更新 `plugin.json`、`marketplace.json`、`gemini-extension.json`、`CLAUDE.md`、`README.md` badge

## AI 團隊行為

- AI 團隊無工作量限制，同概念工作應打包一起做
- 校準儀式自動完成，不等 Stakeholder 回覆
- Sprint 外小修用 patch bump
- Sprint Review 的 `gh issue` 操作委託 subagent，不在主 session 跑
