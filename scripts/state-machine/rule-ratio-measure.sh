#!/usr/bin/env bash
# rule-ratio-measure.sh — 規則佔比測量腳本（Story #983 AC-2 + #996 AC-1~5）
#
# 測量 prompt 檔案中規則區塊的 token 佔比。
#
# 規則區塊識別：「## 規則片段」到「## 輸入契約」之間的內容
#
# Token 估算（零依賴，純 bash/awk）：
#   - 英文字元（ASCII 可見字元）：字元數 / 4
#   - 中文字元（Unicode CJK）：字元數 / 1.5
#
# 用法：
#   rule-ratio-measure.sh [--threshold <float>] <prompt_file>
#
# 參數：
#   --threshold <float>  — 自訂門檻值（0.0 <= threshold <= 1.0）
#                           預設值：0.10
#                           環境變數：RULE_RATIO_THRESHOLD
#                           優先順序：CLI > ENV > 預設
#
# 輸出：JSON
#   { "rule_tokens": N, "total_tokens": N, "ratio": 0.XX, "passed": true/false }
#
# 退出碼：
#   0 — 成功（無論 passed 為 true 或 false）
#   1 — 錯誤（無參數、檔案不存在、閾值超出範圍等）

set -euo pipefail

THRESHOLD=0.10  # 預設規則佔比最低門檻 >= 10%

# ── 使用說明 ──

usage() {
  echo "Usage: rule-ratio-measure.sh [--threshold <float>] <prompt_file>" >&2
  echo "" >&2
  echo "Measures the ratio of rule tokens in a prompt file." >&2
  echo "" >&2
  echo "Options:" >&2
  echo "  --threshold <float>  Custom threshold value (0.0 <= threshold <= 1.0)" >&2
  echo "                        Default: 0.10" >&2
  echo "                        Env var: RULE_RATIO_THRESHOLD" >&2
  echo "                        Precedence: CLI > ENV > default" >&2
  echo "" >&2
  echo "Rule block: content between '## 規則片段' and '## 輸入契約'" >&2
  echo "Token estimation (zero dependency):" >&2
  echo "  ASCII chars / 4 = English tokens" >&2
  echo "  CJK chars / 1.5 = Chinese tokens" >&2
  echo "" >&2
  echo "Output: JSON { rule_tokens, total_tokens, ratio, passed }" >&2
  exit 1
}

# ── 引數解析與驗證（Story #996 AC-1~3）──

