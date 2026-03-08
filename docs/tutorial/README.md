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

Shikigami 框架的不同 Sprint 環節對模型能力的需求不同，建議依環節選用適當模型：

| 環節 | 建議模型 | 理由 |
|------|---------|------|
| **Sprint Planning** | Opus（`claude-opus-4-6`） | Planning 需要多步策略推理（AC 分析、Story 估點、平行分群、依賴評估），高階模型在此類任務具備明顯優勢，且 Planning 決策品質直接影響整個 Sprint 執行效率 |
| **Story Execution（開發）** | Sonnet（`claude-sonnet-4-6`） | 代碼實作與文件撰寫的速度與準確性要求高，Sonnet 已達足夠水準，且速度比 Opus 快 3-5 倍 |
| **Sprint Review** | Sonnet（預設），Opus（選用） | 常規指標計算與通過標準核對用 Sonnet 即可；出現 Velocity 大幅偏差或連續 Problem 趨勢時，可升級至 Opus 進行深度回顧 |

### 切換指令

```bash
# 切換至 Opus（建議 Sprint Planning 前執行）
/model claude-opus-4-6

# 切換回 Sonnet（Planning 完成後或 Execution 開始前）
/model claude-sonnet-4-6
```

> 詳細策略說明請參閱 [模型分層策略文件](../km/MODEL_TIERING_STRATEGY.md)。

---

## 相關文件

- [README.md（專案入口）](../../README.md) — 完整功能說明、7 個角色介紹、22 個 Skills
- [安裝驗證報告](../km/INSTALL_VERIFICATION.md) — 安裝流程系統性驗證記錄（US-15）
- [Project Board](../PROJECT_BOARD.md) — Sprint 進度看板與工件導覽
