# Sprint 112

**Sprint Goal**：讓 Shikigami Sprint 可從 GitHub Actions 動態觸發，對任意 repo 執行 headless Sprint
**日期**：2026-03-21
**容量**：10 points
**狀態**：完成

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| FEATURE：GitHub Actions Runner 動態 Sprint 派遣 | #323 | L | 10 | 完成 |

## Acceptance Criteria

### #323 — GitHub Actions Runner 動態 Sprint 派遣（L, 10pt）

> **Type**：FEATURE
> **修改範圍**：新增 workflow YAML（sprint-dispatch.yml）、ADR-027（CI 權限）、ADR-028（多 Sprint 觀測）、觀測機制三層（stdout 標記 / per-session log push / Issue 留言）、測試腳本
> **Architect 備注**：ADR-027 選項 C（`--allowedTools`），MCP 不啟動；ADR-028 選項 A+D（Actions UI + 中央 Issue 留言）

#### Phase 1（workflow + headless + session ID）

**AC-1：Workflow YAML**
- `.github/workflows/sprint-dispatch.yml` 存在
- `workflow_dispatch` inputs：`target_repo`（required）、`sprint_command`（required）、`timeout_minutes`（optional, default 120）
- concurrency group：不設 concurrency（靠 #312 claim 機制協調 Story 互斥，同 repo 多 runner 可平行）

**AC-2：Headless 執行**
- `--allowedTools` 或等效 headless 權限配置，確保 Claude Code 無需人工確認
- MCP Server 不啟動（CI 環境降級）

**AC-3：Session ID**
- `CLAUDE_SESSION_ID=${{ github.run_id }}`（使用 GitHub Run ID 作為 Session ID）

#### Phase 2（三層觀測）

**AC-4：Layer 1 — stdout 標記格式**
- 所有關鍵事件輸出 `[SHIKIGAMI] event=<type> ...` 格式至 stdout
- GitHub Actions Log 天然收集 stdout，無額外動作

**AC-5：Layer 2 — per-session log push**
- Workflow step 4（或等效位置），`if: always()` 條件
- 將 per-session log 檔案 commit + push 回 repo

**AC-6：Layer 3 — Issue 留言（opt-in）**
- 環境變數 `SHIKIGAMI_LIVE_NOTIFY=true` 開啟
- `SHIKIGAMI_LIVE_NOTIFY_ISSUE=<N>` 指定留言目標 Issue
- 關鍵事件自動 `gh issue comment`

**AC-7：三層 failure isolation**
- 任一觀測層失敗不影響 Sprint 主流程
- 任一觀測層失敗不影響其他觀測層

#### Phase 3（ADR）

**AC-8：ADR-027 — CI 權限**
- 決策：`--allowedTools`（選項 C）+ MCP 降級（不啟動）
- 涵蓋 Claude Code headless 模式、GH_TOKEN、GitHub App token / PAT

**AC-9：ADR-028 — 多 Sprint 觀測**
- 決策：Actions UI（A）+ 中央 Issue 留言（D）組合
- 涵蓋多 Runner 對不同 repo 同時跑 Sprint 的統一觀測方案

#### Phase 4（測試）

**AC-10：test-runner-dispatch.sh**
- 覆蓋 workflow YAML 結構驗證（inputs / concurrency / steps）
- 覆蓋觀測機制驗證（stdout 標記格式 / per-session log push step / Issue 留言 opt-in）
- 與 protect-main.sh 相容（不衝突）

## 技術評估摘要

### Architect 備注

- **ADR-027**：`--allowedTools`（選項 C），MCP 不啟動（CI 環境無 MCP 依賴）
- **ADR-028**：Actions UI + 中央 Issue 留言（A+D 組合）
- **concurrency**：不設 concurrency（同 repo 多 runner 可平行，靠 #312 claim 機制協調 Story 互斥）
- **timeout**：可配（預設 120 min）
- **4 Phase 串行**：workflow → 觀測 → ADR → 測試

### QA 備注

- **所有 AC 可驗證**
- AC-1：結構型（YAML 檔案存在 + inputs/concurrency 欄位檢查）
- AC-2：結構型（headless 配置存在性檢查）
- AC-3：結構型（env 設定檢查）
- AC-4：格式型（stdout 輸出格式 regex 驗證）
- AC-5：結構型（workflow step `if: always()` 檢查）
- AC-6：行為型（env 變數 + gh issue comment 機制檢查）
- AC-7：隔離型（各層獨立 try/catch 或 `|| true` 機制）
- AC-8：文件型（ADR-027 存在 + 決策內容一致性）
- AC-9：文件型（ADR-028 存在 + 決策內容一致性）
- AC-10：測試執行型（test script PASS）
- **DoR**：PASS
- **防漂移基準**：1 Story, 10 pts
