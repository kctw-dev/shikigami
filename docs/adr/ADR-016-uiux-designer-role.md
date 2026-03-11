# ADR-016：UI/UX Designer 角色定義與 Design Foundation 流程

**狀態**：Accepted
**日期**：2026-03-11
**決策者**：Architect
**關聯 Issue**：#207（UI/UX Designer 角色缺口）
**關聯 ADR**：ADR-014（UIUX Agent 架構決策）、ADR-015（Figma 整合取代 SSD 管線）、ADR-007（Story Lifecycle Subagent）

---

## 背景

### 問題陳述

Shikigami 框架自 v0.50.0（Sprint 76）起建立了完整的 Story Type 分類系統，其中 **DESIGN** type 定義了 UI/UX 設計相關 Story 的分類規則、Contract Owner（UI/UX Designer）、Type-specific DoR/DoD。然而，框架實際上**不存在 UI/UX Designer 角色**——現有 7 個角色（PO、Architect、Developer、QA、Security Engineer、SRE、Scrum Master）中沒有任何一個承擔設計職責。

這導致了一個結構性矛盾：

- `skills/sprint-planning/SKILL.md` §8.3 將 DESIGN type 的 Contract Owner 指定為「UI/UX Designer」
- `skills/sprint-execution/SKILL.md` §5 為 DESIGN type 定義了 TDD 豁免和 Review 策略
- `skills/sprint-execution/story-lifecycle-prompt.md` 將 DESIGN 列為合法 `story_type` 值
- **但沒有任何 Agent 定義檔（`agents/`）或 Skill 定義檔（`skills/`）對應此角色**

### 已有技術資產

本決策不是從零開始。以下資產已在框架中存在且經過驗證：

| 資產 | 狀態 | 說明 |
|------|------|------|
| `skills/vision-critic/SKILL.md` | **Active** | 三維度視覺評分（Layout 35% + Token 40% + Component 25%），Figma MCP 整合，PASS/FAIL 判定 |
| `skills/ux-agent/SKILL.md` | Deprecated | ADR-015 廢棄 SSD JSON 管線後不再使用；但語意架構萃取的方法論仍有價值 |
| `skills/ui-agent/SKILL.md` | Deprecated | ADR-015 廢棄後不再使用；但元件庫白名單與 Design Token 注入規則仍適用 |
| `KCTW/talk-to-figma-mcp` | **已驗證**（kagemusha） | Fork of grab/cursor-talk-to-figma-mcp，新增 `set_reactions`、`create_component_from_node`、`create_variables` + ECDSA P-256 認證 |
| `docs/design/design-tokens.json` | **Active** | 13 個具名 Figma Variables，v1.0.0 |
| `docs/design/component-library-spec.md` | **Active** | Button/Input/Card 規格（尺寸、間距、圓角、Auto Layout） |
| ADR-014 | Accepted | 三層 Agent 架構決策（Phase 1 完成，Phase 2-3 凍結） |
| ADR-015 | Accepted | Figma 整合取代 SSD JSON（OQ-1~OQ-4 全部調查完成） |

### 約束條件

| 約束 | 來源 | 說明 |
|------|------|------|
| Token 成本控制 | 框架核心原則 | 每增加一個 subagent 角色增加 LLM 呼叫成本；角色數量需與價值成正比 |
| Figma Desktop App 依賴 | ADR-015 OQ-1 | 設計寫入操作必須透過 Plugin API，需 Figma Desktop App 執行環境 |
| 現有 7 角色制衡體系 | 框架既有設計 | 新角色引入不得破壞現有角色的職責邊界與制衡機制 |
| YAGNI 原則 | ADR-011/ADR-012 共同確立 | 不為假設性需求預先設計 |
| ADR-006 注入防護 | ADR-006 | 所有外部資料（Figma 截圖、節點 JSON）進入 Agent prompt 須套用 XML 隔離標記 |

---

## 決策問題

Shikigami 框架應以何種角色架構整合 UI/UX 設計能力，定義該角色的職責邊界、與現有角色的協作機制、Design Foundation 流程、以及 DESIGN type Story 的完整執行路徑？

---

## 決策域 1：角色架構——合併 vs 拆分

### Option A：單一 UI/UX Designer 角色（合併）

