# Sprint 37

**狀態**：進行中
**期間**：2026-05-04 ~ 2026-05-10
**Sprint Goal**：完成 backlog-intake 單層 Issue 架構改造（#73/#72 合併交付）與 shoot US-XX ADR-010 適配，讓 Backlog 管理全工具鏈達到單層一致性與 PO 審查閉環。
**總計**：3 Stories / 4 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | Phase | 狀態 |
|----------|---------|------|------|--------|-------|------|
| US-77 | #74 | 單層 Issue 架構改造 — backlog-intake / backlog-management 棄用兩層 Issue，改為 blockquote 保留原始內容 | M | 2 | Phase 1（可並行） | 進行中 |
| US-78 | #67 | shoot skill US-XX 模式需適配 ADR-010 — 從 GitHub Issues 查詢 Story | S | 1 | Phase 1（可並行） | 進行中 |
| US-80 | #75 | backlog-intake PO Review Gate — AI 自動入庫後新增 PO 審查階段與 label 語意修正 | S | 1 | Phase 2（US-77 之後） | 待開始 |

**Sprint 容量**：4 Points

---

## Story 詳細 AC

---

### US-77：單層 Issue 架構改造 — backlog-intake / backlog-management 棄用兩層 Issue，改為 blockquote 保留原始內容

**來源**：ADR-010 單層 Issue 架構改造 — Issue #74
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：Yes
**ADR 參考**：ADR-010（§兩層 Issue 設計 → 廢棄；§單層 Issue 架構）
**ADR-003 Checklist**：必須執行（修改 skills/ 目錄）

**User Story**

As a Product Owner managing the Backlog via GitHub Issues, I want backlog-intake and backlog-management to operate on a single-layer Issue architecture (no child Issue creation), preserving the original raw content as a blockquote within the same Issue body, so that the Backlog toolchain is consistent with a single source of truth per Issue.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | `skills/backlog-intake/SKILL.md` 中不存在建立子 Issue（child Issue）的指令 | SKILL.md 中找不到 `gh issue create` 用於建立 backlog-item child Issue 的指令 |
| AC2 | [靜態] | `skills/backlog-management/SKILL.md` 中不存在建立子 Issue 的指令 | SKILL.md 中找不到 `gh issue create` 用於建立 backlog-item child Issue 的指令 |
| AC3 | [靜態] | 原始來源內容以 blockquote 格式保留於 Issue body | SKILL.md 中有明確指引將原始內容包裹於 `>` blockquote 格式中 |
| AC4a | [動態] | label-only 冪等性驗證 — 移除 `backlog-intake-done` 後重執行 | 移除 `backlog-intake-done` label 後重新執行 backlog-intake，Issue 應被重新處理（非跳過） |
| AC4b | [靜態] | SKILL.md 中不存在 `type: backlog-item` body 掃描指令 | SKILL.md 中找不到任何掃描 Issue body 以判斷 `type: backlog-item` 的邏輯 |
| AC5 | [靜態] | `skills/backlog-management/SKILL.md` Grooming 流程不含子 Issue 操作 | SKILL.md 中的 Grooming 流程僅操作單一 Issue，無子 Issue 建立或連結邏輯 |
| AC6a | [靜態] | SKILL.md 中不存在 `type: backlog-item` label body 掃描指令 | SKILL.md 中找不到基於 `type: backlog-item` label 掃描 Issue body 的任何指令 |
| AC6b | [靜態] | SKILL.md 中不存在「來源：#N」欄位解析或寫入邏輯 | SKILL.md 中找不到解析或寫入「來源：#N」格式欄位的邏輯 |

---

### US-78：shoot skill US-XX 模式需適配 ADR-010 — 從 GitHub Issues 查詢 Story

**來源**：shoot skill ADR-010 適配 — Issue #67
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes
**ADR 參考**：ADR-010（§shoot skill 整合；§Backlog Source of Truth 遷移）
**ADR-003 Checklist**：必須執行（修改 skills/ 目錄）

**User Story**

As a Developer using the shoot skill with US-XX mode, I want the skill to query Story details from GitHub Issues (per ADR-010) instead of reading from PRODUCT_BACKLOG.md, so that US-XX mode remains accurate and operational after the Backlog Source of Truth migration.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | `skills/shoot/SKILL.md` US-XX 模式中使用 `gh issue list` 或 `gh issue view` 查詢 Story | SKILL.md 中可找到以 GitHub Issues 為來源的 Story 查詢指令 |
| AC2 | [靜態] | `gh issue list` 匹配條件明確（如 `--search "US-XX in:title"` 或特定 label），且警告輸出格式規範化 | SKILL.md 中明確指定匹配條件（title 搜尋或 label 過濾），若回退至歷史快照則輸出 `[WARN] 從歷史快照讀取：docs/prd/PRODUCT_BACKLOG.md` 格式警告 |
| AC3 | [靜態] | `skills/shoot/SKILL.md` 中不存在直接讀取 `PRODUCT_BACKLOG.md` 作為主要來源的指令 | SKILL.md 中 PRODUCT_BACKLOG.md 僅作為 fallback 來源，主要來源為 GitHub Issues |
| AC4 | [靜態] | US-XX 模式查詢流程包含 Issue not found 的錯誤處理 | SKILL.md 中有 Issue 查詢失敗時的錯誤處理或 fallback 說明 |

