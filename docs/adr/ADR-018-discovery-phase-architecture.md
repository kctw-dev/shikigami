# ADR-018：Discovery Phase 架構方案 — 獨立 Skill vs 擴充 backlog-management

**狀態**：Proposed
**日期**：2026-03-11
**決策者**：Architect（待定）
**關聯 Issue**：#217（US-215 Discovery Phase RESEARCH Spike）
**關聯 ADR**：ADR-007（Story Lifecycle Subagent）、ADR-010（Backlog 管理演進）
**關聯 Sprint**：Sprint 80

---

## 背景

### 問題陳述

Shikigami 框架目前在 `skills/backlog-management/SKILL.md` §2 中定義了 **Product Discovery 流程**，作為里程碑啟動時的需求發掘機制。隨著框架複雜度提升（目前 8 個角色、多種 Story Type），現有 Product Discovery 流程暴露出以下問題：

1. **流程耦合過重**：`backlog-management` Skill 將 Product Discovery（探索性）與 Backlog Grooming（維護性）兩種性質迥異的流程合併，造成語意混淆。
2. **缺乏結構化產出物**：現有 Product Discovery 步驟僅產出 GitHub Issues 與 ROADMAP.md 更新，沒有定義 Product Brief 格式——導致需求的背景脈絡、商業價值、假設與驗證方法缺乏標準化記錄。
3. **PO 確認關卡不明確**：現有流程沒有定義 PO 在哪個節點必須確認需求有效，導致「探索產出」與「可執行 Backlog」之間的邊界模糊。
4. **反 Hallucination 風險**：Discovery 過程中大量依賴 PO subagent 的自由推斷，缺乏強制假設明確化的機制（與 US-214 不確定性三問的目標方向一致）。

### 觸發本 ADR 的契機

Sprint 80 US-215 要求調查 Discovery Phase 的架構方案，為後續實作 Story 提供決策基礎。本 ADR 為 Research Spike 產出，**不做最終決策**，僅完成選項分析與 PO/Architect 決策所需的資訊準備。

### 現有 backlog-management §2 的能力邊界

| 現有能力 | 說明 |
|---------|------|
| PO subagent 分析願景文件 | 有定義，但無結構化 Prompt 約束 |
| PO + Architect 協作討論 | 有定義，無正式輸出格式 |
| RICE 評分排序 | 有定義（§5.1） |
| GitHub Issues 開立 | 有定義（§2 最後步驟） |
| ROADMAP.md 更新 | 有定義 |
| **Product Brief 格式** | **不存在** |
| **PO 確認關卡** | **不存在** |
| **假設明確化機制** | **不存在** |
| **Discovery 與 Grooming 的明確分界** | **不存在** |

---

## 決策問題

Discovery Phase 的結構化強化應以何種架構方式實作？

具體而言：**應建立獨立的 Discovery Skill，還是在現有 `backlog-management` Skill 中擴充 §2？**

---

## 差異分析：現有 backlog-management §2 vs 提案 Discovery Phase

| 比較維度 | 現有 backlog-management §2 | 提案 Discovery Phase |
|---------|--------------------------|---------------------|
| **流程範疇** | Product Discovery + Backlog Grooming 合併（雙職能） | 專注 Discovery（需求探索與假設驗證），與 Grooming 完全分離 |
| **結構化產出物** | GitHub Issues + ROADMAP.md（自由格式描述） | Product Brief（標準化格式，含背景、假設、驗證方法、PO 確認）+ GitHub Issues + ROADMAP.md |
| **PO 確認關卡** | 無明確閘門，Discovery 產出直接成為 Backlog | 強制 PO 確認關卡：Product Brief 須經 PO 簽核後才能轉化為 Backlog Issues |
| **假設明確化** | 隱含於 RICE 評分，無強制外顯化 | 強制假設列舉（與 US-214 三問機制一致），每個 Discovery 項目必須明確標注假設與驗證方法 |
| **觸發時機** | 里程碑啟動時（§2 標題明確） | 里程碑啟動 + Sprint 中段（有新的重大需求不確定性時可獨立觸發） |
| **與 Grooming 的關係** | 緊密耦合（同一 SKILL.md，共享 §3–§8） | 完全解耦（獨立 Skill 或獨立 Section，各自有觸發條件與 DoD） |
| **維護成本** | 低（單一 Skill 檔案） | 高（獨立 Skill）/ 中（擴充現有 Skill） |
| **Agent 派遣複雜度** | 統一由 `/backlog-management` 觸發，內部 §2 或 §3 分流 | 獨立 Skill：`/discovery-phase` 獨立觸發；擴充 Skill：`/backlog-management --mode=discovery` |
| **Product Brief 格式** | 不存在，由 PO 自由撰寫 | 標準化模板：背景（Problem Statement）、目標使用者、商業假設、驗證方法、成功指標、PO 簽核欄 |

