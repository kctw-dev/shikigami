# Sprint Lifecycle 模組 SBE Index

**模組**：sprint-lifecycle
**版本**：v1.0
**日期**：2026-03-12
**狀態**：Active
**關聯 Story**：US-227
**上層索引**：`../meta-index.md`

---

## 用途

此模組 Index 是 Agent 載入 SBE 知識的**第二層入口**，列出 `sprint-lifecycle` 模組下所有可用的 SBE 範例，提供每個範例的簡要描述，協助 Agent 快速定位目標 `.sbe.md` 文件，再按需載入完整內容。

---

## 格式定義

每個範例條目的格式如下：

```
| 範例檔案名稱（.sbe.md） | 業務情境描述（簡要說明涵蓋的 Scenarios） | 適用 GATE 或決策點 | 狀態 |
```

**填寫原則**：
- **範例檔案名稱**：完整檔案名稱，含 `.sbe.md` 副檔名，提供相對路徑連結
- **業務情境描述**：說明該 SBE 文件涵蓋的核心業務情境，一句話為主（不超過 40 字）
- **適用 GATE 或決策點**：指出業務規則中的關鍵判斷點，協助 Agent 快速辨識是否與當前任務相關
- **狀態**：`Active`（現行規則）、`Deprecated`（已廢棄，移至 archive/）

---

## 範例清單

| 範例 | 業務情境描述 | 適用 GATE 或決策點 | 狀態 |
|------|------------|------------------|------|
| [sprint_planning_scheduled_mode.sbe.md](sprint_planning_scheduled_mode.sbe.md) | 排程模式 HARD-GATE：非 S-size Story 的阻擋條件，含混合 Size 候選與手動模式豁免情境 | `SHIKIGAMI_SCHEDULED=true` 時的 Story 選取 GATE | Active |
| [sprint_planning_refinement_gate.sbe.md](sprint_planning_refinement_gate.sbe.md) | Refinement 前置門禁：M/L size Story 進入 PO Round 1 前必須通過 Refinement，含 S-size 豁免與例外情境 | PO Round 1 前的 Refinement 完成度 GATE | Active |

---

## 快速匹配指南

Agent 在查閱本 Index 時，依照以下情境快速定位目標 SBE 文件：

| 業務情境關鍵詞 | 目標 SBE 文件 |
|-------------|-------------|
| 排程模式、SHIKIGAMI_SCHEDULED、HARD-GATE、S-size only | `sprint_planning_scheduled_mode.sbe.md` |
| Refinement、READY、NOT_READY、PO Round 1 前置門禁、M-size 必須 Refinement | `sprint_planning_refinement_gate.sbe.md` |
| S-size 豁免、跨 3 Type、前置依賴、外部系統依賴 | `sprint_planning_refinement_gate.sbe.md` |

---

## 維護規範

### 新增 SBE 範例時

1. 在 `sprint-lifecycle/` 目錄下新增 `.sbe.md` 文件（依照 `SBE_FORMAT.md` 格式）
2. 在本 Index 的「範例清單」表格新增一行
3. 若有新的業務情境關鍵詞，在「快速匹配指南」中補充對應關係
4. 更新版本號與日期

### 廢棄 SBE 範例時

1. 將 `.sbe.md` 文件移至 `sprint-lifecycle/archive/` 子目錄
2. 在「範例清單」表格將該行狀態改為 `Deprecated`，並加入廢棄日期說明
3. 不刪除條目（保留歷史可追蹤性）

---

## 參考文件

- `../meta-index.md`：SBE 範例庫 Meta-Index（上層索引，含三層載入流程定義）
- `../SBE_FORMAT.md`：SBE 標準格式定義（Given/When/Then 格式規範）
- `../SBE_TO_TEST_RULES.md`：SBE → 測試案例轉換規則
- `skills/sprint-planning/SKILL.md`：Sprint Planning 業務規則來源
