# Sprint 28

**狀態**：進行中
**期間**：2026-03-02 ~ 2026-03-08
**Sprint Goal**：完成 OpenCode 平台五角色 subagent 模型（US-49）與外部使用者安裝指南（US-50），同步推進 Task tool 動態驗證結論（US-51），使 Issue #3 進入可結案狀態
**總計**：3 Stories / 4 Points

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | QA doc-only 判定 | 狀態 |
|----------|------|------|--------|-----------------|------|
| US-49 | OpenCode Phase 3a — 剩餘四個角色 Agent 移植 | S | 1 | No | 完成 |
| US-50 | OpenCode Phase 3b — INSTALL_OPENCODE.md 安裝指南 | S | 1 | No | 完成 |
| US-51 | OpenCode Phase 3c — Task Tool 參數確認與 Developer dispatch 動態驗證 | M | 2 | No | 完成 |

**Sprint 容量**：4 Points

---

## Story 詳細 AC

---

### US-49：OpenCode Phase 3a — 剩餘四個角色 Agent 移植

**來源**：US-48 Phase 2 移植模式驗證完成 / OPENCODE_POC.md Phase 3 定義
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As a Product Owner targeting OpenCode platform expansion, I want the remaining four Shikigami roles ported to OpenCode subagent format, so that the full five-role agent model is available on the OpenCode platform and Issue #3 can move toward resolution.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 四角色設定檔建立 | `.opencode/agents/` 下新建四個角色設定檔：`architect.md`、`product-owner.md`、`qa-engineer.md`、`security-engineer.md`（注：Scrum Master 為主 session 編排者，非被派遣 subagent，不需 agent 設定檔） |
| AC2 | [靜態] | 設定檔格式完整性 | 每個檔案包含 YAML frontmatter（name、description、model）+ Markdown body（角色 prompt 正文） |
| AC3 | [靜態] | 內容來源一致性 | 內容來源自各角色對應的 `SKILL.md` 或 `skills/` 目錄下既有 prompt 檔案（如 `spec-reviewer-prompt.md`、`quality-reviewer-prompt.md`）；無獨立 prompt 檔的角色（architect、product-owner、security-engineer）從對應 `SKILL.md` 提取角色定義作為 system prompt |
| AC4 | [靜態] | OPENCODE_POC.md §9 Phase 3a 子章節 | `docs/km/OPENCODE_POC.md` §9 新增 Phase 3a 子章節，記錄四角色遷移稽核 |
| AC5 | [靜態] | AGENTS.md 更新 | `AGENTS.md` 更新，列出全部 5 個 OpenCode agent 設定檔 |

---

### US-50：OpenCode Phase 3b — INSTALL_OPENCODE.md 安裝指南

**來源**：M5 條件 (a) 外部使用者觸及 / ADR-008 決策一
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As an external user who wants to adopt Shikigami on OpenCode, I want a clear installation guide documenting prerequisites, setup steps, and a quick-start Sprint walkthrough, so that I can successfully configure and run Shikigami on OpenCode without needing to read internal architecture documents.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | INSTALL_OPENCODE.md 建立 | 新建 `docs/INSTALL_OPENCODE.md`，包含前置需求、安裝步驟、首次 Sprint 快速上手指引 |
| AC2 | [靜態] | ADR-008 引用 | 安裝指南引用 ADR-008 決策一的 symlink 設定方式 |
| AC3 | [靜態] | README.md 新增章節 | `README.md` 新增 OpenCode 安裝章節，連結至 `docs/INSTALL_OPENCODE.md` |
| AC4 | [靜態] | OPENCODE_POC.md §9 Phase 3b 子章節 | `docs/km/OPENCODE_POC.md` §9 新增 Phase 3b 子章節，記錄指南建立 |

---

### US-51：OpenCode Phase 3c — Task Tool 參數確認與 Developer dispatch 動態驗證

**來源**：US-48 Phase 2 完成 / Issue #3 結案評估需求
**Size**：M / 2 Points
**Owner**：Developer

