# Hard Gates + TDD + doc-only 規則（§5）

## Hard Gates

<HARD-GATE>
每個 Story 必須通過雙階段審查（Spec Compliance + Code Quality）才能標記為完成。
不得跳過任何一個審查階段。

> 歷史案例：Sprint 7 因跳過此步驟列為 Retro Problem（Issue #14），導致品質門禁失效。
</HARD-GATE>

> **Bypass 豁免：** 標記為 `[BYPASS]` 的 Story 豁免雙階段審查（Spec Compliance + Code Quality）。豁免條件與 `skills/scrum-master/SKILL.md` §10.3 Bypass 保護清單對齊——涉及 Framework Document Change、外部 API、安全相關的 Story 不得適用豁免，即使標注 `[QUICK]` 亦然。

<HARD-GATE>
所有功能實作必須遵循 TDD：先寫失敗測試 → 最小實作讓測試通過 → 重構。
例外：標注為 [SPIKE] 的探索性任務可豁免，但進入正式開發時必須補測試。
</HARD-GATE>

## Story Type 對 TDD 豁免與 Review 策略的影響（AC3）

<!-- US-201 Story Type 分類系統定義 — Sprint 76 -->

Story Type（定義於 `skills/sprint-planning/SKILL.md` §8）影響 Sprint Execution 中的 TDD 豁免判定與 Review 策略。完整 Type 定義與分類規則請參閱 sprint-planning/SKILL.md §8。

### Type 對 TDD 策略的影響

| Story Type | TDD 要求 | 說明 |
|-----------|---------|------|
| **FEATURE** | 必須（HARD-GATE） | 功能實作須先寫測試再寫代碼 |
| **DESIGN** | 豁免 | 視覺設計與規格文件無可執行測試 |
| **INFRA** | 條件性 | 含腳本/程式碼的 INFRA Story 須 TDD；純設定檔修改豁免 |
| **SECURITY** | 必須（強制） | 安全修復必須有對應安全測試，不得豁免 |
| **INTEGRATION** | 必須（HARD-GATE） | 跨系統整合必須有整合測試（含 mock 或 contract test） |
| **RESEARCH** | 豁免 | 探索性調查無需測試；輸出為 Spike Report，非可執行代碼 |

### Type 對 Review 策略的影響

| Story Type | Spec Compliance Review | Code Quality Review | Security Review |
|-----------|----------------------|-------------------|----------------|
| **FEATURE** | 必須通過 | 必須通過 | 條件觸發（含外部輸入時） |
| **DESIGN** | 必須通過 | 不適用（無代碼） | 不適用 |
| **INFRA** | 必須通過 | 必須通過 | 條件觸發（含網路/權限設定時） |
| **SECURITY** | 必須通過 | 必須通過 | **強制執行**（所有 SECURITY Story 均觸發） |
| **INTEGRATION** | 必須通過 | 必須通過 | 條件觸發（含認證/授權時） |
| **RESEARCH** | 必須通過（Spike Report 完整性） | 不適用 | 不適用 |

### Story Type 與 doc-only 規則的優先順序（AC5）

Story Type 系統與 doc-only 判定規則（見下方「doc-only Story 識別規則」）為**正交維度**，各自獨立判定，無衝突：

1. **doc-only 優先判定 TDD 豁免**：doc-only Story（滿足下方識別規則）無論 Story Type 為何，均豁免 TDD 開發流程。例如 FEATURE Type 的 doc-only Story 豁免 TDD，但 Spec Compliance + Code Quality Review 維持必要。
2. **Story Type 決定 Contract Owner 與 Review 深度**：即使是 doc-only Story，仍須標注 Story Type 以確定 Contract Owner 和適用的 Review 深度。
3. **RESEARCH Type 的特殊交互**：RESEARCH Type 本身即豁免 TDD，若同時標注 doc-only 則兩者判定結果一致（均豁免 TDD）。
4. **判定優先順序**：`doc-only=true` → TDD 豁免（優先規則）；Story Type → Review 策略（獨立規則）。兩者無矛盾，可同時套用。

> **實踐指引**：QA subagent 在 Sprint Planning 時確認 doc-only 狀態；Story-Lifecycle subagent 在執行時依 Story Type 選擇 Review 策略。兩個判定步驟相互獨立，不互相覆蓋。

---

## doc-only Story 識別規則

**正向識別條件（滿足以下任一條件即判定為 doc-only）：**

- 條件 A：Story 對應的 CLAUDE.md 含有 `doc-only: true` 欄位
- 條件 B：Story 的所有 AC 條目均為 `[靜態]` 類型，**且**所有目標檔案路徑均在 `docs/` 目錄下

**執行分支（識別為 doc-only 時）：**

| 步驟 | 一般路徑 | doc-only 路徑 |
|------|---------|--------------|
| Developer 實作 | TDD（Red → Green → Refactor） | **跳過**（TDD 豁免） |
| 執行 bash 指令 | 可執行 bash 命令 | **跳過**（不執行任何 shell 命令） |
| 修改 src/ 目錄 | 依需求修改 | **禁止**（僅允許修改 docs/ 下檔案） |
| 修改 skills/ 目錄 | 依需求修改 | **禁止**（僅允許修改 docs/ 下檔案） |
| Spec Compliance Review | 必須通過（HARD-GATE） | **維持**（必須通過，不豁免） |
| Code Quality Review | 必須通過（HARD-GATE） | **維持**（必須通過，不豁免） |

> **重要**：doc-only 豁免僅豁免 TDD 開發流程。雙階段 QA Review（Spec Compliance + Code Quality）維持必要，**不得跳過**。

**負面案例排除清單（以下情況不適用 doc-only 路徑）：**

1. **[動態] AC 排除**：Story 的 AC 含有 `[動態]` 類型且需執行 shell 命令，即使其他 AC 均為 [靜態]，整體 Story 仍走一般路徑
2. **skills/ / commands/ / agents/ 路徑排除**：目標路徑含 `skills/`、`commands/`、`agents/` 目錄時，即使副檔名為 `.md`，**仍需執行 ADR-003 Checklist**，且不適用 doc-only 路徑（如本 Issue #34 本身即屬此類）
3. **CLAUDE.md 不存在降級**：若 CLAUDE.md 不存在，條件 A 無法觸發，TDD 豁免不生效；此時須退回條件 B 判斷，若條件 B 亦不滿足，則走一般路徑

**判定機制：** QA subagent 在 Sprint Planning 時確認，確認標準為「Story 所有 AC 引用路徑均為 `.md` 副檔名，且路徑均在 `docs/` 目錄下」。判定結果記錄於 `docs/sprints/sprint_N.md` 對應 Story 的備注欄或 QA 狀態欄。
