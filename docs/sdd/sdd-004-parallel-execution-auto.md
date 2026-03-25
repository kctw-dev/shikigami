# SDD-004: Parallel Execution Auto-Dispatch Architecture

<!-- #722 parallel-safety 全自動化 — 消除人工決策 — Sprint 154 -->

## 概述

本 SDD 描述 Sprint Execution 平行 subagent 派遣的全自動決策架構，整合 #712 動態記憶體感知機制（`scripts/memory-aware-dispatch.sh`），消除先前需要人工介入的並行上限決策步驟。

**問題陳述**：Sprint 153 實作（#712）建立了記憶體感知腳本，但 `skills/sprint-execution/SKILL.md` §2.2 的 HARD-GATE 描述中仍要求人工確認並行數量。本 Story（#722）將邏輯整合進 SKILL.md，使全流程自動化。

---

## 架構

### 元件關係

```
Sprint Execution (SKILL.md §2.2)
  └── 派遣前自動執行
        └── scripts/memory-aware-dispatch.sh  (#712 已實作)
              ├── get_available_memory_mb()    — 跨平台記憶體偵測
              ├── calculate_dynamic_max_parallel()  — FINAL_MAX 計算
              └── get_dispatch_decision()      — 整合決策函式
                    └── 輸出 FINAL_MAX（無需人工）
```

### 決策流程（全自動）

```
Sprint Execution 準備派遣 subagent
  |
  v
自動呼叫 scripts/memory-aware-dispatch.sh
  |
  v
取得 FINAL_MAX = min(DYNAMIC_MAX, SHIKIGAMI_MAX_PARALLEL)
  |-- FINAL_MAX == SHIKIGAMI_MAX_PARALLEL → 正常平行派遣（無警告）
  +-- FINAL_MAX < SHIKIGAMI_MAX_PARALLEL  → 自動輸出 [OOM-WARN]，採用 FINAL_MAX
  |
  v
依 FINAL_MAX 執行批次派遣（無人工介入）
```

---

## 記憶體偵測策略（跨平台）

| 平台 | 偵測方式 | 優先順序 |
|------|---------|---------|
| Linux（含 WSL2） | `/proc/meminfo` MemAvailable → MemFree | 1st |
| macOS | `sysctl hw.memsize` × 60% | 1st |
| WSL2 fallback | `/proc/meminfo` MemFree | 2nd |
| 偵測失敗 | 靜默採用靜態值 2 | fallback |

**估計每 agent 記憶體**：512 MB（包含 Claude model context、git worktree、node 進程）。

**公式**：
```
DYNAMIC_MAX = floor(available_mb / 512)
DYNAMIC_MAX_SAFE = max(1, DYNAMIC_MAX)  # 最低保證 1
FINAL_MAX = min(DYNAMIC_MAX_SAFE, SHIKIGAMI_MAX_PARALLEL)
```

---

## 行為場景（BDD）

### Scenario 1: 記憶體充足 → 平行派遣

```
Given SHIKIGAMI_MAX_PARALLEL = 2
And   系統可用記憶體 = 8192 MB
When  Sprint Execution 準備派遣
Then  DYNAMIC_MAX = floor(8192 / 512) = 16
And   FINAL_MAX = min(16, 2) = 2
And   派遣 2 個 subagent（平行）
And   不輸出 [OOM-WARN]
```

### Scenario 2: 記憶體不足 → 串行派遣

```
Given SHIKIGAMI_MAX_PARALLEL = 2
And   系統可用記憶體 = 400 MB
When  Sprint Execution 準備派遣
Then  DYNAMIC_MAX = floor(400 / 512) = 0 → DYNAMIC_MAX_SAFE = 1
And   FINAL_MAX = min(1, 2) = 1
And   派遣 1 個 subagent（串行）
And   自動輸出 [OOM-WARN] memory_limited: FINAL_MAX=1 < STATIC_MAX=2
```

---

## 可觀察性

每次自動派遣決策記錄至 cruise log（`docs/cruise-logs/`），JSONL type: `memory-aware-dispatch`：

```json
{
  "timestamp": "2026-03-25T15:00:00Z",
  "type": "memory-aware-dispatch",
  "available_mb": 8192,
  "dynamic_max": 16,
  "static_max": 2,
  "final_max": 2,
  "detection_method": "proc",
  "warning_triggered": false,
  "memory_per_agent_mb": 512
}
```

---

## 相關文件

- `skills/sprint-execution/SKILL.md` §2.2 — HARD-GATE 與自動派遣說明
- `skills/sprint-execution/references/parallel-safety.md` — 平行安全完整規格
- `scripts/memory-aware-dispatch.sh` — 記憶體偵測實作（#712）
- `docs/adr/ADR-039-token-cost-routing.md` — OOM 風險評分依據

## 變更歷史

| 版本 | 日期 | 說明 |
|------|------|------|
| v1.0 | 2026-03-25 | 初版：整合 #712 → SKILL.md §2.2 全自動決策（#722） |
