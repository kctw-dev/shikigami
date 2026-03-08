# SKILL.md 減法審查報告

**審查日期**：2026-03-08
**審查範圍**：skills/*/SKILL.md（25 個檔案）
**審查策略**：重點審查高冗餘風險檔案（sprint-planning、sprint-execution、sprint-review、scrum-master、qa-engineer、architect）+ 跨檔關鍵字比對（Grep 搜尋 Hard Gate、Commit+Push、Token 記錄、doc-only、ADR-003、DoD、安全審查觸發條件）

---

## 識別項目

### 項目 1：Token 記錄步驟三重重複

- **所在檔案**：
  - `skills/sprint-planning/SKILL.md`
  - `skills/sprint-execution/SKILL.md`
  - `skills/sprint-review/SKILL.md`
- **段落引用**：
  - `sprint-planning/SKILL.md` 行 50–70（`## 2. 流程 Checklist` — Token Baseline Snapshot 步驟 + Token 消耗記錄步驟）
  - `sprint-execution/SKILL.md` 行 112–116（步驟 0：Execution Baseline Snapshot）、行 221–225（Execution Token 消耗記錄）
  - `sprint-review/SKILL.md` 行 745–749（`## 流程 Checklist` — Review Token 消耗記錄步驟）
- **冗餘理由**：三個檔案各自內嵌了幾乎完全相同的 Token 計算操作說明，包含：
  1. 讀取 `~/.claude/projects/` JSONL 檔案的具體步驟
  2. 完全相同的公式說明：「有效 input tokens = input_tokens + cache_read_input_tokens + cache_creation_input_tokens」
  3. 相同的降級方法文字：「若 JSONL 檔案不存在……各 token 欄填『N/A』……輸出精確字串『Token 資料不可用，需手動補充』」

  這三段重複的操作說明若日後需修改（例如路徑變更或公式調整），必須同步修改三個位置，維護成本高且容易產生版本不一致。
- **建議動作**：後續 Sprint 可將 Token 記錄操作規格抽取至獨立的 `skills/sprint-execution/token-recording-spec.md`（或 `docs/km/` 下的參考文件），三個 SKILL.md 僅保留精簡的「*(慢想模式限定)：參照 token-recording-spec.md 執行*」引用。

---

### 項目 2：Definition of Done（DoD）表格跨檔重複

- **所在檔案**：
  - `skills/scrum-master/SKILL.md`
  - `skills/sprint-execution/SKILL.md`
- **段落引用**：
  - `scrum-master/SKILL.md` 行 284–297（`## 8. Definition of Done（DoD）`）
  - `sprint-execution/SKILL.md` 行 372–386（`## 6. DoD 自檢`）
- **冗餘理由**：兩個表格包含完全相同的 8 個 DoD 條件（功能、測試、安全、文件、設定、度量、反回歸、技術債），且各欄內容措辭幾乎一字不差。唯一差異是 `sprint-execution/SKILL.md` 多了「自檢」欄位（checkbox `[ ]`）。

  在兩個獨立 SKILL.md 中維護語義相同的規範，增加了未來兩份文件內容分歧的風險。例如若新增一個 DoD 條件（如「無 accessibility 回歸」），容易只更新其中一個，造成不一致。
- **建議動作**：後續 Sprint 可指定 `scrum-master/SKILL.md` 為 DoD 唯一定義來源（Single Source of Truth），`sprint-execution/SKILL.md` §6 改為引用：「DoD 自檢條件定義請參照 `skills/scrum-master/SKILL.md` §8，以下為執行時 checkbox 格式：{列出 checkbox}」，或直接引用連結。

---

### 項目 3：安全審查觸發條件清單在 sprint-execution 內部重複

- **所在檔案**：
  - `skills/sprint-execution/SKILL.md`
  - `skills/sprint-execution/story-lifecycle-prompt.md`
- **段落引用**：
  - `sprint-execution/SKILL.md` 行 410–418（`## 8. 安全審查觸發條件`）
  - `sprint-execution/story-lifecycle-prompt.md` 行 248–253（`### 觸發條件` 下的清單）
- **冗餘理由**：兩個檔案中「安全審查觸發條件」的五個條目完全相同：
  1. Story 涉及外部使用者輸入處理
  2. 新增或修改 API 端點
  3. 涉及認證 / 授權邏輯
  4. 涉及加密 / 金鑰管理
  5. 涉及配置變更或環境變數

  `SKILL.md` §8 是主 session 層級的觸發說明，`story-lifecycle-prompt.md` 是 subagent 內部的觸發說明，兩者描述的是同一套規則。若觸發條件需要修改（例如新增「涉及個資處理」），需要在兩個檔案分別修改，且 `SKILL.md` §8 本身更像是「摘要提醒」，實際執行者是 subagent（參照 `story-lifecycle-prompt.md`），因此 `SKILL.md` 的重複說明產生的是噪音而非價值。
- **建議動作**：後續 Sprint 可將 `sprint-execution/SKILL.md` §8 精簡為一句話引用：「安全審查觸發條件與判斷邏輯定義於 `story-lifecycle-prompt.md` §7，主 session 層級的觸發入口為 ESCALATE: SECURITY_CRITICAL 回傳值。」刪除重複的五條清單。

---

### 項目 4：ADR-007 Phase 2 靜態驗收清單已過時（功能已完成）

- **所在檔案**：`skills/sprint-execution/SKILL.md`
- **段落引用**：行 442–516（`## 11. ADR-007 Phase 2 靜態驗收清單`）
- **冗餘理由**：此段落（75 行）是 Sprint 24 / US-41 實作 ADR-007 Phase 2 時所建立的「建置時一次性驗收清單」，供 QA 在該 Sprint 驗收時使用。功能已在 Sprint 24 完成交付，驗收清單本身已完成其歷史使命。

  目前這 75 行的靜態 checkbox 清單（包含 a–f 六個驗收子項）仍留在 SKILL.md 中，但在日常 Sprint 執行中沒有人需要逐項勾選它（它描述的是「文件是否存在特定段落」，而非每次執行的操作步驟）。這 75 行佔 SKILL.md 總行數（515 行）的 14.6%，是顯著的「歷史殘留」。

  進一步確認：此段落以 HTML 注釋 `<!-- ADR-007 Phase 2 實作 — Sprint 24 / US-41 AC5 -->` 開頭，明確標示其為特定 Sprint 的產物；且其唯一用途是「供 QA Engineer 在 Sprint Review 時逐項靜態核對」，但 Sprint 24 的 Sprint Review 早已完成。
- **建議動作**：後續 Sprint 可將 §11 整段移除，或改為一行歷史記錄：「ADR-007 Phase 2 外部抽樣審查機制已於 Sprint 24 US-41 完成實作並通過 QA 驗收，詳見 `docs/adr/ADR-007-story-lifecycle-subagent.md`。」

---

### 項目 5：Commit + Push 規範在三個 SKILL.md 中各自重複描述

- **所在檔案**：
  - `skills/sprint-planning/SKILL.md`
  - `skills/sprint-execution/SKILL.md`
  - `skills/sprint-review/SKILL.md`
- **段落引用**：
  - `sprint-planning/SKILL.md` 行 190–200（`### Commit + Push 規範`）、行 71（Checklist 中的引用）
  - `sprint-execution/SKILL.md` 行 227–233（「更新完成後，立即執行 git commit + git push」）
  - `sprint-review/SKILL.md` 行 754–758（「產出文件完成最後修改後，立即執行 git commit + git push」）
- **冗餘理由**：三個 SKILL.md 各自描述「只 commit Sprint 狀態文件，其他 KM 文件不適用，否則觸發 ADR-003 Out-of-Sprint Hard Gate」的相同規範，且每次都包含幾乎相同的長段落說明（哪些檔案適用、哪些不適用）。

  `sprint-planning/SKILL.md` §5 Commit + Push 規範段落（行 190–200）的說明文字與 `sprint-review/SKILL.md` 行 754 括弧說明高度重疊，解釋的是同一條規則（Sprint 狀態文件立即 commit；KM 文件不適用）。重複定義同一規範三次，造成「哪裡是權威來源」不清晰。
- **建議動作**：後續 Sprint 可在 `skills/git-workflow/SKILL.md` 或 `skills/scrum-master/SKILL.md` 建立統一的「Sprint 文件 Commit + Push 規範」段落，三個 SKILL.md 各自以一行「*(參照 git-workflow/SKILL.md §Sprint Commit 規範)*」引用，刪除冗長的重複說明。

---

## 摘要統計

| 項目 | 類型 | 涉及檔案數 | 估計可刪除行數 |
|------|------|-----------|--------------|
| 項目 1：Token 記錄步驟 | 跨檔重複 | 3 | ~30 行（合併後） |
| 項目 2：DoD 表格 | 跨檔重複 | 2 | ~15 行 |
| 項目 3：安全審查觸發條件 | 同目錄重複 | 2 | ~10 行 |
| 項目 4：ADR-007 Phase 2 靜態驗收清單 | 過時步驟 | 1 | ~75 行 |
| 項目 5：Commit + Push 規範 | 跨檔重複 | 3 | ~20 行 |

**識別總計：5 處冗餘，估計可精簡約 150 行（主要由項目 4 貢獻）**

---

## 審查限制說明

本次審查使用「重點檔案 + Grep 跨檔比對」策略，未逐行讀取全部 25 個 SKILL.md。以下檔案未深入審查（預期冗餘風險較低）：

- `skills/escalation/SKILL.md`
- `skills/git-workflow/SKILL.md`
- `skills/security-review/SKILL.md`
- `skills/quality-gate/SKILL.md`
- `skills/parallel-dispatch/SKILL.md`
- `skills/systematic-debugging/SKILL.md`
- `skills/dispel/SKILL.md`
- `skills/shoot/SKILL.md`（已快速掃描 Hard Gate 引用）
- `skills/architecture-decision/SKILL.md`
- `skills/health-check/SKILL.md`
- `skills/deployment-readiness/SKILL.md`
- `skills/diagram/SKILL.md`
- `skills/backlog-management/SKILL.md`
- `skills/schedule/SKILL.md`
- `skills/onboarding/SKILL.md`
- `skills/issue-management/SKILL.md`
- `skills/ux-agent/SKILL.md`
- `skills/ui-agent/SKILL.md`
- `skills/vision-critic/SKILL.md`
