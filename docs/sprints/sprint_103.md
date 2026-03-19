# Sprint 103

**Sprint Goal**：強化多 Session 並行可靠性 — 清理過期測試技術債、定義檔案鎖定架構、建立中斷恢復機制
**日期**：2026-03-19
**容量**：7 points
**狀態**：完成

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：刪除過期測試 test-us13 / test-us37 | #314 | S | 1 | 完成 |
| FEATURE：多 Session 並行開發的檔案鎖定機制 | #311 | L | 3 | 完成 |
| FEATURE：Sprint 中斷恢復機制（Spot VM / Session Crash） | #313 | L | 3 | 完成 |

## Acceptance Criteria

### #314 — INFRA：刪除過期測試

**AC-1：刪除 test-us13-dora-metrics.sh**
- `tests/test-us13-dora-metrics.sh` 已刪除

**AC-2：刪除 test-us37-prompt-injection-protection.sh**
- `tests/test-us37-prompt-injection-protection.sh` 已刪除

**AC-3：無 regression**
- 刪除後 `bash tests/test-*.sh` 全部通過

### #311 — FEATURE：多 Session 並行開發的檔案鎖定機制

> **前置條件**：實作前需完成 ADR-022（檔案鎖定技術選型），ADR 狀態需為 Accepted。

**AC-1：ADR 技術選型決議**
- 產出 ADR 文件，決定鎖定機制的技術選型（儲存方式、粒度、TTL、整合方式）
- ADR 狀態為 Accepted

**AC-2：檔案鎖定 acquire/release API 實作**
- 提供 acquire-lock / release-lock 腳本或 MCP tool
- acquire 時若已被鎖定，回傳錯誤訊息（含鎖持有者資訊）

**AC-3：TTL 自動釋放機制**
- 鎖具備 TTL（預設 2 小時），超時自動釋放
- 防止 session crash 導致永久死鎖

**AC-4：parallel-dispatch 整合**
- parallel-dispatch 派遣 subagent 前自動 acquire 目標檔案鎖
- subagent 完成或失敗時自動 release

**AC-5：SessionEnd hook 自動釋放**
- session 結束時自動釋放該 session 持有的所有檔案鎖

### #313 — FEATURE：Sprint 中斷恢復機制

**AC-1：Sprint 進度 Checkpoint 機制**
- sprint-execution 每完成一個 Story 後自動記錄進度至持久化檔案
- checkpoint 資料含：Sprint 編號、Story 清單與狀態、當前步驟、時間戳

**AC-2：斷點續跑（Resume）**
- 新 session 偵測到未完成 checkpoint → 自動從斷點繼續
- 已完成的 Story 不重做，從中斷的 Story 重新開始

**AC-3：孤兒 Claim 清理**
- claim 鎖具備 TTL（預設 2 小時），超時自動釋放
- 提供 `claim-cleanup.sh` 腳本供手動或排程清理

**AC-4：頻繁 git push**
- sprint-execution 每完成一個 Story 後自動 git push
- shoot 完成後自動 git push

## 技術評估摘要

### Architect 備注

- **#314**：純刪除操作，無技術風險，TDD 驗證（刪除後跑全測試）
- **#311**：**需 ADR-022**（檔案鎖定技術選型）。關鍵決策點：鎖儲存方式（檔案系統 vs MCP）、與 #312 claim 機制的關係（共用 vs 獨立）。建議先完成 ADR 再進入實作。技術選項：(A) 檔案系統 flock + lock 目錄、(B) MCP Server 集中管理、(C) 擴展既有 claim 機制。與 #312 共用基礎設施可降低維護成本。
- **#313**：技術方案較明確 — checkpoint 用 JSON 檔案（類似 MCP Server 的狀態持久化模式，Sprint 89 已驗證）。孤兒 claim 清理與 #311 的 TTL 機制有共通邏輯，可共用。
- **方法論**：#314 TDD，#311 ADR-first + TDD，#313 TDD
- **ADR 檢查**：#311 需 ADR-022（新增），#313 無需新 ADR（使用既有持久化模式），#314 無需 ADR
- **Refinement**：READY（#311 ADR 為 Sprint 內第一步）

### 平行分群建議

