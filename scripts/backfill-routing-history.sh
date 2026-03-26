#!/usr/bin/env bash
# scripts/backfill-routing-history.sh
# Story #867 — routing-stats 歷史趨勢補齊
#
# AC1: 從 docs/sprints/sprint_*.md 掃描路由記錄
# AC2: 對每個 Sprint 文件中的 Model Routing 表格輸出 model-route 格式記錄
# AC3: --dry-run 模式輸出補充記錄而不寫入；預設模式 append 至 Metrics_Log.md（idempotent）
# AC4: 執行後 routing-stats.sh haiku 比例應 >= 30%（基準修正）
#
# NFR: idempotent — 重複執行不產生重複記錄

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPRINTS_DIR="${REPO_ROOT}/docs/sprints"
METRICS_LOG="${REPO_ROOT}/docs/km/Metrics_Log.md"

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
fi

# ── 驗證必要檔案 ──────────────────────────────────────────────────────────

if [ ! -d "$SPRINTS_DIR" ]; then
  echo "[ERROR] Sprint directory not found: $SPRINTS_DIR" >&2
  exit 1
fi

if [ ! -f "$METRICS_LOG" ]; then
  echo "[ERROR] Metrics_Log.md not found: $METRICS_LOG" >&2
  exit 1
fi

# ── 掃描並提取路由記錄 ──────────────────────────────────────────────────

# 臨時檔案儲存新的路由記錄
NEW_ROUTES=$(mktemp)
trap "rm -f '$NEW_ROUTES'" EXIT

# 掃描所有 sprint_*.md 檔案（跳過 checkpoint）
for sprint_file in "$SPRINTS_DIR"/sprint_[0-9]*.md; do
  [ -f "$sprint_file" ] || continue

  # 提取 Sprint 編號
  sprint_num=$(basename "$sprint_file" | sed -E 's/sprint_([0-9]+)\.md/\1/')

  # 查找 Model Routing 區段
  # 使用 awk 來識別並解析表格（支援多種格式）
  awk -v sprint_num="$sprint_num" '
    # 找到 Model Routing 標題
    /^## Model Routing/ {
      in_routing = 1
      table_row = 0
      next
    }

    # 當進入新的主要段落時，停止解析
    /^## / && in_routing && table_row > 0 {
      in_routing = 0
    }

    # 解析表格行
    in_routing && /^\| / {
      table_row++
      # 跳過表頭行和分隔符行
      if (table_row <= 2) next

      # 格式1：| #857 | LOG | 4 | haiku（強制） |
      # Story | Story Type | Risk Score | Routing Tier
      if (match($0, /\| #([0-9]+) \| ([^ |]+) \| ([0-9]+) \| ([^|]+) \|/, arr)) {
        story_id = arr[1]
        story_type = arr[2]
        risk_score = arr[3]
        routing_tier = arr[4]

        # 清理 routing_tier（移除空格和括號內容）
        gsub(/[（（].*[））]/, "", routing_tier)
        gsub(/^ +| +$/, "", routing_tier)

        # 映射模型名稱
        model = ""
        tier = ""
        if (routing_tier ~ /haiku/) {
          model = "haiku"
          tier = "1"
        } else if (routing_tier ~ /sonnet/) {
          model = "sonnet"
          tier = "2"
        } else if (routing_tier ~ /opus/) {
          model = "opus"
          tier = "3"
        }

        if (model != "") {
          printf "model-route #%s tier=%s score=%s model=%s reason=backfill-from-sprint-%s\n", story_id, tier, risk_score, model, sprint_num
          next
        }
      }

      # 格式2：| #737 | 2 | 7 | sonnet |
      # Story | Tier | Score | Model
      if (match($0, /\| #([0-9]+) \| ([0-9]+) \| ([0-9]+) \| ([^|]+) \|/, arr)) {
        story_id = arr[1]
        tier = arr[2]
        score = arr[3]
        model = arr[4]

        # 清理 model（移除空格和括號內容）
        gsub(/[（（].*[））]/, "", model)
        gsub(/^ +| +$/, "", model)

        # 驗證 model 和 tier
        if ((model ~ /haiku/ && tier == "1") ||
            (model ~ /sonnet/ && tier == "2") ||
            (model ~ /opus/ && tier == "3")) {
          printf "model-route #%s tier=%s score=%s model=%s reason=backfill-from-sprint-%s\n", story_id, tier, score, model, sprint_num
          next
        }
      }
    }
  ' "$sprint_file" >> "$NEW_ROUTES" || true
done

# ── 去重：檢查 Metrics_Log.md 中已存在的記錄 ─────────────────────────────

# 保存已存在的 story IDs
EXISTING_STORIES=$(grep -oE "model-route #[0-9]+" "$METRICS_LOG" 2>/dev/null | sed 's/model-route //' | sort -u || true)

# 篩選出新記錄（idempotent）
FILTERED_ROUTES=$(mktemp)
trap "rm -f '$NEW_ROUTES' '$FILTERED_ROUTES'" EXIT

while IFS= read -r line; do
  [ -z "$line" ] && continue

  story_id=$(echo "$line" | grep -oE "#[0-9]+" | head -1)

  # 如果 story 已在 Metrics_Log.md 中，跳過（idempotent）
  if echo "$EXISTING_STORIES" | grep -q "^$story_id$"; then
    # echo "[SKIP] $story_id already exists in Metrics_Log.md" >&2
    continue
  fi

  echo "$line" >> "$FILTERED_ROUTES"
done < "$NEW_ROUTES"

ROUTE_COUNT=$(wc -l < "$FILTERED_ROUTES" | tr -d ' ')

# ── 輸出結果 ──────────────────────────────────────────────────────────────

if [ "$ROUTE_COUNT" -eq 0 ]; then
  echo "[OK] No new routing records to backfill (all sprints already recorded)"
  exit 0
fi

if [ "$DRY_RUN" = true ]; then
  echo "[DRY-RUN] 將新增以下 $ROUTE_COUNT 條記錄："
  echo "---"
  cat "$FILTERED_ROUTES"
  echo "---"
  echo "[DRY-RUN] 未修改 Metrics_Log.md 和 metrics-log/"
else
  # 追加至 Metrics_Log.md（在文件末尾）
  {
    echo ""
    echo "# Sprint Execution 中各 Story 的 model 路由決策記錄"
    echo ""
    cat "$FILTERED_ROUTES"
  } >> "$METRICS_LOG"

  # 同時建立 metrics-log 中的 session 記錄（用於 routing-stats.sh 讀取）
  METRICS_LOG_DIR="${REPO_ROOT}/docs/km/metrics-log"
  mkdir -p "$METRICS_LOG_DIR"

  TIMESTAMP=$(date '+%Y-%m-%d')
  BACKFILL_SESSION="${METRICS_LOG_DIR}/${TIMESTAMP}-backfill-routing-history.md"

  {
    echo "# Model Routing Backfill — ${TIMESTAMP}"
    echo ""
    echo "**用途**：從 Sprint 文件中補齊歷史路由記錄"
    echo ""
    echo "## Model Routing Records"
    echo ""
    cat "$FILTERED_ROUTES"
  } > "$BACKFILL_SESSION"

  echo "[OK] 已新增 $ROUTE_COUNT 條路由記錄至 Metrics_Log.md"
  echo "[OK] 已建立 metrics-log 補齊記錄：$BACKFILL_SESSION"
fi

exit 0
