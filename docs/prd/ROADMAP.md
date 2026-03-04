# 產品路線圖

> 最後更新：2026-03-04（Sprint 41 US-84 — M4 里程碑正式收尾：US-14 完成標注、M4 結案評估記錄）
> 擁有者：Product Owner

本文件是里程碑規劃的**唯一來源（Single Source of Truth）**。
各 Story 細節見 `docs/prd/PRODUCT_BACKLOG.md`，Sprint 執行見 `docs/sprints/`。

---

## 版號策略

每個 Sprint 完成後 minor bump（v0.4.0, v0.5.0...），直到達成 v1.0.0 條件。目前版本：**v0.20.0**（Sprint 36）。

| 版號 | 含義 |
|------|------|
| v0.1.0 ~ v0.3.0 | 已交付的歷史里程碑（M1–M4，git tag 已存在） |
| v0.4.0 ~ v0.10.0 | M5 穩定化階段增量交付（minor bump per Sprint） |
| v1.0.0 | 外部使用者可穩定使用（M5 全部完成條件達成後） |

後續的「M4 外部整合」「M5 穩定化」為**內部里程碑名稱**，不對應 git tag 版號。

---

## v0.1.0 核心框架 — 已交付

**主題**：建立 AI Agent Scrum Team 基礎能力

**目標**：14 個 Skills + 7 個 Agents + 3 個 Commands 完整運作，Issue Management 全生命週期管理

| Story | 功能 | Sprint |
|---|---|---|
| Story 5 | 專案等級自治策略（low/medium/high） | Sprint 1 |
| Story 1 | Issue Lifecycle Management（7 個子流程） | Sprint 1 |
| ADR-001 | Backlog Bridge 編排模式決策 | Sprint 1 |
| Story 2 | Backlog Bridge（Issue → User Story） | Sprint 1 |
| Story 3 | Issue Comment（場景模板自動回覆） | Sprint 1 |
| Story 4 | Issue Triage（自動分類 + 補充資訊請求） | Sprint 1 |

**完成條件**：所有 Story AC 通過、Sprint Review 驗收、Retrospective 完成

---

## v0.2.0 自我感知 — 已交付（Sprint 2–3）

**主題**：讓框架能觀察自己、診斷自己、引導新使用者

**目標**：新專案 5 分鐘內完成 Shikigami 設定，框架能自我檢查健康狀態

| Story | 功能 | Sprint |
|---|---|---|
| US-06 | Onboarding Skill — 自動初始化專案文件結構 | Sprint 3 ✅ |
| US-07 | Health Check Skill — 自我診斷框架完整性 | Sprint 2 ✅ |
| US-08 | Sprint Metrics — Velocity 追蹤與趨勢分析 | Sprint 4 ✅ |

### US-06：Onboarding（專案初始化）

新使用者安裝 Shikigami 後，說「幫我設定專案」即可自動：
- 建立 `docs/` 目錄結構（prd/, adr/, sprints/, km/）
- 從 templates/ 複製初始文件（PROJECT_BOARD, PRODUCT_BACKLOG, ROADMAP）
- 生成 CLAUDE.md（詢問專案名稱、技術棧、專案等級）
- 引導第一次 Product Discovery

### US-07：Health Check（自我診斷）

說「檢查一下框架狀態」即可自動：
- 檢查必要文件是否存在（CLAUDE.md, PROJECT_BOARD, PRODUCT_BACKLOG）
- 檢查 Backlog 是否有孤兒 Story（標記 In Sprint 但 Sprint 文件不存在）
- 檢查 ADR 一致性（Story 標注需要 ADR 但 ADR 不存在或未 Accepted）
- 檢查 Retro Action Items 是否有逾期未關閉
- 產出健康報告摘要

### US-08：Sprint Metrics（度量與趨勢）

Sprint Review 時自動產出：
- Velocity 趨勢（每 Sprint 完成的 Story Points）
- 完成率（計畫 vs 實際交付）
- 累積至 `docs/km/Metrics_Log.md`
- 跨 Sprint 趨勢分析（改善中/退步中/穩定）

