# Sprint 23

**狀態**：完成
**期間**：2026-03-23 ~ 2026-03-29
**Sprint Goal**：落實 ADR-007 首個實作里程碑，同步清零 Sprint 22 技術品質欠帳
**總計**：4 Stories / 5 Points

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| US-40 | Story-Lifecycle Subagent 實作 — ADR-007 Phase 1 | M | 2 | 完成 |
| Retro #59（Issue #59） | Cron template SHIKIGAMI_SCHEDULED 條件化 export 修正 | S | 1 | 完成 |
| Retro #60（Issue #60） | TECH-DEBT Registry 補登 ADR-006 JSON Schema 技術債 (TD-002) | S | 1 | 完成 |
| Retro #61（Issue #61） | Onboarding SKILL.md stale reference 審查與修正 | S | 1 | 完成 |

**Sprint 容量**：5 Points

---

## Story 詳細 AC

---

### US-40：Story-Lifecycle Subagent 實作 — ADR-007 Phase 1

**來源**：ADR-007（Sprint 22 決策）
**Size**：M / 2 Points
**Owner**：Developer

**User Story**
As a Scrum Master running sprint execution, I want a Story-Lifecycle subagent prompt and SKILL.md integration defined for Phase 1, so that the ADR-007 architecture decision has a concrete first implementation milestone that validates the interface contract before full rollout.

**Phase 1 範圍說明**：strictly `story-lifecycle-prompt.md` + SKILL.md §3 update。AC3 sampling 機制（ADR-007 Phase 2）不在本 Sprint 範圍內。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | story-lifecycle-prompt.md 建立 | 新建 `skills/sprint-execution/story-lifecycle-prompt.md`；檔案存在且非空；內容包含 Story-Lifecycle subagent 的角色定義、輸入格式說明（Story ID、AC 清單、相關檔案路徑）、輸出格式說明（PASS/FAIL + 摘要 + 修改檔案清單 + commit SHA）、錯誤升級條件（escalation triggers） |
| AC2 | [靜態] | SKILL.md §3 更新含 ASCII flow diagram | `skills/sprint-execution/SKILL.md` §3 更新為引用 story-lifecycle-prompt.md 的派遣步驟說明；§3 的 ASCII flow diagram 須同步更新以反映 Story-Lifecycle subagent 的新派遣路徑（不得僅更新步驟文字而保留舊 flow diagram）；flow diagram 中須明確顯示 subagent 派遣節點 |
| AC3 | [靜態] | 介面契約內嵌 YAML schema | `story-lifecycle-prompt.md` 或 `SKILL.md` §3 須包含 ADR-007 §AC2 Phase 1 介面契約的 inline YAML schema copy，涵蓋：input schema（Story ID、AC list、file paths）與 output schema（status、summary、modified_files、commit_sha、escalation）；Phase 1 範圍不包含 §AC3（sampling）與 §AC4（fallback strategy）的完整實作，但 schema 須有對應欄位佔位 |
| AC4 | [動態] | 現有測試套件驗證（或 N/A） | 若 `skills/sprint-execution/` 下存在測試套件（如 `test-*.sh` 或 `tests/` 目錄），執行現有測試確認無回歸；若無測試套件，標記本 AC 為 N/A 並說明原因；不要求新建測試套件 |

---

### Retro #59（Issue #59）：Cron template SHIKIGAMI_SCHEDULED 條件化 export 修正

**來源**：Sprint 22 Retro / GitHub Issue #59
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As a framework operator using scheduled sprint execution, I want the cron template to conditionally export SHIKIGAMI_SCHEDULED only when a sprint skill is being invoked, so that the environment variable does not leak into non-sprint skill executions and cause unintended behavior.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | bash if-condition 條件化 export 實作 | schedule skill 的 cron template（`skills/schedule/` 相關模板檔案）中，`SHIKIGAMI_SCHEDULED` 的 export 改為以 bash if-condition 實作條件化：僅當 `SKILL_NAME` 變數值為 sprint 相關 skill（如 `sprint-planning`、`sprint-execution`）時才執行 `export SHIKIGAMI_SCHEDULED=true`；其他 skill 呼叫時不 export 此變數；條件語法須為 bash if 語句（如 `if [[ "$SKILL_NAME" == "sprint-planning" ]] || [[ "$SKILL_NAME" == "sprint-execution" ]]; then`） |
| AC2 | [靜態] | 測試場景覆蓋（sprint vs non-sprint） | 在 `tests/test-schedule.sh`（或 schedule skill 對應測試檔案）新增測試案例，至少涵蓋以下兩個場景：(a) sprint skill 呼叫場景：`SKILL_NAME=sprint-planning` 或 `SKILL_NAME=sprint-execution` 時，`SHIKIGAMI_SCHEDULED` 應被 export 且值為 `true`；(b) non-sprint skill 呼叫場景：`SKILL_NAME` 為非 sprint 值（如 `standup`、`health-check`）時，`SHIKIGAMI_SCHEDULED` 不應被 export（unset 狀態） |

