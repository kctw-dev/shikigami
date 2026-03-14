# CLI 輸出設計原則符合性評估報告

**Story**：US-109（Issue #116）
**評估日期**：2026-03-06
**評估範圍**：三層 UIUX Agent 管線各技能 CLI 輸出格式
**評估基準**：ADR-014（三層管線 CLI 輸出規格）、Shikigami CLI 設計原則
**後置 Story**：US-129（UX Agent 符合性審查）、US-130（UI Agent 符合性審查）、US-131（Vision Critic 符合性審查）

---

## 1. 評估目的與範圍

本報告對三層 UIUX Agent 管線的 CLI 輸出格式進行系統性評估，識別各技能在 CLI 輸出標準化方面的現有缺口，並提供具體改善建議，以指引 US-129/130/131 的執行順序與重點。

**評估技能清單**：

| 技能 | 指令 | SKILL.md 路徑 |
|------|------|---------------|
| UX Agent | `shikigami:uiux-designer` / `/ux-agent` | `skills/ux-agent/SKILL.md` |
| UI Agent | `shikigami:uiux-designer` / `/ui-agent` | `skills/ui-agent/SKILL.md` |
| Vision Critic Agent | `shikigami:vision-critic` / `/vision-critic` | `skills/vision-critic/SKILL.md` |

---

## 2. CLI 輸出設計原則定義

依據 Shikigami 框架既有技能（如 `skills/sprint-execution/SKILL.md`、`skills/issue-management/SKILL.md`）的 CLI 輸出慣例，以及 ADR-014 對三層管線輸出格式的要求，定義以下基準原則：

### 原則一：結構化狀態訊息前綴（P-01）

CLI 輸出應使用統一的狀態前綴標記，讓使用者快速識別訊息類型：

| 前綴 | 語意 | 適用場景 |
|------|------|---------|
| `[OK]` | 步驟成功完成 | 正常執行進度 |
| `[WARN]` | 可繼續但有潛在問題 | 非致命性異常 |
| `[ERROR]` | 執行失敗，需要中止或人工介入 | 致命性錯誤 |
| `[INFO]` | 一般資訊性輸出 | 執行摘要、路徑提示 |

**技能特定前綴（已在 SKILL.md 中定義，需對齊一致格式）**：

| 技能 | 現有前綴 | 原則建議 |
|------|---------|---------|
| UX Agent | `[UX-WARN]`、`[UX-ERROR]` | 統一為 `[UX-OK]`、`[UX-WARN]`、`[UX-ERROR]`、`[UX-INFO]` |
| UI Agent | `[UI-WARN]`、`[UI-ERROR]` | 統一為 `[UI-OK]`、`[UI-WARN]`、`[UI-ERROR]`、`[UI-INFO]` |
| Vision Critic | `[VC-ERROR]` | 統一為 `[VC-OK]`、`[VC-WARN]`、`[VC-ERROR]`、`[VC-INFO]` |

### 原則二：執行進度可見性（P-02）

長時間執行的操作（如 LLM 呼叫、Playwright 截圖）需在 stdout 輸出進度指示，避免使用者誤以為程式卡頓：

```
[INFO] 正在分析 User Story（LLM 呼叫中...）
[INFO] 正在驗證 SSD JSON Schema 符合性...
[OK]   SSD JSON 輸出完成（1,247 tokens）
```

### 原則三：結構化輸出與人類可讀輸出分離（P-03）

- **機器消費的 JSON 輸出**：輸出至 stdout（純 JSON，無額外文字）
- **人類可讀的進度/狀態訊息**：輸出至 stderr
- **管線模式**（`--ssd-stdin` 等）下：所有非 JSON 輸出必須導向 stderr，確保 stdout 為純 JSON

### 原則四：錯誤訊息可操作性（P-04）

錯誤訊息必須包含：
1. 錯誤類型（前綴標記）
2. 具體錯誤描述（發生了什麼）
3. 影響說明（哪個欄位/元件受影響）
4. 修正建議或後續行動（使用者應該怎麼做）

**符合原則範例**：
```
[UI-ERROR] SSD 輸入驗證失敗：$schema 欄位不符合
  影響：無法解析骨架文件
  期望：https://shikigami.dev/schemas/ssd/v1
  實際：https://shikigami.dev/schemas/ssd/v0
  建議：請確認 UX Agent 版本為 v1.0.0 並重新產生骨架文件
```

