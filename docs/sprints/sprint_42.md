# Sprint 42

**狀態**：完成
**期間**：2026-03-04 ~ 2026-03-10
**Sprint Goal**：完善 Onboarding 自動化鏈路（GitHub Action 串接）並強化 Sprint 執行品質（Done 定義 checkbox 強化），同時在本 Sprint Review 中首次驗證 US-86 一致性審查機制的完整覆蓋率。
**總計**：2 Stories / 3 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | Phase | 狀態 |
|----------|---------|------|------|--------|-------|------|
| US-88 | #83 | Onboarding 自動串接 GitHub Action — runner 偵測 + backlog-intake 驗證 | M | 2 | Phase 1（平行） | 完成 |
| US-89 | #84 | story-lifecycle-prompt.md Done 定義 checkbox 自動勾選提醒強化 | S | 1 | Phase 1（平行） | 完成 |

**Sprint 容量**：3 Points

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1（全平行） | US-88、US-89 | 修改檔案不重疊：US-88 修改 skills/onboarding/SKILL.md；US-89 修改 skills/sprint-execution/story-lifecycle-prompt.md |

**平行可行性判定**：APPROVED — 兩個 Story 的檔案修改路徑無交集，可同時執行。

---

## Story 詳細 AC

---

### US-88：Onboarding 自動串接 GitHub Action — runner 偵測 + backlog-intake 驗證

**來源**：Onboarding 自動化 — Issue #83
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：Yes（僅修改 skills/onboarding/SKILL.md）
**ADR 參考**：ADR-011（GitHub Actions 整合架構）

**User Story**

As a new Shikigami user, I want the onboarding process to automatically detect, register, and verify the GitHub Actions self-hosted runner and backlog-intake workflow, so that the full backlog automation pipeline is ready to use immediately after onboarding without any manual configuration steps.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | onboarding SKILL.md 新增 Phase 2.6（GitHub Action 串接） | SKILL.md 中存在明確的 runner 偵測 + 條件性提示區段，流程可讀且步驟有序 |
| AC2 | [靜態] | Runner 偵測邏輯明確 | 使用 `gh api repos/{owner}/{repo}/actions/runners` 偵測；若無 runner，輸出清晰的手動安裝指引，不自動執行 root-level 安裝（安全邊界） |
| AC3 | [靜態] | OAuth 驗證狀態確認 | 執行 `claude auth status`；若未認證，輸出明確指引，不儲存憑證 |
| AC4 | [靜態] | Workflow 存在性確認 | 確認 `.github/workflows/backlog-intake.yml` 存在；若不存在，說明需先執行 US-87 相關步驟 |
| AC5 | [靜態] | 冪等性保護 | 若 runner 已存在且 OAuth 已認證，略過提示並輸出「[略過] GitHub Action 串接已就緒」，不重複操作 |
| AC6 | [靜態] | Onboarding 完成摘要更新 | §2.5「下一步清單」新增 backlog-intake 啟用狀態一行摘要 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 5 | 影響所有新使用者（onboarding 必經路徑） |
| Impact | 3 | 從 6 個手動步驟降至零手動配置 |
| Confidence | 0.7 | gh api 與 claude auth status 均有前例 |
| Effort | 2 | onboarding SKILL.md 新增一個 Phase |
| **RICE Score** | **5.25** | R×I×C/E |

**Done 定義**

- [x] onboarding SKILL.md 新增 Phase 2.6（GitHub Action 串接）
- [x] Runner 偵測邏輯使用 `gh api repos/{owner}/{repo}/actions/runners`
- [x] OAuth 驗證狀態確認使用 `claude auth status`
- [x] Workflow 存在性確認（`.github/workflows/backlog-intake.yml`）
- [x] 冪等性保護（已就緒時略過）
- [x] Onboarding 完成摘要更新
- [x] Issue #83 關閉

---

### US-89：story-lifecycle-prompt.md Done 定義 checkbox 自動勾選提醒強化

**來源**：Sprint 41 Retro Problem 1 — Issue #84
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes（僅修改 skills/sprint-execution/story-lifecycle-prompt.md）
**ADR 參考**：無

**User Story**

As a Developer subagent executing Sprint Stories, I want the Done Definition checkbox auto-completion to be explicitly prompted in story-lifecycle-prompt.md, so that Done checkboxes are consistently ticked as part of the Story completion flow without requiring manual intervention at Sprint Review.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | story-lifecycle-prompt.md 新增「Done 定義 checkbox 更新」步驟 | 於 Story 完成時明確指示 Developer subagent 更新 `sprint_N.md` Done 定義中的 `- [ ]` 為 `- [x]` |
| AC2 | [靜態] | 觸發時機明確定義 | Story 通過雙階段審查後、狀態更新為完成前 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 4 | 影響每個 Sprint 所有 Developer subagent |
| Impact | 2 | 防止 Sprint Review 補正 overhead |
| Confidence | 1.0 | 純文字提示新增 |
| Effort | 1 | 新增 1-2 行提示 |
| **RICE Score** | **8.0** | R×I×C/E |

**Done 定義**

- [x] story-lifecycle-prompt.md 新增「Done 定義 checkbox 更新」步驟
- [x] 觸發時機明確定義（雙階段審查後、狀態更新前）
- [x] Issue #84 關閉

---

## ADR 觸發清單

| Story | ADR | 觸發原因 | 動作 |
|-------|-----|----------|------|
| US-88 | ADR-011 | onboarding 串接 GitHub Actions runner 偵測，在 ADR-011 框架內 | 確認 ADR-011 架構對齊，無需新 ADR |
| US-89 | — | 無 ADR 觸發 | — |

---

## Sprint Planning 簽核記錄

| 角色 | 確認項目 | 狀態 |
|------|----------|------|
| Product Owner | Sprint Goal 對齊 Onboarding 自動化 + Sprint 執行品質強化，US-88 + US-89 優先級確認 | 已確認 |
| Architect | US-88 M-size 技術可行性（onboarding SKILL.md 新增 Phase 2.6，ADR-011 框架內）；US-89 S-size 技術可行性 | 已確認 |
| QA | US-88 AC1-AC6 驗收標準（6/6 PASS）；US-89 AC1-AC2 驗收標準（2/2 PASS） | 已確認 |
| Developer | Story 清晰度確認，Phase 1 全平行執行可行 | 待確認 |

**Sprint Planning 決策記錄**

- Sprint 42 選入 2 Stories（US-88 + US-89），共 3 Points
- 平行分群：Phase 1 全平行（檔案範圍無重疊）
- US-88 doc-only 判定：Yes（僅修改 skills/onboarding/SKILL.md，ADR-011 框架內）
- US-89 doc-only 判定：Yes（僅修改 skills/sprint-execution/story-lifecycle-prompt.md）
- Milestone "Sprint 42" 建立於 GitHub，Issue #83、#84 已設定 in-sprint 標籤
- Sprint 41 Retro 無新增 Action Items，無需列入
