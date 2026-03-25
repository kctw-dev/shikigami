---
name: doctor
description: "Use when diagnosing a consumer project's Shikigami setup health — checks configuration, hooks, directory structure, CLI tools, and applies automatic fixes where possible"
---

# Doctor — 消費端專案健康診斷

## 1. 概述

Doctor Skill 是消費端專案（已安裝 Shikigami 的專案）的四階段健康診斷工具。像醫生一樣依序執行「體檢→問診→處置→追蹤」，快速識別 CRITICAL / WARNING / INFO 等級問題，能自動修的立即修，不能自動修的給出明確操作步驟並建立追蹤 Issue。

**觸發方式**：使用者說「診斷我的專案」、「幫我檢查 Shikigami 設定」、「/shikigami:doctor」時由 Scrum Master 路由至此 Skill。

**執行時間**：< 30 秒（純檢查，不含自動修復）

---

## 2. 四階段流程

### 第一階段：檢查（體檢）

掃描消費端專案，逐項執行以下 8 項必要條件檢查：

| # | 項目 | 檢查指令 | 通過條件 |
|---|------|---------|---------|
| 1 | CLAUDE.md | `ls CLAUDE.md` | 存在且含 shikigami 設定（grep 'shikigami'） |
| 2 | shikigami.local.md | `ls .claude/shikigami.local.md` | 存在且 YAML frontmatter 格式正確 |
| 3 | claim/release hooks | `ls hooks/claim-issue.sh hooks/release-issue.sh` | 兩個檔案存在且可執行（`-x`） |
| 4 | docs/ 目錄結構 | `ls docs/sprints/ docs/PROJECT_BOARD.md docs/prd/` | 三個路徑均存在 |
| 5 | gh CLI | `gh auth status` | 退出碼 0（已認證） |
| 6 | GitHub remote | `git remote get-url origin` | 回傳有效 GitHub URL（含 github.com） |
| 7 | git pre-commit hook | `ls .git/hooks/pre-commit` | 存在且可執行 |
| 8 | .gitignore 排除項 | `grep -E 'logs/\|shikigami.local.md' .gitignore` | 兩項均已排除 |

```bash
# 第一階段執行偽碼
CHECKS=()
check_item() {
  local name="$1" cmd="$2" pass_condition="$3"
  local result
  result=$(eval "$cmd" 2>&1)
  local exit_code=$?
  if eval "$pass_condition"; then
    CHECKS+=("PASS|${name}")
  else
    CHECKS+=("FAIL|${name}|${result}")
  fi
}

check_item "CLAUDE.md" "ls CLAUDE.md 2>/dev/null && grep -l 'shikigami' CLAUDE.md 2>/dev/null" "[[ $exit_code -eq 0 ]]"
check_item "shikigami.local.md" "ls .claude/shikigami.local.md 2>/dev/null" "[[ $exit_code -eq 0 ]]"
check_item "claim/release hooks" "ls hooks/claim-issue.sh hooks/release-issue.sh 2>/dev/null && test -x hooks/claim-issue.sh && test -x hooks/release-issue.sh" "[[ $exit_code -eq 0 ]]"
check_item "docs/ 目錄結構" "ls docs/sprints/ docs/PROJECT_BOARD.md docs/prd/ 2>/dev/null" "[[ $exit_code -eq 0 ]]"
check_item "gh CLI" "gh auth status 2>/dev/null" "[[ $exit_code -eq 0 ]]"
check_item "GitHub remote" "git remote get-url origin 2>/dev/null | grep -q 'github.com'" "[[ $exit_code -eq 0 ]]"
check_item "git pre-commit hook" "test -x .git/hooks/pre-commit 2>/dev/null" "[[ $exit_code -eq 0 ]]"
check_item ".gitignore 排除項" "grep -E 'logs/' .gitignore 2>/dev/null && grep -E 'shikigami.local.md' .gitignore 2>/dev/null" "[[ $exit_code -eq 0 ]]"
```

---

### 第二階段：問診（比對症狀）

將第一階段結果依嚴重度分類：

| 等級 | 符號 | 條件 | 說明 |
|------|------|------|------|
| **CRITICAL** | `[CRIT]` | 阻塞工作流程 | CLAUDE.md 不存在、gh CLI 未認證、GitHub remote 無效 |
| **WARNING** | `[WARN]` | 降級運作 | claim/release hooks 缺失或不可執行、docs/ 目錄不完整 |
| **INFO** | `[INFO]` | 可改善 | .gitignore 未排除必要項、pre-commit hook 未啟用 |

