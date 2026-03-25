# Architecture Decision Records (ADR) — Index

本文件為 Shikigami 框架所有 ADR 的索引，消除 `validate-orphans.sh` 對孤兒 ADR 文件的 WARNING 噪音。

> 每個 ADR 連結至對應文件，維護人員可快速查閱架構決策脈絡。

---

## ADR 列表

| ADR | 標題 | 狀態 |
|-----|------|------|
| [ADR-001](ADR-001.md) | Backlog Bridge 跨 Skill 編排模式 | Accepted |
| [ADR-002](ADR-002.md) | 測試框架技術選型 | Accepted |
| [ADR-003](ADR-003.md) | SQA 稽核閘門介入模式 | Accepted |
| [ADR-004](ADR-004.md) | Retrospective Problem 主題比對機制 | Accepted |
| [ADR-005](ADR-005-schedule-skill-technical-decisions.md) | Schedule Skill 技術決策 | Accepted |
| [ADR-006](ADR-006-prompt-injection-protection.md) | Issue 內容提示注入防護 | Accepted |
| [ADR-007](ADR-007-story-lifecycle-subagent.md) | Story 生命週期 Subagent 封裝 | Accepted |
| [ADR-008](ADR-008.md) | OpenCode 平台整合策略 | Accepted |
| [ADR-009](ADR-009.md) | Backlog Intake 自動化技術決策 | Accepted |
| [ADR-010](ADR-010.md) | Backlog Source of Truth — GitHub Issues 優先策略 | Accepted |
| [ADR-011](ADR-011-github-actions-integration.md) | GitHub Actions 整合架構決策 | Accepted |
| [ADR-012](ADR-012-max-account-rotation.md) | Claude Max 多開發環境認證架構決策 | Accepted |
| [ADR-013](ADR-013-diagram-skill-mcp-integration.md) | shikigami:diagram MCP 整合架構決策 | Accepted |
| [ADR-014](ADR-014-uiux-agent-architecture.md) | UIUX Agent 架構決策 | Accepted |
| [ADR-015](ADR-015-figma-integration.md) | UIUX 管線架構轉型 — Figma 整合取代三層 SSD 管線 | Accepted |
| [ADR-016](ADR-016-uiux-designer-role.md) | UI/UX Designer 角色定義與 Design Foundation 流程 | Accepted |
| [ADR-017](ADR-017-context-hub-knowledge-ingestion.md) | Context Hub 整合架構決策 — Knowledge Ingestion 機制 | Accepted |
| [ADR-018](ADR-018-discovery-phase-architecture.md) | Discovery Phase 架構方案 — 獨立 Skill vs 擴充 backlog-management | Accepted |
| [ADR-019](ADR-019-mcp-three-layer-architecture.md) | MCP 三層架構 — 知識庫 / 流程管理 / 品質觀察 MCP Server | Accepted |
| [ADR-020](ADR-020-sdd-as-ac-upstream-constraint.md) | SDD 作為 AC 的強制上游約束 — 建立 SDD → AC → TDD 追溯鏈 | Accepted |
| [ADR-021](ADR-021-pr-review-toolkit-integration.md) | pr-review-toolkit 外部 Plugin 整合架構 | Accepted |
| [ADR-022](ADR-022-file-level-locking.md) | 檔案級別鎖定機制 — 多 Session 同時編輯衝突防護 | Accepted |
| [ADR-023](ADR-023-pr-based-git-flow.md) | PR-based Git Flow — 從直推 main 遷移至 Pull Request 審查流程 | Accepted |
| [ADR-024](ADR-024-attendance-hook.md) | 出勤時數機制 — SessionStart/End Hook JSONL 紀錄 | Accepted |
| [ADR-025](ADR-025-exploration-record.md) | 探索紀錄收集機制 | Accepted |
| [ADR-026](ADR-026-cruise-mode.md) | Cruise Mode — 巡航模式定期執行機制 | Accepted |
| [ADR-027](ADR-027-ci-permissions.md) | CI 權限 — Claude Code Headless 模式授權策略 | Accepted |
| [ADR-028](ADR-028-multi-sprint-observability.md) | 多 Sprint 觀測 — 多 Runner 統一觀測方案 | Accepted |
| [ADR-029](ADR-029-cruise-close-policy-delivery-chain.md) | Cruise Close Policy + Delivery Chain Per-Repo 可定義 | Accepted |
| [ADR-030](ADR-030-oauth-token-watchdog.md) | Claude OAuth Token Watchdog — 偵測+告警策略 | Accepted |
| [ADR-031](ADR-031-team-debate.md) | 同職能 Team Debate 機制 | Accepted |
| [ADR-032](ADR-032-delivery-path-tiering.md) | 交付路徑分層（/commit vs /shoot vs /sprint-execution） | Accepted |
| [ADR-033](ADR-033-structured-trace-log.md) | Structured Trace Log 架構 | Accepted |
| [ADR-034](ADR-034-browser-automation-tool-selection.md) | Browser Automation 工具選型 | Accepted |
| [ADR-035](ADR-035-tdad-dependency-analysis.md) | TDAD 依賴分析工具選型 | Accepted |
| [ADR-036](ADR-036-schema-first-api-contract.md) | Schema-first API Contract 統一定義架構決策 | Accepted |
| [ADR-037](ADR-037-context-engineering-jit.md) | Context Engineering — Just-in-Time Retrieval 架構決策 | Accepted |
| [ADR-038](ADR-038-kill-switch-design.md) | Kill Switch — 高自治模式緊急停止機制設計 | Accepted |
| [ADR-039](ADR-039-token-cost-routing.md) | Token Cost Routing — Risk-based Model 分級架構決策 | Accepted |
| [ADR-040](ADR-040-tcb-checkpoint-design.md) | TCB 斷點管理 — Agent Action 級 Checkpoint 設計 | Accepted |
| [ADR-041](ADR-041-crash-recovery-design.md) | Temporal-style Crash Recovery — Session 級別恢復設計 | Accepted |
| [ADR-042](ADR-042-session-watchdog-design.md) | Session Watchdog — 存活監控與自動重啟設計 | Accepted |

---

> 建立日期：2026-03-25（Sprint 144，#655）
> 目的：消除 `validate-orphans.sh` 對 docs/adr/ 下 ADR 文件的孤兒 WARNING（263 個中有大量來自此目錄）
