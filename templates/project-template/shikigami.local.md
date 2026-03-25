---
shikigami:
  project_level: medium
  close_policy:
    require_creator_approval: false
    default_timeout: 2h
  delivery_chain:
    default: production
  feedback_routing:
    default: {{OWNER_REPO}}
  cruise:
    patrol: po
    progress_fallback_window: 30m
    cruise_archive_days: 7
---

# {{PROJECT_NAME}} 專案配置

- **專案名稱**：{{PROJECT_NAME}}
- **自治等級**：medium — 高風險操作留言確認
