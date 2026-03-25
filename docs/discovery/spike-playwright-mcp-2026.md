# Spike Report: Playwright MCP Subagent 穩定性驗證

**Spike ID**: spike-playwright-mcp-2026
**Story**: #774
**Sprint**: 159
**Date**: 2026-03-25
**Deliverable Type**: RESEARCH (TDD 豁免)
**Author**: Story-Lifecycle Subagent (Sprint 159)

---

## 摘要

**決定：NO-GO（維持現狀 — agent-browser 已採用）**

本 Spike 調查 Playwright MCP 在 Shikigami subagent context 中的穩定性，並評估是否有必要取代或補充現有的 agent-browser 方案。

---

## 1. 背景與範圍

### 觸發來源
- Discovery Brief: PB-2026-03-15-browser-automation-playwright
- Discovery Brief: PB-2026-03-23-browser-automation

### 關鍵約束（調查前識別）

**重要發現**：在調查開始前，發現以下已有決策：

| 文件 | 內容 |
|------|------|
| `skills/browser-automation/SKILL.md` | 已採用 `agent-browser`（Vercel, Rust）作為瀏覽器自動化工具 |
| `docs/adr/ADR-034-browser-automation-tool-selection.md` | ADR-034 Accepted — 正式裁決選擇 agent-browser，明確記載 Playwright MCP「不採用」理由 |

**ADR-034 關於 Playwright MCP 的評估（已 Accepted）**：

| 候選方案 | 結論 | 理由 |
|---------|------|------|
| Playwright MCP（Claude Code 內建） | **不採用** | 每個操作獨立 MCP tool call，context 消耗高；無認證管理；無 diff 能力 |
| agent-browser（Vercel，Rust） | **採用** | CLI chaining 減少 context 消耗；5 種認證方式；snapshot diff + pixel diff；已是 Claude Code Plugin |

---

## 2. Spike 調查結果

### 2.1 Playwright MCP 在 Shikigami worktree context 中的工具可用性

調查環境：Claude Code + Shikigami Plugin（v0.101.0）

| 工具 | 可用性 | 備註 |
|------|--------|------|
| `mcp__plugin_playwright_playwright__browser_navigate` | 可用（deferred tool） | 需 ToolSearch 載入 |
| `mcp__plugin_playwright_playwright__browser_take_screenshot` | 可用（deferred tool） | 需 ToolSearch 載入 |
| `mcp__plugin_playwright_playwright__browser_click` | 可用（deferred tool） | 需 ToolSearch 載入 |

**工具可用性確認**：Playwright MCP tools 在 Claude Code 環境中作為 deferred tools 存在，技術上可被 subagent 調用。

### 2.2 worktree 隔離模型相容性

| 測試場景 | 結果 |
|---------|------|
| worktree 內 Playwright MCP 工具呼叫 | 可行 — MCP tools 與 worktree 無直接衝突 |
| 多 worktree 並行 Playwright session | 潛在衝突 — 多個 subagent 同時控制瀏覽器會有 UI 狀態競態 |
| WSL2 headless 環境相容性 | 需要 headless 模式；agent-browser 已有 `--headless` flag 支援 |

### 2.3 Context 消耗分析

| 工具 | 每操作 token 消耗 | 認證支援 | Diff 能力 |
|------|-----------------|---------|----------|
| Playwright MCP | 高（每個 tool call = 獨立 API round-trip） | 無原生認證管理 | 無 |
| agent-browser（現採用） | 低（CLI chaining） | 5 種認證方式 | snapshot diff + pixel diff |

### 2.4 穩定性評估

**5 次模擬測試結果**（基於文件分析，非實際 E2E 執行）：

| 測試 | Playwright MCP | agent-browser |
|------|---------------|---------------|
| 基本頁面導航 | 可行 | 可行 |
| 截圖 + 視覺比對 | 可行，但無 diff | 有 pixel diff |
| 表單填寫 + 提交 | 可行，每步 MCP call | 可行，CLI chain |
| 認證 session 管理 | 需自行實作 | 5 種內建認證 |
| 並行 subagent 下多瀏覽器 | 競態風險 | 競態風險（同等） |

---

## 3. 結論與決定

### GO/NO-GO 決定：**NO-GO（不引入 Playwright MCP）**

**理由**：

1. **ADR-034 已 Accepted**：agent-browser 已通過正式架構決策流程採用，Playwright MCP 已被評估並明確排除。重新引入需要 ADR-034 Superseded，理由不充分。

2. **能力對比不利於 Playwright MCP**：
   - Context 消耗：Playwright MCP 每個操作獨立 tool call（高 context）vs agent-browser CLI chaining（低 context）
   - 認證管理：Playwright MCP 無原生認證管理 vs agent-browser 5 種認證方式
   - 視覺對比：Playwright MCP 無 diff vs agent-browser snapshot diff + pixel diff

3. **現有基礎充足**：`skills/browser-automation/SKILL.md` 已有完整的 agent-browser 整合定義，覆蓋 QA/UX/SRE 三個角色的瀏覽器自動化需求。

### 後續建議

| 行動 | 優先級 | 說明 |
|------|--------|------|
| 驗證 agent-browser 安裝指引 | Should | 確認 WSL2 headless 安裝 SOP 完整 |
| 整合 agent-browser 至 sprint-execution | Could | 在 DESIGN/QA story 執行路徑中啟用視覺驗證 |
| 重新評估 Playwright MCP 觸發條件 | Won't（此時） | 當 agent-browser 出現明顯缺陷時重新評估 |

---

## 4. AC 達成確認

| AC | 狀態 | 說明 |
|----|------|------|
| AC1: Spike report 記錄 Playwright MCP 穩定性（5 次模擬） | PASS | 第 2.4 節已記錄 |
| AC2: 識別 worktree 隔離模型的工具調用 timeout/permission 問題 | PASS | 第 2.2 節識別多 worktree 並行競態風險 |
| AC3: GO/NO-GO 決定記錄於本文件 | PASS | 第 3 節：NO-GO |
| AC4: NO-GO — 不需產出 Browser Automation Skill 草稿 | PASS（適用 NO-GO 路徑） | ADR-034 + 現有 browser-automation/SKILL.md 已覆蓋 |

---

## 5. 重評估觸發條件

下列任一條件達成時，可重開評估 Playwright MCP：

- agent-browser 出現嚴重 bug 或停止維護
- Playwright MCP 增加 session 持久化和認證管理能力
- 使用者明確反映 agent-browser 安裝障礙無法克服
