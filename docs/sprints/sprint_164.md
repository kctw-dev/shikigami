# Sprint 164

**Sprint Goal**：Backlog 治理工具強化 — 健康度儀表板、Velocity 趨勢自動化、RICE Score 缺漏掃描、Retrospective 模板預填，提升 Sprint Planning 資料驅動能力

- **開始日期**：2026-03-26
- **容量**：4 pts（基準 velocity 6 pts，本 Sprint 選入 4 pts — backlog 候選不足導致低於建議下限，合理接受）

## Sprint Backlog

| # | Story | Issue | Points | Status | Assignee |
|---|-------|-------|--------|--------|----------|
| 1 | feat: Backlog 健康度儀表板 — sprint-candidate 數量/年齡/MoSCoW 分布一覽 | #824 | 1 | DONE (#832) | Developer |
| 2 | feat: Sprint Velocity Trend 自動報告 — 容量估算資料化（最近 5 Sprint 滾動平均） | #825 | 1 | DONE (#833) | Developer |
| 3 | feat: RICE Score 缺漏掃描 — sprint-candidate 補分提醒腳本 | #826 | 1 | DONE (#834) | Developer |
| 4 | feat: Sprint Retrospective 自動模板生成 — 預填 Sprint 指標減少手工填寫 | #827 | 1 | DONE (#835) | Developer |

**Total: 4 pts**

## PO Round 1：Backlog 排序與 Story 選取

### Velocity 計算
| Sprint | Velocity |
|--------|----------|
| Sprint 161 | 7 pts |
| Sprint 162 | 6 pts |
| Sprint 163 | 7 pts |
| **平均** | **6 pts** |
| **建議容量** | **4-7 pts（上限 7 pts）** |

> 腳本輸出：`[CAPACITY] avg_velocity=6pts, recommended_capacity=6pts (±20% range: 4-7pts)`

### RETRO-AUTO-PROMOTE 掃描結果
`[BACKLOG-OK]` 無 `retro-action` + `priority: must` 未升格 Issues。

### 即時排序（MoSCoW Tier + RICE Score）
| Issue | MoSCoW Tier | RICE Score | Size | Points | 選入決策 |
|-------|------------|-----------|------|--------|---------|
| #827 | could (tier 3) | 4.5 | S | 1 | 選入（RICE 最高） |
| #825 | could (tier 3) | 3.4 | S | 1 | 選入（RICE 第二） |
| #824 | could (tier 3) | 3.2 | S | 1 | 選入（RICE 並列第三） |
| #826 | could (tier 3) | 3.2 | S | 1 | 選入（RICE 並列第三，Backlog 全數納入） |

`[BACKLOG-WARN]` sprint-candidate 不足（4 < 5），所有候選全數選入（4 pts < 建議容量 6 pts）。

### 非功能屬性審查
| Issue | NFR 欄位 | 狀態 |
|-------|---------|------|
| #824 | NFR1: 腳本執行時間 < 5 秒（含 gh API 呼叫） | 通過 |
| #825 | NFR1: 腳本無需網路連線（純本地 docs/ 解析） | 通過 |
| #826 | NFR1: gh API 失敗時靜默略過，不阻塞主流程 | 通過 |
| #827 | NFR1: 腳本無需網路連線（純本地文件解析）；NFR2: [RETRO-TEMPLATE-WARN] 格式不符時輸出告警 | 通過 |

### 獨立性評估
| Issue | 預計修改檔案 | 獨立性 |
|-------|------------|--------|
| #824 | scripts/backlog-dashboard.sh, tests/test-backlog-dashboard.sh | 獨立 |
| #825 | scripts/velocity-report.sh, tests/test-velocity-report.sh | 獨立 |
| #826 | scripts/check-rice-scores.sh, tests/test-check-rice-scores.sh（implied） | 獨立 |
| #827 | scripts/generate-retro-template.sh, tests/test-generate-retro-template.sh | 獨立 |

## 技術評估（Architect）

