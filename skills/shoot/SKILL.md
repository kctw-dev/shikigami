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

`/shoot` 是跳過 Sprint 儀式的快速執行路徑，讓使用者可以快速完成小型任務。相較於完整 Sprint 流程，`/shoot` **保留** QA 雙階段審查與 Architect 技術審查（Hard Gate），但**跳過** Planning、Review、Retro、Metrics 等儀式。

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
[步驟 2] QA Pre-flight 審查（第一階段 Hard Gate）
  |-- FAIL --> exit code 非 0，Shoot_Log.md 無 PASS 記錄，不執行 shoot: commit
  +-- PASS
        |
        v
[步驟 3] Architect 審查（技術審查 Hard Gate）
  |-- FAIL --> exit code 非 0，Shoot_Log.md 無 PASS 記錄，不執行 shoot: commit
  +-- PASS
        |
        v
[步驟 4] 執行任務（實作）
        |
        v
[步驟 5] QA Post-check 審查（第二階段 Hard Gate）
  |-- FAIL --> exit code 非 0，Shoot_Log.md 無 PASS 記錄，不執行 shoot: commit
  +-- PASS
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
  |-- CI PASS → 繼續
  |-- CI FAIL → exit code 非 0，Shoot_Log.md 不寫 PASS，輸出失敗資訊，終止
  +-- CI 不可用 → 輸出 [WARN]，依降級行為繼續（見 §8.2）
        |
        v
[步驟 7] 更新 docs/km/Shoot_Log.md（寫入 PASS）與 docs/PROJECT_BOARD.md
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

## 8. QA 雙階段審查（Hard Gate）

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

### 第二階段：QA Post-check

實作完成後由 QA subagent 執行後審，確認：

- 所有 Acceptance Criteria 通過
- 測試覆蓋完整
- 無迴歸

**輸出格式**：

```
── QA Post-check ──────────────────────
  [PASS/FAIL] AC 驗收
  [PASS/FAIL] 測試覆蓋
  [PASS/FAIL] 迴歸檢查
```

### Architect 審查

由 Architect subagent 確認：

- 實作方向符合既有架構
- 無需 ADR 觸發
- 技術選型合規

### 任一 FAIL 時的三個可觀察驗收點

當 QA Pre-flight、Architect 審查、QA Post-check 或 CI/CD 雙審查 Gate 任一回傳 FAIL 時：

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
| CI FAIL | `failure` / `cancelled` / `timed_out` | **不寫 PASS**，輸出失敗資訊，exit code 非 0，終止 |
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

── QA Pre-flight ──────────────────────
  [PASS] 任務範圍檢查
  [PASS] 安全疑慮檢查
  [PASS] 架構影響檢查

── Architect 審查 ─────────────────────
  [PASS] 架構符合性確認
  [PASS] 無 ADR 觸發

── 執行任務 ───────────────────────────
  ... 實作過程 ...

── QA Post-check ──────────────────────
  [PASS] AC 驗收
  [PASS] 測試覆蓋
  [PASS] 迴歸檢查

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
