# Sprint 40

**狀態**：進行中
**期間**：2026-05-25 ~ 2026-05-31
**Sprint Goal**：完成 M4 度量層 — US-13 DORA Metrics 交付，並清償 TD-002 技術債，讓工程效能可量化、PO subagent 輸出結構可驗證。
**總計**：2 Stories / 5 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | Phase | 狀態 |
|----------|---------|------|------|--------|-------|------|
| US-13 | #62 | DORA Metrics — 部署頻率、變更前置時間、MTTR、變更失敗率追蹤 | L | 3 | Phase 1（平行） | 進行中 |
| TD-002 | #65 | PO subagent 輸出格式 JSON Schema 正式驗證 | M | 2 | Phase 1（平行） | 進行中 |

**Sprint 容量**：5 Points

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1（全平行） | US-13、TD-002 | 檔案修改範圍無重疊：US-13 修改 skills/sprint-review、docs/Metrics_Log.md；TD-002 修改 schemas/、tests/、skills/sprint-execution |

**平行可行性判定**：APPROVED — 兩個 Story 的檔案修改路徑無交集，可同時執行。

---

## Story 詳細 AC

---

### US-13：DORA Metrics — 部署頻率、變更前置時間、MTTR、變更失敗率追蹤

**來源**：ROADMAP.md M4 外部整合 — Issue #62
**Size**：L / 3 Points
**Owner**：Developer（獨立 DORA subagent）
**QA doc-only 判定**：No（涉及 skills/ 修改，新增 DORA 計算子節）
**ADR 參考**：ADR-003（SKILL.md 修改規範）、ADR-006（gh CLI 輸出 XML 標記包裹）、ADR-011（GitHub Actions 整合架構）
**ADR-003 Checklist**：適用（修改 skills/sprint-review SKILL.md）

**Architect 設計摘要**
- 介面：gh CLI 查詢（`gh run list` + `gh pr list` + `gh issue list --label bug`）
- 模組：sprint-review SKILL.md 新增獨立子節（§2.7 或 §7.1：DORA Metrics 計算）
- 執行：獨立 DORA subagent（不合併至 Metrics subagent，職責分離）
- 安全：所有 gh CLI 輸出以 `<dora_input>` XML 標記包裹（ADR-006 合規）
- 輸出：Metrics_Log.md 新增獨立 DORA Metrics 表格段落

**User Story**

As a Product Owner monitoring engineering health, I want DORA four key metrics (Deployment Frequency, Lead Time for Changes, MTTR, Change Failure Rate) automatically computed and reported at each Sprint Review, so that I can objectively assess team delivery performance and identify systemic bottlenecks.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | sprint-review SKILL.md 新增 DORA 指標計算步驟 | SKILL.md 存在 §2.7 或 §7.1 子節，Sprint Review 自動輸出四項 DORA 指標數值（Deployment Frequency、Lead Time for Changes、MTTR、Change Failure Rate） |
| AC2 | [靜態] | 資料來源為 gh CLI，所有輸出以 `<dora_input>` XML 標記包裹 | 不依賴外部 API，僅使用 gh CLI（`gh run list`、`gh pr list`、`gh issue list --label bug`）；SKILL.md 明確標注 XML 包裹要求（ADR-006 合規） |
| AC3 | [靜態] | 指標累積至 Metrics_Log.md | Metrics_Log.md 包含獨立 DORA Metrics 表格段落；每次 Sprint Review 的 DORA 快照追加至該段落 |
| AC4 | [靜態] | 趨勢分析演算法寫入 SKILL.md，含資料不足處理邏輯 | SKILL.md 明確定義：（a）累積 Sprint ≥ 3 時，判定改善中 / 退步中 / 穩定；（b）累積 Sprint < 3 時，趨勢欄填「資料不足」並記錄現有數值。Sprint 40 為首次建立 DORA baseline，趨勢判定需至 Sprint 42 才有完整數據。 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 5 | 有實際部署流程的專案均受益 |
| Impact | 2 | 提供量化工程效能視角 |
| Confidence | 0.6 | gh CLI 資料可提取部分 DORA 指標，MTTR 需 Issue 關閉時間近似 |
| Effort | 3 | 需新增計算邏輯 + Metrics_Log 格式擴展 |
| **RICE Score** | **2.0** | R×I×C/E |

**Done 定義**

- [ ] sprint-review SKILL.md 新增 DORA 計算子節（含四項指標定義、gh CLI 查詢指令、XML 包裹要求）
- [ ] 趨勢判定演算法寫入 SKILL.md（含「資料不足」處理邏輯）
- [ ] Metrics_Log.md 新增 DORA Metrics 表格段落（Sprint 40 baseline 快照）
- [ ] ADR-006 合規性確認（`<dora_input>` XML 標記）
- [ ] Issue #62 狀態回寫為已完成

---

### TD-002：PO subagent 輸出格式 JSON Schema 正式驗證