**完成條件**：新專案能零配置啟動、Health Check 能偵測至少 5 種異常、Metrics 能回溯分析 3+ 個 Sprint

> **備注**：v0.2.0 全部交付完成。核心功能（Onboarding + Health Check）於 Sprint 2–3 交付，US-08 Sprint Metrics 於 Sprint 4 補完。

---

## v0.3.0 知識沉澱 — 已交付（Sprint 4–6）

**主題**：框架從過去的經驗中學習，讓每個 Sprint 比上一個更好

**目標**：Retrospective 趨勢自動分析，Tech Debt 系統化管理，品質保障體系機制化

| Story | 功能 | Sprint |
|---|---|---|
| US-09 | Retrospective Analytics — 問題趨勢分析與模式辨識 | Sprint 4 ✅ |
| US-10 | Tech Debt Registry — 技術債追蹤與自動排入 Backlog | Sprint 5 ✅ |
| ADR-002 | 測試框架技術選型（Pure Bash + shared library） | Sprint 5 ✅ |
| ADR-003 | SQA 審計閘介入模型（3 Hard Gate + 1 Soft Gate） | Sprint 5 ✅ |
| US-T01 | Skill 完整性驗證 | Sprint 5 ✅ |
| US-FIX-01 | 修復審計發現（16 項框架監控缺口） | Sprint 5 ✅ |
| US-T02 | Agent 完整性驗證 | Sprint 6 ✅ |
| US-T03 | JSON Schema 驗證 | Sprint 6 ✅ |
| US-FIX-02 | Hard Gate Checklist 機制 | Sprint 6 ✅ |
| US-11 | Decision Knowledge Base — ADR 查詢與決策影響追蹤 | 延後至 v0.4.0+ |

### US-09：Retrospective Analytics

分析 `Retrospective_Log.md` 歷史紀錄：
- 統計 Good/Problem/Action 的分類頻率
- 辨識重複出現的 Problem（代表根因未解決）
- 追蹤 Action Items 的關閉速度（平均幾個 Sprint 關閉）
- 每次 Retrospective 前先展示歷史趨勢，避免重複犯錯

### US-10：Tech Debt Registry

建立 `docs/km/TECH_DEBT.md`：
- 開發過程中標記的技術債自動收集（Developer/Architect 標記 `[TECH-DEBT]`）
- RICE 評分排序，定期在 Backlog Grooming 時由 PO 審視
- 與 Story 關聯（「這個 Story 引入了哪些技術債」）
- 技術債總量趨勢（增加中/減少中/穩定）

### US-11：Decision Knowledge Base

讓 ADR 不只是存檔，而是可查詢的知識庫：
- 說「之前有沒有類似的架構決策？」→ 搜尋相關 ADR
- ADR 影響追蹤：這個決策影響了哪些 Story、哪些檔案
- 決策失效偵測：如果後續 Sprint 因為某決策出問題，標記 ADR 為 `Superseded`

**完成條件**：Retrospective 趨勢分析能回溯全部歷史、Tech Debt 有完整生命週期、品質保障機制化（5 驗證腳本 + 3 Hard Gate）

> **備注**：v0.3.0 核心目標全部交付完成。US-11 Decision Knowledge Base 從未被列為 v0.3.0 Must 條件，延後至 v0.4.0+ 不影響里程碑結案。品質保障體系（ADR-002/003 + US-T01~T03 + US-FIX-01~02）為 Sprint 5–6 的額外產出，超出原定規劃。

---

## M4 外部整合 — 已達成 ✅（內部里程碑，Sprint 41 正式收尾）

**主題**：與真實開發工具鏈整合，從「指引框架」進化為「執行框架」

**目標**：CI/CD 狀態感知、DORA Metrics、通知機制

| Story | 功能 | Sprint |
|---|---|---|
| ADR-011 | GitHub Actions 整合架構決策 — **ADR Accepted ✅**（Option A: Push-Based 事件觸發，Sprint 39 正式裁決） | Sprint 39 ✅ |
| US-12 | GitHub Actions 整合 — CI/CD 狀態感知 | Sprint 39 ✅ |
| US-13 | DORA Metrics — 部署頻率、變更前置時間、MTTR、變更失敗率 | Sprint 40 ✅ |
| US-14 | Notification Templates — PR/Deploy/Review 事件通知模板 | Sprint 40 外 ✅ |

