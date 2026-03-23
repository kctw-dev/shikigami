# ADR-031：同職能 Team Debate 機制

**日期**：2026-03-23
**狀態**：Accepted
**相關 Issue**：#383
**提案者**：Architect Agent
**關聯 ADR**：ADR-022（File-Level Locking）、ADR-023（PR-based Git Flow）
**來源**：#362 P0 GAD 研究報告 §六、PB-2026-03-23-team-debate.md

---

## 背景

### 問題陳述

目前 Shikigami Sprint Execution 的每個 Story 由單一 subagent 執行完整生命週期（實作 + self-review）。self-review 屬於自我批判，受限於同一 agent 的認知盲點 — 自己寫的程式碼自己審，容易漏掉結構性問題、邊界條件遺漏或設計偏見。

現有流程：

```
Scrum Master 派遣 Story
    ↓
Story-Lifecycle subagent（單一 agent）
    ├── TDD 開發
    ├── Spec Compliance self-review（自審）
    ├── Code Quality self-review（自審）
    └── Security self-review（條件觸發）
    ↓
git push → PR → merge
```

這等於「個人作業直接交審」，缺乏同儕外部視角。品質基線完全取決於單一 agent 的能力上限，無法透過辯論發現盲點。

### 驅動力

- Sprint Review DISPUTE 率仍有改善空間
- 自審 PASS 後外部抽樣仍可能發現品質問題
- #362 P0 GAD 研究報告指出：多 agent 辯論是提升自審品質的關鍵槓桿

---

## 決策問題

如何在 Story-Lifecycle 流程中引入同職能外部視角，使自審品質不再受限於單一 agent 的認知盲點？

---

## 考慮的選項

### 選項 A：單一 Agent 自我批判（現狀）

在 prompt 中加入 Devil's Advocate 指令，讓同一 agent 先產出、再自我批判、再修正。不改變 subagent 數量。

**優點**：
- 零額外 token 成本（僅多一輪 prompt 迴圈）
- 不改變現有流程架構
- 實作最簡單

**缺點**：
- 自我批判受限於同一 context window 的認知偏見
- 研究顯示同一 LLM 對自身產出的批判深度有限（anchoring bias）
- 無真正的外部視角，效果上限低

**結論**：否決 — 效果有限，無法突破單一 agent 認知上限

### 選項 B：序列雙 Agent（Agent A 實作 → Agent B 批判）

Agent A 完成實作與 self-review 後，將完整產出交給 Agent B 執行獨立審查。Agent B 僅批判不修改，批判結果回傳主 session 決定是否通過。

**優點**：
- 引入真正的外部視角（獨立 context window）
- Agent B 不帶 Agent A 的認知偏見
- 結構簡單，單向流動

**缺點**：
- Agent B 只批判不修復，批判結果需要 Agent A 再啟動修復（成本更高）
- 若 Agent A 不同意批判，無仲裁機制
- 單次批判可能不夠深入（Agent B 缺乏互動動機去追問）

**結論**：否決 — 缺乏修復閉環，需額外協調成本

### 選項 C：交替批判（Agent A 實作 → Agent B 批判 → Agent A 修復，2 輪上限）

Agent A 完成實作後，Agent B 執行批判並列出改善項目。Agent A 收到批判後修復。此循環最多 2 輪（2 次批判 + 2 次修復），之後強制收斂。

```
Agent A（Worker）                Agent B（Critic）
    │                                │
    ├── 實作 + self-review ──────────→ │
    │                                ├── 獨立批判
    │  ←──────── 批判結果 + 改善清單 ──┤
    ├── 修復 ────────────────────────→ │
    │                                ├── 二次批判（若仍有問題）
    │  ←──────── 二次批判結果 ─────────┤
    ├── 最終修復                       │
    │                                │
    └── 產出最終版本                    │
```

**優點**：
- 真正的外部視角 + 修復閉環
- 2 輪上限確保收斂，避免無限辯論
- 比選項 A（全 team）省 token，僅需 2 個 agent
- 每輪交替有明確輸入/輸出，易於追蹤與除錯
- 漸進式導入：Phase 1 僅 Developer，低風險驗證

**缺點**：
- Token 成本約 2-3x（相對單一 agent）
- 新增流程步驟，增加 Story 執行時間
- Agent 間通訊機制需要設計

**結論**：採用

---

## 決策

**採用選項 C：交替批判機制（2 輪上限）**

