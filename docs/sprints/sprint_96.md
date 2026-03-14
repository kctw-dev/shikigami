# Sprint 96

**Sprint Goal**：強化框架品質護欄 — 版號驗證自動化、Skill 角色 prompt 拆分、UI/UX 設計前置 Gate，全面消除已知合規盲點
**日期**：2026-03-14
**容量**：9 points
**狀態**：進行中

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-263：validate-version.sh 增強：README.md badge 版號檢查 | #259 | S | 1 | 待辦 |
| US-264：版本驗證 Hook：commit 前自動檢查版號一致性 | #260 | M | 2 | 待辦 |
| US-265：architecture-decision Skill 拆分：角色 prompt 檔案分離 | #261 | M | 2 | 待辦 |
| US-266：deployment-readiness Skill 拆分：SRE / Security 角色 prompt 分離 | #262 | M | 2 | 待辦 |
| US-267：UI/UX Designer 前置檢查：Design System / Design Token / Guideline 文件存在性驗證 | #258 | S | 1 | 待辦 |
| US-268：演示模式 / 火力展示（Spike）：技術可行性報告 | #255 | S | 1 | 待辦 |

## Acceptance Criteria 摘要

### US-263 (#259)

- **AC1**：validate-version.sh 新增 README.md badge 版號檢查
- **AC2**：badge 版號不一致時 FAIL
- **AC3**：現有 AC1/AC1b/AC2 不受影響

### US-264 (#260)

- **AC1**：`.githooks/pre-commit` 存在且可執行
- **AC2**：Git pre-commit hook 跑 validate-version.sh，exit code 1 時阻止 commit
- **AC3**：Claude Code PreToolUse hook，matcher regex `git\s+commit`
- **AC4**：兩層 hook 獨立性驗證：(a) 僅 Git hook 阻止 (b) 僅 Claude Code hook 警告 (c) 同時啟用不衝突
- **AC5**：前置依賴 US-263 完成

### US-265 (#261)

- **AC1**：SKILL.md 僅保留流程編排
- **AC2**：4 個角色 prompt 檔案存在且自包含
- **AC3**：流程步驟與 Hard Gates 不變
- **AC4**：語意等價（拆分前後內容覆蓋一致）

### US-266 (#262)

- **AC1**：SKILL.md 僅保留流程編排
- **AC2**：sre-prompt.md 與 security-prompt.md 存在且自包含
- **AC3**：平行執行語意保留
- **AC4**：語意等價

### US-267 (#258)

- **AC1**：SKILL.md 新增 Design Foundation 前置檢查段落
- **AC2**：檢查目標：`docs/design/design-system.md`、`docs/design/design-tokens.json`、`docs/design/ui-guideline.md`
- **AC3**：DESIGN type Story → Hard Gate 阻塞
- **AC4**：非 DESIGN type Story → Soft Gate 警告
- **AC5**：首次使用者體驗：不存在時包含建立指引

### US-268 (#255)

- **AC1**：產出技術可行性報告（Spike Report）
- **AC2**：評估三個方向：terminal dashboard / 錄影回放 / live log streaming
- **AC3**：報告含建議方案、估算工時、技術風險

## 技術評估摘要

- US-263：S/1pt，FEATURE type。修改 scripts/validate-version.sh，新增 README.md badge 版號比對邏輯。
- US-264：M/2pt，INFRA type。新增 .githooks/pre-commit + Claude Code PreToolUse hook 設定。前置依賴 US-263。
- US-265：M/2pt，FEATURE type。拆分 skills/architecture-decision/SKILL.md 為流程編排 + 4 個角色 prompt 檔案。
- US-266：M/2pt，FEATURE type。拆分 skills/deployment-readiness/SKILL.md，分離 sre-prompt.md 與 security-prompt.md。
- US-267：S/1pt，FEATURE type。修改 skills/shoot/SKILL.md（或對應 Skill），新增 Design Foundation 前置檢查段落。
- US-268：S/1pt，RESEARCH type。產出 Spike Report，無程式碼變更。

## Refinement 記錄

- US-263：S-size 豁免，無需 Refinement
- US-264：READY（前置依賴 US-263 同 Sprint 可達成）
- US-265：READY（完全獨立）
- US-266：READY（完全獨立）
- US-267：S-size 豁免，無需 Refinement
- US-268：S-size 豁免，無需 Refinement

## 平行分群

- **Phase 1**（可平行）：US-263, US-265, US-266, US-267, US-268
- **Phase 2**（等 US-263 完成後）：US-264
