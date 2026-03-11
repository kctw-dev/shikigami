# Sprint 78

**Sprint Goal**：全力落地 ADR-016 — 建立 UI/UX Designer 角色定義、整合進框架流程、清除已棄用設計 Skill

**期間**：2026-03-11 ~ 2026-03-18
**狀態**：進行中
**ADR 依賴**：ADR-016（Accepted）

---

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 | 備註 |
|-------|-------|------|--------|------|------|
| US-206：UI/UX Designer 角色建立 — Agent 定義 + Skill 定義 | #207 | M | 2 | 完成 | doc-only, FEATURE |
| US-207：框架整合更新 — Scrum Master 角色清單 + Sprint Execution DESIGN 路徑 | #207 | S | 1 | 完成 | FEATURE |
| US-208：棄用 Skill 清除 — 刪除 ux-agent / ui-agent | #207 | S | 1 | 完成 | INFRA |

**Sprint 容量**：4 points

---

## Story 定義

### US-206：UI/UX Designer 角色建立（M, 2pts, doc-only, FEATURE）

**Contract Owner**：Architect

**AC1**：`agents/uiux-designer.md` 已建立，遵循既有 agent 定義格式（YAML frontmatter + 決策權 + 方法論 + 跨角色協作），涵蓋 ADR-016 五大決策域

**AC2**：`skills/uiux-designer/SKILL.md` 已建立，包含：
- 概述（角色定位、ADR-016 背景）
- Design Foundation 三方協作流程（PO + Architect + Designer）
- DESIGN Story 執行流程（Design Token → Component → Prototype → Contract 凍結）
- Review 責任矩陣（Vision Critic 自審 + Architect 技術審查）
- Refinement 職責（設計可行性評估、視覺規格確認）
- DoR/DoD（與 sprint-planning §10 對齊）

**AC3**：Vision Critic 定位為 Designer self-review 工具（非 QA），與 `skills/vision-critic/SKILL.md` 職責劃分明確

**AC4**：Contract 定義：Figma Prototype 凍結流程 = Vision Critic PASS + QA Contract Testability Review

**AC5**：跨角色協作介面已定義（與 PO、Architect、QA、Developer 的互動點）

### US-207：框架整合更新（S, 1pt, FEATURE）

**AC1**：`skills/scrum-master/SKILL.md` §3 角色清單從 7 → 8 個，新增 UI/UX Designer 行，RACI 矩陣新增 Designer 欄

**AC2**：`skills/sprint-execution/SKILL.md` §5 新增 DESIGN type 執行路徑描述（派遣 Designer subagent）

**AC3**：`skills/sprint-execution/story-lifecycle-prompt.md` 新增 DESIGN type 分支（TDD 豁免、Review 策略）

### US-208：棄用 Skill 清除（S, 1pt, INFRA）

**AC1**：`skills/ux-agent/` 目錄已完全刪除

**AC2**：`skills/ui-agent/` 目錄已完全刪除

**AC3**：框架內無任何檔案仍引用 `ux-agent` 或 `ui-agent`（grep 驗證 0 結果，排除 ADR/歷史文件中的參考）

---

## 平行分群建議

### Phase 1（可平行執行）
| Story | Size | 說明 |
|-------|------|------|
| US-206 | M | 建立新檔案，無衝突 |
| US-208 | S | 刪除舊檔案，無衝突 |

### Phase 2（需序列執行）
| Story | Size | 衝突原因 |
|-------|------|---------|
| US-207 | S | 依賴 US-206 完成後的角色定義，需修改 scrum-master/sprint-execution 共用檔案 |

---

## 權重調整記錄

快思模式，跳過權重調整