建立一個統合角色，同時承擔 UX（資訊架構、互動設計）與 UI（視覺設計、元件實作）職責。

#### 架構示意

```
UI/UX Designer（統合角色）
  ├─ UX 職責：資訊架構、互動流程、使用者旅程
  ├─ UI 職責：Design System、Design Tokens、Component Library
  ├─ 產出：Figma Prototype（= DESIGN Story Contract）
  └─ 自審：Vision Critic（三維度視覺評分）
```

#### 優缺點

| 面向 | 評估 | 說明 |
|------|------|------|
| Token 成本 | **優** | 每個 DESIGN Story 僅派遣 1 個 subagent，相比拆分方案節省 50% LLM 呼叫 |
| 上下文連貫性 | **優** | UX 決策（架構）與 UI 決策（視覺）在同一 context window 內，避免跨 Agent 資訊遺失 |
| 實作複雜度 | **優** | 1 個 Agent 定義 + 1 個 SKILL.md，維護成本低 |
| 關注點分離 | **中** | UX 與 UI 兩種認知模式在同一 prompt 中競爭，但 Figma 工具本身已將兩者整合 |
| 可擴展性 | **中** | 未來若需拆分，可從單一角色中分離出 UX 專責，演進路徑明確 |

### Option B：拆分 UX Designer + UI Designer

建立兩個獨立角色，形成串行設計管線。

#### 架構示意

```
UX Designer（資訊架構師）
  │ 輸出：資訊架構規格（Figma wireframe）
  ▼
UI Designer（視覺設計師）
  │ 輸入：UX wireframe + Design System
  │ 輸出：Figma Prototype（高保真）
  └─ 自審：Vision Critic
```

#### 優缺點

| 面向 | 評估 | 說明 |
|------|------|------|
| Token 成本 | **劣** | 每個 DESIGN Story 需派遣 2 個 subagent（成本加倍） |
| 關注點分離 | **優** | UX 專注架構思維，UI 專注視覺實作，各自 prompt 更聚焦 |
| 實作複雜度 | **劣** | 2 個 Agent 定義 + 2 個 SKILL.md + Agent 間溝通協議（ADR-014 已經證明此複雜度的維護成本高） |
| 跨 Agent 資訊遺失 | **劣** | UX → UI 的語意傳遞需要中間格式（ADR-015 已廢棄 SSD JSON 正是因為此問題） |
| 可逆性 | **中** | 合併容易，但拆分後合併需重新定義職責邊界 |

### Option C：不新增角色，DESIGN Story 由 Developer 執行

不引入新角色，DESIGN type Story 由 Developer subagent 在 TDD 豁免模式下執行設計工作。

#### 優缺點

| 面向 | 評估 | 說明 |
|------|------|------|
| 變更成本 | **優** | 零新增角色，零架構變更 |
| 設計品質 | **劣** | Developer 的 prompt 專注於程式開發，缺乏設計思維約束；ADR-014 的核心動機即是「不相信 AI 的自由發揮，只相信嚴格定義的約束」 |
| 制衡機制 | **劣** | Developer 既設計又實作，無制衡；Vision Critic 的審查基準需要 Designer 角色來定義與維護 |
| 長期演進 | **劣** | 框架無法區分「設計能力」與「開發能力」，DESIGN Story 永遠依附於 Developer 的 context |

### 決策域 1 評估矩陣

| 評估維度 | Option A（合併） | Option B（拆分） | Option C（不新增） |
|---------|-----------------|-----------------|-------------------|
| Token 成本 | 低（1 subagent） | 高（2 subagents） | 最低（0 新增） |
| 設計品質保證 | 高 | 最高 | 低 |
| 實作複雜度 | 低 | 高 | 最低 |
| 維護成本 | 低 | 高 | 最低 |
| 角色制衡 | 高（Designer + Vision Critic） | 最高（UX + UI + Vision Critic） | 低（無獨立審查） |
| ADR-015 相容性 | 高（Figma 整合設計本身合併 UX/UI） | 中（需定義 UX→UI 在 Figma 中的交接） | 低（Developer 非設計角色） |
| YAGNI 符合性 | 高 | 低（過度設計） | 最高（但犧牲品質） |

---

## 決策域 2：Design Foundation 流程

### 問題

