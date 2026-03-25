#!/usr/bin/env bash
# scripts/validate-a2a-schema.sh
# #801 A2A Protocol — Subagent result file schema 驗證
#
# 依據 ADR-044（A2A Protocol Schema v1.0）驗證 subagent 回傳的 JSON 結果檔案。
#
# 驗證項目：
#   - 必要欄位存在：protocol_version, story_id, actor, result, summary, timestamp
#   - protocol_version 值為 "1.0"
#   - actor 合法值：developer | architect | qa | po | security | sm
#   - result 合法值：PASS | FAIL | ESCALATE
#   - timestamp 格式為 ISO 8601（含基本格式檢查）
#   - escalation 在 result=ESCALATE 時必填
#
# 使用方式：
#   bash scripts/validate-a2a-schema.sh <json-file>
#
# Exit code:
#   0 = PASS（全部驗證通過）
#   1 = FAIL（有驗證錯誤）
#
# 依賴：bash >= 4, python3（JSON 解析）

set -uo pipefail

# ---------------------------------------------------------------------------
# 常數
# ---------------------------------------------------------------------------
readonly REQUIRED_FIELDS=("protocol_version" "story_id" "actor" "result" "summary" "timestamp")
readonly VALID_ACTORS=("developer" "architect" "qa" "po" "security" "sm")
readonly VALID_RESULTS=("PASS" "FAIL" "ESCALATE")
readonly VALID_ESCALATION_TYPES=("DESIGN_ISSUE" "CONTEXT_OVERFLOW" "REQUIREMENT_AMBIGUITY" "DEPENDENCY_MISSING" "SECURITY_CRITICAL" "DEBATE_DESIGN_ISSUE")

# ---------------------------------------------------------------------------
# 狀態追蹤
# ---------------------------------------------------------------------------
EXIT_CODE=0
ERROR_COUNT=0
PASS_COUNT=0

