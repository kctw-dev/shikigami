# Skills 連結設定指引

## 推薦做法：符號連結

透過符號連結使用 Shikigami 官方 Skills，確保版本同步更新：

```bash
# 設定 SHIKIGAMI_ROOT 為 Shikigami 安裝路徑
SHIKIGAMI_ROOT=path/to/shikigami

# 建立核心 Skill 符號連結
ln -s ${SHIKIGAMI_ROOT}/skills/sprint-planning      skills/sprint-planning
ln -s ${SHIKIGAMI_ROOT}/skills/sprint-execution     skills/sprint-execution
ln -s ${SHIKIGAMI_ROOT}/skills/sprint-review        skills/sprint-review
ln -s ${SHIKIGAMI_ROOT}/skills/shoot                skills/shoot
ln -s ${SHIKIGAMI_ROOT}/skills/health-check         skills/health-check
ln -s ${SHIKIGAMI_ROOT}/skills/issue-management     skills/issue-management
ln -s ${SHIKIGAMI_ROOT}/skills/cruise               skills/cruise
```

## 推薦 Skill 清單（最小集合）

| Skill | 用途 | 必要性 |
|-------|------|--------|
| sprint-planning | Sprint 週期起點，Backlog 排序與 Story 選取 | 必要 |
| sprint-execution | Story 開發執行，TDD + 審查 + PR | 必要 |
| sprint-review | Sprint 驗收與 Retro | 必要 |
| shoot | 快速單一 Story 交付 | 建議 |
| health-check | 框架完整性自我診斷 | 建議 |
| issue-management | Issue 生命週期管理 | 建議 |
| cruise | 定期 PO 巡邏 + 背景監控 | 可選 |

## 版本同步

Skills 透過符號連結指向 Shikigami 安裝目錄，版本 bump 時自動同步，無需手動更新。