### M4 結案評估（Sprint 41 正式收尾，2026-03-04）

**M4 Goal 達成結果**：ACHIEVED — 全部 4 個 M4 交付項目已完成（ADR-011、US-12、US-13、US-14）

**已完成 Stories 清單**：

| Story | 標題 | Sprint | 狀態 |
|-------|------|--------|------|
| ADR-011 | GitHub Actions 整合架構決策（Push-Based 事件觸發，Option A） | Sprint 39 | 完成 ✅ |
| US-12 | GitHub Actions 整合 — CI/CD 狀態感知與 Sprint Health Check 整合 | Sprint 39 | 完成 ✅ |
| US-13 | DORA Metrics — 部署頻率、變更前置時間、MTTR、變更失敗率追蹤 | Sprint 40 | 完成 ✅ |
| US-14 | Notification Templates — PR/Deploy/Review 事件通知模板 | Sprint 40 外（短衝） | 完成 ✅ |

**實際 Velocity（M4 交付階段，Sprint 39–40）**：

| Sprint | M4 貢獻 Stories | Points |
|--------|-----------------|--------|
| Sprint 39 | ADR-011（S, 1pt）+ US-12（M, 2pt） | 3 Points |
| Sprint 40 | US-13（L, 3pt）+ TD-002（M, 2pt）※ | 5 Points |
| Sprint 40 外 | US-14（S, 1pt，短衝執行） | 1 Point |
| **M4 合計** | 4 個 M4 交付項目（不含 TD-002） | **7 Points** |

> ※ TD-002 為 M4 期間順帶執行的技術債結案，非 M4 正式 Story。

**M4 Goal 達成結論**：M4「外部整合」里程碑的三大目標（CI/CD 狀態感知、DORA Metrics、通知機制）全部完成。框架已從「指引框架」進化為具備 GitHub Actions 整合能力的「執行框架」，並建立了 DORA 工程效能度量基準線（首次 baseline 於 Sprint 40 建立）。

---

## M5 穩定化 — 進行中（內部里程碑，Sprint 7+）

**主題**：準備正式發布，品質與文件達到公開標準

**目標**：外部使用者能順利安裝、使用、回報問題

