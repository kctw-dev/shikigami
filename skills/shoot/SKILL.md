---
name: shoot
description: "Use when executing a single task quickly without full Sprint ceremony. Handles task selection, QA gates, implementation, and lightweight logging."
requiredTools:
  - Read
  - Glob
  - Grep
  - Edit
  - Write
  - Bash
---

# Shoot Skill — 短衝模式

**關聯 Story**：US-31（Issue #47）
**關聯 ADR**：ADR-003（Accepted）

## 1. 概述

`/shoot` 是跳過 Sprint 儀式的快速執行路徑，讓使用者可以快速完成小型任務。相較於完整 Sprint 流程，`/shoot` **保留與 Sprint Execution 相同品質的 QA 機制**（測試可寫性檢查、Spec Compliance、Code Quality、外部獨立審查、Architect 技術審查），但**跳過** Planning、Review、Retro、Metrics 等儀式。

**品質原則**：品質才是快。shoot 與 sprint-execution 的 QA 深度完全一致，只省 Sprint 儀式。

**適用場景**：Bug 修復、Retro Action Item、小型功能增強（Size=S）。

---

## 2. 觸發語法

```
/shoot                    # 自動抓取模式（依優先順序自動選取任務）
/shoot "任務描述"          # 直接描述模式（以文字作為任務標題）
/shoot #N                 # GitHub Issue 模式（執行指定 Issue）
/shoot US-XX              # Backlog Story 模式（執行指定 Story）
```

### 參數說明

| 語法 | 說明 |
|------|------|
| `/shoot`（無參數） | 自動抓取模式：依三層優先順序選取任務 |
| `/shoot "描述"` | 直接描述模式：以引號內文字為任務標題直接執行 |
| `/shoot #N` | GitHub Issue 模式：透過 `gh issue view #N` 取得 Issue 內容執行 |
| `/shoot US-XX` | Backlog Story 模式：優先從 GitHub Issues 查詢對應 Story，若無結果則 fallback 至 `docs/prd/PRODUCT_BACKLOG.md` |

---

## 3. 自動抓取模式（AC1）

執行 `/shoot`（無參數）時，依以下優先順序自動選取任務：

### 三層優先順序

| 優先順序 | 來源 | 命令 |
|---------|------|------|
| (1) 第一優先 | `bug` label 的 open Issue | `gh issue list --label "bug" --state open --limit 1` |
| (2) 第二優先 | `retro-action` label 的 open Issue | `gh issue list --label "retro-action" --state open --limit 1` |
| (3) 第三優先 | `docs/prd/PRODUCT_BACKLOG.md` 頂部 `Size=S` Story | 讀取 PRODUCT_BACKLOG.md，取第一筆 Size=S 的 Story |

### 抓取邏輯

```bash
# Step 1：嘗試 bug label
TASK=$(gh issue list --label "bug" --state open --limit 1 --json number,title 2>/dev/null)
if [[ -n "$TASK" && "$TASK" != "[]" ]]; then
  # 使用第一個 bug Issue
  ...
fi

# Step 2：嘗試 retro-action label
TASK=$(gh issue list --label "retro-action" --state open --limit 1 --json number,title 2>/dev/null)
if [[ -n "$TASK" && "$TASK" != "[]" ]]; then
  # 使用第一個 retro-action Issue
  ...
fi

# Step 3：嘗試 PRODUCT_BACKLOG.md 頂部 Size=S Story
# 讀取 docs/prd/PRODUCT_BACKLOG.md，取第一筆 Size=S 的 Story
```

### 三者均無時的錯誤處理

三者均無可用任務時，輸出錯誤訊息並終止：

```
[ERROR] 自動抓取失敗：無可用任務
  - bug label 無 open Issue
  - retro-action label 無 open Issue
  - PRODUCT_BACKLOG.md 無 Size=S Story
請改用 /shoot "描述"、/shoot #N 或 /shoot US-XX 指定任務。
```

---

## 4. 直接描述模式（AC2）

`/shoot "任務描述"` 將引號內的文字作為任務標題直接執行。

### 規則

- 描述文字**完整保留**，不截斷、不修改
- 描述完整寫入 `docs/km/Shoot_Log.md` 的標題欄位
- 來源欄位記錄為 `direct`

### 範例

```bash
# 使用者執行
/shoot "修復登入頁面 CORS 問題"

# 記錄至 Shoot_Log.md
| 2026-03-02 | direct | 修復登入頁面 CORS 問題 | PASS | abc1234 |
```

---

## 5. GitHub Issue 模式（AC3）

`/shoot #N` 透過 `gh issue view` 取得 Issue 標題與描述後執行。

### 執行步驟

```bash
gh issue view N --json number,title,body
```

### 錯誤處理

| 情境 | 處理方式 |
|------|----------|
| Issue 不存在（404） | 輸出 `[ERROR] Issue #N 不存在` 並終止，exit code 非 0 |
| gh CLI 未認證 | 輸出 `[ERROR] gh CLI 未認證，請執行 gh auth login` 並終止，exit code 非 0 |
| gh CLI 未安裝 | 輸出 `[ERROR] gh CLI 未安裝` 並終止，exit code 非 0 |

---

## 6. Backlog Story 模式（AC4）

`/shoot US-XX` 優先從 GitHub Issues 查詢對應 Story，若無結果則 fallback 至 `docs/prd/PRODUCT_BACKLOG.md`。

### 查詢優先序

1. **優先**：使用 `gh issue list` 搜尋 title 包含 US-XX 的 Issue
2. **Fallback**：若 GitHub Issues 無結果，讀取 `docs/prd/PRODUCT_BACKLOG.md`（輸出警告）
3. **兩者皆查無結果**：輸出錯誤並終止

### Story ID 比對邏輯

