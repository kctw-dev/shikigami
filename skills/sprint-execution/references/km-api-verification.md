# §7.6 KM 第三方 API 文件驗證（條件觸發，doc_only 不豁免）

<!-- SSOT：story-lifecycle-prompt.md §7.6 已移至此處（Sprint 127 #485 模組化拆分） -->
<!-- US-274 KM 第三方 API 文件驗證機制 — Sprint 100, #276 -->

在 pr-review-toolkit 補充審查（§7.5）之後、DoD 自檢（§8）之前，對本次 Story 涉及的 KM 文件執行第三方 API 來源驗證。

## 觸發條件

**以下任一關鍵字出現在 Story AC 或修改的 KM 文件內容中，即觸發本驗證**（避免 false positive）：

- API、SDK、endpoint、webhook、OAuth、第三方

**不觸發情境（以下情況跳過，輸出 `[KM-API-SKIP]`）**：

- 純內部模組修改（無第三方 API 互動）
- doc-only Story 但 AC 確認無第三方 API 內容
- RESEARCH Story（探索性調查，不涉及 API 實作）

## 驗證規則

對本次修改或新增的 `docs/km/` 路徑下文件執行以下兩項驗證：

### 規則 1：強制來源標注（AC-1）

KM 文件中凡出現以下內容，必須附有來源標注：
- API 的 enum 值（如 status、type、event 等欄位的可能取值）
- API 參數的值域範圍（最小值、最大值、允許格式）
- API 回傳格式或結構（response schema、欄位類型）

**合規的來源標注形式（以下任一即符合）**：
- 官方文件 URL（如 `https://api.example.com/docs`）
- 版本號標注（如 `v2.3 官方文件`）
- 實測日期（如 `實測於 YYYY-MM-DD`）

**違反時輸出**：
```
[KM-WARN] {檔案路徑}: enum "{參數名}" 缺少來源標注
```

### 規則 2：Enum 完整性宣告（AC-2）

KM 文件中的 enum 列舉必須標注以下任一完整性宣告：
- `（完整列舉）` — 表示已列出所有可能值，來源已驗證
- `（部分列舉，截至 YYYY-MM-DD）` — 表示僅列出已知部分，存在未列出的值

**禁止**：在無來源佐證下，未加任何完整性宣告即列出 enum 值（視為腦補行為）。

**違反時輸出**：
```
[KM-WARN] {檔案路徑}: enum "{參數名}" 缺少完整性宣告（需標注「完整列舉」或「部分列舉，截至 YYYY-MM-DD」）
```

## 非第三方 API KM 文件豁免

本驗證**不影響**以下類型的 KM 文件寫入：
- 架構決策記錄（ADR）
- Sprint Retrospective Log
- 技術債 Registry
- 內部系統設計文件（無第三方 API enum 或參數）

## 執行流程

```
觸發條件檢查
  |-- 不觸發 → 輸出 [KM-API-SKIP]，直接繼續
  +-- 觸發
        |
        v
掃描本次修改的 docs/km/ 文件
  |
  v
對每個含第三方 API 資訊的段落執行規則 1 + 規則 2 檢查
  |
  |-- 無違反 → [KM-API-PASS]，繼續
  +-- 有違反 → 輸出 [KM-WARN] 清單
                 → 在本 subagent 內部補充來源標注（若可確認來源）
                 → 若無法確認來源，保留 WARN 並在回傳摘要中標記 [KM-SOURCE-UNKNOWN]
                 → 不阻塞流程（WARN 不等同 FAIL），但 WARN 必須在摘要中可見
```

## 輸出格式

```
KM 第三方 API 驗證 — {story_id}

觸發狀態：觸發 / [KM-API-SKIP]（原因：{觸發條件未滿足}）

掃描文件：
- {docs/km/xxxx.md} — {掃描結果：PASS / 含 WARN}

WARN 清單（若有）：
- [KM-WARN] {檔案}: enum "{參數名}" 缺少來源標注
- [KM-WARN] {檔案}: enum "{參數名}" 缺少完整性宣告

整體結論：[KM-API-PASS] / [KM-API-WARN]（含 {N} 個待補充項）
```
