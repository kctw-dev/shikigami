# Hooks 架構說明文件

此文件解釋 Shikigami hooks 系統的設計、各 hook 類型的職責邊界，以及何時使用 `hook-runner.sh` 的決策規則。

## Overview

Hooks 是 Claude Code Plugin 的自動化執行點，在特定事件發生時觸發 bash script。Shikigami 的 hooks 架構提供以下功能：

- **事件驅動**：在 SessionStart、SessionEnd、PreToolUse、PostToolUse、Stop 時刻自動觸發
- **隔離執行**：Hook 失敗不影響主流程（透過 subshell + trap）
- **超時保護**：可選的 timeout 機制，保護長時間操作
- **Metrics 記錄**：執行時間、狀態、exit code 記錄到 `.claude/hooks/execution-metrics.jsonl`
- **非阻塞**：SessionEnd 等時刻的 hooks 標記為 `async: true`，不延遲 session 關閉

所有 hooks 定義在 `hooks/hooks.json`，透過 Claude Code 的 hook runner 執行。

---

## Hook Types — 職責邊界

### SessionStart
**時機**：Session 啟動時（startup、resume、clear、compact 四個觸發點）

**用途**：
- 初始化工作環境
- 讀取上一次的 checkpoint 或狀態
- 驗證依賴項

**示例**：`hooks/run-hook.cmd session-start` — 執行平台相關的 startup script（Windows `.cmd` / Unix shell）

**特性**：
- 同步執行（`async: false`）
- 必須快速完成，否則延遲 session 開始
- 失敗應中止 session 初始化

---

### SessionEnd
**時機**：Session 結束時（關閉主視窗、執行 clear 指令、compact 後等）

**用途**：
- 清理臨時檔案
- 上傳 metrics / checkpoint
- 停止 background 監視程式
- 移除 kill-switch flags

**示例**：
- `session-end-release.sh` — 長時間清理工作（移除舊 worktree、壓縮日誌等）
- `kill-switch.sh clear` — 移除 flag

**特性**：
- 非同步執行（`async: true`），不延遲 session 關閉
- 可能失敗而不影響 session 終止
- 應在背景完成所有清理工作

---

### PreToolUse
**時機**：執行某個 tool 之前

**用途**：
- 記錄 tool 調用（用於 exploration 追蹤）
- 驗證 git 操作前的完整性檢查（版號驗證、branch gate 等）
- 防止危險操作（例：禁止在 main branch 上 push）

**示例**：
- WebSearch / WebFetch 前：記錄到 `exploration-record.sh`
- Bash 前：執行多個檢查
  - `validate-version.sh`（commit 時的版號驗證）
  - `protect-main.sh`（禁止在 main branch 上危險操作）
  - `pr-merge-gate.sh`（防止意外 merge）
  - `branch-gate.sh`（branch 命名驗證）
  - `push-main-gate.sh`（main push 防護）

**特性**：
- 同步執行（tool 前必須驗證完成）
- 可 exit non-zero 以阻止 tool 執行
- 通常很快（幾毫秒）

---

### PostToolUse
**時機**：執行某個 tool 之後

**用途**：
- 更新 live log（Agent 執行後記錄 live log）
- 運行監視程式（session watchdog，監測 session 狀態）
- 收集 metrics

**示例**：
- Agent tool 後：`posttooluse-agent-livelog.sh`
- 所有 tool 後：`session-watchdog.sh`（if exists）

**特性**：
- 非同步執行（不阻塞後續 tool 調用）
- 失敗不影響後續工作
- 適合背景監視、日誌更新

---

### Stop
**時機**：User 點擊 Stop 按鈕時

**用途**：
- 緊急清理（例：殺掉正在執行的 background process）
- 記錄停止事件
- 觸發 kill-switch 機制

**特性**：
- 應快速完成（user 期望立即停止）
- 當前 Shikigami 無定義（空陣列）

---

## hook-runner.sh 使用時機決策樹

`hook-runner.sh` 提供 **timeout 保護 + metrics 記錄**。使用它時會額外增加 hook-runner 本身的開銷（subshell + timeout 檢查）。

### 使用 hook-runner.sh 的情況

✅ **長時間操作**（預期 > 1 秒或不可預測）
- `session-end-release.sh` — 清理多個 worktree、壓縮日誌，通常 5-30 秒
- 需要對外部服務的調用（git push、file I/O 等）
- **決策**：使用 `hook-runner.sh` + 設定合適的 `HOOK_TIMEOUT`

✅ **必須記錄 metrics 的操作**
- 需要了解執行時間分佈、failures 的操作
- 性能敏感的 hook
- **決策**：使用 `hook-runner.sh`

