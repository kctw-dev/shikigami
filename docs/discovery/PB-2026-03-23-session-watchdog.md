# Product Brief: Session Watchdog（存活監控 + 自動重啟）

**PB ID**: PB-2026-03-23-session-watchdog
**狀態**: Draft
**建立日期**: 2026-03-23
**來源議題**: #362 GAD 研究報告 §三 Watchdog Pingpong
**相關 PB**: PB-2026-03-23-crash-recovery（Watchdog 偵測 crash，Crash Recovery 處理恢復邏輯）
**產品負責人**: PO Agent

---

## 1. 問題陳述

Shikigami 在執行長時 Cruise 或 Sprint 時，session 可能「無聲掛掉」（silent hang）：

- **無聲 hang**：agent 停止輸出但 session 沒有報錯，使用者不知道任務已停滯
- **發現延遲**：使用者可能幾十分鐘後才發現 session 已掛，這段時間完全浪費
- **無自動恢復**：即使使用者注意到 session 掛掉，也需要手動重啟並重新定位恢復點
- **長 Cruise 不可信賴**：跨多個 repo 的 Cruise（可能數小時）特別脆弱，一個 hang 就讓整個 Cruise 中止
- **缺乏 SLA**：沒有「session 必須在 X 分鐘內有輸出，否則視為異常」的機制

GAD 研究報告（#362）的 Watchdog Pingpong 概念：Watchdog 定期向 session 發 ping，session 必須在時限內回應，否則觸發重啟。

---

## 2. 目標使用者

**主要**：執行長時 Cruise（>1 小時）或長時 Sprint 的開發者，需要任務在背景自動進行
**次要**：需要 SLA 保證的企業使用者（「任務不能無聲掛掉超過 5 分鐘」）

使用場景：
- 夜間 Cruise：使用者睡覺時 Cruise 在背景跑，Watchdog 確保不無聲掛掉
- 長時 Sprint：Sprint 跑幾小時，Watchdog 偵測到 hang 後自動重啟並從 checkpoint 繼續
- CI/CD 整合：Shikigami 在 pipeline 中跑，Watchdog 確保 pipeline 不會因 agent hang 而永久卡住

---

## 3. 商業假設 [UNCERTAIN]

- [UNCERTAIN] 長時 session（>1 小時）中無聲 hang 的發生頻率至少每週 1–2 次（使用頻率夠高才值得實作）
- [UNCERTAIN] Watchdog 自動重啟可將 hang 造成的有效損失時間從「幾十分鐘（使用者發現前）」降低到「幾分鐘（Watchdog 偵測間隔）」
- [UNCERTAIN] Pingpong 機制的 false positive 率（誤判 session 已掛）可控制在 5% 以下
- [UNCERTAIN] 自動重啟後結合 Crash Recovery（PB-2026-03-23-crash-recovery），可實現近無損恢復

---

## 4. 提案解決方向

### 核心概念
在 session 外部（或 hook 層）建立 Watchdog 程序，定期向 session 發送 ping（heartbeat check），超時未回應則觸發重啟流程。

### Watchdog 工作流（草案）
```
Watchdog Loop（每 N 分鐘）:
  1. 發送 ping 到 session（透過 hook 或 IPC）
  2. 等待 pong 回應（session 回應「我還活著」+ 當前任務狀態）
  3. 若在 timeout 內收到 pong → 記錄 heartbeat，繼續監控
  4. 若 timeout 超過 → 標記 session 為 hung
  5. 觸發 restart：
     a. 記錄當前 checkpoint（如果 session 還能回應的話）
     b. 終止 hung session
     c. 啟動新 session 並從最近 checkpoint 恢復
```

### Pong 回應內容（草案）
```json
{
  "status": "alive",
  "current_task": "story-42-action-3",
  "last_progress_at": "2026-03-23T10:20:00Z",
  "estimated_completion": "2026-03-23T10:30:00Z"
}
```

### 方向 A：外部 Shell Watchdog
獨立 shell script / cron job，定期檢查 session 進程狀態（process alive check + output 活躍度）。最簡單，但無法做語義級 ping（只能知道進程存在，不知道是否真在工作）。

### 方向 B：Hook-based Heartbeat
在 agent 每次輸出後更新 heartbeat 文件，Watchdog 監控文件更新時間。Agent hang（停止輸出）時 Watchdog 偵測到 heartbeat 過期。

### 方向 C：MCP-based Pingpong（語義級監控）
透過 MCP server 實現雙向 ping/pong，agent 定期回報狀態（不只是「存活」，還有「任務進度」）。最完整，但需要 MCP server 修改。

推薦方向：**方向 B**（Hook-based Heartbeat，低侵入性，快速驗證假設），之後可升級到方向 C。

---

## 5. 成功指標

| 指標 | 基準線 | 目標 | 測量方式 |
|------|--------|------|----------|
| 無聲 hang 平均發現時間 | 待建立基準（估計 30+ 分鐘） | < 5 分鐘 | Watchdog 事件日誌 |
| Hang 後自動恢復成功率 | N/A（目前無自動恢復） | ≥ 80% | Watchdog 重啟統計 |
| False positive 重啟率（誤殺正常 session） | N/A | < 5% | Watchdog 事件日誌 |
| 長時 Cruise 完成率（>1 小時） | 待建立基準 | 提升 30% | Cruise 完成統計 |

---

## 6. 排除範圍

- 不實作分散式 Watchdog（多機器監控屬於另一個規模）
- 不處理 Watchdog 自身的高可用（Watchdog crash 屬於邊緣情況，暫不處理）
- 不涉及 session 效能監控（CPU/memory，此為基礎設施議題）
- 不強制所有 session 都啟用 Watchdog（opt-in，長時 session 才需要）

---

## 7. 依賴與風險

### 依賴
- Crash Recovery（PB-2026-03-23-crash-recovery）需要先建立，否則 Watchdog 重啟後無法恢復狀態，重啟意義有限
- Hook 機制需要支援「agent 每次輸出時更新 heartbeat 文件」（hooks.json 修改或新 hook type）
- 需要定義 `session-local` 目錄規範（heartbeat 文件存放位置）

### 風險
| 風險 | 可能性 | 影響 | 緩解策略 |
|------|--------|------|----------|
| Heartbeat timeout 閾值設定困難（太短誤殺，太長失去意義） | 高 | 中 | 提供可配置閾值，預設 10 分鐘，根據 Retro 反饋調整 |
| Watchdog 自動重啟打斷正在進行的關鍵操作（如 git push） | 中 | 高 | 在 side effect 操作前暫停 heartbeat 更新（或延長 timeout） |
| 方向 B 的 heartbeat 文件更新遺漏（某些 agent path 沒有更新） | 中 | 中 | Hook 覆蓋率測試，確保所有 agent 輸出路徑都觸發 heartbeat 更新 |
| 使用者覺得自動重啟行為不可預測，反而不信任 | 低 | 中 | 重啟前先通知（console 輸出），提供 dry-run 模式讓使用者驗證行為 |
