## §3 Code Quality Review 策略

### 靜態分析標準

Code Quality Review 的審查範圍與深度根據 Story 類型調整。

#### 通用靜態分析標準（所有 Story 適用）

**命名與可讀性：**
- 函式/變數名稱能清楚表達意圖（自文件化命名）
- 無單字母變數（除非在明確的 loop 範圍內如 `i`、`j`）
- 中英文命名一致性（不在同一作用域混用）

**結構與設計：**
- 函式長度原則 < 20 行（超過需說明理由或重構）
- 無明顯重複邏輯（DRY 原則）
- 無硬編碼常數（使用具名常數或設定檔）

**測試品質：**
- 測試名稱清楚描述情境（`test_X_when_Y_should_Z` 格式）
- Arrange-Act-Assert 模式清晰可辨
- 測試之間無順序依賴（每個測試獨立可執行）

**安全性基礎：**
- 無硬編碼 secrets（API Key、密碼、token）
- 外部輸入有驗證或結構化隔離（參照 ADR-006）

### CQ-MOCK：Mock 假設真實性檢查（AC3）

<!-- US-250 AC3: QA Code Review 包含「mock 假設是否反映真實世界」檢查項 — Sprint 93 -->

TDD 中 mock 的目的是隔離外部依賴，但過度或不精確的 mock 會導致「測試通過，真實世界失敗」的隱患。QA 在 Code Review 時須執行以下 mock 假設真實性檢查：

| 檢查項目 | 判定標準 | FAIL 條件 |
|---------|---------|----------|
| **CQ-MOCK-1 回應格式一致性** | Mock 回傳的資料格式（欄位名稱、型別、巢狀結構）與真實外部系統文件或已知行為一致 | Mock 回應格式與真實 API/系統行為明顯不符 → FAIL |
| **CQ-MOCK-2 資料範圍合理性** | Mock 使用的測試資料值符合真實世界的資料範圍與分佈（如日期範圍、數值上下限） | Mock 使用不合理的測試資料（如 `publishedAt: "2099-01-01"` 模擬「新聞」） → FAIL |
| **CQ-MOCK-3 錯誤情境覆蓋** | Mock 策略包含真實世界可能發生的錯誤情境（如 timeout、rate limit、空回應） | Mock 僅涵蓋成功路徑，無任何錯誤情境模擬 → 標記 Warning |
| **CQ-MOCK-4 Mock 範圍最小化** | Mock 僅隔離真正無法控制的外部依賴，未 mock 可直接測試的內部邏輯 | 過度 mock（如 mock 自己的純函式）導致測試語意喪失 → 標記 Warning |

**CQ-MOCK FAIL 嚴重度：**

| 情況 | 嚴重度 |
|------|-------|
| Mock 回應格式與真實系統明顯不符（CQ-MOCK-1 FAIL） | Major |
| Mock 資料範圍不合理導致功能性假設錯誤（CQ-MOCK-2 FAIL） | Major |
| 無錯誤情境 Mock 但 Story 涉及外部資源（CQ-MOCK-3 Warning） | Important |
| 過度 mock 導致測試語意喪失（CQ-MOCK-4 Warning） | Minor |

**觸發條件**：Story 中存在任何使用 mock/stub 的測試代碼時，CQ-MOCK 檢查自動觸發。

> **US-252 掛載點**：資料品質 Gate 的靜態資料覆蓋率驗證（US-252）在 CQ-MOCK-2 之後執行，作為「Mock 資料範圍合理性」的延伸檢查。US-252 的資料品質檢查清單應嵌入此處作為附加項目。

### CQ-DATA：靜態資料覆蓋率驗證（US-252）

<!-- US-252 資料品質 Gate：補充靜態資料覆蓋率驗證機制 — Sprint 93 -->

靜態資料檔（如字符資料表、常用詞庫、代碼對照表）的覆蓋率不足，會導致功能在 Demo 時表面正常但在真實使用場景中大量失敗。此問題的根源是測試恰好選取的樣本都在資料集內，而非資料集本身足夠完整。

> **背景（US-252）**：占卜筆劃功能 `stroke-data.ts` 資料集僅約 500 字即通過 Sprint Review Demo，因為測試時恰好所有查詢字符均在資料集內。缺乏覆蓋率驗證機制，導致不完整資料集被部署到 Production。

#### 資料品質覆蓋率指標定義（AC1）

以下為框架預定義的靜態資料覆蓋率標準。Story 涉及靜態資料檔時，對應的覆蓋率指標必須在 AC 中明確定義：