```bash
# Step 1：優先查詢 GitHub Issues（搜尋 title 包含 US-XX 的 backlog-item Issue）
STORY_ID="US-XX"  # 替換為實際 Story ID，如 US-78
ISSUES=$(gh issue list --label "type: backlog-item" --state open \
  --json number,title,body --limit 200 2>/dev/null)

# 過濾 title 包含 Story ID 的 Issue
MATCHED=$(echo "$ISSUES" | jq --arg id "$STORY_ID" \
  '[.[] | select(.title | test($id; "i"))] | first')

if [[ -n "$MATCHED" && "$MATCHED" != "null" ]]; then
  # 使用 GitHub Issue 作為 Story 來源
  ISSUE_NUMBER=$(echo "$MATCHED" | jq '.number')
  STORY_BODY=$(echo "$MATCHED" | jq -r '.body')
  # 繼續執行...
else
  # Step 2：Fallback 至 PRODUCT_BACKLOG.md
  echo "[WARN] 從歷史快照讀取：docs/prd/PRODUCT_BACKLOG.md"
  if [[ ! -f "docs/prd/PRODUCT_BACKLOG.md" ]]; then
    echo "[ERROR] 找不到 Story $STORY_ID"
    exit 1
  fi
  MATCHED_LINE=$(grep -n "| $STORY_ID " docs/prd/PRODUCT_BACKLOG.md)
  if [[ -z "$MATCHED_LINE" ]]; then
    # Step 3：兩者皆查無結果
    echo "[ERROR] 找不到 Story $STORY_ID"
    exit 1
  fi
  # 使用 PRODUCT_BACKLOG.md 作為 Story 來源
fi
```

Story ID 需**精確比對**（`US-XX` 格式，大小寫不敏感）。

### 錯誤處理

| 情境 | 處理方式 |
|------|----------|
| GitHub Issues 無結果，fallback 至 PRODUCT_BACKLOG.md | 輸出 `[WARN] 從歷史快照讀取：docs/prd/PRODUCT_BACKLOG.md` 並繼續執行 |
| GitHub Issues 無結果且 PRODUCT_BACKLOG.md 也找不到 | 輸出 `[ERROR] 找不到 Story US-XX` 並終止，exit code 非 0 |
| PRODUCT_BACKLOG.md 不存在（fallback 時） | 輸出 `[ERROR] 找不到 Story US-XX` 並終止，exit code 非 0 |
| gh CLI 未認證 | 輸出 `[ERROR] gh CLI 未認證，請執行 gh auth login` 並終止，exit code 非 0 |

---

## 7. 執行流程（AC8：Hard Gate 保留）

```
使用者執行 /shoot [參數]
  |
  v
[步驟 1] 任務解析（依觸發語法確定任務來源與內容）
  |-- 解析失敗 --> 輸出錯誤，exit code 非 0，終止
  +-- 解析成功
        |
        v
[步驟 1.1] Claim Issue（US-312，有 GitHub Issue number 時）
  若任務來源為 #N 或 US-XX（可對應 Issue），執行：
  claim_issue <issue_number>
  |-- [CLAIM-OK]      --> 繼續執行（已取得 issue 鎖）
  |-- [CLAIM-BLOCKED] --> 輸出 [WARN]，繼續執行（不阻塞 shoot）
  +-- git push 失敗   --> 輸出 [WARN]，繼續執行（保守策略）
  無 Issue number（direct 模式）→ 跳過 claim
        |
        v
[步驟 1.2] SDD-000 存在性檢查
  確認 docs/sdd/SDD-000-architecture.md 是否存在
  |-- 不存在 --> 建立 SDD-000（複製 templates/SDD-000-architecture.md + {日期} 替換）
  |              建立完成後終止當前 shoot，輸出提示：
  |              「SDD-000 已建立，請重新執行 /shoot」
  |              exit code 0（建立成功，非錯誤終止）
  +-- 存在 --> 繼續
        |
        v
[步驟 1.5] 測試可寫性檢查（TC-W1~W5 Hard Gate，見 §8.4）
  |-- FAIL --> 回傳結構化問題清單，禁止進入實作，終止
  +-- PASS
        |
        v
[步驟 2] QA Pre-flight 審查（第一階段 Hard Gate）
  |-- FAIL --> exit code 非 0，Shoot_Log.md 無 PASS 記錄，不執行 shoot: commit
  +-- PASS
        |
        v
[步驟 3] Architect 審查（技術審查 Hard Gate，含 DM-1/DM-2/DM-3/DM-4）
  |-- FAIL --> exit code 非 0，Shoot_Log.md 無 PASS 記錄，不執行 shoot: commit
  +-- PASS
        |
        v
[步驟 4] 執行任務（實作）
        |
        v
[步驟 4.5] 測試執行 + Systematic Debugging（見 §8.3）
  執行本地測試（unit test / integration test）
  |-- 測試全部通過 → 繼續
  +-- 測試失敗 → invoke shikigami:systematic-debugging（根因排查）
        |-- 修復成功 → 重新執行測試，通過後繼續
        +-- 修復失敗 → exit code 非 0，Shoot_Log.md 無 PASS 記錄，終止
        |
        v
[步驟 5] QA Post-check 審查（完整品質審查 Hard Gate，見 §8）
  包含：Spec Compliance + Code Quality（CQ-NEW / CQ-MOCK / CQ-SMOKE / CQ-DATA）
  |-- FAIL --> 內部修復，最多重試 3 次；3 次仍 FAIL → 終止
  +-- PASS
        |
        v
[步驟 5.3] 外部獨立審查（100%，見 §8.5）
  由獨立 QA subagent（非實作者）重新驗證 Spec Compliance + Code Quality
  |-- CONFIRM → 繼續
  +-- DISPUTE → 回傳缺陷清單，修復後強制第二輪外部審查
        |-- 第二輪 CONFIRM → 繼續
        +-- 第二輪 DISPUTE → 升級至 Architect，終止
        |
        v
[步驟 5.4] pr-review-toolkit 補充審查（見 §8.6）
  平行派遣 code-reviewer / silent-failure-hunter / comment-analyzer
  |-- Plugin 未安裝 → [WARN] 跳過，繼續
  |-- Doc-only → 僅執行 comment-analyzer
  |-- 全部 PASS（無 CRITICAL/HIGH）→ 繼續
  +-- CRITICAL/HIGH 發現 → 修復 → 重新審查
        |-- 二審 PASS → 繼續
        +-- 二審仍 CRITICAL/HIGH → 升級 Architect，終止
        |
        v
[步驟 5.5] CI/CD 雙審查 Gate（條件觸發，見 §8.1）
  偵測 .github/workflows/**、scripts/deploy*.sh、scripts/add_secret.sh、
  Dockerfile*、cloudbuild*.yaml、docker-compose*.yml 是否被修改
  |-- 偵測到 CI/CD 變更
  │     ├─ QA regression check FAIL → exit code 非 0，禁止 shoot: commit
  │     └─ SRE infra config check FAIL → exit code 非 0，禁止 shoot: commit
  +-- 無 CI/CD 變更 → SKIP
        |
        v
[步驟 6] git commit（以 shoot: 前綴）+ git push
        |
        v
[步驟 6.5] CI Gate — 等待 CI 狀態（見 §8.2）
  |-- Doc-only 變更 → SKIP，直接繼續
  |-- CI PASS → 繼續
  |-- CI FAIL → invoke shikigami:systematic-debugging（CI FAIL 根因排查）
  |     |-- 修復成功 → 重新 commit + push，回到 CI Gate 等待
  |     +-- 修復失敗 → exit code 非 0，Shoot_Log.md 不寫 PASS，輸出失敗資訊，終止
  +-- CI 不可用 → 輸出 [WARN]，依降級行為繼續（見 §8.2）
        |
        v
[步驟 7] 更新 docs/km/Shoot_Log.md（寫入 PASS）與 docs/PROJECT_BOARD.md
        |
        v
[步驟 7.5] Release Issue（US-312，有 GitHub Issue number 時）
  若步驟 1.1 執行了 claim，執行：
  release_issue <issue_number>
  → [CLAIM-RELEASE] refs/claims/<issue_number>
  失敗不阻塞（|| true）
  無 Issue number → 跳過 release
        |
        v
[步驟 8] 瘦身歸檔檢查（若 Shoot_Log.md > 20 筆則觸發歸檔）
        |
        v
輸出完成訊息
```

