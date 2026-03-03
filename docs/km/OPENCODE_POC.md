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

## 8. Phase 1 完成記錄（US-46 執行結果）

**執行日期**：2026-03-03
**執行者**：AI Agent（Developer Subagent，Claude Sonnet 4.6）
**Sprint**：Sprint 26
**Story**：US-46

---

### 8.1 目錄適配結果摘要

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

### 8.2 SKILL.md 相容性評估結果

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

### 8.3 AC4 動態驗證標注說明

本 Story（US-46）的驗證範圍為靜態相容性審查，不包含實機 OpenCode 執行驗證。

**標注**：完整 Happy Path 動態驗證（`skills/sprint-planning/SKILL.md` 在 OpenCode 中完整執行 Sprint Planning 流程）待 Phase 2 實機 POC Sprint 執行，不計入本 Story DoD。

**動態驗證的遺留阻礙**：

| 阻礙 | 說明 | 預計在 Phase |
|------|------|------------|
| Task tool 參數格式確認 | OpenCode Task tool 與 Claude Code 參數欄位命名差異尚未實機驗證 | Phase 2 |
| SessionStart hook 等效性 | OpenCode session 生命週期事件機制尚未調查 | Phase 2 |
| 實機 OpenCode 環境 | 本 Phase 1 執行者（Claude Code 環境）無法直接測試 OpenCode | Phase 2 |

---

### 8.4 建議下一步

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

---

## 9. Phase 2 完成記錄（US-48 執行結果）

**執行日期**：2026-03-03
**執行者**：AI Agent（Developer Subagent，Claude Sonnet 4.6）
**Sprint**：Sprint 27
**Story**：US-48
**依賴**：US-47（ADR-008 Accepted，2026-03-03）

---

### 9.1 Subagent 設定檔審查結果（AC1）

**審查對象**：`skills/sprint-execution/` 下的現有 subagent prompt 檔案

| 現有檔案 | 對應角色 | 發現差異 |
|---------|---------|---------|
| `developer-prompt.md` | Developer | 無 YAML frontmatter；路徑不符 ADR-008 規範 |
| `spec-reviewer-prompt.md` | QA Engineer（Spec Compliance 子角色） | 無 YAML frontmatter；路徑不符 ADR-008 規範 |
| `quality-reviewer-prompt.md` | QA Engineer（Code Quality 子角色） | 無 YAML frontmatter；路徑不符 ADR-008 規範 |
| `story-lifecycle-prompt.md` | 複合角色（封裝 Developer + Reviewer）| 無 YAML frontmatter；ADR-008 五角色模型中無直接對應 |

**相容性差異清單（OpenCode ADR-008 格式 vs. 現有檔案）**：

| 差異維度 | ADR-008 規範 | 現有檔案現狀 | 差異等級 |
|---------|-------------|------------|---------|
| 設定檔路徑 | `.opencode/agents/<role>.md` | `skills/sprint-execution/*-prompt.md` | 必須修正 |
| 檔案格式 | YAML frontmatter（`name` + `description`）+ Markdown 正文 | 純 Markdown，無 frontmatter | 必須修正 |
| 檔案命名 | `developer.md`, `architect.md`, `qa-engineer.md`, `product-owner.md`, `scrum-master.md` | `developer-prompt.md`, `spec-reviewer-prompt.md` 等 | 必須修正 |
| 角色對應 | 五角色：PO / Architect / QA / Developer / SM | 四個 prompt 檔，其中兩個為 QA 子角色，一個為複合角色 | 需整合規劃 |
| Markdown 正文內容 | 角色 system prompt 說明（可直接移植） | 完整角色 prompt 說明（格式相容） | 無差異（可直接移植） |

**審查結論**：現有 prompt 檔案的 **Markdown 正文內容** 可直接移植至 OpenCode subagent 格式，主要工作為：(1) 建立 `.opencode/agents/` 目錄；(2) 新增 YAML frontmatter；(3) 依 ADR-008 角色命名規範重新命名。Phase 2（US-48）僅移植 Developer 角色作為首個驗證案例。

---

### 9.2 Developer 角色移植結果（AC2）

**來源檔案**：`skills/sprint-execution/developer-prompt.md`
**目標檔案**：`.opencode/agents/developer.md`（已建立）

**移植內容摘要**：

| 欄位 | 值 |
|------|---|
| `name` | `developer` |
| `description` | `Senior full-stack developer implementing User Stories with TDD discipline, conflict detection, and tech debt management` |
| 正文來源 | `skills/sprint-execution/developer-prompt.md` 完整內容 |

**移植差異清單**：

