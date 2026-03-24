# 觸發模式比較（Issue 觸發 vs Milestone 觸發）

Discovery Phase 支援兩種觸發入口，流程步驟相同，但背景分析的起點與範圍不同：

| 屬性 | Milestone 觸發 | Issue 觸發 |
|------|--------------|-----------|
| **觸發來源** | 里程碑啟動（新里程碑）或 Sprint 中段重大不確定性 | `feature-request` Issue 達閾值（≥3 thumbs-up 或 ≥5 comments），由 `/issue-management §10.2` 偵測並建議 |
| **Step 1 背景分析起點** | 願景文件（PRD、ROADMAP.md）+ 功能缺口盤點 | 觸發 Issue 本身（Issue body、留言、reactions）+ 相關功能現況 |
| **候選需求範圍** | 里程碑全範圍，可能包含多個候選需求 | 聚焦於觸發 Issue 所描述的單一需求（可擴展至相關 Issues） |
| **Product Brief 數量** | 一個里程碑通常產出多個 Product Brief | 通常聚焦產出 1 個 Product Brief（對應觸發 Issue） |
| **Issue 處理** | Step 6 新開 GitHub Issues | Step 6 引用原觸發 Issue，不重複開新 Issue |

## Issue 觸發的 Step 1 補充說明

當由 `/issue-management §10.2` 建議啟動時，Step 1 背景分析應額外執行：

```bash
# 讀取觸發 Issue 的完整內容與留言
gh issue view <trigger-issue-number> --comments --json \
  number,title,body,comments,reactionGroups,labels

# 查找相關 feature-request Issues（相似主題）
gh issue list --label "feature-request" --state open \
  --json number,title,reactionGroups,comments --limit 100
```

- [ ] 讀取觸發 Issue 的完整 body、所有留言與 reactions，作為候選需求的需求基礎
- [ ] 盤點是否有重複主題的其他 `feature-request` Issues，可一併納入同一 Discovery 探索範圍
- [ ] 識別候選需求清單（通常以觸發 Issue 為核心，可擴展至相關 Issues）
