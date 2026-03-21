# Sprint 113

**Sprint Goal**：CI 權限分層落地 — 讓 Runner 依場景選擇權限等級，高風險操作需 Stakeholder Issue 核准
**日期**：2026-03-21
**容量**：5 points
**狀態**：準備中

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| FIX：ADR-027 CI 權限模型改為可選分層 | #324 | M | 5 | 待開始 |

## Acceptance Criteria

### #324 — ADR-027 CI 權限模型改為可選分層（M, 5pt）

> **Type**：FIX
> **修改範圍**：sprint-dispatch.yml（新增 input + 動態 allowedTools 組裝 + approval gate step）、ADR-027（Amendment section）、test-runner-dispatch.sh（擴充測試）
> **Architect 備注**：ADR-027 Amendment，不推翻原決策；permission_level 動態組裝用 case/switch；high 等級 approval 用 Issue 留言 polling（30s 間隔、30min timeout）；允許清單用 repo variable SHIKIGAMI_APPROVERS

**AC-1：workflow input 新增 permission_level**
- `permission_level`：type string，choices low/medium/high，default medium
- 新增至 `.github/workflows/sprint-dispatch.yml` 的 `workflow_dispatch.inputs`

**AC-2：--allowedTools 依 permission_level 動態組裝**
- low：`Read,Grep,Glob`（唯讀）
- medium（預設）：`Bash,Read,Write,Edit,Grep,Glob,WebSearch,WebFetch`（現行 ADR-027）
- high：同 medium（差別在 approval gate）
- 新增「Resolve permission level」step，用 case/switch 設定 `ALLOWED_TOOLS` 環境變數
- Sprint Execution step 改用 `$ALLOWED_TOOLS`

**AC-3：high 等級需 Stakeholder Issue 核准**
- `github.actor` 必須在 repo variable `SHIKIGAMI_APPROVERS` 允許清單
- 或：自動在 Issue 留言請求核准 → polling 等待 approved/rejected
- polling 間隔 30 秒，timeout 30 分鐘
- approved → 繼續；rejected 或 timeout → exit 1
- 核准記錄留在 GitHub Issue，可追溯可審計
- 邊界案例：
  - approval_issue 未指定 + high → fail fast
  - 非 approved/rejected 回覆 → 忽略繼續等待
  - SHIKIGAMI_APPROVERS 為空 → fail fast
  - 多 dispatch 同時 polling → 用 run ID 區分留言

**AC-4：ADR-027 更新 Amendment**
- ADR-027 新增 `## Amendment 1：權限分層（#324）` section
- 記錄分層表格（low/medium/high）
- 原決策（medium）為預設值，不推翻

**AC-5：測試覆蓋**
- test-runner-dispatch.sh 擴充：
  - permission_level input 存在性
  - case/switch 動態組裝邏輯
  - approval gate step 存在性（high path）
  - ALLOWED_TOOLS 環境變數引用

## 技術評估摘要

### Architect 備注

- **ADR-027 Amendment**：原決策不推翻，medium 成為預設值，新增 low/high
- **動態組裝**：case/switch in shell，結果存入 GITHUB_ENV
- **Approval gate**：Issue 留言 polling（shell while loop + sleep 30）
- **允許清單**：repo variable `SHIKIGAMI_APPROVERS`（逗號分隔 GitHub username）
- **跨機器安全**：permission_level 為 dispatch input（無 conflict）；approval 記錄在 Issue 留言（天然多 session 安全）；用 run ID 區分留言避免 race condition
- **風險**：polling 佔用 Runner 時間（30min timeout 可接受）

### QA 備注

- **所有 AC 可驗證**
- AC-1：結構型（YAML input 欄位檢查）
- AC-2：結構型（case/switch 邏輯 + ALLOWED_TOOLS 引用）
- AC-3：結構型 + 行為型（approval gate step + polling 機制）
- AC-4：文件型（ADR-027 Amendment section 存在 + 內容一致）
- AC-5：測試執行型（test script PASS）
- **邊界案例**：5 項已識別（approval_issue 未指定、非標準回覆、timeout 邊界、APPROVERS 為空、多 dispatch race condition）
- **DoR**：PASS
- **防漂移基準**：1 Story, 5 pts
