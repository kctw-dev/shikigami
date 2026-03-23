# 並行安全規則矩陣 — 多 Agent 同時操作邊界

> **文件版本**：v1.0.0（2026-03-23）
> **來源**：Sprint 122 Retro Action Item #2，Issue #451
> **消費者**：Architect（Sprint Planning 平行分群決策）、Story-Lifecycle subagent（執行期間邊界遵守）
> **相關文件**：
> - `skills/sprint-execution/SKILL.md` §2.2（共用文件 HARD-GATE）
> - `skills/sprint-planning/architect-prompt.md`（平行分群建議格式）

---

## 1. 故事類型 × 修改範圍 → 可並行決策表

以下矩陣說明各 Story Type 在不同修改範圍下，是否可以與其他 Story 並行執行（Phase 1）。

| Story Type | 修改範圍 | 可並行？ | 衝突風險 | 說明 |
|-----------|---------|---------|---------|------|
| **FEATURE** | 獨立 `skills/` 子目錄（不與其他 Story 重疊） | **YES** | 低 | 每個 Skill 子目錄天然隔離 |
| **FEATURE** | 相同 `skills/` 子目錄（同一 SKILL.md） | **NO** | 高 | 同一檔案寫入衝突 |
| **FEATURE** | `docs/km/` 獨立新建文件 | **YES** | 低 | 建立新文件無衝突 |
| **FEATURE** | `docs/km/` 修改現有共用文件 | **NO** | 中 | 讀-改-寫競態 |
| **FEATURE** | 修改 `CLAUDE.md` | **NO** | 高 | 共用文件禁止並行修改 |
| **FEATURE** | 修改 `docs/PROJECT_BOARD.md` | **NO** | 高 | HARD-GATE：禁止平行 subagent 直接修改 |
| **FEATURE** | 修改 `docs/sprints/sprint_N.md` | **NO** | 高 | HARD-GATE：禁止平行 subagent 直接修改 |
| **DESIGN** | `design/` 獨立設計稿 | **YES** | 低 | 設計稿通常以元件/頁面為粒度隔離 |
| **DESIGN** | 修改 Design Token / 共用設計系統 | **NO** | 高 | 設計系統變更影響全域 |
| **INFRA** | `.github/workflows/` 獨立 workflow 檔案 | **YES** | 低 | 不同 workflow 檔案天然隔離 |
| **INFRA** | `.github/workflows/` 同一 workflow 檔案 | **NO** | 高 | 同一 CI 配置寫入衝突 |
| **INFRA** | `scripts/` 獨立腳本 | **YES** | 低 | 新腳本無衝突 |
| **INFRA** | `hooks/hooks.json` | **NO** | 高 | 單一 JSON 配置競態 |
| **SECURITY** | 安全修補（獨立模組） | **YES** | 低 | 與其他 Story 無功能依賴 |
| **SECURITY** | 安全修補（影響認證核心流程） | **NO** | 高 | 認證流程改動需序列化以確保一致性 |
| **INTEGRATION** | 對接獨立第三方服務（API 契約已定義） | **YES** | 低 | 不同外部服務整合天然隔離 |
| **INTEGRATION** | 對接與另一 Story 有共享介面的服務 | **NO** | 高 | 介面契約衝突 |
| **RESEARCH** | 任何 Spike / 調查（唯讀） | **YES** | 無 | RESEARCH 不修改任何框架文件 |
| **RESEARCH** | 產出 Spike Report（新建文件） | **YES** | 低 | 新建文件無衝突 |

### 快速判斷規則（Decision Rule）

```
可並行 =
  修改範圍完全不重疊（不同檔案、不同目錄）
  AND 不涉及任何共用文件（見第 2 節清單）
  AND 無下游依賴關係（一個 Story 的輸出不是另一個 Story 的輸入）
```

---

## 2. 共用文件清單（禁止平行修改）

以下文件在任何並行場景下，**同一時間只允許一個 Story 修改**。主 session 負責批次協調更新，平行 subagent 禁止直接寫入。

### 2.1 HARD-GATE 文件（框架強制執行）

來源：`skills/sprint-execution/SKILL.md` §2.2

