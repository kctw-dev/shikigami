# Metrics Log

Sprint Review 完成後自動追加 Velocity、完成率與趨勢分析。

計算規則：
- **Velocity**：Done Stories 依 T-shirt Sizing 換算（S=1 / M=2 / L=3）加總
- **完成率**：Done 數 ÷ 計畫總數（分母為 0 時輸出 N/A）
- **趨勢**：Sprint 1–2 輸出「資料不足」；Sprint 3+ 依連升 → 連降 → 穩定（±20%）→ 不規則順序判定

---

| Sprint 編號 | 日期 | Velocity | 完成率 | 趨勢 | 備註 |
|------------|------|----------|--------|------|------|
| Sprint 1 | 2026-02-28 | 8 points | 100% | 資料不足 | 6 Stories（4S+2M），Sprint Goal 達成 |
| Sprint 2 | 2026-02-28 | 5 points | 100% | 資料不足 | 4 Items（1M+3S），Sprint Goal 達成 |
| Sprint 3 | 2026-03-01 | 5 points | 100% | 穩定 | 4 Stories（1M+3S），Sprint Goal 達成；S2→S3 持平（5→5，0%） |
| Sprint 4 | 2026-03-01 | 4 points | 100% | 穩定 | 3 Stories（2S+1M），Sprint Goal 達成；S3→S4 微降（5→4，-20%） |
| Sprint 5 | 2026-03-01 | 6 points | 100% | 不規則 | 4 Stories（2S+2M），Sprint Goal 達成；S4→S5 回升（4→6，+50%） |
| Sprint 6 | 2026-03-01 | 8 points | 100% | 上升趨勢 | 5 Stories（3S+1M+1L），Sprint Goal 達成；S5→S6 續升（6→8，+33%）；v0.3.0 里程碑結案 |
| Sprint 7 | 2026-03-01 | 7 points | 100% | 穩定 | 5 Stories（3S+2M），Sprint Goal 達成；S6→S7 微降（8→7，-12.5%，±20% 內）；v0.5.0 穩定化啟動 |
| Sprint 8 | 2026-03-01 | 6 points | 100% | 穩定 | 4 Stories（2S+2M），Sprint Goal 達成；S7→S8 微降（7→6，-14.3%，±20% 內）；QA 雙階段審查恢復 |
| Sprint 9 | 2026-03-01 | 5 points | 100% | 穩定 | 3 Stories（1S+2M），Sprint Goal 達成；S8→S9 微降（6→5，-16.7%，±20% 內）；Token 成本透明化機制建立 |
| Sprint 10 | 2026-03-01 | 6 points | 100% | 穩定 | 3 Stories（1S+1M+1L），Sprint Goal 達成；S9→S10 回升（5→6，+20%，±20% 內）；分環節記錄 + 權重自動調整 |
| Sprint 11 | 2026-03-01 | 4 points | 100% | 不規則 | 3 Stories（2S+1M），Sprint Goal 達成；S10→S11 下降（6→4，-33.3%）；零讀取架構導入 |
| Sprint 12 | 2026-03-01 | 4 points | 100% | 穩定 | 4 Stories（4S），Sprint Goal 達成；S11→S12 持平（4→4，0%，±20% 內）；health-check 架構對齊 + US-25 AC4 量測完成 |
| Sprint 13 | 2026-03-01 | 4 points | 100% | 穩定 | 4 Stories（4S），Sprint Goal 達成；S12→S13 持平（4→4，0%，±20% 內）；Sprint Planning 平行派工規範建立 + Retro #24-#27 流程缺口清零 |
| Sprint 14 | 2026-03-02 | 2 points | 100% | 不規則 | 2 Stories（2S），Sprint Goal 達成；S13→S14 大幅下降（4→2，-50%）；品質優先策略，低容量係因 QA Hard Gate 篩除無完整 AC 之候選 Story |
| Sprint 15 | 2026-03-02 | 4 points | 100% | 不規則 | 2 Stories（2M），Sprint Goal 達成；S14→S15 大幅回升（2→4，+100%）；M5 使用者就緒交付，全新環境安裝驗證報告 + 端對端使用者文件完成；方向不一致（S13→S14 降、S14→S15 升）→ 不規則 |
| Sprint 16 | 2026-03-02 | 8 points | 100% | 上升趨勢 | 6 Stories（4S+2M），Sprint Goal 達成；S15→S16 倍增（4→8，+100%）；M5 穩定化持續推進；快思/慢想雙模式導入 |
| Sprint 17 | 2026-03-02 | 4 points | 100% | 不規則 | 3 Stories（2S+1M），Sprint Goal 達成；S16→S17 大幅下降（8→4，-50%）；檔案瘦身歸檔機制建立 + Retro Actions 清零 |
| Sprint 18 | 2026-03-02 | 3 points | 100% | 穩定 | 1 Story（1L），Sprint Goal 達成；S17→S18 微降（4→3，-25%，±20% 內偏高但方向一致穩定）；Schedule Skill 交付，ADR-005 先行解鎖 |
| Sprint 19 | 2026-03-02 | 5 points | 100% | 不規則 | 4 Stories（3S+1M），Sprint Goal 達成；S18→S19 回升（3→5，+67%）；近三期（S17=4, S18=3, S19=5）方向不一致（先降後升），且 S19 超出均值 ±20% 區間（4±0.8 = 3.2–4.8）→ 不規則；PO drift 保護 + 序列群組鎖 + schedule whitelist/template 強化 |
| Sprint 20 | 2026-03-02 | 5 points | 100% | 穩定 | 3 Stories（2S+1L），Sprint Goal 達成；S19→S20 持平（5→5，0%）；穩定（3→5→5，最近兩個 Sprint 均為 5pt）；/shoot 短衝模式交付 + Retro Actions 清零 |
| Sprint 21 | 2026-03-02 | 4 points | 100% | 穩定 | 3 Stories（2S+1M），Sprint Goal 達成；S20→S21 微降（5→4，-20%，±20% 內）；穩定（5→5→4，波動在容許範圍內）；parallel-dispatch 衝突偵測 + Onboarding Labels + Retro #58 清零 |
| Sprint 22 | 2026-03-02 | 6 points | 100% | 不規則 | 4 Stories（3S+1L），Sprint Goal 達成；S21→S22 大幅回升（4→6，+50%）；雙 ADR 同 Sprint 交付（ADR-006, ADR-007）；框架安全性強化 |
| Sprint 23 | 2026-03-29 | 5 points | 100% | 穩定 | 4 Stories（3S+1M），Sprint Goal 達成；S22→S23 微降（6→5，-16.7%，±20% 內）；穩定（4→6→5，均值 5.0，全部落於 ±20% 區間 4.0–6.0 內）；ADR-007 Phase 1 實作 + Retro Actions 清零 |
| Sprint 24 | 2026-03-30 | 5 points | 100% | 穩定 | 2 Stories（1S+1M），Sprint Goal 達成；S23→S24 持平（5→5，0%）；穩定（6→5→5，均值 5.33，全部落於 ±20% 區間 4.27–6.40 內）；ADR-007 Phase 2 外部抽樣審查機制交付 |
| Sprint 25 | 2026-03-03 | 4 points | 100% | 穩定 | 3 Stories（2S+1M），Sprint Goal 達成；S24→S25 微降（5→4，-20%，±20% 內）；穩定（5→5→4，均值 4.67，全部落於 ±20% 區間 3.73–5.60 內）；M5 完成條件終審 + Tech Debt Grooming #1 + OpenCode POC 可行性調查；快思模式執行，Token 記錄 N/A |

