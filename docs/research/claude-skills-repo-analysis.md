# 外部 Skills 資源分析報告：alirezarezvani/claude-skills × Shikigami 角色對照

**日期**：2026-03-13
**來源**：https://github.com/alirezarezvani/claude-skills（177+ skills）
**目的**：評估外部 skills 能否強化 Shikigami 現有 8 個角色的能力

---

## 1. 對照總覽

| Shikigami 角色 | 現有能力 | 外部可借鑑 Skills | 強化潛力 |
|---------------|---------|-----------------|---------|
| **PO** | Backlog 排序、Story 選取、Discovery Phase | Product Manager、Agile PO、UX Researcher、Discovery、Experiment Design、Roadmap Communication、Analytics | ★★★ |
| **Architect** | ADR、技術評估、平行分群 | RAG Architect、Database Designer、Migration Architect、API Design Reviewer、Agent Designer、Agent Workflow Designer、MCP Server Builder | ★★★ |
| **Developer** | TDD、Story-Lifecycle 閉環 | Database Designer、Migration Architect、Performance Profiler、Tech Debt Tracker、Monorepo Navigator、Codebase Onboarding、Agent Designer、Changelog Generator | ★★★ |
| **QA** | AC 驗證、Spec/Code Quality Review | Playwright Pro（12 skills）、API Test Suite Builder、PR Review Expert、Performance Profiler | ★★★ |
| **Security** | Security Review、OWASP 檢查 | Skill Security Auditor、Env Secrets Manager、Dependency Auditor、SecOps、ISO 27001 / GDPR 合規框架 | ★★★ |
| **SRE** | 部署、監控、Incident Response | Observability Designer、Performance Profiler、Incident Commander、Runbook Generator、CI/CD Pipeline Builder、Release Manager | ★★★ |
| **UI/UX Designer** | Figma Prototype、Vision Critic | UX Researcher、UI Design、Landing Page、SaaS Scaffolding、Analytics（使用者行為分析） | ★★★ |
| **Stakeholder** | 商業期待確認、校準儀式 | C-Level Advisory（CEO/CTO/CFO 商業推理）、Customer Success、Revenue Operations、Strategic Planning | ★★☆ |

---

## 2. 角色逐一分析

### 2.1 QA Engineer

**現有痛點**（Issue #247 指出）：
- 只做規格驗收，缺少使用者視角
- 沒有探索性測試
- Mock 過度，缺少真實資料驗證
- Demo 只走 happy path，抽樣偏差

**可借鑑 Skills：**

| 外部 Skill | 能力 | 對應強化方向 |
|-----------|------|------------|
| **Playwright Pro** | E2E 測試生成、flaky fix、55 測試模板 | 探索性測試自動化、邊界案例生成模板 |
| **API Test Suite Builder** | 掃描 API routes 自動生成測試套件 | Smoke Test 自動化（#251 需求） |
| **PR Review Expert** | Blast radius 分析、coverage delta | Code Review 深度：變更影響範圍分析 |
| **Performance Profiler** | Load testing、bundle analysis | 非功能性驗收：效能面 AC 驗證 |

**落地建議**：
- Playwright Pro 的 55 測試模板 → 轉化為 Shikigami「探索性測試 checklist」模板，供 QA 在 Sprint Review 時執行
- API Test Suite Builder 的「掃描→生成」模式 → Smoke Test 設計原則：自動掃描 AC 引用的外部 API，生成至少 1 個真實資料驗證測試
- PR Review Expert 的 blast radius 分析 → 整合進 Code Quality Review，自動分析變更影響範圍

---

### 2.2 PO / Product Owner

**現有痛點**：
- AC 只寫功能性需求，漏掉非功能屬性（freshness、completeness）
- Discovery Phase 產出偏技術面，缺少使用者視角
- Backlog Grooming 的 RICE 評分缺少量化數據支撐

**可借鑑 Skills：**

| 外部 Skill | 能力 | 對應強化方向 |
|-----------|------|------------|
| **UX Researcher** | 使用者研究、痛點分析、Persona 建構 | Discovery Phase Step 1：從使用者痛點出發而非技術缺口 |
| **Product Manager** | 需求拆解、PRD 撰寫、優先級框架 | Backlog Grooming RICE 評分深度 |
| **Discovery** | 產品探索結構化流程 | Discovery Phase 流程交叉對照 |
| **Experiment Design** | A/B 測試設計、假設驗證方法 | Discovery Phase Step 2 假設外顯化的驗證方法具體化 |
| **Roadmap Communication** | 里程碑進度溝通、Stakeholder 對齊 | Sprint Review Stakeholder 確認深度 |
| **Analytics** | 數據分析、使用者行為追蹤 | AC 撰寫時引入可量測指標 |

