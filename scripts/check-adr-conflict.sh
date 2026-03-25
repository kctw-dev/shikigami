#!/usr/bin/env bash
# check-adr-conflict.sh — ADR 編號衝突預偵測（Sprint Planning Architect 評估工具）
# Sprint 155 | #730 AC3
# 在 Sprint Planning 時驗證擬用 ADR 編號未被佔用，並建議下一個可用編號

set -euo pipefail

ADR_DIR="${1:-docs/adr}"
PROPOSED_NUM="${2:-}"

usage() {
  echo "Usage: $0 [ADR_DIR] [PROPOSED_NUM]"
  echo "  ADR_DIR       ADR 目錄（預設: docs/adr）"
  echo "  PROPOSED_NUM  擬用 ADR 編號，如 041"
  echo ""
  echo "Examples:"
  echo "  $0 docs/adr 041           # 檢查 ADR-041 是否可用"
  echo "  $0 docs/adr               # 列出最新可用 ADR 編號"
  exit 0
}

# ── 確認 ADR 目錄存在 ─────────────────────────────────────────────
if [ ! -d "$ADR_DIR" ]; then
  echo "[ADR-CHECK-ERROR] ADR 目錄不存在: $ADR_DIR"
  exit 1
fi

# ── 找出最後一個已使用的 ADR 編號 ────────────────────────────────
LAST_NUM=$(ls "$ADR_DIR"/ADR-*.md 2>/dev/null | \
  grep -oE 'ADR-[0-9]+' | \
  sort -t- -k2 -n | \
  tail -1 | \
  grep -oE '[0-9]+' || echo "0")

NEXT_AVAILABLE=$((10#$LAST_NUM + 1))

# ── 若未指定擬用編號，直接輸出建議 ──────────────────────────────
if [ -z "$PROPOSED_NUM" ]; then
  printf '[ADR-NEXT] 下一個可用 ADR 編號：ADR-%03d\n' "$NEXT_AVAILABLE"
  exit 0
fi

# ── 衝突偵測（AC1 + AC2）─────────────────────────────────────────
PROPOSED_PADDED=$(printf '%03d' "$((10#$PROPOSED_NUM))")

if ls "$ADR_DIR"/ADR-${PROPOSED_PADDED}-*.md 2>/dev/null | head -1 | grep -q .; then
  # ADR 編號已被佔用 → 輸出 [ADR-CONFLICT] 並建議下一個可用編號（AC2）
  OCCUPIED_FILE=$(ls "$ADR_DIR"/ADR-${PROPOSED_PADDED}-*.md | head -1 | xargs basename)
  printf '[ADR-CONFLICT] ADR-%s 已被佔用（%s），建議使用 ADR-%03d\n' \
    "$PROPOSED_PADDED" "$OCCUPIED_FILE" "$NEXT_AVAILABLE"
  exit 1
else
  # ADR 編號可用
  printf '[ADR-OK] ADR-%s 可用\n' "$PROPOSED_PADDED"
  exit 0
fi
