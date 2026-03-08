# 模型分層策略：Sprint 環節模型選用指南

**文件版本**：v1.0
**建立日期**：2026-03-08
**關聯 Story**：US-156（Sprint 58，Issue #106）
**關聯 Issue**：#106（模型分層策略：Planning 用高階模型、Coding 用合適模型）
**文件類型**：知識管理（Knowledge Management）

---

## 一、背景與目的

Shikigami 框架的每個 Sprint 包含三個主要環節：

- **Planning**（Sprint Planning + Backlog Grooming）：需要高層次策略思考、需求分析、架構評估
- **Execution**（Story-Lifecycle Subagent 驅動開發）：需要精確代碼實作、TDD 循環、文件撰寫
- **Review**（Sprint Review + Retrospective）：需要品質判斷、指標分析、回顧摘要

各環節的認知負荷與輸出品質要求不同，因此存在按環節選用不同模型層級的可能性，以達到**品質與 token 成本的最佳平衡**。

本文件記錄：
1. 三環節的模型層級建議表格（AC1）
2. Claude Code Agent tool `model` 參數可行性調查結論（AC2）
3. 分層 vs. 統一模型的成本效益估算（AC3）

---

## 二、三環節模型層級建議表格（AC1）

| 環節 | 建議模型層級 | 具體模型（2026-03 參考） | 理由 |
|------|------------|------------------------|------|
| **Planning** | 高階（Opus） | claude-opus-4-6 | Planning 環節需要多步策略推理：AC 分析、Story 點數估算、平行分群策略、依賴關係評估。高階模型在多步推理與模糊需求解析上具備明顯優勢，錯誤的 Planning 決策對後續 Execution 的修正成本極高，值得前置投入高品質模型。|
| **Execution** | 中階（Sonnet） | claude-sonnet-4-6 | Execution 環節的主要工作是 TDD 開發、代碼實作、文件撰寫——這些任務對執行速度與準確性要求高，但相對於 Planning 的策略複雜度較低。Sonnet 在代碼生成與文件撰寫品質上達到足夠水準，且速度比 Opus 快 3-5 倍，可有效降低整體 Sprint 執行時間。|
| **Review** | 混合（Sonnet + Opus 選項） | Sonnet 預設，Opus 選用 | Sprint Review 的指標計算、DORA 數據彙整、通過標準核對可由 Sonnet 高品質完成。Retrospective 的深度分析、根因識別、架構影響評估若需要更高深度，可選用 Opus。建議以 Sonnet 為預設，僅在 Velocity 大幅偏差或出現系統性問題時升級至 Opus。|

### 補充說明

**為何 Execution 不用 Haiku？**

Haiku 雖然速度最快、成本最低，但在 Execution 環節的兩個核心任務上存在已知限制：

1. **TDD 精確性**：TDD 要求對 AC 的精確語義理解，Haiku 在邊界條件處理與多步測試設計上的品質下滑在 Sprint 54 調查中被記錄（US-116 UIUX Agent 模型分層策略調查）
2. **文件一致性**：Shikigami 的文件標準要求精確引用 ADR、SDD、Story 編號，Haiku 在長文件的一致性維持上較 Sonnet 弱

**Story-Lifecycle Subagent 的現有模型**：

目前所有 Story-Lifecycle Subagent 使用 `claude-sonnet-4-6`（系統配置的預設模型），與本文件的 Execution 層建議一致，無需變更。

---

## 三、Claude Code Agent Tool `model` 參數可行性調查（AC2）

### 3.1 調查結論摘要

**結論：Claude Code Agent tool（即 Task tool）目前不支援 `model` 參數指定。**

分層策略在技術上**無法**透過 Agent tool 的 model 參數原生實現，需採用替代方案。

### 3.2 調查細節

#### (a) Claude Code Agent tool 的現有介面

根據對 `skills/sprint-execution/story-lifecycle-prompt.md` 及 `SKILL.md` 的分析，Story-Lifecycle Subagent 的派遣方式為：

```
主 session 透過 Agent tool（Task tool）派遣 subagent
  輸入：prompt 字串（包含 story_id, sprint_file 等參數）
  輸出：subagent 回傳的標準化摘要（PASS/FAIL/ESCALATE）
```

Agent tool 的呼叫介面為：

```yaml
task:
  description: "..."   # subagent prompt 內容
  # 目前無 model 欄位
```

