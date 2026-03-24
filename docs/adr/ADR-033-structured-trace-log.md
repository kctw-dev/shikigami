# ADR-033：Structured Trace Log 架構

**日期**：2026-03-24
**狀態**：Accepted
**相關 Issue**：#392、#473
**提案者**：Architect Agent
**關聯 ADR**：ADR-024（Attendance Hook）、ADR-026（Cruise Mode）、ADR-028（Multi-Sprint Observability）、ADR-032（Delivery Path Tiering）

---

## 背景

### 問題陳述

Shikigami 目前有兩種日誌形式：

| 日誌類型 | 路徑 | 用途 | 格式 |
|---------|------|------|------|
| cruise-log | `docs/cruise-logs/{date}-{session}.jsonl` | 巡航事件（Cruise Mode 巡邏）| JSONL，每行一筆 cycle 事件 |
| live-log | `logs/live/{date}-{session}.log` | 即時 Sprint 狀態文字紀錄 | 純文字，人工可讀 |

然而，多 Agent 協作情境中，缺乏一層**執行路徑追蹤**機制：

1. **跨 Agent 追蹤缺失**：主 session 派遣 subagent 後，無法得知各 Agent 在哪個時間點執行了什麼動作
2. **效能瓶頸診斷困難**：無 duration 紀錄，無法判斷哪個 step 是執行瓶頸
3. **異常行為溯源困難**：某個 Story 失敗時，無法追蹤是哪個 Agent 在哪個動作出問題
4. **多機器協作可視性不足**：多個 session 同時運行時，無法區分各 session 的執行軌跡

Issue #342 研究報告確認此為框架可觀測性的核心缺口，#392 定義具體 User Story 需求。

### 驅動力

- #342 研究報告識別跨 Agent 追蹤為高優先缺口
- 現有 cruise-log 僅記錄 Cruise cycle 事件，不記錄 subagent 內部執行細節
- 現有 live-log 為文字格式，不適合程式化查詢與聚合分析
- 多機器協作場景下，per-session 隔離是防止寫入衝突的必要機制（CLAUDE.md 紅線 #8）

---

## 決策問題

如何在不干擾現有 cruise-log / live-log 的前提下，為 Shikigami 多 Agent 協作引入結構化執行路徑追蹤機制？

---

## 考慮的選項

### 決策 1：Trace Log 格式

#### 選項 A：JSONL（每行一筆 trace span）

每個 Agent 動作寫入一行 JSON，遵循 OpenTelemetry Span 精神（traceId / spanId / parentSpanId 三層索引）：

```jsonl
{"traceId":"abc123","spanId":"s001","parentSpanId":null,"agentRole":"scrum-master","action":"dispatch-story","storyId":"#473","timestamp":"2026-03-24T10:00:00+0800","duration":null,"status":"started","sessionId":"session-xyz"}
{"traceId":"abc123","spanId":"s002","parentSpanId":"s001","agentRole":"developer","action":"tdd-implement","storyId":"#473","timestamp":"2026-03-24T10:00:05+0800","duration":null,"status":"started","sessionId":"session-xyz"}
{"traceId":"abc123","spanId":"s002","parentSpanId":"s001","agentRole":"developer","action":"tdd-implement","storyId":"#473","timestamp":"2026-03-24T10:02:15+0800","duration":130,"status":"completed","sessionId":"session-xyz"}
```

**優點**：
- 結構化，程式化查詢友好（jq、Python 均可處理）
- 每行獨立，append-only，I/O 非阻塞
- 與 cruise-log 格式一致，學習成本低
- traceId/spanId/parentSpanId 支援跨 Agent 因果追蹤
- 可擴充欄位，向後相容

**缺點**：
- started / completed 需兩筆記錄同一 action，若 crash 只有 started 沒有 completed

#### 選項 B：結構化文字（Human-Readable Log）

類似 live-log 的文字格式，但加入固定前綴欄位：

```
[TRACE] 2026-03-24T10:00:00+0800 scrum-master dispatch-story #473 started
[TRACE] 2026-03-24T10:00:05+0800 developer tdd-implement #473 started
```

**優點**：
- 人工直接可讀，不需工具
- 簡單，無解析成本

**缺點**：
- 無 traceId/spanId，無法追蹤父子關係
- 正規表達式解析脆弱，欄位順序敏感
- 難以聚合（count duration、filter by agentRole）

