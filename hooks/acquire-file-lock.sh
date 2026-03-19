#!/usr/bin/env bash
# acquire-file-lock.sh
# US-311 AC-2/AC-3 — 取得檔案級別鎖定（遠端 ref 互斥鎖 + 本地 flock）
# US-316 — 修復：#4 無鎖模式假陽性、#7 unfetched SHA、#9 local-only 寫 metadata、
#           #11 flock fd redirection、#17 hash fallback WARN
# US-316 DISPUTE — AC-18 修復：路徑長度 fallback 碰撞，改用 base64 路徑編碼
#
# 用法：bash hooks/acquire-file-lock.sh <relative_file_path> [issue_id]
#
# 輸出標記：
#   [FILE-LOCK-OK] refs/file-locks/<hash>        — 成功取得鎖
#   [FILE-LOCK-BLOCKED] refs/file-locks/<hash>   — 已被其他 session 鎖定（含持有者資訊）
#   [FILE-LOCK-STALE] refs/file-locks/<hash>     — stale lock 清除後重新鎖定
#   [FILE-LOCK-DEGRADED] refs/file-locks/<hash>  — 降級模式（無完整互斥保護）
#   [WARN] <原因>                                — 降級警告（不阻塞）
#
# TTL：30 分鐘（1800 秒）
# 失敗不阻塞（set +e / || true）

set +e

REL_PATH="${1:-}"
ISSUE_ID="${2:-}"

if [[ -z "$REL_PATH" ]]; then
  echo "[WARN] acquire-file-lock.sh: 缺少 relative_file_path 參數" >&2
  exit 1
fi

# ── 常數設定 ────────────────────────────────────────────────────────
TTL_SECONDS=1800  # 30 分鐘
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"

# ── Path Hash 計算 ─────────────────────────────────────────────────
# 使用相對路徑計算 sha256，取前 16 字元，確保跨機器一致性
if command -v sha256sum &>/dev/null; then
  HASH=$(echo "$REL_PATH" | sha256sum | cut -c1-16)
elif command -v md5sum &>/dev/null; then
  # macOS fallback：使用 md5sum
  HASH=$(echo "$REL_PATH" | md5sum 2>/dev/null | cut -c1-16)
else
  # AC-18 修復（DISPUTE）：路徑長度 fallback 碰撞（同長度不同路徑），改用 base64 編碼路徑
  echo "[WARN] acquire-file-lock.sh: sha256sum 與 md5sum 均不可用，hash 使用 base64 fallback（鎖不可靠）"
  if command -v base64 &>/dev/null; then
    HASH=$(echo "$REL_PATH" | base64 | tr -d '=/+\n' | cut -c1-16)
  else
    # base64 亦不可用：sanitize 路徑字串直接作為 ref name（去除非 alphanumeric 字元）
    HASH=$(echo "$REL_PATH" | tr -cd 'a-zA-Z0-9_-' | cut -c1-16)
  fi
  # 確保 HASH 非空（極端情況：路徑全為特殊字元）
  if [[ -z "$HASH" ]]; then
    HASH=$(printf '%016d' $$)
  fi
fi

REF="refs/file-locks/${HASH}"

# ── repo fingerprint 計算（本地鎖目錄，兩步法）────────────────────
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
REPO_FP=$(echo "$REPO_ROOT" | sha256sum 2>/dev/null | cut -c1-8 \
         || echo "$REPO_ROOT" | md5sum 2>/dev/null | cut -c1-8 \
         || echo "fallback0")

# ── 本地 metadata 目錄 ────────────────────────────────────────────
META_DIR="/tmp/shikigami-file-locks-${REPO_FP}"
mkdir -p "$META_DIR" 2>/dev/null || true
META_FILE="${META_DIR}/${HASH}.meta"
LOCK_FILE="${META_DIR}/${HASH}.lock"

# ── write_metadata：寫入本地 metadata（acquire_remote 和 local-only 共用）─
write_metadata() {
  local NOW_TS
  NOW_TS=$(date +%s)
  cat > "$META_FILE" 2>/dev/null <<EOF
{
  "session_id": "${SESSION_ID}",
  "path": "${REL_PATH}",
  "issue_id": "${ISSUE_ID}",
  "timestamp": ${NOW_TS},
  "ref": "${REF}",
  "hash": "${HASH}"
}
EOF
}

