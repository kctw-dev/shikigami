# ADR 需求判斷 — 詳細規則

> 本文件由 `skills/architect/SKILL.md §2` 拆出。主文件保留觸發條件摘要，詳細規則在此。

## 判斷框架

ADR（Architecture Decision Record）的目的是記錄**有架構影響的技術決策**，使未來的 Architect 能理解決策背景、選項與取捨。以下標準判斷何時需要 ADR。

### 需要新建 ADR 的條件

**滿足任一以下條件即需要新建 ADR：**

1. **引入新技術選型**：引入目前專案未使用的框架、資料庫、第三方服務或工具（觸發 Hard Gate：無 ADR 的技術選型 Story 不得進入 Sprint）

2. **架構模式變更**：改變 Agent 之間的協作模式（例如從主 session 執行 Review 改為 subagent 自審，如 ADR-007）

3. **系統邊界重定義**：改變 Skill 之間的介面契約（輸入/輸出 Schema 改變）、新增或移除 Skill 之間的依賴關係

4. **安全策略決策**：定義新的安全邊界或 Prompt Injection 防護機制（如 ADR-006）

5. **流程強制化決策**：將原本「建議執行」的步驟升格為 Hard Gate（如 ADR-003 Framework Document Change 流程）

6. **角色權重調整機制**：新增基於指標的自動調整規則（如 ADR-004 Role Weight Adjustment）

**判斷觸發詞：** 若 Story 描述中出現「架構」、「選型」、「介面契約」、「協作模式」、「強制執行」、「Hard Gate 新增」等詞，應評估是否需要新建 ADR。

### 需要修改現有 ADR 的條件

**滿足以下條件時修改現有 ADR（而非新建）：**

1. **擴充現有決策範圍**：在既有 ADR 定義的架構框架內新增子機制（例如 ADR-007 Phase 2 外部抽樣審查機制是 ADR-007 §AC3 的實作，屬於既有決策範圍的延伸，不需新 ADR）

2. **修正決策細節**：原 ADR 的判斷條件需要微調，但核心決策方向不變

3. **新增觸發條件**：在既有機制中新增觸發條件（如在 ADR-004 的關鍵字清單中新增關鍵字）

**修改 ADR 時必須遵循 ADR-003 Checklist**（Framework Document Change 流程）。

### 不需要 ADR 的條件

**滿足以下任一條件即不需要 ADR：**

1. **純知識文件擴充**：新建或修改 SKILL.md 作為角色指引文件，無架構決策變更（如本 Story US-42）

2. **實作既有 ADR 的決策**：Story 的工作內容已在現有 Accepted ADR 的範圍內定義（如 US-41 實作 ADR-007 §AC3，無需新 ADR）

3. **Bug 修復或細節補充**：修正現有實作的錯誤，不改變設計方向

4. **UI/UX 或輸出格式調整**：調整 Markdown 格式、輸出樣式，不影響系統行為

**判斷觸發詞：** 若 Story 描述為「實作 ADR-XXX」、「補充說明」、「修正文件」、「新增知識文件」，通常不需要新 ADR。

## ADR 建立前置步驟（AC3 — US-#318）

<!-- US-#318 ADR claim 前置步驟 — Sprint 107 -->

**新建 ADR 前，Architect 必須先執行 claim**，確保多 session 不會同時建立同一 ADR 導致編號衝突：

```bash
bash hooks/claim-issue.sh "adr-NNN"
```

| 回傳值 | 處置 |
|--------|------|
| `[CLAIM-OK]` | 繼續建立 ADR 文件 |
| `[CLAIM-BLOCKED]` | 輸出 `[WARN] 已有其他 session 正在建立此 ADR`，繼續執行（不阻塞） |
| claim 失敗（git push 失敗）| 輸出 `[WARN]`，繼續執行（保守策略） |

ADR 文件建立完成並 commit 後，執行 release：

```bash
bash hooks/release-issue.sh "adr-NNN"
```

> **`NNN`** 為新 ADR 的三位數編號，例如：`bash hooks/claim-issue.sh "adr-024"`

## ADR 觸發清單（Sprint Planning 輸出項目）

Architect 在 Sprint Planning Round 2 必須輸出 ADR 觸發清單：

| Story | ADR 編號 | 說明 |
|-------|----------|------|
| US-#N | 新建 ADR-YYY | {觸發原因} |
| US-#N | 修改 ADR-YYY | {修改原因} |
| US-#N | 無需 ADR | {依據條件} |
