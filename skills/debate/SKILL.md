---
name: debate
description: "在技術方案需要結構化辯論與決策時調度此 Skill（D3 Framework: Debate-Deliberate-Decide）"
---

# D3 Debate Framework — 結構化辯論與決策

<!-- #403 D3 Debate Framework — Sprint 133 -->
<!-- 來源：PB-2026-03-23-d3-debate-framework.md，基於 EACL 2026 D3 論文 -->

## 1. 概述

D3 Framework 提供結構化的三階段辯論流程，解決 Shikigami 框架中技術辯論缺乏格式、成本感知不足、決策依據不透明的問題。

**與 FREE-MAD 的關係**（#397）：
- D3 規範**辯論流程格式**（如何辯、誰擔任什麼角色）
- FREE-MAD 規範**最終決策收斂**（QA 挑戰韌性、避免群體盲思）
- 兩者互補，D3 在 FREE-MAD 之前提供結構框架

## 2. 適用場景

| 場景 | 觸發條件 |
|------|---------|
| Sprint Planning 技術方案選擇 | 有 2 個以上候選方案，且各有技術取捨 |
| ADR 形成前的正式辯論 | 重大架構決策（涉及多模組或長期影響） |
| Sprint Review 缺陷根因辯論 | 缺陷根因有爭議，各方論點不一致 |
| 高風險 Story 實作前的 risk assessment | Story 估點 M 或 L，且有明確技術分歧 |

## 3. 角色定義

| 角色 | Agent | 職責 |
|------|-------|------|
| **Advocate（倡導者）** | QA Engineer（預設）或提出方案者 | 為特定方案提出最強論述 |
| **Judge（裁判）** | Scrum Master | 基於明確標準做最終裁決 |
| **Jury（陪審）** | Architect | 提出成本評估、風險分析，輔助 Judge |

## 4. 三階段流程

### Phase 1：Debate（辯論）

**輸入**：候選方案清單（至少 2 個）
**執行**：

```
[D3-DEBATE-START] {topic} 時間={timestamp}

方案清單：
- 方案 A：{名稱} — {一句話描述}
- 方案 B：{名稱} — {一句話描述}
（可有更多方案）

每個方案的 Advocate 提出論述，格式：
[ADVOCATE] 方案={A/B/...} Effort={Story Points}
論述：{具體技術論點，引用測試數據或 spec 條文}
成本：{Effort 評估，單位 Story Points}
風險：{具體失敗情境}
```

**重要**：每個論點必須附 Effort 評估（成本感知），防止高成本方案因論述強勢而通過。

### Phase 2：Deliberate（商議）

**執行**：Jury（Architect）對各方案進行交叉質詢

```
[D3-DELIBERATE] 時間={timestamp}

成本分析：
- 方案 A：Effort={N} pts，風險={level}，{具體說明}
- 方案 B：Effort={M} pts，風險={level}，{具體說明}

技術取捨矩陣：
| 維度 | 方案 A | 方案 B |
|------|--------|--------|
| 實作成本 | {N} pts | {M} pts |
| 長期維護 | {評估} | {評估} |
| 測試覆蓋 | {評估} | {評估} |
| 風險等級 | {Low/Med/High} | {Low/Med/High} |
```

### Phase 3：Decide（決策）

**執行**：Judge（Scrum Master）基於 Phase 1+2 輸出做最終裁決

```
[D3-DECIDE] 決策={方案 X} 時間={timestamp}
裁決依據：
1. {具體依據，引用 Phase 1 Advocate 論點或 Phase 2 成本分析}
2. {具體依據}

被否決方案說明：
- 方案 Y 否決原因：{明確說明，可追溯}

ADR 草稿觸發：{是/否}
（若是：自動產出 ADR 草稿模板至 docs/adr/）
```

## 5. 決策紀錄（可追溯性）

D3 辯論完成後，自動產出結構化紀錄：

```
docs/km/debate-log/YYYY-MM-DD-{topic-slug}.md
```

紀錄格式（可轉換為 ADR 草稿）：

```markdown
# D3 辯論紀錄：{topic}

**日期**：{date}
**參與者**：Advocate={A}, Jury={B}, Judge={C}
**決策**：{結論}

## Phase 1 摘要
{各 Advocate 論點}

## Phase 2 摘要
{成本分析與取捨矩陣}

## Phase 3 裁決
{裁決依據}
```

## 6. 與其他機制的整合

- **FREE-MAD（#397）**：D3 的 Advocate 論述階段結束後，進入 FREE-MAD 協議 — QA 挑戰時需明確反證才可撤回
- **ADR 流程**：D3 辯論紀錄可自動轉換為 ADR 草稿（`docs/adr/ADR-XXX-{topic}.md`），降低 ADR 撰寫摩擦
- **Sprint Planning**：Architect 發現技術分歧時，觸發 D3 Debate 作為 ADR 形成前置步驟

## 7. 觸發指令

在 Sprint Planning 或 Sprint Execution 中，Architect 可透過以下方式觸發：

```
invoke shikigami:debate
```

或在 agents/architect.md 的 Decision Challenge 段落中描述候選方案，框架將自動識別並引用 D3 流程。