| 項目 | 來源（Claude Code 格式）| 目標（OpenCode 格式）| 處置方式 |
|------|----------------------|---------------------|---------|
| 檔案路徑 | `skills/sprint-execution/developer-prompt.md` | `.opencode/agents/developer.md` | 新建（不刪除原檔） |
| YAML frontmatter | 無 | 新增 `name` + `description` | 新增 |
| 正文內容 | 原有 Markdown | 原封不動移植 | 完整保留 |
| 角色 system prompt | Claude Code subagent 派遣格式 | OpenCode subagent 格式（frontmatter 包裝）| 格式轉換 |

**關係說明**：`skills/sprint-execution/developer-prompt.md` 保持不變（Claude Code 平台繼續使用），`.opencode/agents/developer.md` 作為 OpenCode 平台的獨立設定檔。兩者內容相同，僅格式包裝不同。

---

### 9.3 殘留項修正記錄（AC3）

**修正範圍**：`skills/sprint-planning/SKILL.md`（Phase 1 識別的 R-1~R-7 全部位於此檔案）

**修正方式**：雙平台標注（dual-platform annotation）—— 保留原 Claude Code 語法並以 HTML 注釋格式補充 OpenCode 對應說明：

```
<!-- Claude Code -->
<原 Claude Code 語法>
<!-- OpenCode -->
<OpenCode 等效說明>
<!-- /OpenCode -->
```

**各殘留項修正記錄**：

| 殘留項 | 類型 | 位置（修正後行號）| 修正方式 | OpenCode 等效說明 |
|--------|------|----------------|---------|----------------|
| R-1 | 平台調用語法（health-check）| 行 39 | 雙平台標注 | `使用 health-check skill` |
| R-2 | 平台調用語法（issue-management）| 行 41 | 雙平台標注 | `使用 issue-management skill 並傳入 Triage 任務` |
| R-3 | Claude Code 特有路徑 | 行 50 | 雙平台標注 | `OpenCode session 資料路徑待 Phase 2 實機調查確認；暫時填「N/A」` |
| R-4 | Claude Code CLI 指令 | 行 81 | 雙平台標注 | `` `opencode sprint-planning`（待實機確認）`` |
| R-5 | Claude Code CLI 指令（程式碼區塊）| 行 132-133 | 雙平台標注（區塊）| `opencode sprint-planning` |
| R-6 | Claude Code CLI 指令（程式碼區塊）| 行 135-136 | 雙平台標注（區塊）| `opencode sprint-planning --deep` |
| R-7 | 平台調用語法（流程圖）| 行 192 | 雙平台標注 | `使用 health-check skill` |

**不可接受的處置方式確認**：所有殘留項均保留原 Claude Code 語法（符合 ADR-008 「不允許在不提供替代說明的情況下直接刪除 Claude Code 語法」規範）。

**修正結論**：R-1~R-7 全部 7 項殘留項已完成雙平台標注修正。Claude Code 平台使用者讀取 SKILL.md 時體驗不受影響（HTML 注釋在渲染時隱藏）；OpenCode 平台使用者可在原始碼層面查看等效說明。

---

### 9.4 AC4 靜態驗證結果

**驗證對象**：`.opencode/agents/developer.md`

**驗證項目**：

| 驗證項目 | 規範要求（ADR-008 決策三）| 實際狀態 | 結果 |
|---------|-------------------------|---------|------|
| 設定檔路徑 | `.opencode/agents/developer.md` | `.opencode/agents/developer.md` | PASS |
| YAML frontmatter 存在 | 必填 `name` + `description` | 已存在，兩欄位均填入 | PASS |
| `name` 欄位格式 | 角色英文名稱 | `developer` | PASS |
| `description` 欄位格式 | 角色職責一句話說明 | `Senior full-stack developer implementing...` | PASS |
| Markdown 正文 | 角色 system prompt 正文 | 完整 Developer 角色 prompt | PASS |
| 路徑一致性 | ADR-008 §決策一目錄結構 | `.opencode/agents/developer.md` 符合定義 | PASS |

**靜態驗證結論**：`.opencode/agents/developer.md` 符合 OpenCode subagent 設定規範的所有靜態驗證項目（格式、必填欄位、路徑一致性）。

**格式規範相容性確認**：YAML frontmatter（`name` + `description`）格式基於 OpenCode 官方 Agents 文件定義，靜態審查確認無明顯格式衝突。

**[動態驗證標注]**：完整 Happy Path 動態驗證（Task tool 派遣 `.opencode/agents/developer.md` 作為 subagent system prompt，執行端對端流程）待實機 POC Sprint 執行。本 Story（US-48）不計入 DoD。待確認項目包含：Task tool 參數欄位命名（`description`、`prompt` 等）、subagent 派遣實際行為與 Claude Code 的差異。

