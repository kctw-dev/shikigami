---
name: security-review
description: "Use when handling external input, API endpoints, configuration changes, security scanning, or vulnerability assessment"
---

# Security Review — 安全審查

## 1. 概述

Security Engineer 主導的安全審查 Skill，確保在安全漏洞被利用前發現並修復。

針對所有涉及外部輸入、API 端點、配置變更的程式碼，派遣 Security Engineer subagent 進行系統性安全審查。以 OWASP Top 10 為核心檢查框架，結合 DevSecOps 實踐與 Secrets Management 審查，在開發流程中建立完整的安全防線。

---

## 2. OWASP Top 10 檢查清單

每次安全審查必須逐項檢查以下十大風險類別：

| # | 風險類別 | 說明 | 檢查重點 |
|---|---------|------|---------|
| A1 | Injection（注入攻擊） | SQL、NoSQL、OS、LDAP 注入 | 參數化查詢、輸入驗證、ORM 使用 |
| A2 | Broken Authentication（認證失效） | Session 管理、密碼策略缺陷 | 多因素認證、Session 過期、密碼雜湊強度 |
| A3 | Sensitive Data Exposure（敏感資料暴露） | 傳輸/儲存中的資料洩漏 | TLS 強制、加密儲存、資料分類標記 |
| A4 | XML External Entities（XXE） | XML 解析器外部實體攻擊 | 停用外部實體、使用 JSON 替代、XML 解析器加固 |
| A5 | Broken Access Control（存取控制失效） | 權限繞過、越權存取 | RBAC 驗證、最小權限原則、資源所有權檢查 |
| A6 | Security Misconfiguration（安全設定錯誤） | 預設設定、錯誤的 HTTP Header | 安全 Header 設定、錯誤訊息處理、版本資訊隱藏 |
| A7 | Cross-Site Scripting（XSS） | 反射型、儲存型、DOM 型 XSS | 輸出編碼、CSP 設定、輸入消毒 |
| A8 | Insecure Deserialization（不安全的反序列化） | 物件注入、遠端代碼執行 | 反序列化白名單、完整性檢查、型別限制 |
| A9 | Using Components with Known Vulnerabilities（使用已知漏洞元件） | 過時的依賴、未修補的漏洞 | 依賴版本檢查、CVE 掃描、自動更新策略 |
| A10 | Insufficient Logging & Monitoring（日誌與監控不足） | 攻擊偵測與回應能力不足 | 安全事件日誌、異常告警、稽核軌跡完整性 |

---

## 3. DevSecOps 實踐

### 3.1 Shift-Left Security（安全左移）

將安全檢查從部署後移至開發階段，越早發現漏洞，修復成本越低：

- 開發人員在本機即可執行安全掃描
- Code Review 階段納入安全審查
- PR 合併前強制通過安全品質門禁
- 安全需求納入 Story 的 Acceptance Criteria

### 3.2 SAST/DAST 整合到 CI/CD

- **SAST（靜態應用安全測試）**：在 CI 階段分析原始碼，識別潛在漏洞（如 SQL Injection、XSS、硬編碼密鑰）
- **DAST（動態應用安全測試）**：在 CD 階段對運行中的應用進行黑箱測試，模擬真實攻擊場景
- 掃描結果自動回報至 PR，Critical/High 等級阻塞合併
- 定期更新掃描規則庫，確保涵蓋最新威脅

### 3.3 依賴漏洞掃描

- 每次建構時自動掃描所有直接與間接依賴
- 對照 CVE 資料庫比對已知漏洞
- 自動產生修復建議（版本升級路徑）
- 設定漏洞嚴重度閾值，超過閾值自動阻塞

### 3.4 Container Image 掃描

- Base image 安全性驗證
- 多層掃描：OS 套件漏洞 + 應用依賴漏洞
- 禁止使用 root 用戶運行容器
- Image 簽名與來源驗證

---

## 4. Secrets Management 審查

### 4.1 密鑰輪替自動化

