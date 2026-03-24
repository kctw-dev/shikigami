# §15 使用範例

本節提供完整的 `/schedule` 指令使用範例，說明前提條件與預期結果，協助使用者快速設定自動化排程。

---

## 範例 (a)：README 統計自動更新排程

`/schedule readme-update --interval 1h` — 每小時自動更新 README 徽章統計並 commit。

**前提條件**：OAuth 認證有效、目標 Skill 已存在、flock 可用、專案目錄可寫（同 §4 Pre-flight 檢測項目）。

移除排程：`/schedule readme-update --remove`

---

## 範例 (b)：Daily Standup 自動排程

`/schedule daily-standup --interval 1h` — 每小時觸發 standup report 生成。

**注意**：`/schedule` 不接受原始 cron 表達式（如 `0 9 * * 1-5`）。若需精確時間觸發，選擇 `--interval 1h` 並在 Skill 內部加入時間條件判斷（如 `[ $(date +%H) -eq 9 ] || exit 0`）。

**序列執行**（避免與 sprint-execution 共享檔案衝突）：兩者均綁定 `--sequential-group sprint-cycle`。

---

## 範例 (c)：Issue 管理自動化排程（issue-management）

`/schedule issue-management --interval 1h` — 每小時掃描 GitHub Issues 執行入庫、分類、回覆。移除：`/schedule issue-management --remove`。

**注意**：依賴 gh CLI OAuth 與 claude CLI OAuth 兩者認證，需定期確認。新 Issue 入庫已由 GitHub Action（`new-issue-intake.yml`）即時處理，排程用於批次補齊。
