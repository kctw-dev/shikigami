#!/usr/bin/env bash
# scripts/predict-conflicts.sh
# Story #780 — 平行任務衝突預測靜態分析
#
# 使用方式：
#   # 真實模式（從 GitHub 讀取 Story body）
#   bash scripts/predict-conflicts.sh 101 102 103
#
#   # Mock 模式（測試用，直接傳入 body 檔案，不呼叫 gh API）
#   bash scripts/predict-conflicts.sh \
#     --mock-body-1 /path/body1.txt --story-id-1 101 \
#     --mock-body-2 /path/body2.txt --story-id-2 102
#
# 輸出 JSON 格式：
#   {
#     "conflicts": [
#       {"story_a": 101, "story_b": 102, "shared_files": ["path/to/file"]}
#     ],
#     "groups": {
#       "parallel": [103],
#       "sequential": [101, 102]
#     }
#   }
#
# NFR1: False positive（預測衝突但實際無衝突）可接受，保守策略
# NFR2: 輸出 JSON 格式，便於 SKILL.md 組織邏輯解析
# AC3: 預測基於 Story body 關鍵字，不依賴 git history

set -uo pipefail

REPO_NAME="${REPO_NAME:-kctw-dev/shikigami}"

# ── 使用說明 ──────────────────────────────────────────────────────────────
usage() {
  cat <<USAGE
用法：
  bash scripts/predict-conflicts.sh <story_id1> [story_id2] ...
    從 GitHub 讀取 Story body 進行衝突預測

  bash scripts/predict-conflicts.sh \\
    --mock-body-1 <file> --story-id-1 <id> \\
    --mock-body-2 <file> --story-id-2 <id> \\
    [--mock-body-3 <file> --story-id-3 <id>]
    Mock 模式：直接傳入 body 檔案（測試用，不呼叫 GitHub API）

說明：
  predict-conflicts.sh 讀取 Story body，萃取提及的檔案路徑與模組名稱，
  比對各 Story 間的重疊，輸出衝突預測矩陣（JSON）。

  預測基於 Story body 關鍵字（file paths mentioned, module names），
  不依賴 git history（AC3 MVP 原則）。

輸出：
  JSON 格式：
    { "conflicts": [...], "groups": { "parallel": [...], "sequential": [...] } }
USAGE
}

# ── 關鍵字萃取：從 Story body 提取檔案路徑與模組名稱 ─────────────────────
extract_keywords() {
  local body="$1"

  # 萃取策略（AC3：不依賴 git history，純靜態文字分析）：
  # 1. backtick 包裹的路徑（`path/to/file.ext`）
  # 2. 直接提及的路徑（含 / 且含 . 的字串）
  # 3. 引號包裹的路徑（"path/to/file" 或 'path/to/file'）

  echo "${body}" | grep -oE '\`[^\`]+\`' | sed 's/`//g' | \
    grep -E '^[a-zA-Z0-9_./-]+[./][a-zA-Z0-9_.-]+$' || true

  echo "${body}" | grep -oE '"[a-zA-Z0-9_./-]+\.[a-zA-Z0-9_.-]+"' | \
    sed 's/"//g' | grep -E '/' || true

  echo "${body}" | grep -oE "[a-zA-Z0-9_.-]+/[a-zA-Z0-9_./-]+\.[a-zA-Z0-9_-]+" | \
    grep -vE '^(http|https|ftp)' || true
}

# ── JSON 輸出工具 ──────────────────────────────────────────────────────────
json_array_of_nums() {
  # 輸入：空白分隔的數字
  local nums="$1"
  if [[ -z "${nums}" ]]; then
    echo "[]"
    return
  fi
  local out="["
  local first=1
  for n in ${nums}; do
    if [[ "${first}" -eq 1 ]]; then
      out+="${n}"
      first=0
    else
      out+=", ${n}"
    fi
  done
  out+="]"
  echo "${out}"
}

json_array_of_strs() {
  # 輸入：換行分隔的字串
  local strs="$1"
  if [[ -z "${strs}" ]]; then
    echo "[]"
    return
  fi
  local out="["
  local first=1
  while IFS= read -r s; do
    [[ -z "${s}" ]] && continue
    if [[ "${first}" -eq 1 ]]; then
      out+="\"${s}\""
      first=0
    else
      out+=", \"${s}\""
    fi
  done <<< "${strs}"
  out+="]"
  echo "${out}"
}

# ── 主邏輯 ────────────────────────────────────────────────────────────────

# 處理 --help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

# 偵測 Mock 模式 vs 真實模式
MOCK_MODE=0
declare -a STORY_IDS=()
declare -a BODY_FILES=()