### 明確跳過項目

`/shoot` **跳過**以下 Sprint 儀式，不執行：

| 跳過項目 | 說明 |
|---------|------|
| Sprint Planning | 不進行 Story 點數估算與 Sprint 規劃 |
| Sprint Review | 不進行 Demo 展示與 PO/Stakeholder 驗收 |
| Sprint Retro | 不進行 Good/Problem/Action 收集 |
| Sprint Metrics | 不計算 Velocity，不更新 Metrics_Log.md |

---

## 8. QA 完整品質審查（與 Sprint Execution 對齊）

<!-- Issue #257 — Shoot QA 補齊：與 Sprint Execution 品質對齊 -->

### 第一階段：QA Pre-flight

在實作前由 QA subagent 執行預審，確認：

- 任務範圍明確，不超過 Size=S
- 無安全疑慮（外部輸入、認證、授權）
- 無架構影響（若有，升級至 Architect 處理）

**輸出格式**：

```
── QA Pre-flight ──────────────────────
  [PASS/FAIL] 任務範圍檢查
  [PASS/FAIL] 安全疑慮檢查
  [PASS/FAIL] 架構影響檢查
```

### 第二階段：QA Post-check（Spec Compliance + Code Quality）

實作完成後由 QA subagent 執行完整品質審查，**與 sprint-execution story-lifecycle 的 §5-§6 審查標準一致**。

#### Spec Compliance 審查

- 逐一讀取原始任務 AC / Issue 描述，對照實作逐條驗證
- 邊界條件檢查（`[動態]` AC 執行、Edge case、錯誤路徑）
- 行為範例驗證（`[行為]` AC 的 Given-When-Then 場景）

#### Code Quality 審查

**通用靜態分析**：命名可讀性、結構設計（函式 < 20 行）、測試品質（Arrange-Act-Assert）、安全性基礎

**條件觸發的品質清單**（與 story-lifecycle-prompt.md §6 一致）：

| 清單 | 觸發條件 | 檢查項目 |
|------|---------|---------|
| **CQ-NEW** | 新增程式碼 | CQ-NEW-1 測試覆蓋率、CQ-NEW-2 舊測試一致性 |
| **CQ-MOCK** | 使用 Mock/Stub | CQ-MOCK-1 回應格式一致性、CQ-MOCK-2 資料範圍合理性、CQ-MOCK-3 錯誤情境覆蓋、CQ-MOCK-4 Mock 範圍最小化 |
| **CQ-SMOKE** | 涉及外部資源 | CQ-SMOKE-1 外部資源識別、CQ-SMOKE-2 Smoke test 存在、CQ-SMOKE-3 使用真實資料、CQ-SMOKE-4 假設覆蓋 |
| **CQ-DATA** | 涉及靜態資料檔 | CQ-DATA-1 覆蓋率指標定義、CQ-DATA-2 實際覆蓋率達標（**Hard Gate**）、CQ-DATA-3 Blast Radius 評估、CQ-DATA-4 測試集代表性 |

完整判定標準請參照 `skills/sprint-execution/story-lifecycle-prompt.md` §6。

#### 修復閉環

