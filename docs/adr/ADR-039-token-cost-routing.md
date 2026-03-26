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
| **Tier 1：haiku** | `claude-haiku-*`（最新穩定版） | 4–6 | doc-only 修改、log 摘要、格式轉換、retro-action 文件類、schema 範例新增、**backlog-management Issue 建立（新增 sprint-candidate）**、**Cruise PO 巡邏留言操作（comment-only 巡邏 cycle）**、**Sprint Review Metrics 計算**、**Sprint Review Analytics 趨勢分析** |
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

### 決策 2.5：haiku 適用場景擴充（#817，Sprint 163）

<!-- #817 retro: ADR-039 haiku 路由適用場景擴充 — Sprint 163 -->

**背景**：Sprint 161 Retro [OVER-ROUTING-WARN] 顯示 haiku 比例 21% < 30% 目標，需識別更多可降級場景。

以下任務類型新增至 Tier 1（haiku）適用範圍：

| 任務類型 | 識別條件 | Risk Score 估計 | 說明 |
|---------|---------|---------------|------|
| **Backlog 補充 Issue 建立** | `story_type=PROCESS`，任務僅為建立 GitHub Issues 且無程式碼修改 | 4（1+1+1+1） | Issue 建立為可逆操作，僅影響 GitHub，有固定範本，不涉及架構推理 |
| **Cruise PO 巡邏 comment-only cycle** | Cruise cycle 無 actionable Issues，僅執行 GitHub 留言更新 | 5（1+1+2+1） | 留言操作可覆寫，無代碼修改，半範本（有固定留言格式） |
| **Sprint Review Metrics 計算** | `task=metrics-calculation`，僅讀取 sprint_N.md 計算 velocity/完成率 | 4（1+1+1+1） | 純數值計算，有明確公式，結果可驗證，docs 僅追加 |
| **Sprint Review Analytics 趨勢分析** | `task=trend-analysis`，從 Metrics_Log.md 計算趨勢 | 5（1+1+2+1） | 趨勢判斷邏輯固定（連升/連降/穩定/不規則），半範本 |
| **retro-action doc-only Story** | `doc_only=true`，`story_type=PROCESS`，title 含「retro:」 | 4-5（依新穎程度） | 文件修改為可逆，影響範圍小，通常有前次 retro 範本可循 |

**路由記錄範例（新增規則）**：
```
model-route #818 tier=1 score=4 model=haiku reason=backlog-issue-creation+no-code
model-route cruise-cycle-N tier=1 score=5 model=haiku reason=comment-only+no-actionable
model-route sprint-163-metrics tier=1 score=4 model=haiku reason=metrics-calculation+template
```

**預期效果**：haiku 比例從 21% 提升至 >= 25%（AC3 可接受閾值）。

---

### 決策 2.6：Score 4-5 TEST/DOC/LOG 強制 haiku 規則（#854，Sprint 166）

<!-- #854 retro: haiku 路由比例偏低（18%）— ADR-039 Score 4-5 TEST/DOC 強制 haiku 規則 — Sprint 166 -->

**背景**：Sprint 165 Retro 顯示 haiku 路由比例僅 18%（目標 >= 30%），Planning 階段 Risk Scoring 偏保守，Score 4-5 的低風險任務仍被路由至 sonnet。

**新增強制規則**：

<HARD-RULE id="haiku-force-route-456">
**Score 4-5 且 Story Type ∈ {TEST, DOC, LOG} 時，一律路由至 haiku（Tier 1），不依賴 agent 主觀判斷。**

此規則優先於 agent 評分結果。Planning 時若 Story 符合條件但被評為 Tier 2+，PO 必須降級至 haiku 並說明理由。
</HARD-RULE>

**識別規則**：

| 條件 | Story Type 判斷標準 |
|------|------------------|
| `TEST` | 標題含「test:」前綴、或 AC 主要內容為新建/修改 tests/ 腳本 |
| `DOC` | 標題含「doc:」「retro:」前綴、或 AC 主要為修改 .md 文件 |
| `LOG` | Story 主要輸出為 log 記錄、metrics 計算或報告生成 |

**防 over-correction 規則**（AC4 — QA 建議補充）：

此強制規則不影響 Score >= 7 的 Story 路由。Score >= 7 的 Story 仍依動態評分路由至 sonnet 或 opus，不被此規則強制降至 haiku。

**RICE Score 與路由 Tier 交叉審查（Sprint Planning PO Round 新增步驟）**：

Sprint Planning PO Round 完成 Story 選取後，計算本 Sprint haiku 比例預估值：
```
haiku_ratio = haiku_stories / total_stories
```
若 `haiku_ratio < 20%`，PO 必須逐一說明 Tier 2+ 選用理由，確認無可降級的 TEST/DOC/LOG Stories 被誤評。

**路由記錄範例（新增規則）**：
```
model-route #853 tier=1 score=5 model=haiku reason=score-4-5+story-type=DOC(retro:)
model-route #840 tier=1 score=6 model=haiku reason=score-4-6+story-type=TEST(tests/)
```

**預期效果**：haiku 比例從 18% 提升至 >= 30%（Sprint 166 起生效）。

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
