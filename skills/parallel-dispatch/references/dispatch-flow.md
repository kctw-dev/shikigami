# Parallel Dispatch — 派遣流程詳細步驟

## Step 0.5：檔案衝突預檢（US-311 AC-4）

**在識別獨立領域前，先進行檔案衝突預檢，避免多個 subagent 同時編輯同一檔案。**

列出各 subagent 預計觸碰的檔案清單，檢查是否有重疊：

```
各任務預計觸碰檔案？
  ├── 有重疊 → 標記為「有共享狀態」→ 不適用平行派遣（改為順序處理）
  └── 無重疊 → 各 subagent 在開始時 acquire 所需檔案鎖
```

若無重疊，在派遣前對各 subagent 預計觸碰的關鍵檔案取得 file lock：

```bash
# acquire file lock（US-311）
FILE_LOCKS_ACQUIRED=()
for FILE_PATH in "${TARGET_FILES[@]}"; do
  RESULT=$(bash hooks/acquire-file-lock.sh "$FILE_PATH")
  if echo "$RESULT" | grep -q "\[FILE-LOCK-OK\]\|\[FILE-LOCK-STALE\]"; then
    FILE_LOCKS_ACQUIRED+=("$FILE_PATH")
  elif echo "$RESULT" | grep -q "\[FILE-LOCK-BLOCKED\]"; then
    echo "[WARN] 檔案 $FILE_PATH 已被鎖定：$RESULT"
    echo "[PARALLEL-DISPATCH-ABORT] 檔案衝突，中止本次派遣"
    # rollback 已 acquire 的 file lock
    for PREV_FILE in "${FILE_LOCKS_ACQUIRED[@]}"; do
      bash hooks/release-file-lock.sh "$PREV_FILE"
    done
    exit 1
  fi
done
```

任一 file lock acquire 失敗 → 全部放棄已 acquire 的 lock，回報衝突後中止派遣。

subagent 完成或失敗後，統一在 Step 4 釋放 file lock：

```bash
# release file lock（US-311）
for FILE_PATH in "${FILE_LOCKS_ACQUIRED[@]}"; do
  bash hooks/release-file-lock.sh "$FILE_PATH" || true
done
```

---

## Step 1：識別獨立領域

按問題域分組。將需要處理的任務按模組、檔案、子系統歸類，確認每個群組之間沒有依賴關係。

---

## Step 2：撰寫聚焦的 Agent Prompt

為每個 Agent 撰寫明確的 prompt，包含範圍、目標、限制、預期產出。Prompt 品質直接決定 Agent 的執行效果。

詳細 Prompt 結構見 `references/prompt-structure.md`。

---

## Step 3：使用 Task tool 平行派遣

**派遣前執行 Batch Claim（US-312）**：對每個子任務（有對應 Issue number 時）執行 claim：

```bash
# 逐一 claim 所有子任務
CLAIMED=()
for ID in "${TASK_IDS[@]}"; do
  RESULT=$(bash hooks/claim-issue.sh "$ID")
  if echo "$RESULT" | grep -q "\[CLAIM-OK\]"; then
    CLAIMED+=("$ID")
  else
    echo "[CLAIM-BLOCKED] $ID — 已被占用，放棄全部已 claim 的任務"
    # 衝突：rollback 已 claim 的任務
    for PREV_ID in "${CLAIMED[@]}"; do
      bash hooks/release-issue.sh "$PREV_ID"
    done
    echo "[PARALLEL-DISPATCH-ABORT] Claim 衝突，中止本次派遣"
    exit 1
  fi
done
```

任一 claim 失敗 → 全部放棄已 claim 的，回報衝突後中止派遣。

在同一個訊息中發出多個 Task 呼叫，讓所有 Agent 同時啟動。不要等一個完成再派下一個。

---

## Step 4：收集結果

所有 Agent 回報後，統一檢視：
1. 讀取每個 Agent 的摘要
2. 檢查衝突（是否編輯了相同檔案）
3. 執行完整測試套件
4. 整合變更

**Step 4 完成後執行 Batch Release（US-312）**：逐一 release 所有已 claim 的子任務：

```bash
for ID in "${CLAIMED[@]}"; do
  bash hooks/release-issue.sh "$ID"
done
```

release 失敗不阻塞（|| true）。完整 claim 機制定義見 `skills/sprint-execution/SKILL.md` §2.11。
