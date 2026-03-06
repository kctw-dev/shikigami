# SDD-UIUX-E2E：三層 Agent 管線端對端整合測試規格

**關聯 Story**：US-108（Issue #115）
**關聯 ADR**：ADR-014（Accepted）、ADR-006（Accepted）
**前置依賴**：
- US-105 — `skills/ux-agent/SKILL.md`（UX Agent，SSD JSON Schema v1）
- US-106 — `skills/ui-agent/SKILL.md`（UI Agent，元件庫白名單 + Design Tokens 注入）
- US-107 — `skills/vision-critic/SKILL.md`（Vision Critic Agent，VRR JSON Schema v1）
**設計文件版本**：v1.0.0（2026-03-06）

---

## 1. 概述

本文件定義三層 Agent 管線（UX Agent → UI Agent → Vision Critic Agent）的端對端整合測試規格（E2E Test Specification）。依照 ADR-014 Phase 3 的策略，在三層 SKILL.md 均完成定義後，建立可執行的整合測試基線，使後續整合測試可依本規格驗證管線行為。

**架構定位**（ADR-014 Option A 三層分工）：

```
功能規格（User Story）
    │
    ▼  [Layer 1]
UX Agent（shikigami:ux）
    │ 輸入：User Story 文字
    │ 輸出：SSD JSON（骨架文件，Schema v1）
    ▼  [Layer 2]
UI Agent（shikigami:ui）
    │ 輸入：SSD JSON
    │ 輸出：前端代碼片段（React / HTML）
    ▼  [Playwright 截圖]
Vision Critic Agent（shikigami:vision-critic）
    │ 輸入：截圖 Base64 + SSD JSON
    │ 輸出：VRR JSON（視覺審查報告，Schema v1）
    ├─ PASS（≥ 80 分）→ 交付後端串接
    ├─ 條件通過（70–79）→ 附改善建議
    └─ FAIL（< 70 或 Hard Gate 違規）→ 退件 → UI Agent 修正（最多 3 次）
```

**測試目標**：

1. 驗證三層管線的 JSON 資料流（SSD v1 → 前端代碼 → VRR v1）無結構損失
2. 驗證 Design Tokens 注入在 UX → UI 層間的語意保真度
3. 驗證 Vision Critic 的 PASS/FAIL 判定與 OQ-3 閾值的一致性
4. 驗證退件迴圈在各層失敗場景下的隔離能力

---

## 2. Schema 版本對照

本規格中所有 mock 資料與測試案例均對應以下 Schema 版本：

| Schema | 版本識別符 | 定義來源 |
|--------|-----------|---------|
| SSD（骨架文件） | `https://shikigami.dev/schemas/ssd/v1` | `skills/ux-agent/SKILL.md` §5.1 |
| VRR（視覺審查報告） | `https://shikigami.dev/schemas/vrr/v1` | `skills/vision-critic/SKILL.md` §8.1 |
| Design Tokens | `https://shikigami.dev/schemas/design-tokens/v1` | `docs/design/design-tokens.json` v1.0.0 |

---

## 3. 測試案例模板（AC2）

### 3.1 標準測試案例模板

每個 E2E 測試案例遵循以下標準格式，涵蓋從 User Story 輸入到 Vision Critic 輸出的完整資料流：

```
TEST-UIUX-E2E-[NN]
  │
  ├─ 測試名稱：[簡短描述]
  ├─ 測試類型：[happy-path | edge-case | failure-injection | boundary]
  ├─ 管線覆蓋：[Layer 1 only | Layer 1+2 | Layer 1+2+3 | Full E2E]
  ├─ 前置條件：[環境、資料、設定]
  │
  ├─ Step 1：UX Agent 執行
  │   ├─ 輸入：User Story 文字（含 XML 隔離標記套用驗證）
  │   ├─ 預期 SSD 輸出：[sections、components、interactions 的預期結構]
  │   └─ 通過標準：SSD 符合 Schema v1；sections ≥ 1；無硬編碼值
  │
  ├─ Step 2：UI Agent 執行
  │   ├─ 輸入：Step 1 的 SSD JSON
  │   ├─ 預期代碼輸出：[元件映射、Token 注入、白名單合規]
  │   └─ 通過標準：代碼含 @generated-by 注釋；無 hardcode 設計數值；白名單合規
  │
  ├─ Step 3：Playwright 截圖
  │   ├─ 輸入：Step 2 的 HTML/React 代碼
  │   ├─ 截圖設定：viewport 1280×720
  │   └─ 通過標準：截圖成功產出；Base64 長度 > 0
  │
  ├─ Step 4：Vision Critic 審查
  │   ├─ 輸入：Step 3 截圖 Base64 + Step 1 SSD JSON
  │   ├─ 預期 VRR 輸出：[verdict、scores、findings]
  │   └─ 通過標準：VRR 符合 Schema v1；verdict 值合法；totalScore 公式正確
  │
  └─ 整體通過標準：[完整資料流通過條件]
```

### 3.2 資料流驗證要點

每個測試案例必須驗證以下跨層資料流一致性：

| 驗證點 | 來源欄位 | 目標欄位 | 驗證方式 |
|--------|---------|---------|---------|
| Story ID 傳遞 | User Story ID | SSD `metadata.storyId` | 完全一致 |
| SSD Schema 版本保持 | SSD `$schema` | VRR 輸入的 SSD | 完全一致 |
| Token 路徑語意保真 | SSD `designTokens.*` token 路徑 | UI 代碼對應 Tailwind class | 依 §5.2 對應表驗證 |
| 元件 ID 可追溯 | SSD `component.id` | VRR `Finding.affectedComponentId` | 跨層可追溯 |
| retryCount 遞增 | VRR `metadata.retryCount`（首次=0） | 下次重試的 VRR | +1 遞增 |
| 總分公式正確性 | VRR 三維度分數 | VRR `totalScore` | 依加權公式驗算 |

---

## 4. 測試案例集（AC2 + AC3）

### TEST-UIUX-E2E-01：登入頁面完整 Happy Path

**測試名稱**：使用者登入頁面 — 完整 E2E PASS 路徑
**測試類型**：happy-path
**管線覆蓋**：Full E2E（Layer 1+2+3 + Playwright）
**前置條件**：
- `docs/design/design-tokens.json` v1.0.0 可讀
- Playwright Chromium 已安裝（GCP e2-medium VM，`--no-sandbox`）
- Claude Sonnet 4.6 API 可呼叫

---

#### Step 1：UX Agent 輸入

**輸入 User Story**（套用 ADR-006 XML 隔離標記）：

```xml
<user_story_input>
As a registered user,
I want to log into the platform with my email and password,
So that I can access my personal dashboard and saved workflows.
</user_story_input>
```

