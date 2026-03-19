# Project Board

**最後更新**：2026-03-19（Sprint 104 Planning 完成）
**當前 Sprint**：Sprint 104（進行中）

工件導覽：[ROADMAP](prd/ROADMAP.md) → [Backlog](prd/PRODUCT_BACKLOG.md) → [Sprint 104](sprints/sprint_104.md) → 本看板 | [Tutorial](tutorial/README.md)

---

## Sprint 104（進行中）

> Sprint Goal：Sprint Git Flow 改為 PR-based — 禁止直推 main，引入 code review 環節提升程式碼品質

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| FEATURE：Sprint Git Flow 改為 PR-based — 禁止直推 main | #315 | L | 3 | 完成 |

**Sprint 容量**：3 points

---

## Sprint 103（完成）

> Sprint Goal：強化多 Session 並行可靠性 — 清理過期測試技術債、定義檔案鎖定架構、建立中斷恢復機制
> **結果**：Goal 達成（3/3 Stories PASS）。Velocity 7 points，完成率 100%。過期測試清理（#314）+ 檔案鎖定機制（acquire-file-lock.sh / release-file-lock.sh，ADR-022 選項 C 複用 #312 架構，32/32 PASS，CONFIRM）+ Sprint 中斷恢復機制（checkpoint JSON + claim-cleanup.sh，15/15 PASS，CONFIRM）。bump v0.74.0。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：刪除過期測試 test-us13 / test-us37 | #314 | S | 1 | 完成 |
| FEATURE：多 Session 並行開發的檔案鎖定機制 | #311 | L | 3 | 完成 |
| FEATURE：Sprint 中斷恢復機制（Spot VM / Session Crash） | #313 | L | 3 | 完成 |

**Sprint 容量**：7 points

## Sprint 103 統計
- Velocity：7 points
- 完成率：100%（完成 3 / 計畫 3）
- 日期：2026-03-19

---

## Sprint 102（完成）

> Sprint Goal：清除 Sprint 100 Retro 遺留測試技術債
> **結果**：Goal 達成（3/3 Stories PASS）。Velocity 3 points，完成率 100%。test-sprint-planning-skill.sh 修復（12/12 PASS）+ US-275 邊界補齊（空目錄 fallback + git pull 容錯）+ 測試技術債評估報告（test-us13/test-us37 建議刪除）。bump v0.73.1。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：修復 test-sprint-planning-skill.sh | #308 | S | 1 | 完成 |
| INFRA：US-275 邊界補齊 | #309 | S | 1 | 完成 |
| RESEARCH：評估既有測試技術債清理 | #310 | S | 1 | 完成 |

**Sprint 容量**：3 points

## Sprint 102 統計
- Velocity：3 points
- 完成率：100%（完成 3 / 計畫 3）
- 日期：2026-03-19

---

## Sprint 101（完成）

> Sprint Goal：落地多 Session 並行協調機制，防止跨 session 重複領取 Issue/Story
> **結果**：Goal 達成（1/1 Stories PASS）。Velocity 2 points，完成率 100%。三層協調機制（git remote ref 互斥鎖 + flock 本地原子鎖 + GitHub Issue 展示層）落地；獨立腳本 claim-issue.sh / release-issue.sh 可重用；SessionEnd hook 自動 release；外部審查 DISPUTE（4 缺陷）→ 修復後 CONFIRM。bump v0.73.0。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：多 Session 並行開發 — Issue/Story 級別協調機制 | #312 | M | 2 | 完成 |

**Sprint 容量**：2 points

## Sprint 101 統計
- Velocity：2 points
- 完成率：100%（完成 1 / 計畫 1）
- 日期：2026-03-19

---

## Sprint 100（完成）

