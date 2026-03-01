# 決策記錄：領域專家審查機制

> 來源：Sprint 9 Retrospective Action Item #19
> 日期：2026-03-01
> 參與者：PO + Architect

---

## 問題陳述

Sprint 9 Retrospective 中，使用者指出 Shikigami 框架缺乏在特定階段引入外部領域專家（Domain Expert）的機制。目前框架由 7 個內建角色組成（PO、Architect、Developer、QA Engineer、SRE Engineer、Security Engineer、Stakeholder），這些角色的設計假設是「AI Agent 執行 Scrum 最佳實踐」，其知識邊界等同於 LLM 的訓練資料。

當 Sprint Story 涉及特定垂直領域（如醫療法規、金融合規、機械工程設計）時，框架無法引入「不在訓練資料中」或「需要實際業務脈絡驗證」的領域知識。這是框架從「開發工具框架」擴展至「真實產品開發輔助工具」時可能面臨的知識盲區。

---

## 調查結果

### 使用案例識別

調查問題：哪些 Sprint 階段最可能需要領域專家？什麼類型的 Story 最需要外部知識驗證？

**場景一：Sprint Planning — 需求定義階段**

當 Story 的 Acceptance Criteria 涉及特定法規、行業標準或使用者業務流程時，AC 的合理性難以由 PO（AI Agent）獨立驗證。例如：

- 醫療軟體的 HIPAA 合規要求
- 金融系統的 KYC / AML 規則
- 工業自動化系統的安全標準（IEC 61508）

現有框架中，PO 負責需求定義（RACI 中 A），但 PO 的知識基礎是通用 LLM。若業務規則與訓練資料存在差異，AC 可能基於過時或不完整的假設建立。

**場景二：Sprint Execution — 實作審查階段**

Developer + QA 完成實作後，Code Quality Review 和 Spec Compliance Review 檢查的是「是否符合 AC」，但無法檢查「AC 本身是否反映了正確的業務邏輯」。此處是知識盲區最難被偵測的位置——系統性誤解不會在品質審查中浮現。

**場景三：Sprint Review — 成果驗收階段**

Stakeholder 角色承擔最終仲裁，但 Stakeholder 在框架中是升級鏈的終點，主要職責是解決「角色間無法解決的僵局」，而非「提供領域知識驗證」。若成果包含領域特定邏輯，Stakeholder（AI Agent）同樣缺乏外部視角。

**結論：Planning 的需求定義是最高風險點**，因為 AC 錯誤會向下游傳遞，被 Execution 和 Review 依賴。Execution 審查是第二高風險點，因為此處的知識盲區不可見。

---

### 現有框架限制

**7 個角色的知識覆蓋範圍：**

| 角色 | 知識邊界 | 領域專家替代可能性 |
|------|----------|-------------------|
| Product Owner | 需求優先級、Scrum 流程、通用業務邏輯 | 低 — 缺乏垂直領域法規、業務規則 |
| Architect | 系統設計、ADR、軟體架構模式 | 低 — 缺乏行業特定技術標準 |
| Developer | TDD、SOLID、實作最佳實踐 | 不適用 — Developer 是執行角色 |
| QA Engineer | 測試策略、品質門禁、審查流程 | 低 — 品質標準通用，但驗收邏輯需領域知識 |
| Security Engineer | OWASP、常見安全漏洞、認證授權 | 中 — 一般安全知識廣泛，但行業特定安全規範不足 |
| SRE Engineer | 部署、監控、可靠性 | 不適用 — 涉及基礎設施，不需垂直領域知識 |
| Stakeholder | 最終仲裁、策略方向 | 低 — 是升級解決者而非領域知識提供者 |

**框架在「Dogfooding」場景（開發框架本身）的分析：**

Shikigami 本身就是框架的使用對象。此場景中，「領域」是「Scrum 流程設計」和「AI Agent 協作模式」。這兩個領域的知識已完整內化於 7 個角色的 SKILL.md 和 ADR 中。Sprint 1–9 的歷史記錄顯示，dogfooding 場景下 100% 完成率且無需外部領域知識介入。

**框架用於真實產品開發的分析：**

當框架被部署於垂直領域產品（如 FinTech、MedTech、LegalTech）時，知識缺口顯著擴大。使用者的業務脈絡、法規約束、行業慣例無法從 LLM 訓練資料中完整取得，且部分屬於公司內部知識，根本不存在於訓練資料中。

**核心缺口定位：** 現有框架缺少一個「能帶入外部業務脈絡」的角色或機制，且現有的 RACI 矩陣沒有為領域知識驗證定義 Accountable。

---

### 可行方案

#### 方案 A：新增 Domain Expert 角色（第 8 個 Subagent）

**描述：** 在 7 個現有角色之外，定義 `domain-expert` 為第 8 個 Subagent 角色。在 sprint-planning SKILL.md 中新增觸發條件：當 Story 標注 `[DOMAIN-SENSITIVE]` 標籤時，派遣 Domain Expert 進行需求審查；在 sprint-execution SKILL.md 中新增可選的 Domain Expert 審查步驟。建立對應的 SKILL.md 和 agent prompt，包含「領域知識驗證」的審查框架（提問清單、盲區偵測、法規合規確認）。

**優點：**
- 結構化整合進現有流程，Domain Expert 成為框架一等公民
- 觸發條件明確（Story 標注），可選擇性啟用，不強制每個 Story 都經過
- RACI 矩陣可以明確為 Domain Expert 定義職責，消除現有「領域知識驗證無人 Accountable」的缺口
- 可與 ADR-003 Hard Gate / Soft Gate 分級體系整合（低頻高影響 → Hard Gate）