| 文件路徑 | 說明 | 違反後果 |
|---------|------|---------|
| `docs/PROJECT_BOARD.md` | Sprint 看板狀態 | Race condition → 狀態不一致 |
| `docs/sprints/sprint_N.md` | Sprint 計畫/回顧文件 | 多個 subagent 互相覆蓋更新 |

### 2.2 高風險共用文件（強烈建議序列化）

| 文件路徑 | 說明 | 衝突類型 |
|---------|------|---------|
| `CLAUDE.md` | 專案主要指引，版號/紅線定義 | 寫 |
| `.claude-plugin/plugin.json` | Plugin manifest，版號 source of truth | 寫 |
| `.claude-plugin/marketplace.json` | Marketplace 發布資訊 | 寫 |
| `gemini-extension.json` | Gemini 配置版號同步 | 寫 |
| `README.md` | 版號 badge 同步 | 寫 |
| `hooks/hooks.json` | Hook 配置（session-start/end 行為） | 寫 |
| `agents/*.md`（現有 Agent 定義） | Agent 角色行為定義 | 寫 |

### 2.3 天然 Per-Session 隔離文件（可安全並行）

以下文件採 per-session 路徑設計，多台機器並行無衝突：

| 文件路徑模式 | 說明 |
|------------|------|
| `docs/sprints/live-log/YYYY-MM-DD-session-<SESSION_ID>.log` | Sprint 執行即時日誌 |
| `docs/km/retro-log/YYYY-MM-DD-session-<SESSION_ID>.md` | Sprint Review retrospective log |
| `docs/km/metrics-log/YYYY-MM-DD-session-<SESSION_ID>.md` | Sprint Review metrics log |
| `docs/attendance/YYYY-MM-DD-session-<SESSION_ID>.jsonl` | 出勤紀錄 |
| `docs/cruise-logs/YYYY-MM-DD-session-<SESSION_ID>.jsonl` | Cruise cycle 日誌 |
| `docs/sprints/subagent-results/<ISSUE_ID>.md` | Story subagent 執行結果 |

> **設計原則**：新增任何需要多 session 寫入的文件，必須採用 `*-session-<SESSION_ID>.*` 命名規範，避免 git conflict。結算時由專用 settle 腳本合併。

---

## 3. 安全規則

### 3.1 Git Worktree 隔離

每個 Story-Lifecycle subagent 運行於獨立 git worktree（`isolation: "worktree"`），分支命名為 `sprint-{N}/{issue_id}`：

- 每個 subagent 看到的工作目錄完全獨立
- 共用文件衝突風險大幅降低（各 subagent 在自己的 worktree 修改，不影響彼此）
- 但最終 merge 至 main 時仍可能產生 merge conflict（見 §3.3）

### 3.2 Story Claim 鎖機制

多 session 並行時，使用三層協調防止重複領取同一 Story：

| 層級 | 機制 | 範圍 |
|------|------|------|
| 1 | `flock` + local lock file | 同機器原子操作 |
| 2 | `git push refs/claims/<id>` | 跨 session 互斥（同名 ref 拒絕 = 已佔用） |
| 3 | 展示層輸出（`[CLAIM-OK]` / `[CLAIM-BLOCKED]`） | 可觀測性 |

Claim 在 SessionEnd hook 時自動 release（`hooks/session-end-release.sh`）。

### 3.3 PR Merge 順序規則

當多個 Story 完成後，merge 至 main 的順序影響衝突：

| 情境 | 建議 merge 順序 | 說明 |
|------|----------------|------|
| 多個 Story 均修改不同獨立檔案 | 任意順序 | 無衝突 |
| Story A 修改檔案 X，Story B 也修改檔案 X | Story A 先 merge，Story B 後 rebase | Architect 在分群時已將此標注為 Phase 2 |
| 共用文件（PROJECT_BOARD.md 等）由主 session 批次更新 | 所有 Story subagent 完成後統一 commit | 主 session 單次原子更新 |

### 3.4 衝突解決優先順序

發生 merge conflict 時，依以下優先序處理：

1. **HARD-GATE 文件**（PROJECT_BOARD.md、sprint_N.md）：主 session 統一解決，保留所有 subagent 的狀態更新，不得丟棄任何 Story 完成記錄
2. **版號文件**（plugin.json 等）：取較高版號，確保版號只增不減
3. **Skill / Agent .md 文件**：保留兩者改動，由 Architect review 後手動合併
4. **一般文件**：取 main 為 base，cherry-pick 衝突段落後 commit

