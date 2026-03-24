#!/usr/bin/env bash
# tests/test-shoot-skill.sh
# US-31：Shoot Skill 測試套件
# 覆蓋 AC1（自動抓取模式）/ AC2（直接描述模式）/ AC3（GitHub Issue 模式）/
#        AC4（Backlog Story 模式）/ AC5（文件產出完整性）/ AC6（瘦身歸檔）/
#        AC7（Sprint Review 連動）/ AC8（Hard Gate 保留）

set -uo pipefail

# ---------------------------------------------------------------------------
# 測試框架（輕量）
# ---------------------------------------------------------------------------
PASS_COUNT=0
FAIL_COUNT=0

pass() {
  echo "PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [ "$actual" = "$expected" ]; then
    pass "$label"
  else
    fail "$label (expected='${expected}', actual='${actual}')"
  fi
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [ "$actual" -eq "$expected" ]; then
    pass "$label"
  else
    fail "$label (expected exit=${expected}, actual exit=${actual})"
  fi
}

assert_file_exists() {
  local path="$1"
  local label="$2"
  if [ -f "$path" ]; then
    pass "$label"
  else
    fail "$label (file not found: ${path})"
  fi
}

assert_file_not_exists() {
  local path="$1"
  local label="$2"
  if [ ! -f "$path" ]; then
    pass "$label"
  else
    fail "$label (file should NOT exist: ${path})"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    pass "$label"
  else
    fail "$label (expected to find '${needle}')"
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    pass "$label"
  else
    fail "$label (expected NOT to find '${needle}')"
  fi
}

assert_count_eq() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [ "$actual" -eq "$expected" ]; then
    pass "$label"
  else
    fail "$label (expected count=${expected}, actual count=${actual})"
  fi
}

# ---------------------------------------------------------------------------
# 測試輔助：取得專案根目錄
# ---------------------------------------------------------------------------
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHOOT_SKILL_MD="${PROJECT_DIR}/skills/shoot/SKILL.md"
SPRINT_REVIEW_SKILL_MD="${PROJECT_DIR}/skills/sprint-review/SKILL.md"

# ---------------------------------------------------------------------------
# 區段 1：SKILL.md 結構靜態驗證（AC1-AC4：觸發語法）
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 1：shoot SKILL.md 結構驗證 ==="

# 1.1 SKILL.md 存在
assert_file_exists "$SHOOT_SKILL_MD" "skills/shoot/SKILL.md 存在"

if [ -f "$SHOOT_SKILL_MD" ]; then
  SKILL_CONTENT=$(cat "$SHOOT_SKILL_MD")

  # 1.2 frontmatter 含 name: shoot
  assert_contains "$SKILL_CONTENT" "name: shoot" "SKILL.md frontmatter 含 name: shoot"

  # 1.3 含 /shoot 觸發語法
  assert_contains "$SKILL_CONTENT" "/shoot" "SKILL.md 含 /shoot 觸發語法"

  # 1.4 AC1：自動抓取模式（無參數）
  assert_contains "$SKILL_CONTENT" 'bug' "SKILL.md 含 bug label 優先順序說明"
  assert_contains "$SKILL_CONTENT" 'retro-action' "SKILL.md 含 retro-action label 優先順序說明"
  assert_contains "$SKILL_CONTENT" 'PRODUCT_BACKLOG' "SKILL.md 含 PRODUCT_BACKLOG 第三優先順序說明"

  # 1.5 AC1：三層優先順序都有
  assert_contains "$SKILL_CONTENT" '優先順序' "SKILL.md 含優先順序說明"

  # 1.6 AC1：三者均無時輸出錯誤
  assert_contains "$SKILL_CONTENT" '三者均無' "SKILL.md 含三者均無錯誤處理"

  # 1.7 AC2：直接描述模式 /shoot "描述"
  assert_contains "$SKILL_CONTENT" '直接描述' "SKILL.md 含直接描述模式說明"

  # 1.8 AC2：描述完整保留至 Shoot_Log.md
  assert_contains "$SKILL_CONTENT" 'Shoot_Log.md' "SKILL.md 含 Shoot_Log.md 記錄說明"

  # 1.9 AC3：GitHub Issue 模式 /shoot #N
  assert_contains "$SKILL_CONTENT" '/shoot #' "SKILL.md 含 /shoot #N 語法"
  assert_contains "$SKILL_CONTENT" 'gh issue view' "SKILL.md 含 gh issue view 說明"

  # 1.10 AC3：Issue 不存在時輸出錯誤
  assert_contains "$SKILL_CONTENT" 'Issue 不存在' "SKILL.md 含 Issue 不存在錯誤處理"

  # 1.11 AC4：Backlog Story 模式 /shoot US-XX
  assert_contains "$SKILL_CONTENT" '/shoot US-' "SKILL.md 含 /shoot US-XX 語法"
  assert_contains "$SKILL_CONTENT" 'Story ID' "SKILL.md 含 Story ID 比對說明"

  # 1.12 AC4：找不到 Story ID 時輸出錯誤
  assert_contains "$SKILL_CONTENT" '找不到 Story' "SKILL.md 含找不到 Story 錯誤處理"

