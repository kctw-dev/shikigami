#!/usr/bin/env bash
# tests/test-schema-first.sh
# Story #406: Schema 先行 — API Contract 統一定義
# AC4: 驗證 docs/schema/ 目錄存在且命名規範檔案存在

set -euo pipefail

PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

run_test() {
  local desc="$1"
  local result="$2"
  if [[ "$result" == "PASS" ]]; then
    echo "  [PASS] ${desc}"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] ${desc}"
    FAIL=$((FAIL + 1))
  fi
}

echo "========================================"
echo "  test-schema-first.sh"
echo "  Story #406: Schema-first API Contract"
echo "========================================"

# AC1: docs/schema/ 目錄存在
test -d "${REPO_ROOT}/docs/schema" \
  && run_test "docs/schema/ 目錄存在" "PASS" \
  || run_test "docs/schema/ 目錄存在" "FAIL"

# AC1: docs/schema/README.md 存在（命名規範）
test -f "${REPO_ROOT}/docs/schema/README.md" \
  && run_test "docs/schema/README.md 存在（命名規範）" "PASS" \
  || run_test "docs/schema/README.md 存在（命名規範）" "FAIL"

# AC2: architect-prompt.md 包含 Schema Definition 階段指引
grep -q "Schema\|schema" "${REPO_ROOT}/skills/sprint-planning/references/architect-prompt.md" \
  && run_test "architect-prompt.md 包含 Schema 定義關鍵字" "PASS" \
  || run_test "architect-prompt.md 包含 Schema 定義關鍵字" "FAIL"

grep -q "Schema Contract\|schema-contract\|schema_contract\|Schema Definition" \
  "${REPO_ROOT}/skills/sprint-planning/references/architect-prompt.md" \
  && run_test "architect-prompt.md 包含 Schema Contract / Schema Definition 指引" "PASS" \
  || run_test "architect-prompt.md 包含 Schema Contract / Schema Definition 指引" "FAIL"

# AC1: docs/schema/README.md 包含命名規範說明（kebab-case）
if test -f "${REPO_ROOT}/docs/schema/README.md"; then
  grep -q "kebab-case\|命名\|naming" "${REPO_ROOT}/docs/schema/README.md" \
    && run_test "docs/schema/README.md 包含命名規範說明" "PASS" \
    || run_test "docs/schema/README.md 包含命名規範說明" "FAIL"
else
  run_test "docs/schema/README.md 包含命名規範說明" "FAIL"
fi

# AC3: sprint_136.md 包含 Schema Contract locked 狀態記錄（或相關欄位）
SPRINT_FILE="${REPO_ROOT}/docs/sprints/sprint_136.md"
if test -f "${SPRINT_FILE}"; then
  grep -q "Schema\|schema" "${SPRINT_FILE}" \
    && run_test "sprint_136.md 包含 Schema 相關記錄" "PASS" \
    || run_test "sprint_136.md 包含 Schema 相關記錄" "FAIL"
else
  run_test "sprint_136.md 包含 Schema 相關記錄" "FAIL"
fi

echo ""
echo "========================================"
echo "  結果：PASS ${PASS} / FAIL ${FAIL}"
if [[ ${FAIL} -eq 0 ]]; then
  echo "  全部通過"
  echo "========================================"
  exit 0
else
  echo "  有測試失敗"
  echo "========================================"
  exit 1
fi
