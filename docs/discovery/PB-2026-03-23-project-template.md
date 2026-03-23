# Product Brief: 專案範本（Skills/Hooks/Script 綁定）

**PB ID**: PB-2026-03-23-project-template
**狀態**: Draft
**建立日期**: 2026-03-23
**來源議題**: #362 GAD 研究報告 §三 NX Monorepo 範本
**產品負責人**: PO Agent

---

## 1. 問題陳述

每個新專案導入 Shikigami 時，使用者需要從零配置：

- **配置成本高**：需要手動設定 `CLAUDE.md`、`hooks.json`、`.claude-plugin/plugin.json`，容易遺漏或設定錯誤
- **配置不一致**：不同專案的 Shikigami 配置差異大，難以分享最佳實踐或 debug 他人問題
- **Onboarding 摩擦**：新使用者（或新 AI agent）進入一個已有的 repo 時，不知道這個 repo 的 Shikigami 配置是什麼
- **Monorepo 支援缺失**：多個子 repo 共存時，每個子 repo 各自配置，共用 Skill 和 Hook 沒有統一管理機制
- **範本過時**：`templates/CLAUDE.md` 存在，但沒有綁定對應的 hooks、scripts、skill 清單，不是完整的「起點」

GAD 研究報告（#362）指出：NX Monorepo 範本的思路（workspace 級別的統一配置 + 子 project 的局部覆蓋）可以解決此問題。

---

## 2. 目標使用者

**主要**：將 Shikigami 導入新專案的開發者（第一次配置的使用者）
**次要**：管理多個子 repo 的 Platform 團隊，需要在所有 repo 推行統一的 Shikigami 配置

使用場景：
- 新建一個 Node.js 後端 repo，執行 `shikigami init --template node-backend`，自動配置完整環境
- Platform 團隊更新 Shikigami 範本後，所有採用範本的 repo 可以 pull 最新配置
- GAD 場景中，多個子 repo 共享同一份 Skill 定義，確保一致性

---

## 3. 商業假設 [UNCERTAIN]

- [UNCERTAIN] 新專案導入 Shikigami 的配置時間目前超過 30 分鐘，範本可降低到 5 分鐘以內
- [UNCERTAIN] 標準化配置可讓 AI agent 在進入新 repo 時，減少 50% 的「理解配置」所需時間
- [UNCERTAIN] 開發者願意遵循範本提供的標準結構，不隨意自定義（範本的約束性可被接受）
- [UNCERTAIN] Monorepo 場景的 Shikigami 使用頻率足以支撐對應範本的投資（至少 20% 的用戶是 Monorepo）

---

## 4. 提案解決方向

### 核心概念
建立分層範本系統：workspace 級別範本（通用配置）+ 專案類型範本（language/framework 特定配置）+ 局部覆蓋（per-repo 客製化）。

### 範本結構（草案）
```
templates/
├── base/                    # 通用基礎配置
│   ├── CLAUDE.md            # 基礎 CLAUDE.md（含 Shikigami 標準規範）
│   ├── hooks.json           # 標準 Hook 配置
│   └── .claude-plugin/
│       └── plugin.json      # Plugin manifest 範本
├── node-backend/            # Node.js 後端範本
│   ├── CLAUDE.md            # 繼承 base，加 Node.js 特定規範
│   └── scripts/             # Node.js 特定驗證腳本
├── python-backend/          # Python 後端範本
├── frontend-react/          # React 前端範本
└── monorepo/                # Monorepo 範本（NX 風格）
    ├── workspace.json       # Workspace 級別配置
    └── packages/            # 子 package 範本
```

### 方向 A：CLI 工具（shikigami init）
建立 `shikigami init` 指令，互動式選擇範本類型，自動套用配置。需要實作 CLI，成本較高。

### 方向 B：複製貼上範本（docs + scripts）
在 `templates/` 目錄提供完整範本，配合 `scripts/init-from-template.sh` 腳本快速套用。不需要 CLI，但體驗較不流暢。

### 方向 C：GitHub Template Repository
將 Shikigami 範本發布為 GitHub template repo，新專案直接 fork template。最容易使用，但缺乏後續更新同步機制。

推薦方向：**方向 B + C**（先做 Script + GitHub Template，快速交付，未來再考慮 CLI）。

---

## 5. 成功指標

| 指標 | 基準線 | 目標 | 測量方式 |
|------|--------|------|----------|
| 新專案 Shikigami 配置時間 | 待建立基準（估計 30+ 分鐘） | < 10 分鐘 | 新使用者訪談 |
| 範本採用率（新專案中使用範本的比例） | N/A（無範本） | ≥ 60% | GitHub template 使用統計 |
| 因配置錯誤導致的 agent 異常次數 / Sprint | 待建立基準 | 降低 70% | Sprint Retro 紀錄 |
| Monorepo 場景的配置一致性（子 repo 遵循 workspace 配置） | N/A | ≥ 90% | 配置審查 |

---

## 6. 排除範圍

- 不實作 CLI 工具（範本腳本優先，CLI 是長期演進方向）
- 不處理現有 repo 的「遷移到範本」（只針對新專案；現有 repo 遷移是獨立工作）
- 不涉及 Shikigami 以外的工具配置（git hooks、lint 等不在本 PB 範圍）
- 不提供超過 5 個範本類型（過多範本維護成本過高，優先覆蓋最常見場景）

---

## 7. 依賴與風險

### 依賴
- 需要盤點現有 `templates/` 目錄的內容，評估與目標範本的差距
- 範本的 `CLAUDE.md` 必須與主 repo 的 `CLAUDE.md` 規範保持同步（版本對齊機制）
- Monorepo 範本需要 Architect 定義 workspace 與 package 之間的 Shikigami 配置繼承規則

### 風險
| 風險 | 可能性 | 影響 | 緩解策略 |
|------|--------|------|----------|
| 範本與主 repo 版本 drift，採用舊範本的 repo 行為不一致 | 高 | 中 | 範本版號與 plugin.json 版號綁定，範本更新時主動通知 |
| 範本過於通用，各專案仍需大量客製化 | 中 | 中 | 收集前 3 個真實採用案例的反饋，疊代範本內容 |
| Monorepo 範本的 workspace 配置繼承規則複雜 | 中 | 中 | 先做 flat 範本（不做繼承），monorepo 進階支援在 v2 處理 |
