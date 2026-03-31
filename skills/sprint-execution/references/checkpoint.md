# Sprint 進度 Checkpoint + Task List

## 2.12 Sprint 進度 Checkpoint（US-313）

<!-- US-313 Sprint 進度 Checkpoint 機制 — Sprint 102 -->
<!-- US-315 AC-6：Checkpoint 歸入狀態文件豁免清單，可直推 main -->

> **[狀態文件豁免]** `docs/sprints/sprint-checkpoint.json` 屬於豁免清單（ADR-023 決策 3 + 決策 4，US-315 AC-5/AC-6），允許**直推 main**，不受 `protect-main.sh` PreToolUse hook 攔截。PR-based git flow 導入後本節流程**不受影響**，維持現行直推機制。

每個 Story 完成（看板更新 + git commit + push）後，主 session 自動將當前 Sprint 進度寫入 `docs/sprints/sprint-checkpoint.json`，實現持久化 checkpoint，供 context 恢復或進度查詢使用。

### Checkpoint 寫入時機

**每個 Story 完成後**（外部獨立審查 CONFIRM → 主 session merge PR → 狀態文件 git push 完成之後）立即執行。

### Checkpoint 格式

```json
{
  "sprint": 102,
  "stories": [
    {"id": "US-313", "status": "completed", "completed_at": "2026-03-19T18:15:01+08:00"},
    {"id": "US-314", "status": "in-progress", "completed_at": null},
    {"id": "US-315", "status": "pending", "completed_at": null}
  ],
  "current_step": "story-completed",
  "updated_at": "2026-03-19T18:15:01+08:00"
}
```

### 欄位說明

| 欄位 | 說明 |
|------|------|
| `sprint` | Sprint 編號（從 PROJECT_BOARD.md 提取） |
| `stories[].id` | Story 識別碼（如 `US-313`） |
| `stories[].status` | `completed` / `in-progress` / `pending` |
| `stories[].completed_at` | 完成時間（ISO 8601，未完成為 `null`） |
| `current_step` | 當前步驟描述（如 `story-completed`、`sprint-review-triggered`） |
| `updated_at` | checkpoint 最後更新時間（ISO 8601） |

### 寫入方式

```bash
# 時間戳使用系統時間
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
# 寫入 docs/sprints/sprint-checkpoint.json（完整覆寫）
```

### 容錯設計

- 寫入失敗時**靜默略過**，輸出 `[CHECKPOINT-WRITE-WARN] checkpoint 寫入失敗，繼續執行`，不阻塞主流程
- checkpoint 為輔助持久化機制，非流程控制依據

---

## 2.13 Sprint Task List — compact 後進度恢復（#469）

<!-- #469 Cruise/Sprint 執行時建立 Task List — 防止 compact 後跳步 -->

Sprint Execution 啟動時建立 Task List，記錄 Sprint 的三個主要 phase。compact 後可透過 TaskList 查詢恢復進度，跳過已完成的 phase，防止跳步或停下來詢問使用者。

### Task List 建立時機

Sprint Execution **啟動時**（§3 流程最開始，Sprint Checkpoint 偵測之前）立即建立：

```
# 建立 Sprint Task List（多 session 隔離：以 SESSION_ID 命名）
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
TASK_LIST_ID="sprint-${SESSION_ID}"

TaskCreate 以下 tasks（依執行順序）：
  1. "sprint-planning-${SESSION_ID}"   — Sprint Planning（backlog refinement 至排程確定）
  2. "sprint-execution-${SESSION_ID}"  — Sprint Execution（Story 逐一開發交付）
  3. "sprint-review-${SESSION_ID}"     — Sprint Review（驗收、Velocity 計算、Retro）

# ── compact 後恢復進度（#469 AC4）──
# 重啟時先查詢 TaskList，判斷從哪個 phase 繼續
EXISTING_TASKS=$(TaskList --filter "sprint-${SESSION_ID}")
if [[ -n "$EXISTING_TASKS" ]]; then
  echo "[SPRINT] 偵測到既有 Task List，恢復進度（compact 後重啟）"
  # 讀取各 phase 狀態：
  #   completed → 跳過（已完成）
  #   failed    → 從該 phase 重試（#469 AC6）
  #   in-progress / pending → 正常繼續
fi
```

### Task 狀態轉換規則（#469 AC2 / AC6）

| 事件 | TaskUpdate 動作 |
|------|----------------|
| Execution 開始 | `TaskUpdate id="sprint-execution-${SESSION_ID}" status=in-progress` |
| 每個 Story 完成時更新進度 | `TaskUpdate id="sprint-execution-${SESSION_ID}" content="completed: #N1,#N2..."` |
| Execution 完成 | `TaskUpdate id="sprint-execution-${SESSION_ID}" status=completed` |
| Review 開始 | `TaskUpdate id="sprint-review-${SESSION_ID}" status=in-progress` |
| Review 完成 | `TaskUpdate id="sprint-review-${SESSION_ID}" status=completed` |
| 任一 phase 失敗 | `TaskUpdate id="sprint-<phase>-${SESSION_ID}" status=failed` |

### 多 session 隔離（#469 AC5）

- Task List 名稱含 SESSION_ID，每個 session 獨立，互不干擾
- 不同 session 的 Task List 不會互相覆蓋（`sprint-${SESSION_ID}` 命名空間）

### Task 命名格式（#538 AC2）

`{repo}/sprint-{N}-{phase}`

其中 `{repo}` = 從 `git remote get-url origin` 解析的 `owner/repo`（如 `kctw-dev/shikigami`），`{N}` = Sprint 編號（從 sprint_N.md 讀取），`{phase}` = `planning` | `execution` | `review`。

命名範例：
- `kctw-dev/shikigami/sprint-129-planning`
- `kctw-dev/shikigami/sprint-129-execution`
- `kctw-dev/shikigami/sprint-129-review`

compact 後恢復（#538 AC4）：以 `{repo}/sprint-{N}-` 為前綴查詢 TaskList，從第一個非 completed 的 task 繼續。

舊 Sprint 殘留 Task（#538 AC5）：若 TaskList 中存在前一 Sprint 的 Task（status 非 completed），標記為 completed。

### 容錯設計

- TaskCreate / TaskUpdate 失敗時**靜默略過**，不阻塞主流程
- Task List 為輔助進度追蹤機制，sprint-checkpoint.json（§2.12）為主要斷點恢復依據，兩者互補
