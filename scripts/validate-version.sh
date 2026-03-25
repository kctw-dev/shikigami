#!/usr/bin/env bash
# scripts/validate-version.sh
# US-T04：版號一致性驗證
#
# 驗證 .claude-plugin/ 目錄下各檔案的版號一致性。
#
# Exit code:
#   0 = 全部通過（PASS / WARNING）
#   1 = 有 FAIL
#
# 依賴：jq, git, bash >= 4

set -uo pipefail

# ---------------------------------------------------------------------------
# 常數
# ---------------------------------------------------------------------------
readonly PLUGIN_JSON=".claude-plugin/plugin.json"
readonly MARKETPLACE_JSON=".claude-plugin/marketplace.json"
readonly GEMINI_EXTENSION_JSON="gemini-extension.json"
readonly README_FILE="README.md"
readonly CLAUDE_MD="CLAUDE.md"

# ---------------------------------------------------------------------------
# 狀態追蹤
# ---------------------------------------------------------------------------
EXIT_CODE=0
PLUGIN_VERSION=""

# ---------------------------------------------------------------------------
# 輔助函式
# ---------------------------------------------------------------------------
print_pass() {
  echo "[PASS] $1"
}

print_fail() {
  echo "[FAIL] $1"
  EXIT_CODE=1
}

print_warning() {
  echo "[WARNING] $1"
}

print_section() {
  echo ""
  echo "--- $1"
}

is_dev_version() {
  # 回傳 0（true）若版號符合 0.x.x 開發期格式
  local version="$1"
  [[ "$version" =~ ^0\.[0-9]+\.[0-9]+$ ]]
}

