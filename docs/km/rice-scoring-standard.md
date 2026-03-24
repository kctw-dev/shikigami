# RICE Score 評分標準 — Shikigami Sprint Planning

> **版本**：v1.0.0（2026-03-24，Sprint 132，Issue #564）
> **用途**：Sprint Planning PO Round 1 的 sprint-candidate 優先級量化
> **消費者**：PO Agent（Sprint Planning po-prompt.md 引用）

---

## 1. RICE 公式

```
RICE Score = (Reach × Impact × Confidence) / Effort
```

## 2. 各維度評分標準

### 2.1 Reach（影響範圍）

衡量「此 Story 影響幾個 Shikigami 角色或流程」。

| 分值 | 標準 | 範例 |
|------|------|------|
| 1 | 影響 1 個角色或 1 個獨立流程 | 只影響 PO 的 Sprint Planning 步驟 |
| 2 | 影響 2-3 個角色或跨流程 | 影響 Developer + QA 的協作流程 |
| 3 | 影響 4 個以上角色或整個框架 | 影響 Sprint Execution 整體流程（所有角色都受益） |
| 4 | 影響外部使用者或跨 repo 場景 | 影響所有導入 Shikigami 的使用者 |

### 2.2 Impact（影響程度）

衡量「對框架效能或使用者體驗的改善程度」。

| 分值 | 標準 |
|------|------|
| 1 | 微小改善（解決邊緣案例、細節優化） |
| 2 | 中等改善（減少重工或溝通摩擦） |
| 3 | 顯著改善（填補重要缺口，提升整體品質） |
| 4 | 重大改善（解決系統性問題，對 Sprint 效率或框架可靠性有明顯提升） |
| 5 | 關鍵改善（解決 P0 缺陷，不修復會導致嚴重品質問題） |

### 2.3 Confidence（估算信心度）

衡量「對上述 Reach 和 Impact 估算的信心程度」。

| 比例 | 標準 |
|------|------|
| 100% | 已有充分證據（歷史數據、實際問題記錄、明確需求） |
| 85% | 有合理依據（Retro 記錄、使用者反饋） |
| 70% | 中等信心（假設合理但未驗證） |
| 50% | 低信心（[UNCERTAIN] 假設尚未驗證） |

### 2.4 Effort（實作工時，單位：Story Points）

直接使用 T-shirt size 對應的 Story Points：

| Story Size | Effort 值 |
|------------|-----------|
| S（1 pt） | 1 |
| M（2 pt） | 2 |
| L（3 pt） | 3 |

---

## 3. 計算範例

### 範例 A：#563 retro: Story AC 完整性前置確認

- Reach = 3（影響 PO + QA + Developer 協作流程）
- Impact = 4（直接解決 Sprint 131 Problem 1，減少多輪溝通摩擦）
- Confidence = 90%（有明確歷史案例：#388/#386 Sprint 131）
- Effort = 1（S）

RICE = (3 × 4 × 0.90) / 1 = **10.8**

### 範例 B：#394 feat: TDAD Dependency Map

- Reach = 2（影響 Developer + QA 協作）
- Impact = 3（提升 TDD 精準度，縮短測試執行時間）
- Confidence = 70%（技術假設合理但未在 Shikigami 實際驗證）
- Effort = 2（M）

RICE = (2 × 3 × 0.70) / 2 = **2.1**

---

## 4. RICE Score 在 Issue 中的格式

sprint-candidate Issue body 中的標準格式（po-prompt.md 的正則提取規則）：

```markdown
**RICE Score** | **N.N**
```

例：
```markdown
**RICE Score** | **10.8**
```

---

## 5. Sprint Planning 排序規則

1. 先依 MoSCoW tier 升序（priority: must → tier 1，priority: should → tier 2，priority: could → tier 3）
2. 同 tier 內依 RICE Score 降序（分數高者優先）
3. 無 RICE Score 的 Story 以 RICE = 0 計算，排在同 tier 最後

---

## 6. 高頻 Sprint Candidate RICE Score（Sprint 132 補充，前 10 個）

以下為 sprint-candidate Issue 的 RICE Score 評估（2026-03-24）：

| Issue | 標題 | R | I | C% | E | RICE |
|-------|------|---|---|-----|---|------|
| #563 | retro: Story AC 完整性前置確認 | 3 | 4 | 90 | 1 | 10.8 |
| #567 | ADR RESEARCH: TDAD 依賴分析工具選型 | 2 | 3 | 90 | 1 | 5.4 |
| #394 | feat: TDAD Dependency Map | 2 | 3 | 70 | 2 | 2.1 |
| #564 | retro: Sprint Candidate RICE Score 補充 | 2 | 3 | 85 | 2 | 2.6 |
| #385 | feat: GAD 接入 Delivery Phase | 2 | 4 | 70 | 2 | 2.8 |
| #407 | feat: 專案範本 Skills/Hooks/Script 綁定 | 3 | 4 | 70 | 2 | 4.2 |
| #403 | feat: D3 Debate Framework | 2 | 3 | 70 | 2 | 2.1 |
| #395 | feat: Parallel Conflict Prediction | 2 | 3 | 70 | 2 | 2.1 |
| #397 | feat: QA FREE-MAD 挑戰韌性機制 | 2 | 3 | 60 | 2 | 1.8 |
| #394 | feat: TDAD Dependency Map | 2 | 3 | 70 | 2 | 2.1 |

> 注意：此表格為初始補充，後續新開 sprint-candidate Issue 時應於 Issue body 填寫 RICE Score（格式：`**RICE Score** | **N.N**`），Sprint Planning 時自動提取。

---

## 7. 維護說明

- 新開 sprint-candidate Issue 時，在 Issue body 加入 `**RICE Score** | **N.N**` 格式
- PO Cruise 巡邏時可在評估後補充 RICE Score 至 Issue comment
- 本標準文件由 PO 維護，每 3 個月（~12 Sprint）review 一次評分維度

---

## Model Routing 決策規則（ADR-039 Token Cost Routing）

<!-- #402 ADR-039 Token Cost Routing 實作 — Sprint 138 -->

在 RICE Score 基礎上，Sprint 138 新增 **Model Routing** 決策：Story 進入 Sprint Execution 前，依 ADR-039 四維度風險評分選擇適當 model tier。

### 風險評分 → Model Tier 對應

| 風險分數 | Tier | Model | 適用場景 |
|---------|------|-------|---------|
| 4–6 | 1 | `haiku` | doc-only 文件修改、格式轉換、retro-action 文件類 |
| 7–9 | 2 | `sonnet` | 一般功能實作、CI 修復、Backlog 分析（預設） |
| 10–12 | 3 | `opus` | ADR 架構決策、安全審查、L-size Story |

### RICE Score 與 Model Routing 的關係

- RICE Score 決定 **Backlog 排序優先序**（選哪些 Story 進 Sprint）
- Risk Score 決定 **執行時 model tier**（用哪個 model 執行）
- 兩者獨立計算，高 RICE Score 的 Story 不必然使用高 tier model

### 計算範例

| Story | RICE Score | Risk Score（R+S+C+N） | Model Tier |
|-------|-----------|----------------------|-----------|
| doc-only retro 任務 | 8 | 4（1+1+1+1）| Tier 1 haiku |
| CI workflow 修復 | 12 | 7（2+2+2+1）| Tier 2 sonnet |
| L-size 架構 ADR | 6 | 11（3+3+3+2）| Tier 3 opus |
