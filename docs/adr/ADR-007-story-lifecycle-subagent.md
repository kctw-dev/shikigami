# ADR-007：Story 生命週期 Subagent 封裝

**狀態**：Accepted
**日期**：2026-03-02
**決策者**：Architect
**挑戰者**：QA Engineer
**關聯 Issue**：#45（Sprint Execution context overflow — Story 生命週期應封裝為單一 subagent）
**關聯 Story**：US-39（Sprint 22）

---

## 背景

Sprint Execution 執行多個 Story 時，主 session context 快速膨脹導致 overflow。

**根因**：目前架構中，Developer subagent 回傳代碼後，Spec Compliance Review、Code Quality Review、Security Review 的完整對話都累積在主 session。每個 Story 的 QA 修復循環（DEF/SEC 缺陷 → 修復 → 重審）進一步放大 context 消耗。

Sprint 4 實測數據：4 個核心 Story + 6 個缺陷修復循環 → context overflow，session 中斷後需手動續傳 + 狀態校正。

**現狀架構 context 消耗模型（每個 Story 的 context 貢獻）：**

```
主 session（累積所有對話）
  ├─ 派 Developer subagent → 回傳代碼
  ├─ 主 session 自己跑 Spec Review        ← 佔 context（AC 文字 + 代碼 + 對話）
  ├─ 主 session 自己跑 Quality Review     ← 佔 context（代碼 + 評審意見 + 對話）
  ├─ 主 session 自己跑 Security Review    ← 佔 context（代碼 + 安全分析 + 對話）
  ├─ 修復循環 × N 次                      ← 每次循環額外增加 K context 單位
  └─ 重複 × Story 數量 → 線性累積直至 overflow
```

**設計張力**：封裝後獲得 context 隔離收益，但代價是 Review 獨立性（由主 session 獨立 QA 降為 subagent 自審）、可觀測性（主 session 失去 QA 細節）、以及 subagent 自身的 context 限制（M/L Story 仍有 overflow 風險）。

---

## 決策問題

Sprint Execution 中每個 Story 的生命週期管理應採用哪種 context 隔離策略，在防止主 session overflow 的同時，最小化審查獨立性退化與可觀測性損失？

---

## 選項分析

### 選項 A：現有基準（current baseline）

維持現有架構不變。主 session 直接負責派遣 Developer subagent、執行 Spec Compliance Review、Code Quality Review、Security Review，修復循環全程在主 session 中進行。

```
主 session
  ├─ 讀取 Sprint Backlog
  ├─ 派 Developer subagent → 回傳實作摘要 + 修改檔案清單
  ├─ 主 session 執行 Spec Compliance Review（讀取 AC + 代碼）
  ├─ 主 session 執行 Code Quality Review（讀取代碼）
  ├─ 主 session 執行 Security Review（條件觸發）
  ├─ 修復循環（Developer fix → 重審，全程在主 session）
  └─ 更新 PROJECT_BOARD → 下一個 Story
```

**優點：**

- 審查獨立性最高：Spec/Quality/Security Review 由主 session 獨立執行，非 Developer 自審
- 可觀測性最高：主 session 持有完整對話歷史，除錯時直接回溯
- 架構複雜度最低：無需定義新介面或額外的 subagent 協作協定
- 零遷移成本：現有 SKILL.md 不需改動

**缺點：**

- Context overflow 問題未解決：M/L size Story + 多次修復循環 → 主 session context 線性累積
- Sprint 規模上限受限：超過 4 Story 的 Sprint 在 M/L size Story 混入時，overflow 風險高
- 修復成本不可預期：overflow 後需手動續傳 + 狀態校正，維運負擔高

**風險：**

- 已知 Sprint 4 實測：4 Story + 6 缺陷修復 → overflow，此問題隨 Sprint 規模擴大持續惡化
- 缺乏根本性改善路徑：在現有架構下，唯一的緩解手段是減少 Sprint Story 數量，但這與提升 Velocity 目標衝突

---

### 選項 B：完整 Story-Lifecycle Subagent（採用）

將每個 Story 的完整生命週期（Dev → Spec Review → Quality Review → Security Review → 修復循環）封裝為單一 Story-Lifecycle subagent。主 session 僅負責調度與接收最終摘要。

