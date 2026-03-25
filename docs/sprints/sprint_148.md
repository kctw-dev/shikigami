---
sprint: 148
start_date: 2026-03-25
end_date: 2026-03-31
status: in-progress
velocity_baseline: 2.7
capacity: 4
version_target: v0.96.2
---

# Sprint 148

## Sprint Goal

強化框架維護性與可讀性：清理 Cruise SKILL 行數超限、補充 GitHub Issue 模板 NFR 欄位、建立 cruise-logs 自動歸檔機制，提升框架長期健康度。

## Sprint Backlog

| Story | Issue | Type | Size | Points | 狀態 | Assignee | 獨立性 |
|-------|-------|------|------|--------|------|----------|--------|
| chore: logrotate.sh 擴充 — 加入 docs/cruise-logs JSONL 自動歸檔清理 | #682 | CHORE | S | 1 | DONE(#687) | Developer | Wave 1（獨立，修改 scripts/logrotate.sh） |
| chore: GitHub Issue 模板補充 非功能性需求 欄位 — 減少 Sprint Planning 補充工作 | #683 | CHORE | S | 1 | DONE(#688) | Developer | Wave 1（獨立，建立 .github/ISSUE_TEMPLATE/） |
| refactor: cruise/SKILL.md 行數超限重構 — 段落移至 references/ 控制在 250 行以內 | #684 | REFACTOR | M | 2 | DONE(#689) | Developer | Wave 2（獨立，修改 skills/cruise/SKILL.md + references/） |

**Sprint 容量**：4 pts（Sprint 145=2, 146=1, 147=5, avg≈2.7；本 Sprint 4pts 含彈性空間，三個維護性 chore/refactor Story）

**平行分群**：
- Wave 1（可平行）：#682（scripts/logrotate.sh）、#683（.github/ISSUE_TEMPLATE/）
- Wave 2（依序）：#684（skills/cruise/SKILL.md + references/）

## Architect 技術評估

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | 說明 |
|-------|---------|---------|---------|-------------|------|
| US-#682 | S | 無需 ADR | 不適用 | — | Shell script 擴充，無架構涉及；dry-run 模式設計已在 AC 中明確 |
| US-#683 | S | 無需 ADR | 不適用 | — | `.github/ISSUE_TEMPLATE/` 目錄需同時建立；doc-only 性質，無架構涉及 |
| US-#684 | M | 無需 ADR | 不適用 | — | 已有 Sprint 143 #654 重構先例；純文字搬移，不改變任何行為定義；references/ 目錄已存在 |

## QA 驗收確認

| Story | AC 確認結果 | Path verification | 隱性需求 |
|-------|------------|------------------|---------|
| US-#682 | APPROVED | PASS（scripts/logrotate.sh 存在） | NFR: reliability — dry-run 不誤刪 KEEP_DAYS 內檔案，AC4 已定義；NFR2 maintainability — KEEP_DAYS 可環境變數覆蓋，AC 已涵蓋 |
| US-#683 | APPROVED | N/A（目錄尚未存在，工作即是建立） | NFR: completeness — 所有 Issue 類型均更新，NFR1 已定義；NFR2 maintainability — 欄位有說明注釋 |
| US-#684 | APPROVED | PASS（skills/cruise/SKILL.md 352行存在，references/ 存在） | NFR: reliability — 重構不改變行為定義，NFR2 已明確；NFR1 maintainability — 30秒內定位關鍵流程，NFR1 已定義 |

## DoD（Definition of Done）

- [ ] US-#682：scripts/logrotate.sh 新增 cruise-logs 清理邏輯，dry-run 模式可用，測試通過
- [ ] US-#683：.github/ISSUE_TEMPLATE/ 建立/更新，所有 Issue 模板含 NFR 欄位，格式符合 po-prompt.md 規範
- [ ] US-#684：skills/cruise/SKILL.md ≤ 250 行，validate-skills.sh + validate-xrefs.sh + validate-orphans.sh PASS
- [ ] 所有修改 git commit + push 完成
- [ ] 關聯 GitHub Issues 關閉
