#!/usr/bin/env bash
# scripts/validate-orphans.sh
# US-T09：孤兒文件偵測腳本
#
# 掃描 docs/ 下所有 .md 文件，找出未被任何其他 .md 文件以相對路徑引用
# 且不在豁免清單中的孤兒文件，輸出 WARNING（不阻塞 CI）。
#
# AC1：孤兒定義 — docs/ 下的 .md 文件未被任何其他 .md 文件以相對路徑引用
#       且不在豁免清單中
# AC2：輸出格式 — WARNING: <file_path>: 孤兒文件（無任何 .md 引用）  [直接 echo，不使用 print_warning]
#       exit code 均為 0（warning 不影響 CI pass/fail）
# AC3：處置說明 — 見 skills/health-check/SKILL.md 第 6 節
#
# .orphan-allowlist 豁免清單機制（#658）：
#   專案根目錄下的 .orphan-allowlist 文件，每行為一個豁免路徑前綴。
#   匹配豁免前綴的孤兒文件改為 [INFO] 級別輸出，不計入 WARNING 數。
#   建立方式：在專案根目錄建立 .orphan-allowlist，每行填入豁免路徑前綴
#   （如 docs/sprints/subagent-results/），空行與 # 開頭行視為註解忽略。
#
# 使用方式：
#   bash scripts/validate-orphans.sh
#   （在專案根目錄下執行；docs/ 目錄相對於 cwd）
#
# Exit code:
#   0 = 永遠為 0（warning 不阻塞 CI）
#
# 依賴：bash >= 4, grep, find

set -uo pipefail

source "$(dirname "$0")/lib/validate-helpers.sh"

# ---------------------------------------------------------------------------
# 常數
# ---------------------------------------------------------------------------
readonly DOCS_DIR="docs"
readonly ALLOWLIST_FILE=".orphan-allowlist"

# 豁免清單規則（4 類）：
#   CLASS_1：sprints/sprint_N.md — Sprint 週期文件，不需要被引用
#   CLASS_2：km/Metrics_Log.md — 度量紀錄，自動累積不需引用
#   CLASS_3：頂層文件（docs/ 直屬，非子目錄）— PROJECT_BOARD.md 等
#   CLASS_4：adr/ADR-*.md — ADR 文件，由 Backlog 管理而非相互引用
#   CLASS_5：.orphan-allowlist 路徑前綴豁免（#658）— 永久性孤兒靜默為 [INFO]
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# 載入 .orphan-allowlist 豁免前綴清單（#658）
# ---------------------------------------------------------------------------
ALLOWLIST_PREFIXES=()
if [[ -f "$ALLOWLIST_FILE" ]]; then
  while IFS= read -r line; do
    # 跳過空行與 # 開頭的註解行
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    ALLOWLIST_PREFIXES+=("$line")
  done < "$ALLOWLIST_FILE"
fi

# ---------------------------------------------------------------------------
# is_allowlisted：判斷文件是否匹配 .orphan-allowlist 中的路徑前綴
# 參數：$1 = 相對於專案根目錄的文件路徑
# 回傳：0 = 匹配豁免（輸出 INFO），1 = 不匹配
# ---------------------------------------------------------------------------
is_allowlisted() {
  local filepath="$1"
  for prefix in "${ALLOWLIST_PREFIXES[@]+"${ALLOWLIST_PREFIXES[@]}"}"; do
    if [[ "$filepath" == ${prefix}* ]]; then
      return 0
    fi
  done
  return 1
}

# ---------------------------------------------------------------------------
# 狀態追蹤（EXIT_CODE 固定為 0，但仍追蹤 WARNING_COUNT）
# ---------------------------------------------------------------------------
EXIT_CODE=0
ERROR_COUNT=0
WARNING_COUNT=0
INFO_ALLOWLISTED_COUNT=0
SCANNED_COUNT=0
ORPHAN_COUNT=0

# ---------------------------------------------------------------------------
# 前置檢查：docs/ 目錄必須存在
# ---------------------------------------------------------------------------
preflight_check() {
  if [[ ! -d "$DOCS_DIR" ]]; then
    print_error "找不到目錄：$DOCS_DIR"
    # 即使前置失敗也 exit 0（不阻塞 CI）
    exit 0
  fi
}