---

## 選項 A：獨立 Discovery Skill

### 架構描述

建立新的 `skills/discovery-phase/SKILL.md`，完全獨立於 `backlog-management`。Discovery Phase 有自己的觸發條件、執行流程、Product Brief 格式、PO 確認關卡、DoR/DoD，透過獨立的 slash command（`/discovery-phase`）或 Agent 派遣觸發。

### 架構示意

```
/discovery-phase（獨立觸發）
  ├─ Step 1：背景分析（PO 分析願景文件）
  ├─ Step 2：假設外顯化（三問機制，每個候選需求）
  ├─ Step 3：Product Brief 草稿（PO 產出標準化格式）
  ├─ Step 4：技術可行性評估（Architect 輸入）
  ├─ Step 5：PO 確認關卡（PO 簽核 Product Brief）
  └─ Step 6：轉化為 Backlog（開 GitHub Issues，移交 /backlog-management §3 Grooming）

/backlog-management（維持現有，§2 降格或保留為精簡版）
  └─ §2：簡化的 Discovery 摘要（指向 /discovery-phase 執行完整流程）
  └─ §3：Backlog Grooming（維持現有）
```

### Product Brief 格式建議

```markdown
# Product Brief：[需求名稱]

**版本**：v0.1（草稿）
**日期**：YYYY-MM-DD
**負責 PO**：[PO subagent]
**狀態**：草稿 / PO 確認中 / PO 已簽核

---

## 1. 問題陳述（Problem Statement）
[用 1-3 句話描述此需求解決的核心問題]

## 2. 目標使用者（Target Users）
[角色 + 使用場景描述]

## 3. 商業假設（Business Assumptions）
[UNCERTAIN] 假設 1：[描述] — 驗證方法：[方法]
[UNCERTAIN] 假設 2：[描述] — 驗證方法：[方法]

## 4. 提案解決方向（Proposed Direction）
[Option 1 / Option 2 … 不需完整設計，方向描述即可]

## 5. 成功指標（Success Metrics）
[可量化的驗收指標，與 RICE Reach/Impact 對應]

## 6. 排除範圍（Out of Scope）
[明確排除的功能或場景]

## 7. 依賴與風險（Dependencies & Risks）
[技術依賴 / 外部依賴 / 主要風險]

---

## PO 確認關卡

- [ ] Problem Statement 已與 Stakeholder 對齊
- [ ] Business Assumptions 已外顯化
- [ ] 提案解決方向已達成 PO 與 Architect 共識
- [ ] 此需求已 RICE 評分並確認優先級
- [ ] **PO 簽核**：□ 批准轉為 Backlog Issues　□ 退回修訂　□ 擱置
```

### PO 確認關卡定義

| 關卡名稱 | 觸發時機 | 守門人 | 通過條件 | 未通過後果 |
|---------|---------|--------|---------|----------|
| **Product Brief 草稿審查** | Step 3 完成後 | PO | Problem Statement 清晰、Assumptions 已外顯化 | 退回 Step 2 重新分析 |
| **技術可行性確認** | Step 4 完成後 | Architect | 無技術阻塞，或阻塞已識別並記錄 | 標注技術風險，回到 PO 決定是否繼續 |
| **PO 最終簽核** | Step 5 | PO | 所有 Assumptions 已驗證方法明確、優先級已 RICE 確認 | Brief 退回修訂或永久擱置 |

### 優劣分析

