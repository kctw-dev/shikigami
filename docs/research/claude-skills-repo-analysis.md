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
| **Developer** | TDD、Story-Lifecycle 閉環 | Fullstack、Codebase Onboarding、Git Worktree Manager | ★☆☆ 低 |
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

### 2.7 Developer（強化潛力：★☆☆）

現有 Developer 角色已有完整的 TDD 閉環 + Story-Lifecycle subagent 封裝，外部 skills 能補充的有限。

| 外部 Skill | 能力 | 備注 |
|-----------|------|------|
| **Codebase Onboarding** | 新專案快速上手 | 可參考用於 /dispel skill |
| **Git Worktree Manager** | Worktree 管理 | Claude Code 已內建 |
| **Tech Debt Tracker** | 技術債追蹤 | 已有 Tech_Debt_Registry.md |

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

177+ skills 中，約 **25 個**（14%）與 Shikigami 現有角色有直接強化關係。最大受益者是 **QA**（4 個 skills 可借鑑）、**SRE**（5 個）和 **PO**（5 個）。

Sprint 93 正在做的 #247 品質強化全家桶，可以在實作 US-250（QA 升級）、US-253（Smoke Test）、US-254（探索性測試）時，參考 Playwright Pro 和 API Test Suite Builder 的設計模式，不需要直接安裝這些 skills，而是將其思維融入框架自有角色的 prompt 中。
