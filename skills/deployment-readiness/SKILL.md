---
name: deployment-readiness
description: "Use when preparing for deployment, version release, environment configuration changes, or production readiness checks"
---

# Deployment Readiness — SRE 主導部署就緒檢查

## 1. 概述

SRE Engineer 主導的部署就緒檢查 Skill，確保每次部署安全、可靠、可回滾。

部署前由 **SRE subagent** 準備部署計畫與回滾方案，同時 **Security subagent** 並行執行部署前安全掃描。兩者皆通過後方可執行部署，任一不通過則修復後重新審查。

---

## 2. 核心原則

**安全部署 = 充分準備 + 並行驗證 + 可回滾保障**

- **雙軌並行**：SRE 準備部署計畫的同時，Security 執行安全掃描，縮短前置時間
- **回滾優先**：任何部署必須先有經過驗證的回滾方案，才能執行
- **可觀測性**：Golden Signals 監控確保部署後即時發現異常
- **Error Budget 驅動**：部署前確認 SLO Error Budget 充足，避免在預算不足時冒險部署

---

## 3. 執行流程

```
部署請求觸發
  |
  +------------------+
  |                  |
  v                  v
派遣 SRE subagent    派遣 Security subagent
（部署計畫 +          （部署前安全掃描）
  回滾方案）
  |                  |
  v                  v
SRE 審查結果      Security 審查結果
  |                  |
  +------------------+
  |
  v
兩者都通過？
  |-- 否 --> 修復問題 --> 重新審查（回到並行派遣）
  +-- 是
        |
        v
執行部署 Checklist 最終確認
  |
  v
執行部署
  |
  v
部署後 Golden Signals 監控驗證
  |
  v
更新部署文件 + 通知相關角色
```

### 步驟詳解

1. **部署請求觸發**：從 Sprint 完成的 Stories 或版本發布需求觸發部署就緒檢查。
2. **派遣 SRE subagent**：準備完整部署計畫，包含部署步驟、環境配置變更、回滾方案與驗證程序。
3. **派遣 Security subagent（並行）**：執行部署前安全掃描，涵蓋依賴套件漏洞、配置安全性、機密資訊洩漏檢查。
4. **審查結果匯總**：兩個 subagent 的結果皆必須通過。任一不通過則產出問題清單，修復後重新審查。
5. **執行部署**：通過所有檢查後，按部署計畫執行部署。
6. **部署後驗證**：監控 Golden Signals，確認服務健康，驗證 SLO 達標。

---

## 4. 版本 Tag 管理

Sprint Review 驗收通過後，由 SRE subagent 負責打 tag 與更新版號。

### 版號策略（Semantic Versioning）

| 事件 | 版號變化 | 範例 |
|------|----------|------|
| Sprint Review 通過 | minor +1 | `v0.1.0` → `v0.2.0` |
| Hotfix（Sprint 外緊急修復） | patch +1 | `v0.2.0` → `v0.2.1` |
| 正式穩定版（外部使用者驗證） | major | `v0.x.y` → `v1.0.0` |

### 執行步驟

1. 更新 `.claude-plugin/plugin.json` 的 `version` 欄位
2. 更新 `.claude-plugin/marketplace.json` 的 `version` 欄位
3. Commit：`chore: bump version to vX.Y.Z`
4. 打 tag：`git tag vX.Y.Z`
5. Push：`git push && git push --tags`

### 觸發時機

```
sprint-review 驗收通過
  → 觸發 deployment-readiness
    → SRE subagent 執行版本 Tag 流程
    → 部署就緒檢查（若有部署需求）
```

<HARD-GATE>
`plugin.json` 與 `marketplace.json` 的版號必須一致。
Tag 名稱必須與 `plugin.json` 的 version 欄位一致（加 `v` 前綴）。
</HARD-GATE>

### 版本 Tag 決策規則

在執行版本 Tag 流程前，SRE subagent 必須依下列規則判定版號 bump 類型。

#### 決策矩陣

| 條件 | 決策 | 版號變化 |
|------|------|----------|
| Sprint Review 通過 + 所有 Stories 完成 + 無安全掃描失敗 | **Minor bump** | `vX.Y.0` → `vX.(Y+1).0` |
| ROADMAP 里程碑完成（所有里程碑 Stories 均已交付）+ PO 確認 + 無安全掃描失敗 | **Major bump** | `vX.Y.Z` → `v(X+1).0.0` |
| Hotfix（Sprint 外緊急修復，標注 `[EMERGENCY]`） | **Patch bump** | `vX.Y.Z` → `vX.Y.(Z+1)` |
| 以下任一禁止條件成立 | **禁止 bump** | 不更新版號 |

#### Minor Bump 觸發條件（vX.Y+1.0）

以下**全部**條件成立時，執行 Minor bump：

- Sprint Review 驗收通過（PO Subagent 確認）
- Sprint Backlog 中所有計畫 Stories 均已完成（無「未完成」狀態 Story）
- 安全掃描已通過（Security subagent 確認）
- sprint-review SKILL.md §7 執行檢查清單全部打勾

#### Major Bump 觸發條件（vX+1.0.0）

以下**全部**條件成立時，**且已符合 Minor Bump 條件**，升級為 Major bump：

- `docs/prd/ROADMAP.md` 某個里程碑下的所有 Stories 均已標記完成
- PO 明確確認該里程碑達成（口頭或 Sprint Review 記錄）
- sprint-review SKILL.md 的 ROADMAP 里程碑對齊檢查確認里程碑完成
- 安全掃描已通過

#### 禁止 Bump 條件

以下任一條件成立時，**不得執行任何版號 bump**：

- Sprint Backlog 有任何 Story 狀態為「未完成」
- 安全掃描未通過或尚未執行
- 部署 Checklist 有未勾選項目
- sprint-review SKILL.md §7 執行檢查清單有未完成項目

#### PO Override 機制

當自動決策規則判定「禁止 bump」，但 PO 認為基於商業原因應執行 bump 時，PO 可啟動覆蓋機制。

**觸發條件**：自動規則建議禁止 bump，但 PO 明確指示應執行 bump。

**執行步驟**：

