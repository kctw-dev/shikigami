# Feature-Request 回饋匯總（Grooming 前置步驟）

每次 Sprint Grooming 執行時，PO subagent 必須**自動匯總** `feature-request` Issue 的回饋趨勢，作為 Grooming 主流程的前置輸出。

## 執行指令

```bash
# Step A：取得所有 feature-request Issues（含 reactions 與 comments 數量）
gh issue list --label "feature-request" --state open \
  --json number,title,url,reactionGroups,comments,createdAt --limit 200

# Step B：解析 thumbs-up 數量並排序
# （由 PO subagent 解析 reactionGroups[].content == "THUMBS_UP" 的 reactors.totalCount）
```

## 匯總輸出格式

```
## Feature-Request 回饋趨勢匯總（Sprint Grooming）

### 投票數排序 Top-N（按 thumbs-up 降序）
| # | Issue | 👍 Reactions | 💬 Comments | 建議動作 |
|---|-------|-------------|------------|---------|
| 1 | #<N> <標題> | <數> | <數> | [達閾值] 建議啟動 /discovery-phase |
| 2 | #<N> <標題> | <數> | <數> | 維持 Backlog |
| … |

### 重複主題識別
- 主題「<主題描述>」：涉及 Issue #<N1>, #<N2>（共 <X> 個，合計 <Y> 票）
- （若無重複主題，輸出：未識別到重複主題）

### Discovery 觸發建議
- 達閾值（≥3 👍 或 ≥5 💬）Issues：<N> 筆
- 建議啟動 /discovery-phase：<列出 Issue #N 與標題>
- 已帶 `discovery-candidate` label：<N> 筆
```

## 閾值定義（對應 `/issue-management §10.2`）

| 觸發條件 | 閾值 |
|---------|------|
| Thumbs-up reactions（👍） | ≥ 3 |
| Comments 數量 | ≥ 5 |

達閾值的 Issue 自動套用 `discovery-candidate` label（低風險操作，自動執行）：

```bash
gh issue edit <N> --add-label "discovery-candidate"
```
