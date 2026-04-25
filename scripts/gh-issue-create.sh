#!/usr/bin/env bash
# scripts/gh-issue-create.sh
# Issue #1001 (Sprint 182 Retro A1)：強制 --body-file 模式封裝 gh issue create
#
# 解決問題：直接以 --body "..." 傳入含冒號/星號/引號等特殊字元時，
# YAML / shell 解譯會截斷或破壞 body（CLAUDE.md 紅線 #13；Sprint 135 #597、
# Sprint 182 #994/#995/#996 歷史案例）。
#
# 用法：
#   bash scripts/gh-issue-create.sh \
#     --title "Issue 標題" \
#     --body  "Issue 內容（可含 :、*、'、\"、` 等特殊字元）" \
#     [--repo OWNER/REPO]   [--label L1,L2]   [--milestone N] \
#     [--assignee USER]     [--body-file FILE] [--dry-run]
#
# 參數規則：
#   --body 與 --body-file 互斥；亦可改用 stdin（將 body 由 pipe 傳入時自動偵測）
#   未指定 --repo 時沿用當前 git repo 的設定
#
# Exit code:
#   0 = 建立成功（或 dry-run 通過）
#   1 = 參數錯誤 / gh 呼叫失敗

set -euo pipefail

readonly SCRIPT_NAME="gh-issue-create.sh"

usage() {
  cat <<'EOF'
用法：bash scripts/gh-issue-create.sh --title TITLE (--body BODY | --body-file FILE | -)
                                       [--repo OWNER/REPO] [--label LABELS]
                                       [--milestone N] [--assignee USERS]
                                       [--dry-run]

必要參數：
  --title TITLE         Issue 標題
  --body  BODY          Issue 內容（字串）
  --body-file FILE      Issue 內容（從檔案讀入）
  -                     從 stdin 讀入 body（與 --body / --body-file 三選一）

選用參數：
  --repo  OWNER/REPO    指定 repo（預設沿用當前 git repo）
  --label LABELS        逗號分隔的 labels
  --milestone N         milestone 編號或名稱
  --assignee USERS      逗號分隔的 GitHub 帳號
  --dry-run             僅顯示將寫入暫存檔的 body 與將呼叫的 gh 指令，不實際建立
  -h, --help            顯示此說明
EOF
}

die() { echo "[ERROR] $*" >&2; exit 1; }

# require_value <flag-name> <remaining-arg-count>
# 避免缺值參數在 set -uo pipefail（無 -e）下使 shift 2 失敗導致無限迴圈
require_value() {
  local flag="$1" remaining="$2"
  [[ "$remaining" -ge 2 ]] || die "$flag requires a value"
}

# ---------------------------------------------------------------------------
# 參數解析
# ---------------------------------------------------------------------------
TITLE=""
BODY=""
BODY_FILE=""
READ_STDIN=0
REPO=""
LABEL=""
MILESTONE=""
ASSIGNEE=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)      require_value --title "$#";     TITLE="$2";     shift 2 ;;
    --body)       require_value --body "$#";      BODY="$2";      shift 2 ;;
    --body-file)  require_value --body-file "$#"; BODY_FILE="$2"; shift 2 ;;
    -)            READ_STDIN=1; shift ;;
    --repo)       require_value --repo "$#";      REPO="$2";      shift 2 ;;
    --label)      require_value --label "$#";     LABEL="$2";     shift 2 ;;
    --milestone)  require_value --milestone "$#"; MILESTONE="$2"; shift 2 ;;
    --assignee)   require_value --assignee "$#";  ASSIGNEE="$2";  shift 2 ;;
    --dry-run)    DRY_RUN=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *)            die "未知參數：$1（-h 查看用法）" ;;
  esac
done

# ---------------------------------------------------------------------------
# 參數驗證
# ---------------------------------------------------------------------------
[[ -n "$TITLE" ]] || die "缺少必要參數 --title"

# body 來源三選一
sources=0
[[ -n "$BODY" ]] && sources=$((sources + 1))
[[ -n "$BODY_FILE" ]] && sources=$((sources + 1))
[[ "$READ_STDIN" -eq 1 ]] && sources=$((sources + 1))
if [[ "$sources" -ne 1 ]]; then
  die "需且僅需指定一種 body 來源：--body / --body-file / -（stdin）"
fi

if [[ -n "$BODY_FILE" && ! -r "$BODY_FILE" ]]; then
  die "--body-file 指定的檔案不存在或無法讀取：$BODY_FILE"
fi

# 僅在「實際呼叫 gh」時才需要 gh — dry-run 純預覽不需要（codex review P3）
if [[ "$DRY_RUN" -ne 1 ]]; then
  command -v gh >/dev/null 2>&1 || die "找不到 gh CLI，請先安裝 GitHub CLI"
fi

# ---------------------------------------------------------------------------
# 寫入暫存檔（核心安全機制）
# ---------------------------------------------------------------------------
TMP_BODY="$(mktemp -t gh-issue-body.XXXXXX)"
trap 'rm -f "$TMP_BODY"' EXIT INT TERM

if [[ -n "$BODY" ]]; then
  # 使用 printf 而非 echo，避免 -n / -e 等內容被解譯
  printf '%s' "$BODY" > "$TMP_BODY"
elif [[ -n "$BODY_FILE" ]]; then
  cat "$BODY_FILE" > "$TMP_BODY"
else
  # stdin
  cat > "$TMP_BODY"
fi

# 確保檔尾有換行（gh 有時對缺尾行的檔案行為不一致）
if [[ -s "$TMP_BODY" ]] && [[ "$(tail -c1 "$TMP_BODY" | wc -l | tr -d ' ')" -eq 0 ]]; then
  printf '\n' >> "$TMP_BODY"
fi

# ---------------------------------------------------------------------------
# 組裝 gh 指令
# ---------------------------------------------------------------------------
GH_ARGS=(issue create --title "$TITLE" --body-file "$TMP_BODY")
[[ -n "$REPO" ]]      && GH_ARGS+=(--repo "$REPO")
[[ -n "$LABEL" ]]     && GH_ARGS+=(--label "$LABEL")
[[ -n "$MILESTONE" ]] && GH_ARGS+=(--milestone "$MILESTONE")
[[ -n "$ASSIGNEE" ]]  && GH_ARGS+=(--assignee "$ASSIGNEE")

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[DRY-RUN] 暫存 body 檔案：$TMP_BODY"
  echo "[DRY-RUN] body 大小：$(wc -c < "$TMP_BODY") bytes"
  echo "[DRY-RUN] body 內容："
  echo "----- BEGIN BODY -----"
  cat "$TMP_BODY"
  echo "----- END BODY -----"
  echo "[DRY-RUN] 將呼叫："
  printf '  gh'
  for a in "${GH_ARGS[@]}"; do printf ' %q' "$a"; done
  printf '\n'
  exit 0
fi

# ---------------------------------------------------------------------------
# 實際呼叫 gh
# ---------------------------------------------------------------------------
gh "${GH_ARGS[@]}"