PROMPT_FILE=""
CLI_THRESHOLD=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --threshold)
      if [[ $# -lt 2 ]]; then
        echo "[ERROR] --threshold requires an argument" >&2
        usage
      fi
      CLI_THRESHOLD="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    -*)
      echo "[ERROR] Unknown option: $1" >&2
      usage
      ;;
    *)
      PROMPT_FILE="$1"
      shift
      ;;
  esac
done

if [[ -z "${PROMPT_FILE}" ]]; then
  usage
fi

if [[ ! -f "${PROMPT_FILE}" ]]; then
  echo "[ERROR] File not found: ${PROMPT_FILE}" >&2
  exit 1
fi

# ── 優先順序：CLI > ENV > 預設（Story #996 AC-3）──

if [[ -n "${CLI_THRESHOLD}" ]]; then
  THRESHOLD="${CLI_THRESHOLD}"
elif [[ -n "${RULE_RATIO_THRESHOLD:-}" ]]; then
  THRESHOLD="${RULE_RATIO_THRESHOLD}"
fi

# ── 閾值範圍驗證（Story #996 AC-1）──

validate_threshold() {
  local threshold="$1"
  # 檢查是否為有效的浮點數且在 [0.0, 1.0] 範圍內
  if ! [[ "${threshold}" =~ ^([0-9]*\.?[0-9]+)$ ]]; then
    echo "[ERROR] Invalid threshold value: ${threshold} (must be a number)" >&2
    return 1
  fi

  local is_valid=0
  # 使用 awk 進行範圍檢查
  if awk "BEGIN { exit (${threshold} >= 0.0 && ${threshold} <= 1.0) ? 0 : 1 }"; then
    is_valid=1
  fi

  if [[ ${is_valid} -ne 1 ]]; then
    echo "[ERROR] Threshold out of range: ${threshold} (must be between 0.0 and 1.0)" >&2
    return 1
  fi
  return 0
}

if ! validate_threshold "${THRESHOLD}"; then
  exit 1
fi

# ── Token 估算函數（使用 awk 純 bash 實作）──
#
# 策略：
#   1. awk 計算每行的 ASCII 可見字元數與 CJK（3-byte UTF-8）字元數
#   2. 英文 token = ascii_chars / 4
#   3. 中文 token = cjk_chars / 1.5
#   4. 四捨五入為整數
#
# awk 實作說明：
#   UTF-8 中文字元在 byte 層面每個 3-4 bytes
#   我們透過計算非 ASCII（高位元組）字元估算 CJK 字元數
#   保守估算：high byte chars / 3 ≈ CJK 字元數

estimate_tokens_for_text() {
  local text="$1"
  if [[ -z "${text}" ]]; then
    echo "0"
    return
  fi

  # 使用 awk 計算 token 估算
  # LC_ALL=C 確保 byte 層面處理
  echo "${text}" | LC_ALL=C awk '
  BEGIN {
    ascii_chars = 0
    high_bytes = 0
  }
  {
    n = length($0)
    for (i = 1; i <= n; i++) {
      c = substr($0, i, 1)
      # 取得 ASCII 值
      code = ord(c)
      if (code >= 33 && code <= 126) {
        # 可見 ASCII 字元（英文、數字、符號）
        ascii_chars++
      } else if (code > 127) {
        # 高位元組（中文 UTF-8 的組成部分）
        high_bytes++
      }
    }
  }
  function ord(c,    i) {
    for (i = 0; i < 256; i++) {
      if (sprintf("%c", i) == c) return i
    }
    return 0
  }
  END {
    # 中文字元估算：每個 CJK 字元 = 3 high bytes
    cjk_chars = high_bytes / 3
    # Token 估算
    en_tokens = ascii_chars / 4
    zh_tokens = cjk_chars / 1.5
    total = en_tokens + zh_tokens
    # 四捨五入
    printf "%d\n", int(total + 0.5)
  }
  '
}

# ── 提取規則區塊內容 ──

extract_rule_block() {
  local file="$1"
  # 提取「## 規則片段」到「## 輸入契約」之間的內容
  # 使用 awk 精確提取（不含邊界標記行本身）
  awk '
  /^## 規則片段/ { in_rule = 1; next }
  /^## 輸入契約/ { in_rule = 0; next }
  in_rule { print }
  ' "${file}"
}

# ── 主邏輯 ──

# 1. 讀取全部內容
FULL_CONTENT=$(cat "${PROMPT_FILE}")

# 2. 提取規則區塊
RULE_CONTENT=$(extract_rule_block "${PROMPT_FILE}")

# 3. 估算 token 數
RULE_TOKENS=$(estimate_tokens_for_text "${RULE_CONTENT}")
TOTAL_TOKENS=$(estimate_tokens_for_text "${FULL_CONTENT}")

# 4. 計算佔比（避免除以零）
if [[ "${TOTAL_TOKENS}" -eq 0 ]]; then
  RATIO="0.0"
  PASSED="false"
else
  # 使用 awk 計算浮點比例
  RATIO=$(awk "BEGIN { printf \"%.4f\", ${RULE_TOKENS} / ${TOTAL_TOKENS} }")
  # 判斷是否達到門檻
  PASSED=$(awk "BEGIN { print (${RATIO} >= ${THRESHOLD}) ? \"true\" : \"false\" }")
fi

# 5. 輸出 JSON
cat <<JSON_EOF
{
  "rule_tokens": ${RULE_TOKENS},
  "total_tokens": ${TOTAL_TOKENS},
  "ratio": ${RATIO},
  "passed": ${PASSED}
}
JSON_EOF
