# 安裝驗證報告 — Shikigami

**文件版本**：1.0
**對應 Story**：US-15（Sprint 15）
**測試日期**：2026-03-02
**執行者**：AI Agent（Claude Sonnet 4.6）— 文件審查模式（Architect 降級決策）
**降級說明**：AC2 依 Architect 降級決策改以「文件審查模式」執行，逐步審查 README 步驟合理性、指令可執行性、前提假設完整性，不需實際環境執行。

---

## 測試環境規格（文件審查基準）

| 項目 | 規格 / 版本 |
|------|------------|
| 作業系統 | Linux 6.17.0-1008-gcp（GCP VM，Ubuntu 系列） |
| Node.js 版本 | v20.x LTS（README 隱含前提，需 Claude Code 相容版本） |
| Claude Code CLI 版本 | 最新穩定版（v1.x，安裝 plugin 所需） |
| git 版本 | v2.x（用於 Clone 步驟） |
| GitHub CLI（gh）版本 | v2.x（部分 Skill 使用，非安裝必要） |
| 審查方式 | 文件審查（非實際執行） |

---

## 驗證場景 Checklist

### 場景 1：環境前提確認

| # | 指令 / 動作描述 | 預期輸出 | 結果 | 備注 |
|---|----------------|---------|------|------|
| 1.1 | 確認 Claude Code CLI 已安裝：在終端機執行 `claude --version` | 輸出版本號，如 `claude 1.x.x` | PASS（文件審查） | README 未明確說明此前提；建議補充「需先安裝 Claude Code CLI」的說明 |
| 1.2 | 確認 Claude Code 帳號已認證：開啟 Claude Code，確認可正常對話 | Claude Code 回應正常，無認證錯誤 | PASS（文件審查） | README 未提及認證前提；為隱含假設，建議補充 |
| 1.3 | 確認 git 已安裝：執行 `git --version` | 輸出版本號，如 `git version 2.x.x` | PASS（文件審查） | Plugin 安裝不需 git，但使用框架功能（Clone 等）需要 |
| 1.4 | 確認網路連線正常（可存取 Claude Code marketplace） | 無網路錯誤 | PASS（文件審查） | 隱含前提，無需明文列出但用戶應自行確認 |

**場景 1 審查結論**：環境前提步驟存在 2 個隱含假設未在 README 明確說明（Claude Code CLI 安裝前提、認證狀態），需補充至 README 快速開始區段。

---

### 場景 2：Plugin 安裝（取代 Clone）

> **說明**：Shikigami 是 Claude Code plugin，安裝方式為 `claude plugin add`，不需 git clone。本場景驗證 Plugin 安裝流程。

| # | 指令 / 動作描述 | 預期輸出 | 結果 | 備注 |
|---|----------------|---------|------|------|
| 2.1 | 開啟 Claude Code 互動介面（非終端機 shell） | Claude Code session 已啟動 | PASS（文件審查） | README 有說明「在 Claude Code 互動介面中執行」，指引清楚 |
| 2.2 | 執行：`/plugin marketplace add KCTW/shikigami` | 輸出 marketplace 新增確認訊息 | PASS（文件審查） | 指令格式正確，符合 Claude Code plugin API |
| 2.3 | 執行：`/plugin install shikigami` | 輸出安裝完成確認訊息 | PASS（文件審查） | 指令格式正確；README 同時提供 UI 方式作為替代 |
| 2.4 | 開啟新 Session，確認 plugin 已載入 | 系統提示中出現 `shikigami:` 前綴的 Skills | PASS（文件審查） | README FAQ 有說明確認方式，指引完整 |

**場景 2 審查結論**：Plugin 安裝步驟清晰完整，指令可執行，無需修正。README 提供了 UI 備選路徑，降低失敗風險。

---

### 場景 3：Claude Code CLI 設定與認證確認

| # | 指令 / 動作描述 | 預期輸出 | 結果 | 備注 |
|---|----------------|---------|------|------|
| 3.1 | 確認 Claude Code 已正常認證：開啟 Claude Code 新 Session | 可正常對話，無 401/認證錯誤 | PASS（文件審查） | README 未明確說明認證步驟，屬隱含前提 |
| 3.2 | 確認 plugin 已正確載入：說「你有 shikigami superpowers 嗎？」 | Claude 回應確認已載入 Shikigami Skills | PASS（文件審查） | README FAQ 有此驗證方式，指引清楚 |
| 3.3 | 確認 Scrum Master 可被觸發：說「幫我初始化 Shikigami」 | 觸發 onboarding skill | PASS（文件審查） | README 快速開始有此指引，流程合理 |

