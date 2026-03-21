# ADR-026：Cruise Mode — 巡航模式定期執行機制

**日期**：2026-03-21
**狀態**：Accepted
**相關 Issue**：#321
**提案者**：Architect Agent

---

## 背景

Sprint 111 引入 Cruise Mode — 一種可在當前 Session 內持續執行的 PO 巡邏 + SRE 巡檢機制。需要決定：

1. 定期執行機制（如何週期性觸發）
2. 停止機制（如何優雅退出）
3. 多 Agent 協作（PO 與 SRE 如何平行執行）
4. Log 儲存策略（如何在多機器環境下避免衝突）
5. Issue 重複建立防護

---

## 決策

### 決策 1：定期執行 — Session 內 loop（sleep + flag file）

**選擇**：Session 內 loop（不使用 CronCreate）

**理由**：
- Cruise Mode 是 Session 範圍的功能，Session 結束時應自動停止
- CronCreate 是跨 Session 的持久化機制，不適合 Cruise 的生命週期語意
- Sleep + flag file 的 loop 模式實作簡單，可在 Skill 內完整描述

**實作**：
```
建立 flag file → while 檢查 flag file 存在 → 執行巡邏/巡檢 → sleep <interval> → loop
```

### 決策 2：Stop 機制 — 刪除 flag file + SessionEnd hook 清理

**選擇**：
1. `/cruise stop` 指令：刪除 flag file → loop 在下次 flag 檢查時退出
2. SessionEnd hook (`session-end-release.sh`)：自動清除遺留的 cruise flag file

**Flag file 路徑**：`/tmp/shikigami-cruise-<SESSION_ID>.active`

**理由**：
- `/tmp` 是本機暫存，Session 結束後 OS 可能清理（Linux 重開機後）
- SessionEnd hook 確保即使 Session 異常中斷也能清理
- flag file 以 SESSION_ID 命名，多 session 各自獨立不衝突

### 決策 3：Subagent 派遣 — PO + SRE 平行執行（Task tool）

**選擇**：每個 loop cycle 平行派遣 PO Agent 與 SRE Agent

**理由**：
- PO 巡邏與 SRE 巡檢互相獨立，可同時執行節省時間
- 使用 Task tool 派遣，符合 Shikigami 多 Agent 協作架構

**實作**：
```
TaskCreate PO-patrol → TaskCreate SRE-inspection → 等待兩者完成 → 寫 log → sleep
```

### 決策 4：Log — per-session JSONL（docs/cruise-logs/）

**選擇**：每個 Session 獨立的 JSONL 檔案

**路徑格式**：`docs/cruise-logs/YYYY-MM-DD-session-<SESSION_ID>.jsonl`

**理由**：
- 遵循開發紅線第 8 條：共用檔案 append 會 git conflict
- per-session 檔案各自獨立，多台機器同時 cruise 不衝突
- JSONL 格式支援增量 append，每個巡邏/巡檢 cycle 追加一條記錄
- `docs/cruise-logs/` 需加入 protect-main.sh 豁免清單（狀態文件，可直推 main）

**Log 欄位**：
```json
{
  "session_id": "<SESSION_ID>",
  "cycle": <N>,
  "timestamp": "<ISO8601>",
  "type": "po-patrol|sre-inspection",
  "summary": "<摘要>",
  "actions": ["<action1>", "<action2>"]
}
```

### 決策 5：Issue 重複防護 — gh issue list --search

**選擇**：建立 Issue 前先搜尋同標題的 Issue 是否已存在

**實作**：
```bash
# SRE 建 Issue 前搜尋
EXISTING=$(gh issue list --search "<標題>" --state all --json number,title 2>/dev/null)
if [[ -z "$EXISTING" || "$EXISTING" == "[]" ]]; then
  gh issue create --title "<標題>" --body "<內容>"
fi
```

**理由**：
- 多 session 同時 cruise 可能偵測到同樣的問題
- 搜尋防護避免同一問題重複建立多個 Issue
- `--state all` 確保連已關閉的 Issue 也納入搜尋（問題可能已修復）

---

## 替代方案考量

| 方案 | 優點 | 缺點 | 決策 |
|------|------|------|------|
| CronCreate 定期觸發 | 持久化，跨 Session | 生命週期不符，清理麻煩 | 否決 |
| Session 內 loop + flag file | 簡單，生命週期一致 | 需 SessionEnd hook 清理 | 採用 |
| 共用 cruise.log 單一檔案 | 集中管理 | 多 session git conflict | 否決 |
| per-session JSONL | 無衝突，可 append | 結算需合併 | 採用 |

---

## 影響

1. **新增**：`skills/cruise/SKILL.md`
2. **新增**：`docs/cruise-logs/` 目錄
3. **修改**：`hooks/session-end-release.sh` — 追加 cruise flag cleanup
4. **修改**：`hooks/protect-main.sh` — 豁免 `^docs/cruise-logs/`
5. **新增**：`tests/test-cruise-skill.sh`
