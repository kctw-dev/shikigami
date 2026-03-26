# Hook 開發標準規範

**Story #924 — chore: 建立 Hook 開發標準規範**
**建立日期**：2026-03-26
**版本**：v1.0

---

## 概述

Shikigami 框架目前包含 30+ 個 Hook，負責攔截 Claude Code session 事件（SessionStart、SessionEnd、PreToolUse、PostToolUse 等）。本指南定義 Hook 開發的命名慣例、入參/出參約定、錯誤處理標準，確保新舊 Hook 維護一致性。

---

## 1. Hook 分類（AC2）

### 1.1 Gate Hook（閘門 Hook）

**職責**：攔截並判斷是否允許繼續執行。Gate Hook 決定「能不能做」。

| 屬性 | 規範 |
|------|------|
| 命名後綴 | `-gate.sh`（如 `push-main-gate.sh`、`branch-gate.sh`） |
| 成功行為 | `exit 0`（允許通過） |
| 失敗行為 | `exit 1` + 輸出錯誤訊息至 stderr |
| 副作用 | 最小化，避免修改狀態 |
| 典型事件 | `PreToolUse`、`PostToolUse` |

**範例**：`protect-main.sh`、`push-main-gate.sh`、`pr-merge-gate.sh`

### 1.2 Settle Hook（結算 Hook）

**職責**：在事件結束後執行資料整理、狀態更新、記錄寫入。Settle Hook 決定「結束後要記什麼」。

| 屬性 | 規範 |
|------|------|
| 命名後綴 | `-settle.sh`（如 `attendance-settle.sh`、`retro-settle.sh`） |
| 成功行為 | `exit 0`，靜默完成 |
| 失敗行為 | 靜默降級（`|| true`），不阻塞主流程 |
| 副作用 | 允許寫入 docs/ 記錄文件 |
| 典型事件 | `SessionEnd`、`PostToolUse` |

**範例**：`attendance-settle.sh`、`metrics-settle.sh`、`retro-settle.sh`

### 1.3 Utility Hook（工具 Hook）

**職責**：提供可複用的工具功能，被其他 Hook 或主流程呼叫。Utility Hook 是「函式庫」。

| 屬性 | 規範 |
|------|------|
| 命名 | 動詞-名詞格式，無固定後綴（如 `claim-issue.sh`、`release-issue.sh`） |
| 成功行為 | `exit 0` + 輸出標準化標記至 stdout（如 `[CLAIM-OK]`） |
| 失敗行為 | `exit 1` + 標準化錯誤標記至 stdout（如 `[CLAIM-BLOCKED]`） |
| 副作用 | 依功能而定，必須文件化 |
| 呼叫方式 | `bash hooks/<utility-hook>.sh <args>` |

**範例**：`claim-issue.sh`、`release-issue.sh`、`acquire-file-lock.sh`

---

## 2. 命名慣例（AC1）

### 2.1 命名規則

```
<動詞>-<名詞>[-<後綴>].sh
```

| 元素 | 規範 | 範例 |
|------|------|------|
| 動詞 | 小寫，描述 Hook 的動作 | `protect`、`claim`、`release`、`record` |
| 名詞 | 小寫，操作的對象 | `main`、`issue`、`attendance`、`file-lock` |
| 後綴 | 分類後綴（gate/settle），Utility Hook 可省略 | `-gate`、`-settle` |
| 分隔符 | kebab-case，全小寫 | `session-end-release.sh` |

### 2.2 禁止事項

- 不使用 camelCase（`claimIssue.sh` ✗）
- 不使用底線（`claim_issue.sh` ✗）
- 不使用縮寫（`clm-iss.sh` ✗）

---

## 3. 入參與出參約定（AC1）

### 3.1 環境變數（輸入）

Hook 透過環境變數接收 Claude Code 注入的上下文：

| 變數 | 來源 | 說明 |
|------|------|------|
| `CLAUDE_PLUGIN_ROOT` | Claude Code | Plugin 根目錄路徑 |
| `SHIKIGAMI_SESSION_ID` | Claude Code | 當前 Session ID |
| `SHIKIGAMI_PROJECT_LEVEL` | 使用者設定 | `low`/`medium`/`high` |
| `CLAUDE_TOOL_INPUT` | Claude Code（PostToolUse） | 工具呼叫輸入（JSON）|
| `CLAUDE_TOOL_OUTPUT` | Claude Code（PostToolUse） | 工具呼叫輸出（JSON）|

### 3.2 位置參數（輸入）

Utility Hook 的位置參數應在檔頭說明：

```bash
# 用法：bash hooks/claim-issue.sh <issue_id>
# 參數：
#   $1  issue_id  — GitHub Issue 編號（必填）
```

### 3.3 標準化輸出標記

所有 Hook 輸出標記一律使用 `[UPPER-CASE]` 格式，輸出至 stdout：

| 標記格式 | 意義 | 使用場景 |
|---------|------|---------|
| `[<HOOK>-OK]` | 成功完成 | Utility Hook 成功路徑 |
| `[<HOOK>-FAIL]` | 明確失敗 | Gate Hook 攔截、Utility Hook 失敗 |
| `[<HOOK>-WARN]` | 降級警告 | 非致命錯誤，流程繼續 |
| `[<HOOK>-SKIP]` | 條件不滿足跳過 | 早期返回 |
| `[<HOOK>-BLOCKED]` | 被阻擋（互斥/衝突） | Claim 衝突、Gate 攔截 |

