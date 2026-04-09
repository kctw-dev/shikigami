# Sprint 182

**Sprint Goal：強化 QA 品質防線三要素 — PO 輸出自律（#994）、API 容錯自動化（#995）、閾值彈性化（#996），加上 Skill 依賴驗證補強（#940）**

**開始日期**：2026-04-10
**結束日期**：2026-04-17
**容量**：6 pts
**Velocity 基準**：avg 6 pts（Sprint 179=6, Sprint 180=6, Sprint 181=6）

---

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 | 負責 | Routing Tier |
|-------|-------|------|--------|------|------|-------------|
| PO Prompt Template 禁用軟性字樣 | #994 | S | 1 | TODO | haiku | haiku（Score 4, PROCESS） |
| rule-ratio-measure.sh 支援 per-prompt THRESHOLD | #996 | S | 1 | TODO | haiku | haiku（Score 4, TOOL） |
| Subagent API Error Fallback | #995 | M | 3 | TODO | sonnet | sonnet（Score 6, PROCESS+ARCH） |
| Skill 依賴宣告一致性驗證 | #940 | S | 1 | TODO | haiku | haiku（Score 4, TEST） |

**總計**：4 Stories / 6 pts

---

## 驗收標準摘要

### #994 PO Prompt Template 禁用軟性字樣

**背景**：Sprint 181 QA Round 1 將 3 個 Story 全部打回 NEEDS_REVISION，理由都是軟性字樣：「考慮阻斷」「明確的升級路徑」等。PO Round 1 輸出的 AC 留有解釋空間，被 agent 利用來自圓其說（正是 Sprint 180 #953 事件的病灶）。

**AC-1：禁用清單建立**
- 修改 `skills/sprint-planning/references/po-prompt.md`
- 新增「## 禁用軟性字樣清單」章節
- 至少包含 8 個詞彙：考慮、明確、適當、合理、盡量、儘可能、必要時、建議（作為 AC 主語時）
- 清單以 Markdown 表格形式呈現，每個詞彙附反例和正例

**AC-2：強制自檢步驟**
- po-prompt.md 的 PO Round 1 輸出流程中加入自檢步驟
- 自檢在輸出 AC 表格前執行
- 自檢腳本：`grep -E "(考慮|明確|適當|合理|盡量|儘可能|必要時|建議)" <(輸出文字)`
- 命中任一詞彙時，禁止輸出，先改寫

**AC-3：改寫規則**
- 檢測到軟性字樣時，改寫為以下三類具體條件之一：
  - **數值條件**：如「>= 10%」「< 30s」
  - **狀態條件**：如「status=completed」「exit code == 0」
  - **路徑條件**：如「檔案 X 存在」「指令 Y 執行成功」

**AC-4：測試驗證**
- 新建 `tests/test-po-prompt-soft-language.sh`
- 測試範例文字（含禁用字樣）→ 斷言偵測到
- 測試範例文字（無禁用字樣）→ 斷言通過
- 測試改寫範例轉換正確

**AC-5：整合驗證**
- 執行 `bash scripts/validate-agents.sh` 通過
- 執行 `bash tests/test-po-prompt-soft-language.sh` 通過

---

### #996 rule-ratio-measure.sh 支援 per-prompt THRESHOLD

**背景**：Sprint 181 #988 的 `delivery-completion-check` 要求規則佔比 >= 30%，但 `rule-ratio-measure.sh` 的預設 THRESHOLD 硬編碼為 0.10，導致工具閾值與 AC 要求不一致。不同 step subagent 應可設定不同門檻。

**AC-1：CLI 參數支援**
- 修改 `scripts/state-machine/rule-ratio-measure.sh`
- 新增 `--threshold <float>` CLI 參數覆蓋預設值
- 範例：`bash rule-ratio-measure.sh --threshold 0.30 prompt.md`
- 參數值範圍驗證：0.0 <= threshold <= 1.0，超出範圍 exit != 0

**AC-2：環境變數支援**
- 新增 `RULE_RATIO_THRESHOLD` 環境變數覆蓋預設值
- 範例：`RULE_RATIO_THRESHOLD=0.30 bash rule-ratio-measure.sh prompt.md`

**AC-3：優先順序**
- CLI `--threshold` > 環境變數 `RULE_RATIO_THRESHOLD` > 預設值 0.10
- 測試驗證三種來源的優先順序

**AC-4：文件更新**
- 新增 `scripts/state-machine/THRESHOLD_GUIDE.md`
- 記錄各 step subagent 建議門檻：
  - `delivery-completion-check`: 0.30
  - `task-list-init`: 0.20
  - 通用 story-lifecycle-prompt: 0.10
- 更新 `skills/sprint-execution/references/step-subagent-contract.md` 引用此文件

**AC-5：Preflight hook 更新**
- 修改 `scripts/state-machine/dispatch-preflight.sh`（Sprint 181 #990 建立）
- 根據被量測的 prompt 檔名或 step type 傳入對應門檻
- 無法判斷 step type 時，使用預設 0.10

**AC-6：測試**
- 擴充 `tests/test-rule-ratio-measure.sh`
- TC1：預設值 → 使用 0.10
- TC2：`--threshold 0.30` → 使用 0.30
- TC3：`RULE_RATIO_THRESHOLD=0.25` → 使用 0.25
- TC4：CLI + ENV 同時設定 → CLI 勝出
- TC5：超出範圍值（-0.1, 1.5）→ exit != 0

---

### #995 Subagent API Error Fallback

**背景**：Sprint 181 Planning 遇到 2 次 opus overload（HTTP 529 / 500），PO Round 2 和 Architect 評估都需要主 session 手動介入。Sprint 182 Planning 本身又遇到 API 拒絕（usage policy），再次手動降級至 sonnet。這是重複發生的問題，需要自動化 fallback 機制。

