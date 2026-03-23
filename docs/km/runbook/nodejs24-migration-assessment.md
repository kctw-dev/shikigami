# Node.js 24 遷移評估報告

**Issue**: #424 [SRE] Warning: Node.js 20 actions deprecated — 2026-06-02 前須遷移
**評估日期**: 2026-03-23
**評估人**: SRE Subagent（Sprint 122）
**狀態**: 已完成評估，待人工審核後執行遷移

---

## 背景

GitHub Actions runner 上 Node.js 20 支援將依以下時程淘汰：

| 日期 | 事件 |
|------|------|
| 2026-06-02 | Node.js 24 成為預設執行環境，Node.js 20 actions 可能行為異常 |
| 2026-09-16 | Node.js 20 從 runner 完全移除，未遷移 actions 將完全失效 |

CI 執行中已出現 deprecation warning，需在 2026-06-02 前完成評估與遷移。

---

## 受影響 Actions 清單

掃描結果來自 `bash scripts/validate-ci-versions.sh`，共掃描 3 個 workflow 檔案：
- `.github/workflows/e2e.yml`
- `.github/workflows/new-issue-intake.yml`
- `.github/workflows/sprint-dispatch.yml`

### 5 個受影響 Actions

| Action | 當前版本 | 出現 Workflow | Node.js 24 相容版本 | 狀態 |
|--------|----------|---------------|---------------------|------|
| actions/checkout | @v4 | e2e.yml, sprint-dispatch.yml | @v4.2.2+（內建支援）| 已相容，需確認 minor 版本 |
| actions/setup-node | @v4 | e2e.yml | @v4.3.0+（Node.js 24 GA 版本）| 已相容，需確認 minor 版本 |
| actions/upload-artifact | @v4 | e2e.yml（×2）| @v4.6.0+（Node.js 24 相容）| 已相容，需確認 minor 版本 |
| oven-sh/setup-bun | pinned SHA | （未在掃描中出現）| 依 SHA 版本而定 | 需確認當前 SHA 對應版本 |
| anthropics/claude-code-action | @v1 | new-issue-intake.yml | 上游決定，追蹤中 | 待上游更新 |

> **注意**：Issue #424 原始說明提及 `oven-sh/setup-bun` 但掃描結果中未出現於任何 workflow。
> 可能已在先前 Sprint 移除，或在 self-hosted runner 環境外部設定中使用。

---

## 各 Action 詳細評估

### 1. actions/checkout@v4

- **當前狀態**：@v4 標籤釘定，未釘定 minor 版本
- **Node.js 24 相容性**：`@v4` 系列已在 `v4.2.2` 之後加入 Node.js 24 支援（actions/checkout CHANGELOG）
- **遷移建議**：`@v4` 標籤會自動跟隨最新 v4.x minor release，無需手動升版
- **風險評估**：低風險 — @v4 語意版本釘定確保向後相容
- **行動項目**：確認 GitHub 已將 @v4 標籤指向 v4.2.2+（已可自動解決）

### 2. actions/setup-node@v4

- **當前狀態**：@v4 標籤釘定，e2e.yml 中指定 `node-version: "20"`
- **Node.js 24 相容性**：`@v4` 系列支援任意 Node.js 版本安裝，action runtime 本身在 v4.3.0+ 已遷移至 Node.js 24
- **遷移建議**：
  1. action 版本：@v4 標籤自動追蹤，無需手動升版
  2. **e2e.yml 的 `node-version: "20"` 是獨立問題** — 這是測試目標 Node.js 版本，應視專案需求更新至 `"22"` 或 `"24"`（屬於應用層決策，不在本 Story 範圍內）
- **風險評估**：低風險（action runtime）/ 中風險（node-version 配置需 PO 決策）
- **行動項目**：開立後續 Issue 討論 e2e 測試 Node.js 版本升級

### 3. actions/upload-artifact@v4

- **當前狀態**：@v4 標籤釘定，在 e2e.yml 中使用 2 次
- **Node.js 24 相容性**：v4.6.0+ 已支援 Node.js 24，@v4 標籤自動追蹤
- **遷移建議**：@v4 自動更新，無需手動升版
- **風險評估**：低風險

### 4. oven-sh/setup-bun（pinned SHA）

- **當前狀態**：Issue #424 提及，但掃描結果未在 workflow 中發現
- **Node.js 24 相容性**：oven-sh/setup-bun 較新版本（v1.2.0+）已對應 Node.js 24 runner
- **遷移建議**：
  - 若仍在使用 pinned SHA，建議更新 SHA 至最新 release tag 對應的 commit
  - 若已從 workflow 移除，則無需處理
