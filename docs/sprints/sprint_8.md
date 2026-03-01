# Sprint 8

> 週期：2026-03-01 ~ 2026-03-08
> 狀態：進行中
> 專案等級：low（完全自治）

---

## Sprint Goal

**「修復 Sprint Execution Issue 回覆缺口，恢復 QA 雙階段審查，建立制衡案例文件庫，引入輕量 Bypass 機制，讓 v0.3.x 更接近可推廣狀態」**

Retro #14 恢復 Sprint 7 跳過的 QA 雙階段審查。US-21 從歷史 Sprint 提取真實制衡案例，建立信任。US-18 在 sprint-execution 流程中加入 Issue 快掃，解決外部協作者被忽略的問題。US-20 引入 Bypass 機制，減少小任務的 ceremony 成本。

對應 ROADMAP：M5「穩定化」。

---

## Sprint Backlog

| Story | 任務 | 負責 | 狀態 | QA Review |
|---|---|---|---|---|
| Retro #14：恢復 QA 雙階段審查 | sprint-execution SKILL.md Hard Gate 語言強化 + sprint_8.md QA Review 欄位新增 | Developer | 完成 | Spec: PASS / Code: PASS |
| US-21：真實制衡案例文件 | 新建 `docs/km/ROLE_BALANCE_CASES.md`（4+ 案例）+ README 連結 + sprint-review 提示 | Developer | 待開始 | Spec: — / Code: — |
| US-18：Sprint Execution Issue 回覆自動化 | sprint-execution SKILL.md 新增 Issue 快掃子步驟 + label 狀態追蹤機制 | Developer + Architect | 待開始 | Spec: — / Code: — |
| US-20：輕量 Bypass 機制 | scrum-master SKILL.md 新增 Bypass 定義 + Hard Gate 豁免條款 | Developer + Architect | 待開始 | Spec: — / Code: — |

---

## 工作容量

- Retro #14：< 0.1 Sprint（S，SKILL.md 文字強化 + 欄位新增）
- US-21：~0.2 Sprint（S，案例提取整理 + 連結新增）
- US-18：~0.3 Sprint（M，流程設計 + label 機制 + 多 Agent 協調定義）
- US-20：~0.3 Sprint（M，Bypass 定義 + 保護清單 + Hard Gate 豁免條款）
- 合計：~0.9 Sprint（6 points）

**Points 換算**（T-shirt Sizing）：Retro #14 = 1pt（S）、US-21 = 1pt（S）、US-18 = 2pt（M）、US-20 = 2pt（M）= 合計 **6 points**

> **容量決策說明**：歷史 Velocity 為 5→4→6→8→7，6pt 處於中位。US-18 Architect 上調至 M（多 Agent 協調設計），整體容量仍可控。

---

## 執行順序

```
Retro #14 ─────────────────────────────────> 待開始（最優先：恢復 Hard Gate，後續 Story 依此執行）

US-21 ─────────────────────────────────────> 待開始（無依賴，文件整理工作）

US-18 ─────────────────────────────────────> 待開始（無依賴，但建議 Retro #14 完成後開始）

US-20 ─────────────────────────────────────> 待開始（前置：Retro #14 完成，需在 Hard Gate 條文下新增豁免條款）
```

- Retro #14 最優先：Sprint 8 所有 Story 都要走 QA 雙階段審查
- US-21 與 Retro #14 可並行（無依賴）
- US-18 建議在 Retro #14 完成後開始（確保 QA 審查流程已恢復）
- US-20 必須在 Retro #14 完成後實作（需要在 Hard Gate 下新增 Bypass 豁免條款）

---

## 風險

