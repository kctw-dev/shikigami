# Sprint Live Log（演示模式 — US-269）

<!-- US-269 演示模式 Live Log Streaming — Sprint 99 -->

Sprint Execution 支援 **Live Log Streaming** 功能，讓使用者在另一個 terminal 視窗即時觀看 Story-Lifecycle subagent 的工作進度，適用於技術評估會議、客戶展示、新成員 Onboarding 等場合。

## 啟動方式

在另一個 terminal 視窗執行：

```bash
# 監看當前 session 的 live log（路徑含 session ID）
tail -f logs/live/$(date '+%Y-%m-%d')-session-${SESSION_ID:-unknown-*}.log

# 或使用萬用字元觀看當日所有 session
tail -f logs/live/$(date '+%Y-%m-%d')-session-*.log
```

> **跨平台說明**：`tail -f` 在 Linux、macOS、WSL 均原生支援。Windows 原生環境需使用 Git Bash 或 WSL。

## 日誌檔案路徑（US-322 AC-2，per-session）

```
logs/live/YYYY-MM-DD-session-<SESSION_ID>.log
```

每個 session 寫入自己的 `.log` 檔案（天然隔離，多台機器無 conflict）。結算腳本 `hooks/live-log-settle.sh` 合併同日日誌為 `YYYY-MM-DD.summary.log`。

每次 Sprint 可清除舊 session 檔案（保留 summary.log 歸檔）。

## 日誌格式範例

```
[18:15:01] [US-269] 開始執行
[18:15:05] [US-269] TDD Red — 開始
[18:15:45] [US-269] TDD Green — 開始
[18:16:10] [US-269] TDD Refactor — 開始
[18:16:23] [US-269] Spec Compliance Review — 開始
[18:16:30] [US-269] Spec Compliance Review — PASS
[18:16:31] [US-269] Code Quality Review — 開始
[18:16:40] [US-269] Code Quality Review — PASS
[18:16:41] [US-269] 結果：PASS
```

## 機制說明

- **可選機制**：日誌寫入為 Story-Lifecycle subagent 的附加行為，不影響既有 Sprint Execution 邏輯
- **容錯設計**：日誌寫入失敗時靜默忽略，不阻塞主流程
- **Token 成本**：日誌寫入使用 shell 指令（`echo >> 檔案`），不消耗主 session context window
- **實作位置**：日誌寫入指令定義於 `skills/sprint-execution/story-lifecycle-prompt.md` 各關鍵步驟
