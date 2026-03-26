# Sprint 176

**Sprint Goal：強化 CI 自動化與品質基礎建設 — 交付水位監控週期性腳本、SessionEnd Hook 遷移至 hook-runner.sh 保護、輕量版 Discovery SOP 實現，以及 MCP Server quality-observer 端到端測試**

**開始日期**：2026-03-26
**結束日期**：2026-04-02
**容量**：6 pts
**Velocity 基準**：avg 6 pts（Sprint 173=6, Sprint 174=6, Sprint 175=6）

---

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 | 負責 | Routing Tier |
|-------|-------|------|--------|------|------|-------------|
| retro: 自動化 sprint-candidate 水位週期性監控機制 | #944 | S | 1 | DONE | PR#945 | haiku（Score 5, INFRA script） |
| chore: 將高風險 SessionEnd Hook 遷移至 hook-runner.sh | #939 | S | 1 | DONE | PR#946 | sonnet（Score 6, config migration） |
| chore: 輕量版 Backlog Discovery 流程與 SOP 實現 | #930 | M | 2 | DONE | PR#951 | haiku（Score 4, DOC/RESEARCH） |
| test: MCP Server 端到端測試 — quality-observer | #926 | M | 2 | DONE | PR#952 | haiku（Score 5, TEST） |

**總計**：4 Stories / 6 pts

---

## 驗收標準摘要

### #944 retro: 自動化水位監控
- AC1: scripts/check-backlog-health.sh 建立，讀取 sprint-candidate 水位
- AC2: 水位不足輸出 [BACKLOG-REPLENISH-TRIGGER]
- AC3: 整合至 CI workflow（參考 complexity-trend.yml）
- AC4: 支援 --threshold 參數覆蓋預設值 10
- NFR1: gh CLI 失敗靜默降級（exit 0）
- NFR2: 每次執行結果寫入 JSONL 趨勢記錄

### #939 chore: SessionEnd Hook 遷移
- AC1: hooks.json SessionEnd Hook 改為透過 hook-runner.sh 執行
- AC2: test-hook-integration-suite.sh 通過
- AC3: 新增 validate-json.sh 通過確認測試
- NFR1: 遷移不影響現有 Hook 功能行為
- NFR2: timeout 設定不意外 kill 正常 Hook

### #930 chore: 輕量版 Discovery SOP
- AC1: 輕量版 Discovery SOP（步驟、觸發條件、模板）
- AC2: 工作量 <= 1pt，文件說明理由
- AC3: 定義增量 Discovery 觸發條件
- AC4: 補充至少 4 個新 sprint-candidate issues
- NFR1: 可持續月執行
- NFR2: 與完整版本相輔相成

### #926 test: MCP Server e2e
- AC1: tests/test-mcp-quality-observer-e2e.sh，至少 4 個查詢場景
- AC2: 所有 response 符合 MCP 標準結構（id, result/error, jsonrpc）
- AC3: error cases 測試（無效 query, 缺失數據源）
- AC4: query payload 多種形式（filter, range 等）
- NFR1: MCP 協議版本一致性
- NFR2: 所有 query 可重複執行

---

## 獨立性評估

| Story | 主要修改檔案 | 衝突評估 |
|-------|------------|---------|
| #944 | scripts/check-backlog-health.sh, .github/workflows/*.yml（新建） | 獨立 |
| #939 | hooks/hooks.json | 獨立 |
| #930 | docs/（新建文件）, GitHub Issues | 獨立 |
| #926 | tests/test-mcp-quality-observer-e2e.sh（新建） | 獨立 |

**結論**：4 個 Stories 修改不同檔案，可全部平行執行。

---

## Architect 技術評估

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | 說明 |
|-------|---------|---------|---------|-------------|------|
| #944 | S | 無需 ADR | 不適用 | SDD-000 §3 | 遵循 complexity-trend.yml 既有 CI 模式，無新架構決策 |
| #939 | S | 無需 ADR | 不適用 | SDD-000 §5 | hook-runner.sh 已由 #923 建立，本 Story 純遷移 |
| #930 | M | 無需 ADR | 不適用 | — | SOP 文件交付，無架構涉及 |
| #926 | M | 無需 ADR | 不適用 | SDD-000 | test-only，quality-observer 架構不變 |

**容量確認**：[CAPACITY] avg_velocity=6pts, recommended_capacity=6pts (±20% range: 4-7pts) — 本 Sprint 6pts，PASS。

---

## QA 驗收確認

| Story | AC 可測試 | 路徑驗證 | 隱性需求 | DoR 確認 |
|-------|---------|---------|---------|---------|
| #944 | PASS | scripts/ PASS | JSONL 格式規範（Minor，不阻擋） | READY |
| #939 | PASS | tests/test-hook-integration-suite.sh PASS | — | READY |
| #930 | PASS | N/A（新建） | — | READY |
| #926 | PASS | mcp-servers/quality-observer/index.js PASS | — | READY |

**Haiku Ratio**：3/4 = 75% — ROUTING-OK（>= 20% 門檻通過）

---

## 風險評估

| 風險 | 機率 | 影響 | 緩解措施 |
|------|------|------|---------|
| #939 hooks.json 格式錯誤導致 Hook 失效 | 低 | 高 | AC3 要求 validate-json.sh 通過驗證 |
| #926 MCP stdio transport 測試不穩定 | 低 | 中 | 參考現有 test-mcp-quality-observer.sh 模式 |
| #930 AC4 補充 Issues 可能水位不足 | 低 | 低 | AC4 本身即為驗收標準，不足時需補充 |
