# Sprint 108

**Sprint Goal**：修復出勤紀錄跨機器 conflict + 落地探索紀錄收集
**日期**：2026-03-20
**容量**：4 points
**狀態**：已完成

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：出勤紀錄 per-session + 結算 | #319 | M | 2 | 完成 |
| FEATURE：探索紀錄收集（#317 P3） | #317 | M | 2 | 完成 |

## Acceptance Criteria

### #319 — 出勤紀錄跨機器修復（M, 2pt）

> **Type**：INFRA
> **修改範圍**：`hooks/session-start`、`hooks/session-end-release.sh`、`hooks/attendance-settle.sh`（新建）、`docs/attendance/`
> **Architect 備注**：更新 ADR-024 Amendment，per-session 命名

**AC-1：每個 session 寫入獨立 `YYYY-MM-DD-session-<session_id>.jsonl`**
- `hooks/session-start` 與 `hooks/session-end-release.sh` 改用 per-session 檔案
- 檔名格式：`YYYY-MM-DD-session-<session_id>.jsonl`
- 不再寫入共用的 `YYYY-MM-DD.jsonl`（消除跨機器 conflict）

**AC-2：`hooks/attendance-settle.sh` 合併同日檔案為 `YYYY-MM-DD.summary.jsonl`**
- 新建結算腳本 `hooks/attendance-settle.sh`
- 掃描 `docs/attendance/YYYY-MM-DD-session-*.jsonl`
- 合併為 `docs/attendance/YYYY-MM-DD.summary.jsonl`

**AC-3：跨機器不再 conflict**
- per-session 檔案各自獨立，不共用同一檔案
- 驗證：兩個不同 session_id 同時寫入不產生 merge conflict

### #317 Phase 3 — 探索紀錄收集（M, 2pt）

> **Type**：FEATURE
> **修改範圍**：PreToolUse hook、`hooks/exploration-settle.sh`（新建）、`docs/exploration/`
> **Architect 備注**：需 ADR-025 + PreToolUse spike

**AC-1：WebSearch/WebFetch 後 append 到 `docs/exploration/YYYY-MM-DD-session-<id>.jsonl`**
- PreToolUse hook 攔截 WebSearch / WebFetch 工具呼叫
- 紀錄 append 至 `docs/exploration/YYYY-MM-DD-session-<session_id>.jsonl`

**AC-2：`hooks/exploration-settle.sh` 合併為 daily-summary**
- 新建結算腳本 `hooks/exploration-settle.sh`
- 掃描 `docs/exploration/YYYY-MM-DD-session-*.jsonl`
- 合併為 `docs/exploration/YYYY-MM-DD.summary.jsonl`

**AC-3：跨機器不 conflict（per-session 檔案）**
- 每個 session 獨立檔案，不共用同一檔案
- 驗證同 #319 AC-3

**AC-4：欄位完整（session_id, role, event, timestamp, repo, tool, query_or_url）**
- JSONL 每行為完整 JSON 物件
- 必要欄位：`session_id`、`role`、`event`、`timestamp`（ISO 8601）、`repo`、`tool`（WebSearch/WebFetch）、`query_or_url`

**AC-5：測試覆蓋**
- 測試腳本驗證 JSONL 格式正確性
- 測試腳本驗證結算合併行為
- 測試腳本驗證跨 session 不 conflict

## 技術評估摘要

### Architect 備注

- **#319 更新 ADR-024 Amendment** — per-session 命名消除跨機器 conflict
- **#317 P3 需 ADR-025** — 探索紀錄收集架構決策 + PreToolUse spike
- **執行序**：#319 → #317 P3（#319 的 per-session 模式為 #317 P3 提供模板）
- per-session 命名：`YYYY-MM-DD-session-<session_id>.jsonl`
- `protect-main.sh` 需加 `^docs/exploration/` 豁免路徑
- 結算先各自獨立（`attendance-settle.sh` 與 `exploration-settle.sh`）

### QA 備注

- **所有 AC 可驗證**
- #319：3 項 AC — AC-1 為 hook 修改型（檔名格式驗證），AC-2 為新腳本型（結算合併邏輯），AC-3 為並行安全型（多 session 模擬）
- #317 P3：5 項 AC — AC-1 為 PreToolUse hook 型（攔截 + 寫入），AC-2 為結算型（合併邏輯），AC-3 為並行安全型，AC-4 為 schema 型（JSONL 解析），AC-5 為測試覆蓋型
- **DoR**：PASS
- **防漂移基準**：2 Stories, 4 pts
