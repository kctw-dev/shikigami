# docs/guides/ — 指南索引

本目錄集中收錄 Shikigami 框架的各類開發指南，供不同角色快速查閱。

## 指南清單

| 指南 | 摘要 | 適用對象 |
|------|------|---------|
| [hook-development-guide.md](hook-development-guide.md) | Hook 開發標準規範：命名、結構、錯誤處理、測試 | Hook 開發者、Plugin 維護者 |
| [script-testability-guide.md](script-testability-guide.md) | 腳本可測試性設計規範：環境變數注入、test fixture 設計 | 腳本開發者、QA |
| [E2E-TEST-MANAGEMENT.md](E2E-TEST-MANAGEMENT.md) | E2E Test Case 管理規範：測試案例生命週期、命名、維護 | QA、Sprint 執行者 |
| [figma-mcp-setup.md](figma-mcp-setup.md) | Figma MCP Server 選型與本地設定指南 | UI/UX 設計者、環境設定 |
| [figma-desktop-verification-sop.md](figma-desktop-verification-sop.md) | Figma Desktop 本地驗證環境 SOP | UI/UX 設計者 |
| [figma-pipeline-usage-guide.md](figma-pipeline-usage-guide.md) | Figma 管線使用指南：從設計稿到元件的流程 | UI/UX 設計者、前端開發者 |

## 入門路徑

依角色建議的閱讀順序：

**Hook 開發者**
1. [hook-development-guide.md](hook-development-guide.md) — Hook 開發標準
2. [script-testability-guide.md](script-testability-guide.md) — 確保腳本可測試

**Sprint 執行者**
1. [E2E-TEST-MANAGEMENT.md](E2E-TEST-MANAGEMENT.md) — 測試案例管理
2. [script-testability-guide.md](script-testability-guide.md) — 腳本設計規範

**UI/UX 設計者**
1. [figma-mcp-setup.md](figma-mcp-setup.md) — MCP 環境設定
2. [figma-desktop-verification-sop.md](figma-desktop-verification-sop.md) — 本地驗證環境
3. [figma-pipeline-usage-guide.md](figma-pipeline-usage-guide.md) — 從設計稿到元件
