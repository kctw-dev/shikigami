# Sprint 179

**Sprint Goal：落地 ADR-045 架構方向修正（short-lived subagent 模型），同步清理 Sprint 178 Retro 遺留行動項目，強化框架自動化工具鏈**

**開始日期**：2026-04-09
**結束日期**：2026-04-16
**容量**：6 pts
**Velocity 基準**：avg 6 pts（Sprint 176=6, Sprint 177=6, Sprint 178=6）

---

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 | 負責 | Routing Tier |
|-------|-------|------|--------|------|------|-------------|
| feat: ADR-045 方向修正 — 規則衰減是注意力問題，改用細粒度 short-lived subagent | #977 | L | 3 | DONE | PR#979 | opus（Score 11, ARCH） |
| retro: haiku subagent 任務理解不完整 — 確保派遣 prompt 明確要求建立 PR | #976 | S | 1 | DONE | PR#978 | haiku（Score 5, FIX） |
| feat: backlog 水位歷史趨勢查詢腳本（JSONL 可視化） | #948 | S | 1 | DONE | PR#980 | haiku（Score 5, FEAT） |
| retro: 評估 SessionEnd kill-switch hook 是否需遷移至 hook-runner.sh | #955 | S | 1 | DONE | PR#981 | haiku（Score 4, RESEARCH） |

**總計**：4 Stories / 6 pts

---

## 驗收標準摘要

### #977 feat: ADR-045 方向修正 — 規則衰減是注意力問題，改用細粒度 short-lived subagent
- AC-1：更新 ADR-045，修正問題診斷（記憶力→注意力）與結論（狀態機驅動→short-lived subagent + 進度追蹤）
- AC-2：設計 sprint-execution 細粒度 subagent 派遣方案（哪些步驟需要獨立 subagent、prompt 模板、結果回傳契約）
- AC-3：state-machine.sh 角色重新定義為 progress tracker，移除 gate 驅動邏輯，保留 checkpoint/status/recovery 功能
- AC-4：PoC 驗證 — 至少 1 個步驟改為 short-lived subagent 派遣，對比衰減前後遵守率

### #976 retro: haiku subagent 任務理解不完整 — 確保派遣 prompt 明確要求建立 PR
- AC-1：Sprint Execution Skill 派遣 haiku subagent 的 prompt 加入「必須建立 PR」的明確說明
- AC-2：Wave 完成後主 agent 執行 PR 存在性驗證（`gh pr list --head <branch>`）
- AC-3：Sprint 179+ 無同類重派事件

### #948 feat: backlog 水位歷史趨勢查詢腳本（JSONL 可視化）
- AC-1：新增 scripts/show-backlog-water-trend.sh，讀取 JSONL 趨勢並輸出表格摘要
- AC-2：至少顯示最近 7 天趨勢（日期、水位、狀態）

### #955 retro: 評估 SessionEnd kill-switch hook 是否需遷移至 hook-runner.sh
- AC-1：評估 kill-switch hook 是否需要 timeout 保護（kill-switch 邏輯通常很快，可能不需要）
- AC-2：若需要，遷移至 hook-runner.sh；若不需要，文件說明理由

---

## 技術評估摘要

| Story | T-shirt | ADR | Schema Contract | Related SDDs | 平行分群 |
|-------|---------|-----|----------------|-------------|---------|
| #977 | L | ADR-045 更新 | subagent 派遣契約 | 參考 ADR-007 | Wave 1 |
| #976 | S | 不需要 | 無 | 無 | Wave 1 |
| #948 | S | 不需要 | 無 | 無 | Wave 2 |
| #955 | S | 不需要 | 無 | 無 | Wave 2 |

## 平行分群

> **SHIKIGAMI_MAX_PARALLEL=2**

**Wave 1（2 worktrees 平行）**：#977 (opus) + #976 (haiku)
**Wave 2（Wave 1 完成後）**：#948 (haiku) + #955 (haiku)
