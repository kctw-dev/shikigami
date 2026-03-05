# Sprint 48

**狀態**：進行中
**期間**：2026-03-05 ~ 2026-03-11
**Sprint Goal**：解決 ADR-013 高優先級開放問題（OQ-1、OQ-2），驗證 drawio-mcp-server stdio local 環境可行性，為 shikigami:diagram SKILL.md 實作（子 Story B）提供可信的技術基礎。
**總計**：1 Story / 1 Point

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | Phase | 狀態 |
|----------|---------|------|------|--------|-------|------|
| US-97 | #96 | shikigami:diagram 環境準備 — drawio-mcp-server stdio local 安裝與整合驗證 | S | 1 | Phase 1 | 進行中 |

**Sprint 容量**：1 Point

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1 | US-97 | 單一 Story，無並行需求 |

---

## Story 詳細 AC

---

### US-97：shikigami:diagram 環境準備 — drawio-mcp-server stdio local 安裝與整合驗證

**來源**：Issue #96（Issue #89 子 Story A）
**Size**：S / 1 Point
**Owner**：Developer
**QA doc-only 判定**：No（含動態驗證 AC4）
**前置 ADR**：ADR-013（Issue #95，已完成 Proposed）
**父 Issue**：#89（feat: shikigami:diagram 技能）

**User Story**

As a Developer subagent, I want drawio-mcp-server installed and verified in the local GCE environment via stdio transport, so that the technical unknowns (headless Chrome path, tool output format) are resolved before implementing the full shikigami:diagram skill.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | drawio-mcp-server 安裝 | `npx drawio-mcp-server@<pinned-version> --version`（或等效指令）在 GCE 開發機上執行成功，無錯誤 |
| AC2 | [靜態] | headless Chrome 安裝確認 | drawio-mcp-server 所需的 headless Chrome / Chromium 安裝於 GCE；安裝指令與版本記錄於本 Issue 或 ADR-013 Addendum |
| AC3 | [靜態] | .mcp.json stdio 設定 | `.mcp.json` 包含 drawio-mcp-server 的 stdio transport 設定（精確版號，非 `@latest`）；設定範例符合 ADR-013 §對 .mcp.json 的影響 |
| AC4 | [動態] | Claude Code ↔ MCP 通訊驗證 | `claude mcp list` 顯示 drawio-mcp-server 已連線；能呼叫至少一個 drawio-mcp-server tool 並收到回應（即使是簡單的 ping/list tools） |
| AC5 | [文件] | OQ-1 解決紀錄 | ADR-013 OQ-1 解答記錄：GCE headless Chrome 安裝方式與路徑確認（更新 ADR-013 或建立 Addendum） |
| AC6 | [文件] | OQ-2 解決紀錄 | ADR-013 OQ-2 解答記錄：drawio-mcp-server tool 輸出格式確認（檔案路徑 vs. Base64），並確認 ADR-006 XML 隔離標記的應用方式（更新 ADR-013 或建立 Addendum） |

**RICE 評分**

| 因子 | 分數 | 說明 |
|------|------|------|
| Reach | 2 | 影響所有後續 diagram 技能相關 Stories |
| Impact | 3 | 解鎖子 Story B/C 實作；OQ-1/OQ-2 若不解決將阻礙整個 #89 |
| Confidence | 0.8 | stdio 方案技術路徑成熟；headless Chrome 安裝為已知領域；主要不確定性為實際路徑確認 |
| Effort | 1 | S-size；環境安裝 + 驗證 + 文件記錄 |
| **RICE Score** | **4.8** | R×I×C/E |

**Done 定義**

- [ ] drawio-mcp-server 安裝成功（AC1）
- [ ] headless Chrome / Chromium 安裝確認（AC2）
- [ ] .mcp.json stdio 設定完成，精確版號鎖定（AC3）
- [ ] Claude Code ↔ MCP 通訊驗證通過（AC4）
- [ ] OQ-1 解答記錄完成（AC5）
- [ ] OQ-2 解答記錄完成（AC6）

---

## ADR 觸發清單

| Story | ADR | 觸發原因 | 動作 |
|-------|-----|----------|------|
| US-97 | ADR-013 | 實作結果需回填 OQ-1/OQ-2 答案至 ADR-013 | 更新 ADR-013 開放問題區塊（或建立 Addendum） |

---

## Issue #89 拆分說明

ADR-013 決定採用 stdio local 方案後，Issue #89 原始 AC（Cloud Run + HTTP+SSE）需全面改寫。拆分後的子 Story 序列：

| 子 Story | Issue | Size | 主要工作 | 狀態 |
|----------|-------|------|----------|------|
| 子 Story A（US-97） | #96 | S | 環境準備 + OQ-1/OQ-2 解決 | 本 Sprint |
| 子 Story B | 待建立 | M | SKILL.md 實作（雙格式輸出、--provider、ADR-006 XML 隔離） | 待子 Story A 完成後規劃 |
| 子 Story C | 待建立 | S | 文件整合（自動嵌入 Markdown、Issue 回覆附圖） | 待子 Story B 完成後規劃 |

原始 Issue #89 的 AC1（Cloud Run 部署）廢棄；AC2（.mcp.json）改寫為 stdio transport；AC3-AC6 保留至子 Story B/C。

---

## Sprint Planning 簽核記錄

| 角色 | 確認項目 | 狀態 |
|------|----------|------|
| Product Owner | Sprint Goal 對齊 ADR-013 開放問題解決，Backlog 拆分決策已記錄 | 已確認 |
| Architect | S-size 合理（環境安裝 + 驗證），ADR-013 OQ-1/OQ-2 解決路徑清晰 | 已確認 |
| QA | AC4 動態驗證可測試，AC5/AC6 文件 AC 有明確通過標準 | 已確認 |
| Developer | Story 清晰度確認 | 待確認 |

**Sprint Planning 決策記錄**

- Sprint 48 選入 1 Story（US-97 #96），共 1 Point
- Issue #89 依 ADR-013 決策拆分為 3 個子 Stories（A/B/C），本 Sprint 執行子 Story A
- 子 Story B/C 待子 Story A 完成後依序納入後續 Sprint
- 目標 Velocity：1 Point
