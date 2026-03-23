# shoot pr-review-toolkit 補充審查

本文件定義 `/shoot` 的 pr-review-toolkit 整合規則，由 `skills/shoot/SKILL.md` 按需載入。

設計 SSOT：`docs/adr/ADR-021-pr-review-toolkit-integration.md`

---

## pr-review-toolkit 補充審查（步驟 5.4）

<!-- Story #266 — 整合 pr-review-toolkit 審查 agents 至 commit 前 Gate -->

在外部獨立審查（步驟 5.3）CONFIRM 後、CI/CD 雙審查 Gate（步驟 5.5）前，追加 pr-review-toolkit 三個專業審查 agent 作為**工程品質深度補充層**。

**與步驟 5.3 的責任邊界**：步驟 5.3 負責 **Spec Compliance**（AC 逐條驗證、邊界條件），步驟 5.4 負責**工程品質深度**（跨檔案一致性、降級路徑、文件準確性）。兩者互補，不重疊核心職責。詳見 ADR-021 §4 責任矩陣。

### 三 agent 平行派遣

透過 Claude Code `Agent` tool 平行派遣三個 subagent：

```
Agent 1: subagent_type: "pr-review-toolkit:code-reviewer"
  → 審查跨檔案一致性、命名規範、CLAUDE.md 合規
  → 輸入: git diff

Agent 2: subagent_type: "pr-review-toolkit:silent-failure-hunter"
  → 審查降級路徑、fallback 行為、error handling
  → 輸入: git diff

Agent 3: subagent_type: "pr-review-toolkit:comment-analyzer"
  → 審查文件準確性、comment 與程式碼一致性
  → 輸入: git diff
```

### 嚴重度 Gate 規則

各 agent 使用不同嚴重度系統，統一對照至框架四級制（完整對照表見 ADR-021 §1 嚴重度對照表）：

| 嚴重度 | 行為 | 說明 |
|--------|------|------|
| **CRITICAL** | **阻擋** — 必須修復後重新審查 | Hard Gate |
| **HIGH** | **阻擋** — 必須修復後重新審查 | Hard Gate |
| **MEDIUM** | **記錄** — 寫入審查報告，不阻擋 | Soft Gate |
| **LOW** | **記錄** — 寫入審查報告，不阻擋 | 僅供參考 |

### 修復閉環

CRITICAL/HIGH 阻擋時：
1. 修復問題
2. 重新派遣**所有**第一輪回報 CRITICAL/HIGH 的 agent 進行第二輪審查（非僅修復對象的單一 agent）
3. 第二輪仍有任一 agent 回報 CRITICAL/HIGH → **升級至 Architect，終止**

### doc-only 條件觸發

複用 CI Gate 已定義的 doc-only pattern（SSOT，不重複定義）：

| Agent | doc-only 變更 | 非 doc-only 變更 |
|-------|--------------|-----------------|
| `code-reviewer` | **跳過** — 無程式碼可審 | 執行 |
| `silent-failure-hunter` | **跳過** — 無 error handling 可審 | 執行 |
| `comment-analyzer` | **執行** — .md 文件準確性仍需審查 | 執行 |

**doc-only 判定**：複用 CI Gate 的判定邏輯與 pattern 清單。

### 降級行為

複用 CI Gate 的降級模式（WARN + 跳過 + 繼續）：

| 情境 | 降級行為 |
|------|---------|
| Plugin 未安裝 | 輸出 `[WARN]`，跳過步驟 5.4，繼續 |
| 部分 agent 不可用 | 該 agent 輸出 `[WARN]`，其餘 agent 正常執行 |
| Agent 回應異常 | 該 agent 輸出 `[WARN]`，其餘 agent 正常執行 |
| Agent 回應正常但嚴重度解析失敗（無法提取任何嚴重度項目） | 視為回應異常，該 agent 輸出 `[WARN]`，不視為 `[PASS]` |

**設計原則**：pr-review-toolkit 是**增強層**，非**必要層**。未安裝不阻擋流程，品質底線由步驟 5.3 的外部獨立審查保障。

### 輸出格式

五種情境範例（基於 ADR-021 §7 輸出格式，新增 doc-only CRITICAL 情境）：

**正常 PASS**：
```
── pr-review-toolkit 補充審查 ────────
  code-reviewer：      [PASS] 無 CRITICAL/HIGH issue
  silent-failure-hunter：[PASS] 無 CRITICAL/HIGH issue
  comment-analyzer：    [PASS] 無 Critical Issues
```

**有 CRITICAL/HIGH（阻擋）**：
```
── pr-review-toolkit 補充審查 ────────
  code-reviewer：      [FAIL] 發現 HIGH issue
    - [HIGH] handler.js L28: 跨檔案命名不一致（confidence: 85）
  silent-failure-hunter：[PASS] 無 CRITICAL/HIGH issue
  comment-analyzer：    [PASS] 無 Critical Issues

  修復中...

── pr-review-toolkit 補充審查（第二輪）──
  code-reviewer：      [PASS] 無 CRITICAL/HIGH issue
```

**doc-only 變更**：
```
── pr-review-toolkit 補充審查 ────────
  code-reviewer：      [SKIP] Doc-only 變更
  silent-failure-hunter：[SKIP] Doc-only 變更
  comment-analyzer：    [PASS] 無 Critical Issues
```

**doc-only + comment-analyzer CRITICAL（阻擋）**：
```
── pr-review-toolkit 補充審查 ────────
  code-reviewer：      [SKIP] Doc-only 變更
  silent-failure-hunter：[SKIP] Doc-only 變更
  comment-analyzer：    [FAIL] 發現 Critical Issues
    - [CRITICAL] docs/adr/ADR-021.md L45: 文件描述與實際行為不符

  修復中...

── pr-review-toolkit 補充審查（第二輪）──
  comment-analyzer：    [PASS] 無 Critical Issues
```

**降級（未安裝）**：
```
── pr-review-toolkit 補充審查 ────────
  [WARN] pr-review-toolkit 未安裝，跳過補充審查
  提示：安裝 pr-review-toolkit 可獲得跨檔案一致性、降級路徑、文件準確性的專業審查
  安裝方式：Claude Code → /plugins → 搜尋 "pr-review-toolkit" → Install
```

<HARD-GATE>
**pr-review-toolkit 補充審查 Hard Gate（/shoot）**：步驟 5.4 派遣 pr-review-toolkit 三 agent 平行審查。CRITICAL/HIGH 嚴重度阻擋 commit，修復後二審仍 CRITICAL/HIGH → 升級 Architect，exit code 非 0，禁止 commit。Plugin 未安裝時採降級行為（WARN + 跳過 + 繼續）。
</HARD-GATE>