# ---------------------------------------------------------------------------
# 前置檢查：確認必要工具與檔案存在
# ---------------------------------------------------------------------------
preflight_check() {
  local error=0

  # 檢查 jq 是否存在
  if ! command -v jq &>/dev/null; then
    echo "[ERROR] 必要工具 jq 未安裝。"
    echo "  請先安裝 jq："
    echo "    macOS:  brew install jq"
    echo "    Ubuntu: sudo apt-get install jq"
    echo "    Alpine: apk add jq"
    exit 1
  fi

  if [ ! -f "$PLUGIN_JSON" ]; then
    echo "[ERROR] 找不到 $PLUGIN_JSON"
    error=1
  fi

  if [ ! -f "$MARKETPLACE_JSON" ]; then
    echo "[ERROR] 找不到 $MARKETPLACE_JSON"
    error=1
  fi

  if [ "$error" -eq 1 ]; then
    echo ""
    echo "前置檢查失敗，請確認 .claude-plugin/ 目錄結構正確。"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# AC1：比較 plugin.json version vs marketplace.json plugins[0].version
# 結果存入全域變數 PLUGIN_VERSION
# ---------------------------------------------------------------------------
check_ac1_json_consistency() {
  print_section "AC1：plugin.json vs marketplace.json 版號一致性"

  local market_version
  PLUGIN_VERSION=$(jq -r '.version' "$PLUGIN_JSON")
  market_version=$(jq -r '.plugins[0].version' "$MARKETPLACE_JSON")

  echo "  plugin.json      version: $PLUGIN_VERSION"
  echo "  marketplace.json version: $market_version"

  # AC4：版本為空字串時 FAIL，而非靜默 PASS
  if [ -z "$PLUGIN_VERSION" ]; then
    print_fail "plugin.json 版號為空字串，無法驗證"
    return
  fi

  if [ -z "$market_version" ]; then
    print_fail "marketplace.json 版號為空字串，無法驗證"
    return
  fi

  if [ "$PLUGIN_VERSION" = "$market_version" ]; then
    print_pass "plugin.json 與 marketplace.json 版號一致 ($PLUGIN_VERSION)"
  else
    print_fail "版號不一致：plugin.json=$PLUGIN_VERSION，marketplace.json=$market_version"
  fi
}

# ---------------------------------------------------------------------------
# AC1b：比較 gemini-extension.json version vs plugin.json version
# ---------------------------------------------------------------------------
check_ac1b_gemini_consistency() {
  print_section "AC1b：gemini-extension.json vs plugin.json 版號一致性"

  if [ ! -f "$GEMINI_EXTENSION_JSON" ]; then
    print_warning "找不到 $GEMINI_EXTENSION_JSON，跳過 Gemini Extension 版號檢查"
    return
  fi

  local gemini_version
  gemini_version=$(jq -r '.version' "$GEMINI_EXTENSION_JSON")

  echo "  plugin.json            version: $PLUGIN_VERSION"
  echo "  gemini-extension.json  version: $gemini_version"

  if [ "$PLUGIN_VERSION" = "$gemini_version" ]; then
    print_pass "plugin.json 與 gemini-extension.json 版號一致 ($PLUGIN_VERSION)"
  else
    print_fail "版號不一致：plugin.json=$PLUGIN_VERSION，gemini-extension.json=$gemini_version"
  fi
}

# ---------------------------------------------------------------------------
# AC-README：比較 README.md badge 版號 vs plugin.json version
# ---------------------------------------------------------------------------
check_readme_badge_consistency() {
  print_section "AC-README：README.md badge 版號一致性"

  if [ ! -f "$README_FILE" ]; then
    print_fail "找不到 $README_FILE，無法驗證 badge 版號"
    return
  fi

  # 用 regex 提取 badge 版號
  # 格式：![Version](https://img.shields.io/badge/version-v<VERSION>-blue...)
  local badge_version
  badge_version=$(grep -oP '!\[Version\]\(https://img\.shields\.io/badge/version-v\K[^-]+' "$README_FILE" | head -1)

  echo "  plugin.json  version: $PLUGIN_VERSION"
  echo "  README.md badge version: ${badge_version:-（未找到）}"

  if [ -z "$badge_version" ]; then
    print_fail "README.md 中找不到 Version badge，無法驗證版號"
    return
  fi

  if [ "$PLUGIN_VERSION" = "$badge_version" ]; then
    print_pass "README.md badge 與 plugin.json 版號一致 ($PLUGIN_VERSION)"
  else
    print_fail "版號不一致：plugin.json=$PLUGIN_VERSION，README.md badge=v$badge_version"
  fi
}

# ---------------------------------------------------------------------------
# AC-CLAUDE：比較 CLAUDE.md 版號 vs plugin.json version
# ---------------------------------------------------------------------------
check_claude_md_consistency() {
  print_section "AC-CLAUDE：CLAUDE.md vs plugin.json 版號一致性"

  if [ ! -f "$CLAUDE_MD" ]; then
    print_warning "找不到 $CLAUDE_MD，跳過版號檢查"
    return
  fi

  local claude_version
  claude_version=$(grep -oP '^\- \*\*目前版本\*\*：v\K[0-9]+\.[0-9]+\.[0-9]+' "$CLAUDE_MD" | head -1)

  echo "  plugin.json  version: $PLUGIN_VERSION"
  echo "  CLAUDE.md    version: ${claude_version:-（未找到）}"

  if [ -z "$claude_version" ]; then
    print_fail "CLAUDE.md 中找不到版號行，無法驗證"
    return
  fi

  if [ "$PLUGIN_VERSION" = "$claude_version" ]; then
    print_pass "CLAUDE.md 與 plugin.json 版號一致 ($PLUGIN_VERSION)"
  else
    print_fail "版號不一致：plugin.json=$PLUGIN_VERSION，CLAUDE.md=v$claude_version"
  fi
}

# ---------------------------------------------------------------------------
# AC2 + AC3：比較最新 semver git tag vs plugin.json version
# ---------------------------------------------------------------------------
check_ac2_git_tag_consistency() {
  local plugin_version="$1"
  print_section "AC2：git tag vs plugin.json 版號一致性"

  # 取得最新 semver tag（v 開頭，依 semver 排序）
  local latest_tag
  latest_tag=$(git tag --list 'v*' --sort=-v:refname 2>/dev/null | head -1)

  if [ -z "$latest_tag" ]; then
    print_pass "無 git tag，跳過 tag 版號檢查"
    return
  fi

  # 去除 v 前綴以取得純版號
  local tag_version="${latest_tag#v}"

  echo "  最新 git tag:    $latest_tag ($tag_version)"
  echo "  plugin.json:     $plugin_version"

  if [ "$tag_version" = "$plugin_version" ]; then
    print_pass "git tag 與 plugin.json 版號一致 ($tag_version)"
    return
  fi

  # 版號不一致：套用 AC3 規則
  if is_dev_version "$plugin_version"; then
    # AC3：0.x.x 開發期，降級為 WARNING
    print_warning "git tag 與 plugin.json 版號不一致（開發期，允許未對齊）：tag=$tag_version，plugin=$plugin_version"
  else
    # 1.0.0 以上：強制 FAIL
    print_fail "git tag 與 plugin.json 版號不一致：tag=$tag_version，plugin=$plugin_version"
  fi
}

# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
main() {
  echo "=============================="
  echo " validate-version.sh"
  echo " .claude-plugin/ 版號一致性驗證"
  echo "=============================="

  preflight_check

  # AC1：直接在目前 shell 執行，EXIT_CODE 與 PLUGIN_VERSION 可被修改
  check_ac1_json_consistency

  # AC1b：gemini-extension.json vs plugin.json
  check_ac1b_gemini_consistency

  # AC-README：README.md badge vs plugin.json
  check_readme_badge_consistency

  # AC-CLAUDE：CLAUDE.md vs plugin.json
  check_claude_md_consistency

  # AC-ROADMAP：ROADMAP.md 版號同步（#810）
  check_roadmap_version_consistency

  # AC2 + AC3
  check_ac2_git_tag_consistency "$PLUGIN_VERSION"

  # 總結
  echo ""
  echo "=============================="
  if [ "$EXIT_CODE" -eq 0 ]; then
    echo " 總結：版號驗證全部通過"
  else
    echo " 總結：版號驗證發現問題，請修正後重試"
  fi
  echo "=============================="

  exit "$EXIT_CODE"
}



# ---------------------------------------------------------------------------
# AC-ROADMAP：比較 ROADMAP.md 目前版本 vs plugin.json version（#810）
# ---------------------------------------------------------------------------
check_roadmap_version_consistency() {
  print_section "AC-ROADMAP：ROADMAP.md 版號同步驗證（#810）"

  local roadmap_file="docs/prd/ROADMAP.md"

  if [ ! -f "$roadmap_file" ]; then
    print_warning "找不到 $roadmap_file，跳過 ROADMAP 版號檢查"
    return
  fi

  # Extract version from "目前版本：**vX.Y.Z**" pattern
  local roadmap_version
  roadmap_version=$(grep -oP "目前版本：\*\*v\K[0-9]+\.[0-9]+\.[0-9]+" "$roadmap_file" | head -1)

  echo "  plugin.json  version: $PLUGIN_VERSION"
  echo "  ROADMAP.md   version: ${roadmap_version:-（未找到）}"

  if [ -z "$roadmap_version" ]; then
    print_fail "ROADMAP.md 中找不到「目前版本：**vX.Y.Z**」格式，無法驗證版號（請確認 bump 時同步更新）"
    return
  fi

  if [ "$PLUGIN_VERSION" = "$roadmap_version" ]; then
    print_pass "ROADMAP.md 與 plugin.json 版號一致 ($PLUGIN_VERSION)"
  else
    print_fail "ROADMAP.md 版號落後：plugin.json=$PLUGIN_VERSION，ROADMAP.md=v$roadmap_version（請執行 bump 更新 ROADMAP.md）"
  fi
}

main
