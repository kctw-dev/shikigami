# Git Workflow — 建立隔離環境（§2 詳解）

## 流程概覽

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

---

## 2.1 Worktree 目錄選擇

依照以下優先順序決定 Worktree 根目錄：

| 優先順序 | 來源 | 路徑 |
|----------|------|------|
| 1 | 預設目錄 | `.worktrees/` |
| 2 | 備選目錄 | `worktrees/` |
| 3 | 專案設定 | CLAUDE.md 中指定的路徑 |
| 4 | 互動詢問 | 詢問使用者指定路徑 |

---

## 2.2 安全驗證

執行 `.gitignore` 檢查，確保 Worktree 目錄不會被意外追蹤：

```bash
git check-ignore -q .worktrees
```

若該目錄**未被** `.gitignore` 忽略：

1. 將目錄加入 `.gitignore`
2. `git add .gitignore`
3. `git commit -m "chore: add worktree directory to .gitignore"`

---

## 2.3 建立 Worktree + Feature Branch

建立 worktree 時，應明確指定 base ref 以確保從乾淨狀態起點開始（#968）：

```bash
# 準備：同步遠端 main
git fetch origin main

# 建立 worktree，明確指定 origin/main 作為 base
git worktree add <worktree-path> -b <branch-name> origin/main
```

**重要**：
- 使用 `origin/main` 作為 base，而非本地 `main` 或 `.`（current HEAD）
- 這確保 worktree 從遠端乾淨的 main 起點建立
- 尤其在平行執行多個 worktree 時，此做法防止 commit 交叉污染（#968 Retro Action）

---

## 2.4 安裝依賴

自動偵測專案類型並安裝依賴：

| 偵測檔案 | 執行指令 |
|----------|----------|
| `package.json` | `npm install` |
| `Cargo.toml` | `cargo build` |
| `pyproject.toml` | `pip install -e .` 或 `poetry install` |
| `go.mod` | `go mod download` |

---

## 2.5 基線測試

在隔離環境中執行測試，確認乾淨起點：

- 測試**通過** → 環境就緒，開始開發
- 測試**失敗** → 報告失敗內容，詢問使用者是否仍要繼續
