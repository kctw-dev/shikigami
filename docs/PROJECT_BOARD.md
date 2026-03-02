# Project Board

**最後更新**：2026-03-02（Sprint 17 Planning 完成）
**當前 Sprint**：Sprint 17（進行中）

工件導覽：[ROADMAP](prd/ROADMAP.md) → [Backlog](prd/PRODUCT_BACKLOG.md) → [Sprint 17](sprints/sprint_17.md) → 本看板 | [Tutorial](tutorial/README.md)

---

## Sprint 17 — 進行中

**Sprint Goal**：檔案瘦身優先 — 建立 PROJECT_BOARD 與 Retrospective_Log 歷史歸檔機制（US-29），清零 Sprint 16 Retro Action Items（Retro #41 Token 記錄指引 cache tokens 修正、Retro #42 OpenCode POC 佔位候選入 Backlog），確保效能可觀測性與知識管理基礎就緒。
**期間**：2026-03-02 ~ 2026-03-08

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| Retro #41：Token 記錄指引更新 — 三個 SKILL.md 納入 cache tokens 加總計算 | S | 1 | 待開發 |
| Retro #42：OpenCode POC 可行性調查佔位入 Backlog | S | 1 | 待開發 |
| US-29（Issue #44）：PROJECT_BOARD.md 與 Retrospective_Log.md 歷史歸檔機制 | M | 2 | 待開發 |

---

## Sprint 16 — 完成

**Sprint Goal**：清零 Sprint 15 Retro Action Items，完成 US-17 多平台可行性調查，修正文件類 SKILL.md 越權執行風險（Issue #34），更新 sprint-review SKILL.md 覆蓋缺口（Issue #36），導入快思/慢想雙模式精簡化（Issue #39），鞏固 M5 穩定化最後一哩路。
**結果**：Goal 達成（6/6 Stories PASS）。Velocity 8 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-03-02 ~ 2026-03-08

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| Retro #37：GETTING_STARTED.md 補上 ToC 目錄 | S | 1 | 完成 |
| US-17：多平台調查（Cursor / OpenCode / Codex 可行性） | M | 2 | 完成 |
| Issue #34：sprint-execution SKILL.md 跳過 doc-only Story 執行保護 | S | 1 | 完成 |
| Issue #36：sprint-review SKILL.md 覆蓋缺口修正 | S | 1 | 完成 |
| Retro #38：Token JSONL 提取機制調查與 SKILL.md 主要方法更新 | S | 1 | 完成 |
| US-28：快思/慢想雙模式 — Sprint Planning & Standup 精簡化 | M | 2 | 完成 |

**實際 Velocity**：8 points（6 Stories）

---

## Sprint 15 — 完成

**Sprint Goal**：完成 M5 穩定化的使用者就緒工作 — 建立可重複的全新環境安裝驗證報告，並交付端對端使用者文件（Tutorial + Troubleshooting），讓外部使用者能獨立完成安裝並走完第一個 Sprint。
**結果**：Goal 達成（2/2 Stories PASS）。Velocity 4 points，完成率 100%。
**Stakeholder 驗收**：接受

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-15：完整安裝流程驗證（全新環境測試） | M | 2 | 完成 |
| US-16：使用者文件完善（Tutorial + Troubleshooting） | M | 2 | 完成 |

**實際 Velocity**：4 points（2 Stories）

---

## Sprint 14 — 完成

**Sprint Goal**：清零 Sprint 13 Retro Action Items，收窄 Retro #29 修改範圍至 sprint-execution SKILL.md，完成 sprint-review 硬編碼版本號修正，確保框架指引文件在 M5 穩定化階段維持長期可維護性。
**結果**：Goal 達成（2/2 Stories PASS）。Velocity 2 points，完成率 100%。
**Stakeholder 驗收**：接受

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| Retro #29：Issue 快掃觸發條件排除 retro-action label（收窄至 sprint-execution SKILL.md） | S | 1 | 完成 |
| Retro #30：sprint-review SKILL.md 禁止項硬編碼版本號修正 | S | 1 | 完成 |

**實際 Velocity**：2 points（2 Stories）

---

## Sprint 13 — 完成