1. PO 提供覆蓋原因（必須是具體商業原因，例如：「僅有文件性 Story 未完成，不影響功能穩定性」）
2. SRE subagent 在執行 bump 前在 commit message 中標注：
   ```
   chore: bump version to vX.Y.Z [PO-OVERRIDE]

   覆蓋原因：<PO 提供的覆蓋原因>
   覆蓋時間：YYYY-MM-DD
   覆蓋決策者：PO
   ```
3. 同步將覆蓋記錄寫入 `docs/km/Metrics_Log.md` 的備注欄（格式：`[PO-OVERRIDE] vX.Y.Z — <原因摘要>`）
4. Sprint Review Retrospective 的 Problem 區塊記錄此次覆蓋事件，確保下個 Sprint 追蹤根因

**限制**：

- PO Override 不得用於規避安全掃描未通過的限制——安全掃描失敗是絕對禁止條件，PO 無法覆蓋
- 連續兩個 Sprint 使用 PO Override 時，自動升級至 Stakeholder 審查

<HARD-GATE>
安全掃描未通過時，禁止任何版號 bump，包括 PO Override 情況。
PO Override 必須標注 [PO-OVERRIDE] 於 commit message，且同步記錄至 Metrics_Log.md。
</HARD-GATE>

---

## 5. 部署 Checklist

每次部署前必須逐項確認：

| 項目 | 狀態 |
|------|------|
| 所有測試通過 | [ ] |
| 安全掃描通過 | [ ] |
| 回滾方案已驗證 | [ ] |
| 環境變數已設定 | [ ] |
| 監控告警已配置 | [ ] |
| 部署文件已更新 | [ ] |
| 效能基準驗證通過（見 §14） | [ ] |

<HARD-GATE>
Checklist 中任一項目未勾選，不得執行部署。
回滾方案必須經過實際驗證（dry-run），不接受僅文件描述。
</HARD-GATE>

---

## 5.1 L2 API 整合驗證步驟模板

**目的**：在版本 tag 前自動驗證關鍵 API 端點的 response schema，補足 unit test 無法覆蓋的跨服務整合驗證。

> **使用方式**：消費端專案將此模板複製至部署腳本或 CI workflow，並自行填入 `ENDPOINTS` 清單與各端點的預期欄位。

### 前置條件

- 目標環境（Staging / Production）API 服務已啟動
- 具備 API 呼叫權限（Token / API Key 已設定於環境變數）
- `curl` 與 `jq` 已安裝於執行環境

### 驗證步驟

#### 步驟 1：定義待驗證端點清單

消費端專案自行填入以下變數（請勿硬編碼至 SKILL.md，僅在部署腳本或 CI workflow 中配置）：

```bash
# ============================================================
# 消費端自行填入區域（此段不應出現在 SKILL.md，僅作範例說明）
# ============================================================

# 基礎 URL（由環境變數注入，勿硬編碼）
BASE_URL="${API_BASE_URL}"          # 例：https://api.example.com
AUTH_HEADER="${API_AUTH_HEADER}"    # 例：Authorization: Bearer ${TOKEN}

# 待驗證端點清單（格式：METHOD PATH REQUIRED_FIELD1,REQUIRED_FIELD2,...）
ENDPOINTS=(
  "GET  /health          status,version"
  "GET  /api/v1/ping     pong"
  # 在此新增更多端點
)
```

#### 步驟 2：執行 L2 API Schema 驗證

使用以下腳本逐一驗證端點回應是否包含必要欄位：

```bash
#!/usr/bin/env bash
# l2-api-validation.sh — L2 API 整合驗證腳本
# 用法：BASE_URL=https://api.example.com AUTH_HEADER="Authorization: Bearer <token>" bash l2-api-validation.sh

set -euo pipefail

FAIL=0

validate_endpoint() {
  local method="$1"
  local path="$2"
  local required_fields="$3"  # 逗號分隔欄位名稱

  local url="${BASE_URL}${path}"
  local response

  echo "  [CHECK] ${method} ${url}"

  response=$(curl --silent --fail \
    --request "${method}" \
    --header "${AUTH_HEADER}" \
    --header "Accept: application/json" \
    "${url}") || {
    echo "  [FAIL]  HTTP 請求失敗：${method} ${path}"
    FAIL=1
    return
  }

  # 驗證每個必要欄位是否存在且非 null
  IFS=',' read -ra fields <<< "${required_fields}"
  for field in "${fields[@]}"; do
    local value
    value=$(echo "${response}" | jq -r ".${field} // empty")
    if [[ -z "${value}" ]]; then
      echo "  [FAIL]  缺少必要欄位：${field}（路徑：${path}）"
      FAIL=1
    else
      echo "  [OK]    欄位存在：${field} = ${value}"
    fi
  done
}

echo "=== L2 API 整合驗證開始 ==="
echo "目標 BASE_URL：${BASE_URL}"
echo ""

for entry in "${ENDPOINTS[@]}"; do
  read -r method path fields <<< "${entry}"
  validate_endpoint "${method}" "${path}" "${fields}"
done

echo ""
if [[ "${FAIL}" -eq 0 ]]; then
  echo "=== L2 驗證通過：所有端點 schema 驗證成功 ==="
  exit 0
else
  echo "=== L2 驗證失敗：發現一個或多個端點 schema 不符 ==="
  exit 1
fi
```

#### 步驟 3：範例 — 單一端點 curl + jq 快速驗證

若只需手動驗證單一端點，可直接複製以下 snippet：

```bash
# 範例：驗證 /health 端點回應包含 status 與 version 欄位
curl --silent --fail \
  --request GET \
  --header "Authorization: Bearer ${API_TOKEN}" \
  --header "Accept: application/json" \
  "${API_BASE_URL}/health" \
| jq '
  if (.status != null and .version != null)
  then "PASS: status=\(.status), version=\(.version)"
  else error("FAIL: 缺少必要欄位 status 或 version")
  end
'

# 範例：驗證 /api/v1/users 回應為陣列且包含 id 欄位
curl --silent --fail \
  --request GET \
  --header "Authorization: Bearer ${API_TOKEN}" \
  --header "Accept: application/json" \
  "${API_BASE_URL}/api/v1/users" \
| jq '
  if (type == "array" and length > 0 and .[0].id != null)
  then "PASS: 回應為陣列，首筆資料 id=\(.[0].id)"
  else error("FAIL: 回應格式不符預期")
  end
'
```

### 驗證結果判斷

