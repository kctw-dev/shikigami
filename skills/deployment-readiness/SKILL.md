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

---

## 8. 可靠性架構

部署方案必須考慮以下可靠性設計：

| 模式 | 說明 | 驗證要點 |
|------|------|----------|
| **冗餘設計** | 關鍵服務多副本部署，消除單點故障 | 確認副本數量、跨區域分布 |
| **斷路器模式** | 依賴服務異常時自動斷路，防止級聯故障 | 確認斷路閾值、半開策略、降級行為 |
| **優雅降級** | 部分功能不可用時，核心功能維持運作 | 確認降級策略、使用者體驗影響 |
| **健康檢查端點** | 提供標準化健康檢查介面 | 確認 liveness / readiness probe 配置 |

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
