#!/usr/bin/env bash
# scripts/routing-stats.sh
# Story #711 — ADR-039 Model Routing 準確率追蹤 Dashboard
#
# AC1: 從 docs/sprints/sprint_*.md 及 docs/km/metrics-log/ 提取 model-route 記錄
# AC2: 統計輸出：tier 分布比例、平均 risk score、各維度均值
# AC3: 輸出寫入 docs/km/model-routing-dashboard.md（每次執行覆寫）
# AC5: 若 haiku tier 比例 < 30%，輸出警告
# NFR2: 覆蓋最近 10 個 Sprint 的路由記錄
# NFR3: dashboard 包含具體建議

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPRINTS_DIR="${REPO_ROOT}/docs/sprints"
METRICS_DIR="${REPO_ROOT}/docs/km/metrics-log"
OUTPUT_FILE="${REPO_ROOT}/docs/km/model-routing-dashboard.md"
RECENT_SPRINTS=10

# ── 提取 model-route 記錄 ────────────────────────────────────────────

# 從最近 N 個 sprint_*.md 中提取 model-route 記錄
# 格式1（sprint_*.md）：model-route #N tier=X score=Y model=M reason=...
# 格式2（sprint_*.md 簡短）：#708 → haiku (score=4)
# 格式3（metrics-log）：model-route #N tier=X score=Y model=M reason=...

RECENT_SPRINT_FILES=$(ls "${SPRINTS_DIR}/sprint_"*.md 2>/dev/null \
  | grep -v checkpoint \
  | sort -t_ -k2 -n \
  | tail -${RECENT_SPRINTS} \
  || true)

# 臨時工作目錄
WORK_DIR=$(mktemp -d)
trap "rm -rf ${WORK_DIR}" EXIT

ROUTES_FILE="${WORK_DIR}/routes.txt"
touch "$ROUTES_FILE"

# 從 sprint 文件提取（格式1：標準格式）
if [ -n "$RECENT_SPRINT_FILES" ]; then
  while IFS= read -r sprint_file; do
    [ -f "$sprint_file" ] || continue
    grep -E "model-route #[0-9]+ tier=[0-9]+ score=[0-9]+" "$sprint_file" 2>/dev/null >> "$ROUTES_FILE" || true
    # 格式2：簡短格式（#N → tier (score=S)）
    grep -E "#[0-9]+ → (haiku|sonnet|opus) \(score=[0-9]+\)" "$sprint_file" 2>/dev/null \
      | sed -E 's/.*#([0-9]+) → (haiku|sonnet|opus) \(score=([0-9]+)\).*/model-route #\1 tier=auto score=\3 model=\2 reason=sprint-doc/' \
      >> "$ROUTES_FILE" || true
  done <<< "$RECENT_SPRINT_FILES"
fi

# 從 metrics-log 提取（格式3）
if [ -d "$METRICS_DIR" ]; then
  RECENT_METRICS=$(ls "${METRICS_DIR}/"*.md 2>/dev/null | sort -r | head -20 || true)
  if [ -n "$RECENT_METRICS" ]; then
    while IFS= read -r mfile; do
      [ -f "$mfile" ] || continue
      grep -E "model-route #[0-9]+ tier=[0-9]+ score=[0-9]+" "$mfile" 2>/dev/null >> "$ROUTES_FILE" || true
    done <<< "$RECENT_METRICS"
  fi
fi

TOTAL_ROUTES=$(grep -c "model-route" "$ROUTES_FILE" 2>/dev/null || echo 0)

# ── 統計計算 ─────────────────────────────────────────────────────────

# Tier 計數（tier= 格式）
T1_COUNT=$(grep -c "tier=1\b" "$ROUTES_FILE" 2>/dev/null || true)
T1_COUNT=${T1_COUNT:-0}
T2_COUNT=$(grep -c "tier=2\b" "$ROUTES_FILE" 2>/dev/null || true)
T2_COUNT=${T2_COUNT:-0}
T3_COUNT=$(grep -c "tier=3\b" "$ROUTES_FILE" 2>/dev/null || true)
T3_COUNT=${T3_COUNT:-0}

# 從 model= 欄位補充計數（處理 tier=auto 的格式2記錄）
HAIKU_BY_MODEL=$(grep -c "model=haiku" "$ROUTES_FILE" 2>/dev/null || true)
HAIKU_BY_MODEL=${HAIKU_BY_MODEL:-0}
SONNET_BY_MODEL=$(grep -c "model=sonnet" "$ROUTES_FILE" 2>/dev/null || true)
SONNET_BY_MODEL=${SONNET_BY_MODEL:-0}
OPUS_BY_MODEL=$(grep -c "model=opus" "$ROUTES_FILE" 2>/dev/null || true)
OPUS_BY_MODEL=${OPUS_BY_MODEL:-0}

# 取較大值（tier= 或 model= 都可能是來源）
T1_FINAL=$((T1_COUNT > HAIKU_BY_MODEL ? T1_COUNT : HAIKU_BY_MODEL))
T2_FINAL=$((T2_COUNT > SONNET_BY_MODEL ? T2_COUNT : SONNET_BY_MODEL))
T3_FINAL=$((T3_COUNT > OPUS_BY_MODEL ? T3_COUNT : OPUS_BY_MODEL))
TOTAL_BY_TIER=$((T1_FINAL + T2_FINAL + T3_FINAL))

# 如果 tier 統計與 total 差異過大，用 total_routes 作為分母
DENOM=$TOTAL_ROUTES
if [ "$DENOM" -eq 0 ]; then
  DENOM=1
fi

