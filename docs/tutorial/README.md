# Tutorial 目錄

**最後更新**：2026-03-02（US-16 Sprint 15）

本目錄包含 Shikigami 的外部使用者導向文件，協助首次使用者從安裝到第一個 Sprint 完整上手。

---

## 文件清單

| 文件 | 用途 | 適合時機 |
|------|------|---------|
| [GETTING_STARTED.md](./GETTING_STARTED.md) | 入門教學：從安裝到第一個 Sprint 的端對端步驟指引，含指令範例與預期輸出摘要 | 首次安裝、第一次走完整 Sprint 循環 |
| [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) | 常見問題排查指南：6 個常見失敗情境，含症狀描述、根因說明與解決步驟 | 遇到問題、安裝卡關、功能異常 |

---

## 快速導覽

**剛安裝完 Shikigami？** → 從 [GETTING_STARTED.md](./GETTING_STARTED.md) 開始

**遇到問題？** → 查看 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

---

## 模型選用建議

Shikigami 框架會在派遣 subagent 時**自動指定適當模型**，使用者無需手動切換：

| 環節 | 自動選用模型 | 理由 |
|------|------------|------|
| **Sprint Planning** | Opus（自動） | Planning subagent（PO / Architect / QA）派遣時自動指定 `model: "opus"`，用於多步策略推理 |
| **Story Execution（開發）** | Sonnet（自動） | Story-Lifecycle subagent 派遣時自動指定 `model: "sonnet"`，兼顧速度與成本 |
| **Sprint Review** | Sonnet（自動） | Review subagent 使用 Sonnet，常規指標計算與通過標準核對已足夠 |

> 框架透過 Agent tool 的 `model` 參數自動分層，使用者不需要執行 `/model` 切換。詳細策略說明請參閱 [模型分層策略文件](../km/MODEL_TIERING_STRATEGY.md)。

---

## 相關文件

- [README.md（專案入口）](../../README.md) — 完整功能說明、7 個角色介紹、22 個 Skills
- [安裝驗證報告](../km/INSTALL_VERIFICATION.md) — 安裝流程系統性驗證記錄（US-15）
- [Project Board](../PROJECT_BOARD.md) — Sprint 進度看板與工件導覽
