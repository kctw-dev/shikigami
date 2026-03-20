# ADR-025 — 探索紀錄收集機制

**日期**：2026-03-20
**狀態**：已採納
**作者**：Architect / US-#317 Phase 3

---

## 背景

老闆（Stakeholder）需要 AI 團隊績效可視化，其中包括探索紀錄（Web 搜尋與頁面擷取行為）。
目標是在 Claude Code 呼叫 WebSearch / WebFetch 時，自動記錄查詢與 URL，以提供可稽核的探索軌跡。

---

## 決策問題

如何在不影響正常工作流程的前提下，自動記錄 AI 的 Web 探索行為？

---

## 方案評估

| 方案 | 說明 | 優點 | 缺點 |
|------|------|------|------|
| **A（選定）** | PreToolUse hook 攔截 WebSearch/WebFetch | 零侵入，agent 無需感知 | 需 hook 支援 |
| B | Agent 在 Skill 中手動呼叫 log 指令 | 靈活 | 容易遺漏，需 agent 配合 |
| C | PostToolUse hook 攔截 | 同 A | 無法在工具呼叫前記錄意圖 |

---

## 決策：方案 A — PreToolUse Hook

### 觸發機制

在 `hooks/hooks.json` 的 `PreToolUse` 區塊新增 matcher：

```json
{
  "matcher": "WebSearch|WebFetch",
  "hooks": [
    {
      "type": "command",
      "command": "bash '${CLAUDE_PLUGIN_ROOT}/hooks/exploration-record.sh'",
      "async": true
    }
  ]
}
```

### 檔案格式

每次 WebSearch/WebFetch 呼叫 append 一筆 JSONL 到：
```
docs/exploration/YYYY-MM-DD-session-<session_id>.jsonl
```

JSONL 欄位：
```json
{
  "session_id": "<id>",
  "role": "scrum-master",
  "event": "explore",
  "timestamp": "<ISO8601>",
  "repo": "<repo>",
  "tool": "WebSearch|WebFetch",
  "query_or_url": "<查詢字串或 URL>"
}
```

### per-session 設計理由

沿用 US-319 的 per-session 命名模式：

- 每個 session 寫自己的檔案（`YYYY-MM-DD-session-<session_id>.jsonl`）
- 天然隔離，無需 flock
- AC3（跨機器不 conflict）自動滿足
- `session_id=unknown` 時用 `unknown-$(date +%s)` 避免覆寫

### 結算腳本

`hooks/exploration-settle.sh` 合併同日所有 per-session 檔案為：
```
docs/exploration/YYYY-MM-DD.summary.jsonl
```

行為：
- 掃描 `docs/exploration/<date>-session-*.jsonl`
- 合併並依 timestamp 排序
- 保留原始 per-session 檔案（保守策略）

### protect-main.sh 豁免

`docs/exploration/` 加入 `hooks/protect-main.sh` 豁免清單，允許探索紀錄直推 main（與出勤紀錄、Sprint 狀態文件一致）。

---

## 結果

- 探索紀錄自動收集，無需 agent 感知
- 跨機器無衝突（per-session 天然隔離）
- 每日可透過 `exploration-settle.sh` 彙整分析
- 與 ADR-024（出勤記錄）設計一致，降低維護複雜度