**Sprint Goal**：清零 Sprint 12 Retro 流程缺口，建立 Sprint Planning 平行派工正式規範，為 M5 外部發布排除最後的流程控制風險
**結果**：Goal 達成（4/4 Stories PASS）。Velocity 4 points，完成率 100%。
**Stakeholder 驗收**：接受

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| Retro #26：PO Demo 應讀取 repo 源碼而非 plugin cache | S | 1 | 完成 |
| Retro #27：Developer Board 更新範圍限制 — 防止越權標記 Sprint 完成 | S | 1 | 完成 |
| Retro #25：PO Sprint Planning Story 選取應納入平行派工可行性考量 | S | 1 | 完成 |
| Retro #24：Architect Sprint Planning 評估應包含平行派工策略 | S | 1 | 完成 |

**實際 Velocity**：4 points（4 Stories）

---

## Sprint 12 — 完成

**Sprint Goal**：修正 health-check 架構對齊、完成 US-25 AC4 零讀取效果量測、強化 QA 路徑驗證，讓 M5 穩定化的架構完整性與流程品質收斂
**結果**：Goal 達成（4/4 Stories PASS）。Velocity 4 points，完成率 100%。
**Stakeholder 驗收**：接受

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| Retro #21：Sprint Planning QA 精化 — AC 路徑驗證步驟 | S | 1 | 完成 |
| Retro #22：US-25 AC4 量測 — cache_read_input_tokens < 41.6M | S | 1 | 完成 |
| Issue #23：health-check SKILL.md 零讀取架構對齊 | S | 1 | 完成 |
| US-24 AC3/AC4：Subagent Token 成本優化量測 | S | 1 | 完成 |

**實際 Velocity**：4 points（4 Stories）

---

## Sprint 11 — 完成

**Sprint Goal**：導入 Scrum Master 零讀取架構，讓主 session context 瘦身，同步清零 Sprint 10 Retro Action Item，為 Token 成本大幅下降奠定結構基礎
**結果**：Goal 達成（3/3 Stories PASS）。Velocity 4 points，完成率 100%。
**Stakeholder 驗收**：接受

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| Retro #20：SKILL.md token 記錄指引更新為 JSONL 提取 | S | 1 | 完成 |
| US-S02：Standup 健康快篩框架 Repo 誤判修正 | S | 1 | 完成 |
| US-25：Scrum Master 零讀取架構 | M | 2 | 完成 |

**實際 Velocity**：4 points（3 Stories）

---

## Sprint 10 — 完成

**Sprint Goal**：填入 Token 真實數據並細化至分環節記錄，引入 Retrospective 驅動的角色權重自動調整，讓框架的成本可觀測性與自我演進能力同步提升
**結果**：Goal 達成（3/3 Stories PASS）。Velocity 6 points，完成率 100%。
**Stakeholder 驗收**：接受

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| Retro #19：領域專家審查機制設計 [BYPASS] | S | 1 | 完成 |
| US-23：Token 成本分環節記錄 | M | 2 | 完成 |
| US-22：Retrospective 驅動角色權重自動調整 | L | 3 | 完成 |

**實際 Velocity**：6 points（3 Stories）

---

## Sprint 9 — 完成

**Sprint Goal**：建立 Token 成本透明化機制，強化 Sprint 流程檔案即時持久化，並建立孤兒文件自動偵測能力
**結果**：Goal 達成（3/3 Stories PASS）。Velocity 5 points，完成率 100%。
**Stakeholder 驗收**：接受

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| Retro #16：Sprint 文件即時 commit + push | S | 1 | 完成 |
| US-19：Token 成本透明化 | M | 2 | 完成 |
| US-T09：孤兒文件清理規範 | M | 2 | 完成 |

**實際 Velocity**：5 points（3 Stories）

---

## Sprint 8 — 完成

**Sprint Goal**：修復 Sprint Execution Issue 回覆缺口，恢復 QA 雙階段審查，建立制衡案例文件庫，引入輕量 Bypass 機制
**結果**：Goal 達成（4/4 Stories PASS）。Velocity 6 points，完成率 100%。
**Stakeholder 驗收**：接受

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| Retro #14：恢復 QA 雙階段審查 | S | 1 | 完成 |
| US-21：真實制衡案例文件 | S | 1 | 完成 |
| US-18：Sprint Execution Issue 回覆自動化 | M | 2 | 完成 |
| US-20：輕量 Bypass 機制 | M | 2 | 完成 |

**實際 Velocity**：6 points（4 Stories）

---

## Sprint 7 — 完成