DESIGN type Story 的 Contract（Figma Prototype）不會從天上掉下來。在 Sprint 內執行 DESIGN Story 之前，需要 Design System、Design Tokens、Component Library 等基礎設施。這些基礎設施的建立流程為何？

### Design Foundation 三方協作模型

Design Foundation 是 **Pre-Sprint 流程**，在 Sprint Planning 之前執行，為 DESIGN Story 提供必要的設計基礎。

```
PO（產品輸入）+ Architect（技術約束）
         ↓
   UI/UX Designer
   （Design Foundation 產出）
         ↓
   Design System + Tokens + Component Library
```

#### 三方職責分工

| 參與者 | Design Foundation 職責 |
|--------|----------------------|
| **PO** | 產品願景、User Stories、商業需求優先級、使用者旅程定義 |
| **Architect** | 技術可行性審查、架構約束輸入（前端框架限制、效能預算）、元件邊界定義（與系統模組對齊）、Design Token 結構與 CSS 架構相容性確認 |
| **UI/UX Designer** | Design System 建立（Figma Variables、Auto Layout 規則）、Design Tokens 定義（遷移至 Figma Variables）、Component Library 產出（Figma Component + Instance）、Prototype 製作 |

#### 依賴鏈

```
PO 產出 User Stories（必要前置）
  → Architect 提供技術約束（元件粒度、效能預算、框架限制）
    → UI/UX Designer 建立 Design Foundation
      → Design System + Tokens + Component Library 就緒
        → Sprint Planning 可選入 DESIGN Story
```

**關鍵約束**：PO 必須先產出 User Stories，Designer 才能建立對應的 Component Library。沒有商業需求驅動的設計是空中樓閣。Architect 必須參與，否則 Designer 可能設計出技術上不可行的元件。

#### Design Foundation 觸發時機

| 觸發條件 | 說明 |
|---------|------|
| 新消費端專案啟動 | 首次建立 Design System，為專案定義設計語言 |
| 新 ROADMAP 里程碑啟動 | 里程碑涉及新頁面/新功能區域時，評估是否需要擴充 Component Library |
| Design Tokens 重大變更 | 品牌改版、主題系統引入等，需 Architect 確認技術相容性 |

---

## 決策域 3：Review 責任矩陣

### 問題

DESIGN type Story 的產出物（設計稿、Prototype）應由誰審查？QA 的審查標準適用於程式碼品質，不適用於視覺設計品質。但 Prototype 作為 Contract 凍結前，其「可測試性完整度」又是 QA 專長所在。

### Review 責任矩陣

| 產出物 | Review 者 | 審查工具 | 審查重點 |
|--------|----------|---------|---------|
| Design System / Tokens | **Architect** | 人工 Review | 技術可行性、CSS 架構相容性、效能預算 |
| Component Library | **Architect** | 人工 Review | 元件粒度與框架 component model 匹配、模組邊界 |
| Figma Prototype（視覺合規） | **Vision Critic**（Designer 自審） | `skills/vision-critic/SKILL.md` | Layout 一致性、Design Token 合規、Component Spec 合規 |
| Figma Prototype（Contract 可測試性） | **QA** | Contract Testability Review | 狀態覆蓋完整性、互動行為定義、可驗收性 |
| 前端實作（依 Prototype Contract） | **QA** | Spec Compliance + Code Quality | 功能正確性、Contract 符合度、程式碼品質 |

### 雙重審查流程（Prototype → Contract 凍結）

```
UI/UX Designer 完成 Figma Prototype
  → Vision Critic 審查（視覺合規性，≥80 分 PASS）
    → QA Contract Testability Review（可測試性完整度）
      → 兩者皆 PASS → Prototype 凍結為 Contract
      → 任一 FAIL → 回到 Designer 修正
```

**為何需要雙重審查（Decision Challenger 挑戰回應）**：

QA Decision Challenger 指出 Vision Critic 評分的三個維度（Layout 35% + Token 40% + Component 25%）全部聚焦於**設計系統合規性**，與 **Contract 可測試性完整度**正交。一個 Prototype 可以拿到 Vision Critic 97 分，卻缺少 Error State、表單驗證行為、邊界狀態覆蓋——這些缺陷在前端實作階段才被發現時，修改成本是 Prototype 階段的 5~10 倍。

