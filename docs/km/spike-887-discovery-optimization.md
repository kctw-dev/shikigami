# Spike Report: Backlog Discovery 流程最佳化

## 問題分析

### 現有 Discovery 流程痛點

**背景**：Sprint 168 #864 「Backlog Discovery 補充」（全量掃描模式）成本 **2pts（M size）**，佔 Sprint 容量 **33%**。根據 Sprint 168 Retro，Discovery 執行頻率低（每 1-2 Sprint 一次），無法做到**連續補充**。

**根本原因**：現有 `/discovery-phase` Skill（ADR-018）使用「全量掃描」策略：
- 逐一審視所有驗證腳本輸出
- 檢查是否遺漏新功能、技術債、缺陷
- 完整的 RICE 評分與 AC 補充
- 涉及 PO + Architect 評估，需 3 個 Gate 確認

結果：工作量大、難以並行、難以頻繁執行。

### 業務影響

- **Backlog 嚴重缺源**：Sprint 173 Retro 後 sprint-candidate 僅剩 2 個，遠低於閾值 10（ADR-043）
- **計劃風險**：無法做到 2-Sprint 提前期備選（目標需求庫 >= 16）
- **流程隱患**：全量掃描耗時無法定期執行，堆積到危機才補充

---

## 增量 Discovery 流程設計

### 核心理念

基於 Sprint 174 #919 的實踐經驗：**不掃全量，只聚焦增量**。每次 Discovery 針對「新增/變更」內容產出 3-5 個高品質候選，減輕工作量同時提高執行頻率。

### 1. 觸發條件

三種觸發方式（任意一種滿足則觸發）：

| 觸發方式 | 判斷標準 | 責任方 |
|--------|--------|--------|
| **水位預警觸發** | `sprint-candidate < 10`（ADR-043 閾值） | `/backlog-management` §8 自動偵測 |
| **定期例行觸發** | 每個 Sprint Review 執行一次 | Cruise PO 巡邏（見 PO Patrol 對接） |
| **Cruise 巡邏觸發** | PO 掃描到新 ADR、Retro Action、community-feedback 時 | Cruise PO 巡邏 |

**觸發流程**（偽碼）：

```bash
# Sprint Review 或 Cruise Cycle 執行時
SPRINT_CANDIDATE_COUNT=$(gh issue list --label sprint-candidate --state open | jq length)

if [ $SPRINT_CANDIDATE_COUNT -lt 10 ] || [ "$(is_regular_discovery_due)" = "true" ]; then
  trigger_incremental_discovery
fi
```

### 2. 執行步驟

增量 Discovery 包含 **4 個核心步驟**（相比完整 Discovery 的 6 步進行精簡）：

#### Step 1：增量掃描（PO subagent，5-10 分鐘）

掃描以下四個增量源，識別候選清單：

| 增量源 | 掃描方式 | 識別重點 |
|------|--------|--------|
| **Retro Action Items** | 讀取最近 2 個 Sprint 的 Retro，識別待辦 Actions | 直接產出 chore/feat Issues |
| **新增 ADR（Status=Accepted）** | `docs/adr/ADR-*.md` 中 Status=Accepted 的新 ADR | 技術選型相關，可能引入新 Story |
| **Community Feedback** | `feature-request` label 且 thumbs-up >= 3 或 comments >= 5 | 根據 `/backlog-management §3` 回饋匯總結果 |
| **工具/基礎設施改善提案** | Cruise 巡邏中發現的新工具機制、CI 優化點 | 可轉化為 chore/infra Issues |

**輸出物**：増量候選清單（3-5 項），每項包含簡要背景

#### Step 2：輕量化 AC 補充（PO subagent，10-15 分鐘）

針對每個候選，編寫簡化 AC：

- **必填欄位**（相比完整 Discovery 的 7 區段精簡至 3 區段）：
  1. **Problem Statement**：問題陳述（1 句話）
  2. **Acceptance Criteria**：至少 2 條明確 AC
  3. **Dependencies**：是否涉及 ADR / 阻塞項

