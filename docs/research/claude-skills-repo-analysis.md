# 外部 Skills 資源分析報告：alirezarezvani/claude-skills × Shikigami 角色對照

**日期**：2026-03-13
**來源**：https://github.com/alirezarezvani/claude-skills（177+ skills）
**目的**：評估外部 skills 能否強化 Shikigami 現有 8 個角色的能力

---

## 1. 對照總覽

| Shikigami 角色 | 現有能力 | 外部可借鑑 Skills | 強化潛力 |
|---------------|---------|-----------------|---------|
| **PO** | Backlog 排序、Story 選取、Discovery Phase | Product Manager、Agile PO、UX Researcher、Discovery、Roadmap Communication | ★★★ 高 |
| **Architect** | ADR、技術評估、平行分群 | RAG Architect、Database Designer、Migration Architect、API Design Reviewer | ★★☆ 中 |
| **Developer** | TDD、Story-Lifecycle 閉環 | Database Designer、Migration Architect、Performance Profiler、Tech Debt Tracker、Monorepo Navigator、Agent Designer、Changelog Generator | ★★★ 高 |
| **QA** | AC 驗證、Spec/Code Quality Review | Playwright Pro（12 skills）、API Test Suite Builder、PR Review Expert | ★★★ 高 |
| **Security** | Security Review、OWASP 檢查 | Skill Security Auditor、Env Secrets Manager、SecOps | ★★☆ 中 |
| **SRE** | 部署、監控、Incident Response | Observability Designer、Performance Profiler、Incident Commander、Runbook Generator | ★★★ 高 |
| **UI/UX Designer** | Figma Prototype、Vision Critic | UI Design、UX Researcher、Landing Page | ★★☆ 中 |
| **Stakeholder** | 商業期待確認、校準儀式 | C-Level Advisory（28 skills）、Customer Success | ★☆☆ 低 |

---

## 2. 角色逐一分析

### 2.1 QA Engineer（強化潛力：★★★）

**現有痛點**（Issue #247 指出）：
- 只做規格驗收，缺少使用者視角
- 沒有探索性測試
- Mock 過度，缺少真實資料驗證

**可借鑑 Skills：**

| 外部 Skill | 能力 | 對應強化方向 |
|-----------|------|------------|
| **Playwright Pro** | E2E 測試生成、flaky fix、55 測試模板 | 探索性測試自動化、邊界案例生成 |
| **API Test Suite Builder** | 掃描 API routes 自動生成測試套件 | Smoke Test 自動化（#251 需求） |
| **PR Review Expert** | Blast radius 分析、coverage delta | Code Review 深度提升 |
| **Performance Profiler** | Load testing、bundle analysis | 非功能性驗收（效能面） |

**建議**：QA 角色最需要升級。Playwright Pro 的測試模板思維可引入「探索性測試 checklist」；API Test Suite Builder 的「掃描後自動生成」模式可作為 Smoke Test 要求的實作參考。

---

### 2.2 PO / Product Owner（強化潛力：★★★）

**現有痛點**：
- AC 只寫功能性需求，漏掉非功能屬性（freshness、completeness）
- Discovery Phase 產出偏技術面，不夠全面

**可借鑑 Skills：**

| 外部 Skill | 能力 | 對應強化方向 |
|-----------|------|------------|
| **UX Researcher** | 使用者研究、痛點分析 | Discovery Phase Step 1 背景分析深度 |
| **Product Manager** | 需求拆解、優先級框架 | Backlog Grooming RICE 評分強化 |
| **Discovery** | 產品探索流程 | Discovery Phase 流程對照 |
| **Experiment Design** | A/B 測試設計、假設驗證 | Discovery Phase Step 2 假設外顯化的驗證方法 |
| **Roadmap Communication** | 里程碑溝通 | Stakeholder 對齊 |

**建議**：UX Researcher 的使用者研究框架可整合進 Discovery Phase，強化「使用者隱性期待」的捕捉能力。

---

### 2.3 SRE Engineer（強化潛力：★★★）

**現有痛點**：
- 部署與監控流程已建立，但 Incident Response 和可觀測性仍有提升空間

**可借鑑 Skills：**

| 外部 Skill | 能力 | 對應強化方向 |
|-----------|------|------------|
| **Observability Designer** | 監控三件套設計（Metrics / Logs / Traces） | #222 SRE 完整化需求 |
| **Incident Commander** | Incident Response 流程自動化 | Post-mortem 流程強化 |
| **Runbook Generator** | 運維手冊自動生成 | 部署 runbook 標準化 |
| **Performance Profiler** | Node/Python/Go profiling、load testing | 效能基準管理（#224） |
| **CI/CD Pipeline Builder** | Pipeline 設計與最佳化 | CI Gate 強化 |

**建議**：Observability Designer + Incident Commander 的組合可直接對應 #222（SRE 完整化）的需求，值得在該 Story 實作時參考。

---

### 2.4 Architect（強化潛力：★★☆）

**可借鑑 Skills：**

| 外部 Skill | 能力 | 對應強化方向 |
|-----------|------|------------|
| **RAG Architect** | RAG 系統設計 | Knowledge Ingestion 架構優化 |
| **Database Designer/Schema Designer** | 資料庫設計、Schema 演進 | 消費端專案技術評估 |
| **Migration Architect** | 遷移策略規劃 | Legacy 系統遷移（/dispel skill 強化） |
| **API Design Reviewer** | API 設計審查 | 消費端 API 整合品質 |

**建議**：現有 Architect 角色已相當完整。RAG Architect 可在 Knowledge Ingestion（ADR-017）演進時參考。

---

### 2.5 Security Engineer（強化潛力：★★☆）

**可借鑑 Skills：**

