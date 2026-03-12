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

## 5.1 L2 API 整合驗證

**目的**：在版本 tag 前驗證關鍵 API 端點的 response schema，補足 unit test 無法覆蓋的跨服務整合驗證。

### 驗證步驟摘要

1. **定義端點清單**：在部署腳本或 CI workflow 中配置待驗證端點（格式：`METHOD PATH REQUIRED_FIELDS`）
2. **執行 Schema 驗證**：對每個端點發送請求，確認回應包含所有必要欄位且非 null
3. **收集結果**：逐端點記錄 PASS/FAIL，任一失敗即整體 FAIL

> **前置條件**：目標環境 API 已啟動、具備 API 呼叫權限、`curl` 與 `jq` 已安裝。

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

**目的**：在版本 tag 後透過 Playwright E2E 測試驗證完整使用者流程。

> **注意**：L3 E2E 驗證為 **Soft Gate**。失敗時輸出 `[E2E-SOFT-GATE]`，需 PO 確認後方可繼續。

> **模板參照**：Playwright workflow 模板 `.github/workflows/e2e.yml`、Firebase 登入腳本 `docs/templates/ci-firebase-login.js`。依模板內佔位符說明設定即可。

### 驗證結果判斷

| 結果 | 說明 | 後續動作 |
|------|------|----------|
| 所有測試 PASS | L3 E2E 驗證通過 | 記錄至部署 Checklist 備注欄 |
| 測試失敗 | L3 E2E 驗證失敗 | 輸出 `[E2E-SOFT-GATE]`，記錄失敗原因，需 PO 確認後方可繼續 |
| CI 環境問題 | 環境未就緒 | 確認 Secrets 設定與服務狀態 |

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

### 6.1 Golden Signals 部署後監控規則

部署後 SRE subagent 依序檢查以下四類指標，任一超出閾值時依「異常處置」欄動作執行：

| 類別 | 檢查項目 | 閾值 | 異常處置 |
|------|---------|------|---------|
| **Latency** | P50 延遲 | 基線值 ±20% | 檢查慢查詢、N+1、索引 |
| | P95 延遲 | ≤ SLO P95 目標 | 分析長尾來源（逾時、GC pause、鎖競爭） |
| | P99 延遲 | 未顯著上升 | 啟動回滾評估 |
| **Traffic** | QPS/RPS | 與預期流量一致 | 過低：查 LB/服務發現；過高：查 DDoS/重試風暴 |
| | 流量分布 | 無異常集中 | 確認地區/端點分布 |
| **Errors** | 5xx 錯誤率 | < 0.1% | 立即查錯誤日誌，定位錯誤類型 |
| | 4xx 錯誤率 | 無異常 spike（排除正常 404） | 對比部署前後差異 |
| | 錯誤類型分布 | 無新錯誤類型 | 對比部署前後錯誤日誌 |
| **Saturation** | CPU | < 70%（警戒）/ 80%（告警） | 確認擴容或優化需求 |
| | Memory | < 80% 且無持續上升 | 確認記憶體洩漏，考慮滾動重啟 |
| | Connection Pool | < 80% | 確認連線洩漏，限流或重啟 |
| | 磁碟 | < 85% | 關注日誌磁碟填充速度 |

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

| SLI | 公式 | 量測來源 |
|-----|------|---------|
| **可用性** | `(總請求數 - 5xx 錯誤數) / 總請求數 × 100%` | `http_requests_total`、`http_requests_total{status=~"5.."}` |
| **延遲** | `延遲 < 閾值的請求數 / 總請求數 × 100%` | histogram_quantile（P50/P95/P99） |
| **MTTR** | `Σ(解除時間 - 偵測時間) / 事故總數` | Post-mortem 記錄（SEV-1/SEV-2） |

**Error Budget 計算**：`(1 - SLO 目標) × 總量測時間`（例：99.9% SLO，30 天 → 43.2 分鐘）。已消耗百分比 = 累計停機 / Error Budget × 100%。

> **效能基準交叉參照**：延遲 SLI 基線值應與 §14 效能基準保持一致。Load Test 更新基線時需同步更新本節 SLO 閾值。模板：`docs/templates/performance-baseline-template.md`。

### 7.2 SLO 達標追蹤（部署前）

部署前 SRE subagent 必須查詢以下指標並記錄於 Checklist 備注欄：