| 結果 | 說明 | 後續動作 |
|------|------|----------|
| 所有端點 PASS | L2 驗證通過 | 繼續 Release tag 流程 |
| 任一端點 FAIL | L2 驗證失敗 | **阻擋 Release tag**，依下方 Hard Gate 處理 |
| HTTP 連線失敗 | 環境未就緒 | 確認服務狀態後重試，逾時視為 FAIL |

<HARD-GATE>
L2 API 整合驗證失敗（任一端點回應 schema 不符或 HTTP 請求失敗）時，禁止打 Release tag。
必須修復 API 回應問題後，重新執行完整 L2 驗證並全部通過，方可繼續版本 tag 流程。
L2 驗證結果必須記錄於部署就緒檢查的 Checklist 備注欄。
</HARD-GATE>

---

## 5.2 L3 E2E 端對端驗證步驟（Soft Gate）

**目的**：在版本 tag 後透過 Playwright E2E 測試驗證完整使用者流程，補足 L2 API 驗證無法涵蓋的 UI 互動與跨服務整合場景。

> **注意**：L3 E2E 驗證為 **Soft Gate**。E2E 測試失敗時輸出 `[E2E-SOFT-GATE]`，需 PO 確認後方可繼續。建議在 Staging 環境完成 L2 API 驗證後執行。

> **模板路徑**：
> - Playwright workflow 模板：`.github/workflows/e2e.yml`
> - CI 環境 Firebase 登入腳本模板：`docs/templates/ci-firebase-login.js`

### 前置條件

- Staging / Production 環境服務已啟動並通過 L2 API 驗證
- 消費端專案已安裝 Playwright（`@playwright/test`）
- GitHub 倉庫已設定必要 Secrets（`YOUR_TEST_URL` 等）
- 若需要登入驗證：Firebase Service Account 已設定於 CI Secrets

### 啟用步驟

#### 步驟 1：複製 Playwright E2E Workflow 模板

將 `.github/workflows/e2e.yml` 複製至消費端專案的 `.github/workflows/` 目錄，並替換佔位符：

| 佔位符 | 說明 | 範例值 |
|--------|------|--------|
| `YOUR_NODE_VERSION` | Node.js 版本 | `"20"` |
| `YOUR_TEST_URL` | 測試目標服務 URL（設定於 GitHub Secrets） | `https://staging.example.com` |
| `YOUR_PLAYWRIGHT_REPORT_DIR` | Playwright 報告輸出目錄 | `playwright-report/` |
| `YOUR_PLAYWRIGHT_TRACES_DIR` | Playwright traces 輸出目錄 | `test-results/` |

#### 步驟 2（若需登入）：設定 CI Firebase 登入腳本

若 E2E 測試需要通過 Firebase Authentication 登入，複製 `docs/templates/ci-firebase-login.js` 並替換佔位符：

| 佔位符 / 環境變數 | 說明 |
|-------------------|------|
| `YOUR_PROJECT_ID` | Firebase 專案 ID |
| `YOUR_TEST_USER_UID` | 測試用 Firebase UID（需在 Firebase Auth 中已存在） |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Service Account JSON（設定於 CI Secrets，切勿硬編碼） |
| `FIREBASE_WEB_API_KEY` | Firebase Web API Key（設定於 CI Secrets） |

在 E2E 測試前執行腳本取得 ID Token：

```bash
# 在 workflow 步驟中捕獲 ID Token
ID_TOKEN=$(node scripts/ci-firebase-login.js)
export TEST_ID_TOKEN="${ID_TOKEN}"
```

#### 步驟 3：執行 E2E 測試並收集報告

tag-only workflow 會自動觸發（push `v*` tag 時）。手動執行方式：

```bash
npx playwright test
```

測試報告與 traces 會自動上傳至 GitHub Actions Artifact，保留 30 天（失敗的 traces 保留 7 天）。

### 驗證結果判斷

| 結果 | 說明 | 後續動作 |
|------|------|----------|
| 所有測試 PASS | L3 E2E 驗證通過 | 記錄至部署 Checklist 備注欄 |
| 測試失敗 | L3 E2E 驗證失敗 | 輸出 `[E2E-SOFT-GATE]`，記錄失敗原因，需 PO 確認後方可繼續 |
| CI 環境問題 | 環境未就緒 | 確認 Secrets 設定與服務狀態 |

> **提醒**：L3 驗證失敗為 Soft Gate，輸出 `[E2E-SOFT-GATE]` 後須記錄失敗原因，由 PO 確認是否繼續；建議排入下個 Sprint 追蹤。

---

## 6. Golden Signals 監控

部署後必須持續監控以下四大黃金信號，確保服務健康：

| Signal | 說明 | 監控重點 |
|--------|------|----------|
| **Latency**（延遲） | 請求處理所需時間 | P50 / P95 / P99 延遲是否在基線範圍內 |
| **Traffic**（流量） | 系統承受的請求量 | QPS / RPS 是否符合預期，有無異常波動 |
| **Errors**（錯誤率） | 失敗請求的比例 | 5xx 錯誤率是否低於閾值，錯誤類型分布 |
| **Saturation**（飽和度） | 資源使用程度 | CPU / Memory / Disk / Connection Pool 使用率 |

部署後若任一 Signal 超出閾值，立即啟動回滾程序。

### 6.1 Golden Signals 人工可操作監控 Checklist

部署後 SRE subagent 依序執行以下逐項檢查，確認每項狀態後打勾：

#### Latency（延遲）檢查

- [ ] **查詢 P50 延遲**：確認在基線值 ±20% 範圍內
  - 基線值（填入）：\_\_\_ ms | 目前值：\_\_\_ ms
  - 超出閾值時：檢查慢查詢日誌、N+1 查詢問題、資料庫索引使用情況
- [ ] **查詢 P95 延遲**：確認未超過 SLO 定義的 P95 目標
  - SLO 目標（填入）：\_\_\_ ms | 目前值：\_\_\_ ms
  - 超出閾值時：分析長尾延遲來源（逾時請求、GC pause、鎖競爭）
- [ ] **查詢 P99 延遲**：確認未出現顯著上升（相較部署前）
  - 超出閾值時：啟動回滾評估，P99 突升通常預示系統壓力問題

#### Traffic（流量）檢查

