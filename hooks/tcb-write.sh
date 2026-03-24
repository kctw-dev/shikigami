#!/usr/bin/env bash
# tcb-write.sh — TCB（Thread Control Block）斷點管理（ADR-040）
#
# 用途：記錄 Agent Action 級 Checkpoint，支援細粒度 Sprint 斷點與恢復
# 設計原則：best-effort（寫入失敗不阻塞主流程），純 shell + file-based
#
# 子命令：
#   init {sprint} {session_id} {story_id}
#       初始化 session TCB 目錄 + index.json
#       建立 docs/sprints/tcb/sprint-{sprint}/session-{session_id}/
#
#   start {sprint} {session_id} {story_id} {action} [{depends_on}]
#       記錄 action 開始（status=running）
#       輸出：tcb_id（如 404-act-1），供 complete 子命令引用
#
#   complete {sprint} {session_id} {tcb_id} [{output_ref}]
#       更新 TCB status=completed，填入 output_ref 與 completed_at
#
#   fail {sprint} {session_id} {tcb_id} [{error_msg}]
#       更新 TCB status=failed，填入 error 與 completed_at
#
#   resume {sprint} {session_id}
#       查詢恢復狀態：輸出 status=failed 或 status=running 的 tcb_id 清單
#       SM 重啟時使用，判斷從哪個 action 繼續
#
# Story: #404 Sprint 139
# ADR: docs/adr/ADR-040-tcb-checkpoint-design.md

# best-effort：任何 trap/set -e 皆不阻塞主流程
set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
AGENT="${SHIKIGAMI_AGENT:-scrum-master}"
SESSION_ID="${SHIKIGAMI_SESSION_ID:-unknown}"

# ── 工具函式 ──────────────────────────────────────────────

_tcb_dir() {
  local sprint="$1"
  local session="$2"
  echo "${REPO_ROOT}/docs/sprints/tcb/sprint-${sprint}/session-${session}"
}

_tcb_log() {
  echo "[TCB] $*" >&2
}

_tcb_error() {
  echo "[TCB-WARN] $*" >&2
}

_now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ
}

_sha256_digest() {
  local input="$1"
  # 取前 16 碼作為 digest
  echo -n "$input" | sha256sum 2>/dev/null | cut -c1-16 || echo "xxxxxxxxxxxxxxxx"
}

# 自增序號：讀取 index.json 的 action_count，回傳下一個序號
_next_seq() {
  local tcb_dir="$1"
  local story_id="$2"
  local index_file="${tcb_dir}/index.json"

  if [ -f "$index_file" ]; then
    local count
    count=$(python3 -c "import json; d=json.load(open('${index_file}')); print(d.get('action_count', 0))" 2>/dev/null || echo "0")
    echo $((count + 1))
  else
    echo 1
  fi
}

# 更新 index.json 的 action_count
_update_index_count() {
  local tcb_dir="$1"
  local new_count="$2"
  local index_file="${tcb_dir}/index.json"

  if [ -f "$index_file" ]; then
    python3 -c "
import json
f = '${index_file}'
d = json.load(open(f))
d['action_count'] = ${new_count}
json.dump(d, open(f, 'w'), indent=2, ensure_ascii=False)
" 2>/dev/null || _tcb_error "failed to update index action_count"
  fi
}

# ── 子命令：init ──────────────────────────────────────────

cmd_init() {
  local sprint="${1:?sprint required}"
  local session="${2:?session_id required}"
  local story_id="${3:?story_id required}"

  local tcb_dir
  tcb_dir="$(_tcb_dir "$sprint" "$session")"

  mkdir -p "$tcb_dir" 2>/dev/null || { _tcb_error "cannot create TCB dir: $tcb_dir"; return 0; }

  local index_file="${tcb_dir}/index.json"
  if [ ! -f "$index_file" ]; then
    python3 -c "
import json
data = {
    'sprint': ${sprint},
    'session_id': '${session}',
    'created_at': '$(_now_iso)',
    'action_count': 0,
    'stories': ['${story_id}'],
    'tcb_entries': []
}
json.dump(data, open('${index_file}', 'w'), indent=2, ensure_ascii=False)
" 2>/dev/null || _tcb_error "cannot write index.json"
    _tcb_log "init sprint=${sprint} session=${session} story=${story_id}"
  else
    # Append story to existing index if not already present
    python3 -c "
import json
f = '${index_file}'
d = json.load(open(f))
if '${story_id}' not in d.get('stories', []):
    d.setdefault('stories', []).append('${story_id}')
    json.dump(d, open(f, 'w'), indent=2, ensure_ascii=False)
" 2>/dev/null || true
    _tcb_log "init (session exists) sprint=${sprint} session=${session} story=${story_id}"
  fi
}