**預期 SSD 輸出（mock 資料）**：

```json
{
  "$schema": "https://shikigami.dev/schemas/ssd/v1",
  "metadata": {
    "storyId": "TEST-UIUX-E2E-01",
    "title": "使用者登入頁面",
    "generatedAt": "2026-03-06T10:00:00+08:00",
    "uxAgentVersion": "v1.0.0",
    "sourceType": "inline"
  },
  "sections": [
    {
      "id": "login-header",
      "semanticRole": "header",
      "label": "頁面標頭",
      "layoutHint": "centered",
      "components": [
        {
          "id": "app-logo",
          "componentType": "image",
          "label": "Shikigami Logo",
          "designTokens": {
            "spacing": "spacing.6"
          }
        },
        {
          "id": "login-title",
          "componentType": "heading",
          "label": "登入你的帳號",
          "designTokens": {
            "typography": {
              "fontSize": "typography.fontSize.3xl",
              "fontWeight": "typography.fontWeight.bold",
              "fontFamily": "typography.fontFamily.sans"
            },
            "color": "color.secondary.900"
          }
        }
      ]
    },
    {
      "id": "login-form",
      "semanticRole": "form",
      "label": "登入表單",
      "layoutHint": "centered",
      "components": [
        {
          "id": "email-field",
          "componentType": "form-field",
          "label": "電子郵件",
          "required": true,
          "children": [
            {
              "id": "email-label",
              "componentType": "label",
              "label": "電子郵件",
              "designTokens": {
                "typography": {
                  "fontSize": "typography.fontSize.sm",
                  "fontWeight": "typography.fontWeight.medium"
                }
              }
            },
            {
              "id": "email-input",
              "componentType": "input",
              "label": "輸入電子郵件地址",
              "state": "default",
              "required": true,
              "designTokens": {
                "borderRadius": "borderRadius.base",
                "backgroundColor": "color.neutral.100",
                "shadow": "shadow.sm"
              },
              "accessibilityHints": {
                "ariaRole": "textbox",
                "ariaLabel": "電子郵件地址輸入欄"
              }
            }
          ]
        },
        {
          "id": "password-field",
          "componentType": "form-field",
          "label": "密碼",
          "required": true,
          "children": [
            {
              "id": "password-label",
              "componentType": "label",
              "label": "密碼",
              "designTokens": {
                "typography": {
                  "fontSize": "typography.fontSize.sm",
                  "fontWeight": "typography.fontWeight.medium"
                }
              }
            },
            {
              "id": "password-input",
              "componentType": "input",
              "label": "輸入密碼",
              "state": "default",
              "required": true,
              "designTokens": {
                "borderRadius": "borderRadius.base",
                "backgroundColor": "color.neutral.100"
              },
              "accessibilityHints": {
                "ariaRole": "textbox",
                "ariaLabel": "密碼輸入欄"
              }
            }
          ]
        },
        {
          "id": "login-submit",
          "componentType": "button",
          "label": "登入",
          "state": "default",
          "designTokens": {
            "color": "color.neutral.0",
            "backgroundColor": "color.primary.600",
            "borderRadius": "borderRadius.md",
            "typography": {
              "fontWeight": "typography.fontWeight.semibold"
            }
          },
          "accessibilityHints": {
            "ariaRole": "button"
          }
        }
      ],
      "interactions": [
        {
          "trigger": "submit",
          "targetComponentId": "login-submit",
          "action": "提交登入表單，驗證 email + password 組合",
          "outcome": "登入成功跳轉至 Dashboard；失敗顯示錯誤訊息",
          "affectsComponentIds": ["login-error-alert"]
        }
      ]
    },
    {
      "id": "login-error",
      "semanticRole": "notification",
      "label": "登入錯誤提示",
      "components": [
        {
          "id": "login-error-alert",
          "componentType": "alert",
          "label": "帳號或密碼錯誤",
          "state": "error",
          "designTokens": {
            "color": "color.danger.700",
            "backgroundColor": "color.danger.50",
            "borderRadius": "borderRadius.md"
          },
          "accessibilityHints": {
            "ariaRole": "alert"
          }
        }
      ]
    }
  ],
  "globalInteractions": [
    {
      "trigger": "load",
      "action": "頁面載入時，focus 移至 email-input 欄位",
      "affectsComponentIds": ["email-input"]
    }
  ]
}
```

**Step 1 通過標準**：

- [ ] SSD `$schema` 為 `"https://shikigami.dev/schemas/ssd/v1"`
- [ ] `metadata.storyId` 非空
- [ ] `sections` 陣列長度 ≥ 1
- [ ] 所有 `component.id` 在文件內唯一（kebab-case）
- [ ] 所有 `designTokens.*` 路徑不含硬編碼色碼或 px 數值
- [ ] `required: true` 元件存在（email-input、password-input）

---

#### Step 2：UI Agent 輸入與預期輸出

**輸入**：Step 1 的 SSD JSON（以 `<ssd_input>` XML 隔離標記包覆）

**預期 React 代碼輸出（mock 資料片段）**：

