---
name: sprint-execution
description: "Use when executing sprint stories, implementing features, or working through sprint backlog items"
---

# Sprint Execution — Subagent 驅動開發

## 1. 概述

Sprint 執行的核心 Skill。從 Sprint Backlog 逐個取出 Story，透過 **Subagent 驅動開發模式** 完成實作與審查。

每個 Story 派遣一個全新的 Developer subagent 進行 TDD 開發，完成後經過**雙階段審查**（Spec Compliance + Code Quality）確保品質，最終更新 PROJECT_BOARD 並進入下一個 Story。

---

## 2. 核心原則

**Fresh subagent per story + 雙階段審查 = 高品質、快速迭代**

- **隔離性**：每個 Story 使用全新的 Developer subagent，避免上下文污染
- **TDD 強制**：所有功能實作必須先寫測試再寫代碼
- **雙階段審查**：Spec Compliance 確認做對了，Code Quality 確認做好了
- **小步快跑**：每個小步驟一個 commit，保持可追溯性

---

## 3. 執行流程

```
Issue 快掃（gh issue list --state open --limit 10）
  |-- gh 失敗 --> 靜默略過，繼續下一步（不阻塞）
  +-- 成功 --> 篩出需回覆的 issue → PO 草稿 → QA 審核 → 發布
  |
  v
Sprint Backlog 中取出 Story
  |
  v
派遣 Developer subagent（使用 developer-prompt.md）
  |
  v
Developer 實作 + TDD + 自我審查
  |
  v
派遣 QA subagent 做 Spec Compliance Review（使用 spec-reviewer-prompt.md）← 不可跳過（HARD-GATE）
  |-- 不通過 --> Developer 修復 --> 重新審查
  +-- 通過
        |
        v
派遣 QA subagent 做 Code Quality Review（使用 quality-reviewer-prompt.md）← 不可跳過（HARD-GATE）
  |-- 不通過 --> Developer 修復 --> 重新審查
  +-- 通過
        |
        v
如有安全相關 --> 派遣 Security subagent
  |
  v
更新 PROJECT_BOARD
  |
  v
Sprint Backlog 還有 Story？
  |-- YES --> 取出下一個 Story（回到頂端繼續）
  +-- NO（所有 Story 完成）--> 立即 invoke shikigami:sprint-review（不詢問使用者）
```

### 步驟詳解

1. **Issue 快掃**：在取出 Story 之前，執行 GitHub Issue 快速掃描，處理社群或使用者的待回覆問題。

   **執行指令：**
   ```bash
   gh issue list --state open --limit 10
   ```

   **降級指引：** gh 指令失敗（網路問題、權限不足、非 GitHub 倉庫等）時靜默略過，不阻塞 Story 執行。

   **觸發條件（同時滿足以下三項才對該 issue 執行回覆）：**
   - **(a)** issue 不含 `in-backlog` label 且不含 `retro-action` label（已排入 backlog 的 issue 由開發流程處理，retro action item 由 Retro 流程處理，兩者均不需額外回覆）
   - **(b)** issue 不含 `sprint-N-replied` label（N 為當前 Sprint 編號），避免本 Sprint 內重複回覆
   - **(c)** open issue 超過 5 個時，僅處理最舊的前 5 個（依 issue 編號升冪排序取前五）

   **回覆流程：**
   1. 派遣 PO subagent 針對每個符合觸發條件的 issue 起草回覆內容
   2. 派遣 QA subagent 審核草稿內容（語氣、正確性、是否承諾不必要的功能）
   3. QA 通過後，依專案等級發布回覆：
      - 公開專案：直接 `gh issue comment` 發布
      - 私有 / 敏感專案：回覆前請 User 確認

   **防重複機制：** 回覆成功後，立即為該 issue 加上 `sprint-N-replied` label（N 替換為當前 Sprint 編號，例如 Sprint 8 → `sprint-8-replied`）。下次快掃時篩除含此 label 的 issue，確保每個 Sprint 週期內不重複回覆同一 issue。

   > **Decision Note — 為何採用 GitHub Label 追蹤狀態**
   >
   > 備選方案包含：(1) 本地狀態檔、(2) commit message 標記、(3) GitHub Label。
   > 採用 Label 的理由：
   > - **持久化**：label 存於 GitHub，跨 subagent、跨 session 均可查詢，無需共享本地狀態
   > - **可靜態驗證**：`gh issue list --label sprint-N-replied` 可直接驗證，無需額外解析
   > - **原生支援**：gh CLI 原生 `--label` 篩選，指令簡單、無副作用
   > - **低成本**：不需要引入新的基礎設施或 ADR，符合 YAGNI 原則