因此，Contract 凍結的充分條件修正為：**Vision Critic PASS（視覺合規）AND QA Contract Testability Review PASS（可測試性）**。

### QA Contract Testability Review 審查清單

QA 在 Vision Critic PASS 後、Contract 凍結前執行以下審查（不涉及視覺判斷）：

| 審查項目 | 說明 |
|---------|------|
| Happy Path 覆蓋 | 每個 User Story 的主要成功路徑是否有對應 Figma Frame |
| Error Path 覆蓋 | 至少一條錯誤路徑（如表單驗證失敗、網路錯誤、權限不足）有對應 Frame |
| 互動元件狀態完整性 | 每個可互動元件的狀態（Default、Hover、Active、Disabled、Error）是否定義 |
| 表單驗證行為 | 驗證觸發時機（即時 / 提交後）、錯誤訊息位置是否明確 |
| 邊界狀態 | 空狀態（Empty State）、Loading 狀態、文字截斷處理是否有規格 |
| AC 可轉化性 | Prototype 能否轉化為可量化的 Acceptance Criteria |

### 設計原則

- **QA 不介入視覺審查**：QA 不判斷「這個藍色好不好看」，那是 Vision Critic 的職責。QA 判斷的是「這個 Prototype 能否作為可驗收的 Contract」。
- **Vision Critic 是 Designer 的 self-review 工具**：類似 Developer 的 Code Quality self-review，Designer 透過 Vision Critic 驗證自己的 Figma 產出是否符合 Design System 規範。
- **Architect 審查 Foundation 層**：Design System 和 Component Library 是技術基礎設施，需 Architect 確認與系統架構相容。
- **雙重審查避免單點失效**：Vision Critic 單獨作為 Contract 凍結閘門是單點失效風險。加入 QA Testability Review 不增加新 Agent（QA 角色已存在），Token 成本影響可忽略。

---

## 決策域 4：Contract 定義

### 問題

FEATURE type Story 的 Contract 是 API 契約（端點、Request/Response Schema）。DESIGN type Story 的 Contract 應為何？

### 決策

**Figma Prototype = DESIGN Story 的 Contract**

| 面向 | FEATURE Contract | DESIGN Contract |
|------|-----------------|----------------|
| 格式 | API 契約（JSON Schema） | Figma Prototype（Frame + Interactions） |
| 內容 | 端點路徑、Request/Response Schema、狀態碼 | 頁面佈局、互動流程、元件規格、Design Token 綁定 |
| 驗證方式 | QA Spec Compliance Review | Vision Critic 三維度評分 |
| 消費者 | Developer（實作 API） | Developer（實作前端，以 Prototype 為規格書） |
| 儲存位置 | `docs/sdd/` 或 Sprint 文件 | Figma 文件（Frame link 記錄於 Sprint 文件） |

### Contract 生命週期

```
DESIGN Story 進入 Sprint
  → UI/UX Designer 建立 Figma Prototype
    → Vision Critic 審查（視覺合規，≥80 分 PASS）
      → QA Contract Testability Review（可測試性完整度）
        → 兩者皆 PASS → Prototype 凍結為 Contract
          → 後續 FEATURE Story 的 Developer 依 Contract 實作前端
            → QA 驗收前端實作是否符合 Prototype Contract
```

---

## 決策域 5：工具整合

### KCTW/talk-to-figma-mcp 定位

| 能力 | 對應 Design Foundation 需求 |
|------|--------------------------|
| `create_component_from_node` | Component Library 建立（Frame → Component） |
| `create_variables` | Design Tokens 定義（Variable Collection + 多模式） |
| `set_reactions` | Prototype 互動定義（ON_CLICK 導航等） |
| ECDSA P-256 認證 | 安全 WebSocket 連線 |
| 自動加入 Channel | 簡化連線流程 |

### MCP 工具路由

| 操作類型 | MCP Server | 說明 |
|---------|-----------|------|
| 設計寫入（建立 Frame、Component、Variable） | KCTW/talk-to-figma-mcp | Plugin API 路徑，無 Enterprise 限制 |
| 設計讀取（截圖、節點結構） | 官方 Figma MCP Server 或 KCTW fork | 均支援 |
| Vision Critic 截圖審查 | `export_node_as_image`（KCTW fork）或 `get_screenshot`（官方） | ADR-015 已定義 |