else
  fail "SKILL.md 內容測試跳過（檔案不存在）"
fi

# ---------------------------------------------------------------------------
# 區段 2：文件產出完整性驗證（AC5）
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 2：文件產出完整性（AC5）==="

if [ -f "$SHOOT_SKILL_MD" ]; then
  SKILL_CONTENT=$(cat "$SHOOT_SKILL_MD")

  # 2.1 AC5：更新 Shoot_Log.md
  assert_contains "$SKILL_CONTENT" "docs/km/Shoot_Log.md" "SKILL.md 含 docs/km/Shoot_Log.md 路徑"

  # 2.2 AC5：更新 PROJECT_BOARD.md 短衝記錄
  assert_contains "$SKILL_CONTENT" "PROJECT_BOARD.md" "SKILL.md 含 PROJECT_BOARD.md 更新說明"
  assert_contains "$SKILL_CONTENT" "短衝記錄" "SKILL.md 含短衝記錄區塊說明"

  # 2.3 AC5：git commit 以 shoot: 前綴
  assert_contains "$SKILL_CONTENT" 'shoot:' "SKILL.md 含 shoot: commit 前綴說明"

  # 2.4 AC5：Shoot_Log.md 包含日期/來源/標題/結果/commit hash 欄位
  assert_contains "$SKILL_CONTENT" '日期' "SKILL.md Shoot_Log 含日期欄位"
  assert_contains "$SKILL_CONTENT" '來源' "SKILL.md Shoot_Log 含來源欄位"
  assert_contains "$SKILL_CONTENT" '標題' "SKILL.md Shoot_Log 含標題欄位"
  assert_contains "$SKILL_CONTENT" '結果' "SKILL.md Shoot_Log 含結果欄位"
  assert_contains "$SKILL_CONTENT" 'commit hash' "SKILL.md Shoot_Log 含 commit hash 欄位"
else
  fail "AC5 測試跳過（SKILL.md 不存在）"
fi

# ---------------------------------------------------------------------------
# 區段 3：瘦身歸檔規則驗證（AC6）
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 3：瘦身歸檔規則（AC6）==="

if [ -f "$SHOOT_SKILL_MD" ]; then
  SKILL_CONTENT=$(cat "$SHOOT_SKILL_MD")

  # 3.1 AC6：主文件超過 20 筆時觸發歸檔
  assert_contains "$SKILL_CONTENT" "20" "SKILL.md 含 20 筆觸發閾值說明"

  # 3.2 AC6：移至恰好保留 20 筆
  assert_contains "$SKILL_CONTENT" "保留 20 筆" "SKILL.md 含保留 20 筆說明"

  # 3.3 AC6：移出記錄附加至 archive
  assert_contains "$SKILL_CONTENT" "SHOOT_LOG_ARCHIVE" "SKILL.md 含歸檔目標路徑 SHOOT_LOG_ARCHIVE"

  # 3.4 AC6：更新 archive/README.md
  assert_contains "$SKILL_CONTENT" "archive/README.md" "SKILL.md 含更新 archive/README.md"

  # 3.5 AC6：邊界測試情境說明（20 筆不觸發）
  assert_contains "$SKILL_CONTENT" "20 筆不觸發" "SKILL.md 含 20 筆不觸發邊界說明"

  # 3.6 AC6：21 筆移 1 筆
  assert_contains "$SKILL_CONTENT" "21 筆" "SKILL.md 含 21 筆邊界情境說明"

  # 3.7 AC6：筆數 - 20 公式
  assert_contains "$SKILL_CONTENT" "筆數 - 20" "SKILL.md 含移走筆數公式說明"

