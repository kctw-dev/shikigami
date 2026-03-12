# Sprint 84

> 狀態：完成
> 日期：2026-03-12
> Sprint Goal：建立內部品質體系的知識基礎架構 — SBE 範例體系、兩層索引機制、Quality Observer 角色與知識老化偵測，打造知識品質閉環

## Sprint Backlog

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| US-221 | 知識老化偵測 — API 文件更新主動感知與 ground truth 保鮮機制 | M | 2 | 完成 |
| US-226 | SBE 範例體系 — Given/When/Then 結構化業務規則範例 | M | 2 | 完成 |
| US-227 | 兩層索引機制 — Context 管理的 meta-index 漸進載入策略 | S | 1 | 完成 |
| US-228 | Quality Observer — 獨立品質觀察角色與系統性診斷報告 | M | 2 | 完成 |

容量：7 points（3M + 1S）

## Acceptance Criteria

### US-221 知識老化偵測（M/2pt）

| AC | 類型 | 驗證重點 | 目標檔案 |
|----|------|---------|---------|
| AC1 | [靜態] | health-check SKILL.md 新增「知識新鮮度檢查」項目 | `skills/health-check/SKILL.md` |
| AC2 | [靜態] | Sprint 開始時 API 文件版本驗證步驟 | `skills/sprint-planning/SKILL.md` 或 `skills/sprint-execution/SKILL.md` |
| AC3 | [靜態] | 三層偵測機制設計文件（觸發條件與降級策略） | `docs/km/Knowledge_Staleness_Detection.md` |

### US-226 SBE 範例體系（M/2pt）

| AC | 類型 | 驗證重點 | 目標檔案 |
|----|------|---------|---------|
| AC1 | [靜態] | SBE 標準格式定義（Given/When/Then 結構 + 完整範例） | `docs/definition/sbe-examples/SBE_FORMAT.md` |
| AC2 | [靜態] | 目錄結構已建立，含至少一個模組子目錄 | `docs/definition/sbe-examples/` |
| AC3 | [靜態] | SBE → 測試案例轉換規則 | `docs/definition/sbe-examples/SBE_TO_TEST_RULES.md` |
| AC4 | [靜態] | Discovery Phase 或 Sprint Planning 流程引用 SBE 使用時機 | 相關 SKILL.md |

### US-227 兩層索引機制（S/1pt）

| AC | 類型 | 驗證重點 | 目標檔案 |
|----|------|---------|---------|
| AC1 | [靜態] | meta-index 格式定義 | `docs/definition/sbe-examples/meta-index.md` |
| AC2 | [靜態] | 模組 index 格式定義 | `docs/definition/sbe-examples/<module>/index.md` |
| AC3 | [靜態] | Agent 知識載入三層流程（meta-index → 模組 index → 具體範例） | `meta-index.md`「Agent 載入流程」區塊 |
| AC4 | [靜態] | Knowledge Ingestion 流程文件引用兩層索引 | ADR-017 或相關文件 |

### US-228 Quality Observer（M/2pt）

| AC | 類型 | 驗證重點 | 目標檔案 |
|----|------|---------|---------|
| AC1 | [靜態] | Quality Observer 角色定義（含與 QA 差異說明） | `docs/km/Quality_Observer.md` |
| AC2 | [靜態] | 三維度觀察維度定義（幻覺頻率、斷鏈模式、角色協作效率） | `docs/km/Quality_Observer.md` |
| AC3 | [靜態] | 診斷報告格式定義 | `docs/km/Quality_Observer.md`「診斷報告格式」區塊 |
| AC4 | [靜態] | SPACE 指標整合（觀察數據來源對照表） | `docs/km/Metrics_Log.md` |
| AC5 | [靜態] | Sprint Review 流程引用 Quality Observer | `skills/sprint-review/SKILL.md` |

## 平行分群

### Phase 1（可平行執行）
| Story ID | 標題 | Size | 說明 |
|----------|------|------|------|
| US-221 | 知識老化偵測 | M | 修改 skills/health-check + schedule，無衝突 |
| US-226 | SBE 範例體系 | M | 新建 docs/definition/sbe-examples/，無衝突 |
| US-228 | Quality Observer | M | 新建 docs/km/Quality_Observer.md + 修改 sprint-review，無衝突 |

### Phase 2（需序列執行）
| Story ID | 標題 | Size | 衝突原因 |
|----------|------|------|---------|
| US-227 | 兩層索引機制 | S | 依賴 US-226 完成的目錄結構 |
