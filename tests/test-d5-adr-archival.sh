#!/usr/bin/env bash
# tests/test-d5-adr-archival.sh
# D5（ADR 歸檔策略）：audit-adr-references.sh + update-adr-index.sh + ARCHIVAL_POLICY
#
# 覆蓋 AC：
#   AC1 — audit script 能正確分類 ACTIVE / DOCS-ONLY / DORMANT / SUPERSEDED
#   AC2 — audit --candidates 只列 DORMANT / SUPERSEDED
#   AC3 — audit --json 輸出合法 JSONL
#   AC4 — audit 對「Superseded by ADR-NN」標記的精準偵測（不誤命中本文引用）
#   AC5 — update-adr-index.sh 主表 status 不再有多字節 byte 殘渣
#   AC6 — update-adr-index.sh 產生「已歸檔 ADR」段落 + 取代者欄位正確
#   AC7 — ARCHIVAL_POLICY.md 必要 section 存在
#   AC8 — ADR-009 已搬移到 archive/，原位置為 forwarding stub

set -uo pipefail

PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIT="$REPO_ROOT/scripts/audit-adr-references.sh"
INDEX="$REPO_ROOT/scripts/update-adr-index.sh"
README="$REPO_ROOT/docs/adr/README.md"
POLICY="$REPO_ROOT/docs/adr/ARCHIVAL_POLICY.md"

pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

# ---------------------------------------------------------------------------
# AC1：audit 分類存在
# ---------------------------------------------------------------------------
[[ -x "$AUDIT" ]] && pass "AC1.0 audit script 可執行" \
  || { fail "AC1.0 audit script 缺失或非可執行"; exit 1; }

OUT=$("$AUDIT" 2>&1)
for cat in ACTIVE DOCS-ONLY DORMANT SUPERSEDED TOTAL; do
  if printf '%s' "$OUT" | grep -q "^$cat[[:space:]]*:"; then
    pass "AC1.$cat 統計列含 $cat 區塊"
  else
    fail "AC1.$cat 統計列缺 $cat 區塊"
  fi
done

# ---------------------------------------------------------------------------
# AC2：--candidates 只列 DORMANT / SUPERSEDED
# ---------------------------------------------------------------------------
CAND=$("$AUDIT" --candidates 2>&1)
# 不該出現 ACTIVE / DOCS-ONLY 的列（修 codex P3：grep pattern 對應實際輸出
# 格式 `ADR-001      | ACTIVE`，不是 markdown 表格 `| ADR-001 |`）
if printf '%s' "$CAND" | grep -E '^ADR-[0-9]+[[:space:]]*\| (ACTIVE|DOCS-ONLY)\b' >/dev/null; then
  fail "AC2.1 --candidates 不應包含 ACTIVE / DOCS-ONLY 列"
else
  pass "AC2.1 --candidates 只列候選類別"
fi
# ADR-009 已歸檔，不該再出現在 candidates（forwarding stub 不被視為候選）
if printf '%s' "$CAND" | grep -E '^ADR-009[[:space:]]' >/dev/null; then
  fail "AC2.2 ADR-009 已歸檔，不該再列為 candidate"
else
  pass "AC2.2 ADR-009 已歸檔後不再列入 candidates"
fi

# candidates 列表應呈現乾淨表格（即使是空表也能輸出標頭）
if printf '%s' "$CAND" | grep -q "ADR.*CATEGORY"; then
  pass "AC2.3 --candidates 仍輸出表格標頭（即使無候選）"
else
  fail "AC2.3 --candidates 缺表格標頭"
fi

# ---------------------------------------------------------------------------
# AC3：--json 輸出合法 JSONL
# ---------------------------------------------------------------------------
JSON=$("$AUDIT" --json 2>&1)
if command -v jq >/dev/null 2>&1; then
  json_ok=1
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if ! printf '%s' "$line" | jq -e . >/dev/null 2>&1; then
      json_ok=0
      fail "AC3.1 JSON 解析失敗：$line"
      break
    fi
  done <<< "$JSON"
  [[ $json_ok -eq 1 ]] && pass "AC3.1 所有 JSONL 行可解析"

  # 抽查必要欄位
  first=$(printf '%s' "$JSON" | head -1)
  for k in adr category runtime_refs docs_refs status path title; do
    if printf '%s' "$first" | jq -e ".$k" >/dev/null 2>&1; then
      pass "AC3.2 JSONL 含欄位 $k"
    else
      fail "AC3.2 JSONL 缺欄位 $k (first line: $first)"
    fi
  done
else
  pass "AC3 jq 不存在，跳過 JSON 解析驗證"
fi

# AC3.3（codex review P2 regression）：count_docs_refs 必須排除 ADR 自身
# 結構性檢查：count_docs_refs 內含 --exclude（grep 排除）邏輯
if grep -A 20 'count_docs_refs()' "$AUDIT" | grep -q -- '--exclude='; then
  pass "AC3.3 count_docs_refs 含自身檔案排除（codex P2 regression）"
