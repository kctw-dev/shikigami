# Sprint 24

**狀態**：完成
**期間**：2026-03-30 ~ 2026-04-05
**Sprint Goal**：在 ADR-007 Phase 1 架構基準上實作外部抽樣審查機制（Phase 2），完成「自審為主、抽檢為輔」品質保障層，並同步強化 Architect/QA 角色在 Story-Lifecycle 架構下的決策知識
**總計**：2 Stories / 5 Points

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| US-41 | ADR-007 Phase 2 — 外部抽樣審查機制實作 | M | 3 | 完成 |
| US-42 | Architect/QA 框架知識強化 — Story-Lifecycle 架構下角色決策指引 | S | 2 | 完成 |

**Sprint 容量**：5 Points

---

## Story 詳細 AC

---

### US-41：ADR-007 Phase 2 — 外部抽樣審查機制實作

**來源**：ADR-007 Phase 2（ROADMAP M5）
**Size**：M / 3 Points
**Owner**：Developer
**ADR-003**：適用（修改 `skills/sprint-execution/SKILL.md`、`skills/sprint-execution/story-lifecycle-prompt.md`）

**User Story**
As a Scrum Master running sprint execution with Story-Lifecycle subagent, I want the external sampling review mechanism (Phase 2) implemented in SKILL.md and story-lifecycle-prompt.md, so that the "self-review first, sampling second" quality assurance layer is operational and compensates for the review independence regression introduced in ADR-007 Phase 1.

**Phase 2 範圍說明**：實作 ADR-007 §AC3 定義的外部抽樣審查機制，包含觸發邏輯、CONFIRM/DISPUTE 流程、Circuit Breaker 機制。不含 §AC4（fallback strategy）的新增內容（Phase 1 已涵蓋）。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | `skills/sprint-execution/SKILL.md` §3 更新 | §3 的 ASCII flow diagram 新增外部抽樣審查步驟節點，明確顯示：(a) 觸發節點位置（Story-Lifecycle subagent 回傳 PASS 後）；(b) 抽樣決策分支（觸發抽樣 vs 不觸發抽樣）；(c) 抽樣結果分支（CONFIRM → 繼續下一個 Story；DISPUTE → 回退處理） |
| AC2 | [靜態] | `skills/sprint-execution/story-lifecycle-prompt.md` 更新 — 抽樣觸發邏輯 | 新增抽樣觸發邏輯章節，包含：(a) 基礎抽樣率：30%（取上整，每 Sprint Story 數 × 30%）；(b) TC-1：首次出現在 Sprint 的 Story 類型（L-size Story 存在時觸發全量 100%）；(c) TC-2：Story 涉及安全相關 AC 時觸發全量 100%；(d) TC-3：前次 Sprint Review 發現自審品質問題時，下一 Sprint 全量觸發直至連續 2 Sprint 無此類問題；(e) TC-4：Story-Lifecycle subagent 連續 2 次 self-review FAIL 時強制觸發外部抽樣；每個觸發條件（TC-1 到 TC-4）為獨立可識別段落，包含判斷規則與觸發優先順序（TC-1 到 TC-4 依序評估，任一觸發即執行全量） |
| AC3 | [靜態] | CONFIRM/DISPUTE 流程定義 | `skills/sprint-execution/SKILL.md` 新增章節（§4 或相應節次），定義主 session 收到外部抽樣審查結果後的完整處理路徑：(a) CONFIRM 路徑：記錄抽樣結果，繼續下一個 Story 執行；(b) DISPUTE 路徑：將相關 Story 狀態回退至「待修復」，將缺陷清單傳入 Story-Lifecycle subagent 要求修復，修復完成後強制執行第二輪外部抽樣審查；兩個路徑各有明確、可識別的步驟列表 |
| AC4 | [靜態] | Circuit Breaker 機制 | 寫入 `skills/sprint-execution/SKILL.md` 或 `skills/sprint-execution/story-lifecycle-prompt.md`（實作者自行決定位置），定義自動降級規則：連續 3 個 Sprint 的 DISPUTE 率超過 20% 時，框架自動觸發 Review 架構重評估，Architect 必須在下一個 Sprint Planning 前決定是否回退至部分封裝（ADR-007 選項 C）或引入其他補償機制；實作者須自行決定 DISPUTE 率重置條件（如：成功 Sprint 後重置計數器，或滾動 3 Sprint 窗口）並明確文件化重置條件 |
| AC5 | [靜態] | 驗收清單（靜態核對） | 提供 Phase 2 所有新增機制的靜態驗收清單，供 QA 逐項核對，清單須涵蓋：(a) 基礎 sampling rate 30% 設定值在文件中存在且可識別；(b) TC-1 至 TC-4 每個觸發條件各有獨立可識別段落；(c) CONFIRM 路徑有明確步驟列表；(d) DISPUTE 路徑有明確步驟列表（含回退 + 缺陷傳入 + 第二輪抽樣三個步驟）；(e) Circuit Breaker 觸發條件（3 Sprint + 20% 閾值）有文件化；(f) Circuit Breaker 重置條件有文件化 |

