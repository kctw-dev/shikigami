# 多平台調查報告：Cursor / OpenCode / Codex CLI 可行性分析

**M5 標注**：本文件對應 M5（平台擴展前置研究）里程碑，US-17 調查完成
**調查日期**：2026-03-02
**執行者**：AI Agent（Developer Subagent，Claude Sonnet 4.6）
**關聯 Issues**：#3（支援 OpenCode / Codex 平台安裝）、#4（支援 Cursor 平台安裝）
**Sprint**：Sprint 16

---

## M5 前置條件確認記錄

在執行本調查前，已確認以下前置條件：

| Issue | 標題 | 狀態（2026-03-02 確認） |
|-------|------|------------------------|
| #3 | 支援 OpenCode / Codex 平台安裝 | **OPEN** |
| #4 | 支援 Cursor 平台安裝 | **OPEN** |

確認方式：執行 `gh issue view 3 --json state` 與 `gh issue view 4 --json state`，兩者均回傳 `{"state":"OPEN"}`。外部使用者需求仍然有效，調查具備執行依據。

---

## 調查背景

Shikigami 框架目前僅在 Claude Code 平台驗證過完整功能。核心機制（Subagent dispatch、Skill invocation、SKILL.md 載入、Task tool、SessionStart hook）高度依賴 Claude Code 的特有功能。

本調查針對三個候選平台評估：

1. **Cursor**（v2.4+）— GUI-based AI IDE，2026 年 1 月新增 Subagents 支援
2. **OpenCode**（v1.0.190+）— 開源 CLI agentic 工具，原生支援 Skills 系統
3. **Codex CLI** — OpenAI 官方 CLI agent，使用 AGENTS.md 系統

每個平台均從四個維度評估：
- **(a) SKILL.md 載入機制**：平台是否支援等效的 instructions file / context 載入
- **(b) Subagent 派遣支援**：是否支援 Task tool 或等效的子任務並行執行能力
- **(c) 權限模型**：工具呼叫權限是否支援 bash、file read/write、gh CLI 等必要操作
- **(d) 整合可行性評分（1–5 分）**：附評分理由

---

## AC1：Cursor 可行性分析

### 平台概述

Cursor 是建立在 VS Code 基礎上的 AI-first IDE。2026 年 1 月發布的 v2.4 版本引入了 Subagents 系統，是 Cursor 在 agentic 能力上的重要里程碑。

### (a) SKILL.md 載入機制

**支援程度：部分支援（需格式轉換）**

Cursor 使用以下幾種指令載入機制：

| 機制 | 說明 | 等效性 |
|------|------|--------|
| `.cursorrules`（舊版） | 專案根目錄的靜態規則文件 | 等效於 SKILL.md 靜態內容 |
| `.cursor/rules/*.mdc`（現行） | MDC 格式，含 frontmatter（globs、alwaysApply 等）| 等效於 SKILL.md，但格式不兼容 |
| Cursor 2.4 Skills Marketplace | SKILL.md 格式的 manifest，可從 marketplace 下載 | **部分直接相容** |

Cursor 2.4 的 Skills Marketplace 採用 SKILL.md manifest 格式，這與 Shikigami 現有的 SKILL.md 格式存在結構性相似性，但 Cursor 的 `.mdc` 格式含有 Shikigami SKILL.md 沒有的 frontmatter 欄位（如 `alwaysApply`、`globs`）。

社群工具 `rule-porter` 可以雙向轉換 `.mdc` 規則與 CLAUDE.md/AGENTS.md 格式，顯示存在轉換路徑。

**關鍵限制**：Cursor 2.4 的 Memory 機制目前仍存在「每 Session 重置」問題，Project Knowledge 不會跨 Session 持久化，需要用戶每次手動重新載入或透過 `.cursor/rules/` 靜態設定。

### (b) Subagent 派遣支援

**支援程度：原生支援（v2.4+）**

Cursor 2.4 正式引入 Subagents 功能：

- Subagents 可**並行執行**，每個 Subagent 擁有獨立的 context window
- 支援 agent-to-agent 通訊（parent agent 指派任務給 subagent）
- 可透過 `.cursor/agents/` 目錄配置自訂 Subagent（含自訂 prompt、工具存取權限、使用的 model）
- 支援的並行模式：例如 Subagent A 研究文件，Subagent B 撰寫代碼，Subagent C 執行 terminal 命令

