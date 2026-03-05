# Sprint 46

**狀態**：進行中
**期間**：2026-03-05 ~ 2026-03-11
**Sprint Goal**：確保多 GCE 開發架構穩定落地 — 建立版號三檔同步安全網，並完成開發環境可攜性與可重建性方案，讓多 GCE 平行開發流程具備足夠的操作一致性與防錯機制。
**總計**：2 Stories / 3 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | Phase | 狀態 |
|----------|---------|------|------|--------|-------|------|
| US-94 | #94 | 版號更新三檔同步 checklist 或自動化腳本 | S | 1 | Phase 1（平行） | 進行中 |
| US-95 | #90 | 開發環境可攜性與可重建性 — 多 GCE 環境管理策略 | M | 2 | Phase 1（平行） | 進行中 |

**Sprint 容量**：3 Points

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1（完全平行） | US-94、US-95 | 兩者無相互依賴，無檔案衝突，可完全平行執行 |

**平行可行性判定**：Yes — US-94 交付 `scripts/` 下腳本，US-95 交付 `docs/` 下文件與 MVP 實作，無共享資源衝突，無執行順序限制。

---

## Story 詳細 AC

---

### US-94：版號更新三檔同步 checklist 或自動化腳本

**來源**：Issue #94（Sprint 45 Retro Action Item #1，三檔同步教訓）
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：No（含動態 AC，需腳本執行驗證）
**ADR 參考**：無（S-size，無需 ADR，技術風險極低）

**User Story**

As a Developer subagent, I want a version-bump script that atomically updates all three version files in a single command, so that I can eliminate the risk of partial-update failures that caused CI Structural Validation failures in v0.28.1.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [動態] | `scripts/bump-version.sh` 主要交付物 | 執行 `bash scripts/bump-version.sh <version>`（格式：MAJOR.MINOR.PATCH）後，`.claude-plugin/plugin.json`、`.claude-plugin/marketplace.json`、`gemini-extension.json` 的 `version` 欄位均更新為指定版本 |
| AC2 | [動態] | 版本一致性驗證 | 執行 `bash scripts/validate-version.sh` 結果全部 PASS |
| AC3 | [動態] | 輸入格式防錯 | 輸入格式不符（非 MAJOR.MINOR.PATCH）時，腳本輸出明確錯誤訊息並以 exit 1 結束 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響所有版號更新操作，每次 Release 必經流程 |
| Impact | 3 | 直接消除 Sprint 45 Retro 識別的 CI 失敗根因，防止重複發生 |
| Confidence | 1.0 | 問題根因明確（三檔漏更新），技術方案無疑義 |
| Effort | 0.5 | S-size；腳本實作，無複雜架構 |
| **RICE Score** | **18.0** | R×I×C/E |

**Done 定義**

- [ ] `scripts/bump-version.sh` 建立並可執行（AC1）
- [ ] 執行腳本後三個檔案版號同步更新（AC1）
- [ ] `scripts/validate-version.sh` 執行全部 PASS（AC2）
- [ ] 非 MAJOR.MINOR.PATCH 格式輸入觸發 exit 1 並輸出錯誤訊息（AC3）

---

### US-95：開發環境可攜性與可重建性 — 多 GCE 環境管理策略

**來源**：Issue #90（US-90 精化後子主題，開發不中斷 · 營運不中斷方向）
**Size**：M / 2 Points
**Owner**：Developer
**QA doc-only 判定**：部分（AC1/AC3/AC4 為靜態文件；AC2 含 MVP 實作）
**ADR 參考**：ADR-012（Accepted，環境管理考量章節）；條件性 ADR-013（若選 Container-based/IaC 方向則觸發，本 Sprint scope 已排除）

**User Story**