- [ ] **查詢目前 QPS/RPS**：確認與預期流量模式一致
  - 預期值（填入）：\_\_\_ req/s | 目前值：\_\_\_ req/s
  - 流量過低時：確認 Load Balancer 路由配置、服務發現是否正常
  - 流量異常高時：確認是否有 DDoS 攻擊、Bot 流量或功能引起的重試風暴
- [ ] **確認流量分布正常**：無異常地區集中或特定端點 spike

#### Errors（錯誤率）檢查

- [ ] **查詢 5xx 錯誤率**：確認低於告警閾值（通常 < 0.1%）
  - 告警閾值（填入）：\_\_\_ % | 目前值：\_\_\_ %
  - 超出閾值時：立即查看錯誤日誌，確認錯誤類型（資料庫錯誤？外部依賴？程式 bug？）
- [ ] **查詢 4xx 錯誤率**：排除正常的 404（資源不存在），確認無異常 4xx spike
- [ ] **確認錯誤類型分布**：新版本是否引入新的錯誤類型
  - 新錯誤類型出現時：對比部署前後的錯誤日誌，定位變更影響

#### Saturation（飽和度）檢查

- [ ] **CPU 使用率**：確認低於 70%（警戒線），若超過 80% 立即告警
  - 目前值：\_\_\_ % | 警戒閾值：70%
- [ ] **Memory 使用率**：確認低於 80%，關注是否有持續上升趨勢（記憶體洩漏）
  - 目前值：\_\_\_ % | 警戒閾值：80%
  - 持續上升時：確認有無記憶體洩漏，考慮滾動重啟
- [ ] **Connection Pool 使用率**：確認低於 80%，避免連線耗盡
  - 目前值：\_\_\_ % | 警戒閾值：80%
- [ ] **磁碟使用率**：確認低於 85%，關注日誌磁碟（高流量部署可能快速填滿）
  - 目前值：\_\_\_ % | 警戒閾值：85%

### 6.2 告警閾值設定建議

| Signal | 警告閾值（Warning） | 嚴重閾值（Critical） | 建議動作 |
|--------|-------------------|---------------------|---------|
| P95 Latency | > SLO 目標 80% | > SLO 目標 | 分析慢查詢，考慮 Canary 回滾 |
| 5xx 錯誤率 | > 0.05% | > 0.1% | 立即查看錯誤日誌，評估回滾 |
| CPU 使用率 | > 70% | > 85% | 確認是否需要擴容或優化 |
| Memory 使用率 | > 75% | > 90% | 確認記憶體洩漏，考慮重啟 |
| Connection Pool | > 70% | > 85% | 確認連線洩漏，限流或重啟 |

<HARD-GATE>
部署後 Golden Signals 監控窗口最短 10 分鐘。
任一 Signal 觸發 Critical 閾值，立即啟動 Incident Response 流程（參考 §12）。
</HARD-GATE>

---

## 7. SLO/SLI 驗證

部署前後必須驗證服務水準目標：

| 指標 | 目標 | 說明 |
|------|------|------|
| **SLO 可用性** | > 99.9% | 服務可用性目標 |
| **MTTR** | < 30 分鐘 | 平均修復時間，含偵測、診斷、修復全程 |
| **Error Budget** | 充足 | 部署前確認剩餘 Error Budget 足以承擔部署風險 |

### Error Budget 決策規則

- **Error Budget 充足**（> 50% 剩餘）：正常部署流程
- **Error Budget 緊張**（20%–50% 剩餘）：加強監控，縮小部署範圍（Canary 部署）
- **Error Budget 耗盡**（< 20% 剩餘）：凍結功能部署，僅允許可靠性修復部署

### 7.1 SLI 定義與量測方法

SLI（Service Level Indicator）是量測 SLO 達標的具體指標。每個 SLO 必須對應至少一個可量測的 SLI。

#### 可用性 SLI

**定義**：成功請求數 / 總請求數 × 100%

**量測方式**：
```
可用性 SLI = (總請求數 - 5xx 錯誤數) / 總請求數 × 100%
```

**量測步驟**：
1. 從監控系統查詢指定時間窗口的總請求數（`http_requests_total`）
2. 查詢同期的 5xx 錯誤請求數（`http_requests_total{status=~"5.."}`）
3. 計算可用性 = (總請求 - 5xx 錯誤) / 總請求 × 100%
4. 與 SLO 目標（例：99.9%）比較

**Error Budget 計算**：
```
Error Budget = (1 - SLO 目標) × 總量測時間
例：99.9% SLO，30 天窗口 → Error Budget = 0.1% × 43,200 分鐘 = 43.2 分鐘
```

**本月 Error Budget 消耗量測**：
- 查詢本月累計停機時間（5xx 錯誤率超過閾值的持續時間）
- 計算已消耗 Error Budget 百分比 = 累計停機 / Error Budget × 100%

#### 延遲 SLI

**定義**：X% 請求的延遲低於目標閾值

**量測方式**：
```
延遲 SLI = 延遲 < 閾值的請求數 / 總請求數 × 100%
例：P95 延遲 SLO 目標 500ms → SLI = 延遲 < 500ms 的請求比例
```

**量測步驟**：
1. 查詢延遲直方圖（histogram_quantile 或 percentile 函數）
2. 確認 P50、P95、P99 各百分位數值
3. 與 SLO 定義的目標閾值比較

> **效能基準交叉參照**：延遲 SLI 的量測基線值（P50 / P95 / P99 目標閾值）應與 §14 效能基準管理中定義的基線值保持一致。每次 Load Test 後若基線值更新，需同步更新本節的 SLO 閾值設定。模板參考：`docs/templates/performance-baseline-template.md`。

#### MTTR SLI

**定義**：平均修復時間（從事故偵測到服務恢復的平均時間）

**量測方式**：
```
MTTR = Σ(事故解除時間 - 事故偵測時間) / 事故總數
```

**量測步驟**：
1. 從 Post-mortem 記錄彙整本月/本季所有 SEV-1、SEV-2 事故
2. 計算每次事故的 TTR（Time to Recovery）= 解除時間 - 偵測時間
3. 計算平均值（MTTR）
4. 與目標（< 30 分鐘）比較

### 7.2 SLO 達標追蹤 Checklist（部署前）

