# Shikigami 專案範本

本範本提供使用 Shikigami AI Agent Scrum Team 框架的快速啟動配置。

## 快速開始

在新專案目錄執行以下指令，5 分鐘內完成初始化：

```bash
# 1. 複製範本到新專案
cp -r path/to/shikigami/templates/project/. ./

# 2. 初始化 Shikigami 配置
bash scripts/init-project.sh

# 3. 驗證配置完整性
bash scripts/validate-json.sh
bash scripts/validate-skills.sh
```

## 範本內容

```
templates/project/
├── README.md              # 本文件
├── hooks.json             # 預設 Hook 配置（SessionStart / SessionEnd / Stop）
├── skills/                # 推薦 Skill 清單（符號連結說明）
│   └── README.md          # Skill 連結設定指引
└── scripts/               # 常用腳本範本
    └── init-project.sh    # 一鍵初始化腳本
```

## 配置說明

### hooks.json

預設 Hook 配置包含：
- `SessionStart`：session 啟動時執行 session-start hook（日誌、出勤紀錄）
- `SessionEnd`：session 結束時 release claim 鎖
- `Stop`：緊急停止處理

複製到專案根目錄後修改 `CLAUDE_PLUGIN_ROOT` 指向實際 Shikigami 安裝路徑。

### skills/ 目錄

建議透過符號連結使用 Shikigami 官方 Skills，確保版本同步更新：

```bash
# 建立 skill 符號連結（以 sprint-planning 為例）
ln -s path/to/shikigami/skills/sprint-planning skills/sprint-planning
```

### 版本同步

範本與 Shikigami 主框架版本保持同步。版本 bump 時一同更新。

## 相關文件

- [Shikigami 框架 CLAUDE.md](../../CLAUDE.md)
- [Hook 配置說明](../../hooks/)
- [Skills 目錄](../../skills/)