- FAIL 時若為 **Critical** 缺陷，進入 CRITICAL 互動決策點（選項 A/B/C，規則參見 `skills/quality-gate/SKILL.md` §7.1）
- 選擇 A（修復）後內部修復，不升級
- 選擇 B/C 強制寫入 `docs/km/quality-gate-decisions.md`（格式參見 `skills/quality-gate/SKILL.md` §7.2）
- 連續失敗 3 次（選擇 A 後仍 FAIL）→ 終止，exit code 非 0
- 同一任務連續選擇 B/C 超過 2 次 → 升級 Architect 審查

**輸出格式**：

```
── QA Post-check ──────────────────────
  Spec Compliance：
    [PASS/FAIL] AC 逐條驗證
    [PASS/FAIL] 邊界條件檢查
    [PASS/FAIL] 行為範例驗證（若適用）
  Code Quality：
    [PASS/FAIL] 通用靜態分析
    [PASS/FAIL] CQ-NEW 測試覆蓋（若適用）
    [PASS/FAIL] CQ-MOCK Mock 假設驗證（若適用）
    [PASS/FAIL] CQ-SMOKE Smoke 測試（若適用）
    [PASS/FAIL] CQ-DATA 靜態資料覆蓋（若適用）
```

### Architect 審查

由 Architect subagent 確認：

- 實作方向符合既有架構
- 無需 ADR 觸發
- 技術選型合規

**Layer Compliance checklist**（分層合規檢查）：

- [ ] Layer Compliance 共用常數/設定層級檢查：常數與設定值置於正確的共用層，不得散落於業務邏輯層或個別模組
- [ ] Layer Compliance 跨模組 import 方向檢查：import 方向必須符合分層架構單向依賴原則，不得出現跨層或逆向 import
- [ ] Layer Compliance Single Source of Truth 檢查：語意相同的常數或設定不得在多處重複定義，必須維持單一來源

**領域模型審查**（DM checklist，見 `skills/architect/SKILL.md` §10）：

- [ ] DM-1 業務邏輯封裝：業務邏輯封裝在 Service 層，Router 只做 I/O
- [ ] DM-2 Single Source of Truth：相同業務邏輯只有一個實作來源
- [ ] DM-3 狀態轉換統一：狀態轉換有統一對照表，不散落各處
- [ ] DM-4 共享寫入入口：共享資源有唯一寫入入口（Gateway），類別圖標示依賴方向

### 任一 FAIL 時的三個可觀察驗收點

當 QA Pre-flight、Architect 審查、QA Post-check、外部獨立審查或 CI/CD 雙審查 Gate 任一回傳 FAIL 時：

| 可觀察點 | 說明 |
|---------|------|
| (a) exit code 非 0 | process 以錯誤碼結束 |
| (b) Shoot_Log.md 中該次任務無 PASS 記錄 | log 筆數不增加，Shoot_Log.md 保持不變 |
| (c) 不執行 `shoot:` 前綴的 git commit | commit 狀態為未提交 |

---

## 8.1 CI/CD 雙審查 Gate（條件觸發）

<!-- US-189 CI/CD 變更強制 QA + SRE 雙審查 Gate — Sprint 72 -->

在 QA Post-check 通過後、執行 `shoot:` commit 前，偵測本次任務修改的檔案是否包含 CI/CD 相關路徑。

### CI/CD 路徑 Pattern

| Pattern | 範例 |
|---------|------|
| `.github/workflows/**` | `.github/workflows/deploy.yml` |
| `scripts/deploy*.sh` | `scripts/deploy-prod.sh` |
| `scripts/add_secret.sh` | `scripts/add_secret.sh` |
| `Dockerfile*` | `Dockerfile`、`Dockerfile.prod` |
| `cloudbuild*.yaml` | `cloudbuild.yaml`、`cloudbuild-staging.yaml` |
| `docker-compose*.yml` | `docker-compose.yml`、`docker-compose.prod.yml` |

### 審查規則

偵測到 CI/CD 變更後，**QA regression check 與 SRE infra config check 兩者均必須 PASS，才允許執行 `shoot:` commit**。

完整審查項目定義請參照 `skills/sprint-execution/story-lifecycle-prompt.md` §6.8「CI/CD 雙審查 Gate」。

<HARD-GATE>
**CI/CD 雙審查 Hard Gate（/shoot）**：偵測到 CI/CD 路徑變更時，QA regression check 與 SRE infra config check **兩者均必須 PASS**，才允許執行 `shoot:` git commit。任一 FAIL → exit code 非 0，禁止 commit。
</HARD-GATE>

---

## 8.2 CI Gate（US-241）

<!-- US-241 shoot CI Gate — CI pass 才標 PASS — Sprint 88 -->

在 `shoot:` commit + `git push` 完成後、寫 `Shoot_Log.md` PASS 前，執行 CI 狀態等待與驗證。

### Doc-only 跳過規則

若本次修改的檔案**全部**符合以下 pattern，視為 doc-only 變更，**跳過 CI Gate**：

| Pattern | 說明 |
|---------|------|
| `docs/**` | 文件目錄 |
| `**/*.md` | 所有層級的 Markdown 文件 |
| `skills/**/*.md` | Skill 定義文件 |
| `agents/**/*.md` | Agent 定義文件 |
| `templates/**/*.md` | 範本文件 |

輸出：
```
── CI Gate ────────────────────────────
  [SKIP] Doc-only 變更，跳過 CI Gate
```

### 執行步驟

```bash
# Step 1：取得最新的 CI run（push 後觸發的 workflow）
CI_RUN=$(gh run list --limit 1 --json databaseId,name,status,conclusion,url \
  2>/dev/null)

# Step 2：若 run 尚在執行中，等待完成（最多 10 分鐘）
RUN_ID=$(echo "$CI_RUN" | jq -r '.[0].databaseId // empty')
if [[ -n "$RUN_ID" ]]; then
  gh run watch "$RUN_ID" --exit-status 2>/dev/null
  CONCLUSION=$(gh run view "$RUN_ID" --json conclusion -q '.conclusion' 2>/dev/null)
fi
```