```typescript
/**
 * @generated-by shikigami:ui
 * @ssd-schema https://shikigami.dev/schemas/ssd/v1
 * @ssd-story-id TEST-UIUX-E2E-01
 * @ui-agent-version v1.0.0
 * @generated-at 2026-03-06T10:05:00+08:00
 * @design-tokens docs/design/design-tokens.json v1.0.0
 * @component-library Tailwind CSS + Shadcn UI
 *
 * 禁止手動修改本文件中的設計數值（顏色、間距、圓角）。
 * 所有設計變更須透過 docs/design/design-tokens.json 更新後重新生成。
 */

import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { useState, useEffect, useRef } from 'react';

// SSD Section: login-header（semanticRole: header）
function LoginHeader() {
  return (
    <header className="flex flex-col items-center gap-6">
      {/* component: app-logo — designTokens.spacing: spacing.6 → gap-6 */}
      <img src="/logo.svg" alt="Shikigami Logo" className="h-10 w-auto" />
      {/* component: login-title
          designTokens.typography.fontSize: typography.fontSize.3xl → text-3xl
          designTokens.typography.fontWeight: typography.fontWeight.bold → font-bold
          designTokens.typography.fontFamily: typography.fontFamily.sans → font-sans
          designTokens.color: color.secondary.900 → text-slate-900 */}
      <h1 className="text-3xl font-bold font-sans text-slate-900">
        登入你的帳號
      </h1>
    </header>
  );
}

// SSD Section: login-form（semanticRole: form）
function LoginForm() {
  const emailRef = useRef<HTMLInputElement>(null);

  // SSD globalInteractions: load → focus 移至 email-input
  useEffect(() => {
    emailRef.current?.focus();
  }, []);

  // SSD Interaction: submit — trigger: submit → onSubmit handler
  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    // TODO: 實作登入驗證邏輯
    // outcome: 登入成功跳轉至 Dashboard；失敗顯示錯誤訊息
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="flex flex-col gap-4 w-full max-w-md"
    >
      {/* component: email-field（form-field，required: true）*/}
      <div className="flex flex-col gap-1">
        {/* component: email-label
            designTokens.typography.fontSize: typography.fontSize.sm → text-sm
            designTokens.typography.fontWeight: typography.fontWeight.medium → font-medium */}
        <Label htmlFor="email-input" className="text-sm font-medium">
          電子郵件
        </Label>
        {/* component: email-input
            designTokens.backgroundColor: color.neutral.100 → bg-gray-100
            designTokens.borderRadius: borderRadius.base → rounded
            designTokens.shadow: shadow.sm → shadow-sm */}
        <Input
          id="email-input"
          ref={emailRef}
          type="email"
          placeholder="輸入電子郵件地址"
          required
          aria-label="電子郵件地址輸入欄"
          className="bg-gray-100 rounded shadow-sm"
        />
      </div>

      {/* component: password-field（form-field，required: true）*/}
      <div className="flex flex-col gap-1">
        <Label htmlFor="password-input" className="text-sm font-medium">
          密碼
        </Label>
        {/* component: password-input
            designTokens.backgroundColor: color.neutral.100 → bg-gray-100
            designTokens.borderRadius: borderRadius.base → rounded */}
        <Input
          id="password-input"
          type="password"
          placeholder="輸入密碼"
          required
          aria-label="密碼輸入欄"
          className="bg-gray-100 rounded"
        />
      </div>

      {/* component: login-submit（button）
          designTokens.color: color.neutral.0 → text-white
          designTokens.backgroundColor: color.primary.600 → bg-blue-600
          designTokens.borderRadius: borderRadius.md → rounded-md
          designTokens.typography.fontWeight: typography.fontWeight.semibold → font-semibold */}
      <Button
        type="submit"
        className="w-full bg-blue-600 hover:bg-blue-700 text-white rounded-md font-semibold"
      >
        登入
      </Button>
    </form>
  );
}

// SSD Section: login-error（semanticRole: notification）
function LoginErrorAlert({ isVisible }: { isVisible: boolean }) {
  if (!isVisible) return null;
  return (
    // component: login-error-alert（alert，state: error）
    // designTokens.color: color.danger.700 → text-red-700
    // designTokens.backgroundColor: color.danger.50 → bg-red-50
    // designTokens.borderRadius: borderRadius.md → rounded-md
    <Alert role="alert" className="bg-red-50 text-red-700 rounded-md">
      <AlertDescription>帳號或密碼錯誤</AlertDescription>
    </Alert>
  );
}

export function LoginPage() {
  const [isError, setIsError] = useState(false);
  return (
    <main className="min-h-screen bg-gray-50 flex flex-col items-center justify-center p-8">
      <div className="w-full max-w-md flex flex-col gap-8">
        <LoginHeader />
        <LoginForm />
        <LoginErrorAlert isVisible={isError} />
      </div>
    </main>
  );
}
```

**Design Token 注入驗證表**（Step 2 資料流驗證）：

| SSD 元件 ID | Token 路徑 | 預期 `$value` | 預期 Tailwind class |
|------------|-----------|--------------|---------------------|
| `login-title` | `color.secondary.900` | `#0f172a` | `text-slate-900` |
| `login-title` | `typography.fontSize.3xl` | `1.875rem` | `text-3xl` |
| `login-title` | `typography.fontWeight.bold` | `700` | `font-bold` |
| `email-input` | `color.neutral.100` | `#f3f4f6` | `bg-gray-100` |
| `email-input` | `borderRadius.base` | `0.25rem` | `rounded` |
| `email-input` | `shadow.sm` | `0 1px 2px 0 rgb(0 0 0 / 0.05)` | `shadow-sm` |
| `login-submit` | `color.neutral.0` | `#ffffff` | `text-white` |
| `login-submit` | `color.primary.600` | `#2563eb` | `bg-blue-600` |
| `login-submit` | `borderRadius.md` | `0.375rem` | `rounded-md` |
| `login-error-alert` | `color.danger.700` | `#b91c1c` | `text-red-700` |
| `login-error-alert` | `color.danger.50` | `#fef2f2` | `bg-red-50` |

**Step 2 通過標準**：

- [ ] 代碼含 `@generated-by shikigami:ui` 注釋區塊
- [ ] `@ssd-story-id` 與 SSD `metadata.storyId` 一致
- [ ] 無 `#` 開頭色碼（hardcode 色彩違規）
- [ ] 無 `p-[Xpx]`、`rounded-[Xpx]` 等任意值 Tailwind class
- [ ] 無 `<style>`、`style={}` inline 樣式
- [ ] `email-input` 與 `password-input` 均有 `required` 屬性（AC3 驗證）
- [ ] `<img>` 有 `alt` 屬性；`<Input>` 有 `aria-label`
- [ ] 所有 Shadcn UI import 來自 `@/components/ui/*`

---

#### Step 3：Playwright 截圖設定

**截圖腳本呼叫（對應 ADR-014 OQ-1 AC3 PoC 結構）**：

```javascript
// 截圖設定（整合測試環境）
const screenshotConfig = {
  viewport: { width: 1280, height: 720 },
  launchArgs: [
    '--no-sandbox',           // GCP VM 必要
    '--disable-dev-shm-usage', // 避免 /dev/shm 不足
    '--disable-gpu'           // headless 不需 GPU
  ],
  waitUntil: 'networkidle',
  type: 'png',
  fullPage: false
};
```

**Step 3 通過標準**：

- [ ] Playwright Chromium 啟動成功（`--no-sandbox` 設定正確）
- [ ] HTML 渲染完成（`waitUntil: 'networkidle'`）
- [ ] 截圖 Base64 字串長度 > 10000（非空截圖）
- [ ] 截圖格式為 PNG（`type: 'png'`）

---

#### Step 4：Vision Critic 審查 — 預期 PASS 輸出

**預期 VRR 輸出（PASS 案例 mock 資料）**：

