# ADR-043: Backlog Replenishment Strategy — 提前預警機制與 2-Sprint 提前期設計

**狀態**：Accepted
**日期**：2026-03-25
**決策者**：Architect Agent + PO Agent
**觸發 Story**：#723（RESEARCH: ADR-043）
**Unblocks**：#721 retro: Sprint 153 Backlog 補充頻率調整 — 建立提前預警機制

---

## 背景與問題

Sprint 150-151 的 Backlog 耗盡事件分析：

| Sprint | sprint-candidate 數量 | 結果 |
|--------|----------------------|------|
| Sprint 149 結束 | 4 | 健康（但預警閾值 8 未達標，應已觸發補充） |
| Sprint 150 結束 | 1 | 危險（缺口） |
| Sprint 151 | 容量降至 2 pts | Backlog 耗盡，Sprint 被迫降容量 |
| Sprint 152-153 | 恢復 5-6 pts | 補充流程晚了 1 個 Sprint |

**根本原因**：
1. 預警閾值 `< 8` 觸發太晚（Sprint 149 結束時已有 4 個，閾值設定使補充延遲了 1 個週期）
2. Backlog Discovery 為「事後補充」（Sprint Review 後觸發），而非「主動預警」
3. 無 2-Sprint 提前期概念 — 僅確保當前 Sprint 有足夠 candidate，未規劃下一個 Sprint

---

## 決策內容

### 選項 A：提高閾值 + 提前觸發（選定）

**閾值調整**：`sprint-candidate < 8` → `sprint-candidate < 10`

**補充觸發時機改變**：
- 舊：Sprint Review 後觸發（事後）
- 新：當前 Sprint 執行中，當 sprint-candidate 降至 10 以下時，主動觸發補充（事中）

**2-Sprint 提前期目標**：`sprint-candidate >= 16`（約 2 個 Sprint 的候選庫存）

### 選項 B：動態閾值（未選）

依 Sprint velocity 動態計算閾值（閾值 = 2 × velocity）。
未選擇原因：velocity 波動大（2-7 pts），動態閾值計算複雜，維護成本高。

---

## 決策理由

1. **簡單優先**：固定閾值（10）比動態閾值易理解、易驗證
2. **提前觸發**：在 Sprint 執行中觸發補充，確保下一 Sprint 開始時 candidate 充足
3. **2-Sprint 緩衝**：目標 16 個 candidate 提供約 2 個 Sprint 的緩衝，容許 1 次 Backlog Discovery 失敗

---

## 實作規範（供 #721 參照）

### 觸發條件

```bash
# 在 PO 巡邏（po-patrol.md）中：
SPRINT_CANDIDATE_COUNT=$(gh issue list -R ${OWNER_REPO} --label "sprint-candidate" --state open --json number | jq length)

# 舊閾值（deprecated）
# if [[ "$SPRINT_CANDIDATE_COUNT" -lt 8 ]]; then
#   trigger backlog discovery

# 新閾值（ADR-043）
REPLENISHMENT_THRESHOLD="${BACKLOG_THRESHOLD:-10}"  # 讀取 .claude/shikigami.local.md backlog_health.threshold
if [[ "$SPRINT_CANDIDATE_COUNT" -lt "${REPLENISHMENT_THRESHOLD}" ]]; then
  # 立即觸發 Backlog Discovery（不等 Sprint Review）
  log action: "backlog-replenishment-triggered: count=${SPRINT_CANDIDATE_COUNT} < threshold=${REPLENISHMENT_THRESHOLD}"
  invoke shikigami:backlog-discovery  # 或觸發 PO Backlog Discovery 流程
fi
```

### 目標庫存

```bash
# 2-Sprint 提前期目標
REPLENISHMENT_TARGET=16  # 可設定於 .claude/shikigami.local.md

# 補充後驗收條件
if [[ "$SPRINT_CANDIDATE_COUNT" -ge "${REPLENISHMENT_TARGET}" ]]; then
  log action: "backlog-health: HEALTHY count=${SPRINT_CANDIDATE_COUNT} >= target=${REPLENISHMENT_TARGET}"
else
  log action: "backlog-health: BELOW-TARGET count=${SPRINT_CANDIDATE_COUNT} < target=${REPLENISHMENT_TARGET}"
fi
```

### .claude/shikigami.local.md 配置項（建議）

```yaml
shikigami:
  backlog_health:
    threshold: 10           # sprint-candidate 最少數量閾值（舊：8 → 新：10）
    replenishment_target: 16  # 2-Sprint 提前期目標庫存
```

---

## 驗收標準

- [x] ADR-043 文件建立於 docs/adr/ADR-043-backlog-replenishment-strategy.md
- [x] ADR 狀態標記為 Accepted
- [x] #721 更新參照此 ADR（ADR-043）
- AC2（#721 驗收）: Sprint 154 開始後 sprint-candidate 維持 >= 10
- AC3（#721 驗收）: backlog-management/SKILL.md 閾值更新為 10

---

## 影響範圍

| 元件 | 變更 | 負責 |
|------|------|------|
| `skills/backlog-management/SKILL.md` | 閾值從 8 改為 10，補充觸發時機改為執行中觸發 | #721 |
| `.claude/shikigami.local.md` | backlog_health.threshold: 10（當前值為 8） | #721 |
| `skills/cruise/references/po-patrol.md` | 閾值參照改為讀取配置（已使用 backlog_health.threshold） | 無需變更 |

---

## 相關文件

- `docs/sprints/sprint_153.md` — Sprint 153 Review（Retro Action 來源）
- `skills/backlog-management/SKILL.md` — Backlog Discovery 流程（#721 修改目標）
- `docs/km/Metrics_Log.md` — Backlog 健康度指標追蹤