### 決策 1：Agent 間通訊機制 — Worktree + 檔案交換

Agent A（Worker）與 Agent B（Critic）透過 **worktree 隔離 + 檔案交換** 通訊：

| 機制 | 說明 |
|------|------|
| 隔離方式 | Agent A 使用 `isolation: "worktree"` 在獨立 worktree 開發 |
| 批判觸發 | Agent A 完成實作後，commit 至 worktree branch，回傳 branch name + worktree path |
| Agent B 載入 | Agent B 派遣時指定相同 branch，讀取 Agent A 的產出進行批判 |
| 批判結果 | Agent B 將批判寫入約定檔案路徑（見下方格式），回傳主 session |
| 修復循環 | 主 session 將批判結果傳遞給 Agent A，Agent A 在同一 worktree 修復 |

**批判結果檔案格式**：

```
.claude/debate/critique-round-{N}.md
```

內容結構：

```markdown
# Critique Round {N}

## Verdict: PASS | FAIL

## Issues Found
- [SEVERITY: HIGH|MED|LOW] 描述
  - 位置：<file>:<line>
  - 建議：<改善方向>

## Summary
<總結評語>
```

**替代方案（否決）**：Shared state / memory — Claude Code Agent tool 目前不支援 agent 間 shared memory，且 worktree + 檔案交換已被 #379 驗證為可行模式。

### 決策 2：收斂機制 — 2 輪硬上限 + Verdict 判定

| 參數 | 值 | 理由 |
|------|-----|------|
| 最大批判輪數 | 2 | 實驗表明第 3 輪以上的批判邊際效益遞減，且 token 成本線性增長 |
| 收斂條件 | Agent B 回傳 `Verdict: PASS` | Critic 認可即收斂 |
| 強制收斂 | 第 2 輪結束後無論 Verdict 均收斂 | 防止無限辯論 |
| 2 輪後仍 FAIL | 標記 `[DEBATE-UNRESOLVED]`，由主 session 決定是否升級 | 保留人工介入節點 |

流程圖：

```
主 session 派遣 Story
    │
    ├─ 派遣 Agent A（Worker）──→ worktree 開發 + self-review
    │                            │
    │                            ├─ commit to branch
    │                            └─ 回傳 branch + worktree path
    │
    ├─ 派遣 Agent B（Critic）──→ 讀取 Agent A 產出
    │                            │
    │                            ├─ 獨立批判
    │                            └─ 寫入 critique-round-1.md
    │                               │
    │                               ├─ Verdict: PASS → 收斂，進入 PR 流程
    │                               └─ Verdict: FAIL → 繼續
    │
    ├─ 派遣 Agent A（修復）───→ 讀取 critique-round-1.md
    │                            │
    │                            ├─ 修復 + commit
    │                            └─ 回傳更新後 branch
    │
    ├─ 派遣 Agent B（二次批判）→ 讀取修復後產出
    │                            │
    │                            └─ 寫入 critique-round-2.md
    │                               │
    │                               ├─ Verdict: PASS → 收斂
    │                               └─ Verdict: FAIL → [DEBATE-UNRESOLVED] 強制收斂
    │
    └─ PR 流程（git push → gh pr create → merge）
```

### 決策 3：Token 成本評估與控制

| 場景 | 預估 token 倍率 | 說明 |
|------|-----------------|------|
| 1 輪即 PASS | ~1.8x | Agent A 完整執行 + Agent B 批判（讀取為主，生成較少） |
| 2 輪收斂 | ~2.5x | 加上 Agent A 修復 + Agent B 二次批判 |
| 2 輪仍 FAIL | ~2.5x | 同上，強制收斂不再追加 |

**成本控制措施**：

| 措施 | 說明 |
|------|------|
| Phase 1 僅 Developer | 限制適用角色，觀察成本效益比 |
| doc-only Story 豁免 | 文件類 Story 不啟用 debate（成本不值得） |
| Story 規模門檻 | 可選：僅 M/L 規模的 Story 啟用 debate，S 規模維持單一 agent |
| 批判 prompt 精簡 | Agent B 的 prompt 聚焦批判，不重複完整開發 context |

### 決策 4：適用角色與 Phase 規劃

