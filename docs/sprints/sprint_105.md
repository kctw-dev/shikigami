# Sprint 105

**Sprint Goal**：分散式鎖機制 silent failure 與跨機器互斥缺陷修復 — 18 項 CRITICAL/HIGH/MEDIUM 缺陷全數清除
**日期**：2026-03-20
**容量**：3 points
**狀態**：進行中

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：分散式鎖機制 — silent failure 與跨機器互斥缺陷修復（18 項） | #316 | L | 3 | 進行中 |

## Acceptance Criteria

### #316 — INFRA：分散式鎖機制 — silent failure 與跨機器互斥缺陷修復（18 項）

**背景**：Sprint 101-104 Review 後，pr-review-toolkit 的 code-reviewer + silent-failure-hunter 發現 18 項問題，涵蓋 CRITICAL（5）、HIGH（4）、IMPORTANT（4）、MEDIUM（5）。

**AC-1：#7 unfetched SHA 修復（最危險）**
- `claim-issue.sh` + `acquire-file-lock.sh` + `claim-cleanup.sh`：查不到 SHA → 保守拒絕（不 fallback 為 "0"）
- 加 `git fetch origin "$REF"` 嘗試取得 commit，失敗則輸出 [WARN] 並保守拒絕

**AC-2：#2/#3/#5 release 失敗假成功修復**
- `release-issue.sh`：`git push --delete` 後檢查 exit code，失敗輸出 [WARN]
- `release-file-lock.sh`：遠端確認刪除成功後才刪本地 metadata
- `session-end-release.sh`：async hook 清理失敗輸出 [WARN]

**AC-3：#4 無鎖模式假陽性修復**
- `acquire-file-lock.sh`：無鎖模式改報 `[FILE-LOCK-DEGRADED]` 而非 `[FILE-LOCK-OK]`

**AC-4：#6/#12/#13 REPO_FP 統一**
- `claim-issue.sh`、`session-end-release.sh`、`acquire-file-lock.sh` 統一為兩步法：先 `REPO_ROOT=$(git rev-parse ...)` 再 hash

**AC-5：#1/#8/#9 claim-issue 和 acquire-file-lock 修復**
- #1：stale delete 失敗時輸出 [WARN]
- #8：flock 失敗與 claim_remote 失敗分開處理
- #9：local-only 模式也寫 metadata

**AC-6：#10/#11 protect-main 和 quoting 修復**
- #10：`grep -oP` 改為 POSIX sed fallback
- #11：flock -c 改用 fd redirection

**AC-7：#14/#15/#16/#17 MEDIUM 修復**
- #14：SESSION_ID unknown 時 WARN 移出迴圈（只輸出一次）
- #15：cleanup 後驗證 ref 是否真的刪除
- #16：JSON 解析失敗時 log WARN
- #17：hash fallback 加 WARN（不再靜默使用常數）

**AC-8：測試覆蓋**
- `test-claim-mechanism.sh`、`test-file-lock-mechanism.sh`、`test-pr-flow.sh` 新增對應測試案例
- 全部現有測試仍然通過

## 平行分群建議

| Phase | 分群 | AC | 理由 |
|-------|------|----|------|
| Phase 1 | 優先 1 | AC-1（#7）+ AC-2（#2/#3/#5）+ AC-3（#4）| 最危險缺陷，影響跨機器互斥 |
| Phase 2 | 優先 2 | AC-4（#6/#12/#13）+ AC-5（#1/#8/#9）| 中等優先，鞏固 REPO_FP 計算 |
| Phase 3 | 優先 3 | AC-6（#10/#11）+ AC-7（#14/#15/#16/#17）| POSIX 相容性 + MEDIUM 修復 |
| Phase 4 | TDD | AC-8 | 補足測試覆蓋，確認全 PASS |

## 技術評估摘要

### Architect 備注

- **#316**：18 項修復均為現有腳本的行為修正，不涉及架構變更
- **最高風險**：#7 unfetched SHA — 現行 `|| echo "0"` fallback 導致跨機器互斥完全失效（所有遠端鎖被誤判為 stale）
- **影響範圍**：`hooks/` 內 7 個腳本
- **技術可行性**：高 — 均為 bash 邏輯修正
- **TDD 先行**：測試先寫，驗證 Red 後再實作 Green

### QA 驗收確認摘要

- **#316**：8 AC 全數可驗證
  - AC-1：驗證 SHA 查不到時輸出 [WARN]，不輸出 [CLAIM-OK]
  - AC-2：驗證 push --delete 失敗時輸出 [WARN]，不輸出假成功
  - AC-3：驗證無鎖模式輸出 [FILE-LOCK-DEGRADED]
  - AC-4：驗證 REPO_FP 計算使用兩步法（grep REPO_ROOT）
  - AC-5：驗證 stale delete 失敗有 WARN，flock/claim_remote 錯誤分離
  - AC-6：驗證 protect-main.sh 無 grep -oP，flock 使用 fd redirection
  - AC-7：驗證 WARN 不重複，cleanup 有驗證步驟
  - AC-8：全部測試 PASS
