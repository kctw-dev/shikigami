# Sprint 135

**Sprint Goal**：推進 Context Engineering 基礎架構（ADR-037 + JIT Retrieval 實作），研究 Agent Skills 開放標準對齊可行性，並修復 CI OAuth token 認證失效

**Sprint 期間**：2026-03-24 起

**容量**：6 pts（Velocity 平均 6.3 pts，建議區間 6-7 pts）

**版本目標**：v0.90.0（minor bump，含 Context Engineering JIT 功能交付）

---

## Sprint Backlog

| Story | Issue | Size | Points | Type | 負責人 | 狀態 |
|-------|-------|------|--------|------|--------|------|
| RESEARCH: ADR-037 — Context Engineering JIT 架構決策 | #602 | S | 1 | RESEARCH | Architect | 已完成 (#603) |
| retro: 修復 CI New Issue Intake OAuth token 認證失效 | #597 | S | 1 | INFRA | SRE | 已完成 (#604) |
| research: Agent Skills 開放標準對齊評估 | #396 | M | 2 | RESEARCH | Architect | 已完成 (#605) |
| feat: Context Engineering — Just-in-Time Retrieval | #400 | M | 2 | FEATURE | Developer | 已完成 (#607) |

**Sprint 容量**：6 points

---

## 執行順序（平行分群）

> **SHIKIGAMI_MAX_PARALLEL**：未設定，不限制平行數量

### ADR Phase（必須先執行）

**ADR Phase 1（先執行）**：#602 — ADR-037 Context Engineering JIT 架構決策

### Batch 1（ADR Phase 完成後，可平行執行）

| Story | Issue | T-shirt | 說明 |
|-------|-------|---------|------|
| retro: CI OAuth token 修復 | #597 | S | 獨立 CI workflow 修復，無衝突 |
| research: Agent Skills 開放標準對齊 | #396 | M | 獨立調查，修改 docs/research/ 無衝突 |

### Batch 2（Batch 1 完成後，序列執行）

| Story | Issue | T-shirt | 衝突原因 |
|-------|-------|---------|---------|
| feat: Context Engineering JIT | #400 | M | 依賴 #602（ADR-037 必須先 Accepted）；修改 hooks/session-start/，無其他衝突 |

### 檔案衝突分析

| 衝突檔案 | 涉及 Story | 建議執行順序 | 矩陣依據 |
|---------|-----------|------------|---------|
| docs/adr/ADR-037-*.md | #602, #400 | #602 → #400 | parallel-safety-matrix.md §1：ADR 文件為 #400 的前置依賴 |

**無 ADR Phase 2 for #601/#406**：#601（ADR-036 Schema-first）與 #406（Schema 先行）已移出本 Sprint，下個 Sprint 排入。

---

## Sprint Goal 詳細說明

### 為什麼是這組 Stories？

**Context Engineering（#602 + #400）** 是本 Sprint 的核心功能交付：
- Sprint 134 完成了 Security Gate 與 Conflict Prediction，下一步是提升 agent 本身的執行效率
- JIT context 載入解決 context rot 問題，是長 Sprint 穩定性的基礎
- ADR-037 先行確保架構決策有文件依據，避免後續重工

**Agent Skills 標準評估（#396）** 是戰略研究：
- M5 穩定化里程碑中「輕量化、好上手」方向需要評估格式標準化可行性
- RESEARCH 類型不阻塞其他開發，適合與功能 Story 平行進行

**CI 修復（#597）** 是緊急維運：
- retro-action，CI 持續失敗直接影響 New Issue Intake 自動化流程
- S size，直接排入不推遲

---

## Acceptance Criteria 摘要

### US-#602 RESEARCH: ADR-037 Context Engineering JIT

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | ADR 文件建立 | docs/adr/ADR-037-context-engineering-jit.md 存在 |
| AC2 | ADR 狀態 Accepted | 文件內含 "Accepted" 狀態 |
| AC3 | 三個方向比較（A/B/C） | 文件包含方向 A/B/C 的 trade-off 分析 |
| AC4 | Story #400 確認參照 | Issue #400 有留言確認已參照本 ADR |

### US-#597 retro: CI OAuth token 修復

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | New Issue Intake CI 成功 | gh run list 最新顯示 success |
| AC2 | token 過期預防 | 建立 token 到期提醒或自動更新機制 |

### US-#396 research: Agent Skills 開放標準對齊評估

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | Gap Analysis 文件產出 | docs/research/agent-skills-standard-gap-analysis.md 存在，含對照表 |
| AC2 | Developer 角色 PoC | 所有 tests/test-*.sh 全部通過 |
| AC3 | 決策建議文件 | 包含三個遷移策略選項與建議理由 |

### US-#400 feat: Context Engineering JIT Retrieval

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | Read-on-Demand Hook 實作 | session-start hook 只注入路徑清單 |
| AC2 | Context Manifest 定義 | 至少 1 個 agent 有 context-manifest.yaml |
| AC3 | 測試驗證 | tests/test-context-engineering.sh 通過 |
| AC4 | ADR-037 Accepted | docs/adr/ADR-037 狀態為 Accepted |
| AC5 | Graceful Fallback | manifest 路徑不存在時退回全量預載，不中斷執行 |

---

## Sprint Planning 會議摘要

- **Sprint Planning 開始時間**：2026-03-24T18:57+08:00
- **Velocity 基準**（Sprint 132-134）：6/6/7 pts，平均 6.3 pts
- **容量決定**：6 pts（保守，ADR Phase 加入導致結構複雜）
- **ADR 自動補建**：#601（ADR-036 Schema-first）→ 移出本 Sprint；#602（ADR-037 JIT）→ 納入本 Sprint
- **移出 Backlog 原因**：#406（Schema 先行）+ #601（ADR-036）合計 3 pts 超出容量上限，移至 Sprint 136
- **QA 隱性需求**：#400 補充 AC5（graceful fallback，Major severity）
- **retro-action 自動列入**：#597（Sprint 134 retro action）直接列入 Batch 1

---

## Definition of Done

所有 Story 完成條件：
- [x] 所有 Acceptance Criteria 通過
- [x] 單元測試 / 整合測試全部通過（0 failed）（RESEARCH 豁免）
- [x] 無硬編碼金鑰，配置透過環境變數管理
- [ ] Metrics_Log.md 本 Sprint 數據已更新
- [x] 既有測試全部仍然通過
- [x] PR merged，Issue closed
