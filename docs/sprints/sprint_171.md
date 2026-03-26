# Sprint 171

**Sprint Goal：可觀測性工具補齊 x Retro Action 清倉 — NFR 補充、Sprint/ADR/CI 健康度指標腳本交付、測試可測試性規範建立**

**開始日期**：2026-03-26
**結束日期**：2026-04-02
**容量**：6 pts
**Velocity 基準**：avg 6 pts（Sprint 168=6, Sprint 169=6, Sprint 170=6）

---

## Sprint Backlog

| Story | 標題 | Size | pts | Story Type | Risk Score | Routing Tier | 狀態 |
|-------|------|------|-----|-----------|-----------|-------------|------|
| US-#899 | retro: 為 #894 #895 #886 補充非功能性需求欄位 | S | 1 | DOC | 4 | haiku（強制） | DONE (#901) |
| US-#874 | feat: Sprint Goal 達成率歷史追蹤 — sprint_*.md 目標達成統計分析 | S | 1 | INFRA | 5 | haiku（強制） | DONE (#902) |
| US-#869 | feat: Sprint Metrics 歷史趨勢儀表板 — metrics-log 多 Sprint 比較分析 | S | 1 | INFRA | 5 | haiku（強制） | DONE (#903) |
| US-#868 | feat: ADR 老化偵測 — 超過 90 天未更新的 Accepted ADR 自動告警 | S | 1 | INFRA | 5 | haiku（強制） | DONE (#905) |
| US-#876 | feat: ci-health-check.sh 自動化測試 — CI 健康檢查腳本單元測試 | S | 1 | TEST | 5 | haiku（強制） | DONE (#904) |
| US-#900 | retro: 測試輔助規範 — 腳本應提供 REPO_ROOT 環境變數覆蓋機制 | S | 1 | DOC | 4 | haiku（強制） | DONE (#906) |

**總計：6 pts**

---

## 技術評估（Architect）

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | 說明 |
|-------|---------|---------|---------|-------------|------|
| US-#899 | S | 無需 ADR | 不適用 | — | Issue body 編輯，doc-only，無架構涉及 |
| US-#874 | S | 無需 ADR | 不適用 | — | 新建 scripts/sprint-goal-stats.sh + tests/test-sprint-goal-stats.sh，純 shell 腳本，無跨模組依賴 |
| US-#869 | S | 無需 ADR | 不適用 | — | 新建 scripts/sprint-metrics-trend.sh + tests，掃描 docs/km/metrics-log/*.md，純讀取分析 |
| US-#868 | S | 無需 ADR | 不適用 | — | 擴充 scripts/adr-status-dashboard.sh --check-staleness 旗標，現有腳本新增功能 |
| US-#876 | S | 無需 ADR | 不適用 | — | 新建 tests/test-ci-health-check-unit.sh，mock-based，不依賴真實 CI 狀態 |
| US-#900 | S | 無需 ADR | 不適用 | — | 新建 docs/guides/script-testability-guide.md，doc-only |

**容量確認**：[CAPACITY] avg_velocity=5pts（scripts 計算），建議 5pts；實際選取 6pts，在 ±20% 範圍（4-6pts）內，通過。

**平行分群（Parallel Groups）**：
- **Group A（可平行）**：#899（Issue body 編輯）、#900（新建 docs/guides/）
- **Group B（可平行）**：#874（新建 sprint-goal-stats.sh）、#869（新建 sprint-metrics-trend.sh）、#876（新建 test-ci-health-check-unit.sh）
- **Group C（順序執行）**：#868（擴充 adr-status-dashboard.sh，需在 Group B 完成後確認無衝突）

---

## QA 驗收確認

| Story | AC 確認結果 | 路徑驗證 | NFR 驗證 | SDD 引用 | 結果 |
|-------|-----------|---------|---------|---------|------|
| US-#899 | PASS（AC 4 條，涵蓋三個目標 Issues 的 NFR 補充） | N/A（Issue body 編輯） | NFR1: 符合 po-prompt.md 格式 | — | CONFIRMED |
| US-#874 | PASS（AC 5 條，含測試與趨勢識別） | N/A（新建腳本） | NFR1: < 5s；NFR2: --last N 可配置 | — | CONFIRMED |
| US-#869 | PASS（AC 4 條，含趨勢方向識別） | N/A（新建腳本） | NFR1: < 3s；NFR2: 與 metrics-log/*.md 相容 | — | CONFIRMED |
| US-#868 | PASS（AC 4 條，含 [ADR-STALE] 標記與測試） | scripts/adr-status-dashboard.sh: PASS | NFR1: 使用 git log 日期，非 mtime | — | CONFIRMED |
| US-#876 | PASS（AC 4 條，含 mock 方式與執行時間） | scripts/ci-health-check.sh: PASS | NFR1: < 5s | — | CONFIRMED |
| US-#900 | PASS（AC 4 條，含最佳實踐範例） | docs/guides/ dir: PASS（目錄存在） | NFR1: 規範文件 < 1 頁 | — | CONFIRMED |

**RICE Score 與 Routing Tier 交叉審查**：

| Story | Story Type | Risk Score | Routing Tier |
|-------|-----------|-----------|-------------|
| US-#899 | DOC | 4 | haiku（強制） |
| US-#874 | INFRA | 5 | haiku（強制） |
| US-#869 | INFRA | 5 | haiku（強制） |
| US-#868 | INFRA | 5 | haiku（強制） |
| US-#876 | TEST | 5 | haiku（強制） |
| US-#900 | DOC | 4 | haiku（強制） |

haiku 比例：6/6 = 100% — 超過 20% 門檻，無 [HAIKU-RATIO-WARN]

---

## NFR 待補充 Issues（本 Sprint 未選入）

以下 Issues 缺少 `## 非功能性需求` 欄位，退回 Backlog 待補充後重新評估（#899 本 Sprint 會補充 #894/#895/#886）：

- **#896** retro: routing-stats.sh 支援 custom section 保護 — 非功能屬性待補
- **#887** retro: Backlog Discovery 流程最佳化 — 非功能屬性待補
- **#848** feat: 複雜度趨勢追蹤 — 非功能屬性待補
- **#842** feat: Cruise Log 搜尋增強 — 非功能屬性待補

---

## Next Sprint Preview（候選）

- #895 retro: 建立 routing-history schema 規格文件（#899 補充 NFR 後可進入）
- #894 retro: validate-a2a-schema.sh 補充 story_id integer 型別文件（同上）
- #886 retro: 驗證腳本整合測試補齊（Size M，#899 補充 NFR + RICE 後可進入）
- #898 retro: validate-orphans.sh 整合測試效能優化
- #882 feat: Backlog Health 自動告警（Size M）
- #872 feat: Retro Action Items 歷史分析工具（Size M）
