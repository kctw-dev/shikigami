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

### 人機協作配置（#415）

<!-- #415 Sprint 不應等待 stakeholder — 人機協作流程改善 -->

以下配置控制 shoot 的人機協作行為，可在 `.claude/shikigami.local.md` 中設定：

| 設定 | 預設值 | 說明 |
|------|--------|------|
| `shoot.skip_merge` | `false` | `true` 時跳過步驟 6.6（gh pr merge），PR 送出即視為 shoot 完成。Stakeholder 獨立決定 merge 時機 |
| `shoot.self_review` | `true` | PR 送出後、通知 stakeholder 前，執行 self-review（gh pr diff 重新確認） |
| `shoot.notify_stakeholder` | `true` | PR 送出後是否通知 stakeholder（Issue comment 或 assign） |

**讀取方式**：
```bash
CONFIG_FILE=".claude/shikigami.local.md"
SKIP_MERGE=$(grep -A10 'shoot:' "$CONFIG_FILE" 2>/dev/null | grep 'skip_merge:' | awk '{print $2}' | head -1)
SKIP_MERGE="${SKIP_MERGE:-false}"
SELF_REVIEW=$(grep -A10 'shoot:' "$CONFIG_FILE" 2>/dev/null | grep 'self_review:' | awk '{print $2}' | head -1)
SELF_REVIEW="${SELF_REVIEW:-true}"
```

---

## 2. 觸發語法

```
/shoot                    # 自動抓取模式（依優先順序自動選取任務）
/shoot "任務描述"          # 直接描述模式（以文字作為任務標題）
/shoot #N                 # GitHub Issue 模式（執行指定 Issue）
/shoot US-#N              # Backlog Story 模式（執行指定 Story，如 US-#312）
/shoot US-XX              # Backlog Story 模式（向後相容舊格式）
```

### 參數說明

| 語法 | 說明 |
|------|------|
| `/shoot`（無參數） | 自動抓取模式：依三層優先順序選取任務 |
| `/shoot "描述"` | 直接描述模式：以引號內文字為任務標題直接執行 |
| `/shoot #N` | GitHub Issue 模式：透過 `gh issue view #N` 取得 Issue 內容執行 |
| `/shoot US-#N` | Backlog Story 模式：優先從 GitHub Issues 查詢對應 Story，若無結果則 fallback 至 `docs/prd/PRODUCT_BACKLOG.md` |
| `/shoot US-XX` | Backlog Story 模式（舊格式，向後相容，同上） |

---

## 3. 自動抓取模式（AC1）

執行 `/shoot`（無參數）時，依以下優先順序自動選取任務：

| 優先順序 | 來源 |
|---------|------|
| (1) 第一優先 | `bug` label 的 open Issue |
| (2) 第二優先 | `retro-action` label 的 open Issue |
| (3) 第三優先 | `docs/prd/PRODUCT_BACKLOG.md` 頂部 `Size=S` Story |

三者均無可用任務時，輸出錯誤訊息並終止。詳細邏輯請參照：`skills/shoot/references/trigger-modes.md`

---

## 4. 直接描述模式（AC2）

`/shoot "任務描述"` 將引號內的文字作為任務標題直接執行。描述完整保留，寫入 `docs/km/Shoot_Log.md`，來源記錄為 `direct`。

---

## 5. GitHub Issue 模式（AC3）

`/shoot #N` 透過 `gh issue view N --json number,title,body` 取得 Issue 標題與描述後執行。

Issue 不存在、gh CLI 未認證或未安裝時，輸出 `[ERROR]` 並終止，exit code 非 0。

---

## 6. Backlog Story 模式（AC4）

`/shoot US-#N`（或舊格式 `/shoot US-XX`）優先從 GitHub Issues 查詢對應 Story，若無結果則 fallback 至 `docs/prd/PRODUCT_BACKLOG.md`。兩者皆查無結果時輸出 `[ERROR] 找不到 Story US-#N` 並終止。

Story ID 需**精確比對**（`US-#N` 格式優先，大小寫不敏感）。詳細邏輯請參照：`skills/shoot/references/trigger-modes.md`

---

## 7. 執行流程（AC8：Hard Gate 保留）