else
  fail "AC6 測試跳過（SKILL.md 不存在）"
fi

# ---------------------------------------------------------------------------
# 區段 4：歸檔邏輯數學驗證（AC6 動態）
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 4：歸檔邏輯數學驗證（AC6 動態）==="

# 模擬歸檔計算邏輯
calculate_archive_count() {
  local total="$1"
  local keep=20
  if [ "$total" -gt "$keep" ]; then
    echo $((total - keep))
  else
    echo 0
  fi
}

# 4.1 恰好 20 筆 — 不觸發（移出 0 筆）
result=$(calculate_archive_count 20)
assert_eq "0" "$result" "AC6 邊界：20 筆移出 0 筆（不觸發）"

# 4.2 21 筆 — 移出 1 筆
result=$(calculate_archive_count 21)
assert_eq "1" "$result" "AC6 邊界：21 筆移出 1 筆"

# 4.3 25 筆 — 移出 5 筆
result=$(calculate_archive_count 25)
assert_eq "5" "$result" "AC6 邊界：25 筆移出 5 筆"

# 4.4 26 筆 — 移出 6 筆
result=$(calculate_archive_count 26)
assert_eq "6" "$result" "AC6 邊界：26 筆移出 6 筆"

# 4.5 19 筆 — 不觸發（移出 0 筆）
result=$(calculate_archive_count 19)
assert_eq "0" "$result" "AC6 邊界：19 筆移出 0 筆（不觸發）"

# ---------------------------------------------------------------------------
# 區段 5：Hard Gate 保留驗證（AC8）
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 5：Hard Gate 保留（AC8）==="

if [ -f "$SHOOT_SKILL_MD" ]; then
  SKILL_CONTENT=$(cat "$SHOOT_SKILL_MD")

  # 5.1 AC8：QA 雙階段審查保留
  assert_contains "$SKILL_CONTENT" "QA" "SKILL.md 含 QA 審查說明"
  assert_contains "$SKILL_CONTENT" "雙階段" "SKILL.md 含雙階段審查說明"

  # 5.2 AC8：Architect 技術審查保留
  assert_contains "$SKILL_CONTENT" "Architect" "SKILL.md 含 Architect 審查說明"

  # 5.3 AC8：任一 FAIL 時終止
  assert_contains "$SKILL_CONTENT" "任一 FAIL" "SKILL.md 含任一 FAIL 終止說明"

  # 5.4 AC8：FAIL 場景可觀察驗收點 (a) exit code 非 0
  assert_contains "$SKILL_CONTENT" "exit code 非 0" "SKILL.md 含 FAIL exit code 非 0 說明"

  # 5.5 AC8：FAIL 場景可觀察驗收點 (b) Shoot_Log.md 無 PASS 記錄
  assert_contains "$SKILL_CONTENT" "Shoot_Log.md 中該次任務無 PASS 記錄" "SKILL.md 含 FAIL Shoot_Log 無 PASS 記錄說明"

  # 5.6 AC8：FAIL 場景可觀察驗收點 (c) 不執行 shoot: commit
  assert_contains "$SKILL_CONTENT" "不執行" "SKILL.md 含 FAIL 不執行 shoot: commit 說明"

  # 5.7 AC8：明確跳過 Planning
  assert_contains "$SKILL_CONTENT" "Planning" "SKILL.md 含跳過 Planning 說明"

  # 5.8 AC8：明確跳過 Review
  assert_contains "$SKILL_CONTENT" "Review" "SKILL.md 含跳過 Review 說明"

  # 5.9 AC8：明確跳過 Retro
  assert_contains "$SKILL_CONTENT" "Retro" "SKILL.md 含跳過 Retro 說明"

  # 5.10 AC8：明確跳過 Metrics
  assert_contains "$SKILL_CONTENT" "Metrics" "SKILL.md 含跳過 Metrics 說明"

