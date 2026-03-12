# Sprint 88

> 狀態：完成
> 日期：2026-03-12
> Sprint Goal：框架品質全面強化 — TDD 需求理解升級 + Shoot CI Gate + E2E 修復 + MCP 三層架構評估 + 前端設計 Gate

## Sprint Backlog

| Story ID | Issue | 標題 | Size | Points | Type | 狀態 |
|----------|-------|------|------|--------|------|------|
| US-240 | #237 | TDD 需求理解驗證 — 寫不出測試自動觸發 REQUIREMENT_AMBIGUITY 升級 | S | 1 | FEATURE | 完成 |
| US-241 | #236 | shoot CI Gate — CI pass 才標 PASS | S | 1 | FEATURE | 完成 |
| US-242 | #206 | E2E workflow placeholder 修復 | S | 1 | INFRA | 完成 |
| US-243 | #231 | MCP 三層架構 — 知識庫/流程管理/品質觀察 MCP Server | M | 2 | RESEARCH | 完成 |
| US-244 | #198 | 前端 Story 設計資訊 Gate — Pre-check + 角色派遣 + 交付審查 | M | 2 | FEATURE | 完成 |

容量：7 points（3S + 2M）

## Acceptance Criteria

### US-240 TDD 需求理解驗證 — 寫不出測試自動觸發 REQUIREMENT_AMBIGUITY 升級（S/1pt）| FEATURE

| AC | 驗證重點 | 目標檔案 |
|----|---------|---------|
| AC1 | story-lifecycle-prompt.md TDD Red 階段新增「測試可寫性檢查」步驟，定義至少 3 個判斷條件 | `skills/story-lifecycle-prompt.md` |
| AC2 | 無法寫測試時回傳 ESCALATE: REQUIREMENT_AMBIGUITY，附帶結構化問題清單 | `skills/story-lifecycle-prompt.md` |
| AC3 | sprint-execution/SKILL.md 升級類型處置表補充「TDD 測試可寫性失敗」觸發來源 | `skills/sprint-execution/SKILL.md` |
| AC4 | 既有 TDD Hard Gate 行為不受影響 | `skills/story-lifecycle-prompt.md` |

### US-241 shoot CI Gate — CI pass 才標 PASS（S/1pt）| FEATURE

| AC | 驗證重點 | 目標檔案 |
|----|---------|---------|
| AC1 | shoot 流程在 git push 後、寫 Shoot_Log PASS 前，插入 CI 狀態等待步驟 | `skills/shoot/SKILL.md` |
| AC2 | CI PASS 時才寫 Shoot_Log.md PASS | `skills/shoot/SKILL.md` |
| AC3 | CI FAIL 時不寫 PASS，輸出 CI 失敗資訊（workflow 名稱 + run URL） | `skills/shoot/SKILL.md` |
| AC4 | CI 不可用時的降級行為已定義 | `skills/shoot/SKILL.md` |

### US-242 E2E workflow placeholder 修復（S/1pt）| INFRA

| AC | 驗證重點 | 目標檔案 |
|----|---------|---------|
| AC1 | .github/workflows/e2e.yml 中的 placeholder 已替換為實際值或改為 workflow_dispatch | `.github/workflows/e2e.yml` |
| AC2 | 修改後 CI 不會在 tag push 時因 placeholder 而失敗 | `.github/workflows/e2e.yml` |

### US-243 MCP 三層架構 — 知識庫/流程管理/品質觀察 MCP Server（M/2pt）| RESEARCH

| AC | 驗證重點 | 目標檔案 |
|----|---------|---------|
| AC1 | 產出 MCP 三層架構評估報告，涵蓋知識庫/流程管理/品質觀察三個 MCP Server | `docs/adr/` or `docs/research/` |
| AC2 | 定義每個 MCP Server 的工具清單與資源定義 | 同上 |
| AC3 | 評估與現有 plugin 架構的整合方式 | 同上 |
| AC4 | 至少一個 MCP Server 的 POC 實作 | `mcp-servers/` (NEW) |
| AC5 | 產出 ADR-019 草稿 | `docs/adr/adr-019-mcp-three-layer-architecture.md` (NEW) |

### US-244 前端 Story 設計資訊 Gate — Pre-check + 角色派遣 + 交付審查（M/2pt）| FEATURE

| AC | 驗證重點 | 目標檔案 |
|----|---------|---------|
| AC1 | Sprint Planning 階段新增前端 Story 設計資訊 Pre-check | `skills/sprint-execution/SKILL.md` |
| AC2 | Story 類型識別規則新增 Design 類 Story 派遣至 UIUX Agent | `skills/story-lifecycle-prompt.md` |
| AC3 | 前端 Story 交付時須經 UIUX/QA 視覺一致性審查 | `skills/story-lifecycle-prompt.md` |
| AC4 | 修改涉及的 SKILL.md 檔案路徑均存在 | 所有涉及的 SKILL.md |

## 平行分群

### Phase 1（平行執行）
| Story ID | 標題 | Size | 說明 |
|----------|------|------|------|
| US-240 | TDD 需求理解驗證 | S | 修改 story-lifecycle-prompt.md + sprint-execution/SKILL.md |
| US-241 | shoot CI Gate | S | 修改 skills/shoot/SKILL.md |
| US-242 | E2E workflow placeholder 修復 | S | 修改 .github/workflows/e2e.yml |
| US-243 | MCP 三層架構 | M | 新建研究報告 + ADR-019 + POC |

### Phase 2（序列，等 US-240 完成後）
| Story ID | 標題 | Size | 說明 |
|----------|------|------|------|
| US-244 | 前端 Story 設計資訊 Gate | M | 與 US-240 共用 story-lifecycle-prompt.md + sprint-execution/SKILL.md，需序列執行 |

## 備註
- US-240、US-241、US-244 為 FEATURE 類型，US-242 為 INFRA 類型，US-243 為 RESEARCH 類型
- US-244 需等 US-240 完成後再開始，因共用 story-lifecycle-prompt.md 與 sprint-execution/SKILL.md
- US-243 含 POC 實作，非純 doc-only
