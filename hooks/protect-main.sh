#!/usr/bin/env bash
# protect-main.sh — US-315 AC-2 PreToolUse hook：禁止直推 main
#
# 攔截邏輯：
#   - 攔截 git push origin main
#   - 攔截 git push origin HEAD:main
#   - 攔截當前在 main branch 時執行的裸 git push
#
# 豁免清單（ADR-023 決策 2 + 決策 3，US-315 AC-2/AC-5/AC-6；US-317 P2 AC-5）：
#   1. push 目標為 refs/claims/（#312 機制）
#   2. push --tags 或 push origin v*（版本標籤）
#   3. 所有 staged/committed 檔案均屬豁免路徑（狀態文件，ADR-023 決策 3）
#      豁免路徑：
#        docs/sprints/**（含 sprint-checkpoint.json、sprint.live.log、subagent-results/）
#        docs/PROJECT_BOARD.md
#        docs/attendance/**（出勤紀錄，ADR-024 決策）
#        docs/exploration/**（探索紀錄，ADR-025 決策）
#
# 使用方式：由 hooks.json PreToolUse hook 呼叫
#   CLAUDE_TOOL_INPUT（JSON）提供 command 欄位
#   STAGED_FILES（選填）：覆寫自動偵測的 staged 檔案清單（測試用途）

set -euo pipefail

# ── 讀取指令 ────────────────────────────────────────────────────────────────
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
if [[ -z "$TOOL_INPUT" ]]; then
  exit 0
fi

# 從 JSON 解析 command 欄位（支援 jq 與 POSIX sed 兩種方式）
CMD=""
PARSE_WARN=false
if command -v jq &>/dev/null; then
  # #16 修復：jq 解析失敗時偵測並輸出 WARN
  # 使用 || true 防止 set -e 觸發，再檢查輸出是否有效
  JQ_OUT=$(echo "$TOOL_INPUT" | jq -r '.command // ""' 2>/dev/null || echo "__JQ_PARSE_ERROR__")
  if [[ "$JQ_OUT" == "__JQ_PARSE_ERROR__" ]]; then
    PARSE_WARN=true
  else
    CMD="$JQ_OUT"
  fi
else
  # #10 修復：改用 POSIX sed（macOS 不支援 grep 的 Perl regex 模式）
  CMD=$(echo "$TOOL_INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null | head -1 || echo "")
  if [[ -z "$CMD" ]]; then
    PARSE_WARN=true
  fi
fi

if [[ "$PARSE_WARN" == "true" ]]; then
  # AC-17 修復（DISPUTE）：malformed JSON 無法判斷指令是否為 git push main
  # 保守策略應為「拒絕」而非「放行」，以防止誤推 main
  echo "[WARN] protect-main.sh: JSON 解析失敗，保守拒絕操作（無法確認指令安全性）" >&2
  exit 1
fi

if [[ -z "$CMD" ]]; then
  exit 0
fi

# ── 只關心 git push 指令 ─────────────────────────────────────────────────
if ! echo "$CMD" | grep -qE '^\s*git\s+push'; then
  exit 0
fi

# ── 豁免 1：refs/claims/ push ────────────────────────────────────────────
if echo "$CMD" | grep -qE 'refs/claims/'; then
  exit 0
fi

# ── 豁免 2：tag push（--tags 或 v*.* 格式）──────────────────────────────
if echo "$CMD" | grep -qE '(--tags|push origin v[0-9])'; then
  exit 0
fi

# ── 判定是否為直推 main ──────────────────────────────────────────────────
IS_PUSH_MAIN=false

# 明確指定 origin main
if echo "$CMD" | grep -qE 'git\s+push\s+.*origin\s+main(\s|$)'; then
  IS_PUSH_MAIN=true
fi

# HEAD:main
if echo "$CMD" | grep -qE 'HEAD:main'; then
  IS_PUSH_MAIN=true
fi

# 裸 git push（無分支參數）且當前在 main
if [[ "$IS_PUSH_MAIN" == "false" ]]; then
  if echo "$CMD" | grep -qE '^\s*git\s+push\s*(origin\s*)?$'; then
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [[ "$CURRENT_BRANCH" == "main" ]]; then
      IS_PUSH_MAIN=true
    fi
  fi
fi

# 非直推 main → 放行
if [[ "$IS_PUSH_MAIN" == "false" ]]; then
  exit 0
fi

# ── 豁免 3：狀態文件豁免（ADR-023 決策 3，AC-5/AC-6）────────────────────
# 豁免路徑模式（ERE）
EXEMPT_PATTERNS=(
  "^docs/sprints/"
  "^docs/PROJECT_BOARD\.md$"
  "^docs/attendance/"
  "^docs/exploration/"
)

# 取得 staged/committed 檔案清單
# 優先使用 STAGED_FILES 環境變數（測試用途），否則從 git 取得
if [[ -n "${STAGED_FILES:-}" ]]; then
  FILE_LIST="$STAGED_FILES"
else
  # 嘗試取得 staged 檔案（已加入 index 但未 commit 的）
  STAGED=$(git diff --cached --name-only 2>/dev/null || echo "")
  # 嘗試取得最近 commit 的檔案（已 commit 但未 push 的）
  UNPUSHED=$(git diff @{u}...HEAD --name-only 2>/dev/null || git diff origin/main...HEAD --name-only 2>/dev/null || echo "")
  FILE_LIST=$(printf '%s\n%s' "$STAGED" "$UNPUSHED" | sort -u | grep -v '^$' | tr '\n' ' ' || true)
fi

# trim whitespace
FILE_LIST=$(echo "$FILE_LIST" | xargs 2>/dev/null || echo "")

if [[ -n "$FILE_LIST" ]]; then
  ALL_EXEMPT=true
  for f in $FILE_LIST; do
    [[ -z "$f" ]] && continue
    FILE_EXEMPT=false
    for pattern in "${EXEMPT_PATTERNS[@]}"; do
      if echo "$f" | grep -qE "$pattern"; then
        FILE_EXEMPT=true
        break
      fi
    done
    if [[ "$FILE_EXEMPT" == "false" ]]; then
      ALL_EXEMPT=false
      break
    fi
  done
  if [[ "$ALL_EXEMPT" == "true" ]]; then
    exit 0
  fi
fi

# ── 攔截輸出 ─────────────────────────────────────────────────────────────
echo "[MAIN-PROTECT] 禁止直推 main。請建立 feature branch 並透過 PR 合併。"
echo "  指令：$CMD"
echo "  Branch 命名規則："
echo "    Sprint Story:  sprint-<N>/<story-id>   （例：sprint-102/US-315）"
echo "    Shoot 任務:    shoot/<issue-or-desc>    （例：shoot/320）"
echo "  流程：git checkout -b <branch> → commit → git push -u origin <branch> → gh pr create"
echo "  豁免清單（可直推 main）："
echo "    - docs/sprints/**（含 sprint-checkpoint.json、sprint.live.log、subagent-results/）"
echo "    - docs/PROJECT_BOARD.md"
echo "    - docs/attendance/**（出勤紀錄，ADR-024）"
echo "    - docs/exploration/**（探索紀錄，ADR-025）"
echo "    - refs/claims/ push（#312 機制）"
echo "    - tag push（--tags 或 v* 格式）"
exit 1
