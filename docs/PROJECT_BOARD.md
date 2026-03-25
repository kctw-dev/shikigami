# Project Board

**最後更新**：2026-03-25（Sprint 144 Planning 完成 — 4 Stories / 6 pts）
**當前 Sprint**：Sprint 144（進行中）

工件導覽：[ROADMAP](prd/ROADMAP.md) → [Backlog](prd/PRODUCT_BACKLOG.md) → 本看板 | [Tutorial](tutorial/README.md)

---

## 短衝記錄

| 日期 | 來源 | 標題 | 結果 | commit |
|------|------|------|------|--------|
| 2026-03-24 | #638 | retro: tcb-write.sh smoke test — stdout 污染回歸防護 | PASS | d4e353d |

---

## Sprint 144（進行中）

> Sprint Goal：消除框架 validate-orphans.sh 長期 263 WARNING 噪音，補強驗證腳本覆蓋完整性，並完成 TDAD 設定關閉功能，提升框架可維護性與開發者體驗。
> **容量**：6 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| retro: 驗證 validate-skills.sh 覆蓋完整性 | #667 | S | 1 | DONE(#669) |
| feat: TDAD 依賴分析可透過設定關閉 | #653 | S | 1 | DONE(#670) |
| chore: ADR index 修復 263 WARNING | #655 | M | 3 | DONE(#671) |
| feat: validate-orphans.sh 豁免清單機制 | #658 | S | 1 | DONE(#672) |

---

## Sprint 143（完成）

> Sprint Goal：補強 Sprint Planning 自動化防線、解決框架 CI 遺留資產混亂，並完成 sprint-execution SKILL 長期技術債重構。
> **結果**：Goal 達成（4/4 Stories DONE）。Velocity 6 pts，完成率 100%。連續第 17 Sprint 100%（127-143）。
> **容量**：6 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| feat: Sprint Planning Pre-flight Backlog 健康度檢查 | #656 | S | 1 | DONE(#663) |
| retro: 評估 #657 是否與 #652 重複，決定關閉或縮小範疇 | #661 | S | 1 | DONE(#665) |
| chore: 清除 new-issue-intake.yml 殘留引用 | #662 | S | 1 | DONE(#664) |
| refactor: sprint-execution/SKILL.md 行數超限重構 | #654 | M | 3 | DONE(#666) |

---

## Sprint 142（完成）

> Sprint Goal：修復 New Issue Intake CI 持續失敗根因，並完成 Backlog 健康補充，確保後續 Sprint 容量充足。
> **結果**：Goal 達成（2/2 Stories DONE）。Velocity 5 pts，完成率 100%。連續第 16 Sprint 100%（127-142）。v0.95.1。
> **容量**：5 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| retro: 調查並修正 New Issue Intake CI workflow 連續失敗 | #650 | M | 2 | DONE(#652) |
| retro: Backlog 補充 — 掃描 open Issues 提升可執行 Story 存量 | #651 | M | 3 | DONE(#659) |

**外部依賴**：AC2b Admin secret setup (ANTHROPIC_API_KEY) — 等待 Admin 操作

---

## Sprint 141（完成）

> Sprint Goal：完成 Sprint 140 殘留改善項目 — watchdog 閾值精確對齊 AC 規格，並聚合 Sprint 98-140 Retrospective Log 確保知識庫完整性
> **結果**：Goal 達成（2/2 Stories DONE）。Velocity 2 pts，完成率 100%。連續第 15 Sprint 100%（127-141）。
> **容量**：2 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| retro: watchdog-monitor.sh 閾值與 #408 AC 規格對齊（10 分鐘） | #646 | S | 1 | DONE(#648) |
| retro log 補完 — Retrospective_Log.md Sprint 98-140 條目聚合 | #647 | S | 1 | DONE(#649) |

---

## Sprint 140（完成）

> Sprint Goal：落地 ADR-041/ADR-042 決策成果——實作 Crash Recovery 與 Session Watchdog 彈性架構，並根本解決持續發生的 CI Token 輪換問題。
> **結果**：Goal 達成（3/3 Stories DONE）。Velocity 5 pts，完成率 100%。連續第 14 Sprint 100%（127-140）。
> **容量**：5 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| retro: CI Token 輪換自動化 — CLAUDE_CODE_OAUTH_TOKEN 持續過期根本解決 | #637 | S | 1 | DONE(#640) |
| feat: Temporal-style Crash Recovery（ADR-041 Accepted） | #405 | M | 2 | DONE(#641) |
| feat: Session Watchdog — 存活監控 + 自動重啟（ADR-042 Accepted） | #408 | M | 2 | DONE(#642) |

---

## Sprint 139（完成）

> Sprint Goal：落地 TCB 斷點管理實作（ADR-040 決策成果），同步推進 Crash Recovery 與 Session Watchdog 的 ADR 先行工作，並完成 A2A 協議相容性研究評估。
> **結果**：Goal 達成（4/4 Stories DONE）。Velocity 5 pts，完成率 100%。連續第 13 Sprint 100%（127-139）。
> **容量**：5 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| feat: TCB 斷點管理 — Agent Action 級 Checkpoint | #404 | M | 2 | DONE(#634) |
| RESEARCH: ADR-041 — Crash Recovery 架構決策（unblocks #405）| #631 | S | 1 | DONE(#633) |
| RESEARCH: ADR-042 — Session Watchdog 架構決策（unblocks #408）| #632 | S | 1 | DONE(#635) |
| research: A2A 協議相容性評估 | #399 | S | 1 | DONE(#636) |

**Sprint 容量**：5 points
**執行順序**：Phase 1 平行（#404 | #631 | #399）→ Phase 2 序列（#632，依賴 #631）

---

## Sprint 138（完成）

> Sprint Goal：落地 ADR-038/ADR-039 決策成果——實作 Kill Switch 緊急停止機制與 Token Cost Routing 風險評分分級，同步修復持續發生的 New Issue Intake CI 認證失敗根因（第五次，升級為必修）。
> **結果**：Goal 達成（4/4 Stories DONE）。Velocity 6 pts，完成率 100%。連續第 12 Sprint 100%（127-138）。
> **容量**：6 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| [SRE] New Issue Intake CI 持続失敗 — 調查根本原因 | #622 | S | 1 | 已完成 |
| incident: ANTHROPIC_API_KEY 缺失（第五次）— CI 認證修復 | #618 | S | 1 | 已完成 |
| feat: Kill Switch — High 自治模式緊急停止 | #398 | M | 2 | 已完成 |
| feat: Token Cost Routing — Risk-based Model 分級 | #402 | M | 2 | 已完成 |

