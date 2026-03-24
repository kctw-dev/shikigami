# Sprint 127

**日期**：2026-03-24
**Sprint Goal**：鞏固 Sprint Execution 核心品質 — 完成結構重構 + 清除 Skill 技術債

---

## Stories

| Story ID | 標題 | Size | Points | Type | AC 精化 |
|----------|------|------|--------|------|---------|
| #485 | Sprint Execution Skill 結構重構 — story-lifecycle-prompt 模組化拆分 | M | 3 | FEATURE | QA 確認 references/ 已有 6 檔（Sprint 126 部分實作），本 Sprint 完成剩餘項目：AC 驗證 token 壓縮、HARD-RULE 遷移確認 |
| #486 | shoot/SKILL.md 模組化拆分 — 1108 行降至 <=400 行 | S | 2 | FEATURE | QA 修正實際行數為 1108（非 837），目標不變 <=400 行；test-shoot-skill.sh 可能需同步調整 |
| #490 | RESEARCH: #452 拆分評估與最小可交付增量 | S | 1 | RESEARCH | QA 修正 AC4 為「Sprint 128 Planning 前完成拆分」 |
| #488 | Plugin 維護 — LICENSE 檔案 + git tag 同步 | S | 1 | CHORE | QA 要求 AC1 補充 LICENSE 存在性驗證（validate-version.sh 不覆蓋，需獨立檢查） |

**Sprint 容量**：7 points

---

## 平行分群

### Phase 1（全部可平行）
- #485 Sprint Execution 結構重構（M, 3pt）
- #486 shoot/SKILL.md 模組化拆分（S, 2pt）
- #490 RESEARCH: #452 拆分評估（S, 1pt）
- #488 LICENSE + git tag 同步（S, 1pt）

**依賴關係**：無（四個 Stories 檔案路徑無重疊）

---

## Architect 評估摘要

- 4/4 技術可行，T-shirt size 維持
- 無需新建 ADR
- 全部可平行（Phase 1）— 四個 Stories 檔案路徑無重疊

---

## QA 回饋處理紀錄

| Story | QA Round 1 結果 | PO Round 2 處理 |
|-------|----------------|----------------|
| #485 | references/ 已有 6 個檔案，Sprint 126 部分實作 | 採納。Story 仍排入，聚焦完成剩餘項目（token 壓縮驗證、HARD-RULE 遷移確認） |
| #486 | 實際 1108 行（非 837），test-shoot-skill.sh 需同步 | 採納。更正行數描述，目標 <=400 行不變，測試同步列入 AC 注意事項 |
| #490 | AC4 需修正為「Sprint 128 Planning 前完成拆分」 | 採納。AC4 時限對齊 Sprint 128 Planning |
| #488 | AC1 需補充 LICENSE 存在性驗證 | 採納。新增獨立驗證步驟（validate-version.sh 不覆蓋此項） |
