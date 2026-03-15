# ADR-021：pr-review-toolkit 外部 Plugin 整合架構

**狀態**：Draft
**日期**：2026-03-15
**決策者**：Architect（架構定義）+ QA Decision Challenger
**關聯 ADR**：ADR-003（Shoot 模式）
**關聯 Story**：#267（RESEARCH type — Sprint 97）
**觸發來源**：#266 Planning Round 2 退回 — 外部 plugin 整合架構、降級行為、安裝提醒在框架內均未定義

---

## 背景

### 問題陳述

`pr-review-toolkit` 是 Claude Code 官方 Marketplace 的外部 Plugin，提供六個專業審查 agent。Shikigami 框架的 shoot（§8.5 外部獨立審查）與 sprint-execution 流程目前使用內部 QA subagent 執行 Spec Compliance + Code Quality 審查，但缺乏**跨檔案一致性、降級路徑靜默繞過、文件準確性**等專業維度的審查能力。

pr-review-toolkit 已安裝於本機環境，三個 agent 已在 ADR-020 實作審查中實際驗證可用：

| Agent | 專長 | 嚴重度分級 |
|-------|------|-----------|
| `code-reviewer` | 跨檔案一致性、命名規範、CLAUDE.md 合規 | Critical (90-100), Important (80-89) — confidence score |
| `silent-failure-hunter` | 降級路徑、fallback 行為、靜默繞過、error handling | CRITICAL, HIGH, MEDIUM — severity |
| `comment-analyzer` | 文件準確性、comment rot、文件與程式碼一致性 | Critical Issues, Improvement Opportunities, Recommended Removals |

### 現行外部獨立審查的定位

shoot §8.5 與 sprint-execution 的外部獨立審查目前由**獨立 QA sonnet subagent** 執行，審查範圍為：

- **Spec Compliance**：AC 逐條驗證、邊界條件、行為範例
- **Code Quality**：命名可讀性、結構設計、測試品質、安全性

這些審查由**同一個泛用 QA subagent** 完成，沒有針對特定品質維度的專業深度。

### 派遣方式（已驗證）

透過 Claude Code 的 `Agent` tool 派遣，指定 `subagent_type`：

```
subagent_type: "pr-review-toolkit:code-reviewer"
subagent_type: "pr-review-toolkit:silent-failure-hunter"
subagent_type: "pr-review-toolkit:comment-analyzer"
```

- **輸入**：透過 prompt 描述審查範圍，agent 自行讀取檔案和 git diff
- **輸出**：Markdown 格式審查報告，含嚴重度分級
- **平行執行**：三個 agent 可同時派遣

---

## 決策問題

1. pr-review-toolkit 三個 agent 如何嵌入 shoot 和 sprint-execution 流程？
2. 何時全部執行、何時部分執行（doc-only 條件）？
3. 嚴重度 Gate 如何定義（阻擋 vs 記錄）？
4. Plugin 未安裝時如何降級？
5. 何時何地提示使用者安裝？
6. 與現有 §8.5 外部獨立審查的責任邊界如何劃分？

---

## 考慮的選項

### 選項 A：補充層 — 外部獨立審查之後追加（建議）

在現有 §8.5 外部獨立審查 CONFIRM 後、CI/CD 雙審查 Gate（§8.1）前，追加 pr-review-toolkit 審查作為**補充層**。

```
步驟 5.3 外部獨立審查（現有，不變）
  ↓ CONFIRM
步驟 5.4 pr-review-toolkit 補充審查（新增）
  ↓ PASS
步驟 5.5 CI/CD 雙審查 Gate（現有，不變）
```

**優勢**：
- 不改動現有流程結構，向後相容
- 外部獨立審查保持泛用 QA 職責，pr-review-toolkit 補充專業維度
- Plugin 未安裝時直接跳過整個步驟 5.4，流程不受影響

**劣勢**：
- 審查步驟增加，總執行時間增長
- 兩層審查可能有重疊（如 code-reviewer 與 QA 的 Code Quality）

### 選項 B：替換層 — 用 pr-review-toolkit 取代外部獨立審查

移除現有 §8.5 外部獨立審查，完全由 pr-review-toolkit 三個 agent 承擔。

**劣勢**：
- pr-review-toolkit 不做 Spec Compliance 驗證（AC 逐條驗證），會失去這個關鍵審查
- 外部 plugin 未安裝時，整個外部審查環節消失，品質無保障
- 強耦合外部依賴

### 選項 C：融合層 — 將 pr-review-toolkit agent 融入外部獨立審查內

在步驟 5.3 外部獨立審查中，除了現有 QA subagent，同時派遣 pr-review-toolkit agent，合併為一個審查步驟。

