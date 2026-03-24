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

1. 取得日期（`date` 指令，開發紅線第 6 條）
2. 讀取 `docs/attendance/${REPORT_DATE}.summary.jsonl` — 依 session_id 配對計算時數
3. 讀取 `docs/exploration/${REPORT_DATE}.summary.jsonl` — 統計 WebSearch/WebFetch 筆數
4. Glob 掃描 `docs/meetings/${REPORT_DATE}-*.md` — 解析 frontmatter 提取會議資訊
5. 輸出 Markdown 報表（見 `references/report-format.md`）

---

## 4. 報表格式

報表格式與 AC6 不存在提示見 `references/report-format.md`。

---

## 5. 多團隊 / 跨機器考量

- 儀表板只讀 `*.summary.jsonl`（已結算），不讀 per-session 原始檔案
- 結算（settle）應在當日作業結束後由各機器分別執行
- 不同機器的 per-session 檔案天然隔離，彙整後的 summary 是唯一真相來源

---

## 6. 產出文件

| 產出 | 路徑 | 說明 |
|------|------|------|
| Markdown 報表（stdout） | — | 輸出至 conversation，不寫入檔案 |