| Story | 功能 | Sprint |
|---|---|---|
| shikigami:dispel | 解咒模式 — Legacy 系統考古分析 Skill | Sprint 7 ✅ |
| US-T05 | 交叉引用驗證腳本 | Sprint 7 ✅ |
| US-T07 | CI Pipeline — GitHub Actions 自動化驗證 | Sprint 7 ✅ |
| US-21 | 真實制衡案例文件 | Sprint 8 ✅ |
| US-18 | Sprint Execution Issue 回覆自動化 | Sprint 8 ✅ |
| US-20 | 輕量 Bypass 機制 | Sprint 8 ✅ |
| US-19 | Token 成本透明化 | Sprint 9 ✅ |
| US-T09 | 孤兒文件清理規範 + CI 整合 | Sprint 9 ✅ |
| ADR-004 | Retrospective Problem 主題比對機制 | Sprint 10 ✅ |
| US-23 | Token 成本分環節記錄 | Sprint 10 ✅ |
| US-22 | Retrospective 驅動角色權重自動調整 | Sprint 10 ✅ |
| US-25 | Scrum Master 零讀取架構 | Sprint 11 ✅ |
| US-S02 | Standup 健康快篩框架 Repo 誤判修正 | Sprint 11 ✅ |
| Retro #21 | Sprint Planning QA 精化 — AC 路徑驗證步驟 | Sprint 12 ✅ |
| Retro #22 | US-25 AC4 量測 — cache_read_input_tokens 降幅 59.7% | Sprint 12 ✅ |
| Issue #23 | health-check SKILL.md 零讀取架構對齊（Subagent 委派 + UNKNOWN fallback） | Sprint 12 ✅ |
| US-24 AC3/AC4 | Subagent Token 成本優化量測（Planning 降幅 89.9%，API call 123） | Sprint 12 ✅ |
| Retro #26 | PO Demo 讀取 repo 源碼（禁止依賴 plugin cache） | Sprint 13 ✅ |
| Retro #27 | Developer Board 更新範圍限制（防止越權標記 Sprint 完成） | Sprint 13 ✅ |
| Retro #25 | PO Sprint Planning 納入平行派工可行性考量 | Sprint 13 ✅ |
| Retro #24 | Architect Sprint Planning 包含平行派工策略 | Sprint 13 ✅ |
| Retro #29 | Issue 快掃觸發條件排除 retro-action label（sprint-execution SKILL.md） | Sprint 14 ✅ |
| Retro #30 | sprint-review SKILL.md 禁止項硬編碼版本號修正 | Sprint 14 ✅ |
| US-15 | 完整安裝流程驗證（全新環境測試） | Sprint 15 ✅ |
| US-16 | 使用者文件完善（Tutorial + Troubleshooting） | Sprint 15 ✅ |
| US-17 | 多平台調查（Cursor / OpenCode / Codex 可行性） | Sprint 16 ✅ |
| Issue #34 | sprint-execution SKILL.md doc-only 執行保護 | Sprint 16 ✅ |
| Issue #36 | sprint-review SKILL.md 覆蓋缺口修正 | Sprint 16 ✅ |
| US-28 | 快思/慢想雙模式 — Sprint Planning & Standup 精簡化 | Sprint 16 ✅ |
| Retro #41 | Token 記錄指引 cache tokens 修正 | Sprint 17 ✅ |
| US-29 | PROJECT_BOARD 與 Retrospective_Log 歷史歸檔機制 | Sprint 17 ✅ |
| ADR-005 | Schedule Skill 技術決策（cron + flock + allowedTools + OAuth + 回滾） | Sprint 18 ✅ |
| US-35 | Sprint 排程執行 + 權限 bypass 機制（shikigami:schedule） | Sprint 18 ✅ |
| Retro #53 | schedule skill — skill name 字元白名單驗證（注入防護） | Sprint 19 ✅ |
| Retro #54 | schedule skill — 模板品質強化（set -euo pipefail + 備份安全） | Sprint 19 ✅ |
| US-30 | PO subagent 多輪派遣 Story 內容偏離修正機制（drift 保護） | Sprint 19 ✅ |
| US-36 | Planning + Execution 序列排程 — 序列群組鎖避免平行衝突 | Sprint 19 ✅ |
| Retro #56 | test-schedule.sh assert_contains SIGPIPE 非確定性失敗修復 | Sprint 20 ✅ |
| Retro #57 | Developer subagent 狀態更新衝突防護 | Sprint 20 ✅ |
| US-31 | /shoot 短衝模式 — 單一任務快速執行（跳過 Sprint 儀式） | Sprint 20 ✅ |
| Retro #58 | L-size Story QA checklist 強化 — SKILL.md 新增大型 Story 審查增強項 | Sprint 21 ✅ |
| US-32 | parallel-dispatch 同檔案衝突偵測與自動序列化 | Sprint 21 ✅ |
| US-34 | Onboarding 預建常用 GitHub Labels | Sprint 21 ✅ |
| US-33 | Onboarding 補全 BACKLOG_DONE.md 模板（新用戶歸檔結構就緒） | Sprint 22 ✅ |
| ADR-006 | Prompt Injection Protection — sprint-execution Issue Quick-Scan 隔離機制 | Sprint 22 ✅ |
| US-37 | 防範 Issue 提示注入攻擊（結構化隔離標記 + ADR-006） | Sprint 22 ✅ |
| US-38 | 排程模式 Velocity 自動調小 — 僅選 S size Stories（HARD-GATE） | Sprint 22 ✅ |
| ADR-007 | Story-Lifecycle Subagent — context overflow 解決方案架構決策 | Sprint 22 ✅ |
| US-39 | Sprint Execution context overflow — Story 生命週期封裝為 subagent（ADR-007） | Sprint 22 ✅ |
| US-40 | Story-Lifecycle Subagent 實作 — ADR-007 Phase 1（story-lifecycle-prompt.md + SKILL.md §3） | Sprint 23 ✅ |
| Retro #59 | Cron template SHIKIGAMI_SCHEDULED 條件化 export 修正 | Sprint 23 ✅ |
| Retro #60 | TECH-DEBT Registry 補登 ADR-006 JSON Schema 技術債 (TD-002) | Sprint 23 ✅ |
| Retro #61 | Onboarding SKILL.md stale reference 審查與修正 | Sprint 23 ✅ |
| US-41 | ADR-007 Phase 2 — 外部抽樣審查機制實作（CONFIRM/DISPUTE + Circuit Breaker） | Sprint 24 ✅ |
| US-42 | Architect/QA 框架知識強化 — Story-Lifecycle 架構下角色決策指引 | Sprint 24 ✅ |
| US-43 | M5 完成條件終審 + Issues #3/#4/#5 結論決策 | Sprint 25 ✅ |
| US-44 | Tech Debt Grooming Sprint 25 + TD-001 降級決策 | Sprint 25 ✅ |
| US-45 | OpenCode POC 可行性調查（Go 決策，MVP 路徑定義） | Sprint 25 ✅ |
| US-46 | OpenCode 目錄適配與 SKILL.md 載入驗證（Phase 1） | Sprint 26 ✅ |
| US-47 | ADR-008: OpenCode 平台整合策略架構決策 | Sprint 27 ✅ |
| US-48 | OpenCode Phase 2 — Subagent 角色移植與派遣驗證 | Sprint 27 ✅ |
| US-49 | OpenCode Phase 3a — 剩餘四個角色 Agent 移植（五角色模型完成） | Sprint 28 ✅ |
| US-50 | OpenCode Phase 3b — INSTALL_OPENCODE.md 安裝指南（外部使用者就緒） | Sprint 28 ✅ |
| US-51 | OpenCode Phase 3c — Task Tool 參數分析與 Developer dispatch 驗證（Issue #3 接近可結案） | Sprint 28 ✅ |
| US-52 | OpenCode Phase 4 — Issue #3 正式結案：動態驗證補完（[STATIC-CONFIRMED]）與 Issue 關閉 | Sprint 29 ✅ |
| US-53 | M5 Beta 使用者招募 — README 招募文案 + Issue 引導機制（M5 條件 (a) 主動招募啟動） | Sprint 29 ✅ |
| US-54 | 互動 Session 自動偵測待審排程 PR + Scrum Master 提醒機制（Issue #46 子 Story #1） | Sprint 30 ✅ |
| US-55 | README 準確性修正 — 版本號、Skill 數量、版本歷史對齊 | Sprint 30 ✅ |
| US-56 | Deployment Readiness 版本 Tag 決策規則強化 + PO Override 機制（Issue #36） | Sprint 30 ✅ |
| US-57 | 排程衝刺 worktree 隔離執行框架（Issue #46 子 Story #2）— schedule + scrum-master SKILL.md | Sprint 31 ✅ |
| US-58 | M5 Beta 回饋閉環強化 — Issue #59 追蹤機制與 README 招募文案精化（M5 條件 (a) 推進） | Sprint 31 ✅ |
| US-59 | README 自動更新排程設定指引（Issue #52）— schedule SKILL.md 使用範例補完 | Sprint 31 ✅ |
| US-60 | Issue #46 子 Story #3 — 排程衝刺程式碼入庫 QA 自動化（schedule + scrum-master/sprint-review SKILL.md） | Sprint 32 ✅ |
| US-61 | M5 條件 (a) 外部使用者觸及強化 — Onboarding 低摩擦路徑最佳化（README + tutorial + M5 追蹤更新） | Sprint 32 ✅ |
| US-62 | Issue #35 — Token 追蹤 Baseline Snapshot 機制（Metrics_Log.md + sprint-planning/execution SKILL.md） | Sprint 32 ✅ |
| US-63 | Issue #46 子 Story #4 — 需求入庫自動化（PO Backlog Intake cron + shikigami:backlog-intake Skill） | Sprint 33 ✅ |
| US-64 | M5 條件 (a) 主動觸及強化 — 外部社群推廣文案製作（GitHub README badges + 技術文章草稿 + 主動 outreach 指引） | Sprint 33 ✅ |
| US-65 | US-T08（Intent Routing 測試）評估重開 — RICE 重新評分（2.0，No-Go，Deferred） | Sprint 33 ✅ |
| US-66 | Issue #46 最終收尾 — 四條排程流程驗收條件逐項確認、缺口補齊，Issue #46 CLOSED | Sprint 34 ✅ |
| US-68 | Issue #49 框架端主動修正評估 — workflow check 失敗根因分析、Issue #49 CLOSED | Sprint 34 ✅ |
| ADR-010 | Backlog Source of Truth 遷移至 GitHub Issues 架構決策 | Sprint 34 外 ✅ |
| US-69 | ADR-010 Label 基礎設施 — 14 個 labels 建立 + onboarding Pre-flight 更新 | Sprint 35 ✅ |
| US-70 | backlog-intake SKILL.md 重大改寫 — Issue label + body template 兩層架構 | Sprint 35 ✅ |
| US-71 | sprint-planning SKILL.md 修改 — PO Story 選取來源改為 gh issue list + 即時 RICE 排序 | Sprint 35 ✅ |
| US-72 | backlog-management SKILL.md 修改 — Grooming 流程改為操作 GitHub Issues + 錯誤恢復掃描 | Sprint 35 ✅ |
| US-73 | PRODUCT_BACKLOG.md DEPRECATED 標頭 + ADR-009「Superseded by ADR-010」標注 | Sprint 35 ✅ |
| US-74 | ADR-010 後置 — sprint-review SKILL.md Story 完成後 Issue 狀態回寫對齊 | Sprint 36 ✅ |
| US-75 | ADR-010 Backlog 初始化 — 將現有候選 Stories 建立為 GitHub Issues | Sprint 36 ✅ |
| US-76 | Tech Debt Grooming Sprint 36 — TD-002 評估 + ADR-010 遷移後新技術債掃描 | Sprint 36 ✅ |
| US-77 | 單層 Issue 架構改造 — backlog-intake / backlog-management 棄用兩層 Issue，改為 blockquote 保留原始內容 | Sprint 37 ✅ |
| US-78 | shoot skill US-XX 模式需適配 ADR-010 — 從 GitHub Issues 查詢 Story | Sprint 37 ✅ |
| US-80 | backlog-intake PO Review Gate — AI 自動入庫後新增 PO 審查階段與 label 語意修正 | Sprint 37 ✅ |
| US-11 | Decision Knowledge Base — ADR 查詢與決策影響追蹤（Decision_KB_Index.md + architecture-decision SKILL.md 查詢區段） | Sprint 38 ✅ |
| US-82 | PO 審查積壓量可視化 — backlog-management 新增待審 Issues 計數與老齡警示 | Sprint 38 ✅ |
| US-83 | ADR-011 正式裁決 — GitHub Actions 整合架構決策 Proposed → Accepted | Sprint 39 ✅ |
| US-12 | GitHub Actions 整合 — CI/CD 狀態感知與 Sprint Health Check 整合 | Sprint 39 ✅ |
| US-13 | DORA Metrics — 部署頻率、變更前置時間、MTTR、變更失敗率追蹤 | Sprint 40 ✅ |
| US-84 | M4 里程碑正式收尾 — ROADMAP US-14 完成標注 + M4 結案評估 | Sprint 41 ✅ |
| US-85 | TD-002 技術債結案 + Schema 文案修正 | Sprint 41 ✅ |
| US-86 | 交付物文案一致性審查機制 — 回應 Sprint 38-40 連續 Retro Problem | Sprint 41 ✅ |
| US-87 | GitHub Action 自動觸發 backlog-intake — Issue labeled 事件驅動入庫 | Sprint 41 ✅ |