---

## 建議方案

### 建議：Option A（單一 UI/UX Designer 角色）+ Design Foundation 三方協作 + Vision Critic 自審 + Figma Prototype Contract

#### 理由

1. **ADR-015 已消除拆分理由**：ADR-014 拆分 UX/UI 的動機是 SSD JSON 中間格式需要兩個 Agent 分工。ADR-015 廢棄 SSD JSON 後，AI 直接在 Figma 操作，UX 架構與 UI 視覺在 Figma 中天然統一，拆分失去技術必要性。

2. **Token 成本最佳化**：合併方案每個 DESIGN Story 派遣 1 個 subagent，相比拆分方案節省 50% LLM 呼叫成本。在 Shikigami 框架已有 7 個角色的前提下，新增 1 個角色比新增 2 個角色的邊際成本更可控。

3. **已驗證技術基礎**：KCTW/talk-to-figma-mcp 已在 kagemusha 專案驗證，Vision Critic Skill 已實作且 Active，Design Tokens 定義檔已建立。技術層全部就緒，缺的只是角色定義與流程串接。

4. **演進路徑保留**：若未來發現合併角色的 context window 不足以同時處理 UX 架構與 UI 視覺，可透過新 ADR 將角色拆分，演進路徑明確且可逆。

5. **YAGNI 符合**：在沒有實際消費端專案驗證「UX 與 UI 必須拆分」之前，合併方案是最小可行設計。

#### 決策摘要

| 決策域 | 決策 |
|--------|------|
| 角色架構 | 單一 UI/UX Designer（合併 UX + UI） |
| Design Foundation | Pre-Sprint 三方協作（PO + Architect + Designer） |
| Review 責任 | Design Foundation → Architect；Prototype 視覺合規 → Vision Critic（Designer 自審）；Prototype 可測試性 → QA Contract Testability Review；前端實作 → QA |
| Contract 凍結條件 | Vision Critic PASS（≥80 分）**AND** QA Contract Testability Review PASS（雙重審查） |
| Contract 定義 | Figma Prototype = DESIGN Story Contract |
| 工具基礎 | KCTW/talk-to-figma-mcp + 官方 Figma MCP Server |

---

## 實作影響

### 新增文件

| 文件 | 內容 |
|------|------|
| `agents/uiux-designer.md` | UI/UX Designer Agent 定義（角色描述、觸發條件、可用工具） |
| `skills/uiux-designer/SKILL.md` | UI/UX Designer Skill 定義（Design Foundation 流程、DESIGN Story 執行路徑、Vision Critic 整合） |

### 修改文件

| 文件 | 修改內容 |
|------|----------|
| `skills/sprint-execution/SKILL.md` | §5 DESIGN type Review 策略：指向 `uiux-designer` 角色；新增 DESIGN Story 執行路徑 |
| `skills/sprint-execution/story-lifecycle-prompt.md` | 新增 DESIGN type 執行分支：派遣 UI/UX Designer subagent（非 Developer） |
| `skills/sprint-planning/SKILL.md` | §8.3 Contract Owner 確認指向實際 Agent；Design Foundation 觸發時機寫入 §9 Refinement |
| `skills/scrum-master/SKILL.md` | 角色清單從 7 個更新為 8 個 |
| `.claude-plugin/plugin.json` | 若 Agent 定義影響 plugin 結構則更新 |

### 對現有 ADR 的影響

| ADR | 影響 | 說明 |
|-----|------|------|
| ADR-014 | 補充 | Phase 1 交付物保留（Design Tokens、元件庫白名單）；三層分工在 Figma 語境下收斂為 Designer + Vision Critic 雙層 |
| ADR-015 | 擴展 | 新流程定義中「AI 透過 Figma MCP 畫 UI」的「AI」角色正式定義為 UI/UX Designer subagent |
| ADR-007 | 擴展 | Story-Lifecycle subagent 需新增 DESIGN type 執行分支（派遣 Designer 而非 Developer） |

### 框架角色數量變化

| 變化前 | 變化後 |
|--------|--------|
| 7 個角色：PO、Architect、Developer、QA、Security、SRE、Scrum Master | 8 個角色：PO、Architect、**UI/UX Designer**、Developer、QA、Security、SRE、Scrum Master |

