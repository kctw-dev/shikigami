# Sprint 80

**Sprint Goal**：Anti-Hallucination 第一步 — 建立 Agent 不確定性前置檢查機制，同步啟動 Discovery Phase 架構調查

**期間**：2026-03-11 ~ 2026-03-18
**狀態**：進行中
**ADR 依賴**：無（ADR-017 由 Architect 平行撰寫中，不阻塞本 Sprint）

---

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 | 備註 |
|-------|-------|------|--------|------|------|
| US-214：不確定性前置檢查 — Agent 執行前強制假設列舉與驗證 | #215 | M | 2 | 待開始 | doc-only, FEATURE |
| US-215：Discovery Phase RESEARCH Spike — 架構方案調查與 ADR-018 草稿 | #217 | M | 2 | 待開始 | doc-only, RESEARCH |

**Sprint 容量**：4 points

---

## Story 定義

### US-214：不確定性前置檢查 — Agent 執行前強制假設列舉與驗證（M, 2pt, FEATURE, doc-only）

**Issue**：#215
**主要修改**：`skills/sprint-execution/story-lifecycle-prompt.md`

**AC1**：story-lifecycle-prompt.md 的「開始前準備」區段新增第 7 步「不確定性三問檢查」，subagent 在讀取 AC 後、進入 doc_only/TDD 路徑判斷前，必須強制輸出三問回答：(1) 我的假設是什麼？(2) 哪些地方我不確定？(3) 我需要查什麼才能繼續？格式為結構化清單。

**AC2**：定義「腦補行為」的可觀測 FAIL 條件 — 若 subagent 三問輸出中第 (2) 項回答「無」且第 (3) 項回答「無」，但後續 Spec Compliance self-review 出現 FAIL，則回溯判定為「腦補行為」，在輸出摘要中標記 `[ASSUMPTION-VIOLATION]`。

**AC3**：不確定性標記格式規範 — 不確定項目以 `[UNCERTAIN]` 標記，附帶驗證方式。subagent 必須在進入 TDD/doc-only 路徑前完成所有 `[UNCERTAIN]` 項目驗證，未驗證項目存在時禁止繼續。

**AC4**：三問與現有流程交互明確 — (a) TDD 路徑：三問在 Red 之前執行；(b) doc-only：同樣必須執行三問（不豁免）；(c) 不取代 Spec Compliance self-review。

**AC5**：三問輸出在 subagent 回傳摘要中可見 — §9 輸出格式新增 `uncertainty_check` 區塊。

### US-215：Discovery Phase RESEARCH Spike — 架構方案調查與 ADR-018 草稿（M, 2pt, RESEARCH, doc-only）

**Issue**：#217
**主要修改**：`docs/adr/ADR-018.md`（新建）

**AC1**：產出 `docs/adr/ADR-018.md` 草稿，遵循 ADR 格式，至少含兩個選項：(a) 獨立 Discovery Skill；(b) 擴充現有 backlog-management Skill。

**AC2**：ADR-018 含差異分析表格（至少 3 個比較維度），區分現有 backlog-management §2 與提案 Discovery Phase。

**AC3**：每個選項含 Product Brief 格式建議、PO 確認關卡定義、優劣分析。

**AC4**：ADR-018 狀態為 `Proposed`（草稿），不做最終決策。

---

## 退回 Backlog 的 Story

- **#216（Knowledge Ingestion）**：ADR-017 Hard Gate 阻塞，退回 Backlog。Architect 將在 Sprint 80 期間平行撰寫 ADR-017。

---

## 平行分群建議

### 完全平行（無檔案衝突）
| Story | Size | 說明 |
|-------|------|------|
| US-214 | M | 修改 story-lifecycle-prompt.md，與 ADR-018 無交集 |
| US-215 | M | 新建 ADR-018.md，與 story-lifecycle-prompt.md 無交集 |

兩個 Story 修改的檔案完全不同，可由兩個 subagent 完全平行執行。

---

## 權重調整記錄

快思模式，跳過權重調整
