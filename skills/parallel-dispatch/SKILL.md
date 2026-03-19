---
name: parallel-dispatch
description: "Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies"
---

# Parallel Dispatch — 平行 Subagent 派遣

## 1. 概述

識別獨立任務，同時派遣多個 Subagent 加速執行。當面對多個互不相關的問題時，不需逐一處理，而是讓多個 Agent 同步作業、各自解決。

核心原則：**一個 Agent 一個獨立問題領域，平行工作不互相干擾。**

---

## 2. 適用判斷

```
多個任務？
  ├── 否 → 單一 Agent 順序處理
  └── 是 → 任務之間獨立？
            ├── 否（有關聯）→ 單一 Agent 順序處理
            └── 是 → 有共享狀態？
                      ├── 是 → 順序處理
                      └── 否 → ✓ 平行派遣
```

### 適用情境（Use When）

- 2+ 個測試檔案因不同根因失敗
- 多個子系統獨立故障
- 各問題可獨立理解，不需要其他問題的脈絡
- 無共享狀態（不存取同一份資料、不寫入同一個檔案）

### 不適用情境（Don't Use When）

- 失敗有關聯（修一個可能修另一個）
- 需要理解整體系統狀態
- Agent 之間會互相干擾（編輯同檔案、使用同資源）
- 探索性除錯（還不知道問題在哪）

---

## 3. 派遣流程

```
Step 0.5: 檔案衝突預檢（US-311）
  |
  v
Step 1: 識別獨立領域
  |
  v
Step 2: 撰寫聚焦的 Agent Prompt
  |
  v
Step 3: 使用 Task tool 平行派遣
  |
  v
Step 4: 收集結果
```

### Step 0.5：檔案衝突預檢（US-311 AC-4）

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

### Step 1：識別獨立領域

按問題域分組。將需要處理的任務按模組、檔案、子系統歸類，確認每個群組之間沒有依賴關係。

### Step 2：撰寫聚焦的 Agent Prompt

為每個 Agent 撰寫明確的 prompt，包含範圍、目標、限制、預期產出。Prompt 品質直接決定 Agent 的執行效果。

### Step 3：使用 Task tool 平行派遣

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

### Step 4：收集結果

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

---

## 4. Agent Prompt 結構

一個好的 Agent Prompt 具備四個要素：

| 要素 | 說明 | 反例 |
|------|------|------|
| 聚焦 | 一個明確的問題領域 | 「修好所有東西」 |
| 自足 | 包含理解問題所需的所有脈絡 | 「修復那個 bug」 |
| 有限制 | 明確標示不得修改的範圍 | 無限制，Agent 可能重構一切 |
| 明確產出 | Agent 應回報什麼 | 「修好它」 |

### Prompt 範本

```markdown
修復 [檔案/模組名稱] 中的 [N] 個失敗測試：

1. "[測試名稱 1]" — [錯誤描述]
2. "[測試名稱 2]" — [錯誤描述]

你的任務：
1. 閱讀測試檔案，理解每個測試驗證的內容
2. 找到根因
3. 修復問題

限制：不得修改 [範圍外的檔案]
回報：根因摘要 + 修改內容
```

---

## 5. 常見錯誤

| 錯誤 | 正確做法 |
|------|----------|
| 範圍太廣：「修復所有測試」 | 聚焦：「修復 agent-tool-abort.test.ts」 |
| 缺少脈絡：「修復 race condition」 | 提供脈絡：貼上錯誤訊息與測試名稱 |
| 無限制：Agent 可能重構一切 | 加限制：「不得修改 production code」 |
| 模糊產出：「修好它」 | 明確產出：「回報根因摘要與修改內容」 |

---

## 6. 與 Shikigami 角色的整合

常見的平行派遣場景：

| 場景 | 說明 |
|------|------|
| sprint-execution | 多個獨立 Story 同時派遣 Developer subagent 實作 |
| deployment-readiness | SRE + Security subagent 同時進行部署前檢查 |
| architecture-decision | Architect 設計方案 + QA 準備 Decision Challenge，同步進行 |
| systematic-debugging | 多個獨立 bug 同時派遣 Developer subagent 除錯 |

---

## 7. 驗證

所有 Agent 回報後，必須執行以下驗證步驟：

1. **讀取每個 Agent 的摘要** — 確認每個 Agent 都完成了指派的任務，並理解其修改內容
2. **檢查衝突** — 確認不同 Agent 是否編輯了相同檔案；如有衝突，手動合併
3. **執行完整測試套件** — 跑全部測試，確保沒有 Agent 的修改導致其他部分回歸
4. **抽查 Agent 的修改** — Agent 可能犯系統性錯誤（例如用了錯誤的 pattern），需人工抽查確認品質
