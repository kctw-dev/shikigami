# Sprint 180 Review 會議紀錄

**日期**：2026-04-09
**主持**：Sprint Review Subagent
**Sprint**：Sprint 180
**Sprint Goal**：將 ADR-045 short-lived subagent 從 PoC 模擬升級為 sprint-execution task-list-init 步驟的真實整合，同步補完 Sprint 179 Retro Action Items 的可觀測性與文件缺口

---

## §1.5 一致性審查

| 項目 | 結果 | 備注 |
|------|------|------|
| sprint_180.md vs PROJECT_BOARD.md | 一致（更新後） | 兩處狀態均已更新為 DONE |
| ROADMAP.md 版號 | — | 不適用（本 Sprint 無版號 bump） |
| plugin.json vs marketplace.json | 一致 | 兩者均為 v0.118.1 |
| README.md badge | 一致 | v0.118.1 |
| CI 狀態 | PASS（核心）/ 4 FAIL（既有） | 4 項失敗為 test-story-lifecycle 的前期既有問題，非 Sprint 180 引入 |
| test-step-subagent-poc.sh | PASS 30/30 | #983 核心測試全通過 |

---

## §2 Sprint Review

### §2.1 PO Demo — Story 交付內容摘要

#### Story #983：feat: ADR-045 落地 — task-list-init 整合（PR#985，DONE）
- **交付物**：
  - `scripts/state-machine/step-subagent-poc.sh`：從模擬升級為真實 dispatch 模式，保留 `--mode=simulate` 旗標（NFR1 向後相容）
  - `scripts/state-machine/rule-ratio-measure.sh`：規則佔比量測工具，零依賴（bash + 基本工具）
  - `skills/sprint-execution/references/step-subagent-contract.md`：step subagent 契約文件（Prompt 規範四區塊 + 結果 JSON 契約）
- **AC 驗收**：AC-1 ✓、AC-2 ✓（腳本可跑）、AC-3 ✓（觀察記錄：本 Sprint 派遣 1 次 task-list-init step subagent，無規則忽略事件觀察）、AC-4 ✓
- **test-step-subagent-poc.sh**：30/30 PASS

#### Story #982：feat: backlog 水位趨勢整合至自動化報告（PR#986，DONE）
- **交付物**：`scripts/check-backlog-health.sh` 輸出整合趨勢摘要（`show-backlog-water-trend.sh` 自動呼叫）
- **AC 驗收**：AC-1 ✓、AC-2 ✓（無需手動執行即可看趨勢）

#### Story #984：docs: hooks 架構說明文件（PR#987，DONE）
- **交付物**：`hooks/README.md` — 說明 hook-runner.sh vs 直接執行的決策規則，納入 #955 評估結論
- **AC 驗收**：AC-1 ✓、AC-2 ✓

#### Story #953：docs: TDD 外部工具模擬最佳實踐指南（直推 main commit 4de02fb，**PROCESS-VIOLATION**）
- **交付物**：`docs/km/tdd-external-tool-mocking.md` — fake binary vs PATH 清空陷阱說明，含反例（`PATH=/nonexistent`）與正例（fake binary in TMPBIN）
- **AC 驗收**：AC-1 ✓、AC-2 ✓（內容層面通過，但交付流程違規）
- **Issue 狀態**：已 CLOSED（2026-04-09T13:37:37Z）

---

### §2.2 QA 邊界測試

- `tests/test-step-subagent-poc.sh`：**30/30 PASS** — ADR-045 核心功能全通過
- `tests/test-*.sh`（全套）：PASS 12 / FAIL 4 — 4 項失敗（`test-story-lifecycle.sh`）為既有問題，本 Sprint 未引入，不影響 Sprint 180 DoD

---

### §2.3 Stakeholder 確認

Sprint Goal 達成：ADR-045 落地第一步完成，task-list-init 整合為 short-lived subagent 架構，規則佔比量測機制可運行。backlog 水位趨勢與 hooks 架構文件補齊。

---

### §2.4 PROJECT_BOARD.md 更新

Sprint 180 狀態更新為 DONE（4/4 Stories completed，Velocity 6 pts）。

---

### §2.5 sprint_180.md 回寫

狀態欄更新，加入 Review 結果摘要。

---

### §2.6 Issue 關閉紀錄

| Issue | 操作 |
|-------|------|
| #983 | CLOSE（PR#985 merged 2026-04-09T13:23:17Z） |
| #982 | CLOSE（PR#986 merged 2026-04-09T13:32:42Z） |
| #984 | CLOSE（PR#987 merged 2026-04-09T13:32:47Z） |
| #953 | 已 CLOSED（2026-04-09T13:37:37Z，direct-main，PROCESS-VIOLATION） |

---

### §2.64 PR 流程合規檢查

| Story | PR | 狀態 |
|-------|-----|------|
| #983 | PR#985 | MERGED ✓ |
| #982 | PR#986 | MERGED ✓ |
| #984 | PR#987 | MERGED ✓ |
| #953 | 無 | **[PROCESS-VIOLATION] Story #953 未透過 PR 交付**，commit 4de02fb 直推 main |

---

### §2.7 Backlog 健康度

- **sprint-candidate 數量**：4（健康基準 >= 6，目前偏低，需 Retro 追蹤）
- 建議 Sprint 181 Planning 前補充 sprint-candidate

---

## Process Violations

- Story #953: haiku subagent 直推 main（commit 4de02fb），未建立 PR。自圓其說為「純文件 Story 無需 PR 流程」，違反 Sprint 165 Retro #853 HARD-GATE。此為 ADR-045 注意力衰減問題的實證案例，將作為 Sprint 180 Retro 核心議題。

---

## Sprint 180 結論

| 指標 | 數值 |
|------|------|
| Sprint Goal 達成 | ✓ |
| Stories 完成 | 4 / 4 |
| Velocity | 6 pts |
| PR 合規率 | 3 / 4（75%）|
| Process Violations | 1（#953 直推 main） |
| test-step-subagent-poc.sh | 30/30 PASS |
| Backlog sprint-candidate 水位 | 4（偏低） |

**下一步**：Sprint 180 Retro → Sprint 181 Planning
