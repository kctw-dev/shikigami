# Sprint 133

## Sprint Goal
提升框架 QA 制衡品質（FREE-MAD + D3 Debate）+ 推進 GAD 研究成果落地（GAD Delivery Phase 視覺對比 Gate），同步完善專案範本降低使用者導入門檻。

## Sprint Backlog

| Story ID | 標題 | Type | Size | Priority | Assignee | Phase |
|----------|------|------|------|----------|----------|-------|
| #397 | feat: QA FREE-MAD 挑戰韌性機制 | FEATURE | S(1) | should | Developer | Batch 1 |
| #407 | feat: 專案範本 — Skills/Hooks/Script 綁定 | FEATURE | S(1) | should | Developer | Batch 1 |
| #403 | feat: D3 Debate Framework（Debate-Deliberate-Decide） | FEATURE | M(2) | should | Developer | Batch 2 | DONE(#578) |
| #385 | feat: GAD 接入 Delivery Phase — 雙 Team 視覺對比 | FEATURE | M(2) | should | Developer | Batch 2 | DONE(#579) |

## Capacity
- Total: 6 pts (2S + 2M)
- Sprint 132 Velocity: 6 pts (100%)
- Sprint 131 Velocity: 6 pts (100%)
- Sprint 130 Velocity: 5 pts (100%)
- Baseline: 5-7 pts（3 Sprint 平均 5.67 pts ± 1）
- 連續 100%: 第 6 Sprint（127+128+129+130+131+132）

## Execution Plan

### Batch 0（主 session 執行，chore，0pt）
- 修正 docs/adr/ADR-034-browser-automation-tool-selection.md 狀態為 Accepted
  （PR#560 已合併，補文件遺漏）

### Batch 1（可平行，SHIKIGAMI_MAX_PARALLEL=2）
- #397 feat: QA FREE-MAD 挑戰韌性機制（S, 1pt）
  - 修改 `agents/qa-engineer.md`，新增明確反證撤回門檻
  - 修改 `skills/sprint-planning/references/qa-prompt.md`，新增 Challenge Protocol 章節
  - 輸出格式：`[QA-CHALLENGE-WITHDRAW]` + `[QA-ESCALATION]` 告警
  - 完成後 patch version bump
- #407 feat: 專案範本 — Skills/Hooks/Script 綁定（S, 1pt）
  - 新建 `templates/project/` 目錄（hooks.json + skills symlink + scripts）
  - 撰寫 README.md onboarding 說明
  - 通過 validate-json.sh + validate-skills.sh

### Batch 2（Batch 1 完成後，序列執行）
- #403 feat: D3 Debate Framework（M, 2pt）
  - 新建 `skills/debate/SKILL.md`（D3 三階段：Debate/Deliberate/Decide）
  - 修改 `agents/architect.md`：加入 D3 觸發條件
  - 修改 `agents/qa-engineer.md`：加入 advocate 角色（Batch 1 完成後無衝突）
  - 通過 validate-skills.sh + validate-agents.sh
  - 完成後 patch version bump
- #385 feat: GAD Delivery Phase 視覺對比 Gate（M, 2pt）（依賴 Batch 0 ADR-034 修正）
  - 修改 `skills/sprint-execution/SKILL.md`：新增 Delivery Phase 視覺對比步驟
  - 修改 `agents/qa-engineer.md`：視覺對比 Gate 操作說明（#403 完成後無衝突）
  - Vision Critic 分數 < 80 → FAIL Gate，阻擋 merge
  - 通過 validate-skills.sh
  - 完成後 patch version bump

## RICE Score 摘要

| Story | Reach | Impact | Confidence | Effort | RICE |
|-------|-------|--------|------------|--------|------|
| #397 QA FREE-MAD | 2 | 2 | 70% | 1 | 2.8 |
| #407 專案範本 | 3 | 2 | 85% | 1 | 5.1 |
| #403 D3 Debate | 2 | 3 | 70% | 2 | 2.1 |
| #385 GAD Delivery | 2 | 3 | 70% | 2 | 2.1 |

## ADR 狀態確認

| Story | ADR 需求 | 狀態 |
|-------|---------|------|
| #397 | 無需 ADR | — |
| #407 | 無需 ADR | — |
| #403 | 建議補 ADR-036（D3 Debate 架構決策） | Optional |
| #385 | ADR-034（Batch 0 修正為 Accepted） | PASS |

## Risks
- #403 和 #385 均修改 agents/qa-engineer.md，Batch 2 必須序列執行（#403 先，#385 後）
- #385 依賴 Batch 0 ADR-034 文件修正，確認 Proposed→Accepted 後才可開始
- Sprint 130 Velocity 僅 5 pts，若 #403 或 #385 超出預期，可退回 Backlog
