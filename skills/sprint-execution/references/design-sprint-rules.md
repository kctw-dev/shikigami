# DESIGN Type Story 執行路徑 + Sprint 內排序規則

## 4.5 DESIGN Type Story 執行路徑（ADR-016）

<!-- US-207：框架整合更新 — Sprint 78 -->

DESIGN type Story 的執行路徑與 FEATURE type 不同，派遣 **UI/UX Designer subagent**（而非 Developer subagent）：

```
Sprint Backlog 取出 DESIGN type Story
  |
  v
派遣 UI/UX Designer subagent（agents/uiux-designer.md）
  |
  v
Designer 內部閉環：
  ├─ 確認 Design Foundation 就緒（Design System、Tokens、Component Library）
  ├─ 透過 KCTW/talk-to-figma-mcp 製作 Figma Prototype
  ├─ Vision Critic 自審（≥80 分 PASS，最多重試 3 次）
  ├─ QA Contract Testability Review（確認 Prototype 可測試性）
  └─ 兩者皆 PASS → Prototype 凍結為 Contract
  |
  v
回傳 PASS / FAIL / ESCALATE
```

**與 FEATURE 路徑的差異：**

| 面向 | FEATURE 路徑 | DESIGN 路徑 |
|------|-------------|-------------|
| 執行角色 | Developer subagent | UI/UX Designer subagent |
| TDD | 必須（Hard Gate） | 豁免（無可執行測試） |
| 自審工具 | Spec Compliance + Code Quality | Vision Critic（三維度評分） |
| Contract 產出 | API 契約 | Figma Prototype |
| QA 審查 | Spec Compliance + Code Quality Review | Contract Testability Review |

詳細 DESIGN Story 執行流程定義請參閱 [`skills/uiux-designer/SKILL.md`](../uiux-designer/SKILL.md) §4。

---

## 4.6 DESIGN ↔ FEATURE Sprint 內排序規則（ADR-016 OQ-2）

<!-- US-210：DESIGN Story Sprint 內排序規則 — Sprint 79, ADR-016 OQ-2 -->

### 排序原則

**DESIGN Story 是同 Sprint 內依賴其 Contract 的 FEATURE Story 的 blocker。**

在 Sprint Backlog 取出 Story 時，必須依以下優先順序執行：

```
Sprint Backlog 取出順序：
  1. DESIGN Story（所有 DESIGN type Story 優先執行）
  2. 其他 Story（FEATURE / INFRA / RESEARCH 等，不依賴 DESIGN Contract 者）
  3. 依賴 DESIGN Contract 的 FEATURE Story（需等 DESIGN Story Contract 凍結後執行）
```

**規則說明：**

| 規則 | 說明 |
|------|------|
| DESIGN 先行 | 同 Sprint 若同時有 DESIGN Story 與依賴其 Contract 的 FEATURE Story，DESIGN Story 必須先完成 Contract 凍結，FEATURE Story 才可開始執行 |
| 無依賴 FEATURE 可平行 | 若 FEATURE Story 不依賴當前 Sprint 任何 DESIGN Story 的 Contract，可與 DESIGN Story 平行執行，不受排序限制 |
| 依賴判定標準 | FEATURE Story 的 AC 中明確引用「依 Figma Prototype Contract」或 Sprint 文件的「依賴」欄位標注依賴 DESIGN Story，判定為依賴關係 |

### DESIGN Story 依賴判定

主 session 取出 Story 前，掃描各 FEATURE Story 的 AC 與備注欄：若含「依 Figma Prototype」或「依 {DESIGN Story ID} Contract」→ 標記為 DESIGN 依賴，加入等待佇列；否則可平行執行。

### 未完成 DESIGN Story 的處理程序（AC2）

若 DESIGN Story 在 Sprint 結束前未完成 Contract 凍結（FAIL 或 ESCALATE），依賴其 Contract 的 FEATURE Story 適用以下處理程序：

<HARD-GATE>
**DESIGN blocker 未解除時，依賴其 Contract 的 FEATURE Story 禁止進入開發。**
</HARD-GATE>

#### 處理決策樹

```
DESIGN Story 執行結果：
  |
  |-- PASS（Contract 凍結）
  |     → 依賴此 Contract 的 FEATURE Story 解除封鎖，可按正常流程取出執行
  |
  |-- FAIL（Vision Critic 或 QA Contract Testability Review 持續失敗）
  |     → 依賴此 Contract 的 FEATURE Story 適用「FAIL 處理程序」（見下方）
  |
  +-- ESCALATE（DESIGN_ISSUE / DEPENDENCY_MISSING）
        → 依賴此 Contract 的 FEATURE Story 適用「ESCALATE 處理程序」（見下方）
```

#### FAIL 處理程序

當 DESIGN Story 回傳 FAIL 時，主 session 執行以下決策：

| 決策 | 條件 | 說明 |
|------|------|------|
| **方案 A：回流 Backlog** | Sprint 剩餘時間不足以修復 DESIGN Story | 將 DESIGN Story 與所有依賴其 Contract 的 FEATURE Story 一起回流至 Product Backlog，下次 Sprint Planning 重新排程 |
| **方案 B：拆分 Sprint** | Sprint 剩餘時間充裕，DESIGN 問題為局部瑕疵 | DESIGN Story 繼續修復重試（Architect 介入評估設計問題），FEATURE Story 持續等待 |
| **方案 C：降級執行** | FEATURE Story 可用模擬資料（Mock Contract）開發 | 標注 FEATURE Story 為「[MOCK-CONTRACT] 依賴未凍結 Contract，需 Sprint Review 前補充驗收」；開發完成後 Contract 凍結時補做 Contract Compliance 驗收 |

**預設行為**：若主 session 無法判斷上述方案，預設採用**方案 A（回流 Backlog）**，不強行執行依賴未凍結 Contract 的 FEATURE Story。

#### ESCALATE 處理程序

當 DESIGN Story 回傳 ESCALATE 時，依升級類型處置：

| 升級類型 | 對依賴 FEATURE Story 的影響 | 主 session 處置 |
|---------|--------------------------|----------------|
| `DESIGN_ISSUE` | 依賴 FEATURE Story 暫停（Architect 介入中） | 暫停 Sprint，等待 Architect 評估後決定是否繼續 |
| `DEPENDENCY_MISSING` | 依賴 FEATURE Story 封鎖（Design Foundation 不完整） | 解決 Design Foundation 依賴後重試 DESIGN Story |
