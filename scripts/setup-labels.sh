#!/usr/bin/env bash
set -euo pipefail

# Shikigami — GitHub Labels Setup
# 建立 Shikigami 框架所需的常用 GitHub Labels
# 使用 --force 確保冪等性（已存在的 label 會更新而非報錯）

LABELS=(
  "bug:#d73a4a:Something isn't working"
  "feature-request:#a2eeef:New feature or request"
  "retro-action:#fbca04:Retrospective action item"
  "in-backlog:#0075ca:Tracked in product backlog"
  "needs-info:#d876e3:Further information is requested"
  "priority-high:#b60205:High priority"
  "priority-low:#c5def5:Low priority"
  "enhancement:#a2eeef:Enhancement to existing feature"
  "deferred:#e4e669:Deferred to next sprint"
)

for entry in "${LABELS[@]}"; do
  IFS=':' read -r name color description <<< "$entry"
  gh label create "$name" --color "${color#\#}" --description "$description" --force
done

echo "Labels setup complete."