- 所有密鑰必須設定自動輪替排程
- 輪替過程零停機（雙密鑰重疊期）
- 輪替後自動驗證服務健康狀態
- 輪替記錄納入稽核日誌

### 4.2 動態密鑰生成

- 使用短期有效的動態密鑰取代長期靜態密鑰
- 資料庫連線使用臨時憑證（如 Vault Dynamic Secrets）
- 雲端服務使用臨時 Token（如 STS AssumeRole）
- 密鑰有效期依最小必要原則設定

### 4.3 密鑰蔓延防護

- 禁止在程式碼、設定檔、日誌中出現明文密鑰
- Pre-commit hook 掃描密鑰洩漏
- CI/CD Pipeline 密鑰注入而非靜態儲存
- 定期掃描版本控制歷史中的密鑰殘留

### 4.4 API 金鑰治理

- API 金鑰依服務/環境隔離
- 設定使用範圍限制（IP 白名單、權限範圍）
- 金鑰使用量監控與異常告警
- 停用未使用的金鑰，定期清理殭屍金鑰

---

## 5. 執行流程

```
Security Review 觸發
  |
  v
1. Security Engineer subagent 派遣
  |
  v
2. OWASP Top 10 逐項檢查
  |
  v
3. 輸入驗證審查（所有外部入口）
  |
  v
4. 認證/授權/密碼學審查
  |
  v
5. 依賴掃描
  |
  v
6. 漏洞分級判定
  |-- Critical 漏洞 --> 阻塞，修復後重審
  |-- High 漏洞 --> 阻塞，修復後重審
  |-- Medium/Low 漏洞 --> 記錄追蹤，允許繼續
  +-- 無漏洞
        |
        v
7. 通過 --> 繼續流程
```

### 步驟詳解

1. **Security Engineer subagent 派遣**：建立全新的 Security Engineer subagent，注入待審查程式碼的上下文、相關 ADR、已知的安全需求。
2. **OWASP Top 10 逐項檢查**：依照第 2 節檢查清單，逐一檢視程式碼是否存在對應風險。
3. **輸入驗證審查**：識別所有外部輸入入口（API 參數、表單欄位、URL 參數、Header、檔案上傳），驗證是否有完整的輸入驗證與消毒處理。
4. **認證/授權/密碼學審查**：檢查認證流程完整性、授權邏輯正確性、加密演算法選擇與實作是否符合最佳實踐。
5. **依賴掃描**：掃描所有依賴套件的已知漏洞，確認無 Critical/High 等級的已知 CVE。
6. **漏洞分級判定**：依 CVSS 評分分級，Critical/High 漏洞阻塞合併，Medium/Low 記錄追蹤。
7. **通過**：所有 Critical/High 漏洞已解決，安全審查通過，繼續後續流程。

---

## 6. 升級觸發

當發現 Critical 漏洞時，立即啟動升級機制：

| 嚴重度 | 動作 | 時效要求 |
|--------|------|---------|
| Critical | 立即通知 Stakeholder + SRE，阻塞所有相關部署 | 發現後 15 分鐘內通知 |
| High | 通知 Tech Lead，阻塞 PR 合併 | 發現後 1 小時內通知 |
| Medium | 建立追蹤 Issue，排入下一 Sprint | Sprint 內處理 |
| Low | 記錄至技術債清單 | 季度內處理 |

<HARD-GATE>
Critical 漏洞發現後必須立即通知 Stakeholder 與 SRE，不得延遲或靜默處理。
所有受影響的部署流水線必須立即暫停，直到漏洞修復並通過重新審查。
</HARD-GATE>

---

## 7. 安全品質門禁

所有程式碼在合併前必須通過以下安全品質門禁：