---

### US-42：Architect/QA 框架知識強化 — Story-Lifecycle 架構下角色決策指引

**來源**：Stakeholder 需求 / 候選 Story「Architect/QA 框架開發領域專家知識強化」
**Size**：S / 2 Points
**Owner**：Developer
**ADR-003**：適用（新建 `skills/architect/SKILL.md`、`skills/qa-engineer/SKILL.md`）
**ADR-003 Checklist item 3 豁免說明**：`skills/architect/SKILL.md` 與 `skills/qa-engineer/SKILL.md` 為全新建立的檔案，不存在「修改前讀取當前版本」的前提，ADR-003 Checklist item 3（讀取當前版本後再修改）對本 Story 的新建檔案豁免適用。

**User Story**
As an Architect or QA Engineer agent operating within the Story-Lifecycle architecture, I want dedicated SKILL.md files that provide concrete decision criteria for my role, so that I can make consistent and justified decisions during Sprint Planning rounds without relying on ad-hoc interpretation of the framework's general guidelines.

**依賴**：US-41（需優先完成，因 US-42 的 SKILL.md 內容需引用 US-41 交付的 Phase 2 機制，且 US-41 修改 `skills/sprint-execution/SKILL.md` 而 US-42 AC3 需新增指向新建 SKILL.md 的引用連結，避免同檔案競態條件）

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 建立 `skills/architect/SKILL.md` | 新建 `skills/architect/SKILL.md`，包含 Story-Lifecycle 架構下 Architect 角色決策指引；以下三個主題各為獨立可識別章節，每個章節至少包含一個具體判斷標準或觸發條件：(a) 估點策略（T-shirt sizing 判斷規則，S/M/L 的具體邊界條件）；(b) ADR 需求判斷（何時需要新建 ADR、何時修改現有 ADR、何時不需要 ADR 的具體判斷標準）；(c) 平行分群策略（Story 間依賴關係判斷、Phase 劃分規則、同檔案競態偵測條件） |
| AC2 | [靜態] | 建立 `skills/qa-engineer/SKILL.md` | 新建 `skills/qa-engineer/SKILL.md`，包含 Story-Lifecycle 架構下 QA 角色決策指引；以下三個主題各為獨立可識別章節，每個章節至少包含一個具體判斷標準或觸發條件：(a) AC 驗證策略（靜態 AC vs 動態 AC 的識別規則、驗收標準補全觸發條件、測試覆蓋判斷）；(b) Spec Compliance review 決策（通過 vs 失敗的判斷邊界、DISPUTE 升級觸發條件）；(c) Code Quality review 策略（靜態分析標準、doc-only Story 的 review 豁免規則、L-size Story 的加強審查項目） |
| AC3 | [靜態] | 現有 SKILL.md 交叉引用 | `skills/sprint-execution/SKILL.md` 或 `skills/sprint-planning/SKILL.md` 新增指向 `skills/architect/SKILL.md` 與 `skills/qa-engineer/SKILL.md` 的引用連結；引用位置須與角色職責相關（如 sprint-execution SKILL.md 中角色派遣段落，或 sprint-planning SKILL.md 中 Architect/QA 輪次段落）；連結格式為 Markdown 超連結，路徑使用相對路徑 |

---

## 平行分群（Architect 建議）

### Phase 1 — 優先執行