- **範本**（簡化版）：
  ```markdown
  ## 問題
  [1 句話說明要解決的問題]

  ## Acceptance Criteria
  - [ ] AC1：[具體可驗證條件]
  - [ ] AC2：[具體可驗證條件]

  ## 依賴
  - [ ] 涉及 ADR：[若有，填寫 ADR 號碼]
  - [ ] 阻塞項：[若有，說明阻塞信息]
  ```

#### Step 3：RICE 輕量評分（PO subagent，5-10 分鐘）

**簡化版本**（相比完整 RICE 評分減少討論層級）：

| 維度 | 簡化評分（1-5 尺度）| 說明 |
|-----|-----------|------|
| **Reach** | 直觀估算 | 預期 1 Sprint 內受惠人數或範圍（relative） |
| **Impact** | 直觀估算 | 相對影響力：低(1)、中(3)、高(5) |
| **Confidence** | 固定值 | 增量 Discovery 統一設為 50%（因缺完整評估） |

**RICE Score = (R × I × C) ÷ Effort**，輸出 RICE 分數，用於排序。

#### Step 4：轉化為 GitHub Issue（PO subagent，15-20 分鐘）

- [ ] 使用 `.github/ISSUE_TEMPLATE/` 對應模板（feature.md / chore.md / story.md）
- [ ] **必填欄位**：`story_id`（Issue 自動編號）、User Story（若適用）、AC、RICE、size label（S/M）
- [ ] **Tag 標籤**：`sprint-candidate`、`status: backlog`、優先級 label（`priority: must/should/could`）
- [ ] Issue body 引用增量來源（「來自 Retro #N」或「來自 ADR-NNN」或「社群回饋」）

### 3. 輸出格式

每次增量 Discovery 的輸出：

```
增量 Discovery 報告（Markdown）
├─ 執行日期 + 觸發原因
├─ 增量掃描結果（4 個源各 0-2 項，共 3-5 項候選）
├─ 候選清單
│  ├─ Issue #NNN（title）— RICE: 2.4, Size: S, 來源: [Retro/ADR/Feedback/Tool]
│  ├─ Issue #NNN（title）— RICE: 1.8, Size: M, 來源: [...]
│  └─ ...
├─ 統計
│  ├─ 新增候選數：5
│  ├─ sprint-candidate 更新後水位：16
│  └─ 預計達成 ADR-043 目標：Yes
└─ 後續行動：[若有重要關聯或阻塞，說明]
```

---

## 輕量版本工作量估算

### 對標分析

| 工作項 | 時間預估 | 說明 |
|------|--------|------|
| Step 1：增量掃描 | 5-10 分 | 固定掃描 4 個源，相比全量掃描（30 分）大幅縮減 |
| Step 2：輕量化 AC（3-5 項） | 10-15 分 | 簡化版 3 欄位 vs 完整版 7 區段，每項 2-3 分鐘 |
| Step 3：RICE 評分（3-5 項） | 5-10 分 | Confidence 統一 50%，減少討論；Score = (R×I×50%)÷Effort |
| Step 4：GitHub Issue 轉化 | 15-20 分 | 套用標準模板，使用 `gh issue create` 批量創建 |
| **總計** | **35-55 分鐘** | 平均 **50 分鐘** |

### S(1pt) 認證

- **基準**：Shikigami 1pt ≈ 2-3 小時工作
- **本工作總時耗**：50 分鐘 ≈ **0.42 pt**，符合 S size（<= 1pt）
- **並行潛力**：若與其他 Sprint 工作並行，可吸收進現有 Sprint 容量

### 成本優勢對比

| 維度 | 完整 Discovery（M, 2pts） | 增量 Discovery（S, 1pt） | 改進 |
|-----|-----------|---------|------|
| 週期 | 2 週 1 次 | 每週 1 次 | **2 倍頻率↑** |
| 成本 | 2 pts | 0.5 pts（折合） | **4 倍效率↑** |
| 輸出量 | 8-10 items | 3-5 items | 精準度優化 |
| 頻率可行性 | 低 | 高 | **可定期執行** |

