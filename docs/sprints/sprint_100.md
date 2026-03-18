# Sprint 100

**Sprint Goal**：強化框架執行可靠性與 Anti-Hallucination 能力 — 補齊 story-lifecycle-prompt.md 執行漏洞（git commit 缺失、測試批量修復）、KM 文件 API 參數腦補防護、Sprint Planning 並行衝突修復、CI workflow 最佳實踐
**日期**：2026-03-18
**容量**：6 points
**狀態**：進行中

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：Story-Lifecycle subagent 完成後強制 git commit Hard Gate | #307 | S | 1 | 完成 |
| FEATURE：story-lifecycle-prompt: 測試修復批量執行策略 | #304 | S | 1 | 完成 |
| FEATURE：KM 第三方 API 文件驗證機制 — 禁止腦補 enum 值 | #276 | M | 2 | 完成 |
| INFRA：Bug：Sprint Planning 多 session 並行編號衝突修復 | #277 | S | 1 | 完成 |
| INFRA：CI/CD: 所有 workflow 加入 cancel-in-progress | #306 | S | 1 | 完成 |

## Acceptance Criteria

### US-272 — INFRA #307：Story-Lifecycle subagent 完成後強制 git commit Hard Gate

**AC-1：Hard Gate 強制 commit**
- story-lifecycle-prompt.md 完成步驟加入 Hard Gate：subagent 完成開發後必須執行 `git add` + `git commit`
- 完成後 `git status -s` 無 unstaged 改動（排除 untracked 檔案）

**AC-2：失敗處理**
- git commit 失敗時（如 pre-commit hook 失敗），subagent 須輸出錯誤訊息並上報主 session
- 錯誤訊息須包含失敗原因與影響範圍

**AC-3：commit message 格式**
- commit message 須符合 Conventional Commits 格式（`feat:/fix:/chore:` + Story ID）

**非功能屬性**
- 不得增加 subagent 平均執行時間超過 30 秒

### US-273 — FEATURE #304：story-lifecycle-prompt: 測試修復批量執行策略

**AC-1：批量修復策略**
- story-lifecycle-prompt.md 測試修復階段明確指示：先分析所有失敗測試，再批量修復，禁止逐個修復逐個全量驗證
- 批量修復後統一執行一次全量測試驗證

**AC-2：效率提升**
- 避免 N 次失敗產生 N 次全量測試的 O(N²) 行為

### US-274 — FEATURE #276：KM 第三方 API 文件驗證機制 — 禁止腦補 enum 值

**AC-1：強制來源標注**
- KM 文件中涉及第三方 API 的 enum 值、參數範圍、回傳格式，必須標注來源（官方文件 URL 或版本號）
- 無來源標記的 enum 值，品質門禁應報 WARN

**AC-2：Enum 完整性檢查**
- KM 文件中的 enum 列舉須標注「完整列舉」或「部分列舉（截至 YYYY-MM-DD）」
- 禁止在無來源佐證下自行推斷 enum 值

**AC-3：驗收測試**
- KM 文件中的 enum 若無來源標記，品質門禁應報 WARN（可驗證）

**非功能屬性**
- 驗證機制不得阻斷非第三方 API 類的 KM 文件寫入
- 實作方向：「強制來源標注 + Enum 完整性檢查」兩項，Specialist Review 可後續迭代

### US-275 — INFRA #277：Bug：Sprint Planning 多 session 並行編號衝突修復

**AC-1：並行衝突防護**
- Sprint Planning 流程加入 git pull + 檔案存在性檢查 + 自動遞增機制
- 多 session 同時執行 Sprint Planning 時，不會產生重複編號

**AC-2：regression 驗收**
- 並行衝突時輸出 WARN 日誌，告知操作者發生衝突並已自動處理

**非功能屬性**
- 不得增加 Sprint Planning 正常流程（無衝突時）延遲

### US-276 — INFRA #306：CI/CD: 所有 workflow 加入 cancel-in-progress

**AC-1：cancel-in-progress 設定**
- 所有 `.github/workflows/*.yml` 加入 `concurrency` 設定，同分支重複觸發時自動取消舊的 run
- 設定 `cancel-in-progress: true`

**AC-2：完整覆蓋**
- 所有現有 workflow 均已套用，無遺漏

## 技術評估摘要

- **Architect 評估**：所有 Stories 不需 ADR
- **方法論**：US-272/273/274/275 建議 BDD；US-276 不適用
- **Refinement**：全部 READY

## QA 驗收確認摘要

- **US-272**：CONDITIONAL → 已補充失敗處理 AC + commit message 格式 + 非功能屬性
- **US-273**：PASS
- **US-274**：CONDITIONAL → 已確認實作方向 + 補充驗收測試手段 + 非功能屬性
- **US-275**：CONDITIONAL → 已確認修正方案 + 補充 regression 驗收 + 非功能屬性
- **US-276**：PASS
- **防漂移基準**：5 Stories, 6 pts

## 平行分群建議

| Phase | 分群 | Stories | 理由 |
|-------|------|---------|------|
| Phase 1 | Group A（串行） | #307 → #304 | 同檔案 story-lifecycle-prompt.md，須串行避免衝突 |
| Phase 1 | Group B（平行） | #306 | CI workflow 獨立作業，可與 Group A 平行 |
| Phase 2 | Group C（平行） | #277 | Sprint Planning 流程修改，Phase 1 完成後執行 |
| Phase 2 | Group D（平行） | #276 | KM 驗證機制，與 Group C 平行 |

Phase 1 與 Phase 2 序列執行；同 Phase 內各 Group 可平行。