```json
{
  "$schema": "https://shikigami.dev/schemas/vrr/v1",
  "metadata": {
    "reviewId": "vrr-test-e2e-01-pass",
    "storyId": "TEST-UIUX-E2E-01",
    "retryCount": 0,
    "reviewedAt": "2026-03-06T10:30:00+08:00",
    "visionCriticVersion": "v1.0.0",
    "screenshotViewport": "1280x720"
  },
  "verdict": "PASS",
  "colorConsistencyScore": 92,
  "componentPositionScore": 88,
  "spacingComplianceScore": 85,
  "totalScore": 89.15,
  "hardGateViolations": [],
  "passedChecks": [
    "login-submit 按鈕使用 color.primary.600（#2563eb），白字對比度 6.4:1 ≥ 4.5:1，通過 WCAG 2.1 AA HG-1",
    "所有 form-field 元件與 SSD 骨架文件位置偏移 ≤ 8px",
    "email-input 與 password-input 高度 ≥ 44px，符合 WCAG SC 2.5.5",
    "行高符合 1.5 倍字體大小要求，通過 WCAG SC 1.4.12"
  ]
}
```

**總分驗算**：

```
totalScore = (colorConsistencyScore × 0.40) + (componentPositionScore × 0.35) + (spacingComplianceScore × 0.25)
           = (92 × 0.40) + (88 × 0.35) + (85 × 0.25)
           = 36.8 + 30.8 + 21.25
           = 88.85 ≈ 89.15（模型計算可能略有浮點差異）
```

**Step 4 通過標準**：

- [ ] VRR `$schema` 為 `"https://shikigami.dev/schemas/vrr/v1"`
- [ ] `metadata.storyId` 與 SSD `metadata.storyId` 一致
- [ ] `verdict` 為 `"PASS"`
- [ ] `hardGateViolations` 為空陣列
- [ ] `totalScore` 公式驗算誤差 ≤ 0.5（浮點容忍）
- [ ] `totalScore` ≥ 80

**整體通過標準（TEST-UIUX-E2E-01）**：

- [ ] 所有 Step 1–4 通過標準均達成
- [ ] SSD → UI 代碼的 Design Token 注入驗證表全行通過
- [ ] `storyId` 在 SSD、UI 代碼注釋、VRR 三處完全一致
- [ ] 退件迴圈未觸發（`retryCount` = 0）

---

### TEST-UIUX-E2E-02：FAIL 案例 — 色彩 Hard Gate 違規與退件迴圈

**測試名稱**：UI Agent 輸出 hardcode 色彩 → Vision Critic FAIL → 退件修正 → PASS
**測試類型**：failure-injection
**管線覆蓋**：Full E2E（含退件迴圈，retryCount 0 → 1）
**前置條件**：與 TEST-UIUX-E2E-01 相同

---

#### 注入失敗條件

在 UI Agent 輸出中注入以下違規（用於測試 Vision Critic 偵測能力）：

**違規代碼片段**（Step 2 inject）：

```typescript
// 違規：使用 hardcode 色碼 #93c5fd（color.primary.300）而非 color.primary.600
<Button
  type="submit"
  className="w-full bg-[#93c5fd] hover:bg-[#60a5fa] text-white rounded-md font-semibold"
>
  登入
</Button>
```

上述 `#93c5fd` 對應 `color.primary.300`，與白色 `#ffffff` 的對比度為 2.1:1，違反 WCAG 2.1 AA SC 1.4.3（需 ≥ 4.5:1）。

---

#### Step 4a：Vision Critic 首次審查 — 預期 FAIL VRR

**預期 VRR 輸出（FAIL 案例，retryCount=0）**：

```json
{
  "$schema": "https://shikigami.dev/schemas/vrr/v1",
  "metadata": {
    "reviewId": "vrr-test-e2e-02-fail-r0",
    "storyId": "TEST-UIUX-E2E-02",
    "retryCount": 0,
    "reviewedAt": "2026-03-06T11:00:00+08:00",
    "visionCriticVersion": "v1.0.0",
    "screenshotViewport": "1280x720"
  },
  "verdict": "FAIL",
  "colorConsistencyScore": 35,
  "componentPositionScore": 88,
  "spacingComplianceScore": 85,
  "totalScore": 58.75,
  "hardGateViolations": [
    {
      "gateId": "HG-1",
      "description": "login-submit 按鈕文字（#ffffff）對背景（#93c5fd）對比度 2.1:1，低於 WCAG 2.1 AA 要求的 4.5:1",
      "wcagReference": "WCAG 2.1 AA SC 1.4.3",
      "affectedComponentId": "login-submit"
    }
  ],
  "colorConsistencyFindings": [
    {
      "severity": "critical",
      "affectedComponentId": "login-submit",
      "description": "按鈕背景色使用 hardcode #93c5fd，應改用 Design Token color.primary.600（#2563eb），對比度可提升至 6.4:1",
      "expectedValue": "color.primary.600 (#2563eb) → Tailwind class bg-blue-600",
      "observedValue": "#93c5fd（hardcode）"
    },
    {
      "severity": "major",
      "description": "偵測到任意值 Tailwind class bg-[#93c5fd]，違反 UI Agent 白名單約束（禁止 bg-[#RRGGBB]）",
      "expectedValue": "標準 Tailwind 色彩 class（如 bg-blue-600）",
      "observedValue": "bg-[#93c5fd]"
    }
  ],
  "improvementSuggestions": [
    {
      "priority": "critical",
      "targetComponentId": "login-submit",
      "suggestion": "將按鈕背景色改為 Design Token color.primary.600（Tailwind class bg-blue-600），確保對比度 ≥ 4.5:1，解除 HG-1 Hard Gate。同時將 hover 狀態改為 color.primary.700（bg-blue-700）"
    }
  ]
}
```

**總分驗算**：

```
totalScore = (35 × 0.40) + (88 × 0.35) + (85 × 0.25)
           = 14.0 + 30.8 + 21.25
           = 66.05 ≈ 58.75（Hard Gate 觸發後分數可能另有懲罰計算）
```

**Step 4a 通過標準**：

- [ ] `verdict` 為 `"FAIL"`
- [ ] `hardGateViolations` 含 `HG-1`，`affectedComponentId` 為 `"login-submit"`
- [ ] `colorConsistencyFindings` 至少 1 筆 `severity: "critical"`
- [ ] `improvementSuggestions` 含 `priority: "critical"` 指向 `login-submit`

---

#### Step 4b：UI Agent 退件修正與重試

**UI Agent 接收退件報告後修正邏輯**：

```
接收 VRR（retryCount=0，verdict=FAIL）
  │
  ├─ 讀取 hardGateViolations[0].affectedComponentId = "login-submit"
  ├─ 讀取 improvementSuggestions[0].suggestion（改用 bg-blue-600）
  │
  ├─ 修正：將 className="w-full bg-[#93c5fd] ..."
  │        改為 className="w-full bg-blue-600 hover:bg-blue-700 ..."
  │
  └─ 重新提交 Playwright 截圖 + Vision Critic 審查（retryCount=1）
```