| 資料類型 | 覆蓋率指標 | 最低門檻 | 說明 |
|---------|----------|---------|------|
| **CJK 常用字資料集** | 收錄字符數 | >= 3000 字 | 覆蓋教育部甲表常用字（含繁體中文日常用字） |
| **CJK 擴展字符（冷門字）** | 收錄 CJK Extension A/B 字符數 | >= 500 字 | 支援生僻字查詢場景 |
| **筆劃資料集** | 覆蓋 Unicode CJK 基本區塊字符數 | >= 20902 字（CJK 統一漢字基本區塊全量） | Unicode U+4E00–U+9FFF 完整覆蓋 |
| **國字常用字詞表** | 收錄詞條數 | >= 50000 詞 | 教育部國語辭典詞條基準 |
| **姓名用字資料集** | 收錄可用字數 | >= 5000 字 | 戶政常用姓名用字覆蓋 |
| **代碼對照表（如 ISO 標準）** | 對照表條目完整性 | 100%（與標準文件一致） | 不得有遺漏的標準碼 |
| **自定義資料集** | 業務場景覆蓋率 | 由 PO 在 AC 中明確定義 | Story AC 中必須有可量化的覆蓋率目標 |

**Blast Radius 分析**：覆蓋率不足的靜態資料檔影響範圍（Blast Radius）計算方式：

| 評估維度 | 說明 |
|---------|------|
| **受影響使用者比例** | 使用資料集外字符 / 詞條的使用者百分比（估算） |
| **失敗模式** | 查詢缺字 → 回傳空值 / 錯誤訊息 / 系統崩潰（三種嚴重度遞增） |
| **可見度** | 覆蓋率不足是否在 Demo 測試集中被發現（若測試集為熱門字，Blast Radius 被低估） |
| **修復成本** | 資料補齊後是否需要重新 Deploy / 資料遷移（修復成本高則嚴重度升一級） |

#### 資料品質審查步驟（AC2 — Sprint Review 時執行）

QA 在 Sprint Review Demo 結束後，對涉及靜態資料檔的 Story 執行以下審查：

1. **識別靜態資料檔**：確認 Story 交付物中是否包含靜態資料檔（`.ts`、`.json`、`.csv`、`.yaml` 等格式的資料表）
2. **比對覆蓋率指標**：依上表找出對應的資料類型，確認 AC 中是否定義了覆蓋率目標
3. **量化核實**：使用工具（`wc -l`、`jq length`、`grep -c`）統計資料集的實際條目數，與覆蓋率目標對比
4. **Blast Radius 評估**：若覆蓋率不足，評估受影響使用者比例與失敗模式嚴重度
5. **記錄結果**：將覆蓋率核實結果記錄於 Sprint Review 報告的「資料品質驗證結果」段落

**資料品質審查觸發條件**：

滿足以下任一條件即觸發資料品質審查：

- Story 涉及靜態資料檔的新增或修改
- Story 的功能依賴預定義資料集（如字典查詢、代碼對照、標準資料表）
- Story AC 中含有覆蓋率相關的驗收標準

#### CQ-DATA 檢查清單（AC3 — Code Review 時執行）

QA 在 Code Review（外部抽樣審查）對涉及靜態資料檔的 Story 執行以下額外檢查：

| 檢查項目 | 判定標準 | FAIL 條件 |
|---------|---------|----------|
| **CQ-DATA-1 覆蓋率指標定義** | Story AC 中明確定義了資料集的覆蓋率目標（可量化數字） | AC 中無覆蓋率目標，或目標描述模糊（如「足夠多的字」）→ FAIL |
| **CQ-DATA-2 實際覆蓋率達標** | 資料集實際條目數 >= AC 中定義的覆蓋率目標 | 實際條目數 < 目標 → Hard Gate FAIL（阻止 Story 標記為完成） |
| **CQ-DATA-3 Blast Radius 評估** | Story 說明文件或 AC 包含覆蓋率不足時的 Blast Radius 說明 | 覆蓋率不足且無 Blast Radius 評估 → 標記 Warning |
| **CQ-DATA-4 測試集代表性** | 自動化測試的測試資料集涵蓋資料邊界（含稀少字符、邊界值），不僅測試熱門資料 | 測試資料集僅包含熱門 / 常見值，無冷門或邊界值測試 → 標記 Important |

**CQ-DATA FAIL 嚴重度：**

