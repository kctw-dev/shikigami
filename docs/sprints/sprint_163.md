# Sprint 163

**Sprint Goal**：框架品質自動化與 Backlog 治理強化 — Backlog 補充執行、Story 依賴靜態分析、重疊檢查機制、haiku 路由擴充、TCB Phase-Level Checkpoint、worktree 清理驗收

- **開始日期**：2026-03-25
- **容量**：8 pts（基準 velocity 6.67 pts，容量上限 8 pts）

## Sprint Backlog

| # | Story | Issue | Points | Status | Assignee |
|---|-------|-------|--------|--------|----------|
| 1 | retro: Backlog 補充 — sprint-candidate 低於閾值 10（目前 7） | #818 | 1 | DONE | Developer |
| 2 | feat: TDAD Story 依賴圖 — Sprint 平行執行衝突自動靜態分析 | #800 | 1 | DONE (#828) | Developer |
| 3 | retro: Story 重疊檢查機制 — Sprint Planning 時自動偵測候選 Story 與已完成功能的重疊 | #823 | 1 | DONE (#829) | Developer |
| 4 | retro: ADR-039 haiku 路由適用場景擴充 — 識別可降級低風險任務 | #817 | 1 | DONE (#830) | Developer |
| 5 | retro: Sprint 159 — worktree 自動清理整合驗證（#735） | #790 | 1 | DONE | Developer |
| 6 | feat: TCB 細粒度 Checkpoint — Story-Lifecycle Phase 級別中斷恢復（action 粒度防損失） | #781 | 3 | DONE (#831) | Developer |

**Total: 8 pts**

## PO Round 1：Backlog 排序與 Story 選取

### Velocity 計算
| Sprint | Velocity |
|--------|----------|
| Sprint 160 | 7 pts |
| Sprint 161 | 7 pts |
| Sprint 162 | 6 pts |
| **平均** | **6.67 pts** |
| **建議容量** | **6-8 pts（上限 8 pts）** |

### RETRO-AUTO-PROMOTE 掃描結果
`[BACKLOG-OK]` 無 `retro-action` + `priority: must` 未升格 Issues。

### 即時排序（MoSCoW Tier + RICE Score）
| Issue | MoSCoW Tier | RICE Score | Size | Points | 選入決策 |
|-------|------------|-----------|------|--------|---------|
| #818 | should (tier 2) | 0（無標記） | S | 1 | 選入（最高 MoSCoW） |
| #800 | could (tier 3) | 3.15 | S | 1 | 選入（RICE 最高） |
| #781 | could (tier 3) | 2.6 | M | 3 | 選入（RICE 第二） |
| #817 | could (tier 3) | 0（無標記） | S | 1 | 選入（retro-action 補充） |
| #823 | could (tier 3) | 0（無標記） | S | 1 | 選入（retro-action 品質） |
| #790 | could (tier 3) | 0（無標記，deferred） | S | 1 | 選入（多次延期，清除技術債） |

**[BACKLOG-OK]** sprint-candidate: 6 個，達到容量上限 8 pts，Backlog 全數納入。

### 非功能屬性審查
| Issue | NFR 欄位 | 狀態 |
|-------|---------|------|
| #818 | 未明確列出（任務本質為流程執行） | 通過（AC 已定義完成標準） |
| #800 | NFR1: < 10 秒完成 | 通過 |
| #823 | 未明確列出 | 通過（AC 定義輸出格式） |
| #817 | 未明確列出（haiku 比例 >= 25% 隱性 NFR） | 通過（AC3 含量化指標） |
| #790 | 未明確列出（驗證腳本執行正確性） | 通過（功能驗收明確） |
| #781 | NFR1: per-session per-story 無衝突；NFR2: graceful fallback | 通過 |

## 技術評估（Architect）

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | Story Type | Refinement | 說明 |
|-------|---------|---------|---------|-------------|------------|-----------|------|
| #818 | S | 無需新 ADR（ADR-043 已定義補充策略） | 不適用 | ADR-043 | PROCESS | READY | 執行 backlog-management skill，識別 3+ 新 sprint-candidate；修改 GitHub Issues |
| #800 | S | 無需新 ADR（延伸 Sprint 162 #780 靜態分析機制） | 不適用 | — | FEATURE | READY | 新建 scripts/analyze-dependencies.sh；新建 tests/test-dependency-map.sh |
| #823 | S | 無需新 ADR（延伸現有 Refinement 流程） | 不適用 | — | FEATURE | READY | 新建腳本或 Skill 段落，掃描修改範圍比對已完成 Story；嵌入 Refinement 報告 |
| #817 | S | ADR-039（已 Accepted） | 不適用 | ADR-039 | FEATURE | READY | 掃描 skills/ agents/ model-route 決策；修改 ADR-039 增加 haiku 適用規則 2+；執行 routing-stats.sh 驗證 |
| #790 | S | 無需新 ADR（#735 已完成設計） | 不適用 | — | VERIFICATION | READY | 驗證 scripts/cleanup-worktrees.sh 自動執行；若未整合則補整合 |
| #781 | M | ADR-040（已 Accepted） | JSON Schema（TCB Schema） | ADR-040 | FEATURE | READY | 修改 story-lifecycle-prompt.md 加入 phase checkpoint 寫入；修改 sprint-execution SKILL.md 加入 phase 恢復邏輯；新建 scripts/tcb-status.sh；新建 tests/test-tcb-checkpoint.sh |

