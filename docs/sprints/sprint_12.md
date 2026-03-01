# Sprint 12

> 週期：2026-03-08 ~ 2026-03-15
> 狀態：Execution 完成，Review 待執行
> 專案等級：low（完全自治）

---

## Sprint Goal

**「修正 health-check 架構對齊、完成 US-25 AC4 零讀取效果量測、強化 QA 路徑驗證，讓 M5 穩定化的架構完整性與流程品質收斂。」**

Issue #23 修正 health-check SKILL.md 為 subagent 模式，與零讀取架構對齊。Retro #22 量測 US-25 AC4 的 cache_read_input_tokens 降幅，驗證 Sprint 11 架構改造的實際效果。US-24 AC3/AC4 量測 Sprint 12 Planning 的 API call 數量與 token 成本降幅，與 Sprint 10 基準對比。Retro #21 強化 QA 路徑驗證步驟，確保 AC 路徑可信。

對應 ROADMAP：M5「穩定化」。

---

## Sprint Backlog

| Story | 任務 | 負責 | 狀態 | QA Review | 平行組 |
|---|---|---|---|---|---|
| Retro #21：Sprint Planning QA 精化 — AC 路徑驗證步驟 | `skills/sprint-planning/SKILL.md` §6 QA 條目新增路徑驗證規則 | Developer | 完成 (QA PASS) | PASS | Phase 1（平行） |
| Retro #22：US-25 AC4 量測 — cache_read_input_tokens < 41.6M | Sprint 12 Review 從 JSONL 提取 cache_read_input_tokens，填入 Metrics_Log.md | Developer | 完成（待量測） | PASS | Phase 1（平行） |
| Issue #23：health-check SKILL.md 零讀取架構對齊 | `skills/health-check/SKILL.md` §4 改寫為 subagent 模式 | Developer | 完成 (QA PASS) | PASS | Phase 1（平行） |
| US-24 AC3/AC4：Subagent Token 成本優化量測 | 量測 Sprint 12 Planning message 物件數 + token 降幅 | Developer | 完成（待量測） | PASS | Phase 1（平行） |

---

## T-shirt Size / Points 摘要

| Story | Size | Points | 備註 |
|-------|------|--------|------|
| Retro #21：Sprint Planning QA 精化 — AC 路徑驗證步驟 | S | 1 | 純靜態文件修改 |
| Retro #22：US-25 AC4 量測 | S | 1 | 純量測，無檔案異動 |
| Issue #23：health-check SKILL.md 零讀取架構對齊 | S | 1 | 單一 SKILL.md 改寫 |
| US-24 AC3/AC4：Subagent Token 成本優化量測 | S | 1 | Architect 調降 from M（純量測） |
| **合計** | — | **4** | 低於近期平均 5.6pt，保守合理（量測密集型 Sprint） |

---

## 工作容量

| 指標 | 數值 |
|------|------|
| 計畫 Stories | 4 |
| 計畫 Points | 4（4 × S） |
| 近 3 Sprint 平均 Velocity | 5.6pt（Sprint 9: 5、Sprint 10: 6、Sprint 11: 4） |
| 緩衝率 | 71%（保守，量測類 Story 依賴 JSONL 可得性，存在 SKIPPED 風險） |

**容量決策說明**：4 個 S-size Story 全部可平行執行，無檔案衝突。Retro #22 與 US-24 AC3/AC4 為純量測，依賴 JSONL 資料可得性；若資料不可得，AC 均定義了 SKIPPED 降級路徑，不阻塞 Sprint 結案。

---

## 執行順序（平行化分析）

```
Phase 1（全部平行派遣，無檔案衝突）：
  Subagent A — Retro #21（修改 skills/sprint-planning/SKILL.md）
  Subagent B — Retro #22（純量測，無檔案修改）
  Subagent C — Issue #23（修改 skills/health-check/SKILL.md）
  Subagent D — US-24 AC3/AC4（純量測，無檔案修改）
```

**平行化理由（Architect 確認）**：
- Retro #21 修改 `skills/sprint-planning/SKILL.md`
- Issue #23 修改 `skills/health-check/SKILL.md`
- Retro #22 與 US-24 AC3/AC4 為純量測，不修改任何檔案
- 四者之間無檔案衝突，可完全平行執行

**Architect 附加說明**：Issue #23 需定義 subagent 失敗時的 fallback 策略（AC3 已納入：輸出 Overall Status: UNKNOWN，不降級讀取）。Retro #22 與 US-24 AC3/AC4 共享 Sprint 10 基準值，須於 Sprint 12 Review 時並排呈現。

---

## 精化後 Acceptance Criteria

### Retro #21：Sprint Planning QA 精化 — AC 路徑驗證步驟

| # | AC | 類型 |
|---|-----|------|
| AC1 | `skills/sprint-planning/SKILL.md` §6 QA 條目新增規則：若 Story AC 包含具體檔案路徑，QA 須執行 Glob/ls 存在性確認，回報 `Path verification: PASS / FAIL / N/A` | [靜態] |
| AC2 | 路徑 FAIL 時，QA 標記 NEEDS_REVISION，Story 退回 PO 修正 | [靜態] |
| AC3 | 不引用路徑時填 N/A | [靜態] |

**修改檔案（限定範圍）**：`skills/sprint-planning/SKILL.md`

