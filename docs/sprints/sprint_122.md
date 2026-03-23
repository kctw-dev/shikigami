# Sprint 122 — CI 基礎設施修復

**Sprint Goal**：修復 CI 基礎設施三大故障點（GitHub App 安裝、unzip 缺失、Node.js 20 deprecation），恢復 Shikigami CI/CD 可靠度。
**期間**：2026-03-23 ~ 2026-03-30
**Velocity 目標**：5 pts（降速 Sprint：僅 3 stories READY，聚焦 CI 修復）

## Sprint Backlog

| # | Story | Size | Points | MoSCoW | 狀態 | 執行順序 |
|---|-------|------|--------|--------|------|----------|
| #423 | [SRE] CI failure: Claude Code GitHub App 未安裝 | S | 1 | Must | 完成（PR #445） | 1 |
| #442 | [SRE] CI failure: unzip 缺失導致 Bun setup 失敗 | S | 1 | Must | 完成（PR merged） | 2 |
| #424 | [SRE] Node.js 20 actions deprecated 遷移 | M | 3 | Must | 完成（PR #448） | 3 |

## PO 決策紀錄

### 為何接受 5pt Sprint（非目標 10pt）

- Architect 評估：#388（AC 未定義）、#394（PB Draft）NOT_READY，不可強行選入
- #443（compact 後 project_level 遺失）已作為 hotfix 合併（PR #444），不納入 Sprint 計點
- 其餘 sprint-candidate 均為 enhancement 功能，未經 Architect/QA 本輪 readiness 評估
- 聚焦 CI 修復比填充未就緒 stories 更有價值
- 連續 4 Sprint 100% 完成（118-121），偶爾降速聚焦基礎設施是健康的

### 執行順序（QA 建議）

1. **#423 先行**：安裝 GitHub App 是前提，否則後續 CI 驗證都會 401
2. **#442 次之**：修復 unzip 問題，恢復 Bun setup 穩定性
3. **#424 最後**：Node.js 20 遷移需人工審核（CI Actions 版本釘定規範），且 validate-ci-versions.sh 不存在需一併建立

## 技術決策

- #423 為人工操作（安裝 GitHub App），Story 負責產出操作指引與驗證腳本
- #442 修改 .github/workflows/，加入 apt-get install unzip 步驟
- #424 檢查 actions/checkout 與 oven-sh/setup-bun 是否有 Node.js 24 相容版本，建立 validate-ci-versions.sh，需人工審核版本升級

## 獨立性評估

| Story | 修改檔案 | 獨立性 |
|-------|---------|--------|
| #423 | GitHub App 設定（外部操作）+ 驗證文件 | 獨立 |
| #442 | .github/workflows/ | 獨立（但建議 #423 先完成） |
| #424 | .github/workflows/ + scripts/validate-ci-versions.sh | 與 #442 有檔案重疊，建議序列 |

## 平行分群

### Phase 1（可平行）
| Story | 標題 | Size | 說明 |
|-------|------|------|------|
| #423 | GitHub App 安裝 | S | 人工操作指引 + 驗證 |
| #442 | unzip 修復 | S | workflow 修改 |

### Phase 2（序列）
| Story | 標題 | Size | 說明 |
|-------|------|------|------|
| #424 | Node.js 20 遷移 | M | 需 #442 workflow 變更先合併，避免衝突 |

## 風險

| 風險 | 影響 | 緩解 |
|------|------|------|
| #423 需要 repo admin 權限安裝 GitHub App | 阻塞 | Stakeholder 已知，可即時操作 |
| #424 Actions 升級可能破壞 CI | 高 | 先在 branch 測試，人工審核後才合併 |
| validate-ci-versions.sh 不存在 | 低 | 納入 #424 一併建立 |