| 情況 | 嚴重度 | 判定 |
|------|-------|------|
| Story 涉及靜態資料檔但 AC 無覆蓋率定義（CQ-DATA-1 FAIL） | Major | Code Quality Review FAIL |
| 資料集實際覆蓋率未達 AC 目標（CQ-DATA-2 FAIL） | Critical | **Hard Gate：強制 FAIL，禁止 Story 標記為完成** |
| 無 Blast Radius 評估（CQ-DATA-3 Warning） | Important | 記錄為 Issue，累計計入 Important 問題數 |
| 測試集缺乏代表性（CQ-DATA-4 Important） | Important | 記錄為 Issue，累計計入 Important 問題數 |

> **Hard Gate 說明**：CQ-DATA-2 FAIL 觸發時，即使其他所有 Code Quality 項目均通過，Story 整體判定為 FAIL，不得標記為「完成」，必須補齊資料集後重新執行驗收流程。

**觸發條件**：Story 交付物中含靜態資料檔（`.ts`、`.json`、`.csv`、`.yaml` 等格式的資料表），且資料集大小超過 100 條目時，CQ-DATA 檢查自動觸發。

---

### doc-only Story 的 Review 豁免規則

**doc-only Story 的 Code Quality Review 範圍縮減：**

適用條件（必須同時滿足）：
- Story 的 `doc_only` 標記為 `true`
- 所有修改檔案路徑均在 `docs/` 目錄下（不含 `skills/`、`commands/`、`agents/`）
- 所有 AC 均為 `[靜態]` 類型

**豁免項目（doc-only Story 不適用）：**

| 審查項目 | 一般 Story | doc-only Story |
|---------|----------|---------------|
| 函式長度檢查 | 適用 | 豁免（無函式實作） |
| 測試品質審查 | 適用 | 豁免（無測試代碼） |
| 硬編碼常數檢查 | 適用 | 豁免 |
| 無 dead code | 適用 | 豁免 |

**doc-only Story 仍適用的審查項目（不得豁免）：**

| 審查項目 | 說明 |
|---------|------|
| 無硬編碼 secrets | 即使是文件，不得包含真實 API Key 或密碼 |
| Markdown 結構完整性 | 標題層次合理，無破損連結語法 |
| YAML frontmatter 格式 | 若文件包含 frontmatter，格式必須符合 YAML 規範 |
| 文件內部一致性 | 文件內的交叉引用、路徑引用、版本號一致 |

**重要邊界**：`skills/` 目錄下的 `.md` 文件（包含 SKILL.md）**不適用** doc-only 豁免規則（參照 sprint-execution/SKILL.md §5 Hard Gates —「負面案例排除清單」子項目），即使副檔名為 `.md` 也需執行完整 ADR-003 Checklist。

### L-size Story 加強審查項目

**觸發條件**：Story Size = L（自動啟用，無需額外判斷）

**加強審查項目（在標準審查基礎上額外執行）：**

1. **模組邊界完整性審查**：
   - 確認新增的函式/模組有明確的單一職責（SOLID S 原則）
   - 確認模組之間的依賴方向符合設計文件（SDD 或 ADR）的定義
   - 若存在循環依賴，必須標記為 FAIL

2. **向後相容性檢查**：
   - L-size Story 通常涉及多個檔案，確認對現有介面的修改不破壞已知的呼叫方
   - 對修改 `skills/*/SKILL.md` 的 L-size Story：確認新增章節不與現有章節矛盾
   - 對修改 prompt 文件的 L-size Story：確認新增指令不與現有指令衝突

3. **回歸測試覆蓋確認**：
   - 確認 Story-Lifecycle subagent 的 commit message 中包含「全部 N 項測試通過，無回歸」字樣
   - 若 commit message 缺少此記錄，標記為 Code Quality FAIL（需補充完整回歸掃描記錄）

4. **分階段驗收一致性**：
   - L-size Story 分批次執行時，確認各批次的 AC 驗收邊界清晰不重疊
   - 確認批次間的 commit 有明確的 `batch-1`、`batch-2` 標記（參照 ADR-007 §AC4 策略 2）

5. **外部抽樣強制觸發確認**：
   - L-size Story 必須觸發全量外部抽樣（TC-1 條件，參照 story-lifecycle-prompt.md §AC3）
   - 若主 session 未執行外部抽樣，Sprint Review 時標記為流程異常

**L-size Story 加強審查 FAIL 優先條件：**

| 缺陷類型 | 判定 |
|---------|------|
| 循環依賴 | FAIL |
| commit message 缺少回歸測試記錄 | FAIL |
| 批次 commit 標記缺失 | FAIL（若 Story 採用分批執行模式） |
| 向後相容性破壞（有已知呼叫方受影響） | FAIL |