| 查詢項目 | 目標 |
|---------|------|
| 本月 Error Budget 消耗百分比 | 依 Error Budget 決策規則判定部署策略 |
| 近 7 天可用性 SLI | > 99.9% |
| 近 7 天 P95 延遲 | < SLO 定義閾值 |
| 近 3 個月 MTTR | < 30 分鐘 |

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

### 8.1 斷路器（Circuit Breaker）設定規則

```
Closed（正常）→ 錯誤率超過閾值 → Open（斷路）→ 半開計時器到期 → Half-Open（試探）
                                                      ↑                    |
                                                      |── 試探失敗 ←────────|
                                                      |── 試探成功 → Closed ←┘
```

#### 斷路器核心設定

| 設定項目 | 建議值 | 說明 |
|---------|--------|------|
| 斷路閾值（錯誤率） | 50%（固定時間窗口內） | Open 觸發條件 |
| 最小請求數 | 10 次 | 避免冷啟動誤斷 |
| Open 持續時間 | 30-60 秒 | 依依賴服務恢復速度調整 |
| Half-Open 試探數 | 1-3 次 | 全部成功 → Closed；任一失敗 → Open |

**部署前必須確認**：外部依賴清單已定義、降級行為已對應（§8.2）、斷路器狀態可觀測、Staging 環境已測試斷路器觸發行為。

#### 斷路器告警設定

| 告警事件 | 嚴重性 | 動作 |
|---------|--------|------|
| 斷路器進入 Open 狀態 | SEV-2 | 立即調查依賴服務狀態，啟動 Incident Response |
| 斷路器 Open 持續 > 5 分鐘 | SEV-1 | 升級 Incident，確認降級方案是否有效 |
| 斷路器頻繁開關（震盪） | SEV-3 | 調整閾值或修復依賴服務不穩定問題 |

### 8.2 降級策略（Graceful Degradation）規則

#### 功能分級與降級策略類型

| 功能分級 | 定義 | 可用降級策略 |
|---------|------|------------|
| 核心功能 | 絕對不能降級 | — |
| 可降級功能 | 依賴異常時可降低服務品質 | Cache Fallback、靜態回應 |
| 可停用功能 | 依賴異常時可暫停 | 功能停用（需 UI 提示） |

#### 降級策略驗證要點

| 策略類型 | 驗證要點 |
|---------|---------|
| Cache Fallback | TTL 合理、暖機充足、一致性影響可接受 |
| 靜態回應 | 不洩漏敏感資訊、不造成資料不一致 |
| 功能停用 | UI 有降級提示、不影響核心流程 |

**部署前必須確認**：Staging 環境已測試降級策略、PO 已確認降級體驗可接受、降級狀態有監控告警、降級模式 SLO 目標已定義、恢復流程已定義。

### 8.3 可靠性架構部署前必要項目

| 項目 | 驗證標準 |
|------|---------|
| 冗餘設計 | 關鍵服務副本數 ≥ 2，跨節點/跨可用區 |
| 斷路器 | 所有外部依賴已設定（見 §8.1） |
| 降級策略 | 所有可降級功能已定義並測試（見 §8.2） |
| 健康檢查 | `/healthz`（liveness）+ `/readyz`（readiness）已實作 |
| Timeout | 所有外部呼叫已設定合理 Timeout |
| Retry 策略 | Exponential Backoff with Jitter |
| 負載測試 | Staging 環境已執行，服務在預期流量下穩定 |

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

1. 掃描 `grep -rn "runs-on:" .github/workflows/`，列出所有 workflow 的 runner 配置
2. 若所有 `runs-on:` 均為 `self-hosted`，輸出 `[CI/CD 拆分建議]` 警示：建議依 `docs/ci-cd-guide/README.md` 決策樹將 compute-heavy 任務移至 GitHub-hosted runner（OOM 風險），event-driven 任務保留 self-hosted
3. 記錄偵測結果於部署 Checklist 備注欄

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

1. **召開會議**：事故解除後 24-48 小時內，SEV-1 時長 60-90 分鐘，SEV-2/3 時長 30-60 分鐘，由非事故直接涉入者主持
2. **填寫文件**：複製 `docs/templates/post-mortem-template.md`，依模板完成時間軸、5 Whys（≥ 3 層）、影響評估、Action Items、復盤摘要
3. **Action Items 追蹤**：會議當天錄入 Sprint Backlog；立即修復（< 1 週）本 Sprint 追蹤，短期排入下 Sprint，長期列入 ROADMAP
4. **歸檔**：命名 `docs/incidents/INC-YYYYMMDD-NNN-postmortem.md`，更新 `docs/km/Metrics_Log.md`（事故編號、MTTR、根因類別）