# ── 子命令：start ─────────────────────────────────────────

cmd_start() {
  local sprint="${1:?sprint required}"
  local session="${2:?session_id required}"
  local story_id="${3:?story_id required}"
  local action="${4:?action required}"
  local depends_on="${5:-}"

  local tcb_dir
  tcb_dir="$(_tcb_dir "$sprint" "$session")"
  mkdir -p "$tcb_dir" 2>/dev/null || { _tcb_error "cannot create TCB dir"; return 0; }

  local seq
  seq="$(_next_seq "$tcb_dir" "$story_id")"
  local tcb_id="${story_id}-act-${seq}"
  local tcb_file="${tcb_dir}/${tcb_id}.json"
  local input_digest
  input_digest="$(_sha256_digest "${story_id}:${action}:${seq}")"

  python3 -c "
import json
data = {
    'tcb_id': '${tcb_id}',
    'story_id': '${story_id}',
    'sprint': ${sprint},
    'session_id': '${session}',
    'agent': '${AGENT}',
    'action': '${action}',
    'status': 'running',
    'depends_on': [x for x in '${depends_on}'.split(',') if x],
    'input_digest': '${input_digest}',
    'output_ref': '',
    'started_at': '$(_now_iso)',
    'completed_at': '',
    'error': ''
}
json.dump(data, open('${tcb_file}', 'w'), indent=2, ensure_ascii=False)
" 2>/dev/null || { _tcb_error "cannot write TCB start: $tcb_id"; echo "$tcb_id"; return 0; }

  # Update index count
  _update_index_count "$tcb_dir" "$seq"

  # Append to index entries
  python3 -c "
import json
f = '${tcb_dir}/index.json'
if not __import__('os').path.exists(f):
    d = {'sprint': ${sprint}, 'session_id': '${session}', 'action_count': ${seq}, 'stories': ['${story_id}'], 'tcb_entries': []}
else:
    d = json.load(open(f))
d.setdefault('tcb_entries', []).append({'tcb_id': '${tcb_id}', 'story_id': '${story_id}', 'action': '${action}', 'status': 'running'})
d['action_count'] = ${seq}
json.dump(d, open(f, 'w'), indent=2, ensure_ascii=False)
" 2>/dev/null || true

  _tcb_log "start tcb_id=${tcb_id} action=${action}"
  echo "$tcb_id"  # Output tcb_id for caller to reference
}

# ── 子命令：complete ──────────────────────────────────────

cmd_complete() {
  local sprint="${1:?sprint required}"
  local session="${2:?session_id required}"
  local tcb_id="${3:?tcb_id required}"
  local output_ref="${4:-}"

  local tcb_dir
  tcb_dir="$(_tcb_dir "$sprint" "$session")"
  local tcb_file="${tcb_dir}/${tcb_id}.json"

  if [ ! -f "$tcb_file" ]; then
    _tcb_error "TCB file not found: $tcb_id"
    return 0  # best-effort
  fi

  python3 -c "
import json
f = '${tcb_file}'
d = json.load(open(f))
d['status'] = 'completed'
d['output_ref'] = '${output_ref}'
d['completed_at'] = '$(_now_iso)'
json.dump(d, open(f, 'w'), indent=2, ensure_ascii=False)
" 2>/dev/null || { _tcb_error "cannot update TCB complete: $tcb_id"; return 0; }

  # Update index entry status
  python3 -c "
import json
f = '${tcb_dir}/index.json'
if __import__('os').path.exists(f):
    d = json.load(open(f))
    for e in d.get('tcb_entries', []):
        if e.get('tcb_id') == '${tcb_id}':
            e['status'] = 'completed'
    json.dump(d, open(f, 'w'), indent=2, ensure_ascii=False)
" 2>/dev/null || true

  _tcb_log "complete tcb_id=${tcb_id} output_ref=${output_ref}"
}

