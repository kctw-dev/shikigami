# Project Board

**最後更新**：2026-03-13（Sprint 94 Planning 完成）
**當前 Sprint**：Sprint 94（進行中）

工件導覽：[ROADMAP](prd/ROADMAP.md) → [Backlog](prd/PRODUCT_BACKLOG.md) → [Sprint 94](sprints/sprint_94.md) → 本看板 | [Tutorial](tutorial/README.md)

---

## Sprint 94（進行中）

> Sprint Goal：修復版號一致性測試技術債 — 確保 CI 驗證腳本在缺少 `jq` 環境下正確報告失敗，恢復 4 個 FAIL 測試至 PASS 狀態

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-256：retro: 修復版號一致性測試 — Sprint 93 既有 FAIL 技術債清理 | #253 | S | 1 | 待開發 |

**Sprint 容量**：1 point

---

## Sprint 93（完成）

> Sprint Goal：強化框架品質深度 — 資料品質 Gate、隱性需求捕捉、Smoke Test、探索性測試與 QA 視角升級 + 低記憶體環境控制
> **結果**：Goal 達成（6/6 Stories PASS）。Velocity 6 points，完成率 100%。QA 角色升級為「使用者代言人」+ AC 模板非功能屬性指引 + 資料品質 Gate（Hard Gate 覆蓋率驗證）+ Smoke Test 要求（外部資源 Story 真實資料驗證）+ Sprint Review 探索性測試（邊界案例清單）+ 低記憶體環境平行上限控制（SHIKIGAMI_MAX_PARALLEL）。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-250：QA 角色升級：從規格檢查員到使用者代言人 | #248 | S | 1 | 完成 |
| US-251：AC 模板補充非功能屬性指引 | #249 | S | 1 | 完成 |
| US-252：資料品質 Gate：補充靜態資料覆蓋率驗證機制 | #250 | S | 1 | 完成 |
| US-253：Smoke Test 要求：涉及外部資源的 Story 需真實資料驗證 | #251 | S | 1 | 完成 |
| US-254：Sprint Review 探索性測試：邊界案例與隨機輸入驗證 | #252 | S | 1 | 完成 |
| US-255：低記憶體環境平行 Subagent 數量上限控制 | #246 | S | 1 | 完成 |

**Sprint 容量**：6 points

## Sprint 93 統計
- Velocity：6 points
- 完成率：100%（完成 6 / 計畫 6）
- 日期：2026-03-13

---

## Sprint 92（完成）

> Sprint Goal：強化框架可靠性 — 修正外部 Issue 通知時機與 Subagent 結果持久化
> **結果**：Goal 達成（2/2 Stories PASS）。Velocity 3 points，完成率 100%。外部 Issue 階段 2 留言觸發時機修正（deployment-readiness PASS + E2E PASS 雙重條件）+ Subagent 結果暫存機制（§9.0 暫存寫入 + §3 CACHE-RECOVERY fallback）。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-248：sprint-review S2.6 外部 Issue 階段 2 留言觸發時機修正 | #242 | S | 1 | 完成 |
| US-249：Subagent 結果暫存 — context compaction 後結果復原機制 | #208 | M | 2 | 完成 |

**Sprint 容量**：3 points

## Sprint 92 統計
- Velocity：3 points
- 完成率：100%（完成 2 / 計畫 2）
- 日期：2026-03-13

---

## Sprint 91（完成）

> Sprint Goal：透過 SKILL.md 瘦身與角色 Prompt 拆分，將框架 context 消耗削減約 75%
> **結果**：Goal 達成（2/2 Stories PASS）。Velocity 5 points，完成率 100%。SKILL.md 瘦身 -1601 行（31.9%）+ 角色 Prompt 拆分（sprint-planning/sprint-review 各拆為 SKILL.md + 3 個角色 prompt）。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-246：SKILL.md 瘦身：移除 agent 已知的工具教學與重複樣板 | #245 | L | 3 | 完成 |
| US-245：SKILL.md 角色專屬 Prompt 拆分 — 減少 subagent context 消耗 | #244 | M | 2 | 完成 |

