---
sprint: 144
start_date: 2026-03-25
end_date: 2026-03-31
status: done
velocity_baseline: 4.7
capacity: 6
version_target: v0.96.1
---

# Sprint 144

## Sprint Goal

消除框架 validate-orphans.sh 長期 263 WARNING 噪音，補強驗證腳本覆蓋完整性，並完成 TDAD 設定關閉功能，提升框架可維護性與開發者體驗。

## Sprint Backlog

| Story | Issue | Type | Size | Points | 狀態 | Assignee | 獨立性 |
|-------|-------|------|------|--------|------|----------|--------|
| retro: 驗證 validate-skills.sh 覆蓋完整性 | #667 | RETRO | S | 1 | DONE(#669) | Developer | Wave 1（獨立） |
| feat: TDAD 依賴分析可透過設定關閉 | #653 | FEAT | S | 1 | DONE(#670) | Developer | Wave 1（獨立） |
| chore: ADR index 修復 263 WARNING | #655 | CHORE | M | 3 | DONE(#671) | Developer | Wave 1（獨立） |
| feat: validate-orphans.sh 豁免清單機制 | #658 | FEAT | S | 1 | DONE(#672) | Developer | Wave 2（依賴 #655） |

**Sprint 容量**：6 pts（Sprint 141=2, 142=5, 143=6, avg≈4.7, 建議 5-6 pts）

**平行分群**：
- Wave 1（可平行）：#667、#653、#655 — 修改不同檔案，可同時執行
- Wave 2（依賴 Wave 1）：#658 — 需在 #655 ADR index 完成後執行，確認 validate-orphans.sh 行為

## Retro Action Items 處置

- #667（retro-action）：已排入 Sprint 144，驗證 validate-skills.sh 覆蓋範圍
- #668（retro-action，#658 升級決策）：#658 已排入 Sprint 144，#668 AC1 達成，Planning 完成後關閉

## 技術評估摘要（Architect）

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | 說明 |
|-------|---------|---------|---------|-------------|------|
| US-#667 | S | 無需 ADR | 不適用 | — | 驗證腳本覆蓋性確認，可能無需修改腳本 |
| US-#653 | S | 無需 ADR | 不適用 | — | developer-prompt.md 加入 tdad=false 跳過條件 |
| US-#655 | M | 無需 ADR | 不適用 | — | 新增 docs/adr/README.md 含 ADR-020~042 索引 |
| US-#658 | S | 無需 ADR | 不適用 | — | scripts/validate-orphans.sh + .orphan-allowlist |

## QA 驗收確認

| Story | AC 確認 | Path Verification | 隱性需求補充 |
|-------|---------|------------------|------------|
| US-#667 | PASS | PASS（scripts/validate-skills.sh 存在） | NFR: reliability — validate 輸出 SKILL 數量與實際一致 |
| US-#653 | PASS | PASS（skills/sprint-execution/developer-prompt.md 存在） | NFR: compatibility — 未設定 tdad 時行為不變 |
| US-#655 | PASS | PASS（docs/adr/ 目錄存在） | NFR: maintainability — ADR index 建立後 WARNING 歸零 |
| US-#658 | PASS | PASS（scripts/validate-orphans.sh 存在） | NFR: maintainability — .orphan-allowlist 格式說明清楚 |

## Story 獨立性評估

| Story | 預計修改主要檔案 | 衝突 |
|-------|----------------|------|
| #667 | scripts/validate-skills.sh（若需修改），Issue 留言驗證結果 | 無 |
| #653 | skills/sprint-execution/developer-prompt.md | 無 |
| #655 | docs/adr/README.md（新增），scripts/validate-orphans.sh（若採豁免方案） | 若採豁免：與 #658 有順序依賴 |
| #658 | scripts/validate-orphans.sh，.orphan-allowlist（新增） | 依賴 #655（Wave 2） |