---

### Retro #60（Issue #60）：TECH-DEBT Registry 補登 ADR-006 JSON Schema 技術債 (TD-002)

**來源**：Sprint 22 Retro / GitHub Issue #60
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As a Product Owner tracking technical debt, I want ADR-006's JSON Schema gap to be formally registered in the TECH-DEBT Registry as TD-002, so that this known technical debt is visible, prioritized, and not forgotten in future sprint planning.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | TD-002 新增至 TECH-DEBT Registry | `docs/km/TECH_DEBT.md` 新增 TD-002 登錄項目；TD-002 內容描述 ADR-006 JSON Schema 缺口（prompt injection isolation 介面未有正式 schema 定義）；TD-001（EXAMPLE 佔位項）保持不變，TD-002 為第二個條目 |
| AC2 | [靜態] | TD-002 登錄欄位完整 | TD-002 登錄項目包含以下完整欄位：ID（TD-002）、標題、描述（ADR-006 JSON Schema 缺口說明）、引入 Sprint（Sprint 22）、關聯 Story（US-37 / ADR-006）、RICE 評分（或待定）、MoSCoW 分級、現況（Open）、解決方式（待定或具體描述） |

---

### Retro #61（Issue #61）：Onboarding SKILL.md stale reference 審查與修正

**來源**：Sprint 22 Retro / GitHub Issue #61
**Size**：S / 1 Point
**Owner**：Developer

**注意**：本 Story 修改 `skills/onboarding/SKILL.md`，屬 Framework Document Change，須走 ADR-003 Checklist 完整流程（非 doc-only 路徑）。

**User Story**
As a framework user following the Onboarding skill, I want all references in onboarding SKILL.md to be accurate and up-to-date, so that I can follow the onboarding instructions without hitting broken links or outdated step references.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | ADR-003 Checklist 通過 | 修改 `skills/onboarding/SKILL.md` 前確認 ADR-003 Framework Document Change Audit Checklist 四項條件全部通過；本 Story 不走 doc-only 路徑 |
| AC2 | [靜態] | 審查範圍定義與 stale reference 修正 | 審查 `skills/onboarding/SKILL.md` 全文中的所有數字引用（numeric references：章節號碼、步驟編號、檔案計數等數字）與路徑引用（path references：檔案路徑如 `docs/`、`skills/`、`commands/` 開頭的路徑，以及 skill route 名稱如 `shikigami:standup`、`shikigami:health-check` 等）；識別並修正所有 stale reference；若發現 `/standup` 引用（如 `shikigami:standup` 或 `commands/standup.md`），Developer 須驗證其是否仍有效，無效則更新或移除 |
| AC3 | [靜態] | 修正結果報告 | 在 Sprint 執行記錄或 commit message 中列出：(a) 審查的 numeric references 總數與 path references 總數；(b) 發現的 stale references 清單（每項含：原文、位置行號、修正後內容）；(c) 若無 stale reference，明確輸出「審查完成，無 stale reference 發現」 |

**Retro #61 AC3 審查報告**（補登，修正 QA Issue #61 AC3(a) 缺漏）

