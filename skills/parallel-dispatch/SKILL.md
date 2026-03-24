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

詳細步驟（含 file lock / claim 程式碼）見 `references/dispatch-flow.md`。

---

## 4. Agent Prompt 結構

Prompt 四要素：聚焦、自足、有限制、明確產出。

詳細範本與常見錯誤見 `references/prompt-structure.md`。

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