**落地建議**：
- UX Researcher 的 Persona 方法 → 整合進 Discovery Phase Step 1，強制建構目標使用者 Persona
- Experiment Design 的假設驗證 → Step 2「三問機制」的第三問（「如果假設是錯的，會怎樣？」）加入量化驗證方法
- Analytics 的行為追蹤思維 → AC 模板加入「成功指標」欄位，引導 PO 寫出可量測的非功能性 AC

---

### 2.3 Architect

**現有痛點**：
- 技術評估聚焦在 ADR 和可行性，缺少資料架構和 Agent 架構的結構化指引
- MCP 整合已有兩例（Figma、Context Hub），但缺少通用 MCP 設計模式

**可借鑑 Skills：**

| 外部 Skill | 能力 | 對應強化方向 |
|-----------|------|------------|
| **RAG Architect** | RAG 系統設計、向量化策略、chunking | Knowledge Ingestion（ADR-017）架構優化 |
| **Database Designer / Schema Designer** | DB 設計、Schema 演進、正規化 | Refinement 階段資料架構審查 |
| **Migration Architect** | 遷移策略、向前相容、回滾計劃 | Legacy 遷移評估（/dispel skill 強化） |
| **API Design Reviewer** | REST/GraphQL 設計審查、契約優先 | 消費端 API 整合品質把關 |
| **Agent Designer** | Agent 架構設計模式 | Shikigami 自身 subagent 架構演進 |
| **Agent Workflow Designer** | 多 Agent 協作工作流設計 | 平行分群策略、跨角色協作模式優化 |
| **MCP Server Builder** | MCP Server 開發最佳實踐 | ADR-019 MCP 三層架構的 Server 設計 |

**落地建議**：
- Agent Designer + Agent Workflow Designer → 直接對應 Shikigami 自身架構演進，可在 subagent 品質退化時作為重構參考
- MCP Server Builder → ADR-019 Phase 2/3 MCP Server 實作時參考
- Database Designer → 整合進 Refinement Q1-Q5 分析，新增「資料架構評估」維度

---

### 2.4 Developer

**現有痛點**：
- Story 涉及資料庫時缺少結構化設計指引
- 效能敏感 Story 缺少 profiling 手段
- 技術債追蹤仍為手動
- 消費端大型 codebase 導航效率待提升

**可借鑑 Skills：**

| 外部 Skill | 能力 | 對應強化方向 |
|-----------|------|------------|
| **Database Designer / Schema Designer** | DB 設計、Schema 演進策略 | Story 涉及資料庫時的設計品質 |
| **Migration Architect** | 資料庫/架構遷移策略規劃 | 遷移類 Story 的實作品質與風險控制 |
| **Performance Profiler** | Node/Python/Go profiling、bundle analysis、load testing | 效能敏感 Story 的 TDD 補充（效能測試） |
| **Tech Debt Tracker** | 技術債自動識別、分類、優先排序 | Tech_Debt_Registry.md 自動化：從手動標記升級為主動偵測 |
| **Monorepo Navigator** | 大型 codebase 快速定位與理解 | 消費端大型專案的開發效率 |
| **Codebase Onboarding** | 新專案快速上手流程 | /dispel（Legacy 考古）skill 強化 |
| **Agent Designer / Workflow Designer** | Agent 設計模式與工作流最佳化 | Subagent 自身的架構品質提升 |
| **Changelog Generator** | 自動生成結構化 changelog | deployment-readiness 版本發布流程強化 |

**落地建議**：
- Database Designer → 整合進 Refinement 的 Developer 諮詢環節（§10），Story 開始前提供結構化 DB 設計指引
- Performance Profiler → 非功能性 AC 實作參考，效能敏感 Story 強制包含效能測試
- Tech Debt Tracker 自動偵測模式 → 升級現有手動 `[TECH-DEBT]` 標記為自動掃描

---

### 2.5 Security Engineer

**現有痛點**：
- Security Review 聚焦在 OWASP Top 10 和外部輸入防護
- 缺少 Supply Chain 安全（依賴審計）和合規面向
- 框架自身的 skill/prompt 安全審計機制不完整

**可借鑑 Skills：**