**User Story**
As a Product Owner evaluating Issue #3 closure, I want a structured analysis of the Task tool parameter mapping between Claude Code Agent tool and OpenCode Task tool, and a verification record of Developer subagent dispatch behavior, so that the team has the technical evidence needed to assess M5 condition (a) and make a final Issue #3 closure decision.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | OPENCODE_POC.md §9 Phase 3c 子章節 | `docs/km/OPENCODE_POC.md` §9 新增 Phase 3c 子章節，記錄 Task tool 參數對應分析（Claude Code Agent tool → OpenCode Task tool） |
| AC2 | [靜態] | 參數比較表 | 參數比較表：supported / unsupported / equivalent，每列標注來源依據 |
| AC3 | [動態/降級可靜態] | Developer dispatch 驗證記錄 | 若 OpenCode 實機環境可用：執行 Developer subagent dispatch 並以文字敘述 + 結構化記錄方式記載結果。若不可用：基於設定檔分析記錄預期行為，標注「pending dynamic verification」 |
| AC4 | [靜態] | Issue #3 結案評估 | Issue #3 結案評估：參照 `docs/prd/ROADMAP.md` M5 條件 (a) 定義，列出達成路徑剩餘步驟 |

---

## 平行分群（Architect 建議）

### Phase 1 — 全部平行執行（OPENCODE_POC.md §9 寫入序列化）

| 群組 | Stories | 說明 |
|------|---------|------|
| Phase 1 | US-49、US-50、US-51（全部平行） | 三個 Story 無強制序列依賴，可平行執行；但 `docs/km/OPENCODE_POC.md` §9 的寫入操作需序列化（US-49 Phase 3a → US-50 Phase 3b → US-51 Phase 3c），避免同檔案衝突 |

**執行順序說明**：
- US-49、US-50、US-51 主體工作可平行執行（各自操作不同目錄/檔案）
- `OPENCODE_POC.md` §9 子章節寫入遵循順序：Phase 3a（US-49 AC4）→ Phase 3b（US-50 AC4）→ Phase 3c（US-51 AC1~AC4）
- Architect 評估：US-49 S/1pt 確認，無 ADR 需求；US-50 S/1pt 確認，ADR-003 NOT triggered for README.md；US-51 M/2pt 確認，AC3 靜態降級建議

---

## 工作容量

| 項目 | 數值 |
|------|------|
| Sprint 期間 | 2026-03-02 ~ 2026-03-08（7 天） |
| 總 Stories | 3 |
| 總 Points | 4 |
| 平行分群 | Phase 1（US-49、US-50、US-51 全部平行；OPENCODE_POC.md §9 序列化寫入） |

---

## ADR 觸發清單

| Story | ADR 編號 | 說明 |
|-------|----------|------|
| US-49 | 無 | S size，無架構決策需求 |
| US-50 | 無 | ADR-003 NOT triggered（README.md 為說明文件，非 SKILL.md 框架文件） |
| US-51 | 無 | 分析與記錄任務，無架構決策 |

**本 Sprint 無新建 ADR。**

---

## Sprint Planning 簽核

- **PO Round 1**：完成（Story 選取：US-49 S/1pt + US-50 S/1pt + US-51 M/2pt；Sprint Goal 確定；總計 4pt）
- **Architect Round 1**：完成（US-49 S/1pt 確認，無 ADR；US-50 S/1pt 確認，ADR-003 NOT triggered；US-51 M/2pt 確認，AC3 靜態降級建議；平行分群：Phase 1 全部平行，OPENCODE_POC.md §9 序列化）
- **QA Round 1**：完成（US-49 PASS（含 AC1/AC3 修正）；US-50 PASS；US-51 PASS（含 AC4/AC3 修正）；全部 Stories doc-only 判定：No）
- **PO Round 2**：完成（整合 Architect/QA 反饋；AC 最終版確認；Sprint Backlog 最終確認）
