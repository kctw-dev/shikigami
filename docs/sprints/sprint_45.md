# Sprint 45

**狀態**：進行中
**期間**：2026-03-05 ~ 2026-03-11
**Sprint Goal**：完善多開發環境操作文件 — 建立 GCE 認證設定指引與 CI/CD workflow 拆分指引，讓多 GCE 平行開發流程可循、消費端 CI/CD 配置有據可依。
**總計**：2 Stories / 2 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | Phase | 狀態 |
|----------|---------|------|------|--------|-------|------|
| US-A | #87 | 多 GCE 認證設定指引 — 文件化各開發環境 OAuth 認證與使用紀律規範 | S | 1 | Phase 1（平行） | 待開發 |
| US-93 | #88 | CI/CD workflow 拆分指引 — GitHub-hosted tests + self-hosted notification trigger | S | 1 | Phase 1（平行） | 待開發 |

**Sprint 容量**：2 Points

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1（完全平行） | US-A、US-93 | 兩者均為獨立文件化工作，無相互依賴，可完全平行執行 |

**平行可行性判定**：Yes — 兩個 Story 均為文件化工作，無共享資源衝突，無執行順序限制。

---

## Story 詳細 AC

---

### US-A：多 GCE 認證設定指引 — 文件化各開發環境 OAuth 認證與使用紀律規範

**來源**：Issue #87（Sprint 43 US-90 精化子主題 A）；AC 依 ADR-012 後續行動（第 459–464 行）修訂
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes（建立 docs/ 下認證設定指引文件）
**ADR 參考**：ADR-012（選項 B：多 GCE 各自訂閱），ADR-011

**User Story**

As a Developer subagent, I want documented guidance for setting up Claude Max authentication on each GCE development machine and CI/CD pipeline, so that the team can follow a clear, ADR-012-compliant process for multi-environment development without manual intervention gaps.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | ADR-012 前置確認 | ADR-012 Status = Accepted，本 Story 實作與 ADR-012 選項 B 決策對齊，不實作帳號切換邏輯 |
| AC2 | [靜態] | GCE 認證設定流程文件 | `docs/` 下新增 GCE 認證設定指引，說明每台 GCE 透過 `claude auth login` 完成獨立 OAuth 認證的步驟 |
| AC3 | [靜態] | GitHub Secrets 設定驗證指引 | 文件包含 GitHub Repository Secret `ANTHROPIC_API_KEY` 設定步驟，確認 workflow YAML 以 `${{ secrets.ANTHROPIC_API_KEY }}` 注入 |
| AC4 | [靜態] | 使用紀律規範文件 | 文件包含使用紀律規範：平行獨立開發、不進行帳號輪換、配額耗盡即停原則 |
| AC5 | [靜態] | 認證資訊安全規範 | 文件明確聲明認證資訊（OAuth token、API Key）不得出現於版本控制追蹤的任何檔案中 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 2 | 影響所有使用多 GCE 開發環境的 Developer subagent |
| Impact | 2 | 文件化解決設定流程不透明問題，降低人工操作風險 |
| Confidence | 0.9 | ADR-012 決策明確，文件化工作無架構不確定性 |
| Effort | 0.5 | S-size；純文件化工作 |
| **RICE Score** | **7.2** | R×I×C/E |

**Done 定義**

- [ ] ADR-012 Status = Accepted 確認（AC1）
- [ ] GCE 認證設定流程文件建立於 `docs/` 下（AC2）
- [ ] GitHub Secrets 設定驗證指引完成（AC3）
- [ ] 使用紀律規範文件完成（AC4）
- [ ] 認證資訊安全規範聲明完成（AC5）

---

### US-93：CI/CD workflow 拆分指引 — GitHub-hosted tests + self-hosted notification trigger

**來源**：Issue #88（消費端 CI/CD 架構需求）；AC4 依 QA NEEDS_REVISION 修訂
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：Yes（建立 docs/ci-cd-guide/ 文件與 notify-comment.yml 模板）
**ADR 參考**：ADR-011（GitHub Actions 整合架構）

**User Story**