### CI Gate 判斷規則

| 情況 | CONCLUSION 值 | 行為 |
|------|---------------|------|
| CI PASS | `success` | 繼續，寫 Shoot_Log.md PASS |
| CI FAIL | `failure` / `cancelled` / `timed_out` | 觸發 `invoke shikigami:systematic-debugging`（CI FAIL 根因排查）；修復成功 → 重新 commit + push + 等待 CI；修復失敗 → **不寫 PASS**，輸出失敗資訊，exit code 非 0，終止 |
| CI 不可用 | — | 依降級行為處理（見下方） |

### CI FAIL 輸出格式（AC3）

```
── CI Gate ────────────────────────────
  [FAIL] CI 檢查未通過，中止寫入 Shoot_Log PASS
  Workflow：<workflow 名稱>
  Run URL ：<run URL>
  結論    ：<conclusion>

[ERROR] CI Gate FAIL，終止執行
  - exit code：1（非 0）
  - Shoot_Log.md 未更新（無 PASS 記錄）
```

### CI 不可用時的降級行為（AC4）

CI 不可用情境包括：`gh` CLI 未安裝、未認證、repo 無 CI workflow 配置、`gh run list` 回傳空結果。

| 情境 | 偵測條件 | 降級行為 |
|------|---------|---------|
| `gh` CLI 未安裝 | `command -v gh` 失敗 | 輸出 `[WARN] gh CLI 未安裝，跳過 CI Gate`，繼續寫 PASS |
| `gh` CLI 未認證 | `gh auth status` 失敗 | 輸出 `[WARN] gh CLI 未認證，跳過 CI Gate`，繼續寫 PASS |
| repo 無 CI workflow | `gh run list` 回傳 `[]` | 輸出 `[WARN] 無 CI workflow，跳過 CI Gate`，繼續寫 PASS |
| `gh run list` 執行失敗 | exit code 非 0 | 輸出 `[WARN] CI 狀態查詢失敗，跳過 CI Gate`，繼續寫 PASS |

降級輸出格式：

```
── CI Gate ────────────────────────────
  [WARN] <降級原因>，跳過 CI Gate
  CI Gate 已略過，手動確認 CI 狀態後再繼續
```

<HARD-GATE>
**CI Gate Hard Gate（/shoot）**：git push 完成後，CI PASS 才允許寫入 Shoot_Log.md PASS。CI FAIL → exit code 非 0，Shoot_Log.md 不寫 PASS 記錄，不輸出完成訊息。CI 不可用時採降級行為（輸出 WARN，繼續執行）。
</HARD-GATE>

---

## 8.3 測試執行 + Systematic Debugging（步驟 4.5）

<!-- Sprint 90 — 新增寫完程式立即測試 + systematic debugging 觸發點 -->

在步驟 4（實作）完成後、步驟 5（QA Post-check）之前，**立即執行本地測試**，確保程式碼在 commit 前就通過測試，不等到 CI Gate 才發現問題。

### 執行步驟

1. **執行本地測試**：跑 unit test / integration test（依專案測試框架）
2. **測試全部通過** → 繼續步驟 5（QA Post-check）
3. **測試失敗** → 觸發 `invoke shikigami:systematic-debugging`，告知目的為「shoot 實作後測試失敗根因排查」
4. **修復後重新測試**：systematic debugging 完成修復後，重新執行測試
   - 通過 → 繼續步驟 5
   - 仍失敗 → exit code 非 0，Shoot_Log.md 無 PASS 記錄，終止

### 與 CI Gate（§8.2）的關係

步驟 4.5 在 commit **之前**攔截測試失敗，§8.2 CI Gate 在 push **之後**攔截 CI 環境特有的失敗（如環境差異、依賴衝突）。兩者互補：

| 觸發點 | 時機 | 抓的問題 |
|--------|------|---------|
| 步驟 4.5（本地測試） | commit 前 | 邏輯錯誤、回歸、型別錯誤 |
| §8.2 CI Gate | push 後 | 環境差異、CI 專屬檢查（lint rules、coverage threshold） |

兩處測試失敗均可觸發 `invoke shikigami:systematic-debugging` 進行根因排查。

---

## 8.4 測試可寫性檢查（步驟 1.5）

<!-- Issue #257 — 移植 story-lifecycle-prompt.md §3 TC-W1~W5 -->

在任務解析完成後、QA Pre-flight 之前，**檢查任務描述 / AC 是否可轉化為測試**。此步驟與 sprint-execution story-lifecycle 的測試可寫性檢查完全一致。

### 檢查條件

| 條件 | 判斷標準 | 說明 |
|------|---------|------|
| **TC-W1** | AC 描述模糊無法寫 assertion | 使用「適當」、「正確」、「合理」等主觀詞，無法轉化為可驗證斷言 |
| **TC-W2** | AC 缺少輸入/輸出定義 | 未定義輸入資料格式、邊界值、或預期的輸出值/狀態碼/回應結構 |
| **TC-W3** | AC 涉及未定義的外部依賴 | 依賴尚未定義的外部系統行為、API 契約、或第三方服務規格 |
| **TC-W4** | AC 之間存在邏輯矛盾 | 多個 AC 相互排斥，無法同時滿足 |
| **TC-W5** | AC 完成標準無法量測 | 驗收標準為主觀定性判斷，無法轉化為自動化測試 |

### 處理流程

- 任一 AC 觸發 TC-W1 ~ TC-W5 → 測試可寫性檢查 FAIL
- 輸出結構化問題清單，要求釐清後重新執行
- **禁止進入實作**（Hard Gate）

### 輸出格式

```
── 測試可寫性檢查 ─────────────────────
  [PASS] 所有 AC 可轉化為測試
```

FAIL 時：

