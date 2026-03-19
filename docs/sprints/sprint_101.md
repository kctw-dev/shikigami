# Sprint 101

**Sprint Goal**：落地多 Session 並行協調機制，防止跨 session 重複領取 Issue/Story
**日期**：2026-03-19
**容量**：2 points
**狀態**：完成

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：多 Session 並行開發 — Issue/Story 級別協調機制 | #312 | M | 2 | 完成 |

## Acceptance Criteria

### US-312 — INFRA #312：多 Session 並行開發 — Issue/Story 級別協調機制

**AC-1：Claim 取得機制**
- `git push refs/claims/<id>` 成功取鎖
- 已占用回 `[CLAIM-BLOCKED]`

**AC-2：Claim 釋放機制**
- SessionEnd hook 自動 release，輸出 `[CLAIM-RELEASE]`

**AC-3：本地鎖原子性**
- `flock` + lock file 保證同機器原子操作

**AC-4：GitHub Issue 展示層**
- claim 後 assign + label；release 時移除

**AC-5：gh CLI 降級容錯**
- gh 不可用輸出 WARN，不阻塞

**AC-6：Hook 失敗不阻塞**
- session-end-release.sh 失敗不影響 session

**AC-7：可觀測標記**
- 輸出 `[CLAIM-OK]` / `[CLAIM-RELEASE]` / `[CLAIM-BLOCKED]`

**AC-8：Skill 文件更新**
- 4 個 SKILL.md + po-prompt.md 均含 claim 指引

**AC-9：測試腳本通過**
- `tests/test-claim-mechanism.sh` 三路徑全 PASS

**非功能屬性**
- NFR1：hook 失敗不阻塞
- NFR2：標準化標記輸出（`[CLAIM-OK]` / `[CLAIM-RELEASE]` / `[CLAIM-BLOCKED]`）
- NFR3：gh CLI 降級容錯

## 技術評估摘要

- **Architect 備注**：flock macOS 需 fallback（mkdir 原子操作）；SessionEnd crash 不保證觸發，需 stale lock 偵測
- **方法論**：TDD
- **Refinement**：READY

## QA 驗收確認摘要

- **US-312**：PASS — 9 AC 全數可驗證
- **防漂移基準**：1 Story, 2 pts

## 平行分群建議

| Phase | 分群 | Stories | 理由 |
|-------|------|---------|------|
| Phase 1 | Group A | #312 | 單一 Story，無需分群 |

## Sprint Review 最終驗收

**日期**：2026-03-19
**外部審查結果**：DISPUTE（第一輪，4 缺陷）→ 修復後 CONFIRM（第二輪）
**測試**：26/26 PASS
**驗證腳本**：全部通過
**Stakeholder 驗收**：接受

### QA 邊界測試（Sprint Review §2.2）

| 測試項目 | 結果 |
|---------|------|
| claim-issue.sh 無參數時正確 exit 1 + WARN | PASS |
| release-issue.sh 對不存在 ref 容錯，exit 0 | PASS |
| session-end-release.sh CLAUDE_SESSION_ID=unknown 時略過 release | PASS |
| hooks.json SessionEnd 配置正確（async: true） | PASS |

**最終狀態**：完成（PASS）— bump v0.73.0