2. **取出 Story**：從 `docs/PROJECT_BOARD.md` 的「待辦」欄取出優先級最高的 Story，移至「進行中」。**主 session 不讀取 Story 內容**，Story ID 與路徑傳入 subagent prompt，由 subagent 自行讀取。
3. **派遣 Developer subagent**：使用 `developer-prompt.md` 作為 prompt，在 prompt 中指定以下檔案路徑由 **Developer subagent 自行讀取**，主 session 不預讀這些內容：
   - `docs/sprints/sprint_N.md`（Story AC 與完整需求）
   - 相關 ADR 路徑（如 `docs/adr/ADR-XXX.md`）
   - 相關設計文件路徑（如 `docs/sdd/SDD-XXX.md`）
4. **Developer 實作**：遵循 TDD（Red → Green → Refactor），每個小步驟一個 commit，完成後執行自我審查 checklist。
5. **Spec Compliance Review**：派遣 QA subagent 使用 `spec-reviewer-prompt.md`，在 prompt 中指定 `docs/sprints/sprint_N.md` 路徑由 **QA subagent 自行讀取** Story AC，獨立驗證實作是否符合所有 Acceptance Criteria。QA subagent **回傳格式**：`PASS/FAIL + 一句話摘要`（例：`PASS — 所有 AC 均通過，測試覆蓋完整`）。
6. **Code Quality Review**：派遣 QA subagent 使用 `quality-reviewer-prompt.md`，在 prompt 中指定需審查的代碼路徑由 **QA subagent 自行讀取**，評估代碼品質、SOLID 原則、測試品質。QA subagent **回傳格式**：`PASS/FAIL + 一句話摘要`（例：`FAIL — 發現 3 個硬編碼常數，需提取為命名常量`）。
7. **安全審查（條件觸發）**：若 Story 涉及外部輸入、API 端點、配置變更，派遣 Security subagent 進行安全審查。在 prompt 中指定相關檔案路徑由 **Security subagent 自行讀取**。Security subagent **回傳格式**：`PASS/FAIL + 一句話摘要`（例：`PASS — 無外部輸入注入風險，配置透過環境變數管理`）。
8. **更新看板與同步 Sprint 文件**：Story 移至「已完成」，更新 `docs/PROJECT_BOARD.md`。同時同步 `docs/sprints/sprint_N.md` 的 Sprint Backlog 狀態欄（N 從 PROJECT_BOARD.md 符合 `/^## Sprint (\d+)/` 的最近「進行中」標題提取）：開啟 `docs/sprints/sprint_N.md`，將對應 Story 列的「狀態」欄更新為與 PROJECT_BOARD.md 一致。

   <HARD-GATE>
   **Developer 更新範圍限制（越權禁止）**

   **PROJECT_BOARD.md — Developer 可更新欄位：**
   - 僅限個別 Story 的狀態欄（「待辦」→「進行中」→「已完成」欄位移動）

   **PROJECT_BOARD.md — 禁止 Developer 修改的欄位：**
   - Sprint 完成標記（如「Sprint N 完成」、「已關閉」等 Sprint 級別狀態）
   - Stakeholder 驗收欄位（如「Stakeholder 驗收：接受」）
   - Sprint 級別的任何結果欄位

   **sprint_N.md — Developer 可更新欄位：**
   - 僅限 Sprint Backlog 表格中各 Story 列的「狀態」欄（如「待開始」→「進行中」→「完成」）

   **sprint_N.md — 禁止 Developer 修改的欄位（Sprint 級別欄位）：**
   - 文件頂部的「狀態：」欄位
   - Sprint Goal 結果描述
   - Sprint 驗收結論
   - 任何 Sprint 級別的完成標記或驗收記錄

   以上 Sprint 級別欄位僅由 **sprint-review** Skill 負責更新，Developer 不得觸碰。
   </HARD-GATE>

   ### 狀態更新衝突防護

   Developer subagent 在更新 sprint_N.md 的 Story 狀態欄之前，**必須先執行 read-then-compare 檢查**：

   1. 讀取目前檔案，先讀取目前檔案中該 Story 的狀態值（read-then-compare）
   2. 比對讀取到的值是否符合預期值（即本次更新前應存在的值）
   3. 若當前值**不符合預期**（例如已被其他 subagent 或主 session 標記為「完成」或「FAIL」），則：
      - 輸出精確字串：`[CONFLICT] 狀態衝突，跳過覆蓋：{story_id} 當前值={actual}，預期值={expected}`
      - 不執行任何檔案寫入（放棄寫入，不得靜默覆蓋）
   4. 若當前值符合預期，則繼續執行狀態更新

   **衝突發生時的三個可觀察指示：**

   | 指示 | 說明 |
   |------|------|
   | (a) 輸出精確字串 | subagent 輸出含 `[CONFLICT] 狀態衝突，跳過覆蓋：{story_id} 當前值={actual}，預期值={expected}` |
   | (b) 不執行任何檔案寫入 | subagent 偵測到衝突後，不對 sprint_N.md 執行任何 Edit 或 Write 操作 |
   | (c) 主 session log 可識別 | 主 session 接收 subagent 回傳輸出時，可從 log 中找到 `[CONFLICT]` 關鍵字，識別衝突事件 |

   **記錄本次 Execution 環節 Token 消耗** *(慢想模式限定)*：所有 Story 完成後（即 Sprint Backlog 清空時），將本 Execution 環節累計 Token 消耗記錄至 `docs/km/Metrics_Log.md` Token 成本分環節記錄表格（對應 Execution token 欄）：
   - **主要方法（優先）**：讀取 `~/.claude/projects/` 目錄下當前 session 的 JSONL 檔案，提取所有 `message.usage` 欄位中的 `input_tokens`、`cache_read_input_tokens`、`cache_creation_input_tokens` 與 `output_tokens`，依下列公式加總後填入 Metrics_Log.md 對應欄位：
     - **有效 input tokens = input_tokens + cache_read_input_tokens + cache_creation_input_tokens**
     - **output tokens = output_tokens**
   - **次選（降級方法）**：若 JSONL 檔案不存在、路徑不可存取、或 `message.usage` 欄位解析失敗，則各 token 欄填「N/A」，佔比欄填「N/A」，並輸出精確字串「Token 資料不可用，需手動補充」。

   **更新完成後，立即執行 git commit + git push**（本步驟僅 commit `PROJECT_BOARD.md` 與 `sprint_N.md`；`Metrics_Log.md` 與 `Retrospective_Log.md` 由 sprint-review 負責 commit。其他 Knowledge Management 文件不適用本規範，避免觸發 ADR-003 Out-of-Sprint Hard Gate）：

   ```bash
   git add docs/PROJECT_BOARD.md docs/sprints/sprint_N.md
   git commit -m "docs: Sprint N — [Story ID] 狀態更新為已完成"
   git push
   ```

   接著檢查終止條件：Sprint Backlog 中仍有待辦 Story → 取出下一個 Story 繼續執行；Sprint Backlog 已清空（所有 Story 完成）→ **立即 invoke shikigami:sprint-review**，不詢問使用者、不跳回「下一個 Story」流程。

