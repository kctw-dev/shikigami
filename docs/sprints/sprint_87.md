# Sprint 87

> 狀態：完成
> **結果**：Goal 達成（2/2 Stories PASS）。Velocity 5 points，完成率 100%。效能基準管理框架建立（三場景 Load Test + 偏差公式 + 告警閾值 + SLI 交叉參照）+ Solo Mode 角色封裝規範交付（SPEC + QA POC 雙檔案互驗）。
> **Stakeholder 驗收**：接受
> 日期：2026-03-12
> Sprint Goal：部署品質雙軌強化 — 建立效能基準管理機制 + 定義 Shikigami 單人服務模式角色封裝規範

## Sprint Backlog

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| US-238 | 效能基準管理 — 部署前 Load Test 與效能回歸偵測 | M | 2 | 完成 |
| US-239 | 單人服務模式 — 角色獨立派遣至外部專案 | L | 3 | 完成 |

容量：5 points（1M + 1L）

## Acceptance Criteria

### US-238 效能基準管理 — 部署前 Load Test 與效能回歸偵測（M/2pt）| INFRA | doc-only

| AC | 類型 | 驗證重點 | 目標檔案 |
|----|------|---------|---------|
| AC1 | [靜態] | `skills/deployment-readiness/SKILL.md` 新增效能基準 (Baseline) 定義格式規格區段，包含欄位：指標名稱、量測方法、基線值、告警閾值（Warning/Critical）、量測工具 | `skills/deployment-readiness/SKILL.md` |
| AC2 | [靜態] | 新增 Load Test 觸發時機指引，至少 3 種觸發場景（部署前、效能相關 PR、定期排程），每種含觸發條件與執行步驟 | `skills/deployment-readiness/SKILL.md` |
| AC3 | [靜態] | 新增效能回歸偵測告警閾值定義，含比對邏輯（baseline vs. current）、偏差百分比閾值（Warning/Critical）、告警動作 | `skills/deployment-readiness/SKILL.md` |
| AC4 | [靜態] | S5 部署 Checklist 新增「效能基準驗證通過」項目 | `skills/deployment-readiness/SKILL.md` |
| AC5 | [靜態] | S7 SLO/SLI 延遲 SLI 區段交叉參照效能基準 | `skills/deployment-readiness/SKILL.md` |
| AC6 | [靜態] | `docs/templates/performance-baseline-template.md` 模板新建，欄位與 AC1 定義一致 | `docs/templates/performance-baseline-template.md` (NEW) |

### US-239 單人服務模式 — 角色獨立派遣至外部專案（L/3pt）| FEATURE | doc-only

| AC | 類型 | 驗證重點 | 目標檔案 |
|----|------|---------|---------|
| AC1 | [靜態] | SOLO_MODE_SPEC.md 定義角色封裝規範：攜帶 skill 清單規則、skill 依賴解析邏輯、角色 profile 最小結構定義 | `docs/solo-mode/SOLO_MODE_SPEC.md` (NEW) |
| AC2 | [靜態] | context 最小集清單：獨立派遣最小檔案集合、不需攜帶的團隊流程檔案清單、context 注入方式 | `docs/solo-mode/SOLO_MODE_SPEC.md` (NEW) |
| AC3 | [靜態] | 品質標準攜帶規則：不確定性前置檢查必攜帶、self-review 必攜帶、quality-gate 攜帶條件 | `docs/solo-mode/SOLO_MODE_SPEC.md` (NEW) |
| AC4 | [靜態] | 資安邊界規則：任務資料不留存、敏感資訊處理、與 security-review SKILL.md 關聯 | `docs/solo-mode/SOLO_MODE_SPEC.md` (NEW) |
| AC5 | [靜態] | QA 角色獨立派遣 POC：攜帶 skill 具體清單、context 最小集具體檔案列表、模擬外部專案使用場景 | `docs/solo-mode/roles/qa-solo-poc.md` (NEW) |
| AC6 | [靜態] | POC 品質標準攜帶驗證：QA 在無 Sprint 流程下仍能執行 AC 驗證、code review、測試覆蓋檢查 | `docs/solo-mode/roles/qa-solo-poc.md` (NEW) |
| AC7 | [靜態] | SPEC 與 POC 交叉一致性驗證 | 兩份檔案交叉驗證 |

## 平行分群

### Phase 1（平行執行，無檔案衝突）
| Story ID | 標題 | Size | 說明 |
|----------|------|------|------|
| US-238 | 效能基準管理 | M | 修改 deployment-readiness SKILL.md + 新增 template |
| US-239 | 單人服務模式 | L | 新建 docs/solo-mode/ 全部檔案 |

## 備註
- 兩個 Story 皆為 doc-only，TDD 豁免
- US-238 為 INFRA 類型（Contract Owner: SRE），US-239 為 FEATURE 類型（Contract Owner: Architect）
- 兩個 Story 無檔案衝突，可完全平行執行
