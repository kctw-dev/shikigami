# Sprint 136

**Sprint Goal**：建立 Schema-first API Contract 決策基礎（ADR-036）並落地 Schema 先行工作流程，同步加固 CI YAML lint 品質防護，修復持續發生的 CI OAuth 401 認證失敗根因

**Sprint 期間**：2026-03-24 起

**容量**：6 pts（Velocity 平均 6 pts，Sprint 133-135 均 6/6/6 pts，建議區間 6-7 pts）

**版本目標**：v0.91.0（minor bump，含 Schema-first 工作流程交付）

---

## Sprint Backlog

| Story | Issue | Size | Points | Type | 負責人 | 狀態 |
|-------|-------|------|--------|------|--------|------|
| RESEARCH: ADR-036 — Schema-first API Contract 統一定義架構決策 | #601 | S | 1 | RESEARCH | Architect | 已完成 (#611) |
| retro: Workflow issue body 應使用 --body-file 模式避免 YAML 特殊字符衝突 | #610 | S | 1 | INFRA | Developer | 已完成 (#612) |
| retro: 新增 GitHub Actions workflow YAML lint CI 步驟 | #609 | S | 1 | INFRA | SRE | 已完成 (#613) |
| [SRE] CI 持續失敗：New Issue Intake 401 Invalid bearer token | #600 | S | 1 | BUG | SRE | 已完成 (#614) |
| feat: Schema 先行 — API Contract 統一定義 | #406 | M | 2 | FEATURE | Developer | 已完成 (#615) |

**Sprint 容量**：6 points

---

## 執行順序（平行分群）

> **SHIKIGAMI_MAX_PARALLEL**：未設定，視為 2（OOM 防護，詳見 parallel-safety.md）

### ADR Phase（必須先執行）

**ADR Phase 1（先執行）**：#601 — RESEARCH: ADR-036 Schema-first API Contract 架構決策

### Batch 1（ADR Phase 完成後，可平行執行）

| Story | Issue | T-shirt | 說明 |
|-------|-------|---------|------|
| retro: --body-file 模式規範 | #610 | S | 修改 CLAUDE.md + workflow 檔案，獨立無衝突 |
| retro: YAML lint CI 步驟 | #609 | S | 新增 .github/workflows/ci-yamllint.yml，獨立無衝突 |
| [SRE] CI OAuth 401 修復 | #600 | S | 更新 Secret + 驗證，不涉及程式碼衝突（需人工更新 Secret） |

> Batch 1 最多 2 個 worktree 平行（SHIKIGAMI_MAX_PARALLEL=2），先派 #610 + #609，完成後再執行 #600。

### Batch 2（Batch 1 完成後，序列執行）

| Story | Issue | T-shirt | 衝突原因 |
|-------|-------|---------|---------|
| feat: Schema 先行 API Contract 統一定義 | #406 | M | 依賴 #601（ADR-036 必須先 Accepted）；修改 skills/sprint-planning/references/architect-prompt.md + docs/schema/ |

### 檔案衝突分析

| 衝突檔案 | 涉及 Story | 建議執行順序 | 矩陣依據 |
|---------|-----------|------------|---------|
| docs/adr/ADR-036-*.md | #601, #406 | #601 → #406 | parallel-safety-matrix.md §1：ADR 文件為 #406 的前置依賴 |
| skills/sprint-planning/references/architect-prompt.md | #406 only | 序列 | 單一修改，無衝突 |

---

## Sprint Goal 詳細說明

### 為什麼是這組 Stories？

**戰略背景**：
- Sprint 135 已交付 Context Engineering JIT Retrieval，GAD 工作流程進入 Schema 定義階段
- #406（Schema 先行）在 Sprint 135 規劃時因 ADR-036 尚未建立而移出；Sprint 136 補建 ADR-036（#601）並一起交付
- 兩個 retro-action（#610、#609）直接對應 Sprint 135 的 YAML 問題，屬於高優先框架品質保證工作
- #600 CI 401 bug 持續發生（歷史案例 #551/#557/#583），需本 Sprint 根本解決

**MoSCoW 排序**：
- Must：#600（CI 持續失敗，影響所有 Issue 自動 triage）
- Should：#610、#609（retro-action，Sprint 135 承諾落地）
- Should：#601（ADR-036，#406 前置依賴）
- Could：#406（Schema 先行，依賴 ADR-036）

**容量計算**：
- Velocity 基準（Sprint 133-135）：6/6/6 pts，平均 6 pts
- 容量決定：6 pts（與平均齊平）
- ADR Phase 自動納入：#601（ADR-036）作為 #406 前置，依 ADR 自動納入規則（#456）同列 Sprint

---

## Architect 技術評估

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | 說明 |
|-------|---------|---------|---------|-------------|------|
| #601 RESEARCH ADR-036 | S | 無需 ADR（IS the ADR） | 不適用 | — | RESEARCH type，產出 docs/adr/ADR-036 |
| #610 retro --body-file | S | 無需 ADR | 不適用 | — | doc-only + workflow fix，CLAUDE.md 更新 |
| #609 retro YAML lint | S | 無需 ADR | 不適用 | — | 新增 .github/workflows/ci-yamllint.yml |
| #600 SRE CI 401 | S | 無需 ADR | 不適用 | — | Secret 更新 + 驗證，不涉及框架架構 |
| #406 feat Schema 先行 | M | ADR-036（#601，同 Sprint 納入）| 不適用 | — | 修改 architect-prompt.md + 建立 docs/schema/ |

**Hard Gate 檢查**：#406 需要 ADR-036 → #601（ADR RESEARCH）已納入同 Sprint，ADR Phase 先執行，Hard Gate 通過。

---

## QA 驗收確認

| Story | AC 確認結果 | 路徑驗證 | 隱性需求 | 備註 |
|-------|-----------|---------|---------|------|
| #601 ADR-036 | PASS | N/A（ADR 路徑新建） | — | 4 條 AC 明確可測試 |
| #610 retro --body-file | PASS | N/A（CLAUDE.md 存在） | reliability: YAML parse error 率降為 0 | 3 條 AC 明確 |
| #609 retro YAML lint | PASS | N/A（新建 workflow） | reliability: PR check 阻擋 YAML 錯誤 | 3 條 AC 明確 |
| #600 SRE CI 401 | PASS | N/A（不涉及特定路徑） | reliability: CI 認證失敗率=0 | 3 條 AC，AC3 評估文件需記錄 |
| #406 feat Schema 先行 | PASS | Path verification: PASS（docs/schema/ 為新建）| reliability: Schema-first 不增加 Planning 超 30 分鐘 | 4 條 AC 明確，AC4 有 test script |

---

## Schema Contracts（ADR-036 Schema 先行）

| Contract | 路徑 | 狀態 | 使用 Story |
|---------|------|------|-----------|
| GAD Schema-first 命名規範 | docs/schema/README.md | reference | #406 |

---

## DoD（Definition of Done）

- [ ] 所有 AC 通過
- [ ] PR 審查通過（pr-review-toolkit）
- [ ] 版號 bump（v0.91.0）
- [ ] docs/PROJECT_BOARD.md 更新
- [ ] git tag v0.91.0