---

## 4. Hard Gates

<HARD-GATE>
每個 Story 必須通過雙階段審查（Spec Compliance + Code Quality）才能標記為完成。
不得跳過任何一個審查階段。

> 歷史案例：Sprint 7 因跳過此步驟列為 Retro Problem（Issue #14），導致品質門禁失效。
</HARD-GATE>

> **Bypass 豁免：** 標記為 `[BYPASS]` 的 Story 豁免雙階段審查（Spec Compliance + Code Quality）。豁免條件與 `skills/scrum-master/SKILL.md` §10.3 Bypass 保護清單對齊——涉及 Framework Document Change、外部 API、安全相關的 Story 不得適用豁免，即使標注 `[QUICK]` 亦然。

<HARD-GATE>
所有功能實作必須遵循 TDD：先寫失敗測試 → 最小實作讓測試通過 → 重構。
例外：標注為 [SPIKE] 的探索性任務可豁免，但進入正式開發時必須補測試。
</HARD-GATE>

### doc-only Story 識別規則

**正向識別條件（滿足以下任一條件即判定為 doc-only）：**

- 條件 A：Story 對應的 CLAUDE.md 含有 `doc-only: true` 欄位
- 條件 B：Story 的所有 AC 條目均為 `[靜態]` 類型，**且**所有目標檔案路徑均在 `docs/` 目錄下

**執行分支（識別為 doc-only 時）：**

| 步驟 | 一般路徑 | doc-only 路徑 |
|------|---------|--------------|
| Developer 實作 | TDD（Red → Green → Refactor） | **跳過**（TDD 豁免） |
| 執行 bash 指令 | 可執行 bash 命令 | **跳過**（不執行任何 shell 命令） |
| 修改 src/ 目錄 | 依需求修改 | **禁止**（僅允許修改 docs/ 下檔案） |
| 修改 skills/ 目錄 | 依需求修改 | **禁止**（僅允許修改 docs/ 下檔案） |
| Spec Compliance Review | 必須通過（HARD-GATE） | **維持**（必須通過，不豁免） |
| Code Quality Review | 必須通過（HARD-GATE） | **維持**（必須通過，不豁免） |

