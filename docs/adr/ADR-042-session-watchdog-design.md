# ADR-042: Session Watchdog — 存活監控與自動重啟設計

**狀態**：Accepted
**日期**：2026-03-24
**決策者**：Architect Agent
**觸發 Story**：#632（RESEARCH: ADR-042）
**Unblocks**：#408 feat: Session Watchdog — 存活監控 + 自動重啟

---

## 背景與問題

Shikigami 的 Scrum Master session 在長時間執行（Cruise Mode、長 Sprint）時，可能遭遇：

1. **無聲 Hang**：session 進程存活但 LLM 停止回應（API timeout、rate limit、context 過深）
2. **缺乏自動恢復**：目前只能手動重啟，且需要人工判斷「從哪裡繼續」
3. **與 Crash Recovery 的互補需求**：ADR-041 解決了「已知 crash 的恢復」，但沒有解決「偵測到 hang 後如何主動觸發恢復」

**相關 ADR 依賴**：
- **ADR-038（Kill Switch）**：已有 session 緊急停止機制（file-based flag），Watchdog 觸發重啟時需整合此機制
- **ADR-041（Crash Recovery）**：已定義恢復流程（Checkpoint + Side Effect Log），Watchdog 偵測 hang 後觸發此流程

參考：
- `docs/discovery/PB-2026-03-23-session-watchdog.md`
- `docs/adr/ADR-038-kill-switch-design.md`（Kill Switch）
- `docs/adr/ADR-041-crash-recovery-design.md`（Crash Recovery）
- Hook-based Heartbeat 模式（PB 推薦方向 B）

---

## 三種方案評估

### 方案 A：外部 Shell Watchdog（進程存活檢查）

獨立 shell script / cron job，定期檢查 session 進程狀態（`ps aux`、`/proc/<pid>/stat`）。

**優點**：最簡單，無 LLM 依賴
**缺點**：只知道進程存活，無法判斷 LLM 是否真在工作（semantic hang 無法偵測）
**結論**：可作為 L1 基礎層，但不足以單獨使用

### 方案 B：Hook-based Heartbeat（檔案時間戳監控）【選定核心】

在 agent 每次輸出後更新 heartbeat 文件（`docs/sprints/watchdog/session-{id}-heartbeat.json`）。外部 Watchdog 監控文件更新時間，超過閾值視為 hang。

**優點**：低侵入性（只需在 PostToolUse hook 寫文件）；可以區分 "LLM 正在思考" vs "真正 hang"
**缺點**：heartbeat 更新頻率受 tool call 頻率影響；長思考期間（> threshold）可能誤判
**結論**：**選定方案 B** 作為核心監控機制

### 方案 C：MCP-based Pingpong（語義級監控）

透過 MCP server 實現雙向 ping/pong，agent 定期回報進度。

**優點**：最完整，可知道「任務進度」不只是「存活」
**缺點**：需要 MCP server 修改，實作成本高，與現有 MCP 架構有整合複雜度
**結論**：長期演進方向，當前列為 Could

---

## 決策

### 決策 1：Watchdog 偵測機制 — Hook-based Heartbeat

**選定方案 B**（Hook-based Heartbeat）作為 Session Watchdog 的核心偵測層。

**Heartbeat 文件格式**：

```json
{
  "session_id": "string（SHIKIGAMI_SESSION_ID）",
  "sprint": "integer（當前 Sprint 編號，null 若無）",
  "story_id": "string（當前執行的 Story ID，null 若無）",
  "action": "string（最後執行的 tool 名稱）",
  "last_beat_at": "string（ISO8601，最後更新時間）",
  "started_at": "string（ISO8601，session 啟動時間）",
  "beat_count": "integer（累積 heartbeat 次數）"
}
```

**儲存路徑**：`docs/sprints/watchdog/session-{id}-heartbeat.json`
（與 TCB 分開管理，Watchdog 是 infrastructure 層）

**更新觸發**：每次 PostToolUse hook 觸發時更新（利用現有 PostToolUse hook 機制，ADR-038 已驗證）

### 決策 2：Hang 判定閾值

採用**漸進式閾值**策略，避免誤判：

| 閾值 | 行為 | 說明 |
|------|------|------|
| Heartbeat 超過 15 分鐘未更新 | `[WD-WARN]` 記錄警告，繼續監控 | LLM 可能在長時間思考 |
| Heartbeat 超過 30 分鐘未更新 | `[WD-HANG-DETECTED]` 標記 hang，觸發恢復流程 | 合理認定 session hung |
| 無 heartbeat 文件且 Sprint 進行中 | `[WD-NO-HEARTBEAT]` 靜默（session 可能不支援 Watchdog）| opt-in 機制 |