**Sprint 容量**：6 points

---

## Sprint 137（完成）

> Sprint Goal：落地 Sprint 136 Retro Action Items（GAD Schema 範例 + CI 認證升級機制），並推進 ADR 先行工作——為 Kill Switch、Token Cost Routing、TCB 斷點管理三大功能奠定架構基礎
> **結果**：Goal 達成（5/5 Stories PASS）。Velocity 6 pts，完成率 100%。連續第 11 Sprint 100%（127-137）。
> **容量**：6 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| retro: docs/schema/ 新增 GAD workflow JSON Schema Contract 範例檔案 | #617 | S | 1 | 已完成 (#623) |
| retro: CI 認證問題快速升級機制（第二次發生時自動建議根本解決） | #616 | M | 2 | 已完成 (#627) |
| RESEARCH: ADR-038 — Kill Switch 架構決策（緊急停止機制設計） | #619 | S | 1 | 已完成 (#624) |
| RESEARCH: ADR-039 — Token Cost Routing 架構決策（Risk-based Model 分級） | #620 | S | 1 | 已完成 (#625) |
| RESEARCH: ADR-040 — TCB 斷點管理架構決策（Agent Action 級 Checkpoint 設計） | #621 | S | 1 | 已完成 (#626) |

**Sprint 容量**：6 points

---

## Sprint 136（完成）

> Sprint Goal：建立 Schema-first API Contract 決策基礎（ADR-036）並落地 Schema 先行工作流程，同步加固 CI YAML lint 品質防護，修復持續發生的 CI OAuth 401 認證失敗根因
> **結果**：Goal 達成（5/5 Stories PASS）。Velocity 6 pts，完成率 100%。連續第 10 Sprint 100%（127-136）。
> **容量**：6 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| RESEARCH: ADR-036 — Schema-first API Contract 統一定義架構決策 | #601 | S | 1 | 已完成 (#611) |
| retro: Workflow issue body 應使用 --body-file 模式避免 YAML 特殊字符衝突 | #610 | S | 1 | 已完成 (#612) |
| retro: 新增 GitHub Actions workflow YAML lint CI 步驟 | #609 | S | 1 | 已完成 (#613) |
| [SRE] CI 持續失敗：New Issue Intake 401 Invalid bearer token | #600 | S | 1 | 已完成 (#614) |
| feat: Schema 先行 — API Contract 統一定義 | #406 | M | 2 | 已完成 (#615) |

**Sprint 容量**：6 points

---

## Sprint 135（完成）

> Sprint Goal：推進 Context Engineering 基礎架構（ADR-037 + JIT Retrieval 實作），研究 Agent Skills 開放標準對齊可行性，並修復 CI OAuth token 認證失效。
> **結果**：Goal 達成（4/4 Stories PASS）。Velocity 6 pts，完成率 100%。連續第 9 Sprint 100%（127+128+129+130+131+132+133+134+135）。
> **容量**：6 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| RESEARCH: ADR-037 — Context Engineering JIT 架構決策 | #602 | S | 1 | 已完成 (#603) |
| retro: 修復 CI New Issue Intake OAuth token 認證失效 | #597 | S | 1 | 已完成 (#604) |
| research: Agent Skills 開放標準對齊評估 | #396 | M | 2 | 已完成 (#605) |
| feat: Context Engineering — Just-in-Time Retrieval | #400 | M | 2 | 已完成 (#607) |

**Sprint 容量**：6 points
**執行順序**：ADR Phase（#602）→ Batch 1（#597 | #396 平行）→ Batch 2（#400 序列）

---

## Sprint 134（完成）

> Sprint Goal：落地 Sprint 133 Retro Action Items（並行 worktree 穩定性 + Sprint Planning AC 品質 + git tag 自動化）+ 啟動安全框架升級（Prompt Injection Defense Gate + Parallel Conflict Prediction）。
> **結果**：Goal 達成（5/5 Stories PASS）。Velocity 7 pts，完成率 100%。連續第 8 Sprint 100%（127+128+129+130+131+132+133+134）。
> **容量**：7 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| retro: Sprint Planning AC 指定明確檔案路徑 | #573 | S | 1 | 已完成 (#592) |
| retro: Sprint 133 — 並行 worktree 版本衝突預防機制 | #581 | S | 1 | 已完成 (#593) |
| retro: Sprint Review 後補打 git tag | #574 | S | 1 | 已完成 (#594) |
| feat: Prompt Injection Defense — Security Gate 擴充 | #393 | M | 2 | 已完成 (#595) |
| feat: Parallel Conflict Prediction — 平行任務衝突預測 | #395 | M | 2 | 已完成 (#596) |

**Sprint 容量**：7 points
**執行順序**：Batch 1（#573 | #581 平行）→ Batch 2（#574 | #393 平行）→ Batch 3（#395 序列）

---

## Sprint 133（完成）

> Sprint Goal：提升框架 QA 制衡品質（FREE-MAD + D3 Debate）+ 推進 GAD 研究成果落地（GAD Delivery Phase 視覺對比 Gate），同步完善專案範本降低使用者導入門檻。
> **結果**：Goal 達成（4/4 Stories PASS）。Velocity 6 pts，完成率 100%。連續第 7 Sprint 100%（127+128+129+130+131+132+133）。v0.89.7
> **容量**：6 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| feat: QA FREE-MAD 挑戰韌性機制 | #397 | S | 1 | 已完成 (#576) |
| feat: 專案範本 — Skills/Hooks/Script 綁定 | #407 | S | 1 | 已完成 (#577) |
| feat: D3 Debate Framework（Debate-Deliberate-Decide） | #403 | M | 2 | 已完成 (#578) |
| feat: GAD 接入 Delivery Phase — 雙 Team 視覺對比 | #385 | M | 2 | 已完成 (#579) |

**Sprint 容量**：6 points
**執行順序**：Batch 0（chore: ADR-034 修正）→ Batch 1（#397 | #407 平行）→ Batch 2（#403 → #385 序列）

---

## Sprint 132（完成）