| Phase | 適用角色 | 啟用條件 | 驗證指標 |
|-------|---------|---------|---------|
| Phase 1 | Developer only | 預設啟用（可由 Scrum Master 關閉） | DISPUTE 率下降 30%+、收斂效率 90% 在 2 輪內 |
| Phase 2（未來） | QA Engineer | Phase 1 驗證通過後評估 | 同上 |
| Phase 3（未來） | Architect | Phase 2 驗證通過後評估 | 同上 |

**Phase 1 不包含的角色**：
- PO、Scrum Master：流程管理角色，非產出角色，debate 機制不適用
- SRE、Security Engineer：低頻觸發，成本效益比不佳
- UI/UX Designer：設計審查有獨立流程

### 決策 5：與現有流程的整合點

| 整合點 | 變更 | 向後相容 |
|--------|------|---------|
| Story-Lifecycle subagent | 原「單一 subagent 閉環」改為「主 session 協調 Worker + Critic」 | 可 fallback 至單一 agent 模式 |
| Spec Compliance self-review | 由 Agent A self-review 移至 Agent B 批判範圍 | Agent A 仍做 self-review，Agent B 為第二道防線 |
| Code Quality self-review | 同上 | 同上 |
| PR 流程 | 不變，debate 收斂後走原有 PR 流程 | 完全相容 |
| worktree 隔離（#379） | 復用現有 worktree 機制，Agent A 和 Agent B 共用同一 worktree branch | 相容 |

---

## 實作影響

### 需新增的檔案

| 檔案 | 內容 |
|------|------|
| `skills/team-debate/SKILL.md` | Team Debate Skill 定義（Worker/Critic 派遣、批判格式、收斂邏輯） |

### 需修改的檔案

| 檔案 | 修改內容 |
|------|---------|
| `skills/sprint-execution/SKILL.md` | Story-Lifecycle 派遣流程中插入 debate 階段 |
| `skills/scrum-master/SKILL.md` | 新增 team-debate Skill 引用 |
| `agents/developer.md` | 新增 Worker / Critic 角色說明與行為差異 |

### 不修改的檔案

| 檔案 | 理由 |
|------|------|
| `hooks/hooks.json` | debate 由 Skill 層驅動，不需 hook |
| `agents/qa-engineer.md` | Phase 1 不涉及 QA |
| `agents/architect.md` | Phase 1 不涉及 Architect |

---

## 後果

### 正面

- **外部視角**：Critic 從獨立 context 審查，不受 Worker 認知偏見影響
- **修復閉環**：批判 + 修復形成完整 PDCA 迴圈，不需額外協調
- **收斂保證**：2 輪硬上限 + `[DEBATE-UNRESOLVED]` 標記，不會無限辯論
- **漸進導入**：Phase 1 僅 Developer，低風險驗證效果
- **可逆性高**：debate 機制可隨時關閉，回退至單一 agent 模式

### 負面

- **Token 成本增加**：2-2.5x，需觀察 ROI
- **執行時間增加**：每個 Story 多 1-2 輪 subagent 派遣
- **流程複雜度**：主 session 需協調 Worker/Critic 交替，邏輯較單一 subagent 複雜

### 風險緩解

| 風險 | 緩解措施 |
|------|---------|
| Token 成本超過預期 | Story 規模門檻（僅 M/L 啟用）+ Phase 1 觀察期 |
| Critic 品質不佳（無效批判） | Critic prompt 精確定義批判維度（正確性、邊界、設計、測試覆蓋） |
| 無限辯論 | 2 輪硬上限 + 強制收斂 |
| Worker 與 Critic 意見分歧無法收斂 | `[DEBATE-UNRESOLVED]` 升級主 session，由人或 Scrum Master 仲裁 |
| Agent 間檔案交換失敗 | 復用 #379 worktree 機制（已驗證）；批判檔案路徑約定明確 |

---

## 附錄：方案比較表

| 維度 | 選項 A（自我批判） | 選項 B（序列雙 Agent） | 選項 C（交替批判） |
|------|-------------------|----------------------|-------------------|
| 外部視角 | 無 | 有 | 有 |
| 修復閉環 | 自修復（品質有限） | 無（需額外協調） | 有（Worker 直接修復） |
| Token 成本 | 1x | ~2x | 2-2.5x |
| 收斂保證 | 無限自我迴圈風險 | 單次批判即結束 | 2 輪硬上限 |
| 實作複雜度 | 低 | 中 | 中 |
| 預期效果 | 有限 | 中等 | 最佳 |
| 可逆性 | 高 | 高 | 高 |
