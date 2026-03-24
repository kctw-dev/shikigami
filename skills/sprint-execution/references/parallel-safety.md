# 平行執行安全防護（共用文件保護）

<!-- US-188 平行 subagent 禁止直接修改共用文件 — Sprint 72 -->
<!-- US-255 SHIKIGAMI_MAX_PARALLEL 平行數量上限控制 — Sprint 93 -->

## 共用文件限制規則

<HARD-GATE>
**平行 Story-Lifecycle subagent 禁止直接修改以下共用文件：**

- `docs/PROJECT_BOARD.md`
- `docs/sprints/sprint_N.md`（任何 sprint 文件）

**理由**：多個平行 subagent 同時寫入共用文件會造成競態條件（race condition），導致狀態不一致（如多個 subagent 各自讀取舊版並覆蓋彼此的更新）。
</HARD-GATE>

## 平行數量上限控制（SHIKIGAMI_MAX_PARALLEL）

<!-- US-255 低記憶體環境平行 Subagent 數量上限控制 — Sprint 93 -->
<!-- #536 平行 subagent OOM 防護 — Sprint 129 -->

環境變數 `SHIKIGAMI_MAX_PARALLEL` 控制 Sprint Execution 平行派遣 subagent 的最大數量，用於防止記憶體不足（OOM）。

**歷史依據**：Sprint 127 中 4 個 worktree 同時執行觸發 OOM core dump，確認安全上限為 2–3 個。

**預設值**：`SHIKIGAMI_MAX_PARALLEL` 未設定時，**預設視為 2**（不再無限制平行）。

| 環境變數值 | 行為 |
|-----------|------|
| 未設定 | **預設 2**：最多同時 2 個 subagent（OOM 防護預設值） |
| `1` | 強制循序執行：所有 Story 一個接一個執行，不出現平行派遣 |
| `N`（N ≥ 2） | 最多同時 N 個 subagent；超出部分排入下一批次依序執行 |

### 上限檢查規則（含現存 Worktree 計數）

Sprint Execution **派遣 subagent 前**，主 session 執行以下檢查：

```
讀取 SHIKIGAMI_MAX_PARALLEL 環境變數
  |-- 未設定 → 使用預設值 2（OOM 防護預設，#536 AC1）
  |-- = 1    → 強制循序：忽略 Architect 平行分群，所有 Story 單一循序執行
  +-- = N（N ≥ 2）
        |
        v
      計算現存 worktree 數量（重派前確認）
        EXISTING_WT=$(git worktree list | grep -v "bare\|main\|master" | wc -l)
        AVAILABLE_SLOTS=$((N - EXISTING_WT))
        |
        |-- AVAILABLE_SLOTS ≤ 0 → [OOM-WARN] 現存 worktree 已達上限（${EXISTING_WT}/${N}），
        |       等待現有 subagent 完成後再派遣（不阻塞主流程，進入等待循環）
        +-- AVAILABLE_SLOTS > 0
              |
              v
            取得本批次待派遣 Story 清單（Architect 分群的 Phase 1 Story）
              |-- 清單數 ≤ AVAILABLE_SLOTS → 全部同批次平行派遣
              +-- 清單數 > AVAILABLE_SLOTS → 拆分批次：
                    批次 1：前 AVAILABLE_SLOTS 個 Story 平行派遣
                    批次 2+：剩餘 Story 等待批次 1 完成後繼續（可再拆）
```

### Worktree 唯一性檢查（#537）

<!-- #537 重複派遣防護 Gate — Sprint 129 -->

Sprint Execution **派遣 Story-Lifecycle subagent 前**，必須執行 worktree 唯一性檢查，防止同一個 Story 被重複派遣：

```
取得現存 worktree 清單
  STORY_BRANCH="sprint-*/$(echo ${story_id} | tr '#' '' | tr -d ' ')-*"
  git worktree list --porcelain | grep "branch" | grep -q "${story_id}"
  |-- 找到對應 story_id 的 worktree → [DISPATCH-SKIP] 跳過，不重複派遣
  |     輸出：[DISPATCH-SKIP] Story #{id} 已有 worktree 存在（branch: {branch_name}），跳過重複派遣
  +-- 未找到 → 繼續後續派遣流程（OOM 上限檢查 → Claim → 派遣）
```

