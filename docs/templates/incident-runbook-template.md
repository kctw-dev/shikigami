# Incident Response Runbook — [SERVICE_NAME]

> **使用說明**：複製此模板至事故處理文件，填入服務專屬資訊。
> 模板版本：v1.0 | 建立於 US-237 (Sprint 86)

---

## 事故基本資訊

| 欄位 | 填入值 |
|------|--------|
| 事故 ID | INC-YYYYMMDD-NNN |
| 服務名稱 | [SERVICE_NAME] |
| 事故開始時間 | YYYY-MM-DD HH:MM (UTC+8) |
| 事故結束時間 | YYYY-MM-DD HH:MM (UTC+8) |
| 嚴重性等級 | SEV-[1/2/3/4] |
| 指揮官 (Incident Commander) | [姓名] |
| 通訊頻道 | [Slack Channel / War Room URL] |

---

## 1. 嚴重性分級 (Severity Classification)

| 等級 | 定義 | 範例 | 初始回應時間 |
|------|------|------|------------|
| **SEV-1** | 生產環境完全中斷，所有使用者受影響，無降級方案 | 資料庫無法連線、核心 API 全面 5xx | 立即（< 5 分鐘） |
| **SEV-2** | 生產環境嚴重降級，大多數使用者受影響，降級方案失效或不足 | 主要功能異常、支付流程中斷 | < 15 分鐘 |
| **SEV-3** | 部分功能受影響，少數使用者受到影響，有可用的降級方案 | 非核心功能錯誤、特定地區延遲升高 | < 1 小時 |
| **SEV-4** | 輕微問題，不影響使用者體驗，需排入工單處理 | 日誌錯誤、監控告警誤報 | 下一個工作日 |

### 嚴重性判斷決策樹

```
使用者是否完全無法使用服務？
  ├── 是 → SEV-1
  └── 否
      ├── 主要功能是否嚴重降級（> 50% 使用者受影響）？
      │   ├── 是 → SEV-2
      │   └── 否
      │       ├── 部分使用者或非核心功能受影響？
      │       │   ├── 是 → SEV-3
      │       │   └── 否 → SEV-4
```

---

## 2. 升級路徑 (Escalation Path)

### 升級觸發條件

| 條件 | 動作 |
|------|------|
| 事故持續 > 15 分鐘且無法確認根因 | 升級至 On-call SRE Lead |
| 事故持續 > 30 分鐘（SEV-1/SEV-2） | 升級至 Engineering Manager |
| 涉及資料遺失或資安問題 | 立即升級至 Security + CTO |
| 影響範圍擴大（SEV 升級） | 重新通知對應升級對象 |

### 升級聯絡清單

| 角色 | 姓名/群組 | 聯絡方式 | 值班時間 |
|------|-----------|---------|---------|
| On-call SRE | [填入聯絡人] | [Slack Handle / 電話] | 24/7 輪值 |
| SRE Lead | [填入聯絡人] | [Slack Handle / 電話] | 工作日 + 緊急呼叫 |
| Engineering Manager | [填入聯絡人] | [Slack Handle / 電話] | 緊急呼叫 |
| CTO | [填入聯絡人] | [Slack Handle / 電話] | SEV-1 限定 |

---

## 3. 通訊協議 (Communication Protocol)

### 內部通訊

| 事件 | 通訊對象 | 頻道 | 頻率 |
|------|---------|------|------|
| 事故確認 | SRE Team | #incident-[date] | 立即 |
| 狀態更新 | Engineering Team | #incidents | 每 15 分鐘（SEV-1/2）/ 每 30 分鐘（SEV-3） |
| 根因初步確認 | Engineering Manager | 直接訊息 | 確認後立即 |
| 事故解除 | All stakeholders | #general + #incidents | 解除後立即 |

### 外部通訊（如適用）

| 事件 | 負責人 | 範本 |
|------|--------|------|
| 服務降級公告 | Product Manager | 見下方範本 A |
| 服務恢復公告 | Product Manager | 見下方範本 B |

**範本 A — 服務降級公告**
```
[服務狀態] 我們正在調查影響 [SERVICE_NAME] 的問題。
目前 [功能描述] 可能受到影響。
我們正積極處理中，將持續更新進展。
最後更新：YYYY-MM-DD HH:MM
```

**範本 B — 服務恢復公告**
```
[服務恢復] [SERVICE_NAME] 已於 YYYY-MM-DD HH:MM 恢復正常服務。
影響期間：HH:MM – HH:MM（共 X 分鐘）
根本原因將於 24 小時內發布 Post-mortem 報告。
造成不便，深感抱歉。
```

---

## 4. 解決步驟 (Resolution Steps)

### 初始回應 Checklist

- [ ] 確認事故嚴重性等級（參考第 1 節）
- [ ] 建立事故通訊頻道（Slack Channel: `#incident-YYYYMMDD`）
- [ ] 指定 Incident Commander
- [ ] 通知相關人員（參考第 2 節升級路徑）
- [ ] 開始填寫事故時間軸（第 5 節）

### 診斷 Checklist

- [ ] 確認問題發生時間點與觸發事件（最近部署？配置變更？）
- [ ] 檢查 Golden Signals（Latency / Traffic / Errors / Saturation）
- [ ] 查看相關服務日誌（錯誤訊息、異常堆疊）
- [ ] 確認基礎設施狀態（資料庫、快取、外部依賴）
- [ ] 確認影響範圍（哪些使用者、哪些功能、哪些地區）

### 緩解與修復 Checklist

- [ ] 評估是否啟動回滾（若為最近部署所致）
- [ ] 評估是否啟動降級模式（Graceful Degradation）
- [ ] 執行緩解措施（填入具體步驟）：
  - 步驟 1：[填入具體操作]
  - 步驟 2：[填入具體操作]
  - 步驟 3：[填入具體操作]
- [ ] 驗證 Golden Signals 恢復正常
- [ ] 驗證關鍵功能運作正常（End-to-End 冒煙測試）

### 事故解除 Checklist

- [ ] Golden Signals 全部恢復基線水準（持續 > 10 分鐘）
- [ ] 關鍵功能驗證通過
- [ ] 通知所有相關人員事故解除
- [ ] 更新外部狀態頁面（如適用）
- [ ] 安排 Post-mortem 會議（SEV-1/SEV-2 必須在 48 小時內進行）
- [ ] 建立 Post-mortem 文件（參考 `docs/templates/post-mortem-template.md`）

---

## 5. 時間軸模板 (Timeline Template)

> 填寫原則：每個重要事件都應記錄。時間使用 UTC+8，格式 HH:MM。

| 時間 | 事件描述 | 執行人 | 系統/服務 |
|------|---------|--------|---------|
| HH:MM | 事故初次偵測（監控告警 / 使用者回報） | [姓名] | [系統] |
| HH:MM | 事故確認，嚴重性判定為 SEV-X | [姓名] | — |
| HH:MM | 開始診斷 | [姓名] | [系統] |
| HH:MM | [根因診斷 / 緩解措施記錄點] | [姓名] | [系統] |
| HH:MM | 緩解措施執行 | [姓名] | [系統] |
| HH:MM | 服務恢復正常，監控確認 | [姓名] | [系統] |
| HH:MM | 事故正式解除宣告 | [姓名] | — |

---

## 相關資源

- Post-mortem 模板：`docs/templates/post-mortem-template.md`
- Deployment Readiness SKILL：`skills/deployment-readiness/SKILL.md`
- Golden Signals 監控 Checklist：`skills/deployment-readiness/SKILL.md` §6
- SLO/SLI 指標：`skills/deployment-readiness/SKILL.md` §7