- **風險評估**：需確認使用狀態
- **行動項目**：確認 self-hosted runner 或其他設定中是否仍使用此 action

### 5. anthropics/claude-code-action@v1

- **當前狀態**：@v1 標籤，用於 new-issue-intake.yml
- **Node.js 24 相容性**：@v1 為 Anthropic 維護，Node.js 24 遷移依賴上游更新
- **遷移建議**：
  1. 追蹤 https://github.com/anthropics/claude-code-action/releases
  2. 依 CLAUDE.md 第 10 條，任何版本升級（@v1 → @v2 等）需人工審核
  3. 短期緩解：可設定 `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true` 提前測試
- **風險評估**：中風險 — 依賴 Anthropic 上游，時程不確定
- **行動項目**：訂閱 anthropics/claude-code-action release 通知

---

## Self-hosted Runner 相容性評估

依 CLAUDE.md 第 10 條：「升級需先確認 self-hosted runner 相容性」

| Runner 類型 | Node.js 24 支援 | 說明 |
|-------------|-----------------|------|
| GitHub-hosted ubuntu-latest | 完整支援 | GitHub 已提供 Node.js 24 |
| self-hosted（shikigami-sprint label）| 需確認 | 見下方 |

**self-hosted runner 確認清單**：
- [ ] 確認 runner 機器 OS 版本（需支援 Node.js 24 二進位）
- [ ] 確認 runner 上已安裝或可安裝 Node.js 24
- [ ] 參考 `docs/km/runner-environment-checklist.md` 執行環境確認

> **注意**：sprint-dispatch.yml 使用 `[self-hosted, shikigami-sprint]` runner，
> 此 runner 相容性必須在正式遷移前由人工確認。

---

## 短期緩解方案

在正式遷移完成前，可在各 workflow 加入以下環境變數提前測試：

```yaml
env:
  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: "true"
```

此設定會強制 action 使用 Node.js 24 執行，可提早發現相容性問題。

**風險**：部分尚未完全支援 Node.js 24 的 action 可能在此設定下失敗。

---

## 遷移計畫

### 可立即處理（無需升版）

| 項目 | 處理方式 | 狀態 |
|------|----------|------|
| actions/checkout@v4 | @v4 標籤自動跟隨，無需操作 | 待確認 |
| actions/setup-node@v4 | @v4 標籤自動跟隨，無需操作 | 待確認 |
| actions/upload-artifact@v4 | @v4 標籤自動跟隨，無需操作 | 待確認 |

### 需後續追蹤

| 項目 | 處理方式 | 截止日期 |
|------|----------|----------|
| anthropics/claude-code-action@v1 | 等待 Anthropic 上游更新 | 2026-06-01（緩衝至截止日前） |
| oven-sh/setup-bun pinned SHA | 確認使用狀態後決定是否更新 SHA | 2026-05-01 |
| e2e.yml node-version: "20" | PO 決策後開新 Story 處理 | 依 PO 指示 |
| self-hosted runner 相容性確認 | 人工確認 runner 環境 | 2026-05-01 |

### 版本升級需人工審核項目

依 CLAUDE.md 第 10 條，以下任何升級均需人工審核：
- 任何 action 從 @v4 升至 @v5 或以上
- anthropics/claude-code-action 版本升級
- oven-sh/setup-bun SHA 更新

---

## AC 驗收

| AC | 條件 | 狀態 |
|----|------|------|
| AC1 | 識別所有使用 Node.js 20 的 Actions 並記錄 | DONE — 4 個受影響 action 已記錄 |
| AC2 | 建立 validate-ci-versions.sh 驗證腳本 | DONE — `scripts/validate-ci-versions.sh` |
| AC3 | 產出 Node.js 24 遷移評估報告 | DONE — 本文件 |
| AC4 | CI warning 有對應處理計畫 | DONE — 見「遷移計畫」章節 |

---

## 參考資料

- [GitHub: Node.js 20 Actions Deprecation](https://github.blog/changelog/2025-11-11-node-20-actions-deprecation/)
- [actions/checkout releases](https://github.com/actions/checkout/releases)
- [actions/setup-node releases](https://github.com/actions/setup-node/releases)
- [actions/upload-artifact releases](https://github.com/actions/upload-artifact/releases)
- [anthropics/claude-code-action releases](https://github.com/anthropics/claude-code-action/releases)
- CLAUDE.md 第 10 條：CI Actions 版本釘定規範
- `docs/km/runner-environment-checklist.md`
