---
name: deployment-readiness
description: "Use when preparing for deployment, version release, environment configuration changes, or production readiness checks"
---

# Deployment Readiness — SRE 主導部署就緒檢查

## 1. 概述

SRE Engineer 主導的部署就緒檢查 Skill，確保每次部署安全、可靠、可回滾。

部署前由 **SRE subagent** 準備部署計畫與回滾方案，同時 **Security subagent** 並行執行部署前安全掃描。兩者皆通過後方可執行部署，任一不通過則修復後重新審查。

> **Subagent Prompt 參照**：
> - SRE subagent：`skills/deployment-readiness/references/sre-prompt.md`（Golden Signals 監控、SLO/SLI 驗證、可靠性架構、Incident Response、Post-mortem、效能基準管理）
> - Security subagent：`skills/deployment-readiness/references/security-prompt.md`（部署前安全掃描、L2 API 整合驗證、L3 E2E 端對端驗證）

---

## 2. 核心原則

**安全部署 = 充分準備 + 並行驗證 + 可回滾保障**

- **雙軌並行**：SRE 準備部署計畫的同時，Security 執行安全掃描，縮短前置時間
- **回滾優先**：任何部署必須先有經過驗證的回滾方案，才能執行
- **可觀測性**：Golden Signals 監控確保部署後即時發現異常（詳見 `references/sre-prompt.md §6`）
- **Error Budget 驅動**：部署前確認 SLO Error Budget 充足，避免在預算不足時冒險部署（詳見 `references/sre-prompt.md §7`）

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
  回滾方案）           → 詳見 references/security-prompt.md
  → 詳見 references/sre-prompt.md
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
執行部署 Checklist 最終確認（§5）
  |
  v
執行部署
  |
  v
部署後 Golden Signals 監控驗證（references/sre-prompt.md §6）
  |
  v
