# ADR-028：多 Sprint 觀測 — 多 Runner 統一觀測方案

**日期**：2026-03-21
**狀態**：Accepted
**相關 Issue**：#323
**提案者**：Architect Agent

---

## 背景

US-#323 引入 GitHub Actions Runner 動態 Sprint 派遣後，可能出現多台 CI Runner 對不同 repo 同時跑 Sprint 的情境。需要決定：

1. **如何從外部觀測** Sprint 執行狀態（不在 Runner 上直接看）
2. **多 Runner 的統一視圖**：多個 Runner 各自執行，如何在單一位置看到全局狀態
3. **Layer 設計**：觀測層的隔離性（任一觀測層失敗不影響 Sprint 主流程）

---

## 選項評估

### 選項 A：GitHub Actions UI

利用 GitHub Actions 原生 UI（每次 workflow run 的 Job Log）作為主要觀測入口。

**優點**：
- 零額外實作成本，GitHub 原生功能
- 每個 Runner 的 Log 在 Actions UI 中天然隔離
- stdout 標記（`[SHIKIGAMI] event=...`）在 Actions Log 中直接可見
- 支援 Filter 搜尋 `[SHIKIGAMI]` 標記

**缺點**：
- 需要進入每個 workflow run 才能看完整 Log
- 無法在單一頁面看到跨 repo 的 Sprint 狀態

**結論**：採用（方案 A）

### 選項 B：Slack / Discord 通知

每個關鍵事件發送 Slack/Discord 訊息。

**優點**：即時推播通知
**缺點**：
- 需要 Slack/Discord 整合
- 通知量大時容易噪音
- 無狀態，不易追溯

**結論**：否決（運維複雜度 + 噪音問題）

### 選項 C：中央儀表板（單獨服務）

建立專用的 Sprint 監控儀表板服務。

**優點**：統一視圖，可視化程度高
**缺點**：需要額外服務，維護成本極高，超出 Shikigami 框架範疇

**結論**：否決（過度設計，超出範疇）

### 選項 D：中央 Issue 留言

選定一個 GitHub Issue 作為「Sprint 觀測中央」，每個 Runner 的關鍵事件以 `gh issue comment` 留言。

**優點**：
- 單一 Issue 可聚合來自多個 Runner、多個 repo 的 Sprint 事件
- GitHub Issue 為 opt-in（設 `SHIKIGAMI_LIVE_NOTIFY=true` + `SHIKIGAMI_LIVE_NOTIFY_ISSUE=N`）
- 不影響 Sprint 主流程（`|| true` failure isolation）
- 免費，無需額外服務

**缺點**：
- 需要 `gh` CLI + 適當 token
- Issue 留言可能過多時較難閱讀

**結論**：採用（方案 D），搭配方案 A 組合使用

---

## 決策

### 決策：Actions UI（A）+ 中央 Issue 留言（D）組合

**三層觀測架構（US-#323 AC-4/5/6）**：

| 層 | 名稱 | 機制 | 特性 |
|----|------|------|------|
| Layer 1 | stdout 標記 | `echo "[SHIKIGAMI] event=..."` | 零成本，Actions Log 天然收集 |
| Layer 2 | per-session log push | `if: always()` step commit + push | 持久化，Runner 結束後仍可查閱 |
| Layer 3 | Issue 留言 | `gh issue comment`（opt-in） | 多 Runner 統一聚合，跨 repo 可見 |

### Layer 1：stdout 標記格式

```
[SHIKIGAMI] event=story_start story=<id>
[SHIKIGAMI] event=story_end story=<id> status=PASS|FAIL
[SHIKIGAMI] event=sprint_end
```

所有標記輸出至 stdout，GitHub Actions Log 天然收集，無需額外配置。

### Layer 2：per-session log push

Workflow step 4（`if: always()`）：
```yaml
- name: Push session logs
  if: always()
  run: |
    git add docs/sprints/live-log/
    git commit -m "ci: push session logs [run=...]" || true
    git push origin HEAD || true
```

### Layer 3：Issue 留言 opt-in

```
環境變數：
  SHIKIGAMI_LIVE_NOTIFY=true          # 開啟 Issue 留言
  SHIKIGAMI_LIVE_NOTIFY_ISSUE=<N>     # 目標 Issue 號碼
```

**多 Runner 統一觀測**：
- 多個 Runner 同時執行時，各自發送 story_start / story_end 留言至同一 Issue
- 留言時間戳自然排序，可觀察跨 repo Sprint 的事件序列
- `|| true` 確保 gh CLI 失敗（token 未設定、網路問題）不阻塞 Sprint

### Failure Isolation 原則（AC-7）

```
Layer 1 失敗 → 不影響 Layer 2、Layer 3、Sprint 主流程
Layer 2 失敗 → 不影響 Layer 1、Layer 3、Sprint 主流程
Layer 3 失敗 → 不影響 Layer 1、Layer 2、Sprint 主流程
任一 Layer 失敗 → 不影響 Sprint 主流程
```

所有觀測操作加 `|| true`（Bash）或 `2>/dev/null || true`（靜默錯誤 + 繼續）。

---

## 影響

1. **新增**：`.github/workflows/sprint-dispatch.yml` — Layer 2 push step（`if: always()`）
2. **修改**：`skills/sprint-execution/story-lifecycle-prompt.md` — 步驟 8（Layer 1 + Layer 3）、§9.0（Layer 1 + Layer 3）
3. **修改**：`skills/sprint-execution/SKILL.md` — sprint_end 標記（Layer 1）
4. **docs/sprints/live-log/**：per-session 路徑已在 protect-main.sh 豁免清單，可直推 main

---

## 替代方案考量

| 方案 | 優點 | 缺點 | 決策 |
|------|------|------|------|
| Actions UI（A） | 零成本，原生支援 | 多 Runner 無統一視圖 | **採用** |
| Slack/Discord（B） | 即時推播 | 需整合，噪音問題 | 否決 |
| 中央儀表板（C） | 統一視圖 | 過度設計，超出範疇 | 否決 |
| 中央 Issue 留言（D） | 統一聚合，免費 | Issue 留言數量可能多 | **採用**（A+D 組合） |