**來源**：Tech_Debt_Registry.md TD-002 — Issue #65
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：No（涉及 schemas/、tests/、skills/ 修改）
**ADR 參考**：ADR-003（SKILL.md 修改規範）、ADR-006（prompt injection 防護與輸出格式驗證）
**ADR-003 Checklist**：適用（修改 skills/sprint-execution SKILL.md 與 docs/adr/）

**User Story**

As a Security Engineer maintaining Shikigami's injection protection, I want a formal JSON Schema validation layer added to the PO subagent output pipeline, so that structural output constraints are enforced at the architecture level rather than relying solely on LLM instruction-following behavior, reducing the residual injection risk identified in ADR-006.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 定義 PO subagent 輸出的正式 JSON Schema | `schemas/po-subagent-output.schema.json` 存在並通過語法驗證 |
| AC2 | [靜態] | sprint-execution 中的 PO subagent 輸出通過 Schema 驗證 | 驗證腳本 `tests/validate-po-output.sh` 存在並包含 schema check 步驟；驗證腳本須包含工具存在性檢查（若 JSON Schema 驗證工具不可用，輸出警告並 graceful fallback，不阻斷 Sprint 執行） |
| AC3 | [靜態] | Schema 驗證失敗時的錯誤恢復路徑明確 | SKILL.md 包含 schema 驗證失敗的回退行為說明（含警告訊息格式與人工審查觸發條件） |
| AC4 | [靜態] | 對應 ADR 決策記錄（ADR-006 Addendum） | `docs/adr/ADR-006-prompt-injection-protection.md` 加入「JSON Schema 驗證決策」補充段落，說明驗證層設計決策與 graceful fallback 策略 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響所有使用 PO subagent 的 Sprint 執行路徑 |
| Impact | 2 | 提升安全性，現有 ADR-006 防護已足夠 v1.0.0 前需求 |
| Confidence | 0.8 | JSON Schema 技術成熟，實作可信度高 |
| Effort | 2 | Schema 設計 + 驗證腳本 + ADR 更新 |
| **RICE Score** | **2.4** | R×I×C/E |

**Done 定義**

- [ ] `schemas/po-subagent-output.schema.json` 建立並通過語法驗證
- [ ] `tests/validate-po-output.sh` 新增 schema check 步驟（含工具存在性檢查與 graceful fallback）
- [ ] SKILL.md 新增 schema 驗證失敗回退行為說明
- [ ] `docs/adr/ADR-006-prompt-injection-protection.md` 新增「JSON Schema 驗證決策」補充段落
- [ ] Issue #65 狀態回寫為已完成

---

## ADR 觸發清單

| Story | ADR | 觸發原因 | 動作 |
|-------|-----|----------|------|
| US-13 | ADR-003 | 修改 skills/sprint-review SKILL.md（新增 DORA 子節） | 遵循 ADR-003 SKILL.md 修改規範 |
| US-13 | ADR-006 | gh CLI 輸出需 XML 標記包裹（prompt injection 防護） | 依 ADR-006 使用 `<dora_input>` XML 標記 |
| US-13 | ADR-011 | 使用 gh CLI 查詢 GitHub Actions 資料（gh run list） | 遵循 ADR-011 GitHub Actions 整合架構 |
| TD-002 | ADR-003 | 修改 skills/sprint-execution SKILL.md + docs/adr/ | 遵循 ADR-003 SKILL.md 修改規範 |
| TD-002 | ADR-006 | 補充 JSON Schema 驗證決策至 ADR-006 Addendum | 於 `ADR-006-prompt-injection-protection.md` 新增補充段落 |

---

## Sprint Planning 簽核記錄

| 角色 | 確認項目 | 狀態 |
|------|----------|------|
| Product Owner | Sprint Goal 對齊 M4 度量層，US-13（DORA）+ TD-002（JSON Schema）優先級確認 | 已確認 |
| Architect | US-13 L-size 技術可行性評估（gh CLI 介面、獨立 DORA subagent 架構、ADR-006 XML 包裹）；TD-002 M-size 技術可行性評估 | 已確認 |
| QA | US-13 AC4 趨勢判定「資料不足」處理邏輯；TD-002 AC2 graceful fallback + AC4 路徑修正（ADR-006-prompt-injection-protection.md） | 已確認（NEEDS_REVISION 修正整合） |
| Developer | Story 清晰度確認，Phase 1 全平行執行可行 | 待確認 |

**Sprint Planning 決策記錄**

- Sprint 40 選入 2 Stories（US-13 + TD-002），共 5 Points
- 平行分群：Phase 1 全平行（檔案範圍無重疊）
- US-13 doc-only 判定：No（涉及 skills/ 修改，ADR-003 適用）
- TD-002 doc-only 判定：No（涉及 schemas/、tests/、skills/ 修改，ADR-003 適用）
- Sprint 40 為 DORA Metrics 首次 baseline 建立，趨勢判定於 Sprint 42 才可完整評估
- Milestone "Sprint 40" 建立於 GitHub（#4），Issue #62、#65 已設定 in-sprint 標籤
