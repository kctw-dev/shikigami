#!/bin/bash
# init-project.sh — Shikigami 專案快速初始化腳本
# 使用方式：bash scripts/init-project.sh [SHIKIGAMI_ROOT]
# 來源：templates/project/scripts/init-project.sh

set -euo pipefail

SHIKIGAMI_ROOT="${1:-$(dirname "$0")/../../..}"
PROJECT_ROOT="$(pwd)"

echo "==============================="
echo " Shikigami 專案初始化"
echo "==============================="
echo "Shikigami 路徑：${SHIKIGAMI_ROOT}"
echo "專案路徑：${PROJECT_ROOT}"
echo ""

# 步驟 1：複製 hooks.json
if [ ! -f "${PROJECT_ROOT}/hooks.json" ]; then
    cp "${SHIKIGAMI_ROOT}/templates/project/hooks.json" "${PROJECT_ROOT}/hooks.json"
    echo "[OK] hooks.json 已複製"
else
    echo "[SKIP] hooks.json 已存在，跳過"
fi

# 步驟 2：建立 skills/ 目錄與符號連結
mkdir -p "${PROJECT_ROOT}/skills"
for skill in sprint-planning sprint-execution sprint-review shoot health-check issue-management; do
    if [ -d "${SHIKIGAMI_ROOT}/skills/${skill}" ]; then
        if [ ! -L "${PROJECT_ROOT}/skills/${skill}" ]; then
            ln -s "${SHIKIGAMI_ROOT}/skills/${skill}" "${PROJECT_ROOT}/skills/${skill}"
            echo "[OK] 建立 skills/${skill} 符號連結"
        else
            echo "[SKIP] skills/${skill} 符號連結已存在"
        fi
    else
        echo "[WARN] skills/${skill} 在 Shikigami 路徑中不存在，跳過"
    fi
done

# 步驟 3：複製 CLAUDE.md.template（若不存在）
if [ ! -f "${PROJECT_ROOT}/.claude/CLAUDE.md" ] && [ ! -f "${PROJECT_ROOT}/CLAUDE.md" ]; then
    mkdir -p "${PROJECT_ROOT}/.claude"
    cp "${SHIKIGAMI_ROOT}/templates/CLAUDE.md.template" "${PROJECT_ROOT}/CLAUDE.md"
    echo "[OK] CLAUDE.md 已從範本複製"
else
    echo "[SKIP] CLAUDE.md 已存在，跳過"
fi

echo ""
echo "==============================="
echo " 初始化完成，驗證配置..."
echo "==============================="

# 步驟 4：驗證
VALIDATE_OK=true
if [ -f "${PROJECT_ROOT}/scripts/validate-json.sh" ]; then
    bash "${PROJECT_ROOT}/scripts/validate-json.sh" && echo "[PASS] validate-json.sh" || { echo "[FAIL] validate-json.sh"; VALIDATE_OK=false; }
fi

if [ "$VALIDATE_OK" = "true" ]; then
    echo ""
    echo "[完成] 專案初始化成功！"
    echo "下一步：設定 .claude/shikigami.local.md 中的 project_level 和其他配置"
else
    echo ""
    echo "[警告] 部分驗證失敗，請手動修正後重新執行驗證腳本"
fi