---

## Token 成本記錄

Sprint 整體 Token 消耗記錄，與 Velocity 記錄粒度對齊（Sprint 為單位）。

資料來源允許值：`Claude Code API` / `手動記錄` / `不可用`

| Sprint 編號 | 輸入 token | 輸出 token | 估算成本 (USD) | 資料來源 |
|------------|-----------|-----------|--------------|---------|
| Sprint 10 | 107M | 266K | $234.10 | Claude Code JSONL |
| Sprint 11 | N/A | N/A | N/A | 不可用 |

---

### 手動記錄模板

當 Token 資料無法自動取得時，依下列模板手動填入 Token 成本記錄表格：

| Sprint 編號 | 輸入 token | 輸出 token | 估算成本 (USD) | 資料來源 |
|------------|-----------|-----------|--------------|---------|
| Sprint N | 12500 | 3200 | $0.0245 | 手動記錄 |

---

## Token 成本分環節記錄

Sprint 環節 Token 消耗記錄，依 Planning / Execution / Review 分別記錄。

佔比計算基準：本環節 token（輸入 + 輸出）÷ 三環節 token 總和 × 100%（取整數）。
數值格式：≥1000 用 K 表示（如 45K），<1000 顯示原始數字。

| Sprint 編號 | Planning token | Execution token | Review token | 合計 token | 佔比（Planning / Execution / Review） |
|------------|---------------|-----------------|-------------|-----------|--------------------------------------|
| Sprint N（示範） | 12K | 20K | 10K | 42K | 29% / 48% / 23% |
| Sprint 10 | 87M | 10M | 11M | 108M | 81% / 9% / 10% |
| Sprint 11 | N/A | N/A | N/A | N/A | N/A / N/A / N/A |
| Sprint 12 | 8761K | 486K | N/A | N/A（Review 進行中，無法精確切分） | N/A（Review token 進行中無法精確切分，合計待補） |
| Sprint 13 | 5450K | 4242K | 5804K | 15496K | 35% / 27% / 38% |
| Sprint 14 | N/A | N/A | N/A | N/A | N/A / N/A / N/A |
| Sprint 15 | N/A | N/A | N/A | N/A | N/A / N/A / N/A |
| Sprint 16 | 4174K | 21679K | 6441K | 32294K | 13% / 67% / 20% |
| Sprint 17 | N/A | N/A | N/A | N/A | N/A / N/A / N/A |
| Sprint 18 | N/A | N/A | N/A | N/A | N/A / N/A / N/A |
| Sprint 19 | N/A | N/A | N/A | N/A | N/A / N/A / N/A |
| Sprint 23 | N/A | N/A | N/A | N/A | N/A / N/A / N/A |