```
主 session（精簡調度）
  ├─ 讀取 Sprint Backlog（Story 清單）
  ├─ 派 Story-Lifecycle subagent（Story A）→ PASS/FAIL + 摘要 + commit SHA
  ├─ 派 Story-Lifecycle subagent（Story B）→ PASS/FAIL + 摘要 + commit SHA
  └─ 只累積摘要，不累積 QA 對話 → context 穩定

Story-Lifecycle subagent 內部：
  ├─ 讀取 Sprint AC（sprint_N.md）
  ├─ TDD 開發（Red → Green → Refactor）
  ├─ Spec Compliance self-review
  ├─ Code Quality self-review
  ├─ Security self-review（條件觸發）
  ├─ 修復循環（內部閉環，不溢出至主 session）
  ├─ DoD 自檢
  ├─ commit + push
  └─ 回傳：PASS/FAIL + 摘要 + 修改檔案清單 + commit SHA
```

**優點：**

- 主 session context 顯著減少：QA 來回對話不進入主 session，預估減少 70-80%
- Sprint 規模上限提升：Sprint 4 規模（4 Story + 6 缺陷修復循環）不再觸發 overflow
- 主 session 責任清晰：專注於調度（Story 排序、看板更新、Sprint Review 觸發）
- 每個 Story 獨立隔離：Story A 的 context 不污染 Story B 的執行

**缺點：**

- 審查獨立性退化：Review 由主 session 獨立 QA 降為 Story-Lifecycle subagent 自審，Reviewer 與 Developer 為同一 subagent
- subagent 自身 context 限制：M/L size Story 的 Dev + 多輪修復循環可能導致 subagent 本身 overflow
- 可觀測性降低：主 session 看不到 QA 細節，除錯時需要回溯 subagent 日誌

**風險：**

- 審查獨立性是品質保障的核心。自審（Reviewer = Developer）比獨立審查（Reviewer ≠ Developer）在認知偏差上有已知缺陷，需要補償機制（見 §AC3）
- M/L size Story 的 subagent context overflow 需要明確的回退策略（見 §AC4）

---

### 選項 C：部分封裝 — 修復循環隔離模式

僅將 Developer + 修復循環部分封裝，Spec Compliance Review 和 Code Quality Review 仍由主 session 獨立執行。修復完成後，結果回傳主 session 做最終審查。

```
主 session
  ├─ 讀取 Sprint Backlog
  ├─ 派 Dev-Fix subagent（Developer + 修復循環封裝）
  │     ├─ TDD 開發
  │     ├─ 若 Review 失敗：內部修復循環（不溢出）
  │     └─ 回傳：修改檔案清單 + commit SHA
  ├─ 主 session 執行 Spec Compliance Review（讀取 AC + 代碼）← 獨立審查保留
  ├─ 主 session 執行 Code Quality Review（讀取代碼）← 獨立審查保留
  ├─ 主 session 執行 Security Review（條件觸發）← 獨立審查保留
  └─ 更新 PROJECT_BOARD → 下一個 Story
```

**優點：**

- 審查獨立性完整保留：Review 仍由主 session 執行，不退化為自審
- context 部分改善：修復循環（主要 context 消耗源）從主 session 移出
- 可觀測性保留：主 session 持有完整 Review 結果

**缺點：**

- Context 改善幅度有限：主 session 仍累積所有 Review 對話，僅修復循環被隔離
- 介面複雜度增加：主 session 需要接收 Dev-Fix subagent 的修改清單，再自行讀取所有修改後的檔案執行 Review，每個 Story 仍有一次完整代碼讀取負擔
- 修復閉環的邊界模糊：Dev-Fix subagent 在修復時需要知道 Review 失敗的具體原因，意味著主 session 的 Review 結果必須傳入 subagent，形成雙向通信

**風險：**

- Context 節省量的估算存在不確定性：Review 對話本身即佔有相當 context，若 Review 對話量與修復循環相當，則實際節省可能不如預期
- Dev-Fix subagent 的「已知 Review 失敗，但修復時 Review 標準不在眼前」的場景，容易導致修復不充分，增加 Review 通過率下降的風險

---

### 選項 D：分段委派模式 — 批次審查

累積多個 Story 的開發結果後，以批次模式執行 Review。Developer subagent 依序完成各 Story 開發，所有 Story 開發完成後，統一派遣 QA subagent 批次審查。

