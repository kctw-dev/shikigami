# Sprint 139

**Sprint Goal**：落地 TCB 斷點管理實作（ADR-040 決策成果），同步推進 Crash Recovery 與 Session Watchdog 的 ADR 先行工作，並完成 A2A 協議相容性研究評估。

**日期**：2026-03-24
**版本目標**：v0.93.0（含 Sprint 138 成果 Kill Switch + Token Cost Routing，TCB Checkpoint 實作為本 Sprint 主要功能落地）

**容量**：5 pts（Velocity 基準 Sprint 136-138：6/6/6 pts，平均 6 pts，建議區間 5-7 pts）

---

## Sprint Backlog

| Story | Issue | Type | Size | Points | 狀態 | 獨立性 |
|-------|-------|------|------|--------|------|--------|
| feat: TCB 斷點管理 — Agent Action 級 Checkpoint | #404 | FEATURE | M | 2 | 待執行 | 獨立（hooks/tcb-write.sh 新建，與其他 Story 無衝突） |
| RESEARCH: ADR-041 — Crash Recovery 架構決策（unblocks #405） | #631 | RESEARCH | S | 1 | 待執行 | 獨立（docs/adr/ADR-041 新建） |
| RESEARCH: ADR-042 — Session Watchdog 架構決策（unblocks #408） | #632 | RESEARCH | S | 1 | 待執行 | 依賴 #631（ADR-042 需先了解 ADR-041 恢復策略） |
| research: A2A 協議相容性評估 | #399 | RESEARCH | S | 1 | 待執行 | 獨立（docs/research/a2a-protocol-evaluation.md） |

**Sprint 容量**：5 points

---

## Sprint Goal 拆解

### Phase 1（可平行執行）
- **#404**（TCB Checkpoint 實作）｜**#631**（ADR-041 Crash Recovery）｜**#399**（A2A 研究）

### Phase 2（序列，依賴 #631）
- **#632**（ADR-042 Session Watchdog）— 需先了解 #631 的 Crash Recovery 恢復策略

---

## 技術評估（Architect）

| Story | T-shirt | ADR 需求 | API 契約 | Schema Contract | Related SDDs | 說明 |
|-------|---------|---------|---------|----------------|-------------|------|
| US-#404 | M | 已有 ADR-040（Accepted）+ SM 狀態圖已完成（docs/sdd/scrum-master-state-graph.md）| 不適用 | 豁免（file-based shell script）| docs/sdd/scrum-master-state-graph.md | hooks/tcb-write.sh 新建；ADR-040 定義 TCB JSON Schema，hooks.json 新增 hook 配置 |
| US-#631 | S | 本 Story 本身即 ADR RESEARCH，產出 ADR-041 | 不適用 | 豁免（RESEARCH）| — | doc-only，無架構實作涉及 |
| US-#632 | S | 本 Story 本身即 ADR RESEARCH，產出 ADR-042 | 不適用 | 豁免（RESEARCH）| — | 依賴 #631 完成後執行 |
| US-#399 | S | 無需 ADR（RESEARCH 類型）| 不適用 | 豁免（RESEARCH）| — | 純研究評估，結論決定後續 Story |

### ADR 依賴分群

| Story | ADR | 狀態 |
|-------|-----|------|
| #404 | ADR-040（TCB Checkpoint Design）| Accepted ✓ |
| #631 | 產出 ADR-041（Crash Recovery）| 本 Sprint 目標 |
| #632 | 產出 ADR-042（Session Watchdog）| 本 Sprint 目標，依賴 #631 |
| #399 | 無需 ADR | N/A |

### 平行分群建議

> SHIKIGAMI_MAX_PARALLEL 預設 2，目前 worktree=1

**Phase 1（可平行執行）**：#404 | #631 | #399（修改不同目錄，無衝突）

**Phase 2（序列）**：#632（ADR-042，需先閱讀 #631 產出的 ADR-041）

---

## AC 驗收確認（QA）

| Story | AC 完整性 | 路徑驗證 | NFR 覆蓋 | DoR 狀態 | 結論 |
|-------|----------|---------|---------|---------|------|
| US-#404 | PASS（AC1-AC7）| PASS（hooks/，scripts/validate-json.sh，docs/sdd/scrum-master-state-graph.md 均存在）| PASS（NFR1 reliability, NFR2 performance, NFR3 completeness）| READY | APPROVED |
| US-#631 | PASS（AC1-AC5）| N/A（RESEARCH type）| PASS（NFR1-NFR2）| READY | APPROVED |
| US-#632 | PASS（AC1-AC5）| N/A（RESEARCH type）| PASS（NFR1）| READY（依賴 #631 序列）| APPROVED |
| US-#399 | PASS（AC1-AC5）| PASS（docs/research/ 存在）| PASS（NFR1-NFR2）| READY | APPROVED |

### 隱性需求補充（QA 使用者代言人視角）

**US-#404 隱性需求**：
```
[隱性需求] Story US-#404
發現的隱性期待：使用者期待 TCB 機制在 Sprint 中透明運作，不產生可見延遲
建議補充至 AC：AC5 已涵蓋（best-effort，失敗不阻塞主流程）
非功能屬性類別：reliability, performance
嚴重度：Minor（AC5 已有對應規範）
```

---

## Model Routing（ADR-039）

| Story | Model Used | Tier | Risk Score | 路由原因 |
|-------|-----------|------|-----------|---------|
| #404 | sonnet | 2 | 7 | 新建 hook script + hooks.json 修改，有副作用（R=2, S=2, C=2, N=1）|
| #631 | haiku | 1 | 5 | ADR 文件撰寫，doc-only，可逆（R=1, S=1, C=2, N=1）|
| #632 | haiku | 1 | 5 | ADR 文件撰寫，doc-only，可逆（R=1, S=1, C=2, N=1）|
| #399 | haiku | 1 | 4 | 純研究評估，無副作用（R=1, S=1, C=1, N=1）|

---

## 複雜度預算

**前置快照**：Skill=30（門檻 40），Agent=8（門檻 15），Hooks=27（門檻 35），Lines=8977（門檻 25000）

- #404 新增：hooks/tcb-write.sh（新 hook script，不增 Skill/Agent count，Hooks +1 = 28）
- #631/#632/#399：doc-only，不增加 Skill/Agent/Hook count
- **結果**：PASS，不超出複雜度預算（Hooks 28 < 35）

---

## Retrospective Action Items 追蹤

| 來源 | Issue | 狀態 |
|------|-------|------|
| Sprint 138 Retro | 無 retro-action open issues | N/A |

