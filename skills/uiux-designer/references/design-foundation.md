# Design Foundation 流程（Pre-Sprint 三方協作）

> 摘錄自 `skills/uiux-designer/SKILL.md` §3

## 3.1 三方職責分工

| 參與者 | Design Foundation 職責 |
|--------|----------------------|
| **PO** | 產品願景、User Stories、商業需求優先級、使用者旅程定義 |
| **Architect** | 技術可行性審查、架構約束輸入（前端框架限制、效能預算）、元件邊界定義（與系統模組對齊）、Design Token 結構與 CSS 架構相容性確認 |
| **UI/UX Designer** | Design System 建立（Figma Variables、Auto Layout 規則）、Design Tokens 定義（遷移至 Figma Variables）、Component Library 產出（Figma Component + Instance）、Prototype 製作 |

## 3.2 依賴鏈

```
PO 產出 User Stories（必要前置）
  → Architect 提供技術約束（元件粒度、效能預算、框架限制）
    → UI/UX Designer 建立 Design Foundation
      → Design System + Tokens + Component Library 就緒
        → Sprint Planning 可選入 DESIGN Story
```

**關鍵約束**：PO 必須先產出 User Stories，Designer 才能建立對應的 Component Library。沒有商業需求驅動的設計是空中樓閣。

## 3.3 Design Foundation 產出物

| 產出物 | 格式 | 儲存位置 | 審查者 |
|--------|------|---------|--------|
| Design System | Figma Variables Collection | Figma 文件 | Architect |
| Design Tokens | Figma Variables + JSON 定義 | `docs/design/design-tokens.json` | Architect |
| Component Library | Figma Components（Button/Input/Card 等） | Figma 文件 + `docs/design/component-library-spec.md` | Architect |

## 3.4 觸發時機

| 觸發條件 | 說明 |
|---------|------|
| 新消費端專案啟動 | 首次建立 Design System，為專案定義設計語言 |
| 新 ROADMAP 里程碑啟動 | 里程碑涉及新頁面/新功能區域時，評估是否需要擴充 Component Library |
| Design Tokens 重大變更 | 品牌改版、主題系統引入等，需 Architect 確認技術相容性 |

## 3.5 與 sprint-planning §9 的對齊

Design Foundation 觸發於 Sprint Planning §9 Refinement 階段，當 Backlog 中出現 DESIGN type Story 時：

1. Sprint Planning 識別 DESIGN type Story 進入 Ready 狀態的前置條件
2. 確認 Design Foundation（Design System + Tokens + Component Library）是否就緒
3. 若未就緒，則 Design Foundation 本身需作為 Pre-Sprint 任務先行完成
4. 確認就緒後，DESIGN Story 方可列入 Sprint Backlog
