#!/usr/bin/env bash
# validate-ci-versions.sh
# 掃描所有 .github/workflows/*.yml，檢查 action 版本是否在允許清單中
# 並偵測 Node.js 20 deprecation 相關 action 使用狀況
#
# 使用方式：bash scripts/validate-ci-versions.sh
# 退出碼：0 = PASS，1 = FAIL

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${CI_VERSIONS_REPO_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
WORKFLOWS_DIR="${REPO_ROOT}/.github/workflows"

# ──────────────────────────────────────────────
# 允許清單：action@version（精確比對）
# 依 CLAUDE.md 第 10 條：統一使用 @v4
# ──────────────────────────────────────────────
ALLOWED_ACTIONS=(
  "actions/checkout@v4"
  "actions/setup-node@v4"
  "actions/upload-artifact@v4"
  "actions/download-artifact@v4"
  "actions/cache@v4"
  "anthropics/claude-code-action@v1"
  # oven-sh/setup-bun 使用 pinned SHA（特例，見 ADR 說明）
  # 允許任何 SHA（40 位十六進位）
)

# ──────────────────────────────────────────────
# Node.js 20 廢棄偵測：已知在 Node.js 20 上執行的 action 版本
# ──────────────────────────────────────────────
NODEJS20_AFFECTED_ACTIONS=(
  "actions/checkout@v4"
  "actions/setup-node@v4"
  "actions/upload-artifact@v4"
  "actions/download-artifact@v4"
  "actions/cache@v4"
  "anthropics/claude-code-action@v1"
)

PASS=true
WARNINGS=()
ERRORS=()
AFFECTED_NODES20=()

echo "======================================"
echo "  CI Actions 版本驗證"
echo "  工作目錄：${REPO_ROOT}"
echo "======================================"
echo ""

if [[ ! -d "${WORKFLOWS_DIR}" ]]; then
  echo "ERROR：找不到 workflows 目錄：${WORKFLOWS_DIR}"
  exit 1
fi

WORKFLOW_FILES=("${WORKFLOWS_DIR}"/*.yml)
if [[ ${#WORKFLOW_FILES[@]} -eq 0 ]]; then
  echo "WARN：找不到任何 workflow 檔案"
  exit 0
fi

echo "掃描 workflow 檔案："
for wf in "${WORKFLOW_FILES[@]}"; do
  echo "  - $(basename "${wf}")"
done
echo ""

# ──────────────────────────────────────────────
# 掃描每個 workflow 中的 uses: 行
# ──────────────────────────────────────────────
declare -A FOUND_ACTIONS  # action_ref -> 出現的檔案列表

for wf in "${WORKFLOW_FILES[@]}"; do
  wf_name="$(basename "${wf}")"

  # 擷取所有 uses: <action> 行（包含縮排）
  while IFS= read -r line; do
    # 去掉前後空白，取得 action ref
    action_ref=$(echo "${line}" | sed -E 's/.*uses:\s*//; s/\s*#.*//' | xargs)
    [[ -z "${action_ref}" ]] && continue

    # 追蹤出現位置
    if [[ -n "${FOUND_ACTIONS[${action_ref}]+_}" ]]; then
      FOUND_ACTIONS["${action_ref}"]="${FOUND_ACTIONS[${action_ref}]}, ${wf_name}"
    else
      FOUND_ACTIONS["${action_ref}"]="${wf_name}"
    fi
  done < <(grep -E '^\s+(- )?uses:\s+' "${wf}" 2>/dev/null || true)
done

echo "──────────────────────────────────────"
echo "  發現的 Actions"
echo "──────────────────────────────────────"

for action_ref in "${!FOUND_ACTIONS[@]}"; do
  wf_list="${FOUND_ACTIONS[${action_ref}]}"
  echo "  [${action_ref}]"
  echo "    出現於：${wf_list}"

  # 判斷是否為允許的版本
  action_name="${action_ref%%@*}"
  action_version="${action_ref##*@}"

  is_allowed=false

  # 檢查是否在允許清單
  for allowed in "${ALLOWED_ACTIONS[@]}"; do
    if [[ "${action_ref}" == "${allowed}" ]]; then
      is_allowed=true
      break
    fi
  done

  # 特例：pinned SHA（oven-sh/setup-bun 或任何以 40 位 hex SHA 結尾的 action）
  if [[ "${action_version}" =~ ^[0-9a-f]{40}$ ]]; then
    is_allowed=true
    echo "    狀態：OK（pinned SHA）"
    WARNINGS+=("${action_ref}（${wf_list}）— 使用 pinned SHA，建議定期更新至新版 SHA")
  elif [[ "${is_allowed}" == "true" ]]; then
    echo "    狀態：OK（允許清單）"
  else
    echo "    狀態：FAIL — 版本不在允許清單"
    ERRORS+=("${action_ref}（${wf_list}）— 不在允許清單，請確認並人工審核後更新允許清單")
    PASS=false
  fi

  # 偵測 Node.js 20 deprecation 影響
  for affected in "${NODEJS20_AFFECTED_ACTIONS[@]}"; do
    if [[ "${action_ref}" == "${affected}" ]]; then
      AFFECTED_NODES20+=("${action_ref}（${wf_list}）")
      break
    fi
  done
done

echo ""
echo "──────────────────────────────────────"
echo "  Node.js 20 Deprecation 偵測"
echo "──────────────────────────────────────"
if [[ ${#AFFECTED_NODES20[@]} -eq 0 ]]; then
  echo "  無受影響 action（目前版本已支援 Node.js 24）"
else
  echo "  以下 actions 可能受 Node.js 20 deprecation 影響："
  echo "  （參考：https://github.blog/changelog/2025-11-11-node-20-actions-deprecation/）"
  echo "  截止日期：2026-06-02（Node.js 24 強制），2026-09-16（Node.js 20 移除）"
  echo ""
  for item in "${AFFECTED_NODES20[@]}"; do
    echo "  WARNING: ${item}"
  done
  echo ""
  echo "  建議短期緩解方案："
  echo "    在 workflow 中加入以下 env，提前測試 Node.js 24 相容性："
  echo "    FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true"
fi

echo ""
echo "──────────────────────────────────────"
echo "  警告（Warnings）"
echo "──────────────────────────────────────"
if [[ ${#WARNINGS[@]} -eq 0 ]]; then
  echo "  無警告"
else
  for w in "${WARNINGS[@]}"; do
    echo "  WARN: ${w}"
  done
fi

echo ""
echo "──────────────────────────────────────"
echo "  錯誤（Errors）"
echo "──────────────────────────────────────"
if [[ ${#ERRORS[@]} -eq 0 ]]; then
  echo "  無錯誤"
else
  for e in "${ERRORS[@]}"; do
    echo "  ERROR: ${e}"
  done
fi

echo ""
echo "======================================"
if [[ "${PASS}" == "true" ]]; then
  echo "  結果：PASS"
  echo "  所有 action 版本符合專案規範（CLAUDE.md 第 10 條）"
  echo "======================================"
  exit 0
else
  echo "  結果：FAIL"
  echo "  發現不符合規範的 action 版本，請人工審核後處理"
  echo "======================================"
  exit 1
fi
