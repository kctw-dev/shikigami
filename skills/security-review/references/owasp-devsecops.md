# Security Review — OWASP / DevSecOps / Secrets 參考

## §2. OWASP Top 10 檢查清單

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

## §3. DevSecOps 實踐

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

## §4. Secrets Management 審查

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
