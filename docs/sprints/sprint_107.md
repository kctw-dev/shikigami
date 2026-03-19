# Sprint 107

**Sprint Goal**：落地 AI 團隊識別碼統一規範與出勤時數可視化
**日期**：2026-03-20
**容量**：4 points
**狀態**：進行中

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：編號統一 — US-#N + ADR claim 鎖 | #318 | M | 2 | 待開發 |
| FEATURE：出勤時數 — 角色簽到/簽退（#317 P2） | #317 | M | 2 | 待開發 |

## Acceptance Criteria

### #318 — 編號統一（M, 2pt）

> **Type**：INFRA
> **修改範圍**：42 個檔案批量替換 + PO prompt 修正 + claim-issue.sh ADR claim 支援

**AC-1：Sprint 文件使用 US-#N 格式**
- 既有 Sprint 文件中的自編 US-XXX 格式統一替換為 US-#N（對應 GitHub Issue 編號）
- 42 個檔案批量替換

**AC-2：PO subagent 不再自行編 US 編號**
- PO prompt 移除自編 US 編號邏輯
- 新 Story 統一使用 GitHub Issue # 作為唯一識別碼

**AC-3：ADR 建立前執行 claim（`refs/claims/adr-NNN`）**
- ADR 建立前必須先透過 `claim-issue.sh adr-NNN` 取得 claim
- 防止多 session 同時建立同一 ADR 編號
- claim-issue.sh 已支援任意字串 ID，直接複用

**AC-4：既有文件引用向後相容（舊 US-XX 不改）**
- 已完成 Sprint 中的舊 US-XX 引用保持不變
- 僅修正活躍/模板文件中的格式

### #317 Phase 2 — 出勤時數（M, 2pt）

> **Type**：FEATURE
> **修改範圍**：`hooks/session-start` + `hooks/session-end-release.sh` + `docs/attendance/`
> **Architect 建議**：新建 ADR-024（出勤機制決策），方案 A（SessionStart/End hook）

**AC-1：SessionStart hook 寫入 checkin 紀錄（JSONL）**
- `hooks/session-start` 新增出勤簽到邏輯
- 紀錄寫入 `docs/attendance/YYYY-MM-DD.jsonl`

**AC-2：SessionEnd hook 寫入 checkout 紀錄**
- `hooks/session-end-release.sh` 新增出勤簽退邏輯
- 紀錄寫入同一 JSONL 檔案

**AC-3：紀錄含 session_id, role, event, timestamp, repo**
- JSONL 每行為完整 JSON 物件
- 必要欄位：`session_id`、`role`、`event`（checkin/checkout）、`timestamp`（ISO 8601）、`repo`

**AC-4：多 session 併發寫入安全（flock 保護）**
- JSONL 寫入使用 flock 保護
- 防止多 session 同時寫入導致資料損壞

**AC-5：`docs/attendance/` 加入狀態文件豁免清單**
- 出勤紀錄不觸發版號檢查等狀態驗證
- 加入 `.gitignore` 或對應豁免機制

## 技術評估摘要

### Architect 備注

- **#318 不需要 ADR** — 42 個檔案批量替換，不涉及架構變更
- **#317 P2 建議 ADR-024** — 出勤機制決策，方案 A（SessionStart/End hook）
- ADR-024 建立時可直接使用 claim 機制（`claim-issue.sh adr-024`）
- JSONL 格式，不自動 commit
- 兩個 Story 可完全平行執行

### QA 備注

- **所有 AC 可驗證**
- #318：4 項 AC — AC-1/AC-2 為批量替換型（grep 驗證），AC-3 為 claim 機制型（claim-issue.sh 已支援），AC-4 為 no-op 驗證
- #317 P2：5 項 AC — AC-1/AC-2 為 hook 擴充型，AC-3 為 schema 型（JSONL 解析），AC-4 為併發安全型（flock 測試），AC-5 為配置型
- claim-issue.sh 已支援任意字串 ID（`REF="refs/claims/${ID}"`），#318 AC-3 直接複用
- **DoR**：PASS
- **防漂移基準**：2 Stories, 4 pts
