---
name: performance-dashboard
description: "Use when generating AI team performance dashboards — attendance hours, exploration logs, meeting summaries, and Sprint velocity metrics"
requiredTools:
  - Read
  - Glob
  - Bash
---

# Performance Dashboard Skill — 績效儀表板

**關聯 Story**：US-317（Issue #317）Phase 4
**關聯 ADR**：ADR-024（出勤機制）、ADR-025（探索紀錄）

## 1. 概述

`/performance-dashboard` 讀取三類已結算資料（出勤、探索、會議），輸出單日績效 Markdown 報表。

- **出勤**：`docs/attendance/<date>.summary.jsonl`（已結算）
- **探索**：`docs/exploration/<date>.summary.jsonl`（已結算）
- **會議**：`docs/meetings/<date>-*.md`（即時掃描）

> 儀表板只讀 `*.summary.jsonl`（已結算）。若需結算，請先執行對應 settle 腳本。

---

## 2. 觸發語法

```
/performance-dashboard
/performance-dashboard --date YYYY-MM-DD
```

| 參數 | 必填 | 預設 | 說明 |
|------|------|------|------|
| `--date YYYY-MM-DD` | 否 | 今日（由 `date` 指令取得） | 指定報表日期 |

---

## 3. 執行流程

### 步驟 1：取得日期

```bash
# 預設今日
REPORT_DATE="$(date '+%Y-%m-%d')"
# 若指定 --date 參數，使用指定值
```

> 日期必須用 `date` 指令取得，不可靠 agent 推斷（開發紅線第 6 條）。

### 步驟 2：讀取出勤資料

讀取 `docs/attendance/${REPORT_DATE}.summary.jsonl`。

- 若檔案**不存在**：顯示 AC6 提示（見第 5 節），不自動執行結算。
- 若檔案**存在**：逐行解析 JSONL，配對 checkin/checkout 事件，計算各角色時數。

#### JSONL 欄位
```jsonl
{"session_id":"...","role":"scrum-master","event":"checkin","timestamp":"2026-03-20T09:00:00+0800","repo":"shikigami"}
{"session_id":"...","role":"scrum-master","event":"checkout","timestamp":"2026-03-20T10:30:00+0800","repo":"shikigami"}
```

#### 計算邏輯
1. 依 `session_id` 分組，配對 checkin/checkout 計算時長
2. 累加各角色總時數
3. 取首次 checkin（最小 timestamp）與末次 checkout（最大 timestamp）

### 步驟 3：讀取探索資料

讀取 `docs/exploration/${REPORT_DATE}.summary.jsonl`。

- 若檔案**不存在**：顯示 AC6 提示（見第 5 節）。
- 若檔案**存在**：統計 WebSearch/WebFetch 筆數，並列出 top-5 query_or_url（依出現頻率排序）。

#### JSONL 欄位
```jsonl
{"session_id":"...","role":"scrum-master","event":"explore","timestamp":"...","tool":"WebSearch","query_or_url":"shikigami attendance hook","repo":"shikigami"}
```

### 步驟 4：掃描會議紀錄

使用 Glob 掃描 `docs/meetings/${REPORT_DATE}-*.md`。

- 無檔案：會議場數為 0。
- 有檔案：解析每份 Markdown 的 YAML frontmatter，提取 `type`、`sprint`、`start_time`、`end_time`、`participants`。

#### 時長計算
```bash
# 從 start_time / end_time 計算 duration（分鐘）
```

### 步驟 5：輸出 Markdown 報表

依第 4 節格式輸出。

---

## 4. 報表格式

```markdown
# 績效儀表板 — YYYY-MM-DD

## 出勤摘要

| 角色 | Session 數 | 總時數 | 首次簽到 | 末次簽退 |
|------|-----------|-------|---------|---------|
| scrum-master | 2 | 3h 30m | 09:00 | 12:30 |

## 探索紀錄摘要

| 筆數 | WebSearch | WebFetch | Top-5 查詢/URL |
|------|-----------|----------|---------------|
| 12 | 8 | 4 | shikigami attendance hook, ... |

## 會議紀錄摘要

| 類型 | Sprint | 時長 | 參與角色 | 檔案 |
|------|--------|------|---------|------|
| sprint-review | 108 | 15m | PO, QA, SM | [2026-03-20-sprint-review.md](docs/meetings/2026-03-20-sprint-review.md) |

## 彙總

- 本日出勤：Xh Ym（N sessions）
- 本日探索：N 筆（WebSearch: N，WebFetch: N）
- 本日會議：N 場（共 Xm）
```

---

## 5. AC6 — summary 不存在時的提示

當 `docs/attendance/<date>.summary.jsonl` 不存在時，**出勤摘要**區段顯示：

```
> 尚未結算。請先執行：
> `bash hooks/attendance-settle.sh YYYY-MM-DD`
```

當 `docs/exploration/<date>.summary.jsonl` 不存在時，**探索紀錄摘要**區段顯示：

```
> 尚未結算。請先執行：
> `bash hooks/exploration-settle.sh YYYY-MM-DD`
```

> 儀表板不自動觸發結算，避免跨機器資料污染。

---

## 6. 多團隊 / 跨機器考量

- 儀表板只讀 `*.summary.jsonl`（已結算），不讀 per-session 原始檔案
- 結算（settle）應在當日作業結束後由各機器分別執行
- 不同機器的 per-session 檔案天然隔離，彙整後的 summary 是唯一真相來源

---

## 7. 產出文件

| 產出 | 路徑 | 說明 |
|------|------|------|
| Markdown 報表（stdout） | — | 輸出至 conversation，不寫入檔案 |