**場景 3 審查結論**：CLI 設定步驟依賴 Claude Code 本身認證流程，README 未提供認證失敗的處理指引，建議在 FAQ 補充「Claude Code CLI 未認證」情境。

---

### 場景 4：Plugin 掛載驗證

| # | 指令 / 動作描述 | 預期輸出 | 結果 | 備注 |
|---|----------------|---------|------|------|
| 4.1 | 新 Session 中執行：`/plugin`，開啟 plugin UI | 顯示已安裝的 plugin 清單，包含 shikigami | PASS（文件審查） | Claude Code UI 操作，指引合理 |
| 4.2 | 確認 plugin 狀態為 Active（非 Disabled） | shikigami 顯示為啟用狀態 | PASS（文件審查） | 無需額外操作，plugin 安裝後預設啟用 |
| 4.3 | 驗證 Skills 列表可見：確認系統提示含 `shikigami:scrum-master` 等 Skills | 至少可見 scrum-master、sprint-planning 等核心 Skills | PASS（文件審查） | README FAQ「怎麼確認式神有沒有啟動？」有說明，指引清楚 |
| 4.4 | 確認 `.claude-plugin/plugin.json` 存在（框架 repo 內） | 檔案存在且非空 | PASS（文件審查） | 框架 repo 結構已驗證；消費端不需此檔案 |

**場景 4 審查結論**：Plugin 掛載驗證步驟完整，README FAQ 提供了充分的確認方式。無需修正。

---

### 場景 5：首次 `shikigami:standup` 執行確認

| # | 指令 / 動作描述 | 預期輸出 | 結果 | 備注 |
|---|----------------|---------|------|------|
| 5.1 | 確認已完成 onboarding（有 CLAUDE.md）：說「幫我初始化 Shikigami」 | 產生 CLAUDE.md 與 docs/ 目錄結構 | PASS（文件審查） | README 快速開始有說明初始化步驟 |
| 5.2 | 執行 standup：說「standup」或「開始站立會議」 | Scrum Master 觸發 `shikigami:standup`，輸出健康快篩報告 | PASS（文件審查） | standup 是日常使用入口，README 有 `/standup` Command 說明 |
| 5.3 | 確認健康快篩結果為 HEALTHY 或明確列出問題 | 輸出健康狀態（HEALTHY / WARNING / CRITICAL）和 Action Items | PASS（文件審查） | 健康快篩邏輯在 commands/standup.md 中，行為確定 |
| 5.4 | 確認輸出中無「CLAUDE.md 缺失」誤報（框架 repo 環境） | 框架 repo 中跳過 CLAUDE.md 檢查（US-S02 已修正） | PASS（文件審查） | US-S02 已在 Sprint 11 修正此問題，框架 repo 有 plugin.json 會略過此檢查 |

**場景 5 審查結論**：standup 首次執行流程合理，US-S02 的修正確保框架 repo 環境不會誤報。外部使用者需先完成 onboarding 才能有有效的 standup 結果。

---

## 發現問題清單

| # | 問題描述 | 嚴重度 | 所在位置 | 修正動作 |
|---|---------|-------|---------|---------|
| P1 | README「快速開始」未說明「需先安裝 Claude Code CLI」的前置條件 | 中 | README.md — 快速開始 > 安裝區段 | 新增前置條件說明（Prerequisites 區段） |
| P2 | README「快速開始」未說明「需先完成 Claude Code 帳號認證」的前置條件 | 中 | README.md — 快速開始 > 安裝區段 | 在 Plugin 安裝步驟前新增「確認 Claude Code 已認證」說明 |
| P3 | README 版本號顯示「v0.3.3」，但 plugin.json 版本為 0.3.8，版本號過時 | 低 | README.md — 標題下方版本標籤（第 15 行） | 將版本號從 v0.3.3 更新為 v0.3.8（已修正） |

**發現問題總數**：3 個（中 × 2，低 × 1）

---

## 審查總結

| 指標 | 數值 |
|------|------|
| 驗證場景總數 | 5 個（場景 1–5） |
| 步驟總數 | 18 個步驟 |
| 所有步驟結果 | PASS（文件審查模式） |
| 發現問題數 | 3 個（需修正 README） |
| 整體評估 | 安裝流程結構完整，主要缺漏為隱含前提未明確說明 |

**結論**：Shikigami 的 Plugin 安裝流程（`/plugin marketplace add` + `/plugin install`）設計合理、指令可執行，README 的核心安裝步驟無誤。主要缺漏是環境前提（Claude Code CLI 安裝與認證）未在 README 明確說明，對首次使用者可能造成困惑。建議依「發現問題清單」修正 README 後，安裝流程可達到完全自助的品質標準。
