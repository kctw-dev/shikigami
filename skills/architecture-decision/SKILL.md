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

ADR 並非隨時都需要建立，以下兩個階段是主要的產出時機：

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

**流程說明**：

1. **標注需求**：PO 在 Backlog Grooming 或主 Agent 在分析 Story 時，識別出需要技術選型的 Story，標注「需要 ADR」。
2. **Architect 產出 ADR**：Architect subagent 分析問題背景，列舉可行的技術選項，進行利弊分析，並產出初版 ADR 文件至 `docs/adr/ADR-xxx.md`。詳細執行規則見 [`architect-prompt.md`](architect-prompt.md)。
3. **Decision Challenger 挑戰**：QA subagent 以 Decision Challenger 身份，針對 Architect 最關鍵的決策進行挑戰。詳細執行規則見 [`qa-challenger-prompt.md`](qa-challenger-prompt.md)。
4. **SRE 審查**：SRE subagent 從維運角度審查決策的可行性，包括部署複雜度、監控需求、故障恢復等。詳細執行規則見 [`sre-prompt.md`](sre-prompt.md)。
5. **Architect 拍板**：Architect subagent 綜合 Decision Challenger 與 SRE 的意見，決定是否維持原案或調整決策，更新 ADR 狀態。詳細執行規則見 [`architect-prompt.md`](architect-prompt.md) 第二輪段落。
6. **Story 解鎖**：ADR 狀態變更為 Accepted 後，對應的 Story 方可在 Sprint Planning 中選入 Sprint。

---

## 4. Hard Gate

<HARD-GATE>
沒有 ADR 的技術選型 Story 不能進 Sprint。
</HARD-GATE>

**說明**：任何涉及技術選型的 Story（例如選擇框架、資料庫、第三方服務、通訊協定等），必須先透過本流程完成 ADR 並獲得 Accepted 狀態。未通過此門禁的 Story 將被退回 Backlog，待 ADR 完成後方可在下次 Sprint Planning 重新選入。

---

## 8. Subagent 派遣順序

Architecture Decision 的 Subagent 調度遵循以下固定順序：

```
1. Architect     → 評估技術選項、產出 ADR 初版（architect-prompt.md）
2. QA (Challenger) → 挑戰最關鍵決策（qa-challenger-prompt.md）
3. SRE           → 維運可行性審查（sre-prompt.md）
4. Architect     → 綜合意見、拍板定案、更新 ADR 狀態（architect-prompt.md）
5. Developer     → 同步更新 Decision_KB_Index.md（developer-prompt.md）
```

**派遣說明**：

1. **Architect（第一輪）**：分析 Story 的技術需求，調研可行方案，進行選項分析，產出 ADR 初版（狀態為 Proposed）。執行細節見 [`architect-prompt.md`](architect-prompt.md)。
2. **QA — Decision Challenger**：閱讀 ADR，挑選最關鍵決策，執行完整的挑戰流程，產出挑戰結論。執行細節見 [`qa-challenger-prompt.md`](qa-challenger-prompt.md)。
3. **SRE**：從維運角度審查 ADR，評估部署複雜度、監控需求、故障恢復機制、資源需求等。執行細節見 [`sre-prompt.md`](sre-prompt.md)。
4. **Architect（第二輪）**：綜合 QA 與 SRE 的回饋，決定維持或調整方案，更新 ADR 文件並將狀態變更為 Accepted（或退回重新評估）。執行細節見 [`architect-prompt.md`](architect-prompt.md)。
5. **Developer（ADR 索引同步）**：ADR 狀態確認為 Accepted 後，同步更新 `docs/km/Decision_KB_Index.md`。執行細節見 [`developer-prompt.md`](developer-prompt.md)。

---

## 10. 與其他 Skill 的關係

| 情境 | 觸發 |
|------|------|
| Discovery 階段引入新技術 | 由 Discovery Skill 觸發 architecture-decision |
| Sprint Planning 識別技術選型需求 | 在 Story 進 Sprint 前完成 ADR |
| ADR 完成後 Story 解鎖 | 回到 sprint-planning 繼續 Story 選入流程 |
| ADR 影響現有架構設計 | 同步更新相關 SDD 文件（`docs/sdd/`），並觸發受影響 Story AC 校準（ADR-020，見下方） |

### SDD 變更連鎖校準（ADR-020）

當 ADR 觸發 SDD 更新時，Architect 必須執行以下連鎖校準。若專案尚無 SDD（`docs/sdd/SDD-000-architecture.md` 不存在），連鎖校準不適用。

1. **列出受影響 Story**：檢查 Sprint 文件（`docs/sprints/sprint_N.md`）中各 Story 的 `related_sdds` 欄位，識別引用了被修改 SDD 章節的 Story
2. **AC 重新校準**：與 PO 確認受影響 Story 的 AC 是否需要更新（SDD 約束變更可能使既有 AC 過時或不完整）
3. **記錄校準結果**：在 Sprint 文件中記錄哪些 Story AC 被校準、校準原因
4. **重新進入 TDD**：若受影響 Story 已開始實作，需從 TDD Red 階段重新開始（基於新 AC 重寫失敗測試）

**輸出格式**：

```
[SDD-CASCADE] ADR-XXX 觸發 SDD-YYY 更新
  受影響 Story：{story_id_list}
  校準結果：
    - {story_id}: AC 已更新 / AC 無需更新 / 待 PO 確認
  TDD 重置：
    - {story_id}: 從 Red 階段重新開始 / 尚未開始實作（不影響）
```

**失敗處理**：若無法確定受影響範圍（Sprint 文件缺失或 `related_sdds` 欄位不完整），輸出 `[SDD-CASCADE-INCOMPLETE]` 並 ESCALATE 至主 session。主 session 收到後：(a) 暫停所有尚未開始實作的當前 Sprint Story；(b) 請 Architect 手動列出可能受影響的 Story；(c) 完成手動列舉後重新執行連鎖校準