> **重要**：doc-only 豁免僅豁免 TDD 開發流程。雙階段 QA Review（Spec Compliance + Code Quality）維持必要，**不得跳過**。

**負面案例排除清單（以下情況不適用 doc-only 路徑）：**

1. **[動態] AC 排除**：Story 的 AC 含有 `[動態]` 類型且需執行 shell 命令，即使其他 AC 均為 [靜態]，整體 Story 仍走一般路徑
2. **skills/ / commands/ / agents/ 路徑排除**：目標路徑含 `skills/`、`commands/`、`agents/` 目錄時，即使副檔名為 `.md`，**仍需執行 ADR-003 Checklist**，且不適用 doc-only 路徑（如本 Issue #34 本身即屬此類）
3. **CLAUDE.md 不存在降級**：若 CLAUDE.md 不存在，條件 A 無法觸發，TDD 豁免不生效；此時須退回條件 B 判斷，若條件 B 亦不滿足，則走一般路徑

**判定機制：** QA subagent 在 Sprint Planning 時確認，確認標準為「Story 所有 AC 引用路徑均為 `.md` 副檔名，且路徑均在 `docs/` 目錄下」。判定結果記錄於 `docs/sprints/sprint_N.md` 對應 Story 的備注欄或 QA 狀態欄。

---

## 5. DoD 自檢

每個 Story 完成前，Developer 必須逐項檢查 Definition of Done：

| 層次 | 條件 | 自檢 |
|------|------|------|
| 功能 | 所有 Acceptance Criteria 通過 | [ ] |
| 測試 | 單元測試 + 整合測試全部通過（0 failed） | [ ] |
| 安全 | 外部輸入通過安全驗證與去活化處理 | [ ] |
| 文件 | 設計文件對應章節已更新，代碼含設計文件引用 | [ ] |
| 設定 | 無硬編碼金鑰，配置透過環境變數管理 | [ ] |
| 度量 | Metrics_Log.md 本 Sprint 數據已更新（Velocity、完成率、趨勢） | [ ] |
| 反回歸 | 既有測試全部仍然通過 | [ ] |
| 技術債 | 取捷徑情況已用 `[TECH-DEBT]` 標記，並更新 `docs/km/Tech_Debt_Registry.md`（詳見 `developer-prompt.md` 的「Tech Debt 管理」區段） | [ ] |

---

## 6. 審查失敗處理

當任一審查階段不通過時：

1. Reviewer 產出具體問題清單（含嚴重度分級）
2. 同一個 Developer subagent 接收問題清單進行修復
3. 修復完成後，重新執行該審查階段
4. 同一審查階段連續失敗 3 次，升級至 Architect 評估是否有設計問題

---

### L-size Story 審查增強

**觸發條件**：Story Size = L（3 points）時自動啟用增強審查，以下 checklist 項目為額外必要通過條件。

- [ ] **Architect 設計審查**：L-size Story 實作開始前，Architect 必須確認設計方向（介面定義、模組邊界、資料流），避免大型 Story 因設計問題在後期返工。Developer subagent 需在 prompt 中包含 Architect 確認的設計摘要，方可開始 TDD 循環。
- [ ] **分階段驗收**：將 Story 的 Acceptance Criteria 分為至少 2 個驗收批次（例如：核心路徑為第一批，邊界條件與錯誤處理為第二批），每批 AC 通過 Spec Compliance Review 後，再繼續下一批實作。若任一批次不通過，僅需針對該批次修復，不影響已通過批次。
- [ ] **額外回歸測試掃描**：L-size Story 完成後，除執行新增測試外，必須執行既有測試套件的完整掃描，確認無回歸失敗。掃描結果須明確記錄於 Story 完成 commit message（格式：`全部 N 項測試通過，無回歸`）。

---

## 7. 安全審查觸發條件

以下情況自動觸發 Security subagent：

- Story 涉及外部使用者輸入處理
- 新增或修改 API 端點
- 涉及認證 / 授權邏輯
- 涉及加密 / 金鑰管理
- 涉及配置變更或環境變數

---

## 8. 與其他 Skill 的關係

| 情境 | 觸發 |
|------|------|
| 發現需求不清 | 暫停，升級至 PO 釐清 → 回到 sprint-execution |
| 發現需要架構決策 | 暫停，觸發 `architecture-decision` → ADR 定案後回到 sprint-execution |
| 所有 Story 完成 | 觸發 `sprint-review` 進行驗收與回顧 |
| 發現安全問題 | 觸發 `security-review` 進行深度安全審查 |
