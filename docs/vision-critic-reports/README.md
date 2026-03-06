# Vision Critic 退件報告儲存規範

**關聯 Story**：US-128（Issue #131）
**關聯 SKILL.md**：`skills/vision-critic/SKILL.md` §10（退件報告自動儲存）
**關聯 ADR**：ADR-014（三層 Agent 分工架構）、ADR-014 OQ-3（通過閾值量化）

---

## 1. 儲存路徑規則（AC1）

退件報告（verdict 為 `FAIL` 或 `CONDITIONAL_PASS`）自動儲存至以下路徑：

```
docs/vision-critic-reports/YYYY-MM-DD-{story-id}.json
```

### 路徑規則說明

| 欄位 | 格式 | 範例 |
|------|------|------|
| `YYYY-MM-DD` | ISO 8601 日期（UTC+8） | `2026-03-06` |
| `{story-id}` | User Story ID，全小寫，連字號分隔 | `us-128` |
| 副檔名 | `.json` | — |

### 路徑範例

```
docs/vision-critic-reports/2026-03-06-us-128.json
docs/vision-critic-reports/2026-03-10-us-135.json
docs/vision-critic-reports/2026-03-12-us-111.json
```

### 多次退件命名規則

同一 Story 同一天發生多次退件（最多 3 次）時，以 `-retry{N}` 後綴區分：

```
docs/vision-critic-reports/2026-03-06-us-128.json          # 第 1 次（retryCount: 0）
docs/vision-critic-reports/2026-03-06-us-128-retry1.json   # 第 2 次（retryCount: 1）
docs/vision-critic-reports/2026-03-06-us-128-retry2.json   # 第 3 次（retryCount: 2）
```

---

## 2. 退件報告 JSON 格式定義（AC2）

退件報告遵循 Vision Critic Agent SKILL.md §8 定義的 Visual Review Report（VRR）JSON Schema（`https://shikigami.dev/schemas/vrr/v1`）。退件報告必須包含以下三個核心區塊：

### 2.1 評分詳情（Score Details）

| 欄位 | 類型 | 說明 |
|------|------|------|
| `colorConsistencyScore` | integer (0–100) | 色彩一致性維度分數（權重 40%） |
| `componentPositionScore` | integer (0–100) | 元件位置維度分數（權重 35%） |
| `spacingComplianceScore` | integer (0–100) | 間距合規性維度分數（權重 25%） |
| `totalScore` | number (0–100) | 加權總分（色彩×0.40 + 位置×0.35 + 間距×0.25） |
| `verdict` | string | 審查判定（`FAIL` 或 `CONDITIONAL_PASS`） |

### 2.2 失敗維度（Failure Dimensions）

退件報告必須包含至少一個以下維度的具體發現（Findings）：

| 欄位 | 說明 |
|------|------|
| `hardGateViolations` | Hard Gate 強制失敗清單（HG-1 WCAG 對比度、HG-2 邊框對比度、HG-3 必要元件缺失） |
| `colorConsistencyFindings` | 色彩一致性維度具體發現（維度分 < 70 時必填） |
| `componentPositionFindings` | 元件位置維度具體發現（維度分 < 70 時必填） |
| `spacingComplianceFindings` | 間距合規性維度具體發現（維度分 < 70 時必填） |

每個 Finding 包含：`severity`（critical / major / minor）、`description`（問題描述含數值）、`expectedValue`（期望值）、`observedValue`（觀測到的實際值）。

### 2.3 改善建議（Improvement Suggestions）

退件報告必須包含 `improvementSuggestions` 陣列，每筆建議包含：

| 欄位 | 說明 |
|------|------|
| `priority` | 優先級（`critical` / `major` / `minor`） |
| `targetComponentId` | 對應 SSD 中的元件 ID |
| `suggestion` | 具體改善建議（含 Design Token 名稱或 WCAG 標準值） |

---

## 3. 退件報告範例

### FAIL 案例（含 Hard Gate 違規）

```json
{
  "$schema": "https://shikigami.dev/schemas/vrr/v1",
  "metadata": {
    "reviewId": "vrr-20260306-us128-001",
    "storyId": "US-128",
    "retryCount": 0,
    "reviewedAt": "2026-03-06T10:30:00+08:00",
    "visionCriticVersion": "v1.0.0",
    "screenshotViewport": "1280x720"
  },
  "verdict": "FAIL",
  "colorConsistencyScore": 42,
  "componentPositionScore": 78,
  "spacingComplianceScore": 72,
  "totalScore": 62.0,
  "hardGateViolations": [
    {
      "gateId": "HG-1",
      "description": "submit-button 文字（#ffffff）對背景（#93c5fd）對比度 2.1:1，低於 WCAG 2.1 AA 要求的 4.5:1",
      "wcagReference": "WCAG 2.1 AA SC 1.4.3",
      "affectedComponentId": "submit-button"
    }
  ],
  "colorConsistencyFindings": [
    {
      "severity": "critical",
      "affectedComponentId": "submit-button",
      "description": "按鈕背景色使用 hardcode #93c5fd，應改用 Design Token color.primary.600（#2563eb），對比度可提升至 6.4:1",
      "expectedValue": "color.primary.600 (#2563eb)",
      "observedValue": "#93c5fd"
    }
  ],
  "improvementSuggestions": [
    {
      "priority": "critical",
      "targetComponentId": "submit-button",
      "suggestion": "將按鈕背景色改為 Design Token color.primary.600（對應 Tailwind class bg-primary-600），可確保對比度 ≥ 4.5:1，解除 HG-1 Hard Gate"
    }
  ]
}
```

### CONDITIONAL_PASS 案例（無 Hard Gate，改善建議為可選）

```json
{
  "$schema": "https://shikigami.dev/schemas/vrr/v1",
  "metadata": {
    "reviewId": "vrr-20260306-us128-002",
    "storyId": "US-128",
    "retryCount": 0,
    "reviewedAt": "2026-03-06T14:00:00+08:00",
    "visionCriticVersion": "v1.0.0",
    "screenshotViewport": "1280x720"
  },
  "verdict": "CONDITIONAL_PASS",
  "colorConsistencyScore": 80,
  "componentPositionScore": 75,
  "spacingComplianceScore": 70,
  "totalScore": 75.5,
  "hardGateViolations": [],
  "componentPositionFindings": [
    {
      "severity": "minor",
      "affectedComponentId": "nav-menu",
      "description": "導航選單水平對齊偏移 6px，略超過建議值（≤ 4px），但在可接受容忍範圍（≤ 8px）內",
      "expectedValue": "對齊偏移 ≤ 4px",
      "observedValue": "6px 偏移"
    }
  ],
  "improvementSuggestions": [
    {
      "priority": "minor",
      "targetComponentId": "nav-menu",
      "suggestion": "將導航選單的 margin-left 改用 spacing.1（4px），消除 6px 偏移，使版面更精確對齊 SSD 規格"
    }
  ]
}
```

---

## 4. 儲存觸發條件

| verdict | 自動儲存 | 說明 |
|---------|---------|------|
| `PASS` | 否 | PASS 結果不產生退件報告 |
| `CONDITIONAL_PASS` | 是 | 條件通過仍儲存報告，供後續追蹤改善 |
| `FAIL` | 是 | 強制儲存，作為 UI Agent 修正依據 |

---

## 5. 報告保留策略

- 退件報告以 git 方式版本控制（commit 至 repo）
- 同一 Story 的全部重試報告均保留（最多 3 份 + 1 份初始）
- 報告作為管線可追溯性的永久記錄，不自動清除
- `.gitignore` 中不排除此目錄（有意識納入版本控制）
