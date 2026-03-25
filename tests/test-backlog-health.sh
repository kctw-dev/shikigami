#!/usr/bin/env bash
# Test #698: Backlog 健康度自動檢查 — sprint-candidate < 8 觸發補充信號
# AC1: Sprint Review Skill 加入 Backlog 健康度檢查步驟
# AC2: sprint-candidate < 8 時輸出 [BACKLOG-REPLENISH-TRIGGER] 信號
# AC4: cruise 日誌記錄 backlog-health entry
# AC5: gh API 失敗時降級為 [WARN]
# NFR2: 閾值可配置（shikigami.local.md）

set -euo pipefail

PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"
  if [ "$result" = "0" ]; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Test #698: Backlog 健康度自動檢查 ==="

# Test 1: Verify shikigami.local.md has backlog_health config
CONFIG_FILE=".claude/shikigami.local.md"
if [[ -f "$CONFIG_FILE" ]]; then
  grep -q "backlog_health:" "$CONFIG_FILE"
  check "CONFIG: backlog_health section exists" $?

  grep "backlog_health:" -A 1 "$CONFIG_FILE" | grep -q "threshold:"
  check "CONFIG: threshold setting exists in backlog_health" $?
fi

# Test 2: Verify Sprint Review SKILL.md includes backlog health check reference
SKILL_FILE="skills/sprint-review/SKILL.md"
if [[ -f "$SKILL_FILE" ]]; then
  # Should reference backlog health check
  grep -q "健康度" "$SKILL_FILE"
  check "SKILL: sprint-review mentions backlog health" $?

  # Should mention the check happens after issue writeback
  grep -q "§2.6" "$SKILL_FILE"
  check "SKILL: issue writeback reference (§2.6) exists" $?
  
  # Should have section 2.7
  grep -q "## 2.7" "$SKILL_FILE"
  check "SKILL: section 2.7 (backlog health) exists" $?
fi

# Test 3: Verify log-format.md includes backlog-health entry type
LOG_FORMAT_FILE="skills/cruise/references/log-format.md"
if [[ -f "$LOG_FORMAT_FILE" ]]; then
  grep -q "backlog-health" "$LOG_FORMAT_FILE"
  check "LOG-FORMAT: backlog-health entry type defined" $?

  grep -q "sprint_candidate_count" "$LOG_FORMAT_FILE"
  check "LOG-FORMAT: sprint_candidate_count field exists" $?

  grep -q "threshold" "$LOG_FORMAT_FILE"
  check "LOG-FORMAT: threshold field exists" $?
fi

# Test 4: Verify po-patrol.md mentions backlog health check and signal consumption
PO_PATROL_FILE="skills/cruise/references/po-patrol.md"
if [[ -f "$PO_PATROL_FILE" ]]; then
  grep -q "BACKLOG-REPLENISH-TRIGGER" "$PO_PATROL_FILE"
  check "PO-PATROL: [BACKLOG-REPLENISH-TRIGGER] signal mentioned" $?

  grep -q "project_level" "$PO_PATROL_FILE"
  check "PO-PATROL: project_level behavior reference exists" $?
  
  grep -q "Step 5.6" "$PO_PATROL_FILE"
  check "PO-PATROL: section 5.6 (backlog health) exists" $?
fi

# Test 5: Verify trigger signal format in sprint-review SKILL.md
if [[ -f "$SKILL_FILE" ]]; then
  grep -q "BACKLOG-REPLENISH-TRIGGER" "$SKILL_FILE"
  check "SKILL: [BACKLOG-REPLENISH-TRIGGER] signal format documented" $?
fi

# Test 6: JSONL format validation - verify backlog-health entry fields
# This checks that the definition is well-formed
if [[ -f "$LOG_FORMAT_FILE" ]]; then
  # Should have example with sprint_candidate_count
  grep -A 2 "backlog-health" "$LOG_FORMAT_FILE" | grep -q "sprint_candidate_count"
  check "JSONL: backlog-health example has sprint_candidate_count" $?

  # Example should include timestamp, type, repo fields
  grep "backlog-health" "$LOG_FORMAT_FILE" | grep -q "timestamp"
  check "JSONL: backlog-health example has timestamp" $?
fi

# Test 7: Verify AC5 (non-blocking degradation) is documented
if [[ -f "$SKILL_FILE" ]]; then
  grep -q "BACKLOG-HEALTH-WARN" "$SKILL_FILE"
  check "SKILL: AC5 [BACKLOG-HEALTH-WARN] degradation documented" $?
fi

# Test 8: Verify log entry includes both sprint_candidate_count and threshold
if [[ -f "$LOG_FORMAT_FILE" ]]; then
  grep '"type":"backlog-health"' "$LOG_FORMAT_FILE" | grep -q '"sprint_candidate_count"'
  check "JSONL: log entry has sprint_candidate_count field" $?
  
  grep '"type":"backlog-health"' "$LOG_FORMAT_FILE" | grep -q '"threshold"'
  check "JSONL: log entry has threshold field" $?
  
  grep '"type":"backlog-health"' "$LOG_FORMAT_FILE" | grep -q '"signal"'
  check "JSONL: log entry has signal field" $?
fi

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "All tests passed."
