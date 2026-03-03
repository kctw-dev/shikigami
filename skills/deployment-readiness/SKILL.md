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