| 外部 Skill | 能力 | 對應強化方向 |
|-----------|------|------------|
| **SecOps** | 完整安全運營體系 | Security Review 範圍擴展：從程式碼層擴展至運營層 |
| **Skill Security Auditor** | Skills/Plugins 安全審計 | Shikigami 自身 skill 與 prompt 的注入風險審查 |
| **Env Secrets Manager** | 環境變數與密鑰管理最佳實踐 | ADR-006 Injection 防護延伸至 secrets 管理 |
| **Dependency Auditor** | 依賴掃描、License compliance、升級規劃 | Supply Chain 安全 + 開源授權合規 |
| **ISO 27001 / GDPR 框架** | 資訊安全管理系統、資料保護 | Security Review 加入合規維度 checklist |

**落地建議**：
- Dependency Auditor → Security Review 新增「依賴安全掃描」步驟，檢查 npm/pip 依賴的已知漏洞和 license 合規
- Skill Security Auditor → 定期審計 Shikigami 自身 prompt 的注入風險（ADR-006 自指向檢查）
- ISO 27001 / GDPR 合規思維 → 消費端涉及使用者資料的 Story，Security Review 加入資料保護 checklist

---

### 2.6 SRE Engineer

**現有痛點**：
- 部署與監控流程已建立，但可觀測性三件套（Metrics/Logs/Traces）尚未完整
- Incident Response 流程仍為手動
- 缺少標準化 Runbook

**可借鑑 Skills：**

| 外部 Skill | 能力 | 對應強化方向 |
|-----------|------|------------|
| **Observability Designer** | 監控三件套設計（Metrics / Logs / Traces） | #222 SRE 完整化：可觀測性架構 |
| **Incident Commander** | Incident Response 流程自動化、升級鏈 | Post-mortem 流程標準化 |
| **Runbook Generator** | 運維手冊自動生成 | 部署 runbook 標準化，降低人工操作風險 |
| **Performance Profiler** | Node/Python/Go profiling、load testing | 效能基準管理（#224）：部署前 Load Test |
| **CI/CD Pipeline Builder** | Pipeline 設計、最佳化、安全掃描整合 | CI Gate 強化、Pipeline 效能優化 |
| **Release Manager** | 版本管理、Release Notes、回滾策略 | deployment-readiness 流程深度提升 |

**落地建議**：
- Observability Designer + Incident Commander → 直接對應 #222（SRE 完整化），可作為 Story 實作的設計藍圖
- Runbook Generator → 消費端專案的部署 runbook 自動生成，降低手動操作失誤
- Release Manager → 整合進 deployment-readiness skill，強化版本管理與回滾策略

---

### 2.7 UI/UX Designer

**現有痛點**：
- Vision Critic 聚焦視覺一致性，缺少使用者體驗維度
- DESIGN Story 的驗收偏重「看起來對不對」而非「用起來好不好」
- Design Token 體系建立但缺少與真實使用者數據的回饋循環

**可借鑑 Skills：**

| 外部 Skill | 能力 | 對應強化方向 |
|-----------|------|------------|
| **UX Researcher** | 使用者研究方法論、可用性測試 | DESIGN Story 加入使用者驗證環節 |
| **UI Design** | Design System 管理、元件庫維護 | Design Token 體系的系統化管理 |
| **Landing Page** | 高品質頁面快速生成、設計模式庫 | 前端 Story 的設計效率與品質 |
| **SaaS Scaffolding** | SaaS 產品 UI 骨架快速搭建 | 消費端產品的 UI 架構一致性 |
| **Analytics** | 使用者行為數據分析 | Design Token 優化的數據驅動依據 |

**落地建議**：
- UX Researcher → Vision Critic 新增「使用者體驗」維度，從純視覺評分擴展至可用性評估
- UI Design 的 Design System 管理 → Design Token 體系加入版本管理與變更日誌
- Analytics 的使用者行為分析 → DESIGN Story AC 引入使用者體驗指標（如操作步驟數、認知負荷）

---

### 2.8 Stakeholder

**現有能力**：商業期待確認、校準儀式、升級鏈終端決策者

**可借鑑 Skills：**

