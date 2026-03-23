---
name: quality-gate
description: "Use when code review is needed, features are complete, PRs are ready, or quality metrics need checking"
---

# Quality Gate — QA 品質門禁

## 1. 概述

QA 品質門禁 Skill，由 **QA Engineer** 主導的品質檢查流程。確保所有代碼在合併前通過嚴格的品質標準，涵蓋測試覆蓋率、代碼複雜度、安全性基本檢查，以及 Decision Challenger 機制。

---

## 2. 品質門禁標準

所有代碼必須通過以下品質門禁才能合併：

| 指標 | 門檻 | 說明 |
|------|------|------|
| 測試覆蓋率 | > 80% | 行覆蓋率與分支覆蓋率皆須達標 |
| 關鍵缺陷 | 零 | 不允許任何 Critical 級別缺陷存在 |
| 自動化測試比例 | > 70% | 自動化測試佔所有測試案例的比例 |
| Cyclomatic Complexity | < 10 | 單一函式的圈複雜度上限 |

<HARD-GATE>
品質門禁標準為強制性要求。任何未達標的代碼不得合併至主分支。
關鍵缺陷必須經過處置才能繼續（CRITICAL 缺陷的處置方式參見 §7.1 互動決策點）。
</HARD-GATE>

---

## 3. 測試金字塔

測試分佈遵循測試金字塔原則，確保快速回饋與穩定性：

```
        /  E2E  \          10%  — 端對端測試（關鍵使用者旅程）
       /--------\
      / 整合測試  \        20%  — 模組間整合驗證
     /------------\
    /   單元測試    \      70%  — 函式級別的隔離測試
   /________________\
```

| 測試層級 | 比例 | 職責 |
|----------|------|------|
| 單元測試 | 70% | 驗證單一函式或模組的邏輯正確性，執行速度快、隔離性高 |
| 整合測試 | 20% | 驗證模組間的交互與資料流正確性 |
| E2E 測試 | 10% | 驗證關鍵使用者旅程與端對端業務流程。Web UI 場景可使用 agent-browser 執行瀏覽器 E2E（詳見 `skills/browser-automation/SKILL.md`），agent-browser 未安裝時降級為程式碼層級驗證 |

---

## 4. 品質門禁流程

```
1. QA subagent 派遣 → 代碼審查
   |
   v
2. 審查標準：
   - 邏輯正確性
   - 錯誤處理
   - 命名慣例
   - SOLID 合規
   - 重複偵測
   |
   v
3. 測試覆蓋檢查
   |
   v
4. 安全性基本檢查（輸入驗證、注入漏洞）
   |
   v
5. PASS → 繼續
   FAIL → 修復 → 重新審查
```

### 步驟詳解

1. **派遣 QA subagent**：針對完成的功能或 PR，派遣 QA subagent 進行代碼審查。
2. **代碼審查**：依據審查清單（見第 6 節）逐項檢查代碼品質。
3. **測試覆蓋檢查**：驗證測試覆蓋率是否達到 80% 門檻，測試金字塔比例是否合理。
4. **安全性基本檢查**：檢查輸入驗證是否完整、是否存在 SQL Injection / XSS / Command Injection 等常見注入漏洞。
5. **判定結果**：
   - **PASS**：所有標準達標，代碼可進入下一階段（合併或部署）。
   - **FAIL**：產出具體問題清單（含嚴重度分級），交由 Developer 修復後重新審查。

---

## 5. Decision Challenger 機制

QA Engineer 在品質門禁之外，還承擔 **Decision Challenger**（Devil's Advocate）角色：

### 觸發時機

當 Architect 產出技術評估或架構決策時，QA 自動啟動 Decision Challenger 機制。

### 執行規則

1. **為被否決方案辯護**：無論 QA 個人是否同意 Architect 的決策，必須為被否決的方案提出最強論述。
2. **描述具體失敗情境**：針對被採納的方案，描述可能導致失敗的具體情境與條件。
3. **即使同意也必須挑戰**：這是流程強制要求，不因個人認同而跳過挑戰步驟。
4. **建設性挑戰**：目標是強化決策品質，而非阻礙進度。

