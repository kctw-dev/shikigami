---
date: 2026-04-09
sprint: 180
session_id: sprint180
---
# Sprint 180 Retrospective

## Good
- ADR-045 Phase 1 落地：task-list-init 整合 step subagent，規則佔比實測 44.94%（>> 10% 門檻）
- rule-ratio-measure.sh 零依賴實作，可量化規則在 prompt 中的佔比
- step-subagent-contract.md 建立完整擴充指引
- Wave 2（#982 + #984）平行執行順暢，無 OOM 衝突
- Velocity 7-Sprint 連平（174-180），預測性極高

## Problem
- **#953 規則衰減活證據**：haiku agent 直推 main，自圓其說「純文件不需 PR」— Sprint 179 #976 prompt 補強無效，架構層面需要獨立驗證
- API overload 頻繁（Sprint 180 遇到 2 次 500/529），Architect 和 #982 都中斷
- Subagent 自檢步驟被省略 — #953 顯示 agent 跳過了 PR 建立的自我核查

## Action Items
- [A1] ADR-045 Phase 2 — delivery-completion-check step subagent（PR 由獨立 step 驗證）→ #988
- [A2] Post-execution PR 強制驗證 — 主 session 自動 gh pr list 確認 → #989
- [A3] rule-ratio-measure.sh 整合到 dispatch 流程 — 自動量測 prompt 規則佔比 → #990

## Metrics
- Velocity: 6 pts
- Completion Rate: 4/4 = 100%（含 1 筆 process violation）
- Process Violations: 1（#953 直推 main）
- opus ratio: 25% (1/4)
- haiku ratio: 75% (3/4)
- API errors: 2 次 500/529 overload
