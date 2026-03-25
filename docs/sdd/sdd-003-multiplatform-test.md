# SDD-003: 多平台測試策略（3 平台基線）

**Story**: #720 retro: Sprint 153 多平台測試覆蓋強化 — 補充 WSL2 實測
**版本**: v1.0.0
**建立日期**: 2026-03-25
**狀態**: Active

---

## 1. 目標

定義 Shikigami 框架的 3 平台測試基線策略，確保框架在 Linux (native)、macOS、WSL2 三種執行環境下均能正確運作。

## 2. 問題背景

Sprint 153 #710（多平台相容性驗證測試）建立了 Claude Code / OpenCode / Gemini CLI / Cursor 四個宿主平台的相容性測試（`tests/test-multiplatform-compat.sh`），但未覆蓋 WSL2 環境的運行時差異。

Sprint 154 #720 補強此缺口：
- 當前開發環境：WSL2 (Linux 6.6.87.2-microsoft-standard-WSL2)
- 問題：/proc/meminfo（Linux）vs vm_stat（macOS）的記憶體讀取差異可能導致 parallel-safety 邏輯在不同平台行為不一致

## 3. 3 平台測試基線定義

| 平台 | 識別方式 | 記憶體讀取 | 測試重點 |
|------|---------|-----------|---------|
| **WSL2** | `/proc/version` 含 `Microsoft` 字串 | `/proc/meminfo` (MemTotal, MemAvailable) | WSL2 核心特有行為、Windows 互動性 |
| **Linux (native)** | `/proc/version` 不含 `Microsoft`，`uname -s` = Linux | `/proc/meminfo` | 純 Linux 環境，無 WSL2 wrapper |
| **macOS** | `uname -s` = Darwin | `vm_stat` + `sysctl hw.memsize` | BSD date、vm_stat 格式、Homebrew 依賴 |

## 4. 平台識別邏輯（標準偽碼）

```bash
# 跨平台識別（在所有 bash 腳本中統一使用）
detect_platform() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "macOS"
  elif [[ -f "/proc/version" ]]; then
    if grep -qi "Microsoft\|WSL" /proc/version 2>/dev/null; then
      echo "WSL2"
    else
      echo "Linux-native"
    fi
  else
    echo "other-unix"
  fi
}
```

## 5. 記憶體讀取跨平台邏輯（parallel-safety 相關）

```bash
# 取得可用記憶體（MB）— 跨平台實作
get_available_memory_mb() {
  local platform
  platform="$(detect_platform)"

  case "${platform}" in
    macOS)
      # macOS: vm_stat + sysctl
      local page_size mem_free
      page_size=$(sysctl -n hw.pagesize 2>/dev/null || echo 4096)
      mem_free=$(vm_stat 2>/dev/null | grep "Pages free:" | awk '{print $3}' | tr -d '.' || echo 0)
      echo $(( (mem_free * page_size) / 1024 / 1024 ))
      ;;
    WSL2|Linux-native)
      # Linux / WSL2: /proc/meminfo
      awk '/^MemAvailable:/ { printf "%d", $2/1024 }' /proc/meminfo 2>/dev/null || echo 0
      ;;
    *)
      echo "1024"  # fallback: 假設 1GB 可用
      ;;
  esac
}
```

## 6. 測試覆蓋矩陣

| 測試項目 | WSL2 | Linux-native | macOS | 實作位置 |
|---------|------|-------------|-------|---------|
| 平台偵測 | ✓ | ✓ | ✓ | test-multiplatform-compat.sh §AC6 |
| /proc/meminfo 讀取 | ✓ (MemTotal) | ✓ | N/A | test-multiplatform-compat.sh §AC6b |
| vm_stat 可用性 | N/A | N/A | ✓ | test-multiplatform-compat.sh §AC6b |
| parallel-safety 記憶體感知 | ✓ (#722) | ✓ (#722) | ✓ (#722) | test-parallel-safety.sh |
| 宿主平台相容性（Claude Code等） | ✓ | ✓ | ✓ | test-multiplatform-compat.sh §AC1-AC5 |

## 7. AC2 — cruise logs 記錄平台資訊

cruise logs 在 Sprint 154+ 記錄當前執行平台（由 §4.4 log-archived 或初始化 log entry 附加）：

```json
{
  "type": "cruise-init",
  "platform": "WSL2",
  "platform_detail": "Linux 6.6.87.2-microsoft-standard-WSL2",
  "timestamp": "2026-03-25T15:00:00Z"
}
```

## 8. 關聯文件

- `tests/test-multiplatform-compat.sh` — 4 宿主平台相容性測試（#710）+ WSL2 環境檢測（#720）
- `tests/test-memory-aware-parallel.sh` — 記憶體感知 parallel-safety 測試（#712）
- `skills/sprint-execution/references/parallel-safety.md` — parallel-safety 設計
- `docs/adr/ADR-039-token-cost-routing.md` — model routing 風險評分