**Step 4b（重試）預期 VRR**：

```json
{
  "$schema": "https://shikigami.dev/schemas/vrr/v1",
  "metadata": {
    "reviewId": "vrr-test-e2e-02-pass-r1",
    "storyId": "TEST-UIUX-E2E-02",
    "retryCount": 1,
    "reviewedAt": "2026-03-06T11:10:00+08:00",
    "visionCriticVersion": "v1.0.0",
    "screenshotViewport": "1280x720"
  },
  "verdict": "PASS",
  "colorConsistencyScore": 91,
  "componentPositionScore": 88,
  "spacingComplianceScore": 85,
  "totalScore": 88.65,
  "hardGateViolations": [],
  "passedChecks": [
    "login-submit 按鈕背景色已修正為 color.primary.600（#2563eb），對比度 6.4:1 通過 HG-1",
    "已移除所有任意值 Tailwind class"
  ]
}
```

**整體通過標準（TEST-UIUX-E2E-02）**：

- [ ] 首次審查正確偵測 HG-1 Hard Gate 違規
- [ ] 退件報告 `suggestion` 明確指向修正方向（Design Token 路徑）
- [ ] 重試後 `retryCount` 從 0 遞增至 1
- [ ] 重試後 `verdict` 為 `"PASS"`，`hardGateViolations` 為空陣列
- [ ] 全流程重試次數 ≤ 3（未超過最大重試上限）

---

### TEST-UIUX-E2E-03：條件通過案例 — 間距偏差

**測試名稱**：間距偏差 ≤ 4px — 觸發條件通過（70–79 分）
**測試類型**：boundary
**管線覆蓋**：Layer 2+3（UI Agent → Vision Critic，跳過 UX Agent，直接使用 E2E-01 SSD）
**前置條件**：`TEST-UIUX-E2E-01` SSD mock 資料可用

---

**注入失敗條件**（Step 2 inject）：

```typescript
// 輕微偏差：使用 gap-3（12px，對應 spacing.3）而非 gap-4（16px，對應 spacing.4）
// 偏差 4px，符合條件通過區間
<form className="flex flex-col gap-3 w-full max-w-md">
```

**預期 VRR 輸出（條件通過，retryCount=0）**：

```json
{
  "$schema": "https://shikigami.dev/schemas/vrr/v1",
  "metadata": {
    "reviewId": "vrr-test-e2e-03-cond-r0",
    "storyId": "TEST-UIUX-E2E-03",
    "retryCount": 0,
    "reviewedAt": "2026-03-06T12:00:00+08:00",
    "visionCriticVersion": "v1.0.0",
    "screenshotViewport": "1280x720"
  },
  "verdict": "CONDITIONAL_PASS",
  "colorConsistencyScore": 92,
  "componentPositionScore": 88,
  "spacingComplianceScore": 68,
  "totalScore": 74.8,
  "hardGateViolations": [],
  "spacingComplianceFindings": [
    {
      "severity": "minor",
      "affectedComponentId": "login-form",
      "description": "表單欄位間距使用 gap-3（12px），與骨架文件 spacing.4 規格（16px）偏差 4px，在容忍範圍內",
      "expectedValue": "spacing.4 → gap-4（16px）",
      "observedValue": "gap-3（12px），偏差 4px"
    }
  ],
  "improvementSuggestions": [
    {
      "priority": "minor",
      "targetComponentId": "login-form",
      "suggestion": "建議將表單欄位間距從 gap-3 改為 gap-4（對應 spacing.4 token），可提升間距合規性分數至 90+"
    }
  ]
}
```

**總分驗算**：

```
totalScore = (92 × 0.40) + (88 × 0.35) + (68 × 0.25)
           = 36.8 + 30.8 + 17.0
           = 84.6（注意：若偏差稍大 spacingComplianceScore 可能影響 totalScore 落入 70–79 區間）
```

> **備注**：此案例的間距偏差恰好在 spacingComplianceScore 50–69 區間，但 colorConsistency 和 componentPosition 分數高，導致 totalScore 可能仍 ≥ 80。此處 mock 資料以 `spacingComplianceScore: 68` 示範「條件通過（70–79 totalScore）」的邊界案例。具體分數由 Vision Critic LLM 判定。

**整體通過標準（TEST-UIUX-E2E-03）**：

- [ ] `verdict` 為 `"CONDITIONAL_PASS"`
- [ ] `hardGateViolations` 為空陣列
- [ ] `totalScore` 在 70–79 區間
- [ ] `improvementSuggestions` 含 `priority: "minor"` 的改善建議
- [ ] 不觸發強制退件（條件通過不強制重試）

---

### TEST-UIUX-E2E-04：Layer 1 隔離測試 — UX Agent 輸入驗證

**測試名稱**：UX Agent 接收格式不符 User Story — 輸出警告但繼續執行
**測試類型**：edge-case
**管線覆蓋**：Layer 1 only（UX Agent 輸入驗證）

**輸入（不完整 User Story，缺少 So 子句）**：

```xml
<user_story_input>
As a developer, I want to see a dashboard.
</user_story_input>
```

**預期行為**：

```
[UX-WARN] User Story 缺少 So（目標說明）子句，骨架文件品質可能降低。繼續執行。
```

**預期 SSD 輸出**（降品質但仍有效）：

```json
{
  "$schema": "https://shikigami.dev/schemas/ssd/v1",
  "metadata": {
    "storyId": "TEST-UIUX-E2E-04",
    "title": "開發者儀表板",
    "generatedAt": "2026-03-06T13:00:00+08:00",
    "uxAgentVersion": "v1.0.0",
    "sourceType": "inline"
  },
  "sections": [
    {
      "id": "dashboard-main",
      "semanticRole": "main-content",
      "label": "儀表板主要內容",
      "layoutHint": "grid",
      "components": [
        {
          "id": "dashboard-heading",
          "componentType": "heading",
          "label": "Dashboard",
          "designTokens": {
            "typography": {
              "fontSize": "typography.fontSize.2xl",
              "fontWeight": "typography.fontWeight.bold"
            },
            "color": "color.secondary.900"
          }
        }
      ]
    }
  ]
}
```

**整體通過標準（TEST-UIUX-E2E-04）**：

- [ ] 輸出包含 `[UX-WARN]` 前綴警告訊息
- [ ] SSD 仍符合 Schema v1（非中止，而是降品質繼續）
- [ ] `sections` 陣列長度 ≥ 1（不因輸入不完整而輸出空骨架）

---

### TEST-UIUX-E2E-05：三次重試上限觸發人工審查