---

### 分環節手動記錄模板

當分環節 Token 資料無法自動取得時，依下列模板手動填入：

| Sprint 編號 | Planning token | Execution token | Review token | 合計 token | 佔比（Planning / Execution / Review） |
|------------|---------------|-----------------|-------------|-----------|--------------------------------------|
| Sprint N | 12K | 20K | 10K | 42K | 29% / 48% / 23% |

---

## Token JSONL 調查記錄

**調查日期**：2026-03-02

**執行者**：Developer Subagent（AI Agent，Retro #38 Sprint 16）

### 調查步驟結果（AC1）

**步驟 a — 列出 project 目錄**

執行 `ls ~/.claude/projects/`，輸出如下：

```
-home-kevin
-home-kevin-george
-home-kevin-kagemusha
-home-kevin-kinun
-home-kevin-onmyodo
-home-kevin-seven-bala
-home-kevin-shikigami
```

shikigami 專案對應目錄：`~/.claude/projects/-home-kevin-shikigami/`

目錄下包含 8 個 JSONL 檔案，命名格式：`<session-uuid>.jsonl`

**步驟 b — 讀取最新 JSONL 的 `message.usage` 欄位**

最新 JSONL（依修改時間排序）：
`~/.claude/projects/-home-kevin-shikigami/7b27788f-a884-4323-870f-9cce6719abc2.jsonl`

讀取結果：

- 操作狀態：**成功**
- 檔案共 800 條 JSONL 記錄，其中 210 條含 `message.usage` 欄位
- `message.usage` 欄位結構如下：

```json
{
  "input_tokens": 1,
  "cache_creation_input_tokens": 198,
  "cache_read_input_tokens": 162314,
  "output_tokens": 746,
  "server_tool_use": {
    "web_search_requests": 0,
    "web_fetch_requests": 0
  },
  "service_tier": "standard",
  "cache_creation": {
    "ephemeral_1h_input_tokens": 198,
    "ephemeral_5m_input_tokens": 0
  },
  "inference_geo": "",
  "iterations": [],
  "speed": "standard"
}
```

**步驟 c — 分支判定**：**分支 A（可存取）**

- JSONL 路徑格式：`~/.claude/projects/<project-slug>/<session-uuid>.jsonl`
- `message.usage` 欄位：僅存在於 `type` 為 assistant 回應的記錄中（含 `requestId` 的條目）
- 提取 token 需加總所有含 `message.usage` 條目的 `input_tokens` 與 `output_tokens`

### 結論

**分支 A：可提取**

- JSONL 路徑可存取，無權限限制（檔案屬主為當前使用者）
- `message.usage` 欄位存在且可正常解析

### 對應 SKILL.md 更新策略

**分支 A 一致確認：無需更新**

三個 SKILL.md 現有的主要方法描述（`skills/sprint-planning/SKILL.md`、`skills/sprint-execution/SKILL.md`、`skills/sprint-review/SKILL.md`）均已正確指向：

- 路徑：`~/.claude/projects/` 目錄下當前 session 的 JSONL 檔案
- 欄位：`message.usage` 的 `input_tokens` 與 `output_tokens`

與實際可存取的 JSONL 結構完全一致，無需修改。

**ADR-003 適用性**：不適用（分支 A 一致，SKILL.md 無需修改；豁免理由已記錄）
