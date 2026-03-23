# shoot 文件產出規則

本文件定義 `/shoot` 的文件產出、歸檔、輸出範例等規則，由 `skills/shoot/SKILL.md` 按需載入。

---

## 文件產出（AC5）

每次 `/shoot` 成功完成後，同時更新以下兩份文件：

### docs/km/shoot-log/（per-session，US-322 AC-1）

<!-- US-322 AC-1 — Shoot Log 改為 per-session + 結算 — Sprint 110 -->

**路徑格式**：`docs/km/shoot-log/YYYY-MM-DD-session-<SESSION_ID>.md`

每個 session 寫入自己的檔案（天然隔離，零 conflict）。`SESSION_ID` 來源：
- 優先使用環境變數 `SESSION_ID`（Claude Code 注入）
- 無環境變數時使用 `unknown-$(date +%s)` 作為備援

**寫入指令**：
```bash
SESSION_ID="${SESSION_ID:-unknown-$(date +%s)}"
TODAY="$(date '+%Y-%m-%d')"
LOG_DIR="docs/km/shoot-log"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/${TODAY}-session-${SESSION_ID}.md"
echo "| ${TODAY} | <來源> | <標題> | PASS | <hash> |" >> "$LOG_FILE"
```

**格式**（Markdown 表格列）：

```markdown
| YYYY-MM-DD | auto/direct/#N/US-#N | 任務標題 | PASS | abc1234 |
```

**欄位說明**：

| 欄位 | 格式 | 說明 |
|------|------|------|
| 日期 | `YYYY-MM-DD` | 任務完成日期 |
| 來源 | `auto` / `direct` / `#N` / `US-#N` | 任務來源類型 |
| 標題 | 原始任務文字 | 完整保留，不截斷 |
| 結果 | `PASS` / `FAIL` | 執行結果（FAIL 時不寫入） |
| commit hash | 7 碼 short hash | `shoot:` commit 的 hash |

**結算腳本**：`hooks/shoot-log-settle.sh`（合併同日 per-session 檔案為 summary.md）

**protect-main.sh 豁免**：`^docs/km/shoot-log/` 已加入豁免清單，允許直推 main。

### docs/PROJECT_BOARD.md 短衝記錄

在 `docs/PROJECT_BOARD.md` 的「短衝記錄」區塊新增條目：

```markdown
## 短衝記錄

| 日期 | 標題 | Issue/Story | commit hash |
|------|------|-------------|-------------|
| YYYY-MM-DD | 任務標題 | #N 或 US-#N 或 — | abc1234 |
```

若「短衝記錄」區塊不存在，在 `PROJECT_BOARD.md` 末尾新增此區塊。

### git commit 格式

```bash
git commit -m "shoot: <任務標題>"
```

---

## 瘦身歸檔（AC6）

### 觸發條件

`docs/km/Shoot_Log.md` 主文件超過 **20 筆**記錄時觸發歸檔。

### 歸檔規則

- **目標**：移至**恰好保留 20 筆**（移走 `筆數 - 20` 筆）
- **移出對象**：最舊的 `筆數 - 20` 筆記錄
- **移出目標**：附加至 `docs/km/archive/SHOOT_LOG_ARCHIVE.md`
- **更新文件**：同步更新 `docs/km/archive/README.md` 的歸檔範圍欄位與最後更新日期

### 邊界測試情境

| 總筆數 | 移出筆數 | 剩餘筆數 | 說明 |
|--------|---------|---------|------|
| 20 | 0 | 20 | **20 筆不觸發**歸檔 |
| 21 | 1 | 20 | **21 筆**移出 1 筆 |
| 25 | 5 | 20 | 移出 5 筆 |
| 26 | 6 | 20 | 移出 6 筆 |

### 歸檔計算公式

```bash
# 計算需移出筆數
TOTAL=$(count_shoot_log_entries "docs/km/Shoot_Log.md")
KEEP=20
if [ "$TOTAL" -gt "$KEEP" ]; then
  ARCHIVE_COUNT=$((TOTAL - KEEP))
  # 移出最舊的 ARCHIVE_COUNT 筆記錄至 SHOOT_LOG_ARCHIVE.md
fi
```

### SHOOT_LOG_ARCHIVE.md 格式

```markdown
# Shoot Log Archive

| 日期 | 來源 | 標題 | 結果 | commit hash |
|------|------|------|------|-------------|
| YYYY-MM-DD | auto | 任務標題 | PASS | abc1234 |
```

---

## 動態建立的檔案

以下檔案由 Shoot Skill 在首次執行時動態建立，不需預先建立：

