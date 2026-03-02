# Sprint 14

**Sprint Goal**：清零 Sprint 13 Retro Action Items，收窄 Retro #29 修改範圍至 sprint-execution SKILL.md，完成 sprint-review 硬編碼版本號修正，確保框架指引文件在 M5 穩定化階段維持長期可維護性。
**期間**：2026-03-02 ~ 2026-03-08

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| Retro #29 | Issue 快掃觸發條件排除 retro-action label（收窄至 sprint-execution SKILL.md） | S | 1 | 待開發 |
| Retro #30 | sprint-review SKILL.md 禁止項硬編碼版本號修正 | S | 1 | 待開發 |

**總計：2 Stories / 2 Points**

---

## Acceptance Criteria

### Retro #29：Issue 快掃觸發條件排除 retro-action label

**範圍說明（PO 第二輪 AC 精化）**：
QA 指出原 AC 中 `commands/standup.md` 的「區塊二」無觸發條件結構，與 `sprint-execution/SKILL.md` 結構不同。PO 決策：`standup.md` 區塊二本身是純顯示（列出 open issues），不做回覆動作，因此無觸發條件結構需修改。本 Story 修改範圍**收窄為僅修改 `skills/sprint-execution/SKILL.md`**。

| # | AC | 類型 |
|---|-----|------|
| AC1 | `skills/sprint-execution/SKILL.md` Issue 快掃觸發條件 (a) 修改為：issue 不含 `in-backlog` label **且**不含 `retro-action` label | [靜態] |
| AC2 | 修改後觸發條件 (a) 的完整表述為「距上次回覆超過 24 小時，且無 `in-backlog` label，且無 `retro-action` label」（或等義表述） | [靜態] |

**修改檔案（限定範圍）**：`skills/sprint-execution/SKILL.md`

---

### Retro #30：sprint-review SKILL.md 禁止項硬編碼版本號修正

| # | AC | 類型 |
|---|-----|------|
| AC1 | `skills/sprint-review/SKILL.md` 禁止項說明中移除 `v0.3.5`（或其他具體版本號）硬編碼，改用版本無關描述（例如「不得依賴 plugin cache 版本」） | [靜態] |
| AC2 | 修改後禁止項說明不含任何具體版本號格式（如 `v\d+\.\d+\.\d+`），確保跨版本迭代持續有效 | [靜態] |

**修改檔案（限定範圍）**：`skills/sprint-review/SKILL.md`

---

## 權重調整記錄

- 觸發條件：Sprint 12（Problem「Developer 在 Sprint Execution 完成後越權標記 Sprint 完成」，關鍵字：Review）與 Sprint 13（Problem「QA Code Quality Review 發現 Retro #26 實作含硬編碼版本號」，關鍵字：QA、Review、品質）連續出現 QA 相關 Problem
- 調整項目：QA Review 升為 Hard Gate（Must），Bypass 不適用 QA 相關審查
- 生效 Sprint：Sprint 14

---

## 平行分群策略

### Phase 1（可平行）

| Story ID | 修改檔案 |
|----------|---------|
| Retro #29 | `skills/sprint-execution/SKILL.md` |
| Retro #30 | `skills/sprint-review/SKILL.md` |

**平行化理由**：Retro #29 修改 `skills/sprint-execution/SKILL.md`，Retro #30 修改 `skills/sprint-review/SKILL.md`，兩者目標檔案互異，無衝突，可完全平行執行。

---

## 工作容量

| 指標 | 數值 |
|------|------|
| 計畫 Stories | 2 |
| 計畫 Points | 2（2 × S） |
| 近 3 Sprint 平均 Velocity | 4.7pt（Sprint 10: 6、Sprint 11: 4、Sprint 12: 4） |
| Sprint 13 Velocity | 4pt |
| 緩衝率 | 50%（低於歷史 Velocity，但無符合 QA Hard Gate 要求的候選 Story） |

**容量決策說明**：
Sprint 14 僅選入 2 個 Retro Action Items（2 points），低於歷史平均 Velocity（4pt）。原因：
1. US-15/US-16 在 PRODUCT_BACKLOG.md 無正式條目，QA Hard Gate（Must）要求所有 Story 必須有可測試 AC，故退回
2. Backlog 中唯一有完整 AC 的待選 Story 為 US-T08（Could / L），優先級（Could）和規模（L）均不適合此 Sprint
3. ROADMAP M5 中的 US-17 在 BACKLOG 無完整條目，亦不符合 Hard Gate 要求
4. 品質優先：寧可降低 Velocity，不選入無完整 AC 的 Story

---

## ADR 前提

| Story | ADR 需求 | 狀態 |
|-------|---------|------|
| Retro #29 | ADR-003 Checklist（修改 skills/ 下 .md） | 待 Architect 確認 |
| Retro #30 | ADR-003 Checklist（修改 skills/ 下 .md） | 待 Architect 確認 |

**ADR-003 適用說明**：兩個 Stories 均修改 `skills/` 目錄下的 SKILL.md 檔案，ADR-003 Framework Document Change Audit Hard Gate 適用。Developer 執行時須通過 Checklist。

---

## Token 記錄

| 環節 | Token | 備註 |
|------|-------|------|
| Planning | 待補 | Sprint 14 Planning 完成後從 JSONL 提取 |
| Execution | 待補 | Sprint 14 Execution 完成後填入 |
| Review | 待補 | Sprint 14 Review 完成後填入 |
