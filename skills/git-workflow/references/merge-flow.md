# Git Workflow — 完成開發整合（§4 詳解）

## PR 顆粒度規範

**規則：每個 Story 必須對應獨立 PR。**

- 一個 Story = 一個 Feature Branch = 一個 PR
- 不得將多個 Story 的變更打包在同一個 PR 中
- 此規則確保 Review 可追溯性清晰，回滾影響範圍最小

**例外：Strong Coupling**

若兩個或多個 Story 之間存在 strong coupling（例如：共用介面定義無法拆分、原子性資料遷移），可允許例外打包，但**必須**在 PR 說明中明確標注：

```markdown
## Story Coupling 聲明

本 PR 包含以下 Story（strong coupling 例外）：
- #XXX Story 標題
- #YYY Story 標題

**Coupling 原因**：[說明為何無法拆分為獨立 PR]
```

若未標注 coupling 原因，視為違反規範，PR 不得合併。

---

## Quality Gate：PR 提交前自我檢查

建立 PR 前，必須確認以下 checklist：

```
[ ] 本 PR 是否只包含單一 Story 的變更？
    → 是：繼續
    → 否：是否有 strong coupling 原因？
      → 有：在 PR 說明中填寫「Story Coupling 聲明」
      → 無：必須拆分為獨立 PR，不得繼續
```

---

## 四個選項

測試全數通過後，提供以下四個選項：

### 選項 1：本地合併（Merge to base branch）

```bash
git checkout <base-branch>
git pull origin <base-branch>
git merge <feature-branch>
# 執行測試確認合併後仍通過
git branch -d <feature-branch>
```

### 選項 2：建立 PR（Create PR）

```bash
git push -u origin <feature-branch>
gh pr create
```

### 選項 3：保留（Keep as-is）

保留分支與 Worktree，不做任何清理。適用於尚需後續開發的情境。

### 選項 4：丟棄（Discard）

需要使用者輸入 `discard` 確認後，才執行：

```bash
git branch -D <feature-branch>
```

---

## Quick Reference

| 選項 | Merge | Push | 保留 Worktree | 清理 Branch |
|------|-------|------|--------------|------------|
| 1. 本地合併 | ✓ | - | - | ✓ |
| 2. 建立 PR | - | ✓ | ✓ | - |
| 3. 保留 | - | - | ✓ | - |
| 4. 丟棄 | - | - | - | ✓（force） |

### Worktree 清理規則

- **清理 Worktree**：選項 1、選項 4
- **保留 Worktree**：選項 2、選項 3