```
[步驟 1]   任務解析 → 解析失敗則終止
[步驟 1.1] Claim Issue（有 Issue number 時）→ bash hooks/claim-issue.sh
[步驟 1.2] SDD-000 存在性檢查 → 不存在則建立並提示重新執行
[步驟 1.5] 測試可寫性檢查（TC-W1~W5 Hard Gate）→ FAIL 則禁止進入實作
[步驟 2]   QA Pre-flight（Hard Gate）→ FAIL 則終止
[步驟 3]   Architect 審查（Hard Gate，DM-1~DM-4）→ FAIL 則終止
[步驟 4]   執行任務（實作）
[步驟 4.5] 本地測試 + Systematic Debugging → 失敗則修復後重試，仍失敗則終止
[步驟 5]   QA Post-check（Spec Compliance + Code Quality Hard Gate）→ FAIL 最多重試 3 次
[步驟 5.3] 外部獨立審查 100%（Hard Gate）→ DISPUTE 強制二審，仍 DISPUTE 升級 Architect
[步驟 5.4] pr-review-toolkit 三 agent 平行審查（Hard Gate，Plugin 未安裝則降級）
[步驟 5.5] CI/CD 雙審查 Gate（條件觸發，偵測到 CI/CD 路徑變更時）
[步驟 6]   Branch + PR 流程
           6.1 git checkout -b shoot/<issue-or-desc>
           6.2 git commit -m "shoot: <任務標題>"
           6.3 git push
           6.4 gh pr create（PR title 與 Issue title 語義對齊）
           6.5 Code Review Loop（pr-review-toolkit）
           6.55 Self-Review（shoot.self_review=true 時）
           6.6 gh pr merge --squash --delete-branch（shoot.skip_merge=true 時跳過）
           6.7 git checkout main && git pull
[步驟 6.5] CI Gate — 等待 CI PASS，Doc-only 跳過，CI FAIL 觸發 systematic-debugging
[步驟 7]   更新 docs/km/Shoot_Log.md（PASS）與 docs/PROJECT_BOARD.md
           docs/PROJECT_BOARD.md 豁免直推 main（ADR-023 決策 3）
[步驟 7.5] Release Issue（bash hooks/release-issue.sh，失敗不阻塞）
[步驟 8]   瘦身歸檔檢查（Shoot_Log.md > 20 筆則歸檔）
輸出完成訊息
```

詳細每步驟規則：
- QA 審查：`skills/shoot/references/qa-review-rules.md`
- CI/CD Gate 與 CI Gate：`skills/shoot/references/ci-gate.md`
- 外部獨立審查：`skills/shoot/references/external-review.md`
- pr-review-toolkit：`skills/shoot/references/pr-review-integration.md`
- 文件產出：`skills/shoot/references/doc-output.md`

### 明確跳過項目（Sprint 儀式）

`/shoot` 跳過：Sprint Planning、Sprint Review、Sprint Retro、Sprint Metrics（不計算 Velocity）

---

## 8. QA 完整品質審查（與 Sprint Execution 對齊）

<!-- Issue #257 — Shoot QA 補齊：與 Sprint Execution 品質對齊 -->

完整 QA 審查規則請參照：`skills/shoot/references/qa-review-rules.md`

### 雙階段審查摘要

- **第一階段：QA Pre-flight** — 實作前預審（任務範圍、安全、架構影響）
- **第二階段：QA Post-check** — 實作後完整審查（Spec Compliance + Code Quality）

完整判定標準請參照 `skills/sprint-execution/story-lifecycle-prompt.md` §6。

### Architect 審查

由 Architect subagent 確認實作方向符合架構、無需 ADR 觸發、技術選型合規。
DM checklist（DM-1/DM-2/DM-3/DM-4）與 Layer Compliance checklist 詳見 `references/qa-review-rules.md`。

### 任一 FAIL 時的三個可觀察驗收點

| 可觀察點 | 說明 |
|---------|------|
| (a) exit code 非 0 | process 以錯誤碼結束 |
| (b) Shoot_Log.md 中該次任務無 PASS 記錄 | log 筆數不增加，Shoot_Log.md 保持不變 |
| (c) 不執行 `shoot:` 前綴的 git commit | commit 狀態為未提交 |

<HARD-GATE>
**QA 雙階段 Hard Gate（/shoot）**：QA Pre-flight、Architect 審查、QA Post-check 任一 FAIL → exit code 非 0，Shoot_Log.md 不寫 PASS，不執行 shoot: commit。
</HARD-GATE>

---

## 8.1 CI/CD 雙審查 Gate（條件觸發）

完整規則請參照：`skills/shoot/references/ci-gate.md`

偵測到 CI/CD 路徑變更時（`.github/workflows/**`、`scripts/deploy*.sh`、`Dockerfile*` 等），QA regression check 與 SRE infra config check **兩者均必須 PASS**。

<HARD-GATE>
**CI/CD 雙審查 Hard Gate（/shoot）**：偵測到 CI/CD 路徑變更時，QA regression check 與 SRE infra config check **兩者均必須 PASS**，才允許執行 `shoot:` git commit。任一 FAIL → exit code 非 0，禁止 commit。
</HARD-GATE>

---

## 8.2 CI Gate（US-241）

完整規則請參照：`skills/shoot/references/ci-gate.md`

git push 完成後，等待 CI 結果，PASS 才寫 Shoot_Log.md。Doc-only 變更跳過 CI Gate。