> Sprint Goal：鞏固 Sprint Planning 品質 + 強化 Developer TDD 精準執行，落地 Sprint 131 Retro Action Items，並完成 TDAD 依賴分析工具選型 ADR。
> **結果**：Goal 達成（4/4 Stories PASS）。Velocity 6 pts，完成率 100%。連續第 6 Sprint 100%（127+128+129+130+131+132）。
> **容量**：6 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| retro: Story AC 完整性前置確認 | #563 | S | 1 | 已完成 (#568) |
| ADR RESEARCH: TDAD 依賴分析工具選型 | #567 | S | 1 | 已完成 (#569) |
| retro: Sprint Candidate RICE Score 補充 | #564 | M | 2 | 已完成 (#570) |
| feat: TDAD Dependency Map — 精準 TDD 執行 | #394 | M | 2 | 已完成 (#571) |

**Sprint 容量**：6 points
**執行順序**：Batch 1（#563 | #567 平行） → Batch 2（#564 | #394 平行，#394 依賴 #567）

---

## Sprint 131（完成）

> Sprint Goal：框架品質保障自動化 + shoot 進化 + browser-automation 工具選型 ADR，維持連續 100% 完成率。
> **結果**：Goal 達成（4/4 Stories PASS）。Velocity 6 pts，完成率 100%。連續第 5 Sprint 100%（128+129+130+131）。
> **容量**：6 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| retro: 建立 Skill 行數自動偵測腳本 | #555 | S | 1 | 已完成 (#559) |
| ADR RESEARCH: browser-automation 工具選型 ADR | #386 | M | 2 | 已完成 (#560) |
| retro: CI 升級確認時機明確化 | #556 | S | 1 | 已完成 (#561) |
| feat: /shoot 進化版 — test→review→PR 一鍵串接 | #388 | M | 2 | 已完成 (#562) |

**Sprint 容量**：6 points
**執行順序**：Batch 1（#555 | #386 平行） → Batch 2（#556 | #388 平行）

---

## Sprint 130（完成）

> Sprint Goal：交付 2 個 Feature Story 恢復產品功能前進動能（Retro-Action 自動偵測機制 + Skill 品質改善），同步處理 Node.js 20 deprecation CI 升級。
> **結果**：Goal 達成（3/3 Stories PASS）。Velocity 5 pts，完成率 100%。
> **容量**：5 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| feat: Retro-Action 連續未完成自動觸發 Grooming 機制 | #493 | M | 2 | 已完成 |
| chore: Skill description 改善 + 章節重新編號 | #487 | M | 2 | 已完成 |
| [SRE] Node.js 20 deprecation CI 升級 | #526 | S | 1 | 已完成 |

**Sprint 容量**：5 points
**執行順序**：Phase 1（#493 | #526 平行） → Phase 2（#487 序列）

---

## Sprint 129（完成）

> Sprint Goal：落地 Sprint 128 Retro 四項行動改善（Issue 追蹤紀律、OOM 防護、重複派遣防護、Task name 格式），修復 CI OAuth token 失效並建立長期自動同步機制，同步完成 worktree 殘留清理功能。
> **結果**：Goal 達成（7/7 Stories PASS）。Velocity 7 pts，完成率 100%。
> **容量**：7 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| retro: Retro-Action Issue 追蹤紀律 | #534 | S | 1 | 已完成 |
| feat: Worktree 自動清理 | #500 | S | 1 | 已完成 |
| retro: 平行 subagent OOM 防護 | #536 | S | 1 | 已完成 |
| retro: 重複派遣防護 Gate | #537 | S | 1 | 已完成 |
| retro: Task name 改用 repo/sprint-N 格式 | #538 | S | 1 | 已完成 |
| [SRE] CI failure: OAuth token 過期 | #524 | S | 1 | 已完成 |
| feat: GCE watchdog 自動同步 OAuth token | #539 | S | 1 | 已完成 |

**Sprint 容量**：7 points
**執行順序**：Phase 1a（#534 | #500 平行 worktree） → Phase 1b（#536 → #537 → #538 序列） → Phase 2（#524 → #539 人工部署）

---

## Sprint 128（完成）

> Sprint Goal：修復 Cruise Mode 核心行為缺陷（project_level=low HARD-GATE + SRE main branch 盲區），完成 INFRA 測試框架首次交付，同步落地三項 retro 流程改善。
> **結果**：Goal 達成（7/7 Stories PASS）。Velocity 8 pts，完成率 100%。
> **容量**：8 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| [Cruise] project_level=low 自動行為標為 HARD-GATE | #517 | S | 1 | 已完成 |
| [SRE] SRE 巡檢補充 main branch CI 獨立檢查 | #519 | S | 1 | 已完成 |
| Architect Gate for M+ Refactor Story | #491 | S | 1 | 已完成 |
| INFRA 測試框架架構設計 | #494 | S | 1 | 已完成 |
| INFRA 回歸測試案例實作 | #495 | M | 2 | 已完成 |
| Task 工具追蹤 Sprint Stories 進度 | #513 | S | 1 | 已完成 |
| Sprint 容量估算修訂 | #492 | S | 1 | 已完成 |

**Sprint 容量**：8 points
**執行順序**：Phase 1（#519 | #494 平行） → Phase 2（#517 → #513 → #491 → #492 序列） → Phase 3（#495 依賴 #494）

---

## Sprint 127（完成）

> Sprint Goal：鞏固 Sprint Execution 核心品質 — 完成結構重構 + 清除 Skill 技術債
> **結果**：Goal 達成（4/4 Stories PASS）。Velocity 7 pts，完成率 100%。
> **容量**：7 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| Sprint Execution Skill 結構重構 — story-lifecycle-prompt 模組化拆分 | #485 | M | 3 | 已完成 |
| shoot/SKILL.md 模組化拆分 — 1108 行降至 <=400 行 | #486 | S | 2 | 已完成 |
| RESEARCH: #452 拆分評估與最小可交付增量 | #490 | S | 1 | 已完成 |
| Plugin 維護 — LICENSE 檔案 + git tag 同步 | #488 | S | 1 | 已完成 |

**Sprint 容量**：7 points
**Phase 1**：全部平行執行（#485 | #486 | #490 | #488）

---

## Sprint 126（完成）

