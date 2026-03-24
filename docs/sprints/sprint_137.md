# Sprint 137

**Sprint Goal**：落地 Sprint 136 Retro Action Items（GAD Schema 範例 + CI 認證升級機制），並推進 ADR 先行工作——為 Kill Switch、Token Cost Routing、TCB 斷點管理三大功能奠定架構基礎。

**日期**：2026-03-24
**版本目標**：v0.92.0（minor bump，含 Retro Actions 落地 + ADR 三連發）

**容量**：6 pts（Velocity 基準 Sprint 134-136：7/6/6 pts，平均 6.3 pts，建議區間 6-7 pts）

---

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 | 獨立性 |
|-------|-------|------|--------|------|--------|
| retro: docs/schema/ 新增 GAD workflow JSON Schema Contract 範例檔案 | #617 | S | 1 | 已完成 (#623) | 獨立（docs/schema/examples/） |
| retro: CI 認證問題快速升級機制 | #616 | M | 2 | 已完成 (#627) | 獨立（.github/workflows/） |
| RESEARCH: ADR-038 — Kill Switch 架構決策 | #619 | S | 1 | 已完成 (#624) | 獨立（docs/adr/ADR-038） |
| RESEARCH: ADR-039 — Token Cost Routing 架構決策 | #620 | S | 1 | 已完成 (#625) | 獨立（docs/adr/ADR-039） |
| RESEARCH: ADR-040 — TCB 斷點管理架構決策 | #621 | S | 1 | 已完成 (#626) | 獨立（docs/adr/ADR-040） |

**Sprint 容量**：6 points

---

## 執行順序（SHIKIGAMI_MAX_PARALLEL=2）

```
Phase 1 Batch 1（平行）：#617 | #619
Phase 1 Batch 2（平行）：#620 | #621
Phase 2（序列）：#616（CI workflow，獨立執行確保 CI lint 驗證環境乾淨）
```

---

## 技術評估（Architect）

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | 說明 |
|-------|---------|---------|---------|-------------|------|
| #617 | S | 無需 ADR | 不適用 | — | doc-only，新增 JSON 範例，無架構涉及 |
| #616 | M | 無需 ADR | 不適用 | — | CI workflow 邏輯修改，無 API 互動 |
| #619 | S | 無需 ADR（本身即 ADR 研究） | 不適用 | — | RESEARCH，產出 ADR-038 |
| #620 | S | 無需 ADR（本身即 ADR 研究） | 不適用 | — | RESEARCH，產出 ADR-039 |
| #621 | S | 無需 ADR（本身即 ADR 研究） | 不適用 | — | RESEARCH，產出 ADR-040 |

---

## 驗收確認（QA）

| Story | AC 完整性 | 路徑驗證 | 結果 |
|-------|---------|---------|------|
| #617 | PASS（AC1-4） | docs/schema/README.md PASS | PASS |
| #616 | PASS（AC1-4） | .github/workflows/oauth-token-monitor.yml PASS | PASS |
| #619 | PASS（AC1-3） | 新建路徑（RESEARCH 產出） | PASS |
| #620 | PASS（AC1-3） | 新建路徑（RESEARCH 產出） | PASS |
| #621 | PASS（AC1-3） | 新建路徑（RESEARCH 產出） | PASS |

---

## Backlog 保留（等待 ADR 完成後升格）

| Issue | 標題 | 阻塞原因 |
|-------|------|---------|
| #398 | feat: Kill Switch — High 自治模式緊急停止 | 等待 ADR-038（#619）完成 |
| #402 | feat: Token Cost Routing — Risk-based Model 分級 | 等待 ADR-039（#620）完成 |
| #404 | feat: TCB 斷點管理 — Agent Action 級 Checkpoint | 等待 ADR-040（#621）完成 |
| #405 | feat: Temporal-style Crash Recovery | 等待 ADR + TCB (#404) 完成 |
| #408 | feat: Session Watchdog | 等待 ADR + Crash Recovery (#405) 完成 |
| #399 | research: A2A 協議相容性評估 | 等待 PB-2 + PB-5 完成 |