### 3.5 race-condition 防護（read-then-compare）

Story-Lifecycle subagent 更新共用狀態文件前，必須執行 read-then-compare：

```
讀取當前狀態值 → 比對是否符合預期 → 不符合時輸出 [CONFLICT] 並放棄寫入
```

輸出格式：
```
[CONFLICT] 狀態衝突，跳過覆蓋：{story_id} 當前值={actual}，預期值={expected}
```

---

## 4. Architect 在 Sprint Planning 的分群參考指引

Architect 使用本矩陣決定 Phase 1（可平行）與 Phase 2（序列執行）分群。

### 4.1 分群決策流程

```
對每個 Story 執行以下檢查：

Step 1 — 檔案範圍分析
  列出本 Story 預計修改的所有檔案/目錄

Step 2 — 共用文件衝突掃描
  對照第 2 節清單，是否有任何修改目標屬於共用文件？
  ├─ YES → 標記為「需序列化」，進入 Phase 2 候選
  └─ NO  → 進入 Step 3

Step 3 — 跨 Story 範圍重疊分析
  與 Sprint 中其他 Story 的修改範圍比對，是否有重疊？
  ├─ YES → 標記衝突檔案，進入 Phase 2（後執行方需 rebase）
  └─ NO  → 進入 Step 4

Step 4 — 依賴關係確認
  本 Story 的輸出是否是另一 Story 的輸入？
  ├─ YES → 本 Story 優先排入 Phase 1，依賴方進 Phase 2
  └─ NO  → 標記為可平行，進入 Phase 1
```

### 4.2 Story Type 對分群的影響

| Story Type | 分群傾向 | 備註 |
|-----------|---------|------|
| **FEATURE** | 需逐一檔案分析 | 最多樣化，依修改範圍決定 |
| **DESIGN** | Phase 1（大多數情況） | 設計稿與程式碼通常不重疊 |
| **INFRA** | 依 CI/腳本重疊度決定 | 修改同一 workflow 檔案需序列化 |
| **SECURITY** | Phase 2 傾向（謹慎） | 認證/授權邏輯改動建議序列化 |
| **INTEGRATION** | Phase 1（各自對接不同服務） | 若共享介面契約則 Phase 2 |
| **RESEARCH** | Phase 1（永遠） | 唯讀性質，無修改衝突 |

### 4.3 輸出格式提醒

Architect 在平行分群報告中，必須填寫「衝突檔案分析」表格（詳見 `skills/sprint-planning/architect-prompt.md` §平行分群建議）：

```markdown
### 檔案衝突分析
| 衝突檔案 | 涉及 Story | 建議執行順序 | 矩陣依據 |
|---------|-----------|------------|---------|
| skills/sprint-execution/SKILL.md | US-#M, US-#K | US-#K → US-#M | 矩陣 §1：相同 skill 子目錄 = NO |
```

「矩陣依據」欄位填入本矩陣 §1 決策表的對應規則，確保決策可追溯。

---

## 5. 一致性驗證：per-session 設計原則

本節驗證現有 per-session 檔案 + 結算機制符合 CLAUDE.md 紅線 #8（跨機器多團隊）。

| 設計原則（CLAUDE.md 紅線 #8） | 現有實作 | 一致性 |
|-----------------------------|---------|-------|
| 共用檔案 append 會 git conflict — 改用 per-session 檔案 | `live-log/YYYY-MM-DD-session-<ID>.log`、`retro-log/`、`metrics-log/`、`attendance/`、`cruise-logs/` 全部採 per-session 路徑 | 符合 |
| 結算機制 | `hooks/live-log-settle.sh` 合併同日日誌 | 符合 |
| 取號用 GitHub Issue `#N` 或 claim 鎖，不可自行編號 | `hooks/claim-issue.sh` 三層協調機制 | 符合 |
| 多台機器各開一個 session 同時工作 | worktree 隔離 + claim ref + per-session 路徑三重防護 | 符合 |

---

*由 Story-Lifecycle subagent 建立，Issue #451，Sprint 123*
