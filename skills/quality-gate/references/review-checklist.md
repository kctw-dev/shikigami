# 代碼審查清單 & 缺陷分類

> 參見主文件：`skills/quality-gate/SKILL.md §6–§7`

## §6 代碼審查清單

QA subagent 進行代碼審查時，必須逐項檢查以下清單：

| 項目 | 檢查內容 | 自檢 |
|------|----------|------|
| Logic correctness（邏輯正確性） | 業務邏輯是否正確、邊界條件是否處理 | [ ] |
| Error handling（錯誤處理） | 異常是否妥善捕獲與處理、錯誤訊息是否有意義 | [ ] |
| Naming conventions（命名慣例） | 變數、函式、類別命名是否清晰一致 | [ ] |
| Code organization（代碼組織） | 檔案結構是否合理、職責是否清晰分離 | [ ] |
| Cyclomatic complexity（圈複雜度） | 單一函式圈複雜度 < 10 | [ ] |
| Duplication detection（重複偵測） | 是否存在重複代碼，是否應抽取共用模組 | [ ] |
| SOLID compliance（SOLID 合規） | 是否遵循 SOLID 原則（SRP、OCP、LSP、ISP、DIP） | [ ] |
| Dependency verification（邏輯依賴驗證） | 若當前 Story 依賴其他 Story，確認被依賴 Story 的狀態（Issue ID + 是否已 merge） | [ ] |

### 邏輯依賴驗證（Dependency Verification）

<!-- #435 Sprint 121 — Shoot 模式邏輯依賴驗證 -->

**觸發條件**：Story 描述、PR body 或 commit message 中出現以下任一形式時觸發：
- `depends on #N`、`依賴 #N`、`blocked by #N`、`requires #N`

**檢查步驟**：

1. 識別所有被依賴的 Story（Issue ID 列表）
2. 查詢每個依賴 Story 的狀態：`gh issue view <N> -R <repo> --json state,title`
3. 確認對應 PR 是否已 merge：`gh pr list -R <repo> --search "closes #N" --state merged`

**Review Feedback 格式**：

```
[DEP-CHECK] 依賴驗證結果：
  - #<Story ID>（<標題>）：<狀態>
    - Issue 狀態：open / closed
    - PR merge 狀態：merged / not merged / not found
    - 結論：OK / WARN / BLOCK
```

**判定規則**：

| 狀態 | 結論 | 處置 |
|------|------|------|
| Issue closed + PR merged | OK | 不阻擋 |
| Issue closed，PR 狀態不明 | WARN | Important 缺陷，建議確認 |
| Issue open 或 PR not merged | BLOCK | Critical 缺陷，進入 §7.1 互動決策點 |

**未偵測到依賴時**：跳過此檢查，不輸出任何 `[DEP-CHECK]` 訊息。

---

## §7 缺陷分類與建議分層

<!-- US-384 Review 建議清單分層（MUST FIX vs SUGGESTION）— Sprint 119 -->

審查發現的問題依阻塞性分為兩層，再細分三級：

### MUST FIX 層（阻塞）

| 等級 | 名稱 | 定義 | 處理方式 |
|------|------|------|----------|
| Critical | 關鍵缺陷 | 影響系統正確性、安全性或穩定性的嚴重問題 | **必須修復**才能合併，進入 §7.1 CRITICAL 互動決策點 |
| Important | 重要缺陷 | 影響可維護性、效能或可讀性的問題 | **應該修復**，累計 3 個以上**阻塞**門禁 |

### SUGGESTION 層（非阻塞）

| 等級 | 名稱 | 定義 | 處理方式 |
|------|------|------|----------|
| Suggestion | 改進建議 | 風格優化、更佳實踐方式的建議 | **非阻塞**，Developer 自行決定；選擇不採納時須記錄決策理由 |

**分層設計原意**（參照 `docs/discovery/PB-2026-03-23-review-suggestions.md`）：MUST FIX 不修不過 gate；SUGGESTION 由 Developer 保留決策權，降低強制修復循環次數。

### 判定規則

- 存在任何 **Critical** 缺陷 → 依 `project_level` 進入 §7.1 CRITICAL 互動決策點（low=自動修復；medium/high=AskUserQuestion 逐一確認）
- 僅有 **Important** 缺陷 → 門禁 **條件通過**，強烈建議修復
- 僅有 **Suggestion** → 門禁 **PASS**，建議改進但不阻擋

