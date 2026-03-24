# ADR-039: Token Cost Routing — Risk-based Model 分級架構決策

**狀態**：Accepted
**日期**：2026-03-24
**決策者**：Architect Agent
**觸發 Story**：#620（RESEARCH: ADR-039）
**Unblocks**：#402 feat: Token Cost Routing — Risk-based Model 分級

---

## 背景與問題

Shikigami 目前所有 agent 統一使用 `model: sonnet`，無任務風險分級路由。CLAUDE.md 紅線 3 規定「所有 agent 統一使用 model: sonnet」，但此規範原意是防止隨意選模型造成行為不一致，並非禁止有根據的差異化選用。

本 ADR 定義：
1. 任務風險評分維度與 model tier 分級規則
2. CLAUDE.md `model: sonnet` 統一規範的修訂範圍與例外條件
3. 路由決策的可觀測性要求

參考：`docs/discovery/PB-2026-03-23-token-cost-routing.md`

---

## 決策

### 決策 1：任務風險評分維度

採用 PB §4 草案，定義四個評分維度（各 1-3 分，加總為風險分數）：

| 維度 | 定義 | 分數說明 |
|------|------|---------|
| **Reversibility（可回滾性）** | 任務結果是否可輕易回滾 | 1=可回滾（git revert / 刪除檔案），2=部分可逆，3=不可逆（production 部署、外部 API 呼叫）|
| **Stakes（影響範圍）** | 錯誤是否影響 production 或 user-facing 功能 | 1=僅影響 docs/tests，2=影響內部工具，3=影響 user-facing 或 production |
| **Complexity（推理複雜度）** | 任務是否需要跨多個上下文的推理 | 1=單一文件/明確範本，2=跨多檔案/輕度分析，3=跨模組/架構設計/安全審查 |
| **Novelty（新穎程度）** | 任務是否有明確範本可循 | 1=完全範本化（如 doc-only retro 任務），2=半範本，3=無範本/首次類型 |

**風險分數**：4 維度加總，範圍 4–12

---

### 決策 2：Model Tier 分級規則

採用 PB 推薦的**混合模式（方向 C）**：

| Tier | Model | 適用風險分數 | 適用任務類型 |
|------|-------|------------|------------|
| **Tier 1：haiku** | `claude-haiku-*`（最新穩定版） | 4–6 | doc-only 修改、log 摘要、格式轉換、retro-action 文件類、schema 範例新增 |
| **Tier 2：sonnet** | `claude-sonnet-*`（最新穩定版） | 7–9 | 一般功能實作、CI workflow 修改、Backlog 分析、Sprint Planning PO Round 1 |
| **Tier 3：opus** | `claude-opus-*`（最新穩定版） | 10–12 | 架構設計（ADR）、安全審查、L-size Story、跨 Sprint 依賴分析、Sprint Planning Architect/QA |

**CLAUDE.md 紅線 3 修訂範圍**：

現有規範「所有 agent 統一使用 `model: sonnet`」修訂為：

> **基準模型為 `model: sonnet`**。Agent 定義中若未明確指定 model，預設使用 sonnet。Sprint Planning / Execution 中可依本 ADR（ADR-039）的風險評分規則路由至 haiku 或 opus。路由決策必須記錄（log action：`model-route #N tier=X score=Y`）。

**靜態例外（Hardcode 不路由）**：
- Architect subagent（Sprint Planning/Execution）：固定 `opus`（不參與動態路由）
- QA subagent（Sprint Planning）：固定 `opus`
- Security self-review：固定 `opus`
- 所有其他 agent：預設 `sonnet`，可依動態路由升降

---

### 決策 3：路由決策的可觀測性

**路由記錄位置**：`docs/km/Metrics_Log.md` 每個 Sprint 的 token 消耗紀錄中，新增 `model_routing` 欄位：

```markdown
| Story | Model Used | Tier | Risk Score | 路由原因 |
|-------|-----------|------|-----------|---------|
| #617  | haiku     | 1    | 5          | doc-only, reversible, no-template |
| #616  | sonnet    | 2    | 8          | CI workflow, semi-template |
```

**log action 格式**（cruise-log / sprint-execution log）：
```
model-route #617 tier=1 score=5 model=haiku reason=doc-only+reversible
```

**路由決策時機**：Sprint Planning PO Round 2 計算各 Story 風險分數，記錄於 sprint_N.md「Model Routing」區塊；Sprint Execution 派遣 subagent 時依此執行。

---

### 決策 4：實作方式 — 靜態分類優先，動態評分備援

實作順序（#402）：
1. **Phase 1（靜態）**：在 story-lifecycle-prompt.md 中加入風險評分表，Developer subagent 自評 + 根據評分選 model。記錄路由結果。
2. **Phase 2（動態，後續 Sprint）**：若 Phase 1 評分準確率 < 80%，由 Scrum Master hook 執行輕量評分 prompt，自動判斷 tier。

---

## 後果

**正面**：
- 理論上可降低 doc-only / retro 類任務的 token 成本（Tier 1 haiku 約為 sonnet 的 1/5 成本）
- 強制路由記錄提升 token 使用可觀測性，為後續成本分析提供基礎
- 修訂後的 CLAUDE.md 規範保留 sonnet 為預設，降低誤用風險

**負面 / 風險**：
- haiku 路由任務的品質仍需 Sprint Review 驗收確認（PB §3 [UNCERTAIN]）
- 靜態分類需要 PO/Architect 在 Sprint Planning 時額外評分步驟，輕微增加 Planning 時間
- 模型版本（haiku-*/sonnet-*/opus-*）應固定使用最新穩定版，避免版本飄移

---

## 相關文件

- `docs/discovery/PB-2026-03-23-token-cost-routing.md`
- CLAUDE.md 紅線 3（`model: sonnet` 統一規範）
- #402 feat: Token Cost Routing — Risk-based Model 分級（待實作）
- `docs/km/Metrics_Log.md`（路由記錄目標位置）
