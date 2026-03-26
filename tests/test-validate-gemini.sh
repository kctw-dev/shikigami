#!/usr/bin/env bash
# tests/test-validate-gemini.sh
# validate-gemini.sh 自動化測試
# Issue #843, Sprint 167
# AC1: 測試涵蓋版號一致性檢查（與 plugin.json 同步）
# AC2: 測試涵蓋必要欄位存在性檢查
# AC3: 測試涵蓋版號一致性
# AC4: 測試 PASS 且 exit 0
# NFR1: 使用 fixture，不修改真實 gemini-extension.json

set -uo pipefail

PASS=0
FAIL=0
SCRIPT="scripts/validate-gemini.sh"

# 建立 fixture 環境
FIXTURE_DIR=$(mktemp -d)
trap "rm -rf ${FIXTURE_DIR}" EXIT

setup_fixture() {
  local DIR="$1"
  # 建立 fixture 目錄結構（模擬專案根目錄）
  mkdir -p "${DIR}/.claude-plugin"
  mkdir -p "${DIR}/.gemini/commands/shikigami"

  # 建立 plugin.json fixture（2-space indented JSON，符合 json_get_string_value 解析要求）
  cat > "${DIR}/.claude-plugin/plugin.json" << 'EOF'
{
  "name": "shikigami",
  "version": "0.108.0"
}
EOF

  # 建立 GEMINI.md fixture
  echo "# GEMINI" > "${DIR}/GEMINI.md"

  # 建立 gemini command fixtures（含 prompt 欄位，符合 AC5 驗證）
  for cmd in sprint standup review dispel; do
    cat > "${DIR}/.gemini/commands/shikigami/${cmd}.toml" << EOF
prompt = "Execute ${cmd} skill"
EOF
  done
}

