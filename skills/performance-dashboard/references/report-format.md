# Performance Dashboard — 報表格式

## Markdown 報表格式

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

## AC6 — summary 不存在時的提示

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
