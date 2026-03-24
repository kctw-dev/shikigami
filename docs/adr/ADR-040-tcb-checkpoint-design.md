# ADR-040: TCB 斷點管理 — Agent Action 級 Checkpoint 設計

**狀態**：Accepted
**日期**：2026-03-24
**決策者**：Architect Agent
**觸發 Story**：#621（RESEARCH: ADR-040）
**Unblocks**：#404 feat: TCB 斷點管理 — Agent Action 級 Checkpoint

---

## 背景與問題

Shikigami 現有 Sprint checkpoint 機制（`sprint-checkpoint.json`）以 Story 為最小粒度。長時間 Sprint（> 2 小時、> 5 個 Story）中斷時，整個 Story 必須重做，造成 token 浪費。

Self-Manager 論文（arxiv）的 TCB（Thread Control Block）概念：每個 agent task 有獨立 control block，記錄狀態、依賴、輸入輸出，支援細粒度暫停與恢復。

本 ADR 為 #404 實作定義：
1. Agent Action 級 checkpoint 格式（TCB schema）
2. checkpoint 儲存位置與命名
3. 恢復策略
4. 與 Scrum Master 狀態圖的整合介面

參考：`docs/discovery/PB-2026-03-23-tcb-checkpoint.md`

---

## 決策

### 決策 1：Agent Action 級 Checkpoint 格式（TCB Schema）

採用 PB 推薦的**方向 B（關鍵路徑 TCB）**：只記錄高成本或有副作用的 action，低成本 action 不記錄，降低寫入開銷。

**TCB 記錄觸發條件（關鍵路徑 action 定義）**：

| Action 類型 | 記錄觸發條件 |
|-----------|------------|
| git commit / push | 必記錄（有副作用，不可重複） |
| gh pr create / merge | 必記錄（外部 API，不可重複） |
| 文件生成（ADR / Sprint doc / Meeting notes） | 必記錄（高成本輸出） |
| LLM 分析輸出（>500 token 輸出） | 必記錄（高成本，可快取） |
| 驗證腳本執行（validate-*.sh） | 選記錄（低成本，可重跑） |
| git checkout / worktree 操作 | 不記錄（低成本，冪等） |

**TCB JSON Schema**（遵循 JSON Schema Draft 2020-12，與 ADR-036 對齊）：

```json
{
  "tcb_id": "string（格式：{story_id}-{action_seq}，如 617-act-3）",
  "story_id": "string（如 #617）",
  "sprint": "integer（如 137）",
  "session_id": "string（從 SHIKIGAMI_SESSION_ID 讀取）",
  "agent": "string（developer | architect | qa | po | scrum-master）",
  "action": "string（描述此 action，如 git-commit | gh-pr-create | doc-generate）",
  "status": "string（enum: pending | running | completed | failed | skipped）",
  "depends_on": "array of tcb_id（前置 action ID 清單）",
  "input_digest": "string（輸入摘要，sha256 前 16 字）",
  "output_ref": "string（輸出檔案路徑或 PR URL）",
  "started_at": "string（ISO8601）",
  "completed_at": "string（ISO8601，status=completed 時填入）",
  "error": "string（status=failed 時填入，描述失敗原因）"
}
```

---

### 決策 2：Checkpoint 儲存位置

**目錄結構**：
```
$REPO_PATH/docs/sprints/tcb/
├── sprint-137/
│   ├── session-{session_id}/
│   │   ├── 617-act-1.json    ← Story #617 的第 1 個 TCB 記錄
│   │   ├── 617-act-2.json
│   │   ├── 616-act-1.json
│   │   └── ...
│   └── index.json            ← Session TCB 索引（含所有 tcb_id 及狀態摘要）
└── sprint-136/
    └── ...（歷史保留）
```

**設計原則**：
- 按 session 隔離（`session-{session_id}/`），符合 CLAUDE.md 紅線 8（多機器多 session 共用檔案衝突防護）
- 每個 TCB 記錄為獨立 JSON 文件（atomic write，避免半寫入損毀）
- `index.json` 為 session 內的 TCB 目錄，由 Scrum Master 維護

