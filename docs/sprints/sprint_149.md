---
sprint: 149
start_date: 2026-03-25
end_date: 2026-03-31
status: done
velocity_baseline: 3.3
capacity: 4
version_target: v0.96.2
---

# Sprint 149

## Sprint Goal

強化框架可靠性基線 — 補齊 onboarding hooks 安裝缺口、鎖定 Sprint Review 版號一致性硬性門禁、更新 Backlog Bridge 以確保新 Issue 格式完整性。

## Sprint Backlog

| Story | Issue | Type | Size | Points | 狀態 | Assignee | 獨立性 |
|-------|-------|------|------|--------|------|----------|--------|
| fix: onboarding 流程缺少 claim/release hooks 安裝步驟 | #692 | FIX | S | 1 | DONE(#695) | Developer | Wave 1（獨立，修改 onboarding skill） |
| retro: Sprint Review §1.5 加入 ROADMAP.md 版號一致性硬性檢查 | #690 | RETRO | S | 1 | DONE(#694) | Developer | Wave 1（獨立，修改 sprint-review/SKILL.md） |
| retro: Backlog Bridge 流程更新 — 引導新 Issue 使用 .github/ISSUE_TEMPLATE 模板 | #691 | RETRO | M | 2 | DONE(#696) | Developer | Wave 2（獨立，修改 issue-management skill） |

**Sprint 容量**：4 pts（Sprint 146=1, 147=5, 148=4, avg≈3.3；本 Sprint 4pts，Backlog 耗盡）

**平行分群**：
- Wave 1（可平行）：#692（onboarding skill）、#690（sprint-review/SKILL.md）
- Wave 2（接續）：#691（issue-management skill）

## Architect 技術評估

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | 說明 |
|-------|---------|---------|---------|-------------|------|
| US-#692 | S | 無需 ADR | 不適用 | — | onboarding 流程補充 hooks 安裝步驟，無架構涉及 |
| US-#690 | S | 無需 ADR | 不適用 | — | Sprint Review SKILL.md §1.5 新增版號一致性硬性檢查，doc 行為變更 |
| US-#691 | M | 無需 ADR | 不適用 | — | Backlog Bridge 流程更新，引導使用 ISSUE_TEMPLATE，doc 行為變更 |

## QA 驗收確認

| Story | AC 確認結果 | Path verification | 隱性需求 |
|-------|------------|------------------|---------|
| US-#692 | APPROVED | PASS（onboarding skill 存在） | hooks 複製到消費端 hooks/，來源 ${CLAUDE_PLUGIN_ROOT}/hooks/，cruise self-heal 偵測 [WARN] |
| US-#690 | APPROVED | PASS（sprint-review/SKILL.md 存在） | 版號不一致時 Sprint Review 必須 FAIL，不可僅警告 |
| US-#691 | APPROVED | PASS（issue-management skill 存在） | 以 ISSUE_TEMPLATE 為基礎追加 BB 專屬欄位 |

## DoD（Definition of Done）

- [x] US-#692：onboarding 流程包含 claim/release hooks 安裝步驟，cruise self-heal 可偵測缺漏
- [x] US-#690：Sprint Review §1.5 版號一致性為硬性檢查，不一致時 Review FAIL
- [x] US-#691：Backlog Bridge 引導新 Issue 使用 ISSUE_TEMPLATE 模板，格式完整性提升
- [x] 所有修改 git commit + push 完成
- [x] 關聯 GitHub Issues 關閉