> Sprint Goal：Sprint Execution 結構重構 + Observability 端到端驗證 + CI 防回歸永久修復
> **結果**：部分達成（3/5 Stories PASS，#483 #481 #484）。Velocity 5 pts，完成率 60%。
> **Stakeholder 驗收**：接受（Observability 基礎建設目標達成，CI 防回歸目標達成）
> **容量**：11 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| Sprint Execution Skill 結構重構 | #485 | M | 3 | 未完成（carry-over） |
| Trace Log 端到端驗證 | #483 | M | 2 | 已完成 |
| INFRA 測試框架 — 自動化回歸測試 | #452 | M | 3 | 未完成（carry-over） |
| CI unzip 永久修復機制 | #481 | M | 2 | 已完成 |
| Runner offline 主動監控 | #484 | S | 1 | 已完成 |

**Sprint 容量**：11 points / **完成 Points**：5 pts
**執行順序**：Phase 1（#485 | #483 平行） → Phase 2（#484 → #481 序列） → Phase 3（#452）

---

## Sprint 125（完成）

> Sprint Goal：CI Regression 永久修復 + 框架治理強化 + Multi-Agent Observability 基礎建設
> **結果**：Goal 達成（7/7 Stories PASS）。Velocity 11 pts，完成率 100%。
> **Stakeholder 驗收**：接受
> **容量**：11 pts

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| [SRE] CI unzip 缺失問題復發 | #472 | S | 1 | 已完成 |
| [SRE] Runner offline: github-runner-mig-blpf | #471 | S | 1 | 已完成 |
| 框架複雜度預算機制 | #462 | M | 3 | 已完成 |
| Cruise/Sprint Task List 防跳步 | #469 | S | 1 | 已完成 |
| PR 顆粒度規範 | #470 | S | 1 | 已完成 |
| Structured Trace Log | #392 | L | 3 | 已完成 |
| ADR-033 Trace Log 架構決策 | #473 | S | 1 | 已完成 |

**Sprint 容量**：11 points
**執行順序**：Phase 1（#472 | #471 | #469 | #470 | #473 平行） → Phase 2（#462 | #392 依賴 #473）

---

## Sprint 124（完成）

> Sprint Goal：Team Debate 核心機制 + CI Regression 修復 + Retro Actions 落地
> **結果**：Goal 達成（6/6 Stories PASS）。Velocity 11 pts，完成率 100%。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| [SRE] #442 Regression fix (sudo) | #464 | S | 1 | 完成 |
| Team Debate — 雙 Agent 交替批判 | #383 | M | 3 | 完成 |
| ADR 自動納入 Sprint | #456 | S | 1 | 完成 |
| PR Quality Gate | #461 | S | 1 | 完成 |
| Cruise SKILL.md 模組拆分 | #460 | M | 3 | 完成 |
| ci-health-check 整合 SRE | #463 | S | 2 | 完成 |

**Sprint 容量**：11 points

---

## Sprint 123（完成）

> Sprint Goal：消除 Cruise Mode 隨機阻斷 + 交付 Cruise 雙模式 + 強化 CI 主動偵測
> **結果**：Goal 達成（5/5 Stories PASS）。Velocity 9 pts，完成率 100%。v0.83.0 發布。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| [Bug] prompt hooks 隨機擋 Bash | #446 | S | 1 | 完成 |
| cruise: /tmp flag 被清理 | #449 | S | 1 | 完成 |
| Cruise 雙模式（Phase 1） | #430 | M | 3 | 完成 |
| CI 健康檢查腳本 | #450 | M | 2 | 完成 |
| 並行安全規則矩陣 | #451 | M | 2 | 完成 |

**Sprint 容量**：9 points

---

## Sprint 122（完成）

> Sprint Goal：修復 CI 基礎設施三大故障點，恢復 Shikigami CI/CD 可靠度
> **結果**：Goal 達成（3/3 Stories PASS）。Velocity 5 pts，完成率 100%。降速聚焦 CI 修復。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| [SRE] GitHub App 安裝 | #423 | S | 1 | 完成 |
| [SRE] unzip 修復 | #442 | S | 1 | 完成 |
| [SRE] Node.js 20 遷移 | #424 | M | 3 | 完成 |

**Sprint 容量**：5 points

---

## Sprint 121（完成）

> Sprint Goal：強化 Sprint 運作韌性
> **結果**：Goal 達成（5/5 Stories PASS）。Velocity 10 pts，完成率 100%。全 5 Story 平行執行（worktree 隔離）。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| retro: Sprint 阻塞 bypass | #434 | M | 3 | 完成 |
| retro: Runner 環境標準化 | #436 | S | 2 | 完成 |
| retro: 邏輯依賴驗證 | #435 | S | 1 | 完成 |
| feat: Sprint Review 平行化 | #420 | M | 3 | 完成 |
| feat: SM 狀態圖 | #401 | S | 1 | 完成 |

**Sprint 容量**：10 points

---

## Sprint 120（完成）

> Sprint Goal：PO 巡邏行為修正 + CI 基礎設施修復 + code-review 強化
> **結果**：Goal 達成（5/5 Stories PASS）。Velocity 10 pts，完成率 100%。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| retro: 修復 new-issue-intake CI workflow | #381 | S | 2 | 完成 |
| [Cruise Feedback] PO 巡邏交付物識別缺陷 | #412 | M | 3 | 完成 |
| [Cruise Feedback] Stakeholder 回覆處置表 | #422 | S | 2 | 完成 |
| [Cruise Feedback] Sprint 不等 stakeholder | #415 | S | 2 | 完成 |
| retro: code-review checklist PR/Issue title 一致性 | #421 | S | 1 | 完成 |

**Sprint 容量**：10 points

---

## Sprint 119（完成）

> Sprint Goal：ADR-032 + CRITICAL 互動確認 + Review 分層 + Discovery Checklist + Worktree 驗證
> **結果**：Goal 達成（5/5 Stories PASS）。Velocity 10 pts，完成率 100%。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| adr: ADR-032 交付路徑分層 | #391 | M | 3 | 完成 |
| feat: CRITICAL issue 互動式確認 | #387 | S | 2 | 完成 |
| feat: Discovery Per-Item Checklist | #390 | S | 2 | 完成 |
| feat: Review 建議清單分層 | #384 | S | 2 | 完成 |
| retro: worktree 隔離驗證 | #382 | S | 1 | 完成 |

**Sprint 容量**：10 points

---

## Sprint 118（完成）

