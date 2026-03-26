# Script Testability Guide — 腳本可測試性設計規範

**版本**：1.0
**建立日期**：2026-03-26
**Story**：#900（Sprint 171 Retro Action）

---

## 概述

本規範定義 Shikigami 框架腳本（`scripts/*.sh`、`tests/*.sh`）的可測試性設計標準，確保每個腳本在測試環境下可被隔離執行，不依賴實際的 repo 路徑或外部服務。

---

## 核心原則：環境變數覆蓋機制

**所有腳本的關鍵路徑（REPO_ROOT、LOG_DIR 等）必須支援環境變數覆蓋。**

### 最佳實踐模式（以 logrotate.sh 為範本）

```bash
# 正確做法：支援環境變數覆蓋
CRUISE_LOG_DIR="${CRUISE_LOG_DIR:-$REPO_ROOT/docs/cruise-logs}"

# 錯誤做法：硬編碼路徑（測試需 wrapper script 迂迴，增加複雜度）
CRUISE_LOG_DIR="/home/user/workspace/shikigami/docs/cruise-logs"
```

### REPO_ROOT 覆蓋標準

每個腳本應在頂部定義：

```bash
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
```

測試時即可透過環境變數指定 fixture 目錄：

```bash
REPO_ROOT="/tmp/fixture-dir" bash scripts/my-script.sh
```

---

## 可覆蓋變數清單（框架標準）

| 變數名稱 | 用途 | 預設值推薦 |
|---------|------|----------|
| `REPO_ROOT` | 框架根目錄 | `$(cd "$(dirname "$0")/.." && pwd)` |
| `CRUISE_LOG_DIR` | Cruise log 目錄 | `$REPO_ROOT/docs/cruise-logs` |
| `SPRINT_DIR` | Sprint 文件目錄 | `$REPO_ROOT/docs/sprints` |
| `METRICS_DIR` | Metrics log 目錄 | `$REPO_ROOT/docs/km/metrics-log` |
| `ADR_DIR` | ADR 文件目錄 | `$REPO_ROOT/docs/adr` |

---

## grep 搭配 set -e 的陷阱

### 問題說明

當腳本使用 `set -euo pipefail` 時，`grep` 未找到匹配內容會返回 exit code 1，導致腳本非預期退出。這是 grep 的設計特性（0 = 有匹配，1 = 無匹配，2+ = 錯誤），與 `set -e` 的「任何非零退出碼即停止」衝突。

### 錯誤模式

```bash
#!/usr/bin/env bash
set -euo pipefail

# 如果 file.log 中找不到 "ERROR"，grep 返回 1，腳本非預期終止
ERROR_COUNT=$(grep -c "ERROR" file.log)
echo "錯誤數：$ERROR_COUNT"
```

### 正確模式

```bash
#!/usr/bin/env bash
set -uo pipefail

# 方法 1：搭配 || true（推薦）
ERROR_COUNT=$(grep -c "ERROR" file.log || true)
echo "錯誤數：${ERROR_COUNT:-0}"

# 方法 2：移除 set -e（若允許其他命令失敗未偵測）
# ⚠️   僅在確實不需監控其他失敗時使用
```

---

## 測試隔離技術

### 1. Fixture 目錄（推薦）

```bash
FIXTURE_DIR=$(mktemp -d)
trap "rm -rf $FIXTURE_DIR" EXIT

# 建立測試用 ADR fixture
cat > "$FIXTURE_DIR/ADR-001.md" << 'EOF'
# ADR-001：測試 ADR
**狀態**：Accepted
EOF

# 執行腳本，指向 fixture
REPO_ROOT="$FIXTURE_DIR" bash scripts/adr-status-dashboard.sh
```

### 2. Mock Command（gh API 模擬）

```bash
MOCK_BIN=$(mktemp -d)
trap "rm -rf $MOCK_BIN" EXIT

cat > "$MOCK_BIN/gh" << 'MOCK_EOF'
#!/usr/bin/env bash
echo '[{"conclusion":"success","name":"Test","status":"completed"}]'
MOCK_EOF
chmod +x "$MOCK_BIN/gh"
export PATH="$MOCK_BIN:$PATH"
```

### 3. 環境變數注入

```bash
# 覆蓋關鍵路徑，不修改腳本
SPRINT_DIR="/tmp/my-fixture" METRICS_DIR="/tmp/metrics-fixture" bash scripts/sprint-metrics-trend.sh
```

---

## Sprint Planning Architect 審查項目

Architect 在 Sprint Planning 技術評估涉及路徑硬編碼的 Story 時，必須確認：

1. 新增腳本是否使用 `REPO_ROOT="${REPO_ROOT:-...}"` 模式
2. 所有路徑常數是否可透過環境變數覆蓋
3. 對應測試是否使用 `mktemp -d` fixture 隔離

---

## Sentinel 字串衝突防護

### 問題說明

腳本 footer 或說明段落若直接輸出 **測試用的 sentinel 字串**（如 `[ADR-STALE]`、`[ADR-PENDING]`、`[WARN]`），會導致測試 grep 命令產生假陽性。

### 禁止模式（❌ 錯誤）

```bash
# footer 直接輸出 sentinel —— 測試 grep 誤判
echo "> [ADR-STALE] 上述 ADR 已標記為老化"
```

### 允許模式（✅ 正確）

```bash
# 用不同措辭描述狀態，避免與 sentinel 字串重複
echo "> 上述 ADR 已被標記為老化（請重新評估）"
```

### 真實案例（Sprint 171）

`scripts/adr-status-dashboard.sh` 修復前輸出 `[ADR-STALE]` footer，測試中 grep 檢查 `[ADR-STALE]` 狀態表報時產生假陽性。改為使用「已標記」替代 literal `[ADR-STALE]` 關鍵字後解決。

---

## 歷史案例（#900 背景）

Sprint 169 `update-adr-index.sh` 硬編碼 `REPO_ROOT`，測試需要額外 wrapper script 迂迴。對比 `logrotate.sh` 已提供 `CRUISE_LOG_DIR` 環境變數覆蓋，是更好的設計。本規範確保後續腳本遵循 logrotate.sh 的可測試性模式。

---

## NFR1

本文件 < 1 頁（約 800 字），簡潔可執行。
