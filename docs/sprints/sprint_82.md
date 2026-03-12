# Sprint 82

**Sprint Goal**：奠定「組織記憶」基礎 — 建立 Decision Journal 與代理人校準機制，解決跨 Sprint 價值觀漂移問題，並統一跨角色交付標準查閱點。

**期間**：2026-03-12 ~ 2026-03-19
**狀態**：完成
**ADR 依賴**：無

---

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 | 備註 |
|-------|-------|------|--------|------|------|
| US-219：Decision Journal — 衝突決策思考過程與價值觀取捨記錄 | #219 | M | 2 | 完成 | doc-only, FEATURE |
| US-218：代理人校準機制 — 定期價值觀歸納審查與漂移偵測 | #218 | M | 2 | 完成 | doc-only, FEATURE, 搭配 US-219 |
| US-204：統一合約位置 — 跨角色共用的交付標準應有單一查閱點 | #204 | M | 2 | 完成 | doc-only, FEATURE, 待 US-218 完成 |

**Sprint 容量**：6 points

---

## Story 定義

### US-219：Decision Journal — 衝突決策思考過程與價值觀取捨記錄（M, 2pt, FEATURE, doc-only）

**Issue**：#219
**主要修改**：`docs/km/Decision_Journal.md`, `docs/km/Decision_KB_Index.md`

**AC1**：[靜態] `docs/km/Decision_Journal.md` 檔案存在，包含 YAML frontmatter（`title`、`created`、`last_updated`、`maintainer`）。

**AC2**：[靜態] 每筆記錄為 H3 區塊（`### DJ-NNN`），包含五個必要欄位：`**日期**`、`**情境**`、`**衝突面向**`（至少兩個對立選項）、`**決策結果**`、`**後續追蹤**`。

**AC3**：[靜態] `docs/km/Decision_KB_Index.md` 新增 `## Decision Journal 索引` 區段，含表格 `| DJ 編號 | 日期 | 情境摘要 | 關聯 ADR/Issue |`。

**AC4**：[靜態] `Decision_KB_Index.md` 的「依關鍵字篩選」表格新增至少一筆 DJ 關鍵字映射。

**AC5**：[靜態] 包含至少一筆範例記錄（`### DJ-001`），涵蓋 AC2 定義的五個必要欄位。

**Done 定義**：
- [ ] AC1：Decision_Journal.md 存在且 YAML frontmatter 完整
- [ ] AC2：每筆記錄為 H3 區塊，五個必要欄位齊全
- [ ] AC3：Decision_KB_Index.md 新增 Decision Journal 索引區段與表格
- [ ] AC4：關鍵字篩選表格新增 DJ 關鍵字映射
- [ ] AC5：DJ-001 範例記錄完整
- [ ] Spec Compliance self-review 通過
- [ ] Code Quality self-review 通過

### US-218：代理人校準機制 — 定期價值觀歸納審查與漂移偵測（M, 2pt, FEATURE, doc-only）

**Issue**：#218
**主要修改**：`skills/sprint-review/SKILL.md`, `docs/km/Calibration_Log.md`
**依賴**：搭配 US-219（Decision Journal），漂移差異寫入 DJ

**AC1**：[靜態] `skills/sprint-review/SKILL.md` 的 Retrospective 流程步驟 4 之後新增步驟 5「代理人校準儀式」，含三個子步驟：(a) Agent 列出歸納的 Stakeholder 三個核心價值觀、(b) Agent 列出本 Sprint 最重要的一個決策及其依據、(c) Stakeholder 確認或修正，差異點記錄至 Decision Journal。

**AC2**：[靜態] `docs/km/Calibration_Log.md` 存在，每筆校準記錄為 H3 區塊（`### Sprint N 校準記錄`），包含四個必要欄位：`**日期**`、`**Agent 歸納的價值觀**`（條列三項）、`**Stakeholder 修正**`、`**漂移判定**`。

**AC3**：[靜態] 漂移偵測判定標準定義於步驟 5——Stakeholder 修正任一項價值觀即「偵測到漂移」；三項均確認無修正即「無漂移」。

**AC4**：[動態] 漂移判定為「偵測到漂移」時，將差異點寫入 `docs/km/Decision_Journal.md`（依 US-219 AC2 格式），情境欄位標注「來源：Sprint N 校準儀式」。

