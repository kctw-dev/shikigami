# E2E Test Case 管理規範

**關聯 Story**：US-205（Issue #200）
**版本**：v1.0.0
**建立日期**：2026-03-11（Sprint 77）
**關聯文件**：
- `.github/workflows/e2e.yml`（E2E workflow 模板，US-197）（**已於 Sprint 142 移除**，workflow 範例見本文件 §4.2 / §4.3）
- `docs/sdd/SDD-UIUX-E2E.md`（三層 Agent 管線 E2E 規格，US-108）
- `skills/deployment-readiness/SKILL.md`（E2E Soft Gate，US-199）
- `docs/ci-cd-guide/README.md`（CI/CD workflow 拆分指引，US-93）

---

## 目錄

1. [E2E 目錄結構規範](#1-e2e-目錄結構規範)
2. [測試分層標記](#2-測試分層標記)
3. [Test Case 篩選標準](#3-test-case-篩選標準)
4. [CI/CD 整合策略](#4-cicd-整合策略)
5. [Flaky Test 管理機制](#5-flaky-test-管理機制)
6. [Page Object / Fixture 規範](#6-page-object--fixture-規範)

---

## 1. E2E 目錄結構規範

### 1.1 標準目錄結構

所有 E2E 測試放置於 `tests/e2e/` 目錄下，依功能模組分類：

```
tests/
└── e2e/
    ├── fixtures/                  # 測試資料（靜態 fixture 與 factory）
    │   ├── users.json             # 靜態使用者測試資料
    │   └── factories/             # 動態資料產生器
    │       └── user.factory.ts
    ├── pages/                     # Page Object Model（POM）封裝
    │   ├── base.page.ts           # 共用 BasePage（導航、等待輔助）
    │   ├── auth/
    │   │   ├── login.page.ts
    │   │   └── register.page.ts
    │   └── dashboard/
    │       └── dashboard.page.ts
    ├── specs/                     # 測試規格（依功能模組分類）
    │   ├── auth/
    │   │   ├── login.spec.ts      # 登入流程
    │   │   └── logout.spec.ts     # 登出流程
    │   ├── dashboard/
    │   │   └── dashboard.spec.ts  # Dashboard 主要功能
    │   └── api/                   # API 層 E2E（非 UI 流程）
    │       └── contract.spec.ts
    ├── support/                   # 共用輔助工具
    │   ├── auth.setup.ts          # 認證 setup（CI 登入）
    │   └── global-setup.ts        # 全域前置條件
    └── playwright.config.ts       # Playwright 設定（或放置於 tests/e2e 同層）
```

### 1.2 目錄命名規則

| 規則 | 說明 | 範例 |
|------|------|------|
| 目錄名稱 | 小寫 kebab-case | `auth/`、`user-profile/` |
| spec 檔案 | `[功能].spec.ts` | `login.spec.ts`、`checkout.spec.ts` |
| page 檔案 | `[功能].page.ts` | `login.page.ts`、`dashboard.page.ts` |
| fixture 檔案 | `[資料類型].json` 或 `[資料類型].factory.ts` | `users.json`、`order.factory.ts` |

### 1.3 模組分類原則

依業務功能（而非技術層）建立子目錄：

```
specs/
├── auth/          # 認證相關（登入、登出、權限）
├── dashboard/     # 主要儀表板功能
├── settings/      # 設定與偏好
├── api/           # API 契約端對端驗證
└── smoke/         # 跨模組 Smoke 測試（快速驗證核心功能）
```

> 當某功能模組的 spec 數量超過 5 個時，考慮新增子目錄（如 `auth/mfa/`）。

---

## 2. 測試分層標記

### 2.1 標記定義總覽

Playwright 使用 `@` 前綴標記（在測試標題中加入，或透過 `tag` 選項）：

| 標記 | 意義 | 數量目標 | 執行時間目標 |
|------|------|---------|------------|
| `@smoke` | 快速驗證核心功能可用性 | 每次部署後必跑，數量控制在 10–20 個 | ≤ 5 分鐘 |
| `@regression` | 完整功能回歸，防止既有功能退化 | 完整功能覆蓋 | ≤ 30 分鐘 |
| `@critical` | 業務關鍵路徑，失敗即阻擋發版 | Critical Path 清單中的流程 | 含於 smoke 或 regression |

### 2.2 `@smoke` 標記規範

**選擇標準**（同時滿足以下條件才可標記為 smoke）：

- 驗證核心功能是否「可正常啟動並操作」（非深度驗證）
- 執行時間單一測試 ≤ 30 秒
- 不依賴複雜測試資料或特定狀態
- 覆蓋「登入 → 完成一個主要操作 → 登出」的最短路徑

**執行時機**：

1. 每次部署到任何環境後（staging、production）自動觸發
2. PR Merge 前的快速驗證（optional，視專案需求）

**範例**：

```typescript
test('@smoke 使用者可成功登入並進入 Dashboard', async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.navigate();
  await loginPage.loginWith(testUsers.standard);
  await expect(page).toHaveURL('/dashboard');
});
```

### 2.3 `@regression` 標記規範

**選擇標準**（符合以下任一條件即應標記）：

- 驗證完整的使用者流程（含邊界條件、錯誤路徑）
- 曾經發生過 regression bug 的功能路徑
- 涉及多個模組整合的複雜流程
- 需要特定測試資料設定或清理的測試

**執行時機**：

1. 每週定時執行一次（建議週一凌晨）
2. 發版前手動觸發
3. 重大功能合入 main branch 後觸發

**範例**：

```typescript
test('@regression 使用者輸入錯誤密碼三次後帳號鎖定', async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.navigate();
  for (let i = 0; i < 3; i++) {
    await loginPage.loginWith({ email: 'user@test.com', password: 'wrong' });
  }
  await expect(loginPage.lockoutMessage).toBeVisible();
});
```

### 2.4 `@critical` 標記規範

**選擇標準**（業務影響評估，符合以下條件之一）：

- 失敗會直接導致收入損失或用戶無法完成核心業務
- 屬於 §3.2 Critical Path 清單中的業務流程
- 安全相關功能（認證、授權、資料保護）

**執行時機**：

- `@critical` 標記通常與 `@smoke` 或 `@regression` 共存（不單獨執行）
- 共存範例：`@smoke @critical`（部署後立即驗證）或 `@regression @critical`（深度驗證）
- CI Gate 判定：`@critical` 測試失敗時，自動升級為 Hard Gate，阻擋 deployment-readiness 流程

**範例**：

```typescript
test('@smoke @critical 登入功能正常運作', async ({ page }) => {
  // 核心登入路徑，smoke 且 critical
});

test('@regression @critical 付款流程端對端完整驗證', async ({ page }) => {
  // 深度付款流程，regression 且 critical
});
```

### 2.5 標記使用禁止事項

- 禁止對同一個測試同時標記 `@smoke` 和 `@regression`（功能定位衝突）
- 禁止未加任何標記（所有 E2E spec 必須至少帶一個層級標記）
- 禁止 `@smoke` 測試內含超過 5 個步驟（超過則移至 `@regression`）

---

## 3. Test Case 篩選標準

### 3.1 Risk-based 篩選框架

評估一個業務流程是否需要 E2E 覆蓋，依下列風險矩陣判定：

```
          │  業務影響（高）  │  業務影響（低）
──────────┼────────────────┼────────────────
變更頻率高 │  必須 E2E 覆蓋  │  建議 E2E 覆蓋
          │  (@smoke)      │  (@regression)
──────────┼────────────────┼────────────────
變更頻率低 │  必須 E2E 覆蓋  │  可選 E2E 覆蓋
          │  (@regression) │  （視資源決定）
```

**判定步驟**：

1. **業務影響評估**：若此流程失敗，使用者是否無法完成核心業務？
   - 是 → 高業務影響
   - 否 → 低業務影響

2. **變更頻率評估**：此流程相關代碼在最近 3 個 Sprint 有無被修改？
   - 是 → 高變更頻率
   - 否 → 低變更頻率

3. **判定結果**：依矩陣選擇覆蓋策略與標記

### 3.2 Critical Path 清單（必須有 E2E 覆蓋）

以下業務流程無論風險評估結果如何，均必須有 E2E 測試覆蓋：

| # | 業務流程 | 標記 | 說明 |
|---|---------|------|------|
| CP-01 | 使用者登入（成功路徑） | `@smoke @critical` | 所有功能的入口 |
| CP-02 | 使用者登出 | `@smoke` | Session 管理安全性 |
| CP-03 | 登入失敗（錯誤憑證） | `@regression @critical` | 安全機制驗證 |
| CP-04 | 主要業務核心動作（依專案定義） | `@smoke @critical` | 專案核心價值交付 |
| CP-05 | 權限邊界驗證（無權限操作被拒） | `@regression @critical` | 授權機制正確性 |
| CP-06 | API 契約端對端驗證 | `@regression` | 前後端契約一致性（US-195） |

> Critical Path 清單由 Architect 於 Sprint Planning 審查更新，需反映當前業務最高價值路徑。

### 3.3 排除原則

以下情況不建議撰寫 E2E 測試（應改用 unit / integration test 覆蓋）：

- 純計算邏輯（資料轉換、格式化）
- 已有 unit test 充分覆蓋的 API 邏輯
- 需要精確時序控制的異步行為（如動畫效果）
- 需要外部硬體（如指紋辨識器）的功能

### 3.4 新增 Test Case 決策清單

```
新功能 / 修改的業務流程
    │
    ├─ 是否在 Critical Path 清單（§3.2）中？
    │   └─ 是 → 必須新增 E2E（@smoke @critical 或 @regression @critical）
    │
    ├─ 業務影響高 + 變更頻率高？
    │   └─ 是 → 必須新增 @smoke 覆蓋
    │
    ├─ 業務影響高 + 變更頻率低？
    │   └─ 是 → 必須新增 @regression 覆蓋
    │
    ├─ 業務影響低 + 變更頻率高？
    │   └─ 是 → 建議新增 @regression 覆蓋
    │
    └─ 業務影響低 + 變更頻率低？
        └─ 可選，依團隊資源決定
```

---

## 4. CI/CD 整合策略

### 4.1 整體執行策略

```
程式碼合入
    │
    ▼
PR / Push（unit + integration）
    │
    ▼
部署至 Staging 環境
    │
    ▼
Smoke Suite 自動執行（@smoke）
    │
    ├─ PASS → 繼續
    └─ FAIL (@critical) → Hard Gate，阻擋發版
    └─ FAIL (非 @critical) → E2E Soft Gate，需 PO 確認
    │
    ▼
（發版前或每週排程）
Regression Suite 執行（@regression）
    │
    ├─ PASS → 正常發版
    └─ FAIL (@critical) → 阻擋發版，開 Bug Issue
    └─ FAIL (非 @critical) → 記錄，Sprint 回顧時處理
```

### 4.2 Smoke Suite — 部署後自動執行

**觸發時機**：deployment workflow 完成後（`workflow_run` 事件）

**執行範圍**：所有帶 `@smoke` 標記的測試

**Runner 選型**（依 CI/CD 指引，`docs/ci-cd-guide/README.md`）：

- Compute-heavy 的 Playwright 執行 → GitHub-hosted runner (`ubuntu-latest`)
- 執行環境需求：Node.js、Playwright chromium、目標服務 URL

**Workflow 設定範例**（基於 `.github/workflows/e2e.yml` 模板）：

```yaml
name: E2E Smoke Suite

on:
  workflow_run:
    workflows: ["Deploy to Staging"]
    types: [completed]

jobs:
  smoke:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - name: Run Smoke Suite
        run: npx playwright test --grep "@smoke"
        env:
          TEST_BASE_URL: ${{ secrets.STAGING_URL }}
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: smoke-report-${{ github.run_id }}
          path: playwright-report/
          retention-days: 7
```

**Gate 行為**：

| 結果 | `@critical` | Gate 行為 |
|------|------------|----------|
| 全部 PASS | — | 繼續 deployment-readiness 流程 |
| 任一 FAIL | 是 | Hard Gate：阻擋，輸出 `[E2E-HARD-GATE]`，需 fix before deploy |
| 任一 FAIL | 否 | Soft Gate：輸出 `[E2E-SOFT-GATE]`，需 PO 確認後繼續（對齊 US-199） |

### 4.3 Regression Suite — 排程執行

**觸發時機**：

1. 每週一 08:00（UTC+8）自動排程
2. 手動觸發（`workflow_dispatch`）
3. 發版 Tag push 前（選擇性，視交付速度而定）

**執行範圍**：所有帶 `@regression` 標記的測試

**Workflow 設定範例**：

```yaml
name: E2E Regression Suite

on:
  schedule:
    - cron: "0 0 * * 1"  # 每週一 00:00 UTC（= 08:00 UTC+8）
  workflow_dispatch:
    inputs:
      environment:
        description: "Target environment"
        required: true
        default: "staging"
        type: choice
        options: [staging, production]

jobs:
  regression:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - name: Run Regression Suite
        run: npx playwright test --grep "@regression"
        env:
          TEST_BASE_URL: ${{ secrets.STAGING_URL }}
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: regression-report-${{ github.run_id }}
          path: playwright-report/
          retention-days: 30
```

**結果處理**：

- Regression FAIL 時自動開 GitHub Issue（標題：`[E2E-REGRESSION-FAIL] <測試名稱>`）
- 指派給負責該功能模組的開發者
- 下一個 Sprint Planning 前必須確認是否為已知 Flaky（進隔離）或真實 Bug（進 Backlog）

### 4.4 環境分離原則

| 環境 | Smoke Suite | Regression Suite | 備注 |
|------|------------|-----------------|------|
| Development（本機） | 手動執行 | 手動執行 | `npx playwright test --grep "@smoke"` |
| Staging | 部署後自動 | 每週排程 | 主要驗證環境 |
| Production | 部署後自動（僅 CP 項目） | 月度手動 | 最小化對生產環境影響 |

---

## 5. Flaky Test 管理機制

### 5.1 Flaky Test 定義

Flaky Test 是指「在代碼和測試未變更的情況下，執行結果不穩定（有時 PASS 有時 FAIL）」的測試。

**常見成因**：

| 類型 | 描述 | 典型症狀 |
|------|------|---------|
| 時序問題 | 等待條件不充分，元素未載入即操作 | 間歇性 `TimeoutError` |
| 測試資料衝突 | 測試間共用可變資料 | 依執行順序結果不同 |
| 環境不穩定 | 外部服務延遲或不可用 | CI 偶發失敗，本機穩定 |
| 元素定位不穩 | 選擇器在 DOM 重渲染後失效 | 間歇性 `ElementNotFoundError` |
| 競態條件 | 異步操作完成時間不確定 | 偶發資料不一致 |

### 5.2 Flaky Test 識別標準

一個測試被認定為 Flaky，需滿足：

- 在相同代碼、相同環境下連續執行 5 次，出現 ≥ 1 次 FAIL 且 ≥ 1 次 PASS

或：

- 在 CI 中同一 PR 的重試執行中，首次 FAIL、重試後 PASS（無代碼變更）

### 5.3 Quarantine（隔離）流程

```
發現 Flaky Test
    │
    ▼
Step 1：標記隔離（當日完成）
    │   在測試標題加入 @quarantine 標記
    │   例：'@regression @quarantine 付款流程'
    │
    ▼
Step 2：開 GitHub Issue（當日完成）
    │   標題：[FLAKY] <測試名稱>
    │   內容：失敗截圖/log、重現頻率、可能成因
    │   標籤：flaky-test、待修復
    │
    ▼
Step 3：從 CI Suite 排除（當日完成）
    │   Playwright config 排除 @quarantine：
    │   grep: /^(?!.*@quarantine)/
    │
    ▼
Step 4：調查與修復（≤ 2 個 Sprint）
    │   Root cause 分析 → 修復 → 移除 @quarantine 標記
    │
    ▼
Step 5：驗證穩定性（修復後）
    │   連續執行 10 次全部 PASS → 移除 @quarantine
    └─  否則 → 回到 Step 4
```

### 5.4 Retry 策略

Playwright 設定中的 retry 用於處理偶發性環境問題，**不是隱藏 Flaky Test 的手段**：

```typescript
// playwright.config.ts
export default defineConfig({
  // CI 環境允許最多重試 2 次（僅用於環境不穩定）
  retries: process.env.CI ? 2 : 0,
  // 本機開發不重試（強制開發者看到真實失敗）
});
```

**Retry 使用原則**：

| 原則 | 說明 |
|------|------|
| Retry 上限 | CI 環境最多 2 次，本機 0 次 |
| Retry 不等於修復 | 如某測試每次 CI 都需要重試才能通過，必須進入 Quarantine 流程 |
| 連續重試 PASS 觸發警告 | 若某測試在同一個 CI run 中需重試才 PASS，輸出 `[FLAKY-WARN]` 並記錄 |

### 5.5 修復追蹤看板

在 GitHub 使用 `flaky-test` 標籤追蹤所有 Quarantine 測試：

| 欄位 | 說明 |
|------|------|
| Issue 標題 | `[FLAKY] <測試名稱>` |
| 標籤 | `flaky-test`、`sprint-N`（發現的 Sprint） |
| 狀態 | `quarantined`（隔離中）→ `investigating`（調查中）→ `fixed`（已修復） |
| 修復期限 | 發現後 2 個 Sprint 內必須修復或升級為已知技術債 |

**每 Sprint Review 必須確認**：當前 Quarantine 清單中是否有超過 2 個 Sprint 未修復的測試。若有，升級為 Tech Debt Issue 進入 Backlog。

---

## 6. Page Object / Fixture 規範

### 6.1 Page Object Model（POM）規範

#### 6.1.1 POM 設計原則

所有 UI 互動必須透過 Page Object 封裝，禁止在 spec 檔案中直接使用 Playwright locator API：

```typescript
// 正確：透過 POM 操作
const loginPage = new LoginPage(page);
await loginPage.loginWith(testUsers.standard);

// 錯誤：直接在 spec 中操作 DOM（禁止）
await page.fill('#email', 'user@test.com');
await page.click('[data-testid="submit-btn"]');
```

#### 6.1.2 BasePage 共用介面

所有 Page Object 繼承 `BasePage`：

```typescript
// tests/e2e/pages/base.page.ts
import { Page, Locator } from '@playwright/test';

export abstract class BasePage {
  readonly page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async navigate(): Promise<void> {
    await this.page.goto(this.url);
    await this.waitForReady();
  }

  protected abstract get url(): string;

  protected async waitForReady(): Promise<void> {
    await this.page.waitForLoadState('networkidle');
  }
}
```

#### 6.1.3 Page Object 結構標準

```typescript
// tests/e2e/pages/auth/login.page.ts
import { Page, Locator, expect } from '@playwright/test';
import { BasePage } from '../base.page';

export interface LoginCredentials {
  email: string;
  password: string;
}

export class LoginPage extends BasePage {
  // 1. Locators（使用 data-testid 優先）
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    super(page);
    this.emailInput = page.getByTestId('email-input');
    this.passwordInput = page.getByTestId('password-input');
    this.submitButton = page.getByTestId('login-submit');
    this.errorMessage = page.getByTestId('login-error');
  }

  protected get url(): string {
    return '/login';
  }

  // 2. Actions（業務動作，單一職責）
  async loginWith(credentials: LoginCredentials): Promise<void> {
    await this.emailInput.fill(credentials.email);
    await this.passwordInput.fill(credentials.password);
    await this.submitButton.click();
  }

  // 3. Assertions（驗證方法，供 spec 複用）
  async assertLoginSuccess(): Promise<void> {
    await expect(this.page).toHaveURL('/dashboard');
  }

  async assertErrorVisible(message?: string): Promise<void> {
    await expect(this.errorMessage).toBeVisible();
    if (message) {
      await expect(this.errorMessage).toContainText(message);
    }
  }
}
```

#### 6.1.4 Locator 優先順序

優先使用以下順序選擇元素定位方式（由穩定到不穩定）：

1. `data-testid` 屬性（最穩定，語意明確）
2. ARIA role + label（無障礙友善）
3. `getByText()`（顯示文字，需注意多語系）
4. CSS selector（如有唯一且穩定的 class）
5. XPath（最後手段，極力避免）

```typescript
// 優先：data-testid
page.getByTestId('submit-button')

// 次選：ARIA role
page.getByRole('button', { name: '送出' })

// 避免：脆弱 CSS selector
page.locator('.btn.btn-primary.submit')  // 禁止
```

### 6.2 Fixture 與測試資料管理

#### 6.2.1 靜態 Fixture（JSON）

用於不需要動態生成、不會改變的測試資料：

```json
// tests/e2e/fixtures/users.json
{
  "standard": {
    "email": "e2e-standard@test.internal",
    "password": "TestPass123!",
    "displayName": "E2E 標準測試用戶"
  },
  "admin": {
    "email": "e2e-admin@test.internal",
    "password": "AdminPass456!",
    "displayName": "E2E 管理員測試用戶"
  }
}
```

**靜態 Fixture 使用規範**：

- 測試帳號使用 `*.test.internal` 域名，與生產環境帳號明確隔離
- 密碼存放於 Fixture 中（E2E 測試環境非生產帳號），禁止使用生產環境憑證
- CI 環境的敏感測試資料（如 Service Account）使用 GitHub Secrets 注入

#### 6.2.2 Factory（動態資料產生）

用於需要唯一性或動態生成的資料：

```typescript
// tests/e2e/fixtures/factories/user.factory.ts
import { faker } from '@faker-js/faker';

export interface TestUser {
  email: string;
  password: string;
  displayName: string;
}

export function createTestUser(overrides?: Partial<TestUser>): TestUser {
  return {
    email: `e2e-${faker.string.uuid()}@test.internal`,
    password: 'TestPass123!',
    displayName: faker.person.fullName(),
    ...overrides,
  };
}
```

**Factory 使用時機**：

| 情境 | 使用 Fixture | 使用 Factory |
|------|------------|-------------|
| 登入驗證（固定帳號） | 是 | 否 |
| 新增資料（需唯一性） | 否 | 是 |
| 批次測試不同輸入組合 | 否 | 是 |
| CI 環境認證帳號 | 是（Secrets 注入） | 否 |

#### 6.2.3 Playwright Fixture（Test Context）

使用 Playwright 的 `test.extend` 建立共用 fixture，避免每個 spec 重複初始化：

```typescript
// tests/e2e/fixtures/index.ts
import { test as base, expect } from '@playwright/test';
import { LoginPage } from '../pages/auth/login.page';
import { DashboardPage } from '../pages/dashboard/dashboard.page';
import testUsers from './users.json';

type E2EFixtures = {
  loginPage: LoginPage;
  dashboardPage: DashboardPage;
  authenticatedPage: DashboardPage;  // 已登入狀態
};

export const test = base.extend<E2EFixtures>({
  loginPage: async ({ page }, use) => {
    await use(new LoginPage(page));
  },
  dashboardPage: async ({ page }, use) => {
    await use(new DashboardPage(page));
  },
  authenticatedPage: async ({ page }, use) => {
    const loginPage = new LoginPage(page);
    await loginPage.navigate();
    await loginPage.loginWith(testUsers.standard);
    await loginPage.assertLoginSuccess();
    await use(new DashboardPage(page));
  },
});

export { expect };
```

**在 spec 中使用**：

```typescript
// tests/e2e/specs/dashboard/dashboard.spec.ts
import { test, expect } from '../../fixtures';

test('@smoke @critical Dashboard 頁面正常載入', async ({ authenticatedPage }) => {
  await expect(authenticatedPage.mainContent).toBeVisible();
});
```

### 6.3 測試資料清理原則

| 原則 | 說明 |
|------|------|
| 每個測試獨立 | 測試不應依賴其他測試所建立的資料 |
| After-each 清理 | 測試建立的資料在 `afterEach` 中清理 |
| 隔離環境 | E2E 測試僅針對非生產環境執行，避免污染生產資料 |
| 冪等設計 | 測試可重複執行，不因現有資料狀態而失敗 |

### 6.4 禁止事項

| 禁止行為 | 原因 | 替代方案 |
|---------|------|---------|
| spec 中直接使用 `page.locator()` 複雜選擇器 | 脆弱，難以維護 | 封裝至 POM |
| 硬編碼 URL（如 `page.goto('https://...')`) | 環境耦合 | 使用 `process.env.TEST_BASE_URL` |
| 測試間共享可變 fixture 狀態 | 導致測試順序依賴 | 每個測試獨立初始化 |
| 在 spec 中直接 `page.waitForTimeout(5000)` | 不穩定，掩蓋真實問題 | 使用 `waitFor` 條件等待 |
| 存取生產環境資料庫或 API | 污染生產資料 | 使用 staging 環境與測試資料集 |

---

## 附錄 A：快速參照

### A.1 新增 E2E 測試 Checklist

```
[ ] 在正確的功能模組目錄下建立 spec 檔案（tests/e2e/specs/<module>/）
[ ] 標記至少一個層級標記（@smoke 或 @regression）
[ ] Critical Path 流程加上 @critical
[ ] UI 互動封裝至對應 Page Object
[ ] 測試資料使用 fixtures/users.json 或 Factory（非硬編碼）
[ ] 不使用 page.waitForTimeout()（使用條件等待取代）
[ ] Locator 優先使用 data-testid
```

### A.2 標記速查表

| 情境 | 建議標記 |
|------|---------|
| 登入等核心功能快速驗證 | `@smoke @critical` |
| 一般功能部署後驗證 | `@smoke` |
| 完整流程邊界條件驗證 | `@regression` |
| 安全 / 權限相關完整驗證 | `@regression @critical` |
| 已確認 Flaky 待修復 | `@quarantine`（暫時加入，修復後移除）|

### A.3 Flaky Test 快速診斷

```
測試間歇性失敗
    │
    ├─ 只在 CI 失敗，本機穩定？
    │   └─ 可能：環境差異（網路延遲、服務啟動時間）
    │      修復：增加 waitFor 條件或重試等待
    │
    ├─ 依執行順序結果不同？
    │   └─ 可能：測試資料共享污染
    │      修復：每個測試獨立初始化資料
    │
    ├─ 間歇性 TimeoutError？
    │   └─ 可能：元素等待條件不足
    │      修復：用 waitFor({ state: 'visible' }) 取代固定等待
    │
    └─ 無規律性失敗？
        └─ 進入 Quarantine 流程（§5.3），開 Issue 追蹤
```

---

*本規範依 Sprint 77 US-205 建立，後續修訂需更新版本號並記錄變更原因。*