run_test() {
  local NAME="$1"
  local RESULT="$2"
  local EXPECTED="$3"

  if [[ "$RESULT" == "$EXPECTED" ]]; then
    echo "  PASS: $NAME"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $NAME"
    echo "    Expected: $EXPECTED"
    echo "    Got:      $RESULT"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== validate-gemini.sh 自動化測試 ==="
echo ""

# TC1: 腳本存在性
echo "TC1: 腳本存在性"
if [[ -f "$SCRIPT" ]]; then
  echo "  PASS: $SCRIPT 存在"
  PASS=$((PASS + 1))
else
  echo "  FAIL: $SCRIPT 不存在"
  FAIL=$((FAIL + 1))
fi

# 建立 Fixture 環境
setup_fixture "$FIXTURE_DIR"

# TC2: 版號一致 — 應 PASS（AC1）
echo "TC2: 版號一致（AC1）"
cat > "${FIXTURE_DIR}/gemini-extension.json" << 'EOF'
{
  "name": "shikigami",
  "version": "0.108.0",
  "description": "Test extension",
  "author": "KCTW",
  "contextFileName": "GEMINI.md"
}
EOF
RESULT=$(cd "${FIXTURE_DIR}" && bash "${OLDPWD}/${SCRIPT}" 2>&1)
EXIT_CODE=$?
if [[ "$EXIT_CODE" -eq 0 ]]; then
  echo "  PASS: 版號一致時 exit 0"
  PASS=$((PASS + 1))
else
  echo "  FAIL: 版號一致時應 exit 0，got $EXIT_CODE"
  FAIL=$((FAIL + 1))
fi

# TC3: 版號不一致 — 應偵測到 ERROR（AC1 版號一致性）
echo "TC3: 版號不一致偵測（AC1）"
cat > "${FIXTURE_DIR}/gemini-extension.json" << 'EOF'
{
  "name": "shikigami",
  "version": "0.999.0",
  "description": "Test extension",
  "author": "KCTW",
  "contextFileName": "GEMINI.md"
}
EOF
RESULT=$(cd "${FIXTURE_DIR}" && bash "${OLDPWD}/${SCRIPT}" 2>&1)
EXIT_CODE=$?
if [[ "$EXIT_CODE" -ne 0 ]] || echo "$RESULT" | grep -qiE "error|mismatch|不一致"; then
  echo "  PASS: 版號不一致時偵測到問題"
  PASS=$((PASS + 1))
else
  echo "  FAIL: 版號不一致時應偵測 ERROR"
  FAIL=$((FAIL + 1))
fi

# TC4: 必要欄位存在 — name, version, description, contextFileName（AC2）
echo "TC4: 必要欄位存在性（AC2）"
# 恢復正確 gemini-extension.json
cat > "${FIXTURE_DIR}/gemini-extension.json" << 'EOF'
{
  "name": "shikigami",
  "version": "0.108.0",
  "description": "Test extension",
  "author": "KCTW",
  "contextFileName": "GEMINI.md"
}
EOF
RESULT=$(cd "${FIXTURE_DIR}" && bash "${OLDPWD}/${SCRIPT}" 2>&1)
EXIT_CODE=$?
if [[ "$EXIT_CODE" -eq 0 ]]; then
  echo "  PASS: 必要欄位齊全時 exit 0"
  PASS=$((PASS + 1))
else
  echo "  FAIL: 必要欄位齊全時應 exit 0，got $EXIT_CODE"
  echo "  Output: $RESULT"
  FAIL=$((FAIL + 1))
fi

# TC5: 缺少必要欄位 description — 應偵測 ERROR（AC2）
echo "TC5: 缺少必要欄位偵測（AC2）"
cat > "${FIXTURE_DIR}/gemini-extension.json" << 'EOF'
{
  "name": "shikigami",
  "version": "0.108.0",
  "contextFileName": "GEMINI.md"
}
EOF
RESULT=$(cd "${FIXTURE_DIR}" && bash "${OLDPWD}/${SCRIPT}" 2>&1)
EXIT_CODE=$?
if [[ "$EXIT_CODE" -ne 0 ]] || echo "$RESULT" | grep -qiE "error|missing|缺少|description"; then
  echo "  PASS: 缺少 description 時偵測到問題"
  PASS=$((PASS + 1))
else
  echo "  FAIL: 缺少 description 時應偵測 ERROR"
  FAIL=$((FAIL + 1))
fi

# TC6: gemini-extension.json 不存在 — 應 ERROR
echo "TC6: gemini-extension.json 不存在"
FIXTURE2=$(mktemp -d)
trap "rm -rf ${FIXTURE2}" EXIT
mkdir -p "${FIXTURE2}/.claude-plugin"
echo '{"version":"0.108.0"}' > "${FIXTURE2}/.claude-plugin/plugin.json"
RESULT=$(cd "${FIXTURE2}" && bash "${OLDPWD}/${SCRIPT}" 2>&1)
EXIT_CODE=$?
if [[ "$EXIT_CODE" -ne 0 ]] || echo "$RESULT" | grep -qiE "error|not found|不存在"; then
  echo "  PASS: gemini-extension.json 不存在時偵測到問題"
  PASS=$((PASS + 1))
else
  echo "  FAIL: gemini-extension.json 不存在時應 ERROR"
  FAIL=$((FAIL + 1))
fi

# TC7: GEMINI.md 存在性檢查（AC3 contextFileName 對應）
echo "TC7: GEMINI.md 存在性"
cat > "${FIXTURE_DIR}/gemini-extension.json" << 'EOF'
{
  "name": "shikigami",
  "version": "0.108.0",
  "description": "Test extension",
  "author": "KCTW",
  "contextFileName": "GEMINI.md"
}
EOF
RESULT=$(cd "${FIXTURE_DIR}" && bash "${OLDPWD}/${SCRIPT}" 2>&1)
EXIT_CODE=$?
if [[ "$EXIT_CODE" -eq 0 ]]; then
  echo "  PASS: GEMINI.md 存在時通過"
  PASS=$((PASS + 1))
else
  echo "  FAIL: GEMINI.md 存在時應 PASS"
  echo "  Output: $RESULT"
  FAIL=$((FAIL + 1))
fi

# TC8: 確認不修改真實 gemini-extension.json（NFR1）
echo "TC8: 不修改真實 gemini-extension.json（NFR1）"
REAL_CHECKSUM=$(md5sum gemini-extension.json 2>/dev/null | awk '{print $1}' || echo "skip")
bash "$SCRIPT" > /dev/null 2>&1 || true
NEW_CHECKSUM=$(md5sum gemini-extension.json 2>/dev/null | awk '{print $1}' || echo "skip")
if [[ "$REAL_CHECKSUM" == "$NEW_CHECKSUM" ]]; then
  echo "  PASS: 真實 gemini-extension.json 未被修改"
  PASS=$((PASS + 1))
else
  echo "  FAIL: 真實 gemini-extension.json 被修改"
  FAIL=$((FAIL + 1))
fi

# Summary
echo ""
echo "=== 測試結果 ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo ""

if [[ "$FAIL" -eq 0 ]]; then
  echo "ALL TESTS PASSED"
  exit 0
else
  echo "SOME TESTS FAILED"
  exit 1
fi