**與 Shikigami Task tool 的對應**：Claude Code 的 Task tool 允許 parent agent 以程式化方式派遣 subagent。Cursor 的派遣機制為 AI 驅動（由 parent agent 自主決定是否派遣 subagent），目前尚無等效的 `Task tool` API 供 SKILL.md 直接呼叫。

**限制**：Cursor Subagents 的觸發機制較不確定性（AI 自主決定），而 Shikigami 需要在 SKILL.md 中明確呼叫 `Task tool` 進行可預測的 subagent 派遣。

### (c) 權限模型

**支援程度：支援，但有沙箱限制**

Cursor 2026 年初推出 Agent Sandboxing（沙箱隔離系統）：

| 工具 | 預設狀態 | 說明 |
|------|----------|------|
| Bash / Terminal | 允許（沙箱內） | 可執行終端命令，限制在工作目錄內 |
| File read/write | 允許（工作目錄） | 可讀寫工作目錄內的檔案 |
| 網路存取 | 需明確授權 | 沙箱外需使用者確認 |
| `gh` CLI | 有限支援 | 網路存取需要授權，GH_TOKEN 需預先設定 |

Seatbelt（macOS）或等效機制控制 subprocess tree 的 syscall 和檔案存取。代理在沙箱外發出請求時需要使用者確認，但減少了 40% 的打斷次數（Cursor 2026 年 2 月生產數據）。

**安全注意事項**：已發現 CVE-2026-22708 漏洞（Pillar Security 揭露），攻擊者可透過 shell built-in 命令繞過沙箱。此漏洞的存在表明沙箱機制仍在持續演進中。

**gh CLI 評估**：gh CLI 需要網路存取，在 Cursor 沙箱中需要明確授權。GH_TOKEN 需透過環境變數預先設定，操作上可行但需要使用者的額外設定步驟。

### (d) 整合可行性評分

**評分：3 / 5**

| 評分維度 | 評估 |
|----------|------|
| SKILL.md 相容性 | 格式不直接相容，需轉換層；Cursor Skills Marketplace 提供部分路徑 |
| Subagent 能力 | 已具備並行執行能力，但程式化 Task tool API 尚未開放 |
| 權限充足性 | bash + file I/O 可行，gh CLI 需額外授權設定 |
| 生態系統成熟度 | 快速演進（v2.4 於 2026/01 釋出），但 API 穩定性待觀察 |
| Shikigami 遷移成本 | 中高（需要格式轉換 + Task tool 機制重新設計） |

**評分理由**：Cursor 2.4 已具備 Subagents 並行執行能力，SKILL.md 格式有轉換工具支援，bash 和 file I/O 在沙箱內可行。主要阻礙是程式化 Task tool API 尚未對外開放（subagent 派遣由 AI 自主決定，不可程式化控制），以及 SKILL.md 格式需要轉換。整體可行但需中等遷移成本。

---

## AC2：OpenCode 可行性分析

### 平台概述

OpenCode 是開源的 CLI agentic coding 工具（類似 Claude Code），模型無關（不綁定特定 AI 模型）。v1.0.190+ 版本已將 Skills 系統內建為原生功能。

### (a) SKILL.md 載入機制

**支援程度：原生支援（高度相容）**

OpenCode 的 Skills 系統與 Shikigami 的 SKILL.md 設計幾乎完全吻合：

| 機制 | OpenCode | Shikigami |
|------|----------|-----------|
| Skills 目錄 | `.opencode/skills/*/SKILL.md` | `skills/*/SKILL.md` |
| 全域 Skills | `~/.config/opencode/skills/` | 無（專案為主） |
| 載入方式 | On-demand（agent 見到可用 skills 並按需載入全文） | On-demand（SKILL.md 作為 system prompt）|
| AGENTS.md | 專案根目錄 `AGENTS.md`，全域 `~/.config/opencode/AGENTS.md` | `CLAUDE.md` 等效 |

**關鍵特點**：OpenCode 的 Skills 搜尋路徑包含 `.opencode/` 目錄和 git worktree 中的 `skills/*/SKILL.md`，與 Shikigami 的目錄結構高度一致。僅需建立 `.opencode/` 目錄並設定 symlink 或直接複製即可啟用。

