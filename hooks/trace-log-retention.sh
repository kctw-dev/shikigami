#!/usr/bin/env bash
# trace-log-retention.sh — #392 Structured Trace Log retention 清理腳本
# ADR-033 決策 4：超過 SHIKIGAMI_TRACE_RETENTION_DAYS 的 trace log 自動清理
#
# 設計原則：
# - 僅清理 docs/trace-logs/ 下的 .jsonl 檔案
# - 預設保留 7 天，可透過 SHIKIGAMI_TRACE_RETENTION_DAYS 配置
# - 靜默執行（失敗不阻塞主流程）
# - 允許 TRACE_LOG_DIR 環境變數覆蓋（測試友好設計）

set -euo pipefail

# ---------- 配置 ----------
RETENTION_DAYS="${SHIKIGAMI_TRACE_RETENTION_DAYS:-7}"

# 允許 TRACE_LOG_DIR 覆蓋（供測試使用）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="${PLUGIN_ROOT}"

# 嘗試從 git 取得 repo root（若在 plugin 目錄以外執行）
GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "${PLUGIN_ROOT}")"
TRACE_LOG_DIR="${TRACE_LOG_DIR:-${GIT_ROOT}/docs/trace-logs}"

# ---------- 前置檢查 ----------
if [[ ! -d "${TRACE_LOG_DIR}" ]]; then
  # 目錄不存在，靜默跳過（不算錯誤）
  exit 0
fi

# ---------- 清理邏輯 ----------
# 清理超過 retention 天數的 .jsonl trace log 檔案
# 使用 find -mtime +N（N 天前修改的檔案）
CLEANED=0
while IFS= read -r -d '' old_file; do
  rm -f "${old_file}" 2>/dev/null && CLEANED=$((CLEANED + 1)) || true
done < <(find "${TRACE_LOG_DIR}" -maxdepth 1 -name "*.jsonl" -mtime "+${RETENTION_DAYS}" -print0 2>/dev/null)

if [[ "${CLEANED}" -gt 0 ]]; then
  echo "[trace-log-retention] 已清理 ${CLEANED} 個超過 ${RETENTION_DAYS} 天的 trace log 檔案" >&2
fi

exit 0
