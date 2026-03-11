# Sprint 81

**Sprint Goal**：Anti-Hallucination 第二步 — 落地 Knowledge Ingestion：整合 Context Hub MCP，建立 API 文件強制內化機制，完成雙軌 Anti-Hallucination 閉環。

**期間**：2026-03-12 ~ 2026-03-19
**狀態**：進行中
**ADR 依賴**：ADR-017（Accepted）

---

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 | 備註 |
|-------|-------|------|--------|------|------|
| US-216：Knowledge Ingestion — Context Hub 整合，API 文件強制內化 | #216 | L | 3 | 待開發 | doc-only, INTEGRATION, ADR-017 |
| US-220：錯誤追溯鏈 — 測試失敗自動追溯根因源頭 | #220 | M | 2 | 待開發 | doc-only, FEATURE, 依賴 US-216（graceful degradation） |

**Sprint 容量**：5 points

---

## Story 定義

### US-216：Knowledge Ingestion — Context Hub 整合，API 文件強制內化（L, 3pt, INTEGRATION, doc-only）

**Issue**：#216
**主要修改**：`skills/sprint-execution/story-lifecycle-prompt.md`, `skills/onboarding/SKILL.md`
**ADR 依賴**：ADR-017 Accepted

**AC1**：[靜態] story-lifecycle-prompt.md 新增步驟 7.5（Knowledge Ingestion via MCP），位於步驟 7（三問檢查）之後、步驟 8（TDD/doc-only）之前。

**AC2**：[靜態] 步驟 7.5 觸發條件定義完整（三問檢查有 API [UNCERTAIN] 或 AC 含 API docs URL）。

**AC3**：[靜態] MCP tool call 回傳以 `<api_knowledge>` XML 隔離標記包裹（ADR-006 延伸）。

**AC4**：[靜態] CI 環境 fallback 路徑定義完整（CI=true → 跳過 MCP → 輸出 [KNOWLEDGE-INGESTION-SKIPPED: CI_ENV]）。

**AC5**：[靜態] MCP server 啟動失敗 fallback 定義完整（→ WebFetch native → 輸出 [MCP-FALLBACK]）。

**AC6**：[靜態] onboarding/SKILL.md 新增 MCP 設定驗證步驟（驗證 `.mcp.json` 中 context-hub server 配置存在，與 ADR-015 Figma MCP 驗證同模式）。

**AC7**：[靜態] 範圍限定規則定義（僅查詢 AC 引用端點，上限 5 個）。

**Done 定義**：
- [x] AC1：story-lifecycle-prompt.md 步驟 7.5 已新增（位於步驟 7 三問檢查後、TDD/doc-only 前）
- [x] AC2：步驟 7.5 觸發條件定義完整（三問 API [UNCERTAIN] 或 AC 含 API docs URL）
- [x] AC3：MCP tool call 回傳以 `<api_knowledge>` XML 隔離標記包裹
- [x] AC4：CI 環境 fallback 定義完整（CI=true → 跳過 MCP → [KNOWLEDGE-INGESTION-SKIPPED: CI_ENV]）
- [x] AC5：MCP server 啟動失敗 fallback 定義完整（→ WebFetch native → [MCP-FALLBACK]）
- [x] AC6：onboarding/SKILL.md 已新增 context-hub MCP 設定驗證步驟（§2.1.2）
- [x] AC7：範圍限定規則定義（僅查詢 AC 引用端點，上限 5 個）
- [x] Spec Compliance self-review 通過
- [x] Code Quality self-review 通過

### US-220：錯誤追溯鏈 — 測試失敗自動追溯根因源頭（M, 2pt, FEATURE, doc-only）

**Issue**：#220
**主要修改**：`skills/systematic-debugging/SKILL.md`
**依賴**：US-216（API 追溯路徑依賴 Knowledge Ingestion，graceful degradation）

**AC1**：[靜態] systematic-debugging/SKILL.md 新增「根因分類」步驟（位於 Phase 1 結尾），定義 4 類根因與對應路由：
- 實作問題（程式碼 Bug）→ Developer 修復
- 規格問題（SDD/API 契約定義錯誤）→ Architect 修正
- 業務規則問題（AC/Product Brief 描述不符）→ PO 釐清
- API 問題（外部 API 行為與文件不符）→ 觸發 Knowledge Ingestion 更新

**AC2**：[靜態] 每類根因有明確判定規則表格，含判定依據欄位。判定方式為語意分析（非關鍵字 pattern），以 BDD 行為範例格式撰寫：
- Given 測試錯誤類型為 assertion failure 且失敗斷言對應 AC 描述 → Then 分類為「業務規則問題」
- Given 測試錯誤類型為 runtime error（TypeError/ImportError/SyntaxError）→ Then 分類為「實作問題」
- Given 測試錯誤涉及 API 回應 schema 不符或 HTTP status 異常 → Then 分類為「API 問題」
- Given 測試錯誤涉及介面不符（函式簽名/參數型別）→ Then 分類為「規格問題」

**AC3**：[靜態] 追溯報告輸出格式定義完整，使用結構化標記 `[ROOT-CAUSE-TRACE]`，報告包含以下欄位：根因分類、判定依據、路由目標角色、建議處置動作。報告位置於 Phase 1 流程結尾輸出。

**AC4**：[靜態] API 問題分類路徑含 graceful degradation（若 Knowledge Ingestion 不可用，標記 [KNOWLEDGE-GAP] 並繼續 Developer 修復路徑）。

**Done 定義**：

- [x] AC1：systematic-debugging/SKILL.md Phase 1 結尾新增「根因分類」步驟（步驟 6），定義 4 類根因與對應路由
- [x] AC2：每類根因有 BDD 行為範例格式的判定規則表格（R1-R4，Given/Then 格式，語意分析）
- [x] AC3：`[ROOT-CAUSE-TRACE]` 結構化標記定義完整（根因分類、判定依據、路由目標角色、建議處置動作）
- [x] AC4：API 問題分類含 graceful degradation（KI 不可用 → [KNOWLEDGE-GAP] → Developer 修復路徑）
- [x] Spec Compliance self-review 通過
- [x] Code Quality self-review 通過

---

## 平行分群建議

### 完全平行（無檔案衝突）
| Story | Size | 說明 |
|-------|------|------|
| US-216 | L | 修改 story-lifecycle-prompt.md + onboarding/SKILL.md |
| US-220 | M | 修改 systematic-debugging/SKILL.md |

兩個 Story 修改的檔案完全不同，可由兩個 subagent 完全平行執行。US-220 對 US-216 的依賴為 graceful degradation（Knowledge Ingestion 不可用時標記 [KNOWLEDGE-GAP] 即可），不阻塞平行開發。

---

## Architect 評估結果

- 平行分群：兩個 Story 可完全平行（無共用檔案衝突）
- US-220 建議 BDD 行為範例（已在 AC2 補充）
- 方法論：US-216 不適用，US-220 建議 BDD

---

## 權重調整記錄

快思模式，跳過權重調整
