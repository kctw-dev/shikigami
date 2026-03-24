---
name: team-debate
description: "Use when a M/L size Story completes implementation and needs independent peer critique from a Critic Agent before PR merge"
---

# Team Debate — 同職能雙 Agent 交替批判機制

<!-- ADR-031 Team Debate 機制 — Sprint 124 / #383 -->

## 1. 概述

**Team Debate** 是 Story-Lifecycle 的品質增強機制。在 Developer Worker 完成實作與 self-review 後，派遣獨立的 Developer Critic Agent 執行外部批判，Worker 修復，最多 2 輪收斂。

此機制基於 **ADR-031（Team Debate 機制）選項 C — 交替批判（2 輪上限）**，引入真正的外部視角，突破單一 Agent 認知盲點。

---

## 2. 適用條件（Phase 1）

- **適用**：Developer、FEATURE/INFRA/SECURITY/INTEGRATION、M/L 規模
- **豁免**：`doc_only=true`、`story_type ∈ {RESEARCH, DESIGN}`、S 規模（SM 未明確啟用）
- **不適用角色**：PO、SM（流程角色）、SRE/Security Engineer（低頻）、UI/UX（獨立 Vision Critic 流程）

---

## 3. Agent 角色定義

**Worker（Agent A）**：TDD 開發 + self-review + 接收批判後逐項 accept/reject 修復；獨立 worktree，不帶批判歷史。

**Critic（Agent B）**：外部視角批判 4 維度（正確性、設計、測試覆蓋、安全性）；不修改代碼；不與 Worker 共享 context。

---

## 4. 通訊機制

批判結果路徑：`.claude/debate/critique-round-{N}.md`（N 最大為 2）

格式：`Verdict: PASS | FAIL` + Issues Found（SEVERITY: HIGH|MED|LOW + 位置 + 建議）+ Summary。Issues 為空時 Verdict 必須為 PASS。

---

## 5. 收斂機制（2 輪硬上限）

```
Round 1：Worker 完成 + self-review → Critic 批判
  PASS → 收斂進 PR；FAIL → Round 2

Round 2：Worker 修復 → Critic 二次批判
  PASS → 收斂進 PR；FAIL → [DEBATE-UNRESOLVED] 強制收斂
```

- 第 2 輪後無論 Verdict 均強制收斂，禁止第 3 輪
- `[DEBATE-UNRESOLVED]` 由主 session 決定升級處置

完整流程圖：`references/convergence-rules.md` §5。

---

## 6. 執行流程（主 session 協調）

觸發判斷 → 派遣 Worker（完整 TDD + self-review）→ 派遣 Critic Round 1 → 依 Verdict 決定收斂或 Round 2 → PR 流程（附 debate 摘要）。

**豁免跳過**：`doc_only=true`、`story_type ∈ {RESEARCH, DESIGN}`、`size=S` 且 SM 未啟用。

完整步驟：`references/debate-flow.md` §6。

---

## 7. Critic Prompt 指引

Critic 以外部視角批判，不修改代碼；批判必須具體指出檔案行號；找不到明確問題應給 PASS；`[SEVERITY: HIGH]` 僅用於 AC 缺失或安全漏洞。

完整 prompt 框架：`references/critic-prompt.md` §7。

---

## 8. [DEBATE-UNRESOLVED] 升級處置

| 主 session 行為 | 條件 |
|----------------|------|
| 繼續進入 PR | `project_level=low`（預設） |
| 通知等待確認 | `project_level=medium/high` |
| 升級至 Architect | HIGH severity 設計問題 |

完整規則：`references/convergence-rules.md` §8。

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