**完成條件**：至少 1 位外部使用者完成安裝並走完一個 Sprint、Issue #3 **已結案（Sprint 29）**、Issues #4 #5 有明確結論

### 平台優先排序決策記錄（Sprint 25，2026-03-03）

基於 US-17 多平台調查結論（`docs/km/MULTI_PLATFORM_SURVEY.md`，Sprint 16），Sprint 25 M5 終審時作出以下正式決策：

| 平台 | 評分 | 決策 | 理由摘要 |
|------|------|------|----------|
| **OpenCode** | 4/5 | 第一優先，**Issue #3 已結案（Sprint 29）** | SKILL.md 格式高度相容，原生 Task tool 類似 Claude Code，bash/gh CLI 無阻礙；完整安裝指南已發布 |
| **Cursor** | 3/5 | 延後至 v2.5+ Task tool API 開放後（2026 Q2） | 程式化 Task tool API 尚未開放；Subagent 派遣不可程式化控制 |
| **Codex CLI** | 2/5 | 延後，等待 OpenAI 官方 GitHub integration | gh CLI 預設無法使用（網路沙箱封鎖），為根本性阻礙 |

> 決策依據：Issues #3/#4 各已在 Sprint 16 收到 US-17 調查結論評論；本決策記錄為 Sprint 25 M5 終審的正式補充。

