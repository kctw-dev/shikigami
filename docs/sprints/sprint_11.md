# Sprint 11

> 週期：2026-03-01 ~ 2026-03-08
> 狀態：進行中
> 專案等級：low（完全自治）

---

## Sprint Goal

**「導入 Scrum Master 零讀取架構，讓主 session context 瘦身，同步清零 Sprint 10 Retro Action Item，為 Token 成本大幅下降奠定結構基礎。」**

US-25（RICE 45.0, Must）為本 Sprint 核心——三個 SKILL.md 改為「主 session 不讀檔」架構，所有讀取由 subagent 處理。Retro #20（Must）先行完成 token 記錄指引更新，確保 US-25 在已穩定的 SKILL.md 上操作。US-S02（Should）修正 standup 對框架 repo 的假陽性 CRITICAL。

對應 ROADMAP：M5「穩定化」。

---

## Sprint Backlog

| Story | 任務 | 負責 | 狀態 | QA Review | 平行組 |
|---|---|---|---|---|---|
| Retro #20：SKILL.md token 記錄指引更新為 JSONL 提取 | 3 個 SKILL.md token 指引段落更新 | Developer | 待開始 | — | Phase 1-A |
| US-S02：Standup 健康快篩框架 Repo 誤判修正 | commands/standup.md 新增 plugin.json 判斷 | Developer | 待開始 | — | Phase 1-B |
| US-25：Scrum Master 零讀取架構 | 3 個 SKILL.md subagent 調度重構 | Developer | 待開始 | — | Phase 2（依賴 Phase 1） |

---

## 工作容量

| 指標 | 數值 |
|------|------|
| 計畫 Stories | 3 |
| 計畫 Points | 4（1S + 1M + 1S） |
| 近 3 Sprint 平均 Velocity | 5.7pt |
| 緩衝率 | 70%（保守，因 US-25 需 ADR-003 Checklist） |

---

## 執行順序

```
Phase 1（平行派遣）：
  Subagent A — Retro #20（修改 3 個 SKILL.md 的 token 指引段落）
  Subagent B — US-S02（修改 commands/standup.md 新增 plugin.json 判斷）

Phase 2（序列，Phase 1 commit 後）：
  Subagent C — US-25（在已更新的 3 個 SKILL.md 基礎上進行零讀取架構改造）
```

**平行化理由**：Retro #20 與 US-S02 修改不同檔案（skills/*.md vs commands/standup.md），無衝突。US-25 與 Retro #20 修改相同 3 個 SKILL.md，必須序列。

---

## 精化後 Acceptance Criteria

### Retro #20：SKILL.md token 記錄指引更新為 JSONL 提取

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | Token 記錄區段更新 | 以下 3 個 SKILL.md 的 token 記錄指引段落（僅限 token 記錄相關內容，不修改 subagent 架構描述）更新為：（一）主要方法：從 `~/.claude/projects/` 目錄下對應的 JSONL 檔案提取 `message.usage` 欄位；（二）降級方法（標注為次選）：若 JSONL 不可存取，改為手動輸入或填「N/A」；（三）降級觸發條件：明確說明何種情況切換至手動方式 |
| AC2 | [靜態] | 降級標注格式一致性 | 三個段落的降級方法均以明確的次選標注呈現，與主要方法在視覺上可區分 |
| AC3 | [動態] | Issue #20 關閉 | 執行 `gh issue view 20 --json state` 確認 state 為 "closed" |

修改檔案（限定範圍）：
- `skills/sprint-planning/SKILL.md` — token 記錄指引段落
- `skills/sprint-execution/SKILL.md` — token 記錄指引段落
- `skills/sprint-review/SKILL.md` — token 記錄指引段落

### US-25：Scrum Master 零讀取架構

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | sprint-planning 零讀取 | `skills/sprint-planning/SKILL.md` 的 Subagent 派遣說明更新：（一）PO subagent prompt 指定 PRODUCT_BACKLOG.md、ROADMAP.md、PROJECT_BOARD.md 完整路徑，由 subagent 自行讀取；（二）主 session 流程中不出現對上述檔案的 Read 指引；（三）subagent 回傳結構化摘要（Markdown 表格：Story ID / 標題 / 估點 / AC 確認結果） |
| AC2 | [靜態] | sprint-execution 零讀取 | `skills/sprint-execution/SKILL.md` 修改：Developer / QA / Security subagent 的派遣 prompt 指定需讀取的檔案路徑，主 session 步驟說明中刪除任何預讀指引；subagent 回傳格式限定為狀態 + 結論（PASS/FAIL + 一句話摘要） |
| AC3 | [靜態] | sprint-review 零讀取 | `skills/sprint-review/SKILL.md` 修改：Retro Analytics、PO Demo、Stakeholder 確認等步驟由 subagent 讀取所需檔案（Retrospective_Log.md、Metrics_Log.md、sprint_N.md 等）；主 session 不直接讀取這些檔案 |
| AC4 | [動態] | context 瘦身驗證 | 量測 Sprint：Sprint 12（US-25 實施後首個完整 Sprint）。量測方法：從 JSONL 提取主 session `cache_read_input_tokens` 加總。基準：Sprint 10 = 104M。通過條件：Sprint 12 < 41.6M（下降 60%） |

### US-S02：Standup 健康快篩框架 Repo 誤判修正

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 框架 Repo 偵測 | 修改 `commands/standup.md`（非 skills/standup/SKILL.md）「區塊零：健康快篩」的「檢查 1：必要文件存在性」：在現有檢查之前新增前置判斷——若 `./plugin.json` 存在，跳過 `CLAUDE.md` 檢查，將 CLAUDE.md 結果標記為 PASS 並附加說明「（框架 Repo，CLAUDE.md 檢查略過）」 |
| AC2 | [動態] | 消費端不受影響 | 在無 `plugin.json` 的專案中執行 standup，CLAUDE.md 缺失時仍出現 CRITICAL |
| AC3 | [動態] | 框架端正向驗證 | 在含 `plugin.json` 且缺少 `CLAUDE.md` 的 repo 中執行 standup，輸出不含「CLAUDE.md 缺失」，且快篩結果為 HEALTHY（若無其他 FAIL） |

---

## 權重調整記錄

歷史趨勢穩定，無需調整。

分析基礎：最近 2 個完成 Sprint（Sprint 9、Sprint 10）的 Problem 區塊。Sprint 9 有 1 條 QA 關鍵字匹配（"Code Quality Review"），Sprint 10 無 QA 相關 Problem。連續 2 Sprint 門檻未達，QA Review 維持 Should 等級。

---

## ADR 前提

| Story | ADR 需求 | 狀態 |
|-------|---------|------|
| Retro #20 | ADR-003 Checklist（修改 skills/ 下 .md） | ✅ Accepted |
| US-25 | ADR-003 Checklist（修改 3 個 SKILL.md） | ✅ Accepted |
| US-S02 | ADR-003 Checklist（修改 commands/ 下 .md） | ✅ Accepted |

無需建立新 ADR。

---

## Token 記錄

| 環節 | Token | 備註 |
|------|-------|------|
| Planning | N/A | Token 資料不可用，需手動補充 |
