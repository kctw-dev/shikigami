## §1.2 AC 驗證策略

### 靜態 AC vs 動態 AC 識別規則

AC 類型決定驗收方式與測試策略，QA 在 Sprint Planning 中必須明確識別每個 AC 的類型。

#### 靜態 AC `[靜態]`

**識別標準（滿足所有以下條件）：**

- 驗收方式為「人工閱讀文件/代碼，確認內容存在且符合規範」
- 無需執行 shell 命令、啟動服務或觸發 API
- 可透過靜態分析（grep、read file）完成驗證
- 目標產物為文件（.md、.yaml、.json 設定檔）或 Skill 定義文件

**典型範例：**
- 「`skills/sprint-execution/SKILL.md` §3 新增外部抽樣審查節點」→ `[靜態]`（讀取文件確認段落存在）
- 「YAML frontmatter 包含 name 和 description 欄位」→ `[靜態]`（靜態讀取驗證）
- 「函式 X 包含錯誤處理邏輯」→ `[靜態]`（代碼審查可確認）

#### 動態 AC `[動態]`

**識別標準（滿足任一以下條件即判定為動態）：**

- 驗收需要執行 shell 命令並觀察輸出（如 `bash tests/run-all.sh`）
- 需要啟動程式或服務，觀察執行時行為
- 驗收涉及外部輸入的處理結果（輸入 → 預期輸出的驗證）
- 需要觸發特定條件（如「連續失敗 2 次後觸發 X」）並觀察系統反應

**典型範例：**
- 「執行 `bash tests/run-all.sh` 返回 0」→ `[動態]`（需執行測試）
- 「輸入無效 token 時，API 返回 401」→ `[動態]`（需執行請求）
- 「排程模式下選入 M-size Story 時，Planning 中止並輸出告警字串」→ `[動態]`（需執行並觀察輸出）

#### 行為 AC `[行為]`

**識別標準（滿足所有以下條件）：**

- AC 通過標準涉及多條執行路徑（分支邏輯：「當 X 時 Y，否則 Z」）
- AC 描述的是使用者可觀察的行為（CLI 輸出、告警訊息、狀態轉換等）
- 適合以 Given-When-Then 格式明確描述各路徑

**來源**：由 Architect Round 2 的方法論適用性評估（BDD 建議 B1-B4）標記，QA Round 3 確認後要求 PO 補充行為範例。

**典型範例：**
- 「排程模式下選入 M-size Story 時，Planning 中止並輸出告警字串」→ `[行為]`（多條件分支 + 使用者面向輸出）
- 「Story 狀態從 In Progress 轉為 Done 時，Done 定義 checkbox 全部勾選」→ `[行為]`（狀態轉換邏輯）
- 「輸入無效 token 時返回 401，輸入過期 token 時返回 403」→ `[行為]`（多條件路徑）

**行為範例格式（Specification by Example）：**

若 AC 被標記為 `[行為]` 類型，PO 須在 AC 表格下方補充行為範例：

```markdown
**行為範例（Specification by Example）**

> AC2 範例：
> - **Given** {前置條件}
>   **When** {觸發動作}
>   **Then** {預期結果}
>
> - **Given** {另一前置條件}
>   **When** {相同或不同觸發動作}
>   **Then** {不同預期結果}
```

**行為範例驗證指引（QA 在外部抽樣審查與 Story-Lifecycle 自審中使用）：**

| 驗證項目 | 判定標準 |
|---------|---------|
| 範例完整性 | 每個 `[行為]` AC 至少有 2 個 Given-When-Then 場景（涵蓋主流程與至少一個替代路徑） |
| 場景覆蓋 | 所有 Given-When-Then 場景均有對應的實作行為（靜態核對或測試驗證） |
| 行為一致性 | 實作行為與 Given-When-Then 描述完全一致，無偏離 |
| 遺漏路徑 | 無 AC 描述中隱含但未被 Given-When-Then 覆蓋的執行路徑 |

**FAIL 判定**：任一 `[行為]` AC 的行為範例場景未被實作覆蓋 → Spec Compliance FAIL，問題分類為 `[BEHAVIOR-MISMATCH]`。

#### 混合型 Story 的判斷規則

若 Story 包含靜態與動態 AC：
- **TDD 豁免判斷**：只要有任一 `[動態]` AC，Story 整體不適用 doc-only 路徑（TDD 豁免不觸發）
- **測試覆蓋要求**：所有 `[動態]` AC 必須有對應的自動化測試，`[靜態]` AC 僅需文件審查

### AC 完整性補全觸發條件

以下情況 QA 必須要求 PO 補全 AC（回退至 PO 修正）：

| 觸發條件 | 說明 | 處置 |
|---------|------|------|
| 通過標準不可判斷 | AC 描述僅說「應實作 X」，未定義成功條件 | 退回 PO，要求補充「通過標準：{可觀察的結果}」 |
| 路徑不存在 | AC 引用的檔案路徑不存在（Glob/ls 驗證失敗） | 標記 `Path verification: FAIL`，Story 標為 `NEEDS_REVISION` |
| 邊界條件缺失 | 功能性 AC 無錯誤路徑驗收（只有 happy path） | 建議補充「當 X 無效時，應返回 Y」的 AC 或納入 Spec Review 要求 |
| AC 間矛盾 | 兩個 AC 的預期行為相互衝突 | 退回 PO + Architect 釐清，無法在 QA 層解決 |
| 安全相關 AC 缺失 | Story 涉及外部輸入、認證、授權，但 AC 無對應的安全驗收 | 標記為 Security Review 必觸發，建議補充安全 AC |

### 測試覆蓋判斷

QA 在 Sprint Planning 時確認，Story 完成時在 Story-Lifecycle subagent 的外部抽樣審查中驗證：

**最低測試覆蓋要求：**

| AC 類型 | 最低覆蓋要求 |
|---------|------------|
| `[靜態]` AC | 靜態核對（文件審查），無需自動化測試 |
| `[動態]` AC — Happy Path | 至少 1 個自動化測試覆蓋主流程 |
| `[動態]` AC — Error Path | 至少 1 個自動化測試覆蓋每個錯誤條件 |
| L-size Story 所有 AC | 額外要求：完整回歸測試掃描，測試數量明確記錄 |

**測試覆蓋不足的判斷：**
- 存在 `[動態]` AC 但對應測試不存在 → Code Quality self-review 必須 FAIL
- 測試存在但僅覆蓋 Happy Path，Edge Case AC 有對應的 `[動態]` 標記 → Spec Compliance 必須 FAIL