```
主 session
  ├─ Story A：派 Developer subagent → 回傳實作
  ├─ Story B：派 Developer subagent → 回傳實作
  ├─ Story C：派 Developer subagent → 回傳實作
  └─ 統一批次 QA Review（Spec + Quality + Security）
```

**優點：**

- QA subagent 可在同一 context 中審查所有 Story，發現跨 Story 依賴問題
- 主 session context 在開發階段維持精簡（僅累積 Developer 回傳摘要）

**缺點：**

- 批次審查的缺陷修復問題嚴重：Story A 有缺陷時，Story B、C 可能已基於 Story A 的問題代碼繼續開發，缺陷被放大
- 失去 Story 級別的即時品質回饋：問題在 Sprint 末期才被發現，修復成本最高
- 與現有 SKILL.md §3 流程根本衝突：目前規定每個 Story 完成後立即審查（HARD-GATE），批次模式違反此原則

**風險：**

- 批次模式下缺陷修復的 cascade 效應：一個 Story 的根本缺陷可能導致整批 Story 需要重做，總修復成本高於逐個審查
- 跨 Story 批次審查的 QA subagent context 也有 overflow 風險，且比單 Story 更難緩解

---

## 決策

**採用選項 B（完整 Story-Lifecycle Subagent）。**

核心判準為：

1. **Context overflow 是已知硬限制，必須從架構層面解決**：Sprint 4 實測已證明，現狀（選項 A）在中等規模 Sprint 下就會觸發 overflow。選項 C 的部分封裝雖保留 Review 獨立性，但 context 改善幅度不足以解決根本問題；選項 D 的批次模式反而引入更嚴重的品質風險。
2. **審查獨立性退化有補償機制**：選項 B 的最大代價是 Review 變為自審。此退化可透過外部抽樣審查機制（見 §AC3）部分補償——在 Story-Lifecycle subagent 回傳後，主 session 依抽樣規則決定是否觸發額外的獨立 QA subagent 抽檢，形成「自審為主、抽檢為輔」的品質保障層。
3. **YAGNI 原則**：選項 C 的雙向通信複雜度和選項 D 的批次協調成本，均超出 MVP 階段的合理實作複雜度。

**排除方案說明：**

- 選項 A（現有基準）：Context overflow 根因未解決，不可持續
- 選項 C（部分封裝）：Review 獨立性保留，但 context 改善不足；雙向通信複雜度高
- 選項 D（批次審查）：破壞 Story 級別即時品質回饋，缺陷 cascade 風險高，且與 SKILL.md HARD-GATE 衝突

---

## AC2：介面契約定義

Story-Lifecycle subagent 的最小介面契約，定義主 session 與 subagent 之間的通信邊界。

### (a) 輸入格式

主 session 在派遣 Story-Lifecycle subagent 時，**必須**提供以下輸入：

```yaml
# Story-Lifecycle Subagent 輸入契約
story_id: "US-XX"                          # 必填：Story 識別碼（如 US-39）
sprint_file: "docs/sprints/sprint_N.md"    # 必填：包含 AC 的 Sprint 文件路徑
project_board: "docs/PROJECT_BOARD.md"     # 必填：看板路徑（供狀態更新）
related_adrs:                              # 可選：相關 ADR 路徑清單
  - "docs/adr/ADR-XXX.md"
related_sdds:                              # 可選：相關設計文件路徑清單
  - "docs/sdd/SDD-XXX.md"
doc_only: false                            # 必填：是否為 doc-only Story（影響 TDD 豁免）
size: "M"                                  # 必填：Story Size（S/M/L），影響 fallback 策略觸發閾值
bypass: false                              # 必填：是否為 [BYPASS] Story（影響 Review 豁免）
```

**約束：**

- 主 session **不得**預讀 sprint_N.md 的 AC 內容，路徑由 subagent 自行讀取（維持主 session context 精簡）
- 主 session **不得**預讀 related_adrs 和 related_sdds，路徑清單作為參考傳入
- Story-Lifecycle subagent 接收輸入後，負責讀取所有必要文件

### (b) 輸出格式

Story-Lifecycle subagent **必須**以以下格式回傳最終結果：