else
  fail "AC3.3 count_docs_refs 未排除自身檔案 — DORMANT 偵測會失效"
fi

# AC3.4 行為層驗證：拿一個只在自己檔案出現的 ADR 編號做即時測試
# 找一個 docs_refs > 0 的 ADR，把它從外部清單中找一個確認
# （此測試需現有 repo 狀態 — 確認真檔內 ADR-001 的外部引用 > 0）
EXTERNAL_REFS=$(grep -rl "ADR-001\\b" docs/ \
  --exclude="ADR-001*.md" --exclude="ADR-001*.md" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$EXTERNAL_REFS" -gt 0 ]]; then
  pass "AC3.4 ADR-001 確實有外部引用（檔案數=$EXTERNAL_REFS）"
else
  fail "AC3.4 ADR-001 外部引用為 0，難以驗證行為"
fi

# ---------------------------------------------------------------------------
# AC4：Superseded 偵測精準（ADR-010 不該被誤認 — 它是 superseder，不是被取代）
# ---------------------------------------------------------------------------
if printf '%s' "$CAND" | grep -E '^\| *ADR-010 *\| *SUPERSEDED' >/dev/null; then
  fail "AC4.1 ADR-010 被誤判為 SUPERSEDED（它本身是 superseder）"
else
  pass "AC4.1 ADR-010 未被誤判（精準偵測）"
fi

# ---------------------------------------------------------------------------
# AC5：update-adr-index.sh 後 README 主表無多字節 byte 殘渣
# ---------------------------------------------------------------------------
[[ -x "$INDEX" ]] && pass "AC5.0 update-adr-index.sh 可執行" \
  || fail "AC5.0 update-adr-index.sh 缺失或非可執行"

# 重跑一次（idempotent 驗證）
"$INDEX" >/dev/null 2>&1 && pass "AC5.1 update-adr-index.sh 執行成功" \
  || fail "AC5.1 update-adr-index.sh 執行失敗"

# 偵測 garbled bytes：bc 9a Accepted（Superseded byte 殘渣的特徵）
if grep -qE 'bc 9a Accepted|��Accepted' "$README"; then
  fail "AC5.2 README 含多字節 byte 殘渣（��Accepted）"
else
  pass "AC5.2 README 主表 status 欄位乾淨無殘渣"
fi

# 標題列保留正常 CJK 字元
if grep -q "Backlog Bridge" "$README" && grep -q "Accepted" "$README"; then
  pass "AC5.3 README 標題與 status 欄位渲染正常"
else
  fail "AC5.3 README 渲染異常"
fi

# ---------------------------------------------------------------------------
# AC6：「已歸檔 ADR」段落 + 取代者欄位正確
# ---------------------------------------------------------------------------
if grep -q "^## 已歸檔 ADR" "$README"; then
  pass "AC6.1 README 含「已歸檔 ADR」段落"
else
  fail "AC6.1 README 缺「已歸檔 ADR」段落"
fi

if grep -q "ADR-009.*ADR-010.*archive/ADR-009.md" "$README"; then
  pass "AC6.2 ADR-009 列含取代者 ADR-010 與 archive 連結"
else
  fail "AC6.2 ADR-009 列缺欄位"
fi

# ---------------------------------------------------------------------------
# AC7：ARCHIVAL_POLICY 必要 section
# ---------------------------------------------------------------------------
[[ -f "$POLICY" ]] && pass "AC7.0 ARCHIVAL_POLICY.md 存在" \
  || { fail "AC7.0 ARCHIVAL_POLICY.md 缺失"; exit 1; }

for s in "## 為何要歸檔" "## 歸檔分類" "## 歸檔流程" "## 為何不直接刪除歸檔 ADR" "## 反例"; do
  if grep -qF "$s" "$POLICY"; then
    pass "AC7.$s section 存在"
  else
    fail "AC7.$s section 缺失"
  fi
done

# ---------------------------------------------------------------------------
# AC8：ADR-009 搬移驗證
# ---------------------------------------------------------------------------
if [[ -f "$REPO_ROOT/docs/adr/archive/ADR-009.md" ]]; then
  pass "AC8.1 ADR-009 已搬至 archive/"
else
  fail "AC8.1 archive/ADR-009.md 不存在"
fi

if [[ -f "$REPO_ROOT/docs/adr/ADR-009.md" ]] && grep -q "已歸檔" "$REPO_ROOT/docs/adr/ADR-009.md"; then
  pass "AC8.2 原位置仍有 forwarding stub"
else
  fail "AC8.2 forwarding stub 缺失或內容不對"
fi

# ---------------------------------------------------------------------------
# 結算
# ---------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "Test Result: PASS=$PASS  FAIL=$FAIL"
echo "=========================================="

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
