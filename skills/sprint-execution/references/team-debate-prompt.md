# §7.8 Team Debate — 同職能雙 Agent 交替批判（ADR-031，Phase 1）

<!-- SSOT：story-lifecycle-prompt.md §7.8 已移至此處（Sprint 127 #485 模組化拆分） -->
<!-- ADR-031 Team Debate 機制 — Sprint 124 / #383 -->

## 觸發條件

Team Debate 在以下條件下啟用：

```
啟用條件（以下所有條件均需滿足）：
  1. story_type ∈ {FEATURE, INFRA, SECURITY, INTEGRATION}
  2. doc_only = false
  3. team_debate ≠ false（未被明確關閉）
  4. Story 角色為 Developer（Phase 1 限定）

豁免條件（任一即豁免）：
  - doc_only = true → 跳過（文件類 Story，成本不值得）
  - story_type ∈ {RESEARCH, DESIGN} → 跳過
  - team_debate = false（明確關閉）→ 跳過，回退至標準單一 agent 自審
  - size = S 且 Scrum Master 未明確啟用 → 跳過（S 規模預設豁免）
```

若豁免：輸出 `[DEBATE-SKIP] {原因}`，繼續進入 §8 DoD 自檢。

**M/L Stories 必須觸發 Team Debate**（size=M 或 size=L 且上述啟用條件均滿足時，不可跳過）。

## 執行流程

```
Step 1：確認觸發
  → 輸出：[DEBATE-START] 啟用 Team Debate（ADR-031 Phase 1）

Step 2：當前 subagent 身份確認
  本 subagent 即 Worker（Agent A）。至此已完成：
    - TDD 開發（§3）
    - Spec Compliance self-review（§5）
    - Code Quality self-review（§6）
    - Runtime Verification（§6.5）
    - Security self-review（§7，條件觸發）
    - pr-review-toolkit 審查（§7.5，條件觸發）
  回傳主 session：WORKER_COMPLETE + branch + worktree path

  注意：若本 subagent 為 Critic（Agent B），執行 §7.8.2 Critic 批判流程，
        寫入 .claude/debate/critique-round-{N}.md 後回傳主 session。

Step 3：（由主 session 協調）派遣 Critic（Agent B）
  → 讀取 Worker 產出（git diff 或修改檔案清單）
  → 執行獨立批判（正確性、設計、測試覆蓋、安全性）
  → 寫入 .claude/debate/critique-round-1.md

Step 4：主 session 讀取 critique-round-1.md
  ├─ Verdict: PASS → [DEBATE-PASS-R1] 收斂，繼續 §8
  └─ Verdict: FAIL → 主 session 傳入批判結果，Worker 執行 Round 2 修復

Step 5（Round 2，若 Round 1 FAIL）：
  Worker 讀取 critique-round-1.md → 逐項回應（accept/reject）→ 修復 → commit
  → 主 session 派遣 Critic 二次批判 → critique-round-2.md

Step 6（Round 2 收斂）：
  ├─ Verdict: PASS → [DEBATE-PASS-R2] 收斂，繼續 §8
  └─ Verdict: FAIL → [DEBATE-UNRESOLVED] 強制收斂（禁止 Round 3）
     → 標記升級候選，記錄至 PR description
     → 繼續 §8（不阻塞）
```

## §7.8.1 Worker 修復規則（Round 2）

Worker 接收 critique-round-1.md 後：

```
1. 逐項閱讀 Issues Found
2. 對每項 Issue 決定 accept / reject：
   - accept：說明修復方式，執行修復，commit
   - reject：說明拒絕理由（需有合理理由，如「此為已知設計取捨」）
3. Commit message 格式：
   fix: Team Debate Round 2 修復 — {story_id}
4. 所有 HIGH severity Issue 必須 accept（不可 reject）
```

## §7.8.2 Critic 批判流程

當本 subagent 以 Critic 身份被派遣時：

```
1. 讀取 Worker 的所有修改檔案（git diff origin/main...HEAD 或修改檔案清單）
2. 讀取 Story AC（從 sprint_file 取得）
3. 執行 4 維度批判：
   - 正確性：每項 AC 是否有對應實作？邊界條件？
   - 設計：SOLID 原則？耦合度？命名清晰度？
   - 測試覆蓋：是否真正 TDD？測試是否僅測 happy path？
   - 安全性：外部輸入是否過濾？有無硬編碼 secrets？
4. 確認目錄存在：mkdir -p .claude/debate/
5. 寫入 .claude/debate/critique-round-{N}.md（格式見下方）
6. 回傳主 session：CRITIC_COMPLETE + Verdict + 批判摘要
```

**批判結果格式**：

```markdown
# Critique Round {N}

## Verdict: PASS | FAIL

## Issues Found
- [SEVERITY: HIGH|MED|LOW] {問題描述}
  - 位置：{file}:{line}
  - 建議：{改善方向}

## Summary
{總結評語，說明主要發現與整體評估}
```

**Verdict 判定規則**：
- 有 HIGH severity Issue → Verdict: FAIL
- 有 MED severity Issue 且超過 2 項 → Verdict: FAIL
- 只有 LOW severity Issue → Verdict: PASS（附 Issues Found，但不阻塞）
- Issues Found 為空 → Verdict: PASS

**重要原則**：
- 不能修改任何代碼，只能批判
- 批判必須具體，指出檔案和行號
- 不為了批判而批判：若真的找不到問題，Verdict = PASS

## §7.8.3 [DEBATE-UNRESOLVED] 處置

| project_level | 處置行為 |
|---------------|---------|
| `low` | 標記 [DEBATE-UNRESOLVED] 後直接進入 §8，PR description 附上未解決清單 |
| `medium` / `high` | 輸出升級通知，等待主 session / 使用者決策 |

若未解決問題包含 HIGH severity 設計問題，可升級至 ESCALATE: DESIGN_ISSUE。

## §7.8.4 PR Description 附加資訊

Team Debate 收斂後，PR description 需附加：

```
## Team Debate 摘要

- 批判輪數：{1 / 2}
- 最終 Verdict：{PASS / [DEBATE-UNRESOLVED]}
- Critic 發現：{主要問題摘要，若無則填「無重大問題」}
- Worker 修復：{修復摘要，若 Round 1 PASS 則填「N/A（Round 1 直接通過）」}
- 批判紀錄：`.claude/debate/critique-round-{N}.md`
```