> **品質要求**：5 Whys 答案必須具體（禁止「流程不完善」等模糊陳述），Action Items 須符合 SMART 原則。

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

| 場景 | 觸發條件 | 測試範圍 | 結果處理 |
|------|---------|---------|---------|
| **部署前** | Sprint Review 通過 + 涉及核心 API/DB 變更 | 與上次基線相同參數（VU、時長、端點） | 比對 §14.1 基線 → Critical 阻擋部署 |
| **效能相關 PR** | PR 修改 DB/快取/演算法，或 Label 含 `perf`/`load-test-required`，或 P95 已接近 Warning 80% | 受影響端點局部測試（≥ 5 分鐘，50 VU） | Warning → PR Comment `[PERF-WARNING]`；Critical → `[PERF-BLOCK]` 阻擋合併 |
| **定期排程** | Sprint 倒數第 2 個工作日，或距上次 > 14 天 | 所有已定義基線端點完整測試 | Warning → 建立效能改善 Story；Critical → 當天排入修復；連續 2 次接近 Warning → 主動排入優化 |

**共通流程**：收集 P50/P95/P99 延遲、錯誤率、RPS → 與 §14.1 基線比對（§14.3 偏差公式）→ 記錄結果於部署 Checklist 備注欄。

---

### 14.3 效能回歸偵測告警閾值定義

**比對公式**：`偏差% = (當次值 - 基線值) / 基線值 × 100%`。正值為退化（依下表告警），負值為改善（評估更新基線）。

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

### 14.4 Load Test 整合流程

部署前執行順序：§14.2（觸發 Load Test）→ §14.3（比對告警閾值）→ §8.3（打勾負載測試完成）→ §5（打勾效能基準驗證通過）。

---

## 15. Deploy Board — 部署狀態看板

**新增於**：Sprint 90（US-246，CI/CD Deploy 通知 Workflow）

Deploy Board 是 GitHub Issue 形式的部署狀態看板，追蹤 Staging/Production × Backend/Frontend/E2E 共 6 格的即時狀態，由 `deploy-notify.yml` workflow 自動更新。

### 15.1 Deploy Board 模板參照

| 模板 | 路徑 | 用途 |
|------|------|------|
| Deploy 通知 Workflow | `docs/templates/deploy-notify.yml` | CI workflow，監聽 deploy workflow 完成並自動更新 Board |
| Deploy Board 初始化腳本 | `docs/templates/deploy-board-init.sh` | 一次性腳本，建立 6 格看板 Issue |

### 15.2 部署前設定步驟

1. 執行 `docs/templates/deploy-board-init.sh` 初始化 Deploy Board Issue
2. 將輸出的 Issue 編號設定為 Repository Variable `DEPLOY_BOARD_ISSUE_NUMBER`
3. 複製 `docs/templates/deploy-notify.yml` 至 `.github/workflows/`，依模板內佔位符說明替換
4. 設定 `GH_TOKEN` Secret（需 `issues:write` 權限）

> **注意**：`workflow_run` 觸發的 context 不提供 `contents:read` 權限，因此 deploy-notify.yml **不可進行 checkout**。Board 更新操作直接透過 `gh` CLI 完成。

### 15.3 已知陷阱（來自 CloneAI Sprint 73-74 實戰）

| 陷阱 | 說明 | 解法 |
|------|------|------|
| `workflow_run` 無 checkout 權限 | 此觸發類型的 context 不提供 `contents:read`，無法執行 `actions/checkout` | 直接使用 `gh` CLI 操作，不需要 checkout |
| Board 更新 race condition | 多個 deploy workflow 同時完成時，並發更新 Issue body 可能造成資料遺失 | deploy-notify.yml 使用 `concurrency` group 串行化更新 |
| gcloud `--update-env-vars` 逗號解析 | gcloud CLI 的逗號分隔符在某些環境變數值含逗號時解析錯誤 | 改用 `'^::^'` 自訂分隔符（與 Board 無直接關係，但同批 Sprint 經驗） |
| Firebase Custom Token E2E admin API | Custom Token 需加 `admin` claim 才能呼叫 admin API | 在 `createCustomToken` 時傳入 `{ admin: true }` additionalClaims |