**Git 處理**：TCB 文件加入版控（非 .gitignore），供 post-sprint 分析與審計。Commit 頻率：Session 結束時一次性 commit `docs/sprints/tcb/sprint-N/session-*/` 目錄。

---

### 決策 3：恢復策略

**恢復層次（由粗到細）**：

| 層次 | 現有機制 | TCB 增強 |
|------|---------|---------|
| Sprint 級 | `sprint-checkpoint.json`（Story 完成狀態）| 維持現有，不改動 |
| Story 級 | `sprint-checkpoint.json` stories 陣列 | TCB index.json 補充 action 級狀態 |
| Action 級（新增）| 無 | TCB JSON 文件記錄每個關鍵 action |

**Action 級恢復流程**：
1. Sprint Execution 啟動時，讀取 `docs/sprints/tcb/sprint-N/session-{id}/index.json`
2. 找出 `status=running` 的 TCB（可能是中斷前的 action）→ 標記為 `status=failed`，重新執行
3. 找出 `status=completed` 的 TCB → 跳過，不重做
4. 找出 `status=pending` 的 TCB → 依 `depends_on` 順序執行

**冪等保護**：`completed` 狀態的 TCB 對應的 action 不再執行，利用 `output_ref` 直接引用已有輸出（如已 merged 的 PR URL、已存在的 ADR 文件）。

---

### 決策 4：與 Scrum Master 狀態圖的整合介面

**SM 狀態圖擴展**（在現有 Sprint 狀態機上增加 Action 層）：

```
Sprint [planning → execution → review]
  └── Story [pending → in-progress → completed | failed]
        └── Action [pending → running → completed | failed | skipped]  ← 新增層
```

**SM 職責**：
- Sprint Execution 開始時：初始化 `tcb/sprint-N/session-{id}/index.json`
- 每個 action 開始前：寫入 TCB `status=running`
- 每個關鍵 action 完成後：更新 TCB `status=completed`，填入 `output_ref`
- Sprint 結束時：commit TCB 文件（`docs/sprints/tcb/sprint-N/session-{id}/`）

**介面定義（SM → TCB 操作）**：
```bash
# 初始化 TCB（Story 開始時）
bash hooks/tcb-write.sh init {sprint} {session_id} {story_id}
# → 建立 session 目錄 + index.json

# 記錄 action 開始
bash hooks/tcb-write.sh start {sprint} {session_id} {story_id} {action} [{depends_on}]
# → 寫入 {story_id}-act-N.json（status=running）

# 記錄 action 完成
bash hooks/tcb-write.sh complete {sprint} {session_id} {tcb_id} {output_ref}
# → 更新 {tcb_id}.json（status=completed）

# 查詢恢復狀態（Sprint 重啟時）
bash hooks/tcb-write.sh resume {sprint} {session_id}
# → 輸出需重跑的 tcb_id 清單
```

---

## 後果

**正面**：
- 長時 Sprint 中斷恢復損失從「整個 Story」降低到「最近一個關鍵 action」
- TCB 索引提供 Sprint 執行軌跡，支援 post-sprint 分析與錯誤歸因
- 與現有 checkpoint 機制（sprint-checkpoint.json）層次互補，不破壞現有流程

**負面 / 風險**：
- 每個關鍵 action 前後各增加一次 file write 操作，輕微增加 latency
- Session 隔離目錄在多 session 並行時可能產生大量 TCB 文件，需定期清理
- `index.json` 的維護需要 SM 正確執行 hook，若 hook 失敗需有 graceful degradation（降級為現有 story-level checkpoint）

---

## 相關文件

- `docs/discovery/PB-2026-03-23-tcb-checkpoint.md`
- `docs/sprints/sprint-checkpoint.json`（現有 Story 級 checkpoint）
- #404 feat: TCB 斷點管理 — Agent Action 級 Checkpoint（待實作）
- ADR-023（Sprint Execution 文件直推 main 豁免，TCB 文件適用同規則）
- `skills/sprint-execution/SKILL.md` §2.12（Sprint 進度 Checkpoint 現有機制）