> Sprint Goal：Sprint Execution 流程重構（責任下放 + 流程拆解 + Epic 防護）
> **結果**：Goal 達成（5/5 Stories PASS）。Velocity 10 pts，完成率 100%。Code Review Loop 責任下放至 Story-Lifecycle subagent（ADR-023）+ Story Completion Checklist 5 步拆解 + Sprint Review §2.6 epic 防護（title 含 epic: 不 close）+ Cruise fallback 視窗可配置化 + OAuth 告警閾值可配置化。bump v0.82.0。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| #368-子2 責任下放：Code Review Loop 移至 Story-Lifecycle subagent | #368 | M | 3 | 完成 |
| #368-子3 流程拆解：Story Completion Checklist（5 步明確清單） | #368 | M | 3 | 完成 |
| fix: Sprint Review 不應自動 close epic Issue | #376 | S | 2 | 完成 |
| feat: Cruise 進度偵測 fallback 視窗可配置化 | #374 | S | 1 | 完成 |
| feat: OAuth Token Watchdog 過期通知閾值可配置化 | #375 | S | 1 | 完成 |

**Sprint 容量**：10 points

## Sprint 118 統計
- Velocity：10 pts（目標 10，達成率 100%）
- 完成率：100%（完成 5 / 計畫 5）
- 日期：2026-03-23
- Sprint 外 Shoots：1 項（#379 worktree 隔離）

---

## Sprint 116（完成）

> Sprint Goal：Cruise 治理邊界完善 + SRE 診斷 SOP
> **結果**：Goal 達成（3/3 Stories PASS）。Velocity 10 pts，完成率 100%。Cruise close_policy + delivery_chain per-repo 配置（ADR-029）+ SRE VM 查證 SOP（gcloud MIG + 三分類）+ feedback routing label-based 自動化。bump v0.79.0。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| SRE 巡檢：VM 消失原因不可推測，必須查證 | #329 | S | 2 | 完成 |
| [Cruise] Issue 關閉需發 Issue 人同意 + 交付鏈深度 per-repo 可定義 | #338 | M | 5 | 完成 |
| [Cruise] 回報對象應成為工作流的一部份 | #339 | S | 3 | 完成 |

**Sprint 容量**：10 points

## Sprint 116 統計
- Velocity：10 pts（目標 10，達成率 100%）
- 完成率：100%（完成 3 / 計畫 3）
- 日期：2026-03-23
- Sprint 外 Shoots：10 項（#333, #340, #343, #346, #348, #350, #352, #354, #357, #359）

---

## Sprint 114（準備中）

> Sprint Goal：Cruise Mode 穩定性與可用性改善 — SRE org-level runner + 嚴格模式

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| FIX：SRE 巡檢 org-level runner API 預設 | #325 | S | 1 | 待開始 |
| FEATURE：Cruise --strict 嚴格模式 | #326 | S | 2 | 待開始 |

**Sprint 容量**：3 points

---

## Sprint 113（完成）

> Sprint Goal：CI 權限分層落地 — 讓 Runner 依場景選擇權限等級，高風險操作需 Stakeholder Issue 核准

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| FIX：ADR-027 CI 權限模型改為可選分層 | #324 | M | 5 | 完成 |

**Sprint 容量**：5 points

---

## Sprint 112（進行中）

> Sprint Goal：讓 Shikigami Sprint 可從 GitHub Actions 動態觸發，對任意 repo 執行 headless Sprint

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| FEATURE：GitHub Actions Runner 動態 Sprint 派遣 | #323 | L | 10 | 待開始 |

**Sprint 容量**：10 points

---

## Sprint 111（進行中）

> Sprint Goal：落地 Cruise Mode Phase 1 — PO 巡邏 + SRE 巡檢自動巡航

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| FEATURE：Cruise Mode Phase 1 — PO 巡邏 + SRE 巡檢 | #321 | L | 5 | 完成 |

**Sprint 容量**：5 points

---

## Sprint 110（完成）

> Sprint Goal：統一框架共用檔案的跨機器安全模式 — 所有 append-only log 改為 per-session + 結算

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：框架共用檔案跨機器 conflict 修復 | #322 | L | 5 | 完成 |

**Sprint 容量**：5 points

---

## Sprint 109（完成）

> Sprint Goal：完成 AI 團隊績效儀表板，一指令查看當日工作成果

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| FEATURE：績效儀表板 Skill | #317 | M | 3 | 完成 |
| INFRA：settle sort key 修正 | retro | S | 1 | 完成 |

**Sprint 容量**：4 points

---

## Sprint 108（完成）

> Sprint Goal：修復出勤紀錄跨機器 conflict + 落地探索紀錄收集

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：出勤紀錄 per-session + 結算 | #319 | M | 2 | 完成 |
| FEATURE：探索紀錄收集（#317 P3） | #317 | M | 2 | 完成 |

**Sprint 容量**：4 points

---

## Sprint 107（完成）

> Sprint Goal：落地 AI 團隊識別碼統一規範與出勤時數可視化

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：編號統一 — US-#N + ADR claim 鎖 | #318 | M | 2 | 完成 |
| FEATURE：出勤時數 — 角色簽到/簽退（#317 P2） | #317 | M | 2 | 完成 |

**Sprint 容量**：4 points

## Sprint 107 統計
- Velocity：4 points
- 完成率：100%（完成 2 / 計畫 2）
- 日期：2026-03-20

---

## Sprint 106（完成）

> Sprint Goal：建立版號智慧策略與首階段績效可視化（會議紀錄）

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：版號策略 — 當日 minor 降級 patch | #305 | S | 1 | 完成 |
| FEATURE：Sprint 儀式會議紀錄自動產生（#317 P1） | #317 | M | 2 | 完成 |

**Sprint 容量**：3 points

## Sprint 106 統計
- Velocity：3 points
- 完成率：100%（完成 2 / 計畫 2）
- 日期：2026-03-20

---

## Sprint 105（完成）

> Sprint Goal：修復分散式鎖核心缺陷，確保跨機器多 Session 互斥可靠性

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：分散式鎖機制 — silent failure 與跨機器互斥缺陷修復（18 項） | #316 | L | 3 | 完成 |

**Sprint 容量**：3 points

---

## Sprint 104（完成）

> Sprint Goal：Sprint Git Flow 改為 PR-based — 禁止直推 main，引入 code review 環節提升程式碼品質

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| FEATURE：Sprint Git Flow 改為 PR-based — 禁止直推 main | #315 | L | 3 | 完成 |

**Sprint 容量**：3 points

---

## Sprint 103（完成）