**重複偵測指令**：

```bash
# 偵測指定 story_id 是否已有 worktree 執行中
STORY_ID="537"  # 替換為實際 story_id
git worktree list --porcelain | grep -E "branch refs/heads/sprint-[0-9]+/${STORY_ID}-"
# 有輸出 → 重複，輸出 [DISPATCH-SKIP]；無輸出 → 可繼續派遣
```

**處理規則**：

| 情境 | 行為 |
|------|------|
| 偵測到同 Story worktree 存在 | `[DISPATCH-SKIP]` — 自動跳過（不重複派遣），記錄 WARN 日誌 |
| 未偵測到同 Story worktree | 繼續執行 OOM 上限檢查與後續派遣流程 |
| `git worktree list` 指令失敗 | 靜默忽略唯一性檢查，繼續派遣（保守策略：不阻塞） |

> **設計意圖**：自動跳過而非要求人工確認，避免在 `project_level=low` 的全自動場景中阻塞流程。若需手動清理殘留 worktree，參見 `references/worktree-cleanup.md`。

### Cruise Auto-Shoot 同任務防護

Cruise Auto-Shoot 派工前，必須先確認同任務 subagent 是否還在跑（重派前確認）：

```
取得現存 worktree 清單
  RUNNING_WT=$(git worktree list --porcelain | grep "branch" | grep "sprint-")
  |-- 若 story_id 對應的 branch 已存在於 worktree → [OOM-SKIP] 跳過重派（同 Story 已有 agent 執行中）
  |-- 現存 worktree 總數 ≥ MAX_PARALLEL → [OOM-WARN] 輸出告警，暫緩本次 auto-shoot
  +-- 現存 worktree 數 < MAX_PARALLEL → 繼續派遣
```

### 輸出格式

```
[MAX-PARALLEL] SHIKIGAMI_MAX_PARALLEL={N}，現存 worktree={E}，可用槽={S}，本次派遣批次數={B}
[MAX-PARALLEL-DEFAULT] SHIKIGAMI_MAX_PARALLEL 未設定，使用預設值 2（OOM 防護）
[OOM-WARN] 現存 worktree 已達上限（{E}/{N}），等待釋放後繼續
[OOM-SKIP] Story #{id} 已有 worktree 執行中，跳過重派
[DISPATCH-SKIP] Story #{id} 已有 worktree 存在（branch: {branch_name}），跳過重複派遣
```

## Git Worktree 隔離（#379）

Sprint Execution 派遣 Story-Lifecycle subagent 時，使用 Claude Code Agent tool 的 `isolation: "worktree"` 參數，讓每個 subagent 在獨立 git worktree 操作：

- 每個 subagent 自動獲得獨立的工作目錄副本
- 互不影響：subagent A 修改 SKILL.md 不會影響 subagent B
- worktree 自動清理：subagent 完成後，若有修改則回傳 worktree 路徑和 branch；無修改則自動清理
- 主 session 工作目錄不受 subagent 影響

> **worktree 隔離模式（#379）**：使用 `isolation: "worktree"` 時，
> 每個 subagent 在獨立工作目錄操作，共用文件衝突風險大幅降低。
> 但 PR merge 順序仍可能造成衝突，主 session 負責 merge conflict 解決。

## 主 session 批次更新機制

所有平行 subagent 完成後，**主 session 統一批次更新**：收集所有 PASS/FAIL/ESCALATE 結果 → 一次性讀取 `PROJECT_BOARD.md` 與 `sprint_N.md` → 依序套用狀態更新 → 單次 commit 提交。

## 適用範圍

| 執行模式 | 共用文件更新責任 |
|---------|---------------|
| 單一 Story 循序執行 | Story-Lifecycle subagent 可直接更新（無競態風險） |
| 多 Story **平行**執行 | 主 session 負責批次更新；subagent 禁止直接寫入共用文件 |

> **循序執行的 Story-Lifecycle subagent**（一次只有一個在執行）不受此限制，可依 §3 步驟 7 的流程直接更新共用文件。但當主 session 明確以平行方式派遣多個 subagent 時，所有平行執行的 subagent 均須遵守本限制規則。
