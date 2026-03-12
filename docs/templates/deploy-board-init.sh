#!/usr/bin/env bash
# deploy-board-init.sh — Deploy Board 看板 Issue 初始化腳本模板
# ============================================================
# 使用方式：
#   1. 將此檔案複製至消費端專案的 scripts/ 目錄
#   2. 修改下方「消費端自行填入區域」的參數
#   3. 確認 gh CLI 已登入（gh auth status）
#   4. 執行：bash scripts/deploy-board-init.sh
#   5. 記下輸出的 Issue 編號，填入 GitHub Repository Variable：
#      DEPLOY_BOARD_ISSUE_NUMBER
#
# 產生結果：
#   在指定 GitHub 倉庫建立一個 Deploy Board Issue，
#   包含 6 格狀態看板（Staging/Production × Backend/Frontend/E2E）。
#   此 Issue 由 deploy-notify.yml workflow 自動更新。
#
# 前置條件：
#   - gh CLI 已安裝並登入（具備 issues:write 權限）
#   - 消費端 GitHub 倉庫已存在
# ============================================================

set -euo pipefail

# ============================================================
# 消費端自行填入區域
# ============================================================

# GitHub 倉庫（格式：owner/repo）
REPO="YOUR_ORG/YOUR_REPO"

# Issue 標題（建議包含 Sprint 或版本資訊，方便識別）
ISSUE_TITLE="[Deploy Board] Sprint YOUR_SPRINT_NUMBER — 部署狀態看板"

# Issue 標籤（選填，多個標籤用逗號分隔；標籤必須在倉庫中已存在）
# 若不需要標籤，設定為空字串：ISSUE_LABELS=""
ISSUE_LABELS="deploy-board,ops"

# ============================================================
# 主要邏輯（通常不需要修改以下部分）
# ============================================================

# 驗證 gh CLI 可用
if ! command -v gh &>/dev/null; then
  echo "[ERROR] gh CLI 未安裝。請參考 https://cli.github.com/ 安裝後再執行。"
  exit 1
fi

if ! gh auth status &>/dev/null; then
  echo "[ERROR] gh CLI 尚未登入。請執行 'gh auth login' 後再執行本腳本。"
  exit 1
fi

echo "[deploy-board-init] 準備建立 Deploy Board Issue..."
echo "  倉庫：${REPO}"
echo "  標題：${ISSUE_TITLE}"

# 建立 Issue body（6 格看板 Markdown 表格）
#
# 看板結構：
#   Staging  × Backend  | Staging  × Frontend | Staging  × E2E
#   Production × Backend | Production × Frontend | Production × E2E
#
# 初始狀態說明：
#   ⏳ 待部署  — 尚未開始部署
#   🚀 部署中  — 正在進行部署（手動更新）
#   ✅ 成功    — 部署成功，由 deploy-notify.yml 自動更新
#   ❌ 失敗    — 部署失敗，由 deploy-notify.yml 自動更新
#   ⏭️ 跳過   — 本次不需要部署此格

ISSUE_BODY=$(cat <<'BODY_EOF'
## 部署狀態看板

> **使用說明**：此 Issue 由 `deploy-notify.yml` workflow 自動更新。
> 手動更新時，請修改下方表格的狀態欄位。
> 模板版本：v1.0 | 建立於 US-246 (Sprint 90)

---

### 狀態圖例

| 圖示 | 說明 |
|------|------|
| ⏳ | 待部署 |
| 🚀 | 部署中 |
| ✅ | 成功 |
| ❌ | 失敗 |
| ⏭️ | 跳過（本次不部署） |

---

### 部署狀態矩陣

| 環境 | Backend | Frontend | E2E |
|------|---------|----------|-----|
| **Staging** | ⏳ 待部署 | ⏳ 待部署 | ⏳ 待部署 |
| **Production** | ⏳ 待部署 | ⏳ 待部署 | ⏳ 待部署 |

---

### 本次部署資訊

| 欄位 | 值 |
|------|----|
| Sprint | YOUR_SPRINT_NUMBER |
| 目標版本 | vX.Y.Z |
| 部署計畫連結 | <!-- 填入部署計畫文件連結 --> |
| Deployment Readiness Checklist | <!-- 填入 Issue 或文件連結 --> |

---

## 部署日誌

| 時間 | 環境 | 服務 | 狀態 | 連結 |
|------|------|------|------|------|
<!-- LOG_PLACEHOLDER -->
BODY_EOF
)

# 建立 Issue
if [[ -n "${ISSUE_LABELS}" ]]; then
  ISSUE_NUMBER=$(gh issue create \
    --repo "${REPO}" \
    --title "${ISSUE_TITLE}" \
    --body "${ISSUE_BODY}" \
    --label "${ISSUE_LABELS}" \
    --json number \
    --jq '.number')
else
  ISSUE_NUMBER=$(gh issue create \
    --repo "${REPO}" \
    --title "${ISSUE_TITLE}" \
    --body "${ISSUE_BODY}" \
    --json number \
    --jq '.number')
fi

ISSUE_URL="https://github.com/${REPO}/issues/${ISSUE_NUMBER}"

echo ""
echo "[deploy-board-init] Deploy Board Issue 建立成功！"
echo "  Issue 編號：#${ISSUE_NUMBER}"
echo "  Issue URL：${ISSUE_URL}"
echo ""
echo "=========================================="
echo "  後續步驟："
echo "  1. 前往 GitHub 倉庫設定："
echo "     Settings > Secrets and variables > Actions > Variables"
echo "  2. 新增 Repository Variable："
echo "     名稱：DEPLOY_BOARD_ISSUE_NUMBER"
echo "     值：${ISSUE_NUMBER}"
echo "  3. 確認 deploy-notify.yml 已部署至 .github/workflows/"
echo "=========================================="