> 容量基線：`[CAPACITY] avg_velocity=6pts, recommended_capacity=6pts (±20% range: 4-7pts)`
> ADR 衝突偵測：`[ADR-NEXT] 下一個可用 ADR 編號：ADR-045`（本 Sprint 無新 ADR 需求）

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | Story Type | Refinement | 說明 |
|-------|---------|---------|---------|-------------|------------|-----------|------|
| #824 | S | 無需新 ADR | 不適用 | — | FEATURE | READY | 新建 scripts/backlog-dashboard.sh（gh issue list 解析）；新建 tests/test-backlog-dashboard.sh（零候選不 crash） |
| #825 | S | 無需新 ADR | 不適用 | — | FEATURE | READY | 新建 scripts/velocity-report.sh（解析 docs/sprints/sprint_*.md 提取 Total pts）；新建 tests/test-velocity-report.sh（fixtures 驗證） |
| #826 | S | 無需新 ADR | 不適用 | — | FEATURE | READY | 新建 scripts/check-rice-scores.sh（gh issue list + RICE Score 缺漏偵測）；可被 backlog-health-report.sh 呼叫 |
| #827 | S | 無需新 ADR | 不適用 | — | FEATURE | READY | 新建 scripts/generate-retro-template.sh（解析 sprint_N.md 輸出 Retrospective Markdown）；新建 tests/test-generate-retro-template.sh（用 sprint_162.md fixture 驗證） |

**Hard Gate 檢查**：所有 Stories 無需 ADR，無技術選型，通過。

### 複雜度影響評估
- **新增 Script**：#824 (backlog-dashboard.sh), #825 (velocity-report.sh), #826 (check-rice-scores.sh), #827 (generate-retro-template.sh)
- **複雜度基線**：SKILL=31, AGENT=8, HOOK=30, TOTAL_LINES=10024（全部在預算內）
- **預估增量**：+4 scripts + 4 test files, ~+600 lines → TOTAL_LINES ≈ 10624（遠低於 25000 預算）
- **結論**：PASS，無需刪減既有功能

### Schema-First 前置驗證
`[SCHEMA-WARN]` #781（Sprint 163）舊警告，本 Sprint 新 Stories 均不涉及 API 契約，`[SCHEMA-OK]`。

### 平行分群
| Group | Stories | 說明 |
|-------|---------|------|
| Group A（可並行） | #824, #825 | 修改不同腳本，無衝突 |
| Group B（可並行） | #826, #827 | 修改不同腳本，無衝突 |
| A 與 B 可完全平行 | — | 四個 Stories 互相獨立，可全部並行 |

## QA 驗收確認

| Story | AC 驗收結果 | 路徑驗證 | 隱性需求 | DoR 狀態 |
|-------|------------|---------|---------|---------|
| #824 | PASS — AC1(輸出格式), AC2([BACKLOG-WARN] 觸發), AC3(零候選不 crash) 均可自動化測試 | N/A（新建檔案） | NFR1 < 5s 已明確，PASS | READY |
| #825 | PASS — AC1(velocity 表格), AC2(容量區間建議), AC3(fixture 驗證) 均可自動化測試 | N/A（新建檔案）；docs/sprints/sprint_162.md 作 fixture 存在：PASS | NFR1 無網路依賴已明確，PASS | READY |
| #826 | PASS — AC1(缺漏清單), AC2([RICE-MISSING] 告警), AC3(backlog-health 整合) 均可自動化測試 | N/A（新建檔案）；docs/km/rice-scoring-standard.md 需存在 | NFR1 gh failure graceful 已明確，PASS | READY |
| #827 | PASS — AC1(預填模板), AC2(格式對齊), AC3(sprint_162.md fixture) 均可自動化測試 | docs/sprints/sprint_162.md 存在：PASS | NFR2 [RETRO-TEMPLATE-WARN] 已明確，PASS | READY |

**D3 協定**：Architect 與 QA 無分歧，D3 不觸發。

## Retrospective（待填）

_Sprint 結束後由 Sprint Review 填入。_