```
## Story-Lifecycle 完成摘要

**Story ID**：US-XX
**結論**：PASS / FAIL
**一句話摘要**：{≤50 字的結果說明，如「所有 7 項 AC 通過，3 次 Spec Review 後全部通過，無安全疑慮」}

**修改檔案清單**：
- `path/to/file1.md` — {變更描述}
- `path/to/file2.sh` — {變更描述}

**Commit SHA**：{最後一個 commit 的完整 SHA，如 `a1b2c3d4e5f6...`}

**DoD 狀態**：全部通過 / 有例外（{說明}）

**Review 摘要**：
- Spec Compliance：PASS / FAIL（{一句話說明}）
- Code Quality：PASS / FAIL（{一句話說明}）
- Security：PASS / SKIP（{一句話說明或「未觸發安全審查條件」}）
```

**約束：**

- `結論` 欄位僅允許 `PASS` 或 `FAIL` 兩個值，不允許模糊表述
- `Commit SHA` 在 PASS 時必填；在 FAIL 時若已有部分 commit 則填入最後 commit，否則填 `N/A`
- `修改檔案清單` 必須列出所有被修改的檔案，不得使用「其他」或省略

### (c) 錯誤與升級輸出（Escalation Output）

以下情況 Story-Lifecycle subagent **必須**回傳升級訊號，由主 session 決定後續處置：

```
## Story-Lifecycle 升級通知

**Story ID**：US-XX
**結論**：ESCALATE
**升級原因**：{以下類型之一}
**升級詳情**：{具體說明}

升級類型：
  - DESIGN_ISSUE：同一審查階段連續失敗 3 次，可能存在架構/設計問題
  - CONTEXT_OVERFLOW：subagent context 接近上限（見 §AC4 fallback 策略）
  - REQUIREMENT_AMBIGUITY：AC 描述模糊或存在矛盾，無法判斷完成標準
  - DEPENDENCY_MISSING：依賴的文件、資源或前置條件不存在
  - SECURITY_CRITICAL：發現 Critical 安全問題，需 Security Engineer 人工介入
```

**升級決策規則（主 session 職責）：**

| 升級類型 | 主 session 預設處置 |
|----------|---------------------|
| DESIGN_ISSUE | 暫停 Sprint 執行，升級至 Architect 評估 |
| CONTEXT_OVERFLOW | 觸發 §AC4 定義的 fallback 策略 |
| REQUIREMENT_AMBIGUITY | 暫停 Sprint 執行，升級至 PO 釐清 AC |
| DEPENDENCY_MISSING | 暫停 Sprint 執行，解決依賴後重試 |
| SECURITY_CRITICAL | 暫停 Sprint 執行，觸發 security-review Skill |

---

## AC3：審查獨立性補償機制

### 問題陳述

選項 B（完整 Story-Lifecycle Subagent）的核心代價是 Review 獨立性退化：Review 由主 session 獨立 QA 執行（Reviewer ≠ Developer）退化為 Story-Lifecycle subagent 自審（Reviewer = Developer）。

認知偏差研究表明，同一執行體的自審容易忽略自身引入的系統性錯誤，Review 有效性低於獨立審查。此退化需要結構性補償機制，而非依賴執行體自律。

### 補償機制：抽樣獨立審查

**機制名稱**：Story-Lifecycle 外部抽樣審查（External Sampling Review）

**定義位置**：本 ADR §AC3，以及 `skills/sprint-execution/SKILL.md` §3 的「審查獨立性補償」子章節（ADR-007 實作時新增）

**可量測元素：**

#### 1. 抽樣百分比（Sampling Percentage）

- **基礎抽樣率**：每 Sprint 中 Story 數量的 **30%**（取上整，如 4 Story Sprint 中至少 2 個 Story 接受外部抽樣審查）
- **提升條件**：以下任一條件觸發抽樣率提升至 **100%**（本 Sprint 所有 Story 均接受外部審查）

#### 2. 觸發條件（Trigger Conditions）

以下條件觸發**強制全量外部審查**（抽樣率 100%）：

| 觸發條件 | 說明 |
|----------|------|
| TC-1：Sprint 有 L-size Story | 含 L-size Story 的 Sprint，所有 Story 必須接受外部抽樣審查 |
| TC-2：Story 涉及安全相關 AC | 含安全相關 Acceptance Criteria 的 Story（[動態]類型涉及外部輸入、認證、授權），強制外部抽樣 |
| TC-3：前次 Sprint Review 發現自審品質問題 | Sprint Review 或 Retrospective 中記錄了自審遺漏的缺陷，下一個 Sprint 全量觸發，直至連續 2 Sprint 無此類問題後恢復基礎抽樣率 |
| TC-4：Story 連續 2 次 self-review FAIL | Story-Lifecycle subagent 自審 FAIL 達 2 次，自動升級為外部抽樣 |

