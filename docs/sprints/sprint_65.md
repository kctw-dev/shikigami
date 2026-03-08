# Sprint 65

**Sprint Goal**：Subagent 模型自動調度完善 — 補齊所有 subagent 派遣點的 model 參數標注，建立角色→模型對照表，實現成本分層（haiku/sonnet/opus 三級）自動化。

**期間**：2026-03-08 ~ 2026-03-14
**狀態**：進行中
**ADR 依賴**：無

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-175：Subagent 多模型自動調度 — 角色對照表建立與派遣點 model 參數補齊 | #169 | S | 1 | 待辦 |

## 平行分群

Phase 1：US-175（獨立執行）

## 方法論適用性評估

| Story ID | BDD 建議 | DDD 建議 | 說明 |
|----------|---------|---------|------|
| US-175 | 不適用 | 不適用 | 純文件修改（SKILL.md model 參數補齊），無行為規格或領域模型需求 |

## Acceptance Criteria

### US-175：Subagent 多模型自動調度 — 角色對照表建立與派遣點 model 參數補齊

| # | 條件 | 類型 | 通過標準 |
|---|------|------|---------|
| AC1 | `sprint-review/SKILL.md` DORA subagent 派遣點補齊 model 參數 | [靜態] | S2.7 DORA subagent 派遣描述中包含 `model: "haiku"` 明確指定 |
| AC2 | `sprint-review/SKILL.md` Analytics subagent 派遣點補齊 model 參數 | [靜態] | S3 步驟 0 Analytics subagent 派遣指令中包含 `model: "haiku"` 明確指定 |
| AC3 | `sprint-review/SKILL.md` Metrics subagent 派遣點補齊 model 參數 | [靜態] | Sprint Metrics 計算指引與 Token 成本摘要指引中 Metrics subagent 派遣處包含 `model: "haiku"` 明確指定 |
| AC4 | `sprint-review/SKILL.md` 歸檔 subagent 派遣點補齊 model 參數 | [靜態] | S6 歸檔 subagent 派遣描述中包含 `model: "haiku"` 明確指定 |
| AC5 | `sprint-review/SKILL.md` 模型選用建議區塊更新 | [靜態] | 模型選用建議（第 39-44 行區塊）更新為完整的角色→模型對照表，區分 sonnet（PO/Stakeholder）與 haiku（DORA/Analytics/Metrics/歸檔）用途 |
| AC6 | `story-lifecycle-prompt.md` 補充角色→模型說明 | [靜態] | 在角色定義區塊或輸入格式區塊中，說明本 subagent 由主 session 以 `model: "sonnet"` 派遣，Developer/QA 角色適用中階模型 |
| AC7 | `sprint-planning/SKILL.md` 驗證（無需修改） | [靜態] | 確認 4 處 `model: "opus"` 標注仍然存在且正確，無需修改 |