**劣勢**：
- 步驟 5.3 職責膨脹，從「獨立 QA 審查」變成「多工具聯合審查」
- Plugin 未安裝時需在步驟 5.3 內部處理降級邏輯，增加複雜度
- 審查結果合併判定邏輯複雜

---

## 決策

**選擇選項 A：補充層模式。**

理由：
- **關注點分離**：現有外部獨立審查負責 Spec Compliance + 泛用 Code Quality，pr-review-toolkit 負責專業品質維度，責任清晰
- **降級安全**：Plugin 未安裝時跳過步驟 5.4，步驟 5.3 的審查仍完整保留，品質底線不變
- **向後相容**：不改動任何現有步驟的定義，只新增一個步驟
- **複用降級模式**：降級行為可完全複用 §8.2 CI Gate 的降級模式（WARN + 跳過 + 繼續），無需發明新機制

---

## 詳細設計

### 1. 整合模式（AC1）

#### 步驟 5.4：pr-review-toolkit 補充審查

**嵌入位置**：步驟 5.3（外部獨立審查 CONFIRM）之後、步驟 5.5（CI/CD 雙審查 Gate）之前。

**派遣方式**：平行派遣三個 agent（已驗證可平行執行），透過 prompt 告知審查範圍：

```
Agent 1: pr-review-toolkit:code-reviewer
  → prompt: 審查本次變更的跨檔案一致性、命名規範、CLAUDE.md 合規
  → 輸入: git diff（unstaged 或指定 commit range）

Agent 2: pr-review-toolkit:silent-failure-hunter
  → prompt: 審查本次變更的降級路徑、fallback 行為、error handling
  → 輸入: git diff

Agent 3: pr-review-toolkit:comment-analyzer
  → prompt: 審查本次變更的文件準確性、comment 與程式碼一致性
  → 輸入: git diff
```

**輸出格式統一**：各 agent 回傳 Markdown 報告，由流程引擎統一解析嚴重度。

#### 嚴重度對照表

各 agent 使用不同嚴重度系統，統一對照至框架四級制：

| 框架等級 | code-reviewer | silent-failure-hunter | comment-analyzer |
|---------|---------------|----------------------|-----------------|
| **CRITICAL** | confidence 91-100 | CRITICAL | Critical Issues |
| **HIGH** | confidence 80-90 | HIGH | — |
| **MEDIUM** | — | MEDIUM | Improvement Opportunities |
| **LOW** | — | — | Recommended Removals |

#### 嚴重度 Gate 規則

| 嚴重度 | 行為 | 說明 |
|--------|------|------|
| **CRITICAL** | **阻擋** — 必須修復後重新審查 | 等同外部獨立審查 DISPUTE |
| **HIGH** | **阻擋** — 必須修復後重新審查 | 等同外部獨立審查 DISPUTE |
| **MEDIUM** | **記錄** — 寫入審查報告，不阻擋 | 記錄於 commit message 或審查 log |
| **LOW** | **記錄** — 寫入審查報告，不阻擋 | 僅供參考 |

**修復閉環**：CRITICAL/HIGH 阻擋時，修復後重新派遣對應 agent 進行第二輪審查。第二輪仍有 CRITICAL/HIGH → 升級至 Architect，終止。

### 2. 觸發規則 — doc-only 條件（AC1）

複用 shoot §8.2 CI Gate 已定義的 doc-only pattern（SSOT，不重複定義）：

| Pattern | 說明 |
|---------|------|
| `docs/**` | 文件目錄 |
| `**/*.md` | 所有層級的 Markdown 文件 |
| `skills/**/*.md` | Skill 定義文件 |
| `agents/**/*.md` | Agent 定義文件 |
| `templates/**/*.md` | 範本文件 |

**doc-only 時的觸發規則**：

| Agent | doc-only 變更 | 非 doc-only 變更 |
|-------|--------------|-----------------|
| `code-reviewer` | **跳過** — 無程式碼可審 | 執行 |
| `silent-failure-hunter` | **跳過** — 無 error handling 可審 | 執行 |
| `comment-analyzer` | **執行** — .md 文件的準確性仍需審查 | 執行 |

**doc-only 判定**：複用 §8.2 的判定邏輯，若本次修改的檔案全部符合 doc-only pattern，則為 doc-only 變更。

### 3. 降級行為（AC2）

#### 偵測條件

pr-review-toolkit 未安裝的偵測方式：派遣 agent 時若回傳「plugin not found」或等效錯誤，視為未安裝。

#### 降級行為定義

複用 §8.2 CI Gate 的降級模式（WARN + 跳過 + 繼續）：

| 情境 | 偵測條件 | 降級行為 |
|------|---------|---------|
| Plugin 未安裝 | Agent 派遣失敗（plugin not found） | 輸出 `[WARN]`，跳過步驟 5.4，繼續 |
| Plugin 部分 agent 不可用 | 個別 agent 派遣失敗 | 該 agent 輸出 `[WARN]`，其餘 agent 正常執行 |
| Plugin 已安裝但回應異常 | Agent 回傳非預期格式 | 該 agent 輸出 `[WARN]`，其餘 agent 正常執行 |