| 檔案路徑 | 建立時機 | 說明 |
|---------|---------|------|
| `docs/km/shoot-log/YYYY-MM-DD-session-<ID>.md` | 每次 `/shoot` 成功完成時 | per-session 短衝記錄（US-322 AC-1） |
| `docs/km/shoot-log/YYYY-MM-DD.summary.md` | 執行 `hooks/shoot-log-settle.sh` 時 | 當日結算彙整 |
| `docs/km/archive/SHOOT_LOG_ARCHIVE.md` | 首次觸發歸檔時 | 超過 20 筆時的歸檔目標 |

---

## Sprint Review 連動（AC7）

`/sprint-review` 執行時，會掃描 `docs/km/shoot-log/` 目錄下的 per-session 檔案與 summary.md，將 Sprint 期間的短衝記錄列入「Sprint 外完成項目」區塊。

詳見 `skills/sprint-review/SKILL.md` 的相關段落。

---

## 輸出範例

### 成功執行（/shoot "修復 CSS 問題"）

```
── 任務解析 ───────────────────────────
  來源：direct
  標題：修復 CSS 問題

── 測試可寫性檢查 ─────────────────────
  [PASS] 所有 AC 可轉化為測試

── QA Pre-flight ──────────────────────
  [PASS] 任務範圍檢查
  [PASS] 安全疑慮檢查
  [PASS] 架構影響檢查

── Architect 審查 ─────────────────────
  [PASS] 架構符合性確認
  [PASS] 無 ADR 觸發
  [PASS] Layer Compliance 共用常數/設定層級檢查
  [PASS] Layer Compliance 跨模組 import 方向檢查
  [PASS] Layer Compliance Single Source of Truth 檢查
  [PASS] DM-1 業務邏輯封裝檢查
  [PASS] DM-2 Single Source of Truth 檢查
  [PASS] DM-3 狀態轉換統一檢查
  [PASS] DM-4 共享寫入入口檢查

── 執行任務 ───────────────────────────
  ... 實作過程 ...

── QA Post-check ──────────────────────
  Spec Compliance：
    [PASS] AC 逐條驗證
    [PASS] 邊界條件檢查
  Code Quality：
    [PASS] 通用靜態分析
    [PASS] CQ-NEW 測試覆蓋

── 外部獨立審查 ───────────────────────
  [CONFIRM] Spec Compliance + Code Quality 通過

── pr-review-toolkit 補充審查 ────────
  code-reviewer：      [PASS] 無 CRITICAL/HIGH issue
  silent-failure-hunter：[PASS] 無 CRITICAL/HIGH issue
  comment-analyzer：    [PASS] 無 Critical Issues

── git commit + push ─────────────────
  ✓ git commit：shoot: 修復 CSS 問題（abc1234）
  ✓ git push 完成

── CI Gate ────────────────────────────
  [PASS] CI 檢查通過（workflow: CI / run: https://github.com/.../runs/123）

── 文件更新 ───────────────────────────
  ✓ Shoot_Log.md 已更新（PASS）
  ✓ PROJECT_BOARD.md 短衝記錄已更新

✓ 短衝完成 — 修復 CSS 問題
```

### FAIL 場景 — QA Pre-flight

```
── QA Pre-flight ──────────────────────
  [FAIL] 任務範圍超出 Size=S，建議拆分為多個子任務

[ERROR] QA Pre-flight FAIL，終止執行
  - exit code：1（非 0）
  - Shoot_Log.md 未更新（無 PASS 記錄）
  - git commit 未執行
```

### FAIL 場景 — CI Gate

```
── CI Gate ────────────────────────────
  [FAIL] CI 檢查未通過，中止寫入 Shoot_Log PASS
  Workflow：CI
  Run URL ：https://github.com/org/repo/actions/runs/456
  結論    ：failure

[ERROR] CI Gate FAIL，終止執行
  - exit code：1（非 0）
  - Shoot_Log.md 未更新（無 PASS 記錄）
```

### CI 不可用場景（降級）

```
── CI Gate ────────────────────────────
  [WARN] gh CLI 未安裝，跳過 CI Gate
  CI Gate 已略過，手動確認 CI 狀態後再繼續

── 文件更新 ───────────────────────────
  ✓ Shoot_Log.md 已更新（PASS，CI Gate 略過）
  ✓ PROJECT_BOARD.md 短衝記錄已更新
```

---

## 與其他 Skill 的關係

| 情境 | 說明 |
|------|------|
| Sprint Review 時掃描 | `/sprint-review` 會讀取 Shoot_Log.md，列出「Sprint 外完成項目」 |
| 歸檔觸發 | 主文件超 20 筆時附加至 SHOOT_LOG_ARCHIVE.md |
| Hard Gate 保留 | QA 雙階段審查與 Architect 審查無論如何都保留，不可略過 |
