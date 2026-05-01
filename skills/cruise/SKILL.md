---
name: cruise
description: "Use when starting cruise mode, automated patrol, periodic issue scanning, or background monitoring — enables PO patrol + SRE inspection loops"
requiredTools:
  - Read
  - Glob
  - Grep
  - Bash
---

# Cruise Mode Skill — PO 巡邏 + SRE 巡檢自動巡航

## 子模組索引

| 子模組 | 路徑 | 內容 |
|--------|------|------|
| PO 巡邏指引 | [references/po-patrol.md](./references/po-patrol.md) | Issue 掃描、處置決策表、Sprint 觸發、安全邊界 |
| SRE 巡檢指引 | [references/sre-inspection.md](./references/sre-inspection.md) | CI/CD 狀態、Runner 健康、VM 查證、Issue 建立 |
| Auto-shoot 派遣 | [references/auto-shoot.md](./references/auto-shoot.md) | 連續 shoot 派遣邏輯、失敗升級、log 類型 |
| Stop 機制 | [references/stop-mechanism.md](./references/stop-mechanism.md) | /cruise stop 指令、SessionEnd cleanup |
| Log 格式範例 | [references/log-format.md](./references/log-format.md) | JSONL 完整範例（單一 repo / 多 repo） |
| 啟動流程細節 | [references/startup-flow.md](./references/startup-flow.md) | §1–§6b 完整啟動與執行步驟（參數解析、Repo 偵測、Flag、Task List、Loop） |

## 觸發語法

```
/cruise              — 啟動巡航（Loop Mode，預設間隔 30 分鐘）
/cruise 10m          — 啟動巡航，指定間隔（例：10m, 15m, 60m）
/cruise strict     — 嚴格模式（0 天閾值，無回應立即標記）
/cruise 10m strict — 自訂間隔 + 嚴格模式
/cruise strict 10m — 同上（flag 位置無關）
/cruise --once       — Once Mode：跑一輪 PO+SRE 後自動退出（不進入 sleep loop）
/cruise --once strict — Once Mode + 嚴格模式
/cruise stop         — 停止巡航（Loop Mode 用）
```

### 模式說明

| 模式 | 觸發語法 | 行為 |
|------|---------|------|
| **Loop Mode**（預設） | `/cruise`、`/cruise 10m` | 長駐 loop，每隔指定間隔執行，直到 `/cruise stop` 或 Session 結束 |
| **Once Mode** | `/cruise --once` | 執行一輪 PO 巡邏 + SRE 巡檢，寫入 log，清除 flag，自動退出（不進入 sleep loop） |

**向後相容**：不帶 `--once` 的語法行為不變（Loop Mode）。

## 概覽

Cruise Mode 支援兩種執行模式：

- **Loop Mode**（`/cruise`）：在當前 Session 內持續執行 PO 巡邏與 SRE 巡檢，每隔指定間隔自動觸發一次，直到收到 `/cruise stop` 或 Session 結束為止。
- **Once Mode**（`/cruise --once`）：執行一輪 PO 巡邏與 SRE 巡檢後自動退出，不進入 sleep loop，適合搭配外部排程工具（如 cron）使用。

**參與 Agent**：PO Agent（巡邏）、SRE Agent（巡檢）
**執行模式**：Session 內 loop（sleep + flag file），參見 ADR-026
**Log**：per-session JSONL（`<LOG_BASE>/cruise-logs/YYYY-MM-DD-session-<SESSION_ID>.jsonl`）

### Multi-Repo 支援（#333）

| 模式 | 偵測條件 | 行為 |
|------|---------|------|
| **單一 repo** | 當前目錄含 `.git` | 與原行為完全相同（向後相容） |
| **多 repo** | 當前目錄不含 `.git`，但第一層子目錄有含 `.git` 的 | 對每個子 repo 分別執行 PO 巡邏 + SRE 巡檢 |

---

## 啟動流程（摘要）

> 完整步驟詳見 [references/startup-flow.md](./references/startup-flow.md)

### 執行路徑摘要