```
── 測試可寫性檢查 ─────────────────────
  [FAIL] 以下 AC 無法轉化為測試：
    - AC2：觸發 TC-W1（「適當處理」無法寫 assertion）
    - AC5：觸發 TC-W2（未定義預期回應格式）

[ERROR] 測試可寫性檢查 FAIL，終止執行
  請釐清以上問題後重新執行 /shoot
```

<HARD-GATE>
**測試可寫性 Hard Gate（/shoot）**：TC-W1 ~ TC-W5 任一觸發 → 禁止進入實作，exit code 非 0。
</HARD-GATE>

---

## 8.5 外部獨立審查（步驟 5.3）

<!-- Issue #257 — 移植 sprint-execution/SKILL.md §3-4 外部抽樣機制 -->

在 QA Post-check 通過後、CI/CD 雙審查 Gate 前，由**獨立 QA subagent**（非執行實作的 agent）重新驗證品質。

### 與 Sprint Execution 的差異

| 面向 | Sprint Execution | Shoot |
|------|-----------------|-------|
| 抽樣率 | 30% 基礎，風險升級至 100% | **固定 100%**（單任務，無抽樣意義） |
| 審查內容 | Spec Compliance + Code Quality | **相同** |
| DISPUTE 處理 | 回傳缺陷 → 修復 → 二審 | **相同** |
| 審查 agent | 獨立 sonnet subagent | **相同** |

### 執行流程

1. 派遣獨立 QA subagent（model: sonnet），傳入：
   - 原始任務描述 / AC
   - 實作修改的檔案清單與 diff
2. 獨立 subagent 執行 Spec Compliance + Code Quality 審查
3. 回傳結果：**CONFIRM** 或 **DISPUTE**

### CONFIRM 路徑

記錄結果，繼續步驟 5.5（CI/CD 雙審查 Gate）。

### DISPUTE 路徑

1. 回傳結構化缺陷清單（含嚴重度：Critical / Major / Minor）
2. 實作者修復缺陷
3. **強制第二輪外部審查**（無論缺陷嚴重度）
4. 第二輪結果：
   - CONFIRM → 繼續
   - DISPUTE → 升級至 Architect，exit code 非 0，終止

### 輸出格式

```
── 外部獨立審查 ───────────────────────
  [CONFIRM] Spec Compliance + Code Quality 通過
```

DISPUTE 時：

```
── 外部獨立審查 ───────────────────────
  [DISPUTE] 發現以下缺陷：
    - [Critical] AC3 實作偏離描述：預期回傳 404，實際回傳 500
    - [Minor] 函式 processOrder 超過 20 行

  修復中...

── 外部獨立審查（第二輪） ─────────────
  [CONFIRM] 缺陷已修復，品質通過
```

<HARD-GATE>
**外部獨立審查 Hard Gate（/shoot）**：固定 100% 外部獨立審查。DISPUTE 後強制二審，二審仍 DISPUTE → 升級 Architect，exit code 非 0，禁止 commit。
</HARD-GATE>

---

## 8.6 pr-review-toolkit 補充審查（步驟 5.4）

<!-- Story #266 — 整合 pr-review-toolkit 審查 agents 至 commit 前 Gate -->
<!-- 設計 SSOT：docs/adr/ADR-021-pr-review-toolkit-integration.md -->

在外部獨立審查（步驟 5.3）CONFIRM 後、CI/CD 雙審查 Gate（步驟 5.5）前，追加 pr-review-toolkit 三個專業審查 agent 作為**工程品質深度補充層**。

**與步驟 5.3 的責任邊界**：步驟 5.3 負責 **Spec Compliance**（AC 逐條驗證、邊界條件），步驟 5.4 負責**工程品質深度**（跨檔案一致性、降級路徑、文件準確性）。兩者互補，不重疊核心職責。詳見 ADR-021 §4 責任矩陣。

### 三 agent 平行派遣

透過 Claude Code `Agent` tool 平行派遣三個 subagent：

```
Agent 1: subagent_type: "pr-review-toolkit:code-reviewer"
  → 審查跨檔案一致性、命名規範、CLAUDE.md 合規
  → 輸入: git diff

Agent 2: subagent_type: "pr-review-toolkit:silent-failure-hunter"
  → 審查降級路徑、fallback 行為、error handling
  → 輸入: git diff

Agent 3: subagent_type: "pr-review-toolkit:comment-analyzer"
  → 審查文件準確性、comment 與程式碼一致性
  → 輸入: git diff
```

### 嚴重度 Gate 規則

各 agent 使用不同嚴重度系統，統一對照至框架四級制（完整對照表見 ADR-021 §1 嚴重度對照表）：

| 嚴重度 | 行為 | 說明 |
|--------|------|------|
| **CRITICAL** | **阻擋** — 必須修復後重新審查 | Hard Gate |
| **HIGH** | **阻擋** — 必須修復後重新審查 | Hard Gate |
| **MEDIUM** | **記錄** — 寫入審查報告，不阻擋 | Soft Gate |
| **LOW** | **記錄** — 寫入審查報告，不阻擋 | 僅供參考 |

### 修復閉環

CRITICAL/HIGH 阻擋時：
1. 修復問題
2. 重新派遣**所有**第一輪回報 CRITICAL/HIGH 的 agent 進行第二輪審查（非僅修復對象的單一 agent）
3. 第二輪仍有任一 agent 回報 CRITICAL/HIGH → **升級至 Architect，終止**

### doc-only 條件觸發

複用 §8.2 CI Gate 已定義的 doc-only pattern（SSOT，不重複定義）：

| Agent | doc-only 變更 | 非 doc-only 變更 |
|-------|--------------|-----------------|
| `code-reviewer` | **跳過** — 無程式碼可審 | 執行 |
| `silent-failure-hunter` | **跳過** — 無 error handling 可審 | 執行 |
| `comment-analyzer` | **執行** — .md 文件準確性仍需審查 | 執行 |

