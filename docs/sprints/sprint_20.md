# Sprint 20

**狀態**：進行中
**期間**：2026-03-02 ~ 2026-03-08
**Sprint Goal**：清零 Sprint 19 Retro Action Items（#56、#57），交付 /shoot 短衝模式（US-31）
**總計**：3 Stories / 5 Points

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| Retro #56（Issue #56） | 修復 test-schedule.sh assert_contains SIGPIPE 非確定性失敗 | S | 1 | 待開始 |
| Retro #57（Issue #57） | Developer subagent 狀態更新衝突防護 | S | 1 | 待開始 |
| US-31（Issue #47） | /shoot 短衝模式 | L | 3 | 待開始 |

**Sprint 容量**：5 Points

---

## Story 詳細 AC

---

### Retro #56（Issue #56）：修復 test-schedule.sh assert_contains SIGPIPE 非確定性失敗

**來源**：Sprint 19 Retrospective
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As a Developer, I want test-schedule.sh to run reliably without SIGPIPE-induced non-deterministic failures, so that CI validation results are trustworthy and false negatives no longer block Sprint execution.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | SIGPIPE 根因修正 | `assert_contains` 函式或其呼叫端修正管線寫入競態問題；修正方式（捕捉 SIGPIPE、改用非管線方案、或其他）需在 commit message 中說明 |
| AC2 | [動態] | 連續執行 10 次零失敗 | `test-schedule.sh` 連續執行 10 次，所有執行結果均為通過，exit code 為 0，不出現 SIGPIPE 或 Broken pipe 錯誤訊息 |
| AC3 | [靜態] | 無迴歸 | 修正後 test-schedule.sh 覆蓋的其他測試案例全部維持通過，不引入新的失敗 |

---

### Retro #57（Issue #57）：Developer subagent 狀態更新衝突防護

**來源**：Sprint 19 Retrospective
**Size**：S / 1 Point
**Owner**：Architect

**User Story**
As a Scrum Master, I want Developer subagent state updates to be protected from race conditions when multiple subagents run in parallel, so that the main session's already-updated story status is never silently overwritten.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 衝突偵測機制定義 | `skills/sprint-execution/SKILL.md` 新增「狀態更新衝突防護」段落，明確定義偵測機制：Developer subagent 更新狀態欄前，必須先讀取目前檔案中該 Story 的狀態值（read-then-compare），若已非預期值（例如已被標記為完成或 FAIL），則輸出衝突警告並放棄寫入，不得靜默覆蓋 |
| AC2 | [靜態] | 可觀察的衝突指示 | SKILL.md 明確定義衝突發生時的三個可觀察指示：(a) 輸出精確字串「[CONFLICT] 狀態衝突，跳過覆蓋：{story_id} 當前值={actual}，預期值={expected}」；(b) subagent 不執行任何檔案寫入；(c) 主 session 回傳 subagent 輸出時可從 log 中識別衝突事件 |
| AC3 | [動態] | 衝突場景驗收 | 模擬平行派遣情境：先手動將某 Story 狀態改為「完成」，再執行 Developer subagent 嘗試將同一 Story 改回「進行中」，確認 subagent 輸出含衝突警告字串且 sprint_N.md 中該 Story 狀態維持「完成」不被覆蓋 |

---

### US-31（Issue #47）：/shoot 短衝模式

**來源**：Sprint 17 Retrospective + Stakeholder 回饋
**Size**：L / 3 Points
**Owner**：Developer