**AC5**：[靜態] `skills/sprint-review/SKILL.md` 執行檢查清單新增：`- [ ] 代理人校準儀式已完成（校準記錄已寫入 Calibration_Log.md，漂移判定已標注）`。

**Done 定義**：
- [ ] AC1：sprint-review/SKILL.md 步驟 5 代理人校準儀式已新增（含三個子步驟）
- [ ] AC2：Calibration_Log.md 存在且記錄結構完整（四個必要欄位）
- [ ] AC3：漂移偵測判定標準定義於步驟 5
- [ ] AC4：漂移差異點寫入 Decision Journal 的指令完整
- [ ] AC5：執行檢查清單新增校準儀式檢查項
- [ ] Spec Compliance self-review 通過
- [ ] Code Quality self-review 通過

### US-204：統一合約位置 — 跨角色共用的交付標準應有單一查閱點（M, 2pt, FEATURE, doc-only）

**Issue**：#204
**主要修改**：`contracts/README.md`, `contracts/*.md`, `skills/sprint-planning/SKILL.md` 或 `skills/sprint-execution/SKILL.md`（至少兩個角色 skill）

**AC1**：[靜態] 專案根目錄下存在 `contracts/` 目錄，含 `README.md` 說明文件——定義用途、與 CLAUDE.md 的分工邊界、命名慣例。

**AC2**：[靜態] 合約檔案命名遵循 `{domain}-contract.md` 慣例，每檔包含：(a) YAML frontmatter（`title`、`created`、`last_updated`、`applicable_roles`）、(b) `## 檢查清單` 區段（Markdown checkbox 格式）。

**AC3**：[靜態] 至少兩個角色 skill 的 SKILL.md 新增「合約載入」步驟，含讀取指令與載入時機定義。

**AC4**：[靜態] `contracts/` 目錄含至少兩個範例合約：(a) SOW 交付合約（含「SOW 必須包含架構圖」）、(b) 數值一致性合約（含「數值修改後須跨表同步驗證」）。

**AC5**：[靜態] `contracts/README.md` 含 CLAUDE.md 分工比較表格（`| 面向 | CLAUDE.md | contracts/ |`），至少三個面向。

**Done 定義**：
- [ ] AC1：contracts/ 目錄與 README.md 存在，用途與分工邊界定義完整
- [ ] AC2：合約檔案命名與結構符合規範（YAML frontmatter + 檢查清單）
- [ ] AC3：至少兩個角色 skill 新增合約載入步驟
- [ ] AC4：兩個範例合約檔案存在且內容完整
- [ ] AC5：README.md 含 CLAUDE.md 分工比較表格（至少三個面向）
- [ ] Spec Compliance self-review 通過
- [ ] Code Quality self-review 通過

---

## 平行分群建議

### Phase 1（平行，無檔案衝突）
| Story | Size | 說明 |
|-------|------|------|
| US-219 | M | 修改 docs/km/Decision_Journal.md + Decision_KB_Index.md |
| US-218 | M | 修改 skills/sprint-review/SKILL.md + docs/km/Calibration_Log.md |

US-219 與 US-218 修改的檔案完全不同，可由兩個 subagent 完全平行執行。US-218 AC4 對 US-219 的依賴為寫入格式參照，不阻塞平行開發（格式已在 AC 中明確定義）。

### Phase 2（序列，待 US-218 完成）
| Story | Size | 說明 |
|-------|------|------|
| US-204 | M | 修改 contracts/* + 至少兩個 skills/*/SKILL.md |

US-204 與 US-218 均可能修改 `skills/sprint-review/SKILL.md`，須待 US-218 完成後再啟動 US-204，避免合併衝突。

---

## Architect 評估結果

- T-shirt size：三個 Story 均為 M（各 2pt）
- ADR 需求：無（三個 Story 均不需要 ADR）
- API 契約：不適用（doc-only Stories）
- 平行分群：Phase 1 平行（US-219 + US-218）→ Phase 2 序列（US-204）
- 方法論：BDD 不適用、DDD 不適用（均為文件結構與流程定義，非行為驅動或領域建模）

---

## 權重調整記錄

快思模式，跳過權重調整