As a Developer subagent operating across multiple GCE instances, I want a documented and implemented low-complexity environment portability strategy, so that I can rebuild a new GCE development environment from scratch and reach a fully operational state by following a single reference document, without tribal knowledge dependencies.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 方向選定文件 | 在 `docs/` 下新增 Markdown，評估四個候選方向（Dotfiles repo、GCE Snapshot、IaC、Container-based）後選定低複雜度方向（Dotfiles repo 或 GCE Snapshot 擇一），包含選定理由與排除替代方向的理由；IaC/Container-based 不進入本 Sprint scope |
| AC2 | [動態] | MVP 實作 | 依選定方向（限 Dotfiles repo 或 GCE Snapshot）完成最小可行實作（腳本/設定檔/操作步驟） |
| AC3 | [靜態] | 環境重建流程文件 | 新 GCE 從零到可開發的完整步驟；最低成功條件：依文件執行後能成功 clone repo、執行 git hooks、執行 `scripts/validate-version.sh` 取得 PASS；可引用現有 `docs/gce-auth-guide.md` 作為認證章節基礎 |
| AC4 | [靜態] | ADR-012 對齊確認 | 實作方向與 ADR-012 §環境管理考量一致，文件明確引用 ADR-012 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 3 | 影響所有需在多 GCE 環境間切換的 Developer subagent |
| Impact | 2 | 解決環境重建無據可依的問題，降低開發中斷風險 |
| Confidence | 0.8 | 方向明確（低複雜度），ADR-012 提供架構前提，主要工作為文件化與 MVP 實作 |
| Effort | 2 | M-size；文件撰寫 + MVP 實作 |
| **RICE Score** | **2.4** | R×I×C/E |

**Done 定義**

- [ ] `docs/` 下新增方向選定 Markdown，含四方向評估與選定理由（AC1）
- [ ] 低複雜度方向 MVP 實作完成（腳本/設定檔/操作步驟）（AC2）
- [ ] 環境重建流程文件完成，涵蓋 clone repo、git hooks、validate-version.sh PASS（AC3）
- [ ] 文件明確引用 ADR-012，與 §環境管理考量對齊（AC4）

---

## ADR 觸發清單

| Story | ADR | 觸發原因 | 動作 |
|-------|-----|----------|------|
| US-94 | 無 | S-size 腳本實作，技術風險極低，無架構決策 | N/A |
| US-95 | ADR-012 | 前置 ADR，Status 已 Accepted，環境管理考量為本 Story 架構前提 | 確認 ADR-012 Status，不新增 ADR |
| US-95 | ADR-013（條件性） | 若選 Container-based/IaC 方向則觸發 | 本 Sprint scope 已排除，不觸發 |

---

## Sprint Planning 簽核記錄

| 角色 | 確認項目 | 狀態 |
|------|----------|------|
| Product Owner | Sprint Goal 對齊多 GCE 架構穩定落地，兩 Story 優先級確認（RICE 18.0 / 2.4），防漂移確認 | 已確認 |
| Architect | US-94 S-size 合理（腳本實作，無 ADR），US-95 M-size 合理（ADR-012 Accepted，條件性 ADR-013 本 Sprint 排除），兩者完全平行可行 | 已確認 |
| QA | Round 2 AC 修訂確認：US-94 三個動態 AC 含 exit 1 防錯機制、US-95 方向鎖定低複雜度（Dotfiles repo 或 GCE Snapshot）、AC3 最低成功條件明確 | 已確認 |
| Developer | Story 清晰度確認 | 待確認 |

**Sprint Planning 決策記錄**

- Sprint 46 選入 2 Stories（US-94 #94、US-95 #90），共 3 Points
- Round 2 修訂說明：QA 修訂 US-94 AC3 加入 exit 1 防錯機制；US-95 方向鎖定為低複雜度（排除 IaC/Container-based），AC3 明確最低成功條件
- Sprint 45 Retro Action Item #1（#94）已納入本 Sprint 處理
- 兩 Story 完全平行，無依賴關係，無檔案衝突
- 目標 Velocity：3 Points