```bash
# 嚴重度分類映射
declare -A SEVERITY_MAP
SEVERITY_MAP["CLAUDE.md"]="CRITICAL"
SEVERITY_MAP["shikigami.local.md"]="CRITICAL"
SEVERITY_MAP["gh CLI"]="CRITICAL"
SEVERITY_MAP["GitHub remote"]="CRITICAL"
SEVERITY_MAP["claim/release hooks"]="WARNING"
SEVERITY_MAP["docs/ 目錄結構"]="WARNING"
SEVERITY_MAP["git pre-commit hook"]="INFO"
SEVERITY_MAP[".gitignore 排除項"]="INFO"
```

**問診輸出格式**：

```
[Doctor] 第二階段：問診結果
  [CRIT] CLAUDE.md — 不存在或缺少 shikigami 設定（阻塞：Shikigami 無法載入配置）
  [WARN] claim/release hooks — 缺失（降級：多 Session 並行保護失效）
  [INFO] .gitignore — 未排除 shikigami.local.md（可改善：避免本地配置外洩）
```

---

### 第三階段：處置（自動修復 + 手動建議）

**可自動修復的項目**（直接執行，不需確認）：

| 問題 | 自動修復動作 |
|------|------------|
| claim/release hooks 缺失 | 從 `${CLAUDE_PLUGIN_ROOT}/hooks/` 複製至 `hooks/`，chmod +x |
| docs/ 目錄結構不完整 | `mkdir -p docs/sprints docs/prd`，從 templates/ 複製初始文件 |
| .gitignore 未排除項 | `echo "logs/" >> .gitignore` + `echo ".claude/shikigami.local.md" >> .gitignore` |

**不能自動修復的項目**（給出明確操作步驟）：

| 問題 | 手動操作步驟 |
|------|------------|
| CLAUDE.md 不存在 | 執行 `/shikigami:onboarding` 完整初始化 |
| shikigami.local.md 不存在 | 複製 `templates/shikigami.local.md` 至 `.claude/shikigami.local.md` |
| gh CLI 未認證 | 執行 `gh auth login` |
| GitHub remote 無效 | 執行 `git remote add origin <GitHub URL>` |
| git pre-commit hook 未啟用 | 複製 `hooks/pre-commit` 至 `.git/hooks/pre-commit`，chmod +x |

```bash
# 第三階段：自動修復偽碼
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname $(dirname $(realpath "$0")))}"
FIXED_ITEMS=()
MANUAL_ITEMS=()
DOCTOR_REPORT_ENTRIES=()

for check_result in "${CHECKS[@]}"; do
  if [[ "$check_result" == FAIL* ]]; then
    item=$(echo "$check_result" | cut -d'|' -f2)
    case "$item" in
      "claim/release hooks")
        cp "${PLUGIN_ROOT}/hooks/claim-issue.sh" hooks/ 2>/dev/null
        cp "${PLUGIN_ROOT}/hooks/release-issue.sh" hooks/ 2>/dev/null
        chmod +x hooks/claim-issue.sh hooks/release-issue.sh 2>/dev/null
        FIXED_ITEMS+=("$item")
        ;;
      "docs/ 目錄結構")
        mkdir -p docs/sprints docs/prd
        FIXED_ITEMS+=("$item")
        ;;
      ".gitignore 排除項")
        grep -q 'logs/' .gitignore 2>/dev/null || echo "logs/" >> .gitignore
        grep -q 'shikigami.local.md' .gitignore 2>/dev/null || echo ".claude/shikigami.local.md" >> .gitignore
        FIXED_ITEMS+=("$item")
        ;;
      *)
        MANUAL_ITEMS+=("$item")
        ;;
    esac
    DOCTOR_REPORT_ENTRIES+=("${SEVERITY_MAP[$item]:-INFO}|${item}|$(echo "$check_result" | cut -d'|' -f3)")
  fi
done
```

---

### 第四階段：追蹤（開 Issue + 下次複診）

**GitHub Issue 建立規則**：

- 僅對 **CRITICAL** 與 **WARNING** 等級且**無法自動修復**的項目建立 Issue
- label: `doctor`, `priority: must`（CRITICAL）或 `priority: should`（WARNING）
- 冪等性：建立前先搜尋標題，避免重複

