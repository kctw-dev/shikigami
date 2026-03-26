# 輕量版 Backlog Discovery SOP

**版本**：v1.0  
**建立日期**：2026-03-26  
**Story**：#930（Sprint 176）  
**關聯 Spike**：#887（Discovery 流程最佳化 Spike）

---

## 概述

本文件定義輕量版 Backlog Discovery（S size，<= 1pt）的標準作業程序，
補充完整版 Discovery（M size，2pts）的不足，實現每 Sprint 可執行的增量補充機制。

**設計原則**：
- 範圍聚焦：僅掃描「新增輸入源」，不全量重新評估已有 Issue
- 時間限制：單次執行 < 30 分鐘
- 輸出標準：每次補充 3–6 個品質合格的 sprint-candidate

---

## 為什麼 <= 1pt（AC2 說明）

| 指標 | 完整版（#864, 2pts） | 輕量版（本 SOP, 1pt） |
|------|--------------------|--------------------|
| 掃描範圍 | 全量（所有驗證腳本、架構文件） | 增量（新 ADR、Retro Items、反饋） |
| 估點依據 | 跨多文件分析 + 全 RICE 評分 | 僅聚焦 3 個觸發源，模板化輸出 |
| 預期執行時間 | 60–90 分鐘 | 15–30 分鐘 |
| 預期產出 | 8–12 個新 Issue | 3–6 個新 Issue |

輕量版因掃描範圍固定、輸出模板化，推理複雜度低（Novelty=1, Complexity=1），
故評估為 Score=4（Tier 1），估點 <= 1pt。

---

## 觸發條件（AC3）

增量 Discovery 應在以下任一條件成立時觸發：

| 觸發條件 | 說明 | 頻率建議 |
|---------|------|---------|
| **新 ADR 決策** | 每個新 ADR 通常帶出 1–3 個實作 Issue | 每次 ADR 定案後 |
| **Retro Action Items** | Sprint Retro 產出的 retro-action Issues | 每個 Sprint Review 後 |
| **社群反饋** | 帶 `cruise-feedback` 或 `feature-request` 的 Issue | 每週 Cruise 後 |
| **sprint-candidate 水位低於 8** | `[BACKLOG-REPLENISH-TRIGGER]` 訊號觸發 | 自動偵測（#944 整合） |

**NFR1（可持續性）**：前三個觸發條件為事件驅動，每月至少出現 2–3 次，確保可持續執行。

---

## 執行步驟（SOP）

### Step 1：收集輸入源（5 分鐘）

```bash
# 收集最近 ADR（14 天內新增）
gh issue list -R kctw-dev/shikigami \
  --label "adr" --state open --json number,title,createdAt \
  --jq '[.[] | select(.createdAt > (now - 1209600 | todate))]' 2>/dev/null

# 收集 Retro Action Items（尚未關閉）
gh issue list -R kctw-dev/shikigami \
  --label "retro-action" --state open --json number,title,labels 2>/dev/null

# 收集社群反饋（cruise-feedback 已轉送）
gh issue list -R kctw-dev/shikigami \
  --label "cruise-feedback" --state open --json number,title 2>/dev/null
```

### Step 2：分析與 RICE 評分（10 分鐘）

對每個輸入源，快速判斷可拆出的 sprint-candidate：

- **ADR 決策** → 判斷是否有未完成的實作 Issue
- **Retro Action** → 判斷是否有具體的改善 Issue
- **社群反饋** → 判斷是否符合 Backlog 方向

RICE 快速評分範本：

| 欄位 | 說明 | 預設值 |
|------|------|--------|
| Reach | 受影響的使用者 / session 數 | 1–3 |
| Impact | 問題嚴重程度（1=低, 3=高） | 2 |
| Confidence | 需求清晰度（%） | 70–90% |
| Effort | 估點（S=1, M=2, L=3） | 1–2 |

### Step 3：建立 sprint-candidate Issues（10 分鐘）

每個新 Issue 必須包含：

```markdown
## 背景
<!-- 來自哪個觸發源（ADR #N / Retro #N / 反饋 #N）-->

## 問題
<!-- 具體問題描述 -->

## 驗收條件
- AC1：...
- AC2：...

## RICE Score | <計算值>
```

Issue 建立後立即加 label：`enhancement`, `sprint-candidate`, `size: S|M`, `priority: must|should|could`

### Step 4：更新 Backlog 水位記錄（5 分鐘）

```bash
# 確認水位達標
bash scripts/check-backlog-health.sh --threshold 10

# 留言於觸發 Issue（若由 #944 觸發）
gh issue comment <trigger_issue> -R kctw-dev/shikigami \
  --body "## [Discovery 完成] 輕量版增量 Discovery 執行完畢，補充 N 個 sprint-candidate"
```

---

## 輸出模板（Issue 建立參考）

```bash
# 使用 --body-file 避免特殊字符問題（CLAUDE.md Rule #13）
cat > /tmp/issue-body.txt << 'EOF'
## 背景
<!-- 來源：ADR-XXX / Retro #N / Cruise Feedback #N -->

## 問題
<!-- 描述問題 -->

## 驗收條件
- AC1：
- AC2：

## 非功能性需求
- NFR1：

## RICE Score | <值>
EOF

gh issue create -R kctw-dev/shikigami \
  --title "feat: <描述>" \
  --body-file /tmp/issue-body.txt \
  --label "enhancement,sprint-candidate,size: S,priority: could"
```

---

## 與完整版 Discovery 的關係（NFR2）

| 面向 | 輕量版（本 SOP） | 完整版（#864 模式） |
|------|-----------------|------------------|
| 掃描範圍 | 增量（新輸入源） | 全量（所有文件） |
| 觸發頻率 | 每 Sprint / 每次觸發條件達標 | 每 1–2 Sprint |
| 輸出數量 | 3–6 個 | 8–12 個 |
| 互補性 | 維持日常水位 | 大規模補充 / 方向修正 |

兩個版本互補，**輕量版無法取代完整版**，但可顯著減少完整版的緊迫頻率。

---

## 歷史記錄

| 日期 | 執行者 | 補充數量 | 觸發條件 |
|------|--------|---------|---------|
| 2026-03-26 | Sprint 176 PO-subagent | 4 | sprint-candidate 水位補充（#930 AC4 驗收） |
