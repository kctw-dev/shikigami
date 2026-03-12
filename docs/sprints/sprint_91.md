# Sprint 91

**Sprint Goal**：透過 SKILL.md 瘦身與角色 Prompt 拆分，將框架 context 消耗削減約 75%
**日期**：2026-03-12
**容量**：5 points

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-246：SKILL.md 瘦身：移除 agent 已知的工具教學與重複樣板 | #245 | L | 3 | 待開始 |
| US-245：SKILL.md 角色專屬 Prompt 拆分 — 減少 subagent context 消耗 | #244 | M | 2 | 待開始 |

## 執行順序

US-246 → US-245（序列執行：先瘦身再拆分）

## 技術評估摘要

- 兩個 Story 均為 doc-only FEATURE type
- 無 ADR 需求
- US-246 修改 5 個 SKILL.md，US-245 修改 2 個 SKILL.md（sprint-planning, sprint-review）
- US-245 依賴 US-246 先完成瘦身，再進行拆分
