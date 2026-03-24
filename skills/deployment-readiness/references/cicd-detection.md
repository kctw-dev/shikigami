# CI/CD 環境偵測 — Self-hosted Runner 警示

**抽出自**：deployment-readiness/SKILL.md §11
**新增於**：Sprint 45（US-93，ADR-011 合規）

部署就緒檢查期間，SRE subagent 必須執行以下 CI/CD 環境偵測步驟，識別潛在的 self-hosted runner OOM 風險。

## 偵測步驟

1. 掃描 `grep -rn "runs-on:" .github/workflows/`，列出所有 workflow 的 runner 配置
2. 若所有 `runs-on:` 均為 `self-hosted`，輸出 `[CI/CD 拆分建議]` 警示：建議依 `docs/ci-cd-guide/README.md` 決策樹將 compute-heavy 任務移至 GitHub-hosted runner（OOM 風險），event-driven 任務保留 self-hosted
3. 記錄偵測結果於部署 Checklist 備注欄

## 決策規則

| 偵測結果 | 動作 |
|---------|------|
| 所有 workflow 均跑在 self-hosted | 輸出 CI/CD 拆分建議警示，不阻擋部署 |
| 部分 workflow 已使用 GitHub-hosted | 無需動作，視為已拆分 |
| 無 `.github/workflows/` 目錄 | 無需動作，跳過此步驟 |

> **注意**：此偵測為建議性提示，不構成部署 Hard Gate 阻擋條件。但若消費端專案持續出現 CI 測試失敗，應將拆分建議列入下一 Sprint 技術債處理。
