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
2. **代碼審查**：依據審查清單（見 `references/review-checklist.md §6`）逐項檢查代碼品質。
3. **測試覆蓋檢查**：驗證測試覆蓋率是否達到 80% 門檻，測試金字塔比例是否合理。
4. **安全性基本檢查**：檢查輸入驗證是否完整、是否存在 SQL Injection / XSS / Command Injection 等常見注入漏洞。
5. **判定結果**：
   - **PASS**：所有標準達標，代碼可進入下一階段（合併或部署）。
   - **FAIL**：產出具體問題清單（含嚴重度分級），交由 Developer 修復後重新審查。

---

## 5. Decision Challenger 機制

> 完整規則與輸出格式 → [`references/decision-challenger.md`](references/decision-challenger.md)

QA Engineer 在品質門禁之外，還承擔 **Decision Challenger**（Devil's Advocate）角色。當 Architect 產出技術評估或架構決策時，QA 自動啟動此機制，為被否決方案辯護、描述被採納方案的潛在失敗情境。

<HARD-GATE>
當 Architect 產出技術評估時，QA 必須執行 Decision Challenger 流程。
即使 QA 完全同意 Architect 的決策，仍然必須提出挑戰。不得跳過此步驟。
</HARD-GATE>

---

## 6. 代碼審查清單 & 缺陷分類

> 完整清單與分層規則 → [`references/review-checklist.md`](references/review-checklist.md)

- §6：逐項審查清單（邏輯、錯誤處理、命名、SOLID、依賴驗證等 8 項）
- §7：缺陷分層（MUST FIX / SUGGESTION）、§7.1 CRITICAL 互動決策點（A/B/C 選項）、§7.2 決策記錄格式

---

## 7. 審查失敗處理

<!-- US-384 Review 建議清單分層（MUST FIX vs SUGGESTION）— Sprint 119 -->

當品質門禁發現問題時，依分層處理：

**MUST FIX 層（阻塞）**：

1. QA subagent 產出問題清單，每個 MUST FIX 問題標注嚴重度（Critical / Important）
2. **Critical 問題**：進入 `references/review-checklist.md §7.1` CRITICAL 互動決策點，使用者選擇 A/B/C
3. 選擇 A（修復）：Developer subagent 接收問題清單進行修復，修復完成後重新執行品質門禁審查
4. 選擇 B/C：強制寫入決策記錄（`references/review-checklist.md §7.2`），流程繼續
5. 同一門禁連續失敗 3 次（選擇 A 後仍 FAIL），升級至 Architect 評估是否存在設計層面的問題
6. 同一 Story/PR 連續選擇 B/C 超過 2 次，強制升級至 Architect 審查

**SUGGESTION 層（非阻塞）**：

7. QA subagent 產出 SUGGESTION 清單，每個問題標注改善方向
8. Developer 自行決定是否採納：選擇不採納時，在 commit message 或審查回覆中記錄決策理由
9. SUGGESTION 問題不觸發 FAIL，不影響門禁判定，不進入修復循環

---

## 8.1 KM 文件品質檢查

> 完整規則與輸出格式 → [`references/km-quality-check.md`](references/km-quality-check.md)

適用 `docs/km/` 目錄下含第三方 API 資訊的文件。觸發關鍵字：API、SDK、endpoint、webhook、OAuth、第三方。違規輸出 `[KM-WARN]`（Important 等級），超過 3 項升級為 Critical。

---

## 9. 與其他 Skill 的關係

| 情境 | 觸發 |
|------|------|
| Story 實作完成，需要審查 | 由 `sprint-execution` 觸發 `quality-gate` |
| Architect 產出技術評估 | 觸發 Decision Challenger 機制 |
| 發現安全漏洞 | 升級至 `security-review` 進行深度安全審查 |
| 設計層面問題 | 升級至 `architecture-decision` 重新評估 |
| 門禁通過，準備部署 | 觸發 `deployment-readiness` 進行部署準備 |