### 3.4 Return Code 標準

| Exit Code | 意義 |
|-----------|------|
| `0` | 成功（Gate: 允許通過；Settle: 完成；Utility: 成功） |
| `1` | 失敗（Gate: 阻擋；Utility: 操作失敗） |
| `2` | 輸入錯誤（缺少必填參數） |
| `124` | 超時（由 `hook-runner.sh` 注入，Hook 本身不使用） |

---

## 4. Error Handling 標準（AC1）

### 4.1 基本設定

所有 Hook 開頭應設定 bash 選項：

```bash
#!/usr/bin/env bash
# <hook-name>.sh — 一行說明
set -uo pipefail   # Gate/Utility Hook: 嚴格模式
# 或
set +e             # Settle Hook: 降級模式（不因錯誤中止）
```

**Gate Hook**：使用 `set -euo pipefail`，讓任何錯誤立即傳播。
**Settle Hook**：使用 `set +e`，所有操作加 `|| true`，不因 log 寫入失敗而中止。
**Utility Hook**：使用 `set -uo pipefail`，但對外部指令（`gh`、`git remote`）加降級處理。

### 4.2 外部依賴降級（NFR2: 可靠性）

當依賴外部工具（`gh`、`git remote`）時，必須提供降級路徑：

```bash
# 正確：gh CLI 降級
if ! command -v gh >/dev/null 2>&1; then
  echo "[WARN] gh CLI 不可用，跳過 GitHub 操作" >&2
  exit 0  # 降級繼續（不阻塞）
fi

# 正確：git remote 操作降級
git push origin "refs/claims/${id}" 2>/dev/null || {
  echo "[WARN] git push 失敗，降級繼續" >&2
  # 繼續執行，不 exit 1
}
```

### 4.3 清理與 Trap

需要臨時資源的 Hook 必須使用 trap 清理：

```bash
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT
```

---

## 5. 常見陷阱（NFR1: 可用性）

| 陷阱 | 說明 | 解法 |
|------|------|------|
| 忘記 `set +e` 的 Settle Hook | `set -e` 下任何 `log` 寫入失敗都會中止 Hook | Settle Hook 一律 `set +e` |
| 直接修改共用文件 | `PROJECT_BOARD.md` 等為 coordinator-only（§2.2 HARD-GATE） | Settle Hook 只寫 per-session 檔案 |
| 使用 `echo "..."` 傳多行 body | 含冒號、星號等特殊字符導致 YAML parse error | 改用 `--body-file`（CLAUDE.md 第 13 條） |
| 不處理 gh CLI 不可用 | WSL/CI 環境可能無 gh | 前置 `command -v gh` 檢查 |
| 忽略 `HOOK_TIMEOUT` | 長時間 Hook 會被 hook-runner.sh 強制 kill | 設計 Hook 預期在 30s 內完成 |

---

## 6. 文件格式規範

每個 Hook 檔頭必須包含：

```bash
#!/usr/bin/env bash
# <hook-name>.sh
# <一句話說明 Hook 職責>
#
# 用法：bash hooks/<hook-name>.sh [<args>]
# 參數：
#   $1  <param_name>  — <說明>（必填/可選）
#
# 輸出標記：
#   [<HOOK>-OK]      — <成功情況>
#   [<HOOK>-WARN]    — <警告情況>
#   [<HOOK>-BLOCKED] — <阻擋情況>（若適用）
#
# 失敗行為：<降級/中止/不阻塞>
# Hook 類別：<gate / settle / utility>
```

---

## 7. 現有 Hook 分類速查表

| Hook | 類別 | 主要功能 |
|------|------|---------|
| `protect-main.sh` | gate | 禁止直推 main branch |
| `push-main-gate.sh` | gate | 攔截 git push 至 main |
| `pr-merge-gate.sh` | gate | PR merge 前置檢查 |
| `branch-gate.sh` | gate | branch 命名規範檢查 |
| `low-mode-guard.sh` | gate | project_level=low 下的操作防護 |
| `side-effect-guard.sh` | gate | 不可逆操作前置確認 |
| `attendance-settle.sh` | settle | Session 出勤記錄 |
| `metrics-settle.sh` | settle | 品質指標結算 |
| `retro-settle.sh` | settle | Retro log 記錄 |
| `live-log-settle.sh` | settle | Live log 清理 |
| `quality-decisions-settle.sh` | settle | 品質決策記錄 |
| `claim-issue.sh` | utility | Issue Claim 互斥鎖 |
| `release-issue.sh` | utility | Issue Claim 釋放 |
| `acquire-file-lock.sh` | utility | 檔案層級鎖 |
| `release-file-lock.sh` | utility | 檔案層級鎖釋放 |
| `kill-switch.sh` | utility | Sprint 緊急停止 |
| `hook-runner.sh` | utility | Hook 執行包裝器（timeout + metrics） |

---

## 8. 參考

- `templates/hook-template.sh` — 可複製的 Hook 範本
- `hooks/claim-issue.sh` — Utility Hook 完整範例
- `hooks/protect-main.sh` — Gate Hook 完整範例
- `hooks/attendance-settle.sh` — Settle Hook 完整範例
- `hooks/hook-runner.sh` — timeout + metrics 執行包裝器（Story #923）
- `docs/adr/ADR-023-*.md` — Hook 豁免路徑決策記錄
