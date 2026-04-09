# Sprint 180

**Sprint Goal：將 ADR-045 short-lived subagent 從 PoC 模擬升級為 sprint-execution task-list-init 步驟的真實整合，同步補完 Sprint 179 Retro Action Items 的可觀測性與文件缺口**

**開始日期**：2026-04-09
**結束日期**：2026-04-16
**容量**：6 pts
**Velocity 基準**：avg 6 pts（Sprint 177=6, Sprint 178=6, Sprint 179=6）

---

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 | 負責 | Routing Tier |
|-------|-------|------|--------|------|------|-------------|
| retro: sprint-execution 整合 short-lived subagent — ADR-045 落地第一步 | #983 | M-L | 3 | DONE | PR#985 | sonnet（Score 9, FEAT） |
| retro: backlog 水位趨勢腳本整合至自動化報告 | #982 | S | 1 | TODO | - | haiku（Score 5, FEAT） |
| retro: 建立 hooks 架構說明文件 — hook-runner.sh 使用時機指南 | #984 | S | 1 | TODO | - | haiku（Score 4, DOC） |
| retro: TDD 外部工具模擬最佳實踐指南 — fake binary vs PATH 清空陷阱 | #953 | S | 1 | TODO | - | haiku（Score 4, DOC） |

**總計**：4 Stories / 6 pts

---

## 驗收標準摘要

### #983 retro: sprint-execution 整合 short-lived subagent — ADR-045 落地第一步（Sprint 180 修訂版）

- **AC-1：Task List 初始化整合為 short-lived subagent**
  - 將 sprint-execution §3「Task List 初始化」節點從主 session 直接執行，改為派遣獨立 step subagent
  - PoC (`scripts/state-machine/step-subagent-poc.sh`) 從模擬升級為真實派遣（或保留 `--mode=simulate` 測試旗標）
  - 結果 JSON 契約遵循 ADR-045 §3：`{ step_name, status, output_artifacts, duration_ms, error }`
- **AC-2：規則佔比測量（機制可跑，非衰減指標）**
  - 新增 `scripts/state-machine/rule-ratio-measure.sh`：
    - 輸入：prompt 檔案路徑
    - 輸出：JSON `{ rule_tokens, total_tokens, ratio, passed }`
    - 規則區塊識別：prompt 模板中 `## 規則片段` … `## 輸入契約` 之間為規則
    - Token 估算方案：字元數 / 4（英文）、字元數 / 1.5（中文），零依賴
  - task-list-init subagent prompt 的規則佔比 >= 10%
  - PR CI 驗證（或 `tests/test-step-subagent.sh` 手動驗證）
- **AC-3：軟性觀察指標（非 DoD blocker）**
  - Sprint Review 記錄 task-list-init 步驟的實際派遣次數
  - 記錄任何觀察到的「規則忽略事件」作為 ADR-045 後續 trending 數據
  - 不作為 Story PASS/FAIL 判定標準（樣本量不足以統計驗證）
- **AC-4：契約文件**
  - 新增 `skills/sprint-execution/references/step-subagent-contract.md`：
    - Prompt 模板規範（規則片段 / 輸入契約 / 輸出契約 / 成功失敗判定 四區塊）
    - 結果 JSON 契約
    - 後續步驟擴充指引
- **NFR1**：向後相容 — PoC 保留 `--mode=simulate` 作為測試旗標，`tests/test-step-subagent-poc.sh` 不應 break
- **NFR2**：失敗處置 — step subagent 派遣失敗時，主 session 可讀取 progress tracker 的失敗記錄並決定後續（retry or escalate）
- **NFR3**：規則佔比腳本零依賴（只用 bash + 基本工具，不需 python tiktoken）

### #982 retro: backlog 水位趨勢腳本整合至自動化報告
- AC-1：趨勢摘要整合至自動化報告（`check-backlog-health.sh` 輸出或 cruise report）
- AC-2：無需手動執行 `show-backlog-water-trend.sh` 即可看到最近趨勢

### #984 retro: 建立 hooks 架構說明文件 — hook-runner.sh 使用時機指南
- AC-1：新增 `hooks/README.md` 或 `docs/adr/` 相關說明，包含決策規則（何時用 hook-runner.sh、何時直接執行）
- AC-2：#955 評估結論納入文件，作為未來類似評估的參考範例

### #953 retro: TDD 外部工具模擬最佳實踐指南 — fake binary vs PATH 清空陷阱
- AC-1：在 `docs/km/` 或 `docs/guides/` 建立 `tdd-external-tool-mocking.md`，說明正確的外部工具模擬方式（fake binary in TMPBIN）
- AC-2：文件包含反例（`PATH=/nonexistent`）與正例（fake binary）

---

## 技術評估摘要

| Story | T-shirt | ADR | Schema Contract | Related SDDs | 平行分群 |
|-------|---------|-----|----------------|-------------|---------|
| #983 | M-L | ADR-045（延續） | step subagent 結果 JSON 契約 | 參考 ADR-007 | Wave 1（獨占）|
| #982 | S | 不需要 | 無 | 無 | Wave 2 |
| #984 | S | 不需要 | 無 | 無 | Wave 2 |
| #953 | S | 不需要 | 無 | 無 | Wave 3 |

### Wave 規劃說明

- **Wave 1（獨占）**：#983 修改 coordinator-only 檔案（`skills/sprint-execution/SKILL.md`、`scripts/state-machine/*`），不可與其他 Story 平行 worktree，避免衝突。
- **Wave 2（2 worktrees 平行）**：#982 + #984 — 兩者修改範圍互不重疊（#982 動 `scripts/check-backlog-health.sh` 與 cruise report，#984 新建 `hooks/README.md`）。
- **Wave 3**：#953 獨立文件新建（`docs/km/tdd-external-tool-mocking.md`），可於 Wave 2 完成後接續。

## 平行分群

> **SHIKIGAMI_MAX_PARALLEL=2**

**Wave 1（獨占）**：#983 (sonnet)
**Wave 2（2 worktrees 平行）**：#982 (haiku) + #984 (haiku)
**Wave 3**：#953 (haiku)

## Risk Notes

- **#983 M-L Story 佔 50% 容量**：3 pts 單一 Story，若 task-list-init 整合遇阻礙影響大 → 緩解：Scope Buffer 允許規則佔比量測腳本降級為 v0（手動跑），自動化整合排 Sprint 181。
- **#983 coordinator-only 檔案獨占**：與其他 Story 平行會衝突 → 緩解：排入 Wave 1 獨占執行。
- **#983 軟性指標無 PASS/FAIL**：AC-3 僅作為觀察記錄 → 緩解：AC-1/AC-2/AC-4 為可立即驗證的交付物，DoD 以這三項為準。
