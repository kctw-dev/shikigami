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

環境變數 `SHIKIGAMI_MAX_PARALLEL` 控制 Sprint Execution 平行派遣 subagent 的最大數量，用於低記憶體環境避免記憶體不足（swap thrashing）。

| 環境變數值 | 行為 |
|-----------|------|
| 未設定 | 不限制平行數量，維持現有行為（Sprint Planning Architect 決定的批次） |
| `1` | 強制循序執行：所有 Story 一個接一個執行，不出現平行派遣 |
| `N`（N ≥ 2） | 最多同時 N 個 subagent；超出部分排入下一批次依序執行 |

### 上限檢查規則

Sprint Execution **派遣 subagent 前**，主 session 執行以下檢查：

```
讀取 SHIKIGAMI_MAX_PARALLEL 環境變數
  |-- 未設定 → 不限制，依 Architect 分群建議直接平行派遣
  |-- = 1    → 強制循序：忽略 Architect 平行分群，所有 Story 單一循序執行
  +-- = N（N ≥ 2）
        |
        v
      取得本批次待派遣 Story 清單（Architect 分群的 Phase 1 Story）
        |-- 清單數 ≤ N → 全部同批次平行派遣（不超限）
        +-- 清單數 > N → 拆分批次：
              批次 1：前 N 個 Story 平行派遣
              批次 2+：剩餘 Story 等待批次 1 完成後繼續（可再拆）
```

### 輸出格式

```
[MAX-PARALLEL] SHIKIGAMI_MAX_PARALLEL={N}，本次派遣批次數={B}，每批最多 {N} 個 Story
[MAX-PARALLEL-SKIP] SHIKIGAMI_MAX_PARALLEL 未設定，不限制平行數量
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
