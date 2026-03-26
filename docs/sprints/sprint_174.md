# Sprint 174

**Sprint Goal：提升 Backlog 健康度與 CI 資料積累品質 -- 補充 sprint-candidate 水位、優化 Discovery 流程、建立 Retro Action 分析工具，並讓 complexity-trend 資料自動持續積累**

**開始日期**：2026-03-26
**結束日期**：2026-04-02
**容量**：5 pts
**Velocity 基準**：avg 5.7 pts（Sprint 171=6, Sprint 172=5, Sprint 173=6）

---

## Sprint Backlog

| Story | 標題 | Size | pts | Story Type | Risk Score | Routing Tier | 平行分群 | 狀態 |
|-------|------|------|-----|-----------|-----------|-------------|---------|------|
| US-#919 | retro: Backlog Discovery 補充 -- sprint-candidate 水位低於閾值 | S | 1 | DISCOVERY | 4 | haiku | Batch 1 | TODO |
| US-#922 | retro: complexity-trend.sh 定期 CI 觸發機制 | S | 1 | INFRA/CI | 6 | sonnet | Batch 1 | TODO |
| US-#887 | retro: Backlog Discovery 流程最佳化 | S | 1 | RESEARCH | 4 | haiku | Phase 2（等 #919） | TODO |
| US-#872 | feat: Retro Action Items 歷史分析工具 | M | 2 | FEATURE | 7 | sonnet | Batch 2 | TODO |

**總計：5 pts**

---

## 技術評估（Architect）

| Story | T-shirt | 修改檔案 | 說明 |
|-------|---------|---------|------|
| US-#919 | S | `skills/backlog-discovery/SKILL.md` | Backlog Discovery 補充，sprint-candidate 水位回填 |
| US-#922 | S | `.github/workflows/`, `scripts/complexity-trend.sh` | CI 定期觸發 complexity-trend 資料積累 |
| US-#887 | S | `skills/backlog-discovery/SKILL.md` | Discovery 流程最佳化，依賴 #919 完成後的水位資料 |
| US-#872 | M | `scripts/`, `docs/km/` | Retro Action Items 歷史分析工具，新增腳本與文件 |

---

## 平行分群策略

- **Batch 1**（並行）：#919 + #922 -- 兩者修改不同檔案，可完全並行
- **Batch 2**（獨立）：#872 -- 獨立開發，不與其他 Story 衝突
- **Phase 2**（序列）：#887 -- 依賴 #919 完成後的 Discovery 水位資料

---

## 風險備註

- **#887 依賴 #919**：#887 需要 #919 產出的 sprint-candidate 水位資料。若 #919 延遲，#887 需等待。緩解：#919 為 S(1) 低風險，預計快速完成。
- **CI 權限**：#922 涉及 GitHub Actions workflow 新增/修改，需確認 CI Actions 版本釘定 @v4 規則。緩解：執行 `validate-ci-versions.sh` 驗證。
- **容量安全**：5 pts 低於基準 5.7 pts，留有緩衝空間。
