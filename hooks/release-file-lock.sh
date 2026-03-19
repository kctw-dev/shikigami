#!/usr/bin/env bash
# release-file-lock.sh
# US-311 AC-2 — 釋放檔案級別鎖定（刪除遠端 ref + 清除本地 metadata）
# US-316 — 修復：#3 遠端確認刪除後才清本地 metadata
#
# 用法：bash hooks/release-file-lock.sh <relative_file_path>
#
# 輸出標記：
#   [FILE-LOCK-RELEASE] refs/file-locks/<hash>   — 成功釋放鎖
#   [WARN] <原因>                                — 降級警告（不阻塞）
#
# 失敗不阻塞（set +e / || true）

set +e

REL_PATH="${1:-}"

if [[ -z "$REL_PATH" ]]; then
  echo "[WARN] release-file-lock.sh: 缺少 relative_file_path 參數" >&2
  exit 1
fi

# ── Path Hash 計算 ─────────────────────────────────────────────────
if command -v sha256sum &>/dev/null; then
  HASH=$(echo "$REL_PATH" | sha256sum | cut -c1-16)
else
  HASH=$(echo "$REL_PATH" | md5sum 2>/dev/null | cut -c1-16 || echo "fallback00000000")
fi

REF="refs/file-locks/${HASH}"

# ── repo fingerprint 計算（本地 metadata cleanup）────────────────
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
REPO_FP=$(echo "$REPO_ROOT" | sha256sum 2>/dev/null | cut -c1-8 \
         || echo "$REPO_ROOT" | md5sum 2>/dev/null | cut -c1-8 \
         || echo "fallback0")

META_DIR="/tmp/shikigami-file-locks-${REPO_FP}"
META_FILE="${META_DIR}/${HASH}.meta"
LOCK_FILE="${META_DIR}/${HASH}.lock"

# ── 1. 刪除遠端 ref ──────────────────────────────────────────────
# #3 修復：檢查 exit code，只有遠端確認刪除後才清本地 metadata
git push origin --delete "$REF" 2>/dev/null
DELETE_EXIT=$?
if [[ $DELETE_EXIT -ne 0 ]]; then
  echo "[WARN] $REF 遠端刪除失敗（exit=$DELETE_EXIT），跳過本地 metadata 清除"
  # 不清除本地 metadata（保留供診斷），仍輸出 RELEASE（不阻塞）
  echo "[FILE-LOCK-RELEASE] $REF（遠端刪除失敗，本地 metadata 保留）"
  exit 0
fi

# ── 2. 遠端確認刪除成功後才清除本地 metadata 和 lock 檔案 ────────
if [[ -f "$META_FILE" ]]; then
  rm -f "$META_FILE" 2>/dev/null || true
fi
if [[ -f "$LOCK_FILE" ]]; then
  rm -f "$LOCK_FILE" 2>/dev/null || true
fi

echo "[FILE-LOCK-RELEASE] $REF"
