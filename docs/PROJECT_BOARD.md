# Project Board

**最後更新**：2026-03-05（Sprint 50 Planning 完成）
**當前 Sprint**：Sprint 50（進行中）

工件導覽：[ROADMAP](prd/ROADMAP.md) → [Backlog](prd/PRODUCT_BACKLOG.md) → [Sprint 50](sprints/sprint_50.md) → 本看板 | [Tutorial](tutorial/README.md)

---

## Sprint 50 — 進行中

**Sprint Goal**：完成 shikigami:diagram 技能文件整合 — 補充自動嵌入 Markdown 步驟與 Issue 回覆附圖指引，使 diagram 技能達到完整可交付狀態，並關閉父 Issue #89。
**期間**：2026-03-05 ~ 2026-03-11

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-99（#98）：shikigami:diagram 文件整合 — 自動嵌入 Markdown、Issue 回覆附圖、關閉 #89 | S | 1 | 進行中 |

**目標 Velocity**：1 point（1 Story）

---

## Sprint 49 — 完成

**Sprint Goal**：實作 `shikigami:diagram` SKILL.md 核心功能 — 雙格式輸出、多圖標集切換、ADR-006 XML 隔離，讓 diagram 技能達到可執行狀態。
**結果**：Goal 達成（1/1 Stories PASS）。Velocity 2 points，完成率 100%。ADR-013 升級為 Accepted，SKILL.md 雙格式輸出路徑（.drawio MCP 操控 + PNG/SVG 手動匯出）在 v1.8.0 能力邊界內完整定義。
**Stakeholder 驗收**：接受
**期間**：2026-03-05 ~ 2026-03-11

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-98（#97）：shikigami:diagram SKILL.md 實作 — 雙格式輸出、--provider、ADR-006 XML 隔離 | M | 2 | 完成 |

**目標 Velocity**：2 points（1 Story）
**實際 Velocity**：2 points（1 Story）

---

## Sprint 48 — 完成

**Sprint Goal**：解決 ADR-013 高優先級開放問題（OQ-1、OQ-2），驗證 drawio-mcp-server stdio local 環境可行性，為 shikigami:diagram SKILL.md 實作提供可信的技術基礎。
**結果**：Goal 達成（1/1 Stories PASS）。Velocity 1 point，完成率 100%。AC4（claude mcp list 通訊驗證）標注「需手動驗證」，非阻斷。重要發現：v1.8.0 不需要 headless Chrome（內建 Web 編輯器），18 個 MCP tools 均回傳 type: "text" JSON。
**Stakeholder 驗收**：接受
**期間**：2026-03-05 ~ 2026-03-11

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-97（#96）：shikigami:diagram 環境準備 — drawio-mcp-server stdio local 安裝與整合驗證 | S | 1 | 完成 |

**目標 Velocity**：1 point（1 Story）
**實際 Velocity**：1 point（1 Story）

---

## Sprint 47 — 完成

**Sprint Goal**：為 shikigami:diagram 技能建立架構決策基礎 — 起草 ADR-013，評估 MCP 整合架構。
**結果**：Goal 達成（1/1 Stories PASS）。Velocity 1 point，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-03-05 ~ 2026-03-11

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-96（#95）：ADR-013 起草 — shikigami:diagram MCP 整合架構決策 | S | 1 | 完成 |

**目標 Velocity**：1 point（1 Story）
**實際 Velocity**：1 point（1 Story）

---

## Sprint 46 — 完成

**Sprint Goal**：確保多 GCE 開發架構穩定落地 — 建立版號三檔同步安全網，並完成開發環境可攜性與可重建性方案，讓多 GCE 平行開發流程具備足夠的操作一致性與防錯機制。
**結果**：Goal 達成（2/2 Stories PASS）。Velocity 3 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-03-05 ~ 2026-03-11

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-94（#94）：版號更新三檔同步 checklist 或自動化腳本 | S | 1 | 完成 |
| US-95（#90）：開發環境可攜性與可重建性 — 多 GCE 環境管理策略 | M | 2 | 完成 |

**目標 Velocity**：3 points（2 Stories）
**實際 Velocity**：3 points（2 Stories）

---

## Sprint 45 — 完成

**Sprint Goal**：完善多開發環境操作文件 — 建立 GCE 認證設定指引與 CI/CD workflow 拆分指引，讓多 GCE 平行開發流程可循、消費端 CI/CD 配置有據可依。
**結果**：Goal 達成（2/2 Stories PASS）。Velocity 2 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-03-05 ~ 2026-03-11

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-A（#87）：多 GCE 認證設定指引 — 文件化各開發環境 OAuth 認證與使用紀律規範 | S | 1 | 完成 |
| US-93（#88）：CI/CD workflow 拆分指引 — GitHub-hosted tests + self-hosted notification trigger | S | 1 | 完成 |

**目標 Velocity**：2 points（2 Stories）
**實際 Velocity**：2 points（2 Stories）

---

## Sprint 44 — 完成

**Sprint Goal**：建立多開發環境認證架構基礎 — 起草 ADR-012，確認 ToS 合規性與多 GCE 平行開發認證方案，為 Sprint 45 US-A 實作提供可信的架構前提。
**結果**：Goal 達成（1/1 Stories PASS）。Velocity 1 point，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-03-04 ~ 2026-03-10

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-92：ADR-012 起草 — Claude Max 多開發環境認證架構決策 | S | 1 | 完成 |

**目標 Velocity**：1 point（1 Story）
**實際 Velocity**：1 point（1 Story）

---

## Sprint 43 — 完成

**Sprint Goal**：為 Backlog 下一個發展方向奠定決策基礎：精化 #69（開發不中斷）為可執行 Story，並執行 M5 外部觸及效果最終診斷，確認對外最後一哩是否有可改善空白。
**結果**：Goal 達成（2/2 Stories PASS）。Velocity 3 points，完成率 100%。
**Stakeholder 驗收**：接受
**期間**：2026-03-04 ~ 2026-03-10

| Story | Size | Points | 狀態 |
|-------|------|--------|------|
| US-90：Issue #69 精化 — 「開發不中斷 營運不中斷」可行性分析與 Story 拆解 | S | 1 | 完成 |
| US-91：M5 條件 (a) 觸及診斷 — Outreach Log 審查 + 安裝阻力掃描 | M | 2 | 完成 |

**目標 Velocity**：3 points（2 Stories）
**實際 Velocity**：3 points（2 Stories）

---

## 短衝記錄

| 日期 | 標題 | Issue/Story | commit hash |
|------|------|-------------|-------------|
| 2026-03-05 | 流程缺陷：Framework Document 修改未經 ADR-003 審查即交付 | #91 | 2837d75 |
| 2026-03-05 | Agent 忽略使用者中途留言 — 缺乏即時回應機制 | #93 | e3f5071 |
| 2026-04-27 | 改善 sprint-N-replied label 機制為單一可重用 sprint-replied label | #66 | 7ce9c12 |
| 2026-04-27 | US-14 Notification Templates — PR/Deploy/Review 事件通知模板 | #63 | be133a5 |

---

> 歷史 Sprint 記錄：[PROJECT_BOARD_ARCHIVE](km/archive/PROJECT_BOARD_ARCHIVE.md)（Sprint 1–42）
