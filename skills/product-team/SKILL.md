---
name: product-team
description: "Use when forming a product engineering team that must scale between small fixes and large multi-layer features — selects a gear, sizes the roster, and dispatches teammates with isolated context"
---

# Product Team — 產品工程團隊（三檔變速）

## 1. 概述

本 Skill 定義一套**能大能小**的產品工程團隊。核心設計是：**角色定義只寫一次，變的是 pipeline 深度與同時在線人數**。

多數 AI 團隊框架只有一檔，而且是最重的那檔（全套 PRD → 架構 → 實作 → 驗收），對小專案是災難：前置過重、token 成本失控、探索性需求被僵化流程卡死。本 Skill 用**客觀換檔規則**解決這件事。

**觸發方式**：使用者表達「組團隊」、「派人做這個功能」、「這個要幾個人做」、「product team」等語意，或執行 `/team`。

**執行基礎**：Claude Code Agent Teams（experimental）。需設定 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`。未啟用時降級為 subagent 模式（見 §6）。

---

## 2. 三檔規格

| | **S 檔** | **M 檔** | **L 檔** |
|---|---|---|---|
| **適用** | 小修、單點、文件、設定 | 一般 feature | 新模組、跨層、不可逆變更 |
| **在線 agent** | lead 自己做 + 1 verifier subagent | lead + 3 teammates | lead + 4-5 teammates（worktree 隔離）|
| **前置文件** | 無。一句話意圖 + 一個失敗測試 | 一頁 spec | PRD → ADR → task 拆解 |
| **角色** | lead + verifier | analyst(前置) / dev × 2 / qa | analyst / architect / dev × 2 / qa (+ security) |
| **品質關卡** | verifier 跑測試 | QA 獨立驗收 | 對抗式 review panel（security / perf / coverage）|
| **人類介入** | 只在 PR | spec 確認 + PR | 意圖確認 + ADR 簽核 + PR |
| **隔離模式** | 不適用 | 完全隔離 | 隔離 + 指定議題開辯論 |
| **Token 量級** | 1x | 3-4x | 10-15x |

**L 檔的 10-15x 不是估算誤差，是本來就會這麼貴。** 所以換檔規則必須客觀——讓 lead「自行判斷複雜度」等於沒有規則，它會一路開 L 檔。

---

## 3. 換檔（HARD-GATE）

<HARD-GATE>
每次啟動團隊前必須先跑換檔判定，並**輸出命中的具體條款編號**。禁止以「這個看起來蠻複雜的」這類主觀描述決定檔次。
</HARD-GATE>

### 3.1 升檔觸發（任一命中即升一檔，從 S 起算）

| 編號 | 條件 |
|------|------|
| **U1** | 觸及檔案 > 5 個 |
| **U2** | 跨層（前端 / 後端 / DB 至少兩層）|
| **U3** | 改動 public API、DB schema 或任何對外契約 |
| **U4** | 需要新增外部依賴 |
| **U5** | 不可逆（資料遷移、刪除、對外發布、金流）|

### 3.2 降檔觸發（全部命中才降）

| 編號 | 條件 |
|------|------|
| **D1** | 單一檔案且不跨層 |
| **D2** | 已有測試覆蓋該路徑 |
| **D3** | 純文件、純設定或純格式調整 |

### 3.3 回退觸發（不是升檔，是停下來）

| 編號 | 條件 | 動作 |
|------|------|------|
| **R1** | 需求寫不出驗收測試 | 停止換檔，轉 Product Analyst 釐清需求 |
| **R2** | 命中 U5 但使用者未明確授權 | 停止，向人類確認 |

**R1 優先於所有升檔條款。** 寫不出測試代表需求不清，加人只會放大混亂。

完整判定流程與範例：[`references/gear-selection.md`](references/gear-selection.md)

---

## 4. 隔離邊界

多 agent 的脆弱來源是 context 共享不良與決策互相衝突。本 Skill 的解法是**預設隔離、例外互通**：

- **預設（S / M 檔）**：每個 teammate 拿到自包含任務描述 + 指定輸出格式 + 全新 context，**不知道其他 teammate 存在**，不互相 message
- **例外（L 檔特定議題）**：只有這三種情況開放 mailbox 互通：
  1. root cause 不明的除錯 —— 各持假設互相踢館
  2. 架構方案取捨 —— 需要正反論證
  3. review 意見衝突 —— 需要收斂

預設互通會直接把團隊變成互相污染的雜訊源。詳見 [`references/isolation-boundary.md`](references/isolation-boundary.md)。

---

## 5. 派工紀律

### 5.1 檔案所有權（硬規則）

**一人一組檔案，絕不重疊。** 兩個 teammate 改同一個檔案就是互相覆蓋，沒有例外處理，只有預防。

拆 task 時必須明確標注該 task 擁有哪些檔案路徑。無法切開的工作不要平行——改用 pipeline 串行。

### 5.2 spawn prompt 必須自帶 context

teammate 讀得到 CLAUDE.md、MCP、skills，但**繼承不到 lead 的對話歷史**。省這裡會導致重做，比多花的 token 更貴。

spawn prompt 範本見 [`references/teammate-dispatch.md`](references/teammate-dispatch.md)。

### 5.3 規模

- 3-5 人起步，每人 5-6 個 task
- 三個專注的 teammate 常常贏過五個散的
- 超過 5 人時協調成本超線性成長，收益遞減

### 5.4 Model Routing

依 ADR-039 風險評分路由，這是目前最有效的降本手段：

| 層級 | 用途 |
|------|------|
| `haiku` | 機械性任務：改設定、跑測試、格式化、檔案搬移 |
| `sonnet` | 基準：Developer、Product Analyst |
| `opus` | Architect、QA、Security self-review（靜態例外，不參與動態路由）|

路由決策必須記錄：`model-route #N tier=X score=Y`。

