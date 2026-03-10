# Changelog — Shikigami 版本歷程

完整的版本演進紀錄，由 Shikigami 自治開發流程自動生成與維護。

---

## 版本歷程

| 版本 | 主題 | Sprint | 交付內容 |
|------|------|--------|----------|
| v0.1.0 | 核心框架 | Sprint 1 | 16 Skills + 7 Agents + 3 Commands + Issue Management |
| v0.2.0 | 自我感知 | Sprint 2–4 | Onboarding + Health Check + Sprint Metrics |
| v0.3.0 | 知識沉澱 | Sprint 4–6 | Retrospective Analytics + Tech Debt Registry + 5 驗證腳本 + Hard Gate 機制 |
| v0.3.x | 穩定化 | Sprint 7–15 | dispel 解咒模式 + CI Pipeline + 制衡案例 + Issue 回覆自動化 + Bypass 機制 + Token 成本透明化 + 孤兒文件偵測 + 零讀取架構 + 角色權重自動調整 + 使用者文件（Tutorial + Troubleshooting） |
| v0.5.x | 流程精煉 | Sprint 16–17 | 快思/慢想雙模式精簡化 + doc-only Story 執行保護 + 多平台可行性調查 + 歷史歸檔機制（PROJECT_BOARD + Retrospective_Log） |
| v0.7.x | 自動化擴展 | Sprint 18–20 | schedule Skill（Sprint 自動排程執行）+ ADR-005 + shoot 短衝模式 + /shoot Command + 序列排程保護 + PO drift 修正 |
| v0.9.x | 品質強化 | Sprint 21–24 | parallel-dispatch 同檔案衝突偵測 + Onboarding Labels + 提示注入防護（ADR-006）+ ADR-007 Story-Lifecycle Subagent + 外部抽樣審查機制 + Architect/QA 知識框架 Skill |
| v0.13.0 | 多平台支援 | Sprint 25–29 | M5 完成條件終審 + OpenCode 平台整合（ADR-008）+ symlink 適配策略 + 五角色 Agent 移植 + INSTALL_OPENCODE.md 安裝指南 + Issue #3 正式結案 + Beta 使用者招募 |
| v0.17.0 | 自動化閉環 | Sprint 30–33 | Issue #46 排程四條流程完成 + backlog-intake Skill + ADR-009 + M5 推廣行動 + Token Baseline Snapshot |
| v0.29.0 | 多環境穩定化 + diagram 技能 | Sprint 34–50 | 多 GCE 認證指引（ADR-012）+ CI/CD workflow 拆分指引 + 版號三檔同步腳本 + 環境可攜性方案（Dotfiles Repo）+ ADR-013 diagram MCP 架構決策 + shikigami:diagram Skill（drawio-mcp-server stdio 整合）|
| v0.29.1 | UIUX Agent 基礎建設 | Sprint 51–52 | ADR-014 UIUX Agent 架構決策 + Design Tokens 機器可讀規格（design-tokens.json）+ 前端 SDD 模板標準化 + issue-management 前端 Story AC 自動注入機制 |
| v0.30.0 | Figma 整合管線 | Sprint 53–56 | ADR-015 Figma 整合架構決策 + UX/UI/Vision Critic 三層 Skill 定義 + Figma MCP Server 連線設定 + Component Library 規格 + Design Tokens Versioning + Figma 管線使用指南 + Vision Critic PoC 規格 + 設計師協作指南 |
| v0.34.0 | 輕量化與品質強化 | Sprint 57–60 | Vision Critic 同步 ADR-015 Figma 架構 + Sprint Review 流程精簡化 + 模型分層策略調查與 Phase 1/2 落地（subagent 自動模型指定）+ Plugin 載入 TROUBLESHOOTING 文件化 + Metrics 計算視窗限制（30 Sprint）+ 方法論適用性自動評估（BDD/DDD 建議） |
| v0.41.0 | 方法論強化 | Sprint 61–73 | QA Spec/Code 雙階段審查強化 + Scrum Master 自動排程精煉 + 多平台穩定化 + Gemini CLI / Cursor 平台整合 |
| v0.45.0 | 使用者體驗強化 | Sprint 74 | README 資訊架構重設計 + API 契約 Hard Gate + E2E 測試基礎設施 |

---

## 累積數據（截至 Sprint 73）

- 73 個 Sprint 中完成 72 個以上（完成率 ~98%）
- 15 個 ADR（架構決策紀錄）
- 8 個自動化驗證腳本 + GitHub Actions CI Pipeline
- 25 個 Skills / 7 Agents / 4 Commands

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
| `docs/adr/` | 架構決策紀錄（ADR-001 ~ ADR-015） |
| `docs/sprints/` | Sprint 規劃與執行紀錄 |
| `docs/km/Retrospective_Log.md` | 每次犯的錯都記下來，不重複犯 |
| `docs/km/Metrics_Log.md` | Velocity 趨勢與完成率追蹤 |
| `docs/km/ROLE_BALANCE_CASES.md` | 真實制衡案例記錄 |
| `docs/prd/PRODUCT_BACKLOG.md` | Backlog 歷史快照（source of truth 已遷移至 GitHub Issues） |
