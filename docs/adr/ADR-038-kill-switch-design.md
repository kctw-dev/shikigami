# ADR-038: Kill Switch — 高自治模式緊急停止機制設計

**狀態**：Accepted
**日期**：2026-03-24
**決策者**：Architect Agent
**觸發 Story**：#619（RESEARCH: ADR-038）
**Unblocks**：#398 feat: Kill Switch — High 自治模式緊急停止

---

## 背景與問題

Shikigami 在 `project_level=high`（高自治模式）下，多個 subagent 在近無人監督的環境中長時間並行執行。目前缺乏緊急介入手段，當以下情況發生時無法即時停止：

- Security 角色偵測到 CRITICAL 風險行為（如 prompt injection 成功）
- Agent 執行方向偏離 Stakeholder 預期
- 執行時間超過預設上限，疑似進入無限迴圈

業界 AI Governance 研究（2026）指出 Kill Switch 為核心基礎設施。本 ADR 為 #398 實作提供架構決策基礎。

參考：`docs/discovery/PB-2026-03-23-kill-switch.md`

---

## 決策

### 決策 1：訊號傳遞機制 — File-based Flag

**選擇**：File-based flag（`$REPO_PATH/.kill-switch/{session_id}.flag`）

**評估選項**：

| 選項 | 優點 | 缺點 |
|------|------|------|
| A. File-based flag | 無 LLM 依賴、在 LLM 失控時仍有效、跨 subagent 可見、atomic write | 需 polling，輕微延遲 |
| B. GitHub Issue label | 可遠端觸發、有稽核軌跡 | 依賴 gh CLI 與網路，LLM 失控時可能失效 |
| C. Environment variable | 零依賴 | 無法動態廣播至已啟動的 subagent |

**理由**：Kill Switch 機制不得依賴 LLM 執行（PB §4 設計原則）。File-based 為唯一在 LLM 失控時仍可靠的方案。多機器多 session 場景下，flag 檔以 session_id 隔離，符合 CLAUDE.md 紅線 8。

**Flag 路徑**：`$REPO_PATH/.kill-switch/{session_id}.flag`
**Flag 格式**（JSON）：
```json
{
  "triggered_at": "ISO8601",
  "trigger_source": "manual | security-critical | timeout",
  "session_id": "...",
  "triggered_by": "stakeholder | security-agent | cron"
}
```

---

### 決策 2：Kill Switch 啟動條件

**三種觸發來源**：

| 來源 | 觸發方式 | 說明 |
|------|---------|------|
| 手動（Stakeholder） | 執行 `bash hooks/kill-switch.sh trigger {session_id}` | 任意時間點觸發，最高優先 |
| 自動（Security Agent） | Security self-review 回傳 `ESCALATE: SECURITY_CRITICAL` | Sprint Execution §8.1 已定義此升級路徑 |
| 自動（Timeout） | 執行時間超過 `SHIKIGAMI_MAX_EXECUTION_MINUTES`（預設 60 分鐘） | Cron 或 session-start hook 監控 |

**Polling 間隔**：各 subagent 每完成一個原子操作後檢查一次 flag（非定時輪詢，以原子操作為單位），確保 Graceful shutdown。

**SLA**：Kill Switch 觸發後，所有 subagent 在 30 秒內完成安全停止。

---

### 決策 3：停止後狀態報告格式

**Emergency Stop Report 路徑**：`$REPO_PATH/.kill-switch/{session_id}-report.json`

**格式**：
```json
{
  "session_id": "...",
  "triggered_at": "ISO8601",
  "trigger_source": "manual | security-critical | timeout",
  "stories_status": [
    {
      "story_id": "#N",
      "status": "completed | in-progress-stopped | pending-skipped",
      "last_action": "描述最後執行的原子操作",
      "worktree_path": "...",
      "branch": "sprint-N/storyN"
    }
  ],
  "snapshot_path": ".kill-switch/{session_id}-snapshot/",
  "resume_possible": true,
  "notes": "人可讀的停止摘要"
}
```

**狀態快照**：每個 stopped story 的 worktree 狀態保留（不自動刪除），路徑記錄於 report，供後續手動恢復或重跑使用。

**斷點續跑（此版本為可選 / PoC 階段）**：`resume_possible: true` 表示 worktree 完整，理論上可恢復；實際恢復流程不在本 ADR 定義範圍（PB §6「排除範圍」，後續 ADR 定義）。

---

### 決策 4：`.kill-switch/` 目錄管理

- 目錄加入 `.gitignore`（session 本地暫存，不進 repo）
- SessionEnd hook 在正常完成後自動清理 flag 與 snapshot（保留 report 供稽核）
- Report 保留至下次 Sprint Planning 開始，可選擇 archive 至 `docs/km/kill-switch-log/`

---

## 實作指引（給 #398 Developer）

1. 建立 `hooks/kill-switch.sh`：支援 `trigger {session_id}` / `check {session_id}` / `report {session_id}` 三個子命令
2. 在 `hooks/session-start/` 加入 kill-switch 目錄初始化邏輯
3. 在 Sprint Execution §3 flow 的每個 Story-Lifecycle subagent 回傳後，插入 kill-switch flag 檢查
4. 在 story-lifecycle-prompt.md 加入「原子操作完成後檢查 `.kill-switch/{session_id}.flag`」指引
5. 將 `.kill-switch/` 加入 `.gitignore`

---

## 後果

**正面**：
- 提供可靠的緊急停止能力，不依賴 LLM（在 LLM 失控時仍有效）
- File-based 方案與現有 hooks 架構一致（`hooks/claim-issue.sh` 採用相似模式）
- 狀態報告格式支援後續 AI Governance 稽核需求

**負面 / 風險**：
- Polling 以原子操作為單位，若原子操作耗時（> 30 秒），SLA 可能無法保證 → 後續需在 story-lifecycle-prompt.md 定義「原子操作最大耗時」
- 斷點續跑為 PoC 階段，此版本不保證 → 文件明確標注 `resume_possible` 為「理論可行」

---

## 相關文件

- `docs/discovery/PB-2026-03-23-kill-switch.md`
- `skills/sprint-execution/SKILL.md` §8.1（Security 升級路徑）
- ADR-034（Browser Automation，已 Accepted，非本 ADR 依賴）
- #398 feat: Kill Switch — High 自治模式緊急停止（待實作）
