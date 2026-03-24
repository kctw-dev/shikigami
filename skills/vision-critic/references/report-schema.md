# Vision Critic — 審查報告 Schema 與儲存規範

> 參照自 `skills/vision-critic/SKILL.md` §8 + §10

---

## §8 審查報告 JSON Schema

### 8.1 Schema 定義

Vision Critic Agent 的輸出為**視覺審查報告（Visual Review Report，VRR）**。Schema 定義見 `schemas/vision-critic-report.json`（VRR v2）。

### 8.2 審查報告輸出範例

#### PASS 案例

```json
{
  "$schema": "https://shikigami.dev/schemas/vrr/v2",
  "metadata": {
    "reviewId": "VCR-US-151-20260306T103000Z",
    "storyId": "US-151",
    "frameId": "123:456",
    "frameName": "US-151-VisionCritic-Desktop",
    "retryCount": 0,
    "reviewedAt": "2026-03-06T10:30:00+08:00",
    "visionCriticVersion": "v2.0.0"
  },
  "verdict": "PASS",
  "layoutConsistencyScore": 88,
  "designTokenComplianceScore": 92,
  "componentSpecComplianceScore": 85,
  "totalScore": 89.45,
  "hardGateViolations": [],
  "passedChecks": [
    "主 Frame 設定 VERTICAL Auto Layout，符合 Desktop Frame 規格",
    "所有主要元件顏色屬性已綁定 Figma Variable",
    "Button/Primary、Input/Default、Card/Default 均使用 Component Instance",
    "間距值完全對應 Spacing Scale 允許值清單"
  ]
}
```

#### FAIL 案例（含 Hard Gate 違規）

```json
{
  "$schema": "https://shikigami.dev/schemas/vrr/v2",
  "metadata": {
    "reviewId": "VCR-US-151-20260306T110000Z",
    "storyId": "US-151",
    "frameId": "123:456",
    "retryCount": 1,
    "reviewedAt": "2026-03-06T11:00:00+08:00",
    "visionCriticVersion": "v2.0.0"
  },
  "verdict": "FAIL",
  "layoutConsistencyScore": 72,
  "designTokenComplianceScore": 35,
  "componentSpecComplianceScore": 85,
  "totalScore": 60.45,
  "hardGateViolations": [
    {
      "gateId": "HG-1",
      "description": "無任何節點綁定 Figma Variable",
      "requiredAction": "為主要元件套用 Variable 綁定（如 Button 背景色綁定 color/primary/500）"
    }
  ],
  "designTokenComplianceFindings": [
    {
      "severity": "ERROR",
      "affectedNode": "Button/Primary",
      "description": "背景色為 hardcode #3b82f6，未綁定 Variable color/primary/500",
      "expectedValue": "Variable: color/primary/500",
      "actualValue": "#3b82f6（hardcode）"
    }
  ],
  "recommendations": [
    {
      "priority": "HIGH",
      "isRequired": true,
      "dimension": "designTokenCompliance",
      "action": "為 Button/Primary 的 fills 屬性套用 Variable 綁定 color/primary/500"
    }
  ]
}
```

---

## §10 退件報告自動儲存行為（US-128，保留策略 US-212 更新）

### 10.1 概述

Vision Critic Agent 在審查結果為 `FAIL` 或 `CONDITIONAL_PASS` 時，**自動將結構化退件報告（VRR JSON）儲存至本地檔案系統**，提供管線可追溯性與修正依據。

### 10.2 儲存路徑規則

```
docs/vision-critic-reports/YYYY-MM-DD-{story-id}.json
```

**多次退件命名規則**（同一 Story 同一天）：

```
docs/vision-critic-reports/2026-03-06-us-151.json          # retryCount: 0（首次）
docs/vision-critic-reports/2026-03-06-us-151-retry1.json   # retryCount: 1
docs/vision-critic-reports/2026-03-06-us-151-retry2.json   # retryCount: 2
```

**重要**：VRR JSON 報告檔案已列入 `.gitignore`（`docs/vision-critic-reports/*.json`），**不納入 git 版本控制**。詳見 §10.4 保留策略。

### 10.3 儲存觸發條件

| verdict | 自動儲存 | 說明 |
|---------|---------|------|
| `PASS` | 否 | PASS 結果無需退件報告 |
| `CONDITIONAL_PASS` | 是 | 條件通過仍儲存，供後續追蹤改善建議 |
| `FAIL` | 是 | 強制儲存，作為下一輪修正的輸入 |

### 10.4 報告保留策略（ADR-016 OQ-5 決策，US-212，2026-03-11）

**採用策略：.gitignore 排除 VRR JSON 報告本體 + 90 天本地保留期限建議**

| 策略項目 | 說明 |
|---------|------|
| git 追蹤 | **不納入**：`docs/vision-critic-reports/*.json` 列入 `.gitignore`，VRR JSON 報告本體不 commit |
| 本地保留期限 | **90 天建議**：超過 90 天的 VRR 報告可由開發者手動清理（指令見下） |
| 目錄結構 | **納入 git**：`docs/vision-critic-reports/` 目錄與 `README.md` 仍版本控制，確保路徑規範可追蹤 |
| 外部儲存 | **延後**：框架現階段（v0.50.x）無雲端基礎設施；待有實際消費端專案且跨 Sprint 審計需求確立後，透過新 ADR 引入 GCS/S3 |

**本地清理指令**（90 天期限）：

```bash
# 清理 90 天前的 VRR 報告（macOS/Linux）
find docs/vision-critic-reports/ -name "*.json" -mtime +90 -delete
```

**決策理由**：VRR JSON 允許嵌入 Base64 截圖（單份 5–15 MB），每 Sprint 若有 3–5 個 DESIGN Story，90 天將累積 165–825 MB，造成 repo 膨脹。外部儲存在 doc-only 框架階段為過早引入。完整決策記錄見 `docs/vision-critic-reports/README.md` §5。