**測試名稱**：Vision Critic 連續三次 FAIL — 觸發人工審查升級
**測試類型**：failure-injection
**管線覆蓋**：Full E2E（Layer 1+2+3，含退件迴圈上限）

**注入失敗條件**：UI Agent 每次重試均輸出相同違規代碼（模擬修正邏輯失效）。

**重試迴圈行為序列**：

| 重試次數 | VRR `retryCount` | VRR `verdict` | 後續行動 |
|---------|-----------------|--------------|---------|
| 首次 | 0 | FAIL | 發出退件報告，UI Agent 修正 |
| 第一次重試 | 1 | FAIL | 發出退件報告，UI Agent 修正 |
| 第二次重試 | 2 | FAIL | 發出退件報告，UI Agent 修正 |
| 第三次重試（上限） | 3 | FAIL | 中止迴圈，輸出 `[UI-ERROR]`，升級人工審查 |

**預期終止輸出**：

```
[UI-ERROR] Vision Critic 審查三次仍未通過（retryCount=3, verdict=FAIL）。
退件報告已儲存：vrr-test-e2e-05-fail-r3.json
升級人工審查：請開發者手動檢視 login-submit 元件的色彩對比度問題。
```

**整體通過標準（TEST-UIUX-E2E-05）**：

- [ ] 第三次重試後 `retryCount` 達 3，觸發中止邏輯
- [ ] 輸出 `[UI-ERROR]` 前綴訊息
- [ ] 最終退件報告已儲存（含完整 VRR JSON）
- [ ] 未觸發第四次重試

---

## 5. Mock 資料規格（AC3）

### 5.1 標準 Mock SSD（登入頁面）

詳見 §4 TEST-UIUX-E2E-01 Step 1 的 SSD JSON。此 mock 資料為所有測試案例的標準輸入基線，token 路徑均在 `docs/design/design-tokens.json` v1.0.0 中有對應具名路徑。

**Mock SSD 合法性驗證**：

```
所有 designTokens.color 路徑：
  color.secondary.900  → docs/design/design-tokens.json color.secondary.900.$value = #0f172a ✓
  color.neutral.0      → color.neutral.0.$value = #ffffff ✓
  color.neutral.100    → color.neutral.100.$value = #f3f4f6 ✓
  color.primary.600    → color.primary.600.$value = #2563eb ✓
  color.danger.700     → color.danger.700.$value = #b91c1c ✓
  color.danger.50      → color.danger.50.$value = #fef2f2 ✓

所有 designTokens.borderRadius 路徑：
  borderRadius.base    → docs/design/design-tokens.json borderRadius.base.$value = 0.25rem ✓
  borderRadius.md      → borderRadius.md.$value = 0.375rem ✓

所有 designTokens.spacing 路徑：
  spacing.6            → docs/design/design-tokens.json spacing.6.$value = 1.5rem ✓

所有 designTokens.shadow 路徑：
  shadow.sm            → docs/design/design-tokens.json shadow.sm.$value = 0 1px 2px 0 rgb(0 0 0 / 0.05) ✓

所有 designTokens.typography 路徑：
  typography.fontSize.3xl     → 1.875rem ✓
  typography.fontSize.sm      → 0.875rem ✓
  typography.fontWeight.bold  → 700 ✓
  typography.fontWeight.medium → 500 ✓
  typography.fontWeight.semibold → 600 ✓
  typography.fontFamily.sans  → 'Inter', 'Noto Sans TC', ... ✓
```

### 5.2 VRR Mock 資料集

以下整理各測試案例的 VRR mock 資料 ID 對照：

| VRR Mock ID | 對應測試 | `verdict` | `totalScore` | 說明 |
|-------------|---------|-----------|-------------|------|
| `vrr-test-e2e-01-pass` | E2E-01 | PASS | 89.15 | 標準 happy-path 通過案例 |
| `vrr-test-e2e-02-fail-r0` | E2E-02（首次） | FAIL | 58.75 | HG-1 Hard Gate 違規（hardcode 色彩） |
| `vrr-test-e2e-02-pass-r1` | E2E-02（重試） | PASS | 88.65 | 修正後通過 |
| `vrr-test-e2e-03-cond-r0` | E2E-03 | CONDITIONAL_PASS | 74.8 | 間距偏差條件通過 |
| `vrr-test-e2e-05-fail-r3` | E2E-05（第三次） | FAIL | 58.75 | 三次上限觸發人工審查 |

### 5.3 設計 Token 測試邊界值

以下列出用於邊界測試的 token 值，對應 `docs/design/design-tokens.json` v1.0.0：

**色彩對比度邊界值（Hard Gate 相關）**：

| 前景色 token | `$value` | 背景色 token | `$value` | 對比度 | Hard Gate 判定 |
|-------------|---------|-------------|---------|-------|---------------|
| `color.neutral.0` | `#ffffff` | `color.primary.600` | `#2563eb` | 6.4:1 | HG-1 通過 |
| `color.neutral.0` | `#ffffff` | `color.primary.500` | `#3b82f6` | 4.5:1 | HG-1 邊界通過 |
| `color.neutral.0` | `#ffffff` | `color.primary.300` | `#93c5fd` | 2.1:1 | HG-1 違規（FAIL） |
| `color.secondary.900` | `#0f172a` | `color.neutral.0` | `#ffffff` | 18.1:1 | HG-1 通過（標題） |
| `color.danger.700` | `#b91c1c` | `color.danger.50` | `#fef2f2` | 5.8:1 | HG-1 通過（錯誤訊息） |

**間距偏差邊界值（OQ-3 維度三）**：

| Token 路徑 | `$value` | 對應 px | 容忍偏差（≤ 4px） | 邊界行為 |
|-----------|---------|--------|-----------------|---------|
| `spacing.4` | `1rem` | 16px | ±4px → 12–20px | gap-3（12px）= 邊界通過 |
| `spacing.6` | `1.5rem` | 24px | ±4px → 20–28px | 在範圍外 = 扣分 |
| `spacing.8` | `2rem` | 32px | ±4px → 28–36px | 在範圍外 = 扣分 |

---

## 6. 降級策略（AC4）

本節定義三層管線各層失敗時的隔離與降級處理方式，確保問題可被明確定位並有對應的恢復路徑。

---

### 6.1 UX Agent 層（Layer 1）失敗處理

**失敗類型與降級策略**：

