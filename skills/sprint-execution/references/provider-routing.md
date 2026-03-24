# §0 Provider 路由（Developer 派遣前置決策）

<!-- SSOT：story-lifecycle-prompt.md §0 已移至此處（Sprint 127 #485 模組化拆分） -->
<!-- 主 session 派遣 Developer subagent 前，讀取本文件決定派遣路徑 -->

主 session 在派遣本 subagent 前，依以下步驟決定派遣路徑：

## 步驟 1：解析環境變數

```
ROLE = "developer"

# 步驟 1a：查詢角色層級對照表
MAP_VALUE = $SHIKIGAMI_ROLE_PROVIDER_MAP 中 ROLE 對應的值
  解析格式：
    - "developer:gemini"                   → provider=gemini, model=預設
    - "developer:gemini:gemini-3.1-pro-preview" → provider=gemini, model=gemini-3.1-pro-preview
    - "developer:claude"                   → provider=claude

# 步驟 1b：若角色層級無對照，查詢全域 provider
若 MAP_VALUE 未設定：
  provider = $SHIKIGAMI_MODEL_PROVIDER（若未設定則使用宿主平台偵測結果）

# 步驟 1c：最終決定
provider = MAP_VALUE 中解析的 provider（或全域 provider，或宿主平台偵測結果）
model    = MAP_VALUE 中解析的 model（若有），否則使用 provider 預設模型

# 宿主平台偵測規則（步驟 1b/1c fallback 使用）
宿主平台偵測：
  - Claude Code session 中執行 → provider = "claude"
  - Gemini CLI session 中執行  → provider = "gemini"
  - 無法判定                   → provider = "claude"（保守 fallback）
完整偵測規則參照 SKILL.md §2.1「宿主平台偵測規則」
```

## 步驟 2：依 provider 選擇派遣路徑

**provider = claude（預設路徑）**：

使用 Agent tool 派遣，指定 `model: "sonnet"`：

```
派遣 Story-Lifecycle subagent（Agent tool, model: "sonnet"）
```

**provider = gemini**：

使用 Bash 呼叫 Gemini CLI，以 stdin pipe 傳入 prompt 與 Story 參數：

```bash
# 無模型指定（使用 Gemini 預設模型）
echo "$(cat skills/sprint-execution/story-lifecycle-prompt.md)
story_id: ${story_id}
sprint_file: ${sprint_file}" | gemini

# 有模型指定（使用 SHIKIGAMI_ROLE_PROVIDER_MAP 解析的 model）
echo "$(cat skills/sprint-execution/story-lifecycle-prompt.md)
story_id: ${story_id}
sprint_file: ${sprint_file}" | gemini --model ${model}
```

## 步驟 3：Gemini CLI 失敗處理（自動 Fallback）

Gemini CLI 執行後，檢查回傳結果：

```
若 exit code != 0 或 執行逾時 或 quota 耗盡 或 認證失敗：
  → 輸出告警：[FALLBACK] Gemini CLI 失敗，切回 Claude
  → 自動改用 Claude Agent tool 執行（model: "sonnet"）
  → 不中斷流程，不需使用者手動干預

若 stderr 含 "ModelNotFoundError"：
  → 輸出告警：[FALLBACK] Gemini CLI 失敗，切回 Claude
  → 自動改用 Claude Agent tool 執行（model: "sonnet"）
  → 禁止靜默降級至其他 Gemini 模型（如 gemini-pro）
  → 不中斷流程
```

完整 Fallback 規則請參照 `skills/sprint-execution/SKILL.md` §2.1「Fallback 行為」與「不降級策略」。
