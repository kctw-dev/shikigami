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
