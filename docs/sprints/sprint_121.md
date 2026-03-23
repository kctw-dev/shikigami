# Sprint 121 — Sprint 運作韌性強化

**Sprint Goal**：強化 Sprint 運作韌性：解決外部依賴阻塞問題、修復 CI 環境缺陷、提升 Sprint Review 效率，確保流程不再因單點故障而停滯。
**期間**：2026-03-23 ~ 2026-03-30
**Velocity 目標**：10 pts（Sprint 120: 10 pts）

## Sprint Backlog

| # | Story | Size | Points | MoSCoW | 狀態 |
|---|-------|------|--------|--------|------|
| #434 | retro: Sprint 被外部依賴阻塞時應自動 bypass 並推進 backlog | M | 3 | Must | 完成（PR #439） |
| #436 | retro: Self-hosted runner 環境標準化 — 確保必要工具預裝 | S | 2 | Must | 完成（PR #438） |
| #435 | retro: Shoot 模式邏輯依賴驗證 — code-review checklist 加入依賴檢查 | S | 1 | Must | 完成（PR #437） |
| #420 | feat: Sprint Review 拆成 Review + Retro 兩個平行 subagent | M | 3 | Should | 完成（PR #440） |
| #401 | feat: Scrum Master 調度狀態圖文件（Mermaid） | S | 1 | Should | 完成（PR #441） |

## 技術決策

- #434 修改 cruise SKILL.md PO 巡邏 Step 5/6，新增「Sprint 實質完成」偵測邏輯（Architect 建議：BLOCKED_SPRINT_STORIES == TOTAL_SPRINT_STORIES）
- #436 新建 scripts/runner-setup.sh + runner checklist 文件
- #435 修改 quality-gate SKILL.md 第 6 節 code-review checklist，新增「邏輯依賴驗證」段落
- #420 重構 sprint-review SKILL.md，拆分 S2（Review）與 S3（Retro）為平行可執行段落，S3 Analytics 可提前平行
- #401 新建 docs/sdd/scrum-master-state-graph.md（Mermaid stateDiagram-v2）

## 獨立性評估

| Story | 修改檔案 | 獨立性 |
|-------|---------|--------|
| #434 | skills/cruise/SKILL.md（PO 巡邏段落） | 獨立 |
| #436 | scripts/runner-setup.sh, docs/km/ | 獨立 |
| #435 | skills/quality-gate/SKILL.md（checklist 段落） | 獨立 |
| #420 | skills/sprint-review/SKILL.md | 獨立 |
| #401 | docs/sdd/ 新建文件 | 獨立 |

## 平行分群

### Phase 1（全部可平行執行）
| Story | 標題 | Size | 說明 |
|-------|------|------|------|
| #434 | Sprint 阻塞 bypass | M | 修改 PO 巡邏邏輯 |
| #436 | Runner 環境標準化 | S | 新建 infra 腳本 |
| #435 | 邏輯依賴驗證 | S | 修改 checklist |
| #420 | Sprint Review 平行化 | M | 重構 Sprint Review |
| #401 | SM 狀態圖 | S | 新建文件 |