### 5.5 平行安全

`SHIKIGAMI_MAX_PARALLEL` 預設 2，**未設定時亦視為 2**。派遣 worktree teammate 前必須執行 `git worktree list` 計算現存數量。詳見 `skills/sprint-execution/references/parallel-safety.md`。

---

## 6. 未啟用 Agent Teams 時的降級

`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` 未設定時，不存在共享 task list 與 mailbox。降級規則：

| 檔次 | 降級行為 |
|------|----------|
| **S** | 無差異（本來就不需要團隊）|
| **M** | 改用 subagent 平行派工。失去 self-claim，由 lead 全權指派 |
| **L** | 辯論模式不可用 —— 改為 lead 收集各方獨立意見後自行收斂，並在報告中標注「未經對抗驗證」 |

降級時必須明講，不得假裝團隊功能正常運作。

---

## 7. 品質閘

以下三個 hook 是強制關卡，寫在 prompt 裡的叮嚀 agent 會忘，寫成 hook 繞不過去：

| Hook | 腳本 | 擋什麼 |
|------|------|--------|
| `TaskCreated` | `hooks/team-task-created-gate.sh` | task 未標注檔案所有權範圍 |
| `TaskCompleted` | `hooks/team-task-completed-gate.sh` | 宣稱完成但無對應測試證據 |
| `TeammateIdle` | `hooks/teammate-idle-gate.sh` | 還有未滿足的驗收條件就想收工 |

三者皆以 exit 2 回饋並擋下。**基礎設施失敗時（jq 缺失、payload 無法解析）一律 exit 0 放行**——閘門不該把團隊鎖死。

---

## 8. 執行流程

1. **換檔判定**（§3）→ 輸出命中條款編號與檔次
2. **R1 檢查** → 命中則轉 Product Analyst 釐清，流程中止
3. **spec 產出**（M/L 檔）→ 人類簽核
4. **task 拆解** → 標注檔案所有權，確認無重疊
5. **spawn teammates** → 依 §5.2 範本，帶足 context
6. **監看與導向** → 放著跑太久是浪費 token 最快的方式
7. **驗收** → QA 獨立驗收，L 檔另跑對抗式 review panel
8. **收斂** → lead 綜合結果，產出 PR

---

## 9. 落地建議

**先只做 M 檔。** S 檔不需要團隊（單 session 就夠），L 檔的協調複雜度會在你驗證角色定義好不好用之前先把你淹死。M 檔跑順了，往上往下擴都是加規則，不是重寫。

**第一個 M 檔任務挑 review 或研究類**，不要挑平行寫 code —— 邊界清楚、不寫檔案、無衝突風險，先驗證角色分工與交接品質。

---

## 10. 相關文件

- [`references/gear-selection.md`](references/gear-selection.md) — 換檔判定完整流程與範例
- [`references/teammate-dispatch.md`](references/teammate-dispatch.md) — spawn prompt 範本
- [`references/isolation-boundary.md`](references/isolation-boundary.md) — 隔離與辯論模式
- `agents/product-analyst.md` — 需求展開角色
- `skills/sprint-execution/references/parallel-safety.md` — 平行 worktree OOM 防護