**結論**：否決 — 缺乏跨 Agent 因果索引，不符合 #392 AC1 schema 要求

#### 選項 C：中央集中式 DB（SQLite / JSON DB）

所有 session 的 trace 集中寫入一個 SQLite 或 JSON 資料庫。

**優點**：
- 全局查詢能力最強
- 支援複雜跨 session 分析

**缺點**：
- 多機器同時寫入會產生 file lock 競爭，違反 CLAUDE.md 紅線 #8（共用檔案 append 會 git conflict）
- 引入外部依賴（SQLite），超出 Shikigami 的純檔案架構
- 不符合 per-session 隔離原則

**結論**：否決 — 多機器衝突風險不可接受

**選定方案：選項 A（JSONL 格式）**

---

### 決策 2：JSONL Schema 定義

**選定方案：OpenTelemetry-inspired Span schema，含必要欄位與可選欄位**

#### 必要欄位（Required）

| 欄位 | 類型 | 說明 |
|------|------|------|
| `traceId` | string | 一次完整執行鏈的唯一識別碼（如 Sprint Execution 一次派遣 = 一個 trace）|
| `spanId` | string | 本 span 的唯一識別碼 |
| `parentSpanId` | string \| null | 父 span 的 spanId；根 span 為 null |
| `agentRole` | string | 執行動作的 Agent 角色（scrum-master、developer、qa-engineer 等）|
| `action` | string | 執行的動作名稱（dispatch-story、tdd-implement、spec-review 等）|
| `timestamp` | string | ISO 8601 帶時區，精確到秒（`date` 指令取得，禁止 agent 推斷）|
| `status` | string | `"started"` \| `"completed"` \| `"failed"` |
| `sessionId` | string | Claude session 識別碼（防多機器混淆）|

#### 可選欄位（Optional）

| 欄位 | 類型 | 說明 |
|------|------|------|
| `duration` | number \| null | 秒數，僅 `completed` / `failed` 時填入；`started` 時為 null |
| `storyId` | string | 相關 Story ID（如 `"#473"`）|
| `sprintId` | string | 相關 Sprint 識別碼（如 `"sprint-125"`）|
| `metadata` | object | 自由擴充欄位，不記錄使用者輸入內容（隱私保護）|

#### Schema 完整範例

```jsonl
{"traceId":"sp125-473-abc","spanId":"s001","parentSpanId":null,"agentRole":"scrum-master","action":"dispatch-story","storyId":"#473","sprintId":"sprint-125","timestamp":"2026-03-24T10:00:00+0800","duration":null,"status":"started","sessionId":"session-xyz"}
{"traceId":"sp125-473-abc","spanId":"s002","parentSpanId":"s001","agentRole":"developer","action":"tdd-implement","storyId":"#473","sprintId":"sprint-125","timestamp":"2026-03-24T10:00:05+0800","duration":null,"status":"started","sessionId":"session-xyz"}
{"traceId":"sp125-473-abc","spanId":"s002","parentSpanId":"s001","agentRole":"developer","action":"tdd-implement","storyId":"#473","sprintId":"sprint-125","timestamp":"2026-03-24T10:02:15+0800","duration":130,"status":"completed","sessionId":"session-xyz"}
{"traceId":"sp125-473-abc","spanId":"s001","parentSpanId":null,"agentRole":"scrum-master","action":"dispatch-story","storyId":"#473","sprintId":"sprint-125","timestamp":"2026-03-24T10:05:30+0800","duration":330,"status":"completed","sessionId":"session-xyz"}
```

---

### 決策 3：寫入插入點（Hook 層 vs Agent YAML）

#### 選項 A：Hook 層注入（PostToolUse / PreToolUse hook）

在 hooks.json 新增 hook，監聽特定 Bash 指令（如 Agent dispatch 指令）並自動寫入 trace。

**優點**：
- Agent YAML 完全不需修改
- 集中管理，一處修改即影響所有 Agent
- 對 Agent prompt 零侵入

**缺點**：
- Hook 難以取得 Agent 內部語義（traceId/spanId 需靠約定環境變數傳遞）
- Hook 只能感知工具呼叫層，無法捕捉 Agent 內部邏輯 step
- 精細度有限（無法區分同一工具的不同語義 action）

