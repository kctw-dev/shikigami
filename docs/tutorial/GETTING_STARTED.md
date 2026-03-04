# 入門教學：從安裝到第一個 Sprint

**適合對象**：首次安裝 Shikigami 的外部使用者
**預計時間**：30–60 分鐘（含環境確認）
**對應版本**：v0.26.0+

---

## 目錄

1. [步驟 1：前置條件確認](#步驟-1前置條件確認)
2. [步驟 2：安裝 Shikigami](#步驟-2安裝-shikigami)
3. [步驟 3：初始化專案（`shikigami:onboarding`）](#步驟-3初始化專案shikigamionboarding)
4. [步驟 3.5：設定 GitHub Labels](#步驟-35設定-github-labels)
5. [步驟 4：定義第一個 User Story](#步驟-4定義第一個-user-story)
6. [步驟 5：執行 Sprint Planning](#步驟-5執行-sprint-planning)
7. [步驟 6：執行 Sprint Execution（至少 1 個 Story）](#步驟-6執行-sprint-execution至少-1-個-story)
8. [步驟 7：執行 Sprint Review](#步驟-7執行-sprint-review)

---

## 概覽

本教學帶你走完 Shikigami 的完整上手路徑：

```
前置條件確認 → 安裝 Shikigami → 初始化專案 → 定義 User Story
→ Sprint Planning → Sprint Execution → Sprint Review
```

每個步驟都提供具體指令與預期輸出，讓你知道走對了路。遇到問題請參閱 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)。

---

## 步驟 1：前置條件確認

在安裝 Shikigami 前，請確認以下條件已全部滿足：

### 1.1 Claude Code CLI 已安裝

在終端機執行：

```bash
claude --version
```

**預期輸出**：
```
claude 1.x.x
```

如果出現「command not found」，請先安裝 Claude Code CLI：

```bash
npm install -g @anthropic-ai/claude-code
```

安裝完成後重新執行 `claude --version` 確認。

> **[修正理由 — 高摩擦步驟 #1]**：原文僅提供外部文件連結，使用者需離開本教學查閱外部文件才能繼續安裝。判定標準：步驟需要查詢外部文件。修正方式：將最常用的安裝指令直接內嵌，讓 90% 的使用者不需離開本頁即可完成安裝。需要進階設定（代理、企業環境等）的使用者仍可參閱 [Claude Code 官方文件](https://docs.anthropic.com/en/docs/claude-code)。

### 1.2 Claude Code 帳號已認證

開啟 Claude Code，輸入任意問題確認可正常對話：

```
> 你好，你是誰？
```

**預期輸出**：Claude 正常回應，無認證錯誤（無 401 錯誤訊息）

如果出現認證問題，請先完成 Claude Code 帳號設定再繼續。

### 1.3 GitHub CLI 已安裝（部分功能需要）

```bash
gh --version
```

**預期輸出**：
```
gh version 2.x.x (...)
```

> **注意**：GitHub CLI 並非安裝 Shikigami 的必要條件，但 Sprint Execution 的 Issue 管理、PR 建立等功能需要它。建議提前安裝並認證（`gh auth login`）。

### 1.4 網路連線正常

確認可連線至 Claude Code marketplace（需存取網路）。

---

## 步驟 2：安裝 Shikigami

Shikigami 透過 Claude Code Plugin 系統安裝，**所有指令都在 Claude Code 互動介面中輸入**（不是終端機 shell）。

### 2.1 開啟 Claude Code 互動介面

啟動 Claude Code 並開始新 Session。

### 2.2 加入 Marketplace

```
/plugin marketplace add KCTW/shikigami
```

**預期輸出**：
```
Marketplace source added: KCTW/shikigami
```

### 2.3 安裝 Plugin（二選一）

**方式 A — 指令安裝：**
```
/plugin install shikigami
```

**方式 B — UI 安裝：**
```
/plugin
```
開啟 Plugin UI → 點選 Discover → 找到 shikigami → 安裝

**預期輸出**：
```
Plugin installed: shikigami
```

### 2.4 驗證安裝成功

**開啟新 Session**（重要：Plugin 需要在新 Session 才會載入），然後確認：

```
> 你有 shikigami superpowers 嗎？
```

**預期輸出**：Claude 確認已載入 Shikigami Skills，並能列出可用的技能。

或者查看 Plugin UI：
```
/plugin
```
確認 shikigami 顯示為 Active 狀態。

---

## 步驟 3：初始化專案（`shikigami:onboarding`）

在你的專案目錄中開啟 Claude Code，然後對 Claude 說：

```
> 幫我初始化 Shikigami
```

**Claude 的行為**：
- Scrum Master 觸發 `shikigami:onboarding`
- Onboarding subagent 引導你填寫專案資訊

**預期輸出**：
```
🔄 Scrum Master：觸發 onboarding

📋 Onboarding subagent：
   ✓ 建立 CLAUDE.md（專案配置檔案）
   ✓ 建立 docs/ 目錄結構：
     ├── docs/prd/PRODUCT_BACKLOG.md
     ├── docs/sprints/
     ├── docs/adr/
     └── docs/km/
   ✓ 初始化完成，可以開始使用 Shikigami
```

### 確認初始化結果

```bash
ls CLAUDE.md docs/prd/PRODUCT_BACKLOG.md
```

**預期輸出**：兩個檔案均存在（無「No such file」錯誤）

> **注意**：如果你在 Shikigami 框架 repo 本身（含 `.claude-plugin/plugin.json`）執行 onboarding，CLAUDE.md 檢查會自動略過，此為正常行為。

---

## 步驟 3.5：設定 GitHub Labels

Shikigami 使用 GitHub Labels 來追蹤 Issues 狀態。

**前置確認**：先確認 `gh` 已認證（`gh auth status`）。若尚未認證，執行 `gh auth login` 並跟隨提示完成。

執行以下腳本自動建立所需 Labels：

```bash
bash scripts/setup-labels.sh
```

**預期輸出**：
```
Labels setup complete.
```

腳本可重複執行（冪等），不會建立重複的 Labels。

> **[修正理由 — 高摩擦步驟 #2]**：原文未說明「gh 需要已認證」這個隱性前置條件，使用者執行腳本後才會遇到認證錯誤，需要中斷、查詢 `gh auth login` 用法、認證後再返回。判定標準：步驟有隱性外部依賴，導致執行失敗需查詢外部文件。修正方式：在步驟開頭直接提供認證確認與登入指令，避免中斷流程。

---

## 步驟 4：定義第一個 User Story

告訴 Claude 你想建立的功能：

```
> 我想建立一個使用者登入功能，包含帳號密碼驗證和 JWT token 認證
```

**Claude 的行為**：
- Scrum Master 觸發 `shikigami:backlog-management`
- PO subagent 分析需求，Architect subagent 評估技術可行性

**預期輸出**：
```
🔄 Scrum Master：觸發 backlog-management

📋 PO subagent：
   ✓ 需求分析完成
   ✓ 產出候選 User Stories（含 RICE 評分）：
     - US-01：使用者帳密登入（RICE: 45）
     - US-02：JWT token 認證（RICE: 38）
   ✓ PRODUCT_BACKLOG.md 已更新

🏗️ Architect subagent：
   ✓ 技術評估：可行
   ✓ 估點：US-01(S), US-02(M)
```

> **提示**：你不需要精確描述需求。用自然語言說你想做什麼，PO subagent 會協助整理成標準 User Story 格式。

---

## 步驟 5：執行 Sprint Planning

當你有足夠的 User Stories，可以開始 Sprint Planning：

```
> 開始 Sprint Planning
```

**Claude 的行為**：
- Scrum Master 觸發 `shikigami:sprint-planning`
- PO 選取 Stories → Architect 技術評估 → QA 確認 AC 可測試性

**預期輸出**：
```
🔄 Scrum Master：觸發 sprint-planning

📋 PO subagent：
   ✓ 從 Backlog 選取 2 個 Stories（4 points）
   ✓ Sprint Goal：「建立使用者認證基礎」

🏗️ Architect subagent：
   ✓ 技術評估完成
   ✓ Story A(S/1pt)：帳密登入 — 無 ADR 需求
   ✓ Story B(M/2pt)：JWT 認證 — 建議新建 ADR

🔍 QA subagent：
   ✓ AC 可測試性確認 — 全部通過
   ✓ Sprint 1 QA Hard Gate：PASS

📋 PO subagent：
   ✓ docs/sprints/sprint_1.md 已建立
```

**驗證 Sprint 文件已建立**：
```bash
cat docs/sprints/sprint_1.md
```

**預期輸出**：Sprint 文件包含選取的 Stories、Sprint Goal 和 Acceptance Criteria。

### Sprint Planning QA Hard Gate

QA 會確認每個 Story 的 Acceptance Criteria 可測試性。若 QA Hard Gate 失敗，Sprint Planning 不會繼續 — 需要先修正 AC 的問題。詳見 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)。

---

## 步驟 6：執行 Sprint Execution（至少 1 個 Story）

對 Claude 說出你要實作的 Story：

```
> 實作 US-01 使用者帳密登入功能
```

**Claude 的行為**：
- Scrum Master 觸發 `shikigami:sprint-execution`
- Developer subagent 依 TDD 循環實作
- QA subagent 雙階段審查（Spec Compliance + Code Quality）

**預期輸出**：
```
🔄 Scrum Master：觸發 sprint-execution

👨‍💻 Developer subagent：
   🔴 Red — 撰寫失敗測試
      ✓ commit: "test: 新增使用者登入失敗測試"
   🟢 Green — 最小實作通過測試
      ✓ commit: "feat: 實作使用者帳密驗證邏輯"
   🔄 Refactor — 重構優化
      ✓ commit: "refactor: 抽取驗證邏輯為獨立函式"

🔍 QA subagent（Spec Compliance Review）：
   ✓ AC1：帳號格式驗證 — PASS
   ✓ AC2：密碼雜湊比對 — PASS
   ✓ AC3：登入失敗回傳 401 — PASS

🔍 QA subagent（Code Quality Review）：
   ✓ 無硬編碼金鑰
   ✓ 錯誤處理完整
   ✓ 品質門禁：PASS

📋 docs/sprints/sprint_1.md 更新 — US-01 狀態：完成
```

**驗證 Story 已完成**：
```bash
git log --oneline -5
```

**預期輸出**：看到 Developer 的 TDD commit 記錄（test: → feat: → refactor:）

### TDD 循環說明

Developer 依照以下循環實作每個功能：

| 階段 | 動作 | Commit 格式 |
|------|------|------------|
| Red | 先寫失敗測試，定義預期行為 | `test: ...` |
| Green | 最小實作，讓測試通過 | `feat: ...` |
| Refactor | 重構優化，保持測試通過 | `refactor: ...` |

---

## 步驟 7：執行 Sprint Review

所有 Stories 完成後，執行 Sprint Review：

```
> 執行 Sprint Review
```

或者，當所有 Story 完成時，Scrum Master 通常會自動觸發 Sprint Review。

**Claude 的行為**：
- Scrum Master 觸發 `shikigami:sprint-review`
- PO Demo → Stakeholder 驗收 → Retrospective Analytics → Action Items

**預期輸出**：
```
🔄 Scrum Master：觸發 sprint-review

📋 PO subagent（Demo）：
   ✓ US-01：帳密登入功能 — DEMO PASS
   ✓ Sprint Goal「建立使用者認證基礎」— 達成

👥 Stakeholder subagent：
   ✓ Sprint 1 驗收：接受
   ✓ Velocity：2 points（1 Story）

📊 Retrospective Analytics：
   ✓ Velocity 趨勢：[2]（Sprint 1）
   ✓ 問題記錄：0 個問題
   ✓ Action Items：無

📋 docs/km/Metrics_Log.md 已更新
📋 docs/km/Retrospective_Log.md 已更新
```

**驗證 Review 完成**：
```bash
cat docs/km/Metrics_Log.md
```

**預期輸出**：Sprint 1 的 Velocity 和完成率記錄已填入。

---

## 恭喜！

你已完成 Shikigami 的第一個完整 Sprint 循環。接下來你可以：

- **繼續下一個 Sprint**：說「開始下一個 Sprint」，進入 Sprint 2
- **新增需求**：說你想做什麼，PO subagent 會幫你整理 User Story
- **執行 Standup**：說「standup」或「開始站立會議」，取得健康快篩報告
- **查看 Backlog**：說「看一下 Backlog 的優先順序」

---

## 常用自然語言指令參考

你不需要記憶精確指令，以下只是常見表達方式的範例：

| 意圖 | 範例說法 |
|------|---------|
| 新增需求 | 「我想加一個...功能」、「我們需要...」 |
| Sprint Planning | 「開始 Sprint」、「開始 Sprint Planning」 |
| 實作 Story | 「實作 US-XX」、「開始做 XX 功能」 |
| Sprint Review | 「執行 Sprint Review」、「Sprint 結束了」 |
| 查看狀態 | 「standup」、「我們現在進度如何？」 |
| 架構決策 | 「要用 A 還是 B？」、「需要做技術選型」 |
| 查看文件 | 「看一下 Backlog」、「最近的 Sprint 結果？」 |

---

## 進階功能

完成第一個 Sprint 後，可以進一步探索：

- **架構決策**：說「需要決定技術選型」，觸發 ADR 流程
- **GitHub Issues 管理**：說「幫我分類 GitHub Issues」
- **解咒模式**：說「幫我分析這段 Legacy 代碼」，觸發 dispel Skill
- **平行執行**：多個獨立 Stories 可平行派遣，加速 Sprint

---

## 相關文件

- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) — 常見問題排查指南
- [README.md（專案入口）](../../README.md) — 完整功能說明
- [安裝驗證報告](../km/INSTALL_VERIFICATION.md) — 安裝流程驗證記錄（US-15）