**缺點：**
- 引入新角色需要 ADR（架構變更），有 Hard Gate 阻塞需先通過
- `domain-expert` 角色本質上仍是 AI Agent，其領域知識仍受限於 LLM 訓練資料——對「公司內部特有的業務規則」無法解決根本問題
- Story 標注 `[DOMAIN-SENSITIVE]` 依賴開發者主動識別，存在漏標風險
- 新增角色增加 scrum-master SKILL.md 路由複雜度和框架維護負擔

**適用場景：** 框架需要提醒 AI Agent「此處需要格外謹慎」，但實際領域知識驗證由使用者在 Sprint Review 時人工完成。

---

#### 方案 B：加入「使用者確認節點」而非新角色（流程插入機制）

**描述：** 不新增角色，而是在現有流程中新增「暫停等待使用者確認」的節點，專門用於領域知識驗證。在 sprint-planning SKILL.md 中，當 Story 含有特定觸發條件（如 `[DOMAIN-SENSITIVE]` 標注，或 AC 中包含法規、合規、行業標準等關鍵字），框架輸出「領域知識驗證清單」並暫停，等待使用者填充或確認。此機制利用 `high` 等級的「人工確認」路徑（scrum-master SKILL.md §6.1），但將其擴展為一個可在所有等級啟用的特殊節點。

**優點：**
- 不引入新角色，架構侵入性低，不需要新 ADR
- 直接將「領域知識」的 Accountable 回歸到真正有業務脈絡的人（使用者），而非讓 AI Agent 模擬
- 可以補充現有 `high` 等級的確認機制，也可以為 `low` / `medium` 等級提供主動的領域知識確認機會
- 框架輸出的「領域知識驗證清單」具體說明「框架不確定的假設點」，使用者只需確認，而非從零提供知識

**缺點：**
- 與「不阻塞原則」（scrum-master §6.1）存在張力——明確引入等待節點
- 若使用者跳過確認（例如 `low` 等級專案自動接受），機制形同虛設
- 觸發條件（關鍵字比對 vs. 人工標注）的設計複雜度不低，且和 ADR-004 關鍵字清單機制重疊，需要協調
- 不改變框架中「領域知識驗證無人 Accountable」的根本結構問題

**適用場景：** 框架主要用於真實產品開發，且使用者願意且能夠在 Sprint Planning 時介入提供業務脈絡。

---

## 決策結論

**不採納（在本 Sprint 內推進實作）。**

調查結論為：在 Shikigami 框架目前的主要使用場景（dogfooding — 開發框架本身）下，領域專家審查的需求不成立。9 個 Sprint 的歷史數據顯示，框架自身的持續演進不需要外部領域知識介入，現有 7 個角色和 ADR / Hard Gate 機制已足夠支撐 Sprint 節奏。

然而，這個結論有一個重要的條件邊界：**若框架被部署於垂直領域產品開發，或 Shikigami 本身進入新的高度領域特定的功能（如整合特定法規審查工具），此決策需重新評估。**

不採納的核心理由：

1. **問題規模不匹配當前需求**：目前框架主要服務於自身的迭代開發，此場景中「領域」等同於「Scrum + AI Agent 協作模式」，已被內化於框架知識中。引入領域專家機制解決的是一個當前不存在的問題，違反 YAGNI 原則。

2. **方案 A 的根本限制**：新增 `domain-expert` 角色仍是 AI Agent，其知識邊界仍受 LLM 訓練資料限制。對於框架用於 dogfooding 的場景，新角色沒有實質增值；對於真實產品開發的場景（公司內部業務規則），新角色仍無法提供所需知識。引入角色的架構成本高於其解決的問題。

3. **方案 B 的不阻塞原則衝突**：明確引入等待節點與框架的核心設計決策（scrum-master §6.1 不阻塞原則）衝突。在當前場景下，此衝突的代價大於收益。

4. **現有機制已有部分覆蓋**：`escalation` Skill + `high` 等級專案的人工確認路徑，已為「框架無法自行解決的問題」提供了升級通道。真正需要領域知識介入時，使用者可以在 Sprint Planning 或 Sprint Review 時直接以 Stakeholder 角色介入。

---

## 後續行動

**不採納路徑：監控條件 + 觸發再評估時機**

當以下任一條件成立時，應重新開啟領域專家審查機制的評估：

| # | 觸發條件 | 說明 |
|---|----------|------|
| 1 | Shikigami 被部署於垂直領域真實產品開發 | 使用者報告 Story 驗收失敗的根因是「框架不了解業務規則」 |
| 2 | 連續 2 個 Sprint 的 Retrospective Problem 中出現「領域知識」相關 Problem | 與 ADR-004 關鍵字清單機制對齊，可在 Retrospective Analytics 中自動偵測 |
| 3 | 框架引入需要行業特定知識的新功能（如特定合規工具整合） | 例如整合 GDPR 審查、OWASP 掃描結果解讀等 |

**若未來決定採納：**

- Story 規模估計：**M（2 points）**
  - 範圍：定義觸發條件（關鍵字 / 標注機制）+ 設計流程插入點 + 更新 SKILL.md
  - 不包含新角色建立（建議優先採方案 B 的流程插入機制，避免架構複雜度）

- ADR 需求：**需要建立新 ADR（ADR-005 候選）**
  - 決策問題：領域專家機制應採用「新角色（方案 A）」還是「流程插入節點（方案 B）」
  - 觸發 ADR 的原因：兩個方案在「RACI 結構」和「不阻塞原則相容性」上有根本性差異，構成架構決策而非實作選擇
  - ADR 需在對應 Story 進入 Sprint 之前完成（遵循現有 ADR Hard Gate 機制）

- 排程建議：排入下一個評估週期（Sprint 11 以後），不佔用 Sprint 10 容量
