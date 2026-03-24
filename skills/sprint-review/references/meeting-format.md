# Sprint Review & Retro 會議紀錄格式

`docs/meetings/` 目錄若不存在，執行 `mkdir -p docs/meetings` 建立。

## Sprint Review 紀錄（§2 步驟 7）

檔名規則：`docs/meetings/$(date '+%Y-%m-%d')-sprint-review.md`

```yaml
---
type: sprint-review
sprint: <N>
date: "<YYYY-MM-DD>"
start_time: "<REVIEW_START_TIME>"
end_time: "<date '+%Y-%m-%dT%H:%M+08:00'>"
participants:
  - role: PO
  - role: QA
  - role: Stakeholder
---

# Sprint <N> Review 會議紀錄

## 結論
- 通過驗收 Stories: <list>
- 未通過 Stories: <list>

## 決議事項
1. <decisions>
```

## Retro 紀錄（§3 步驟 8）

檔名規則：`docs/meetings/$(date '+%Y-%m-%d')-retro.md`

```yaml
---
type: retro
sprint: <N>
date: "<YYYY-MM-DD>"
start_time: "<RETRO_START_TIME>"
end_time: "<date '+%Y-%m-%dT%H:%M+08:00'>"
participants:
  - role: PO
  - role: Architect
  - role: QA
  - role: Stakeholder
---

# Sprint <N> Retrospective 會議紀錄

## Good
- <items>

## Problem
- <items>

## Action
- <items>
```
