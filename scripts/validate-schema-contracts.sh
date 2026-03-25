#!/usr/bin/env bash
# validate-schema-contracts.sh — Schema-First Contract 前置驗證腳本
# Story #802 AC1: ADR-036 落地工具 — 確認 Story AC 涉及 API/endpoint 時有對應 schema
# NFR1: Warn-only（警告不阻斷），exit 0

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONTRACTS_DIR="${REPO_ROOT}/docs/contracts"
SCHEMA_DIR="${REPO_ROOT}/docs/schema"
SPRINT_BOARD="${REPO_ROOT}/docs/sprints"

DRY_RUN=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --verbose) VERBOSE=true; shift ;;
    *) shift ;;
  esac
done

WARN_COUNT=0
OK_COUNT=0

echo "[SCHEMA-CHECK] Schema-First Contract 驗證開始"
echo "  Contracts dir: ${CONTRACTS_DIR}"
echo "  Schema dir:    ${SCHEMA_DIR}"

# Find current sprint file
SPRINT_FILE=$(ls -t "${SPRINT_BOARD}"/sprint_*.md 2>/dev/null | head -1)

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[SCHEMA-CHECK] --dry-run 模式：顯示計畫動作，不執行驗證"
  echo "[SCHEMA-OK] dry-run 完成，exit 0（warn-only）"
  exit 0
fi

if [[ -z "$SPRINT_FILE" ]]; then
  echo "[SCHEMA-WARN] 無法找到 sprint_N.md，跳過驗證"
  exit 0
fi

echo "[SCHEMA-CHECK] 掃描 Sprint 文件: $(basename "$SPRINT_FILE")"

# Check AC lines for API/endpoint keywords
API_STORIES=()
while IFS= read -r line; do
  if echo "$line" | grep -qiE "api|endpoint|http|rest|openapi|schema|contract|json.*schema"; then
    story_ref=$(echo "$line" | grep -oE '#[0-9]+' | head -1)
    if [[ -n "$story_ref" ]]; then
      API_STORIES+=("$story_ref")
    fi
  fi
done < "$SPRINT_FILE"

# Deduplicate
mapfile -t API_STORIES < <(printf '%s\n' "${API_STORIES[@]}" | sort -u)

if [[ ${#API_STORIES[@]} -eq 0 ]]; then
  echo "[SCHEMA-OK] 本 Sprint 無涉及 API/endpoint 的 Story，Schema-First Gate 不適用"
  exit 0
fi

echo "[SCHEMA-CHECK] 偵測到 ${#API_STORIES[@]} 個涉及 API 的 Story: ${API_STORIES[*]}"

# For each API story, check if there is a corresponding schema in docs/schema/
for story in "${API_STORIES[@]}"; do
  story_num="${story#\#}"
  schema_found=false

  if [[ -d "$SCHEMA_DIR" ]]; then
    if find "$SCHEMA_DIR" -name "${story_num}-*.json" -o -name "${story_num}-*.yaml" 2>/dev/null | grep -q .; then
      schema_found=true
    fi
  fi

  if [[ "$schema_found" == "true" ]]; then
    echo "[SCHEMA-OK] ${story}: Schema contract 存在"
    OK_COUNT=$((OK_COUNT+1))
  else
    echo "[SCHEMA-WARN] ${story}: AC 涉及 API/endpoint 但無對應 Schema Contract (docs/schema/${story_num}-*.json)"
    echo "  建議：執行 Sprint Planning 時 Architect 產出對應 Schema Contract"
    WARN_COUNT=$((WARN_COUNT+1))
  fi
done

echo ""
echo "[SCHEMA-CHECK] 驗證完成: ${OK_COUNT} OK, ${WARN_COUNT} WARN"
echo "[SCHEMA-CHECK] NFR1: warn-only 模式，不阻擋 Sprint Planning，exit 0"

# Always exit 0 (warn-only, NFR1)
exit 0
