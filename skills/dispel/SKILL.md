---
name: dispel
description: "Use when analyzing legacy or unfamiliar codebases — reverse-engineering architecture, tracing dependencies, and building mental models"
---

# 解咒 Dispel — Legacy 系統考古分析

## 1. 概述

Legacy 系統是前人施下的咒，你需要先解讀它才能動它。

解咒模式讓六個式神各自從角色視角分析**當前 repo**，產出「咒文解析」報告。報告是後續 `/sprint` 改動的基礎 — 先理解系統，再決定怎麼改。

**輸入**：當前 repo（使用者在目標 repo 中啟動 `/dispel`）
**輸出**：`docs/dispel/` 目錄，結構化多文件報告

---

## 2. 適用場景

- 接手一個不熟悉的 codebase
- 評估 Legacy 系統的改造可行性
- 進入新專案前的全面理解
- 技術債評估與重建規劃

**不適用**：活躍開發中的 bug 排查（→ 使用 `systematic-debugging`）

---

## 3. 輸出結構

```
docs/dispel/
├── summary.md          ← 執行摘要 + 整體評估（30 秒掃讀）
├── intent.md           ← PO：系統原始意圖、業務邏輯
├── architecture.md     ← Architect：模組結構、依賴、設計模式
├── codebase.md         ← Developer：代碼品質、技術債
├── quality.md          ← QA：測試覆蓋、品質缺口
├── security.md         ← Security：安全風險、漏洞
├── operations.md       ← SRE：部署、監控、維運
└── recommendations.md  ← 綜合重建建議 + 行動項目（銜接 /sprint）
```

---

## 4. 六角色分析框架

六個式神各自從角色視角分析，詳細分析維度與必要圖表見 [`references/analysis-framework.md`](references/analysis-framework.md)：

| 角色 | 分析面向 | 產出 |
|------|---------|------|
| PO | 業務意圖、功能邊界、需求考古 | `intent.md` |
| Architect | 模組結構、依賴關係、設計模式 | `architecture.md` |
| Developer | 代碼品質、技術債、關鍵路徑 | `codebase.md` |
| QA | 測試覆蓋、品質缺口 | `quality.md` |
| Security | 認證授權、輸入處理、敏感資料 | `security.md` |
| SRE | 部署方式、監控、環境管理 | `operations.md` |

---

## 5. 執行流程

```
使用者啟動 /dispel
  |
  v
Scrum Master：觸發 shikigami:dispel
  |
  v
建立 docs/dispel/ 目錄
  |
  v
派遣 6 個 subagent 並行分析（invoke shikigami:parallel-dispatch）
  ├── PO subagent → intent.md
  ├── Architect subagent → architecture.md
  ├── Developer subagent → codebase.md
  ├── QA subagent → quality.md
  ├── Security subagent → security.md
  └── SRE subagent → operations.md
  |
  v
彙整六份報告，產出：
  ├── summary.md（執行摘要 + 整體評估）
  └── recommendations.md（重建建議 + 行動項目）
  |
  v
提示使用者：「解咒完成。可用 /sprint 開始改動。」
```

**步驟說明**：
1. **建立輸出目錄**：建立 `docs/dispel/`，若已存在則詢問是否覆蓋。
2. **並行分析**：六個 subagent 各自從角色視角分析，遵循 [`references/analysis-framework.md`](references/analysis-framework.md) 中對應角色的分析框架。
3. **彙整摘要**：讀取六份報告，依 [`references/output-templates.md`](references/output-templates.md) 格式產出 `summary.md` 與 `recommendations.md`。
4. **銜接 Sprint**：`recommendations.md` 的行動項目格式與 GitHub Issues 的 User Story 格式對齊，便於透過 `/issue-management` Backlog Bridge 直接匯入。

---

## 6. 輸出格式

`summary.md` 與 `recommendations.md` 的詳細格式見 [`references/output-templates.md`](references/output-templates.md)。

---

## 7. 與其他 Skill 的關係

| 銜接 | 說明 |
|------|------|
| `/dispel` → `/sprint` | 解咒完成後，recommendations.md 的行動項目透過 `/issue-management` Backlog Bridge 匯入至 GitHub Issues，啟動 Sprint |
| dispel vs systematic-debugging | dispel = Legacy/不活躍 codebase 全面考古；systematic-debugging = 活躍開發中的特定 bug/測試失敗 |
| dispel → `/issue-management` | recommendations.md 的行動項目可直接由 PO 評分後，透過 `/issue-management` Backlog Bridge 排入 GitHub Issues Backlog |
