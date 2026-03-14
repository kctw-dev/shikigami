# Sprint 95

**Sprint Goal**：強化 Architect 審查 Gate 的分層合規性檢查能力
**日期**：2026-03-14
**容量**：2 points
**狀態**：進行中

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-257：Architect 審查 Gate 加入 Layer Compliance 分層合規檢查 | #254 | S | 2 | 完成 |

## Acceptance Criteria 摘要

### US-257

- **AC1**：`skills/shoot/SKILL.md` 的 Architect 審查章節新增三個 Layer Compliance checklist 項目：共用常數/設定層級檢查、跨模組 import 方向檢查、Single Source of Truth 檢查
- **AC2**：`agents/architect.md` 新增「Layer Compliance 審查標準」段落，明確列出三種違規模式：常數層級錯置、import 方向違規、語意常數重複定義
- **AC3**：`agents/qa-engineer.md` 新增「QA Pre-flight 檢查提示」段落，包含分層違規靜態分析提示；級別為 WARN，不影響 Pre-flight PASS/FAIL 判定
- **AC4**：三個檔案中「Layer Compliance」用詞一致
- **AC5**：現有內容不被刪除或語意改變
- **AC6**：SKILL.md 輸出範例（第 13 節）同步新增 Architect 審查 Layer Compliance 輸出行

## 技術評估摘要

- US-257：S/2pt，FEATURE type（doc-only）。修改三個 .md 檔案：skills/shoot/SKILL.md、agents/architect.md、agents/qa-engineer.md。無 ADR 需求，無 API 契約。S-size 豁免 Refinement。

## Refinement 記錄

- US-257：S-size 豁免，無需 Refinement