**User Story**
As a framework user, I want a `/shoot` command that executes a single task without full Sprint ceremony, so that I can deliver small improvements quickly without the overhead of Planning, Review, and Retrospective.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 自動抓取模式 | 執行 `/shoot`（無參數）時，依優先順序抓取：(1) `bug` label open Issue → (2) `retro-action` label open Issue → (3) PRODUCT_BACKLOG.md 頂部 Size=S Story。三者均無時輸出錯誤訊息並終止。SKILL.md 自動抓取邏輯可靜態審查，動態測試覆蓋三層優先順序與 fallback 情境 |
| AC2 | [靜態] | 直接描述模式 | `/shoot "任務描述"` 將文字作為任務標題直接執行，描述完整保留至 Shoot_Log.md。靜態審查參數解析規則；動態確認記錄標題未被截斷或修改 |
| AC3 | [靜態] | GitHub Issue 模式 | `/shoot #N` 透過 `gh issue view` 取得 Issue 標題與描述執行；Issue 不存在或 gh CLI 未認證時輸出錯誤並終止。靜態審查錯誤處理流程；動態測試有效與無效 Issue 編號 |
| AC4 | [靜態] | Backlog Story 模式 | `/shoot US-XX` 從 PRODUCT_BACKLOG.md 讀取對應 Story 執行；找不到 Story ID 時輸出錯誤並終止。靜態審查 Story ID 比對邏輯；動態測試有效與無效 Story ID |
| AC5 | [靜態] | 文件產出完整性 | 每次完成後同時更新 (a) `docs/km/Shoot_Log.md`（日期/來源/標題/結果/commit hash）(b) `docs/PROJECT_BOARD.md`「短衝記錄」區塊。git commit 以 `shoot:` 前綴。確認兩份文件均更新且欄位完整，commit message 前綴正確 |
| AC6 | [靜態] | 瘦身歸檔（修訂版）| Shoot_Log.md 主文件超過 20 筆記錄時，將最舊記錄**移至恰好保留 20 筆**（即移走 `筆數 - 20` 筆），移出的記錄附加至 `docs/km/archive/SHOOT_LOG_ARCHIVE.md`，並更新 archive/README.md。邊界測試情境：(a) 恰好 20 筆 — 不觸發歸檔；(b) 21 筆 — 移出 1 筆，主文件剩 20 筆；(c) 25 筆 — 移出 5 筆，主文件剩 20 筆；(d) 26 筆 — 移出 6 筆，主文件剩 20 筆 |
| AC7 | [靜態] | Sprint Review 連動 | `skills/sprint-review/SKILL.md` 新增掃描 Shoot_Log.md 步驟，將 Sprint 期間短衝記錄列入「Sprint 外完成項目」區塊，不計入 Velocity。無記錄時輸出「本 Sprint 無短衝記錄」。確認 sprint-review SKILL.md 含掃描步驟；動態測試有/無短衝記錄兩種情境 |
| AC8 | [靜態] | Hard Gate 保留（修訂版）| QA 雙階段審查 + Architect 技術審查必須保留，任一 FAIL 時終止。FAIL 場景三個可觀察驗收點：(a) exit code 非 0（process 以錯誤碼結束）；(b) Shoot_Log.md 中該次任務無 PASS 記錄（log 筆數不增加）；(c) 不執行 `shoot:` 前綴的 git commit（commit 狀態為未提交）。明確跳過 Planning/Review/Retro/Metrics |

---

## 平行分群（Architect 建議）

### Phase 1（可平行執行）

| Story | 負責人 |
|-------|--------|
| Retro #56（Issue #56） | Developer |
| Retro #57（Issue #57） | Architect |

### Phase 2（序列，Phase 1 完成後執行）

| Story | 負責人 | 前置條件 |
|-------|--------|----------|
| US-31（Issue #47） | Developer | Phase 1 全部完成 |

---

## 工作容量

| 項目 | 數值 |
|------|------|
| Sprint 期間 | 2026-03-02 ~ 2026-03-08（7 天） |
| 總 Stories | 3 |
| 總 Points | 5 |
| Phase 1 容量 | 2 Points（可平行） |
| Phase 2 容量 | 3 Points（序列） |

---

## ADR 觸發清單

| Story | ADR 需求 | 說明 |
|-------|----------|------|
| Retro #56 | 無 | 純修正測試腳本，不涉及架構決策 |
| Retro #57 | 無 | 流程指引修改，不涉及技術選型 |
| US-31 | 無 | Architect 評估：新建 Skill 採既有模式，無需新 ADR |

---

## Sprint Planning 簽核

- **PO Round 1**：完成（Story 選取、初版 AC）
- **Architect Round 1**：完成（估點確認：5pt；無 ADR 觸發；平行分群建議）
- **QA Round 1**：完成（Retro #57 AC 修訂要求；US-31 AC6/AC8 修訂要求）
- **PO Round 2**：完成（AC 修訂完成，Sprint 文件建立）