---

## v1.0.0 正式版 — 遠期

**主題**：穩定、可信賴、可推薦給他人使用的 AI Scrum Team

**目標**：上架 Claude Code 官方 Marketplace

**前提**：M5 穩定化完成 + 外部使用者回饋正面 + Issue #5 達成

### v1.0.0 前提狀態（Sprint 25 更新，2026-03-03）

| 前提條件 | 狀態 | 說明 |
|----------|------|------|
| M5 穩定化完成 | 未達成 | M5 尚有 1 項未達成（見 `docs/prd/M5_COMPLETION_ASSESSMENT.md`） |
| 外部使用者回饋正面 | 未達成 | 尚無可驗證的外部使用者實際使用記錄（M5 完成條件 (a) 缺口） |
| Issue #5 達成（上架申請） | 延後 | 正式決策：等待 M5 全部完成條件達成後再評估上架時機（Sprint 25 M5 終審決定） |

**v1.0.0 時間線評估**：目前仍為遠期目標。最關鍵的阻礙是取得第 1 位外部使用者的實際使用回饋。M5 在技術與文件層面已高度成熟，建議在下一個 Sprint 中安排外部使用者招募行動（Beta 測試邀請），以解除最後一個前置條件。

**上架申請前置清單**（引自 Issue #5，Sprint 25 評估）：