#### 選項 B：Agent YAML / Skill.md 中顯式記錄指令

在 Skill.md 的每個步驟中，明確加入 `append trace log` 指令。

**優點**：
- 語義精確，可捕捉 Agent 層次的業務動作
- traceId/spanId 可由 Agent 自行管理，語義明確

**缺點**：
- 需修改全部 8 個 agent YAML + 相關 Skill.md（高侵入性）
- 遺漏某個步驟就有 trace 缺口
- Skill.md 等同框架行為，修改需走 /shoot 流程（成本高）

#### 選項 C：混合模式（Hook 層 + Agent 層選擇性覆寫）

Hook 層提供基礎 span（session 粒度），Agent 層在關鍵 action 補充語義 span。

**優點**：
- Hook 層確保所有 session 均有基礎覆蓋
- Agent 層選擇性添加高價值語義 span，不強制全量覆寫
- 逐步擴展，先有基礎再精化

**缺點**：
- 兩層混合有重複記錄的邊界模糊風險

**選定方案：選項 B（Agent 層 Skill.md 顯式記錄）— 主方案；並預留 Hook 層為未來可選擴充**

**理由**：
- Shikigami 的 Skill.md 是 Agent 行為的規範文件，trace 的精確語義必須在 Skill 層定義
- Hook 層缺乏 traceId/spanId 語義，用於 trace 品質不足
- Story-Lifecycle Skill 是 trace 最高密度點，集中修改 1-2 個 Skill 即可覆蓋主要場景
- Hook 層擴充留作未來補充粗粒度 span 使用

---

### 決策 4：儲存策略（per-session 檔案命名與 retention）

#### 選項 A：per-session 檔案（與 cruise-log 一致）

每個 session 產生一個獨立 trace log 檔案：

```
docs/trace-logs/{date}-{session-id}.jsonl
```

範例：
```
docs/trace-logs/2026-03-24-session-abc123.jsonl
docs/trace-logs/2026-03-24-session-xyz456.jsonl
```

**優點**：
- 完全符合 CLAUDE.md 紅線 #8（多機器多 session 各自獨立，無 git conflict）
- 與 cruise-log 命名規範一致，學習成本低
- 單一 session 的 trace 可獨立讀取，不受其他 session 干擾

**缺點**：
- 跨 session 分析需合併多個檔案

#### 選項 B：全局單一檔案

所有 session 寫入同一個 `docs/trace-logs/trace.jsonl`。

**缺點**：多機器並發 append 必然導致 git conflict（紅線 #8 明確禁止）

**結論**：直接否決

**選定方案：選項 A（per-session 檔案）**

#### Retention 策略

| 規則 | 配置 |
|------|------|
| 預設保留期限 | 7 天 |
| 配置方式 | 環境變數 `SHIKIGAMI_TRACE_RETENTION_DAYS`（未設定時預設 7）|
| 清理機制 | Hook 或 settle script 在 session start 時清理過期檔案 |
| 清理範圍 | 僅清理 `docs/trace-logs/` 下超過 retention 天數的 `.jsonl` 檔案 |

---

### 決策 5：與既有 live-log / cruise-log 的關係

**選定方案：三層日誌各自獨立，職責不重疊**

| 日誌類型 | 路徑 | 記錄粒度 | 格式 | 用途 |
|---------|------|---------|------|------|
| cruise-log | `docs/cruise-logs/{date}-{session}.jsonl` | Cruise cycle 事件 | JSONL | 巡航事件（PO patrol、SRE inspection）|
| live-log | `logs/live/{date}-{session}.log` | Sprint 即時狀態 | 純文字 | 人工可讀的 Sprint 執行狀態 |
| trace-log | `docs/trace-logs/{date}-{session}.jsonl` | Agent action span | JSONL | 跨 Agent 執行路徑追蹤、效能診斷 |

**職責邊界**：
- cruise-log：記錄「**什麼 Cruise event 發生了**」（巡航層事件）
- live-log：記錄「**Sprint 目前狀態是什麼**」（Sprint 層狀態）
- trace-log：記錄「**哪個 Agent 在哪個時間點做了什麼**」（執行路徑層）

**互補關係**：三種 log 可交叉查詢，但各自獨立存在，互不依賴。

