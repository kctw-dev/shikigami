# Team Debate — Critic Round 1 批判結果

**Story**：#493 — Retro-Action 連續未完成自動觸發 Grooming 機制
**Branch**：sprint-130/493-retro-grooming
**Critic Agent**：Developer Critic（Agent B）
**Date**：2026-03-24

---

## Verdict: FAIL

---

## 批判維度評估

### 1. 正確性（AC 覆蓋度）

| AC | 說明 | 評估 |
|----|------|------|
| AC1 偵測規則 | retro-grooming.md §1 定義連續 2 Sprint 閾值、情境表格、偵測指令 | PASS |
| AC2 Sprint Planning 整合 | SKILL.md checklist 第 51 行加入偵測步驟並引用 retro-grooming.md | PASS |
| AC3 #452 觸發案例 | retro-grooming.md §4 有 #452 的完整說明 | PASS |

所有 3 項 AC 均有對應實作，覆蓋完整。

### 2. 設計（SOLID / 耦合度 / 命名）

**問題 1（MED）**：`skills/sprint-review/references/retro-grooming.md` 第 41-42 行：

§1.3 偵測方式提到「讀取 Issue 的 milestone 歷史（透過 GitHub API）」，但 `gh issue list` 不直接提供 milestone 歷史（只能看當前 milestone），也未給出具體 API endpoint（如 `gh api repos/{owner}/{repo}/issues/{n}/timeline`）。Agent 依此指引執行時可能無法實際完成偵測，陷入無法操作的狀態。

**問題 2（MED）**：`skills/sprint-review/SKILL.md` §4（第 129 行）原文「連續兩 Sprint open → 升級 Stakeholder」，與 §4.1（第 136-138 行）新增「連續 2 個 Sprint → 觸發 [RETRO-GROOMING-TRIGGER]」並存，兩者觸發條件相同但動作不同，關係（並且/取代）未明確說明，可能導致 Agent 執行不一致。

### 3. 測試覆蓋

- 12 項 TC 覆蓋所有 AC 關鍵詞存在性，符合此類 Skill 文件測試慣例
- TC-04（第 80-85 行）測試「包含 '2'」過於寬鬆，數字 2 可能出現於任何位置（LOW）
- 缺少測試覆蓋「升級 Stakeholder 與 RETRO-GROOMING-TRIGGER 並存關係」但屬文件層級測試局限，可接受

### 4. 安全性

- 無外部輸入處理，無硬編碼金鑰。安全性無問題。

---

## Issues Found

### Issue 1
- **SEVERITY: MED**
- **位置**：`skills/sprint-review/references/retro-grooming.md` 第 41-44 行
- **描述**：偵測方式依賴「milestone 歷史 API」但未提供具體指引，實際執行時 Agent 可能無法取得連續排入的歷史資料，導致偵測機制形同虛設
- **建議**：補充具體 GitHub API 路徑，或明確說明以 `deferred` label 回退方案為主要判定方式

### Issue 2
- **SEVERITY: MED**
- **位置**：`skills/sprint-review/SKILL.md` §4（第 129 行）與 §4.1（第 136-138 行）
- **描述**：「升級 Stakeholder」與「觸發 [RETRO-GROOMING-TRIGGER]」觸發條件相同但動作並存，關係未明確，可能導致 Agent 雙重執行或執行不一致
- **建議**：在 §4.1 明確說明兩者並存關係（如：同時觸發，GROOMING 處理技術面，Stakeholder 升級處理管理面）

### Issue 3
- **SEVERITY: LOW**
- **位置**：`tests/test-493-retro-grooming.sh` 第 80-85 行（TC-04）
- **描述**：測試「包含 '2'」過於寬鬆，無法精確驗證閾值語義
- **建議**：改為測試「連續 2 個」或「閾值：連續 2」等更具語義的字串

---

## Summary

Worker 覆蓋了全部 3 項 AC，基本框架設計合理。

2 個 MED 問題需修復：
1. milestone 歷史偵測方式缺乏可行性指引
2. 新舊兩個觸發動作的並存關係未明確

1 個 LOW 問題可選修。
