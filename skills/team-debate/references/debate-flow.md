# Team Debate — 執行流程詳細步驟

## §6 執行流程（主 session 協調）

### 步驟 1：觸發判斷

```
主 session 接收 Story 參數後，判斷是否啟用 Team Debate：

若 doc_only=true → 跳過 Team Debate，使用標準 Story-Lifecycle
若 story_type ∈ {RESEARCH, DESIGN} → 跳過 Team Debate
若 size=S 且 Scrum Master 未明確啟用 → 跳過 Team Debate
否則 → 啟用 Team Debate（Developer Story，Phase 1）
```

### 步驟 2：派遣 Worker（Agent A）

```
派遣 Story-Lifecycle subagent（Worker 角色）
  - 使用標準 story-lifecycle-prompt.md
  - 執行完整 TDD + self-review 流程
  - commit 至 branch，回傳 branch + worktree path
  - 輸出：WORKER_BRANCH={branch}、WORKER_COMMIT={sha}
```

### 步驟 3：派遣 Critic（Agent B）— Round 1

```
派遣 Developer subagent（Critic 角色）
  - 讀取 Worker 的 branch 產出（git diff vs main 或讀取修改檔案）
  - 執行獨立批判（4 維度：正確性、設計、測試覆蓋、安全性）
  - 寫入 .claude/debate/critique-round-1.md
  - 回傳 Verdict（PASS/FAIL）
```

### 步驟 4a：若 Round 1 Verdict = PASS

```
收斂，進入 PR 流程
輸出：[DEBATE-PASS] Round 1 批判通過，收斂
```

### 步驟 4b：若 Round 1 Verdict = FAIL

```
派遣 Worker（修復）：
  - 讀取 critique-round-1.md
  - 逐項回應（accept/reject + 理由）
  - 修復所有 accept 項目
  - commit 修復，回傳 WORKER_COMMIT_R2={sha}

派遣 Critic — Round 2：
  - 讀取修復後產出
  - 執行二次批判
  - 寫入 .claude/debate/critique-round-2.md
  - 回傳 Verdict（PASS/FAIL）
```

### 步驟 5：Round 2 後強制收斂

```
若 Round 2 Verdict = PASS：
  收斂，進入 PR 流程
  輸出：[DEBATE-PASS] Round 2 批判通過，收斂

若 Round 2 Verdict = FAIL：
  強制收斂
  輸出：[DEBATE-UNRESOLVED] 2 輪後仍有未解決問題
  標記升級候選，由主 session 決定是否 ESCALATE
  仍進入 PR 流程，PR description 附上 debate 紀錄
```

### 步驟 6：PR 流程

```
Worker 執行 git push → gh pr create
PR description 必須附上 debate 摘要：
  - Debate rounds 數
  - 最終 Verdict
  - 若 [DEBATE-UNRESOLVED]，列出未解決問題
```
