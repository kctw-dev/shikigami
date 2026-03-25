#!/usr/bin/env bash
# scripts/injection-scan.sh — Prompt Injection Defense Scanner
# Story #776 (Sprint 161) | ADR-006 延伸
#
# Usage: bash scripts/injection-scan.sh <input-file>
# Output: PASS / WARN / BLOCK (last line)
# Exit code: 0=PASS, 1=WARN, 2=BLOCK
#
# Rules source: docs/security/INJECTION_RULES.md (operator-configurable)

set -u

INPUT_FILE="${1:-}"
RULES_FILE="$(dirname "$0")/../docs/security/INJECTION_RULES.md"

# Validate input
if [[ -z "$INPUT_FILE" ]]; then
  echo "[INJECTION-SCAN-ERROR] Usage: injection-scan.sh <input-file>" >&2
  echo "BLOCK"
  exit 2
fi
if [[ ! -f "$INPUT_FILE" ]]; then
  echo "[INJECTION-SCAN-ERROR] Input file not found: $INPUT_FILE" >&2
  echo "BLOCK"
  exit 2
fi

CONTENT=$(cat "$INPUT_FILE")
RESULT="PASS"
FINDINGS=()

# ── HIGH RISK Patterns ──
# HR-001: ignore previous/all instructions
if echo "$CONTENT" | grep -iqE "ignore (previous|all) instructions"; then
  FINDINGS+=("[INJECTION-GATE] HR-001: role override — ignore instructions")
  RESULT="BLOCK"
fi

# HR-002: you are now a different agent / act as superuser
if echo "$CONTENT" | grep -iqE "you are now (a different|an )|act as (root|admin|superuser)"; then
  FINDINGS+=("[INJECTION-GATE] HR-002: role override — impersonation")
  RESULT="BLOCK"
fi

# HR-003: disregard system prompt / forget everything
if echo "$CONTENT" | grep -iqE "disregard your (system prompt|instructions)|forget (everything|all)"; then
  FINDINGS+=("[INJECTION-GATE] HR-003: role override — context reset")
  RESULT="BLOCK"
fi

# HR-004: framework administrator
if echo "$CONTENT" | grep -iqE "as (a )?framework (administrator|admin)"; then
  FINDINGS+=("[INJECTION-GATE] HR-004: privilege escalation — framework admin claim")
  RESULT="BLOCK"
fi

# HR-005: bypass/override gate
if echo "$CONTENT" | grep -iqE "(authorize|grant) you to (skip|bypass|override)"; then
  FINDINGS+=("[INJECTION-GATE] HR-005: privilege escalation — gate bypass")
  RESULT="BLOCK"
fi

# HR-006: sudo / escalate privilege
if echo "$CONTENT" | grep -iqE "\bsudo\b|escalate privilege"; then
  FINDINGS+=("[INJECTION-GATE] HR-006: privilege escalation — sudo/escalate")
  RESULT="BLOCK"
fi

# HR-007: pretend you have no rules/guidelines
if echo "$CONTENT" | grep -iqE "pretend you have no (rules|safety guidelines|restrictions|instructions)"; then
  FINDINGS+=("[INJECTION-GATE] HR-007: role override — rule nullification")
  RESULT="BLOCK"
fi

# HR-008: reveal system instructions
if echo "$CONTENT" | grep -iqE "reveal your (system instructions|system prompt|instructions to me)"; then
  FINDINGS+=("[INJECTION-GATE] HR-008: info extraction — reveal instructions")
  RESULT="BLOCK"
fi

# ── MEDIUM RISK Patterns (only escalate if no HIGH already) ──
if [[ "$RESULT" != "BLOCK" ]]; then
  # MR-001: list internal files
  if echo "$CONTENT" | grep -iqE "list all files|show me (your|the) (skill|system|config)"; then
    FINDINGS+=("[INJECTION-WARN] MR-001: info extraction — list files")
    RESULT="WARN"
  fi

  # MR-002: output system prompt
  if echo "$CONTENT" | grep -iqE "output (the system prompt|your prompt|your instructions)"; then
    FINDINGS+=("[INJECTION-WARN] MR-002: info extraction — output prompt")
    RESULT="WARN"
  fi

  # MR-003: summarize ADR or SKILL.md
  if echo "$CONTENT" | grep -iqE "summarize (each )?ADR|summarize.*SKILL\.md"; then
    FINDINGS+=("[INJECTION-WARN] MR-003: info extraction — summarize internals")
    RESULT="WARN"
  fi

  # MR-004: suspicious base64 (20+ chars pure base64)
  if echo "$CONTENT" | grep -qE "[A-Za-z0-9+/]{20,}={0,2}"; then
    FINDINGS+=("[INJECTION-WARN] MR-004: hidden payload — base64 content")
    RESULT="WARN"
  fi

  # MR-005: pretend/roleplay as developer
  if echo "$CONTENT" | grep -iqE "pretend you are|roleplay as (a )?developer"; then
    FINDINGS+=("[INJECTION-WARN] MR-005: role confusion — developer roleplay")
    RESULT="WARN"
  fi

  # MR-006: enter sudo mode
  if echo "$CONTENT" | grep -iqE "enter (sudo|elevated|admin) mode"; then
    FINDINGS+=("[INJECTION-WARN] MR-006: privilege escalation — mode switch")
    RESULT="WARN"
  fi
fi

# Output findings
for finding in "${FINDINGS[@]}"; do
  echo "$finding"
done

# Final result (always last line — AC1 spec)
echo "$RESULT"

# Exit code
case "$RESULT" in
  PASS)  exit 0 ;;
  WARN)  exit 1 ;;
  BLOCK) exit 2 ;;
esac