---

### 9.5 建議下一步（Phase 3 範圍）

**Phase 2 完成狀態**：

| 項目 | 狀態 |
|------|------|
| ADR-008 架構決策 | 完成（Accepted） |
| Developer 角色 prompt 移植 | 完成（`.opencode/agents/developer.md`） |
| R-1~R-7 殘留項修正 | 完成（雙平台標注） |
| 靜態格式驗證 | PASS |
| 動態派遣驗證 | 待實機 POC |

**Phase 3 建議範圍**（`docs/INSTALL_OPENCODE.md` + 剩餘角色移植）：

1. **完成剩餘四個角色移植**：依 ADR-008 決策一，補建 `.opencode/agents/architect.md`、`.opencode/agents/qa-engineer.md`、`.opencode/agents/product-owner.md`、`.opencode/agents/scrum-master.md`
2. **建立 OpenCode 安裝指南**：`docs/INSTALL_OPENCODE.md`，涵蓋前置需求（OpenCode 版本、模型選擇建議）、目錄設定步驟（symlink 建立說明）、模型選擇建議（緩解 B-1 模型行為差異風險）
3. **更新 README.md**：新增 OpenCode 平台支援說明，標注 Phase 2 完成狀態
4. **實機動態驗證**（待 Phase 3 實機環境）：對照 OpenCode 文件確認 Task tool 參數欄位命名（`description`、`prompt` 等）；在實機 OpenCode 環境中驗證 Developer subagent 派遣 Happy Path；確認 SessionStart hook 等效機制（B-2）
5. **Issue #3 結案**：完成 Phase 3 後關閉 Issue #3，連結安裝指南

**Phase 3 預估**：S / 1pt（安裝指南建立）+ M / 2pt（剩餘角色移植 + 實機驗證）

---

## 10. Phase 3a 完成記錄（US-49 執行結果）

**執行日期**：2026-03-03
**執行者**：AI Agent（Developer Subagent，Claude Sonnet 4.6）
**Sprint**：Sprint 28
**Story**：US-49

---

### 10.1 四角色移植稽核結果（AC1-AC3）

**移植範圍**：剩餘四個核心角色（Phase 2 US-48 僅移植 Developer，Phase 3a 補全其餘四角色）

| 設定檔 | 角色 | 內容來源 | 狀態 |
|--------|------|---------|------|
| `.opencode/agents/architect.md` | Architect | `skills/architect/SKILL.md`（§1 估點策略、§2 ADR 需求判斷、§3 平行分群策略）| 完成 |
| `.opencode/agents/product-owner.md` | Product Owner | `skills/sprint-planning/SKILL.md`（§6 Subagent 派遣順序 PO 段落、§4 Sprint 週期、§3 Hard Gate）| 完成 |
| `.opencode/agents/qa-engineer.md` | QA Engineer | `skills/qa-engineer/SKILL.md`（§1 AC 驗證策略、§2 Spec Compliance、§3 Code Quality）+ `skills/sprint-execution/spec-reviewer-prompt.md` + `skills/sprint-execution/quality-reviewer-prompt.md` | 完成 |
| `.opencode/agents/security-engineer.md` | Security Engineer | `skills/security-review/SKILL.md`（§2 OWASP Top 10、§3 DevSecOps、§4 Secrets Management、§6 升級觸發、§7 安全品質門禁）| 完成 |

---

### 10.2 格式規範符合性驗證

所有四個設定檔均符合 ADR-008 決策三的格式規範：

| 驗證項目 | 規範要求 | 實際狀態 | 結果 |
|---------|---------|---------|------|
| 設定檔路徑 | `.opencode/agents/<role>.md` | 四個檔案均位於 `.opencode/agents/` | PASS |
| YAML frontmatter 存在 | 必填 `name` + `description` + `model` | 三欄位均填入 | PASS |
| `name` 欄位格式 | 角色英文名稱（kebab-case）| `architect` / `product-owner` / `qa-engineer` / `security-engineer` | PASS |
| `description` 欄位 | 角色職責一句話說明 | 各角色均有具體職責描述 | PASS |
| `model` 欄位 | 模型指定 | 均設為 `sonnet` | PASS |
| Markdown 正文 | 角色 system prompt 正文 | 各角色均有完整 prompt，含角色定義、職責、限制、參照文件 | PASS |

---

### 10.3 內容來源一致性確認（AC3）

**Architect**：
- 估點策略（S/M/L 邊界條件）直接提取自 `skills/architect/SKILL.md §1`
- ADR 觸發判斷規則提取自 `skills/architect/SKILL.md §2`
- 平行分群策略提取自 `skills/architect/SKILL.md §3`

