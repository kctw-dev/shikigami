# Product Brief：同職能 Team 內部 Debate

**狀態**：草稿
**來源**：#362 P0 GAD 研究報告 §六
**日期**：2026-03-23

---

## 1. 問題陳述

目前 Shikigami 的每個角色（Developer、QA、Architect）由單一 subagent 執行，產出直接交跨職能 Veto Gate 審查。等於個人作業直接交審，缺乏同儕討論與內部批判。品質基線取決於單一 agent 的能力上限，無法透過辯論發現盲點。

## 2. 目標使用者

- **直接受益**：使用 Shikigami 執行 Sprint 的開發團隊 — 交付品質提升
- **間接受益**：PO / Stakeholder — 減少 Sprint Review 時的 DISPUTE 率

## 3. 商業假設

- [UNCERTAIN] 假設：多個同職能 agent 辯論後的產出品質 > 單一 agent — 驗證方法：A/B 對照實驗（同 Story 跑兩種模式比較 DISPUTE 率）
- [UNCERTAIN] 假設：token 成本增加可接受（3-5 個 agent vs 1 個，預估 3-5x）— 驗證方法：實測一個 Sprint 的 token 消耗比較
- [UNCERTAIN] 假設：Devil's Advocate 不會讓流程卡住（無限辯論）— 驗證方法：設定辯論輪數上限（2 輪）+ timeout
- [UNCERTAIN] 假設：Claude Code Agent tool 支援多 agent 共享 context 或檔案交換 — 驗證方法：技術 PoC（worktree + 檔案交換 as fallback）

## 4. 提案解決方向

### 方案 A：Agent Team 模式（推薦）

每個角色從單一 subagent 升級為小型 team：

```
Scrum Master 派任 Story
    ↓
【新增】同職能 Team 內部 Debate
    ├── Worker × 2（同職能，各自實作）
    ├── Reviewer（同職能視角，審查兩份產出）
    └── Devil's Advocate（刻意找漏洞）
    ↓
Team 共識產出（2 輪辯論上限）
    ↓
交跨職能 Veto Gate（現有流程）
```

### 方案 B：輕量版 — 單一 agent + 自我辯論

不增加 agent 數量，改在 prompt 中加入 Devil's Advocate 指令，讓同一 agent 先產出、再自我批判、再修正。成本最低但效果可能有限。

### 方案 C：雙 agent 交替（折衷）

兩個 agent 交替：Agent A 實作 → Agent B 批判 → Agent A 修正。比方案 A 省 token，但保留外部視角。

## 5. 成功指標

| 指標 | 目標 | 量測方式 |
|------|------|---------|
| Sprint Review DISPUTE 率 | 下降 30%+ | Metrics_Log.md 外部抽樣 DISPUTE 數 |
| 自審 PASS 後外部審查仍 PASS 的比率 | 提升至 90%+ | 外部抽樣 CONFIRM 率 |
| token 成本增幅 | < 3x（相對單一 agent）| 實測比較 |
| 辯論收斂效率 | 90% 在 2 輪內收斂 | 辯論輪數統計 |

## 6. 排除範圍

- 不改變跨職能 Veto Gate 機制（保留現有 QA/Architect gate）
- 不改變 Sprint Planning / Review 流程
- 不適用於 doc-only Story（成本不值得）
- Phase 1 僅 Developer 角色實作 team debate，其他角色後續擴展

## 7. 依賴與風險

| 項目 | 類型 | 說明 |
|------|------|------|
| Claude Code Agent tool 多 agent 通訊 | 技術依賴 | 需確認 agent 間是否能共享 context 或透過檔案交換 |
| worktree 隔離（#379） | 前置依賴 | Team 內多 agent 平行執行需要 worktree 隔離，已完成 |
| token 成本 | 風險 | 3-5x 成本增幅，可能需要限制啟用條件（僅 M/L Story） |
| 辯論品質 vs 單一 agent | 風險 | 若辯論反而引入噪音降低品質，需要有退出機制 |
