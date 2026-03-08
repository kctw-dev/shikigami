# Backlog Done — 已完成 Stories 歸檔

按 Sprint 整理，保留完整 RICE 評分與驗收標準。

---

## Sprint 70（2026-03-08）

**Sprint Goal**：Provider 路由品質修正 — 宿主平台自動偵測，消除 Gemini CLI 預設值邏輯矛盾

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-181（Issue #176）：Provider 路由預設值應偵測宿主平台 — 修正寫死 claude 預設值 | S | 1 | Sprint 70 |

---

## Sprint 69（2026-03-08）

**Sprint Goal**：Developer Provider 路由落地 — Gemini CLI 自動 Fallback 派遣機制

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-180（Issue #175）：Developer 角色 Provider 路由 — 支援 Gemini CLI 可切換派遣（環境變數控制） | S | 1 | Sprint 69 |

---

## Sprint 68（2026-03-08）

**Sprint Goal**：KM 減法 — 移除無用的 DORA Metrics + KM 檔案瘦身

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-178（Issue #172）：移除 DORA Metrics — 刪除 sprint-review §2.7 整段、Metrics_Log DORA 區塊、相關 checklist | S | 1 | Sprint 68 |
| US-179（Issue #173）：BACKLOG_DONE.md 歸檔機制 — 主檔只保留最近 5 個 Sprint | S | 1 | Sprint 68 |

---

## Sprint 67（2026-03-08）

**Sprint Goal**：簡化多模型派遣架構 — 移除基於錯誤前提設計的 cli-adapter.sh 抽象層，直接利用 Gemini CLI 原生 agent 能力。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-177（Issue #171）：CLI Adapter 簡化 — 移除不必要的抽象層，直接使用 Gemini CLI 原生 agent 能力 | S | 1 | Sprint 67 |

---

## Sprint 66（2026-03-08）

**Sprint Goal**：CLI Adapter Phase 3 SKILL.md 整合 — 建立雙軌派遣機制，讓框架能透過 cli-adapter.sh 派遣 Gemini 執行特定角色任務。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-176（Issue #170）：CLI Adapter Phase 3 -- SKILL.md 整合與角色→Provider 路由機制 | M | 2 | Sprint 66 |

---

## Sprint 65（2026-03-08）

**Sprint Goal**：Subagent 模型自動調度完善 — 補齊所有 subagent 派遣點的 model 參數標注，建立角色→模型對照表，實現成本分層自動化。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-175（Issue #169）：Subagent 多模型自動調度 — 角色對照表建立與派遣點 model 參數補齊 | S | 1 | Sprint 65 |

---

## Sprint 64（2026-03-08）

**Sprint Goal**：清空 Backlog，終結所有懸而未決的 Open Issues — 評估並結案或推進 #159、#59、#5、#4。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-171（Issue #159）：多模型 CLI 路由 Phase 3 方向決策 — Issue #159 結案或規劃後續 | S | 1 | Sprint 64 |
| US-172（Issue #59）：Beta 回饋機制評估與結案 — Issue #59 現狀審查 | S | 1 | Sprint 64 |
| US-173（Issue #5）：Marketplace 上架現狀審查 — Issue #5 結案決策 | S | 1 | Sprint 64 |
| US-174（Issue #4）：Cursor 平台現狀審查 — Issue #4 結案決策 | S | 1 | Sprint 64 |

---

## Sprint 63（2026-03-08）

**Sprint Goal**：流程修正與技術債清理 — 修復 Sprint Review Issue 自動關閉問題（#166），評估開源 CLI Adapter 替代方案（#167），清理 50+ Sprint 懸而未決的 Retro Action Items（#168）。

| Story | Size | Points | 完成 Sprint |
|-------|------|--------|------------|
| US-168（Issue #166）：Sprint Review Issue 關閉邏輯修正 — 區分內部/外部 Issue 關閉策略 | S | 1 | Sprint 63 |
| US-169（Issue #167）：多模型 CLI 路由 Phase 2 — 開源 Adapter 評估與決策 | S | 1 | Sprint 63 |
| US-170（Issue #168）：Retro Action Items 批次處理 — Sprint 11-12 懸而未決項目清理 | S | 1 | Sprint 63 |

---

> 歷史完成記錄：[BACKLOG_DONE_ARCHIVE](../km/archive/BACKLOG_DONE_ARCHIVE.md)（Sprint 1–62）