**不符合原則範例（現有 SKILL.md 描述方式）**：
```
輸出 [UI-ERROR] 並中止
```
（僅說明行為，無具體輸出格式範本）

### 原則五：退出碼標準化（P-05）

CLI 工具應遵循 POSIX 退出碼慣例：

| 情境 | 退出碼 |
|------|--------|
| 執行成功（PASS） | `0` |
| 執行警告（WARN，但完成） | `0`（或 `2`，需統一） |
| 執行失敗（ERROR） | `1` |
| 使用者輸入錯誤（參數錯誤） | `2` |

### 原則六：輸出後設資料一致性（P-06）

每次執行完成後，應提供標準化的執行摘要，讓管線下游或使用者快速取得關鍵資訊：

```
[VC-INFO] 執行摘要
  Story ID：US-XXX
  評分：色彩 92 / 位置 88 / 間距 85 → 總分 89.15
  判定：PASS
  執行時間：12.3 秒
  退件報告：未儲存（PASS 不觸發）
```

---

## 3. 各技能 CLI 輸出符合性評估

### 3.1 UX Agent（`shikigami:uiux-designer`）

#### 現有 CLI 輸出定義分析

依據 `skills/ux-agent/SKILL.md` 審查：

**已定義的輸出行為**：

| 節次 | 輸出行為 | SKILL.md 引用 |
|------|---------|---------------|
| §3.3 | `[UX-WARN]` — User Story 格式不符合 As/Want/So 三要素 | §3.3 輸入驗證規則 |
| §3.3 | `[UX-ERROR]` — 輸入來源互斥錯誤 | §3.3 輸入驗證規則 |
| §3.3 | `[UX-ERROR]` — User Story 文字為空 | §3.3 輸入驗證規則 |
| §7 | `[UX-ERROR]` — Schema 符合性失敗 | §7 輸出驗證 |
| §7 | `[UX-ERROR]` — sections 為空 | §7 輸出驗證 |
| §7 | `[UX-WARN]` — ID 非唯一性 | §7 輸出驗證 |
| §7 | `[UX-WARN]` — designToken 路徑格式無效 | §7 輸出驗證 |
| §7 | `[UX-ERROR]` — 禁止硬編碼 | §7 輸出驗證 |
| §10（ADR-014 OQ-5） | `[UX-WARN] input truncated` — 輸入截斷降級 | OQ-5 Context Budget |

#### 不符合項目清單（UX Agent）

| # | 不符合原則 | 不符合描述 | 影響等級 | 改善建議 |
|---|-----------|----------|---------|---------|
| UX-NC-01 | P-01（狀態訊息前綴） | 缺少 `[UX-OK]` 和 `[UX-INFO]` 前綴定義。SKILL.md 僅定義 WARN/ERROR，成功路徑沒有標準化輸出格式，使用者無法確認執行是否完成 | 高 | 在 §7 新增成功路徑輸出規範：`[UX-OK] SSD JSON 產生完成（storyId: US-XXX，sections: N）` |
| UX-NC-02 | P-02（執行進度可見性） | SKILL.md §4 執行流程未定義各步驟的進度訊息輸出。LLM 分析階段（步驟 4）是最長的等待點，完全無進度回饋 | 高 | 在 §4 各執行步驟新增 `[UX-INFO]` 輸出定義，如：`[UX-INFO] 正在分析 User Story 語意架構...` |
| UX-NC-03 | P-03（stdout/stderr 分離） | SKILL.md 未說明哪些輸出走 stdout、哪些走 stderr。SSD JSON 主輸出與狀態訊息的輸出流未明確分離，管線模式（`/ux-agent \| /ui-agent --ssd-stdin`）下可能導致 JSON 解析失敗 | 高 | 新增 §3.4 輸出流分離規範：JSON 輸出至 stdout，所有狀態/錯誤訊息至 stderr |
| UX-NC-04 | P-04（錯誤訊息可操作性） | §3.3 和 §7 的錯誤描述為行為說明（「輸出 [UX-ERROR] 並中止」），未定義具體的訊息格式，包含錯誤描述、影響欄位、修正建議 | 中 | 為每個 `[UX-ERROR]` 和 `[UX-WARN]` 案例定義具體的訊息範本，含影響說明與修正建議 |
| UX-NC-05 | P-05（退出碼標準化） | SKILL.md 完全未提及 CLI 退出碼定義。`[UX-ERROR]` 應返回退出碼 1，成功返回 0，但未明確規範 | 中 | 在 §4 或新節次中定義退出碼對照表 |
| UX-NC-06 | P-06（執行摘要） | SKILL.md §7 有輸出驗證但無標準化執行摘要格式。成功執行後，使用者不知道產生了多少 sections、components 等關鍵指標 | 低 | 在 §7 新增成功執行摘要輸出規範，含 sections 數、components 數、輸出大小等 |

