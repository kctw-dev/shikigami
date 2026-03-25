# Quality Gate Decisions

> **用途**：記錄所有 CRITICAL quality-gate 發現的處置決策，用於跨 Sprint 追蹤風險接受模式。
> **規則**：僅允許 append — 不得截斷或刪除已有記錄（NFR1）。
> **觸發時機**：Sprint Review 發現 CRITICAL 發現被覆寫（PR 已 merge 儘管有 CRITICAL 告警）時，由主 session 在 `sprint-review` 流程中記錄（AC2）。
>
> 稽核指令：`bash scripts/quality-gate-audit.sh docs/km/quality-gate-decisions.md`

## 決策記錄

| Date | Story | Finding | Severity | Decision | Rationale | Sprint |
|------|-------|---------|----------|----------|-----------|--------|
