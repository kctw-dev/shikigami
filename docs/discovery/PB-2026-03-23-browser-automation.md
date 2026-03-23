# Product Brief：QA/UX/SRE Browser Automation — Playwright MCP 整合

**狀態**：草稿
**來源**：#271 gstack vs Shikigami 競品分析 §5.1
**日期**：2026-03-23

---

## 1. 問題陳述

QA Engineer、UX Designer、SRE Engineer 三個角色缺乏「看得到畫面」的能力。無法做視覺驗證、smoke test、responsive 截圖比對。目前 QA Gate 只有「tests GREEN」，看不到實際畫面。

## 2. 目標使用者

- QA Engineer — 視覺 QA 測試（截圖 + DOM diff）
- UX Designer — CSS property 驗證、responsive 截圖
- SRE Engineer — 部署後 smoke test

## 3. 商業假設

- [UNCERTAIN] 假設：Playwright MCP 延遲可接受（< 5 秒/操作）— 驗證方法：PoC 實測
- [UNCERTAIN] 假設：截圖 + Vision Critic 組合能有效判斷 UI 品質 — 驗證方法：與人工 review 對比
- [UNCERTAIN] 假設：Playwright MCP 在 self-hosted runner 環境可用 — 驗證方法：CI 環境測試

## 4. 提案解決方向

| 方案 | 描述 | 優缺點 |
|------|------|--------|
| **C. Playwright MCP（推薦）** | 用已有的 Playwright MCP server 整合 | 原生整合、無外部依賴、但沒有 daemon 持久化 |
| B. gstack browse binary | 取 gstack 的 browse 二進位 | 有 daemon 持久化，但綁定 Bun 依賴 |
| D. 自建 Browser Skill | 參考 gstack 自建 | 完全控制，但開發成本高 |

## 5. 成功指標

| 指標 | 目標 |
|------|------|
| QA 可截圖並對比 Figma | 能力具備 |
| SRE smoke test 自動化 | goto → console → network → is visible |
| 截圖操作延遲 | < 5 秒 |

## 6. 排除範圍

- 不引入 gstack 作為 dependency
- 不自建 headless browser daemon（Phase 1）
- 不改變現有 QA Gate 流程（先加能力，再改 Gate）

## 7. 依賴與風險

- Playwright MCP server 已在 deferred tools 中，但需確認穩定性
- 是 #385（GAD Delivery 視覺對比）的前置依賴
- self-hosted runner 可能沒有安裝 Chromium