> Sprint Goal：強化框架執行可靠性與 Anti-Hallucination 能力 — 補齊 story-lifecycle-prompt.md 執行漏洞（git commit 缺失、測試批量修復）、KM 文件 API 參數腦補防護、Sprint Planning 並行衝突修復、CI workflow 最佳實踐
> **結果**：Goal 達成（5/5 Stories PASS）。Velocity 6 points，完成率 100%。story-lifecycle-prompt.md 新增 §8.05 git commit Hard Gate + §3.5 測試批量修復策略 + §7.6 KM 第三方 API 驗證；Sprint Planning 並行衝突防護落地（po-prompt.md）；CI workflow cancel-in-progress 全覆蓋。bump v0.72.1。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：Story-Lifecycle subagent 完成後強制 git commit Hard Gate | #307 | S | 1 | 完成 |
| FEATURE：story-lifecycle-prompt: 測試修復批量執行策略 | #304 | S | 1 | 完成 |
| FEATURE：KM 第三方 API 文件驗證機制 — 禁止腦補 enum 值 | #276 | M | 2 | 完成 |
| INFRA：Bug：Sprint Planning 多 session 並行編號衝突修復 | #277 | S | 1 | 完成 |
| INFRA：CI/CD: 所有 workflow 加入 cancel-in-progress | #306 | S | 1 | 完成 |

**Sprint 容量**：6 points

## Sprint 100 統計
- Velocity：6 points
- 完成率：100%（完成 5 / 計畫 5）
- 日期：2026-03-19

---

## Sprint 99（完成）

> Sprint Goal：強化框架架構知識基礎與可展示性 — 補充 SDD-000 核心架構內容以解除 PB-2/PB-4 兩條產品線阻塞，並落地演示模式 Live Log Streaming 以提升框架的人機協作可見度，兌現 M5「好上手、人機協作」里程碑承諾。
> **結果**：Goal 達成（2/2 Stories PASS）。Velocity 2 points，完成率 100%。SDD-000 填充 8 Entity / 7 關聯 / 8 術語 / 4 層架構 / 8 Service / 6 Gateway 對照 / 6 元件邊界，解除 PB-2/PB-4 阻塞；Live Log Streaming 落地，story-lifecycle-prompt.md 各關鍵步驟均已加入日誌寫入指令，演示模式可用。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| FEATURE：SDD-000 核心章節補充至最低可用狀態（解除 PB-2/PB-4 共同阻塞） | #270 | S | 1 | 完成 |
| FEATURE：演示模式 Live Log Streaming 實作（Phase 1：tail -f 即時日誌串流） | #269 | S | 1 | 完成 |

**Sprint 容量**：2 points

## Sprint 99 統計
- Velocity：2 points
- 完成率：100%（完成 2 / 計畫 2）
- 日期：2026-03-15

---

## Sprint 98（完成）

> Sprint Goal：將 pr-review-toolkit 三 agent 補充審查層實作至 shoot 與 sprint-execution commit 前 Gate — 兌現 ADR-021 架構設計的工程品質深度承諾
> **結果**：Goal 達成（1/1 Stories PASS）。Velocity 2 points，完成率 100%。shoot §8.6 步驟 5.4 + sprint-execution §7.5 補充審查層完整實作，三 agent 平行派遣（code-reviewer / silent-failure-hunter / comment-analyzer）、CRITICAL/HIGH Hard Gate、doc-only 條件觸發、降級行為（WARN + 跳過 + 繼續）、引用式寫法避免體積膨脹，ADR-021 → #266 完整鏈條落地。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INTEGRATION：整合 pr-review-toolkit 審查 agents 至 shoot / sprint-execution commit 前 Gate | #266 | M | 2 | 完成 |

**Sprint 容量**：2 points

## Sprint 98 統計
- Velocity：2 points
- 完成率：100%（完成 1 / 計畫 1）
- 日期：2026-03-15

---

## Sprint 97（完成）

> Sprint Goal：定義 pr-review-toolkit 外部 Plugin 整合架構 — 為 #266 實作掃清前置依賴
> **結果**：Goal 達成（1/1 Stories PASS）。Velocity 1 point，完成率 100%。ADR-021 定義補充層整合模式（外部獨立審查後追加）、三 agent 平行派遣、嚴重度四級 Gate（CRITICAL/HIGH 阻擋）、降級行為（WARN + 跳過）、責任邊界（§8.5 Spec Compliance vs 步驟 5.4 工程品質深度）、Spike Report 含 5 項建議後續行動。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| RESEARCH：ADR — pr-review-toolkit 外部 Plugin 整合架構定義 | #267 | S | 1 | 完成 |

