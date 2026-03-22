# Sprint 115

**Sprint Goal**：Cruise 巡查閉環 — PO 自動行動 + SRE 觸發 debugging，從「只回報」進化為「發現即處理」
**日期**：2026-03-22
**容量**：8 points
**狀態**：已完成

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| PO 巡邏自動行動（新回覆判斷 + 交付推進 + 催促 + Triage） | #327 Phase 1 | M | 5 | 完成 ✓ |
| SRE 巡檢自動行動（CI fail → 建 Issue + debugging 指引） | #327 Phase 2 | S | 3 | 完成 ✓ |

## Acceptance Criteria

### #327 Phase 1 — PO 巡邏自動行動（M, 5pt）

> **Type**：FEATURE
> **修改範圍**：skills/cruise/SKILL.md（PO 巡邏指引 section + 新增安全邊界 section）
> **Architect 備注**：自動行動決策表 4 種情境 + 安全邊界（Stakeholder Issue 不自動行動）+ 冪等性檢查（重複催促 / 重複推進防護）

**AC-1：PO 巡邏新回覆自動判斷**
- PO 巡邏發現 Issue 有新回覆 → 自動讀取回覆內容
- 判斷行動：排入 Backlog（invoke backlog-management）或直接回覆（內部 Issue only）
- SKILL.md 包含「自動行動決策表」子段，列出 4 種情境

**AC-2：交付卡住自動推進**
- 發現 PR merge 成功但未推進 → 自動推進交付鏈下一步
- 交付鏈：staging → E2E → tag → production → close
- 推進前檢查前置條件（PR 狀態、CI 狀態），避免跳步

**AC-3：awaiting-reply 超時自動催促**
- 超過閾值未回覆的 Issue 自動留言催促
- 催促頻率上限：每 24h 最多催一次（檢查最後一則留言時間）
- 冪等性：最後一則留言若已是自動催促留言 → 跳過

**AC-4：新 Issue 無 label 自動 Triage**
- 無 label 的 Issue 自動觸發 issue-management triage
- 已有 label 的 Issue 不重複 triage（冪等性）

**AC-5：安全邊界 — Stakeholder Issue 不自動行動**
- SKILL.md 新增§安全邊界段落
- 判斷標準：有 `stakeholder` label 的 Issue = Stakeholder Issue
- Stakeholder Issue 只記錄到 cruise log，不自動行動
- log 中標注 `"skipped": "stakeholder-issue"`

**AC-6：Cruise log 擴充（PO 行動）**
- PO 巡邏結果 actions 欄位擴充行動類型：reply / triage / push-delivery / nudge / skipped
- 所有自動行動寫入 cruise log，可追溯

### #327 Phase 2 — SRE 巡檢自動行動（S, 3pt）

> **Type**：FEATURE
> **修改範圍**：skills/cruise/SKILL.md（SRE 巡檢指引 section）
> **Architect 備注**：CI failure 建 Issue + systematic-debugging 指引（松耦合，不在 cruise loop 內同步 debug）；Deploy failure / Runner offline 同樣建 Issue + 指引

**AC-1：CI failure → 建 Issue + 觸發排查指引**
- SRE 發現 CI failure → 建 Issue（現有邏輯）
- Issue body 新增「建議：執行 `/systematic-debugging` 排查」指引
- Issue 加上 `sre-auto-debug` label
- 不在 cruise loop 內同步執行 debugging（保持 cruise 輕量）

**AC-2：Deploy failure → 建 Issue + 通知 PO**
- Deploy failure 建 Issue + 在 Issue body 中 @mention PO
- Issue 加上 `deploy-failure` label

**AC-3：Runner offline → 建 Issue**
- Runner offline 建 Issue（已有權限防護：repo-level fallback）
- Issue 加上 `runner-offline` label

**AC-4：Cruise log 擴充（SRE 行動）**
- SRE 巡檢結果 actions 欄位擴充行動類型：create-issue-with-debug / create-issue-deploy / create-issue-runner
- 所有自動行動寫入 cruise log

**AC-5：跨機器冪等性**
- Issue 重複防護（`gh issue list --search`）覆蓋所有新 Issue 類型
- 多 runner 同時發現同一 failure → 只建一個 Issue（search 防護）

## 技術評估摘要

### Architect 備注