**doc-only 判定**：複用 §8.2 的判定邏輯與 pattern 清單。

### 降級行為

複用 §8.2 CI Gate 的降級模式（WARN + 跳過 + 繼續）：

| 情境 | 降級行為 |
|------|---------|
| Plugin 未安裝 | 輸出 `[WARN]`，跳過步驟 5.4，繼續 |
| 部分 agent 不可用 | 該 agent 輸出 `[WARN]`，其餘 agent 正常執行 |
| Agent 回應異常 | 該 agent 輸出 `[WARN]`，其餘 agent 正常執行 |
| Agent 回應正常但嚴重度解析失敗（無法提取任何嚴重度項目） | 視為回應異常，該 agent 輸出 `[WARN]`，不視為 `[PASS]` |

**設計原則**：pr-review-toolkit 是**增強層**，非**必要層**。未安裝不阻擋流程，品質底線由步驟 5.3 的外部獨立審查保障。

### 輸出格式

五種情境範例（基於 ADR-021 §7 輸出格式，新增 doc-only CRITICAL 情境）：

**正常 PASS**：
```
── pr-review-toolkit 補充審查 ────────
  code-reviewer：      [PASS] 無 CRITICAL/HIGH issue
  silent-failure-hunter：[PASS] 無 CRITICAL/HIGH issue
  comment-analyzer：    [PASS] 無 Critical Issues
```

**有 CRITICAL/HIGH（阻擋）**：
```
── pr-review-toolkit 補充審查 ────────
  code-reviewer：      [FAIL] 發現 HIGH issue
    - [HIGH] handler.js L28: 跨檔案命名不一致（confidence: 85）
  silent-failure-hunter：[PASS] 無 CRITICAL/HIGH issue
  comment-analyzer：    [PASS] 無 Critical Issues

  修復中...

── pr-review-toolkit 補充審查（第二輪）──
  code-reviewer：      [PASS] 無 CRITICAL/HIGH issue
```

**doc-only 變更**：
```
── pr-review-toolkit 補充審查 ────────
  code-reviewer：      [SKIP] Doc-only 變更
  silent-failure-hunter：[SKIP] Doc-only 變更
  comment-analyzer：    [PASS] 無 Critical Issues
```

**doc-only + comment-analyzer CRITICAL（阻擋）**：
```
── pr-review-toolkit 補充審查 ────────
  code-reviewer：      [SKIP] Doc-only 變更
  silent-failure-hunter：[SKIP] Doc-only 變更
  comment-analyzer：    [FAIL] 發現 Critical Issues
    - [CRITICAL] docs/adr/ADR-021.md L45: 文件描述與實際行為不符

  修復中...

── pr-review-toolkit 補充審查（第二輪）──
  comment-analyzer：    [PASS] 無 Critical Issues
```

**降級（未安裝）**：
```
── pr-review-toolkit 補充審查 ────────
  [WARN] pr-review-toolkit 未安裝，跳過補充審查
  提示：安裝 pr-review-toolkit 可獲得跨檔案一致性、降級路徑、文件準確性的專業審查
  安裝方式：Claude Code → /plugins → 搜尋 "pr-review-toolkit" → Install
```

<HARD-GATE>
**pr-review-toolkit 補充審查 Hard Gate（/shoot）**：步驟 5.4 派遣 pr-review-toolkit 三 agent 平行審查。CRITICAL/HIGH 嚴重度阻擋 commit，修復後二審仍 CRITICAL/HIGH → 升級 Architect，exit code 非 0，禁止 commit。Plugin 未安裝時採降級行為（WARN + 跳過 + 繼續）。
</HARD-GATE>

---

## 9. 文件產出（AC5）

每次 `/shoot` 成功完成後，同時更新以下兩份文件：

### 9.1 docs/km/Shoot_Log.md

**格式**（Markdown 表格）：

```markdown
## Shoot Log

| 日期 | 來源 | 標題 | 結果 | commit hash |
|------|------|------|------|-------------|
| YYYY-MM-DD | auto/direct/#N/US-XX | 任務標題 | PASS | abc1234 |
```

**欄位說明**：

| 欄位 | 格式 | 說明 |
|------|------|------|
| 日期 | `YYYY-MM-DD` | 任務完成日期 |
| 來源 | `auto` / `direct` / `#N` / `US-XX` | 任務來源類型 |
| 標題 | 原始任務文字 | 完整保留，不截斷 |
| 結果 | `PASS` / `FAIL` | 執行結果（FAIL 時不寫入） |
| commit hash | 7 碼 short hash | `shoot:` commit 的 hash |

**Shoot_Log.md 不存在時**：自動建立，包含表格標題行。

### 9.2 docs/PROJECT_BOARD.md 短衝記錄

在 `docs/PROJECT_BOARD.md` 的「短衝記錄」區塊新增條目：

```markdown
## 短衝記錄

| 日期 | 標題 | Issue/Story | commit hash |
|------|------|-------------|-------------|
| YYYY-MM-DD | 任務標題 | #N 或 US-XX 或 — | abc1234 |
```

若「短衝記錄」區塊不存在，在 `PROJECT_BOARD.md` 末尾新增此區塊。

### 9.3 git commit 格式

```bash
git commit -m "shoot: <任務標題>"
```

---

## 10. 瘦身歸檔（AC6）

### 觸發條件

`docs/km/Shoot_Log.md` 主文件超過 **20 筆**記錄時觸發歸檔。

### 歸檔規則

- **目標**：移至**恰好保留 20 筆**（移走 `筆數 - 20` 筆）
- **移出對象**：最舊的 `筆數 - 20` 筆記錄
- **移出目標**：附加至 `docs/km/archive/SHOOT_LOG_ARCHIVE.md`
- **更新文件**：同步更新 `docs/km/archive/README.md` 的歸檔範圍欄位與最後更新日期