**Sprint Goal**：啟動 v0.5.0 穩定化，清零 Sprint 6 Retro 技術債，建立解咒模式（Legacy 系統考古 Skill），並完成測試框架 CI 整合
**結果**：Goal 達成（5/5 Stories PASS）。Velocity 7 points，完成率 100%。
**Stakeholder 驗收**：接受

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| Retro #10：sprint_N.md 狀態回寫機制 | S | 1 | 完成 |
| Retro #11：PLUGIN_DEV_NOTES.md 歸入 KM | S | 1 | 完成 |
| shikigami:dispel 解咒模式 | M | 2 | 完成 |
| US-T05：交叉引用驗證 | S | 1 | 完成 |
| US-T07：CI Pipeline | M | 2 | 完成 |

**實際 Velocity**：7 points（5 Stories）

---

## Sprint 6 — 完成

**Sprint Goal**：建立 Hard Gate Checklist 機制（US-FIX-02），擴展測試框架覆蓋（US-T02、US-T03），並清零 Sprint 5 Retro 技術債
**結果**：Goal 達成（5/5 Stories PASS）。Velocity 8 points，完成率 100%。
**Stakeholder 驗收**：接受，v0.3.0 里程碑結案

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| Retro #7：DoD 第 8 層同步 | S | 1 | 完成 |
| Retro #8：QA Review 範圍界定 | S | 1 | 完成 |
| US-T02：Agent 完整性驗證 | S | 1 | 完成 |
| US-T03：JSON Schema 驗證 | M | 2 | 完成 |
| US-FIX-02：Hard Gate Checklist 機制 | L | 3 | 完成 |

**實際 Velocity**：8 points（5 Stories）

---

## Sprint 5 — 完成

**Sprint Goal**：完成 v0.3.0 Tech Debt Registry，並同步建立 ADR-002 解鎖測試框架擴展路徑，並修復 16 項框架監控缺口
**結果**：Goal 達成（4/4 Stories PASS）。Velocity 6 points，完成率 100%。
**Stakeholder 驗收**：接受

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| ADR-002：測試框架技術選型 | S | 1 | 完成 |
| US-10：Tech Debt Registry | M | 2 | 完成 |
| US-T01：Skill 完整性驗證 | S | 1 | 完成 |
| US-FIX-01：修復審計發現 | M | 2 | 完成 |

**實際 Velocity**：6 points（4 Stories）

---

## Sprint 4 — 完成

**Sprint Goal**：啟動 v0.3.0 知識沉澱，以 US-08 Sprint Metrics 完成 v0.2.0 收尾，並建立 Retrospective Analytics 的第一層能力
**結果**：Goal 達成（3/3 Stories PASS）。Velocity 4 points，完成率 100%。
**Stakeholder 驗收**：接受

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-08：Sprint Metrics（Velocity 追蹤與趨勢分析） | S | 1 | 完成 |
| US-09：Retrospective Analytics（問題趨勢分析） | M | 2 | 完成 |
| US-T06：Command 路由驗證 | S | 1 | 完成 |

**實際 Velocity**：4 points（3 Stories）

---

## Sprint 3 — 完成

**Sprint Goal**：完成 v0.2.0 自我感知，並修復跨兩個 Sprint 的行為性缺陷
**結果**：Goal 達成（4/4 Stories PASS）。Velocity 5 points，完成率 100%。
**Stakeholder 驗收**：接受，v0.2.0 Release 批准

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| Story 1（Retro #3）：Sprint Review 自動觸發重修 | S | 1 | 完成 |
| US-06：Onboarding（專案初始化） | M | 2 | 完成 |
| Story 3（Retro #2）：Health Check 自動掛鉤 | S | 1 | 完成 |
| US-T04：版號一致性驗證 | S | 1 | 完成 |

**實際 Velocity**：5 points（4 Stories）

---

## Sprint 2 — 完成

**Sprint Goal**：讓框架能感知自己的狀態

| Story | Size | 狀態 |
|-------|------|------|
| US-07：Health Check Skill | M | 完成 |
| US-S01：Standup 遠端差距感知 | S | 完成 |
| Retro #2：不阻塞原則強化 | S | 完成 |
| Retro #3：Plan Mode 互斥說明 | S | 完成 |

---

## 歷史交付

### Sprint 1（v0.1.0 核心框架）
- [x] Story 5：專案等級自治策略
- [x] Story 1：Issue Lifecycle Management
- [x] ADR-001：Backlog Bridge 編排模式
- [x] Story 2：Backlog Bridge 完整版
- [x] Story 3：Issue Comment 強化
- [x] Story 4：Issue Triage 強化 + triage-prompt.md
