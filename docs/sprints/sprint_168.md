# Sprint 168

**Sprint Goal：可觀測性強化 x 測試防護補齊 — Backlog Discovery 補充、路由歷史修正、高 RICE 測試覆蓋優先交付**

**開始日期**：2026-03-26
**結束日期**：2026-04-02
**容量**：6 pts
**Velocity 基準**：avg 5 pts（Sprint 164=4, Sprint 165=5, Sprint 166=6, Sprint 167=5）

---

## Sprint Backlog

| Story | Issue | Size | Points | Story Type | Routing Tier | 狀態 |
|-------|-------|------|--------|-----------|-------------|------|
| retro: Backlog 嚴重不足 | #864 | M | 2 | PROCESS | sonnet | DONE (#877-#884) |
| retro: routing-stats haiku 比例偏低 | #863 | S | 1 | LOG | haiku（強制） | DONE (1872e02) |
| feat: routing-stats 歷史趨勢補齊 | #867 | S | 1 | INFRA | haiku（強制） | DONE (be27820) |
| feat: injection-scan.sh 自動化測試 | #870 | S | 1 | TEST | haiku（強制） | DONE (c20da05) |
| feat: measure-complexity.sh 自動化測試 | #865 | S | 1 | TEST | haiku（強制） | DONE (9239de1) |

**總計：6 pts**

---

## Architect 技術評估

- 全部 5 個 Story PASS，無需 ADR
- Hard Gate PASS（無技術選型 Story）
- ADR 衝突預偵測：下一個可用 ADR 編號為 ADR-045
- 平行分組：Group A（#870 + #865）、Group B（#863 + #867）、Group C（#864）
- 所有 Story 修改不同檔案，可平行執行（MAX_PARALLEL=2）

## QA 驗收確認

- #867, #870, #865：AC 確認 PASS
- #864, #863：Conditional PASS（retro-action AC 偏描述性，已補強）
  - #864 補充 AC：Discovery 產出的 Issue 含 User Story + AC + RICE + size label
  - #863 補充 AC：輸出調查報告，含缺漏 Sprint 清單
- D3 Debate：不觸發（Architect 與 QA 無分歧）

## Model Routing

| Story | Story Type | Risk Score | Routing Tier |
|-------|-----------|-----------|-------------|
| #864 | PROCESS | 8 | sonnet |
| #863 | LOG | 5 | haiku（強制） |
| #867 | INFRA | 5 | haiku（強制） |
| #870 | TEST | 4 | haiku（強制） |
| #865 | TEST | 4 | haiku（強制） |

haiku_ratio = 4/5 = 80%（超過 20% 門檻）

## Next Sprint Preview

- 延續 Backlog Discovery 補充成果，優先選入新產出的高 RICE 候選
- #848: feat: 複雜度趨勢追蹤 — measure-complexity 歷史記錄與增速預警（S, RICE 3.4）
- #842: feat: Cruise Log 搜尋增強 — type 篩選、時間範圍、統計摘要（S, RICE 3.2）

---

## 複雜度預算

- SKILL_COUNT: 31（門檻 40）— PASS
- AGENT_COUNT: 8（門檻 15）— PASS
- HOOK_COUNT: 30（門檻 35）— PASS
- TOTAL_LINES: ~10049（門檻 25000）— PASS
- 本 Sprint 新增測試腳本 + 調查報告 + Discovery Issue，不新增 Skill/Agent，複雜度預算安全
