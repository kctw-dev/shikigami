# Preflight Check 與 Hard Gate

<!-- 本檔案由 scrum-master/SKILL.md §9 拆出，主文件以指針引用 -->

## 9. Preflight Check 與 Hard Gate

框架文件修改、Sprint 外變更、儀式完整性的品質稽核機制。依 ADR-003（分級介入模式）實作。

> **ADR-003 場景覆蓋說明**：ADR-003 定義四個稽核場景，其中三個 Hard Gate 於本節實作（9.1–9.3）。第四個場景 Story Completion DoD Audit 為 Soft Gate，已委由 `quality-gate` Skill 處理，不在本節重複定義。

### 9.1 Preflight Check：Framework Document Change Audit

<HARD-GATE>
框架文件（`skills/`、`commands/`、`agents/` 下任一 `.md` 檔案）修改前，必須通過以下 4 項二元 checklist。全部 Pass 方可繼續，任一 Fail 則阻塞修改。
</HARD-GATE>

**觸發條件**：`skills/`、`commands/`、`agents/` 下任一 `.md` 檔案即將被修改

**Checklist（二元判定）**：

| # | 檢查項 | 判定 |
|---|--------|------|
| 1 | 修改目的對應 Sprint Backlog 中的某個 Story ID | [ ] |
| 2 | 修改範圍在該 Story 的 AC 所涵蓋文件範圍內 | [ ] |
| 3 | 修改前已讀取目標文件的當前版本 | [ ] |
| 4 | 修改後執行 health-check 確認結構完整性 | [ ] |

**結果判定**：
- 全部 Pass → 繼續修改
- 任一 Fail → 阻塞，修復後重新稽核

**規格來源**：ADR-003「Framework Document Change Audit」

> **Bootstrap 豁免**：本規則自 Sprint 6（US-FIX-02）引入。引入本身的框架文件修改不適用回溯稽核，但後續對本文件的修改須遵循上述 checklist。

### 9.2 Out-of-Sprint Change Audit

<HARD-GATE>
Sprint 期間偵測到 Sprint Backlog 無對應項目的框架文件修改時，必須走以下路徑之一。不得在無對應 Story 的情況下逕行修改框架文件。
</HARD-GATE>

**觸發條件**：Sprint 期間發生非 Sprint Backlog 範圍的框架文件修改

**正常路徑**：

修改必須對應現有 Backlog Story。若無對應 Story，必須先由 PO 建立緊急 Story 並核准後方可繼續修改。

**緊急例外路徑**（僅限安全漏洞或框架破損）：

| # | 步驟 | 說明 |
|---|------|------|
| 1 | `[EMERGENCY]` 標注 | commit message 必須標注 `[EMERGENCY]` 並記錄緊急變更原因 |
| 2 | 48 小時事後稽核 | 48 小時內完成事後稽核，確認變更合理性 |
| 3 | Retrospective 追蹤 | 於下次 Sprint Review 將此事件列入 Retrospective Problem 追蹤 |

**規格來源**：ADR-003「Out-of-Sprint Change Audit」

### 9.3 Ceremony Integrity Audit

<HARD-GATE>
Sprint Planning 與 Sprint Review 儀式結束前，必須通過各自的完整性 checklist。任一項未完成則儀式不得宣告結束。
</HARD-GATE>

**觸發條件**：Sprint Planning 或 Sprint Review 宣告結束前

**Sprint Planning 必要條件（4 項）**：

| # | 檢查項 | 判定 |
|---|--------|------|
| 1 | Sprint Goal 已定義 | [ ] |
| 2 | Sprint Backlog 已選取並完成 Story 點數估算 | [ ] |
| 3 | 所有 Story 有明確 Acceptance Criteria | [ ] |
| 4 | GitHub open issues 已掃描 | [ ] |

**Sprint Review 必要條件（5 項）**：

| # | 檢查項 | 判定 |
|---|--------|------|
| 1 | PO Demo 已完成 | [ ] |
| 2 | Stakeholder 已確認 | [ ] |
| 3 | Retrospective_Log.md 已更新 | [ ] |
| 4 | Action Items 已建立 | [ ] |
| 5 | ROADMAP.md 已更新 | [ ] |

**結果判定**：全部勾選 → 儀式可結束；任一未完成 → 阻塞，補齊後方可結束

**規格來源**：ADR-003「Ceremony Integrity Audit」