| 條件 | 狀態 |
|------|------|
| 版本至少 v0.5.0 | 達成（目前 v0.8.0） |
| 安裝流程完整文件化 | 達成（US-15/16，Sprint 15） |
| 至少 1 位外部使用者驗證回饋 | 未達成 |
| README 中英文完整、無未驗證平台宣稱 | 待確認 |
| plugin.json 符合官方 schema | 待驗證 |

---

## 路線圖視覺摘要

```
v0.1.0 核心框架        v0.2.0 自我感知        v0.3.0 知識沉澱
Sprint 1              Sprint 2–3             Sprint 4–6            版號凍結 v0.3.x
──────────────────────┬──────────────────────┬─────────────────────┬──────────────────
Issue Mgmt            │ Onboard + Health     │ Retro Analytics     │
專案等級 + ADR-001    │ Check + Metrics      │ Tech Debt + ADR KB  │
──────────────────────┴──────────────────────┴─────────────────────┘
已交付 ✅              已交付 ✅               已交付 ✅

                        M5 穩定化（進行中）                          v1.0.0
                        Sprint 7+                                    TBD
                        ────────────────────────────────────────────┬─────
                        dispel + CI + 制衡案例 + Issue 回覆 +       │ 官方
                        Bypass + 安裝驗證 + 多平台 + 使用者文件     │ 上架
                        ────────────────────────────────────────────┴─────
                        v0.3.x patch bump                            v1.0.0
```