### 輸出格式

```
## Decision Challenge Report

### 被否決方案的最強論述
- [論點 1]
- [論點 2]

### 被採納方案的潛在失敗情境
- 情境 1：[具體描述]
- 情境 2：[具體描述]

### 風險緩解建議
- [建議 1]
- [建議 2]

### 最終結論
維持原決策 / 建議重新評估
```

<HARD-GATE>
當 Architect 產出技術評估時，QA 必須執行 Decision Challenger 流程。
即使 QA 完全同意 Architect 的決策，仍然必須提出挑戰。不得跳過此步驟。
</HARD-GATE>

---

## 6. 代碼審查清單

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

## 7. 缺陷分類與建議分層

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

---

## 8. 審查失敗處理

<!-- US-384 Review 建議清單分層（MUST FIX vs SUGGESTION）— Sprint 119 -->

當品質門禁發現問題時，依分層處理：

**MUST FIX 層（阻塞）**：

1. QA subagent 產出問題清單，每個 MUST FIX 問題標注嚴重度（Critical / Important）
2. **Critical 問題**：進入 §7.1 CRITICAL 互動決策點，使用者選擇 A/B/C
3. 選擇 A（修復）：Developer subagent 接收問題清單進行修復，修復完成後重新執行品質門禁審查
4. 選擇 B/C：強制寫入決策記錄（§7.2），流程繼續
5. 同一門禁連續失敗 3 次（選擇 A 後仍 FAIL），升級至 Architect 評估是否存在設計層面的問題
6. 同一 Story/PR 連續選擇 B/C 超過 2 次，強制升級至 Architect 審查

**SUGGESTION 層（非阻塞）**：

7. QA subagent 產出 SUGGESTION 清單，每個問題標注改善方向
8. Developer 自行決定是否採納：選擇不採納時，在 commit message 或審查回覆中記錄決策理由
9. SUGGESTION 問題不觸發 FAIL，不影響門禁判定，不進入修復循環

---

## 8.1 KM 文件品質檢查（第三方 API enum 來源驗證）

<!-- US-274 KM 第三方 API 文件驗證機制 — Sprint 100, #276 -->

**適用範圍**：`docs/km/` 目錄下含第三方 API 資訊的文件。

**觸發條件（以下任一出現在審查對象中即觸發）**：API、SDK、endpoint、webhook、OAuth、第三方。

**純內部模組文件、ADR、Retrospective Log 等非第三方 API 類文件不觸發此項。**

### KM 品質檢查清單

| 項目 | 檢查內容 | 等級 |
|------|----------|------|
| KM-API-1：Enum 來源標注 | KM 文件中的 API enum 值是否附有官方文件 URL、版本號或實測日期 | Important（WARN） |
| KM-API-2：Enum 完整性宣告 | enum 列舉是否標注「完整列舉」或「部分列舉（截至 YYYY-MM-DD）」 | Important（WARN） |

### 判定規則

- 違反 KM-API-1 或 KM-API-2 → 門禁輸出 `[KM-WARN]`，等級為 **Important**
- `[KM-WARN]` 不觸發 CRITICAL 互動決策點（不阻擋合併），但必須記錄於審查報告
- 同一文件連續違反超過 3 項 → 升級為 **Critical**，進入 §7.1 CRITICAL 互動決策點

### 輸出格式

```
[KM-WARN] {檔案路徑}: enum "{參數名}" 缺少來源標注
[KM-WARN] {檔案路徑}: enum "{參數名}" 缺少完整性宣告（需標注「完整列舉」或「部分列舉，截至 YYYY-MM-DD」）
```

---

## 9. 與其他 Skill 的關係

| 情境 | 觸發 |
|------|------|
| Story 實作完成，需要審查 | 由 `sprint-execution` 觸發 `quality-gate` |
| Architect 產出技術評估 | 觸發 Decision Challenger 機制 |
| 發現安全漏洞 | 升級至 `security-review` 進行深度安全審查 |
| 設計層面問題 | 升級至 `architecture-decision` 重新評估 |
| 門禁通過，準備部署 | 觸發 `deployment-readiness` 進行部署準備 |