# ── acquire_remote：遠端 ref 互斥鎖 ──────────────────────────────
acquire_remote() {
  local ISSUE_REF="$REF"

  # Stale lock 偵測：ref 存在超過 TTL_SECONDS → 強制清除後重新 acquire
  EXISTING=$(git ls-remote origin "$ISSUE_REF" 2>/dev/null || echo "")
  if [[ -n "$EXISTING" ]]; then
    # 取得 ref 的 commit 時間
    REF_SHA=$(echo "$EXISTING" | awk '{print $1}')

    # #7 修復：先嘗試 git fetch 取得 commit，避免 unfetched SHA 誤判
    COMMIT_TIME=$(git log -1 --format="%ct" "$REF_SHA" 2>/dev/null)
    if [[ -z "$COMMIT_TIME" ]]; then
      git fetch origin "$REF_SHA" 2>/dev/null || true
      COMMIT_TIME=$(git log -1 --format="%ct" "$REF_SHA" 2>/dev/null)
    fi

    if [[ -z "$COMMIT_TIME" ]]; then
      # #7 修復：SHA 查不到，保守拒絕（不 fallback 為 "0"）
      echo "[WARN] $ISSUE_REF SHA=${REF_SHA} 無法取得 commit 時間，保守拒絕 acquire"
      echo "[FILE-LOCK-BLOCKED] $ISSUE_REF（SHA 未知，保守拒絕）"
      return 1
    fi

    NOW=$(date +%s)
    AGE_SECONDS=$(( NOW - COMMIT_TIME ))
    AGE_MINUTES=$(( AGE_SECONDS / 60 ))

    if [[ $AGE_SECONDS -ge $TTL_SECONDS ]]; then
      # Stale lock：強制清除
      git push origin --delete "$ISSUE_REF" 2>/dev/null || true
      echo "[FILE-LOCK-STALE] $ISSUE_REF 已過期 ${AGE_MINUTES}min，強制清除"
      # 清除後繼續 acquire
    else
      # 讀取 metadata 以顯示鎖持有者資訊
      OWNER_INFO="session=unknown"
      if [[ -f "$META_FILE" ]]; then
        OWNER_SESSION=$(grep '"session_id"' "$META_FILE" 2>/dev/null | sed 's/.*"session_id": *"\([^"]*\)".*/\1/' || echo "unknown")
        OWNER_PATH=$(grep '"path"' "$META_FILE" 2>/dev/null | sed 's/.*"path": *"\([^"]*\)".*/\1/' || echo "unknown")
        OWNER_INFO="session=${OWNER_SESSION} path=${OWNER_PATH}"
      fi
      echo "[FILE-LOCK-BLOCKED] $ISSUE_REF — 已被鎖定（${OWNER_INFO}，age=${AGE_MINUTES}min）"
      return 1
    fi
  fi

  # 推送遠端 ref（原子性：同名 ref 若已存在則失敗）
  git push origin HEAD:"$ISSUE_REF" 2>/dev/null
  local PUSH_EXIT=$?
  if [[ $PUSH_EXIT -ne 0 ]]; then
    echo "[FILE-LOCK-BLOCKED] $ISSUE_REF push 失敗（race condition 或無 remote）"
    return 1
  fi

  # 寫入本地 metadata
  write_metadata

  echo "[FILE-LOCK-OK] $ISSUE_REF"
  return 0
}

# ── 主流程：本地鎖 + 遠端鎖 ──────────────────────────────────────
# 檢查 git remote 是否可用
if ! git ls-remote origin --heads 2>/dev/null | head -1 &>/dev/null; then
  echo "[WARN] git remote 不可用，降級為本地 flock-only 模式"
  # 降級：僅用本地 flock 保護
  if command -v flock &>/dev/null; then
    # #11 修復：使用 fd redirection 取代 flock -c（避免 quoting injection）
    # #9 修復：local-only 模式也寫 metadata
    (
      exec 200>"$LOCK_FILE"
      if flock -n 200; then
        write_metadata
        echo "[FILE-LOCK-DEGRADED] $REF (local-only flock)"
      else
        echo "[FILE-LOCK-BLOCKED] $REF — 本地 flock 取得失敗（local-only 模式）"
      fi
    )
  else
    # 無 flock 且無 remote：最大努力，輸出 DEGRADED（非 OK）
    # #4 修復：無鎖模式改報 [FILE-LOCK-DEGRADED] 而非 [FILE-LOCK-OK]
    echo "[WARN] flock 亦不可用，以無鎖模式繼續（race condition 風險）"
    write_metadata
    echo "[FILE-LOCK-DEGRADED] $REF (no-lock-mode)"
  fi
  exit 0
fi

if command -v flock &>/dev/null; then
  # 有 flock：本地鎖保護競爭窗口 + 遠端鎖
  # #11 修復：使用 fd redirection 取代 flock -c（避免 quoting injection）
  (
    exec 200>"$LOCK_FILE"
    if flock -n 200; then
      acquire_remote
    else
      echo "[FILE-LOCK-BLOCKED] $REF — 本地 flock 取得失敗（本地並行衝突）"
    fi
  )
else
  # 無 flock（macOS）：直接走遠端鎖
  acquire_remote
fi