```
1. 解析參數（STRICT_MODE / ONCE_MODE / INTERVAL）
2. 偵測 Repo 列表（單一 repo 或多 repo 模式）
2.5. 驗證 Repo Remote（排除 local:* 或無效 GitHub remote）
3. 列出偵測結果
3.5. 自動清理 Stale Worktree（git worktree prune + orphan 目錄清除，#697）
4. 建立 Flag File（SESSION_ID 命名，互不干擾）
4.2. 建立 Sprint Stories Task List（{repo}/cruise-cycle-{N}）
4.5. 讀取 project_level（.claude/shikigami.local.md）
4.55. 讀取 cruise.patrol（po / sre / both）
4.6. 讀取 close_policy 與 delivery_chain
5. 準備 Log 目錄（docs/cruise-logs/）
6. 選擇執行模式 → Once Mode（§6a）或 Loop Mode（§6b）
```

## project_level 行為矩陣

<HARD-GATE>
project_level=low 的所有自動行為（auto-shoot、auto-close、auto-sprint-planning、auto-sprint-execution）為強制執行，Agent 禁止加入額外確認步驟。
</HARD-GATE>

| 行為 | low | medium（預設） | high |
|------|-----|---------------|------|
| auto-shoot | 自動派遣 invoke shikigami:shoot | 自動派遣 | 只標記，等人確認 |
| Sprint Planning | 自動 invoke shikigami:sprint-planning | 留言通知等確認 | 只標記 sprint-candidate |
| Issue close | 自動 close | 自動 close | 留言建議，等人確認 |

## Once Mode 執行摘要（`/cruise --once`）

> **預估執行時間（#2214 補注）**：`project_level=low` 時，Once Mode 會依序串聯完整 Sprint 週期（PO Patrol → Sprint Planning → Sprint Execution → Sprint Review），總時間約 **20-30 分鐘**。時間組成：PO 巡邏 + Issue 處理（~3 min）+ Sprint Planning（~5 min）+ Sprint Execution 每個 Story（~5-10 min/story）+ Sprint Review（~3 min）。**請勿中途中斷**，等待完成後再進行下一步。

```
CYCLE=1 → 寫入 cruise-init log
→ 依 PATROL_MODE 派遣 PO-patrol / SRE-inspection subagent
→ 等待完成，寫入 patrol-complete log
→ [AUTO-CONTINUE] project_level=low：auto-shoot ACTIONABLE_ISSUES
  ↳ sprint-candidate ≥ 3 → invoke sprint-planning（HARD-GATE）
  ↳ sprint-planning 完成 → invoke sprint-execution（HARD-GATE）
  ↳ sprint-execution 完成 → invoke sprint-review（常態）
  ↳ 全鏈式串聯：~20-30 分鐘（勿中途中斷）
→ 寫入 once-mode-complete + cruise-cleanup log
→ 清除 flag file，exit 0
```

## Loop Mode 執行摘要

```
寫入 cruise-init log
while flag file 存在:
  CYCLE += 1 → 依 PATROL_MODE 派遣 subagent
  → 等待完成，寫入 patrol-complete log
  → SHOOT_FLAG 殘留防護（>30分鐘強制清除）
  → Auto-shoot（詳見 references/auto-shoot.md）
  sleep INTERVAL_SECONDS
echo "[CRUISE] 巡航模式已停止"
```

> Sprint Planning 觸發由 PO subagent 自行執行（HARD-GATE，見 po-patrol.md Step 5）。

---

## Stop 機制

詳見 [references/stop-mechanism.md](./references/stop-mechanism.md)。

- `/cruise stop`：刪除 `$CRUISE_FLAG`（+ `$SHOOT_FLAG`），loop 在當前 cycle 完成後退出
- SessionEnd Hook：`hooks/session-end-release.sh` 自動清除兩個 flag file

---

## 跨機器考量（AC-5）

- **per-session Log 隔離**：每個 Session 寫入自己的 JSONL（`cruise-logs/YYYY-MM-DD-session-<ID>.jsonl`），避免 git conflict
- **多 repo 模式**：Log 統一寫入 group 目錄，不寫入各子 repo
- **Issue 重複防護**：SRE 建立 Issue 前先 `gh issue list --search`，冪等性覆蓋所有 Issue 類型
- **多 Session 同時 Cruise**：Flag file 以 SESSION_ID 命名，互不干擾

---

## Log 格式

Log JSONL 存放於 `<LOG_BASE>/cruise-logs/YYYY-MM-DD-session-<SESSION_ID>.jsonl`。

完整格式範例與 log entry 類型定義詳見 [references/log-format.md](./references/log-format.md)。
