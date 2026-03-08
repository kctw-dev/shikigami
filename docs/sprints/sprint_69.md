# Sprint 69

**Sprint Goal**：Developer Provider 路由落地 — Gemini CLI 自動 Fallback 派遣機制

**期間**：2026-03-08 ~ 2026-03-15
**狀態**：進行中
**ADR 依賴**：無

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-180：Developer 角色 Provider 路由 — 支援 Gemini CLI 可切換派遣（環境變數控制） | #175 | S | 1 | 進行中 |

## 平行分群

Phase 1：US-180（單一 Story，無分群需求）

## 方法論適用性評估

| Story ID | BDD 建議 | DDD 建議 | 說明 |
|----------|---------|---------|------|
| US-180 | 建議（B1, B2） | 不適用 | AC 含多執行路徑（Provider 路由 + 自動 Fallback），BDD 可驗證路徑覆蓋 |

## Acceptance Criteria

### US-180：Developer 角色 Provider 路由 — 支援 Gemini CLI 可切換派遣（環境變數控制）

| # | 條件 | 類型 | 通過標準 |
|---|------|------|---------|
| AC1 | `SHIKIGAMI_ROLE_PROVIDER_MAP` 與 `SHIKIGAMI_MODEL_PROVIDER` 均未設定（或預設值）時，Developer 派遣行為與現行完全一致（Claude Agent tool） | [靜態] | 預設路徑無行為變更 |
| AC2 | `SHIKIGAMI_ROLE_PROVIDER_MAP` 設定 `developer:gemini` 時，Developer 任務透過 Gemini CLI 執行。支援模型指定格式 `developer:gemini:gemini-3.1-pro-preview` | [動態] | Gemini CLI 被正確調用，模型參數正確傳遞 |
| AC3 | Gemini CLI 失敗（exit code != 0 / timeout / quota / 認證失敗）時自動 fallback 至 Claude Agent tool，輸出 `[FALLBACK] Gemini CLI 失敗，切回 Claude` 告警，不中斷流程。此 AC 變更現行 SKILL.md §2.1 Fallback 行為（從手動改為自動） | [動態] | Fallback 自動觸發 + 告警訊息輸出 + 流程不中斷 |
| AC4 | 指定的 Gemini 模型不存在（Gemini CLI 回傳 ModelNotFoundError）時 fallback 至 Claude，不靜默降級至其他 Gemini 模型 | [動態] | ModelNotFoundError 觸發 fallback，非靜默降級 |

### 影響範圍

- `skills/sprint-execution/story-lifecycle-prompt.md` — Developer 派遣步驟新增 Provider 路由（模型指定格式 + 自動 fallback）
- `skills/sprint-execution/SKILL.md` — §2.1 Fallback 行為更新（手動→自動）、模型指定格式擴充