**Sprint 容量**：5 points

## Sprint 91 統計
- Velocity：5 points
- 完成率：100%（完成 2 / 計畫 2）
- 日期：2026-03-12

---

## Sprint 90（完成）

> Sprint Goal：CI/CD 可觀測性 + QA 流程補強 — Deploy 通知模板建立 + Systematic Debugging 自動觸發時機定義
> **結果**：Goal 達成（2/2 Stories PASS）。Velocity 2 points，完成率 100%。Systematic Debugging 三觸發點定義（Sprint Review HARD-GATE + Deploy 後/Bug 修復後建議觸發）+ Deploy 通知 Workflow 模板與 Deploy Board 初始化腳本建立。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-247：Systematic Debugging 自動觸發時機 — Sprint Review/Deploy/Bug Fix 三觸發點定義 | #240 | S | 1 | 完成 |
| US-246：CI/CD Deploy 通知 Workflow 模板 — deploy-notify.yml + Deploy Board 初始化 | #239 | S | 1 | 完成 |

**Sprint 容量**：2 points

## Sprint 90 統計
- Velocity：2 points
- 完成率：100%（完成 2 / 計畫 2）
- 日期：2026-03-12

---

## Sprint 89（完成）

> Sprint Goal：實作流程管理 MCP Server Phase 1，驗證 context compaction recovery 可行性，解決 Sprint 87/88 連續斷鏈問題
> **結果**：Goal 達成（1/1 Stories PASS）。Velocity 2 points，完成率 100%。流程管理 MCP Server Phase 1 實作完成（get_current_step / advance_step / get_remaining_steps），狀態持久化至檔案系統，Fallback 機制就緒，Context compaction recovery 可行性驗證通過。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-245：流程管理 MCP Server Phase 1 — Sprint 流程狀態機 | #238 | M | 2 | 完成 |

**Sprint 容量**：2 points

## Sprint 89 統計
- Velocity：2 points
- 完成率：100%（完成 1 / 計畫 1）
- 日期：2026-03-12

---

## Sprint 88（完成）

> Sprint Goal：框架品質全面強化 — TDD 需求理解升級 + Shoot CI Gate + E2E 修復 + MCP 三層架構評估 + 前端設計 Gate
> **結果**：Goal 達成（5/5 Stories PASS）。Velocity 7 points，完成率 100%。TDD 測試可寫性檢查（TC-W1~TC-W5）+ Shoot CI Gate + E2E workflow_dispatch 修復 + MCP 三層架構評估報告/POC/ADR-019 草稿 + 前端設計 Gate 三層機制（Pre-check/派遣/審查）。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-240：TDD 需求理解驗證 — 寫不出測試自動觸發 REQUIREMENT_AMBIGUITY 升級 | #237 | S | 1 | 完成 |
| US-241：shoot CI Gate — CI pass 才標 PASS | #236 | S | 1 | 完成 |
| US-242：E2E workflow placeholder 修復 | #206 | S | 1 | 完成 |
| US-243：MCP 三層架構 — 知識庫/流程管理/品質觀察 MCP Server | #231 | M | 2 | 完成 |
| US-244：前端 Story 設計資訊 Gate — Pre-check + 角色派遣 + 交付審查 | #198 | M | 2 | 完成 |

**Sprint 容量**：7 points

## Sprint 88 統計
- Velocity：7 points
- 完成率：100%（完成 5 / 計畫 5）
- 日期：2026-03-12

---

## 短衝記錄

| 日期 | 標題 | Issue/Story | commit hash |
|------|------|-------------|-------------|
| 2026-03-12 | Sprint Review 精簡化 — 移除快思/慢想、歸檔觸發、Token 成本、Backlog .md 同步 | #243 | fadde69 |
| 2026-03-12 | 清理 PRODUCT_BACKLOG.md / BACKLOG_DONE.md 殘留引用（ADR-010 對齊） | — | e98212b |

---

> 歷史 Sprint 記錄：[PROJECT_BOARD_ARCHIVE](km/archive/PROJECT_BOARD_ARCHIVE.md)（Sprint 1–87）