| 風險 | 可能性 | 影響 | 應對 |
|---|---|---|---|
| Retro #14 與 US-20 的 Hard Gate / Bypass 衝突 | 確定 | 高 | Retro #14 先實作，US-20 在 Hard Gate 條文下新增明確豁免條款；QA 已識別此衝突 |
| US-18 的「同一 Sprint 只回覆一次」狀態追蹤 | 中 | 中 | 採用 GitHub label（`sprint-N-replied`）方案，不開正式 ADR，在 SKILL.md 內嵌決策說明 |
| US-20 Bypass 被濫用侵蝕品質 | 低 | 高 | AC3 保護清單 + 40% 上限 + Hard Gate 優先於 Bypass 的明確聲明 |
| US-18 PO+QA 雙 subagent 協調增加 token 消耗 | 中 | 低 | 加入 open issue 數量上限（前 5 個），避免過度掃描 |

---

## Story 詳情

### Retro #14：恢復 QA 雙階段審查

**背景與動機**

Sprint 7 Execution 跳過了 Spec Compliance + Code Quality 雙階段 QA Review，違反 sprint-execution SKILL.md 第 4 節 Hard Gate 規定。

**修改目標**：`skills/sprint-execution/SKILL.md` 語言強化 + `docs/sprints/sprint_8.md` 欄位新增

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | Hard Gate 語言強化 | `skills/sprint-execution/SKILL.md` 第 3 節流程圖的 QA 審查節點旁標注「不可跳過（HARD-GATE）」；第 4 節 Hard Gate 條文後補充歷史案例引用（Sprint 7 Issue #14） |
| AC2 | [靜態] | QA Review 欄位 | `docs/sprints/sprint_8.md` Sprint Backlog 表格新增「QA Review」欄，格式為「Spec: PASS/FAIL / Code: PASS/FAIL」；Sprint 8 所有 Story 列的 QA Review 欄均非空白 |

**MoSCoW**：Must（Retro Action Item）
**GitHub Issue**：#14
**Size**：S / **Points**：1

---

### US-21：真實制衡案例文件

**背景與動機**

Issue #12 指出：Shikigami 的差異化在於角色制衡，但只有文字描述，缺乏真實案例佐證。Sprint 1-7 的 Retrospective Log 已有豐富素材。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 文件建立 | `docs/km/ROLE_BALANCE_CASES.md` 存在；含至少 4 個案例，每個案例含 5 個必填欄位：Sprint 來源、情境描述、制衡角色、決策結果、後續影響 |
| AC2 | [靜態] | 類型覆蓋 | 每個案例含「制衡類型」欄位，取值為列舉值（`QA-推翻設計` / `PO-退回` / `Architect-上調估點` / `Security-阻擋` / `Hard-Gate-攔截`）；4 個案例覆蓋至少 3 種不同類型 |
| AC3 | [靜態] | README 引用 | `README.md` 實戰驗證區段新增指向 `docs/km/ROLE_BALANCE_CASES.md` 的連結 |
| AC4 | [靜態] | Sprint Review 提示 | `skills/sprint-review/SKILL.md` 執行檢查清單新增「是否有本 Sprint 值得記錄的角色制衡案例？若有，更新 `docs/km/ROLE_BALANCE_CASES.md`」 |

**RICE**：25.3
**MoSCoW**：Should
**Size**：S / **Points**：1
**對應 Issue**：#12（建議 3）

---

### US-18：Sprint Execution Issue 回覆自動化

**背景與動機**

Issue #9 指出 sprint-execution 流程缺少 Issue 回覆步驟，外部協作者的問題在 Sprint 執行期間被忽略。

**狀態追蹤決策**：採用 GitHub label（`sprint-N-replied`）作為防重複機制，不開正式 ADR。理由：label 可跨 subagent 持久化、可靜態驗證、gh CLI 原生支援。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 流程整合 | `skills/sprint-execution/SKILL.md` 第 3 節流程圖在「取出 Story」步驟前新增「Issue 快掃」子步驟，含完整步驟說明 |
| AC2 | [靜態] | 降級指引 | SKILL.md 含 `gh issue list --state open --limit 10` 指令；含明確降級指引文字（「gh 失敗時靜默略過，不阻塞 Story 執行」） |
| AC3 | [靜態] | 回覆觸發規則 | SKILL.md 定義觸發條件：(a) 無 `in-backlog`/`sprint-N-replied` label；(b) PO subagent 草稿 → QA 審核 → 依專案等級發布；(c) open issue 超過 5 個時僅處理最舊的前 5 個 |
| AC4 | [靜態] | 防重複機制 | SKILL.md 定義：回覆後加 `sprint-N-replied` label（N 為當前 Sprint 編號）；快掃時篩除含此 label 的 issue |

