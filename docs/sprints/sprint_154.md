# Sprint 154

- **Sprint Goal**: 強化框架自動化防護與可觀察性 — 整合 parallel-safety 全自動決策、建立 cruise logs 歸檔機制、補強 WSL2 測試覆蓋、調整 Backlog 補充閾值策略
- **期間**: 2026-03-25 ~ 2026-03-31
- **容量**: 7 pts

## Stories

| # | Story | Issue | Points | Status | Assignee |
|---|-------|-------|--------|--------|----------|
| 1 | feat: cruise logs 壓縮歸檔機制（長期可觀測性） | #708 | 2 | TODO | Developer |
| 2 | retro: Sprint 153 parallel-safety 全自動化 — 消除人工決策 | #722 | 2 | TODO | Developer |
| 3 | retro: Sprint 153 多平台測試覆蓋強化 — 補充 WSL2 實測 | #720 | 1 | TODO | Developer |
| 4 | RESEARCH: ADR-043 — Backlog Replenishment Strategy | #723 | 1 | TODO | Developer |
| 5 | retro: Sprint 153 Backlog 補充頻率調整 — 建立提前預警機制 | #721 | 1 | TODO | Developer |

**Total: 7 pts**

## 執行順序（Parallel Grouping）

> SHIKIGAMI_MAX_PARALLEL 未設定，預設視為 2（CLAUDE.md §12）。

**Batch 1（同時執行）**：
- #708（2pt, S）— cruise logs 歸檔，修改 skills/cruise/references/startup-flow.md + .gitignore
- #720（1pt, S）— WSL2 測試補強，修改 tests/test-multiplatform-compat.sh

**Batch 2（Batch 1 完成後執行）**：
- #722（2pt, M）— parallel-safety 整合，修改 skills/sprint-execution/SKILL.md + 新增 tests/test-parallel-safety.sh + 新增 SDD
- #723（1pt, S）— ADR-043 撰寫，建立 docs/adr/ADR-043-backlog-replenishment-strategy.md

**Batch 3（#723 ADR Accepted 後執行）**：
- #721（1pt, S）— 修改 skills/backlog-management/SKILL.md（依賴 ADR-043 決策）

## ADR 依賴分群（#456）

> ADR Phase 1 必須在 ADR Phase 2 前完成。

**ADR Phase 1（先執行）**：#723 — ADR-043 Backlog Replenishment Strategy
**ADR Phase 2（ADR Accepted 後執行）**：#721 — retro: Backlog 補充頻率調整

## Architect 技術評估

| Story | T-shirt | Story Type | ADR 需求 | API 契約 | Schema Contract | Related SDDs | ADR-039 Risk | 說明 |
|-------|---------|-----------|---------|---------|----------------|-------------|-------------|------|
| US-#708 | S | FEATURE | 無需 ADR | 不適用 | 豁免 | — | 4（haiku） | startup-flow.md §4.4 + .gitignore 修改，無架構邊界變更 |
| US-#722 | M | FEATURE | 無需 ADR（整合已決策之 #712 邏輯） | 不適用 | 豁免 | — | 6（haiku） | sprint-execution/SKILL.md 集成記憶體感知，Linux/macOS 差異需測試 |
| US-#720 | S | FEATURE | 無需 ADR | 不適用 | 豁免 | — | 4（haiku） | 修改 tests/test-multiplatform-compat.sh（注意：AC1 原文 test-multiplatform.sh 路徑有誤，正確路徑見此） |
| US-#723 | S | RESEARCH | 自身即 ADR | N/A | 豁免（RESEARCH） | — | 4（haiku） | 建立 ADR-043，為 #721 前置 |
| US-#721 | S | FEATURE | 已補建 #723（RESEARCH） | 不適用 | 豁免 | — | 4（haiku） | 修改 backlog-management/SKILL.md 閾值，待 ADR-043 Accepted 後執行 |

## 平行分群建議

> **上限控制**：SHIKIGAMI_MAX_PARALLEL 未設定，預設為 2（CLAUDE.md §12），Phase 1 拆分為 3 批次（每批最多 2 個 Story）

### Phase 1（可平行執行）
| Story ID | 標題 | T-shirt | 說明 |
|----------|------|---------|------|
| US-#708 | cruise logs 壓縮歸檔 | S | 修改 cruise/references/startup-flow.md, .gitignore — 獨立 |
| US-#720 | WSL2 測試補強 | S | 修改 tests/test-multiplatform-compat.sh — 獨立 |
| US-#722 | parallel-safety 全自動化 | M | 修改 sprint-execution/SKILL.md — 獨立 |
| US-#723 | ADR-043 | S | 建立 docs/adr/ADR-043.md — 獨立 |

