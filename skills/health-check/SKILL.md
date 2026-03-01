---
name: health-check
description: "Use when checking framework health, diagnosing configuration issues, or verifying structural integrity"
---

# Health Check — 框架自我診斷

## 1. 概述

Health Check 是框架的自我診斷工具。一鍵掃描 Shikigami 的核心文件與配置狀態，產出結構化健康報告，讓使用者立即知道框架是否處於健康狀態。

**觸發方式**：使用者表達「檢查框架狀態」、「系統健康嗎」、「有沒有問題」等語意時，由 Scrum Master 路由至此 Skill。

---

## 2. 診斷流程

依序執行以下 4 項檢查，每項獨立評估，最終彙整為 Overall Status。

### 檢查 1：必要文件完整性

掃描以下 5 個核心文件：

| 文件 | 路徑 | 說明 |
|------|------|------|
| CLAUDE.md | `./CLAUDE.md`（專案根目錄） | 框架啟動設定 |
| PROJECT_BOARD | `docs/PROJECT_BOARD.md` | Sprint 進度看板 |
| PRODUCT_BACKLOG | `docs/prd/PRODUCT_BACKLOG.md` | 產品待辦清單 |
| ROADMAP | `docs/prd/ROADMAP.md` | 版本里程碑規劃 |
| Metrics_Log | `docs/km/Metrics_Log.md` | Sprint 度量紀錄 |

**判定規則**：
- 文件不存在 → FAIL
- 文件存在但為空（0 bytes）→ FAIL
- 文件存在且有內容 → PASS

**FAIL 時的修復建議**：
- CLAUDE.md 缺失：「請從 `templates/CLAUDE.md.template` 複製並填入專案資訊」
- PROJECT_BOARD 缺失：「請執行 `/sprint` 建立 Sprint」
- PRODUCT_BACKLOG 缺失：「請執行 Product Discovery 建立 Backlog」
- ROADMAP 缺失：「請建立 `docs/prd/ROADMAP.md` 定義版本里程碑」
- Metrics_Log 缺失：「將在下次 Sprint Review 時由 Metrics 計算自動建立」

**ROADMAP 版號同步檢查**（僅在 ROADMAP PASS 時執行）：
- 讀取 ROADMAP.md 中標示為「進行中」的版本號
- 讀取 `.claude-plugin/plugin.json` 的 `version` 欄位
- 兩者一致 → PASS；不一致 → WARN（「ROADMAP 版本 {X} 與 plugin.json 版本 {Y} 不同步」）

### 檢查 2：孤兒 Story 偵測

掃描 `docs/sprints/` 下所有 `sprint_N.md` 文件，提取其中列出的 Story ID（如 US-07、US-T01 等），反向驗證每個 Story 存在於以下任一文件：
- `docs/prd/PRODUCT_BACKLOG.md`
- `docs/prd/BACKLOG_DONE.md`

**判定規則**：
- Sprint 文件中的 Story 在 Backlog 或 Done 中找到對應 → PASS
- Sprint 文件中的 Story 在兩處都找不到 → WARN（列出孤兒 Story + 來源 Sprint）

**WARN 時的修復建議**：「Story {ID} 出現在 sprint_{N}.md 但不在 Backlog 或 Done 中。請確認是否遺漏登記或已被刪除。」

### 檢查 3：ADR 一致性

掃描 `docs/prd/PRODUCT_BACKLOG.md` 中所有 Story 的 ADR 欄位。

**判定規則**：
- ADR 欄位為「—」或空白 → 本 Story 不需要 ADR，跳過
- ADR 欄位有值（如 `ADR-002`）：
  - 對應 `docs/adr/ADR-002.md` 不存在 → FAIL
  - 文件存在但不含「**狀態**：Accepted」→ FAIL
  - 文件存在且狀態為 Accepted → PASS
- 多個 ADR 引用（逗號分隔，如 `ADR-001, ADR-002`）→ 逐一檢查，任一 FAIL 則整項 FAIL

**FAIL 時的修復建議**：
- ADR 文件不存在：「{Story ID} 引用的 {ADR-ID} 不存在。請執行 `/shikigami:architecture-decision` 建立 ADR。」
- ADR 狀態非 Accepted：「{ADR-ID} 狀態為 {實際狀態}，尚未被接受。Hard Gate：此 Story 不能進入 Sprint。」

### 檢查 4：Retro Action Items 逾期偵測

讀取 `docs/km/Retrospective_Log.md`，找出所有 Action Items 表格中狀態為 `Open` 的項目。

**日期基準**：從 Action Item 所屬的 Sprint 區塊標題提取日期（格式：`## Sprint N — YYYY-MM-DD`）。

**判定規則**：
- 無 Open Action Items → PASS
- 有 Open Action Items，距今 ≤ 14 天 → PASS（顯示待辦提醒）
- 有 Open Action Items，距今 > 14 天 → OVERDUE