**Rules 系統**：AGENTS.md 提供跨 session 的持久化指令，對應 Shikigami 的 CLAUDE.md/SKILL.md 框架。

### (b) Subagent 派遣支援

**支援程度：原生支援（內建 Task tool）**

OpenCode 的 Subagent 系統功能豐富：

- **內建 Subagents**：General（通用）和 Explore（探索）兩個預設 subagent
- **Task tool**：透過 Task tool 程式化派遣 subagent（與 Claude Code 高度相似）
- **@mention 手動呼叫**：可在訊息中以 `@agent-name` 手動呼叫特定 subagent
- **自訂 Subagents**：可透過設定檔定義自訂 subagent
- **Task tool 權限控制**：`permission.task` 支援 glob pattern 控制哪些 subagent 可被呼叫

**與 Shikigami Task tool 的對應**：OpenCode 的 Task tool 與 Claude Code 的 Task tool API 設計相似，Shikigami SKILL.md 中的 subagent 派遣呼叫可能以最小修改移植。

### (c) 權限模型

**支援程度：完整支援，細粒度可配置**

OpenCode 的權限模型設計靈活：

| 工具 | 預設行為 | 可配置選項 |
|------|----------|-----------|
| `bash` | 可配置（ask/allow/deny） | 支援命令層級控制 |
| File edit | 可配置（ask/allow/deny） | 支援路徑 glob 控制 |
| webfetch | 可配置（ask/allow/deny） | 可限定域名 |
| `gh` CLI | 透過 bash 工具執行，需 GH_TOKEN | 環境變數設定後可正常運作 |

**Per-agent 覆蓋**：每個 Subagent 可以有獨立的權限設定，parent agent 規則與 global config 合併（agent 規則優先），這對 Shikigami 的角色隔離模型（PO / Architect / QA / Developer / SM）非常有利。

**gh CLI 評估**：gh CLI 作為 bash 命令執行，設定 `GH_TOKEN` 環境變數後可完整執行。沒有特殊的網路沙箱限制（取決於 bash 工具的配置）。

### (d) 整合可行性評分

**評分：4 / 5**

| 評分維度 | 評估 |
|----------|------|
| SKILL.md 相容性 | 高度相容，目錄結構幾乎一致，需最小適配 |
| Subagent 能力 | 原生 Task tool 支援，與 Claude Code API 相似，移植成本低 |
| 權限充足性 | bash + file I/O + gh CLI 均可正常運作，per-agent 權限隔離 |
| 生態系統成熟度 | 活躍開發，v1.0.190 已穩定，社群 skills 和 plugins 豐富 |
| Shikigami 遷移成本 | 低（主要為目錄設定，SKILL.md 格式相容，Task tool 類似）|

**評分理由**：OpenCode 在四個維度中有三個（SKILL.md、Subagent、權限）幾乎與 Claude Code 對等，且設計理念相同（open source、model-agnostic）。扣 1 分原因：模型無關性意味著不同模型的行為差異可能導致 SKILL.md prompt engineering 需要重新調優，且部分 Claude Code 特有的行為（如 SessionStart hook 的觸發時機）可能需要適配。

---

## AC3：Codex CLI 可行性分析

### 平台概述

Codex CLI 是 OpenAI 官方的命令列 agent 工具，使用 GPT 系列模型（最新為 GPT-5.3-Codex，2026 年 2 月更新）。以安全沙箱和 AGENTS.md 指令系統為核心設計。

### (a) SKILL.md 載入機制

**支援程度：支援（格式不同，需重命名）**

Codex CLI 使用 AGENTS.md 系統：

| 機制 | Codex CLI | Shikigami |
|------|-----------|-----------|
| 指令文件名稱 | `AGENTS.md`（固定命名） | `SKILL.md`（Shikigami 命名）|
| 全域覆蓋 | `~/.codex/AGENTS.override.md` 或 `AGENTS.md` | 無等效機制 |
| 階層載入 | 從 project root 往下至 cwd 逐層讀取 | 單一專案層級 |
| 條件載入 | 不支援 on-demand（全部預先載入至 context）| on-demand 載入 |

**載入邏輯**：Codex 在執行前讀取所有沿路徑的 AGENTS.md 文件（`~/.codex/AGENTS.md` → project root `AGENTS.md` → subdirectory `AGENTS.md`），並全部注入至 system prompt context。