**配置覆蓋**（環境變數）：
```bash
SHIKIGAMI_WD_WARN_MINS=15      # 警告閾值（分鐘），預設 15
SHIKIGAMI_WD_HANG_MINS=30      # hang 判定閾值（分鐘），預設 30
```

### 決策 3：自動重啟流程 — 整合 ADR-038 + ADR-041

Watchdog 偵測到 hang 後，執行以下序列：

```
[WD-HANG-DETECTED] session={id}
  1. 觸發 Kill Switch（ADR-038）：停止 hung session
     bash hooks/kill-switch.sh trigger {session_id} --source watchdog --by watchdog-agent
     → 建立 .kill-switch/{session_id}.flag

  2. 等待 session 停止（最長 30 秒）
     輪詢 .kill-switch/{session_id}.flag 是否存在

  3. 觸發 Crash Recovery（ADR-041）：通知下次 session 從 checkpoint 恢復
     → 更新 docs/sprints/watchdog/session-{id}-restart-log.json
     → 記錄 restart_reason="watchdog-hang", last_heartbeat_at="{ts}"

  4. 清理 heartbeat 文件
     rm docs/sprints/watchdog/session-{id}-heartbeat.json

  5. [可選] 通知機制（opt-in）：
     若 SHIKIGAMI_WD_NOTIFY=true → 建立 GitHub Issue [WD-ALERT]
     → 格式：[Watchdog] Session {id} hang detected, auto-restart triggered
```

**重啟冷卻策略**：
- 同一 session 10 分鐘內連續重啟超過 3 次 → 停止重啟，升級為 `[WD-ESCALATE]`
- `[WD-ESCALATE]` 時建立 GitHub Issue 通知 Stakeholder（若 gh CLI 可用）

### 決策 4：與 ADR-038（Kill Switch）的整合點

| 整合場景 | Watchdog 行為 |
|---------|-------------|
| Kill Switch 已 active（人工觸發）| Watchdog 偵測到 flag → 停止監控，不額外觸發 |
| Watchdog 觸發重啟 | 呼叫 `kill-switch.sh trigger` + 在 restart log 記錄來源=watchdog |
| Session 正常結束 | SessionEnd hook 清理 Kill Switch（現有 hooks.json 已設定），Watchdog 偵測 heartbeat 停止 → 靜默 |

**分工邊界**：
- Kill Switch = 緊急停止訊號（人工或系統觸發）
- Watchdog = 自動化偵測 + 重啟協調層（利用 Kill Switch 作為停止機制）

### 決策 5：與 ADR-041（Crash Recovery）的整合點

| 整合層次 | 說明 |
|---------|------|
| Watchdog 觸發重啟後 | 下次 session 啟動時，Sprint Execution §3 的 Checkpoint 偵測自動找到未完成 Stories |
| Restart Log | Watchdog 寫入 `restart-log.json`，下次 session 可讀取了解重啟原因 |
| Side Effect Log 利用 | 新 session 啟動後，ADR-041 的 Guard-before-Execute 防止 side effect 重複 |

**整合流程圖**：
```
Session hang → Watchdog 偵測 → Kill Switch 停止
    ↓
用戶（或 cron）重啟 session
    ↓
Sprint Execution §3 讀取 sprint-checkpoint.json → [CHECKPOINT-RESUME]
ADR-041 Side Effect Log → 防止 git-commit/gh-pr-create 重複執行
    ↓
從斷點繼續執行
```

---

## 實作路線圖

| 順序 | 工作 | 依賴 |
|------|------|------|
| 1 | hooks/watchdog.sh（本 ADR → #408）| 本 ADR + ADR-038 + ADR-041 |
| 2 | PostToolUse hook 整合（寫 heartbeat）| hooks/hooks.json + #408 |
| 3 | Watchdog 排程（cron 或 SessionStart 觸發）| #408 |
| 4 | MCP-based Pingpong（方案 C 升級）| 長期，獨立 Story |

---

## 後果

**正面**：
- 長時 Cruise/Sprint session hang 問題有自動偵測與恢復機制
- 利用現有 Kill Switch + Crash Recovery 基礎設施，最小化新增程式碼
- opt-in 設計（無 heartbeat 文件時靜默），不影響不需要 Watchdog 的短 session

**負面**：
- Heartbeat 更新依賴 PostToolUse hook 頻率（tool call 稀少時可能誤判）
- 閾值需要根據實際使用調整（15/30 分鐘為初始估算值）
- Watchdog 本身的高可用未處理（Watchdog crash → 無監控，PB 明確排除範圍）

---

*ADR-042 由 Sprint 139 #632 RESEARCH Story 產出*