### §7.1 CRITICAL 互動決策點

**project_level 分層控制**（讀取 `.claude/shikigami.local.md` 的 `shikigami.project_level`，無設定時 fallback 為 `medium`）：

| project_level | CRITICAL 處理方式 |
|---------------|-----------------|
| **low** | 自動修復（現有行為不變），不彈出 AskUserQuestion，直接進入修復循環 |
| **medium** | 用 AskUserQuestion 逐一確認每個 CRITICAL 缺陷，使用者選擇 A/B/C |
| **high** | 用 AskUserQuestion 逐一確認每個 CRITICAL 缺陷，使用者選擇 A/B/C |

**low 模式**（自動修復）：

當 `project_level = low` 時，QA 發現 CRITICAL 缺陷後直接輸出問題清單，派遣 Developer subagent 修復，修復完成後重新執行品質門禁。不顯示互動確認選項。

**medium/high 模式**（AskUserQuestion 逐一確認）：

當 `project_level = medium` 或 `high` 時，QA 發現 CRITICAL 缺陷時，**不直接 FAIL**，而是用 `AskUserQuestion` 向使用者提出結構化選項（每個 CRITICAL 缺陷逐一確認）：

```
[CRITICAL] 發現 N 個關鍵缺陷：
  - [Critical] {file}:{line}: {問題描述}

請選擇處置方式：
  A. 修復後重新審查（推薦）
  B. 降級為 Important，本次繼續（需提供降級理由，強制記錄）
  C. 接受風險並繼續（需在 GitHub 建立 Issue，強制記錄）
```

**選項規則**：

| 選項 | 條件 | 後續動作 |
|------|------|---------|
| **A. 修復** | 無條件可選（推薦） | Developer 修復 → 重新審查 |
| **B. 降級** | 非 Security 類 CRITICAL 可選 | 強制記錄至 `docs/km/quality-decisions/YYYY-MM-DD-session-<SESSION_ID>.md`，附降級理由（US-322 AC-5） |
| **C. 接受風險** | 必須提供 GitHub Issue 編號 | 強制記錄至 `docs/km/quality-decisions/YYYY-MM-DD-session-<SESSION_ID>.md`，附 Issue 編號（US-322 AC-5） |

**Security 類 CRITICAL 限制**：涉及安全漏洞（SQL Injection、XSS、認證繞過等）的 CRITICAL 缺陷，**不允許選擇 B（降級）**，只能 A（修復）或 C（接受風險並建立 Security Issue）。

**防濫用機制**：
- 同一個 Story/PR 連續選擇 B 或 C **超過 2 次**，強制升級至 Architect 審查
- 若 `docs/km/quality-decisions/` 中 C 選擇率 > 20%（跨所有 session summary），觸發設計回顧

**HARD-GATE 語意調整**：本互動決策點不取消 HARD-GATE，而是將「必須修復才能繼續」擴充為「必須做出有記錄的知情決策才能繼續」。未做選擇 = 門禁 FAIL，不得繼續。

### §7.2 決策記錄格式

選擇 B 或 C 時，強制寫入 `docs/km/quality-decisions/YYYY-MM-DD-session-<SESSION_ID>.md`（per-session 檔案，US-322 AC-5）：

> **路徑規則**：SESSION_ID 取自 `${CLAUDE_SESSION_ID:-unknown}`；路徑 = `docs/km/quality-decisions/$(date '+%Y-%m-%d')-session-${SESSION_ID}.md`。結算腳本：`hooks/quality-decisions-settle.sh`。

```markdown
## {日期} — {Story/PR 標識}

| 欄位 | 內容 |
|------|------|
| 問題描述 | {CRITICAL 缺陷描述} |
| 選擇 | B（降級）/ C（接受風險） |
| 理由 | {使用者提供的理由} |
| 後續行動 | {Issue 編號或修復計劃} |
| 審查者 | QA Engineer |
```

此 per-session 文件為追溯用途，供 Sprint Review 時檢視品質決策歷史。結算後可參照 `docs/km/quality-decisions/<date>.summary.md`。
