# §2.6 Story Issue 狀態回寫（ADR-010 生命週期閉環）

Story 驗收判定完成後，依判定結果回寫 GitHub Issue 狀態。在 §2 步驟 5 之後、§3 之前執行。

## 操作規則

| 驗收判定 | Issue 操作 | 說明 |
|---------|-----------|------|
| Story PASS | 依 Issue 建立者判斷執行對應操作 | 內部 Issue 自動關閉；外部 Issue 保持 Open |
| Story FAIL | Issue 保持 open | 回流 Backlog，等待下次 Sprint 選取 |

## Epic Issue 判斷（優先檢查）

**Epic Issue**：Issue title 含 `epic:` 前綴（大小寫不敏感）。

Epic Issue **不得 close**，無論其為內部或外部 Issue，一律執行：

1. `gh issue edit` 加 `done` label、移除 `in-sprint` label
2. `gh issue comment` 留言記錄：「Sprint <N> Review PASS，此 Epic Issue 持續追蹤中，不自動關閉。」

> **理由**：Epic 通常跨多個 Sprint，單一 Sprint 完成不代表 Epic 整體收斂，需手動判斷關閉時機。

## Issue 建立者判斷

**內部 Issue**：建立者為 `github-actions[bot]` 或 body 含 `backlog-intake`。其餘為**外部 Issue**。

> Epic Issue 已於上方獨立處理，以下規則僅適用於**非 Epic Issue**。

## Story PASS — 操作步驟

| 情況 | 步驟 1（共通） | 步驟 2 |
|------|--------------|--------|
| **Epic Issue**（title 含 `epic:`） | `gh issue edit` 加 `done` label、移除 `in-sprint` label | `gh issue comment` 留言記錄，**不執行 close** |
| **內部 Issue** | `gh issue edit` 加 `done` label、移除 `in-sprint` label | `gh issue close` 並留言 |
| **外部 Issue（階段 1）** | 同上 | `gh issue comment` 留言通知，**不執行 close** |
| **外部 Issue（階段 2）** | — | 觸發條件：**deployment-readiness PASS 且 E2E PASS**，方可執行 `gh issue comment` 補充留言 |

> **負面條件**：若 deployment-readiness 尚未完成（FAIL 或未執行），階段 2 留言**不得補發**，即使 Sprint Review 主流程已結束亦不例外。禁止在主流程結束前預先補發。

## Story FAIL — 操作步驟

Issue 保持 open，移除 `in-sprint` label 並加 `status: backlog` label，留言記錄未完成原因。

## §2.6 完成後：寫入同步 Signal

Review subagent 完成 §2.6 全部 Issue 狀態回寫後，立即執行：

```bash
echo "REVIEW_DONE=$(date '+%Y-%m-%dT%H:%M+08:00')" > docs/sprints/.review-signal-${CLAUDE_SESSION_ID:-unknown}
```

Retro subagent 在執行完 §3 步驟 0 後，輪詢此 signal 檔案（每 5 秒一次，最多等 10 分鐘）；讀取到 `REVIEW_DONE=` 後，繼續執行 §3 步驟 1。
