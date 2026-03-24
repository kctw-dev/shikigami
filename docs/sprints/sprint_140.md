# Sprint 140

**Sprint Goal**：落地 ADR-041/ADR-042 決策成果——實作 Crash Recovery 與 Session Watchdog 彈性架構，並根本解決持續發生的 CI Token 輪換問題。

**期間**：2026-03-24 ~ 2026-03-31
**容量**：5 pts
**Velocity 基準**：Sprint 137-139 平均 5.7 pts → 建議容量 5-6 pts

---

## Sprint Backlog

| Story | Issue | Type | Size | Points | ADR | 負責人 | 狀態 |
|-------|-------|------|------|--------|-----|--------|------|
| retro: CI Token 輪換自動化 — CLAUDE_CODE_OAUTH_TOKEN 持續過期根本解決 | #637 | INFRA | S | 1 | 無需 | Developer | DONE(#640) |
| feat: Temporal-style Crash Recovery（依賴 ADR-041 Accepted） | #405 | FEATURE | M | 2 | ADR-041 ✓ | Developer | DONE(#641) |
| feat: Session Watchdog — 存活監控 + 自動重啟（依賴 ADR-042 + #405） | #408 | FEATURE | M | 2 | ADR-042 ✓ | Developer | DONE(#642) |

**總計**：5 pts

---

## 執行順序（平行分群）

### Phase 1（平行）
- **#637** — CI Token 輪換研究（獨立，無依賴）
- **#405** — Crash Recovery 實作（ADR-041 Accepted，依賴 TCB 已完成）

### Phase 2（序列，依賴 Phase 1 #405 完成）
- **#408** — Session Watchdog 實作（依賴 #405 crash-recovery.sh 完成）

---

## Acceptance Criteria 摘要

### US-#637 retro: CI Token 輪換自動化
- AC1: 研究 GitHub Actions secret 自動輪換方案
- AC2: 評估替代認證方式（service account / API key 等）
- AC3: 產出 ADR 或方案文件，明確建議替換策略
- AC4: 若方案可行，實作後 CI 連續 2 週正常執行（本 Sprint 交付文件，後續驗證）
- NFR1: CI 認證失效率 < 1%（near-zero）
- NFR2: 降低人工維護頻率至每季或以上

### US-#405 feat: Temporal-style Crash Recovery
- AC1: Session-level Event Log（`.claude/session-event-log.jsonl`）
- AC2: Side Effect Log，防止 git commit / GitHub API 重複執行
- AC3: `scripts/crash-recovery.sh` — 從 checkpoint 恢復 Sprint 狀態
- AC4: `tests/test-crash-recovery.sh` — 驗證 side effect 防重複
- AC5: 更新 `skills/sprint-execution/SKILL.md` 補充恢復流程說明
- NFR1: crash 後 side effect 重複執行次數 = 0
- NFR2: crash recovery 啟動 < 30 秒
- NFR3: 跨 session 恢復成功率 ≥ 90%

### US-#408 feat: Session Watchdog
- AC1: `hooks/session-watchdog.sh` — PostToolUse heartbeat 更新
- AC2: `scripts/watchdog-monitor.sh` — heartbeat 超時偵測（預設 10 分鐘）
- AC3: `scripts/watchdog-restart.sh` — 呼叫 Crash Recovery 流程
- AC4: `tests/test-watchdog.sh` — 驗證 heartbeat 超時偵測邏輯
- AC5: 更新 `hooks/hooks.json` 加入 watchdog heartbeat hook
- NFR1: Hang 偵測延遲 < timeout + 1 分鐘（< 11 分鐘）
- NFR2: False positive 重啟率 < 5%
- NFR3: 所有 watchdog 事件記錄至 watchdog-events.jsonl

---

## 技術評估（Architect）

| Story | T-shirt | ADR 需求 | Related SDDs | 說明 |
|-------|---------|---------|-------------|------|
| #637 | S | 無需 ADR | — | CI retro/research，交付物為方案文件 |
| #405 | M | ADR-041 Accepted ✓ | SDD-000（Hook/Infrastructure） | Hybrid Checkpoint + Side Effect Log |
| #408 | M | ADR-042 Accepted ✓ | SDD-000（Hook entity 擴充） | Hook-based Heartbeat，依賴 #405 |

---

## QA 驗收確認

| Story | AC 狀態 | 路徑驗證 | 隱性需求 | 結論 |
|-------|---------|---------|---------|------|
| #637 | PASS | N/A | Minor: AC4 跨 Sprint 驗證（本 Sprint 交付文件） | PASS |
| #405 | PASS | PASS（`skills/sprint-execution/SKILL.md` 確認存在） | Minor: NFR4 event log graceful degrade | PASS |
| #408 | PASS | PASS（`hooks/hooks.json` 確認存在） | Minor: NFR4 watchdog graceful 停止 | PASS |

---

## 複雜度評估

- 新增 Skill/Agent：無（新增 scripts + hooks，不新增 Skill/Agent 定義）
- 現有 Skill 修改：`skills/sprint-execution/SKILL.md`（#405 AC5）
- 複雜度預算：無超標風險

---

## Sprint Planning 決議

1. #637 本 Sprint 交付「研究文件 + 方案建議」，AC4（CI 連續 2 週正常）列為後續驗證指標
2. #408 嚴格在 #405 完成後才開始執行（Phase 2）
3. ADR-041 / ADR-042 均已 Accepted，Hard Gate 已通過
4. 三個 Stories 均無 API 契約需求（內部 Shell 實作）