| 面向 | 評估 | 說明 |
|------|------|------|
| 關注點分離 | **優** | Discovery（探索）與 Grooming（維護）完全解耦，各自有清晰的 DoR/DoD |
| 觸發靈活性 | **優** | 可獨立於 Grooming 週期觸發，支援 Sprint 中段發現重大需求不確定性時隨時啟動 |
| 流程完整性 | **優** | 完整的 Product Brief 格式、PO 確認關卡、假設外顯化機制，無妥協 |
| 維護成本 | **劣** | 新增一個 SKILL.md，框架 Skill 數量增加；長期需同步維護兩個相關 Skill |
| 遷移成本 | **劣** | 需要修改 `backlog-management` §2（降格或刪除），有現有使用者影響 |
| 框架複雜度 | **劣** | 增加 Skill 數量，新用戶的學習成本提高 |
| YAGNI 符合性 | **中** | 若 Discovery Phase 確實有獨立觸發需求，分離有其必要性；若非如此則過度設計 |

---

## 選項 B：擴充現有 backlog-management Skill

### 架構描述

在 `skills/backlog-management/SKILL.md` 中強化 §2，新增 Product Brief 格式（附錄或 §2.x 子章節）、PO 確認關卡定義、假設外顯化步驟，維持 Discovery 與 Grooming 在同一 Skill 的架構，但以子流程方式明確分界。

### 架構示意

```
/backlog-management（維持單一觸發點）
  ├─ §2：Product Discovery 流程（強化版）
  │   ├─ §2.1 背景分析
  │   ├─ §2.2 假設外顯化（新增三問機制）
  │   ├─ §2.3 Product Brief 產出（新增標準化格式）
  │   ├─ §2.4 技術可行性評估（Architect 輸入）
  │   ├─ §2.5 PO 確認關卡（新增明確閘門）
  │   └─ §2.6 轉化為 Backlog Issues
  ├─ §3：Backlog Grooming（維持現有）
  └─ §A：Product Brief 格式（新增附錄）
```

### Product Brief 格式建議

與選項 A 相同（見上方 Product Brief 格式建議），格式不受架構選擇影響，均為標準化模板。

### PO 確認關卡定義

與選項 A 的三個關卡定義相同（見上方 PO 確認關卡定義），關卡內容不受架構選擇影響。

差異在於關卡的**落地方式**：
- 選項 A：關卡定義在獨立 Skill 的執行流程中
- 選項 B：關卡定義在 `backlog-management` §2.5，與 Grooming 使用同一 slash command，以模式旗標或執行階段判斷觸發

### 優劣分析

| 面向 | 評估 | 說明 |
|------|------|------|
| 維護成本 | **優** | 單一 SKILL.md，無新增 Skill；框架 Skill 數量保持穩定 |
| 遷移成本 | **優** | 純增量修改，不破壞現有 `/backlog-management` 使用方式 |
| 向後相容 | **優** | 現有使用 `/backlog-management` 的 Sprint 流程無需調整 |
| YAGNI 符合性 | **優** | 在「獨立觸發需求」未被真實場景驗證前，擴充現有 Skill 是最小可行設計 |
| 框架複雜度 | **優** | 不增加新 Skill，降低新用戶學習成本 |
| 關注點分離 | **中** | Discovery 與 Grooming 雖有明確子章節分界，但仍在同一 Skill 內，長期演進可能再度耦合 |
| 觸發靈活性 | **中** | 可以 `--mode=discovery` 旗標支援獨立觸發，但需額外設計觸發機制；不如獨立 Skill 直覺 |
| 流程完整性 | **中** | 能實現所有功能性需求，但架構邊界不如獨立 Skill 清晰 |

---

## 評估矩陣

| 評估維度 | 選項 A（獨立 Discovery Skill） | 選項 B（擴充 backlog-management） |
|---------|-------------------------------|----------------------------------|
| 關注點分離 | 高（完全解耦） | 中（子章節分界，仍在同一 Skill） |
| 維護成本 | 高（新增 Skill） | 低（增量修改） |
| 遷移成本 | 高（需修改現有 §2） | 低（純增量） |
| 向後相容 | 中（需降格現有 §2） | 高（無破壞性變更） |
| 觸發靈活性 | 高（獨立 slash command） | 中（旗標或內部分流） |
| YAGNI 符合性 | 中（需驗證獨立觸發的真實需求） | 高（最小可行設計） |
| Product Brief 完整度 | 高（無妥協） | 高（相同格式，不受架構影響） |
| PO 確認關卡完整度 | 高（無妥協） | 高（相同關卡，不受架構影響） |
| 假設外顯化機制 | 高（流程設計無妥協） | 高（相同機制，不受架構影響） |
| 框架學習成本 | 高（多一個 Skill） | 低（維持現有 Skill 數量） |