- **修改範圍**：`skills/cruise/SKILL.md` 單檔，Phase 1 修改 PO 巡邏段落 + 新增安全邊界段落，Phase 2 修改 SRE 巡檢段落，兩 Phase 修改不同 section 無衝突
- **PO 安全邊界**：label-based 判斷（`stakeholder` label），不維護 team 名單，簡潔
- **SRE → debugging 整合**：松耦合（Issue 指引），不在 cruise loop 同步執行 debugging，保持 cruise 輕量
- **跨機器安全**：Issue 重複防護已存在 + 自動行動冪等性設計（催促頻率上限 / triage 冪等 / 推進前置條件檢查）
- **不需 ADR**：行為擴充，不改變架構模式（仍是 cruise loop + per-session log）

### QA 備注

- **所有 AC 可驗證**
- Phase 1 AC-1~AC-4：行為型（SKILL.md 內容檢查 — 決策表 + 交付推進 + 催促 + triage 邏輯）
- Phase 1 AC-5~AC-6：結構型（安全邊界段落 + log 格式擴充）
- Phase 2 AC-1~AC-3：行為型（Issue body 模板 + label + 指引內容）
- Phase 2 AC-4~AC-5：結構型（log 格式 + 冪等性邏輯）
- **DoR**：PASS
- **防漂移基準**：2 Stories (Phase 1 + Phase 2), 8 pts
- **邊界案例已覆蓋**：Stakeholder Issue 不回覆 (AC-5)、同一問題重複觸發 (AC-5 Phase 2)、交付鏈跳步防護 (AC-2)、催促 spam 防護 (AC-3)

---

## Sprint Planning 會議紀錄

**日期**：2026-03-22
**參與者**：PO、Architect、QA

### PO R1 — 需求評估

- #327 要求 Cruise Mode 從「只回報不行動」升級為「發現問題自動接續處理」
- 涵蓋 PO 巡邏 4 種情境 + SRE 巡檢 3 種情境
- Size 評估：L (8pt)，拆為 Phase 1 (M, 5pt) + Phase 2 (S, 3pt)
- Sprint Goal：Cruise 巡查閉環 — 發現即處理

### Architect — 技術方案

- PO 安全邊界：label-based 判斷（`stakeholder` label），簡潔且不需維護名單
- SRE → debugging：松耦合設計（Issue 指引），不在 cruise loop 同步 debug
- 修改範圍：SKILL.md 單檔，兩 Phase 不同 section 無衝突
- 跨機器：Issue 重複防護 + 自動行動冪等性，不需分散式鎖
- 不需 ADR

### QA — 驗證策略

- 所有 AC 可驗證，DoR PASS
- 邊界案例：Stakeholder 不回覆、重複觸發、交付跳步、催促 spam — 均已在 AC 中覆蓋
- 防漂移基準：2 Stories, 8 pts

### PO R2 — 最終決策

- 兩個 Phase 都做（AI 團隊無工作量限制，同概念打包）
- Sprint 115 容量：8 pts

---

## Sprint 115 Review

**日期**：2026-03-22
**版本**：v0.78.4 → v0.78.5

### §1 Demo

- #327 Phase 1（PO 巡邏自動行動）：65/65 PASS
  - 自動行動決策表 4 種情境（reply / triage / nudge / push-delivery）落地
  - 交付鏈推進前置條件檢查完整（防跳步）
  - 催促冪等雙重防護（[自動催促] 標記 + 24h 頻率上限）
  - Stakeholder 安全邊界段落獨立存在，label-based 判斷
- #327 Phase 2（SRE 巡檢自動行動）：82/82 PASS
  - CI failure → Issue + `/systematic-debugging` 指引（松耦合）
  - Deploy failure → Issue + @mention PO
  - Runner offline → Issue
  - 跨機器冪等性（gh issue list --search 防護覆蓋所有三種 Issue 類型）

### §2.6 Issue 狀態

- #327 → CLOSED（Phase 1 + Phase 2 全部完成）

### §3 Retrospective

**Good**：
- Cruise 從「回報」進化為「行動」，閉環設計完整
- 安全邊界（stakeholder label）+ 冪等性（催促 / triage / 推進）設計嚴謹

**Problem**：無

**Action**：無

### Metrics

- Velocity：8 pts
- 完成率：100%
- DISPUTE 率：0%
- 外部抽樣：Phase 1 65/65 PASS，Phase 2 82/82 PASS
