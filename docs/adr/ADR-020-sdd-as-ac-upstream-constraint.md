# ADR-020：SDD 作為 AC 的強制上游約束 — 建立 SDD → AC → TDD 追溯鏈

**狀態**：Accepted
**日期**：2026-03-15
**決策者**：Architect（審查）+ PO（需求端確認）+ QA Decision Challenger
**關聯 ADR**：ADR-003（Shoot 模式）
**觸發來源**：Stakeholder 回饋 — SDD 與 AC 之間缺乏形式化綁定，SDD 淪為說明文件

---

## 背景

### 問題陳述

目前 Shikigami 框架的設計與實作鏈存在結構性斷裂：

```
SDD（系統設計文件）──── 參考（非強制）────→ Architect 腦中
                                              ↓（隱性影響）
PO 需求理解 ──→ AC（驗收條件）──→ TDD 測試 ──→ Spec Compliance Review
```

**SDD 定義了系統的架構規格（介面、模組邊界、資料流、領域模型），但 AC 沒有強制回溯到 SDD**。這導致：

1. **設計與驗收斷鏈**：SDD 中定義的介面規格、資料結構、模組邊界等約束，不會自動成為 AC 的一部分。Developer 的 TDD 測試只基於 AC，不驗證是否符合 SDD 設計。

2. **SDD 淪為事後說明文件**：既然 AC 和 TDD 都不回溯 SDD，SDD 實質上只是「描述系統現狀的文件」，而非「約束實作方向的設計合約」。寫了等於沒寫。

3. **Spec Compliance Review 只驗半邊**：目前 Spec Reviewer 只驗 AC 符合度，不驗 SDD 一致性。即使實作違反 SDD 定義的架構規格，只要滿足 AC 就會 PASS。

4. **SDD 變更無連鎖效應**：Architecture Decision（ADR）可能觸發 SDD 更新，但 SDD 更新後不會自動觸發受影響 Story 的 AC 重新校準。

### 現行流程中 SDD 的角色

| 流程節點 | SDD 參與方式 | 約束力 |
|---------|-------------|--------|
| Backlog Management | PO 撰寫 AC，不強制參考 SDD | 無 |
| Sprint Planning — Architect 評估 | Architect 可能參考 SDD，但無強制檢查 | 隱性 |
| Sprint Planning — QA 審查 | QA 只驗 AC 可測試性，不驗 SDD 一致性 | 無 |
| Story Lifecycle — 開始前準備 | `related_sdds` 為**可選**欄位，subagent 讀取作為參考 | 弱（可選） |
| TDD 開發 | 測試基於 AC，不基於 SDD | 無 |
| Spec Compliance Review | 只逐條驗 AC，不驗 SDD 一致性 | 無 |

---

## 決策問題

是否應將 SDD 從「可選參考文件」升級為「AC 的強制上游約束」，使 SDD 定義的架構規格成為 AC 撰寫、TDD 測試與 Spec Compliance Review 的強制依據？

---

## 考慮的選項

### 選項 A：SDD → AC 強制追溯（建議）

在三個流程節點建立強制綁定：

**1. Sprint Planning：AC 必須引用相關 SDD 章節**

- Architect 在技術評估時，必須為每個 Story 標注 `related_sdds`（從可選升級為條件必填）
- 若 Story 涉及 SDD 定義範圍內的模組/介面/資料結構，AC 必須包含「SDD 一致性」驗收條件
- QA 在 Sprint Planning 審查時，新增檢查項：「涉及 SDD 定義範圍的 Story，AC 是否引用了對應 SDD 章節」

**2. Spec Compliance Review：增加 SDD 一致性驗證**

- Spec Reviewer 在逐條驗 AC 之外，額外驗證實作是否符合 `related_sdds` 中定義的架構約束
- 驗證範圍：介面簽名、模組邊界（import 方向）、資料結構定義、狀態轉換規則
- SDD 一致性驗證為 FAIL 時，等同 Spec Compliance FAIL

**3. SDD 變更觸發 AC 重新校準**

- 當 ADR 觸發 SDD 更新時，Architect 必須列出受影響的 in-sprint Story
- 受影響 Story 的 AC 須經 PO + Architect 重新校準
- 校準結果記錄在 Sprint 文件中

### 選項 B：維持現狀，靠 Architect 隱性把關

維持 `related_sdds` 為可選欄位，信任 Architect 在 Sprint Planning 時會自行參考 SDD。

**風險**：SDD 持續淪為說明文件，設計與實作的一致性完全依賴個人記憶。

