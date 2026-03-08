# Sprint 67

**Sprint Goal**：簡化多模型派遣架構 — 移除基於錯誤前提設計的 cli-adapter.sh 抽象層，直接利用 Gemini CLI 原生 agent 能力。

**期間**：2026-03-08 ~ 2026-03-14
**狀態**：進行中
**ADR 依賴**：無

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-177：CLI Adapter 簡化 — 移除不必要的抽象層，直接使用 Gemini CLI 原生 agent 能力 | #171 | S | 1 | 進行中 |

## 平行分群

Phase 1：US-177（獨立執行）

## 方法論適用性評估

| Story ID | BDD 建議 | DDD 建議 | 說明 |
|----------|---------|---------|------|
| US-177 | 不適用 | 不適用 | 刪除腳本與修正文件描述，無行為規格或領域模型需求 |

## Acceptance Criteria

### US-177：CLI Adapter 簡化 — 移除不必要的抽象層，直接使用 Gemini CLI 原生 agent 能力

| # | 條件 | 類型 | 通過標準 |
|---|------|------|---------|
| AC1 | `scripts/cli-adapter.sh`、`tests/test-us167-cli-adapter.sh`、`tests/test-us177-health-check.sh` 已刪除 | [靜態] | 三個檔案均不存在於 repo 中 |
| AC2 | `skills/sprint-execution/SKILL.md` §2.1 移除 adapter 引用 | [靜態] | §2.1 中無任何 `cli-adapter` 字串；Gemini 派遣範例改為 `echo "prompt" \| gemini` |
| AC3 | 「Gemini 路徑沒有 tool calling」錯誤描述已修正 | [靜態] | SKILL.md 與 story-lifecycle-prompt.md 中「不具備 tool calling 能力」描述已替換為正確描述（Gemini CLI 具備完整 agent 能力） |
| AC4 | `skills/sprint-execution/story-lifecycle-prompt.md` adapter 引用已清理 | [靜態] | 檔案中無任何 `cli-adapter` 字串 |
| AC5 | 無殘留引用 | [一致性] | `skills/` 目錄下 grep `cli-adapter` 零結果 |