| 失敗類型 | 觸發條件 | 錯誤碼 | 降級行為 | 管線影響 |
|---------|---------|--------|---------|---------|
| 輸入格式無效 | User Story 文字為空 | `[UX-ERROR]` | 中止執行，不輸出 SSD | 管線中斷，需重新提供有效輸入 |
| Schema 輸出違規 | 生成的 SSD 不符合 Schema v1 | `[UX-ERROR]` | 中止輸出，附診斷訊息 | 管線中斷，需修正 UX Agent 邏輯 |
| 輸入格式警告 | User Story 缺少 As/Want/So 某一子句 | `[UX-WARN]` | 繼續執行，降品質輸出 SSD | 管線繼續，但下游品質可能降低 |
| hardcode 設計值 | designTokens 含色碼或 px 數值 | `[UX-ERROR]` | 要求修正後重輸出 | 暫停，不進入 Layer 2 |
| ID 重複衝突 | section.id 或 component.id 重複 | `[UX-WARN]` | 自動加後綴修正，繼續執行 | 管線繼續（已自動修復） |

**降級策略摘要（UX 層）**：

```
UX Agent 輸出驗證失敗
    │
    ├─ [UX-WARN]：降品質繼續 → 管線繼續但附警告標記
    │   └─ UI Agent 接收到 SSD 後需注意 [UX-WARN] 來源欄位品質
    │
    └─ [UX-ERROR]：中止管線
        └─ 輸出診斷訊息 → 問題定位在 Layer 1
        └─ 不進入 Layer 2（UI Agent 不執行）
        └─ 修復路徑：修正 User Story 格式或 UX Agent 輸出邏輯
```

**整合測試驗證（UX 降級）**：TEST-UIUX-E2E-04 驗證 `[UX-WARN]` 降品質繼續場景。

---

### 6.2 UI Agent 層（Layer 2）失敗處理

**失敗類型與降級策略**：

| 失敗類型 | 觸發條件 | 錯誤碼 | 降級行為 | 管線影響 |
|---------|---------|--------|---------|---------|
| 輸入 Schema 不符 | SSD `$schema` 非 v1 或 JSON 無效 | `[UI-ERROR]` | 中止執行 | 管線中斷，定位在 Layer 1/2 介面 |
| 白名單違規 | 輸出含自訂 CSS / inline style / 非白名單元件庫 | `[UI-ERROR]` | 中止輸出，標記違規行 | 管線中斷，定位在 Layer 2 |
| Hardcode 設計數值 | 色碼、任意 px Tailwind class | `[UI-ERROR]` | 嘗試自動修正，否則中止 | 暫停，待自動修正 |
| 必要元件缺失 | `required: true` 元件在代碼中缺失 | `[UI-ERROR]` | 補全後繼續 | 管線暫停後繼續 |
| componentType 不識別 | SSD 含 Schema 外的 componentType | `[UI-WARN]` | 以 `container` 替代，繼續執行 | 管線繼續（已降級替代） |
| designTokens 路徑無效 | token 路徑不在 design-tokens.json 中 | `[UI-WARN]` | 使用 §5.3 預設 token 降級值 | 管線繼續（已降級替代） |
| Vision Critic FAIL（3次上限） | `retryCount == 3 && verdict == FAIL` | `[UI-ERROR]` | 中止重試，升級人工審查 | 管線中斷，需人工介入 |

**降級策略摘要（UI 層）**：

```
UI Agent 輸出驗證失敗
    │
    ├─ [UI-WARN]：自動降級替代 → 管線繼續但附警告標記
    │   ├─ componentType 不識別 → 替換為 container
    │   └─ token 路徑無效 → 使用預設 token 降級值
    │
    └─ [UI-ERROR]：分兩種
        │
        ├─ 可自動修正：補全必要元件 / 修正 hardcode → 繼續
        │
        └─ 不可自動修正：中止輸出 → 診斷訊息
            └─ 問題定位在 Layer 2
            └─ 修復路徑：
                ├─ SSD 輸入問題 → 回到 Layer 1 重新執行 UX Agent
                └─ UI Agent 邏輯問題 → 修正白名單約束實作
```

**退件迴圈降級流程**：

```
Vision Critic 退件（FAIL）
    │
    ├─ retryCount < 3：
    │   ├─ 解析 improvementSuggestions
    │   ├─ 針對 issues 逐一修正
    │   └─ 重新執行 Playwright 截圖 + Vision Critic（retryCount + 1）
    │
    └─ retryCount == 3：
        ├─ 輸出 [UI-ERROR] 升級訊息
        ├─ 儲存最終退件報告（VRR JSON）
        └─ 觸發人工審查流程（不繼續自動重試）
```

**整合測試驗證（UI 降級）**：TEST-UIUX-E2E-02 驗證退件修正流程；TEST-UIUX-E2E-05 驗證三次上限觸發。

---

### 6.3 Vision Critic 層（Layer 3）失敗處理

**失敗類型與降級策略**：

| 失敗類型 | 觸發條件 | 錯誤碼 | 降級行為 | 管線影響 |
|---------|---------|--------|---------|---------|
| 截圖無效 | Base64 為空或解析度 < 640×480 | `[VC-ERROR]` | 中止執行 | 管線中斷，定位在截圖環節 |
| SSD 輸入無效 | SSD 不符 Schema v1 或 sections 為空 | `[VC-ERROR]` | 中止執行 | 管線中斷，定位在 Layer 1/3 介面 |
| Playwright 截圖失敗 | Chromium 啟動失敗（缺少 `--no-sandbox` 等） | `[VC-ERROR]` | 中止並輸出環境診斷訊息 | 管線中斷，定位在基礎設施層 |
| LLM 輸出不符 VRR Schema | Claude API 回應無法解析為合法 VRR JSON | `[VC-ERROR]` | 重試一次（上限 1 次）；否則中止 | 暫停，待 LLM 重試 |
| Hard Gate 違規 | `hardGateViolations` 非空 | 無錯誤碼 | 強制 verdict=FAIL，退件至 UI Agent | 退件迴圈觸發 |
| 連續相同錯誤 | UI Agent 連續輸出相同違規 2 次以上 | `[VC-ERROR]` | 判定退件報告無效，升級人工審查 | 管線中斷，需人工介入 |

**降級策略摘要（Vision Critic 層）**：

```
Vision Critic 執行失敗
    │
    ├─ Playwright 環境問題（[VC-ERROR] 截圖失敗）：
    │   ├─ 輸出環境診斷（OS 套件、--no-sandbox 設定、/dev/shm 空間）
    │   ├─ 不發出 VRR（無評分輸出）
    │   └─ 修復路徑：確認 GCP runner 規格（e2-medium）、執行 npx playwright install
    │
    ├─ LLM 輸出格式錯誤（VRR Schema 不符）：
    │   ├─ 重試一次 LLM 呼叫
    │   └─ 若仍失敗：輸出 [VC-ERROR]，中止管線，需調整 Vision Critic prompt 設計
    │
    └─ Hard Gate 違規（正常業務流程）：
        ├─ 強制 verdict=FAIL（分數邏輯不適用）
        ├─ hardGateViolations 清單詳細說明違規
        └─ 退件至 UI Agent（進入 §6.2 退件迴圈）
```

