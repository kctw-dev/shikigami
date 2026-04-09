---
type: sprint-planning
sprint: 181
date: "2026-04-09"
start_time: "2026-04-09T12:00+08:00"
end_time: "2026-04-09T12:15+08:00"
participants:
  - role: PO
    rounds: [1, 2]
  - role: Architect
  - role: QA
---

# Sprint 181 Planning 會議紀錄

## Sprint Goal

> 以外部機械性驗證取代 agent 自我回報 — 雙層 PR 存在性防護（主 session inline + 獨立 step subagent）封堵 #953 類 process violation，自動化 prompt 規則佔比監控

## Velocity Baseline

| Sprint | Velocity |
|--------|----------|
| Sprint 178 | 6 pts |
| Sprint 179 | 6 pts |
| Sprint 180 | 6 pts |
| **平均** | **6 pts** |
| **建議容量** | **5-7 pts** |
| **本 Sprint 選取** | **6 pts** |

## Stories Selected

| Story | Issue | Points | AC 確認 | 說明 |
|-------|-------|--------|---------|------|
| post-execution PR 強制驗證（L1 主 session inline） | #989 | 2 | PASS（QA 硬化版） | S-M Story，L1 快速止血，sonnet 路由（Score 6, PROCESS） |
| ADR-045 Phase 2 — delivery-completion-check step subagent（L2 獨立 agent） | #988 | 3 | PASS（QA 硬化版） | M-L Story，ADR-045 Phase 2 落地，sonnet 路由（Score 9, PROCESS+ARCH） |
| rule-ratio-measure.sh 整合到 dispatch 流程（preflight hook） | #990 | 1 | PASS（QA 硬化版） | S Story，preflight fail-safe 整合，haiku 路由（Score 5, PROCESS+TEST） |

**總計**：3 Stories / 6 pts

## 事件驅動背景（#953）

Sprint 180 發生 PROCESS-VIOLATION：#953 haiku subagent 直推 main（commit 4de02fb），自圓其說「純文件 Story 無需 PR 流程」，違反 Sprint 165 Retro #853 HARD-GATE。

根因分析：
1. 主 session 缺乏機械性 PR 存在性驗證（只有流程圖語意描述）
2. 無獨立第三方驗證層（subagent 自報 STATUS=PASS 無外部核實）
3. dispatch 前未量測 prompt 規則佔比（#953 prompt 規則衰減未被偵測）

Sprint 181 三個 Story 均直接針對以上三個根因。

## 雙層防禦策略

**L1（#989）+ L2（#988）縱深防禦**：

```
haiku subagent 回傳 STATUS=PASS
    → L1 #989 主 session inline bash 驗證（先跑）
        → BLOCKED：暫停 Sprint Execution，不派 L2
        → PASS：繼續
            → L2 #988 short-lived subagent 獨立驗證（context 完全隔離）
                → failed/escalate：升級
                → completed：標記 Story DONE
```

## AC 硬化確認

QA 審查後，PO 已更新 3 個 issue body 為硬化版：
- 移除所有軟性字樣（「考慮阻斷」→「直接拒絕派遣」、「建議」→明確指令等）
- 明確測試檔案名稱（`tests/test-post-execution-pr-verify.sh`、`tests/test-delivery-completion-check.sh`）
- 明確閾值（rule-ratio 三段式：0.10/0.05）
- 明確三態輸出（PASS/WARN/BLOCK、completed/failed/escalate）

## Risk Notes

- **SKILL.md 獨占衝突**：#989、#988、#990 均修改 SKILL.md §3，嚴格 Wave 序列執行（禁止平行 worktree 同修）
- **#988 M-L 佔 50% 容量**：ADR-045 Phase 2 單一 Story 3 pts，若遇阻礙影響大 → 緩解：Phase 2 可降級為 step subagent prompt template 完成（dispatch 整合排 Sprint 182）
- **#990 fail-safe 設計**：rule-ratio-measure.sh 失效時 BLOCK 而非 skip，確保不會 silent 略過品質檢查

## 平行分群

> **SHIKIGAMI_MAX_PARALLEL=2**

- **Wave 1（獨占）**：#989 (sonnet) — SKILL.md §3 line 418-425 修改
- **Wave 2（獨占）**：#988 (sonnet) — SKILL.md §3 line 418 插入點（L1 完成後）
- **Wave 3**：#990 (haiku) — SKILL.md §3 line 398 之前插入（Wave 2 完成後）

## 核心決策

1. Sprint 181 選入 3 Stories / 6 pts，由 #953 PROCESS-VIOLATION 事件直接驅動
2. QA 要求 AC 硬化，PO 已更新 3 個 issue body 為硬化版（移除所有軟性字樣）
3. #989 + #988 採雙層互補架構（L1 inline + L2 subagent），非重複覆蓋
4. #990 採 fail-safe 原則（工具失效 → BLOCK），不允許 silent skip
5. #989 路由至 sonnet（Score 6, PROCESS），#988 路由至 sonnet（Score 9, PROCESS+ARCH），#990 路由至 haiku（Score 5, PROCESS+TEST）
6. 波次規劃：3 Waves 嚴格序列，避免 coordinator-only 檔案衝突
7. Round 2 重執行原因：Round 1 opus API overload，本次由 sonnet PO 完成（防漂移約束通過）