---

### Retro #22：US-25 AC4 量測 — cache_read_input_tokens < 41.6M

| # | AC | 類型 |
|---|-----|------|
| AC1 | Sprint 12 Review 從 JSONL 提取 cache_read_input_tokens 加總，填入 Metrics_Log.md，以表格呈現與 Sprint 10 基準對比 | [動態] |
| AC2 | 通過：cache_read_input_tokens < 41.6M（相較 Sprint 10 基準 104M，60% 降幅） | [動態] |
| AC3 | JSONL 不可得時填 N/A + 精確字串「Token 資料不可用，需手動補充」，判定 SKIPPED（下 Sprint 補測）| [靜態] |

**基準值確認**：Sprint 10 `cache_read_input_tokens` = **104M**（來源：US-25 AC4 設計文件，Metrics_Log.md 分環節記錄中 Sprint 10 合計 108M 為全 token 總量，非 cache_read 子集）。通過門檻：104M × 40% = **41.6M**。

**Sprint 12 Review 呈現方式**：Retro #22 與 US-24 AC3/AC4 並排呈現（見下方 US-24 說明）。

---

### Issue #23：health-check SKILL.md 零讀取架構對齊

| # | AC | 類型 |
|---|-----|------|
| AC1 | `skills/health-check/SKILL.md` §4 改寫為 subagent 模式，主 session 不直接呼叫 Read/Glob/Grep | [靜態] |
| AC2 | Subagent 回傳格式符合 §3 定義（Overall Status + 4 子檢查 + 判定標籤）| [靜態] |
| AC3 | Subagent 失敗時輸出 Overall Status: UNKNOWN + 說明，不降級讀取（維持零讀取）| [靜態] |

**修改檔案（限定範圍）**：`skills/health-check/SKILL.md`

**Architect 風險說明**：AC3 定義了明確的 fallback 策略（UNKNOWN 狀態），避免 subagent 失敗時主 session 回退至直接讀取，確保零讀取架構不被繞過。

---

### US-24 AC3/AC4：Subagent Token 成本優化量測

| # | AC | 類型 |
|---|-----|------|
| AC3 | Sprint 12 Planning JSONL message 物件數量 < 200 | [動態] |
| AC4 | Sprint 12 Planning input_tokens + output_tokens 較 Sprint 10 Planning 基準下降 >= 50%；基準值從 Metrics_Log.md 取得 | [動態] |

**基準值確認**：Sprint 10 Planning token = **87M**（來源：Metrics_Log.md 分環節記錄表格）。Sprint 10 Planning 總 token（input + output）= 87M（輸入）+ 對應輸出估算。通過門檻：Sprint 12 Planning 總 token < Sprint 10 Planning 基準 × 50%。

**Sprint 10 基準一致性說明**：
- Retro #22 量測基準：**104M**（`cache_read_input_tokens`，全 Sprint cache 讀取）
- US-24 AC4 量測基準：**87M**（Sprint 10 Planning 環節 token，分環節表格）
- 兩者量測對象不同（非衝突），於 Sprint 12 Review 並排呈現時需清楚標注各自基準來源

**AC1/AC2 狀態**：US-24 AC1（檔案傳遞模式）與 AC2（輕量模型指定）已於 Sprint 11 US-25 中部分實現（AC1 架構等同），暫緩獨立執行；Sprint 12 僅驗收 AC3/AC4 量測結果。

---

## 權重調整記錄

**QA Review 升級：Should → Hard Gate（Must）**

**觸發依據（US-22 ADR-004 規則執行）**：
- Sprint 10 Retrospective Problem 區塊：含關鍵字「Review」（匹配 QA 領域關鍵字清單）
- Sprint 11 Retrospective Problem 區塊：含關鍵字「QA」（匹配 QA 領域關鍵字清單）
- 連續 2 Sprint（Sprint 10、Sprint 11）各含至少 1 個 QA 關鍵字 → **觸發條件滿足**

**調整結果**：Sprint 12 QA Review 從 Should 升為 **Hard Gate（Must，不可跳過）**，雙輪審查生效。

**調整項目**：
1. QA Review（Spec Compliance + Code Quality）：Should → Hard Gate（Must）
2. 雙輪審查：啟用（第一輪 Spec，第二輪 Code Quality）

**參考 Sprint**：Sprint 10 Retro（關鍵字：Review）、Sprint 11 Retro（關鍵字：QA）

---

## ADR 前提

| Story | ADR 需求 | 狀態 |
|-------|---------|------|
| Retro #21 | ADR-003 Checklist（修改 skills/ 下 .md） | Hard Gate PASS（Architect 確認） |
| Retro #22 | 純量測，無 ADR 需求 | Hard Gate PASS |
| Issue #23 | ADR-003 Checklist（修改 skills/ 下 .md） | Hard Gate PASS（Architect 確認） |
| US-24 AC3/AC4 | 純量測，無 ADR 需求 | Hard Gate PASS |

無需建立新 ADR。

---

## Token 記錄

| 環節 | Token | 備註 |
|------|-------|------|
| Planning | N/A | Token 資料不可用，需手動補充 |
| Execution | N/A | Token 資料不可用，需手動補充 |
| Review | N/A | Token 資料不可用，需手動補充 |
