# Gemini 3.1 Pro 實測評估報告

**調查日期**：2026-03-08
**相關 Issue**：#174
**前置調查**：GEMINI_CLI_INVESTIGATION.md（Sprint 61, US-163）

---

## 1. Gemini 3.1 Pro 模型概要

| 項目 | Gemini 3.1 Pro | Claude Opus 4.6 | Claude Haiku 4.5 |
|------|---------------|-----------------|-------------------|
| 發布日期 | 2026-02-19 | 2025 | 2025 |
| SWE-bench Verified | 80.6% | 80.8% | N/A |
| Terminal-Bench 2.0 | 68.5% | 65.4% | N/A |
| Context Window | 1,000,000 tokens | 200,000 tokens | 200,000 tokens |
| Max Output | 64,000 tokens | 128,000 tokens | 8,192 tokens |
| Input 定價 (/1M tokens) | $2.00 | $5.00 | $0.25 |
| Output 定價 (/1M tokens) | $12.00 | $25.00 | $1.25 |

**關鍵發現**：Gemini 3.1 Pro 在 SWE-bench 上與 Claude Opus 4.6 幾乎平手（0.2pp 差距），在 Terminal-Bench 上領先 3.1pp。定價約為 Opus 的 40-48%。

---

## 2. Gemini CLI 免費額度

| 認證方式 | 日請求上限 | 分鐘請求上限 | 預設模型 |
|---------|----------|------------|---------|
| Google Account（免費） | 1,000 | 60 | gemini-3-flash-preview |
| Gemini API Key（免費） | 250 | 10 | Flash 系列 |
| Gemini Code Assist Standard | 1,500 | 120 | 付費模型 |

**注意**：免費帳號預設使用 **Gemini 3 Flash Preview**（非 3.1 Pro）。使用 3.1 Pro 需付費或指定模型參數。

---

## 3. 實測結果

### 測試 1：Metrics 計算（haiku 替代場景）

**任務**：讀取 `docs/km/Metrics_Log.md`，計算 Sprint 60-67 平均 Velocity

| 指標 | Gemini CLI | 預期 |
|------|-----------|------|
| 結果 | 2.625 | 2.625 ✅ |
| 使用模型 | gemini-3-flash-preview | — |
| 路由模型 | gemini-2.5-flash-lite | — |
| 總 token | ~47,831 | — |
| 延遲 | ~10 秒 | — |

**結論**：Gemini CLI 能正確讀取本地檔案並計算，結果完全正確。

---

## 4. Shikigami 框架適用性分析

### 4.1 成本比較（haiku 替代場景）

| 場景 | Claude Haiku 成本 | Gemini CLI 免費額度 | 差異 |
|------|------------------|-------------------|------|
| Sprint Review Analytics | ~$0.01/次 | 免費（1000 次/天內） | 100% 節省 |
| Metrics 計算 | ~$0.005/次 | 免費 | 100% 節省 |
| 歸檔操作 | ~$0.003/次 | 免費 | 100% 節省 |

**每 Sprint 預估節省**：haiku subagent 約 3-5 次呼叫，每次 ~$0.01 → 約 $0.03-0.05/Sprint。金額極小。

### 4.2 技術整合難度

| 面向 | 評估 |
|------|------|
| 呼叫方式 | `echo "prompt" \| gemini` — 需 shell out，非 Claude Code Agent tool |
| 回傳格式 | JSON（`--output-format json`）— 需解析 |
| 錯誤處理 | 需自行處理 timeout、認證失敗、quota exceeded |
| Context 傳遞 | 無法共享 Claude Code session context — 需在 prompt 中完整描述任務 |
| 模型指定 | 免費版預設 Flash，指定 3.1 Pro 需額外配置 |

### 4.3 優缺點摘要

**優點**：
- 免費額度充裕（1000 次/天），足以覆蓋 haiku 級任務
- Gemini 3.1 Pro 編碼能力與 Opus 4.6 平手，遠超 haiku 級需求
- 1M context window 對大型檔案分析有優勢

**缺點**：
- 整合成本高：需修改 SKILL.md 派遣邏輯，從 Agent tool 改為 shell out
- 節省金額極小：haiku 已經很便宜（~$0.01/次），切換 ROI 低
- 增加外部依賴：Gemini CLI 認證、版本更新、quota 變更均為風險
- 免費版不用 3.1 Pro：預設是 Flash，品質略低於 haiku

---

## 5. 結論與建議

### 5.1 haiku 替代：**不建議現階段切換**

| 判斷維度 | 評估 |
|---------|------|
| 成本節省 | 極小（$0.03-0.05/Sprint） |
| 整合成本 | 中等（需修改派遣邏輯 + 錯誤處理） |
| 品質風險 | 低（Flash 品質足夠 haiku 級任務） |
| 維護負擔 | 增加（外部依賴管理） |
| **ROI** | **負**（整合成本 > 節省金額） |

### 5.2 程式碼生成：**值得關注但非急迫**

Gemini 3.1 Pro 的編碼能力已達 Opus 級水準（SWE-bench 80.6%），作為 Developer 角色的替代方案具有潛力。但：
- 需要付費使用 3.1 Pro（免費版只有 Flash）
- 定價 $2/$12（vs Opus $5/$25）→ 約 50% 成本
- 整合難度同上（shell out vs Agent tool）

### 5.3 建議的重新評估觸發條件

| # | 觸發條件 | 說明 |
|---|---------|------|
| 1 | Claude API 成本顯著上升 | haiku 定價提高至 10x 以上 |
| 2 | Gemini CLI 支援 MCP 或 Agent protocol | 可無縫整合，不需 shell out |
| 3 | 框架需支援離線 / 多 provider fallback | 網路中斷時 fallback 至本地模型 |
| 4 | Gemini 3.1 Pro 進入免費額度 | 免費即用 Pro 級模型 |

---

## 資料來源

- [Gemini CLI Releases](https://github.com/google-gemini/gemini-cli/releases)
- [Gemini CLI Quota & Pricing](https://geminicli.com/docs/resources/quota-and-pricing/)
- [Gemini 3.1 Pro Announcement](https://blog.google/innovation-and-ai/models-and-research/gemini-models/gemini-3-1-pro/)
- [Gemini 3.1 Pro vs Claude Opus 4.6 Comparison](https://help.apiyi.com/en/gemini-3-1-pro-preview-vs-claude-opus-4-6-comparison-en.html)
- [Gemini 3.1 Benchmarks (DataCamp)](https://www.datacamp.com/blog/gemini-3-1)
- [Claude Code vs Gemini CLI (Shipyard)](https://shipyard.build/blog/claude-code-vs-gemini-cli/)