✅ **需要 timeout 保護，防止無限掛起**
- 調用外部 API 或命令，可能 hang
- 不信任的第三方 script
- **決策**：使用 `hook-runner.sh` + 合適的 timeout 值

### 直接執行（不用 hook-runner.sh）的情況

✅ **極短操作**（< 1 秒，確定性快速）
- 單個檔案刪除（如 kill-switch flag 清除）
- 簡單的條件檢查（grep、test）
- 變數設置、輸出
- **決策**：直接執行，省去 hook-runner 開銷

✅ **async: true 已提供保護**
- SessionEnd 時刻，已標記 `async: true`
- 不會阻塞主流程，即使失敗也無害
- 例：kill-switch `clear` 操作
- **決策**：直接執行

✅ **簡單檔案操作或邏輯驗證**
- grep、test、條件判斷
- 無需超時或 metrics
- **決策**：直接執行

### 決策樹（圖解）

```
Hook script 需要執行？
│
├─ 預期執行時間 > 1s？
│  ├─ YES → 使用 hook-runner.sh
│  └─ NO → 繼續判斷
│
├─ 調用外部服務或命令？（git、HTTP、file I/O）
│  ├─ YES → 使用 hook-runner.sh
│  └─ NO → 繼續判斷
│
├─ 必須記錄 metrics？
│  ├─ YES → 使用 hook-runner.sh
│  └─ NO → 繼續判斷
│
├─ 已標記 async: true 且不會 hang？
│  ├─ YES → 直接執行
│  └─ NO → 繼續判斷
│
└─ 結論：直接執行
```

---

## timeout 設定指南

### 預設值：30 秒

`hook-runner.sh` 的預設 `HOOK_TIMEOUT=30` 基於以下理由：

1. **大多數 hook 快速完成**（< 5 秒）
   - 檔案清理、log 記錄通常 < 1 秒
   - git 操作（push、pull）通常 < 10 秒

2. **30 秒足以應對網路延遲和繁忙磁碟**
   - 即使網路慢，30 秒內也應完成
   - 充足的緩衝，減少誤殺

3. **避免過短導致誤殺**
   - 如果設定太短（5 秒），快速網路環境下仍可能超時
   - 預設 30 秒平衡了保護性和寬鬆性

### 何時需要 override

#### 更短的 timeout（5-10 秒）
- Hook **必須快速完成**，否則表示異常
- 例：檢查某個檔案是否存在，應 < 100ms；如果 > 5 秒，說明有 I/O 問題
- **設定**：`HOOK_TIMEOUT=5 bash hook-runner.sh hooks/my-check.sh`

#### 更長的 timeout（60+ 秒）
- Hook 涉及 **遠端操作**：git push 到慢網路、大檔案 I/O
- 例：`session-end-release.sh` 可能涉及 worktree 清理、可達 30-60 秒
- **設定**：`HOOK_TIMEOUT=60 bash hook-runner.sh hooks/session-end-release.sh`

#### 無限制（HOOK_TIMEOUT=0）
- Hook **本身無 hang 風險**，但希望記錄 metrics
- 用於完全信任的、經過驗證的 script
- **設定**：`HOOK_TIMEOUT=0 bash hook-runner.sh hooks/trusted-script.sh`

### 在 hooks.json 中配置

```json
{
    "type": "command",
    "command": "bash -c 'HOOK_TIMEOUT=60 bash \"${CLAUDE_PLUGIN_ROOT}/hooks/hook-runner.sh\" \"${CLAUDE_PLUGIN_ROOT}/hooks/session-end-release.sh\"'",
    "async": true
}
```

---

## 案例研究：#955 kill-switch 評估

### 問題

Sprint 179 提出：kill-switch 的 `clear` 操作是否應遷移到 `hook-runner.sh`？

**當時的現狀**：
- `SessionEnd` 執行 kill-switch `clear` 命令
- 使用直接 bash 執行，無 timeout
- 問題：是否需要 timeout 保護？

### 評估過程

**分析 kill-switch `clear` 的特性**：

| 特性 | 評估 |
|------|------|
| 執行時間 | < 1ms（僅刪除一個檔案） |
| 外部依賴 | 無（純檔案操作） |
| 掛起風險 | 極低（filesystem 很少 hang） |
| 現有保護 | `async: true` 已保護 SessionEnd |
| Metrics 需求 | 無（操作過於輕量） |

**代碼檢視**（`kill-switch.sh` 的 `clear` 子命令）：