```
Retro #61 審查報告 — skills/onboarding/SKILL.md 全文掃描結果

(a) 審查總數
    Numeric references 審查總數：7 個
      1. 行 20：「5 個階段」（流程階段數）
      2. 行 20：「第 2.4 節」（章節交叉引用）
      3. 行 28：「4 個範本文件」（§2.1 templates 數量）
      4. 行 51：「4 個核心目錄」（§2.2 目錄數量）
      5. 行 68：「4 個核心範本」（§2.3 複製目標數量，原為 stale "3"，已修正）
      6. 行 101：「3 個問題」（§2.4 問答流程問題數）
      7. 行 132：「3 個回答」（§2.4 收到回答數）

    Path references 審查總數：15 個
      1.  templates/（目錄）
      2.  templates/PRODUCT_BACKLOG.md
      3.  templates/ROADMAP.md
      4.  templates/PROJECT_BOARD.md
      5.  templates/BACKLOG_DONE.md
      6.  templates/CLAUDE.md.template
      7.  docs/prd/
      8.  docs/adr/
      9.  docs/sprints/
      10. docs/km/
      11. docs/PROJECT_BOARD.md
      12. shikigami:health-check
      13. shikigami:sprint-planning
      14. shikigami:architecture-decision
      15. shikigami:backlog-management

(b) Stale references 發現（共 1 個）
    - 行 68：「將 3 個核心範本複製至 docs/prd/」
      → 修正為：「將 4 個核心範本複製至 docs/prd/」
      （原因：BACKLOG_DONE.md 於 Sprint 22 / US-33 新增至 templates/ 與 §2.3 table，
              prose 數字 "3" 未同步更新，與 table 實際 4 列不一致）

    /standup 引用驗證：SKILL.md 中出現「/standup」於行 152（
    輸出清單步驟 "執行 /standup"）。此處為使用者引導文字，
    非路徑引用，不觸發路徑有效性檢查。無 shikigami:standup 或
    commands/standup.md 路徑引用存在。

審查完成。除上述 stale reference（已於 commit fe7012c 修正）外，無其他 stale reference。
```

---

## 平行分群（Architect 建議）

### Phase 1 — 優先執行

| Story | 負責人 | 說明 |
|-------|--------|------|
| US-40 | Developer | ADR-007 Phase 1 實作，需優先完成以建立架構基準 |

### Phase 2 — 平行執行（US-40 完成後或獨立）

| Story | 負責人 | 說明 |
|-------|--------|------|
| Retro #59（Issue #59） | Developer | 獨立，無依賴，可與 #60/#61 平行 |
| Retro #60（Issue #60） | Developer | Doc-only，獨立，可與 #59/#61 平行 |
| Retro #61（Issue #61） | Developer | 須 ADR-003 Checklist，可與 #59/#60 平行 |

---

## 工作容量

| 項目 | 數值 |
|------|------|
| Sprint 期間 | 2026-03-23 ~ 2026-03-29（7 天） |
| 總 Stories | 4 |
| 總 Points | 5 |
| Phase 1 容量 | 2 Points（US-40） |
| Phase 2 容量 | 3 Points（Retro #59 + #60 + #61，可平行） |

---

## ADR 觸發清單

| Story | ADR 編號 | 說明 |
|-------|----------|------|
| US-40 | 無新 ADR | ADR-007 已於 Sprint 22 建立；Phase 1 為實作，無需新 ADR |
| Retro #59 | 無新 ADR | ADR-005 無需修訂；純實作修正 |
| Retro #60 | 無新 ADR | Doc-only 登錄，無架構決策 |
| Retro #61 | 無新 ADR | ADR-003 Checklist 適用（修改 skills/onboarding/SKILL.md）；無新 ADR 需求 |

**本 Sprint 無新 ADR**。

---

## Sprint Planning 簽核

- **PO Round 1**：完成（Story 選取：US-40、Retro #59、Retro #60、Retro #61；初版 AC；Sprint Goal 確定；總計 5pt）
- **Architect Round 1**：完成（US-40 M/2pt 確認，Phase 1 範圍限定 story-lifecycle-prompt.md + SKILL.md §3；Retro #59/#60/#61 各 S/1pt 確認；執行順序：US-40 first → Retro #59/#60/#61 parallel；無新 ADR）
- **QA Round 1**：完成（US-40 AC2/AC3/AC4 修訂；Retro #59 AC1/AC2 修訂；Retro #60 PASS；Retro #61 AC2 範圍定義修訂；ADR-003 Checklist 適用確認 Retro #61）
- **PO Round 2**：完成（QA 回饋整合完成：US-40 AC2 明確 ASCII flow diagram 更新要求、AC3 明確 inline YAML schema copy 範圍、AC4 降級為 N/A 機制；Retro #59 AC1 明確 bash if-condition、AC2 明確測試檔案路徑與 sprint vs non-sprint 場景；Retro #61 AC2 明確 numeric/path reference 定義；Sprint 文件建立確認）