if [[ "${1:-}" == --mock-body-* ]]; then
  MOCK_MODE=1
  # 解析 --mock-body-N <file> --story-id-N <id> 參數
  SLOT=0
  while [[ $# -gt 0 ]]; do
    case "${1}" in
      --mock-body-*)
        SLOT=$(echo "${1}" | grep -oE '[0-9]+$')
        BODY_FILES[${SLOT}]="${2}"
        shift 2
        ;;
      --story-id-*)
        SLOT_ID=$(echo "${1}" | grep -oE '[0-9]+$')
        STORY_IDS[${SLOT_ID}]="${2}"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done
else
  # 真實模式：從 GitHub 讀取
  for arg in "$@"; do
    STORY_IDS+=("${arg}")
  done
fi

# 驗證至少有一個 Story
if [[ ${#STORY_IDS[@]} -eq 0 ]]; then
  usage >&2
  exit 1
fi

# 收集每個 Story 的關鍵字（檔案路徑集合）
declare -A STORY_FILES  # story_id -> newline-separated file list

MAX_SLOT=0
for slot in "${!STORY_IDS[@]}"; do
  [[ "${slot}" -gt "${MAX_SLOT}" ]] && MAX_SLOT="${slot}"
done

for slot in "${!STORY_IDS[@]}"; do
  story_id="${STORY_IDS[${slot}]}"
  body=""

  if [[ "${MOCK_MODE}" -eq 1 ]]; then
    # Mock 模式：直接讀取 body 檔案
    body_file="${BODY_FILES[${slot}]:-}"
    if [[ -n "${body_file}" && -f "${body_file}" ]]; then
      body=$(cat "${body_file}")
    fi
  else
    # 真實模式：從 GitHub 讀取 Story body
    body=$(gh issue view "${story_id}" -R "${REPO_NAME}" --json body --jq '.body' 2>/dev/null || echo "")
  fi

  # 萃取關鍵字（AC3：純靜態文字分析，不依賴 git history）
  keywords=$(extract_keywords "${body}" | sort -u)
  STORY_FILES["${story_id}"]="${keywords}"
done

# 衝突分析：逐對比對
CONFLICTS_JSON=""
declare -A IN_CONFLICT  # story_id -> 1 if has conflict

# 取得所有 story_id 清單
ALL_IDS=()
for slot in "${!STORY_IDS[@]}"; do
  ALL_IDS+=("${STORY_IDS[${slot}]}")
done

NUM_STORIES=${#ALL_IDS[@]}

for ((i = 0; i < NUM_STORIES; i++)); do
  for ((j = i + 1; j < NUM_STORIES; j++)); do
    id_a="${ALL_IDS[${i}]}"
    id_b="${ALL_IDS[${j}]}"
    files_a="${STORY_FILES[${id_a}]:-}"
    files_b="${STORY_FILES[${id_b}]:-}"

    # 計算交集
    shared_files=""
    if [[ -n "${files_a}" && -n "${files_b}" ]]; then
      shared_files=$(comm -12 \
        <(echo "${files_a}" | sort -u) \
        <(echo "${files_b}" | sort -u) || true)
    fi

    if [[ -n "${shared_files}" ]]; then
      IN_CONFLICT["${id_a}"]=1
      IN_CONFLICT["${id_b}"]=1

      shared_json=$(json_array_of_strs "${shared_files}")

      if [[ -n "${CONFLICTS_JSON}" ]]; then
        CONFLICTS_JSON+=", "
      fi
      CONFLICTS_JSON+="{\"story_a\": ${id_a}, \"story_b\": ${id_b}, \"shared_files\": ${shared_json}}"
    fi
  done
done

# 分組：parallel（無衝突）vs sequential（有衝突）
PARALLEL_IDS=""
SEQUENTIAL_IDS=""

for id in "${ALL_IDS[@]}"; do
  if [[ "${IN_CONFLICT[${id}]:-0}" -eq 1 ]]; then
    SEQUENTIAL_IDS+=" ${id}"
  else
    PARALLEL_IDS+=" ${id}"
  fi
done

PARALLEL_JSON=$(json_array_of_nums "${PARALLEL_IDS}")
SEQUENTIAL_JSON=$(json_array_of_nums "${SEQUENTIAL_IDS}")

# 輸出 JSON（NFR2）
cat <<JSON
{
  "conflicts": [${CONFLICTS_JSON}],
  "groups": {
    "parallel": ${PARALLEL_JSON},
    "sequential": ${SEQUENTIAL_JSON}
  }
}
JSON
