# PO 審查積壓量（§7 詳細規範）

每次執行 `/backlog-management` 時，必須自動輸出 PO 審查積壓量摘要，以便 PO 掌握待審 Issue 數量與老齡狀態。

## 7.1 計數指令

執行以下指令取得所有待審 Issues（帶有 `auto-triaged` label、狀態為 open）：

```bash
gh issue list --label "auto-triaged" --state open \
  --json number,title,createdAt --limit 200
```

## 7.2 老齡警示規則

根據 Issue 建立時間（`createdAt`）計算齡期，套用以下警示等級：

| 齡期 | 警示等級 | 說明 |
|------|----------|------|
| 0–6 天 | 無警示 | 正常積壓範圍 |
| 7–13 天 | `[WARNING]` | 待審超過 7 天，應優先安排審查 |
| 14 天以上 | `[CRITICAL]` | 待審超過 14 天，需立即處理以防止需求流失 |

## 7.3 輸出格式

執行 `/backlog-management` 時，必須在輸出開頭呈現以下摘要區塊：

```
## PO 審查積壓量摘要

- 待審 Issues 計數：<N> 筆
- 最老 Issue 齡期：<D> 天（Issue #<number>：<title>）
- 警示等級：<無警示 / [WARNING] / [CRITICAL]>
```

若無任何待審 Issue，輸出：

```
## PO 審查積壓量摘要

- 待審 Issues 計數：0 筆
- 警示等級：無警示
```
