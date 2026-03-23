# shoot 觸發模式詳細規則

本文件定義 `/shoot` 各觸發模式的詳細邏輯，由 `skills/shoot/SKILL.md` 按需載入。

---

## 自動抓取模式詳細邏輯（AC1）

### 三層優先順序

| 優先順序 | 來源 | 命令 |
|---------|------|------|
| (1) 第一優先 | `bug` label 的 open Issue | `gh issue list --label "bug" --state open --limit 1` |
| (2) 第二優先 | `retro-action` label 的 open Issue | `gh issue list --label "retro-action" --state open --limit 1` |
| (3) 第三優先 | `docs/prd/PRODUCT_BACKLOG.md` 頂部 `Size=S` Story | 讀取 PRODUCT_BACKLOG.md，取第一筆 Size=S 的 Story |

### 抓取邏輯

```bash
# Step 1：嘗試 bug label
TASK=$(gh issue list --label "bug" --state open --limit 1 --json number,title 2>/dev/null)
if [[ -n "$TASK" && "$TASK" != "[]" ]]; then
  # 使用第一個 bug Issue
  ...
fi

# Step 2：嘗試 retro-action label
TASK=$(gh issue list --label "retro-action" --state open --limit 1 --json number,title 2>/dev/null)
if [[ -n "$TASK" && "$TASK" != "[]" ]]; then
  # 使用第一個 retro-action Issue
  ...
fi

# Step 3：嘗試 PRODUCT_BACKLOG.md 頂部 Size=S Story
# 讀取 docs/prd/PRODUCT_BACKLOG.md，取第一筆 Size=S 的 Story
```

### 三者均無時的錯誤處理

```
[ERROR] 自動抓取失敗：無可用任務
  - bug label 無 open Issue
  - retro-action label 無 open Issue
  - PRODUCT_BACKLOG.md 無 Size=S Story
請改用 /shoot "描述"、/shoot #N 或 /shoot US-#N 指定任務。
```

---

## Backlog Story 模式詳細邏輯（AC4）

### 查詢優先序

1. **優先**：使用 `gh issue list` 搜尋 title 包含 US-#N 的 Issue
2. **Fallback**：若 GitHub Issues 無結果，讀取 `docs/prd/PRODUCT_BACKLOG.md`（輸出警告）
3. **兩者皆查無結果**：輸出錯誤並終止

### Story ID 比對邏輯

```bash
# Step 1：優先查詢 GitHub Issues（搜尋 title 包含 US-#N 的 backlog-item Issue）
STORY_ID="US-#312"  # 替換為實際 Story ID，如 US-#312（舊格式 US-78 也支援）
ISSUES=$(gh issue list --label "type: backlog-item" --state open \
  --json number,title,body --limit 200 2>/dev/null)

# 過濾 title 包含 Story ID 的 Issue
MATCHED=$(echo "$ISSUES" | jq --arg id "$STORY_ID" \
  '[.[] | select(.title | test($id; "i"))] | first')

if [[ -n "$MATCHED" && "$MATCHED" != "null" ]]; then
  # 使用 GitHub Issue 作為 Story 來源
  ISSUE_NUMBER=$(echo "$MATCHED" | jq '.number')
  STORY_BODY=$(echo "$MATCHED" | jq -r '.body')
  # 繼續執行...
else
  # Step 2：Fallback 至 PRODUCT_BACKLOG.md
  echo "[WARN] 從歷史快照讀取：docs/prd/PRODUCT_BACKLOG.md"
  if [[ ! -f "docs/prd/PRODUCT_BACKLOG.md" ]]; then
    echo "[ERROR] 找不到 Story $STORY_ID"
    exit 1
  fi
  MATCHED_LINE=$(grep -n "| $STORY_ID " docs/prd/PRODUCT_BACKLOG.md)
  if [[ -z "$MATCHED_LINE" ]]; then
    # Step 3：兩者皆查無結果
    echo "[ERROR] 找不到 Story $STORY_ID"
    exit 1
  fi
  # 使用 PRODUCT_BACKLOG.md 作為 Story 來源
fi
```

Story ID 需**精確比對**（`US-#N` 格式優先，也支援舊格式 `US-XX`，大小寫不敏感）。

### 錯誤處理

| 情境 | 處理方式 |
|------|----------|
| GitHub Issues 無結果，fallback 至 PRODUCT_BACKLOG.md | 輸出 `[WARN] 從歷史快照讀取：docs/prd/PRODUCT_BACKLOG.md` 並繼續執行 |
| GitHub Issues 無結果且 PRODUCT_BACKLOG.md 也找不到 | 輸出 `[ERROR] 找不到 Story US-#N` 並終止，exit code 非 0 |
| PRODUCT_BACKLOG.md 不存在（fallback 時） | 輸出 `[ERROR] 找不到 Story US-#N` 並終止，exit code 非 0 |
| gh CLI 未認證 | 輸出 `[ERROR] gh CLI 未認證，請執行 gh auth login` 並終止，exit code 非 0 |