**適配方案**：將 SKILL.md 重命名為 AGENTS.md，或在各 skills 子目錄放置 AGENTS.md 包含對應 SKILL.md 的內容。缺點是無法實現 on-demand 載入，所有 skills 會一次性載入 context（可能導致 context window 壓力）。

### (b) Subagent 派遣支援

**支援程度：有限支援（非原生，需 MCP 擴充）**

Codex CLI 的 Subagent 能力較為受限：

- **原生 Multi-agent**：Codex CLI 有 multi-agent 文件，但 sub-agents 繼承當前沙箱策略，且以 non-interactive 模式執行
- **Sub-agent 限制**：若 sub-agent 嘗試需要新的 approval 的操作，操作失敗並將錯誤回傳給 parent workflow
- **MCP 擴充**：社群方案 `codex-subagents-mcp` 透過 MCP server 實現類似 Claude Code 的 subagent 功能，每次呼叫建立 clean context，透過 AGENTS.md 注入 persona，使用 `codex exec --profile <agent>` 保持隔離狀態
- **`/profile` 系統**：支援 `codex exec --profile` 載入特定 profile，可部分替代 subagent 派遣

**與 Shikigami Task tool 的對應**：Codex CLI 缺乏與 Claude Code Task tool 直接對應的原生 API。需透過 MCP 擴充或 `--profile` 系統間接實現，移植複雜度高。

### (c) 權限模型

**支援程度：支援，但有嚴格預設限制**

Codex CLI 的沙箱設計以安全性優先：

| 工具 | 預設行為 | 完整存取設定 |
|------|----------|-------------|
| File read | 允許（工作目錄） | 預設開放 |
| File write | 允許（workspace-write 沙箱內） | 預設開放（工作目錄）|
| Bash / 命令執行 | 允許（Auto 模式，工作目錄內）| 預設開放 |
| 網路存取 | **預設關閉** | 需 `network_access = true` |
| `gh` CLI | **預設無法運作** | 需額外設定（見下方）|

**gh CLI 的嚴重阻礙**：這是最關鍵的整合阻礙。gh CLI 需要網路存取，但 Codex CLI 預設沙箱完全封鎖網路。已確認的問題：
- `GH_TOKEN` 在沙箱環境中不可存取（Issue #10695）
- 需要 Manual Approval Mode（Full Access）才能使用 `GH_TOKEN`（Issue #3837）
- 官方建議的替代方案：使用 GitHub Actions 執行需要網路的操作，Codex 專注於代碼編輯和 PR 撰寫

**設定後的可行性**：透過 `~/.codex/config.toml` 設定 `network_access = true`，或執行時加上 `-c 'sandbox_workspace_write.network_access=true'` 參數，可啟用網路存取。但此設定降低了安全性隔離效果，且需要每位使用者手動設定。

### (d) 整合可行性評分

**評分：2 / 5**

| 評分維度 | 評估 |
|----------|------|
| SKILL.md 相容性 | 需重命名為 AGENTS.md，且無法 on-demand 載入（context 壓力） |
| Subagent 能力 | 原生能力受限（non-interactive 沙箱繼承），需 MCP 擴充 |
| 權限充足性 | gh CLI 預設無法使用（網路封鎖），需額外設定且有安全顧慮 |
| 生態系統成熟度 | 官方維護，更新積極，但 agentic 功能相對保守 |
| Shikigami 遷移成本 | 高（gh CLI 整合問題、subagent 需 MCP 擴充、context 管理重新設計）|

**評分理由**：Codex CLI 的安全沙箱設計雖然值得肯定，但與 Shikigami 的核心需求（gh CLI 操作、programmatic subagent dispatch）存在根本性的衝突。預設網路封鎖使 gh CLI 無法直接使用，subagent 派遣需要依賴社群 MCP 擴充而非原生支援。雖然技術上可以透過設定繞過，但會增加使用者設定負擔並降低安全性，不符合 Shikigami 的設計原則。

---

## AC4：後續行動建議

### (a) 三個平台優先排序

