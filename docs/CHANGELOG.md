# Changelog — Shikigami 版本歷程

完整的版本演進紀錄，由 Shikigami 自治開發流程自動生成與維護。

---

## 版本歷程

| 版本 | 主題 | Sprint | 交付內容 |
|------|------|--------|----------|
| v0.1–0.9 | 核心建立與穩定化 | 1–24 | 25 Skills + 8 Agents 基礎架構、CI Pipeline、Hard Gate 機制、dispel 解咒模式、schedule/shoot 自動化、parallel-dispatch、使用者文件 |
| v0.13–0.29 | 多平台 + 自動化閉環 | 25–50 | OpenCode 平台整合、排程四條流程、版號同步腳本、環境可攜性方案、diagram Skill（drawio MCP 整合） |
| v0.30–0.41 | Design 體系 + 方法論強化 | 51–73 | UIUX Agent + Figma 整合管線 + Vision Critic、QA 雙階段審查強化、模型分層策略、Gemini CLI / Cursor 平台整合 |
| v0.45–0.50 | 流程可靠性與品質閉環 | 74–84 | Story-Lifecycle Subagent 架構、Anti-Hallucination 雙軌閉環、Discovery Phase 草稿（ADR-018）、SPACE 五維度指標、知識品質閉環 |
| v0.59–0.61 | Discovery + SRE + 部署品質 | 85–87 | Discovery Phase Skill 落地、Discovery Ecosystem 閉環、SRE 事故回應框架、效能基準管理、Solo Mode |
| v0.64–0.66 | MCP 基礎建設 + Context 瘦身 | 88–92 | 流程管理 MCP Server Phase 1、TDD 需求理解度升級、SKILL.md 瘦身（~75% context 降低）、Subagent 結果快取 |
| v0.68.0 | 品質深化 | 93–94 | QA 角色升級（→使用者代言人）、資料品質關卡、Smoke Test、探索性測試、低記憶體環境平行限制、版號測試技術債修復 |

---

## 累積數據（截至 Sprint 94）

- 94 個 Sprint 完成率 ~99%
- 19 個 ADR（架構決策紀錄）
- 13 個自動化驗證腳本 + GitHub Actions CI Pipeline
- 25 個 Skills / 8 Agents

---

## 開發流程實證

| 流程 | 角色協作 |
|------|----------|
| **Product Discovery** | PO 分析需求 → Architect 評估可行性 → QA 確認驗收標準 |
| **Sprint Execution** | Developer 依 TDD 實作 → QA 雙階段審查（Spec Compliance + Code Quality） |
| **Architecture Decision** | Architect 提案 → QA 扮演 Decision Challenger 挑戰 → ADR 記錄決策 |
| **Sprint Review** | 自動觸發驗收 → Retrospective Analytics 展示趨勢 → Action Items 轉為 GitHub Issues |
| **Hard Gate** | 框架文件修改前 Preflight Check、儀式完整性稽核、Sprint 外變更偵測 |

---

## 產出文件

| 文件 | 說明 |
|------|------|
| `docs/adr/` | 架構決策紀錄（ADR-001 ~ ADR-019） |
| `docs/sprints/` | Sprint 規劃與執行紀錄 |
| `docs/km/Retrospective_Log.md` | 每次犯的錯都記下來，不重複犯 |
| `docs/km/Metrics_Log.md` | Velocity 趨勢與完成率追蹤 |
| `docs/km/ROLE_BALANCE_CASES.md` | 真實制衡案例記錄 |
| `docs/prd/PRODUCT_BACKLOG.md` | Backlog 歷史快照（source of truth 已遷移至 GitHub Issues） |
