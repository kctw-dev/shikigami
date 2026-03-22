---
type: sprint-planning
sprint: 114
date: "2026-03-22"
start_time: "2026-03-22T09:20:00+0800"
end_time: "2026-03-22T09:21:22+0800"
participants:
  - role: PO
    rounds: [1, 2]
  - role: Architect
  - role: QA
---

# Sprint 114 Planning 會議紀錄

## 結論
- Sprint Goal: Cruise Mode 穩定性與可用性改善 — SRE org-level runner + 嚴格模式
- 選入 Stories: #325（SRE org-level runner API, 1pt）、#326（--strict 嚴格模式, 2pt）

## 決議事項
1. 兩個 Story 都修改 `skills/cruise/SKILL.md`，但不同 section，無衝突
2. #325：org-level API 優先，fallback repo-level（個人帳號 repo 無 org）
3. #325：owner 類型偵測（org vs user）決定查詢路徑
4. #326：--strict flag 解析，THRESHOLD_DAYS 參數化（預設 3 / strict 0）
5. #326：flag 位置無關（`--strict 10m` 或 `10m --strict` 皆可）
6. 不需 ADR — 行為微調，不改變架構決策
7. #271 research 低優先，不排入本 Sprint

## Architect 評估
- #325：SRE Runner 健康檢查從 repo-level 改為 org-level 預設，偵測 owner 類型決定路徑
- #326：參數解析加入 --strict flag，閾值從硬編碼 3 天改為 THRESHOLD_DAYS 變數
- 共同修改 SKILL.md 不同 section，執行順序無限制
- 跨機器安全：只改框架定義檔，無 per-session 資料問題

## QA 評估
- #325：4 項 AC，結構型 + 測試執行型，全部可驗證
- #326：5 項 AC，結構型 + 行為型 + 測試執行型，全部可驗證
- DoR：PASS
- 防漂移基準：2 Stories, 3 pts