| 排序 | 平台 | 評分 | 排序理由 |
|------|------|------|----------|
| 1st | **OpenCode** | 4/5 | SKILL.md 格式高度相容、原生 Task tool 類似 Claude Code、bash/gh CLI 無沙箱阻礙、開源且活躍社群 |
| 2nd | **Cursor** | 3/5 | 具備 Subagents 並行執行（v2.4）、使用者基礎廣大、但 SKILL.md 需格式轉換且程式化 Task tool 尚未開放 |
| 3rd | **Codex CLI** | 2/5 | gh CLI 預設無法使用（網路沙箱封鎖）、原生 subagent 能力受限、整體遷移成本最高 |

### (b) 最優先平台（OpenCode）的已知阻礙事項

1. **模型行為差異**：OpenCode 為 model-agnostic，不同 LLM 對相同 SKILL.md prompt 的執行品質可能不一致，需針對不同模型進行 prompt engineering 調優。

2. **SessionStart hook 適配**：Shikigami 依賴 Claude Code 的 SessionStart hook 觸發機制，OpenCode 可能有不同的 session 生命週期事件（需確認 OpenCode 的 hook/event 系統）。

3. **Claude Code 特有 API 殘留**：SKILL.md 中可能有引用 Claude Code 特有功能的描述（如特定 tool 名稱、API 參數格式），需審查並適配。

4. **Task tool 參數格式差異**：雖然 OpenCode 有 Task tool，但與 Claude Code 的 Task tool 參數格式可能有差異，需對照文件確認。

### (c) 下一步具體行動

**OpenCode（立即可執行，Sprint 17 候選）**

1. **建立 OpenCode POC Sprint**：在 Sprint 17 或 Sprint 18 規劃一個 S-size Story，目標為在 OpenCode 環境中成功載入 `skills/sprint-planning/SKILL.md` 並觸發 Sprint Planning 流程。驗收標準：能夠完整執行 Sprint Planning 的 Happy Path，無需修改 SKILL.md 核心邏輯。

2. **目錄適配層**：建立 `.opencode/` 目錄，內含指向現有 `skills/` 的 symlink 設定指南（或自動化腳本），以最低成本實現 SKILL.md 載入。

3. **SessionStart hook 調查**：調查 OpenCode 的 session 生命週期文件，確認是否有等效 hook 機制，並在調查後更新本文件。

**Cursor（中期，需等待 API 穩定）**

4. **等待 Task tool API 開放**：Cursor 2.4 的 Subagents 系統的程式化 Task tool API 目前不可用，建議在 Cursor v2.5 或後續版本開放 API 後再評估。預計評估時機：2026 Q2。

5. **格式轉換工具評估**：評估 `rule-porter` 等工具是否可自動化 Shikigami SKILL.md → Cursor Rules 的格式轉換，若可行則降低遷移成本至 L 評級以下。

**Codex CLI（延後評估）**

6. **等待沙箱政策演進**：Codex CLI 的 gh CLI 阻礙源於網路沙箱設計決策，而非技術限制。建議追蹤 OpenAI 的 Codex roadmap，等待官方提供更靈活的 gh CLI 整合方案（如官方 GitHub integration）再重新評估。預計重新評估時機：Codex CLI 官方提供 GitHub integration 後。

---

## 附錄：調查資料來源

- [Cursor Subagents 官方文件](https://cursor.com/docs/context/subagents)
- [Cursor 2.4 Release Notes](https://cursor.com/changelog/2-4)
- [Cursor Agent Sandboxing](https://cursor.com/blog/agent-sandboxing)
- [Cursor Agent Security](https://cursor.com/docs/agent/security)
- [OpenCode Agents 文件](https://opencode.ai/docs/agents/)
- [OpenCode Skills 文件](https://opencode.ai/docs/skills/)
- [OpenCode Permissions 文件](https://opencode.ai/docs/permissions/)
- [Codex CLI 官方文件](https://developers.openai.com/codex/cli/)
- [Codex AGENTS.md 指南](https://developers.openai.com/codex/guides/agents-md/)
- [Codex Security Guide](https://developers.openai.com/codex/security/)
- [Codex Multi-agents 文件](https://developers.openai.com/codex/multi-agent/)
- [GitHub Issue #3837：Codex GH_TOKEN Manual Approval](https://github.com/openai/codex/issues/3837)
- [Codex gh CLI 限制分析](https://smartscope.blog/en/Tips/GitHub/codex-gh-cli-limitations/)
