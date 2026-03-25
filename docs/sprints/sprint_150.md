---
sprint: 150
start_date: 2026-03-25
end_date: 2026-03-31
status: done
velocity_baseline: 4.3
capacity: 4
version_target: v0.97.0
---

# Sprint 150

## Sprint Goal

提升框架健壯性與可觀察性 — 修復 stale worktree 死循環、引入消費端健康診斷 Skill、補齊 bug 類 Issue 模板 NFR 欄位。

## Sprint Backlog

| Story | Issue | Type | Size | Points | 狀態 | Assignee | 獨立性 |
|-------|-------|------|------|--------|------|----------|--------|
| fix: cruise 啟動時自動清理 stale worktree（prunable） | #697 | FIX | S | 1 | DONE(#700) | Developer | Wave 1（獨立，修改 skills/cruise/SKILL.md） |
| feat: /shikigami:doctor — 消費端專案健康診斷（檢查→問診→處置→追蹤） | #693 | FEAT | M | 2 | DONE(#701) | Developer | Wave 1（獨立，新增 skills/doctor/SKILL.md） |
| retro: bug 類 Issue Template 補充 NFR 欄位 — 與 enhancement 模板對齊 | #699 | RETRO | S | 1 | DONE(#702) | Developer | Wave 1（獨立，修改 .github/ISSUE_TEMPLATE/bug.md） |

**Sprint 容量**：4 pts（Sprint 147=5, 148=4, 149=4, avg≈4.3；本 Sprint 4pts，三路並行）

**平行分群**：
- Wave 1（可全部平行）：#697（cruise SKILL.md）、#693（新建 doctor SKILL.md）、#699（ISSUE_TEMPLATE/bug.md）

## Architect 技術評估

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | 說明 |
|-------|---------|---------|---------|-------------|------|
| US-#697 | S | 無需 ADR | 不適用 | — | cruise SKILL.md §4 前新增 worktree prune 步驟，bug 修復，無架構涉及 |
| US-#693 | M | 無需 ADR（延用 Health Check 模式，ADR-003） | 不適用 | SDD-000 §Skill 結構 | 新建 skills/doctor/SKILL.md，需同步 plugin.json 版號 bump |
| US-#699 | S | 無需 ADR | 不適用 | — | .github/ISSUE_TEMPLATE/bug.md 新增 NFR 欄位 + issue-management Skill 文件更新 |

## QA 驗收確認

| Story | AC 確認結果 | Path verification | 隱性需求 |
|-------|------------|------------------|---------|
| US-#697 | APPROVED | PASS（skills/cruise/SKILL.md 存在） | reliability: prune 失敗不阻塞 cruise（AC4 `\|\| true` 已覆蓋） |
| US-#693 | APPROVED | N/A（新建檔案，非驗證現有路徑） | performance: 執行時間 < 30s（NFR 已明確定義） |
| US-#699 | APPROVED | PASS（.github/ISSUE_TEMPLATE/bug.md、feature.md、skills/issue-management/SKILL.md 均存在） | accessibility: NFR2 填寫時間 < 2min 已定義 |

## DoD（Definition of Done）

- [x] US-#697：cruise SKILL.md §3.5 + startup-flow.md 新增 worktree prune 步驟（§4 之前），prune 失敗不阻塞（||true）✅
- [x] US-#693：skills/doctor/SKILL.md 四階段流程完整（31 Skills），plugin.json 版號 bump 0.96.2→0.97.0 ✅
- [x] US-#699：.github/ISSUE_TEMPLATE/bug.md NFR 區塊強化，格式與 enhancement 一致，backlog-bridge.md 新增 Bug NFR 指引 ✅

## Retro Action Items（承接自 Sprint 149）

- #698（retro: Backlog 健康度自動檢查 — sprint-candidate < 8 觸發補充信號）→ 排入 Sprint 151（capacity 已達上限）

## Backlog 健康度

Sprint 150 結束後 sprint-candidate 剩餘：1 個（#698）→ 低於健康閾值 8，需於 Sprint 150 Review 後補充 Backlog。