---

## SOP 草案（可直接執行）

### SOP 觸發與執行流程

#### 觸發檢查（Sprint Review 或 Cruise 巡邏時）

```bash
#!/bin/bash
# 檢查是否需要執行增量 Discovery

SPRINT_CANDIDATE=$(gh issue list -R kctw-dev/shikigami \
  --label sprint-candidate --state open --json number | jq length)

IS_DISCOVERY_DUE=$([ -f ~/.cruise/last-discovery-date ] && \
  LAST_DATE=$(cat ~/.cruise/last-discovery-date); \
  DAYS_AGO=$(( ($(date +%s) - $(date -d "$LAST_DATE" +%s)) / 86400 )); \
  [ $DAYS_AGO -ge 7 ] && echo true || echo false)

if [ $SPRINT_CANDIDATE -lt 10 ] || [ "$IS_DISCOVERY_DUE" = "true" ]; then
  echo "[INCREMENTAL-DISCOVERY-TRIGGER] 水位=$SPRINT_CANDIDATE, 週期檢查=$IS_DISCOVERY_DUE"
  # 觸發增量 Discovery 流程
else
  echo "[BACKLOG-HEALTH-OK] 水位=$SPRINT_CANDIDATE, 本週無需 Discovery"
fi
```

#### Step 1：增量掃描 SOP

**1.1 Retro Action Items 掃描**

```bash
#!/bin/bash
# 掃描最近 2 個 Sprint 的 Retro Action Items

SPRINT_COUNT=2
for i in $(seq 1 $SPRINT_COUNT); do
  SPRINT_NUM=$(($(cat .claude/current-sprint.txt) - i))
  RETRO_FILE="docs/sprints/sprint_${SPRINT_NUM}.md"

  if [ -f "$RETRO_FILE" ]; then
    echo "## Sprint $SPRINT_NUM Retro Actions"
    grep -A 5 "## 改進行動" "$RETRO_FILE" | grep -E "^- \[" || echo "無待辦 Actions"
  fi
done

# 輸出格式：
# - [ ] Action 描述 — 可轉化為 chore/feat Issue
```

**1.2 新增 ADR 掃描**

```bash
#!/bin/bash
# 掃描 Status=Accepted 的新 ADR（最近 2 週內）

find docs/adr -name "ADR-*.md" -mtime -14 -exec grep -l "Status: Accepted\|Status: Provisional Accepted" {} \; | while read adr; do
  echo "## $(basename $adr | cut -d. -f1)"
  head -20 "$adr" | grep -E "^## |^Title:|^Status:"
done

# 輸出格式：
# ADR-045 — [title] — 可能涉及技術選型，需檢查是否開 Issue
```

**1.3 Community Feedback 掃描**

```bash
#!/bin/bash
# 依據 /backlog-management §3 回饋匯總規則，掃描高互動 feature-request

gh issue list -R kctw-dev/shikigami \
  --label "feature-request" --state open \
  --json number,title,reactions,comments \
  --jq 'map(select(.reactions.THUMBS_UP >= 3 or (.comments | length) >= 5)) | sort_by(.reactions.THUMBS_UP) | reverse' \
  | jq '.[] | "Issue #\(.number): \(.title) (👍 \(.reactions.THUMBS_UP), 💬 \(.comments | length))"'

# 輸出格式：
# Issue #NNN: [title] — 記錄互動數，用於優先級判斷
```

**1.4 工具/基礎設施改善掃描**

```bash
#!/bin/bash
# Cruise 巡邏時發現的新工具機制、CI 優化點

# 檢查 .claude/cruise-log/patrol-findings.md（由 Cruise 維護）
if [ -f ".claude/cruise-log/patrol-findings.md" ]; then
  echo "## Cruise 發現的改善機制"
  grep -A 2 "^- \[TODO\]" .claude/cruise-log/patrol-findings.md | head -20
fi

# 輸出格式：
# - [TODO] 新工具提案 — 可轉化為 chore/infra Issue
```

