# ADR-024：出勤時數機制 — SessionStart/End Hook JSONL 紀錄

**狀態**：Accepted
**日期**：2026-03-20
**決策者**：Architect（技術選型）+ QA Decision Challenger
**關聯 ADR**：ADR-007（Story Lifecycle Subagent）、ADR-022（檔案級鎖定）、ADR-023（PR-based Git Flow）
**關聯 Issue**：#317（出勤時數 Phase 2）
**觸發來源**：Sprint 107 — 出勤時數可視化需求

---

## 背景

### 問題陳述

Shikigami 框架目前無法追蹤 AI 角色的「工作時數」。在多 session 協作情境中，需要知道：

1. **哪些角色在哪些時段上線**
2. **每個 session 的簽到/簽退時間**
3. **出勤紀錄持久化**（不隨 session 結束消失）

### 現況

- SessionStart hook（`hooks/session-start`）：目前僅注入 scrum-master skill 內容到 context
- SessionEnd hook（`hooks/session-end-release.sh`）：目前僅處理 claim release 與 file lock release
- 無出勤紀錄機制

---

## 決策

### 選項評估

| 選項 | 描述 | 優點 | 缺點 |
|------|------|------|------|
| **A（選定）** | SessionStart/End hook 直接寫 JSONL | 零依賴、自動觸發、結構簡單 | 需要 flock 防止併發衝突 |
| B | MCP server 提供 attendance API | 集中管理、可查詢 | 需額外基礎設施 |
| C | Git commit 記錄出勤 | 天然版控 | 污染 commit history |

### 選定方案：方案 A（SessionStart/End hook JSONL）

**理由**：

1. **零依賴**：只需 bash + date + flock，所有平台皆支援
2. **自動觸發**：Hook 機制確保每次 session 必然記錄，無需手動呼叫
3. **結構清晰**：每日一個 JSONL 檔案，按時間順序 append，易於查詢
4. **與現有機制一致**：flock 已在 claim-issue.sh 中使用，模式熟悉

---

## 設計規格

### JSONL 格式

每行為一個獨立 JSON 物件：

```json
{"session_id":"abc123","role":"scrum-master","event":"checkin","timestamp":"2026-03-20T14:30:00+08:00","repo":"shikigami"}
{"session_id":"abc123","role":"scrum-master","event":"checkout","timestamp":"2026-03-20T16:45:00+08:00","repo":"shikigami"}
```

**必要欄位**：

| 欄位 | 說明 | 來源 |
|------|------|------|
| `session_id` | session 唯一識別碼 | `$CLAUDE_SESSION_ID`（預設 `unknown`） |
| `role` | AI 角色名稱 | 從 `$CLAUDE_SESSION_ID` 推斷，預設 `scrum-master` |
| `event` | `checkin` 或 `checkout` | SessionStart → checkin，SessionEnd → checkout |
| `timestamp` | ISO 8601 格式 | `date '+%Y-%m-%dT%H:%M:%S%z'` |
| `repo` | 倉庫名稱 | `git remote get-url origin` 取得，或 `basename` of `git rev-parse --show-toplevel` |

### 目錄結構

```
docs/attendance/
├── 2026-03-20.jsonl
├── 2026-03-21.jsonl
└── ...
```

- 每日一個檔案，檔名格式：`YYYY-MM-DD.jsonl`
- 使用 `flock` 防止多 session 同時 append 導致資料損壞

### Flock 策略

```bash
# 使用 -x（exclusive lock）+ -w 5（最多等 5 秒）
flock -x -w 5 200
echo '{"session_id":...}' >> "$JSONL_FILE"
```

Lock 檔案位置：`/tmp/shikigami-attendance-${REPO_FP}.lock`

---

## 狀態文件豁免

`docs/attendance/` 屬於狀態文件（自動生成、不涉及邏輯變更），加入 `hooks/protect-main.sh` 豁免清單：

- 現有豁免：`docs/sprints/**`、`docs/PROJECT_BOARD.md`
- 新增豁免：`docs/attendance/**`

---

## 影響

- **hooks/session-start**：新增出勤簽到邏輯（append checkin）
- **hooks/session-end-release.sh**：新增出勤簽退邏輯（append checkout）
- **hooks/protect-main.sh**：豁免清單新增 `docs/attendance/`
- **docs/attendance/**：新目錄，不自動 commit（Sprint 結束時批量 commit）

---

## 反決策

- **不使用 git commit 記錄**：出勤紀錄是高頻操作，每次 session 產生 2 個 commit，會污染 history
- **不使用 MCP server**：對於簡單的 append 操作，MCP server 過度設計
- **不加入 .gitignore**：出勤紀錄需要版控（Sprint 結束批量 commit），不應 ignore
