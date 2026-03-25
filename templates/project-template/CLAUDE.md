# {{PROJECT_NAME}} — Claude Code 開發指南

## 專案資訊

- **專案名稱**：{{PROJECT_NAME}}
- **性質**：（請填寫專案類型）
- **目前版本**：v0.1.0
- **授權**：MIT

## 技術棧

（請填寫技術棧）

## 開發紅線

1. 遵循 Shikigami 框架規範
2. 所有日期時間用 `date` 指令取得系統時間
3. 禁止幻覺：非發散階段遇未定義情況回退詢問
4. TDD 雙重驗證：寫不出測試代表需求不清

## 目錄結構

```
docs/
├── adr/       # 架構決策紀錄
├── sprints/   # Sprint 紀錄
├── km/        # 知識管理
└── prd/       # 產品需求文件
```

## Commit 慣例

使用 Conventional Commits：
- `feat:` — 新功能
- `fix:` — Bug 修復
- `chore:` — 版本 bump、維護
- `docs:` — 文件更新