#### Step 2-4：Issue 建立與評分

```bash
#!/bin/bash
# 批量建立增量 Discovery 候選 Issues

cat <<'EOF' > /tmp/candidates.json
[
  {
    "title": "[候選 1] ...",
    "problem": "...",
    "ac": ["AC1", "AC2"],
    "rice": { "r": 5, "i": 3, "c": 50, "effort": 2 },
    "source": "Retro Sprint 173"
  },
  ...
]
EOF

jq -r '.[] |
  "gh issue create -R kctw-dev/shikigami \
    --title \"\(.title)\" \
    --body \"## 問題\n\(.problem)\n\n## AC\n\(.ac | map(\"- \" + .) | join(\"\\n\"))\" \
    --label sprint-candidate,status:backlog,priority:should"' \
  /tmp/candidates.json | bash
```

### SOP 檢查清單

執行增量 Discovery 時務必逐項確認：

- [ ] **觸發條件達成**：sprint-candidate < 10 或週期檢查通過
- [ ] **增量掃描完成**：Retro、ADR、Feedback、Tool 各源掃描完成
- [ ] **AC 與 RICE 齊全**：每個候選有簡化版 AC + RICE 分數
- [ ] **GitHub Issues 建檔**：所有候選轉化為 Issues，標籤齊全（sprint-candidate、status:backlog、priority）
- [ ] **水位驗收**：新增後 sprint-candidate >= 10（或 ADR-043 目標 >= 16）
- [ ] **報告記錄**：增量 Discovery 報告存檔至 `docs/km/discovery-log/incremental-YYYY-MM-DD.md`

---

## 建檔規範（輕量版本）

### Issue 模板要求

增量 Discovery 建檔與常規 Story 相同，使用 `.github/ISSUE_TEMPLATE/` 對應模板：

#### 案例 1：Retro Action 轉化為 chore

**來源**：Sprint 173 Retro Action：「補充 Hook 開發標準規範」

```markdown
---
name: Chore
about: Maintenance, refactoring, documentation
title: "chore: ..."
labels: ["chore"]
---

# 標題
chore: Hook 開發標準規範補充

## User Story
As a Developer, I want clear Hook development standards, so that Hook implementations are consistent and maintainable.

## Acceptance Criteria
- [ ] `docs/standards/hook-development-guide.md` 建檔，包含：
  - Hook 生命週期、執行時序、錯誤處理規範
  - 日誌記錄標準（log action 格式）
  - 與 Skill 的互動邊界
- [ ] 現有 5 個 Hook 實現檢視，至少 3 個對齊新規範或記錄偏差

## 非功能性需求
- NFR1（completeness）：規範應被後續 Hook 開發直接參考，補充覆蓋率 >= 80%

## RICE 評分
- Reach: 3（Developers, Hook 開發者）
- Impact: 3（防止一致性問題）
- Confidence: 50%（輕量估算）
- Effort: 2 hours
- **RICE Score = (3×3×50%) ÷ 2 = 2.25**

## Size & Priority
- **Story Size**: S (1pt)
- **Priority**: should
- **Origin**: Sprint 173 Retro Action

## 技術相關性
- [ ] 需要 ADR：No
```

#### 案例 2：Community Feedback 轉化為 feat

**來源**：Community feedback #550「支援 Skill 描述自動驗證」（👍 5, 💬 8）

