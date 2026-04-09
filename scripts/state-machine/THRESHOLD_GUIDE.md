# Rule Ratio Threshold Guide

## 概述

`rule-ratio-measure.sh` 測量 prompt 檔案中規則區塊的 token 佔比，用於驗證 Agent Prompt 的品質。不同使用場景需要不同的門檻值。

## 建議門檻值

| 用途 | 門檻值 | 說明 |
|------|--------|------|
| **delivery-completion-check** | **0.30** | Sprint Execution 中檢查 delivery task 的 completion 狀態，需要嚴格的規則要求（>= 30%） |
| **task-list-init** | **0.20** | Sprint Execution 中初始化 Task List，規則佔比較寬鬆（>= 20%） |
| **通用（預設）** | **0.10** | 其他一般性 Agent Prompt 驗證（>= 10%） |

## 使用方式

### 1. 預設值
未指定閾值時，使用預設 0.10：
```bash
scripts/state-machine/rule-ratio-measure.sh prompt.md
```

### 2. CLI 參數（優先度最高）
```bash
scripts/state-machine/rule-ratio-measure.sh --threshold 0.30 prompt.md
```

### 3. 環境變數（優先度次之）
```bash
export RULE_RATIO_THRESHOLD=0.25
scripts/state-machine/rule-ratio-measure.sh prompt.md
```

### 4. 優先順序
**CLI > ENV > 預設 0.10**

當同時指定 CLI 和環境變數時，CLI 參數勝出。

## 有效範圍

- 閾值必須為 0.0 到 1.0 之間的浮點數
- 超出範圍會導致腳本 exit != 0

```bash
# 正確
scripts/state-machine/rule-ratio-measure.sh --threshold 0.30 prompt.md  # OK
scripts/state-machine/rule-ratio-measure.sh --threshold 0.0 prompt.md   # OK
scripts/state-machine/rule-ratio-measure.sh --threshold 1.0 prompt.md   # OK

# 錯誤
scripts/state-machine/rule-ratio-measure.sh --threshold -0.1 prompt.md  # ERROR
scripts/state-machine/rule-ratio-measure.sh --threshold 1.5 prompt.md   # ERROR
```

## 輸出

腳本輸出 JSON 格式：
```json
{
  "rule_tokens": 125,
  "total_tokens": 420,
  "ratio": 0.2976,
  "passed": true
}
```

`passed` 欄位表示：rule_tokens / total_tokens >= 閾值

## 相關文件

- `scripts/state-machine/rule-ratio-measure.sh` — 規則佔比測量腳本
- `scripts/state-machine/dispatch-preflight.sh` — 根據 step type 傳入對應門檻的前置檢查
- `skills/sprint-execution/references/step-subagent-contract.md` — Step Subagent 契約引用此指南

## Story 歷史

- **#983**：建立基礎 rule-ratio-measure.sh（預設 THRESHOLD=0.10）
- **#988**：delivery-completion-check 要求 >= 30%
- **#996**：支援 per-prompt THRESHOLD 參數、環境變數、優先順序規則、範圍驗證
