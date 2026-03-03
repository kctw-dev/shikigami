# Sprint 29

**狀態**：完成
**期間**：2026-03-09 ~ 2026-03-15
**Sprint Goal**：以 Issue #3 正式結案為里程碑，完成 OpenCode 平台動態驗證（US-52）與 M5 條件 (a) 外部使用者觸及的具體招募行動（US-53），使 M5 最後一個開放條件進入可達成狀態
**總計**：2 Stories / 3 Points

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | QA doc-only 判定 | 狀態 |
|----------|------|------|--------|-----------------|------|
| US-52 | OpenCode Phase 4 — Issue #3 正式結案：動態驗證補完與 Issue 關閉 | M | 2 | No | 完成 |
| US-53 | M5 Beta 使用者招募 — README 招募文案 + Issue 引導機制 | S | 1 | No | 完成 |

**Sprint 容量**：3 Points

---

## Story 詳細 AC

---

### US-52：OpenCode Phase 4 — Issue #3 正式結案：動態驗證補完與 Issue 關閉

**來源**：OPENCODE_POC.md §12 Phase 3c [PENDING-DYNAMIC] 標注 / Issue #3 結案評估需求
**Size**：M / 2 Points
**Owner**：Developer

**User Story**
As a Product Owner closing Issue #3, I want the OpenCode dynamic verification gaps identified in Phase 3c to be resolved through supplementary verification, and Issue #3 to be formally closed with a linked summary, so that the team can demonstrate M5 condition readiness with a concrete closed milestone.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | OPENCODE_POC.md §12 Phase 3c 動態驗證補完 | 更新 `docs/km/OPENCODE_POC.md` §12（Phase 3c）中標注為 `[PENDING-DYNAMIC]` 的動態驗證項目：補充 P-2（`prompt` 參數命名）確認記錄或替代驗證說明；更新驗證狀態標注（由 `[PENDING-DYNAMIC]` 改為 `[VERIFIED]` 或 `[STATIC-CONFIRMED]`） |
| AC2 | [靜態] | OPENCODE_POC.md §13 Issue #3 結案記錄 | 在 `docs/km/OPENCODE_POC.md` 新增 §13（Phase 4 / Issue #3 結案記錄）：包含結案日期、達成條件確認清單（對照 §12.4.2 達成路徑剩餘步驟）、Issue #3 關閉行動摘要 |
| AC3 | [動態] | GitHub Issue #3 正式關閉 | 在 GitHub Issue #3 評論中貼上結案摘要（含 OPENCODE_POC.md §13 連結）；使用 `gh issue close 3` 正式關閉 Issue #3；Issue 狀態由 open 變為 closed |
| AC4 | [靜態] | ROADMAP.md Issue #3 狀態更新 | `docs/prd/ROADMAP.md` 中 Issue #3 標注從「有明確結論」更新為「已結案（Sprint 29）」或等效描述 |

---

### US-53：M5 Beta 使用者招募 — README 招募文案 + Issue 引導機制

**來源**：M5 條件 (a) 外部使用者觸及 / Issue #3 結案後 Beta 招募啟動
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As a Product Owner targeting M5 completion, I want README to include an explicit Beta user recruitment section and a GitHub Issue template guiding users to report their first Sprint completion, so that external users have a clear call-to-action to try Shikigami and provide the feedback needed to satisfy M5 condition (a).

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | README.md Beta 招募區段 | `README.md` 新增「Beta 使用者招募」區段（位置：OpenCode 平台支援章節之後）；包含：(a) 招募說明文案（邀請外部使用者試用 Shikigami）；(b) 試用對象說明（Claude Code 或 OpenCode 使用者）；(c) 回報管道說明（連結至 GitHub Issue 或 Discussions） |
| AC2 | [靜態] | GitHub Issue 引導連結 | README.md Beta 招募區段包含明確的 GitHub Issue 回報引導：提供可直接點擊的 Issue 建立連結（pre-filled template URL 或 Issue #3 的 Discussion 連結），讓使用者能輕鬆提交「完成首個 Sprint」回饋 |
| AC3 | [靜態] | M5_COMPLETION_ASSESSMENT.md 狀態更新 | `docs/prd/M5_COMPLETION_ASSESSMENT.md` 條件 (a) 區段新增「招募行動記錄」子節，記錄本次招募行動（日期、管道、README 連結、預期觸及方式） |
| AC4 | [靜態] | OPENCODE_POC.md §13 招募行動交叉引用 | `docs/km/OPENCODE_POC.md` §13 結案記錄中新增「Beta 招募啟動」段落，交叉引用 README.md 新增的招募區段，確認 M5 條件 (a) 達成路徑已啟動 |

---

## 平行分群（Architect 建議）

### Phase 1 — 全部平行執行

| 群組 | Stories | 說明 |
|------|---------|------|
| Phase 1 | US-52、US-53（全部平行） | 兩個 Story 完全獨立，無強制序列依賴，可平行執行；US-53 AC4 交叉引用 OPENCODE_POC.md §13，需在 US-52 AC2 完成 §13 建立後執行（輕量序列化，僅最後一個 AC） |

**執行順序說明**：
- US-52 主體工作（AC1~AC4）與 US-53 主體工作（AC1~AC3）可完全平行執行
- US-53 AC4（OPENCODE_POC.md §13 交叉引用）需在 US-52 AC2（§13 建立）完成後執行
- Architect 評估：US-52 M/2pt 確認，無新 ADR；US-53 S/1pt 確認，ADR-003 NOT triggered for README.md

---

## 工作容量

| 項目 | 數值 |
|------|------|
| Sprint 期間 | 2026-03-09 ~ 2026-03-15（7 天） |
| 總 Stories | 2 |
| 總 Points | 3 |
| 平行分群 | Phase 1（US-52、US-53 全部平行；US-53 AC4 輕量序列化至 US-52 AC2 完成後） |

---

## ADR 觸發清單

| Story | ADR 編號 | 說明 |
|-------|----------|------|
| US-52 | 無 | M size，動態驗證補完與 Issue 關閉，無架構決策需求 |
| US-53 | 無 | ADR-003 NOT triggered（README.md 為說明文件，非 SKILL.md 框架文件） |

**本 Sprint 無新建 ADR。**

---

## Sprint Planning 簽核

- **PO Round 1**：完成（Story 選取：US-52 M/2pt + US-53 S/1pt；Sprint Goal 確定；總計 3pt）
- **Architect Round 1**：完成（US-52 M/2pt 確認，無 ADR；US-53 S/1pt 確認，ADR-003 NOT triggered for README.md；平行分群：Phase 1 全部平行）
- **QA Round 1**：完成（US-52 PASS；US-53 PASS；全部 Stories doc-only 判定：No）
- **PO Round 2**：完成（AC 章節號碼修正：US-52 AC1 §12 Phase 3c、AC2 §13；Sprint Backlog 最終確認）