| Phase | 分群 | Stories | 理由 |
|-------|------|---------|------|
| Phase 1 | Group A | #314 | 獨立刪除操作，無依賴 |
| Phase 1 | Group B | #311 (ADR) | ADR-022 撰寫，獨立作業 |
| Phase 1 | Group C | #313 (AC-1, AC-4) | Checkpoint + git push，獨立作業 |
| Phase 2 | Group D | #311 (AC-2~AC-5) | 依賴 ADR-022 Accepted |
| Phase 2 | Group E | #313 (AC-2, AC-3) | Resume + 孤兒清理，可能共用 #311 TTL 邏輯 |

**注意**：#311 AC-3（TTL）與 #313 AC-3（孤兒 Claim 清理）有共通邏輯。Phase 2 時需協調，避免重複實作。

## QA 驗收確認摘要

- **#314**：PASS — 3 AC 全數可驗證（檔案存在性檢查 + 全測試套件執行）
- **#311**：PASS — 5 AC 全數可驗證
  - AC-1：ADR 檔案存在且狀態為 Accepted
  - AC-2：執行 acquire-lock 腳本驗證鎖取得/衝突錯誤訊息
  - AC-3：設定短 TTL 後等待過期驗證自動釋放
  - AC-4：模擬 parallel-dispatch 派遣驗證鎖行為
  - AC-5：模擬 session 結束驗證鎖釋放
- **#313**：PASS — 4 AC 全數可驗證
  - AC-1：執行 sprint-execution 後檢查 checkpoint JSON 檔案內容
  - AC-2：模擬中斷（刪除 session）後重啟驗證 resume 行為
  - AC-3：設定短 TTL 後執行 claim-cleanup.sh 驗證清理
  - AC-4：檢查 git log 確認每個 Story 完成後有 push
- **防漂移基準**：3 Stories, 7 pts

---

## Sprint Review（2026-03-19）

### §1.5 一致性審查

- PROJECT_BOARD.md：Sprint 103 所有 Story 狀態均為「完成」✓
- sprint_103.md：3 Stories, 7 pts，全數 PASS ✓
- 一致性確認：通過

### §2 Sprint Review

**PO Demo**

| Story | Demo 重點 | 結果 |
|-------|----------|------|
| #314 | test-us13 / test-us37 已刪除，全測試套件 PASS | PASS |
| #311 | acquire-file-lock.sh 取得/衝突/TTL 釋放行為，parallel-dispatch 整合，SessionEnd 自動清除 | PASS（32/32，外部審查 CONFIRM）|
| #313 | checkpoint JSON 記錄進度，resume 從斷點繼續，claim-cleanup.sh 孤兒清理，每 Story 後 git push | PASS（15/15，外部審查 CONFIRM）|

**QA 邊界測試（輕量）**

- #311 邊界：兩個 session 同時 acquire 同一檔案 → 第二個收到 `[FILE-LOCK-BLOCKED]`（✓）
- #311 邊界：TTL 過期後 stale lock 自動清除並重新鎖定（✓）
- #313 邊界：checkpoint 存在但已全部完成 → resume 正確識別為「無需恢復」（✓）
- #314 邊界：刪除後 `test-*.sh` glob 不再包含已刪除檔案（✓）

**Stakeholder 驗收**：接受（全數 PASS，0% DISPUTE）

**§2.6 Issue 狀態回寫**

- #311：已關閉（PASS，CONFIRM）
- #313：已關閉（PASS，CONFIRM）
- #314：已關閉（PASS，Retro Action 兌現）

### §3 Retrospective

**Good**

- 7 points 全數達成，Sprint Goal 完全兌現
- ADR-022 技術選型（選項 C）成功複用 #312 架構，避免重複造輪子
- 兩個 L-size Story（#311、#313）平行執行順利，無互相阻塞

**Problem**

- ADR-022 腳本命名與設計文件不符：ADR 寫的是 `file-lock.sh` / `file-unlock.sh`，實際實作為 `acquire-file-lock.sh` / `release-file-lock.sh`，文件回寫遺漏

**Action**

- [已完成] 補更 ADR-022 核心腳本命名表格，對齊實際實作（`acquire-file-lock.sh` / `release-file-lock.sh`）

**上期 Retro Action 追蹤**

- #314（Sprint 102 Retro Action：刪除過期測試）：本 Sprint 已完成並關閉 ✓

### Sprint 103 Metrics

| 指標 | 數值 |
|------|------|
| Velocity | 7 points |
| 完成率 | 100%（3/3） |
| 外部抽樣 | 67%（2/3，#311 CONFIRM + #313 CONFIRM） |
| DISPUTE 率 | 0% |
| 版本 bump | v0.73.1 → v0.74.0（minor，新功能） |