**UX Agent 符合性評分**：4/10（嚴重缺少進度輸出、stdout/stderr 分離與成功路徑標準化）

---

### 3.2 UI Agent（`shikigami:uiux-designer`）

#### 現有 CLI 輸出定義分析

依據 `skills/ui-agent/SKILL.md` 審查：

**已定義的輸出行為**：

| 節次 | 輸出行為 | SKILL.md 引用 |
|------|---------|---------------|
| §3.1 | `[UI-ERROR]` — SSD $schema 驗證失敗 | §3.1 輸入驗證規則 |
| §3.1 | `[UI-ERROR]` — metadata 必要欄位缺失 | §3.1 輸入驗證規則 |
| §3.1 | `[UI-ERROR]` — sections 陣列不合規 | §3.1 輸入驗證規則 |
| §3.1 | `[UI-WARN]` — componentType 非法，以 container 替代 | §3.1 輸入驗證規則 |
| §3.1 | `[UI-WARN]` — designTokens 路徑格式錯誤 | §3.1 輸入驗證規則 |
| §3.1 | `[UI-ERROR]` — 輸入 JSON 格式無效 | §3.1 輸入驗證規則 |
| §5.2 | `[UI-WARN]` — 顏色 Token 無對應 Tailwind class | §5.2 說明 |
| §8 | `[UI-ERROR]` — 白名單符合性失敗 | §8 輸出驗證 |
| §8 | `[UI-ERROR]` — Hardcode 設計數值 | §8 輸出驗證 |
| §8 | `[UI-WARN]` — section 未覆蓋 | §8 輸出驗證 |
| §8 | `[UI-ERROR]` — required form-field 缺失 | §8 輸出驗證 |
| §8 | `[UI-WARN]` — 無障礙合規問題（自動修正） | §8 輸出驗證 |
| §9.2 | `[UI-ERROR]` — 3 次退件後中止 | §9.2 重試策略 |

#### 不符合項目清單（UI Agent）

| # | 不符合原則 | 不符合描述 | 影響等級 | 改善建議 |
|---|-----------|----------|---------|---------|
| UI-NC-01 | P-01（狀態訊息前綴） | 缺少 `[UI-OK]` 和 `[UI-INFO]` 前綴定義。雖然定義了 WARN/ERROR，但成功路徑無標準化輸出，使用者不知道代碼生成完成 | 高 | 在 §8 新增成功路徑輸出：`[UI-OK] 前端代碼產生完成（sections: N，components: N）` |
| UI-NC-02 | P-02（執行進度可見性） | §4 執行流程 8 個步驟均無進度訊息定義。特別是步驟 6（LLM 代碼生成）和步驟 7（輸出驗證）是最長等待點 | 高 | 為 §4 各步驟新增 `[UI-INFO]` 輸出定義，特別是 LLM 呼叫前後 |
| UI-NC-03 | P-03（stdout/stderr 分離） | 與 UX Agent 相同缺口：SKILL.md 未說明前端代碼輸出（stdout）與狀態訊息（stderr）的分離策略。管線串接（`--ssd-stdin`）模式下尤為關鍵 | 高 | 新增 §3.4 或在 §7 說明輸出流分離規範 |
| UI-NC-04 | P-04（錯誤訊息可操作性） | 各 `[UI-ERROR]` 和 `[UI-WARN]` 案例缺少具體訊息範本。特別是 §8 白名單違規錯誤，使用者不知道具體哪一行/哪個元件違規 | 中 | 為每個錯誤案例定義包含：違規元件 ID、違規類型、修正方式的具體訊息格式 |
| UI-NC-05 | P-05（退出碼標準化） | 完全未提及 CLI 退出碼。特別是 `retryCount == 3` 的升級人工審查情境應返回特殊退出碼（建議 `3`）以供 CI 管線識別 | 中 | 定義退出碼對照表，特別是重試耗盡（退出碼 3）與一般錯誤（退出碼 1）的差異 |
| UI-NC-06 | P-06（執行摘要） | §8 輸出驗證後無標準化執行摘要。使用者和 CI 管線無法從 CLI 輸出快速確認代碼生成的關鍵指標（總行數、元件數、Token 類別數） | 低 | 在 §8 末尾新增執行摘要輸出規範 |
| UI-NC-07 | P-04（退件重試進度） | §9 退件重試流程無進度輸出。`retryCount` 進行中時，使用者不知道目前是第幾次重試，以及每次重試針對哪些問題修正 | 中 | 在 §9 新增重試進度輸出規範：`[UI-INFO] 重試 2/3：針對 login-submit 按鈕色彩問題修正中...` |