else
  fail "AC8 測試跳過（SKILL.md 不存在）"
fi

# ---------------------------------------------------------------------------
# 區段 6：Sprint Review 連動驗證（AC7）
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 6：Sprint Review 連動（AC7）==="

# 6.1 sprint-review SKILL.md 存在
assert_file_exists "$SPRINT_REVIEW_SKILL_MD" "skills/sprint-review/SKILL.md 存在"

if [ -f "$SPRINT_REVIEW_SKILL_MD" ]; then
  REVIEW_CONTENT=$(cat "$SPRINT_REVIEW_SKILL_MD")

  # 6.2 AC7：含掃描 Shoot_Log.md 步驟
  assert_contains "$REVIEW_CONTENT" "Shoot_Log.md" "sprint-review SKILL.md 含 Shoot_Log.md 掃描步驟"

  # 6.3 AC7：含「Sprint 外完成項目」區塊說明
  assert_contains "$REVIEW_CONTENT" "Sprint 外完成項目" "sprint-review SKILL.md 含 Sprint 外完成項目區塊"

  # 6.4 AC7：無記錄時輸出「本 Sprint 無短衝記錄」
  assert_contains "$REVIEW_CONTENT" "本 Sprint 無短衝記錄" "sprint-review SKILL.md 含無記錄時輸出文字"

  # 6.5 AC7：短衝記錄不計入 Velocity
  assert_contains "$REVIEW_CONTENT" "不計入 Velocity" "sprint-review SKILL.md 含不計入 Velocity 說明"

else
  fail "AC7 Sprint Review 連動測試跳過（SKILL.md 不存在）"
fi

# ---------------------------------------------------------------------------
# 區段 7：執行流程完整性驗證
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 7：執行流程完整性 ==="

if [ -f "$SHOOT_SKILL_MD" ]; then
  SKILL_CONTENT=$(cat "$SHOOT_SKILL_MD")

  # 7.1 含執行流程說明
  assert_contains "$SKILL_CONTENT" "執行流程" "SKILL.md 含執行流程說明"

  # 7.2 含 QA Pre-flight（第一階段）
  assert_contains "$SKILL_CONTENT" "QA Pre-flight" "SKILL.md 含 QA Pre-flight 說明"

  # 7.3 含 QA Post-check（第二階段）
  assert_contains "$SKILL_CONTENT" "QA Post-check" "SKILL.md 含 QA Post-check 說明"

  # 7.4 含 Architect 審查步驟
  assert_contains "$SKILL_CONTENT" "Architect 審查" "SKILL.md 含 Architect 審查步驟"

  # 7.5 含 Size=S Story 說明
  assert_contains "$SKILL_CONTENT" "Size=S" "SKILL.md 含 Size=S Story 說明（自動抓取第三層）"

  # 7.6 SKILL.md 含 frontmatter 結尾 ---
  FRONTMATTER_COUNT=$(grep -c "^---$" "$SHOOT_SKILL_MD" || true)
  if [ "$FRONTMATTER_COUNT" -ge 2 ]; then
    pass "SKILL.md frontmatter 格式正確（含開頭與結尾 ---）"
  else
    fail "SKILL.md frontmatter 格式不正確（應有至少 2 個 ---）"
  fi

else
  fail "執行流程完整性測試跳過（SKILL.md 不存在）"
fi

# ---------------------------------------------------------------------------
# 區段 8：動態檔案路徑規格驗證
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 8：動態檔案路徑規格 ==="

if [ -f "$SHOOT_SKILL_MD" ]; then
  SKILL_CONTENT=$(cat "$SHOOT_SKILL_MD")

  # 8.1 Shoot_Log.md 路徑
  assert_contains "$SKILL_CONTENT" "docs/km/Shoot_Log.md" "SKILL.md 含 Shoot_Log.md 正確路徑"

  # 8.2 SHOOT_LOG_ARCHIVE.md 路徑
  assert_contains "$SKILL_CONTENT" "docs/km/archive/SHOOT_LOG_ARCHIVE.md" "SKILL.md 含 SHOOT_LOG_ARCHIVE.md 正確路徑"

  # 8.3 PRODUCT_BACKLOG.md 路徑
  assert_contains "$SKILL_CONTENT" "docs/prd/PRODUCT_BACKLOG.md" "SKILL.md 含 PRODUCT_BACKLOG.md 正確路徑"