> Sprint Goal：強化多 Session 並行可靠性 — 清理過期測試技術債、定義檔案鎖定架構、建立中斷恢復機制
> **結果**：Goal 達成（3/3 Stories PASS）。Velocity 7 points，完成率 100%。過期測試清理（#314）+ 檔案鎖定機制（acquire-file-lock.sh / release-file-lock.sh，ADR-022 選項 C 複用 #312 架構，32/32 PASS，CONFIRM）+ Sprint 中斷恢復機制（checkpoint JSON + claim-cleanup.sh，15/15 PASS，CONFIRM）。bump v0.74.0。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：刪除過期測試 test-us13 / test-us37 | #314 | S | 1 | 完成 |
| FEATURE：多 Session 並行開發的檔案鎖定機制 | #311 | L | 3 | 完成 |
| FEATURE：Sprint 中斷恢復機制（Spot VM / Session Crash） | #313 | L | 3 | 完成 |

**Sprint 容量**：7 points

## Sprint 103 統計
- Velocity：7 points
- 完成率：100%（完成 3 / 計畫 3）
- 日期：2026-03-19

---

## Sprint 102（完成）

> Sprint Goal：清除 Sprint 100 Retro 遺留測試技術債
> **結果**：Goal 達成（3/3 Stories PASS）。Velocity 3 points，完成率 100%。test-sprint-planning-skill.sh 修復（12/12 PASS）+ US-275 邊界補齊（空目錄 fallback + git pull 容錯）+ 測試技術債評估報告（test-us13/test-us37 建議刪除）。bump v0.73.1。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：修復 test-sprint-planning-skill.sh | #308 | S | 1 | 完成 |
| INFRA：US-275 邊界補齊 | #309 | S | 1 | 完成 |
| RESEARCH：評估既有測試技術債清理 | #310 | S | 1 | 完成 |

**Sprint 容量**：3 points

## Sprint 102 統計
- Velocity：3 points
- 完成率：100%（完成 3 / 計畫 3）
- 日期：2026-03-19

---

## Sprint 101（完成）

> Sprint Goal：落地多 Session 並行協調機制，防止跨 session 重複領取 Issue/Story
> **結果**：Goal 達成（1/1 Stories PASS）。Velocity 2 points，完成率 100%。三層協調機制（git remote ref 互斥鎖 + flock 本地原子鎖 + GitHub Issue 展示層）落地；獨立腳本 claim-issue.sh / release-issue.sh 可重用；SessionEnd hook 自動 release；外部審查 DISPUTE（4 缺陷）→ 修復後 CONFIRM。bump v0.73.0。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：多 Session 並行開發 — Issue/Story 級別協調機制 | #312 | M | 2 | 完成 |

**Sprint 容量**：2 points

## Sprint 101 統計
- Velocity：2 points
- 完成率：100%（完成 1 / 計畫 1）
- 日期：2026-03-19

---

## Sprint 100（完成）

> Sprint Goal：強化框架執行可靠性與 Anti-Hallucination 能力 — 補齊 story-lifecycle-prompt.md 執行漏洞（git commit 缺失、測試批量修復）、KM 文件 API 參數腦補防護、Sprint Planning 並行衝突修復、CI workflow 最佳實踐
> **結果**：Goal 達成（5/5 Stories PASS）。Velocity 6 points，完成率 100%。story-lifecycle-prompt.md 新增 §8.05 git commit Hard Gate + §3.5 測試批量修復策略 + §7.6 KM 第三方 API 驗證；Sprint Planning 並行衝突防護落地（po-prompt.md）；CI workflow cancel-in-progress 全覆蓋。bump v0.72.1。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：Story-Lifecycle subagent 完成後強制 git commit Hard Gate | #307 | S | 1 | 完成 |
| FEATURE：story-lifecycle-prompt: 測試修復批量執行策略 | #304 | S | 1 | 完成 |
| FEATURE：KM 第三方 API 文件驗證機制 — 禁止腦補 enum 值 | #276 | M | 2 | 完成 |
| INFRA：Bug：Sprint Planning 多 session 並行編號衝突修復 | #277 | S | 1 | 完成 |
| INFRA：CI/CD: 所有 workflow 加入 cancel-in-progress | #306 | S | 1 | 完成 |

**Sprint 容量**：6 points

## Sprint 100 統計
- Velocity：6 points
- 完成率：100%（完成 5 / 計畫 5）
- 日期：2026-03-19

---

## Sprint 99（完成）

> Sprint Goal：強化框架架構知識基礎與可展示性 — 補充 SDD-000 核心架構內容以解除 PB-2/PB-4 兩條產品線阻塞，並落地演示模式 Live Log Streaming 以提升框架的人機協作可見度，兌現 M5「好上手、人機協作」里程碑承諾。
> **結果**：Goal 達成（2/2 Stories PASS）。Velocity 2 points，完成率 100%。SDD-000 填充 8 Entity / 7 關聯 / 8 術語 / 4 層架構 / 8 Service / 6 Gateway 對照 / 6 元件邊界，解除 PB-2/PB-4 阻塞；Live Log Streaming 落地，story-lifecycle-prompt.md 各關鍵步驟均已加入日誌寫入指令，演示模式可用。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| FEATURE：SDD-000 核心章節補充至最低可用狀態（解除 PB-2/PB-4 共同阻塞） | #270 | S | 1 | 完成 |
| FEATURE：演示模式 Live Log Streaming 實作（Phase 1：tail -f 即時日誌串流） | #269 | S | 1 | 完成 |

**Sprint 容量**：2 points

## Sprint 99 統計
- Velocity：2 points
- 完成率：100%（完成 2 / 計畫 2）
- 日期：2026-03-15

---

## Sprint 98（完成）

> Sprint Goal：將 pr-review-toolkit 三 agent 補充審查層實作至 shoot 與 sprint-execution commit 前 Gate — 兌現 ADR-021 架構設計的工程品質深度承諾
> **結果**：Goal 達成（1/1 Stories PASS）。Velocity 2 points，完成率 100%。shoot §8.6 步驟 5.4 + sprint-execution §7.5 補充審查層完整實作，三 agent 平行派遣（code-reviewer / silent-failure-hunter / comment-analyzer）、CRITICAL/HIGH Hard Gate、doc-only 條件觸發、降級行為（WARN + 跳過 + 繼續）、引用式寫法避免體積膨脹，ADR-021 → #266 完整鏈條落地。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INTEGRATION：整合 pr-review-toolkit 審查 agents 至 shoot / sprint-execution commit 前 Gate | #266 | M | 2 | 完成 |

