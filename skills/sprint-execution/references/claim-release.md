# 多 Session 並行協調 — Claim/Release 機制（US-312）

<!-- US-312 多 Session 並行開發 Issue/Story 級別協調機制 — Sprint 101 -->

## 概述

多個 session 並行執行時，可能同時領取相同 Story 造成重複開發。本機制透過三層協調防止衝突：

| 層次 | 機制 | 說明 |
|------|------|------|
| 本地鎖 | `flock` + lock file | 同機器原子操作防護（macOS 無 flock 時跳過） |
| 遠端鎖 | `git push refs/claims/<id>` | 跨 session 互斥保證（同名 ref 拒絕 = 已被占用） |
| 展示層 | GitHub Issue assignee + label | 可視性（非互斥保證，可選） |

## 輸出標記

| 標記 | 說明 |
|------|------|
| `[CLAIM-OK] refs/claims/<id>` | 成功取得 claim |
| `[CLAIM-BLOCKED] refs/claims/<id> 已被占用` | 已被其他 session 占用 |
| `[CLAIM-STALE] refs/claims/<id> 已過期 Xh，強制清除` | stale lock 清除 |
| `[CLAIM-RELEASE] refs/claims/<id>` | 成功釋放 claim |

## Claim 流程

使用獨立腳本執行 claim（三層協調：本地 flock + 遠端 ref + 展示層）：

```bash
# claim issue（取得 story 鎖）
bash hooks/claim-issue.sh <issue_id>
# 輸出：[CLAIM-OK] / [CLAIM-BLOCKED] / [CLAIM-STALE]
```

詳細實作見 `hooks/claim-issue.sh`。

## Release 流程

使用獨立腳本執行 release：

```bash
# release issue（釋放 story 鎖）
bash hooks/release-issue.sh <issue_id>
# 輸出：[CLAIM-RELEASE]
```

詳細實作見 `hooks/release-issue.sh`。SessionEnd 自動 release 見 `hooks/session-end-release.sh`（呼叫 `release-issue.sh`）。

## Check 流程

```bash
check_claim() {
  local ID=$1
  git ls-remote origin "refs/claims/$ID" 2>/dev/null  # 有輸出 = 有人領了
  gh issue view "$ID" --json assignees,labels 2>/dev/null  # 看是誰
}
```

## Owner 身份類型

| 類型 | assignee | label |
|------|----------|-------|
| human | 本人 | (無) |
| human-team | 本人 | `team:frontend` |
| bot | repo owner | `bot:session-abc` |
| bot-team | repo owner | `bot-team:sprint-101` |

## SessionEnd 自動釋放

`hooks/session-end-release.sh` 在 SessionEnd hook 時自動 release 本 session 所有 claim（見 `hooks/hooks.json` SessionEnd 配置）。失敗不阻塞（AC-6）。
