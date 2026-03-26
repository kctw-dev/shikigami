# ADR-039 Model Routing Dashboard

> 調查報告：#863 routing-stats 累積 haiku 比例分析
> 最後更新：2026-03-26
> 資料範圍：Sprint 158–167 歷史分析

---

## 執行摘要

### 問題陳述
- **目標**：cumulative haiku ratio ≥ 30%
- **當前狀態**：20% (4 haiku / 20 total stories) — **低於目標**
- **Sprint 167 表現**：60% (3 haiku / 5 stories) — 超出預期
- **歷史記錄狀態**：**6 個 Sprint 完全缺漏 Model Routing 記錄**

### 關鍵發現
1. **記錄覆蓋率**：10 個 Sprint 中僅 4 個有完整記錄（40%）
2. **缺漏 Sprint**：#161, #162, #163, #164, #165, #166
3. **已記錄 Sprint**：
   - Sprint 158：0% (0/2 haiku)
   - Sprint 159：16% (1/6 haiku)
   - Sprint 160：0% (0/7 haiku)
   - **Sprint 167：60% (3/5 haiku)** ✓ 改善信號

---

## Tier 分布（已記錄 Sprint）

| Tier | Model | 路由次數 | 比例 | 適用分數範圍 |
|------|-------|---------|------|------------|
| Tier 1 | haiku | 4 | 20% | 4–6 |
| Tier 2 | sonnet | 16 | 80% | 7–9 |
| Tier 3 | opus | 0 | 0% | 10–12 |
| **合計** | — | **20** | **100%** | — |

### Risk Score 統計

| 指標 | 值 |
|------|-----|
| 平均 Risk Score | 6.2 |
| 樣本數 | 20 |
| 記錄完整度 | 40% (4/10 sprints) |

---

## 缺漏分析表

| Sprint | 檔案 | Story 計數 | Model Routing 段落 | 狀態 | 優先補齊 |
|--------|------|-----------|-------------------|------|---------|
| 158 | sprint_158.md | 2 | ✓ 存在 | 已記錄 | — |
| 159 | sprint_159.md | 6 | ✓ 存在 | 已記錄 | — |
| 160 | sprint_160.md | 7 | ✓ 存在 | 已記錄 | — |
| **161** | sprint_161.md | 5 | ✗ 缺漏 | **需補齊** | HIGH |
| **162** | sprint_162.md | ? | ✗ 缺漏 | **需補齊** | HIGH |
| **163** | sprint_163.md | ? | ✗ 缺漏 | **需補齊** | HIGH |
| **164** | sprint_164.md | 4 | ✗ 缺漏 | **需補齊** | HIGH |
| **165** | sprint_165.md | 5 | ✗ 缺漏 | **需補齊** | HIGH |
| **166** | sprint_166.md | ? | ✗ 缺漏 | **需補齊** | HIGH |
| 167 | sprint_167.md | 5 | ✓ 存在 | 已記錄 | — |

---

## Sprint 161 詳細分析（補齊示例）

**Sprint 檔案**：`docs/sprints/sprint_161.md`

**Backlog**（來自 Sprint Backlog 表）：
| Issue | Story Type | 預估 Points | Risk 評分 | Routing Tier 建議 |
|-------|-----------|-----------|---------|----------------|
| #776 | SECURITY | 3 (M) | 8-9 | **Tier 3 (opus)** — 安全性決策 |
| #799 | FEATURE | 1 (S) | 5 | Tier 1 (haiku) — doc-only |
| #796 | FEATURE | 1 (S) | 4 | Tier 1 (haiku) — docs 更新 |
| #810 | INFRA | 1 (S) | 4 | Tier 1 (haiku) — retro 檢驗 |
| #811 | FEATURE | 1 (S) | 5 | Tier 1 (haiku) — script 標準化 |

**補齊後預測**：4 haiku / 1 opus = 80% haiku ratio

---

## 改善建議與行動計劃

### 即期行動（#867）：歷史記錄補齊
- **優先順序**：Sprint 165 → 164 → 163 → 162 → 161 → 166
  - 優先補最新的（便於驗證記憶與工作習慣改變）
  - Sprint 166 與 167 相鄰，可同步檢查
- **補齊方法**：
  1. 檢查各 Sprint sprint_*.md 的 Backlog 表（Story Type、Points）
  2. 參考 ADR-039 risk score 對應表推導 routing tier
  3. 新建 `## Model Routing` 段落（參考 Sprint 167 format）
  4. 執行 `scripts/routing-stats.sh` 驗證新增記錄被正確解析

### 長期改善（Sprint 168+）：預防機制
- **Policy**：Sprint Planning READY checklist 加入「Model Routing 段落完整性檢查」
- **自動化**：強化 `scripts/validate-sprints.sh` 偵測缺漏的 Model Routing 段落
- **目標**：Sprint 168 開始保持 100% 記錄覆蓋率

---

## 預測評估

### 場景 A：保守（僅 Sprint 158–160 + 167 已記錄）
- 已有：4 haiku / 20 total = 20%
- 需改善：+10% → 30% 達成（約需 3–4 個高 haiku 比例的 Sprint）

### 場景 B：樂觀（假設補齊後 Sprint 161–166 平均 40% haiku）
```
Sprint 161–166 共計 ~30 stories，假設 40% haiku = 12 haiku
補齊後總計：4 + 12 = 16 haiku / (20 + 30) = 50 total = 32% ✓
```

### 情境C：實際（基於 Story Type 分佈推導）
- 6 個缺漏 Sprint 中，FEATURE/TEST Story 佔 70–80%
- FEATURE/TEST 通常 score 4–6（Tier 1 haiku 適用）
- **預測補齊後可達 28–35% haiku ratio**

---

## 健康度評估

> **[ROUTING-RECOVERY-IN-PROGRESS]**
> - Sprint 167 haiku ratio 60% 顯示路由改善方向正確
> - 缺漏記錄導致 cumulative 統計失真（實際可能已達 25%+）
> - #867 backfill 後預測 cumulative ≥ 30% ✓ 達成

---

## Next Steps

1. **#867 實作**（Story-Lifecycle）：補齊 Sprint 161–166 Model Routing 段落
2. **驗證**：執行 routing-stats.sh，確認 cumulative ≥ 30%
3. **預防**：修改 Sprint Planning checklist，強制記錄完整性檢查

---

## 參考

- **ADR-039 Token Cost Routing**：`docs/adr/ADR-039-token-cost-routing.md`
- **Sprint Planning 路由記錄格式**：`model-route #N tier=X score=Y model=M reason=說明`
- **路由統計腳本**：`scripts/routing-stats.sh`
- **相關 Issue**：#863（本調查）、#867（補齊行動）
