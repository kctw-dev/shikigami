#!/usr/bin/env bash
# scripts/retro-action-analysis.sh
# Story #872: Retro Action Items 歷史分析工具 — 完成率與重複主題趨勢
#
# Usage:
#   bash scripts/retro-action-analysis.sh [--repo OWNER/REPO] [--last N]
#
# 功能：
#   1. 掃描 retro-action label 的所有 Issues，計算完成率（closed/total）
#   2. 識別標題關鍵字重複出現（>= 2 次）的主題，輸出 [SYSTEMIC-ISSUE] 標記
#   3. 輸出近 5 Sprint 的 Retro Action 完成率趨勢
#
# 環境變數：
#   OWNER_REPO — 預設 kctw-dev/shikigami（可由 --repo 覆寫）

set -uo pipefail

# ── 常數與預設值 ──────────────────────────────────────────────────────────────

OWNER_REPO="${OWNER_REPO:-kctw-dev/shikigami}"
LAST_N=5
SYSTEMIC_THRESHOLD=2  # 關鍵字重複次數閾值

# 常見停用詞（不參與關鍵字計數）
STOPWORDS="的 了 在 是 和 或 但 有 與 我 你 他 她 我們 他們
           a an the and or but in on at to for of with is are was
           改善 加強 補充 處理 解決 優化 更新 修正 增加 移除 清理
           issue issues story stories 問題 事項 工作"

# ── 參數解析 ─────────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)  OWNER_REPO="${2:-$OWNER_REPO}"; shift 2 ;;
    --last)  LAST_N="${2:-5}"; shift 2 ;;
    *)       shift ;;
  esac
done

# ── gh API 呼叫（含降級處理） ─────────────────────────────────────────────────

RAW_JSON=""
GH_OK=true

if ! RAW_JSON=$(gh issue list \
    -R "$OWNER_REPO" \
    --label retro-action \
    --state all \
    --limit 200 \
    --json number,title,state,labels \
    2>&1); then
  echo "[WARN] gh issue list 失敗（$OWNER_REPO），以空資料繼續"
  echo "[WARN] 錯誤訊息：$RAW_JSON"
  RAW_JSON="[]"
  GH_OK=false
fi

# 驗證 JSON 非空陣列字串
if ! echo "$RAW_JSON" | grep -q '^\['; then
  echo "[WARN] gh 回傳非 JSON 格式，以空資料繼續"
  echo "[WARN] 回傳內容：${RAW_JSON:0:200}"
  RAW_JSON="[]"
  GH_OK=false
fi

# ── 解析 Issues ──────────────────────────────────────────────────────────────

# 使用 jq 解析（若不可用則降級）
if ! command -v jq &>/dev/null; then
  echo "[WARN] jq 不可用，無法解析完整資料"
  RAW_JSON="[]"
fi

# 提取欄位：number, title, state, sprint_label
# Sprint label 格式：Sprint NNN
declare -a ALL_TITLES=()
declare -a ALL_STATES=()
declare -a ALL_SPRINTS=()
declare -i TOTAL=0
declare -i CLOSED=0