---

## 開放問題

| # | 問題 | 優先級 | 狀態 |
|---|------|--------|------|
| OQ-1 | Design Foundation 流程的具體 Skill 實作——應獨立為 `design-foundation` Skill 還是整合進 `uiux-designer` SKILL.md？SRE 建議整合以降低 Toil。 | 中 | **Closed**（US-211，2026-03-11） |
| OQ-2 | DESIGN Story 與 FEATURE Story 的 Sprint 內排序——DESIGN Story 是否必須在同 Sprint 的 FEATURE Story 之前完成（blocker 關係）？若 DESIGN Story 未在期限內完成的處理程序為何？此問題影響 Sprint 交付可靠性。 | 高 | Open |
| OQ-3 | UI/UX Designer 的 Provider 路由——是否支援 Gemini CLI 雙軌派遣（§2.1）？Figma MCP 工具在 Gemini 環境是否可用？ | 低 | **Closed**（US-213，2026-03-11） |
| OQ-4 | Figma MCP 環境健康檢查 Runbook——DESIGN Story 啟動前需驗證 4 個依賴項（Figma Desktop、Plugin 連接、CLI Server、MCP 連接），定義快速檢查序列與各依賴失敗的恢復步驟。 | 高 | Open |
| OQ-5 | VRR 報告長期儲存策略——`docs/vision-critic-reports/` 永久保留會造成 git 倉庫持續增長，是否設定保留期限（如 90 天）或排除 git 追蹤？ | 低 | Open |

---

## OQ-3 調查結論（US-213，2026-03-11）

### 問題

UI/UX Designer 的 Provider 路由——是否支援 Gemini CLI 雙軌派遣？Figma MCP 工具（KCTW/talk-to-figma-mcp）在 Gemini CLI 環境是否可用？

### 調查結論

**結論：Gemini CLI 支援 MCP Server，designer 角色可加入雙軌派遣路由表。**

