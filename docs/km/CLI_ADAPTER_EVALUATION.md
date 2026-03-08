# CLI Adapter 開源替代方案評估報告

- **Story**: US-169
- **Issue**: #167
- **日期**: 2026-03-08
- **評估人**: Developer (Story-Lifecycle subagent)

---

## 背景

Sprint 62 完成了 `scripts/cli-adapter.sh`（132 行 Bash），提供統一的 CLI adapter 呼叫入口，支援 Claude/Gemini 切換與自動 fallback。本報告評估是否有開源替代方案可取代或補充自建 adapter。

### 自建 Adapter 核心功能清單

| 功能 | 實作方式 |
|------|---------|
| 多 provider 切換（Claude / Gemini） | 環境變數 `SHIKIGAMI_MODEL_PROVIDER` 或函式引數 |
| stdin pipe prompt | `cat long-prompt.txt \| invoke_cli_adapter "" ""` |
| stdout 回應 | 純文字，自動從 Gemini JSON 提取 `.response` |
| Gemini 失敗自動 fallback 至 Claude | exit code 監控 + 重試邏輯 |
| 無外部依賴（jq 為選配） | 純 Bash，jq 不可用時降級輸出原始 JSON |
| Bash-native（source 後呼叫） | `source scripts/cli-adapter.sh` |
| 測試覆蓋 | 16 項測試全綠 |

---

## 候選專案

### 1. yuekai/llm-cli（LLxprt Code）

- **GitHub**: <https://github.com/yuekai/llm-cli>
- **語言**: TypeScript（Node.js）
- **Stars**: 極少（<100，fork 性質）
- **最近 commit**: 活躍（1,923 commits on main）
- **授權**: Apache-2.0
- **簡介**: Google Gemini CLI 的多 provider fork，支援 OpenAI、Anthropic Claude、Google Gemini、OpenRouter、本地模型

### 2. JaimeCernuda/a2a-cli-llm

- **GitHub**: <https://github.com/JaimeCernuda/a2a-cli-llm>
- **語言**: Python（99.9%）
- **Stars**: 4
- **最近 commit**: 2024-12-27（12 commits 總計）
- **授權**: MIT
- **簡介**: A2A (Agent-to-Agent) CLI 框架，支援 Ollama / Gemini / Claude + 自動 failover，使用 REST API 互動

### 3. sigoden/aichat

- **GitHub**: <https://github.com/sigoden/aichat>
- **語言**: Rust
- **Stars**: ~9,500
- **最近 commit**: 2024-12-05（活躍開發）
- **授權**: MIT / Apache-2.0 dual
- **簡介**: All-in-one LLM CLI，20+ provider 統一介面，支援 RAG、Function Calling、Shell Assistant、REPL 模式

### 4. musistudio/claude-code-router

- **GitHub**: <https://github.com/musistudio/claude-code-router>
- **語言**: TypeScript
- **Stars**: ~29,200
- **最近 commit**: 2025-01-04（活躍）
- **授權**: 未明確標示
- **簡介**: Claude Code 的 model router proxy，攔截 Claude Code 請求並路由至 OpenRouter / DeepSeek / Ollama / Gemini 等 provider

---

## 四維度評估

### 維度一：功能覆蓋

評估各方案是否涵蓋自建 adapter 的核心功能需求。

| 功能需求 | cli-adapter.sh | yuekai/llm-cli | a2a-cli-llm | sigoden/aichat | claude-code-router |
|---------|:---:|:---:|:---:|:---:|:---:|
| stdin pipe prompt | ✅ | ✅（互動模式） | ❌（REST API） | ✅ | ❌（proxy 模式） |
| stdout 純文字回應 | ✅ | 部分（格式化輸出） | ❌ | ✅ | ❌ |
| 環境變數切換 provider | ✅ | 部分（session 指令） | ✅（YAML config） | ✅（YAML config） | ✅（config.json） |
| Gemini fallback to Claude | ✅ | ❌ | ✅（failover 架構） | ❌（需手動配置） | ❌ |
| 純 Bash-native（source） | ✅ | ❌（Node.js 依賴） | ❌（Python 依賴） | ❌（Rust binary） | ❌（Node.js + proxy） |
| 零額外依賴 | ✅ | ❌ | ❌ | ❌（需安裝 binary） | ❌ |
| 現有 Shikigami Bash 腳本整合 | ✅ | 困難 | 困難 | 中等 | 困難 |

**小結**：無任何候選方案能完整覆蓋自建 adapter 的所有功能需求，特別是「純 Bash-native」與「stdin/stdout 對應關係」。

### 維度二：維護活躍度

| 專案 | Stars | Commits | 最近活動 | 評估 |
|------|------:|-------:|---------|------|
| yuekai/llm-cli | <100 | 1,923 | 活躍（fork 跟進 upstream） | 中 — fork 依賴 upstream 穩定性 |
| a2a-cli-llm | 4 | 12 | 2024-12-27 停滯 | 低 — 幾乎無社群，風險高 |
| sigoden/aichat | ~9,500 | 989 | 2024-12 活躍 | 高 — 社群成熟，穩定維護 |
| claude-code-router | ~29,200 | 不明 | 2025-01-04 | 高 — 大量 star，活躍開發 |

**小結**：`sigoden/aichat` 與 `claude-code-router` 維護活躍度最高，但兩者定位與 Shikigami 需求差距較大。`a2a-cli-llm` 幾乎無維護風險。

### 維度三：整合難度