| 外部 Skill | 能力 | 對應強化方向 |
|-----------|------|------------|
| **C-Level Advisory（CEO）** | 商業策略、願景對齊 | Sprint Review 商業期待確認的深度：從「功能滿意」擴展至「策略對齊」 |
| **C-Level Advisory（CTO）** | 技術投資決策、技術債取捨 | Architect 升級時的技術商業面判斷 |
| **C-Level Advisory（CFO）** | ROI 分析、成本效益評估 | Discovery Phase 的商業假設驗證加入財務面 |
| **Customer Success** | 客戶成功運營、滿意度追蹤 | 校準儀式的深度：從「價值觀對齊」擴展至「客戶成功指標追蹤」 |
| **Revenue Operations** | 營收流程優化 | PO Backlog 排序的商業影響力評估 |
| **Strategic Planning** | 長期策略規劃、市場定位 | ROADMAP 里程碑的策略對齊 |

**落地建議**：
- C-Level 商業推理框架 → Stakeholder 在 Sprint Review 時不只確認「功能是否符合期待」，也評估「是否推動商業目標」
- Customer Success 思維 → 校準儀式加入「本 Sprint 交付對終端使用者的實際影響」評估
- 注意：Stakeholder 角色的核心價值在「簡潔決策」，不宜過度複雜化。引入商業推理框架應以「增加判斷深度」為目標，不增加儀式複雜度

---

## 3. 優先建議：Sprint 93 可立即借鑑的項目

| 優先級 | Shikigami 角色 | 借鑑來源 | 落地方式 |
|--------|---------------|---------|---------|
| **P0** | QA | Playwright Pro 測試模板 | US-254 探索性測試：引入邊界案例生成模板 |
| **P0** | QA | API Test Suite Builder | US-253 Smoke Test：「掃描→生成」設計模式 |
| **P0** | PO | UX Researcher + Analytics | US-251 AC 模板：加入非功能屬性欄位 |
| **P1** | Developer | Database Designer + Migration Architect | Refinement 階段 DB 設計指引 |
| **P1** | Developer | Tech Debt Tracker | Tech_Debt_Registry.md 自動化偵測 |
| **P1** | Architect | Agent Designer + MCP Server Builder | Subagent 架構演進 + ADR-019 Phase 2 |
| **P1** | SRE | Observability Designer + Incident Commander | #222 SRE 完整化 Story 設計藍圖 |
| **P1** | Security | Dependency Auditor | Security Review 加入依賴安全掃描 |
| **P2** | UI/UX | UX Researcher | Vision Critic 使用者體驗維度 |
| **P2** | Stakeholder | C-Level Advisory + Customer Success | Sprint Review 商業推理深度 |
| **P2** | Developer | Performance Profiler | 效能敏感 Story 非功能性測試 |
| **P2** | Architect | RAG Architect | Knowledge Ingestion 演進參考 |

---

## 4. 不建議引入的項目

| 外部 Skill 類別 | 原因 |
|----------------|------|
| Marketing（43 skills） | 與 Shikigami Scrum Team 框架定位無關 |
| Finance（2 skills） | 超出 Scrum Team 日常職責；CFO 思維已透過 Stakeholder 間接引入 |
| Regulatory/QM — 醫療專用（ISO 13485、MDR、FDA） | 過於特定產業，不通用；但 ISO 27001/GDPR 已納入 Security 角色 |
| Self-Improving Agent | 功能與 Claude Code 內建 memory 系統重疊 |
| Interview System Designer | 面試流程設計，與框架無關 |
| Google Workspace CLI | 特定工具整合，非角色能力強化 |

---

## 5. 結論

177+ skills 中，約 **45 個**（25%）與 Shikigami 現有 8 個角色有直接強化關係。**全部 8 個角色都有明確的升級路徑**：

| 角色 | 可借鑑數量 | 核心強化主題 |
|------|-----------|------------|
| Developer | 8 | DB 設計、效能、技術債自動化、Agent 架構 |
| Architect | 7 | RAG、Agent 設計、MCP Server、API 審查 |
| QA | 4 | 探索性測試、Smoke Test、blast radius |
| SRE | 6 | 可觀測性、Incident Response、Runbook |
| PO | 7 | UX 研究、假設驗證、數據分析、Roadmap |
| Security | 5 | SecOps、依賴審計、合規框架 |
| UI/UX | 5 | UX 研究、Design System、使用者行為分析 |
| Stakeholder | 6 | C-Level 商業推理、客戶成功、策略規劃 |

Sprint 93 正在做的 #247 品質強化全家桶（US-250 ~ US-254），可在實作時直接參考上述外部 skills 的設計思維，融入框架自有角色的 prompt 中。不需直接安裝外部 skills，而是**內化其思維模式為 Shikigami 角色的能力升級**。
