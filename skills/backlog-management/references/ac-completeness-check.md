# AC 完整性檢查規則（#967）

## 背景

Sprint 177 Retro 發現：Issue 在 Sprint Planning 階段 AC 欄位為空，需在 AC 完整性 Gate 補齊，浪費計劃時間。本規則確保所有 sprint-candidate Issues 在進入 Sprint Planning 前就已具備完整 AC。

## 檢查規則

### AC-1：存在性檢查

**定義**：Issue body 中必須包含 `## Acceptance Criteria` 或 `## AC` 段落。

**檢查指令**：
```bash
gh issue view <number> --json body --jq '.body' | grep -i "## acceptance criteria\|## ac"
```

**判定**：
- 若 grep 無輸出 → **缺 AC，不得取得 sprint-candidate label**
- 若 grep 有輸出 → 進行 AC-2 檢查

### AC-2：完整性檢查

**定義**：AC 段落下方必須至少包含 1 條檢查項（checkbox 或清單項，格式：`- [ ] ...` 或 `- [ ] AC-1: ...`）

**檢查指令**：
```bash
body=$(gh issue view <number> --json body --jq '.body')
# 從 AC 段落開始，抽取到下一個 ## 前或 EOF 的內容
ac_section=$(echo "$body" | sed -n '/^## [Aa]cceptance [Cc]riteria\|^## AC/,/^##/p' | head -n -1)
# 計算 checkbox 項數
checkbox_count=$(echo "$ac_section" | grep -c "^- \[")
if [ "$checkbox_count" -lt 1 ]; then
  echo "FAIL: AC 無檢查項"
else
  echo "PASS: AC 有 $checkbox_count 項"
fi
```

**判定**：
- 若檢查項數 < 1 → **AC 不完整，不得取得 sprint-candidate label**
- 若檢查項數 >= 1 → **通過檢查，可取得 sprint-candidate label**

### AC-3：內容品質建議（非強制）

檢查以下項目（用於 PO 留言提醒，非阻擋條件）：

- [ ] AC 與 Issue 標題、User Story 相關
- [ ] 檢查項表述清晰、可測試
- [ ] 檢查項非空或重複

## 執行流程

### 單一 Issue 檢查

```bash
#!/bin/bash
issue_number=$1

# 讀取 body
body=$(gh issue view "$issue_number" --json body --jq '.body')

# AC-1：存在性檢查
if ! echo "$body" | grep -qi "## acceptance criteria\|## ac"; then
  echo "[$issue_number] FAIL: 缺 AC"
  # PO 留言提醒
  gh issue comment "$issue_number" \
    --body "🚨 AC 存在性檢查失敗：Issue 缺少 Acceptance Criteria。請補齊後重新申請 sprint-candidate。"
  exit 1
fi

# AC-2：完整性檢查
ac_section=$(echo "$body" | sed -n '/^## [Aa]cceptance [Cc]riteria\|^## AC/,/^##/p' | head -n -1)
checkbox_count=$(echo "$ac_section" | grep -c "^- \[")

if [ "$checkbox_count" -lt 1 ]; then
  echo "[$issue_number] FAIL: AC 無檢查項"
  gh issue comment "$issue_number" \
    --body "🚨 AC 完整性檢查失敗：Acceptance Criteria 段落下無檢查項。請至少新增 1 項檢查項。"
  exit 1
fi

echo "[$issue_number] PASS: AC 通過檢查（$checkbox_count 項）"
exit 0
```

### 批次檢查（所有 sprint-candidate 候選）

```bash
#!/bin/bash
# 查詢所有欲取得 sprint-candidate 但尚未取得的 issues
# 假設 PO 在執行 grooming 時維護一份「待檢查清單」或查詢特定 milestone 下的 issues

gh issue list --state open --label "status: backlog" \
  --json number,title,body,labels \
  --limit 200 | jq -r '.[] | select(.labels | map(.name) | index("priority:")) | .number' | while read -r issue_num; do
  
  bash check_ac_single.sh "$issue_num"
  if [ $? -ne 0 ]; then
    echo "[$issue_num] 未通過 AC 檢查，跳過 sprint-candidate 標籤"
  else
    echo "[$issue_num] AC 通過，可申請 sprint-candidate"
  fi
done
```

## PO 操作檢查單

在 Grooming 執行 §3（Grooming 主流程）步驟 4（AC 完整性檢查）時：

```
for each backlog issue 欲升級為 sprint-candidate:
  1. 執行 AC-1 存在性檢查
     - 若失敗：gh issue comment 提醒補齊，跳過此 issue
     - 若通過：進行 AC-2
  
  2. 執行 AC-2 完整性檢查（檢查項數 >= 1）
     - 若失敗：gh issue comment 提醒補齊，跳過此 issue
     - 若通過：進行 AC-3
  
  3. AC-3 品質建議（可選）
     - 若發現問題：gh issue comment 提醒最佳實踐，但不阻擋標籤
  
  4. 通過檢查的 Issue 執行 `gh issue edit <number> --add-label sprint-candidate`
```

## 相關 AC（#967）

- [ ] AC-1：Backlog Grooming Skill / sprint-candidate label 加工流程中，加入 AC 存在性檢查步驟
- [ ] AC-2：缺少 AC 的 issue 不得取得 sprint-candidate label，或取得時自動留言提醒補齊
- [ ] AC-3：補充說明或文件更新，明確 AC 應在 Grooming 完成，不應延遲至 Planning

## 參考

- Issue #967（Retro Action）
- Sprint 177 Retro 紀錄
- Issue #962（原始缺 AC 案例）