- [ ] 查詢本月已消耗 Error Budget 百分比：\_\_\_ %
- [ ] 確認 Error Budget 狀態（充足 > 50% / 緊張 20-50% / 耗盡 < 20%）
- [ ] 查詢近 7 天可用性 SLI：\_\_\_ %（目標：> 99.9%）
- [ ] 查詢近 7 天 P95 延遲：\_\_\_ ms（目標：< \_\_\_ ms）
- [ ] 查詢近 3 個月 MTTR：\_\_\_ 分鐘（目標：< 30 分鐘）
- [ ] 根據 Error Budget 狀態決定部署策略（見 Error Budget 決策規則）

<HARD-GATE>
SLI 量測結果必須記錄於部署就緒 Checklist 備注欄。
Error Budget 耗盡時禁止功能部署，PO Override 不適用此規則。
</HARD-GATE>

---

## 8. 可靠性架構

部署方案必須考慮以下可靠性設計：

| 模式 | 說明 | 驗證要點 |
|------|------|----------|
| **冗餘設計** | 關鍵服務多副本部署，消除單點故障 | 確認副本數量、跨區域分布 |
| **斷路器模式** | 依賴服務異常時自動斷路，防止級聯故障 | 確認斷路閾值、半開策略、降級行為 |
| **優雅降級** | 部分功能不可用時，核心功能維持運作 | 確認降級策略、使用者體驗影響 |
| **健康檢查端點** | 提供標準化健康檢查介面 | 確認 liveness / readiness probe 配置 |

### 8.1 斷路器（Circuit Breaker）實作 Checklist

斷路器防止對異常依賴服務的持續呼叫，避免級聯故障（Cascading Failure）。

#### 斷路器三種狀態

```
Closed（正常）→ 錯誤率超過閾值 → Open（斷路）→ 半開計時器到期 → Half-Open（試探）
                                                      ↑                    |
                                                      |── 試探失敗 ←────────|
                                                      |── 試探成功 → Closed ←┘
```

#### 斷路器設定 Checklist

- [ ] **定義被保護的外部依賴清單**（資料庫、第三方 API、微服務）
  - 依賴 1：\_\_\_ | 依賴 2：\_\_\_ | 依賴 3：\_\_\_
- [ ] **設定斷路閾值（Open 條件）**
  - 錯誤率閾值：\_\_\_ %（建議：50%，在固定時間窗口 N 秒內）
  - 最小請求數：\_\_\_ 次（建議：10 次，避免冷啟動誤斷）
- [ ] **設定 Open 狀態持續時間**（進入 Half-Open 的等待時間）
  - 等待時間：\_\_\_ 秒（建議：30-60 秒，依依賴服務恢復速度調整）
- [ ] **設定 Half-Open 試探策略**
  - 試探請求數：\_\_\_ 次（建議：1-3 次）
  - 成功恢復條件：全部試探請求成功 → 回到 Closed
  - 失敗條件：任一試探失敗 → 回到 Open（重置等待計時器）
- [ ] **定義斷路時的降級行為**（見 §8.2 降級策略 Checklist）
- [ ] **確認斷路器狀態可觀測**：斷路器狀態變化應觸發監控告警
- [ ] **測試斷路器行為**：在 Staging 環境模擬依賴服務異常，確認斷路器正確觸發

#### 斷路器告警設定

| 告警事件 | 嚴重性 | 動作 |
|---------|--------|------|
| 斷路器進入 Open 狀態 | SEV-2 | 立即調查依賴服務狀態，啟動 Incident Response |
| 斷路器 Open 持續 > 5 分鐘 | SEV-1 | 升級 Incident，確認降級方案是否有效 |
| 斷路器頻繁開關（震盪） | SEV-3 | 調整閾值或修復依賴服務不穩定問題 |

### 8.2 降級策略（Graceful Degradation）實作 Checklist

降級策略確保當部分依賴異常時，核心功能仍能運作，降低使用者影響。

#### 降級策略設計 Checklist

- [ ] **識別核心功能 vs. 非核心功能**
  - 核心功能（絕對不能降級）：\_\_\_
  - 可降級功能（依賴異常時可降低服務質量）：\_\_\_
  - 可完全停用功能（依賴異常時可暫停）：\_\_\_

- [ ] **為每個可降級功能定義降級策略**

| 功能 | 依賴服務 | 降級策略 | 使用者感知 |
|------|---------|---------|---------|
| [功能名稱] | [依賴服務] | [Cache Fallback / 靜態回應 / 功能停用] | [影響描述] |
| [功能名稱] | [依賴服務] | [Cache Fallback / 靜態回應 / 功能停用] | [影響描述] |

- [ ] **Cache Fallback 策略**（若使用快取作為降級方案）
  - 確認快取 TTL 設定合理（不會服務過期資料太久）
  - 確認快取在依賴異常前已有足夠的暖機時間
  - 確認快取資料的一致性影響可接受

- [ ] **靜態回應策略**（若使用預設值作為降級回應）
  - 定義各端點的安全靜態回應（不洩漏敏感資訊）
  - 確認靜態回應不會造成使用者資料不一致

- [ ] **功能停用策略**（若決定暫停特定功能）
  - 確認 UI 有適當的降級提示訊息（「功能暫時不可用」）
  - 確認停用功能不會影響核心使用流程

#### 降級觸發 Checklist（部署前驗證）

- [ ] 降級策略已在 Staging 環境測試（模擬依賴服務下線）
- [ ] 降級模式下的使用者體驗已由 PM/PO 確認可接受
- [ ] 降級狀態有對應的監控告警（確認降級模式被觸發時能感知）
- [ ] 降級後的核心 SLO 目標已重新定義（降級模式下的可用性目標）
- [ ] 降級恢復流程已定義（依賴服務恢復後如何自動/手動退出降級模式）

### 8.3 可靠性架構部署前 Checklist

- [ ] **冗餘設計**：關鍵服務副本數 ≥ 2，確認跨節點/跨可用區分布
- [ ] **斷路器**：所有外部依賴已設定斷路器（見 §8.1）
- [ ] **降級策略**：所有可降級功能已定義降級策略並測試（見 §8.2）
- [ ] **健康檢查**：`/healthz`（liveness）和 `/readyz`（readiness）端點已實作
- [ ] **Timeout 設定**：所有外部呼叫已設定合理 Timeout（避免無限等待）
- [ ] **Retry 策略**：已設定 Exponential Backoff with Jitter，避免重試風暴
- [ ] **負載測試**：已在 Staging 環境執行負載測試，確認服務在預期流量下穩定

