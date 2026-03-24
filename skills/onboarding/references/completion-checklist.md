# Onboarding 完成清單

<!-- 本檔案由 onboarding/SKILL.md §2.5 + §3 拆出，主文件以指針引用 -->

## 下一步清單（§2.5 輸出格式）

所有步驟完成後，輸出 Product Discovery 引導清單：

```
## Onboarding 完成

以下是你的下一步：

1. **確認專案配置文件**
   確認專案名稱、技術棧、專案等級設定正確。
   如需調整，直接編輯 CLAUDE.md（Claude Code / OpenCode）或 GEMINI.md（Gemini CLI）。

2. **執行 /standup**
   確認框架狀態健康，開始每日工作節奏。

3. **填寫全局架構文件（SDD-000）**
   `docs/sdd/SDD-000-architecture.md` 已建立。
   **首次執行 Sprint Planning 前**，請填入至少一個核心 Entity 和 Service 作為基線，
   確保後續開發工作可在 SDD 體系中定位（見 Architect SKILL.md §11 Hard Gate）。

4. **Sprint Planning**
   執行 `/sprint` 開始第一個 Sprint，從 Product Backlog 選取 Stories。

5. **GitHub Action 串接狀態**
   {GITHUB_ACTION_STATUS}
```

> `{GITHUB_ACTION_STATUS}` 由 §2.6 執行結果填入，例如：
> - `new-issue-intake 已就緒（self-hosted runner 已連線，OAuth 已認證）`
> - `new-issue-intake 待設定（見 §2.6 手動指引）`

---

## 3. 冪等性報告

執行完成後（無論是首次或重複執行），輸出統計摘要：

```
## Onboarding 執行摘要

跳過 {X} 目錄、{Y} 檔案（共 {Z} 項）

詳細：
- 目錄已存在跳過：{X} 個
- 文件已存在跳過：{Y} 個
- 新建目錄：{A} 個
- 新建文件：{B} 個
```

若為全新安裝（所有項目皆為新建），X=0、Y=0、Z=0。