**Hard Gate 檢查**：#781 依賴 ADR-040（已 Accepted），通過。所有 Stories 無需新增 ADR。

### 複雜度影響評估
- **新增 Skill/Script**：#800 (analyze-dependencies.sh), #823 (重疊分析腳本), #781 (tcb-status.sh)
- **複雜度基線**：SKILL=31, AGENT=8, HOOK=30, TOTAL_LINES=10008（全部在預算內）
- **預估增量**：+3 scripts, ~+400 lines → 維持在 TOTAL_LINES < 25000 預算內
- **結論**：PASS，無需刪減既有功能

### 平行分群
| Group | Stories | 說明 |
|-------|---------|------|
| Group A（可並行） | #818, #800, #823 | 修改不同腳本/Skills，無衝突 |
| Group B（可並行） | #817, #790 | 修改不同檔案，無衝突 |
| Group C（序列後執行） | #781 | 修改 story-lifecycle-prompt.md，需在 Group A/B 完成後確認無衝突 |

## QA 驗收確認

| Story | DoR 確認 | AC 覆蓋 | DoD 路徑 | QA 意見 |
|-------|---------|--------|---------|---------|
| #818 | READY | AC1(執行 backlog-management), AC2(sprint-candidate >= 10), AC3(新 Issues 有 RICE + MoSCoW) | 執行 skill → gh issue list 驗證數量 | APPROVE |
| #800 | READY | AC1(analyze-dependencies.sh 輸出依賴圖), AC2(偵測 file-level 衝突), AC3(tests/test-dependency-map.sh 通過) | 執行腳本，compare sprint_162 Stories，驗證 AC3 測試腳本通過 | APPROVE |
| #823 | READY | AC1(腳本接收 Story list 輸出重疊分析), AC2(覆蓋 file path 與 skill/agent 維度), AC3(輸出結構化文字可嵌入 Refinement 報告) | 輸入 sprint_162 Stories 清單，檢查輸出包含 file + skill 兩維度 | APPROVE |
| #817 | READY | AC1(掃描 model-route 決策列出候選降級場景), AC2(ADR-039 增加 2+ haiku 規則), AC3(routing-stats.sh 執行後 haiku >= 25%) | bash scripts/routing-stats.sh 驗證 haiku 比例；讀取 ADR-039 確認規則新增 | APPROVE — 注意 AC3 baseline 量測需配合 Sprint 162 起始資料 |
| #790 | READY | 驗確認 cleanup-worktrees.sh 在 Sprint Review 後自動執行 | 查看 scripts/cleanup-worktrees.sh 整合狀態，必要時整合並測試 | APPROVE |
| #781 | READY | AC1(story-lifecycle-prompt.md 加入 phase checkpoint 寫入), AC2(sprint-execution 加入 phase 恢復邏輯), AC3(tcb-status.sh 輸出 phase 完成格網), AC4(test-tcb-checkpoint.sh 模擬中斷恢復) | AC4 中斷恢復模擬是高風險測試場景，需確認 test 可在 CI 環境執行 | APPROVE — AC4 須在 sandbox 環境執行，不影響真實 Sprint |

**D3 觸發檢查**：Architect 與 QA 無分歧，跳過 D3。

## Sprint Goal 聲明

**Sprint 163 Sprint Goal**：建立框架品質自動化治理基礎 — 執行 Backlog 補充使 sprint-candidate 達標、引入 Story 依賴圖與重疊偵測強化 Refinement 品質、擴充 haiku 路由降低 Token 成本、驗收 worktree 清理自動化、實作 TCB Phase-Level Checkpoint 提升 Sprint 容錯韌性。

## 里程碑對齊

- **ROADMAP 里程碑**：M5 穩定化（持續推進）
- **版本目標**：v0.106.0（Sprint 163 完成後 minor bump）
