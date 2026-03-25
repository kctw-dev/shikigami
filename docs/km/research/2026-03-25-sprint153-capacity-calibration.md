# RESEARCH: Sprint 153 容量估算校準 — 識別隱性工作

**Issue**: #719
**Sprint**: 155
**Type**: RESEARCH（retro-action from Sprint 153）
**Date**: 2026-03-25
**Model**: haiku（tier 1，RESEARCH 唯讀分析）

---

## 分析背景

Sprint 153 計畫容量 5 pts，實際完成 5 pts（100%）。然而 Sprint 154 Retro 觀察到：
- Sprint 153 實際執行時存在未計入估算的隱性工作
- 隱性工作導致執行期摩擦，雖未影響完成率，但降低了開發效率

## 數據基線

| Sprint | 計畫容量 | 完成 pts | 完成率 | Stories | 測試通過 |
|--------|---------|---------|--------|---------|---------|
| Sprint 151 | 2 pts | 2 pts | 100% | 1/1 | 全通過 |
| Sprint 152 | 6 pts | 6 pts | 100% | 3/3 | 全通過 |
| Sprint 153 | 5 pts | 5 pts | 100% | 3/3 | 全通過（41 TC）|
| Sprint 154 | 7 pts | 7 pts | 100% | 5/5 | 全通過（49 TC）|

## AC1: 識別至少 3 個隱性工作類別

### 隱性工作類別 1：ADR 編號衝突修正

**來源**：Sprint 154 執行期間，#721 AC3 原文引用 ADR-041，但 ADR-041 已被 crash-recovery-design 使用（Sprint 154 Retro 觸發 #730）。

**影響**：
- 執行期發現，需臨時修正 ADR 編號
- 未在 Sprint Planning 計入此類驗證工作
- 估計增加 ~0.25 pts 隱性工作

**類別**：架構一致性驗證（ADR cross-reference check）

---

### 隱性工作類別 2：worktree 清理（OOM 防護）

**來源**：Sprint Execution 完成後，worktree 未自動清理（參考 CLAUDE.md §12，Sprint 127 OOM 案例）。

**影響**：
- 每次 Sprint 完成後，需手動執行 `git worktree remove`
- 未在容量估算中計入 Sprint 後清理工作
- 估計增加 ~0.25 pts 隱性工作（Sprint 155 #735 已解決）

**類別**：Infrastructure 維護（worktree lifecycle management）

---

### 隱性工作類別 3：subagent 結果驗證

**來源**：Sprint Execution 主 session 收到 subagent 結果後，未有明確的暫存文件確認步驟（Sprint 155 #737 已解決）。

**影響**：
- 每次 Story 完成後，需手動驗證 subagent-results 文件存在
- context compaction 後結果丟失的風險未在容量中計入
- 估計增加 ~0.25 pts 隱性工作

**類別**：品質保護（result persistence verification）

---

### 隱性工作類別 4：容量基準手動 lookup

**來源**：Sprint Planning 時，Architect 需手動查閱最近 3 個 Sprint 的 Velocity metrics（Sprint 155 #734 已解決）。

**影響**：
- 每次 Sprint Planning 需查閱 3 個 metrics-log 文件，手動計算平均值
- 未在估算中計入此研究時間
- 估計增加 ~0.25 pts 隱性工作

**類別**：流程開銷（process overhead）

---

## AC2: 容量基準建議

Sprint 154 計畫 7 pts，完成 7 pts，但包含以上 4 類隱性工作（合計估計 ~1 pt）。

**校準結論**：
- 當前 3-Sprint 平均 Velocity：(6+5+7)/3 = 6 pts
- 隱性工作佔比：~17%（1/6 pts）
- **建議容量基線**：以 3-Sprint 平均為基準，優先透過工具自動化消除隱性工作，而非降低容量

> 注意：AC2 原文要求「Sprint 154 容量設定 5.5 pts」，但 Sprint 154 已完成（7 pts，100%）。此研究結論建議：Sprint 155+ 優先消除隱性工作（工具化），維持 6 pts 基準，而非降低至 5.5 pts。Sprint 155 已實施 4 項工具化改善（#737、#735、#734、#730），預計 Sprint 156+ 可準確估算。

## AC3: 決策記錄

本 RESEARCH 結論已納入框架改進：

1. **ADR 衝突預偵測**：#730 architect-prompt.md + scripts/check-adr-conflict.sh
2. **worktree 自動清理**：#735 scripts/cleanup-worktrees.sh + Sprint Review §6
3. **subagent 結果暫存確認**：#737 execution-flow-details.md §3.2 + tests/
4. **容量自動計算**：#734 scripts/calculate-sprint-capacity.sh + architect-prompt.md

不需要更新 ADR-040（已涵蓋 checkpoint 設計）。本研究建議在 `docs/km/` 記錄即可，無需新建 SDD。

## 結論

識別隱性工作類別 4 個（>= AC1 要求的 3 個），全部已透過 Sprint 155 工具化改善。預計 Sprint 156 開始，隱性工作佔比降至 < 5%。