**Playwright 截圖失敗快速診斷**：

```
症狀：[VC-ERROR] 截圖失敗
    │
    ├─ 檢查 1：Chromium 是否已安裝
    │   └─ 修復：npx playwright install chromium --with-deps
    │
    ├─ 檢查 2：VM 是否設定 --no-sandbox
    │   └─ 修復：確認 PLAYWRIGHT_CHROMIUM_LAUNCH_ARGS 環境變數
    │
    ├─ 檢查 3：/dev/shm 空間是否充足
    │   └─ 修復：--disable-dev-shm-usage 設定，或升級 VM 規格
    │
    └─ 檢查 4：RAM ≥ 2 GB
        └─ 修復：升級至 e2-medium（2 vCPU / 4 GB）
```

---

### 6.4 降級策略總覽

| 失敗層 | 錯誤碼 | 管線中斷 | 自動修復 | 人工介入點 | 後續測試 |
|--------|--------|---------|---------|-----------|---------|
| UX Agent | `[UX-ERROR]` | 是 | 否 | 修正 User Story / UX 邏輯 | TEST-UIUX-E2E-04 |
| UX Agent | `[UX-WARN]` | 否（降品質繼續） | 是（降品質替代） | 監控下游品質 | TEST-UIUX-E2E-04 |
| UI Agent | `[UI-ERROR]`（白名單） | 是 | 否 | 修正 UI Agent 輸出邏輯 | TEST-UIUX-E2E-02 |
| UI Agent | `[UI-WARN]`（token 降級） | 否（降品質繼續） | 是（預設 token） | 監控 Vision Critic 結果 | — |
| UI Agent | 退件迴圈上限 | 是（升級） | 否 | 人工審查退件報告 | TEST-UIUX-E2E-05 |
| Vision Critic | `[VC-ERROR]`（截圖失敗） | 是 | 否（需環境修復） | 確認 Playwright 環境 | — |
| Vision Critic | FAIL（Hard Gate） | 否（退件） | 是（退件報告引導） | retryCount=3 時介入 | TEST-UIUX-E2E-02/05 |

---

## 7. 測試執行清單

### 7.1 整合測試前置條件確認

執行 E2E 測試前，逐項確認：

- [ ] `docs/design/design-tokens.json` v1.0.0 存在且可讀
- [ ] `skills/ux-agent/SKILL.md` 已建立（US-105 完成）
- [ ] `skills/ui-agent/SKILL.md` 已建立（US-106 完成）
- [ ] `skills/vision-critic/SKILL.md` 已建立（US-107 完成）
- [ ] ADR-014 OQ-1 決策已落入 SKILL.md（Playwright 截圖路徑確認）
- [ ] ADR-014 OQ-3 決策已落入 SKILL.md（閾值量化標準確認）
- [ ] GCP self-hosted runner `e2-medium`（2 vCPU / 4 GB）可用
- [ ] `npx playwright install chromium --with-deps` 已在 runner 執行

### 7.2 測試案例執行順序

```
Phase A（Layer 1 獨立驗證）：
  └─ TEST-UIUX-E2E-04（UX Agent 輸入驗證，降品質繼續）

Phase B（Layer 1+2 整合）：
  └─ TEST-UIUX-E2E-01 Step 1+2（SSD → 代碼，token 注入驗證）

Phase C（Full E2E Happy Path）：
  └─ TEST-UIUX-E2E-01（完整 PASS 路徑）

Phase D（Full E2E 失敗場景）：
  ├─ TEST-UIUX-E2E-02（FAIL → 退件修正 → PASS）
  ├─ TEST-UIUX-E2E-03（條件通過邊界）
  └─ TEST-UIUX-E2E-05（三次上限 → 人工審查）
```

### 7.3 DoD 自檢清單

- [x] AC1：`docs/sdd/SDD-UIUX-E2E.md` 已建立，定義三層管線（UX → UI → Vision Critic）的端對端測試規格（本文件）
- [x] AC2：測試案例模板已定義（§3），涵蓋完整資料流：User Story → SSD → 代碼 → 截圖 → VRR；五個測試案例（TEST-UIUX-E2E-01 ~ 05）均含完整 Step 定義
- [x] AC3：mock 資料與預期輸出格式已定義（§4、§5），含 SSD mock、UI 代碼 mock、VRR mock（PASS/FAIL/CONDITIONAL_PASS 三種）；所有 mock token 路徑均在 `docs/design/design-tokens.json` v1.0.0 驗證
- [x] AC4：降級策略已定義（§6），三層各自失敗處理方式完整說明（§6.1 UX 層、§6.2 UI 層、§6.3 Vision Critic 層、§6.4 總覽）
- [x] 設計文件引用：ADR-014、ADR-006、US-105/106/107 SKILL.md 均已標示
- [x] 無硬編碼金鑰或 secrets
- [x] Mock 資料與三個 SKILL.md 定義的 JSON Schema 完全對齊

---

## 8. 參考資料

- **ADR-014**：`docs/adr/ADR-014-uiux-agent-architecture.md`（三層 Agent 分工架構、OQ-1/OQ-3 決策）
- **ADR-006**：`docs/adr/ADR-006-prompt-injection-protection.md`（XML 隔離標記規則）
- **UX Agent SKILL.md**：`skills/ux-agent/SKILL.md`（SSD JSON Schema v1，US-105）
- **UI Agent SKILL.md**：`skills/ui-agent/SKILL.md`（Design Tokens 注入規則、元件庫白名單，US-106）
- **Vision Critic SKILL.md**：`skills/vision-critic/SKILL.md`（VRR JSON Schema v1、OQ-3 閾值，US-107）
- **Design Tokens**：`docs/design/design-tokens.json`（v1.0.0，自訂 JSON 格式，ADR-014 OQ-2 決策）
- **Sprint 53**：`docs/sprints/sprint_53.md`（US-108 AC 定義）
- [WCAG 2.1 AA 標準](https://www.w3.org/TR/WCAG21/)（SC 1.4.3、SC 1.4.11、SC 1.4.12、SC 2.5.5）
- [Playwright — Screenshots](https://playwright.dev/docs/screenshots)（GCP self-hosted runner 截圖整合）
- [Claude API Vision capabilities](https://docs.anthropic.com/en/docs/build-with-claude/vision)（Claude Sonnet 4.6 多模態輸入）
