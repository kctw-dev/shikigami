# Sprint 131

## Sprint Goal
框架品質保障自動化 + shoot 進化 + browser-automation 工具選型 ADR，維持連續 100% 完成率。

## Sprint Backlog

| Story ID | 標題 | Type | Size | Priority | Assignee | Phase |
|----------|------|------|------|----------|----------|-------|
| #555 | retro: 建立 Skill 行數自動偵測腳本 | RETRO | S(1) | should | Developer | Batch 1 |
| #386 | ADR RESEARCH: browser-automation 工具選型 ADR | RESEARCH | M(2) | should | Developer | Batch 1 |
| #556 | retro: CI 升級確認時機明確化 | RETRO | S(1) | should | Developer | Batch 2 |
| #388 | feat: /shoot 進化版 — test→review→PR 一鍵串接 | FEATURE | M(2) | could | Developer | Batch 2 |

## Capacity
- Total: 6 pts (2M + 2S)
- Sprint 130 Velocity: 5 pts (100%)
- Sprint 129 Velocity: 7 pts (100%)
- Baseline: 5-8 pts
- 連續 100%: 第 4 Sprint（Sprint 128+129+130）

## Execution Plan

### Batch 1（可平行）
- #555 Skill 行數自動偵測腳本（S, 1pt）
  - 新增 `scripts/validate-skill-length.sh`
  - 閾值以變數定義於腳本頂部，來源標注 SDD-000 §2.1
  - 大型 Skill 清單以陣列變數管理
  - WARNING 時 exit 0，不中斷 CI
  - 整合至 validate-*.sh 流程
- #386 browser-automation 工具選型 ADR（M, 2pts）
  - 產出 `docs/adr/ADR-034-browser-automation-tool-selection.md`
  - 至少評估 3 方案，統一維度比較
  - ADR 結論 unblock #385

### Batch 2（Batch 1 完成後）
- #556 CI 升級確認時機明確化（S, 1pt）
  - CLAUDE.md 補充 Sprint Planning 前確認時機
  - Sprint Planning Skill Checklist 加入前置項目
- #388 /shoot 進化版（M, 2pts）
  - test → QA review → PR 一鍵串接
  - test 失敗中止 + review 回退機制
  - SKILL.md 行數 <= 350 行

## Risks
- #388 修改 shoot SKILL.md 需控制行數上限（AC4: <= 350 行）
- #386 RESEARCH 需在 2pt 時間盒內完成，避免過度發散
- Batch 2 依賴 Batch 1 完成，序列化風險

## Planning Decisions

### AC 補充（Round 2 QA 回饋）
- #555: 補充 exit code 規格、閾值來源、大型 Skill 陣列管理
- #556: 改寫為 Given-When-Then 可測試格式
- #388: 從零補充完整 AC（4 條 + 非功能需求）
- #386: 從零補充 RESEARCH DoR（ADR 結構、評估維度、時間盒、預期輸出）

### 防漂移檢查
Round 1 選入 4 Stories (6 pts) = Round 2 確認 4 Stories (6 pts)：PASS