```bash
# 第四階段：建立追蹤 Issue
OWNER_REPO=$(git remote get-url origin | sed -E 's#^(https?://[^/]+/|git@[^:]+:)##; s#\.git$##')

for item in "${MANUAL_ITEMS[@]}"; do
  severity="${SEVERITY_MAP[$item]:-INFO}"
  if [[ "$severity" == "CRITICAL" || "$severity" == "WARNING" ]]; then
    issue_title="[Doctor] ${item} — ${severity} 需手動修復"
    existing=$(gh issue list -R "$OWNER_REPO" --search "\"$issue_title\"" --state open --json number 2>/dev/null | jq 'length')
    if [[ "$existing" -eq 0 ]]; then
      priority_label="priority: must"
      [[ "$severity" == "WARNING" ]] && priority_label="priority: should"
      printf '[Doctor] 自動建立追蹤 Issue\n\n項目: %s\n嚴重度: %s\n\n%s\n' \
        "$item" "$severity" "$(get_manual_steps "$item")" > /tmp/doctor-issue-body.txt
      gh issue create -R "$OWNER_REPO" \
        --title "$issue_title" \
        --body-file /tmp/doctor-issue-body.txt \
        --label "doctor,${priority_label}" 2>/dev/null || true
    fi
  fi
done
```

**Doctor Report 寫入**：

```bash
# 寫入 docs/km/doctor-report/YYYY-MM-DD.md
REPORT_DATE=$(date '+%Y-%m-%d')
REPORT_DIR="docs/km/doctor-report"
mkdir -p "$REPORT_DIR"
REPORT_FILE="${REPORT_DIR}/${REPORT_DATE}.md"

cat > "$REPORT_FILE" << EOF
# Doctor Report — ${REPORT_DATE}

## 檢查摘要

| 項目 | 等級 | 狀態 | 處置 |
|------|------|------|------|
$(for entry in "${DOCTOR_REPORT_ENTRIES[@]}"; do
  level=$(echo "$entry" | cut -d'|' -f1)
  item=$(echo "$entry" | cut -d'|' -f2)
  detail=$(echo "$entry" | cut -d'|' -f3)
  echo "| $item | $level | FAIL | $detail |"
done)

## 自動修復項目
$(for item in "${FIXED_ITEMS[@]}"; do echo "- $item ✅"; done)

## 手動處置項目
$(for item in "${MANUAL_ITEMS[@]}"; do echo "- $item — 詳見追蹤 Issue"; done)

生成時間：$(date '+%Y-%m-%dT%H:%M:%S')
EOF

echo "[Doctor] 報告已寫入 ${REPORT_FILE}"
```

**Cruise 定期觸發**（AC6）：

Cruise 巡邏每 10 個 cycle 自動觸發一次 doctor 檢查。設定於 `skills/cruise/references/startup-flow.md` §4.3（待後續 Sprint 實作，本 Sprint 完成 Skill 定義）。

---

## 3. 輸出格式

```
[Doctor] ============================================================
[Doctor] 消費端專案健康診斷 — $(date '+%Y-%m-%d %H:%M:%S')
[Doctor] ============================================================

第一階段：體檢（8 項）
  [PASS] CLAUDE.md
  [PASS] shikigami.local.md
  [FAIL] claim/release hooks
  [PASS] docs/ 目錄結構
  [PASS] gh CLI
  [PASS] GitHub remote
  [FAIL] git pre-commit hook
  [FAIL] .gitignore 排除項

第二階段：問診
  [WARN] claim/release hooks — hooks/ 目錄缺少可執行 hooks 檔案
  [INFO] git pre-commit hook — .git/hooks/pre-commit 不存在
  [INFO] .gitignore — 未排除 shikigami.local.md

第三階段：處置
  [AUTO-FIX] claim/release hooks → 從 plugin 複製並 chmod +x ✅
  [AUTO-FIX] .gitignore → 已加入排除項 ✅
  [MANUAL] git pre-commit hook → 步驟：cp hooks/pre-commit .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

第四階段：追蹤
  [SKIP] 無需建立 Issue（所有問題已自動修復或為 INFO 等級）
  [REPORT] 已寫入 docs/km/doctor-report/2026-03-25.md

[Doctor] 整體狀態：WARNING（1 項需手動處置）
[Doctor] ============================================================
```

---

## 4. 整體狀態判定

| 條件 | 整體狀態 |
|------|---------|
| 所有檢查 PASS，或僅剩 INFO 等級問題 | `HEALTHY` |
| 有 WARNING 等級問題（含自動修復後仍存在的）| `WARNING` |
| 有 CRITICAL 等級問題 | `CRITICAL` |

---

## 5. 非功能性需求

- **NFR1（效能）**：純檢查階段 < 30 秒
- **NFR2（安全）**：不修改業務代碼，只修框架配置檔
- **NFR3（冪等性）**：多次執行結果一致，自動修復動作冪等（不重複操作）
- **NFR4（降級）**：gh CLI 不可用時，第四階段跳過 Issue 建立，仍完成 Report 寫入
