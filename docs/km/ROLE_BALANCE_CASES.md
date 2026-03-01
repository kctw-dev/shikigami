# 真實制衡案例記錄

本文件記錄 Shikigami AI Agent Scrum Team 在實際開發過程中發生的角色制衡案例，供框架使用者理解制衡機制的實際運作方式。

每個案例來自 Sprint Retrospective Log，具有可追溯的真實脈絡。

---

## 案例格式

每個案例包含以下 6 個欄位：

| 欄位 | 說明 |
|------|------|
| **Sprint 來源** | 案例發生的 Sprint 編號 |
| **情境描述** | 事件的背景與觸發點 |
| **制衡角色** | 執行制衡的角色 → 被制衡的角色/機制 |
| **制衡類型** | 列舉值（見下方說明） |
| **決策結果** | 制衡後的最終決策 |
| **後續影響** | 制衡對後續 Sprint 或框架的影響 |

### 制衡類型列舉值

- `QA-推翻設計`：QA Engineer 在審查階段發現問題，推翻或要求修改設計/實作
- `PO-退回`：Product Owner 退回 Story 或需求，要求重新規劃
- `Architect-上調估點`：Architect 對 Story 估點進行修正（上調或下調）
- `Security-阻擋`：Security Engineer 因安全疑慮阻擋功能實作或部署
- `Hard-Gate-攔截`：框架 Hard Gate 機制攔截流程，強制補完前置條件

---

## 案例 1：Hard Gate 攔截 ADR 前置條件

| 欄位 | 內容 |
|------|------|
| **Sprint 來源** | Sprint 1 |
| **情境描述** | Story 2（Backlog Bridge 完整版）需要決定 Issue → User Story 的轉換編排模式（PO 直接處理 vs 委派 backlog-management）。Architect 評估認為這是技術選型，觸發 ADR Hard Gate。 |
| **制衡角色** | Architect → Hard Gate 機制 |
| **制衡類型** | `Hard-Gate-攔截` |
| **決策結果** | Story 2 被 Hard Gate 阻擋，先完成 ADR-001（Backlog Bridge 編排模式決策），採用委派模式後，Story 2 才解鎖進入實作。 |
| **後續影響** | ADR-001 成為框架的基礎架構決策之一，委派模式在後續 Sprint 的 Backlog Bridge 流程中持續運作。 |

---

## 案例 2：QA 前置攔截 14 個 AC 缺口

| 欄位 | 內容 |
|------|------|
| **Sprint 來源** | Sprint 2 |
| **情境描述** | PO 完成 US-07（Health Check）和 US-S01（Standup 遠端差距感知）的 AC 撰寫後，QA 在 Sprint Planning 階段進行 AC 審查。 |
| **制衡角色** | QA Engineer → PO |
| **制衡類型** | `QA-推翻設計` |
| **決策結果** | QA 發現 14 個 AC 缺口（US-07 有 5 項需修正），全部在進 Sprint 前由 PO 修補，避免了實作階段的返工。 |
| **後續影響** | QA 前置攔截成為 Sprint Planning 的常態，Sprint 3 繼續發現 13 個缺口。這個機制最終催生了 Sprint 3 Retro Action「AC 分類標注 [靜態]/[動態]」，讓 AC 品質系統性提升。 |

---

## 案例 3：Architect 重估 US-08 Size

| 欄位 | 內容 |
|------|------|
| **Sprint 來源** | Sprint 4 |
| **情境描述** | PO 規劃 US-08（Sprint Metrics）時估為 M（2 points），Architect 實際評估技術內容後認為只需在 sprint-review SKILL.md 加入計算指引，複雜度低於預期。 |
| **制衡角色** | Architect → PO |
| **制衡類型** | `Architect-上調估點` |
| **決策結果** | Architect 將 US-08 從 M 重新估為 S（1 point），釋放出的容量讓 Sprint 4 能額外納入 US-T06（Command 路由驗證）。 |
| **後續影響** | Sprint 4 以 4 points（原規劃更高）完成 3 個 Story，完成率 100%。Architect 估點校正成為持續的品質機制。 |

---

## 案例 4：QA 發現 Bootstrap 自我引用風險

| 欄位 | 內容 |
|------|------|
| **Sprint 來源** | Sprint 6 |
| **情境描述** | US-FIX-02（Hard Gate Checklist 機制）的 Code Quality Review 中，QA 發現 Developer 正在修改的檔案（scrum-master SKILL.md）恰好是定義 Hard Gate 規則的檔案本身——形成了「規則制定者修改自身規則」的自我引用風險。 |
| **制衡角色** | QA Engineer → Developer |
| **制衡類型** | `QA-推翻設計` |
| **決策結果** | QA 將此標記為 Code Quality 問題。Developer 分析後在 Hard Gate 條文中新增「Bootstrap 豁免條款」，明確標注此次修改的自我引用性質並記錄為合理豁免。 |
| **後續影響** | Bootstrap 豁免條款成為框架文件規範的一部分（ADR-003 §9.1），為後續類似的自我引用場景提供了處理先例。 |

---

## 案例 5：Hard Gate 事後攔截 QA 雙階段審查跳過

| 欄位 | 內容 |
|------|------|
| **Sprint 來源** | Sprint 7 |
| **情境描述** | Sprint 7 的 5 個 Stories 全部由主 Agent 直接實作，未派遣獨立 QA subagent 做 Spec Compliance 和 Code Quality Review，違反了 sprint-execution SKILL.md 第 4 節 Hard Gate「每個 Story 必須通過雙階段審查」的規定。 |
| **制衡角色** | Hard Gate 機制（事後 Retro 攔截） |
| **制衡類型** | `Hard-Gate-攔截` |
| **決策結果** | Sprint 7 Retrospective 將此列為 Problem，建立 Retro Action #14（Issue #14），要求 Sprint 8 立即恢復 QA 雙階段審查。 |
| **後續影響** | Sprint 8 第一個 Story 即為 Retro #14（恢復 QA 雙階段審查），在 sprint-execution SKILL.md 加強 Hard Gate 語言，確保後續 Sprint 不再跳過。 |

---

## 統計摘要

| 制衡類型 | 出現次數 | 案例編號 |
|----------|----------|----------|
| `Hard-Gate-攔截` | 2 | 案例 1、案例 5 |
| `QA-推翻設計` | 2 | 案例 2、案例 4 |
| `Architect-上調估點` | 1 | 案例 3 |

覆蓋制衡類型：3 種（共 5 種可能類型）

---

## 維護說明

每次 Sprint Review 結束後，若本 Sprint 有值得記錄的角色制衡案例，請依上述格式新增至本文件。詳見 `skills/sprint-review/SKILL.md` 第 6 節執行檢查清單。
