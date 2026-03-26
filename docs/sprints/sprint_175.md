# Sprint 175

**Sprint Goal：強化 Hook 基礎建設可靠性與開發標準，並落地 Backlog 水位監控機制 — 交付 Hook 執行超時與隔離機制、Hook 開發標準規範、Hook 整合測試套件，以及 sprint-candidate 水位持續監控流程**

**開始日期**：2026-03-26
**結束日期**：2026-04-02
**容量**：7 pts
**Velocity 基準**：avg 6 pts（Sprint 172=6, Sprint 173=6, Sprint 174=5）

---

## Sprint Backlog

| Story | 標題 | Size | pts | Story Type | Risk Score | Routing Tier | 平行分群 | 狀態 |
|-------|------|------|-----|-----------|-----------|-------------|---------|------|
| US-#923 | feat: Hook 執行超時與隔離機制 | M | 2 | FEATURE | 7 | sonnet | Batch 1 | 待開始 |
| US-#924 | chore: 建立 Hook 開發標準規範 | M | 2 | DOC | 4 | haiku（強制） | Batch 1 | 待開始 |
| US-#925 | test: Hook 整合測試補齊 | M | 2 | TEST | 5 | haiku（強制） | Batch 2 | 待開始 |
| US-#934 | retro: sprint-candidate 水位持續監控與補充機制 | S | 1 | CHORE | 3 | haiku（強制） | Batch 2 | 待開始 |

**總計：7 pts**

---

## 技術評估（Architect）

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | 修改檔案 | 說明 |
|-------|---------|---------|---------|-------------|---------|------|
| US-#923 | M | 無需 ADR | 不適用 | — | `hooks/`（執行腳本 timeout 包裝）、`hooks.json`（timeout config）、`.claude/hooks/execution-metrics.jsonl`（新建） | Hook 執行層新增 timeout + 隔離 + metric 記錄 |
| US-#924 | M | 無需 ADR | 不適用 | — | `docs/guides/hook-development-guide.md`（新建）、`templates/hook-template.sh`（新建） | 純文件輸出，Hook 開發規範指南 |
| US-#925 | M | 無需 ADR | 不適用 | — | `tests/test-hook-integration-suite.sh`（新建） | 新增 Hook 整合測試套件 |
| US-#934 | S | 無需 ADR | 不適用 | — | 監控任務（無固定程式碼修改） | 確認 sprint-candidate >= 10，不足則觸發 Discovery |

**容量確認**：[CAPACITY] avg_velocity=6pts, recommended_capacity=6pts (±20% range: 4-7pts)。7pts 在上限內 ✓

---

## 平行分群策略

- **Batch 1（並行）**：#923 + #924 — 修改不同目錄（hooks/ vs docs/guides/ + templates/），完全並行
- **Batch 2（並行）**：#925 + #934 — #925 新建 tests/，#934 為監控操作，互不衝突
- **四個 Stories 可全部並行執行** ✓

---

## 驗收標準摘要（QA 確認）

### US-#923 Hook 執行超時與隔離機制（QA: PASS）

- AC1：新增 Hook timeout 機制（預設 30s，可配置），超過時限自動 kill 並記錄到 live-log
- AC2：新增 Hook 執行隔離層（trap + background execution），確保一個 Hook 的失敗不影響後續 Hook
- AC3：Hook 執行結果 metric 記錄（成功、失敗、超時），寫入 `.claude/hooks/execution-metrics.jsonl`
- AC4：單元測試 >= 3 個（timeout, isolation, metric recording）
- NFR1（reliability）：Hook timeout 應可配置且有合理預設值
- NFR2（observability）：所有 Hook 執行狀態應自動記錄

### US-#924 建立 Hook 開發標準規範（QA: PASS）

- AC1：建立 `docs/guides/hook-development-guide.md`，包含 Hook 命名慣例、入參/出參約定、error handling 標準
- AC2：定義至少 3 種 Hook 類別（gate hook、settle hook、utility hook）及各自的職責與約定
- AC3：提供可複製的 Hook 範本（`templates/hook-template.sh`）
- AC4：補充至少 5 個現存 Hook 的文件註解（參考新標準）
- NFR1（usability）：指南應包含實際範例與常見陷阱
- NFR2（consistency）：現存 Hook 應逐步遷移至新標準

### US-#925 Hook 整合測試補齊（QA: PASS）

- AC1：建立 `tests/test-hook-integration-suite.sh`，覆蓋至少 8 個主要 Hook（claim, release, file-lock, protect-main 等）
- AC2：測試場景 >= 5 個（單個執行、並行執行、error recovery、cleanup）
- AC3：測試執行時間 <= 30s（NFR）
- AC4：測試覆蓋所有 Hook exit code 路徑（success, error, timeout）
- NFR1（performance）：整個 Hook 整合測試套件執行時間 <= 30s
- NFR2（maintainability）：新增 Hook 時應自動納入整合測試

### US-#934 sprint-candidate 水位持續監控與補充機制（QA: PASS）

- AC1：Sprint 175 Planning 前確認 sprint-candidate >= 10
- AC2：若不足，執行 Backlog Discovery 補充
- NFR1（observability）：水位確認結果應有可追溯記錄（cruise log 或 GitHub comment）

---

## 風險備註

- **#923 regression risk**：timeout 包裝修改現有 Hook 執行行為，需確認不影響正常 Hook 流程。緩解：AC4 單元測試覆蓋 timeout/isolation 路徑
- **#925 執行時間 NFR**：整合測試套件 <= 30s 需在開發時持續驗證
- **#934 retro-action**：若 sprint-candidate 水位不足，需額外執行 Backlog Discovery（可能影響本 Sprint 節奏）— 目前水位 10 個，達標 ✓

---

## QA 隱性需求追問記錄

| Story | 隱性期待 | 建議補充 AC | 嚴重度 | 處置 |
|-------|---------|-----------|-------|------|
| US-#923 | Hook timeout 發生時應有可追溯記錄 | AC5（建議）：timeout 事件寫入 live-log | Minor | 不阻擋，建議 Developer 實作時納入 |
| US-#934 | 監控結果應可見，便於 Stakeholder 驗證 | AC3（建議）：水位確認結果寫入可追溯記錄 | Minor | 已納入 NFR1 |

---

## Routing Tier 交叉審查

| Story ID | Story Type | Risk Score | Routing Tier | 說明 |
|----------|-----------|-----------|-------------|------|
| US-#923 | FEATURE | 7 | sonnet（Tier 2） | 功能實作，需完整推理 |
| US-#924 | DOC | 4 | haiku（強制） | Score 4 + DOC type → haiku 強制路由 |
| US-#925 | TEST | 5 | haiku（強制） | Score 5 + TEST type → haiku 強制路由 |
| US-#934 | CHORE | 3 | haiku（強制） | Score ≤4 → haiku 強制路由 |

**haiku_ratio = 3/4 = 75% ≥ 20%** ✓

---
