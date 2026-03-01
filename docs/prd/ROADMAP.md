# 產品路線圖

> 最後更新：2026-03-01
> 擁有者：Product Owner

本文件是里程碑規劃的**唯一來源（Single Source of Truth）**。
各 Story 細節見 `docs/prd/PRODUCT_BACKLOG.md`，Sprint 執行見 `docs/sprints/`。

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

## v0.4.0 外部整合 — 規劃中

**主題**：與真實開發工具鏈整合，從「指引框架」進化為「執行框架」

**目標**：CI/CD 整合、DORA Metrics、通知機制

| Story | 功能 | Sprint |
|---|---|---|
| US-12 | GitHub Actions 整合 — CI/CD 狀態感知 | Sprint 5 |
| US-13 | DORA Metrics — 部署頻率、變更前置時間、MTTR、變更失敗率 | Sprint 5–6 |
| US-14 | Notification Templates — PR/Deploy/Review 事件通知模板 | Sprint 6 |

### US-12：GitHub Actions 整合

- Sprint Execution 時自動檢查 CI 狀態（`gh run list`）
- Quality Gate 納入 CI 結果作為通過條件
- 部署就緒檢查讀取最新 CI 結果
- 測試覆蓋率從 CI artifacts 取得（取代手動檢查）

### US-13：DORA Metrics

四大軟體交付效能指標：
- **Deployment Frequency**：多久部署一次（從 git tag 歷史計算）
- **Lead Time for Changes**：從 commit 到 deploy 的時間
- **MTTR**：服務中斷到恢復的時間
- **Change Failure Rate**：部署後需 hotfix/rollback 的比例

### US-14：Notification Templates

為不同事件提供結構化通知模板：
- Sprint 開始/結束摘要
- PR 建立/合併通知
- 部署完成通知
- Security Review 發現問題通知

**完成條件**：CI 狀態自動納入 Quality Gate、DORA Metrics 可計算並趨勢分析、通知模板覆蓋主要事件

---

## v0.5.0 穩定化 — 規劃中

**主題**：準備正式發布，品質與文件達到公開標準

**目標**：外部使用者能順利安裝、使用、回報問題

| Story | 功能 | Sprint |
|---|---|---|
| US-15 | 完整安裝流程驗證（全新環境測試） | Sprint 7 |
| US-16 | 使用者文件完善（Tutorial + Troubleshooting） | Sprint 7 |
| US-17 | 多平台調查（Cursor / OpenCode / Codex 可行性） | Sprint 7–8 |

**完成條件**：至少 1 位外部使用者完成安裝並走完一個 Sprint、Issues #3 #4 #5 有明確結論

---

## v1.0.0 正式版 — 遠期

**主題**：穩定、可信賴、可推薦給他人使用的 AI Scrum Team

**目標**：上架 Claude Code 官方 Marketplace

**前提**：v0.5.0 完成 + 外部使用者回饋正面 + Issue #5 達成

---

## 路線圖視覺摘要

```
v0.1.0 核心框架        v0.2.0 自我感知        v0.3.0 知識沉澱        v0.4.0 外部整合       v0.5.0 穩定化    v1.0.0
Sprint 1              Sprint 2–3  Sprint 4    Sprint 4   Sprint 5+   Sprint 6+  Sprint 7+  Sprint 8+        TBD
──────────────────────┬──────────┬───────────┬──────────┬───────────┬──────────┬──────────┬──────────────────┬─────
Issue Mgmt            │ Onboard  │ Metrics ✅│ Retro    │ Tech Debt │ CI/CD    │ DORA     │ 安裝驗證         │ 官方
專案等級              │ Health   │           │ Analytic✅│ ADR KB    │ 整合     │ Metrics  │ 多平台調查       │ 上架
ADR-001               │ Check    │           │          │           │          │ 通知     │ 使用者文件       │
──────────────────────┴──────────┴───────────┴──────────┴───────────┴──────────┴──────────┴──────────────────┴─────
已交付 ✅              已交付 ✅               已交付 ✅               規劃中                 規劃中            遠期
```
