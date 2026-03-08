# Sprint 68

**Sprint Goal**：KM 減法 — 移除無用的 DORA Metrics + KM 檔案瘦身

**期間**：2026-03-08 ~ 2026-03-14
**狀態**：進行中
**ADR 依賴**：無

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-178：移除 DORA Metrics — 刪除 sprint-review §2.7 整段、Metrics_Log DORA 區塊、相關 checklist | #172 | S | 1 | 進行中 |
| US-179：BACKLOG_DONE.md 歸檔機制 — 主檔只保留最近 5 個 Sprint | #173 | S | 1 | 進行中 |

## 平行分群

Phase 1：US-178（先行，純刪除操作）
Phase 2：US-179（後行，與 US-178 同修改 SKILL.md，需序列）

## 方法論適用性評估

| Story ID | BDD 建議 | DDD 建議 | 說明 |
|----------|---------|---------|------|
| US-178 | 不適用 | 不適用 | 純刪除操作（doc-only），所有 AC 為靜態驗證 |
| US-179 | 不適用 | 不適用 | 歸檔機制為文件搬移 + SKILL.md 規則新增（doc-only） |

## Acceptance Criteria

### US-178：移除 DORA Metrics

| # | 條件 | 類型 | 通過標準 |
|---|------|------|---------|
| AC1 | `skills/sprint-review/SKILL.md` 中 §2.7「DORA Metrics 計算」整段已刪除 | [靜態] | §2.7 段落不存在 |
| AC2 | SKILL.md 中所有 DORA 相關引用已清除 | [靜態] | 快思/慢想流程描述、角色對照表、checklist、§3 Retrospective 引用中無 DORA |
| AC3 | `docs/km/Metrics_Log.md` 中「## DORA Metrics 記錄」整段已刪除 | [靜態] | DORA 段落不存在 |
| AC4 | `docs/prd/ROADMAP.md` 中 US-13 DORA 記錄保留不動 | [靜態] | 歷史交付記錄不修改 |
| AC5 | `grep -ri "DORA" skills/sprint-review/SKILL.md` 輸出為空 | [一致性] | 零 DORA 引用 |
| AC6 | `grep -c "DORA" docs/km/Metrics_Log.md` 輸出為 0 | [一致性] | 零 DORA 引用 |

### US-179：BACKLOG_DONE.md 歸檔機制

| # | 條件 | 類型 | 通過標準 |
|---|------|------|---------|
| AC1 | 建立 `docs/km/archive/BACKLOG_DONE_ARCHIVE.md` | [靜態] | 檔案存在且包含歸檔標頭 |
| AC2 | BACKLOG_DONE.md 中 Sprint 1-62 記錄搬移至歸檔檔案 | [靜態] | 主檔保留 Sprint 63-67 |
| AC3 | BACKLOG_DONE.md 末尾新增歸檔導覽連結 | [靜態] | 連結指向 BACKLOG_DONE_ARCHIVE.md |
| AC4 | `skills/sprint-review/SKILL.md` §6 歸檔觸發條件新增 BACKLOG_DONE.md 規則 | [靜態] | 歸檔規則涵蓋 BACKLOG_DONE.md |
| AC5 | `wc -l docs/prd/BACKLOG_DONE.md` < 300 行 | [一致性] | 主檔瘦身成功 |
| AC6 | `test -f docs/km/archive/BACKLOG_DONE_ARCHIVE.md` 成功 | [一致性] | 歸檔檔案存在 |
| AC7 | `grep -c "Sprint 1" docs/km/archive/BACKLOG_DONE_ARCHIVE.md` > 0 | [一致性] | 歷史記錄已搬移 |
