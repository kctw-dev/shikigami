---
name: architecture-decision
description: "Use when technical decisions are needed, architecture reviews, technology selection, ADR creation, or system design changes"
---

# Architecture Decision — 架構決策流程

## 1. 概述

Architecture Decision 是技術決策的正式流程，由 **Architect** 主導，產出 ADR（Architecture Decision Record）作為決策紀錄。流程中包含多角色審查機制：QA Engineer 擔任 **Decision Challenger** 挑戰關鍵決策、SRE Engineer 評估維運可行性，最終由 Architect 綜合意見後拍板定案。

**目標**：確保每一項技術選型與架構變更皆經過嚴謹的評估、挑戰與審查，並以 ADR 形式留下可追溯的決策紀錄。

---

## 2. ADR 產出時機

| 階段 | 觸發條件 | 說明 |
|------|----------|------|
| **Discovery 階段** | 新里程碑引入新技術 | 例如：新 Milestone 需要引入新框架、新資料庫、新第三方服務等，必須在規劃階段即產出 ADR |
| **Sprint Planning** | Story 進 Sprint 前需要技術選型 | 涉及技術選型的 Story 在進入 Sprint 前，必須先完成 ADR 並獲得 Accepted 狀態 |

---

## 3. 流程

以下步驟必須依序執行，不可跳過：

```
1. PO 或主 Agent 標注 Story「需要 ADR」
2. Architect subagent → 評估技術選項、產出 ADR（docs/adr/ADR-xxx.md）
3. QA subagent 的 Decision Challenger → 挑戰 Architect 最關鍵決策
4. SRE subagent Review → 維運可行性
5. Architect subagent 綜合意見後拍板
6. ADR 決議後 Story 才能進 Sprint
```

---

## 4. Hard Gate

<HARD-GATE>
沒有 ADR 的技術選型 Story 不能進 Sprint。
</HARD-GATE>

**說明**：任何涉及技術選型的 Story（例如選擇框架、資料庫、第三方服務、通訊協定等），必須先透過本流程完成 ADR 並獲得 Accepted 狀態。未通過此門禁的 Story 將被退回 Backlog，待 ADR 完成後方可在下次 Sprint Planning 重新選入。

---

## 8. Subagent 派遣順序

```
1. Architect     → 評估技術選項、產出 ADR 初版  → references/architect-prompt.md
2. QA (Challenger) → 挑戰最關鍵決策            → references/qa-challenger-prompt.md
3. SRE           → 維運可行性審查              → references/sre-prompt.md
4. Architect     → 綜合意見、拍板定案、更新 ADR  → references/architect-prompt.md
5. Developer     → 同步更新 Decision_KB_Index  → references/developer-prompt.md
```

執行細節依序見：
[`architect-prompt.md`](references/architect-prompt.md) ·
[`qa-challenger-prompt.md`](references/qa-challenger-prompt.md) ·
[`sre-prompt.md`](references/sre-prompt.md) ·
[`developer-prompt.md`](references/developer-prompt.md)

---

## 10. 與其他 Skill 的關係

| 情境 | 觸發 |
|------|------|
| Discovery 階段引入新技術 | 由 Discovery Skill 觸發 architecture-decision |
| Sprint Planning 識別技術選型需求 | 在 Story 進 Sprint 前完成 ADR |
| ADR 完成後 Story 解鎖 | 回到 sprint-planning 繼續 Story 選入流程 |
| ADR 影響現有架構設計 | 同步更新相關 SDD 文件，並觸發受影響 Story AC 校準（見 [`sdd-cascade.md`](references/sdd-cascade.md)） |