<HARD-GATE>
**CI Gate Hard Gate（/shoot）**：git push 完成後，CI PASS 才允許寫入 Shoot_Log.md PASS。CI FAIL → exit code 非 0，Shoot_Log.md 不寫 PASS 記錄，不輸出完成訊息。CI 不可用時採降級行為（輸出 WARN，繼續執行）。
</HARD-GATE>

---

## 8.3 測試執行 + Systematic Debugging（步驟 4.5）

完整規則請參照：`skills/shoot/references/qa-review-rules.md`

實作完成後、QA Post-check 前，執行本地測試。失敗時觸發 `invoke shikigami:systematic-debugging`。

---

## 8.4 測試可寫性檢查（步驟 1.5）

完整規則請參照：`skills/shoot/references/qa-review-rules.md`

任務解析後、QA Pre-flight 前，檢查 AC 是否可轉化為測試（TC-W1 ~ TC-W5）。

<HARD-GATE>
**測試可寫性 Hard Gate（/shoot）**：TC-W1 ~ TC-W5 任一觸發 → 禁止進入實作，exit code 非 0。
</HARD-GATE>

---

## 8.5 外部獨立審查（步驟 5.3）

完整規則請參照：`skills/shoot/references/external-review.md`

固定 100% 外部獨立審查。DISPUTE 後強制二審，二審仍 DISPUTE → 升級 Architect。

<HARD-GATE>
**外部獨立審查 Hard Gate（/shoot）**：固定 100% 外部獨立審查。DISPUTE 後強制二審，二審仍 DISPUTE → 升級 Architect，exit code 非 0，禁止 commit。
</HARD-GATE>

---

## 8.6 pr-review-toolkit 補充審查（步驟 5.4）

完整規則請參照：`skills/shoot/references/pr-review-integration.md`

外部獨立審查 CONFIRM 後，平行派遣 code-reviewer / silent-failure-hunter / comment-analyzer。CRITICAL/HIGH 阻擋，Plugin 未安裝採降級行為。

<HARD-GATE>
**pr-review-toolkit 補充審查 Hard Gate（/shoot）**：步驟 5.4 派遣 pr-review-toolkit 三 agent 平行審查。CRITICAL/HIGH 嚴重度阻擋 commit，修復後二審仍 CRITICAL/HIGH → 升級 Architect，exit code 非 0，禁止 commit。Plugin 未安裝時採降級行為（WARN + 跳過 + 繼續）。
</HARD-GATE>

---

## 9. 文件產出（AC5）

完整規則請參照：`skills/shoot/references/doc-output.md`

每次 `/shoot` 成功後：
- `docs/km/shoot-log/YYYY-MM-DD-session-<SESSION_ID>.md` — per-session 短衝記錄
- `docs/PROJECT_BOARD.md` — 短衝記錄區塊新增條目
- git commit 以 `shoot:` 前綴

**欄位**：日期 / 來源 / 標題 / 結果 / commit hash

---

## 10. 瘦身歸檔（AC6）

完整規則請參照：`skills/shoot/references/doc-output.md`

`docs/km/Shoot_Log.md` 超過 **20 筆**時觸發歸檔，移至恰好保留 20 筆（移走 `筆數 - 20` 筆），附加至 `docs/km/archive/SHOOT_LOG_ARCHIVE.md`。

同步更新 `docs/km/archive/README.md` 的歸檔範圍欄位與最後更新日期。

**邊界**：20 筆不觸發；21 筆移 1 筆。

---

## 11. 動態建立的檔案

| 檔案路徑 | 建立時機 | 說明 |
|---------|---------|------|
| `docs/km/shoot-log/YYYY-MM-DD-session-<ID>.md` | 每次 `/shoot` 成功完成時 | per-session 短衝記錄（US-322 AC-1） |
| `docs/km/shoot-log/YYYY-MM-DD.summary.md` | 執行 `hooks/shoot-log-settle.sh` 時 | 當日結算彙整 |
| `docs/km/archive/SHOOT_LOG_ARCHIVE.md` | 首次觸發歸檔時 | 超過 20 筆時的歸檔目標 |

---

## 12. Sprint Review 連動（AC7）

`/sprint-review` 執行時，會掃描 `docs/km/shoot-log/` 目錄下的 per-session 檔案與 summary.md，將 Sprint 期間的短衝記錄列入「Sprint 外完成項目」區塊。

詳見 `skills/sprint-review/SKILL.md` 的相關段落。

---

## 13. 輸出範例

完整輸出範例請參照：`skills/shoot/references/doc-output.md`

---

## 14. 與其他 Skill 的關係

| 情境 | 說明 |
|------|------|
| Sprint Review 時掃描 | `/sprint-review` 會讀取 Shoot_Log.md，列出「Sprint 外完成項目」 |
| 歸檔觸發 | 主文件超 20 筆時附加至 SHOOT_LOG_ARCHIVE.md |
| Hard Gate 保留 | QA 雙階段審查與 Architect 審查無論如何都保留，不可略過 |