**UI Agent 符合性評分**：4/10（與 UX Agent 有相同的核心缺口，另有退件重試進度缺失）

---

### 3.3 Vision Critic Agent（`shikigami:vision-critic`）

#### 現有 CLI 輸出定義分析

依據 `skills/vision-critic/SKILL.md` 審查：

**已定義的輸出行為**：

| 節次 | 輸出行為 | SKILL.md 引用 |
|------|---------|---------------|
| §3.3 | `[VC-ERROR]` — 截圖格式/解析度不符 | §3.3 輸入驗證規則 |
| §3.3 | `[VC-ERROR]` — 骨架文件格式不符合 SSD Schema v1 | §3.3 輸入驗證規則 |
| §3.3 | `[VC-ERROR]` — SSD sections 為空 | §3.3 輸入驗證規則 |
| §3.3 | `[VC-ERROR]` — 輸入來源互斥衝突 | §3.3 輸入驗證規則 |
| §10.5 | `[VC-INFO]` — 退件報告儲存路徑（stdout） | §10.5 執行流程 |
| §6.4 | 升級人工審查（UI Agent 連續相同錯誤） | §6.4 重試終止條件 |

**Vision Critic 的 VRR JSON 輸出**（§8）是最完整的輸出定義，已包含：
- `verdict`（PASS / CONDITIONAL_PASS / FAIL）
- 三維度評分（colorConsistencyScore、componentPositionScore、spacingComplianceScore）
- `totalScore`（加權總分）
- `hardGateViolations`（Hard Gate 違規清單）
- `improvementSuggestions`（改善建議）

#### 不符合項目清單（Vision Critic）

| # | 不符合原則 | 不符合描述 | 影響等級 | 改善建議 |
|---|-----------|----------|---------|---------|
| VC-NC-01 | P-01（狀態訊息前綴） | 缺少 `[VC-OK]`、`[VC-WARN]`、`[VC-INFO]` 完整前綴集合定義。雖然 §10.5 有 `[VC-INFO]` 退件報告儲存訊息，但成功（PASS）路徑和條件通過（CONDITIONAL_PASS）路徑的前綴均未定義 | 中 | 在 §7 執行流程步驟 10 後新增標準化 PASS/CONDITIONAL_PASS 輸出格式，含 `[VC-OK]` 前綴 |
| VC-NC-02 | P-02（執行進度可見性） | §7 執行流程 10 個步驟（加上 §10.5 兩個額外步驟）均無進度訊息定義。特別是步驟 2（Playwright 截圖觸發）和步驟 6（Claude Sonnet 4.6 多模態 LLM 呼叫）是最長等待點，完全無任何進度回饋 | 高 | 為 §7 步驟 2、6 新增進度訊息：`[VC-INFO] 正在啟動 Playwright 截圖（viewport: 1280x720）...` |
| VC-NC-03 | P-03（stdout/stderr 分離） | SKILL.md §7 說明「輸出結構化審查報告（§8 JSON Schema）至 stdout」，但 §10.5 同時說明退件報告儲存路徑也輸出至 stdout。若兩者同時輸出，stdout 將混合 VRR JSON 與路徑訊息，下游管線解析將失敗 | 高 | 明確規範：VRR JSON 至 stdout，儲存路徑訊息至 stderr（或以 `[VC-INFO]` 前綴路由至 stderr） |
| VC-NC-04 | P-04（錯誤訊息可操作性） | §3.3 的 `[VC-ERROR]` 案例缺少具體訊息範本，特別是截圖解析度不符錯誤，使用者不知道實際解析度為何、期望解析度為何 | 低 | 為每個 `[VC-ERROR]` 案例新增包含期望值與實際值的具體訊息格式 |
| VC-NC-05 | P-05（退出碼標準化） | 完全未提及 CLI 退出碼。特別是三個判定結果（PASS / CONDITIONAL_PASS / FAIL）應對應不同退出碼，供 CI 管線識別 | 中 | 定義退出碼：PASS = 0、CONDITIONAL_PASS = 2、FAIL = 1、ERROR = 1（或 FAIL = 3 區分） |
| VC-NC-06 | P-06（執行摘要） | §8.2 的 VRR JSON 已包含完整評分資訊，但 VRR JSON 是機器消費格式。缺少針對人類使用者的 CLI 執行摘要（簡明的文字格式），使得 CLI 直接執行時缺少可讀性 | 低 | 在 §7 步驟 10 後新增人類可讀的文字執行摘要，與 VRR JSON 並列輸出（至 stderr） |

