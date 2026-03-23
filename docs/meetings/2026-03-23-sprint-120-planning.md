---
type: sprint-planning
sprint: 120
date: "2026-03-23"
start_time: "2026-03-23T18:32+08:00"
end_time: "2026-03-23T18:35+08:00"
participants:
  - role: PO
    rounds: [1, 2]
  - role: Architect
  - role: QA
---

# Sprint 120 Planning 會議紀錄

## 結論
- Sprint Goal: PO 巡邏行為修正 + CI 基礎設施修復 + code-review 強化
- 選入 Stories: #381, #412, #422, #415, #421（5 Stories, 10 pts）

## 決議事項
1. #381 CI workflow 修復為 P0，優先處理
2. #412 與 #422 同根因（PO patrol 行為缺陷），需序列執行：先 #412 建立交付物識別基礎，再 #422 建立 Stakeholder 回覆處置表
3. #415 有 Stakeholder 4 則具體指示（shoot_skip_merge, self_review 等），設計方向明確
4. #421 為 Sprint 119 Retro action，Size=S，獨立可平行
5. 平行分群：Phase 1（#381, #415, #421 可平行）+ Phase 2（#412 → #422 序列）

## Story 選取依據
- 本 Sprint 聚焦 PO patrol 行為修正（3 個 beta-feedback issues 同時解決同根因）
- CI workflow 為 P0 基礎設施問題，持續影響所有新 Issue 自動化流程
- Retro action #421 為低成本高收益改善項目