else
  fail "動態檔案路徑規格測試跳過（SKILL.md 不存在）"
fi

# ---------------------------------------------------------------------------
# 區段 9：test → review → PR 管道驗證（Story #388 AC1-AC3）
# ---------------------------------------------------------------------------
echo ""
echo "=== 區段 9：test → review → PR 管道（#388 AC1-AC3）==="

PIPELINE_REF="${PROJECT_DIR}/skills/shoot/references/pipeline.md"
assert_file_exists "$PIPELINE_REF" "skills/shoot/references/pipeline.md 存在"

if [ -f "$SHOOT_SKILL_MD" ]; then
  SKILL_CONTENT=$(cat "$SHOOT_SKILL_MD")

  # 9.1 AC1：SKILL.md 含管道段落（§7.1）
  assert_contains "$SKILL_CONTENT" "test → review → PR" "SKILL.md 含 test → review → PR 管道說明"

  # 9.2 AC1：含自動串接的三個階段
  assert_contains "$SKILL_CONTENT" "bash tests/test-*.sh" "SKILL.md 含 test 階段指令"

  # 9.3 AC1：含 PR 建立
  assert_contains "$SKILL_CONTENT" "gh pr create" "SKILL.md 含 gh pr create"

  # 9.4 AC1：含 squash merge
  assert_contains "$SKILL_CONTENT" "squash merge" "SKILL.md 含 squash merge 說明"

  # 9.5 AC2：test 失敗中止
  assert_contains "$SKILL_CONTENT" "test 失敗中止" "SKILL.md 含 test 失敗中止說明（AC2）"

  # 9.6 AC2：不進入 review
  assert_contains "$SKILL_CONTENT" "不進入 review" "SKILL.md 含 test FAIL 不進入 review 說明"

  # 9.7 AC2：不建立 PR
  assert_contains "$SKILL_CONTENT" "不建立 PR" "SKILL.md 含 test FAIL 不建立 PR 說明"

  # 9.8 AC3：review 回退修復
  assert_contains "$SKILL_CONTENT" "review 回退修復" "SKILL.md 含 review 回退修復說明（AC3）"

  # 9.9 AC3：含升級 Architect 說明
  assert_contains "$SKILL_CONTENT" "升級 Architect" "SKILL.md 含升級 Architect 說明"

  # 9.10 AC4：SKILL.md 行數不超過 350 行
  LINE_COUNT=$(wc -l < "$SHOOT_SKILL_MD")
  if [ "$LINE_COUNT" -le 350 ]; then
    pass "AC4 SKILL.md 行數 ${LINE_COUNT} <= 350 行"
  else
    fail "AC4 SKILL.md 行數 ${LINE_COUNT} 超過 350 行限制"
  fi

else
  fail "#388 管道測試跳過（SKILL.md 不存在）"
fi

# 9.11 pipeline.md 含管道三階段
if [ -f "$PIPELINE_REF" ]; then
  PIPELINE_CONTENT=$(cat "$PIPELINE_REF")
  assert_contains "$PIPELINE_CONTENT" "階段 1：test" "pipeline.md 含 test 階段"
  assert_contains "$PIPELINE_CONTENT" "階段 2：review" "pipeline.md 含 review 階段"
  assert_contains "$PIPELINE_CONTENT" "階段 3：PR" "pipeline.md 含 PR 階段"
  assert_contains "$PIPELINE_CONTENT" "HARD-GATE" "pipeline.md 含 HARD-GATE 宣告"
  assert_contains "$PIPELINE_CONTENT" "回退修復機制" "pipeline.md 含回退修復機制說明"
else
  fail "#388 pipeline.md 內容測試跳過（檔案不存在）"
fi

# ---------------------------------------------------------------------------
# 總結
# ---------------------------------------------------------------------------
echo ""
echo "========================================="
echo "測試結果：PASS=${PASS_COUNT}  FAIL=${FAIL_COUNT}"
echo "========================================="

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
else
  exit 0
fi