**基礎抽樣（30%）的 Story 選取規則：**

- 優先選取：Size 最大的 Story（M 優先於 S）
- 次優先：本 Sprint 中修改檔案數量最多的 Story（依 subagent 回傳的修改檔案清單計算）
- 隨機保底：若所有 Story 規模和修改量相近，隨機選取達到 30% 門檻

#### 3. 外部抽樣審查執行方式

被選中接受外部抽樣的 Story，主 session 在 Story-Lifecycle subagent 回傳 PASS 後，**額外**派遣一個獨立 QA subagent 執行：

```
外部抽樣審查 subagent（使用 spec-reviewer-prompt.md 或 quality-reviewer-prompt.md）：
  輸入：
    - Story-Lifecycle subagent 回傳的修改檔案清單
    - sprint_N.md 路徑（AC 來源）
    - Story ID
  執行：
    - 獨立讀取修改後的代碼/文件
    - 獨立讀取 AC
    - 驗證 subagent 自審結論是否正確
  回傳：
    - CONFIRM（自審結論正確）
    - DISPUTE + 具體差異說明（自審結論有問題）
```

**DISPUTE 處理：**

若外部抽樣審查回傳 DISPUTE，主 session 記錄為 Sprint Retrospective Problem，並：
1. 將相關 Story 狀態回退至「待修復」
2. 將缺陷清單傳入 Story-Lifecycle subagent 要求修復
3. 修復完成後，被 DISPUTE 的 Story 強制接受第二輪外部抽樣審查

**品質指標追蹤：**

每個 Sprint Review 結束時，記錄以下指標至 `docs/km/Metrics_Log.md`：

| 指標 | 說明 |
|------|------|
| 自審通過率 | Story-Lifecycle self-review PASS 數 / 總 Story 數 |
| 外部抽樣執行率 | 實際外部抽樣 Story 數 / 應抽樣 Story 數（驗證 30% 門檻） |
| DISPUTE 率 | 外部抽樣中 DISPUTE 數 / 外部抽樣執行數（監控自審品質趨勢） |

**機制回退（Circuit Breaker）：**

若連續 3 個 Sprint 的 DISPUTE 率超過 20%（即抽樣中超過 1/5 的自審結論有誤），框架自動觸發 Review 架構重評估，Architect 必須在下一個 Sprint Planning 前決定是否回退至部分封裝（選項 C）或引入其他補償機制。

---

## AC4：Context Overflow 回退策略（Fallback Strategy）

### 問題陳述

選項 B 的 Story-Lifecycle subagent 雖然保護了主 session context，但 subagent 本身有自己的 context 限制。對於 M/L size Story，Dev 開發 + 多輪修復循環的對話可能使 subagent context 接近上限，觸發 overflow。

此問題在 L-size Story 風險最高：L-size Story 通常涉及多個 AC、多個修改檔案、更複雜的修復循環。

### 回退策略

#### 策略 1：M-size Story 分段提交模式

**觸發條件**：Story Size = M，且 subagent 在執行中偵測到 context 使用量超過估算閾值的 **70%**。

**執行方式：**

Story-Lifecycle subagent 將 M-size Story 的 AC 分為 **2 批次**執行：

```
批次 1（前半 AC）：
  ├─ 開發前半 AC（TDD）
  ├─ 自我審查前半 AC
  ├─ commit（標記為「batch-1」）
  └─ 回傳 PARTIAL_PASS + 批次 1 完成摘要

主 session 接收 PARTIAL_PASS：
  ├─ 記錄批次 1 結果
  └─ 派新 Story-Lifecycle subagent 繼續批次 2（傳入批次 1 commit SHA）

批次 2（後半 AC + 全量 Review）：
  ├─ 開發後半 AC（TDD）
  ├─ 自我審查所有 AC（全量驗證）
  ├─ commit（標記為「batch-2」）
  └─ 回傳 PASS/FAIL + 完整摘要
```

**Context 預算管理：**

Story-Lifecycle subagent 在啟動時，根據 Story Size 和 AC 數量估算 context 預算：

