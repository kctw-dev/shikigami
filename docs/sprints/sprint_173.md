# Sprint 173

**Sprint Goal：補齊驗證腳本效能與整合測試基礎建設、強化 Cruise Log 搜尋與複雜度趨勢追蹤**

**開始日期**：2026-03-26
**結束日期**：2026-04-02
**容量**：6 pts
**Velocity 基準**：avg 5 pts（Sprint 170=6, Sprint 171=6, Sprint 172=5）

---

## Sprint Backlog

| Story | 標題 | Size | pts | Story Type | Risk Score | Routing Tier | 平行分群 | 狀態 |
|-------|------|------|-----|-----------|-----------|-------------|---------|------|
| US-#886 | retro: 驗證腳本整合測試補齊 | M | 2 | TEST | 6 | sonnet | Group C | TODO |
| US-#848 | feat: 複雜度趨勢追蹤 — measure-complexity 歷史記錄與增速預警 | S | 1 | FEATURE | 5 | haiku（強制） | Group A | TODO |
| US-#842 | feat: Cruise Log 搜尋增強 — type 篩選、時間範圍、統計摘要 | S | 1 | FEATURE | 5 | haiku（強制） | Group A | TODO |
| US-#898 | retro: validate-orphans.sh 整合測試效能優化 — 14s > 10s NFR1 門檻 | S | 1 | TEST | 5 | haiku（強制） | Group B | TODO |
| US-#896 | retro: routing-stats.sh 支援 custom section 保護 | S | 1 | FEATURE | 5 | haiku（強制） | Group B | TODO |

**總計：6 pts**

---

## 技術評估（Architect）

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | 說明 |
|-------|---------|---------|---------|-------------|------|
| US-#886 | M | 無需 ADR | 不適用 | — | 補齊 7 個腳本的 E2E 整合測試，參考 #875 模板；subtasks 可部分平行執行 |
| US-#848 | S | 無需 ADR | 不適用 | — | 新建 scripts/complexity-trend.sh + docs/km/complexity-trend.csv + 對應測試 |
| US-#842 | S | 無需 ADR | 不適用 | — | 修改既有 scripts/search-cruise-logs.sh，新增 --type / --since / --until / --summary flags |
| US-#898 | S | 無需 ADR | 不適用 | — | 修改 tests/test-validate-orphans-integration.sh，加入 --fast 模式跳過全量掃描 |
| US-#896 | S | 無需 ADR | 不適用 | — | 修改 scripts/routing-stats.sh，保留 custom-section-start/end 區塊不覆蓋 |

**容量確認**：[CAPACITY] avg_velocity=5pts，建議 5pts；實際選取 6pts，在 ±20% 範圍（4-6pts）內，通過。

**平行分群（Parallel Groups）**：
- **Group A（可平行）**：#848, #842（修改不同檔案，可同時執行）
- **Group B（可平行）**：#898, #896（修改不同腳本，可同時執行）
- **Group C（順序）**：#886（M size，複雜 subtasks，建議 Group A/B 完成後執行）

---

## QA 驗收確認

| Story | AC 確認結果 | 路徑驗證 | NFR 驗證 | 隱性需求 | 結果 |
|-------|-----------|---------|---------|---------|------|
| US-#886 | PASS | tests/test-validate-orphans-integration.sh: PASS（模板存在）；新建測試: N/A | NFR1: E2E 可重複執行；NFR2: <10s；NFR3: 7腳本全覆蓋 | reliability：CI 環境下應有穩定執行保障 | CONFIRMED |
| US-#848 | PASS | 新建檔案: N/A | NFR1: CSV 可被 Sprint Review 直接引用 | completeness：趨勢應涵蓋至少最近 5 次快照 | CONFIRMED |
| US-#842 | PASS | scripts/search-cruise-logs.sh: PASS；tests/test-search-cruise-logs.sh: PASS | NFR1: 1000 行 JSONL <2s | performance：大 log 查詢不阻塞使用者 | CONFIRMED |
| US-#898 | PASS | tests/test-validate-orphans-integration.sh: PASS；scripts/validate-orphans.sh: PASS | NFR1: --fast 不破壞完整測試意圖；NFR2: fixture模式<3s | reliability：fast 模式應有明確的抽樣策略說明 | CONFIRMED |
| US-#896 | PASS | scripts/routing-stats.sh: PASS | 冪等性: 重複執行不累積重複內容 | reliability：custom section 保護應對格式異常降級不崩潰 | CONFIRMED |

---

## Retro-Action Items（本 Sprint 選入）

- #886：驗證腳本整合測試補齊（Sprint 168 Retro → 高優先，priority: should）
- #898：validate-orphans.sh 整合測試效能優化（Sprint 170 Retro → priority: could）
- #896：routing-stats.sh 支援 custom section 保護（Sprint 169 Retro → priority: could）

## 延後至下一 Sprint

- #887：retro: Backlog Discovery 流程最佳化（research story，could，容量限制）
- #872：feat: Retro Action Items 歷史分析工具（M size，could，容量限制）

---

## Haiku 路由審查（ADR-039）

| Story ID | Story Type | Risk Score | Routing Tier |
|----------|-----------|-----------|-------------|
| US-#886 | TEST | 6 | sonnet（Score 6，多模組協調） |
| US-#848 | FEATURE | 5 | haiku（強制：Score 4-5） |
| US-#842 | FEATURE | 5 | haiku（強制：Score 4-5） |
| US-#898 | TEST | 5 | haiku（強制：Score 4-5） |
| US-#896 | FEATURE | 5 | haiku（強制：Score 4-5） |

haiku_ratio = 4/5 = 80% — [HAIKU-RATIO-OK]
