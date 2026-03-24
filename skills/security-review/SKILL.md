---
name: security-review
description: "Use when handling external input, API endpoints, configuration changes, security scanning, or vulnerability assessment"
---

# Security Review — 安全審查

## 1. 概述

Security Engineer 主導的安全審查 Skill，確保在安全漏洞被利用前發現並修復。

針對所有涉及外部輸入、API 端點、配置變更的程式碼，派遣 Security Engineer subagent 進行系統性安全審查。以 OWASP Top 10 為核心檢查框架，結合 DevSecOps 實踐與 Secrets Management 審查，在開發流程中建立完整的安全防線。

詳細檢查清單與實踐指引見 `references/owasp-devsecops.md`；Refinement 職責見 `references/refinement-security.md`。

---

## 2. OWASP Top 10 檢查（摘要）

10 大風險類別逐項檢查：Injection、Broken Authentication、Sensitive Data Exposure、XXE、Broken Access Control、Security Misconfiguration、XSS、Insecure Deserialization、Known Vulnerabilities、Insufficient Logging。

完整清單：`references/owasp-devsecops.md` §2。

---

## 3. DevSecOps 實踐（摘要）

- **Shift-Left**：安全需求納入 Story AC，PR 前強制通過安全門禁
- **SAST/DAST**：CI 靜態分析 + CD 動態測試，Critical/High 阻塞合併
- **依賴掃描**：自動比對 CVE，超過閾值自動阻塞
- **Container**：多層掃描，禁 root，Image 簽名驗證

完整細節：`references/owasp-devsecops.md` §3。

---

## 4. Secrets Management（摘要）

- 密鑰自動輪替（零停機，雙密鑰重疊期）
- 動態短期密鑰取代靜態長期密鑰
- Pre-commit hook 防密鑰蔓延
- API 金鑰依服務/環境隔離，異常告警

完整細節：`references/owasp-devsecops.md` §4。

---

## 5. 執行流程

```
Security Review 觸發
  → Security Engineer subagent 派遣
  → OWASP Top 10 逐項檢查
  → 輸入驗證 / 認證授權密碼學審查
  → 依賴掃描
  → 漏洞分級判定
      Critical/High → 阻塞，修復後重審
      Medium/Low   → 記錄追蹤，允許繼續
  → 通過 → 繼續流程
```

---

## 6. 升級觸發

| 嚴重度 | 動作 | 時效 |
|--------|------|------|
| Critical | 通知 Stakeholder + SRE，阻塞所有部署 | 15 分鐘內 |
| High | 通知 Tech Lead，阻塞 PR 合併 | 1 小時內 |
| Medium | 建立追蹤 Issue，排入下一 Sprint | Sprint 內 |
| Low | 記錄至技術債清單 | 季度內 |

<HARD-GATE>
Critical 漏洞發現後必須立即通知 Stakeholder 與 SRE，不得延遲或靜默處理。
所有受影響的部署流水線必須立即暫停，直到漏洞修復並通過重新審查。
</HARD-GATE>

---

## 7. 安全品質門禁

| 門禁條件 | 阻塞等級 |
|---------|---------|
| Critical/High 漏洞合併前解決 | 硬性阻塞 |
| 安全測試覆蓋所有外部輸入路徑 | 硬性阻塞 |
| 生產環境零 Critical 漏洞 | 硬性阻塞 |
| CIS Benchmarks 合規驗證通過 | 硬性阻塞 |
| 無明文密鑰 / Token / 憑證 | 硬性阻塞 |
| 依賴套件無 Critical CVE | 硬性阻塞 |

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
| Sprint Execution 涉及外部輸入/API/配置變更 | 由 `sprint-execution` 觸發 `security-review` |
| 安全審查發現架構層級問題 | 觸發 `architecture-decision` |
| 安全審查通過 | 回到 `sprint-execution` 繼續 |
| Critical 漏洞影響已上線功能 | 升級 Stakeholder + SRE，建立緊急修復 Story |

---

## 9. Security Engineer Refinement 職責（摘要）

<!-- US-203 — Sprint 77 -->

諮詢（Consulted）角色，提前識別 Story 安全風險，確保安全 AC 在開發啟動前明確定義。

**觸發出席**：SECURITY Story、AC 含 `[安全]`、涉及外部輸入/認證/授權/加密、新 API 端點。
**不觸發**：doc-only Story、純 RESEARCH 無程式碼交付物。

完整觸發條件、職責說明與輸出格式：`references/refinement-security.md` §9。
