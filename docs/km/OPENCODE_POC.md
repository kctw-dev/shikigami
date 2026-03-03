# OpenCode POC 可行性調查報告

**調查日期**：2026-03-03
**執行者**：AI Agent（Developer Subagent，Claude Sonnet 4.6）
**Sprint**：Sprint 25
**Story**：US-45
**關聯 Issue**：[Issue #3 — 支援 OpenCode / Codex 平台安裝](../../issues/3)
**參考來源**：[US-17 多平台調查報告 — MULTI_PLATFORM_SURVEY.md](./MULTI_PLATFORM_SURVEY.md)（調查日期：2026-03-02）

> 注意：本報告的技術數據來自 MULTI_PLATFORM_SURVEY.md（2026-03-02），屬靜態文件分析而非實機測試。OpenCode 版本資訊（v1.0.190+）及相關 API 行為可能隨版本更新而改變，建議在 Go 決策後執行 POC 前確認最新版本文件。

---

## 1. 背景與調查目的

Shikigami 框架目前僅在 Claude Code 平台驗證過完整功能。Issue #3 請求支援 OpenCode 平台安裝，使外部使用者可在 OpenCode 環境中運行 Shikigami 完整工作流。

US-17（Sprint 16）已對三個候選平台（Cursor、OpenCode、Codex CLI）進行可行性調查，OpenCode 獲得最高評分（4/5）。本報告（US-45，Sprint 25）基於 US-17 調查結論，針對 OpenCode 進行更深入的 POC 驗證範圍分析，並作出正式的 Go / No-Go 決策。

---

## 2. US-17 結論摘要（引用）

來源：[MULTI_PLATFORM_SURVEY.md](./MULTI_PLATFORM_SURVEY.md) AC2 節（OpenCode 可行性分析）

| 評分維度 | US-17 評估結論 |
|----------|---------------|
| SKILL.md 相容性 | 高度相容。OpenCode 的 Skills 目錄結構（`.opencode/skills/*/SKILL.md`）與 Shikigami 幾乎一致；on-demand 載入機制對應 |
| Subagent 能力 | 原生 Task tool 支援，API 設計與 Claude Code 相似，移植成本低 |
| 權限充足性 | bash、file I/O、gh CLI 均可正常運作；per-agent 權限隔離支援 Shikigami 角色模型 |
| 生態系統成熟度 | 活躍開發，v1.0.190 已穩定，社群 skills 和 plugins 豐富 |
| Shikigami 遷移成本 | 低（主要為目錄設定，SKILL.md 格式相容，Task tool 類似）|
| **整體評分** | **4 / 5**（三個平台中最高）|

US-17 同時點出 OpenCode 的已知阻礙：模型行為差異、SessionStart hook 適配、Claude Code 特有 API 殘留、Task tool 參數格式差異。詳見 MULTI_PLATFORM_SURVEY.md §AC4(b)。

---

## 3. POC 驗證範圍定義

本 POC 屬靜態文件分析，驗證以下兩個核心機制的可行性：

### 3.1 SKILL.md 等效載入機制可行性

**驗證問題**：Shikigami 的 `skills/*/SKILL.md` 能否在 OpenCode 環境下以最小修改載入並正確執行？

**評估依據（來自 US-17）**：

- OpenCode v1.0.190+ 的 Skills 搜尋路徑包含 `.opencode/skills/*/SKILL.md` 及 git worktree 中的 `skills/*/SKILL.md`
- 載入方式與 Shikigami 相同（on-demand，agent 按需載入全文）
- 目錄結構適配方案：建立 `.opencode/` 目錄並以 symlink 指向現有 `skills/` 目錄，或直接複製目錄

**可行性評估**：

- 路徑適配：低成本（symlink 或目錄複製即可）
- 格式相容性：SKILL.md 格式無需修改（純 Markdown 文件，無專屬格式依賴）
- 已知風險：Shikigami SKILL.md 中若有引用 Claude Code 特有功能描述（如 `SessionStart` 觸發語言），需在移植時逐一審查並替換為 OpenCode 對應描述

**結論**：SKILL.md 等效載入機制在 OpenCode 上可行。

### 3.2 單一 Subagent 派遣機制可行性

**驗證問題**：Shikigami SKILL.md 中透過 Task tool 派遣 subagent 的呼叫模式，能否在 OpenCode 環境下以最小修改運作？

**評估依據（來自 US-17）**：

- OpenCode 內建 Task tool，可程式化派遣 subagent（與 Claude Code Task tool API 設計相似）
- 支援內建 subagent（General、Explore）及自訂 subagent
- 支援 `@mention` 手動呼叫，以及 `permission.task` glob pattern 權限控制
- per-agent 獨立權限設定，支援 Shikigami 的五角色隔離模型（PO / Architect / QA / Developer / SM）

**可行性評估**：

- Task tool API 對應：高度相似，移植成本低，但需對照 OpenCode 文件確認參數格式（`description`、`prompt` 等欄位命名是否與 Claude Code 一致）
- 角色定義移植：Shikigami 五個角色可映射為五個自訂 OpenCode subagent，設定成本低
- 已知風險：Task tool 參數格式差異（US-17 指出此項需實機確認）；SessionStart hook 在 OpenCode 的等效事件需確認

**結論**：單一 subagent 派遣機制在 OpenCode 上從設計層面可行，Task tool 參數差異為中低風險，需在實機 POC 階段確認。

---

## 4. 關鍵技術阻礙評估

| # | 阻礙項目 | 嚴重程度 | 說明 |
|---|----------|----------|------|
| B-1 | 模型行為差異 | 中 | OpenCode 為 model-agnostic，不同 LLM 對相同 SKILL.md prompt 的執行品質可能不一致；使用非 Claude 模型時 prompt engineering 可能需調優 |
| B-2 | SessionStart hook 適配 | 中 | Shikigami 依賴 Claude Code 的 `SessionStart` hook 觸發框架初始化；OpenCode 的 session 生命週期事件機制尚未在 US-17 調查中完整確認，需實機調查 |
| B-3 | Task tool 參數格式差異 | 低-中 | OpenCode Task tool 與 Claude Code Task tool 設計相似但非完全相同；參數欄位命名差異可能需逐一對應，但預計影響範圍有限 |
| B-4 | Claude Code 特有 API 殘留 | 低 | SKILL.md 中引用 Claude Code 特有功能的敘述需審查（預計影響少數說明性文字，不影響核心邏輯） |

**整體技術阻礙評級**：低至中（無根本性阻礙，所有阻礙均有明確的技術解法路徑）

---

## 5. Go / No-Go 決策

### 決策：**Go**

**決策理由**：

1. US-17 靜態分析顯示，OpenCode 在 SKILL.md 載入、Task tool subagent 派遣、bash/gh CLI 權限三個核心機制上均具備高相容性（評分 4/5，三個平台最高）
2. 識別到的四項技術阻礙（B-1 至 B-4）均為中低嚴重程度，無根本性架構衝突，每項均有明確的技術解法路徑
3. 遷移成本為「低」——主要工作為目錄設定、symlink 建立及少量 SKILL.md 審查，無需重寫核心邏輯
4. OpenCode 的開源性質與 model-agnostic 設計符合 Shikigami 擴展目標，能讓更廣泛的外部使用者（非 Claude Code 訂閱者）使用 Shikigami

**關鍵前提**：本 Go 決策基於靜態文件分析（US-17，2026-03-02）。正式實施前需執行實機 POC Sprint 以驗證 Task tool 參數格式及 SessionStart hook 等效性。

---

## 6. MVP 整合路徑（Go 情境）

以下為從 Go 決策到 MVP 上線所需的 Story 序列：

### Phase 1：環境適配（1 Sprint，估計 M / 2pt）

**Story A：OpenCode 目錄適配與 SKILL.md 載入驗證**

- 建立 `.opencode/` 目錄及 symlink 設定
- 建立 `AGENTS.md`（對應 `CLAUDE.md`，含框架說明）
- 實機驗證至少一個 SKILL.md（建議使用 `skills/sprint-planning/SKILL.md`）可在 OpenCode 載入並執行 Happy Path
- 審查並修正 SKILL.md 中 Claude Code 特有 API 殘留（B-4）
- DoD：`skills/sprint-planning/SKILL.md` 在 OpenCode 中完整執行 Sprint Planning Happy Path

### Phase 2：Subagent 角色移植（1 Sprint，估計 L / 3pt）

**Story B：OpenCode Subagent 角色定義與派遣驗證**

- 調查 OpenCode SessionStart hook 等效機制（B-2）
- 建立五個自訂 subagent 設定（PO / Architect / QA / Developer / SM）對應 Shikigami 角色模型
- 確認 Task tool 參數格式並修正差異（B-3）
- 實機驗證跨角色 subagent 派遣（至少一個含 subagent 派遣的 SKILL.md 完整執行）
- DoD：跨角色派遣在 OpenCode 中可重現，行為與 Claude Code 一致

### Phase 3：安裝流程整合（1 Sprint，估計 S / 1pt）

**Story C：OpenCode 平台安裝指南建立**

- 建立 `docs/INSTALL_OPENCODE.md`，涵蓋前置需求、目錄設定步驟、模型選擇建議（B-1 緩解）
- 更新主 README.md，新增 OpenCode 平台支援說明
- Issue #3 結案（關閉並連結安裝指南）
- DoD：外部使用者可依照安裝指南在 OpenCode 環境完成 Shikigami 安裝並走完一個 Sprint

---

## 7. 版本資訊與更新提醒

| 項目 | 調查時版本（2026-03-02）| 建議更新動作 |
|------|------------------------|-------------|
| OpenCode | v1.0.190+ | 執行實機 POC 前確認最新版本，檢查 Task tool API 變更日誌 |
| OpenCode Skills 文件 | https://opencode.ai/docs/skills/ | 確認 `.opencode/` 目錄掃描路徑是否有版本間差異 |
| OpenCode Agents 文件 | https://opencode.ai/docs/agents/ | 確認 SessionStart 等效 hook 的最新實作狀態 |

---

## 附錄：相關文件索引

- [US-17 調查報告（MULTI_PLATFORM_SURVEY.md）](./MULTI_PLATFORM_SURVEY.md) — 原始平台評分與技術分析
- [Issue #3 — 支援 OpenCode / Codex 平台安裝](../../issues/3)
- [OpenCode 官方 Skills 文件](https://opencode.ai/docs/skills/)
- [OpenCode 官方 Agents 文件](https://opencode.ai/docs/agents/)
- [OpenCode 官方 Permissions 文件](https://opencode.ai/docs/permissions/)

---

## Phase 1 完成記錄

**執行日期**：2026-03-03
**執行者**：AI Agent（Developer Subagent，Claude Sonnet 4.6）
**Sprint**：Sprint 26
**Story**：US-46

---

### (a) 目錄適配結果摘要

**執行內容**：

1. 建立 `.opencode/` 目錄於 repo 根目錄
2. 以 symlink 將 `.opencode/skills` 指向 `../skills`，使 OpenCode 搜尋路徑 `.opencode/skills/*/SKILL.md` 可解析現有所有 17 個 SKILL.md

**結構差異審查結論**：

| 審查項目 | Shikigami 現狀 | OpenCode 規範 | 差異 |
|---------|--------------|--------------|------|
| Skills 目錄路徑 | `skills/*/SKILL.md` | `.opencode/skills/*/SKILL.md` 或 `skills/*/SKILL.md` | 無差異（symlink 適配完成） |
| SKILL.md frontmatter | `name` + `description` 欄位 | `name` + `description` 欄位 | 無差異 |
| 文件格式 | 純 Markdown | 純 Markdown | 無差異 |
| 載入機制 | On-demand | On-demand | 無差異 |

**結論**：結構相容，symlink 適配已完成，無需修改現有 `skills/` 內容。

**新增產出**：
- `.opencode/skills` → `../skills`（symlink，git 追蹤）
- `AGENTS.md`（OpenCode 平台入口，類比 `CLAUDE.md`）

---

### (b) SKILL.md 相容性評估結果

**審查範圍**：`skills/sprint-planning/SKILL.md`（作為代表性 SKILL.md 進行靜態審查）

**格式相容性**：PASS — frontmatter 格式（`name`、`description`）、Markdown 結構、HARD-GATE 區塊均符合 OpenCode Skills 規範。

**Claude Code 特有 API 殘留項清單**：

| # | 行號 | 殘留項 | 類型 | 影響層級 | 修正方案 |
|---|------|--------|------|----------|---------|
| R-1 | 39 | `invoke shikigami:health-check` | 平台調用語法 | 說明性，不影響 OpenCode 運行 | Phase 2 時替換為 OpenCode skill invocation 語法 |
| R-2 | 41 | `invoke shikigami:issue-management Triage` | 平台調用語法 | 說明性，不影響 OpenCode 運行 | Phase 2 時替換為 OpenCode skill invocation 語法 |
| R-3 | 50 | `~/.claude/projects/` JSONL 路徑 | Claude Code 特有路徑 | 功能性殘留（慢想模式 Token 記錄） | OpenCode 中走降級路徑（填 N/A），Phase 2 調查 OpenCode session 資料路徑 |
| R-4 | 81 | `claude -p "/sprint-planning"` | Claude Code CLI 指令 | 說明性範例 | Phase 2 時補充 OpenCode 對應指令說明 |
| R-5 | 132 | `claude -p "/sprint-planning"` | Claude Code CLI 指令（程式碼區塊） | 說明性範例 | Phase 2 時補充 OpenCode 對應指令說明 |
| R-6 | 135 | `claude -p "/sprint-planning --deep"` | Claude Code CLI 指令（程式碼區塊） | 說明性範例 | Phase 2 時補充 OpenCode 對應指令說明 |
| R-7 | 181 | `invoke shikigami:health-check`（流程圖） | 平台調用語法 | 說明性，不影響 OpenCode 運行 | Phase 2 時替換為 OpenCode skill invocation 語法 |

**殘留項分類**：
- 說明性殘留（R-1、R-2、R-4、R-5、R-6、R-7）：6 項。這些是流程說明文字或 CLI 指令範例，不影響 OpenCode 的 SKILL.md 載入與執行。
- 功能性殘留（R-3）：1 項。`~/.claude/projects/` 路徑在 OpenCode 中不存在，但 SKILL.md 已內建降級機制（填 N/A），不會導致執行失敗。

**靜態相容性驗證結論**：`skills/sprint-planning/SKILL.md` 在 OpenCode 中可靜態載入，格式相容。所有功能性殘留均已有降級路徑。說明性殘留不影響運行，建議在 Phase 2 實機 POC 時一併更新。

---

### (c) AC4 動態驗證標注說明

本 Story（US-46）的驗證範圍為靜態相容性審查，不包含實機 OpenCode 執行驗證。

**標注**：完整 Happy Path 動態驗證（`skills/sprint-planning/SKILL.md` 在 OpenCode 中完整執行 Sprint Planning 流程）待 Phase 2 實機 POC Sprint 執行，不計入本 Story DoD。

**動態驗證的遺留阻礙**：

| 阻礙 | 說明 | 預計在 Phase |
|------|------|------------|
| Task tool 參數格式確認 | OpenCode Task tool 與 Claude Code 參數欄位命名差異尚未實機驗證 | Phase 2 |
| SessionStart hook 等效性 | OpenCode session 生命週期事件機制尚未調查 | Phase 2 |
| 實機 OpenCode 環境 | 本 Phase 1 執行者（Claude Code 環境）無法直接測試 OpenCode | Phase 2 |

---

### (d) 建議下一步

**建議行動**：補建 ADR-008（OpenCode 平台整合策略），並啟動 Phase 2 POC Sprint。

**ADR-008 草稿範圍建議**：
- 決策問題：Shikigami 是否正式採用 OpenCode 作為第二支援平台？
- 選項：(A) 完整整合（Phase 2 + Phase 3）、(B) 部分整合（僅 SKILL.md 載入，不支援 subagent 派遣）、(C) 暫停整合
- 評估依據：Phase 1 靜態驗證結果（本節）+ Phase 2 實機 POC 結果

**Phase 2 建議範圍**（Story B，L / 3pt）：
- 調查 OpenCode SessionStart hook 等效機制（B-2）
- 建立五個自訂 subagent 設定（PO / Architect / QA / Developer / SM）
- 確認 Task tool 參數格式並修正差異（B-3）
- 實機驗證 `skills/sprint-planning/SKILL.md` Happy Path
- 更新所有 SKILL.md 中的 Claude Code 特有 API 殘留（R-1 ~ R-7）