### 選項 C：SDD 合併進 AC，取消獨立 SDD

直接將 SDD 中的約束條件拆解為 AC 的一部分，不再維護獨立 SDD。

**風險**：失去全局架構視角。AC 是 Story 粒度，無法承載跨 Story 的架構一致性約束。

---

## 決策

**選擇選項 A：SDD → AC 強制追溯。**

理由：
- SDD 存在的目的就是約束實作方向，如果不綁定到驗收鏈上就失去意義
- 選項 B 依賴隱性知識，隨團隊規模擴大會失效
- 選項 C 會導致架構碎片化，跨 Story 的一致性無法保證

---

## 實作影響

### 需修改的檔案

| 檔案 | 修改內容 |
|------|---------|
| `skills/sprint-planning/architect-prompt.md` | Architect 技術評估新增「SDD 覆蓋範圍檢查」，`related_sdds` 升級為條件必填 |
| `skills/sprint-planning/qa-prompt.md` | QA Sprint Readiness 新增「SDD 引用檢查」項目 |
| `skills/sprint-execution/story-lifecycle-prompt.md` | `related_sdds` 從可選升級為條件必填；開始前準備新增 SDD 約束提取步驟 |
| `skills/sprint-execution/spec-reviewer-prompt.md` | 新增「SDD 一致性驗證」審查區塊 |
| `skills/sprint-execution/developer-prompt.md` | TDD Red 階段新增 SDD 約束參考指引 |
| `skills/architecture-decision/SKILL.md` | ADR 觸發 SDD 更新時，新增「受影響 Story AC 校準」步驟 |

### `related_sdds` 升級規則

| 情境 | `related_sdds` 要求 |
|------|-------------------|
| Story 涉及 SDD 定義範圍內的模組/介面/資料結構 | **必填**，Architect 在技術評估時標注 |
| Story 為純文件修改（doc-only）且不涉及架構 | 可省略 |
| Story 為 RESEARCH type | 可省略（探索性質，尚無確定設計） |
| SDD-000 不存在（專案初期） | 全部可省略，降級為現行行為 |

### Spec Compliance Review 擴充

現行：
```
Spec Compliance：
  [PASS/FAIL] AC 逐條驗證
  [PASS/FAIL] 邊界條件檢查
  [PASS/FAIL] 行為範例驗證（若適用）
```

擴充後：
```
Spec Compliance：
  [PASS/FAIL] AC 逐條驗證
  [PASS/FAIL] 邊界條件檢查
  [PASS/FAIL] 行為範例驗證（若適用）
  [PASS/FAIL] SDD 一致性驗證（若 related_sdds 存在）
```

SDD 一致性驗證項目：
- [ ] 實作的介面簽名符合 SDD 定義
- [ ] import 方向符合 SDD 定義的模組邊界
- [ ] 資料結構符合 SDD 定義的 Entity / Value Object 規格
- [ ] 狀態轉換符合 SDD 定義的狀態機

### SDD 變更連鎖校準流程

```
ADR 決策
  ↓ 觸發
SDD 更新
  ↓ Architect 列出
受影響的 in-sprint Story 清單
  ↓ PO + Architect
AC 重新校準（記錄於 Sprint 文件）
  ↓
受影響 Story 重新進入 TDD 循環（若已開始實作）
```

---

## 後果

### 正面

- **SDD 成為真正的設計合約**：有約束力，不是說明文件
- **設計 → 實作一致性可驗證**：Spec Compliance Review 同時驗 AC 和 SDD
- **TDD 測試有設計依據**：Developer 知道測試不只要滿足 AC，還要符合架構設計
- **SDD 變更有連鎖效應**：架構決策的影響能自動傳播到實作層

### 負面

- **Sprint Planning 增加步驟**：Architect 需要額外做 SDD 覆蓋範圍檢查
- **Spec Compliance Review 增加審查項**：SDD 一致性驗證增加審查時間
- **SDD 維護壓力增加**：SDD 現在有下游依賴者，品質要求更高，過時的 SDD 會阻塞流程

### 風險緩解

| 風險 | 緩解措施 |
|------|---------|
| SDD 過時導致 AC 校準錯誤 | ADR 觸發 SDD 更新機制已存在（architecture-decision SKILL §6），本 ADR 強化下游傳播 |
| Sprint Planning 效率下降 | SDD 覆蓋範圍檢查由 Architect subagent 自動執行，非手動操作 |
| 專案初期無 SDD 時流程卡住 | 降級規則：SDD-000 不存在時全部可省略，回退現行行為 |