<HARD-GATE>
斷路器缺失或降級策略未定義的依賴服務，部署前必須補充，否則不得執行 Production 部署。
Liveness 與 Readiness Probe 必須正確配置，缺少任一視為 Checklist 未完成。
</HARD-GATE>

---

## 9. Hard Gates

<HARD-GATE>
不可修改業務邏輯——業務邏輯變更屬於 Architect 權限範疇。
SRE 僅負責部署、監控與可靠性相關事務。
</HARD-GATE>

<HARD-GATE>
必須先規劃並驗證回滾方案，才能執行任何部署。
回滾方案需包含：觸發條件、執行步驟、驗證程序、預估時間。
</HARD-GATE>

<HARD-GATE>
Toil（重複性手動操作）不得超過 50% 工時。
若發現 Toil 超標，必須優先排入自動化改善任務。
</HARD-GATE>

---

## 10. 與其他 Skill 的關係

| 情境 | 觸發 |
|------|------|
| 部署前發現架構問題 | 暫停，觸發 `architecture-decision` → ADR 定案後回到 deployment-readiness |
| 安全掃描發現重大漏洞 | 暫停，觸發 `security-review` 進行深度安全審查 → 修復後回到 deployment-readiness |
| 部署後發現品質問題 | 觸發回滾，然後觸發 `quality-gate` 重新審查 |
| 需要新功能才能部署 | 回到 `sprint-execution` 完成實作 → 重新觸發 deployment-readiness |
| Sprint 全部 Stories 部署完成 | 觸發 `sprint-review` 進行驗收與回顧 |

---

## 11. CI/CD 環境偵測 — Self-hosted Runner 警示

**新增於**：Sprint 45（US-93，ADR-011 合規）

部署就緒檢查期間，SRE subagent 必須執行以下 CI/CD 環境偵測步驟，識別潛在的 self-hosted runner OOM 風險。

### 偵測步驟

1. **掃描現有 workflow 設定**

   執行下列指令，列出消費端專案所有 workflow 的 runner 配置：

   ```bash
   grep -rn "runs-on:" .github/workflows/
   ```

2. **判斷是否全部跑在 self-hosted runner**

   檢查輸出結果：
   - 若所有 `runs-on:` 值均包含 `self-hosted`，則進入步驟 3
   - 若已有 workflow 使用 `ubuntu-latest` 或其他 GitHub-hosted runner，則跳過本節

3. **自動提示 CI/CD 拆分建議**

   當偵測到現有 workflow 全部跑在 self-hosted runner 時，SRE subagent 必須輸出以下警示：

   ```
   [CI/CD 拆分建議]
   偵測到所有 GitHub Actions workflow 均配置於 self-hosted runner。

   Self-hosted runner 適合事件驅動型任務（issue_comment、webhook），
   但不適合 compute-heavy 任務（測試套件、建置、依賴安裝）。
   全部使用 self-hosted runner 可能導致：
   - 測試執行時 OOM（記憶體不足）
   - CI 失敗率上升

   建議依 docs/ci-cd-guide/README.md 決策樹拆分 workflow：
   - Compute-heavy 任務 → GitHub-hosted runner（ubuntu-latest）
   - Event-driven 任務  → Self-hosted runner

   模板參考：docs/ci-cd-guide/notify-comment.yml
   ```

4. **記錄偵測結果**

   將偵測結果記錄於部署就緒檢查的 Checklist 備注欄，供後續追蹤。

### 決策規則

| 偵測結果 | 動作 |
|---------|------|
| 所有 workflow 均跑在 self-hosted | 輸出 CI/CD 拆分建議警示，不阻擋部署 |
| 部分 workflow 已使用 GitHub-hosted | 無需動作，視為已拆分 |
| 無 `.github/workflows/` 目錄 | 無需動作，跳過此步驟 |

> **注意**：此偵測為建議性提示，不構成部署 Hard Gate 阻擋條件。但若消費端專案持續出現 CI 測試失敗，應將拆分建議列入下一 Sprint 技術債處理。

---

## 12. Incident Response — 事故應變

**新增於**：Sprint 86（US-237，SRE 完整化 Phase 1）

發生生產環境事故時，SRE subagent 依本節 SOP 執行事故應變，並使用 Runbook 模板記錄處理過程。

### 12.1 Incident Response 觸發條件

以下任一情況發生時，立即啟動 Incident Response 流程：

| 觸發條件 | 最低嚴重性 |
|---------|----------|
| Golden Signals 任一指標觸發 Critical 閾值（見 §6.2） | SEV-2 |
| 使用者回報核心功能異常 | SEV-2（確認後） |
| 部署後服務健康指標持續惡化 > 5 分鐘 | SEV-2 |
| 斷路器進入 Open 狀態（見 §8.1） | SEV-2 |
| 自動回滾觸發 | SEV-1（評估後） |
| 資料遺失或資安漏洞確認 | SEV-1 |

### 12.2 Incident Response 執行 SOP

```
事故觸發（告警 / 使用者回報 / 主動發現）
  |
  v
Step 1: 嚴重性判定（< 5 分鐘）
  使用 incident-runbook-template.md §1 決策樹判定 SEV 等級
  |
  v
Step 2: 建立通訊頻道，指定 Incident Commander（< 10 分鐘）
  Slack Channel: #incident-YYYYMMDD
  |
  v
Step 3: 診斷（執行 Runbook §4 診斷 Checklist）
  ├── 查看 Golden Signals（§6 監控 Checklist）
  ├── 查看錯誤日誌與最近部署記錄
  └── 確認影響範圍
  |
  v
Step 4: 緩解（優先恢復服務，再定位根因）
  ├── 是否為最近部署引發？→ 執行回滾
  ├── 是否為依賴服務異常？→ 確認斷路器已觸發降級
  └── 其他緩解措施（見 Runbook §4）
  |
  v
Step 5: 確認恢復（Golden Signals 全部恢復基線 > 10 分鐘）
  |
  v
Step 6: 事故解除宣告，安排 Post-mortem
  SEV-1/SEV-2：48 小時內完成 Post-mortem（見 §13）
  SEV-3：5 個工作天內完成
```