**設計決策**：Fallback 寫在主 session 派遣層，不在 subagent 自省：subagent 被 API 拒絕後本身無法執行 fallback 指令。

**AC-1：Fallback 策略文件**
- 修改 `skills/sprint-execution/SKILL.md` §2.1 Provider 路由段落後新增 §2.1.1「API Error Fallback 策略」
- 記錄降級決策樹：HTTP 429 路徑 + HTTP 500/529 路徑
- 終止條件：所有重試耗盡後輸出 `[API-FALLBACK-EXHAUSTED]` 並標記 Story=BLOCKED

**AC-2：HTTP 429 路徑（Rate Limit）**
- 指數退避重試同模型：30s → 60s → 120s，最多 3 次
- 3 次失敗後降級至 sonnet 重試 1 次
- sonnet 失敗後 → Story=BLOCKED
- 不再降級至 haiku

**AC-3：HTTP 500/529 路徑（Server Error / Overloaded）**
- 立即降級至 sonnet 重試 1 次（不退避）
- sonnet 失敗 → 指數退避 sonnet：30s → 60s → 120s，最多 3 次
- 3 次全失敗 → Story=BLOCKED

**AC-4：降級 Log 格式**
- 降級事件寫入 stdout + `docs/cruise-logs/model-fallback-<date>.jsonl`
- JSONL schema：`{"timestamp":"ISO8601","story_id":"#N","from_model":"opus","to_model":"sonnet","reason":"HTTP529","retry_count":1}`
- 對應 log action 字串：`[MODEL-FALLBACK] #N from=opus to=sonnet reason=HTTP529`

**AC-5：靜態例外 agent 覆蓋**
- Architect / QA / Security 三個 opus 靜態例外 agent 全部套用此策略
- 在 SKILL.md §2.1.1 明確列出三者的 fallback 路徑表格

**AC-6：測試**
- 新建 `tests/test-api-error-fallback.sh`
- TC1：mock 429 → 斷言退避邏輯觸發
- TC2：mock 529 → 斷言立即降級
- TC3：全部失敗 → 斷言 `[API-FALLBACK-EXHAUSTED]` 輸出
- 使用 TMPBIN + fake Agent tool mock

---

### #940 Skill 依賴宣告一致性驗證

**背景**：validate-skills.sh 驗證 Skill 基本結構，但未檢查 Skill 之間的前置依賴宣告一致性。當 Skill A 宣告依賴 Skill B，但 Skill B 不存在或名稱有誤時，目前無驗證機制。

**AC-1**：建立 `scripts/validate-skill-deps.sh`，掃描所有 Skill 的 `depends_on` 或 `references` 欄位

**AC-2**：驗證被引用的 Skill 均存在（路徑存在性檢查）

**AC-3**：輸出違規報告（file path + 問題描述），整合至 `validate-all.sh`

**NFR-1（completeness）**：掃描所有 Skill 目錄，不遺漏

**NFR-2（performance）**：執行時間 <= 5s

---

## 技術評估摘要

| Story | T-shirt | ADR | 相關檔案 | 平行分群 |
|-------|---------|-----|---------|---------|
| #994 | S | 無需新 ADR | `skills/sprint-planning/references/po-prompt.md` | Wave 1（haiku） |
| #996 | S | ADR-045 補充 | `scripts/state-machine/rule-ratio-measure.sh`, `dispatch-preflight.sh` | Wave 1（haiku） |
| #995 | M | ADR-039 延伸 | `skills/sprint-execution/SKILL.md` §2.1 | Wave 2（sonnet） |
| #940 | S | 無需新 ADR | `scripts/validate-skill-deps.sh`, `validate-all.sh` | Wave 2（haiku） |

---

## Wave 規劃

> **SHIKIGAMI_MAX_PARALLEL=2**

**Wave 1（平行，haiku）**：
- #994 PO Prompt Template 禁用軟性字樣（修改 `po-prompt.md`）
- #996 rule-ratio-measure.sh 支援 per-prompt THRESHOLD（修改 `rule-ratio-measure.sh` + `dispatch-preflight.sh`）
- 兩者修改不同目錄，可安全平行（worktree 各自獨立）

**Wave 2（平行）**：
- #995 Subagent API Error Fallback（sonnet，修改 `SKILL.md` §2.1）
- #940 Skill 依賴宣告一致性驗證（haiku，新建 `validate-skill-deps.sh`）
- #995 修改 SKILL.md，#940 修改 scripts 目錄，範圍不重疊，可平行

---

## Risk Notes

- **#995 SKILL.md 衝突風險**：#995 修改 `skills/sprint-execution/SKILL.md` §2.1，Sprint 181 #989/#988 均修改 §3 line 418 區塊。§2.1 與 §3 不同段落，但執行前需 `git pull` 確認 base 為最新 main，避免 merge 時誤觸已有的 §3 修改。
- **#996 依賴 #990 的 dispatch-preflight.sh**：Sprint 181 #990 已建立 `dispatch-preflight.sh`，#996 AC-5 需修改此檔。執行前確認 PR#993 已合入 main。
- **API 拒絕活案**：Sprint 182 Planning 本身遇到 opus usage policy 拒絕，手動降級至 sonnet。#995 的設計決策（fallback 在主 session 派遣層）已由此次事件驗證。
- **#940 驗證腳本 validate-all.sh 整合**：需確認 `validate-all.sh` 是否已存在，若無則建立該腳本並整合所有 validate-*.sh。

---

## Sprint Review 結果

（待填入）
