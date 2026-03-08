# Gemini CLI 呼叫介面調查報告

**調查日期**：2026-03-08
**CLI 版本**：`@google/gemini-cli` v0.32.1（npm 最新穩定版，調查當日）
**調查者**：US-163 Story-Lifecycle subagent（Shikigami 框架）
**相關 Issue**：#159（多模型 CLI 路由，Phase 0）

---

## 目的

調查 Gemini CLI 的呼叫方式、輸出格式與 Prompt 限制，作為多模型路由機制（Phase 1+）的設計依據。

---

## 第一章：呼叫方式（Invocation Interface）

### 安裝方式

```bash
# 全域安裝（推薦，用於腳本整合）
npm install -g @google/gemini-cli

# 無安裝直接執行
npx @google/gemini-cli

# Homebrew（macOS）
brew install google-gemini/gemini-cli/gemini-cli
```

### 非互動式（Headless）呼叫

Gemini CLI 支援非互動模式（Headless Mode），這是多模型路由最關鍵的能力。觸發條件：

1. **位置引數（Positional Argument）**：直接在命令後附上 prompt

   ```bash
   gemini "請解釋這段程式碼的用途"
   ```

2. **`-p` / `--prompt` 旗標**：明確指定 prompt

   ```bash
   gemini -p "Summarize the main points"
   gemini --prompt "Summarize the main points"
   ```

3. **stdin 管道（Pipe）**：

   ```bash
   echo "Count to 10" | gemini
   cat error.log | gemini "Explain why this failed"
   git diff | gemini "Write a commit message for these changes"
   ```

4. **非 TTY 環境**：在非互動終端（如 CI/CD）中自動進入 Headless 模式。

### 常用旗標

| 旗標 | 說明 |
|------|------|
| `-p` / `--prompt` | 直接傳入 prompt（觸發 Headless 模式） |
| `-m` / `--model` | 指定模型（如 `gemini-2.5-pro`） |
| `--output-format` | 輸出格式（`text`、`json`、`stream-json`） |
| `-y` / `--yolo` | 自動核准所有 tool 操作 |
| `--approval-mode` | 設定 tool 操作的核准行為 |
| `-a` / `--all-files` | 將所有檔案納入 context |
| `--include-directories` | 加入特定目錄至 context |
| `-d` / `--debug` | 啟用 debug 模式 |

### 認證

Gemini CLI 需要 Google 帳號認證，首次使用時觸發 OAuth 流程。自動化環境可透過服務帳號或 API Key 設定認證。

### 結論

**明確結論**：Gemini CLI 支援完整的非互動式呼叫能力，包含位置引數、`-p` 旗標、stdin 管道三種方式，均可用於腳本自動化。行為類似 Claude CLI 的 `-p` 旗標（執行一次後退出），適合多模型路由整合。

---

## 第二章：輸出格式（Output Format）

### 格式選項

透過 `--output-format` 旗標指定，支援三種格式：

#### 1. `text`（預設）

純文字輸出，人類可讀，等同模型回應內容。適合直接閱讀場景。

```bash
gemini "What is 2+2?"
# stdout: 4
```

#### 2. `json`

回傳單一 JSON 物件，包含完整執行結果：

```json
{
  "response": "The model's final answer...",
  "stats": {
    "models": {
      "gemini-2.5-pro": {
        "inputTokens": 42,
        "outputTokens": 128,
        "apiRequests": 1
      }
    },
    "tools": { ... },
    "files": { ... }
  },
  "error": null
}
```

欄位說明：
- `response`：模型的最終回應文字
- `stats`：Token 用量、API 請求數、tool 執行統計、檔案操作統計
- `error`：若執行失敗則包含 `type`、`message`、`code`

#### 3. `stream-json`

串流式 JSONL（Newline-Delimited JSON），每行一個事件：

| 事件類型 | 說明 |
|---------|------|
| `init` | Session 初始化（含 session ID、模型名稱） |
| `message` | 使用者與模型訊息區塊（逐步串流） |
| `tool_use` | Tool 呼叫請求（含引數） |
| `tool_result` | Tool 執行結果 |
| `error` | 非致命警告或系統錯誤 |
| `result` | 最終結果與彙整統計 |

使用範例：

```bash
# JSON 輸出並用 jq 提取回應
gemini --output-format json "Return a summary" | jq -r '.response'

# 串流輸出至檔案
gemini --output-format stream-json --prompt "Analyze this code" > events.jsonl
```

### stdout / stderr 分離

已知問題（Issue #12267）：在非互動模式下，所有輸出（包含應用層訊息）均輸出至 stdout，而非理想的「模型輸出 → stdout，應用訊息 → stderr」分離行為。這是已知的 regression，尚未完全修復。

**對路由設計的影響**：若使用 `text` 格式，需謹慎處理可能混入 stdout 的非模型訊息。建議優先使用 `--output-format json`，透過解析 `response` 欄位取得乾淨的模型輸出。

### Exit Codes

| Exit Code | 意義 |
|-----------|------|
| `0` | 成功 |
| `1` | 一般錯誤或 API 失敗 |
| `42` | 輸入錯誤（無效 prompt 或引數） |
| `53` | Turn 次數限制超過 |