```bash
clear)
    FLAG_PATH="${KILL_SWITCH_DIR}/${SESSION_ID}.flag"
    if [[ -f "${FLAG_PATH}" ]]; then
      rm "${FLAG_PATH}"  # 單個 rm 指令，< 1ms
      echo "[KILL-SWITCH-CLEARED] session=${SESSION_ID} flag removed"
    fi
    ;;
```

### 結論

**決定：不遷移到 hook-runner.sh**

**理由**：
1. **操作本身足夠簡單**：檔案刪除無掛起風險
2. **已有保護機制**：`async: true` 確保不阻塞 SessionEnd
3. **新增複雜性無益**：hook-runner 引入額外 subshell、timeout 檢查、metrics 寫入，但 kill-switch 操作本身完成時間遠小於這些開銷
4. **架構一致性有限**：不是所有 hook 都需要 hook-runner；輕量操作應保持簡單

**最佳實踐啟示**：
- **不盲目統一**：不要為了架構一致性而過度設計
- **成本效益分析**：簡單操作直接執行，複雜操作才用 hook-runner
- **信任輕量 script**：對短小精悍的 script，預設信任其不會 hang

### 驗證

- kill-switch 實現已在 `tests/test-kill-switch.sh` 中測試
- 在所有 Sprint Execution 中穩定運行
- 無超時或阻塞的報告

---

## 新增 Hook 的 Checklist

### 設計階段

- [ ] **目的清晰**：定義 hook 的目的（初始化、清理、驗證、監視）
- [ ] **觸發時機確定**：SessionStart / SessionEnd / PreToolUse / PostToolUse / Stop 中選一個
- [ ] **執行時間估計**：粗略估計，< 1s / 1-10s / 10s+ 中選一個
- [ ] **失敗影響評估**：Hook 失敗是否應阻止主流程？
- [ ] **Metrics 需求**：是否需要記錄執行時間？

### 實作階段

- [ ] **建立 script**：在 `hooks/` 目錄下建立 `.sh` 檔案（kebab-case 命名）
- [ ] **加入 header comment**：說明用途、參數、子命令
- [ ] **錯誤處理**：`set -uo pipefail`，適當的 `|| true`
- [ ] **避免魔法路徑**：使用 `${CLAUDE_PLUGIN_ROOT}` 或 `git rev-parse --show-toplevel`
- [ ] **測試單獨執行**：確保 script 獨立運行時正常

### 註冊階段

- [ ] **編輯 `hooks/hooks.json`**：添加到適當的 hook type 下
- [ ] **決定是否用 hook-runner.sh**：參考 [決策樹](#決策樹圖解)
  - 長時間或遠端操作 → `hook-runner.sh`
  - 輕量操作 → 直接執行
- [ ] **決定 async 值**：
  - SessionEnd / PostToolUse → `async: true`（不阻塞）
  - SessionStart / PreToolUse → `async: false`（必須等待）
- [ ] **設定 matcher**（如需要）：指定觸發條件
- [ ] **設定 HOOK_TIMEOUT**（如用 hook-runner.sh）：基於執行時間估計

### 驗證階段

- [ ] **執行驗證腳本**：`bash scripts/validate-json.sh` 確保 hooks.json 格式正確
- [ ] **手動測試**：在 Claude Code 中 trigger hook 所在的事件
- [ ] **查看 metrics**：檢查 `.claude/hooks/execution-metrics.jsonl` 中的記錄
- [ ] **邊界情況**：測試 hook 失敗、timeout 情況

### 文件階段

- [ ] **更新本文件**：如新增重要 hook，補充案例研究或最佳實踐
- [ ] **撰寫 comment**：在 hooks.json 中註解複雜的邏輯
- [ ] **開 PR 或 commit**：遵循 Shikigami 的 commit 慣例（`feat(hooks): ...` 或 `fix(#NNN): ...`）

---

## 相關檔案

- `hooks/hooks.json` — Hook 定義
- `hooks/hook-runner.sh` — Timeout + metrics 執行包裝器（Story #923）
- `hooks/kill-switch.sh` — 緊急停止機制（ADR-038）
- `docs/adr/ADR-038-kill-switch-design.md` — Kill-switch 架構決策
- `docs/km/spike-955-kill-switch-assessment.md` — #955 評估文件（kill-switch timeout 分析）
- `.claude/hooks/execution-metrics.jsonl` — Hook 執行 metrics 記錄

---

## 相關故事

- **Story #923**：Hook 執行超時與隔離機制（hook-runner.sh）
- **Story #955**：Kill-switch 超時保護評估（決定不遷移）
- **Story #984**：建立此文件（hooks 架構說明）

---

**最後更新**：2026-04-09  
**維護者**：Story-Lifecycle Subagent
