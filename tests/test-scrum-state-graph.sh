#!/usr/bin/env bash
# tests/test-scrum-state-graph.sh — Scrum Master 狀態圖 AC3 validation
# AC3: validates graph file exists and contains all 5 states

set -u
PASS=0
FAIL=0

# AC1: State graph file exists (check existing scrum-master-state-graph.md)
test_file_exists() {
  if [[ -f "docs/sdd/scrum-master-state-graph.md" ]]; then
    echo "PASS: AC1 docs/sdd/scrum-master-state-graph.md exists"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC1 docs/sdd/scrum-master-state-graph.md not found"
    FAIL=$((FAIL+1))
  fi
}

# AC1: Contains stateDiagram (Mermaid format for agent consumption)
test_mermaid_format() {
  if grep -q "stateDiagram" docs/sdd/scrum-master-state-graph.md 2>/dev/null; then
    echo "PASS: AC1 stateDiagram format present (agent-consumable Mermaid)"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC1 stateDiagram format missing"
    FAIL=$((FAIL+1))
  fi
}

# AC3: Contains all 5 core Sprint lifecycle states
test_state_backlog() {
  if grep -qi "Backlog\|backlog" docs/sdd/scrum-master-state-graph.md 2>/dev/null; then
    echo "PASS: AC3 state: Backlog present"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC3 state: Backlog missing"
    FAIL=$((FAIL+1))
  fi
}

test_state_planning() {
  if grep -qi "Planning\|planning" docs/sdd/scrum-master-state-graph.md 2>/dev/null; then
    echo "PASS: AC3 state: Planning present"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC3 state: Planning missing"
    FAIL=$((FAIL+1))
  fi
}

test_state_execution() {
  if grep -qi "Execution\|execution" docs/sdd/scrum-master-state-graph.md 2>/dev/null; then
    echo "PASS: AC3 state: Execution present"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC3 state: Execution missing"
    FAIL=$((FAIL+1))
  fi
}

test_state_review() {
  if grep -qi "Review\|review" docs/sdd/scrum-master-state-graph.md 2>/dev/null; then
    echo "PASS: AC3 state: Review present"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC3 state: Review missing"
    FAIL=$((FAIL+1))
  fi
}

test_state_retro() {
  if grep -qi "Retrospective\|retrospective\|Retro" docs/sdd/scrum-master-state-graph.md 2>/dev/null; then
    echo "PASS: AC3 state: Retrospective present"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC3 state: Retrospective missing"
    FAIL=$((FAIL+1))
  fi
}

# AC2: scrum-master SKILL.md or agents/scrum-master.md references the state graph
test_skill_reference() {
  if grep -q "scrum-master-state-graph\|state-graph\|state_graph\|SDD.*scrum\|stateDiagram" \
      skills/scrum-master/SKILL.md 2>/dev/null || \
     grep -q "scrum-master-state-graph\|state-graph\|sdd.*scrum" \
      agents/scrum-master.md 2>/dev/null; then
    echo "PASS: AC2 scrum-master references state graph"
    PASS=$((PASS+1))
  else
    echo "FAIL: AC2 scrum-master SKILL.md/agents/scrum-master.md missing state graph reference"
    FAIL=$((FAIL+1))
  fi
}

test_file_exists
test_mermaid_format
test_state_backlog
test_state_planning
test_state_execution
test_state_review
test_state_retro
test_skill_reference

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL Total=$((PASS+FAIL))"
[[ $FAIL -eq 0 ]]