---

### US-80：backlog-intake PO Review Gate — AI 自動入庫後新增 PO 審查階段與 label 語意修正

**來源**：backlog-intake PO Review Gate — Issue #75
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes
**ADR 參考**：ADR-010（§Label 設計；§backlog-intake 工作流程）
**ADR-003 Checklist**：必須執行（修改 skills/ 目錄）
**依賴**：US-77 完成後方可開始（單層 Issue 架構為前提）

**User Story**

As a Product Owner, I want a PO Review Gate added to the backlog-intake workflow so that AI-auto-triaged Issues are marked with `auto-triaged` (pending human review) and I can explicitly approve them to `triaged`, ensuring no Issue bypasses human PO judgment before entering Sprint planning.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 原始 Issue 入庫完成後標記 `auto-triaged`（而非 `triaged`），明確基於 US-77 單層架構 | `skills/backlog-intake/SKILL.md` 中入庫完成步驟使用 `auto-triaged` label，且不使用 `triaged` label |
| AC2 | [靜態] | `skills/backlog-intake/SKILL.md` 中包含 PO Review Gate 區塊說明 | SKILL.md 中可找到明確的 PO Review Gate 流程描述，說明 `auto-triaged` 狀態的意義與人工審查觸發條件 |
| AC3 | [靜態] | PO 可執行 `gh issue edit <N> --add-label 'triaged' --remove-label 'auto-triaged'` 完成審查標記，且 SKILL.md 中有對應操作說明 | SKILL.md 中明確記載上述 `gh issue edit` 指令作為 PO 審查完成的標準操作 |
| AC4 | [靜態] | `skills/backlog-intake/SKILL.md` 的 label 語意說明表中，`auto-triaged` 與 `triaged` 各有獨立條目且語意描述不同 | SKILL.md label 語意表中 `auto-triaged` 與 `triaged` 分別有獨立行，且描述文字不同 |

---

## 平行分群（Architect 評估）

### Phase 1 — 可並行執行

| 群組 | Stories | 說明 |
|------|---------|------|
| Phase 1（並行） | US-77 | backlog-intake / backlog-management SKILL.md 改寫；無外部依賴 |
| Phase 1（並行） | US-78 | shoot SKILL.md 修改；獨立檔案，與 US-77 無衝突 |

### Phase 2 — 序列執行（US-77 之後）

| 群組 | Stories | 說明 |
|------|---------|------|
| Phase 2（序列） | US-80 | 依賴 US-77 單層架構完成；需 `auto-triaged` label 存在於 backlog-intake 工作流程後方可實作 PO Review Gate |

**執行順序說明**：
- Phase 1：US-77 與 US-78 可並行，節省 wall-clock 時間
- Phase 2：US-80 必須在 US-77 完成後啟動，確保單層架構前提成立
- 4pt 以 Phase 1 兩路並行 + Phase 2 序列，有效壓縮總執行量

---

## 工作容量

| 項目 | 數值 |
|------|------|
| Sprint 期間 | 2026-05-04 ~ 2026-05-10（7 天） |
| 總 Stories | 3 |
| 總 Points | 4 |
| 平行分群 | Phase 1（US-77 + US-78 並行）；Phase 2（US-80 序列） |
| 退回 Backlog | US-79（#61，GitHub Actions 整合）— 需先建立 ADR-011，排入 Sprint 38 |

---

## ADR 觸發清單

| Story | ADR 編號 | 說明 |
|-------|----------|------|
| US-77 | 無新 ADR | 單層 Issue 架構為 ADR-010 既定方向的實作修正；ADR-003 Checklist 適用（skills/ 修改） |
| US-78 | 無新 ADR | shoot skill ADR-010 適配為遷移後工具鏈對齊；ADR-003 Checklist 適用（skills/ 修改） |
| US-80 | 無新 ADR | PO Review Gate 為 backlog-intake 工作流程強化；設計規範在 ADR-010 label 設計中已涵蓋；ADR-003 Checklist 適用（skills/ 修改） |

**備註**：US-79（#61，GitHub Actions 整合）退回 Backlog；需建立 ADR-011 後排入 Sprint 38。

---

## Sprint Planning 簽核

- **PO Round 1**：完成（Story 選取：US-77 M/2pt + US-78 S/1pt + US-80 S/1pt；Sprint Goal 確定；總計 4pt / 3 Stories）
- **Architect Round 1**：完成（三個 Stories PASS；Phase 1 US-77+US-78 可並行；Phase 2 US-80 依賴 US-77；無檔案衝突；ADR-003 Checklist 適用於全部三個 Stories）
- **QA Round 1**：完成（所有 AC 可測試性 PASS；doc-only：US-77 Yes / US-78 Yes / US-80 Yes；US-77 共 8 條 AC（AC4 拆分為 AC4a/AC4b；AC6 拆分為 AC6a/AC6b）；US-78 共 4 條 AC（AC2 補充匹配條件與警告格式）；US-80 共 4 條 AC（AC1/AC3/AC4 精化））
- **PO Round 2**：完成（整合 Architect/QA 反饋；防漂移驗證通過；AC 最終確認；Sprint Backlog 最終確認；總計 4pt / 3 Stories）
