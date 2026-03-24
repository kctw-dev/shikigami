# §5.8 程式碼入庫 QA 自動化

**關聯 Story**：US-60（Issue #46 子 Story #3）

排程衝刺執行完成、`scheduled/*` 分支 push 後，自動進行程式碼入庫品質驗證並建立 PR，確保排程產出的變更在進入主分支前通過 QA 閘門。

## 偵測條件

排程腳本在執行 §5.7 步驟 (b) push 完成後，偵測以下條件以啟動 QA 自動化流程：

| 偵測項目 | 判定方式 |
|----------|----------|
| 分支命名符合 `scheduled/*` 規則 | `git branch --show-current \| grep -q '^scheduled/'` |
| 分支已 push 至 remote | `git ls-remote --heads origin "$BRANCH_NAME"` 確認遠端分支存在 |
| 無對應 open PR | `gh pr list --head "$BRANCH_NAME" --state open --json number \| jq 'length == 0'` |

三項條件全部滿足時，進入 PR 建立流程；任一不符則 log 說明並跳過。

## PR 建立流程

偵測條件通過後，依序執行以下步驟：

**步驟 1：Quality Gate 前置檢查**

在建立 PR 前先執行 quality-gate 檢查項目（見下方「Quality Gate 檢查項目」）。任一項失敗則記錄錯誤至 log，**不建立 PR**，等待人工介入。

**步驟 2：建立 PR**

使用 `gh pr create --title "[SCHEDULED] ${SKILL_NAME} — <timestamp>" --label "scheduled" --base main`，body 須包含：Skill 名稱、Interval、Sprint 編號、Story ID、分支名、執行時間、Quality Gate 結果、變更摘要。

**步驟 3：PR 建立後通知**

PR URL 與 Quality Gate 結果寫入 `${LOG_FILE}`。

## Quality Gate 檢查項目

排程 PR 建立前必須通過以下三條 quality-gate 規則：

| # | 規則 | 驗證方式 | 失敗處理 |
|---|------|----------|----------|
| (a) | **CI 驗證通過** — bash syntax check + 現有測試 | 對 worktree 內所有新增/修改的 `.sh` 檔案執行 `bash -n <file>`；若專案有測試腳本則執行 `bash tests/run_tests.sh` 或同等指令 | 記錄失敗檔案清單至 log，不建立 PR，等待人工修復 |
| (b) | **PR body 包含 Story ID 與 Sprint 編號標注** — 確保可追溯性 | 驗證 PR body 中含有 `Story ID` 欄位（非空）與 `Sprint` 欄位（非空），格式如 `US-NN` 與 `Sprint NN` | 若環境變數 `STORY_ID` 或 `SPRINT_NUMBER` 未設定則以 `UNKNOWN` 填入並在 log 中警告 |
| (c) | **Merge 前確認無衝突（non-conflicting）** — 確保分支可乾淨合併至主分支 | 執行 `git merge-tree $(git merge-base HEAD origin/main) HEAD origin/main` 並檢查是否有衝突標記（`<<<<<<`） | 記錄衝突檔案清單至 log，不建立 PR，通知人工解衝突後重跑 |

**實作要點**：(a) 用 `find -name "*.sh" -newer .git -print0` 找新增/修改的 sh 檔並逐一 `bash -n` 驗證；(b) 檢查 `STORY_ID` / `SPRINT_NUMBER` 環境變數，空值以 `UNKNOWN` 填入並警告；(c) 用 `git merge-tree` 檢查衝突標記（`<<<<<<`）。任一失敗 return 1，不建立 PR。
