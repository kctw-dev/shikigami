# Sprint 26

**狀態**：進行中
**期間**：2026-03-03 ~ 2026-03-09
**Sprint Goal**：啟動 OpenCode MVP Phase 1，完成目錄適配與 SKILL.md 載入驗證，為 M5 條件 (a) 的外部使用者觸及奠定平台基礎
**總計**：1 Story / 2 Points

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| US-46 | OpenCode 目錄適配與 SKILL.md 載入驗證（Phase 1） | M | 2 | 待開始 |

**Sprint 容量**：2 Points

---

## Story 詳細 AC

---

### US-46：OpenCode 目錄適配與 SKILL.md 載入驗證（Phase 1）

**來源**：US-45 OPENCODE_POC.md Go 決策 / M5 外部使用者觸及前提
**Size**：M / 2 Points
**Owner**：Developer

**User Story**
As a Product Owner targeting OpenCode platform expansion, I want the Shikigami directory structure adapted to OpenCode's conventions and SKILL.md loading verified against OpenCode's Skills spec, so that Phase 1 MVP provides a validated platform foundation before committing to full integration effort.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | OpenCode 目錄結構適配審查 | 審查現有 `skills/` 目錄結構，對照 OpenCode v1.0.190+ 目錄慣例，輸出差異清單；若無差異，明確標記「結構相容，無需修改」 |
| AC2 | [靜態] | CLAUDE.md 相容性說明補充 | 確認 `CLAUDE.md`（或相應根目錄設定檔）已包含 OpenCode 平台載入路徑說明；若缺漏則補充相關段落，標明 OpenCode Skills 載入入口 |
| AC3 | [靜態] | sprint-planning SKILL.md 殘留項識別 | 逐節審查 `skills/sprint-planning/SKILL.md`，識別不符合 OpenCode v1.0.190+ Skills 規範的殘留項（格式、關鍵字、結構），輸出殘留項清單（若為空則明確標記「無殘留項」） |
| AC4 | [靜態] | Sprint Planning SKILL.md 靜態相容性驗證 | 確認 `skills/sprint-planning/SKILL.md` 的目錄結構與格式符合 OpenCode v1.0.190+ Skills 規範；AC3 識別的殘留項均已標注 TODO 或提出修正方案。[動態驗證標注] 完整 Happy Path 驗證待實機 POC Sprint 執行，此 Story 不計入 DoD。 |
| AC5 | [靜態] | Phase 1 結論文件更新 | 於 `docs/km/OPENCODE_POC.md` 新增「Phase 1 完成記錄」區塊，記錄：(a) 目錄適配結果摘要；(b) SKILL.md 相容性評估結果；(c) AC4 動態驗證標注說明；(d) 建議下一步（ADR-008 草稿或 Phase 2 範圍） |

---

## 平行分群（Architect 建議）

### 單 Story，無需分群

| Story | 建議執行順序 | 說明 |
|-------|------------|------|
| US-46 | AC1 → AC2 → AC3 → AC4 → AC5 | 單一 Story，AC 之間具有邏輯前後依賴，依序執行 |

**執行順序說明**：
- AC1 先完成目錄結構審查，提供 AC3/AC4 的審查基準
- AC2 補充 CLAUDE.md 說明，與 AC1 平行可執行但建議 AC1 先完成以確認範圍
- AC3 依賴 AC1 的差異清單進行殘留項識別
- AC4 依賴 AC3 的識別結果進行靜態驗證確認
- AC5 彙整 AC1-AC4 所有產出，更新 OPENCODE_POC.md

---

## 工作容量

| 項目 | 數值 |
|------|------|
| Sprint 期間 | 2026-03-03 ~ 2026-03-09（7 天） |
| 總 Stories | 1 |
| 總 Points | 2 |
| 平行分群 | 單 Story，依 AC 順序執行 |

---

## ADR 觸發清單

| Story | ADR 編號 | 說明 |
|-------|----------|------|
| US-46 | 無新 ADR（本 Sprint） | Phase 1 靜態驗證，無架構決策變更；Architect 建議 Phase 1 完成後補建 ADR-008（OpenCode 平台整合策略） |

**本 Sprint 無新 ADR。Phase 1 完成後建議補建 ADR-008。**

---

## Sprint Planning 簽核

- **PO Round 1**：完成（Story 選取：US-46；Sprint Goal 確定；總計 2pt；M size）
- **Architect Round 1**：完成（US-46 M/2pt 確認；ADR Hard Gate PASS，不需新建 ADR；單 Story 無需分群；建議 AC 執行順序 AC1→AC2→AC3→AC4→AC5；建議 Phase 1 完成後補建 ADR-008）
- **QA Round 1**：完成（AC1 PASS；AC2 PASS 附條件補充 CLAUDE.md 說明；AC3 PASS；AC4 NEEDS_REVISION 降級為靜態相容性驗證；AC5 PASS；doc-only 不適用）
- **PO Round 2**：完成（Architect sizing 確認與 QA AC4 修訂版整合完成；AC4 降級為靜態相容性驗證並附動態驗證標注；Sprint Backlog 最終確認）
