# Sprint 86

> 狀態：進行中
> 日期：2026-03-12
> Sprint Goal：Discovery Ecosystem 第一里程碑 — 打通「用戶聲音 → 自動進入 Discovery」閉環 + SRE 事故回應基礎框架

## Sprint Backlog

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| US-236 | 用戶回饋自動流入 Discovery — Issue 自動轉 User Story 閉環 | M | 2 | 待開始 |
| US-237 | SRE 完整化 Phase 1 — Incident Response Runbook + Post-mortem 框架 | L | 3 | 待開始 |

容量：5 points（1M + 1L）

## Acceptance Criteria

### US-236 用戶回饋自動流入 Discovery — Issue 自動轉 User Story 閉環（M/2pt）| FEATURE | doc-only

| AC | 類型 | 驗證重點 | 目標檔案 |
|----|------|---------|---------|
| AC1 | [靜態] | `skills/issue-management/SKILL.md` §10.1 Post-Triage Routing 新增 Discovery 觸發路徑：`feature-request` label Issue 達指定閾值（≥3 thumbs-up reactions 或 ≥5 comments）自動建議啟動 `/discovery-phase` | `skills/issue-management/SKILL.md` |
| AC2 | [靜態] | `skills/discovery-phase/SKILL.md` §2 Step 1 新增「Issue 觸發」入口，補充 Issue-triggered discovery 與 milestone-triggered 的差異說明 | `skills/discovery-phase/SKILL.md` |
| AC3 | [靜態] | 閉環路徑文件化：Issue → Triage → Backlog Bridge → Discovery Phase 完整路由圖 | `skills/issue-management/SKILL.md` §14 |
| AC4 | [靜態] | 回饋匯總定義：每 Sprint Grooming 時自動匯總 `feature-request` Issue 趨勢（數量、重複主題、投票數排序） | `skills/backlog-management/SKILL.md` §3 |

### US-237 SRE 完整化 Phase 1 — Incident Response Runbook + Post-mortem 框架（L/3pt）| INFRA | doc-only

| AC | 類型 | 驗證重點 | 目標檔案 |
|----|------|---------|---------|
| AC1 | [靜態] | `docs/templates/incident-runbook-template.md` created with sections: Severity Classification, Escalation Path, Communication Protocol, Resolution Steps, Timeline Template | `docs/templates/incident-runbook-template.md` (NEW) |
| AC2 | [靜態] | `skills/deployment-readiness/SKILL.md` 新增 Incident Response 章節，引用 Runbook 模板 | `skills/deployment-readiness/SKILL.md` |
| AC3 | [靜態] | `docs/templates/post-mortem-template.md` created with sections: Timeline, Root Cause (5 Whys), Impact Assessment, Action Items | `docs/templates/post-mortem-template.md` (NEW) |
| AC4 | [靜態] | `skills/deployment-readiness/SKILL.md` 新增 Post-mortem 章節，定義事故復盤 SOP | `skills/deployment-readiness/SKILL.md` |
| AC5 | [靜態] | §6 Golden Signals 監控 Checklist 擴充為人工可操作清單 | `skills/deployment-readiness/SKILL.md` |
| AC6 | [靜態] | §7 SLO/SLI 實作指引：從定義擴展到測量方法（如何量測 SLO 達標） | `skills/deployment-readiness/SKILL.md` |
| AC7 | [靜態] | §8 可靠性架構實作指引：斷路器、降級策略的實作 Checklist | `skills/deployment-readiness/SKILL.md` |

## 平行分群

### Phase 1（平行執行，無檔案衝突）
| Story ID | 標題 | Size | 說明 |
|----------|------|------|------|
| US-236 | 用戶回饋自動流入 Discovery | M | 修改 issue-management / discovery-phase / backlog-management SKILL.md |
| US-237 | SRE 完整化 Phase 1 | L | 修改 deployment-readiness SKILL.md + 新增 templates |

## 備註
- 兩個 Story 皆為 doc-only，TDD 豁免
- US-236 為 FEATURE 類型，US-237 為 INFRA 類型
- Phase 1 scope（US-237）不含 monitoring tool selection + alerting