if [[ "$RAW_JSON" != "[]" && -n "$RAW_JSON" ]]; then
  # 用 jq 解析每個 issue
  while IFS='|' read -r num title state sprint; do
    [[ -z "$title" ]] && continue
    TOTAL=$(( TOTAL + 1 ))
    ALL_TITLES+=("$title")
    ALL_STATES+=("$state")
    ALL_SPRINTS+=("$sprint")
    if [[ "$state" == "CLOSED" ]]; then
      CLOSED=$(( CLOSED + 1 ))
    fi
  done < <(echo "$RAW_JSON" | jq -r '.[] |
    .number as $n |
    .title as $t |
    .state as $s |
    ([ .labels[].name | select(test("^Sprint [0-9]+$")) ] | first // "Unknown") as $sprint |
    "\($n)|\($t)|\($s)|\($sprint)"
  ' 2>/dev/null || true)
fi

# ── 區塊 1: 整體完成率 ────────────────────────────────────────────────────────

echo "=== Retro Action Items 分析報告 ==="
echo "Repository: $OWNER_REPO"
echo ""
echo "── 整體完成率 ─────────────────────────────────────────────────────────────"

if [[ $TOTAL -eq 0 ]]; then
  echo "（無 retro-action Issues 資料）"
else
  # 計算百分比（整數）
  RATE=$(( CLOSED * 100 / TOTAL ))
  echo "總計：${CLOSED}/${TOTAL} 已完成（${RATE}%）"

  # 完成率評估
  if [[ $RATE -ge 80 ]]; then
    echo "[STATUS] HEALTHY — 完成率 >= 80%"
  elif [[ $RATE -ge 50 ]]; then
    echo "[STATUS] WARNING — 完成率 50-79%"
  else
    echo "[STATUS] CRITICAL — 完成率 < 50%"
  fi
fi

echo ""

# ── 區塊 2: 關鍵字重複分析 — [SYSTEMIC-ISSUE] ────────────────────────────────

echo "── 重複主題分析 ────────────────────────────────────────────────────────────"

if [[ $TOTAL -eq 0 ]]; then
  echo "（無資料）"
else
  # 建立關鍵字計數 map
  declare -A KEYWORD_COUNT=()

  for title in "${ALL_TITLES[@]:-}"; do
    [[ -z "$title" ]] && continue
    # 分詞：以空格、標點拆分，轉小寫
    IFS=' 　，、。！？：；「」『』【】〔〕（）…—─' read -ra WORDS <<< "$title"
    for word in "${WORDS[@]:-}"; do
      # 清理特殊字元
      word=$(echo "$word" | tr -d '[:punct:]' | tr '[:upper:]' '[:lower:]')
      [[ -z "$word" ]] && continue
      # 跳過停用詞（長度 <= 1 的也跳過）
      [[ "${#word}" -le 1 ]] && continue
      # 跳過純數字
      [[ "$word" =~ ^[0-9]+$ ]] && continue
      # 跳過停用詞列表
      if echo "$STOPWORDS" | grep -qwF "$word" 2>/dev/null; then
        continue
      fi
      KEYWORD_COUNT["$word"]=$(( ${KEYWORD_COUNT["$word"]:-0} + 1 ))
    done
  done

  # 找出重複 >= SYSTEMIC_THRESHOLD 的關鍵字
  SYSTEMIC_FOUND=false
  declare -a SYSTEMIC_KEYWORDS=()

  for kw in "${!KEYWORD_COUNT[@]}"; do
    cnt="${KEYWORD_COUNT[$kw]}"
    if [[ $cnt -ge $SYSTEMIC_THRESHOLD ]]; then
      SYSTEMIC_KEYWORDS+=("${cnt}:${kw}")
      SYSTEMIC_FOUND=true
    fi
  done

  if [[ "$SYSTEMIC_FOUND" == "true" ]]; then
    # 按出現次數排序
    IFS=$'\n' SORTED_KW=($(printf '%s\n' "${SYSTEMIC_KEYWORDS[@]}" | sort -rn))
    unset IFS
    echo "[SYSTEMIC-ISSUE] 以下關鍵字重複出現 >= ${SYSTEMIC_THRESHOLD} 次，可能為系統性問題："
    for entry in "${SORTED_KW[@]}"; do
      cnt="${entry%%:*}"
      kw="${entry#*:}"
      printf "  %-20s (%d 次)\n" "$kw" "$cnt"
    done
  else
    echo "（未偵測到重複主題 — 無系統性問題信號）"
  fi
fi

echo ""

# ── 區塊 3: 近 N Sprint 完成率趨勢 ───────────────────────────────────────────

echo "── 近 ${LAST_N} Sprint 趨勢 ─────────────────────────────────────────────────"

if [[ $TOTAL -eq 0 ]]; then
  echo "（無資料）"
else
  # 按 Sprint 分組
  declare -A SPRINT_TOTAL=()
  declare -A SPRINT_CLOSED=()
  declare -a SPRINT_NUMS=()

  for i in "${!ALL_SPRINTS[@]}"; do
    sprint="${ALL_SPRINTS[$i]:-Unknown}"
    state="${ALL_STATES[$i]:-}"

    # 提取 Sprint 號碼（用於排序）
    sprint_num=$(echo "$sprint" | grep -oE '[0-9]+$' || echo "0")
    sprint_key="Sprint $sprint_num"

    if [[ -z "${SPRINT_TOTAL[$sprint_key]+_}" ]]; then
      SPRINT_NUMS+=("$sprint_num")
      SPRINT_TOTAL["$sprint_key"]=0
      SPRINT_CLOSED["$sprint_key"]=0
    fi

    SPRINT_TOTAL["$sprint_key"]=$(( SPRINT_TOTAL["$sprint_key"] + 1 ))
    if [[ "$state" == "CLOSED" ]]; then
      SPRINT_CLOSED["$sprint_key"]=$(( SPRINT_CLOSED["$sprint_key"] + 1 ))
    fi
  done

  # 排序 Sprint 號碼（去重）
  if [[ "${#SPRINT_NUMS[@]}" -gt 0 ]]; then
    IFS=$'\n' SORTED_SPRINT_NUMS=($(printf '%s\n' "${SPRINT_NUMS[@]}" | sort -nu))
    unset IFS

    # 取最近 LAST_N 個
    TOTAL_SPRINTS="${#SORTED_SPRINT_NUMS[@]}"
    if [[ "$TOTAL_SPRINTS" -gt "$LAST_N" ]]; then
      START=$(( TOTAL_SPRINTS - LAST_N ))
      SORTED_SPRINT_NUMS=("${SORTED_SPRINT_NUMS[@]:$START}")
    fi

    # 輸出趨勢表
    printf "%-12s %-10s %s\n" "Sprint" "完成率" "Closed/Total"
    printf "%-12s %-10s %s\n" "------" "------" "------------"

    PREV_RATE=""
    for num in "${SORTED_SPRINT_NUMS[@]}"; do
      [[ -z "$num" || "$num" == "0" ]] && continue
      sprint_key="Sprint $num"
      s_total="${SPRINT_TOTAL[$sprint_key]:-0}"
      s_closed="${SPRINT_CLOSED[$sprint_key]:-0}"

      if [[ $s_total -eq 0 ]]; then
        rate_pct="N/A"
        trend_mark=""
      else
        rate_pct=$(( s_closed * 100 / s_total ))

        # 計算趨勢
        trend_mark=""
        if [[ -n "$PREV_RATE" ]] && [[ "$rate_pct" =~ ^[0-9]+$ ]] && [[ "$PREV_RATE" =~ ^[0-9]+$ ]]; then
          if (( rate_pct > PREV_RATE )); then
            trend_mark="[TREND-UP]"
          elif (( rate_pct < PREV_RATE )); then
            trend_mark="[TREND-DOWN]"
          else
            trend_mark="[TREND-STABLE]"
          fi
        fi
        rate_pct="${rate_pct}%"
        PREV_RATE="${rate_pct//%/}"
      fi

      printf "| %-10s | %-8s | %s/%s %s\n" \
        "$sprint_key" "$rate_pct" "$s_closed" "$s_total" "$trend_mark"
    done
  else
    echo "（無 Sprint 標籤資料）"
  fi
fi

echo ""
echo "（顯示近 ${LAST_N} Sprint 趨勢；--last N 可調整）"
[[ "$GH_OK" == "false" ]] && echo "" && echo "[WARN] 部分資料因 gh API 失敗而缺失，以上為降級輸出"

exit 0
