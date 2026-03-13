# Sprint 93

**Sprint Goal**：強化框架品質深度 — 資料品質 Gate、隱性需求捕捉、Smoke Test、探索性測試與 QA 視角升級 + 低記憶體環境控制
**日期**：2026-03-13
**容量**：6 points

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-250：QA 角色升級：從規格檢查員到使用者代言人 | #248 | S | 1 | 完成 |
| US-251：AC 模板補充非功能屬性指引 | #249 | S | 1 | 完成 |
| US-252：資料品質 Gate：補充靜態資料覆蓋率驗證機制 | #250 | S | 1 | 完成 |
| US-253：Smoke Test 要求：涉及外部資源的 Story 需真實資料驗證 | #251 | S | 1 | 完成 |
| US-254：Sprint Review 探索性測試：邊界案例與隨機輸入驗證 | #252 | S | 1 | 完成 |
| US-255：低記憶體環境平行 Subagent 數量上限控制 | #246 | S | 1 | 完成 |

## 執行順序

Phase 1（平行）：
- Group A（US-251）：AC 模板非功能屬性指引 — Story 模板 + PO prompt + QA SKILL.md
- Group B（US-253）：Smoke Test 指引 — 外部資源 Story 定義 + Code Review 檢查點
- Group C（US-254）：探索性測試 — Sprint Review Demo 邊界案例環節 + QA 主導
- Group D（US-255）：低記憶體控制 — SHIKIGAMI_MAX_PARALLEL 環境變數 + 平行分群上限

Phase 2（序列）：
- US-250（QA 角色升級）→ US-252（資料品質 Gate）
- US-250 定義 QA 新職責後，US-252 的資料品質檢查清單才能正確嵌入 QA 流程

## 技術評估摘要

- US-250：S/1pt，FEATURE type。QA subagent 職責升級為「使用者代言人」，sprint-planning 主動追問隱性期待、sprint-review 執行探索性測試、Code Review 檢查 mock 假設真實性。影響 QA subagent 提示詞。
- US-251：S/1pt，FEATURE type。Story/AC 模板增加非功能需求欄位（freshness、completeness、performance 等），PO prompt 加入「至少一個非功能屬性」指引，QA SKILL.md 補充非功能屬性檢查清單。
- US-252：S/1pt，FEATURE type。靜態資料檔覆蓋率指標定義，Sprint Review 資料集覆蓋率檢查，QA SKILL.md 資料品質檢查清單，Code Quality Review 資料覆蓋率 Hard Gate。Blast Radius 分析 + 量化閾值對照。
- US-253：S/1pt，FEATURE type。涉及外部資源 Story 定義清單，smoke test 真實資料驗證要求，Code Review 檢查點補充，框架文件「何時需要 Smoke Test」指引。Input Validation Matrix 對照。
- US-254：S/1pt，FEATURE type。Sprint Review Demo 增加邊界案例測試環節，Demo 報告含邊界案例驗證結果，常見邊界案例清單（CJK 冷門字、時間邊界、空值等），QA 主導邊界案例測試。Input Validation Matrix 對照。
- US-255：S/1pt，FEATURE type。新增 SHIKIGAMI_MAX_PARALLEL 環境變數控制平行 subagent 上限，未設定時不限制，=1 時強制循序，Architect 平行分群階段檢查上限並自動拆批。
