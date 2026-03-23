---
name: team-debate
description: "Use when a Developer Story requires peer critique from an independent Critic Agent after implementation"
---

# Team Debate — 同職能雙 Agent 交替批判機制

<!-- ADR-031 Team Debate 機制 — Sprint 124 / #383 -->

## 1. 概述

**Team Debate** 是 Story-Lifecycle 的品質增強機制。在 Developer Worker 完成實作與 self-review 後，派遣獨立的 Developer Critic Agent 執行外部批判，Worker 修復，最多 2 輪收斂。

此機制基於 **ADR-031（Team Debate 機制）選項 C — 交替批判（2 輪上限）**，引入真正的外部視角，突破單一 Agent 認知盲點。

---

## 2. 適用條件（Phase 1）

| 條件 | 說明 |
|------|------|
| **適用角色** | Developer only（Phase 1） |
| **適用 Story 類型** | FEATURE、INFRA、SECURITY、INTEGRATION |
| **豁免條件** | `doc_only=true` 的 Story（文件類不啟用，成本不值得） |
| **豁免條件** | `story_type=RESEARCH` 的 Story |
| **豁免條件** | `story_type=DESIGN` 的 Story |
| **Size 門檻** | M/L 規模啟用；S 規模可由 Scrum Master 決定是否啟用 |

**不適用角色（Phase 1 不包含）**：
- PO、Scrum Master：流程管理角色，非產出角色
- SRE、Security Engineer：低頻觸發，成本效益比不佳
- UI/UX Designer：設計審查有獨立流程（Vision Critic）

---

## 3. Agent 角色定義

### Worker（Agent A）

- **職責**：執行 TDD 開發、self-review、接收批判後修復
- **行為**：完整 Story-Lifecycle（TDD + Spec/Quality/Security self-review）
- **修復義務**：接收 Critic 批判後必須逐項回應（accept/reject + 理由）並修復 accept 項目
- **context**：獨立 worktree，不帶 Critic 的批判歷史進入修復

### Critic（Agent B）

- **職責**：獨立批判 Worker 的產出，不修改代碼
- **行為**：讀取 Worker 的 branch + 產出，從外部視角進行批判
- **批判維度**：
  1. **正確性**：AC 是否全部覆蓋？邊界條件是否處理？
  2. **設計**：是否符合 SOLID 原則？耦合度？單一職責？
  3. **測試覆蓋**：測試是否充分？Red 階段是否真正先寫失敗測試？
  4. **安全性**：外部輸入是否受保護？有無硬編碼 secrets？
- **禁止行為**：不直接修改代碼；不與 Worker 進行 context 共享

---

## 4. 通訊機制

### 批判結果檔案路徑

```
.claude/debate/critique-round-{N}.md
```

### 批判結果格式

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

### 規則

- `N` 從 1 開始，最大為 2
- `Verdict: PASS`：Critic 認可 Worker 產出，無需修復
- `Verdict: FAIL`：Critic 發現問題，Worker 需修復後再次批判
- 若 Issues Found 為空，Verdict 必須為 PASS

---

## 5. 收斂機制（2 輪硬上限）

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

## 6. 執行流程（主 session 協調）

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

---

## 7. Critic Prompt 指引

Critic Agent 派遣時使用以下 prompt 框架：

```
你是 Developer Critic Agent，負責對以下 Story 的實作進行獨立外部批判。
你不是作者，你沒有看過開發過程，你只看最終產出。

Story ID：{story_id}
Worker Branch：{branch}
Story AC：{ac_list}

批判任務：
1. 讀取 Worker 修改的所有檔案（git diff 或讀取修改檔案清單）
2. 逐項檢查 AC 是否有對應實作
3. 從 4 個維度批判（正確性、設計、測試覆蓋、安全性）
4. 輸出批判結果至 .claude/debate/critique-round-{N}.md（格式見 §4）

重要原則：
- 你的批判必須具體，指出檔案和行號
- 你不能修改任何代碼，只能批判
- 若你找不到明確問題，Verdict = PASS（不要為了批判而批判）
- [SEVERITY: HIGH] 僅用於 AC 缺失或安全漏洞；設計優化建議用 LOW/MED
```

---

## 8. [DEBATE-UNRESOLVED] 升級處置

| 主 session 行為 | 條件 | 說明 |
|----------------|------|------|
| 繼續進入 PR | 預設 | `project_level=low` 時，標記後直接進入 PR |
| 通知等待確認 | `project_level=medium/high` | 留言通知使用者，等待決策 |
| 升級至 Architect | 特殊情況 | 若未解決問題屬設計層面（HIGH severity），升級 DESIGN_ISSUE |

---

## 9. 豁免機制（可關閉）

Scrum Master 可明確關閉 Team Debate：

```yaml
# Story-Lifecycle 輸入中加入：
team_debate: false  # 明確關閉，fallback 至標準單一 agent 模式
```

關閉後，Story 使用標準 Story-Lifecycle 流程（單一 subagent 自審）。

---

## 10. Token 成本參考

| 場景 | 預估 token 倍率 |
|------|-----------------|
| Round 1 PASS（1 輪即收斂） | ~1.8x |
| Round 2 收斂（2 輪） | ~2.5x |
| [DEBATE-UNRESOLVED]（2 輪強制收斂） | ~2.5x |

---

## 參照文件

- **ADR-031**：`docs/adr/ADR-031-team-debate.md`（架構決策）
- **story-lifecycle-prompt.md**：`skills/sprint-execution/story-lifecycle-prompt.md`（整合點）
- **developer.md**：`agents/developer.md`（Worker/Critic 角色定義）
