# Sprint 105

**Sprint Goal**：修復分散式鎖核心缺陷，確保跨機器多 Session 互斥可靠性
**日期**：2026-03-20
**容量**：3 points
**狀態**：進行中

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：分散式鎖機制 — silent failure 與跨機器互斥缺陷修復（18 項） | #316 | L | 3 | 進行中 |

## Acceptance Criteria

### #316 — fix: 分散式鎖機制 — silent failure 與跨機器互斥缺陷修復（18 項）

> **分批策略**：Batch 1（CRITICAL+HIGH 10 項）→ Batch 2（IMPORTANT+MEDIUM 8 項）
> **方法論**：TDD

#### Batch 1：CRITICAL + HIGH（10 項）

**CRITICAL（5 項）**

**AC-1：claim-issue.sh:56 — stale lock 刪除失敗靜默吞錯**
- stale lock 刪除失敗時必須 abort claim 並輸出錯誤訊息
- 不可盲目繼續後續 claim 流程

**AC-2：release-issue.sh:32,49 — release 失敗假報成功**
- 核心 delete 操作失敗時必須檢查 exit code
- 成功才報告 `[CLAIM-RELEASE]`，失敗則報告 `[CLAIM-RELEASE-FAILED]` 並回傳非零 exit code

**AC-3：release-file-lock.sh:42,52 — release 失敗假報成功 + metadata 清除順序錯誤**
- 同 AC-2，delete 操作成功才報告 release
- 本地 metadata 必須在遠端刪除成功後才清除

**AC-4：acquire-file-lock.sh:119-122 — 無鎖模式假陽性**
- 無鎖模式（flock 不可用或降級）改報 `[FILE-LOCK-DEGRADED]` 而非 `[FILE-LOCK-OK]`
- 呼叫端可區分完整鎖定與降級模式

**AC-5：session-end-release.sh:114-116 — async hook 清理失敗靜默**
- hook 清理失敗時必須輸出 WARN 訊息
- 記錄未清理的孤兒 ref 資訊，供後續 claim-cleanup.sh 處理

**HIGH（5 項）**

**AC-6：claim-issue.sh:28-30 — REPO_FP 空字串碰撞**
- 非 git repo 時 REPO_FP 不可為空字串
- 統一採用兩步法計算：先取 git root，失敗則 abort

**AC-7：claim-issue.sh:49 — unfetched commit SHA 導致跨機器互斥失效**
- 方案 C：先 fetch ref name（非 SHA），fetch 失敗則保守拒絕（視為有效 claim）
- 不可因本地無法解析遠端 ref 就判定所有遠端鎖為 stale

**AC-8：claim-issue.sh:95-96 — flock 失敗與 claim_remote 失敗混淆**
- flock 失敗與 claim_remote 失敗必須有不同的錯誤訊息與 exit code
- 呼叫端可區分是本地鎖競爭失敗還是遠端 claim 失敗

**AC-9：acquire-file-lock.sh:114-123 — local-only 模式不寫 metadata**
- local-only 模式仍須寫入 metadata（至少包含 session ID、timestamp、lock type）
- session-end-release.sh 可正確清理 local-only 鎖

**AC-10：release-issue.sh:55 — QA 額外發現：殘留 bug**
- 修復 release-issue.sh:55 殘留 bug（QA 驗收時發現）

#### Batch 2：IMPORTANT + MEDIUM（8 項）

**IMPORTANT（4 項）**

**AC-11：protect-main.sh:34 — grep -oP macOS 不支援**
- 改用 POSIX 相容的 grep/sed/awk 替代 `grep -oP`
- macOS 與 Linux 均可正常執行

**AC-12：acquire-file-lock.sh:128-132 — flock -c 字串插值 quoting injection**
- 消除 flock -c 的字串插值風險
- 使用安全的引號處理或改用 fd-based flock

**AC-13：session-end-release.sh:29-31 — REPO_FP 計算不一致**
- 統一 REPO_FP 計算方式，與 claim-issue.sh 一致（兩步法）

**AC-14：claim-issue.sh:28-30 — REPO_FP pipe chain 不一致**
- 與 AC-6/AC-13 統一，所有腳本採用相同的 REPO_FP 計算邏輯

**MEDIUM（4 項）**

**AC-15：session-end-release.sh:48-52 — SESSION_ID unknown 時 WARN 重複輸出**
- SESSION_ID unknown 的 WARN 只輸出一次
- 後續操作引用同一個 fallback 值

**AC-16：claim-cleanup.sh:98-100 — fallback chain 死碼**
- 移除或修復因 release-issue.sh `|| true` 導致的死碼 fallback chain
- 確保 cleanup 失敗時有正確的降級邏輯

**AC-17：protect-main.sh:30-35 — malformed JSON 靜默放行**
- malformed JSON input 時不可靜默放行
- 必須輸出 WARN 並拒絕操作（保守策略）

**AC-18：acquire-file-lock.sh:36 — hash fallback 常數導致鎖碰撞**
- hash fallback 不可為常數
- 改用檔案路徑本身或其他唯一識別方式，避免所有檔案共用同一鎖

**AC-19（QA 額外）：session-end-release.sh:130 — 殘留 bug**
- 修復 session-end-release.sh:130 殘留 bug（QA 驗收時發現）

**AC-20（QA 額外）：release-file-lock.sh REPO_FP — 殘留 bug**
- 修復 release-file-lock.sh 中 REPO_FP 計算殘留 bug（QA 驗收時發現）

**AC-21（QA 額外）：session-end-release.sh:129-133 — metadata 目錄清理 TOCTOU race**
- metadata 目錄清理使用原子操作或加鎖，避免 TOCTOU race condition

## 技術評估摘要

### Architect 備注

- **不需要新 ADR** — 這是既有架構的 bug fix，不涉及架構變更
- **#7 方案 C**：fetch 用 ref name（非 SHA），fetch 失敗則保守拒絕（視為有效 claim）
- **Release 策略**：失敗時 WARN + 不重試（避免無限重試迴圈）
- **分批策略**：Batch 1（CRITICAL+HIGH 10 項）→ Batch 2（IMPORTANT+MEDIUM 8 項）
- **方法論**：TDD — 每項修復先寫失敗測試，再實作修復
- **影響範圍**：
  - `hooks/claim-issue.sh` — AC-1, AC-6, AC-7, AC-8, AC-14
  - `hooks/release-issue.sh` — AC-2, AC-10
  - `hooks/release-file-lock.sh` — AC-3, AC-20
  - `hooks/acquire-file-lock.sh` — AC-4, AC-9, AC-12, AC-18
  - `hooks/session-end-release.sh` — AC-5, AC-13, AC-15, AC-19, AC-21
  - `hooks/protect-main.sh` — AC-11, AC-17
  - `hooks/claim-cleanup.sh` — AC-16

### QA 備注

- **18 項 AC 全部可驗證**（加上 QA 額外發現 3 項，共 21 項 AC）
- **額外發現 3 個殘留 bug**：
  1. `release-issue.sh:55` — AC-10
  2. `session-end-release.sh:130` — AC-19
  3. `release-file-lock.sh` REPO_FP — AC-20
- **DoR**：PASS
- **防漂移基準**：1 Story, 3 pts