**Claude Code 的 Agent tool（Task tool）不暴露 `model` 參數**。模型選用由 Claude Code 平台層面統一決定，Skill prompt 無法在 subagent 呼叫時指定使用不同模型層級。

#### (b) 平台層級的模型控制

Claude Code 的模型選擇發生在以下層級：

| 控制層 | 機制 | 對分層策略的影響 |
|--------|------|----------------|
| 使用者設定 | `/model` 指令切換主 session 模型 | 影響主 session，不影響 subagent |
| 平台預設 | 系統設定的預設模型（目前為 Sonnet） | subagent 繼承主 session 設定 |
| Agent tool 呼叫 | 無 model 參數 | 無法逐 subagent 指定模型 |

#### (c) 已確認的限制

1. **Subagent 繼承主 session 模型**：透過 Agent tool 派遣的 subagent 使用與主 session 相同的模型配置，不支援獨立指定。
2. **無動態模型切換 API**：Claude Code 目前無法在 SKILL.md prompt 中透過程式化方式在不同 subagent 之間切換模型。
3. **`/model` 指令為手動操作**：使用者可以在對話中手動執行 `/model claude-opus-4-6` 切換，但這是互動式操作，無法在 Skill 流程中自動觸發。

#### (d) 替代方案評估

| 替代方案 | 可行性 | 說明 |
|----------|--------|------|
| **手動環節切換（Manual Tiering）** | 高 | 使用者在 Planning 前手動執行 `/model claude-opus-4-6`，Execution 前切回 `/model claude-sonnet-4-6`。成本：需使用者記憶並執行切換。 |
| **SKILL.md 提示指引** | 中 | 在各環節 SKILL.md 中加入「建議使用者切換至 [模型] 後執行本 Skill」提示。降低遺忘率，但仍是手動操作。 |
| **等待平台支援** | 低（短期） | 持續追蹤 Claude Code 路線圖，待 Agent tool 支援 model 參數後再實作。預計 2026 H2 或更晚。 |
| **Multi-session 架構** | 低 | 主 session 為 Opus、subagent session 為 Sonnet，透過 CLI 呼叫實現。架構複雜度高，不符合 KISS 原則，且需 ADR 決策。 |

**建議採用「手動環節切換 + SKILL.md 提示指引」的輕量方案**，在平台原生支援前作為過渡方案。

#### (e) 未來觀察點

- 追蹤 Claude Code changelog 是否新增 Agent tool `model` 參數（Anthropic API `/v1/messages` 已支援 model 參數，平台 Task tool 整合時間待觀察）
- 若 OpenCode 平台（MULTI_PLATFORM_SURVEY.md 調查結論：可行性 4/5）支援 per-subagent model 指定，可評估 Shikigami OpenCode 版的分層策略原生實作

---

## 四、成本效益估算（AC3）

### 4.1 前提假設

以下估算基於 2026-03 Anthropic 公開定價（每百萬 token）：

| 模型 | Input token 費率 | Output token 費率 |
|------|-----------------|------------------|
| claude-opus-4-6 | $15.00 / MTok | $75.00 / MTok |
| claude-sonnet-4-6 | $3.00 / MTok | $15.00 / MTok |
| claude-haiku-3-5 | $0.80 / MTok | $4.00 / MTok |

*MTok = 百萬 token*

### 4.2 典型 Sprint token 消耗估算

基於 Sprint 55-57 的 Metrics_Log.md 記錄，一個中型 Sprint（3-5 Stories，混合 S/M Size）的典型 token 消耗分布：

| 環節 | 佔比（估算） | Token 量（估算，Input+Output） |
|------|------------|-------------------------------|
| Planning | 約 15-20% | 150K-200K tokens |
| Execution | 約 60-70% | 600K-700K tokens |
| Review | 約 15-20% | 150K-200K tokens |

*注意：Execution 佔比最高，因 Story-Lifecycle Subagent 包含 TDD 開發、文件撰寫、多輪 self-review。*

### 4.3 統一模型 vs. 分層模型成本比較

**情境**：中型 Sprint，假設總 token 消耗為 1,000,000 tokens（100 萬 token），Input:Output = 3:1

#### 統一使用 Opus（目前若手動全程使用）