# 計算百分比（整數）
T1_PCT=$((T1_FINAL * 100 / DENOM))
T2_PCT=$((T2_FINAL * 100 / DENOM))
T3_PCT=$((T3_FINAL * 100 / DENOM))

# 平均 risk score
SCORES=$(grep -oE "score=[0-9]+" "$ROUTES_FILE" 2>/dev/null | grep -oE "[0-9]+" | tr '\n' '+' || true)
if [ -n "$SCORES" ]; then
  SCORES="${SCORES%+}"  # 移除尾部 +
  SCORE_SUM=$(echo "$SCORES" | tr '+' '\n' | paste -sd+ | bc 2>/dev/null || echo 0)
  SCORE_COUNT=$(echo "$SCORES" | tr '+' '\n' | wc -l | tr -d ' ')
  if [ "$SCORE_COUNT" -gt 0 ]; then
    AVG_SCORE=$((SCORE_SUM / SCORE_COUNT))
  else
    AVG_SCORE=0
  fi
else
  AVG_SCORE=0
  SCORE_COUNT=0
fi

# ── haiku 比例警告（AC5）──────────────────────────────────────────────

HAIKU_WARN=""
if [ "$DENOM" -gt 0 ] && [ "$T1_PCT" -lt 30 ]; then
  HAIKU_WARN="[OVER-ROUTING-WARN] haiku tier 比例 ${T1_PCT}% < 30%，疑似 over-routing（高成本模型使用過度）"
  echo "$HAIKU_WARN"
fi

# ── 產生 dashboard ───────────────────────────────────────────────────

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
SPRINT_RANGE=$(ls "${SPRINTS_DIR}/sprint_"*.md 2>/dev/null \
  | grep -v checkpoint \
  | sort -t_ -k2 -n \
  | tail -${RECENT_SPRINTS} \
  | grep -oP 'sprint_\K\d+' \
  | paste -sd' ' \
  || echo "N/A")

{
  cat << HEADER
# ADR-039 Model Routing Dashboard

> 本文件由 \`scripts/routing-stats.sh\` 自動產生，請勿手動修改。
> 最後更新：${TIMESTAMP}
> 資料範圍：最近 ${RECENT_SPRINTS} 個 Sprint（Sprint ${SPRINT_RANGE}）

## Tier 分布

| Tier | Model | 路由次數 | 比例 | 適用分數範圍 |
|------|-------|---------|------|------------|
| Tier 1 | haiku | ${T1_FINAL} | ${T1_PCT}% | 4–6 |
| Tier 2 | sonnet | ${T2_FINAL} | ${T2_PCT}% | 7–9 |
| Tier 3 | opus | ${T3_FINAL} | ${T3_PCT}% | 10–12 |
| **合計** | — | **${TOTAL_ROUTES}** | **100%** | — |

## Risk Score 統計

| 指標 | 值 |
|------|-----|
| 平均 Risk Score | ${AVG_SCORE} |
| 樣本數 | ${SCORE_COUNT} |

## 健康度評估

HEADER

  # 健康度判斷
  if [ "$TOTAL_ROUTES" -eq 0 ]; then
    echo "> **[DATA-UNAVAILABLE]** 未找到 model-route 記錄（確認 sprint docs 格式是否包含 model-route log）"
  elif [ "$T1_PCT" -ge 30 ]; then
    echo "> **[ROUTING-OK]** haiku tier 比例 ${T1_PCT}% >= 30%，路由分布正常"
  else
    echo "> **[OVER-ROUTING-WARN]** haiku tier 比例 ${T1_PCT}% < 30%，疑似 over-routing"
  fi

  cat << ADVICE

## 路由建議（NFR3）

> 基於當前統計資料的具體建議：

ADVICE

  # 動態建議
  if [ "$T1_PCT" -lt 30 ] && [ "$TOTAL_ROUTES" -gt 0 ]; then
    echo "- **降低 haiku 使用門檻**：Score 4-5 的 Story 應路由至 haiku（目前 haiku 比例偏低 ${T1_PCT}%）"
  fi
  if [ "$AVG_SCORE" -ge 8 ]; then
    echo "- **高平均 Risk Score（${AVG_SCORE}）**：建議重新審查各 Story 評分，確認 Reversibility/Novelty 維度未被高估"
  fi
  if [ "$T3_PCT" -gt 20 ]; then
    echo "- **Opus 使用比例偏高（${T3_PCT}%）**：確認 opus 路由僅用於分數 10-12 的 Story，避免不必要的高成本"
  fi
  if [ "$TOTAL_ROUTES" -gt 0 ] && [ "$T1_PCT" -ge 30 ] && [ "$T3_PCT" -le 20 ] && [ "$AVG_SCORE" -le 8 ]; then
    echo "- **路由分布健康**：目前 Tier 分布符合 ADR-039 目標（haiku >= 30%，opus <= 20%，平均分數合理）"
  fi
  echo "- Score 4-5 的 Story 可降至 haiku（doc-only retro / 格式轉換 / log 摘要）"
  echo "- Score 10-12 的 Story 應路由至 opus（架構設計 ADR / 安全審查 / L-size Story）"

  cat << FOOTER

## 參考

- ADR-039 Token Cost Routing：\`docs/adr/ADR-039-token-cost-routing.md\`
- Sprint Planning 路由記錄格式：\`model-route #N tier=X score=Y model=M reason=說明\`
FOOTER

} > "$OUTPUT_FILE"

echo "[OK] Model Routing Dashboard 已更新：${OUTPUT_FILE}"
echo "[OK] 共分析 ${TOTAL_ROUTES} 條 model-route 記錄（最近 ${RECENT_SPRINTS} 個 Sprint）"
if [ -n "$HAIKU_WARN" ]; then
  echo "$HAIKU_WARN"
fi