**Batch 1**（同時執行）：US-#708, US-#720
**Batch 2**（等 Batch 1 完成後執行）：US-#722, US-#723

### Phase 2（需序列執行）
| Story ID | 標題 | T-shirt | 衝突原因 |
|----------|------|---------|---------|
| US-#721 | Backlog 補充頻率調整 | S | 需等 ADR-043（#723）Accepted 後才能修改 SKILL.md |

### 檔案衝突分析
| 衝突檔案 | 涉及 Story | 建議執行順序 | 矩陣依據 |
|---------|-----------|------------|---------|
| docs/adr/ADR-043.md → skills/backlog-management/SKILL.md | US-#723, US-#721 | #723 → #721 | parallel-safety-matrix.md §1：文件輸入依賴 = 序列 |

### ADR 依賴分群
**ADR Phase 1（先執行）**：#723 — ADR-043 Backlog Replenishment Strategy
**ADR Phase 2（ADR Accepted 後執行）**：#721 — retro: Backlog 補充頻率調整

## QA 驗收確認

| Story | AC 確認 | 路徑驗證 | SDD 引用 | 隱性需求 | 結果 |
|-------|--------|---------|---------|---------|------|
| US-#708 | PASS (AC1-AC5) | PASS (startup-flow.md 存在) | — | NFR1-3 已定義 ✓ | **PASS** |
| US-#722 | PASS (AC1-AC3) | PASS (sprint-execution/SKILL.md 存在) | — | BDD 建議補充行為範例（記憶體充足/不足路徑） | **PASS** |
| US-#720 | PASS (AC1-AC3) | NOTE: AC1 原文路徑 `tests/test-multiplatform.sh` 不存在；正確路徑為 `tests/test-multiplatform-compat.sh` | — | WSL2 /proc/version 偵測為核心需求 | **PASS（路徑已在本文件修正）** |
| US-#723 | RESEARCH 豁免 | N/A | — | N/A | **PASS** |
| US-#721 | PASS (AC1-AC3) | PASS (backlog-management/SKILL.md 存在) | — | 無隱性需求缺口 | **PASS（待 ADR-043 Accepted）** |

## 方法論適用性評估

| Story ID | BDD 建議 | DDD 建議 | 說明 |
|----------|---------|---------|------|
| US-#708 | 不適用 | 不適用 | 歸檔腳本，無多路徑行為 |
| US-#722 | **建議（B1）** | 不適用 | AC2 兩個行為場景（記憶體充足→平行，記憶體不足→串行）建議補充 Given/When/Then |
| US-#720 | **建議（B1）** | 不適用 | 三平台（WSL2/Linux/macOS）環境分支需行為範例 |
| US-#721 | 不適用 | 不適用 | 閾值設定，無分支行為 |
| US-#723 | 不適用 | 不適用 | RESEARCH，doc-only |

## Schema Contracts

無（本 Sprint 所有 Story 不涉及 Agent-to-Agent 資料交換或 HTTP REST API）

## Sprint 容量基準

| Sprint | Velocity |
|--------|----------|
| Sprint 151 | 2 pts |
| Sprint 152 | 6 pts |
| Sprint 153 | 5 pts |
| **平均 (3-sprint)** | **4.3 pts** |
| **Sprint 154 容量** | **7 pts**（含 retro 緊急性，ADR-043 補建，上限 8pts 內） |

## Notes

- #720 AC1 路徑修正：原文 `tests/test-multiplatform.sh` 應為 `tests/test-multiplatform-compat.sh`（#710 建立的檔名）
- #721 依賴 #723 ADR-043 Accepted，執行順序為最後
- #722 整合 #712 已實作之記憶體感知邏輯，開發前確認 `skills/sprint-execution/references/parallel-safety.md` 最新狀態
- ADR-043 編號修正說明：原 Issue #721 AC3 提及「ADR-041」，但 ADR-041 已被 crash-recovery-design 使用，因此補建 ADR-043
- model-route log: #708 → haiku (score=4), #722 → haiku (score=6), #720 → haiku (score=4), #723 → haiku (score=4), #721 → haiku (score=4)