| 調查項目 | 結果 |
|---------|------|
| Gemini CLI 是否支援 MCP protocol？ | **是**。Gemini CLI 原生支援 Model Context Protocol（MCP），文件見 [google-gemini/gemini-cli/docs/tools/mcp-server.md](https://github.com/google-gemini/gemini-cli/blob/main/docs/tools/mcp-server.md) |
| 是否支援 STDIO transport？ | **是**。與 KCTW/talk-to-figma-mcp 使用的 STDIO transport 相容，透過 `~/.gemini/settings.json` 的 `mcpServers` 區塊設定（`command`、`args`、`env` 欄位） |
| 設定方式與 Claude Code 差異？ | **最小差異**。Claude Code 使用 `~/.claude/settings.json`（或 MCP config），Gemini CLI 使用 `~/.gemini/settings.json`。MCP Server 本體（KCTW fork）共用，僅宿主平台設定檔不同 |
| KCTW/talk-to-figma-mcp 相容性？ | **可用**。KCTW fork 使用標準 MCP STDIO transport，Gemini CLI 可透過相同設定結構連接 ws://localhost:3000（Figma Plugin WebSocket Server） |
| 環境安全性差異？ | Gemini CLI 有環境變數安全隔離（`*KEY*`、`*TOKEN*` 等自動 redact），ECDSA 金鑰等敏感環境變數需在 `env` 區塊明確聲明 |

### 決策

**designer 角色加入 Provider 路由表，支援雙軌派遣（claude / gemini）。**

預設等效值更新為：

```
SHIKIGAMI_ROLE_PROVIDER_MAP="developer:claude,qa:claude,po:claude,architect:claude,designer:claude"
```

- designer 預設使用宿主平台偵測結果（與其他角色一致）
- 使用者可透過 `SHIKIGAMI_ROLE_PROVIDER_MAP="designer:gemini"` 切換至 Gemini CLI 派遣
- Gemini CLI 環境須額外確認 `~/.gemini/settings.json` 已設定 `mcpServers.talk-to-figma-mcp` 連接（Figma MCP 環境健康檢查見 OQ-4 Runbook）

### 落地文件

| 文件 | 更新內容 |
|------|---------|
| `skills/sprint-execution/SKILL.md` §2.1 | 預設 Provider 路由表新增 `designer:claude`，補充 designer 角色 Gemini CLI 支援說明 |
| `docs/adr/ADR-016-uiux-designer-role.md` | OQ-3 狀態更新為 Closed |

---

## Decision Challenger 審查記錄

### QA Decision Challenger（2026-03-11）

**挑戰目標**：決策域 3 — Vision Critic PASS 作為 Contract 凍結唯一條件

**結論**：RECOMMEND RECONSIDER

**核心論點**：Vision Critic 三維度評分全部聚焦設計系統合規性，與 Contract 可測試性完整度正交。97 分的 Prototype 可能缺少 Error State、表單驗證行為、邊界狀態覆蓋。QA 在 Contract 凍結前介入可在低成本階段識別規格缺口。

**Architect 回應**：接受挑戰。決策域 3 已修正為「Vision Critic PASS + QA Contract Testability Review 雙重審查」。Contract 凍結充分條件從單一條件升級為雙重條件，消除單點失效風險。

### SRE Review（2026-03-11）

**結論**：APPROVE WITH CONDITIONS

**條件**：
1. （高）OQ-2 — DESIGN Story Sprint 內排序需明確定義
2. （高）OQ-4 — Figma MCP 環境健康檢查 Runbook
3. （中）OQ-1 — Design Foundation Skill 歸屬
4. （低）OQ-5 — VRR 報告保留策略

**Architect 回應**：全部接受，已整合至開放問題。OQ-2 和 OQ-4 為高優先，須在實作 Story 進 Sprint 前解決。

---

## OQ 決策記錄

### OQ-1 決策：Design Foundation Skill 歸屬（US-211，2026-03-11）

**決策**：**整合進 `skills/uiux-designer/SKILL.md`**，不建立獨立的 `design-foundation` Skill。

**理由**：

1. **高耦合性**：Design Foundation 流程的執行者即 UI/UX Designer 本人（Designer 建立 Design System、Design Tokens、Component Library）。流程與角色的職責邊界完全重合，分離將導致 Skill 間的強依賴而非真正的關注點分離。

2. **避免過度拆分（YAGNI）**：獨立 Skill 的必要條件是「同一流程被多個角色複用」。Design Foundation 當前僅由 UI/UX Designer 執行，不存在其他角色複用此流程的需求。分離只增加維護成本，不帶來架構收益。

3. **SRE 建議採納**：ADR-016 SRE Review 明確建議整合（「整合以降低 Toil」），與 YAGNI 原則及 Shikigami 框架的 Token 成本控制方向一致。

4. **現行實作已完整**：`skills/uiux-designer/SKILL.md` §3「Design Foundation 流程（Pre-Sprint 三方協作）」已完整定義：
   - §3.1 三方職責分工（PO / Architect / Designer）
   - §3.2 依賴鏈（五層依賴序列）
   - §3.3 Design Foundation 產出物（Design System / Tokens / Component Library）
   - §3.4 觸發時機（三個觸發條件）
   - §3.5 與 sprint-planning §9 的對齊

   AC2 條件（整合路徑下 §3 觸發機制完整定義）已於 US-206 交付時滿足，無需額外修改。

**未來演進觸發條件**：若未來出現以下情況，可透過新 ADR 重新評估是否拆分為獨立 Skill：
- 非 Designer 角色需要直接執行 Design Foundation 流程
- Design Foundation 流程複雜度大幅增長，導致 `skills/uiux-designer/SKILL.md` 超過 600 行且閱讀困難

---

## 參考

- GitHub Issue #207：UI/UX Designer 角色缺口（原始需求與討論記錄）
- ADR-014：UIUX Agent 架構決策（三層管線、Vision Critic 評分框架）
- ADR-015：Figma 整合取代 SSD JSON（OQ-1~OQ-4 技術調查）
- ADR-007：Story Lifecycle Subagent 架構決策（Story 執行封裝模式）
- KCTW/talk-to-figma-mcp：Fork of grab/cursor-talk-to-figma-mcp（已驗證 Figma MCP Server）
- `skills/vision-critic/SKILL.md`：Vision Critic 三維度評分機制
- `docs/design/design-tokens.json`：Design Tokens v1.0.0（13 個具名 Figma Variables）