**Vision Critic 符合性評分**：5/10（VRR JSON Schema 設計完整是優勢，但 stdout/stderr 分離衝突問題最嚴重）

---

## 4. 跨技能共同缺口摘要

| 原則 | UX Agent | UI Agent | Vision Critic | 共同優先級 |
|------|----------|----------|---------------|-----------|
| P-01（前綴完整性） | 缺 OK/INFO | 缺 OK/INFO | 缺 OK/WARN/INFO | 高 |
| P-02（進度可見性） | 完全缺失 | 完全缺失 | 完全缺失 | 高 |
| P-03（stdout/stderr 分離） | 完全未定義 | 完全未定義 | 有衝突（混合輸出） | 高（Vision Critic 最嚴重） |
| P-04（錯誤訊息可操作性） | 僅行為描述 | 僅行為描述 | 僅行為描述 | 中 |
| P-05（退出碼標準化） | 完全缺失 | 完全缺失（特殊情境未處理） | 完全缺失 | 中 |
| P-06（執行摘要） | 缺失 | 缺失 | 部分覆蓋（VRR JSON） | 低 |

---

## 5. 不符合項目依影響範圍排序（指引 US-129/130/131 執行順序）

### 優先級 1（高影響 — 管線穩定性）

以下問題若不修正，將導致三層管線在自動化串接時出現解析失敗或無法確認執行狀態：

| 排名 | Story | 問題 ID | 問題描述 | 影響 |
|------|-------|---------|---------|------|
| 1 | US-131（Vision Critic） | VC-NC-03 | stdout/stderr 混合輸出：VRR JSON 與儲存路徑訊息同時至 stdout，管線下游 JSON 解析失敗 | 管線整合阻塞性問題 |
| 2 | US-129（UX Agent） | UX-NC-03 | stdout/stderr 未分離：SSD JSON 與狀態訊息混合，`--ssd-stdin` 管線模式下 UI Agent 無法解析輸入 | 管線整合阻塞性問題 |
| 3 | US-130（UI Agent） | UI-NC-03 | 與 UX-NC-03 相同問題：前端代碼輸出與狀態訊息混合，下游消費困難 | 管線整合阻塞性問題 |

**結論：US-131（Vision Critic）應優先執行，其 stdout/stderr 衝突問題最具體且影響最嚴重。**

### 優先級 2（高影響 — 使用者體驗）

以下問題影響所有使用者在互動時的操作反饋，修正後可顯著改善 CLI 可用性：

| 排名 | Story | 問題 ID | 問題描述 | 影響 |
|------|-------|---------|---------|------|
| 4 | US-129（UX Agent） | UX-NC-02 | LLM 呼叫期間完全無進度回饋，使用者體驗差 | 高（所有 UX Agent 呼叫均受影響） |
| 5 | US-130（UI Agent） | UI-NC-02 | 代碼生成期間無進度回饋；退件重試時（UI-NC-07）無重試進度 | 高（所有 UI Agent 呼叫均受影響） |
| 6 | US-131（Vision Critic） | VC-NC-02 | Playwright 截圖和 LLM 視覺審查期間無進度回饋 | 高（Vision Critic 等待時間最長） |

### 優先級 3（中影響 — 標準化完整性）

以下問題影響 CLI 行為的可預測性和管線腳本的健壯性：

| 排名 | Story | 問題 ID | 問題描述 | 影響 |
|------|-------|---------|---------|------|
| 7 | US-129（UX Agent） | UX-NC-01 | 成功前綴缺失，執行完成無確認訊息 | 中（使用者不確定是否成功） |
| 8 | US-130（UI Agent） | UI-NC-01 | 成功前綴缺失（同 UX-NC-01） | 中 |
| 9 | US-130（UI Agent） | UI-NC-05 | 退出碼未定義，特別是退件耗盡（3 次 FAIL）無特殊碼，CI 無法區分一般錯誤與審查失敗 | 中（影響 CI 判斷） |
| 10 | US-131（Vision Critic） | VC-NC-05 | 退出碼未定義，PASS/FAIL 返回碼相同，CI 無法自動判斷審查結果 | 中（影響 CI 判斷） |
| 11 | US-129（UX Agent） | UX-NC-05 | 退出碼未定義 | 中 |