**Product Owner**：
- PO 角色無獨立 `SKILL.md`，內容來源自 `skills/sprint-planning/SKILL.md §6`（Subagent 派遣順序中 PO 段落）
- Round 1/Round 2 流程、防漂移約束、Backlog 管理規則均有對應來源
- Scheduled Mode HARD-GATE 規則提取自 `skills/sprint-planning/SKILL.md §3.1`

**QA Engineer**：
- AC 驗證策略（靜態/動態識別）提取自 `skills/qa-engineer/SKILL.md §1`
- Spec Compliance Review 決策提取自 `skills/qa-engineer/SKILL.md §2`
- Code Quality Review 策略提取自 `skills/qa-engineer/SKILL.md §3`
- `spec-reviewer-prompt.md` 與 `quality-reviewer-prompt.md` 作為補充參照，核心內容已整合至設定檔

**Security Engineer**：
- OWASP Top 10 檢查清單提取自 `skills/security-review/SKILL.md §2`
- 輸入驗證審查提取自 `skills/security-review/SKILL.md §5`（步驟 3）
- Secrets Management 提取自 `skills/security-review/SKILL.md §4`
- 安全品質門禁（HARD-GATE）提取自 `skills/security-review/SKILL.md §7`

---

### 10.4 Scrum Master 角色說明

依 Sprint 28 AC1 規範，Scrum Master 為主 session 編排者（非被派遣 subagent），不需建立 agent 設定檔。五角色模型中的 SM 角色由主 session（AGENTS.md 入口）直接承擔，透過 Task tool 按需派遣其他四個角色。

---

### 10.5 Phase 3a 完成狀態

| 項目 | 狀態 |
|------|------|
| 四個 agent 設定檔建立 | 完成（architect / product-owner / qa-engineer / security-engineer） |
| YAML frontmatter 格式符合 ADR-008 | PASS |
| 內容來源可追溯至 SKILL.md | PASS |
| AGENTS.md 更新（列出全部 5 個 agent）| 完成 |
| 動態派遣驗證 | 待實機 POC（US-51 Phase 3c 範疇）|

---

## 11. Phase 3b 完成記錄（US-50 執行結果）

**執行日期**：2026-03-03
**執行者**：AI Agent（Developer Subagent，Claude Sonnet 4.6）
**Sprint**：Sprint 28
**Story**：US-50

---

### 11.1 安裝指南建立結果（AC1/AC2）

**產出檔案**：`docs/INSTALL_OPENCODE.md`

**文件結構**：

| 章節 | 內容摘要 |
|------|---------|
| §1 前置需求 | OpenCode 版本要求、git 設定、gh CLI（選用）、Windows symlink 設定 |
| §2 目錄結構設定（Symlink 適配）| ADR-008 決策一引用、symlink 確認/建立步驟、OpenCode Skills 發現驗證 |
| §3 Agent 設定檔說明 | 五角色設定檔一覽、格式說明、Task tool 派遣方式說明 |
| §4 首次 Sprint 快速上手 | 專案初始化、Sprint Planning、Sprint Execution、Sprint Review 流程說明 |
| §5 模型選擇建議 | 推薦 Claude Sonnet / Claude Opus（prompt 相容性最佳） |
| §6 Troubleshooting | 5 個常見問題：Skills 發現失敗、subagent 派遣失敗、`claude -p` 語法殘留、`~/.claude/projects/` 路徑差異、Scrum Master 意圖辨識問題 |

**ADR-008 引用確認**：`docs/INSTALL_OPENCODE.md §2` 明確引用 ADR-008 決策一，包含完整的目錄結構定義圖，說明 symlink 適配策略為唯一正式支援的目錄整合方式。

---

### 11.2 README.md 更新結果（AC3）

**修改檔案**：`README.md`

**新增章節**：「OpenCode 平台支援」（位於「快速開始」與「文件導覽」之間）

**章節內容**：
- 簡要說明 OpenCode 雙平台支援策略
- 引用 ADR-008 決策一（symlink 適配）
- 連結至 `docs/INSTALL_OPENCODE.md`
- 列出安裝指南六個主要段落的摘要

---

### 11.3 Phase 3b 完成狀態

| 項目 | 狀態 |
|------|------|
| `docs/INSTALL_OPENCODE.md` 建立 | 完成（6 個章節，423 行） |
| ADR-008 決策一引用 | 完成（§2 明確引用，含目錄結構定義） |
| README.md OpenCode 章節新增 | 完成（連結至安裝指南） |
| OPENCODE_POC.md Phase 3b 子章節 | 完成（本節） |
