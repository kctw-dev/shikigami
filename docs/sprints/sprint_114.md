# Sprint 114

**Sprint Goal**：Cruise Mode 穩定性與可用性改善 — SRE org-level runner + 嚴格模式
**日期**：2026-03-22
**容量**：3 points
**狀態**：已完成

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| FIX：SRE 巡檢 org-level runner API 預設 | #325 | S | 1 | 完成 |
| FEATURE：Cruise --strict 嚴格模式 | #326 | S | 2 | 完成 |

## Acceptance Criteria

### #325 — SRE 巡檢 org-level runner API 預設（S, 1pt）

> **Type**：FIX
> **修改範圍**：skills/cruise/SKILL.md（SRE 巡檢 Runner 健康檢查 section）
> **Architect 備注**：org-level API 優先，fallback repo-level（個人帳號 repo 無 org）；需 `admin:org` scope 前置條件提示

**AC-1：Runner 查詢改為 org-level 優先**
- SRE 巡檢的 Runner 健康檢查改用 `gh api /orgs/{org}/actions/runners`
- 若 org API 失敗（403 或 404），fallback 到 `gh api /repos/{owner}/{repo}/actions/runners`
- fallback 時 log 提示「org-level API 不可用，fallback 至 repo-level」

**AC-2：org 名稱自動偵測**
- 從 `gh repo view --json owner` 取得 owner
- 用 `gh api /orgs/{owner}` 判斷是否為 org（非 User）
- 若為 User → 直接走 repo-level，不嘗試 org API

**AC-3：前置條件提示**
- SKILL.md Runner 健康檢查 section 加註：「需 `admin:org` scope 才能查詢 org runner」
- 若權限不足（403），fallback 並在 log 中提示 scope 需求

**AC-4：測試覆蓋**
- 驗證 SKILL.md 中包含 org-level API 呼叫
- 驗證 fallback 邏輯存在
- 驗證前置條件文字存在

### #326 — Cruise --strict 嚴格模式（S, 2pt）

> **Type**：FEATURE
> **修改範圍**：skills/cruise/SKILL.md（觸發語法 + 參數解析 + PO 巡邏判斷邏輯）
> **Architect 備注**：--strict flag 解析加入 §1 參數解析；閾值參數化（THRESHOLD_DAYS）；預設 3 天，--strict 為 0 天

**AC-1：觸發語法擴充**
- 支援 `/cruise --strict`（嚴格模式，0 天閾值）
- 支援 `/cruise 10m --strict`（自訂間隔 + 嚴格模式）
- 語法文檔更新至 SKILL.md 觸發語法 section

**AC-2：--strict flag 解析**
- 參數解析階段偵測 `--strict` flag
- 設定 `STRICT_MODE=true`（預設 false）
- flag 與間隔參數位置無關（`--strict 10m` 或 `10m --strict` 皆可）

**AC-3：閾值參數化**
- 新增 `THRESHOLD_DAYS` 變數
- 預設模式：`THRESHOLD_DAYS=3`
- 嚴格模式：`THRESHOLD_DAYS=0`
- PO 巡邏「無回應 Issue」判斷改用 `THRESHOLD_DAYS` 替代硬編碼 3

**AC-4：嚴格模式行為**
- `--strict` 時，無 assignee + 無留言 = 立即視為「無回應」（0 天閾值）
- `--strict` 時，巡邏 log 輸出標示 `"strict": true`

**AC-5：測試覆蓋**
- 驗證 SKILL.md 觸發語法包含 `--strict`
- 驗證 `THRESHOLD_DAYS` 參數化邏輯存在
- 驗證 strict 模式 log 格式包含 strict 欄位

## 技術評估摘要

### Architect 備注

- **#325**：org-level API 優先 + repo-level fallback，偵測 owner 類型（org vs user）決定路徑
- **#326**：--strict flag 解析 + THRESHOLD_DAYS 參數化，預設 3 / strict 0
- **共同修改**：`skills/cruise/SKILL.md`，兩個 Story 修改不同 section，無衝突
- **不需 ADR**：行為微調，不改變架構決策
- **跨機器安全**：兩者都只修改 SKILL.md（框架定義檔），無 per-session 資料問題

### QA 備注

- **所有 AC 可驗證**
- #325 AC-1~AC-3：結構型（SKILL.md 內容檢查 org API + fallback + scope 提示）
- #325 AC-4：測試執行型
- #326 AC-1~AC-2：結構型（語法文檔 + flag 解析邏輯）
- #326 AC-3~AC-4：行為型（THRESHOLD_DAYS 參數化 + strict log 格式）
- #326 AC-5：測試執行型
- **DoR**：PASS
- **防漂移基準**：2 Stories, 3 pts

---

## Sprint Review（2026-03-22）

### §1 Demo

- **#325 SRE org-level runner API**：`skills/cruise/SKILL.md` Runner 健康檢查改為 org-level 優先（`gh api /orgs/{org}/actions/runners`），自動偵測 owner 類型（org vs user），fallback 至 repo-level 並提示 `admin:org` scope 需求
- **#326 Cruise --strict 嚴格模式**：觸發語法擴充（`/cruise --strict`、`/cruise 10m --strict`、`/cruise --strict 10m`），flag 解析位置無關，`THRESHOLD_DAYS` 參數化（預設 3 / strict 0），PO 巡邏使用 `THRESHOLD_DAYS` 替代硬編碼

### §2 QA 結果

| Story | 外部抽樣 | 結果 |
|-------|---------|------|
| #325 | 9/9 AC | PASS |
| #326 | 40/40 AC | PASS |

- **外部抽樣比例**：100%（#326 較大修改為主要抽樣對象）
- **DISPUTE**：0 項

### §2.6 Issue 狀態

- #325 → CLOSED
- #326 → CLOSED

### §3 Retrospective

**Good**：
- Cruise Mode 兩個改善快速落地（org-level runner + strict 模式），SKILL.md 單檔修改零衝突
- `THRESHOLD_DAYS` 參數化設計清晰，flag 位置無關解析優雅

**Problem**：無

**Action Item**：無

---

## Sprint Metrics

- **Velocity**：3 pts
- **完成率**：100%（2/2 Stories）
- **DISPUTE 率**：0%
- **版本**：v0.78.3 → v0.78.4（patch）
