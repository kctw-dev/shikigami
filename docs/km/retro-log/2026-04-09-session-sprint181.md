# Retro Log — Sprint 181 Session

**日期**：2026-04-09
**Sprint**：181
**Session Type**：Retrospective

## 指標快照

- Velocity: 6 pts（連續第 8 Sprint，平均 6 pts/Sprint）
- Completion: 3/3 = 100%
- Process Violations: 0（Sprint 180 = 1，改善 1 筆）
- Model Routing: sonnet×2, haiku×1（符合 ADR-039 路由策略）

## 架構里程碑

Sprint 181 完成 ADR-045 雙層防禦架構：
- **L1**：主 session inline bash 強制驗證（#989/PR#991）
- **L2**：獨立 step subagent 外部查驗（#988/PR#992）
- **Preflight**：rule-ratio 機械性量測（#990/PR#993）

TC2 (#953 情境重放) 通過外部 QA 驗證 → 架構有效。

## 學習記錄

### L1：AC 軟性字樣仍是 PO 輸出的高頻問題
PO Round 1 輸出包含「考慮」「明確」「適當」等模糊用詞，需要清單機制強制自檢。
→ Action: #994

### L2：opus API overloaded 是自動化流程的脆弱點
兩次 529/500 均在靜態例外 agent（opus 固定路由）發生，fallback 機制缺失。
→ Action: #995

### L3：工具預設閾值與業務需求對齊問題
rule-ratio-measure.sh THRESHOLD=0.10 是全域預設，無法反映各 step subagent 不同需求。
→ Action: #996

## Rule Ratio 實測數據

- delivery-completion-check prompt: **44.07%**（門檻 30%，PASS with margin +14%）

## Action Issues 建立記錄

| Issue | 標題 | 點數 |
|-------|------|------|
| #994 | PO Prompt Template 加入「禁用軟性字樣」清單 | 2 pts |
| #995 | Subagent API Error Fallback 機制 | 3 pts |
| #996 | rule-ratio-measure.sh 支援 per-prompt THRESHOLD 參數 | 2 pts |

## Routing Stats

routing-stats.sh 執行完成，dashboard 已更新：
`docs/km/model-routing-dashboard.md`（共分析 29 條 model-route 記錄，最近 10 Sprint）