| Story | 負責人 | 說明 |
|-------|--------|------|
| US-41 | Developer | ADR-007 Phase 2 外部抽樣審查機制實作，需優先完成以建立 Phase 2 架構基準，且 US-42 AC3 依賴本 Story 完成後的 SKILL.md 狀態 |

### Phase 2 — 依序執行（US-41 完成後）

| Story | 負責人 | 說明 |
|-------|--------|------|
| US-42 | Developer | Architect/QA SKILL.md 建立，依賴 US-41 交付物（Phase 2 機制內容）且 AC3 需修改 US-41 已更新的 SKILL.md，防止同檔案競態條件 |

**執行順序**：US-41 → US-42（嚴格序列，不可平行）

---

## 工作容量

| 項目 | 數值 |
|------|------|
| Sprint 期間 | 2026-03-30 ~ 2026-04-05（7 天） |
| 總 Stories | 2 |
| 總 Points | 5 |
| Phase 1 容量 | 3 Points（US-41） |
| Phase 2 容量 | 2 Points（US-42） |

---

## ADR 觸發清單

| Story | ADR 編號 | 說明 |
|-------|----------|------|
| US-41 | 無新 ADR | ADR-007 Phase 2 為既有 ADR-007 §AC3 的實作，範圍在 ADR-007 既定決策內，無需新 ADR |
| US-42 | 無新 ADR | 建立新 SKILL.md 為知識文件擴充，無架構決策變更；ADR-003 Checklist 適用（新建 skills/architect/SKILL.md、skills/qa-engineer/SKILL.md） |

**本 Sprint 無新 ADR**。

---

## QA 追蹤項目（Round 1 識別）

| 項目 | 說明 | 對應 AC |
|------|------|---------|
| CONFIRM/DISPUTE 文件位置明確化 | AC3 要求新增章節寫入 `skills/sprint-execution/SKILL.md`（§4 或相應節次），已在 AC3 條文中指定 | US-41 AC3 |
| 最低內容規格補充 | AC1/AC2 已明確要求每個主題為獨立可識別章節，且至少包含一個具體判斷標準或觸發條件 | US-42 AC1/AC2 |
| 驗收清單（非可執行測試） | AC5 採用「靜態驗收清單」形式（靜態核對），非可執行測試套件 | US-41 AC5 |
| 執行順序強制序列 | US-41 必須先於 US-42 完成，防止同檔案競態條件（`skills/sprint-execution/SKILL.md`） | 平行分群 |
| ADR-003 Checklist item 3 豁免 | US-42 新建檔案（skills/architect/SKILL.md、skills/qa-engineer/SKILL.md）豁免 ADR-003 Checklist item 3 | US-42 |
| Circuit Breaker 重置條件 | AC4 要求實作者自行決定重置條件並文件化，已在 AC4 中以括號示例提示（如：成功 Sprint 後重置，或滾動 3 Sprint 窗口） | US-41 AC4 |

---

## Sprint Planning 簽核

- **PO Round 1**：完成（Story 選取：US-41、US-42；初版 AC；Sprint Goal 確定；總計 5pt）
- **Architect Round 1**：完成（US-41 M/3pt 確認，ADR-007 Phase 2 範圍內無需新 ADR；US-42 S/2pt 確認，目標 SKILL.md 尚不存在需新建；執行順序：US-41 → US-42 嚴格序列；ADR-003 適用兩個 Stories）
- **QA Round 1**：完成（兩個 Stories 均通過可測試性評估；US-41 AC3 補充文件位置說明；US-42 AC1/AC2 補充最低內容規格；US-41 AC5 改為靜態驗收清單（非可執行測試）；執行順序嚴格序列確認；US-42 ADR-003 Checklist item 3 豁免確認；US-41 AC4 Circuit Breaker 重置條件交由實作者文件化）
- **PO Round 2**：完成（QA 回饋整合完成：US-41 AC1 ASCII flow diagram 三個分支明確化、AC2 TC-1~TC-4 各為獨立可識別段落且含優先順序說明、AC3 CONFIRM/DISPUTE 兩路徑各有明確步驟列表、AC4 重置條件示例提示、AC5 改為靜態核對清單涵蓋六項；US-42 AC1/AC2 章節最低內容規格明確化、AC3 引用連結格式要求；Sprint 文件建立確認）
