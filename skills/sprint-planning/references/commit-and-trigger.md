# Sprint Planning — Commit、Claim/Release 與自動啟動規範

## Sprint Planning 會議紀錄格式

`docs/meetings/` 目錄若不存在，執行 `mkdir -p docs/meetings` 建立。

檔名規則：`docs/meetings/$(date '+%Y-%m-%d')-sprint-planning.md`

時間取得方式：開始時間在流程第一步（記錄 `START_TIME`）取得，結束時間在寫入紀錄時取得。

```yaml
---
type: sprint-planning
sprint: <N>
date: "<YYYY-MM-DD>"
start_time: "<START_TIME>"
end_time: "<date '+%Y-%m-%dT%H:%M+08:00'>"
participants:
  - role: PO
    rounds: [1, 2]
  - role: Architect
  - role: QA
---

# Sprint <N> Planning 會議紀錄

## 結論
- Sprint Goal: <goal>
- 選入 Stories: <story list>

## 決議事項
1. <decisions>
```

## 並行衝突防護

PO Round 2 建立 `sprint_N.md` 前，必須執行 **git pull + 檔案存在性檢查 + 自動遞增** 機制，防止多 session 同時執行 Sprint Planning 時產生重複編號。衝突發生時輸出 `[SPRINT-CONFLICT]` WARN 日誌並自動遞增編號。完整流程見 [po-prompt.md](./po-prompt.md) § 並行衝突防護流程。

## Sprint Planning Claim/Release（US-312）

PO Round 2 開始（建立 `sprint_N.md`）前，執行 Sprint Planning claim：

```bash
bash hooks/claim-issue.sh "sprint-${N}-planning"
# [CLAIM-OK]      → 繼續 Sprint Planning
# [CLAIM-BLOCKED] → 已有其他 session 正在 Planning，輸出 WARN 後繼續（不阻塞）
```

Sprint Planning 完成（git commit + push）後，執行 release：

```bash
bash hooks/release-issue.sh "sprint-${N}-planning"
# [CLAIM-RELEASE] refs/claims/sprint-${N}-planning
```

claim/release 失敗不阻塞 Sprint Planning（gh CLI 不可用時同樣降級容錯）。完整 claim 機制定義見 `skills/sprint-execution/SKILL.md` §2.11。

## Commit + Push 規範

```bash
git add docs/PROJECT_BOARD.md docs/sprints/sprint_N.md docs/meetings/
git commit -m "docs: Sprint N Planning — 更新看板與 Sprint 文件"
git push
```

> **範圍限制**：僅適用 Sprint 狀態文件（`PROJECT_BOARD.md`、`sprint_N.md`、`Metrics_Log.md`、`Retrospective_Log.md`、`docs/meetings/*.md`）。

## 自動啟動 Sprint Execution（#354）

Sprint Planning commit + push 完成後，依 `project_level` 決定是否自動啟動 Sprint Execution：

<HARD-GATE>
project_level=low 時，Sprint Planning commit + push 完成後，必須自動 invoke shikigami:sprint-execution，禁止詢問使用者確認。
</HARD-GATE>

```bash
# 讀取 project_level（同 Cruise 步驟 4.5 讀取方式）
CONFIG_FILE=".claude/shikigami.local.md"
PROJECT_LEVEL=$(grep -A5 'shikigami:' "$CONFIG_FILE" 2>/dev/null | grep 'project_level:' | awk '{print $2}' | head -1)
PROJECT_LEVEL="${PROJECT_LEVEL:-medium}"

if PROJECT_LEVEL == "low":
  # low：自動啟動，不問人
  invoke shikigami:sprint-execution
elif PROJECT_LEVEL == "medium":
  # medium：通知等確認
  echo "[SPRINT] Sprint Planning 完成。請確認是否啟動 Sprint Execution。"
else:  # high
  # high：只記錄
  echo "[SPRINT] Sprint Planning 完成。Sprint Execution 需手動啟動。"
```
