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

流程：確認 Worktree 目錄 → 安全驗證（.gitignore）→ 建立 Worktree + Feature Branch → 安裝依賴 → 基線測試

詳細步驟（目錄選擇優先順序、依賴安裝對照表）見 `references/branch-setup.md`。

---

## 3. 開發過程中

### Branch 命名規範

| 前綴 | 用途 |
|------|------|
| `feat/` | 新功能 |
| `fix/` | 修復 Bug |
| `refactor/` | 重構 |

### Commit 規範

遵循 Conventional Commits 規範：`feat:` / `fix:` / `refactor:` / `docs:` / `test:`

**原則：每個小步驟一個 commit**，保持 commit 歷史清晰可追蹤。

---

## 4. 完成開發：整合工作成果

<HARD-GATE>
測試未全部通過時，不得進行合併或建立 PR。
必須先修復所有失敗測試。
</HARD-GATE>

提供四個選項：本地合併、建立 PR、保留、丟棄。

<HARD-GATE>
丟棄工作成果（選項 4）必須取得使用者明確確認。
不得自動丟棄任何分支。
</HARD-GATE>

詳細流程（PR 顆粒度規範、Strong Coupling 例外、Quick Reference 表）見 `references/merge-flow.md`。

---

## 5. 與其他 Skill 的關係

| 情境 | 觸發 |
|------|------|
| Sprint 開始，Story 需要隔離開發 | 由 sprint-execution 呼叫，建立隔離環境 |
| Sprint 結束 | 由 sprint-review 呼叫，處理分支整合 |
| 開發完成、準備合併 | 直接觸發完成流程 |
| 測試失敗無法合併 | 觸發 systematic-debugging |