# ---------------------------------------------------------------------------
# 輸出函式
# ---------------------------------------------------------------------------
emit_pass() {
  echo "[PASS] $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

emit_fail() {
  echo "[FAIL] $1"
  EXIT_CODE=1
  ERROR_COUNT=$((ERROR_COUNT + 1))
}

# ---------------------------------------------------------------------------
# 前置條件：確認 python3 存在
# ---------------------------------------------------------------------------
check_dependencies() {
  if ! command -v python3 &>/dev/null; then
    echo "[FAIL] 缺少依賴：python3 未安裝，無法進行 JSON 解析"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# 主驗證邏輯（透過 python3 解析 JSON）
# ---------------------------------------------------------------------------
validate_file() {
  local filepath="$1"

  # 確認檔案存在
  if [[ ! -f "${filepath}" ]]; then
    emit_fail "找不到檔案：${filepath}"
    return
  fi

  # 讀取檔案內容
  local content
  content=$(cat "${filepath}" 2>/dev/null || true)

  if [[ -z "${content}" ]]; then
    emit_fail "檔案為空：${filepath}"
    return
  fi

  # 執行 Python 驗證邏輯
  local validation_output
  validation_output=$(python3 - "${filepath}" <<'PYEOF'
import json
import sys
import re
from pathlib import Path

filepath = sys.argv[1]
errors = []
passes = []

# 讀取並解析 JSON
try:
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read().strip()
    obj = json.loads(content)
except json.JSONDecodeError as e:
    print(f"FAIL:JSON 格式錯誤：{e}")
    sys.exit(0)
except Exception as e:
    print(f"FAIL:讀取檔案失敗：{e}")
    sys.exit(0)

if not isinstance(obj, dict):
    print("FAIL:JSON 頂層必須為物件（object）")
    sys.exit(0)

passes.append("JSON 格式合法")

# 必要欄位檢查
required = ["protocol_version", "story_id", "actor", "result", "summary", "timestamp"]
for field in required:
    if field not in obj:
        errors.append(f"缺少必要欄位：{field}")
    else:
        passes.append(f"必要欄位存在：{field}")

if errors:
    for e in errors:
        print(f"FAIL:{e}")
    for p in passes:
        print(f"PASS:{p}")
    sys.exit(0)

# protocol_version 驗證
if obj["protocol_version"] != "1.0":
    errors.append(f"protocol_version 值必須為 '1.0'，實際值：{obj['protocol_version']!r}")
else:
    passes.append("protocol_version = '1.0'")

# actor 合法值驗證
valid_actors = ["developer", "architect", "qa", "po", "security", "sm"]
if obj["actor"] not in valid_actors:
    errors.append(f"actor 值 {obj['actor']!r} 不合法，允許值：{valid_actors}")
else:
    passes.append(f"actor = {obj['actor']!r}（合法）")

# result 合法值驗證
valid_results = ["PASS", "FAIL", "ESCALATE"]
if obj["result"] not in valid_results:
    errors.append(f"result 值 {obj['result']!r} 不合法，允許值：{valid_results}")
else:
    passes.append(f"result = {obj['result']!r}（合法）")

# story_id 型別驗證
if not isinstance(obj["story_id"], int):
    errors.append(f"story_id 必須為整數，實際類型：{type(obj['story_id']).__name__}")
else:
    passes.append(f"story_id = {obj['story_id']}（整數）")

# timestamp 基本格式驗證（ISO 8601 簡略檢查）
ts = obj["timestamp"]
iso_pattern = re.compile(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2}|[+-]\d{4})$'
)
if not iso_pattern.match(str(ts)):
    errors.append(f"timestamp 格式不符合 ISO 8601：{ts!r}")
else:
    passes.append(f"timestamp 格式合法：{ts!r}")

# escalation 在 result=ESCALATE 時必填
if obj["result"] == "ESCALATE":
    if "escalation" not in obj or obj["escalation"] is None:
        errors.append("result=ESCALATE 時，escalation 欄位必填")
    else:
        esc = obj["escalation"]
        valid_types = ["DESIGN_ISSUE", "CONTEXT_OVERFLOW", "REQUIREMENT_AMBIGUITY",
                       "DEPENDENCY_MISSING", "SECURITY_CRITICAL", "DEBATE_DESIGN_ISSUE"]
        if "type" not in esc:
            errors.append("escalation.type 欄位缺失")
        elif esc["type"] not in valid_types:
            errors.append(f"escalation.type 值 {esc['type']!r} 不合法")
        else:
            passes.append(f"escalation.type = {esc['type']!r}（合法）")
        if "reason" not in esc or not esc["reason"]:
            errors.append("escalation.reason 欄位缺失或為空")
        else:
            passes.append("escalation.reason 存在")

# 輸出結果
for e in errors:
    print(f"FAIL:{e}")
for p in passes:
    print(f"PASS:{p}")
PYEOF
  2>&1 || true)

  # 解析 Python 輸出
  local has_fail=0
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    if [[ "${line}" == FAIL:* ]]; then
      emit_fail "${line#FAIL:}"
      has_fail=1
    elif [[ "${line}" == PASS:* ]]; then
      emit_pass "${line#PASS:}"
    else
      # 意外輸出視為錯誤
      emit_fail "驗證異常：${line}"
      has_fail=1
    fi
  done <<< "${validation_output}"
}

# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
main() {
  echo "=== validate-a2a-schema.sh — A2A Protocol Schema 驗證（ADR-044）==="
  echo ""

  check_dependencies

  # 確認有傳入檔案路徑
  if [[ $# -lt 1 ]]; then
    echo "[FAIL] 使用方式：bash scripts/validate-a2a-schema.sh <json-file>"
    exit 1
  fi

  local filepath="$1"
  echo "驗證目標：${filepath}"
  echo ""

  validate_file "${filepath}"

  echo ""
  echo "=============================="
  if [[ "${EXIT_CODE}" -eq 0 ]]; then
    echo " 結果：PASS（${PASS_COUNT} 項全部通過）"
  else
    echo " 結果：FAIL（${ERROR_COUNT} 個錯誤）"
  fi
  echo "=============================="

  exit "${EXIT_CODE}"
}

main "${@}"