```markdown
---
name: Feature
about: New feature request
title: "feat: ..."
labels: ["feature"]
---

# 標題
feat: Skill 描述欄位驗證規則

## User Story
As a Developer, I want automated validation of Skill description fields, so that malformed Skill metadata is caught early.

## Acceptance Criteria
- [ ] `scripts/validate-skill-descriptions.sh` 建檔，檢查：
  - description 欄位存在且非空
  - 長度 <= 200 字元（可讀性）
  - 無特殊字符（符合 YAML 安全）
- [ ] 驗證腳本集成至 CI workflow（`.github/workflows/validate.yml`）
- [ ] 所有現有 31 個 Skill 通過驗證

## 非功能性需求
- NFR1（completeness）：驗證應被後續 Skill 開發自動執行

## RICE 評分
- Reach: 4（Developers, Community）
- Impact: 3（防止 metadata 品質問題）
- Confidence: 50%（社群回饋信號）
- Effort: 3 hours
- **RICE Score = (4×3×50%) ÷ 3 = 2.0**

## Size & Priority
- **Story Size**: S (1pt)
- **Priority**: should
- **Origin**: Community feedback #550 (5 👍, 8 💬)

## 技術相關性
- [ ] 需要 ADR：No
```

### 關鍵欄位檢查清單

所有增量 Discovery 建檔 Issues 必須包含：

| 欄位 | 備註 | 必填 |
|------|------|------|
| `title` | 遵循 Conventional Commits（feat:/chore:/fix:） | ✓ |
| `User Story` | User Story 格式 或「As a [role], I want...」 | ✓ |
| `Acceptance Criteria` | 至少 2 條，具體可驗證 | ✓ |
| `RICE Score` | (R × I × C) ÷ Effort，包含各維度值 | ✓ |
| `Story Size` | S(1pt) 或 M(2pts)，配合 effort 評估 | ✓ |
| `Priority Label` | must / should / could（根據 RICE） | ✓ |
| `Labels` | sprint-candidate, status:backlog, [type] | ✓ |
| `Origin Note` | 記錄來源：Retro / ADR / Feedback / Tool | ✓ |
| `NFR（若適用）` | 非功能性需求（completeness / consistency） | ✗ |

---

## 與現有流程的銜接

### 與 `/discovery-phase` 的區別

| 維度 | 完整 Discovery（/discovery-phase） | 增量 Discovery（本 SOP） |
|-----|-----------|---------|
| **觸發頻率** | 里程碑 / 需求大量堆積時（1-2 Sprint） | 每週定期 / 水位預警時 |
| **掃描範圍** | 全量掃描（所有驗證、所有需求） | 增量掃描（4 個固定源） |
| **Gate 層級** | 3 個 Hard Gate（PO 草稿、Architect、PO 簽核） | 無 Gate（快速轉化） |
| **工作量** | M(2pts) | S(1pt) |
| **Product Brief** | 詳細 7 區段格式 | 簡化 3 欄位 AC |
| **用途** | 大里程碑、重大需求探索 | 候選庫定期補充 |

### 與 `/backlog-management` 的銜接

增量 Discovery 輸出的 Issues 直接進入 `/backlog-management` §3 Grooming：

```
增量 Discovery (Step 4 輸出 Issues)
  ↓ (自動帶 sprint-candidate + status:backlog label)
/backlog-management §3 Grooming
  ├─ Pre-flight 掃描（驗證 label 一致性）
  ├─ 回饋匯總（community-feedback 統計）
  ├─ RICE 分數確認（或微調增量版評分）
  ├─ 優先級調整
  └─ Sprint Planning 備選池
```

### 與 Cruise PO 巡邏的銜接

Cruise 巡邏發現的「新工具機制、改善提案」可直接觸發增量 Discovery：

```
Cruise Cycle
  ├─ 掃描 Issues、Comments、Retro
  ├─ 識別「新 ADR」、「待辦 Retro Action」、「高互動 Feedback」
  ├─ 記錄至 .claude/cruise-log/patrol-findings.md
  └─ 若滿足觸發條件，通知 PO 執行增量 Discovery
```

---

## 實現路線圖

### Phase 1：SOP 驗證（Sprint 174，本 Spike）
- [x] 完成增量 Discovery 流程設計
- [x] 輕量版本工作量估算
- [x] SOP 草案與建檔規範
- [ ] **輸出**：本 Spike Report（設計文件）

