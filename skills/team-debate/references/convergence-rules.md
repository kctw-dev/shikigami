# Team Debate — 收斂機制與升級處置

## §5 收斂機制（2 輪硬上限）

```
Round 1：
  Worker 完成實作 + self-review
    ↓
  Critic 讀取產出 → 寫入 critique-round-1.md
    ├─ Verdict: PASS → 收斂，進入 PR 流程
    └─ Verdict: FAIL → 繼續 Round 2

Round 2：
  Worker 讀取 critique-round-1.md → 修復 → commit
    ↓
  Critic 讀取修復後產出 → 寫入 critique-round-2.md
    ├─ Verdict: PASS → 收斂，進入 PR 流程
    └─ Verdict: FAIL → [DEBATE-UNRESOLVED] 強制收斂
```

**強制收斂規則**：
- 第 2 輪後無論 Verdict 均強制收斂，禁止第 3 輪批判
- Verdict: FAIL 後強制收斂時，標記 `[DEBATE-UNRESOLVED]`，由主 session 決定升級處置

---

## §8 [DEBATE-UNRESOLVED] 升級處置

| 主 session 行為 | 條件 | 說明 |
|----------------|------|------|
| 繼續進入 PR | 預設 | `project_level=low` 時，標記後直接進入 PR |
| 通知等待確認 | `project_level=medium/high` | 留言通知使用者，等待決策 |
| 升級至 Architect | 特殊情況 | 若未解決問題屬設計層面（HIGH severity），升級 DESIGN_ISSUE |