**Sprint 容量**：2 points

## Sprint 98 統計
- Velocity：2 points
- 完成率：100%（完成 1 / 計畫 1）
- 日期：2026-03-15

---

## Sprint 97（完成）

> Sprint Goal：定義 pr-review-toolkit 外部 Plugin 整合架構 — 為 #266 實作掃清前置依賴
> **結果**：Goal 達成（1/1 Stories PASS）。Velocity 1 point，完成率 100%。ADR-021 定義補充層整合模式（外部獨立審查後追加）、三 agent 平行派遣、嚴重度四級 Gate（CRITICAL/HIGH 阻擋）、降級行為（WARN + 跳過）、責任邊界（§8.5 Spec Compliance vs 步驟 5.4 工程品質深度）、Spike Report 含 5 項建議後續行動。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| RESEARCH：ADR — pr-review-toolkit 外部 Plugin 整合架構定義 | #267 | S | 1 | 完成 |

**Sprint 容量**：1 point

## Sprint 97 統計
- Velocity：1 point
- 完成率：100%（完成 1 / 計畫 1）
- 日期：2026-03-15

---

## Sprint 96（完成）

> Sprint Goal：強化框架品質護欄 — 版號驗證自動化、Skill 角色 prompt 拆分、UI/UX 設計前置 Gate，全面消除已知合規盲點
> **結果**：Goal 達成（6/6 Stories PASS）。Velocity 9 points，完成率 100%。版號驗證雙層 Hook（Git pre-commit + Claude Code PreToolUse）+ architecture-decision / deployment-readiness 角色 prompt 拆分 + UI/UX Design Foundation Gate（DESIGN=Hard / 非DESIGN=Soft）+ 演示模式 Spike Report（推薦 Live Log Streaming）。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-263：validate-version.sh 增強：README.md badge 版號檢查 | #259 | S | 1 | 完成 |
| US-264：版本驗證 Hook：commit 前自動檢查版號一致性 | #260 | M | 2 | 完成 |
| US-265：architecture-decision Skill 拆分：角色 prompt 檔案分離 | #261 | M | 2 | 完成 |
| US-266：deployment-readiness Skill 拆分：SRE / Security 角色 prompt 分離 | #262 | M | 2 | 完成 |
| US-267：UI/UX Designer 前置檢查：Design System / Design Token / Guideline 文件存在性驗證 | #258 | S | 1 | 完成 |
| US-268：演示模式 / 火力展示（Spike）：技術可行性報告 | #255 | S | 1 | 完成 |

**Sprint 容量**：9 points

## Sprint 96 統計
- Velocity：9 points
- 完成率：100%（完成 6 / 計畫 6）
- 日期：2026-03-14

---

## Sprint 95（完成）

> Sprint Goal：強化 Architect 審查 Gate 的分層合規性檢查能力
> **結果**：Goal 達成（1/1 Stories PASS）。Velocity 2 points，完成率 100%。Layer Compliance 分層合規檢查三層防線（QA WARN → Architect FAIL → 輸出範例同步），責任邊界清晰。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-257：Architect 審查 Gate 加入 Layer Compliance 分層合規檢查 | #254 | S | 2 | 完成 |

**Sprint 容量**：2 points

## Sprint 95 統計
- Velocity：2 points
- 完成率：100%（完成 1 / 計畫 1）
- 日期：2026-03-14

---

## Sprint 94（完成）

> Sprint Goal：修復版號一致性測試技術債 — 確保 CI 驗證腳本在缺少 `jq` 環境下正確報告失敗，恢復 4 個 FAIL 測試至 PASS 狀態
> **結果**：Goal 達成（1/1 Stories PASS）。Velocity 1 point，完成率 100%。jq preflight 存在性檢查 + 空字串版本防護 + TC-07/TC-08 新增測試案例，16/16 測試全 PASS。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-256：retro: 修復版號一致性測試 — Sprint 93 既有 FAIL 技術債清理 | #253 | S | 1 | 完成 |

**Sprint 容量**：1 point

## Sprint 94 統計
- Velocity：1 point
- 完成率：100%（完成 1 / 計畫 1）
- 日期：2026-03-13

---

## Sprint 93（完成）

> Sprint Goal：強化框架品質深度 — 資料品質 Gate、隱性需求捕捉、Smoke Test、探索性測試與 QA 視角升級 + 低記憶體環境控制
> **結果**：Goal 達成（6/6 Stories PASS）。Velocity 6 points，完成率 100%。QA 角色升級為「使用者代言人」+ AC 模板非功能屬性指引 + 資料品質 Gate（Hard Gate 覆蓋率驗證）+ Smoke Test 要求（外部資源 Story 真實資料驗證）+ Sprint Review 探索性測試（邊界案例清單）+ 低記憶體環境平行上限控制（SHIKIGAMI_MAX_PARALLEL）。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-250：QA 角色升級：從規格檢查員到使用者代言人 | #248 | S | 1 | 完成 |
| US-251：AC 模板補充非功能屬性指引 | #249 | S | 1 | 完成 |
| US-252：資料品質 Gate：補充靜態資料覆蓋率驗證機制 | #250 | S | 1 | 完成 |
| US-253：Smoke Test 要求：涉及外部資源的 Story 需真實資料驗證 | #251 | S | 1 | 完成 |
| US-254：Sprint Review 探索性測試：邊界案例與隨機輸入驗證 | #252 | S | 1 | 完成 |
| US-255：低記憶體環境平行 Subagent 數量上限控制 | #246 | S | 1 | 完成 |

**Sprint 容量**：6 points

## Sprint 93 統計
- Velocity：6 points
- 完成率：100%（完成 6 / 計畫 6）
- 日期：2026-03-13

---

## Sprint 92（完成）

> Sprint Goal：強化框架可靠性 — 修正外部 Issue 通知時機與 Subagent 結果持久化
> **結果**：Goal 達成（2/2 Stories PASS）。Velocity 3 points，完成率 100%。外部 Issue 階段 2 留言觸發時機修正（deployment-readiness PASS + E2E PASS 雙重條件）+ Subagent 結果暫存機制（§9.0 暫存寫入 + §3 CACHE-RECOVERY fallback）。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-248：sprint-review S2.6 外部 Issue 階段 2 留言觸發時機修正 | #242 | S | 1 | 完成 |
| US-249：Subagent 結果暫存 — context compaction 後結果復原機制 | #208 | M | 2 | 完成 |

