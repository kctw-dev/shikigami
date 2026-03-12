# Sprint 85

> 狀態：進行中
> 日期：2026-03-12
> Sprint Goal：ADR-018 裁決（Accept Option A）+ Discovery Skill 實作

## Sprint Backlog

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| US-234 | ADR-018 裁決 — Accept Option A（獨立 Discovery Skill），回答 OQ-1/OQ-2 | S | 1 | 待辦 |
| US-235 | Discovery Skill 實作 — Phase 0 獨立入口、Product Brief 格式定義、PO 確認關卡 | M | 2 | 待辦 |

容量：3 points（1S + 1M）

## Acceptance Criteria

### US-234 ADR-018 裁決（S/1pt）

| AC | 類型 | 驗證重點 | 目標檔案 |
|----|------|---------|---------|
| AC1 | [靜態] | ADR-018 status Proposed → Accepted | `docs/adr/ADR-018-discovery-phase-architecture.md` |
| AC2 | [靜態] | OQ-1 Closed with PO decision (Discovery needs independent trigger) | `docs/adr/ADR-018-discovery-phase-architecture.md` |
| AC3 | [靜態] | OQ-2 Closed with Architect assessment (separation helps context isolation) | `docs/adr/ADR-018-discovery-phase-architecture.md` |
| AC4 | [靜態] | 決策者 updated from 待定 to PO + Architect | `docs/adr/ADR-018-discovery-phase-architecture.md` |
| AC5 | [靜態] | ROADMAP.md Sprint 85 record | `docs/prd/ROADMAP.md` |

### US-235 Discovery Skill 實作（M/2pt）

| AC | 類型 | 驗證重點 | 目標檔案 |
|----|------|---------|---------|
| AC1 | [靜態] | `skills/discovery-phase/SKILL.md` created with 6-step flow | `skills/discovery-phase/SKILL.md` (NEW) |
| AC2 | [靜態] | Product Brief format with 7 required sections + PO sign-off | `skills/discovery-phase/SKILL.md` or template |
| AC3 | [靜態] | PO confirmation gate (Hard Gate) — 3 gates defined | `skills/discovery-phase/SKILL.md` |
| AC4 | [靜態] | Assumption externalization aligned with US-214 三問 format | `skills/discovery-phase/SKILL.md` |
| AC5 | [靜態] | `skills/backlog-management/SKILL.md §2` simplified, points to /discovery-phase | `skills/backlog-management/SKILL.md` |
| AC6 | [靜態] | `skills/discovery-phase/SKILL.md` 含正確 YAML frontmatter（name: discovery-phase + description），符合現有 skill 目錄慣例 | `skills/discovery-phase/SKILL.md` |
| AC7 | [靜態] | `docs/templates/product-brief-template.md` created | `docs/templates/product-brief-template.md` (NEW) |
| AC8 | [靜態] | ADR-018 status = Accepted (Hard Gate, Story 1 first) | `docs/adr/ADR-018-discovery-phase-architecture.md` |

## 平行分群

### Phase 1（無依賴）
| Story ID | 標題 | Size | 說明 |
|----------|------|------|------|
| US-234 | ADR-018 裁決 | S | ADR-018 Proposed → Accepted，回答 OQ-1/OQ-2 |

### Phase 2（序列執行，依賴 Phase 1）
| Story ID | 標題 | Size | 衝突原因 |
|----------|------|------|---------|
| US-235 | Discovery Skill 實作 | M | 依賴 US-234 完成（ADR-018 必須先 Accepted） |
