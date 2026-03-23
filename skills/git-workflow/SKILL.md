---
name: git-workflow
description: "Use when starting feature work needing branch isolation, or when development is complete and ready to merge/PR"
---

# Git Workflow — 分支隔離與完成流程

## 1. 概述

本 Skill 涵蓋開發的完整 Git 生命週期 — 從建立隔離環境到完成合併。

包含兩個主要流程：

- **開始開發** — 建立 Worktree 與 Feature Branch，確保乾淨的隔離環境
- **完成開發** — 測試通過後，選擇合併、建立 PR、保留或丟棄

---

## 2. 開始開發：建立隔離環境

### 流程

```
確認 Worktree 目錄
  │
  v
安全驗證（.gitignore）
  │
  v
建立 Worktree + Feature Branch
  │
  v
安裝依賴
  │
  v
基線測試
```

### 2.1 Worktree 目錄選擇

依照以下優先順序決定 Worktree 根目錄：

| 優先順序 | 來源 | 路徑 |
|----------|------|------|
| 1 | 預設目錄 | `.worktrees/` |
| 2 | 備選目錄 | `worktrees/` |
| 3 | 專案設定 | CLAUDE.md 中指定的路徑 |
| 4 | 互動詢問 | 詢問使用者指定路徑 |

### 2.2 安全驗證

執行 `.gitignore` 檢查，確保 Worktree 目錄不會被意外追蹤：

```bash
git check-ignore -q .worktrees
```

若該目錄**未被** `.gitignore` 忽略：

1. 將目錄加入 `.gitignore`
2. `git add .gitignore`
3. `git commit -m "chore: add worktree directory to .gitignore"`

### 2.3 建立 Worktree + Feature Branch

```bash
git worktree add <worktree-path> -b <branch-name>
```

Branch 命名規則參見 [第 3 節](#3-開發過程中)。

### 2.4 安裝依賴

自動偵測專案類型並安裝依賴：

| 偵測檔案 | 執行指令 |
|----------|----------|
| `package.json` | `npm install` |
| `Cargo.toml` | `cargo build` |
| `pyproject.toml` | `pip install -e .` 或 `poetry install` |
| `go.mod` | `go mod download` |

### 2.5 基線測試

在隔離環境中執行測試，確認乾淨起點：

- 測試**通過** → 環境就緒，開始開發
- 測試**失敗** → 報告失敗內容，詢問使用者是否仍要繼續

---

## 3. 開發過程中

### Branch 命名規範

使用語意化前綴：

| 前綴 | 用途 |
|------|------|
| `feat/` | 新功能 |
| `fix/` | 修復 Bug |
| `refactor/` | 重構 |

### Commit 規範

遵循 Conventional Commits 規範：

| 類型 | 說明 |
|------|------|
| `feat:` | 新增功能 |
| `fix:` | 修復錯誤 |
| `refactor:` | 重構程式碼（不改變行為） |
| `docs:` | 文件變更 |
| `test:` | 測試相關 |

**原則：每個小步驟一個 commit**，保持 commit 歷史清晰可追蹤。

---

## 4. 完成開發：整合工作成果

<HARD-GATE>
測試未全部通過時，不得進行合併或建立 PR。
必須先修復所有失敗測試。
</HARD-GATE>

### PR 顆粒度規範

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

### Quality Gate：PR 提交前自我檢查

建立 PR 前，必須確認以下 checklist：

```
[ ] 本 PR 是否只包含單一 Story 的變更？
    → 是：繼續
    → 否：是否有 strong coupling 原因？
      → 有：在 PR 說明中填寫「Story Coupling 聲明」
      → 無：必須拆分為獨立 PR，不得繼續
```

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

<HARD-GATE>
丟棄工作成果（選項 4）必須取得使用者明確確認。
不得自動丟棄任何分支。
</HARD-GATE>

需要使用者輸入 `discard` 確認後，才執行：

```bash
git branch -D <feature-branch>
```

### Quick Reference

| 選項 | Merge | Push | 保留 Worktree | 清理 Branch |
|------|-------|------|--------------|------------|
| 1. 本地合併 | ✓ | - | - | ✓ |
| 2. 建立 PR | - | ✓ | ✓ | - |
| 3. 保留 | - | - | ✓ | - |
| 4. 丟棄 | - | - | - | ✓（force） |

### Worktree 清理規則

- **清理 Worktree**：選項 1、選項 4
- **保留 Worktree**：選項 2、選項 3

---

## 5. 與其他 Skill 的關係

| 情境 | 觸發 |
|------|------|
| Sprint 開始，Story 需要隔離開發 | 由 sprint-execution 呼叫，建立隔離環境 |
| Sprint 結束 | 由 sprint-review 呼叫，處理分支整合 |
| 開發完成、準備合併 | 直接觸發完成流程 |
| 測試失敗無法合併 | 觸發 systematic-debugging |