**Sprint 容量**：3 points

## Sprint 92 統計
- Velocity：3 points
- 完成率：100%（完成 2 / 計畫 2）
- 日期：2026-03-13

---

## Sprint 91（完成）

> Sprint Goal：透過 SKILL.md 瘦身與角色 Prompt 拆分，將框架 context 消耗削減約 75%
> **結果**：Goal 達成（2/2 Stories PASS）。Velocity 5 points，完成率 100%。SKILL.md 瘦身 -1601 行（31.9%）+ 角色 Prompt 拆分（sprint-planning/sprint-review 各拆為 SKILL.md + 3 個角色 prompt）。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-246：SKILL.md 瘦身：移除 agent 已知的工具教學與重複樣板 | #245 | L | 3 | 完成 |
| US-245：SKILL.md 角色專屬 Prompt 拆分 — 減少 subagent context 消耗 | #244 | M | 2 | 完成 |

**Sprint 容量**：5 points

## Sprint 91 統計
- Velocity：5 points
- 完成率：100%（完成 2 / 計畫 2）
- 日期：2026-03-12

---

## Sprint 90（完成）

> Sprint Goal：CI/CD 可觀測性 + QA 流程補強 — Deploy 通知模板建立 + Systematic Debugging 自動觸發時機定義
> **結果**：Goal 達成（2/2 Stories PASS）。Velocity 2 points，完成率 100%。Systematic Debugging 三觸發點定義（Sprint Review HARD-GATE + Deploy 後/Bug 修復後建議觸發）+ Deploy 通知 Workflow 模板與 Deploy Board 初始化腳本建立。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-247：Systematic Debugging 自動觸發時機 — Sprint Review/Deploy/Bug Fix 三觸發點定義 | #240 | S | 1 | 完成 |
| US-246：CI/CD Deploy 通知 Workflow 模板 — deploy-notify.yml + Deploy Board 初始化 | #239 | S | 1 | 完成 |

**Sprint 容量**：2 points

## Sprint 90 統計
- Velocity：2 points
- 完成率：100%（完成 2 / 計畫 2）
- 日期：2026-03-12

---

## Sprint 89（完成）

> Sprint Goal：實作流程管理 MCP Server Phase 1，驗證 context compaction recovery 可行性，解決 Sprint 87/88 連續斷鏈問題
> **結果**：Goal 達成（1/1 Stories PASS）。Velocity 2 points，完成率 100%。流程管理 MCP Server Phase 1 實作完成（get_current_step / advance_step / get_remaining_steps），狀態持久化至檔案系統，Fallback 機制就緒，Context compaction recovery 可行性驗證通過。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-245：流程管理 MCP Server Phase 1 — Sprint 流程狀態機 | #238 | M | 2 | 完成 |

**Sprint 容量**：2 points

## Sprint 89 統計
- Velocity：2 points
- 完成率：100%（完成 1 / 計畫 1）
- 日期：2026-03-12

---

## Sprint 88（完成）

> Sprint Goal：框架品質全面強化 — TDD 需求理解升級 + Shoot CI Gate + E2E 修復 + MCP 三層架構評估 + 前端設計 Gate
> **結果**：Goal 達成（5/5 Stories PASS）。Velocity 7 points，完成率 100%。TDD 測試可寫性檢查（TC-W1~TC-W5）+ Shoot CI Gate + E2E workflow_dispatch 修復 + MCP 三層架構評估報告/POC/ADR-019 草稿 + 前端設計 Gate 三層機制（Pre-check/派遣/審查）。
> **Stakeholder 驗收**：接受

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-240：TDD 需求理解驗證 — 寫不出測試自動觸發 REQUIREMENT_AMBIGUITY 升級 | #237 | S | 1 | 完成 |
| US-241：shoot CI Gate — CI pass 才標 PASS | #236 | S | 1 | 完成 |
| US-242：E2E workflow placeholder 修復 | #206 | S | 1 | 完成 |
| US-243：MCP 三層架構 — 知識庫/流程管理/品質觀察 MCP Server | #231 | M | 2 | 完成 |
| US-244：前端 Story 設計資訊 Gate — Pre-check + 角色派遣 + 交付審查 | #198 | M | 2 | 完成 |

**Sprint 容量**：7 points

## Sprint 88 統計
- Velocity：7 points
- 完成率：100%（完成 5 / 計畫 5）
- 日期：2026-03-12

---

## 短衝記錄

| 日期 | 標題 | Issue/Story | commit hash |
|------|------|-------------|-------------|
| 2026-03-12 | Sprint Review 精簡化 — 移除快思/慢想、歸檔觸發、Token 成本、Backlog .md 同步 | #243 | fadde69 |
| 2026-03-12 | 清理 PRODUCT_BACKLOG.md / BACKLOG_DONE.md 殘留引用（ADR-010 對齊） | — | e98212b |
| 2026-03-14 | Architect SDD 補領域模型審查 + Shoot QA 與 Sprint Execution 品質對齊 | #256 #257 | 2b00b30 |
| 2026-03-14 | Decision Table Testing 整合至 QA Engineer — 執行規程 + §1.17 + §4 對接 | #263 | dcd95d4 |
| 2026-03-15 | TDD 順序強制 Hard Gate + Sprint Review QA 缺陷修復複驗 Gate | #264 #265 | 065b338 |
| 2026-03-15 | ADR-020 SDD 作為 AC 強制上游約束 — SDD → AC → TDD 追溯鏈 | — | ec9b05d |
| 2026-03-15 | SDD 類別圖強制 Gateway 寫入入口 — 新增 DM-4 審查機制 | #268 | 0da8626 |
| 2026-03-23 | 巡邏留言應編輯而非重複發新留言 | #409 | afd1d37 |
| 2026-03-23 | #389 PO 巡邏加入 PR comments 掃描（補回歸測試） | #389 | 7370b84 |
| 2026-03-24 | 測試腳本 grep 語法規範 — 禁止 grep -l 與 && echo found 混用 | #598 | 7cbb54c |

---

> 歷史 Sprint 記錄：[PROJECT_BOARD_ARCHIVE](km/archive/PROJECT_BOARD_ARCHIVE.md)（Sprint 1–87）
