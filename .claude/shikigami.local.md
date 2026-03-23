---
shikigami:
  project_level: low
  close_policy:
    require_creator_approval: false   # false（預設）= 直接 close；true = 等發 Issue 人確認
    default_timeout: 2h               # 等待確認的 timeout（預設 2h）
    per_repo:
      # 範例：KCTW/kinun: 4h         # 個別 repo 可覆蓋 timeout
  delivery_chain:
    default: production               # production = 完整鏈；pr = PR merge 即完成；none = 跳過
    per_repo:
      # 範例：kctw-dev/seiryu: none  # 純原型 repo，跳過交付追蹤
  feedback_routing:
    default: kctw-dev/shikigami       # 預設回報目標
    # Future: pattern-based routing（尚未實作，目前僅使用 default）
  cruise:
    progress_fallback_window: 30m     # 背景 Agent 進度偵測 fallback 視窗（預設 30m，支援 Nm / Nh）
  oauth:
    warn_threshold_hours: 24          # OAuth Token 過期告警門檻（預設 24 小時）
---

# Shikigami 專案配置

- **專案名稱**：Shikigami（式神）
- **技術棧**：Claude Code Plugin（Markdown + Shell + Node.js）
- **自治等級**：low — 高風險操作自動執行，事後通知
