# Sprint 70

**Sprint Goal**：Provider 路由品質修正 — 宿主平台自動偵測，消除 Gemini CLI 預設值邏輯矛盾

**期間**：2026-03-08 ~ 2026-03-15
**狀態**：進行中
**ADR 依賴**：無

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-181：Provider 路由預設值應偵測宿主平台 — 修正寫死 claude 預設值 | #176 | S | 1 | 待辦 |

## 平行分群

Phase 1：US-181（單一 Story，無分群需求）

## 方法論適用性評估

| Story ID | BDD 建議 | DDD 建議 | 說明 |
|----------|---------|---------|------|
| US-181 | 不建議 | 不適用 | AC 全 [靜態]，偵測邏輯為 LLM 自我認知，非可執行程式碼 |

## Acceptance Criteria

### US-181：Provider 路由預設值應偵測宿主平台 — 修正寫死 claude 預設值

| # | 條件 | 類型 | 通過標準 |
|---|------|------|---------|
| AC1 | `skills/sprint-execution/SKILL.md` §2.1 環境變數定義表格中，`SHIKIGAMI_MODEL_PROVIDER` 預設值欄由 `claude` 改為「宿主平台自動偵測（見偵測規則）」；`SHIKIGAMI_ROLE_PROVIDER_MAP` 預設值欄由「全部 claude」改為「全部使用宿主平台偵測結果」 | [靜態] | 預設值欄位不再寫死 claude |
| AC2 | `skills/sprint-execution/SKILL.md` §2.1 Provider 解析順序的最終 fallback 由 `→ "claude"（預設）` 改為 `→ 宿主平台自動偵測結果`，並新增宿主平台偵測規則說明 | [靜態] | 解析順序末端引用偵測結果而非硬編碼 |
| AC3 | `skills/sprint-execution/story-lifecycle-prompt.md` §0 步驟 1b/1c 中，將 fallback 值 `"claude"` 修正為「宿主平台偵測結果」 | [靜態] | prompt 解析邏輯不再寫死 claude |
| AC4 | SKILL.md §2.1 新增「宿主平台偵測規則」子段落，明確定義三種情境：Claude Code 啟動→claude、Gemini CLI 啟動→gemini、無法判定→claude（保守 fallback） | [靜態] | 偵測規則表存在且涵蓋三種情境 |
| AC5 | SKILL.md §2.1 預設角色 Provider 對照表由固定值 `developer:claude,...` 改為說明「預設所有角色均使用宿主平台偵測結果」，範例保留並標註為「當宿主平台為 Claude Code 時的等效預設值」 | [靜態] | 對照表不再寫死 claude |
| AC6 | 向後相容：已明確設定 `SHIKIGAMI_MODEL_PROVIDER` 或 `SHIKIGAMI_ROLE_PROVIDER_MAP` 的使用者行為不變；未設定任何環境變數且在 Claude Code 中執行的使用者行為維持 claude | [靜態] | 現有使用者行為不受影響 |

### 影響範圍

- `skills/sprint-execution/SKILL.md` — §2.1 Provider 路由段落
- `skills/sprint-execution/story-lifecycle-prompt.md` — §0 Provider 路由段落
