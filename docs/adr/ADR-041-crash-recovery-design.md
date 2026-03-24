# ADR-041: Temporal-style Crash Recovery — Session 級別恢復設計

**狀態**：Accepted
**日期**：2026-03-24
**決策者**：Architect Agent
**觸發 Story**：#631（RESEARCH: ADR-041）
**Unblocks**：#405 feat: Temporal-style Crash Recovery

---

## 背景與問題

Shikigami 現有 sprint-checkpoint.json 以「Story」為最小恢復粒度。Session 意外中斷時：

1. **恢復粒度粗糙**：進行中的 Story 所有工作全部丟失，必須從頭重做
2. **Side effect 重複執行**：git commit、GitHub API 呼叫等在重啟後可能被重複觸發（破壞性）
3. **無自動化機制**：使用者必須手動告知 SM 從哪裡繼續，缺乏 Session 級別的自動恢復
4. **跨 session 狀態遺失**：決策脈絡與中間計算結果無法跨 session 傳遞

ADR-040（TCB Checkpoint）解決了 action 級記錄問題。本 ADR 定義基於 TCB 記錄之上的 **session 級恢復邏輯**，兩者分工明確：
- **ADR-040（TCB）**：提供細粒度 action 記錄（Who / What / When / Result）
- **本 ADR（Crash Recovery）**：提供重啟時如何利用 TCB 記錄恢復 session（How to recover）

參考：
- `docs/discovery/PB-2026-03-23-crash-recovery.md`
- `docs/adr/ADR-040-tcb-checkpoint-design.md`
- Temporal workflow replay 概念
- LangGraph MemorySaver checkpoint
- Microsoft Bulletproof Agents（at-least-once 執行保證 + idempotency）

---

## 三種恢復策略評估

### 策略 A：完整 Temporal-style（Event Sourcing + Replay）

每個 agent action 的輸入、LLM 輸出、決策以 append-only event log 記錄。重啟時 replay event log，使用已記錄的 LLM 輸出（不重新呼叫），實現確定性恢復。

**優點**：最完整，可精確重現任意時間點狀態
**缺點**：需設計 replay engine；LLM 輸出可能過大導致 log 膨脹；重啟時 replay 成本隨 log 長度線性增長
**結論**：長期演進方向，當前成本過高

### 策略 B：MemorySaver-style（Checkpoint Snapshot + Resume）

只記錄 Sprint 狀態快照（Checkpoint），不做 replay。重啟時從最近 checkpoint 載入整體狀態，跳過已完成部分。

**優點**：實作簡單，與現有 sprint-checkpoint.json 相容
**缺點**：Checkpoint 之間的工作仍有可能丟失；未解決 side effect 重複執行問題
**結論**：現有機制的延伸，但 side effect 重複是關鍵痛點，不足以單獨採用

### 策略 C：Hybrid（Checkpoint + Side Effect Log）【選定】

Checkpoint 記錄 Sprint/Story 狀態（沿用現有機制 + 整合 TCB），額外建立 Side Effect Log 記錄所有不可逆操作。重啟時：
1. 從最近 Checkpoint 恢復 Sprint 狀態
2. 查閱 Side Effect Log 跳過已執行的 side effect（idempotency guard）
3. 從斷點繼續未完成的 Action

**優點**：ROI 最高；解決最關鍵痛點（side effect 重複）；與 TCB/ADR-040 完全互補；實作成本可控
**缺點**：Side effect 分類需要明確盤點；不支援完整 event replay（Checkpoint 之間的 LLM 計算仍需重做）
**結論**：**選定策略 C**

---

## 決策

### 決策 1：Side Effect Log 格式

採用 **JSONL（JSON Lines）** 格式，與 TCB 格式對齊（ADR-040 決策 1）。

**Side Effect 定義（不可逆操作清單）**：

| 操作類型 | 分類 | 記錄觸發 |
|---------|------|---------|
| `git commit` | side_effect | 必記錄（commit hash 作為 idempotency key）|
| `git push` | side_effect | 必記錄（remote ref + commit hash）|
| `gh pr create` | side_effect | 必記錄（PR URL 作為 idempotency key）|
| `gh pr merge` | side_effect | 必記錄（merge commit hash）|
| `gh issue create` | side_effect | 必記錄（issue number 作為 idempotency key）|
| `gh issue close` | side_effect | 必記錄（issue number）|
| `gh issue edit` | side_effect | 可選記錄（冪等操作，重複執行影響小）|
| 文件生成（write file）| 冪等操作 | 不記錄（可重複，結果相同）|
| 讀取操作（read/list）| 查詢 | 不記錄（無 side effect）|

**JSONL Side Effect Log Schema**：

```jsonl
{
  "effect_id": "string（格式：{session_id}-{seq_num}，如 sess-abc123-se-01）",
  "session_id": "string（SHIKIGAMI_SESSION_ID）",
  "sprint": "integer",
  "story_id": "string（如 #404）",
  "tcb_id": "string（關聯的 TCB action ID，如有）",
  "effect_type": "string（enum: git-commit | git-push | gh-pr-create | gh-pr-merge | gh-issue-create | gh-issue-close | custom）",
  "idempotency_key": "string（操作的唯一識別，如 commit hash、PR URL、issue number）",
  "payload": "object（操作相關資訊，如 {\"pr_url\": \"...\", \"title\": \"...\"}）",
  "executed_at": "string（ISO8601）",
  "session_restart_count": "integer（本 session 重啟次數，0=第一次執行）"
}
```