### 邊界測試情境

| 總筆數 | 移出筆數 | 剩餘筆數 | 說明 |
|--------|---------|---------|------|
| 20 | 0 | 20 | **20 筆不觸發**歸檔 |
| 21 | 1 | 20 | **21 筆**移出 1 筆 |
| 25 | 5 | 20 | 移出 5 筆 |
| 26 | 6 | 20 | 移出 6 筆 |

### 歸檔計算公式

```bash
# 計算需移出筆數
TOTAL=$(count_shoot_log_entries "docs/km/Shoot_Log.md")
KEEP=20
if [ "$TOTAL" -gt "$KEEP" ]; then
  ARCHIVE_COUNT=$((TOTAL - KEEP))
  # 移出最舊的 ARCHIVE_COUNT 筆記錄至 SHOOT_LOG_ARCHIVE.md
fi
```

### SHOOT_LOG_ARCHIVE.md 格式

```markdown
# Shoot Log Archive

| 日期 | 來源 | 標題 | 結果 | commit hash |
|------|------|------|------|-------------|
| YYYY-MM-DD | auto | 任務標題 | PASS | abc1234 |
```

---

## 11. 動態建立的檔案

以下檔案由 Shoot Skill 在首次執行時動態建立，不需預先建立：

| 檔案路徑 | 建立時機 | 說明 |
|---------|---------|------|
| `docs/km/Shoot_Log.md` | 首次 `/shoot` 成功完成時 | 短衝記錄主日誌 |
| `docs/km/archive/SHOOT_LOG_ARCHIVE.md` | 首次觸發歸檔時 | 超過 20 筆時的歸檔目標 |

---

## 12. Sprint Review 連動（AC7）

`/sprint-review` 執行時，會掃描 `docs/km/Shoot_Log.md`，將 Sprint 期間的短衝記錄列入「Sprint 外完成項目」區塊。

詳見 `skills/sprint-review/SKILL.md` 的相關段落。

---

## 13. 輸出範例

### 成功執行（/shoot "修復 CSS 問題"）

```
── 任務解析 ───────────────────────────
  來源：direct
  標題：修復 CSS 問題

── 測試可寫性檢查 ─────────────────────
  [PASS] 所有 AC 可轉化為測試

── QA Pre-flight ──────────────────────
  [PASS] 任務範圍檢查
  [PASS] 安全疑慮檢查
  [PASS] 架構影響檢查

── Architect 審查 ─────────────────────
  [PASS] 架構符合性確認
  [PASS] 無 ADR 觸發
  [PASS] Layer Compliance 共用常數/設定層級檢查
  [PASS] Layer Compliance 跨模組 import 方向檢查
  [PASS] Layer Compliance Single Source of Truth 檢查
  [PASS] DM-1 業務邏輯封裝檢查
  [PASS] DM-2 Single Source of Truth 檢查
  [PASS] DM-3 狀態轉換統一檢查
  [PASS] DM-4 共享寫入入口檢查

── 執行任務 ───────────────────────────
  ... 實作過程 ...

── QA Post-check ──────────────────────
  Spec Compliance：
    [PASS] AC 逐條驗證
    [PASS] 邊界條件檢查
  Code Quality：
    [PASS] 通用靜態分析
    [PASS] CQ-NEW 測試覆蓋

── 外部獨立審查 ───────────────────────
  [CONFIRM] Spec Compliance + Code Quality 通過

── pr-review-toolkit 補充審查 ────────
  code-reviewer：      [PASS] 無 CRITICAL/HIGH issue
  silent-failure-hunter：[PASS] 無 CRITICAL/HIGH issue
  comment-analyzer：    [PASS] 無 Critical Issues

── git commit + push ─────────────────
  ✓ git commit：shoot: 修復 CSS 問題（abc1234）
  ✓ git push 完成

── CI Gate ────────────────────────────
  [PASS] CI 檢查通過（workflow: CI / run: https://github.com/.../runs/123）

── 文件更新 ───────────────────────────
  ✓ Shoot_Log.md 已更新（PASS）
  ✓ PROJECT_BOARD.md 短衝記錄已更新

✓ 短衝完成 — 修復 CSS 問題
```

### FAIL 場景 — QA Pre-flight

```
── QA Pre-flight ──────────────────────
  [FAIL] 任務範圍超出 Size=S，建議拆分為多個子任務

[ERROR] QA Pre-flight FAIL，終止執行
  - exit code：1（非 0）
  - Shoot_Log.md 未更新（無 PASS 記錄）
  - git commit 未執行
```

### FAIL 場景 — CI Gate

```
── CI Gate ────────────────────────────
  [FAIL] CI 檢查未通過，中止寫入 Shoot_Log PASS
  Workflow：CI
  Run URL ：https://github.com/org/repo/actions/runs/456
  結論    ：failure

[ERROR] CI Gate FAIL，終止執行
  - exit code：1（非 0）
  - Shoot_Log.md 未更新（無 PASS 記錄）
```

### CI 不可用場景（降級）

```
── CI Gate ────────────────────────────
  [WARN] gh CLI 未安裝，跳過 CI Gate
  CI Gate 已略過，手動確認 CI 狀態後再繼續

── 文件更新 ───────────────────────────
  ✓ Shoot_Log.md 已更新（PASS，CI Gate 略過）
  ✓ PROJECT_BOARD.md 短衝記錄已更新
```

---

## 14. 與其他 Skill 的關係

| 情境 | 說明 |
|------|------|
| Sprint Review 時掃描 | `/sprint-review` 會讀取 Shoot_Log.md，列出「Sprint 外完成項目」 |
| 歸檔觸發 | 主文件超 20 筆時附加至 SHOOT_LOG_ARCHIVE.md |
| Hard Gate 保留 | QA 雙階段審查與 Architect 審查無論如何都保留，不可略過 |
