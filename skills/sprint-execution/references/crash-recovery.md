# Crash Recovery — Side Effect Idempotency Guard（§2.14 / #405 / ADR-041）

<!-- #405 Temporal-style Crash Recovery — Sprint 140 -->
<!-- ADR-041 策略 C：Hybrid Checkpoint + Side Effect Log -->

Session crash 後重啟時，Sprint Execution 自動偵測未完成 checkpoint，並透過 Side Effect Log 防止不可逆操作（git commit、GitHub API 呼叫等）被重複執行。

## Side Effect Guard 使用方式

```bash
# source hooks/side-effect-guard.sh 後使用
source hooks/side-effect-guard.sh

# Guard-before-Execute 模式（ADR-041 決策 4）
if check_side_effect "git-commit" "$COMMIT_HASH"; then
  git commit -m "..."
  COMMIT_HASH=$(git rev-parse HEAD)
  record_side_effect "git-commit" "$COMMIT_HASH"
fi

# 或使用 side_effect_wrap 便利函數
side_effect_wrap "gh-pr-create" "$PR_URL" gh pr create --title "..."
```

## Crash Recovery 觸發（session 重啟時）

```bash
# 掃描 checkpoint，輸出恢復報告
bash scripts/crash-recovery.sh --dry-run

# 輸出恢復狀態（供 SM 使用）
bash scripts/crash-recovery.sh
```

**[RECOVERY-TRIGGER] 條件**：`sprint-checkpoint.json` 存在且有 `status=in-progress` 的 Story。

> 實作細節：`hooks/side-effect-guard.sh`、`scripts/crash-recovery.sh`
> 架構決策：`docs/adr/ADR-041-crash-recovery-design.md`
