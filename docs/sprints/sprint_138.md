# Sprint 138

**Sprint Goal**：落地 ADR-038/ADR-039 決策成果——實作 Kill Switch 緊急停止機制與 Token Cost Routing 風險評分分級，同步修復持續發生的 New Issue Intake CI 認證失敗根因（第五次，升級為必修）。

**日期**：2026-03-24
**版本目標**：v0.93.0（minor bump，含 Kill Switch + Token Cost Routing 兩大功能落地 + CI 認證根治）

**容量**：6 pts（Velocity 基準 Sprint 135-137：6/6/6 pts，平均 6 pts，建議區間 6-7 pts）

---

## Sprint Backlog

| Story | Issue | Type | Size | Points | 狀態 | 獨立性 |
|-------|-------|------|------|--------|------|--------|
| [SRE] New Issue Intake CI 持続失敗 — 調查根本原因 | #622 | INFRA | S | 1 | 已完成 DONE(comment) | 與 #618 同 new-issue-intake.yml，需先執行 |
| incident: ANTHROPIC_API_KEY 缺失（第五次）— CI 認證修復 | #618 | INFRA | S | 1 | 待執行（等 #622 完成） | 依賴 #622 調查結果 |
| feat: Kill Switch — High 自治模式緊急停止 | #398 | FEATURE | M | 2 | 待執行 | 獨立（hooks/kill-switch.sh） |
| feat: Token Cost Routing — Risk-based Model 分級 | #402 | FEATURE | M | 2 | 待執行 | 獨立（CLAUDE.md + story-lifecycle-prompt.md） |

**Sprint 容量**：6 points

---

## Sprint Goal 拆解

### Phase 1（CI 修復，序列）
**#622 → #618**：先調查確認根本原因，再執行修復。

### Phase 2（功能實作，可平行）
**#398 | #402**（平行執行）：Kill Switch 與 Token Cost Routing 修改不同檔案，可同時派遣。

---

## 技術評估（Architect）

| Story | T-shirt | ADR 需求 | API 契約 | Schema Contract | Related SDDs | Refinement |
|-------|---------|---------|---------|----------------|-------------|------------|
| US-#622 | S | 無需 ADR | 不適用 | 豁免（INFRA 調查） | — | 豁免（S-size） |
| US-#618 | S | 無需 ADR | 不適用 | 豁免（INFRA fix） | — | 豁免（S-size） |
| US-#398 | M | 已有 ADR-038（Accepted） | 不適用 | 豁免（file-based） | — | READY（Q1-Q5 通過） |
| US-#402 | M | 已有 ADR-039（Accepted） | 不適用 | 豁免（doc 修改） | — | READY（Q1-Q5 通過） |

### ADR 依賴分群

無 ADR RESEARCH Story 在本 Sprint（ADR-038/039 已在 Sprint 137 完成）。

### 平行分群建議

> SHIKIGAMI_MAX_PARALLEL 未設定，不限制平行數量

**Phase 1（序列執行）**：#622 → #618（同 workflow 檔案，調查先於修復）

**Phase 2（可平行執行）**：

| Story ID | 標題 | T-shirt | 說明 |
|----------|------|---------|------|
| US-#398 | Kill Switch 實作 | M | hooks/kill-switch.sh 新建，無衝突 |
| US-#402 | Token Cost Routing 實作 | M | CLAUDE.md + story-lifecycle-prompt.md，與 #398 不衝突 |

**檔案衝突分析**：

| 衝突檔案 | 涉及 Story | 建議執行順序 | 矩陣依據 |
|---------|-----------|------------|---------|
| .github/workflows/new-issue-intake.yml | #622, #618 | #622 → #618 | parallel-safety-matrix.md §1：同一 workflow 檔案 = NO |

---

## 驗收標準（QA 確認）

### US-#622 — SRE 調查
- AC1: PASS — 閱讀 run log，記錄具體錯誤訊息 [可測試]
- AC2: PASS — 產出調查報告 comment [可測試]
- AC3: PASS — 確認 #616 升級機制觸發（第五次）[可測試]
- AC4: PASS — 提出根本修復建議 [可測試]

**隱性需求**：[reliability] 調查報告須涵蓋所有 6 次失敗 run 的模式，不能只看單次。

### US-#618 — CI 修復
- AC1: PASS — secret 引用語法確認 [可測試]
- AC2: PASS — green run [可測試]
- AC3: PASS — 與 #622 調查報告對照 [可測試]
- AC4: PASS — commit reference [可測試]

**隱性需求**：[reliability] 修復後連續 3 次成功才算穩定。

### US-#398 — Kill Switch
- AC1: PASS — hooks/kill-switch.sh trigger 子命令 [可測試]
- AC2: PASS — .kill-switch/ 在 .gitignore [可測試]
- AC3: PASS — report JSON 格式 [可測試]
- AC4: PASS — status 子命令 [可測試]
- AC5: PASS — hooks.json 更新 [可測試]

**SDD 引用**：docs/sdd/ 無對應 SDD，跳過檢查（豁免）。
**路徑驗證**：hooks/hooks.json 存在 — PASS；.gitignore 存在 — PASS。

### US-#402 — Token Cost Routing
- AC1: PASS — CLAUDE.md 紅線 3 修訂 [可測試]
- AC2: PASS — story-lifecycle-prompt.md 風險評分表 [可測試]
- AC3: PASS — Metrics_Log.md model_routing 欄位 [可測試]
- AC4: PASS — rice-scoring-standard.md 更新 [可測試]
- AC5: PASS — sprint_138.md Model Routing 區塊 [可測試]

**路徑驗證**：skills/sprint-execution/story-lifecycle-prompt.md — PASS；docs/km/Metrics_Log.md — PASS。

**QA 確認結果**：所有 Story AC 完整、可測試，DoR 條件滿足。

---

## Model Routing（ADR-039 首次應用）

| Story | Model Used | Tier | Risk Score | 路由原因 |
|-------|-----------|------|-----------|---------|
| #622  | haiku     | 1    | 5          | 調查/唯讀 + doc-only report，可逆（R=1, S=1, C=2, N=1） |
| #618  | sonnet    | 2    | 7          | CI workflow fix，影響 production CI，半範本（R=2, S=2, C=2, N=1） |
| #398  | sonnet    | 2    | 8          | 新建 hooks/ script，影響框架行為，半範本（R=2, S=2, C=2, N=2） |
| #402  | sonnet    | 2    | 8          | CLAUDE.md + skill 修改，影響所有 agent 行為，半範本（R=2, S=2, C=2, N=2） |

---

## 複雜度預算

**前置快照**：Skill=30（門檻 40），Agent=8（門檻 15），Hooks=26（門檻 35），Lines=8789（門檻 25000）

- #398 新增：hooks/kill-switch.sh（新 hook script，不增 Skill/Agent count）
- #402 修改：現有文件，不增加 Skill/Agent count
- **結果**：PASS，不超出複雜度預算

---

## Retrospective Action Items 追蹤

| 來源 | Issue | 狀態 |
|------|-------|------|
| Sprint 137 retro-action | #622 | 本 Sprint 執行 |
| Sprint 137 retro-action（#618） | #618 | 本 Sprint 執行 |