### 結論

**明確結論**：`--output-format json` 是多模型路由整合的最佳選擇，可提供結構化的 `response` 欄位供解析，並附帶 Token 用量統計。須透過 exit code 偵測執行失敗，並注意 stdout/stderr 混合的已知問題（建議搭配 json 格式規避）。

---

## 第三章：Prompt 限制（Prompt Constraints）

### Token 限制

Gemini CLI 預設使用 **Gemini 2.5 Pro**，其 Token 限制如下：

| 限制類型 | 數值 |
|---------|------|
| Context Window（輸入上限） | 1,000,000 tokens（約 750 萬字元、150 萬行程式碼） |
| 輸出 Token 上限 | 64,000 tokens（Gemini 2.5 Pro） |
| Flash 模型輸出上限 | 8,000 ~ 32,000 tokens |

免費帳號（Personal Google Account）的 API 呼叫配額：
- 每分鐘：60 requests
- 每日：1,000 requests

### System Prompt 機制

Gemini CLI 支援透過環境變數 `GEMINI_SYSTEM_MD` 指定外部 Markdown 檔作為 System Prompt：

```bash
export GEMINI_SYSTEM_MD="/path/to/SYSTEM.md"
gemini -p "your prompt here"
```

此設定為**完全替換**（full replacement），不是與預設 System Prompt 合併。

另有 `GEMINI.md`（專案層級）可提供高層次指引，與 `SYSTEM.md`（安全與 tool 操作）分層管理。

### Prompt 傳遞限制

- **CLI 引數長度**：受作業系統 ARG_MAX 限制（Linux 通常為 2MB），超長 prompt 建議改用 stdin 管道
- **多行 prompt**：透過引號或 stdin 傳遞多行內容
- **已知問題**：超長且包含多位元組字元（如中文、日文）的 prompt 在自動換行情況下可能觸發輸入忽略的 bug（Issue #6619）。建議使用 stdin 管道傳遞長 prompt

### 待確認項目

- **待確認（原因：需實測）**：`-p` 旗標的 prompt 字元數上限——目前文件未明確記載 CLI 層的字元限制，實際上限取決於 OS ARG_MAX，建議長 prompt 一律改用 stdin
- **待確認（原因：版本差異）**：付費帳號（Gemini Advanced）的 API 配額數值，官方文件各版本數字不一致

### 結論

**部分明確結論**：Gemini CLI 底層使用 Gemini 2.5 Pro 提供 1M token context window，遠超一般路由場景需求。主要需注意的是：(1) 免費配額每日 1,000 次限制、(2) 長 prompt 應透過 stdin 傳遞以避免 OS 引數限制與多位元組字元 bug、(3) System Prompt 可透過外部 Markdown 檔客製化。

---

## 設計建議（供 Phase 1 路由設計參考）

基於本次調查，多模型路由整合 Gemini CLI 的建議方式：

```bash
# 建議的呼叫模式（最穩定）
echo "${PROMPT}" | gemini --output-format json --model gemini-2.5-pro | jq -r '.response'

# 或使用 -p 旗標（短 prompt）
gemini --output-format json -p "${SHORT_PROMPT}" | jq -r '.response'
```

關鍵設計考量：
1. **使用 `--output-format json`**：避免 stdout/stderr 混合問題，取得乾淨的 `response` 欄位
2. **使用 stdin 管道傳遞長 prompt**：避免 OS ARG_MAX 與多位元組字元問題
3. **監控 exit code**：以 `0/1/42/53` 判斷執行狀態
4. **注意每日配額**：免費帳號 1,000 次/日，需在路由邏輯中加入配額感知

---

## 參考來源

- [Google Gemini CLI GitHub 倉庫](https://github.com/google-gemini/gemini-cli)
- [Headless Mode 官方文件](https://google-gemini.github.io/gemini-cli/docs/cli/headless.html)
- [Headless Mode 參考（geminicli.com）](https://geminicli.com/docs/cli/headless/)
- [自動化 Headless 教學](https://geminicli.com/docs/cli/tutorials/automation/)
- [@google/gemini-cli npm 頁面](https://www.npmjs.com/package/@google/gemini-cli)
- [Gemini CLI System Prompt 文件](https://geminicli.com/docs/cli/system-prompt/)
- [Issue #12267: Non-interactive mode 輸出至 stdout](https://github.com/google-gemini/gemini-cli/issues/12267)
- [Issue #4665: Suppress non-LLM output to stdout](https://github.com/google-gemini/gemini-cli/issues/4665)
- [Issue #6619: 長多位元組字元 prompt 問題](https://github.com/google-gemini/gemini-cli/issues/6619)
- [Issue #1508: Non-interactive 模式功能請求](https://github.com/google-gemini/gemini-cli/issues/1508)
- [Gemini CLI Cheatsheet](https://www.philschmid.de/gemini-cli-cheatsheet)
- [Gemini 3 Pro Token Limits Guide](https://www.glbgpt.com/hub/gemini-3-pro-limits-the-ultimate-guide-to-quotas-tokens-hidden-caps-2025/)