### 12.3 Runbook 使用指引

1. 複製 `docs/templates/incident-runbook-template.md` 建立事故專屬 Runbook
2. 命名格式：`docs/incidents/INC-YYYYMMDD-NNN-runbook.md`
3. 事故期間即時填寫第 5 節時間軸
4. 事故解除後，Runbook 成為 Post-mortem 的重要輸入資料

<HARD-GATE>
SEV-1 事故必須在 5 分鐘內確認並指定 Incident Commander。
SEV-1/SEV-2 事故必須在 48 小時內完成 Post-mortem 文件（見 §13）。
</HARD-GATE>

---

## 13. Post-mortem — 事故復盤 SOP

**新增於**：Sprint 86（US-237，SRE 完整化 Phase 1）

Post-mortem 是事故解除後的系統性復盤，目的是找出根本原因並防止再發，而非追究個人責任。

### 13.1 Post-mortem 執行原則

| 原則 | 說明 |
|------|------|
| **無責文化（Blameless）** | 聚焦系統與流程改善，不追究個人失誤 |
| **時效性** | SEV-1/SEV-2 事故 48 小時內完成，SEV-3 五個工作日內完成 |
| **完整性** | 5 Whys 必須挖掘至根本原因，不停留在表面現象 |
| **可執行性** | Action Items 必須具體、有負責人、有截止日期 |

### 13.2 Post-mortem 執行 SOP

#### 步驟 1：召開 Post-mortem 會議

- **時間**：事故解除後 24-48 小時內（確保記憶新鮮，緊急修復已完成）
- **參與者**：Incident Commander、相關 SRE、Engineering Lead（視需要）
- **時長**：60-90 分鐘（SEV-1），30-60 分鐘（SEV-2/SEV-3）
- **主持人**：建議由非事故直接涉入者主持，確保客觀性

#### 步驟 2：填寫 Post-mortem 文件

使用 `docs/templates/post-mortem-template.md`，依序完成：

1. **事故時間軸**（§1）：重建完整事故歷程，從第一個異常信號到解除
2. **5 Whys 分析**（§2）：逐層追問根本原因，不少於 3 層 Why
3. **影響評估**（§3）：量化使用者影響與 SLO 消耗
4. **Action Items**（§4）：制定防止再發的具體改善行動
5. **復盤討論摘要**（§5）：記錄 What went well / What could be improved

#### 步驟 3：Action Items 追蹤

- Action Items 在會議當天錄入 Sprint Backlog（即時建立對應 Story/Task）
- 立即修復項目（< 1 週）：本 Sprint 內追蹤
- 短期改善項目：排入下個 Sprint 或本 Sprint 剩餘工作
- 長期防護項目：列入 ROADMAP 技術債

#### 步驟 4：Post-mortem 歸檔

- 命名格式：`docs/incidents/INC-YYYYMMDD-NNN-postmortem.md`
- 發布至相關 Slack Channel，確保團隊學習共享
- 更新 `docs/km/Metrics_Log.md`：記錄事故編號、MTTR、根因類別

### 13.3 Post-mortem 文件使用指引

1. 複製 `docs/templates/post-mortem-template.md` 建立事故 Post-mortem
2. 命名格式：`docs/incidents/INC-YYYYMMDD-NNN-postmortem.md`
3. 5 Whys 分析：每個 Why 的答案必須具體，避免「流程不完善」等模糊陳述
4. Action Items 必須使用 SMART 原則（Specific / Measurable / Achievable / Relevant / Time-bound）

### 13.4 Post-mortem 品質 Checklist

SRE subagent 在提交 Post-mortem 前確認：

- [ ] 時間軸完整，涵蓋從偵測到解除的全程
- [ ] 5 Whys 已執行至少 3 層，根本原因已識別
- [ ] 影響評估包含量化數據（使用者數、停機時長、Error Budget 消耗）
- [ ] Action Items 均有具體負責人與截止日期
- [ ] 至少一個 Action Items 對應監控告警改善（防止相同告警遺漏）
- [ ] 至少一個 Action Items 已錄入 Sprint Backlog 或 ROADMAP
- [ ] 無責文化：文件無個人失誤追究性語言

<HARD-GATE>
Post-mortem 文件未完成，不得將事故標記為完全解決。
Action Items 未錄入 Sprint Backlog，下個 Sprint Review 將標記為未追蹤事項。
</HARD-GATE>

---

## 14. 效能基準管理

**新增於**：Sprint 87（US-238，效能基準管理 Phase 1）

本節定義效能基準（Performance Baseline）的格式規格、Load Test 觸發時機，以及效能回歸偵測的告警邏輯。與 §8.3 負載測試 Checklist 整合：§8.3 確認「負載測試已執行」，本節定義「如何量測、記錄與比對基線值」。

### 14.1 效能基準（Baseline）定義格式規格

每個受管理的效能指標必須以下列格式記錄於 `docs/templates/performance-baseline-template.md`（填寫後複製至 `docs/performance/` 目錄存檔）：