### 決策 2：Side Effect Log 儲存位置

與 TCB 儲存策略對齊（ADR-040 決策 3）：

- 儲存路徑：`docs/sprints/tcb/sprint-{N}/session-{id}/side-effects.jsonl`
- 同屬 per-session 目錄，避免多機器 git conflict
- 加入 `.gitignore`（執行時臨時資料，不需版本控制）
- Sprint 結算後由 SM 統計 side effect 執行紀錄（後續 Story 負責實作）

### 決策 3：重啟偵測機制

重啟偵測透過 **Sprint Checkpoint + Session ID** 組合判斷：

```
重啟偵測流程（SM session 啟動時）：
1. 讀取 docs/sprints/sprint-checkpoint.json
2. 若 sprint 欄位與當前 Sprint 相符，且有 status=in-progress 的 Story → [RECOVERY-TRIGGER]
3. 讀取對應 session 的 side-effects.jsonl（若存在）
4. 在 action 執行前查詢 side-effects.jsonl，若 idempotency_key 已存在 → [SKIP-SIDE-EFFECT] 跳過
5. 從 sprint-checkpoint.json 記錄的 current_action 繼續執行
```

若 session_id 不存在（全新 session），side-effects.jsonl 查詢返回空集合，所有 action 正常執行。

### 決策 4：Idempotency Guard 實作

實作原則：**Guard-before-Execute**（先查詢 Side Effect Log，再執行操作）。

```bash
# Side Effect Guard 範例（SM/Developer 使用）
check_side_effect() {
  local effect_type="$1"
  local idempotency_key="$2"
  local se_log="docs/sprints/tcb/sprint-${SPRINT_NUM}/session-${SESSION_ID}/side-effects.jsonl"

  if [ -f "$se_log" ]; then
    if jq -e --arg key "$idempotency_key" '.idempotency_key == $key' "$se_log" > /dev/null 2>&1; then
      echo "[SKIP-SIDE-EFFECT] $effect_type already executed: $idempotency_key"
      return 1  # Already executed, skip
    fi
  fi
  return 0  # Not executed, proceed
}

record_side_effect() {
  local effect_type="$1"
  local idempotency_key="$2"
  local se_log="docs/sprints/tcb/sprint-${SPRINT_NUM}/session-${SESSION_ID}/side-effects.jsonl"

  mkdir -p "$(dirname "$se_log")"
  printf '%s\n' "{\"effect_type\":\"$effect_type\",\"idempotency_key\":\"$idempotency_key\",\"executed_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$se_log"
}
```

### 決策 5：與 ADR-040（TCB）的分工邊界

| 層次 | ADR-040（TCB）| 本 ADR（Crash Recovery）|
|------|-------------|----------------------|
| 記錄粒度 | Action 級（高成本/副作用 action）| Side Effect 級（不可逆操作）|
| 記錄時機 | Action 開始前與完成後 | Side effect 執行後（Guard 通過後）|
| 恢復功能 | 提供「哪個 action 已完成」的狀態 | 提供「哪個 side effect 已執行」的去重 |
| 依賴關係 | 獨立（不依賴 Crash Recovery）| 建立在 TCB 記錄之上（讀取 TCB 確認 action 狀態）|
| 儲存位置 | `tcb/sprint-N/session-{id}/{story_id}/` | `tcb/sprint-N/session-{id}/side-effects.jsonl` |
| 觸發機制 | hooks/tcb-write.sh（#404 實作）| hooks/side-effect-guard.sh（#405 實作）|

**整合流程**：
```
Action 開始 → TCB 記錄 status=running
  → 若 action 含 side effect → Guard-before-Execute
    → [SKIP] side effect 已記錄 → 跳過，從 TCB 讀取已記錄的 output_ref
    → [PROCEED] 執行 side effect → 記錄至 side-effects.jsonl → TCB 更新 status=completed
```

---

## 實作路線圖

本 ADR 為 #405（Temporal-style Crash Recovery 實作）定義架構基礎。實作 Story 應依下列順序進行：

| 順序 | 工作 | 依賴 |
|------|------|------|
| 1 | hooks/tcb-write.sh（ADR-040 → #404）| ADR-040 |
| 2 | hooks/side-effect-guard.sh（本 ADR → #405）| #404（TCB hook）+ 本 ADR |
| 3 | SM 重啟偵測邏輯整合（#405）| #404 + 本 ADR |
| 4 | Session Watchdog 觸發 recovery（ADR-042 → #408）| #405 + ADR-042 |

---

## 後果

**正面**：
- Side effect 重複執行問題被根本性解決（最常見的危害性 crash 後果）
- 與現有 sprint-checkpoint.json 完全相容（補充不替代）
- 與 TCB（ADR-040）形成完整的恢復保障體系
- 實作成本可控（2 個新 shell script + SM 邏輯修改）

**負面**：
- Checkpoint 之間的 LLM 計算在重啟後仍需重做（非完整 event replay）
- Side effect 分類清單需要維護（新增操作類型時需更新）
- session_id 管理依賴環境變數 SHIKIGAMI_SESSION_ID（需確保每個 session 有唯一 ID）

---

*ADR-041 由 Sprint 139 #631 RESEARCH Story 產出*
