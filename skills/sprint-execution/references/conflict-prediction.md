# Parallel Conflict Prediction — 平行任務衝突預測

<!-- Story #395: Parallel Conflict Prediction — Sprint 134 -->
<!-- 依賴：ADR-033（Structured Trace Log，已 Accepted）-->

## 概述

在 Scrum Master 派遣平行 Story-Lifecycle subagent 前，執行靜態衝突分析，預測各 Story 可能修改的檔案集合，將 Sprint Stories 分為：
- **Group A（可平行）**：檔案集合互不重疊的 Story 組合
- **Group B（需序列）**：共享檔案或不確定修改範圍的 Story

此機制減少執行時等待（事後偵測衝突），並產出可視化的 dispatch plan。

---

## 執行流程

```
[CONFLICT-PREDICTION-START] sprint={sprint_num} stories={story_list}

1. 對每個 Story，從 AC 與標題推斷預計修改檔案集合：
   - 從 story 標題關鍵字推斷（retro: po-prompt.md → sprint-planning/references/）
   - 從 AC 中的明確路徑提取（AC1 含 "修改 X 檔案" → 直接使用）
   - 從歷史 trace log 查詢同類 Story 的實際修改記錄（若 logs/trace/ 存在）
   - 無法確定 → 標記為 [UNCERTAIN]，歸入 Group B（保守策略）

2. 衝突分析：
   for each (Story_A, Story_B) in combinations:
     if Story_A.files ∩ Story_B.files ≠ ∅:
       → 有衝突，兩者不可平行
     elif Story_A.files == [UNCERTAIN] or Story_B.files == [UNCERTAIN]:
       → 不確定，保守歸入 Group B
     else:
       → 無衝突，可平行

3. 分組輸出：
   Group A = { stories with no conflicts among themselves }
   Group B = { stories with conflicts or [UNCERTAIN] file sets }

   若 Group A 超過 SHIKIGAMI_MAX_PARALLEL，拆分為多個批次（Batch 1, Batch 2 ...）

4. 產出 dispatch plan（寫入 live-log）：
   [DISPATCH-PLAN] Sprint {N}
   Group A（可平行，Batch 1）：{story_list}
   Group B（需序列）：{story_list}
   預測衝突：{conflict_list}

5. 先派遣 Group A 平行執行

6. Group A 完成後，動態重評估 Group B：
   - 讀取 Group A 實際修改的檔案清單（git diff --name-only）
   - 重新比對 Group B 中各 Story 的預測修改範圍
   - 若 Group B 某 Story 與 Group A 實際修改無重疊 → 升級為可平行
   - 輸出：[CONFLICT-REEVAL] story={id} new_group={A|B} reason={...}

7. 執行 Group B（依重評估結果決定平行或序列）
```

---

## Dispatch Plan 格式（AC2 輸出格式）

dispatch plan 寫入 live-log（`logs/live/YYYY-MM-DD-session-{SESSION_ID}.log`）：

```
[DISPATCH-PLAN] Sprint 134 — 2026-03-24T10:00:00
─────────────────────────────────────
Group A（可平行 | Batch 1 | SHIKIGAMI_MAX_PARALLEL=2）
  ├── #573 retro: Sprint Planning AC 路徑    → 預測修改: sprint-planning/references/po-prompt.md
  └── #581 retro: worktree rebase          → 預測修改: sprint-execution/story-lifecycle-prompt.md
Group A（可平行 | Batch 2）
  ├── #574 retro: git tag                  → 預測修改: sprint-review/SKILL.md
  └── #393 feat: Security Gate             → 預測修改: docs/adr/ADR-006.md, docs/definition/SECURITY_RULES.md
Group B（需序列）
  └── #395 feat: Parallel Conflict         → 預測修改: sprint-execution/SKILL.md（與 #393 無衝突，但待確認）
─────────────────────────────────────
預測衝突：無
預測準確率目標：Precision > 75%，Recall > 80%（下 Sprint 驗證）
```

---

## Trace Log 記錄（AC4，ADR-033 格式）

衝突預測結果寫入 trace log（`docs/trace-logs/YYYY-MM-DD-session-{SESSION_ID}.jsonl`）：

```jsonl
{"traceId":"<id>","spanId":"conflict-pred-1","agentRole":"scrum-master","action":"conflict-prediction","storyId":"sprint-134","timestamp":"...","status":"completed","metadata":{"group_a":["#573","#581","#574","#393"],"group_b":["#395"],"predicted_conflicts":[],"precision_target":0.75,"recall_target":0.80}}
```

Group A 完成後重評估：

```jsonl
{"traceId":"<id>","spanId":"conflict-reeval-1","agentRole":"scrum-master","action":"conflict-reeval","storyId":"#395","timestamp":"...","status":"completed","metadata":{"actual_conflicts_found":0,"upgraded_to_group_a":false,"reason":"sprint-execution/SKILL.md 確認無衝突"}}
```

---

## 保守分組規則

| 情況 | 分組 | 理由 |
|------|------|------|
| 修改範圍明確，無交集 | Group A | 靜態分析確認無衝突 |
| 修改範圍不確定（[UNCERTAIN]）| Group B | 保守策略，避免執行時衝突 |
| 共享 sprint-execution/SKILL.md | Group B | 高頻共享文件，序列執行更安全 |
| 不同目錄且無 import 關係 | Group A | 物理隔離充分 |

**預測準確率目標**（來自 PB AC5）：
- Precision（預測衝突且實際衝突）> 75%
- Recall（實際衝突被預測到）> 80%
- 每個 Sprint dispatch plan 100% 產出