| 專案 | 整合方式 | 難度 | 主要障礙 |
|------|---------|:---:|---------|
| yuekai/llm-cli | 替換 `claude`/`gemini` CLI 呼叫 | 高 | TypeScript runtime 依賴；需 npm 安裝；不支援 stdin pipe 直接路由；互動模式優先設計 |
| a2a-cli-llm | 替換呼叫層 | 極高 | Python 依賴；REST API 架構與 Bash pipe 完全不符；需啟動常駐 server |
| sigoden/aichat | 用 `aichat` 指令替換 `claude`/`gemini` | 中 | 需安裝 Rust binary；config YAML 管理；輸出格式可能需解析；測試需重寫 |
| claude-code-router | 替換 Claude Code 底層 | 極高 | proxy 架構需常駐 HTTP server；與自建 adapter 的 Bash-native 設計完全衝突；整合成本遠超自建 |

**小結**：`sigoden/aichat` 整合難度最低，但仍需引入 Rust binary 依賴與重寫測試套件（16 項測試）。其餘三者整合難度過高，不符合 Shikigami 輕量化方向。

### 維度四：Shikigami 適配性

Shikigami 框架核心要求：

- **輕量化**：不引入重依賴（No Node.js / Python / Rust runtime）
- **Bash-native**：腳本 `source` 後直接使用，無需外部 binary
- **可測試性**：函式級 mock，16 項測試快速執行
- **CI/CD 友善**：無需 server 常駐，無需 API key 設定（使用既有 Claude/Gemini CLI）
- **stdin/stdout pipe**：符合 Unix 哲學，與現有 Shikigami 腳本無縫整合

| 專案 | 輕量化 | Bash-native | 可測試性 | CI/CD 友善 | stdin/stdout | 總適配性 |
|------|:---:|:---:|:---:|:---:|:---:|:---:|
| yuekai/llm-cli | ❌ | ❌ | 中 | 中 | 部分 | **低** |
| a2a-cli-llm | ❌ | ❌ | ❌ | ❌（需 server） | ❌ | **極低** |
| sigoden/aichat | ❌（Rust binary） | ❌ | 中 | 中 | ✅ | **低** |
| claude-code-router | ❌ | ❌ | ❌ | ❌（需 HTTP proxy） | ❌ | **極低** |

---

## 決策建議

### 結論：**維持自建（Maintain）**

**不採用任何候選開源方案**，維持 `scripts/cli-adapter.sh` 自建 adapter。

### 理由

1. **功能契合度不足**：四個候選方案均無法在不大幅改寫的情況下滿足 Shikigami 的 Bash-native + stdin/stdout pipe + 零依賴需求。`sigoden/aichat` 最接近，但仍需引入 Rust runtime 並重寫全部測試。

2. **整合成本超過自建成本**：自建 adapter 僅 132 行 Bash，已有 16 項測試保護，維護成本極低。採用任何開源方案的整合成本（環境設定、依賴管理、測試重寫、文件更新）遠超自建維護成本。

3. **輕量化原則**：Shikigami 框架方向明確為輕量化（2026-03-08 決策），引入 Node.js / Python / Rust binary 違背此原則。

4. **維護風險**：`a2a-cli-llm`（4 stars）與 `yuekai/llm-cli`（fork 依賴 upstream）維護活躍度低。即使 `sigoden/aichat`（9.5k stars）與 `claude-code-router`（29k stars）活躍，但其設計目標與 Shikigami 需求錯位，upstream 變更可能導致整合破裂。

5. **自建 adapter 已足夠**：132 行 Bash 覆蓋了所有核心需求，無 over-engineering。YAGNI 原則：不應引入目前不需要的複雜性。

### 各候選方案個別說明

| 方案 | 決策 | 原因 |
|------|------|------|
| yuekai/llm-cli | **不採用** | TypeScript 依賴；設計為互動式 coding agent，非 pipe-friendly CLI；stars 極少 |
| a2a-cli-llm | **不採用** | Python + REST API server 架構；4 stars 無社群；與 Bash-native 需求完全衝突 |
| sigoden/aichat | **不採用（但列為觀察名單）** | 功能最接近需求；若未來需要擴展至 20+ provider 可重新評估；目前引入 Rust binary 不符合輕量化原則 |
| claude-code-router | **不採用** | HTTP proxy 架構；29k stars 但定位是 Claude Code model routing，非通用 CLI adapter |

### 未來重新評估觸發條件

以下條件發生時，建議重新評估 `sigoden/aichat` 作為替代方案：

- Shikigami 需要支援 5 個以上的 LLM provider
- Bash 自建 adapter 維護成本顯著上升（超過 500 行）
- 專案決定接受 Rust binary 作為可接受依賴

---

## 參考資料

- [yuekai/llm-cli](https://github.com/yuekai/llm-cli) — LLxprt Code，multi-provider fork of gemini-cli
- [JaimeCernuda/a2a-cli-llm](https://github.com/JaimeCernuda/a2a-cli-llm) — A2A CLI with Ollama/Gemini/Claude failover
- [sigoden/aichat](https://github.com/sigoden/aichat) — All-in-one LLM CLI，20+ provider，Rust
- [musistudio/claude-code-router](https://github.com/musistudio/claude-code-router) — Claude Code model router proxy
- `scripts/cli-adapter.sh` — 自建 adapter，132 行 Bash，16 項測試
- `docs/km/GEMINI_CLI_INVESTIGATION.md` — Gemini CLI 調查報告（Sprint 62 基礎資料）
