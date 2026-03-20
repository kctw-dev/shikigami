# Sprint 109

**Sprint Goal**：完成 AI 團隊績效儀表板，一指令查看當日工作成果
**日期**：2026-03-20
**容量**：4 points
**狀態**：進行中

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| FEATURE：績效儀表板 Skill | #317 | M | 3 | 進行中 |
| INFRA：settle sort key 修正 | retro | S | 1 | 進行中 |

## Acceptance Criteria

### #317 Phase 4 — 績效儀表板（M, 3pt）

> **Type**：FEATURE
> **修改範圍**：`skills/performance-dashboard/SKILL.md`（新建）、`commands/performance-dashboard.md`（新建）
> **Architect 備注**：不需 ADR；儀表板讀 daily-summary，不讀 per-session；會議紀錄直接掃描 docs/meetings/（無需結算）

**AC-1：`/performance-dashboard` 可叫用，輸出 Markdown**
- 新建 Skill 與 Command
- 叫用後輸出 Markdown 格式的績效儀表板

**AC-2：出勤角色列表 + 時數**
- 讀取 `docs/attendance/<date>.summary.jsonl`
- 列出所有出勤角色與計算時數

**AC-3：會議次數 + 連結**
- 掃描 `docs/meetings/` 目錄
- 列出當日會議次數與各會議紀錄連結

**AC-4：探索次數 + top-5**
- 讀取 `docs/exploration/<date>.summary.jsonl`
- 列出探索總次數與 top-5 查詢/URL

**AC-5：日期參數（預設今日）**
- 支援日期參數指定查詢日期
- 無參數時預設為今日

**AC-6：daily-summary 不存在時輸出提示（不自動結算）**
- 當 daily-summary 檔案不存在時，輸出友善提示
- 不自動觸發結算腳本

### settle sort key 修正（S, 1pt）

> **Type**：INFRA
> **修改範圍**：`hooks/attendance-settle.sh`、`hooks/exploration-settle.sh`
> **Architect 備注**：sort key k8 → k16

**AC-1：`attendance-settle.sh` sort key 從 k8 改為 k16**
- `sort -t'"' -k8` → `sort -t'"' -k16`
- 確保按 timestamp 欄位排序

**AC-2：`exploration-settle.sh` 同上**
- `sort -t'"' -k8` → `sort -t'"' -k16`
- 確保按 timestamp 欄位排序

**AC-3：排序結果按 timestamp 正確排序**
- 驗證合併後的 summary.jsonl 按時間順序排列

## 技術評估摘要

### Architect 備注

- **#317 P4 不需 ADR** — 純讀取現有 daily-summary，無新架構決策
- **儀表板讀 daily-summary，不讀 per-session** — 確保結算後的彙整資料為唯一來源
- **會議紀錄直接掃描 docs/meetings/** — 無需結算機制
- **sort key k8 → k16** — JSONL 以 `"` 為分隔符，timestamp 值位於第 16 欄位
- **兩個 Story 可完全平行執行**

### QA 備注

- **所有 AC 可驗證**
- #317 P4：6 項 AC — AC-1 為 Skill/Command 存在型，AC-2 為資料讀取型（出勤），AC-3 為目錄掃描型（會議），AC-4 為資料讀取型（探索），AC-5 為參數型（日期），AC-6 為邊界型（檔案不存在）
- settle sort key：3 項 AC — AC-1/AC-2 為程式碼修改型，AC-3 為排序驗證型
- **DoR**：PASS
- **防漂移基準**：2 Stories, 4 pts