**Sprint 容量**：1 point

## Sprint 97 統計
- Velocity：1 point
- 完成率：100%（完成 1 / 計畫 1）
- 日期：2026-03-15

---

## Sprint 96（完成）

> Sprint Goal：強化框架品質護欄 — 版號驗證自動化、Skill 角色 prompt 拆分、UI/UX 設計前置 Gate，全面消除已知合規盲點
> **結果**：Goal 達成（6/6 Stories PASS）。Velocity 9 points，完成率 100%。版號驗證雙層 Hook（Git pre-commit + Claude Code PreToolUse）+ architecture-decision / deployment-readiness 角色 prompt 拆分 + UI/UX Design Foundation Gate（DESIGN=Hard / 非DESIGN=Soft）+ 演示模式 Spike Report（推薦 Live Log Streaming）。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-263：validate-version.sh 增強：README.md badge 版號檢查 | #259 | S | 1 | 完成 |
| US-264：版本驗證 Hook：commit 前自動檢查版號一致性 | #260 | M | 2 | 完成 |
| US-265：architecture-decision Skill 拆分：角色 prompt 檔案分離 | #261 | M | 2 | 完成 |
| US-266：deployment-readiness Skill 拆分：SRE / Security 角色 prompt 分離 | #262 | M | 2 | 完成 |
| US-267：UI/UX Designer 前置檢查：Design System / Design Token / Guideline 文件存在性驗證 | #258 | S | 1 | 完成 |
| US-268：演示模式 / 火力展示（Spike）：技術可行性報告 | #255 | S | 1 | 完成 |

**Sprint 容量**：9 points

## Sprint 96 統計
- Velocity：9 points
- 完成率：100%（完成 6 / 計畫 6）
- 日期：2026-03-14

---

## Sprint 95（完成）

> Sprint Goal：強化 Architect 審查 Gate 的分層合規性檢查能力
> **結果**：Goal 達成（1/1 Stories PASS）。Velocity 2 points，完成率 100%。Layer Compliance 分層合規檢查三層防線（QA WARN → Architect FAIL → 輸出範例同步），責任邊界清晰。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-257：Architect 審查 Gate 加入 Layer Compliance 分層合規檢查 | #254 | S | 2 | 完成 |

**Sprint 容量**：2 points

## Sprint 95 統計
- Velocity：2 points
- 完成率：100%（完成 1 / 計畫 1）
- 日期：2026-03-14

---

## Sprint 94（完成）

> Sprint Goal：修復版號一致性測試技術債 — 確保 CI 驗證腳本在缺少 `jq` 環境下正確報告失敗，恢復 4 個 FAIL 測試至 PASS 狀態
> **結果**：Goal 達成（1/1 Stories PASS）。Velocity 1 point，完成率 100%。jq preflight 存在性檢查 + 空字串版本防護 + TC-07/TC-08 新增測試案例，16/16 測試全 PASS。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-256：retro: 修復版號一致性測試 — Sprint 93 既有 FAIL 技術債清理 | #253 | S | 1 | 完成 |

**Sprint 容量**：1 point

## Sprint 94 統計
- Velocity：1 point
- 完成率：100%（完成 1 / 計畫 1）
- 日期：2026-03-13

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
| 2026-03-14 | Architect SDD 補領域模型審查 + Shoot QA 與 Sprint Execution 品質對齊 | #256 #257 | 2b00b30 |
| 2026-03-14 | Decision Table Testing 整合至 QA Engineer — 執行規程 + §1.17 + §4 對接 | #263 | dcd95d4 |
| 2026-03-15 | TDD 順序強制 Hard Gate + Sprint Review QA 缺陷修復複驗 Gate | #264 #265 | 065b338 |
| 2026-03-15 | ADR-020 SDD 作為 AC 強制上游約束 — SDD → AC → TDD 追溯鏈 | — | ec9b05d |
| 2026-03-15 | SDD 類別圖強制 Gateway 寫入入口 — 新增 DM-4 審查機制 | #268 | 0da8626 |

---

> 歷史 Sprint 記錄：[PROJECT_BOARD_ARCHIVE](km/archive/PROJECT_BOARD_ARCHIVE.md)（Sprint 1–87）