| 欄位 | 說明 | 範例 |
|------|------|------|
| **指標名稱** | 明確描述被量測的指標，需唯一可識別 | `API P95 延遲 — /api/v1/search` |
| **量測方法** | 具體說明如何取得數據，包含工具指令或查詢語法 | `k6 load test，`histogram_quantile(0.95, ...)` |
| **基線值** | 在正常負載下量測到的參考值，附量測時間與環境 | `320ms（Staging，2026-03-01，100 VU 持續 10 分鐘）` |
| **告警閾值 — Warning** | 偏離基線值的警告邊界（百分比或絕對值） | `> 基線值 +20%（> 384ms）` |
| **告警閾值 — Critical** | 偏離基線值的嚴重邊界，超過時阻擋部署或觸發事故 | `> 基線值 +50%（> 480ms）` |
| **量測工具** | 使用的 Load Test 或監控工具名稱與版本 | `k6 v0.50.0、Grafana Dashboard ID: 12345` |

#### 基線值更新規則

- **更新時機**：Load Test 結果顯示持續優化（基線值降低 ≥ 10%）時，由 SRE subagent 更新基線值
- **更新流程**：填寫新基線值 → 記錄量測時間與環境 → 同步更新 §7.1 延遲 SLI 閾值（若適用） → Commit 變更
- **版本追蹤**：每次基線更新須在文件末尾的「變更記錄」區段附上日期與變更原因

### 14.2 Load Test 觸發時機指引

以下三種場景必須執行 Load Test，SRE subagent 需確認觸發條件後依步驟執行：

---

#### 場景一：部署前 Load Test

**觸發條件**：
- Sprint Review 驗收通過，準備執行 Production 部署前
- 部署內容涉及核心 API 端點或資料庫查詢邏輯變更

**執行步驟**：
1. 確認 Staging 環境已部署待部署版本
2. 執行基準 Load Test（與上次基線量測相同參數：VU 數、持續時間、端點清單）
3. 收集 P50 / P95 / P99 延遲、錯誤率、吞吐量（RPS）
4. 與 §14.1 基線值比對，判定是否觸發告警（見 §14.3）
5. 記錄結果於部署 Checklist 備注欄，更新 §5「效能基準驗證通過」項目
6. 若 Critical 閾值未觸發，繼續部署流程；若觸發，阻擋部署並排查效能回歸

---

#### 場景二：效能相關 PR 的 Load Test

**觸發條件**（滿足以下任一條件時觸發）：
- PR 修改了資料庫查詢、快取策略、演算法複雜度相關邏輯
- PR 標籤（Label）包含 `perf`、`performance` 或 `load-test-required`
- PR 涉及的端點在上次 Load Test 中的 P95 延遲已接近 Warning 閾值（>80% 閾值）

**執行步驟**：
1. 在 PR Review 階段，由 Reviewer 判定是否觸發（依上述條件）
2. 部署 PR 分支至 Staging 環境（可使用 Preview 部署）
3. 執行針對受影響端點的局部 Load Test（最少 5 分鐘，50 VU）
4. 對比 PR 分支結果與 main 分支基線值，計算偏差百分比
5. 若偏差超過 Warning 閾值，在 PR Comment 標注 `[PERF-WARNING]` 並要求作者說明
6. 若偏差超過 Critical 閾值，在 PR Comment 標注 `[PERF-BLOCK]`，阻擋 PR 合併直至效能問題解決

---

#### 場景三：定期排程 Load Test

**觸發條件**：
- 每個 Sprint 結束前（Sprint 倒數第 2 個工作日）
- 或距離上次 Load Test 超過 14 天（無論 Sprint 進度）

**執行步驟**：
1. 執行完整 Load Test 套件（涵蓋所有已定義基線的端點）
2. 逐一對比各指標與 §14.1 中的基線值
3. 識別效能趨勢：連續 2 次排程 Load Test 顯示同一指標接近 Warning 閾值時，主動排入下個 Sprint 效能優化任務
4. 若所有指標在 Warning 閾值內：更新 `docs/performance/` 中的 Load Test 記錄（附日期與環境）
5. 若有指標超過 Warning 閾值：建立效能改善 Story，排入下個 Sprint Backlog
6. 若有指標超過 Critical 閾值：立即升級，不等待 Sprint 邊界，當天排入修復

---

### 14.3 效能回歸偵測告警閾值定義

#### 比對邏輯

每次 Load Test 完成後，依下列公式計算各指標的偏差百分比：

```
偏差百分比 = (當次量測值 - 基線值) / 基線值 × 100%
```

- 偏差百分比為**正值**（當次值 > 基線值）：效能退化，需依下表判定告警等級
- 偏差百分比為**負值**（當次值 < 基線值）：效能改善，記錄並評估是否更新基線值

#### 偏差百分比閾值

| 指標類型 | Warning 閾值 | Critical 閾值 | 建議動作 |
|---------|------------|--------------|---------|
| P95 延遲 | > +20% | > +50% | Warning：分析慢查詢；Critical：阻擋部署，立即排查 |
| P99 延遲 | > +30% | > +80% | Warning：記錄並追蹤；Critical：阻擋部署，啟動 Incident Response |
| 錯誤率 | > +50%（絕對值 > 0.05%） | > +100%（絕對值 > 0.1%） | Warning：檢查錯誤日誌；Critical：阻擋部署 |
| 吞吐量（RPS） | < -15%（下降） | < -30%（下降） | Warning：確認資源使用率；Critical：阻擋部署，確認服務容量 |
| P50 延遲 | > +25% | > +60% | Warning：追蹤趨勢；Critical：阻擋部署 |

> **閾值說明**：表中百分比為相對基線值的偏差。閾值設定應參考 §6.2 Golden Signals 告警閾值，兩者保持一致；若針對特定服務有調整，在 `docs/performance/` 基線文件中標注覆蓋值。

#### 告警動作

| 告警等級 | 觸發動作 | 通知對象 | 阻擋部署？ |
|---------|---------|---------|----------|
| **Warning** | 在 Load Test 報告中標注 `[PERF-WARNING]`，建立效能追蹤 Task，排入下個 Sprint | SRE subagent、Engineering Lead | 否 |
| **Critical** | 在 Load Test 報告中標注 `[PERF-CRITICAL]`，立即通知，禁止繼續部署流程 | SRE subagent、Engineering Lead、PO | **是** |
| **改善** | 更新基線值記錄，同步 §7.1 延遲 SLI 閾值 | SRE subagent | — |

<HARD-GATE>
Load Test 結果觸發 Critical 閾值時，禁止繼續部署流程。
必須完成效能回歸根因分析並修復後，重新執行 Load Test 且結果在 Warning 閾值以內，方可繼續部署。
Load Test 結果必須記錄於部署就緒 Checklist 備注欄，§5「效能基準驗證通過」項目需附量測結果摘要。
</HARD-GATE>

### 14.4 Load Test 與 §8.3 負載測試 Checklist 整合說明

§8.3 負載測試 Checklist 項目「已在 Staging 環境執行負載測試，確認服務在預期流量下穩定」與本節整合如下：

- **§8.3 負責**：確認「是否已執行負載測試」這個動作（Go / No-Go 決策）
- **§14 負責**：定義「如何執行、如何量測、如何判定結果」的完整規格
- **§5 負責**：「效能基準驗證通過」為部署前的最終確認項目，需 §14.3 比對結果支持

SRE subagent 在部署前應依序：§14.2（觸發 Load Test）→ §14.3（比對告警閾值）→ §8.3（打勾負載測試完成）→ §5（打勾效能基準驗證通過）。