| 項目 | Token 量 | 費率 | 費用 |
|------|----------|------|------|
| Input | 750,000 | $15.00 / MTok | $11.25 |
| Output | 250,000 | $75.00 / MTok | $18.75 |
| **合計** | | | **$30.00** |

#### 統一使用 Sonnet（目前框架預設）

| 項目 | Token 量 | 費率 | 費用 |
|------|----------|------|------|
| Input | 750,000 | $3.00 / MTok | $2.25 |
| Output | 250,000 | $15.00 / MTok | $3.75 |
| **合計** | | | **$6.00** |

#### 分層使用（Opus for Planning + Sonnet for Execution + Sonnet for Review）

| 環節 | Token 佔比 | Token 量 | 模型 | 費用估算 |
|------|-----------|----------|------|---------|
| Planning | 20% | 200K | Opus | $4.00 |
| Execution | 65% | 650K | Sonnet | $1.95 |
| Review | 15% | 150K | Sonnet | $0.45 |
| **合計** | 100% | 1,000K | | **$6.40** |

### 4.4 成本比較摘要

| 策略 | 估算費用 / Sprint | 相對 Sonnet 統一 | 說明 |
|------|-----------------|-----------------|------|
| 統一 Opus | $30.00 | +400% | 最高品質，成本最高 |
| 分層（Opus Planning + Sonnet 其他） | $6.40 | +7% | Planning 品質提升，整體成本僅微增 |
| 統一 Sonnet（當前預設） | $6.00 | 基準 | 現有框架配置 |
| 統一 Haiku | $1.10 | -82% | 成本最低，但品質風險高 |

### 4.5 採用建議

**建議：採用「分層策略（輕量版）」— Planning 環節選用 Opus，其他環節維持 Sonnet。**

理由：

1. **成本增幅極小**：分層策略相對於統一 Sonnet 的成本增幅僅約 7%（每 Sprint 約多 $0.40），增幅遠低於品質提升的預期收益。

2. **Planning 是高報酬率的投資點**：Planning 環節的決策品質（AC 完整性、Story 依賴關係識別、平行分群策略）直接影響整個 Sprint 的執行效率。Sprint 54 中止事件（架構方向轉型導致 14 個 Story DROP）顯示 Planning 品質不足的修復成本遠超 Opus token 成本。

3. **Execution 維持 Sonnet 符合現有框架**：Story-Lifecycle Subagent 當前使用 Sonnet，實際執行品質在 Sprint 55-57 三個 Sprint 中維持 100% 完成率，無需變更。

4. **過渡期實作方式**：在 Claude Code Agent tool 原生支援 model 參數前，透過 SKILL.md 提示指引告知使用者在 Planning Skill 呼叫前手動切換至 Opus，Review 後切回 Sonnet。

**不建議引入 Haiku**：目前 Execution 環節的代碼實作與文件撰寫任務複雜度，使 Haiku 的品質下滑風險超過成本節省的效益，不建議在 Sprint 任何環節使用。

---

## 五、實作路線圖

### Phase 1（當前可執行，無需 ADR）

- [ ] 在 `skills/sprint-planning/SKILL.md` 開頭新增「建議切換至 Opus 執行本 Skill」提示
- [ ] 在 `skills/sprint-review/SKILL.md` 開頭新增「Sonnet 已足夠；深度 Retro 分析可選用 Opus」提示
- [ ] 在 `docs/tutorial/README.md` 新增「模型選用建議」段落

### Phase 2（待平台支援）

- [ ] 追蹤 Claude Code changelog — Agent tool 是否新增 `model` 參數
- [ ] 若支援，評估在 `story-lifecycle-prompt.md` 中加入 model 參數的架構決策（需要 ADR）

### Phase 3（長期）

- [ ] 若 OpenCode 平台支援 per-subagent model 指定，評估 Shikigami OpenCode 版的原生分層實作

---

## 六、參照文件

- `docs/adr/ADR-007-story-lifecycle-subagent.md`（Story-Lifecycle 架構決策）
- `docs/km/MULTI_PLATFORM_SURVEY.md`（多平台調查，含 OpenCode model-agnostic 特性分析）
- `docs/km/Metrics_Log.md`（Sprint token 消耗記錄）
- Sprint 54 US-116 調查結論（UIUX Agent 模型分層策略，已完成）
- Sprint 54 US-136 調查結論（Issue #107 UIUX Agent 模型分層策略實作規劃，已完成）