**設計原則**：pr-review-toolkit 是**增強層**，非**必要層**。未安裝不應阻擋流程，品質底線由步驟 5.3 的外部獨立審查保障。

#### 降級輸出格式

```
── pr-review-toolkit 補充審查 ────────
  [WARN] pr-review-toolkit 未安裝，跳過補充審查
  提示：安裝 pr-review-toolkit 可獲得跨檔案一致性、降級路徑、文件準確性的專業審查
  安裝方式：Claude Code → /plugins → 搜尋 "pr-review-toolkit" → Install
```

#### 安裝提醒機制

| 提醒時機 | 提醒方式 | 頻率 |
|---------|---------|------|
| 步驟 5.4 偵測到未安裝 | 降級 WARN 訊息中附帶安裝指引 | 每次觸發時 |
| Session 初始化（hooks） | 不主動提醒 | — |

**設計原則**：只在**實際需要使用時**提醒，不在 session 啟動時干擾使用者。提醒訊息包含安裝步驟，降低使用者操作成本。

### 4. 與 §8.5 外部獨立審查的責任邊界（AC3）

#### 責任矩陣

| 審查維度 | §8.5 外部獨立審查（QA subagent） | 步驟 5.4 pr-review-toolkit |
|---------|-------------------------------|---------------------------|
| **Spec Compliance — AC 逐條驗證** | 主責 | 不負責 |
| **Spec Compliance — 邊界條件** | 主責 | 不負責 |
| **Spec Compliance — 行為範例驗證** | 主責 | 不負責 |
| **Code Quality — 命名可讀性** | 基礎檢查 | code-reviewer 深度檢查 |
| **Code Quality — 結構設計** | 基礎檢查（函式 < 20 行） | code-reviewer 跨檔案一致性 |
| **Code Quality — 測試品質** | 基礎檢查 | 不負責（pr-test-analyzer 未納入本次整合） |
| **Code Quality — 安全性** | 基礎檢查 | 不負責 |
| **降級路徑 / fallback 行為** | 不覆蓋 | silent-failure-hunter 主責 |
| **Error handling 品質** | 不覆蓋 | silent-failure-hunter 主責 |
| **文件準確性 / comment rot** | 不覆蓋 | comment-analyzer 主責 |
| **跨檔案一致性** | 不覆蓋 | code-reviewer 主責 |
| **CLAUDE.md 合規** | 不覆蓋 | code-reviewer 主責 |

#### 互補關係說明

```
§8.5 外部獨立審查（QA subagent）
  ├── Spec Compliance（AC 驗收）     ← 唯一來源，pr-review-toolkit 不做
  └── Code Quality（泛用基礎）       ← 基礎品質底線

步驟 5.4 pr-review-toolkit 補充審查
  ├── code-reviewer                  ← 跨檔案一致性、命名深度、CLAUDE.md
  ├── silent-failure-hunter          ← 降級路徑、fallback、error handling
  └── comment-analyzer               ← 文件準確性、comment rot
```

**關鍵原則**：§8.5 保障**功能正確性**（AC 是否滿足），步驟 5.4 保障**工程品質深度**（程式碼是否健壯）。兩者互補，不重疊核心職責。

### 5. 流程圖更新

shoot 流程在步驟 5.3 與步驟 5.5 之間插入步驟 5.4：

```
[步驟 5.3] 外部獨立審查（100%，現有不變）
  |-- CONFIRM → 繼續
  +-- DISPUTE → 修復 → 二審（現有流程不變）
        |
        v
[步驟 5.4] pr-review-toolkit 補充審查（新增）
  |-- Plugin 未安裝 → [WARN] 跳過，繼續
  |-- Doc-only → 僅執行 comment-analyzer
  |-- 全部 PASS（無 CRITICAL/HIGH）→ 繼續
  +-- CRITICAL/HIGH 發現 → 修復 → 重新審查
        |-- 二審 PASS → 繼續
        +-- 二審仍 CRITICAL/HIGH → 升級 Architect，終止
        |
        v
[步驟 5.5] CI/CD 雙審查 Gate（現有不變）
```

### 6. sprint-execution 流程整合

同樣的步驟 5.4 適用於 sprint-execution 的 story-lifecycle。插入位置相同：外部獨立審查之後、commit 之前。

觸發規則、嚴重度 Gate、降級行為與 shoot 完全一致（SSOT — 定義一次，兩個流程共用）。

### 7. 輸出格式

#### 正常執行（全部 PASS）

