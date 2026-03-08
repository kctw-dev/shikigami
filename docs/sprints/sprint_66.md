# Sprint 66

**Sprint Goal**：CLI Adapter Phase 3 SKILL.md 整合 — 建立雙軌派遣機制，讓框架能透過 cli-adapter.sh 派遣 Gemini 執行特定角色任務，實現角色→Provider 路由。

**期間**：2026-03-08 ~ 2026-03-14
**狀態**：完成
**ADR 依賴**：無

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-176：CLI Adapter Phase 3 -- SKILL.md 整合與角色→Provider 路由機制 | #170 | M | 2 | 完成 |

## 平行分群

Phase 1：US-176（獨立執行）

## 方法論適用性評估

| Story ID | BDD 建議 | DDD 建議 | 說明 |
|----------|---------|---------|------|
| US-176 | 不適用 | 不適用 | 純文件修改（SKILL.md / prompt.md），無行為規格或領域模型需求 |

## Acceptance Criteria

### US-176：CLI Adapter Phase 3 -- SKILL.md 整合與角色→Provider 路由機制

| # | 條件 | 類型 | 通過標準 |
|---|------|------|---------|
| AC1 | `sprint-execution/SKILL.md` 新增 Provider 路由配置區段 | [靜態] | 在 §3 執行流程前新增 §2.1「Provider 路由」區段，定義 `SHIKIGAMI_MODEL_PROVIDER` 環境變數偵測邏輯與 `SHIKIGAMI_ROLE_PROVIDER_MAP` 角色對照變數格式 |
| AC2 | `sprint-execution/SKILL.md` Story-Lifecycle 派遣邏輯支援雙軌 | [靜態] | §3 步驟 3 的 subagent 派遣描述新增條件分支：當 provider=claude 時使用 Agent tool（現行模式），當 provider=gemini 時改用 Bash 呼叫 `scripts/cli-adapter.sh` 並以 stdin pipe 傳入 prompt |
| AC3 | `story-lifecycle-prompt.md` 新增 Provider-Aware 說明 | [靜態] | 角色定義區塊新增說明：本 prompt 可被 Claude Agent tool 或 cli-adapter.sh 載入執行，行為不因派遣方式改變 |
| AC4 | 角色→Provider 對照表定義 | [靜態] | `sprint-execution/SKILL.md` §2.1 包含預設角色→Provider 對照表（預設全 claude，使用者可透過環境變數覆寫），格式為 `SHIKIGAMI_ROLE_PROVIDER_MAP="developer:gemini,qa:gemini,po:claude,architect:claude"` |
| AC5 | Fallback 行為文件化 | [靜態] | §2.1 明確記載：Gemini CLI 呼叫失敗時自動 fallback 回 Claude（繼承 cli-adapter.sh 既有行為），Sprint 執行不中斷 |
| AC6 | 手動切換機制文件化 | [靜態] | §2.1 包含使用者操作指引：(a) 設定 `SHIKIGAMI_MODEL_PROVIDER=gemini` 切換全域 provider、(b) 設定 `SHIKIGAMI_ROLE_PROVIDER_MAP` 切換特定角色 provider |
