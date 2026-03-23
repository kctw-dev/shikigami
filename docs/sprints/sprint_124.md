# Sprint 124 — Team Debate 核心機制 + CI Regression 修復 + Retro Actions 落地

**Sprint Goal**：交付同職能 Team Debate 雙 Agent 機制（ADR-031）+ 修復 #442 CI Regression + 落地 Sprint 123 Retro Actions
**期間**：2026-03-23 ~ 2026-03-30
**Velocity 目標**：11 pts（Sprint 121: 10, Sprint 122: 5, Sprint 123: 9，三 Sprint 平均 8 pts，本次略高屬合理 stretch）

## Sprint Backlog

| # | Story | Size | Points | MoSCoW | 狀態 | 執行順序 |
|---|-------|------|--------|--------|------|----------|
| #464 | [SRE] #442 Regression: sudo 密碼問題導致 unzip 修復無效 | S | 1 | Must | 待辦 | 1 |
| #383 | feat: 同職能 Team Debate — 雙 Agent 交替批判機制（方案 C） | M | 3 | Must | 待辦 | 2 |
| #456 | feat: ADR 自動納入 Sprint — Architect Refinement 自動補建 ADR Story | S | 1 | Should | 待辦 | 2 |
| #461 | fix: PR Description Quality Gate 強制 Summary + AC Checklist | S | 1 | Should | 待辦 | 2 |
| #460 | feat: Cruise SKILL.md 模組拆分 — 降低序列瓶頸提升並行效率 | M | 3 | Should | 待辦 | 2 |
| #463 | ci-health-check.sh 整合至 Cruise SRE 啟動流程 | S | 2 | Could | 待辦 | 3 |

## PO 決策紀錄

### 選入理由

**#464（Must/P0）**：#442 修復因 sudo 密碼問題回歸，CI 基礎設施不穩定影響全團隊。SRE Cycle 3 確認 100% 重現。新開 Issue 追蹤，1pt 快速修復。

**#383（Must/P0）**：使用者高優先需求。ADR-031 已 Accepted（解除 Sprint 123 NOT_READY 阻擋因素），Product Brief 存在，方案 C 明確。Sprint 124 的旗艦 Story。

**#456（Should/P1）**：#456 feedback 指出 ADR 應作為 RESEARCH Story 自動排入 Sprint。修改 architect-prompt.md + sprint-planning SKILL.md，範圍明確，1pt。

**#461（Should/P1）**：Sprint 123 Retro Action #2。PR 描述品質門檻，防止單行 PR，1pt。

**#460（Should/P1）**：Sprint 123 Retro Action #1。Cruise SKILL.md 過長是連續 3 Sprint 的問題（#462 也指出），拆分為 Loop/Once/SRE 子模組降低衝突率，3pt。

**#463（Could）**：Sprint 123 Retro Action #4。ci-health-check.sh 整合至 Cruise SRE 啟動流程，2pt。若時間不足優先砍除。

### 排除的候選

- **#462**（框架複雜度預算，M=3pt）：與 #460 概念重疊（都處理複雜度問題），本 Sprint 先做拆分（#460），下 Sprint 再做預算機制
- **#452**（INFRA 測試框架，L）：Size L 不適合本 Sprint 容量
- **#453**（複雜度指標，M）：同 #462，先做 #460 拆分

### Architect 評估

| Story | READY | 依賴 | 技術風險 | 備註 |
|-------|-------|------|----------|------|
| #464 | READY | 無 | Low | CI workflow 單步修改，改用 non-sudo 安裝方式 |
| #383 | READY | ADR-031 (Accepted) | Medium | 雙 subagent 交替機制，需修改 sprint-execution SKILL.md + story-lifecycle，方案 C 架構明確 |
| #456 | READY | 無 | Low | 修改 architect-prompt.md + sprint-planning SKILL.md |
| #461 | READY | 無 | Low | 修改 git-workflow SKILL.md 或 PR template |
| #460 | READY | 無 | Medium | Cruise SKILL.md 拆分需保持引用不破壞，AC 明確（<100行/模組） |
| #463 | READY | #450 (已交付) | Low | 在 Cruise SRE 流程加入 health-check 步驟 |

### #383 Refinement（Q1-Q5）

- **Q1 範圍**：實作 ADR-031 方案 C — 雙 Agent 交替批判。Challenger Agent 在 Author Agent 完成 self-review 後介入，獨立審查並提出反對意見。
- **Q2 非範圍**：不含 multi-round debate（超過 1 輪交替）、不含 Debate 品質評分、不含自動選擇 debate 或 non-debate 的智慧路由。
- **Q3 成功標準**：Story 經過 Debate 後的 Review PASS 率 >= 現狀；Challenger 至少提出 1 項有意義的改善建議。
- **Q4 技術方案**：sprint-execution 派遣 Story 時，Author subagent 完成後觸發 Challenger subagent（同職能不同 context），Challenger 審查 diff 並輸出 findings，Author 回應修正。
- **Q5 測試策略**：模擬 Story lifecycle 測試雙 agent 交替流程，驗證 Challenger 輸出格式正確且 Author 能回應。

### QA AC 確認

所有 6 Stories 的 Acceptance Criteria 已確認可測試、可驗證。#383 補充 AC：
- AC1: Challenger Agent 在 Author self-review 後觸發
- AC2: Challenger 輸出結構化 findings（file, line, severity, suggestion）
- AC3: Author 對每項 finding 逐一回應（accept/reject + 理由）
- AC4: Debate 紀錄寫入 PR description 或 comment
- AC5: 不增加超過 30% 的 Story 執行時間

## 執行順序（平行分群）

### Phase 1（Bug 修復，立即開始）
- **#464** — CI Regression 修復（獨立，不與任何 Story 衝突）

### Phase 2（功能交付，Phase 1 完成後可平行）
- **Group A**：#383（sprint-execution + story-lifecycle 修改）
- **Group B**：#460（skills/cruise/ 拆分）+ #463（skills/cruise/ SRE 整合）— 注意 #460 先完成再做 #463
- **Group C**：#456（agents/architect + skills/sprint-planning）+ #461（skills/git-workflow 或 PR template）

### Phase 3（Buffer）
- #463 若 Phase 2 時間不足，移至 Phase 3

## 檔案衝突矩陣

| Story | 修改檔案 | 衝突風險 |
|-------|---------|----------|
| #464 | .github/workflows/ | 獨立 |
| #383 | skills/sprint-execution/, agents/ | Group A 獨占 |
| #460 | skills/cruise/SKILL.md → 拆分 | Group B（#463 依賴） |
| #463 | skills/cruise/ (SRE 子模組) | Group B（等 #460） |
| #456 | agents/architect.md, skills/sprint-planning/ | Group C 獨立 |
| #461 | skills/git-workflow/ 或 templates/ | Group C 獨立 |