# ── 子命令：fail ──────────────────────────────────────────

cmd_fail() {
  local sprint="${1:?sprint required}"
  local session="${2:?session_id required}"
  local tcb_id="${3:?tcb_id required}"
  local error_msg="${4:-unknown error}"

  local tcb_dir
  tcb_dir="$(_tcb_dir "$sprint" "$session")"
  local tcb_file="${tcb_dir}/${tcb_id}.json"

  if [ ! -f "$tcb_file" ]; then
    _tcb_error "TCB file not found: $tcb_id"
    return 0
  fi

  python3 -c "
import json
f = '${tcb_file}'
d = json.load(open(f))
d['status'] = 'failed'
d['error'] = '${error_msg}'
d['completed_at'] = '$(_now_iso)'
json.dump(d, open(f, 'w'), indent=2, ensure_ascii=False)
" 2>/dev/null || { _tcb_error "cannot update TCB fail: $tcb_id"; return 0; }

  # Update index
  python3 -c "
import json
f = '${tcb_dir}/index.json'
if __import__('os').path.exists(f):
    d = json.load(open(f))
    for e in d.get('tcb_entries', []):
        if e.get('tcb_id') == '${tcb_id}':
            e['status'] = 'failed'
    json.dump(d, open(f, 'w'), indent=2, ensure_ascii=False)
" 2>/dev/null || true

  _tcb_log "fail tcb_id=${tcb_id} error=${error_msg}"
}

# ── 子命令：resume ────────────────────────────────────────

cmd_resume() {
  local sprint="${1:?sprint required}"
  local session="${2:?session_id required}"

  local tcb_dir
  tcb_dir="$(_tcb_dir "$sprint" "$session")"

  if [ ! -d "$tcb_dir" ]; then
    _tcb_log "resume: no TCB session found for sprint=${sprint} session=${session}"
    echo "[]"
    return 0
  fi

  # Find all TCB files with status=running or status=failed
  python3 -c "
import json, os, glob
tcb_dir = '${tcb_dir}'
incomplete = []
for f in sorted(glob.glob(os.path.join(tcb_dir, '*-act-*.json'))):
    try:
        d = json.load(open(f))
        if d.get('status') in ('running', 'failed', 'pending'):
            incomplete.append({
                'tcb_id': d.get('tcb_id'),
                'story_id': d.get('story_id'),
                'action': d.get('action'),
                'status': d.get('status')
            })
    except Exception:
        pass
print(json.dumps(incomplete, indent=2, ensure_ascii=False))
" 2>/dev/null || echo "[]"
}

# ── 主入口 ────────────────────────────────────────────────

SUBCMD="${1:-}"

# best-effort wrapper：任何錯誤只輸出警告，不退出
{
  case "$SUBCMD" in
    init)
      shift
      cmd_init "$@"
      ;;
    start)
      shift
      cmd_start "$@"
      ;;
    complete)
      shift
      cmd_complete "$@"
      ;;
    fail)
      shift
      cmd_fail "$@"
      ;;
    resume)
      shift
      cmd_resume "$@"
      ;;
    ""|--help|-h)
      echo "Usage: tcb-write.sh <init|start|complete|fail|resume> [args...]"
      echo "  init     {sprint} {session_id} {story_id}"
      echo "  start    {sprint} {session_id} {story_id} {action} [{depends_on}]"
      echo "  complete {sprint} {session_id} {tcb_id} [{output_ref}]"
      echo "  fail     {sprint} {session_id} {tcb_id} [{error_msg}]"
      echo "  resume   {sprint} {session_id}"
      ;;
    *)
      _tcb_error "unknown subcommand: $SUBCMD"
      exit 0  # best-effort: unknown command exits 0
      ;;
  esac
} || true  # best-effort: catch all errors (stderr stays on stderr, not merged)

exit 0  # Always exit 0 (best-effort, AC5)