### 優先級 4（中影響 — 開發體驗）

| 排名 | Story | 問題 ID | 問題描述 | 影響 |
|------|-------|---------|---------|------|
| 12 | US-130（UI Agent） | UI-NC-04 | 錯誤訊息無具體格式，特別是白名單違規的元件定位 | 中（開發除錯效率） |
| 13 | US-129（UX Agent） | UI-NC-04 | 錯誤訊息無具體格式 | 中 |
| 14 | US-131（Vision Critic） | VC-NC-04 | 錯誤訊息無具體格式（截圖解析度錯誤） | 低 |

### 優先級 5（低影響 — 品質提升）

| 排名 | Story | 問題 ID | 問題描述 | 影響 |
|------|-------|---------|---------|------|
| 15 | US-129（UX Agent） | UX-NC-06 | 缺少執行摘要（sections 數、components 數） | 低 |
| 16 | US-130（UI Agent） | UI-NC-06 | 缺少執行摘要 | 低 |
| 17 | US-131（Vision Critic） | VC-NC-01 | PASS/CONDITIONAL_PASS 前綴格式未定義 | 低（VRR JSON 已含判定） |
| 18 | US-131（Vision Critic） | VC-NC-06 | 缺少人類可讀文字執行摘要（VRR JSON 為機器格式） | 低 |

---

## 6. US-129/130/131 執行順序建議

依據上述影響範圍排序分析，建議三個審查 Story 的執行優先順序如下：

```
執行順序：US-131 → US-130 → US-129

理由：
1. US-131（Vision Critic）：優先執行
   - VC-NC-03 為管線整合阻塞性問題（最嚴重）
   - Vision Critic 是管線最下游，修正後確保 VRR JSON 輸出不污染 stdout
   - Size S（1 Point），修正工作量最小但影響最大

2. US-130（UI Agent）：次優先執行
   - UI-NC-03 為管線整合阻塞性問題（同等嚴重）
   - 額外的 UI-NC-07（退件重試進度）是 Vision Critic 退件後的重要使用者體驗點
   - Size M（2 Points），包含 7 個不符合項目

3. US-129（UX Agent）：最後執行
   - UX-NC-03 為管線整合阻塞性問題（需修正）
   - UX Agent 是管線最上游，修正後確保 SSD JSON 輸出乾淨
   - Size M（2 Points），包含 6 個不符合項目
```

---

## 7. 自我審查（Spec Compliance Self-Review）

### AC1 驗證：評估報告建立

- [x] 評估報告已建立（本文件）
- [x] 涵蓋三層管線各技能：UX Agent（§3.1）、UI Agent（§3.2）、Vision Critic（§3.3）

### AC2 驗證：不符合項目清單

- [x] UX Agent 不符合項目：6 項（UX-NC-01 至 UX-NC-06），含具體改善建議
- [x] UI Agent 不符合項目：7 項（UI-NC-01 至 UI-NC-07），含具體改善建議
- [x] Vision Critic 不符合項目：6 項（VC-NC-01 至 VC-NC-06），含具體改善建議
- [x] 總計 19 個不符合項目，每項均有：不符合原則識別、具體描述、影響等級、改善建議

### AC3 驗證：優先順序排序

- [x] 不符合項目依影響範圍排序完成（§5，排名 1–18）
- [x] US-129/130/131 執行順序建議已提供（§6）
- [x] 最高優先級為管線整合阻塞性問題（P-03 stdout/stderr 分離），最低優先級為品質提升項目

---

## 8. 參考資料

- **ADR-014**：`docs/adr/ADR-014-uiux-agent-architecture.md`（三層管線 CLI 輸出規格）
- **UX Agent SKILL.md**：`skills/ux-agent/SKILL.md`（US-105 產出）
- **UI Agent SKILL.md**：`skills/ui-agent/SKILL.md`（US-106 產出）
- **Vision Critic SKILL.md**：`skills/vision-critic/SKILL.md`（US-107 產出）
- **US-129**：Issue #132（UX Agent CLI 輸出設計符合性審查）
- **US-130**：Issue #133（UI Agent CLI 輸出設計符合性審查）
- **US-131**：Issue #134（Vision Critic CLI 輸出設計符合性審查）
