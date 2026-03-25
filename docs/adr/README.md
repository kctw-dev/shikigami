# ADR 目錄索引

> 本文件由 `scripts/update-adr-index.sh` 自動產生，請勿手動修改。
> 最後更新：2026-03-25 18:34:32

## 架構決策紀錄（Architecture Decision Records）

| ADR 編號 | 標題 | 狀態 | 日期 |
|---------|------|------|------|
| ADR-001 | [ADR-001：Backlog Bridge 跨 Skill 編排模式](ADR-001.md) | Accepted | 2026-02-28 |
| ADR-002 | [ADR-002：測試框架技術選型](ADR-002.md) | Accepted | 2026-03-01 |
| ADR-003 | [ADR-003：SQA 稽核閘門介入模式](ADR-003.md) | Accepted | 2026-03-01 |
| ADR-004 | [ADR-004：Retrospective Problem 主題比對機制](ADR-004.md) | Accepted | 2026-03-01 |
| ADR-005 | [ADR-005：Schedule Skill 技術決策](ADR-005-schedule-skill-technical-decisions.md) | Accepted | 2026-03-02 |
| ADR-006 | [ADR-006：Issue 內容提示注入防護](ADR-006-prompt-injection-protection.md) | Accepted | 2026-03-02 |
| ADR-007 | [ADR-007：Story 生命週期 Subagent 封裝](ADR-007-story-lifecycle-subagent.md) | Accepted | 2026-03-02 |
| ADR-008 | [ADR-008：OpenCode 平台整合策略](ADR-008.md) | Accepted | 2026-03-03 |
| ADR-009 | [ADR-009：Backlog Intake 自動化技術決策](ADR-009.md) | Accepted | 2026-03-03 |
| ADR-010 | [ADR-010：Backlog Source of Truth — GitHub Issues 優先策略](ADR-010.md) | Accepted | 2026-03-03 |
| ADR-011 | [ADR-011：GitHub Actions 整合架構決策](ADR-011-github-actions-integration.md) | Accepted | 2026-05-11 |
| ADR-012 | [ADR-012：Claude Max 多開發環境認證架構決策](ADR-012-max-account-rotation.md) | Accepted | 2026-03-05 |
| ADR-013 | [ADR-013：shikigami:diagram MCP 整合架構決策](ADR-013-diagram-skill-mcp-integration.md) | Accepted | 2026-03-05 |
| ADR-014 | [ADR-014：UIUX Agent 架構決策](ADR-014-uiux-agent-architecture.md) | Accepted | 2026-03-06 |
| ADR-015 | [ADR-015：UIUX 管線架構轉型 — Figma 整合取代三層 SSD 管線](ADR-015-figma-integration.md) | Accepted | 2026-03-06 |
| ADR-016 | [ADR-016：UI/UX Designer 角色定義與 Design Foundation 流程](ADR-016-uiux-designer-role.md) | Accepted | 2026-03-11 |
| ADR-017 | [ADR-017：Context Hub 整合架構決策 — Knowledge Ingestion 機制](ADR-017-context-hub-knowledge-ingestion.md) | Accepted | 2026-03-11 |
| ADR-018 | [ADR-018：Discovery Phase 架構方案 — 獨立 Skill vs 擴充 backlog-management](ADR-018-discovery-phase-architecture.md) | Accepted | 2026-03-11 |
| ADR-019 | [ADR-019：MCP 三層架構 — 知識庫 / 流程管理 / 品質觀察 MCP Server](ADR-019-mcp-three-layer-architecture.md) | Accepted | 2026-03-12 |
| ADR-020 | [ADR-020：SDD 作為 AC 的強制上游約束 — 建立 SDD → AC → TDD 追溯鏈](ADR-020-sdd-as-ac-upstream-constraint.md) | Accepted | 2026-03-15 |
| ADR-021 | [ADR-021：pr-review-toolkit 外部 Plugin 整合架構](ADR-021-pr-review-toolkit-integration.md) | Accepted | 2026-03-15 |
| ADR-022 | [ADR-022：檔案級別鎖定機制 — 多 Session 同時編輯衝突防護](ADR-022-file-level-locking.md) | Accepted | 2026-03-19 |
| ADR-023 | [ADR-023：PR-based Git Flow — 從直推 main 遷移至 Pull Request 審查流程](ADR-023-pr-based-git-flow.md) | Accepted | 2026-03-20 |
| ADR-024 | [ADR-024：出勤時數機制 — SessionStart/End Hook JSONL 紀錄](ADR-024-attendance-hook.md) | Accepted（含 Amendment：US-#319 per-session 演化） | 2026-03-20 |
| ADR-025 | [ADR-025 — 探索紀錄收集機制](ADR-025-exploration-record.md) | 已採納 | 2026-03-20 |
| ADR-026 | [ADR-026：Cruise Mode — 巡航模式定期執行機制](ADR-026-cruise-mode.md) | Accepted | 2026-03-21（附錄更新：2026-03-23） |
| ADR-027 | [ADR-027：CI 權限 — Claude Code Headless 模式授權策略](ADR-027-ci-permissions.md) | Accepted | 2026-03-21 |
| ADR-028 | [ADR-028：多 Sprint 觀測 — 多 Runner 統一觀測方案](ADR-028-multi-sprint-observability.md) | Accepted | 2026-03-21 |
| ADR-029 | [ADR-029：Cruise Close Policy + Delivery Chain Per-Repo 可定義](ADR-029-cruise-close-policy-delivery-chain.md) | Accepted | 2026-03-23 |
| ADR-030 | [ADR-030：Claude OAuth Token Watchdog — 偵測+告警策略](ADR-030-oauth-token-watchdog.md) | Accepted | 2026-03-23 |
| ADR-031 | [ADR-031：同職能 Team Debate 機制](ADR-031-team-debate.md) | Accepted | 2026-03-23 |
| ADR-032 | [ADR-032：交付路徑分層（/commit vs /shoot vs /sprint-execution）](ADR-032-delivery-path-tiering.md) | Accepted | 2026-03-23 |
| ADR-033 | [ADR-033：Structured Trace Log 架構](ADR-033-structured-trace-log.md) | Accepted | 2026-03-24 |
| ADR-034 | [ADR-034：Browser Automation 工具選型](ADR-034-browser-automation-tool-selection.md) | Accepted | 2026-03-24 |
| ADR-035 | [ADR-035：TDAD 依賴分析工具選型](ADR-035-tdad-dependency-analysis.md) | Accepted | 2026-03-24 |
| ADR-036 | [ADR-036：Schema-first API Contract 統一定義架構決策](ADR-036-schema-first-api-contract.md) | Accepted | 2026-03-24 |
| ADR-037 | [ADR-037：Context Engineering — Just-in-Time Retrieval 架構決策](ADR-037-context-engineering-jit.md) | Accepted | 2026-03-24 |
| ADR-038 | [ADR-038: Kill Switch — 高自治模式緊急停止機制設計](ADR-038-kill-switch-design.md) | Accepted | 2026-03-24 |
| ADR-039 | [ADR-039: Token Cost Routing — Risk-based Model 分級架構決策](ADR-039-token-cost-routing.md) | Accepted | 2026-03-24 |
| ADR-040 | [ADR-040: TCB 斷點管理 — Agent Action 級 Checkpoint 設計](ADR-040-tcb-checkpoint-design.md) | Accepted | 2026-03-24 |
| ADR-041 | [ADR-041: Temporal-style Crash Recovery — Session 級別恢復設計](ADR-041-crash-recovery-design.md) | Accepted | 2026-03-24 |
| ADR-042 | [ADR-042: Session Watchdog — 存活監控與自動重啟設計](ADR-042-session-watchdog-design.md) | Accepted | 2026-03-24 |
| ADR-043 | [ADR-043: Backlog Replenishment Strategy — 提前預警機制與 2-Sprint 提前期設計](ADR-043-backlog-replenishment-strategy.md) | Accepted | 2026-03-25 |