| Story Size | AC 數量 | 建議批次數 |
|------------|---------|------------|
| S | 1-5 | 1（單批次完成） |
| M | 3-8 | 1-2（超過 70% 閾值時分批） |
| L | 5+ | 2-3（預設分批，見策略 2） |

#### 策略 2：L-size Story 強制預分批模式

**觸發條件**：Story Size = L，**無條件觸發**，不等待 context 使用量超過閾值。

**執行方式：**

L-size Story 在主 session 派遣前，先由主 session 將 AC 清單分為 **至少 2 個驗收批次**（此規則與 SKILL.md §6「L-size Story 審查增強」中的「分階段驗收」要求一致）：

```
批次分組規則（由主 session 在派遣前執行）：
  - 核心路徑 AC → 批次 1
  - 邊界條件 + 錯誤處理 AC → 批次 2
  - 若 AC 數量 > 6，考慮批次 3

每批次：
  派 Story-Lifecycle subagent（batch_index, total_batches, previous_commit_sha）
    → 執行當批次 AC 的 TDD + 自審
    → 回傳 PARTIAL_PASS（非最終批次）或 PASS/FAIL（最終批次）

主 session 職責：
  - 維護批次狀態（哪些批次已 PASS，哪些待執行）
  - 若某批次 FAIL，停止後續批次，等待修復後重試該批次
  - 所有批次 PASS 後，觸發整體外部抽樣審查（見 §AC3）
```

**主 session context 控制（保護主 session 不因批次協調而 overflow）：**

主 session 在批次協調中**僅保留**：
- 當前批次的 commit SHA
- 當前批次的 PASS/FAIL 狀態
- 待執行批次的 AC 清單索引

主 session **不保留**：
- 各批次的詳細 Review 對話
- 修改後的代碼內容（由 subagent 直接讀取）

#### 策略 3：Subagent Overflow 緊急回退

**觸發條件**：Story-Lifecycle subagent 在執行中途因 context overflow 強制中斷（回傳 `ESCALATE: CONTEXT_OVERFLOW`），且分批策略已無法繼續（例如單一 AC 的實作本身已超出 subagent context 限制）。

**執行方式：**

```
緊急回退流程：
  1. 主 session 接收 CONTEXT_OVERFLOW 升級訊號
  2. 主 session 記錄中斷點（已完成的 AC、最後一個有效 commit SHA）
  3. 主 session 升級至 Architect，提供：
     - Story ID
     - 已完成 AC 清單
     - 未完成 AC 清單
     - 最後有效 commit SHA
  4. Architect 評估選項：
     (a) 拆分 Story：將未完成 AC 拆出為新 Story（排入下一個 Sprint）
     (b) 切換至部分封裝模式（選項 C）：僅此 Story 採用主 session 直接執行
     (c) 手動執行：Architect 指導人工完成剩餘 AC

  5. 已完成批次的 commit 保留，不 rollback
  6. Sprint Review 記錄此事件至 Retrospective Problem
```

**永久無法自動化的情況：**

若某 Story 的單一 AC 涉及檔案數量或代碼量超出任何單一 subagent context 可負荷的範圍，此 Story 應在 Sprint Planning 時被識別為「超大 Story」，強制拆分後才能進入 Sprint Backlog。Story-Lifecycle 框架**不保障**此類 Story 的自動化執行。

#### Fallback 決策矩陣

| Story Size | Context 狀態 | 觸發策略 | 主 session 行為 |
|------------|-------------|----------|----------------|
| S | 正常 | 無（單批次完成） | 等待 PASS/FAIL |
| M | 正常 | 無（單批次完成） | 等待 PASS/FAIL |
| M | >70% 閾值 | 策略 1（分段提交） | 接收 PARTIAL_PASS，派新 subagent 繼續 |
| L | 任何狀態 | 策略 2（強制預分批） | 維護批次狀態，逐批派遣 subagent |
| 任何 | Overflow 中斷 | 策略 3（緊急回退） | 記錄中斷點，升級 Architect |

---

## 影響

### 對 skills/sprint-execution/SKILL.md 的影響

本 ADR 定義架構方向。實作時（Sprint 22 範圍**不含實作**，後續 Sprint 負責），`skills/sprint-execution/SKILL.md` 需更新：