更新部署文件 + 通知相關角色
```

### 步驟詳解

1. **部署請求觸發**：從 Sprint 完成的 Stories 或版本發布需求觸發部署就緒檢查。
2. **派遣 SRE subagent**：使用 `references/sre-prompt.md` 作為 prompt，準備完整部署計畫，包含部署步驟、環境配置變更、回滾方案與驗證程序。
3. **派遣 Security subagent（並行）**：使用 `references/security-prompt.md` 作為 prompt，執行部署前安全掃描，涵蓋依賴套件漏洞、配置安全性、機密資訊洩漏檢查。
4. **審查結果匯總**：兩個 subagent 的結果皆必須通過。任一不通過則產出問題清單，修復後重新審查。
5. **執行部署**：通過所有檢查後，按部署計畫執行部署。
6. **部署後驗證**：監控 Golden Signals，確認服務健康，驗證 SLO 達標（詳見 `references/sre-prompt.md §6`）。

---

## 4. 版本 Tag 管理

> **詳細規則**：見 `references/version-management.md`（版號策略、決策矩陣、Minor/Major/Patch 觸發條件、PO Override 機制）

Sprint Review 驗收通過後，由 SRE subagent 負責打 tag 與更新版號。

**執行步驟**：
1. 更新 `.claude-plugin/plugin.json` 與 `marketplace.json` 的 `version` 欄位
2. Commit：`chore: bump version to vX.Y.Z`
3. 打 tag：`git tag vX.Y.Z`，Push：`git push && git push --tags`

<HARD-GATE>
`plugin.json` 與 `marketplace.json` 的版號必須一致。
Tag 名稱必須與 `plugin.json` 的 version 欄位一致（加 `v` 前綴）。
安全掃描未通過時，禁止任何版號 bump，包括 PO Override 情況。
</HARD-GATE>

---

## 5. 部署 Checklist

每次部署前必須逐項確認：

| 項目 | 狀態 |
|------|------|
| 所有測試通過 | [ ] |
| 安全掃描通過（Security subagent 確認） | [ ] |
| 回滾方案已驗證 | [ ] |
| 環境變數已設定 | [ ] |
| 監控告警已配置 | [ ] |
| 部署文件已更新 | [ ] |
| 效能基準驗證通過（見 `references/sre-prompt.md §14`） | [ ] |

> **L2/L3 驗證**：API 整合驗證（L2）與 E2E 驗證（L3）由 Security subagent 執行，詳見 `references/security-prompt.md §5.1`、`§5.2`。

<HARD-GATE>
Checklist 中任一項目未勾選，不得執行部署。
回滾方案必須經過實際驗證（dry-run），不接受僅文件描述。
</HARD-GATE>

---

## 6. Hard Gates

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

## 7. 與其他 Skill 的關係

| 情境 | 觸發 |
|------|------|
| 部署前發現架構問題 | 暫停，觸發 `architecture-decision` → ADR 定案後回到 deployment-readiness |
| 安全掃描發現重大漏洞 | 暫停，觸發 `security-review` 進行深度安全審查 → 修復後回到 deployment-readiness |
| 部署後發現品質問題 | 觸發回滾，然後觸發 `quality-gate` 重新審查 |
| 需要新功能才能部署 | 回到 `sprint-execution` 完成實作 → 重新觸發 deployment-readiness |
| Sprint 全部 Stories 部署完成 | 觸發 `sprint-review` 進行驗收與回顧 |

---

## 8. CI/CD 環境偵測

> **詳細步驟**：見 `references/cicd-detection.md`（self-hosted runner 警示、偵測步驟、決策規則）

SRE subagent 於部署就緒檢查期間掃描 `.github/workflows/` runner 配置，識別潛在 OOM 風險並輸出建議（不阻擋部署）。

---

## 9. Deploy Board — 部署狀態看板

**新增於**：Sprint 90（US-246，CI/CD Deploy 通知 Workflow）

Deploy Board 是 GitHub Issue 形式的部署狀態看板，追蹤 Staging/Production × Backend/Frontend/E2E 共 6 格的即時狀態，由 `deploy-notify.yml` workflow 自動更新。

### 9.1 Deploy Board 模板參照

| 模板 | 路徑 | 用途 |
|------|------|------|
| Deploy 通知 Workflow | `docs/templates/deploy-notify.yml` | CI workflow，監聽 deploy workflow 完成並自動更新 Board |
| Deploy Board 初始化腳本 | `docs/templates/deploy-board-init.sh` | 一次性腳本，建立 6 格看板 Issue |

### 9.2 部署前設定步驟

1. 執行 `docs/templates/deploy-board-init.sh` 初始化 Deploy Board Issue
2. 將輸出的 Issue 編號設定為 Repository Variable `DEPLOY_BOARD_ISSUE_NUMBER`
3. 複製 `docs/templates/deploy-notify.yml` 至 `.github/workflows/`，依模板內佔位符說明替換
4. 設定 `GH_TOKEN` Secret（需 `issues:write` 權限）

> **注意**：`workflow_run` 觸發的 context 不提供 `contents:read` 權限，因此 deploy-notify.yml **不可進行 checkout**。Board 更新操作直接透過 `gh` CLI 完成。

### 9.3 已知陷阱（來自 CloneAI Sprint 73-74 實戰）

| 陷阱 | 說明 | 解法 |
|------|------|------|
| `workflow_run` 無 checkout 權限 | 此觸發類型的 context 不提供 `contents:read`，無法執行 `actions/checkout` | 直接使用 `gh` CLI 操作，不需要 checkout |
| Board 更新 race condition | 多個 deploy workflow 同時完成時，並發更新 Issue body 可能造成資料遺失 | deploy-notify.yml 使用 `concurrency` group 串行化更新 |
| gcloud `--update-env-vars` 逗號解析 | gcloud CLI 的逗號分隔符在某些環境變數值含逗號時解析錯誤 | 改用 `'^::^'` 自訂分隔符（與 Board 無直接關係，但同批 Sprint 經驗） |
| Firebase Custom Token E2E admin API | Custom Token 需加 `admin` claim 才能呼叫 admin API | 在 `createCustomToken` 時傳入 `{ admin: true }` additionalClaims |