| 外部 Skill | 能力 | 對應強化方向 |
|-----------|------|------------|
| **Skill Security Auditor** | Skills 安全審計 | 框架自身 skill 的安全檢查 |
| **Env Secrets Manager** | 環境變數與密鑰管理 | ADR-006 延伸 |
| **Dependency Auditor** | 依賴掃描、License compliance | Supply chain 安全 |

**建議**：Dependency Auditor 的 license compliance 檢查是目前框架缺少的面向，可作為 Security Review 的補充項目。

---

### 2.6 UI/UX Designer（強化潛力：★★☆）

**可借鑑 Skills：**

| 外部 Skill | 能力 | 對應強化方向 |
|-----------|------|------------|
| **UX Researcher** | 使用者研究方法論 | DESIGN Story 的使用者驗證 |
| **UI Design** | Design System 管理 | Design Token 體系強化 |
| **Landing Page** | 高品質頁面快速生成 | 前端 Story 效率 |

**建議**：UX Researcher 的能力可強化 DESIGN Story 的「使用者驗證」環節，補充 Vision Critic 的視覺維度之外的使用者體驗維度。

---

### 2.7 Developer（強化潛力：★★★）

Developer 是最核心的執行角色，POWERFUL tier 有多個 skills 可直接強化開發品質與效率。

**現有痛點**：
- Story 涉及資料庫時缺少結構化設計指引
- 效能敏感 Story 缺少 profiling 手段
- 技術債追蹤仍為手動
- 消費端大型 codebase 導航效率待提升

**可借鑑 Skills：**

| 外部 Skill | 能力 | 對應強化方向 |
|-----------|------|------------|
| **Database Designer / Schema Designer** | DB 設計、Schema 演進策略 | Story 涉及資料庫時的設計品質，避免 Schema 設計缺陷進入 Sprint |
| **Migration Architect** | 資料庫/架構遷移策略規劃 | 遷移類 Story 的實作品質與風險控制 |
| **Performance Profiler** | Node/Python/Go profiling、bundle analysis、load testing | 效能敏感 Story 的 TDD 補充（效能測試） |
| **Tech Debt Tracker** | 技術債自動識別、分類、優先排序 | Tech_Debt_Registry.md 的自動化維護，從手動標記升級為主動偵測 |
| **Monorepo Navigator** | 大型 codebase 快速定位與理解 | 消費端大型專案的開發效率提升 |
| **Codebase Onboarding** | 新專案快速上手流程 | /dispel（Legacy 考古）skill 的強化 |
| **Agent Designer / Workflow Designer** | Agent 設計模式與工作流最佳化 | Subagent 自身的架構品質提升 |
| **Changelog Generator** | 自動生成結構化 changelog | deployment-readiness 版本發布流程強化 |

**建議**：Database Designer 和 Migration Architect 可整合進 Architect 技術評估階段的 Developer 諮詢環節（§10 Refinement），讓 Developer 在 Story 開始前就有結構化的 DB 設計指引。Performance Profiler 的 profiling 思維可作為非功能性 AC 的實作參考。Tech Debt Tracker 的自動偵測模式可升級現有手動 `[TECH-DEBT]` 標記流程。

---

### 2.8 Stakeholder（強化潛力：★☆☆）

| 外部 Skill | 能力 | 備注 |
|-----------|------|------|
| **C-Level Advisory** | 28 個 C-suite 角色 | 過於泛化，不適合直接引入 |
| **Customer Success** | 客戶成功運營 | 可參考用於校準儀式的深度 |

---

## 3. 優先建議：Sprint 93 可立即借鑑的項目

| 優先級 | Shikigami 角色 | 借鑑來源 | 落地方式 |
|--------|---------------|---------|---------|
| **P0** | QA | Playwright Pro 測試模板思維 | US-254 探索性測試設計時參考邊界案例生成模式 |
| **P0** | QA | API Test Suite Builder 掃描→生成模式 | US-253 Smoke Test 機制設計時參考 |
| **P1** | PO | UX Researcher 使用者研究框架 | US-250 QA 角色升級時，引入使用者視角 checklist |
| **P1** | SRE | Observability Designer + Incident Commander | 未來 #222 SRE 完整化 Story 實作參考 |
| **P2** | Security | Dependency Auditor license compliance | Security Review 補充項目 |
| **P1** | Developer | Database Designer + Migration Architect | Refinement 階段 DB 設計指引 |
| **P1** | Developer | Tech Debt Tracker 自動偵測模式 | Tech_Debt_Registry.md 自動化 |
| **P2** | Developer | Performance Profiler | 效能敏感 Story 的非功能性測試 |
| **P2** | Architect | RAG Architect | Knowledge Ingestion 演進參考 |

---

## 4. 不建議引入的項目

| 外部 Skill 類別 | 原因 |
|----------------|------|
| Marketing（43 skills） | 與 Shikigami 框架定位無關 |
| Finance（2 skills） | 超出 Scrum Team 職責範圍 |
| Regulatory/QM（12 skills） | 過於特定產業（醫療器材），不通用 |
| C-Level Advisory（28 skills） | 過於泛化，Stakeholder 角色已有明確定位 |
| Self-Improving Agent | 功能與 Claude Code 內建 memory 系統重疊 |

---

## 5. 結論

177+ skills 中，約 **33 個**（19%）與 Shikigami 現有角色有直接強化關係。最大受益者是 **Developer**（8 個 skills 可借鑑）、**QA**（4 個）、**SRE**（5 個）和 **PO**（5 個）。

Sprint 93 正在做的 #247 品質強化全家桶，可以在實作 US-250（QA 升級）、US-253（Smoke Test）、US-254（探索性測試）時，參考 Playwright Pro 和 API Test Suite Builder 的設計模式，不需要直接安裝這些 skills，而是將其思維融入框架自有角色的 prompt 中。