身為 Architect subagent 或消費端專案 SRE，我希望框架提供 CI/CD workflow 拆分指引（含模板與 deployment-readiness 偵測邏輯），區分 compute-heavy 任務應使用 GitHub-hosted runner、事件觸發任務應使用 self-hosted runner，以便消費端專案能解決 self-hosted runner OOM 問題，同時保留「Stakeholder 留言 → 本機 bash 觸發」的事件驅動能力。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|---------|
| AC1 | [靜態] | workflow 模板提供 | `docs/ci-cd-guide/notify-comment.yml` 新增（需建立子目錄），內容包含 issue_comment 事件觸發 + self-hosted runner 設定 |
| AC2 | [靜態] | 資源需求對照文件 | `docs/` 下新增或更新 CI/CD 指引文件，包含 GitHub-hosted vs self-hosted 適用場景對照表與決策樹 |
| AC3 | [靜態] | deployment-readiness 偵測邏輯 | `deployment-readiness` SKILL.md 新增 self-hosted runner 偵測步驟：當偵測到現有 workflow 全跑在 self-hosted 時，自動提示 CI/CD 拆分建議 |
| AC4 | [動態] | 模板 Placeholder 機制 | `notify-comment.yml` 複製至消費端專案 `.github/workflows/` 後，僅需替換 3 個 Placeholder（runner label、bash script 路徑、所需 token scope），其餘 workflow 結構無需修改即可觸發 issue_comment 事件並執行本機 bash |
| AC5 | [靜態] | ROADMAP/PROJECT_BOARD 更新 | ROADMAP.md 與 PROJECT_BOARD.md 標注本 Story 完成狀態 |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 2 | 影響使用 self-hosted runner 的消費端專案，非所有 Shikigami 使用者的通用需求 |
| Impact | 3 | 直接解決連續 11+ Sprint 的 CI 測試失敗 Retro Problem，痛點明確且持續 |
| Confidence | 0.8 | 方向清晰（模板 + 文件 + SKILL.md 更新），無架構層面風險，主要工作為撰寫 |
| Effort | 1 | S-size；workflow 模板撰寫 + 文件更新 + deployment-readiness SKILL.md 偵測邏輯補充 |
| **RICE Score** | **4.8** | R×I×C/E |

**Done 定義**

- [ ] `docs/ci-cd-guide/` 子目錄建立（AC1）
- [ ] `docs/ci-cd-guide/notify-comment.yml` 模板建立，含 issue_comment 觸發 + self-hosted 設定（AC1）
- [ ] CI/CD 指引文件包含 GitHub-hosted vs self-hosted 對照表與決策樹（AC2）
- [ ] `deployment-readiness` SKILL.md 新增 self-hosted runner 偵測步驟（AC3）
- [ ] `notify-comment.yml` 含 3 個明確 Placeholder，複製後零修改可觸發（AC4）
- [ ] ROADMAP.md 與 PROJECT_BOARD.md 完成狀態更新（AC5）

---

## ADR 觸發清單

| Story | ADR | 觸發原因 | 動作 |
|-------|-----|----------|------|
| US-A | ADR-012 | 前置 ADR，Status 需確認為 Accepted | 確認 ADR-012 Status，不新增 ADR |
| US-93 | 無 | 純文件化工作，無架構決策 | N/A |

---

## Sprint Planning 簽核記錄

| 角色 | 確認項目 | 狀態 |
|------|----------|------|
| Product Owner | Sprint Goal 對齊文件化工作性質（ADR-012 合規），兩 Story 優先級確認（RICE 7.2 / 4.8） | 已確認 |
| Architect | US-A S-size 降估（文件化，無實作），US-93 S-size 合理，兩者完全平行可行 | 已確認 |
| QA | Round 2 AC 修訂確認：US-A AC 對齊 ADR-012、US-93 AC4 Placeholder 機制明確、AC1 路徑更新 | 已確認 |
| Developer | Story 清晰度確認 | 待確認 |

**Sprint Planning 決策記錄**

- Sprint 45 選入 2 Stories（US-A #87、US-93 #88），共 2 Points
- Round 2 修訂原因：QA 判定兩者 NEEDS_REVISION（US-A 違反 ADR-012，US-93 AC4 邊界模糊）
- US-A 標題更新：移除「API Key Pool」，改為反映文件化工作性質
- US-A T-shirt 降估：M→S（Architect 判定純文件化工作）
- US-93 AC4 修訂：引入 3-Placeholder 機制，消除「零修改可用」歧義
- US-93 AC1 路徑修訂：`templates/` 改為 `docs/ci-cd-guide/notify-comment.yml`
- 兩 Story 完全平行，無依賴關係
- 目標 Velocity：2 Points