# ---------------------------------------------------------------------------
# is_exempt：判斷文件是否在豁免清單中
# 參數：$1 = 相對於專案根目錄的文件路徑（如 docs/sprints/sprint_1.md）
# 回傳：0 = 豁免（跳過），1 = 不豁免（需檢查）
# ---------------------------------------------------------------------------
is_exempt() {
  local filepath="$1"
  # 取得相對於 docs/ 的路徑（去掉 docs/ 前綴）
  local rel="${filepath#${DOCS_DIR}/}"

  # CLASS_1：sprints/sprint_N.md — Sprint 週期文件
  if [[ "$rel" =~ ^sprints/sprint_[0-9]+\.md$ ]]; then
    return 0
  fi

  # CLASS_2：km/Metrics_Log.md — 度量紀錄
  if [[ "$rel" == "km/Metrics_Log.md" ]]; then
    return 0
  fi

  # CLASS_3：頂層文件（docs/ 直屬，無子目錄層）
  if [[ "$rel" != */* ]]; then
    return 0
  fi

  # CLASS_4：adr/ADR-*.md — ADR 文件
  if [[ "$rel" =~ ^adr/ADR-[0-9]+\.md$ ]]; then
    return 0
  fi

  return 1
}

# ---------------------------------------------------------------------------
# is_referenced：判斷文件是否被任何其他 .md 以相對路徑引用
# 參數：$1 = 相對於專案根目錄的文件路徑（如 docs/km/Tech_Debt_Registry.md）
# 回傳：0 = 有引用，1 = 無引用
# ---------------------------------------------------------------------------
is_referenced() {
  local filepath="$1"
  local filename
  filename=$(basename "$filepath")

  # 搜尋所有 .md 文件中是否有對此文件名的 Markdown link 引用
  # 只匹配真實的 Markdown 相對路徑引用格式：
  #   [text](filename.md)
  #   [text](./filename.md)
  #   [text](../dir/filename.md)
  #   [text](dir/filename.md)
  # 排除純文字敘述、程式碼區塊中的路徑字串
  if grep -rlE --include="*.md" "\]\([^)]*${filename}\)" . 2>/dev/null \
      | grep -v "^\./${filepath}$" \
      | grep -v "^\\./.git/" \
      | grep -q .; then
    return 0
  fi

  return 1
}

# ---------------------------------------------------------------------------
# scan_and_detect_orphans：掃描 docs/ 下所有 .md 文件並偵測孤兒
# ---------------------------------------------------------------------------
scan_and_detect_orphans() {
  local orphan_list=()
  local allowlisted_list=()

  while IFS= read -r md_file; do
    # 去掉開頭的 "./" 讓路徑更乾淨
    local clean_path="${md_file#./}"
    SCANNED_COUNT=$((SCANNED_COUNT + 1))

    # 檢查是否豁免（CLASS_1~4 硬編碼規則）
    if is_exempt "$clean_path"; then
      continue
    fi

    # 檢查是否被引用
    if ! is_referenced "$clean_path"; then
      # 檢查是否在 .orphan-allowlist 豁免清單中（CLASS_5，#658）
      if is_allowlisted "$clean_path"; then
        allowlisted_list+=("$clean_path")
        INFO_ALLOWLISTED_COUNT=$((INFO_ALLOWLISTED_COUNT + 1))
      else
        orphan_list+=("$clean_path")
        ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
      fi
    fi

  done < <(find "./${DOCS_DIR}" -name "*.md" -not -path "./.git/*" | sort)

  # 輸出 .orphan-allowlist 豁免的文件（INFO 級別，不計入 WARNING）
  for allowlisted in "${allowlisted_list[@]+"${allowlisted_list[@]}"}"; do
    echo "[INFO] ${allowlisted}: 永久性孤兒（已加入 .orphan-allowlist 豁免，不計 WARNING）"
  done

  # 輸出孤兒警告
  for orphan in "${orphan_list[@]+"${orphan_list[@]}"}"; do
    echo "WARNING: ${orphan}: 孤兒文件（無任何 .md 引用）"
    WARNING_COUNT=$((WARNING_COUNT + 1))
  done
}

# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
main() {
  print_banner "US-T09：孤兒文件偵測"

  preflight_check

  print_section "掃描 ${DOCS_DIR}/ 目錄"

  scan_and_detect_orphans

  # 摘要
  print_section "摘要"
  print_info "掃描 ${SCANNED_COUNT} 個 .md 文件（含豁免項目）"

  if [[ $INFO_ALLOWLISTED_COUNT -gt 0 ]]; then
    print_info "${INFO_ALLOWLISTED_COUNT} 個永久性孤兒已由 .orphan-allowlist 豁免（[INFO]，不計 WARNING）"
  fi

  if [[ $ORPHAN_COUNT -gt 0 ]]; then
    print_info "偵測到 ${ORPHAN_COUNT} 個孤兒文件（WARNING，不阻塞 CI）"
    print_info "處置方式：在 Retro 列為 Problem，由 PO 裁定刪除 / 補充引用 / 加入 .orphan-allowlist"
  else
    print_pass "未偵測到孤兒文件，docs/ 文件結構健康"
  fi

  # exit code 永遠為 0（warning 不阻塞 CI）
  exit 0
}

main
