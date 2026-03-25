# ADR-039 Model Routing Dashboard

> 本文件由 `scripts/routing-stats.sh` 自動產生，請勿手動修改。
> 最後更新：2026-03-25 23:21:17
> 資料範圍：最近 10 個 Sprint（Sprint 154 155 156 157 158 159 160 161 162 163）

## Tier 分布

| Tier | Model | 路由次數 | 比例 | 適用分數範圍 |
|------|-------|---------|------|------------|
| Tier 1 | haiku | 6 | 21% | 4–6 |
| Tier 2 | sonnet | 22 | 78% | 7–9 |
| Tier 3 | opus | 0 | 0% | 10–12 |
| **合計** | — | **28** | **100%** | — |

## Risk Score 統計

| 指標 | 值 |
|------|-----|
| 平均 Risk Score | 6 |
| 樣本數 | 28 |

## 健康度評估

> **[OVER-ROUTING-WARN]** haiku tier 比例 21% < 30%，疑似 over-routing

## 路由建議（NFR3）

> 基於當前統計資料的具體建議：

- **降低 haiku 使用門檻**：Score 4-5 的 Story 應路由至 haiku（目前 haiku 比例偏低 21%）
- Score 4-5 的 Story 可降至 haiku（doc-only retro / 格式轉換 / log 摘要）
- Score 10-12 的 Story 應路由至 opus（架構設計 ADR / 安全審查 / L-size Story）

## 參考

- ADR-039 Token Cost Routing：`docs/adr/ADR-039-token-cost-routing.md`
- Sprint Planning 路由記錄格式：`model-route #N tier=X score=Y model=M reason=說明`