**RICE**：23.8
**MoSCoW**：Should
**Size**：M / **Points**：2
**對應 Issue**：#9

---

### US-20：輕量 Bypass 機制

**背景與動機**

Issue #12 指出 Scrum 儀式對低複雜度任務（如 Retro Action Item）成本過高。Sprint 1-7 歷史顯示 Retro 類任務反覆消耗完整 ceremony 資源。

**前置條件**：Retro #14 完成（需在 Hard Gate 條文下新增 Bypass 豁免條款）

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | Bypass 觸發條件 | `skills/scrum-master/SKILL.md` 定義 Bypass 觸發條件：(a) Size = S 且無 ADR 依賴；(b) 使用者標注 `[QUICK]`；(c) Retro Action Item 類任務 |
| AC2 | [靜態] | Bypass 流程定義 | Bypass 跳過：Architect T-shirt 估點、QA AC 審查、雙階段 QA Review。保留：DoD 自檢（功能層 = AC 通過）、Commit、PROJECT_BOARD 更新 |
| AC3 | [靜態] | 保護清單 | Bypass 禁止清單含 3 項：Framework Document Change（引用 ADR-003 §9.1）、外部 API、安全相關。標注 `[QUICK]` 仍強制完整流程，SKILL.md 含拒絕輸出格式範例 |
| AC4 | [靜態] | 稽核追蹤 | `sprint_N.md` Story 行標注 `[BYPASS]`；每 Sprint Bypass 不超過 40%（含計算示例：5 Story → 上限 2 個 Bypass） |
| AC5 | [靜態] | Hard Gate 豁免 | `skills/sprint-execution/SKILL.md` 第 4 節 Hard Gate 條文下新增 Bypass 豁免子句：「標記為 [BYPASS] 的 Story 豁免雙階段審查，豁免條件與 scrum-master SKILL.md Bypass 保護清單對齊」 |

**RICE**：20.25
**MoSCoW**：Should
**Size**：M / **Points**：2
**對應 Issue**：#12（建議 2）

---

## 驗收標準

### Retro #14：恢復 QA 雙階段審查

- [ ] sprint-execution SKILL.md Hard Gate 語言強化（AC1 通過）
- [ ] sprint_8.md QA Review 欄位新增且所有 Story 欄位非空（AC2 通過）
- [ ] GitHub Issue #14 關閉

### US-21：真實制衡案例文件

- [ ] `docs/km/ROLE_BALANCE_CASES.md` 存在，含 4+ 案例（AC1 通過）
- [ ] 覆蓋至少 3 種制衡類型（AC2 通過）
- [ ] README.md 新增連結（AC3 通過）
- [ ] sprint-review SKILL.md 新增提示（AC4 通過）

### US-18：Sprint Execution Issue 回覆自動化

- [ ] sprint-execution SKILL.md 新增 Issue 快掃子步驟（AC1 通過）
- [ ] 降級指引完整（AC2 通過）
- [ ] 回覆觸發規則定義（AC3 通過）
- [ ] `sprint-N-replied` label 防重複機制（AC4 通過）

### US-20：輕量 Bypass 機制

- [ ] scrum-master SKILL.md Bypass 觸發條件定義（AC1 通過）
- [ ] Bypass 流程定義（跳過/保留清單）（AC2 通過）
- [ ] 保護清單 + 拒絕格式範例（AC3 通過）
- [ ] sprint_N.md `[BYPASS]` 標注 + 40% 上限（AC4 通過）
- [ ] sprint-execution Hard Gate 豁免條款（AC5 通過）
