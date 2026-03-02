# Sprint 18

**狀態**：進行中
**Sprint Goal**：建立 Schedule Skill — 實現 Sprint 自動排程執行能力
**期間**：2026-03-02 ~ 2026-03-08

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | 狀態 |
|----------|------|------|--------|------|
| US-35（Issue #46） | Sprint 排程執行 + 權限 bypass 機制（shikigami:schedule） | L | 3 | 完成 |

**總計：1 Story / 3 Points**

---

## 退回 Backlog 說明

下列 Stories 原計畫於 Sprint 18 執行，因 Sprint 18 重新規劃（聚焦 Issue #46），退回 Backlog 待後續排期：

| Story ID | 標題 | 退回原因 |
|----------|------|---------|
| US-30（Issue #48） | PO subagent 多輪派遣時 Story 內容偏離修正機制 | Sprint 18 重新規劃，聚焦 Issue #46 |
| US-32（Issue #40） | parallel-dispatch 應內建同檔案衝突偵測與自動序列化 | Sprint 18 重新規劃，聚焦 Issue #46 |
| US-33（Issue #33） | Onboarding 缺少 BACKLOG_DONE.md 模板 | Sprint 18 重新規劃，聚焦 Issue #46 |
| US-34（Issue #32） | Onboarding 應預建常用 GitHub Labels | Sprint 18 重新規劃，聚焦 Issue #46 |

---

## Acceptance Criteria

### US-35（Issue #46）：Sprint 排程執行 + 權限 bypass 機制（shikigami:schedule）

**User Story**
As a framework user, I want to set up automated Sprint execution scheduling with a single command, so that Sprint cycles can run continuously without manual intervention, with proper permission bypass and pre/post QA gates ensuring safe and reliable automation.

**背景**
使用 `claude -p "/sprint-execution"` 搭配 cron 可實現自動化 Sprint 執行，但目前有兩個阻礙：(1) `-p` 模式下需手動指定權限模式，沒有框架層級安全 bypass 機制；(2) 框架沒有內建排程能力，使用者需自行撰寫 cron script + flock 鎖定。ADR-005 已 Accepted。

**QA 狀態**：AC 修訂完成（2026-03-02 QA 審查後修訂）

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 一行指令完成設定 | `/schedule <skill> --interval <duration>` 完成排程設定。`--interval` 接受 `1m` / `5m` / `15m` / `1h` 人類可讀格式，不接受 cron 表達式。成功時 stdout 輸出：(a) 生成的腳本路徑（`scripts/<skill-name>_cron.sh`）；(b) crontab 預覽行（完整 cron entry 字串） |
| AC2 | [靜態] | Pre-flight 阻擋 | QA Pre-flight 檢測環境（claude CLI 存在、認證有效、專案目錄可寫、目標 skill 已註冊、無重複排程），未通過則阻擋，不生成任何檔案 |
| AC3 | [靜態] | 腳本生成 | 自動生成腳本至路徑 `scripts/<skill-name>_cron.sh`（含 flock 互斥鎖 + allowedTools 白名單 + unset ANTHROPIC_API_KEY） |
| AC4 | [靜態] | 冪等 crontab | 冪等寫入 crontab，可重複執行不產生重複 entry |
| AC5 | [靜態] | Post-deploy 自動回滾 | QA Post-deploy 檢測以下項目，未通過則自動回滾：(a) crontab 項目已寫入（`crontab -l` 確認）；(b) 腳本存在且可執行（`test -x`）；(c) flock 配置正確（`grep flock -n` 存在）；(d) 腳本語法正確（`bash -n`）。回滾後期望系統狀態：crontab 無新 entry、腳本已刪除 |
| AC6 | [靜態] | `--remove` 移除排程 | `/schedule <skill> --remove` 從 crontab 移除對應 entry；若目標排程不存在，輸出警告訊息但正常退出（exit 0） |
| AC7 | [靜態] | `--dry-run` 只檢測 | `/schedule <skill> --dry-run` 只執行 Pre-flight 檢測，不部署任何檔案 |
| AC8 | [靜態] | Log 機制 | 每次排程執行有 log，路徑為 `logs/schedule-<skill>.log`（專案內 logs/ 目錄）；log 格式：START / SKIPPED（flock 被前一執行個體佔用時觸發）/ END + exit code；使用方式說明記載於 schedule SKILL.md，不需額外文件 |
| AC9 | [靜態] | docs 說明 | schedule SKILL.md 記載完整使用方式 |

**RICE 評分**

| 維度 | 分數 |
|------|------|
| Reach | 待定 |
| Impact | 待定 |
| Confidence | 待定 |
| Effort | 待定 |
| **RICE Score** | **待定** |

**MoSCoW**：Should / **Size**：L / **Points**：3
**來源**：GitHub Issue #46 / Stakeholder 優先
**ADR**：ADR-005（Accepted）
**依賴**：無前置阻塞（獨立可執行）

---

## 工作容量

| 指標 | 數值 |
|------|------|
| 計畫 Stories | 1 |
| 計畫 Points | 3（1L = 3pt） |
| 近 3 Sprint 平均 Velocity | 5.3pt（Sprint 15: 4、Sprint 16: 8、Sprint 17: 4） |
| Sprint 17 Velocity | 4pt |
| 緩衝率 | 57%（低於近三 Sprint 平均，保守容量） |

**容量決策說明**：
Sprint 18 重新規劃為單一 Story（US-35 / 3pt）。選入理由：
1. Issue #46（shikigami:schedule）已有 ADR-005 Accepted，技術方向確定
2. L size Story，集中資源確保品質
3. US-30/32/33/34 退回 Backlog，避免多線並行風險

---

## ADR 觸發清單

| Story | ADR | 狀態 |
|-------|-----|------|
| US-35 | ADR-005（shikigami:schedule 設計決策） | Accepted |

---

## Token 記錄

| 環節 | Token | 備註 |
|------|-------|------|
| Planning | 待補 | Sprint 18 Planning 完成後從 JSONL 提取（有效 input = input_tokens + cache_read_input_tokens + cache_creation_input_tokens） |
| Execution | 待補 | Sprint 18 Execution 完成後填入 |
| Review | 待補 | Sprint 18 Review 完成後填入 |