---

## 決策

**建立 Structured Trace Log 機制**，具體決策摘要：

| 決策項 | 結論 |
|--------|------|
| Trace 格式 | JSONL，每行一筆 span，遵循 OpenTelemetry-inspired schema |
| Schema | traceId / spanId / parentSpanId / agentRole / action / timestamp / status / sessionId（必要）+ duration / storyId 等（可選）|
| 寫入插入點 | Agent 層 Skill.md 顯式記錄（主方案）；Hook 層為未來可選補充 |
| 儲存策略 | per-session 檔案，路徑 `docs/trace-logs/{date}-{session-id}.jsonl` |
| Retention | 預設 7 天，可透過 `SHIKIGAMI_TRACE_RETENTION_DAYS` 配置 |
| 與既有 log 關係 | 三層獨立，各有職責，互補不重複 |
| 隱私保護 | trace log 不記錄使用者輸入內容，僅記錄 action metadata |
| 跨機器安全 | per-session 檔案命名，多機器並發寫入零 git conflict |

---

## 實作影響

### 需新增的檔案

| 檔案 | 內容 |
|------|------|
| `docs/trace-logs/.gitkeep` | 確保 trace-logs 目錄存在於 repo |
| `docs/adr/ADR-033-structured-trace-log.md` | 本 ADR 文件 |

### 需修改的檔案（#392 實作時處理）

| 檔案 | 修改內容 |
|------|---------|
| `skills/sprint-execution/SKILL.md` | Story-Lifecycle 關鍵 action 加入 trace span 寫入指令 |
| `skills/cruise/SKILL.md`（可選）| Cruise cycle 加入 trace span（若需跨層關聯）|

### 不在本 ADR 範圍的工作

| 項目 | 說明 |
|------|------|
| Trace 可視化工具 | 超出 #392 scope，留作未來 Story |
| Hook 層 trace 注入 | 決策 3 預留為未來補充，不在 #392 實作範圍 |
| Trace 聚合查詢 CLI | 超出 #392 scope |

---

## 後果

### 正面

- **執行路徑可視化**：多 Agent 協作的動作順序、父子關係、耗時一目了然
- **效能診斷基礎**：duration 欄位支援識別執行瓶頸
- **多機器安全**：per-session 隔離，零 git conflict 風險
- **與既有 log 互補**：不衝突，各有職責，可交叉查詢
- **輕量引入**：Agent 層顯式記錄，不需改動 hook 基礎設施
- **可擴充**：schema 設計允許未來加入 metadata 欄位

### 負面

- **Skill.md 修改量**：需修改 story-lifecycle-prompt.md，屬框架行為變更，需走正式流程
- **trace 完整性依賴 Agent 遵守**：Agent 忘記寫入則有缺口（無強制機制）

### 風險緩解

| 風險 | 緩解措施 |
|------|---------|
| Agent 遺漏寫入 trace | Skill.md 中以明確步驟列出，QA self-review 檢查是否有 trace 輸出 |
| session-id 難取得 | 以 `date +%s%N` 或 Claude session 啟動時寫入的識別碼替代；per-session 唯一性可接受 |
| trace log 磁碟佔用 | 7 天 retention 策略控制，JSONL 格式每筆數百 bytes，一般規模不會超限 |
| 跨 session 分析困難 | 可用 `cat docs/trace-logs/*.jsonl | jq ...` 合併查詢 |

---

## 附錄：Action 名稱慣例

為確保 trace log 查詢一致性，定義常用 action 名稱：

| agentRole | action | 說明 |
|-----------|--------|------|
| scrum-master | dispatch-story | 派遣 Story subagent |
| scrum-master | sprint-planning | Sprint Planning 儀式 |
| scrum-master | sprint-review | Sprint Review 儀式 |
| developer | tdd-implement | TDD 實作 |
| developer | spec-review | Spec Compliance self-review |
| developer | code-quality-review | Code Quality self-review |
| developer | security-review | Security self-review |
| developer | git-commit | git commit 動作 |
| developer | pr-create | PR 建立 |
| qa-engineer | ac-refinement | AC 精化 |
| architect | adr-research | ADR 研究撰寫 |
| cruise | po-patrol | PO 巡邏 cycle |
| cruise | sre-inspection | SRE 檢查 cycle |