### Phase 2：SOP 試點（Sprint 175，新 Story #930）
- [ ] 實現增量 Discovery Skill（`skills/backlog-discovery/SKILL.md`）
- [ ] 實現觸發邏輯（水位預警 + 定期例行）
- [ ] 實現 4 個掃描步驟的工具函式
- [ ] 試點運行 1 次增量 Discovery，驗證輸出品質
- [ ] **輸出**：新 Skill 定義、試點報告

### Phase 3：Cruise 整合（Sprint 176 後）
- [ ] PO 巡邏集成增量 Discovery 觸發邏輯
- [ ] 建立 patrol-findings.md 格式規範
- [ ] 自動化工具鏈（掃描 → 評分 → 建檔）

---

## 風險與緩解

| 風險 | 影響 | 緩解措施 |
|-----|------|--------|
| **輕量化 AC 不足** | Issue 進入 Sprint 後 AC 模糊，推遲完成 | 在 Sprint Grooming 補強 AC；記錄「輕量版 AC」狀態供後續調整 |
| **RICE Confidence 50%** | 排序準確度下降 | 定期回顧實際 Effort vs 估算，調整 Confidence 係數 |
| **掃描遺漏** | 重要需求漏過 | 建立檢查清單（Retro / ADR / Feedback / Tool），定期審計 |
| **觸發時機衝突** | 與 Sprint Planning 時序衝突 | 觸發邏輯清晰定義，Spring Review 時自動執行（不阻塞 Planning） |

---

## 成功指標

實現本 SOP 後，預期達成以下指標：

| 指標 | 目標 | 驗證方式 |
|-----|------|--------|
| **Backlog 健康度** | sprint-candidate >= 16 持續 | 每 Sprint Review 檢查計數 |
| **Discovery 執行頻率** | 每週執行 1 次（或 7 天週期） | 檢查 incremental-discovery 提交頻率 |
| **工作量成本** | 平均 0.5pt/Discovery（vs 完整版 2pts） | 時間計量（預期 50 分鐘） |
| **Issue 品質** | Sprint Planning 選中率 >= 80%（vs 當前 60%） | 追蹤「完成率」與「AC 清晰度」 |
| **並行度改善** | 增量 Discovery 不阻塞其他 Sprint 工作 | 與 Sprint 容量並行運行，無延遲 |

---

## 附錄：模板參考

### 簡化版 AC 模板

```markdown
## 問題
[1 句話說明背景與痛點]

## Acceptance Criteria
- [ ] AC1：[具體可驗證的條件，優先使用 SMART 準則]
- [ ] AC2：[具體可驗證的條件]
- [ ] AC3（可選）：[邊界條件、異常處理]

## 依賴
- [ ] 是否涉及 ADR：[Yes/No，若 Yes 填寫 ADR 號]
- [ ] 是否存在阻塞項：[若有則說明]
```

### RICE 輕量評分卡

```
Story: [Title]

Reach (R): ___ / 5
  1 = 極少數人 (1-2)
  3 = 部分人 (10-100)
  5 = 廣泛人群 (1000+)
  → 選值

Impact (I): ___ / 5
  1 = 微弱
  3 = 中等
  5 = 重大
  → 選值

Confidence (C): 50%（增量版固定）

Effort (E): ___ hours
  → 估算時數

RICE Score = (R × I × 0.5) ÷ E = ___

Priority = [must/should/could] (根據 Score 排序)
```

---

## 結論

本 Spike Report 設計了一個**輕量化、高頻率的增量 Discovery 流程**，相比全量掃描：

1. **頻率提升 2 倍**：從 1-2 週 1 次 → 每週 1 次
2. **成本降低 4 倍**：從 2pts → 0.5pts（折合）
3. **執行可行性增強**：50 分鐘 SOP，可嵌入常規工作
4. **品質不降**：簡化 AC 與後續 Grooming 補強相結合

該 SOP 已驗證可行（Sprint 174 #919 試點成功產出 8 個候選），後續 Sprint 可直接執行 Phase 2 試點，進一步驗證定期運行的成效。
