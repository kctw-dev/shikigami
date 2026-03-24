---
name: health-check
description: "Use when checking Shikigami framework health — file integrity, CI status, ADR consistency, version sync, or retro action staleness diagnostics"
---

# Health Check — 框架自我診斷

## 1. 概述

Health Check 是框架的自我診斷工具。一鍵掃描 Shikigami 的核心文件與配置狀態，產出結構化健康報告，讓使用者立即知道框架是否處於健康狀態。

**觸發方式**：使用者表達「檢查框架狀態」、「系統健康嗎」、「有沒有問題」等語意時，由 Scrum Master 路由至此 Skill。

---

## 2. 診斷流程

依序執行以下 6 項檢查，每項獨立評估，最終彙整為 Overall Status。詳細規則見 [`references/diagnostic-rules.md`](references/diagnostic-rules.md)。

| 檢查項目 | 判定結果 |
|----------|---------|
| 1. 必要文件完整性 | PASS / FAIL |
| 2. 孤兒 Story 偵測 | PASS / WARN |
| 3. ADR 一致性 | PASS / FAIL |
| 4. CI 最新狀態 | PASS / FAIL / WARN |
| 5. Retro Action Items 逾期偵測 | PASS / OVERDUE |
| 6. 知識新鮮度檢查 | PASS / WARN / FAIL |
| 7. Worktree 殘留偵測（#500） | PASS / WARN |

---

## 3. 報告格式

執行完 6 項檢查後，產出以下格式的報告：

```
## 框架健康報告

**Overall Status**: {HEALTHY / WARNING / CRITICAL}
**檢查時間**: {YYYY-MM-DD HH:MM}

### 1. 必要文件完整性 — {PASS / FAIL}
### 2. 孤兒 Story 偵測 — {PASS / WARN}
### 3. ADR 一致性 — {PASS / FAIL}
### 4. CI 最新狀態 — {PASS / FAIL / WARN}
### 5. Retro Action Items — {PASS / OVERDUE}
### 6. 知識新鮮度 — {PASS / WARN / FAIL}
### 7. Worktree 殘留偵測 — {PASS / WARN}
```

### Overall Status 判定規則

| 條件 | Overall Status |
|------|----------------|
| 任一項 FAIL | **CRITICAL** |
| 有 WARN 或 OVERDUE 但無 FAIL | **WARNING** |
| 全部 PASS | **HEALTHY** |

---

## 4. 執行方式

此 Skill 採用 **Subagent 委派模式**。主 session（Scrum Master）不直接呼叫 Read、Glob、Grep 工具，所有檔案讀取與診斷邏輯均由 Health Check Subagent 負責執行。

### 4.1 正常執行流程

1. 主 session 派遣一個 **Health Check Subagent**，並提供以下指令：
   - 依序執行 [`references/diagnostic-rules.md`](references/diagnostic-rules.md) 定義的 7 項診斷檢查（含第 7 項：Worktree 殘留偵測）
   - 使用 Read、Glob、Grep 工具讀取所有必要文件；執行 `gh run list` 取得 CI 狀態
   - 依照 §3 定義的格式產出完整報告字串
2. Subagent 完成後，將完整報告字串回傳給主 session
3. 主 session 直接輸出 Subagent 回傳的報告，不再對內容做任何修改
4. 若 Overall Status 為 CRITICAL，建議使用者優先修復後再繼續開發

### 4.2 Subagent 失敗處理（零讀取原則）

若 Subagent 執行失敗，主 session **不得**嘗試降級改為直接讀取檔案。應立即輸出：

```
## 框架健康報告
**Overall Status**: UNKNOWN
health-check subagent 執行失敗，診斷結果不可用，請重試或手動執行。
```

主 session 在任何情況下均不呼叫 Read、Glob、Grep 工具，以維持零讀取架構原則。

---

## 5. 與其他 Skill 的關係

| 診斷結果 | 建議觸發 |
|----------|----------|
| CLAUDE.md 缺失 | 手動建立或使用 templates/ |
| PROJECT_BOARD 缺失 | `shikigami:sprint-planning` |
| ADR 不一致 | `shikigami:architecture-decision` |
| Retro Action 逾期 | `shikigami:escalation`（若連續 2 Sprint 未關閉） |

---

## 6. 孤兒文件清理規範

孤兒文件偵測定義、豁免清單、判定週期、輸出格式與處置流程，見 [`references/orphan-cleanup.md`](references/orphan-cleanup.md)。

<HARD-GATE>
Health Check Subagent 失敗時，主 session 禁止降級為直接讀取模式。
</HARD-GATE>