| 門禁條件 | 說明 | 阻塞等級 |
|---------|------|---------|
| 所有 Critical/High 漏洞必須在合併前解決 | SAST/DAST 掃描結果中不得存在未修復的 Critical 或 High 漏洞 | 硬性阻塞 |
| 安全測試必須覆蓋所有外部輸入路徑 | 每個 API 端點、表單欄位、檔案上傳入口均需對應安全測試 | 硬性阻塞 |
| 生產環境零 Critical 漏洞 | 生產環境中不得存在任何未修復的 Critical 等級漏洞 | 硬性阻塞 |
| CIS Benchmarks 合規驗證 | 基礎設施配置符合 CIS（Center for Internet Security）基準要求 | 硬性阻塞 |
| 無明文密鑰 | 程式碼庫中不得出現任何明文密鑰、Token、憑證 | 硬性阻塞 |
| 依賴漏洞掃描通過 | 所有依賴套件無 Critical 等級已知 CVE | 硬性阻塞 |

<HARD-GATE>
所有 Critical/High 漏洞必須在合併前解決。
安全測試必須覆蓋所有外部輸入路徑。
生產環境零 Critical 漏洞。
CIS Benchmarks 合規驗證必須通過。
</HARD-GATE>

---

## 8. 與其他 Skill 的關係

| 情境 | 觸發 |
|------|------|
| Sprint Execution 中涉及外部輸入/API/配置變更 | 由 `sprint-execution` 觸發 `security-review` |
| 安全審查發現架構層級安全問題 | 觸發 `architecture-decision` 進行安全架構 ADR |
| 安全審查通過 | 回到 `sprint-execution` 繼續後續流程 |
| 安全審查發現 Critical 漏洞影響已上線功能 | 升級至 Stakeholder + SRE，建立緊急修復 Story 排入 Backlog |

---

## 9. Security Engineer Refinement 職責

<!-- US-203 角色 Refinement 職責定義 — Sprint 77 -->

Security Engineer 在 Refinement 中負責提前識別 Story 的安全風險，確保安全需求在開發啟動前已明確定義於 AC 中。Security Engineer 在 Refinement 中為**諮詢（Consulted）**角色，不主持、不輸出正式報告，但需提供具體安全風險評估意見。

### 觸發條件

Security Engineer **須出席 Refinement** 的情況（滿足任一條件）：

| 觸發條件 | 說明 |
|---------|------|
| Story Type 為 SECURITY | SECURITY Story 必須由 Security Engineer 作為 Contract Owner 確認修復方案方向 |
| Story 的 AC 含 `[安全]` 標記 | AC 已明確標注安全需求，需 Security Engineer 確認驗收標準可行性 |
| Story 涉及外部輸入、認證、授權或加密 | 即使 Story Type 非 SECURITY，涉及安全面向需 Security Engineer 提前評估 |
| FEATURE / INTEGRATION Story 引入新 API 端點 | 新 API 端點具備攻擊面，需提前識別輸入驗證與認證需求 |

**不觸發出席**：doc-only Story（僅修改 docs/ 文件）、純 RESEARCH 探索性 Story 且無程式碼交付物。

### 職責說明

| 面向 | 職責內容 |
|------|---------|
| **威脅識別** | 針對 Story 草稿，識別潛在安全威脅向量（OWASP Top 10 類別），列出受影響範圍 |
| **安全 AC 建議** | 若 Story 缺少對應安全驗收條件，建議補充至 AC 清單（如輸入驗證、認證流程、加密要求）|
| **Contract Owner 確認（SECURITY Story）** | 作為 SECURITY Type 的 Contract Owner，確認修復方案方向，提供安全審查策略初稿 |
| **Security Review 觸發預判** | 判斷 Story 完成後是否需觸發 Security Review Skill，並在 Refinement 報告中預先記錄 |

### Refinement 輸出

| 輸出項目 | 說明 |
|---------|------|
| 安全風險評估摘要 | 列出識別的威脅向量（OWASP 分類）、受影響範圍與嚴重度（Critical / High / Medium / Low）|
| 安全 AC 補充建議（若有） | 建議補充的安全驗收條件，由 PO 決定是否納入 Story AC 清單 |
| Security Review 觸發預判 | 明確說明 Story 完成後是否預期觸發 Security Review（是/否/條件觸發）|
