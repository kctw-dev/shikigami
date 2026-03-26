# Sprint 170

**Sprint Goal：測試覆蓋補齊 Vol.2 — 補齊驗證腳本與衝突預測工具的自動化測試防護，確保 review-suggestion-audit、logrotate、analyze-dependencies、validate-orphans（整合）、update-adr-index、predict-conflicts 六支腳本在 CI 中有完整單元/整合測試覆蓋**

**開始日期**：2026-03-26
**結束日期**：2026-04-02
**容量**：6 pts
**Velocity 基準**：avg 5 pts（Sprint 167=5, Sprint 168=6, Sprint 169=6）

---

## Sprint Backlog

| Story | Issue | Size | Points | Story Type | Routing Tier | 狀態 |
|-------|-------|------|--------|-----------|-------------|------|
| feat: review-suggestion-audit.sh 自動化測試 | #880 | S | 1 | TEST | haiku（強制） | TODO |
| feat: logrotate.sh 自動化測試 | #878 | S | 1 | TEST | haiku（強制） | TODO |
| feat: analyze-dependencies.sh 自動化測試 | #877 | S | 1 | TEST | haiku（強制） | TODO |
| feat: validate-orphans.sh 整合測試 | #875 | S | 1 | TEST | haiku（強制） | TODO |
| feat: update-adr-index.sh 自動化測試 | #873 | S | 1 | TEST | haiku（強制） | TODO |
| feat: predict-conflicts.sh 自動化測試 | #866 | S | 1 | TEST | haiku（強制） | TODO |

**總計：6 pts**

---

## Architect 技術評估

- 全部 6 個 Story PASS，無需 ADR
- Hard Gate PASS（無技術選型 Story）
- ADR 衝突預偵測：下一個可用 ADR 編號為 ADR-045（無新 ADR 需求）
- 複雜度評估：PASS（Skill=31/40, Agent=8/15, Hooks=30/35, Lines=10049/25000）
- 平行分群：全部 6 個 Story 各自新建獨立 tests/ 檔案，可完全平行執行

| 分群 | Stories | 修改檔案 |
|------|---------|---------|
| Group A | #880 | tests/test-review-suggestion-audit.sh（新建） |
| Group B | #878 | tests/test-logrotate.sh（新建） |
| Group C | #877 | tests/test-analyze-dependencies.sh（新建） |
| Group D | #875 | tests/test-validate-orphans-integration.sh（新建） |
| Group E | #873 | tests/test-update-adr-index.sh（新建） |
| Group F | #866 | tests/test-predict-conflicts.sh（新建） |

---

## QA 驗收確認

| Story | AC 驗收 | Path Verification | 隱性需求 | 結論 |
|-------|--------|------------------|---------|------|
| #880 | PASS（AC 完整，含 fixture 隔離）| PASS（review-suggestion-audit.sh 存在）| 執行時間隱性期待（Minor，已有 NFR1）| CONFIRMED |
| #878 | PASS（AC 完整，含 fixture 隔離）| PASS（logrotate.sh 存在）| 同上 | CONFIRMED |
| #877 | PASS（AC 完整，含 fixture 隔離）| PASS（analyze-dependencies.sh 存在）| 同上 | CONFIRMED |
| #875 | PASS（AC 完整，E2E 真實 repo）| PASS（validate-orphans.sh 存在）| 執行時間 < 10s（已定義 NFR1）| CONFIRMED |
| #873 | PASS（AC 完整，含 fixture 隔離）| PASS（update-adr-index.sh 存在）| 執行時間 < 5s（已定義 NFR1）| CONFIRMED |
| #866 | PASS（AC 完整，含 fixture 隔離）| PASS（predict-conflicts.sh 存在）| 同上 | CONFIRMED |

---

## RICE Score 與 Routing Tier 交叉審查

| Story | Story Type | Risk Score | Routing Tier |
|-------|-----------|-----------|-------------|
| #880 | TEST | 5 | haiku（強制） |
| #878 | TEST | 5 | haiku（強制） |
| #877 | TEST | 5 | haiku（強制） |
| #875 | TEST | 5 | haiku（強制） |
| #873 | TEST | 5 | haiku（強制） |
| #866 | TEST | 5 | haiku（強制） |

haiku 比例：6/6 = 100% ✅（> 20% 門檻）

---

## NFR 待補充 Issues（本 Sprint 未選入）

以下 Issues 缺少 `## 非功能性需求` 欄位，退回 Backlog 待補充後重新評估：

- **#894** retro: validate-a2a-schema.sh 補充 story_id integer 型別文件 — 非功能屬性待補
- **#895** retro: 建立 routing-history schema 規格文件 — 非功能屬性待補
- **#886** retro: 驗證腳本整合測試補齊 — 非功能屬性待補（M-size，另需補 RICE Score）