---

## 開放問題

| # | 問題 | 優先級 | 狀態 |
|---|------|--------|------|
| OQ-1 | Discovery Phase 是否確實需要在 Grooming 週期外獨立觸發？若現實中 Discovery 永遠只在里程碑啟動時觸發，選項 B 的分離劣勢不存在 | 高 | **Open** |
| OQ-2 | backlog-management §2 與強化版 Discovery 的行為差異是否大到需要完全分離的 context？若 PO subagent 在同一 Skill 內可清晰區分，合併不造成 LLM 行為品質下降 | 高 | **Open** |
| OQ-3 | Product Brief 是否需要作為獨立文件保存（`docs/discovery/`），或僅作為 GitHub Issue body 的一部分？此問題影響產出物管理，但不影響架構選擇 | 中 | **Open** |
| OQ-4 | 與 US-214（不確定性三問機制）的整合點——Discovery Phase 的假設外顯化步驟與 US-214 的三問機制是否應共享同一格式標準，避免兩套平行的假設記錄機制 | 中 | **Open** |

---

## 初步傾向（非最終決策）

基於以下觀察，在最終決策前供 PO 與 Architect 參考：

1. **YAGNI 原則傾向選項 B**：目前無真實場景驗證「Discovery 必須在 Grooming 週期外獨立觸發」。選項 B 能實現所有功能性需求（Product Brief、PO 確認關卡、假設外顯化），且維護成本更低。

2. **長期演進傾向選項 A**：若 OQ-1 驗證後確認需要獨立觸發，從選項 B 演進到選項 A 的遷移成本可接受（建立新 Skill，降格 §2）。從選項 A 回到選項 B 的逆向演進同樣可行。

3. **兩個選項的功能等價性**：Product Brief 格式、PO 確認關卡、假設外顯化機制在兩個選項中完全相同，差異僅在「放在哪裡」和「如何觸發」。這表示可以先選擇選項 B（較低成本），待 OQ-1 有答案後再決定是否遷移到選項 A。

**建議決策路徑**：
1. PO 確認 OQ-1（Discovery 是否需要獨立觸發的真實場景）
2. Architect 評估 OQ-2（同一 Skill 內是否影響 LLM 行為品質）
3. 兩個 OQ 均有答案後，本 ADR 升格為 Accepted 並更新決策

---

## 實作影響預估

### 選項 A 實作影響

| 文件 | 變更類型 | 說明 |
|------|---------|------|
| `skills/discovery-phase/SKILL.md` | **新建** | Discovery Phase 完整 Skill 定義 |
| `skills/backlog-management/SKILL.md` | **修改** | §2 降格為「指向 /discovery-phase 的精簡摘要」或完全移除 |
| `skills/sprint-planning/SKILL.md` | **修改** | 更新 Discovery 觸發說明，指向新 Skill |
| `.claude-plugin/plugin.json` | **修改** | 新增 discovery-phase Skill 定義 |

### 選項 B 實作影響

| 文件 | 變更類型 | 說明 |
|------|---------|------|
| `skills/backlog-management/SKILL.md` | **修改** | §2 強化（新增 §2.2–§2.5、附錄 Product Brief 格式） |

### 共同實作影響

| 文件 | 變更類型 | 說明 |
|------|---------|------|
| `docs/templates/product-brief-template.md` | **新建（可選）** | Product Brief 標準化模板（兩個選項均可使用） |

---

## 參考

- `skills/backlog-management/SKILL.md`：現有 Backlog Management Skill（本 ADR 分析對象）
- ADR-007：Story Lifecycle Subagent 架構（Subagent 派遣模式參考）
- ADR-010：Backlog 管理演進（backlog-management Skill 歷史決策背景）
- ADR-016：UI/UX Designer 角色定義（獨立 Skill vs 整合的決策參考案例，OQ-1 決策為整合）
- GitHub Issue #217：US-215 Discovery Phase RESEARCH Spike（本 ADR 觸發 Issue）
- `skills/sprint-execution/story-lifecycle-prompt.md`：US-214 不確定性三問機制（OQ-4 相關）