1. §3 執行流程：將「派 Developer subagent → 主 session 執行 Review」替換為「派 Story-Lifecycle subagent → 接收摘要」
2. 新增 §X：Story-Lifecycle subagent 介面契約（引用本 ADR §AC2）
3. 新增 §Y：審查獨立性補償機制（引用本 ADR §AC3）
4. 新增 §Z：Context overflow 回退策略（引用本 ADR §AC4）

### 對 developer-prompt.md 的影響

`skills/sprint-execution/developer-prompt.md` 需演進為 `story-lifecycle-prompt.md`，包含：
- 當前 developer-prompt.md 的所有內容
- 新增 Spec Compliance self-review 章節
- 新增 Code Quality self-review 章節
- 新增 Security self-review 章節（含觸發條件）
- 新增本 ADR §AC2 定義的輸出格式

### 對 Sprint 執行節奏的影響

| 場景 | 現狀（選項 A） | 採用選項 B 後 |
|------|--------------|--------------|
| S-size Story，無缺陷 | 主 session 直接執行，累積 context | subagent 執行，主 session 僅收摘要 |
| M-size Story，2 次修復 | 主 session context 大量累積 | subagent 內部閉環，主 session context 穩定 |
| L-size Story | 極高 overflow 風險 | 強制預分批，風險可控 |
| 4-Story Sprint，含 1 個 L | Sprint 4 實測：overflow | 預期 context 穩定 |

### 實作優先級

本 ADR 批准後，後續 Sprint 實作優先序：

1. **P1**：`story-lifecycle-prompt.md` 基礎版本（整合 Developer + self-review）
2. **P2**：L-size Story 分批協調邏輯
3. **P3**：外部抽樣審查觸發邏輯
4. **P4**：Context 使用量估算（M-size 70% 閾值觸發）

---

## Decision Challenge（QA Engineer）

**挑戰**：選項 B 的審查獨立性退化被低估。Spec Compliance Review 和 Code Quality Review 由獨立 QA subagent 執行的核心價值，不僅僅是「Reviewer ≠ Developer」的認知獨立性，更重要的是 Reviewer 的 context 新鮮度——獨立 QA subagent 在全新的 context 中讀取 AC 和代碼，比已經執行了整個開發過程的 Story-Lifecycle subagent 更容易注意到開發過程中積累的「認知慣性」（如：因頻繁修改某個函式而對其品質問題視而不見）。

選項 B 的 §AC3 外部抽樣機制（30% 基礎抽樣率）能部分補償此問題，但若被觸發強制全量審查的條件（TC-1 到 TC-4）在某個 Sprint 都未被滿足，那 70% 的 Story 將僅依賴自審——而這 70% 正是 Review 品質最難被察覺退化的場景。

**反駁**：此挑戰正確識別了選項 B 的結構性弱點，但三點補充可緩解此風險：

第一，基礎 30% 抽樣的設計是保守下限而非理想值。實際執行中，TC-1（L-size Story）在中等複雜度 Sprint 中頻繁出現；TC-2（安全相關 AC）在涉及外部輸入的 Story 中必然觸發。從 Sprint 22 的實際 Story 組合（4 Stories 中含 1 個 L-size）來看，TC-1 必然觸發全量外部審查，30% 基礎抽樣反而是 S/M Sprint 的降級場景。

第二，「認知慣性」的問題在 self-review 的提示設計中可以結構性緩解：Story-Lifecycle subagent 在進入 self-review 階段時，可以明確被指示「以全新視角重新閱讀 AC，不使用開發過程中建立的任何假設」。提示工程可以在一定程度上模擬 context 重置效果。

第三，Circuit Breaker 機制（DISPUTE 率超過 20% 時強制架構重評估）提供了系統性退化的安全閥。若 self-review 品質確實成問題，DISPUTE 率會在 2-3 Sprint 內提升，觸發回退至選項 C 或引入其他補償。這使選項 B 的部署是可撤回的，不是一個不可逆決策。

**結論**：同意 ADR-007 的決策方向（選項 B），同時建議在 story-lifecycle-prompt.md 的 self-review 章節中明確包含「重設認知基準」的提示指令，以結構性緩解認知慣性問題。此建議納入後續 Sprint 的實作要求。

---

## Stakeholder Review 修訂記錄

（本 ADR 為首次發布，無修訂記錄。後續修訂依實作驗證結果在此追加。）