**OVERDUE 時的修復建議**：「Action Item #{N}（{描述}）已逾期 {天數} 天。根據流程規則，連續兩個 Sprint 未關閉的 Action 應升級至 Stakeholder。」

---

## 3. 報告格式

執行完 4 項檢查後，產出以下格式的報告：

```
## 框架健康報告

**Overall Status**: {HEALTHY / WARNING / CRITICAL}
**檢查時間**: {YYYY-MM-DD HH:MM}

### 1. 必要文件完整性 — {PASS / FAIL}
- CLAUDE.md: {PASS / FAIL}
- PROJECT_BOARD.md: {PASS / FAIL}
- PRODUCT_BACKLOG.md: {PASS / FAIL}
{若有 FAIL，列出修復建議}

### 2. 孤兒 Story 偵測 — {PASS / WARN}
{PASS: 所有 Sprint Story 皆有對應 Backlog 記錄}
{WARN: 列出孤兒 Story 清單 + 修復建議}

### 3. ADR 一致性 — {PASS / FAIL}
{PASS: 所有 ADR 引用皆存在且為 Accepted}
{FAIL: 列出不一致項目 + 修復建議}

### 4. Retro Action Items — {PASS / OVERDUE}
{PASS: 無逾期 Action Items}
{OVERDUE: 列出逾期項目 + 修復建議}
```

### Overall Status 判定規則

| 條件 | Overall Status |
|------|----------------|
| 任一項 FAIL | **CRITICAL** |
| 有 WARN 或 OVERDUE 但無 FAIL | **WARNING** |
| 全部 PASS | **HEALTHY** |

---

## 4. 執行方式

此 Skill 由 Scrum Master（主 Agent）直接執行，不需要派遣 Subagent。執行時：

1. 依序讀取相關文件（使用 Read、Glob、Grep 工具）
2. 對每個文件進行對應的檢查邏輯
3. 彙整結果，按上述格式輸出報告
4. 若 Overall Status 為 CRITICAL，建議使用者優先修復後再繼續開發

---

## 5. 與其他 Skill 的關係

| 診斷結果 | 建議觸發 |
|----------|----------|
| CLAUDE.md 缺失 | 手動建立或使用 templates/ |
| PROJECT_BOARD 缺失 | `shikigami:sprint-planning` |
| ADR 不一致 | `shikigami:architecture-decision` |
| Retro Action 逾期 | `shikigami:escalation`（若連續 2 Sprint 未關閉） |

---

## 6. 孤兒文件清理規範（US-T09）

### 6.1 定義

**孤兒文件**（Orphan Document）：`docs/` 目錄下的 `.md` 文件，同時滿足以下兩個條件：

1. 未被任何其他 `.md` 文件以相對路徑引用（例如 `[title](./path/file.md)` 或 `[title](dir/file.md)`）
2. 不在豁免清單中（見下節）

### 6.2 豁免清單

以下 4 類文件自動豁免孤兒偵測，不產生 WARNING：

| 類別 | 規則 | 說明 |
|------|------|------|
| CLASS_1：Sprint 週期文件 | `docs/sprints/sprint_N.md`（N 為數字） | Sprint 文件為週期性產出，由 PROJECT_BOARD 管理，不需直接引用 |
| CLASS_2：度量紀錄 | `docs/km/Metrics_Log.md` | 自動累積的度量紀錄，不需其他文件引用 |
| CLASS_3：頂層文件 | `docs/` 直屬文件（無子目錄層，如 `docs/PROJECT_BOARD.md`） | 頂層導覽文件為入口點，不需被引用 |
| CLASS_4：ADR 文件 | `docs/adr/ADR-*.md` | ADR 文件由 Backlog 管理，不需在文件間相互引用 |

### 6.3 判定週期

每次 CI 執行時自動偵測，對應 `.github/workflows/validate.yml` 中的 `Validate Orphans` 步驟。

### 6.4 輸出格式

偵測到孤兒文件時，輸出以下格式的 WARNING（不阻塞 CI，exit code 為 0）：

```
[WARNING] <file_path>: 孤兒文件（無任何 .md 引用）
```

腳本位置：`scripts/validate-orphans.sh`

### 6.5 處置流程（AC3）

偵測到孤兒文件後，依照以下三步驟處置：

1. **列為 Problem**：開發者在最近一次 Sprint Retrospective 中，將孤兒文件列入 Problem 欄位，說明文件名稱與發現時間
2. **PO 裁定**：由 Product Owner 審視後選擇以下其中一個處置方式：
   - **刪除**：文件已無用途，直接移除
   - **補充引用**：在適當的 `.md` 文件中補充指向該文件的相對路徑引用
   - **加入豁免清單**：文件有保留必要但不適合被引用，在 `scripts/validate-orphans.sh` 的豁免規則中新增對應條件
3. **關閉 Issue**：執行裁定的處置動作後，關閉對應的 GitHub Issue（若已建立）