```
── pr-review-toolkit 補充審查 ────────
  code-reviewer：      [PASS] 無 CRITICAL/HIGH issue
  silent-failure-hunter：[PASS] 無 CRITICAL/HIGH issue
  comment-analyzer：    [PASS] 無 Critical Issues
```

#### 有 MEDIUM/LOW（記錄，不阻擋）

```
── pr-review-toolkit 補充審查 ────────
  code-reviewer：      [PASS] 無 CRITICAL/HIGH issue
    - [MEDIUM] 建議：utils.js L42 命名可改善（confidence: 65）
  silent-failure-hunter：[PASS] 無 CRITICAL/HIGH issue
  comment-analyzer：    [PASS] 無 Critical Issues
    - [LOW] 建議移除：config.js L15 冗餘 comment
```

#### 有 CRITICAL/HIGH（阻擋）

```
── pr-review-toolkit 補充審查 ────────
  code-reviewer：      [FAIL] 發現 HIGH issue
    - [HIGH] handler.js L28: 跨檔案命名不一致（confidence: 85）
  silent-failure-hunter：[FAIL] 發現 CRITICAL issue
    - [CRITICAL] api.js L45: 空 catch block 靜默吞噬錯誤
  comment-analyzer：    [PASS] 無 Critical Issues

  修復中...

── pr-review-toolkit 補充審查（第二輪）──
  code-reviewer：      [PASS] 無 CRITICAL/HIGH issue
  silent-failure-hunter：[PASS] 無 CRITICAL/HIGH issue
```

#### doc-only 變更

```
── pr-review-toolkit 補充審查 ────────
  code-reviewer：      [SKIP] Doc-only 變更
  silent-failure-hunter：[SKIP] Doc-only 變更
  comment-analyzer：    [PASS] 無 Critical Issues
```

---

## Spike Report（AC4）

### 結論

1. **pr-review-toolkit 已驗證可用**：三個 agent 在 ADR-020 審查中實際運行，輸入輸出行為穩定，可平行派遣。
2. **補充層模式最適合**：不改動現有流程，Plugin 未安裝時自動降級，品質底線不受影響。
3. **降級模式可複用**：§8.2 CI Gate 的 WARN + 跳過模式直接適用，無需新機制。
4. **責任邊界清晰**：§8.5 負責 Spec Compliance，步驟 5.4 負責工程品質深度，無職責重疊。
5. **doc-only pattern 已有 SSOT**：§8.2 已定義，直接引用。

### 建議後續行動

| 優先序 | 行動 | 說明 |
|--------|------|------|
| 1 | 依本 ADR 重寫 #266 AC | 本 ADR Accepted 後，#266 AC 需基於此架構定義重新撰寫 |
| 2 | 修改 `skills/shoot/SKILL.md` | 新增步驟 5.4 定義 |
| 3 | 修改 `skills/sprint-execution/story-lifecycle-prompt.md` | 對應新增步驟 |
| 4 | 新增偵測 / 降級邏輯 | 實作 plugin 未安裝偵測與 WARN 輸出 |
| 5 | 新增嚴重度解析邏輯 | 實作三種 agent 報告的嚴重度統一對照 |

### 未納入本次整合的 agent

pr-review-toolkit 共有 6 個 agent，本次僅整合 3 個。未納入的 agent：

| Agent | 原因 |
|-------|------|
| `pr-test-analyzer` | 測試覆蓋已由 QA Post-check CQ-NEW 處理 |
| `type-design-analyzer` | Shikigami 為非 TypeScript 專案（Shell + YAML + Markdown），type design 不適用 |
| `code-simplifier` | 定位為「review 後 polish」，與 Gate 機制的阻擋/通過邏輯不符 |

未來可視需求逐步納入。

---

## 後果

### 正面

- **品質維度擴展**：新增降級路徑審查、文件準確性審查、跨檔案一致性審查三個專業維度
- **漸進式採用**：Plugin 未安裝時自動降級，不影響既有使用者
- **零改動現有流程**：只新增步驟 5.4，不修改步驟 5.3 和 5.5 的定義
- **複用既有模式**：降級行為、doc-only pattern 均複用已定義機制

### 負面

- **審查時間增加**：三個 agent 平行執行仍需等待最慢的 agent 完成
- **外部依賴**：依賴 Claude Code Plugin Marketplace 的 pr-review-toolkit 持續維護
- **嚴重度對照維護**：三種不同嚴重度系統的對照表需隨 plugin 版本更新

### 風險緩解

| 風險 | 緩解措施 |
|------|---------|
| Plugin 停止維護或 API 變更 | 降級行為確保流程不受影響；步驟 5.3 的品質底線始終保在 |
| Agent 回傳大量 false positive | 嚴重度 Gate 只阻擋 CRITICAL/HIGH，MEDIUM/LOW 僅記錄 |
| 審查時間過長 | 三個 agent 平行派遣；doc-only 時僅執行 comment-analyzer |
