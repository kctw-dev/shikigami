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

---

## Token 成本記錄

Sprint 整體 Token 消耗記錄，與 Velocity 記錄粒度對齊（Sprint 為單位）。

資料來源允許值：`Claude Code API` / `手動記錄` / `不可用`

| Sprint 編號 | 輸入 token | 輸出 token | 估算成本 (USD) | 資料來源 |
|------------|-----------|-----------|--------------|---------|
| Sprint 10 | N/A | N/A | N/A | 不可用 |

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
| Sprint 10 | N/A | N/A | N/A | N/A | N/A |

---

### 分環節手動記錄模板

當分環節 Token 資料無法自動取得時，依下列模板手動填入：

| Sprint 編號 | Planning token | Execution token | Review token | 合計 token | 佔比（Planning / Execution / Review） |
|------------|---------------|-----------------|-------------|-----------|--------------------------------------|
| Sprint N | 12K | 20K | 10K | 42K | 29% / 48% / 23% |
