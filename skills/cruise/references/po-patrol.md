# PO 巡邏指引

**觸發**：每個 cruise cycle 由 Task tool 派遣 PO Agent 執行
**Repo context**：subagent 接收 `REPO_PATH` 與 `OWNER_REPO` 參數，所有 `gh` 指令加 `-R ${OWNER_REPO}`

完整 PO 巡邏邏輯詳見以下各節。

## 掃描 Open Issues

```bash
# 列出所有 open issues（含 comments 欄位）
# 單一 repo 與多 repo 模式均使用 -R ${OWNER_REPO}，統一行為
gh issue list -R ${OWNER_REPO} --state open --limit 50 --json number,title,labels,assignees,updatedAt,comments
```

掃描重點：
- 逾期 Issue（`updatedAt` 超過 7 天未更新且無 assignee）
- 無回應 Issue（已開超過 3 天**且無任何留言**且無 assignee）
- 標記為 `blocked` 或 `needs-triage` 的 Issue
- 有新回覆的 Issue（`comments` 較上次 cycle 增加）

## 留言掃描步驟

對 `comments > 0` 的 Issue，讀取實際留言內容：

```bash
# 讀取有留言的 Issue 完整留言
gh issue view <issue_number> -R ${OWNER_REPO} --json comments
```

**「無回應」判斷標準**（#320 教訓）：

Issue 同時滿足以下條件才視為「無回應」：
1. 無 assignee（`assignees` 為空陣列）
2. 最近 3 天內無任何留言（不論留言者是誰）

```bash
# 判斷邏輯（偽碼）
# THRESHOLD_DAYS：預設 3，strict 模式為 0
for each issue in issues:
  has_assignee = issue.assignees.length > 0
  comment_data = gh issue view issue.number -R ${OWNER_REPO} --json comments
  latest_comment_at = comment_data.comments[-1].createdAt  # 若有留言
  days_since_comment = (now - latest_comment_at) in days

  if not has_assignee and (no comments OR days_since_comment > THRESHOLD_DAYS):
    mark as "無回應"

  # Stakeholder 留言優先標記
  for comment in comment_data.comments:
    if "[PRIORITY]" in comment.body:
      mark issue as "PRIORITY"
      alert PO immediately
```

## 關聯 PR comments 掃描步驟（#389）

對 Issue 掃描完留言後，**若存在關聯 PR**，額外讀取 PR comments，以確保不遺漏 stakeholder 在 PR 上留下的工作指示。

```bash
# 透過 issue timeline 取得關聯 PR（ConnectedEvent / CrossReferencedEvent）
PR_LIST=$(gh issue view ${ISSUE_NUMBER} -R ${OWNER_REPO} \
  --json timelineItems \
  --jq '[.timelineItems.nodes[] | select(.__typename=="ConnectedEvent" or .__typename=="CrossReferencedEvent") | .source | select(.number != null) | {number:.number,state:.state}]' \
  2>/dev/null || echo "[]")

# 對每個關聯 PR，讀取其 comments（含 review comments）
for pr_number in $(echo "$PR_LIST" | jq -r '.[].number // empty'); do
  PR_COMMENT_DATA=$(gh pr view "${pr_number}" -R ${OWNER_REPO} \
    --json comments,reviews,reviewRequests \
    2>/dev/null || echo "{}")
  # 篩選 LAST_PATROL_TIME 之後的新留言，避免重複處理
  NEW_PR_COMMENTS=$(echo "$PR_COMMENT_DATA" | jq --arg since "${LAST_PATROL_TIME}" \
    '[.comments[] | select(.createdAt > $since)]')
done
```

**PR comments 解析規則**：

| 解析項目 | 說明 |
|---------|------|
| 識別 stakeholder / PO 指示 | 留言者為 PO 帳號（如 `KCTW`），或留言內容包含工作指令語義（「按 Issue 切開」、「拆分」、「不要混」等） |
| 時間戳篩選 | 僅處理 `createdAt > LAST_PATROL_TIME` 的新留言，避免重複處理舊指示 |
| 指示方向萃取 | 若留言包含明確動作指令，提取並記錄為 `pr_instruction` |

**PR comments 與 Issue comments 衝突時的優先級規則**（#389 核心修復）：

> **以 PR comments 為準**。PR 是工作實作的直接脈絡，stakeholder 在 PR 上留下的指示通常是對 Issue 描述的細化或修正，時間上更接近實際工作狀態。

```bash
# 優先級偽碼
if pr_instruction 與 issue_instruction 方向矛盾:
  EFFECTIVE_INSTRUCTION = pr_instruction  # PR comments 優先
  log action: "pr-instruction-overrides-issue #${ISSUE_NUMBER} PR#${PR_NUMBER}"
  # 在巡邏留言中說明以 PR 指示為準，避免重複矛盾指令
else:
  EFFECTIVE_INSTRUCTION = merge(issue_instruction, pr_instruction)  # 無矛盾則合併
```

**回歸測試場景（#389 case）**：

- Issue #25 / #28 關聯 PR #29（LinGeorge2/AIO-System）
- PR #29 comment（PO KCTW 留言）：「不要混在一起 按 Issue 把工作切開, 再一一送 PR 來」
- 預期 PO Agent 行為：掃描 PR #29 comments → 識別「拆分」指示 → 留言要求拆分 PR，不催促合併
- 修復前錯誤行為：只看 Issue comments，持續催促合併

## Stakeholder 回覆處置表（#422）

<!-- #422 新增 Stakeholder 回覆處置表 — 明確指示應立即觸發執行 -->

**執行時機**：在 Issue 處置決策表之前執行。對有 comments 的 Issue，先掃描最新 comments 判斷是否有 Stakeholder 回覆。

**Stakeholder 識別**：Issue author 或帶有 MEMBER/OWNER association 的留言者。

| Stakeholder 回覆類型 | 識別關鍵字 | PO 處置 | log action |
|---------------------|-----------|---------|-----------|
| **明確指示** | `先做X`、`改成Y`、`加上Z`、`先規劃`、`先不實作`、直接描述待辦事項 | **立即執行**：依指示內容分流（auto-shoot 或 sprint-candidate），不標 awaiting-reply | `"stakeholder-instruction"` |
| **確認/同意** | `OK`、`好`、`同意`、`approve`、`LGTM`、`merge`、`可以` | **推進**：移至下一階段（merge PR、close Issue、繼續開發） | `"stakeholder-confirm"` |
| **提問/澄清** | `?`、`為什麼`、`能不能`、`怎麼做`、問句格式 | **回答**：PO 嘗試回答；無法回答則標記需人工處理 | `"stakeholder-question"` |
| **拒絕/修改** | `不要`、`不行`、`改成`、`重做`、`不是這樣` | **調整**：依拒絕內容修改方向，重新分流 | `"stakeholder-reject"` |
| **無回覆** | 無新 comments | 走 Issue 處置決策表正常流程 | — |

**冪等規則**：同一 Stakeholder 回覆不重複處理。以 comment ID 判斷是否已處理過。

**優先順序**：Stakeholder 回覆處置表 > Issue 處置決策表。若 Stakeholder 有明確指示，直接依指示執行，不再進入 Issue 處置決策表的判斷。

---

## PO Issue 處置決策表（#343，取代 #340 actionable 判斷）

**全覆蓋強制處置**：每個 open Issue **必須**落入以下其中一格。PO **禁止自行加排除條件**。不允許「掃描完跳過」或「已留言所以跳過」。

**安全前置檢查**（每個 Issue 行動前必先執行）：
- 若 Issue 帶有 `stakeholder` label → 跳過所有行動，記錄 `"skipped": "stakeholder-issue"` 至 cruise log
- George 的 issues 不能代關
- 詳見安全邊界段落（`skills/cruise/SKILL.md`）

| 判斷 | 處置 | 行動 | log action 類型 |
|------|------|------|-----------------|
| **無 label** | **Triage** | `gh issue edit --add-label <label>` 自主加分類 label（AC-6），然後重新判斷此 Issue | `"triage"` |
| **帶 `cruise-feedback` label** | **Feedback Routing** | 讀取 `feedback_routing` 設定，依 `project_level` 決定自動轉送（low）或留言確認（medium/high）（#339） | `"cruise-feedback-routed"` / `"cruise-feedback-pending-confirm"` / `"cruise-feedback-skip"` |
| **Size=S，改動明確** | **auto-shoot** | 標記為 actionable，回傳給主 loop 派 `/shoot` | `"auto-shoot"` |
| **Size=M+，需設計或跨模組** | **排入 Sprint** | `gh issue edit --add-label sprint-candidate` | `"sprint-candidate"` |
| **交付物為規劃/設計文件** | **直接開始** | 識別為「規劃類」Issue（見交付物類型識別），標記為 actionable 或 sprint-candidate（依 Size），**不標記 awaiting-reply** | `"deliverable-planning"` |
| **缺資訊，無法判斷**（交付物類型識別後仍不明確） | **等待回覆** | `gh issue edit --add-label awaiting-reply` + 留言問誰要補什麼 | `"awaiting-reply"` |
| **明確暫停** | **暫停** | `gh issue edit --add-label pending` + 留言說明暫停原因 | `"pending"` |
| **已修復但未關** | **結案** | `require_creator_approval: false`（預設）→ `gh issue close`；`true` → 留言建議關閉 + `awaiting-reply`（PO 自建 Issue 豁免，直接 close） | `"close"` / `"close-pending-approval"` |
| **stakeholder Issue** | **跳過** | 只記錄至 cruise log | `"skipped"` |

**Size 判斷標準**：
- **Size=S**：單一檔案或少數檔案修改、修復方向明確、無需跨模組協調
- **Size=M+**：需要 ADR、跨多個模組、涉及架構變更、需要多人討論

## 交付物類型識別（#412）

<!-- #412 PO 巡邏未正確解讀 Issue 交付物 — 交付物識別邏輯 -->

PO 在判斷 Issue 處置前，**必須**先解析 Issue body 判斷交付物類型。此步驟在 Size 判斷之前執行。

| 交付物類型 | 關鍵字 | 正確處置 |
|-----------|--------|---------|
| **實作類**（需要程式碼） | `實作`、`開發`、`新增功能`、`修復`、`fix`、`feat` | 依 Size 判斷 auto-shoot 或 sprint-candidate |
| **規劃類**（需要文件） | `規劃`、`設計`、`先規劃`、`審查後再實作`、`先不實作`、`plan` | **不標記 awaiting-reply**。交付物已明確（規劃文件），直接開始撰寫規劃 |
| **調查類**（需要分析報告） | `調查`、`分析`、`評估`、`research`、`POC` | **不標記 awaiting-reply**。交付物已明確（調查報告），直接開始調查 |

**`awaiting-reply` 使用限制**（#412 根因修正）：

`awaiting-reply` **僅適用於**以下情境：
- Issue 描述本身存在歧義，無法確定範圍
- 缺少必要的技術前提資訊
- 需要 stakeholder 確認優先順序衝突

**不應**用於交付物已明確定義的情況。當 Issue body 包含「先規劃再實作」、「先規劃給我審查」等明確指示時，交付物為**規劃文件**，無需澄清，應直接開始作業。

**PO 自主加分類 label（AC-6）**：除了流程性 label（`stakeholder`）需人工決定，其餘分類 label（`research`、`enhancement`、`bug`、`feature-request` 等）PO 直接 `gh issue edit --add-label` 加上，不需「建議」等人操作。

## 處置決策偽碼（AC-1）

```bash
# 偽碼：每個 open Issue 必須有處置結果，禁止跳過
ACTIONABLE_ISSUES=()
SPRINT_CANDIDATES=()

for each issue in issues:
  # ── 安全前置 ──
  if "stakeholder" in issue.labels:
    log action: "skipped #<issue.number>: stakeholder-issue"
    continue

  # ── Step 0.5：讀取關聯 PR comments（#389），取得 EFFECTIVE_INSTRUCTION ──
  # 執行「關聯 PR comments 掃描步驟」段落的邏輯
  # PR comments 與 Issue comments 有矛盾時，以 PR comments 為準
  EFFECTIVE_INSTRUCTION = merge_with_pr_priority(issue_comments, pr_comments)
  # log 若有覆蓋：log action: "pr-instruction-overrides-issue #<issue.number> PR#<pr.number>"

  # ── Step 0.7：Stakeholder 回覆處置（#422，在 Issue 處置決策表之前執行）──
  if issue.comments > 0:
    latest_stakeholder_comment = get_latest_stakeholder_comment(issue)
    if latest_stakeholder_comment is not None AND not already_processed(latest_stakeholder_comment.id):
      reply_type = classify_stakeholder_reply(latest_stakeholder_comment)
      if reply_type == "instruction":
        # 明確指示 → 立即執行，不進入 Issue 處置決策表
        log action: "stakeholder-instruction #<issue.number>"
        # 依指示內容分流（auto-shoot 或 sprint-candidate）
        continue
      elif reply_type == "confirm":
        log action: "stakeholder-confirm #<issue.number>"
        # 推進至下一階段
        continue
      elif reply_type == "question":
        log action: "stakeholder-question #<issue.number>"
        # PO 嘗試回答
      elif reply_type == "reject":
        log action: "stakeholder-reject #<issue.number>"
        # 調整方向後重新分流

  # ── Step 1：無 label → 先 Triage（PO 自主加 label）──
  if issue.labels is empty:
    # PO 判斷 Issue 類型，直接加 label（AC-6）
    gh issue edit issue.number -R ${OWNER_REPO} --add-label <判斷的 label>
    log action: "triage #<issue.number>"
    # 加完 label 後繼續判斷此 Issue（不跳過）

  # ── Step 1.5：cruise-feedback label → Feedback Routing（#339）──
  if "cruise-feedback" in issue.labels:
    # 讀取 feedback_routing 設定（.claude/shikigami.local.md）
    FEEDBACK_DEFAULT=$(grep -A10 'feedback_routing:' "$CONFIG_FILE" 2>/dev/null \
      | grep 'default:' | awk '{print $2}' | head -1)
    FEEDBACK_TARGET="${FEEDBACK_DEFAULT:-kctw-dev/shikigami}"

    if [[ "$PROJECT_LEVEL" == "low" ]]; then
      # low：自動建 Issue 到目標 repo，事後通知
      FEEDBACK_TITLE="[Cruise Feedback] ${issue.title}"
      EXISTING_FEEDBACK=$(gh issue list -R "${FEEDBACK_TARGET}" \
        --search "\"${FEEDBACK_TITLE}\"" --state all --json number,title \
        2>/dev/null || echo "[]")
      if echo "$EXISTING_FEEDBACK" | jq -e '. | length > 0' &>/dev/null; then
        log action: "cruise-feedback-skip #<issue.number>: duplicate in ${FEEDBACK_TARGET}"
      else
        gh issue create -R "${FEEDBACK_TARGET}" \
          --title "${FEEDBACK_TITLE}" \
          --body "## [Cruise Feedback] 自動轉送

原始 Issue：${OWNER_REPO}#${issue.number}
標題：${issue.title}

---

${issue.body}

---
> 此 Issue 由 Cruise Feedback Routing 自動建立。
> 來源：${OWNER_REPO}#${issue.number}，Session: ${SESSION_ID}" \
          --label "cruise-feedback,feature-request"
        log action: "cruise-feedback-routed #<issue.number> → ${FEEDBACK_TARGET}"
        # 轉送成功後移除 label，避免下一 cycle 重複處理
        gh issue edit issue.number -R ${OWNER_REPO} --remove-label cruise-feedback
      fi
    else
      # medium / high：PO 留言確認，不自動建 Issue（冪等：已有 [巡邏狀態：Feedback Routing] 留言則跳過）
      gh issue comment issue.number -R ${OWNER_REPO} --body "## [巡邏狀態：Feedback Routing]

此 Issue 標有 \`cruise-feedback\` label，判斷屬於框架層級改善建議。

建議回報至：**${FEEDBACK_TARGET}**

project_level=${PROJECT_LEVEL}，請確認是否轉送。

- 巡邏時間：$(date '+%Y-%m-%dT%H:%M:%S')
- Session: ${SESSION_ID}
- Cycle: ${CYCLE}"
      log action: "cruise-feedback-pending-confirm #<issue.number>: notify only (project_level=${PROJECT_LEVEL})"
    fi
    continue

  # ── Step 2：超時自動關閉（AC-4）──
  if "awaiting-reply" in issue.labels OR "pending" in issue.labels:
    label_added_at = issue.updatedAt  # 以最後更新時間近似
    hours_since = (now - label_added_at) in hours
    if hours_since >= 2:
      gh issue close issue.number -R ${OWNER_REPO} \
        --comment "## [自動關閉]

此 Issue 標記為 $(label)，超過 2 小時未回應，自動關閉。
如需重新開啟，請留言說明。

- 關閉時間：$(date '+%Y-%m-%dT%H:%M:%S')
- Session: ${SESSION_ID}"
      log action: "auto-close #<issue.number>"
      continue
    else:
      # 未超時，維持等待狀態（AC-1：仍須記錄處置結果，不靜默跳過）
      log action: "waiting #<issue.number>: <hours_since>h elapsed"
      continue

  # ── Step 3：已修復未關 → 結案（#338：close_policy 控制）──
  # 檢查是否有關聯 PR 已 merged
  if issue 有關聯 PR 且 PR 已 merged:
    if issue 非 George 的 Issue:
      # 讀取此 repo 的 close_policy 設定
      # 豁免條件：PO 自建（issue.author == 當前 PO / bot）→ 直接 close
      IS_PO_ISSUE = (issue.author is PO agent or system bot)

      if REQUIRE_CREATOR_APPROVAL == "true" AND NOT IS_PO_ISSUE:
        # 需要發 Issue 人同意 → 留言建議關閉 + awaiting-reply
        REPO_TIMEOUT=$(get_close_timeout "${OWNER_REPO}")
        gh issue edit issue.number -R ${OWNER_REPO} --add-label awaiting-reply
        gh issue comment issue.number -R ${OWNER_REPO} --body "## [巡邏狀態：已修復] 建議關閉

關聯 PR 已合併，此 Issue 看起來已修復。

如無異議，將在 ${REPO_TIMEOUT} 後自動關閉。如需保持開啟，請回覆說明。

- 巡邏時間：$(date '+%Y-%m-%dT%H:%M:%S')
- Session: ${SESSION_ID}
- Cycle: ${CYCLE}"
        log action: "close-pending-approval #<issue.number>"
        # 留言後交由 Step 2 超時機制統一處理（awaiting-reply label）
        continue
      else:
        # require_creator_approval == false，或 PO 自建 Issue → 直接 close
        gh issue close issue.number -R ${OWNER_REPO} \
          --comment "## [巡邏狀態：已修復] 關聯 PR 已合併，結案。"
        log action: "close #<issue.number>"
        continue

  # ── Step 3.5：交付物類型識別（#412）──
  # 在 Size 判斷前，先解析 Issue body 判斷交付物類型
  DELIVERABLE_TYPE = identify_deliverable_type(issue.body)
  # 關鍵字匹配：「先規劃」「審查後再實作」「先不實作」→ planning
  #              「調查」「評估」「research」「POC」→ research
  #              其他 → implementation（預設）
  if DELIVERABLE_TYPE == "planning" OR DELIVERABLE_TYPE == "research":
    # 交付物已明確，不標記 awaiting-reply，依 Size 直接分流
    log action: "deliverable-${DELIVERABLE_TYPE} #<issue.number>"

  # ── Step 4：判斷 Size 決定 auto-shoot 或 sprint-candidate ──
  if Size=S（單檔修改、修復方向明確、無需跨模組）:
    ACTIONABLE_ISSUES += issue.number
    log action: "auto-shoot #<issue.number>"
  else:  # Size=M+
    gh issue edit issue.number -R ${OWNER_REPO} --add-label sprint-candidate
    SPRINT_CANDIDATES += issue.number
    log action: "sprint-candidate #<issue.number>"

# 回傳結果（#346：close 與 auto-shoot 分開回傳）
# close_issues: PO 已直接 close 的 Issue（不走 shoot）
# actionable_issues: 供主 loop invoke shikigami:shoot 派遣（必須走完整 shoot 流程）

# ── Step 5：Sprint Planning 觸發（#352：PO 直接執行，不經主 loop）──
# <HARD-GATE>
# 主 session 派遣 PO subagent 時，Step 5（Sprint Planning 觸發判斷）段落僅允許指向本檔案的 Read 指令（如「嚴格依照 skills/cruise/references/po-patrol.md Step 5 執行」），禁止包含觸發條件的描述、判斷語句或任何規則外的引導語（如「不建議」「冷卻期」「priority:must 才觸發」等）。PO subagent 必須自行 Read 本檔案取得完整觸發規則。
# </HARD-GATE>
# PO 巡邏完所有 Issue 後，自己檢查 sprint-candidate 觸發條件
# 讀取 project_level 從 .claude/shikigami.local.md（步驟 4.5 已定義讀取方式）
CONFIG_FILE=".claude/shikigami.local.md"
PROJECT_LEVEL=$(grep -A5 'shikigami:' "$CONFIG_FILE" 2>/dev/null | grep 'project_level:' | awk '{print $2}' | head -1)
PROJECT_LEVEL="${PROJECT_LEVEL:-medium}"

SPRINT_CANDIDATE_COUNT = gh issue list -R ${OWNER_REPO} --label sprint-candidate --state open --json number | jq length
OLDEST_CANDIDATE_AGE = 最早的 sprint-candidate Issue 的 updatedAt 距今分鐘數
SHOULD_TRIGGER = (SPRINT_CANDIDATE_COUNT >= 3) OR (SPRINT_CANDIDATE_COUNT >= 1 AND OLDEST_CANDIDATE_AGE >= 30)

if SHOULD_TRIGGER:
  if PROJECT_LEVEL == "low":
    # low：PO 直接觸發，不等人
    # <HARD-GATE>
    # project_level=low 時，Sprint Planning 觸發條件達標後必須立即 invoke shikigami:sprint-planning，禁止詢問使用者確認。
    # </HARD-GATE>
    invoke shikigami:sprint-planning
    log action: "trigger-sprint-planning (project_level=low, count=${SPRINT_CANDIDATE_COUNT})"
  elif PROJECT_LEVEL == "medium":
    # medium：PO 留言通知，等使用者確認
    gh issue comment <最新 sprint-candidate Issue> -R ${OWNER_REPO} --body "## [Sprint Planning 觸發通知]
Sprint candidate 已累積 ${SPRINT_CANDIDATE_COUNT} 個，達到觸發條件。
project_level=medium，請確認是否啟動 Sprint Planning。"
    log action: "sprint-planning-notify (project_level=medium, count=${SPRINT_CANDIDATE_COUNT})"
  else:  # high
    # high：只標記，不觸發不通知
    log action: "sprint-planning-marked (project_level=high, count=${SPRINT_CANDIDATE_COUNT})"

# ── Step 5.5：Sprint 實質完成偵測（#434）──
# 條件：Sprint 中所有 Story 均帶 blocked label → 判定 Sprint 實質完成，允許推進
# 目的：避免外部依賴阻塞時 Sprint 名義進行中卻無法推進 backlog 的問題
BLOCKED_SPRINT_STORIES=$(gh issue list -R ${OWNER_REPO} --label "status: in-sprint" --label "blocked" --state open --json number | jq length)
TOTAL_SPRINT_STORIES=$(gh issue list -R ${OWNER_REPO} --label "status: in-sprint" --state open --json number | jq length)
EFFECTIVELY_COMPLETE=$(( TOTAL_SPRINT_STORIES > 0 && BLOCKED_SPRINT_STORIES == TOTAL_SPRINT_STORIES ))

if [[ "$EFFECTIVELY_COMPLETE" -eq 1 ]]; then
  # Sprint 實質完成：所有 in-sprint Story 均 blocked，允許 bypass
  if [[ "$PROJECT_LEVEL" == "low" ]]; then
    # low：自動觸發 Sprint Review，將 blocked Story 回流 backlog
    # <HARD-GATE>
    # project_level=low 時，Sprint 實質完成後必須立即 invoke shikigami:sprint-review，禁止詢問使用者確認。
    # </HARD-GATE>
    invoke shikigami:sprint-review
    log action: "sprint-effectively-complete-bypass (project_level=low, blocked=${BLOCKED_SPRINT_STORIES}, total=${TOTAL_SPRINT_STORIES})"
  elif [[ "$PROJECT_LEVEL" == "medium" ]]; then
    # medium：留言通知等使用者確認是否觸發 Sprint Review
    FIRST_BLOCKED_ISSUE=$(gh issue list -R ${OWNER_REPO} --label "status: in-sprint" --label "blocked" --state open --json number --jq '.[0].number')
    gh issue comment ${FIRST_BLOCKED_ISSUE} -R ${OWNER_REPO} --body "## [巡邏狀態：Sprint 實質完成]

Sprint 中所有 ${TOTAL_SPRINT_STORIES} 個 Story 均被外部依賴阻塞（blocked）。

Sprint 已實質完成，建議觸發 Sprint Review 將阻塞 Story 回流 backlog，推進下一個 Sprint。

project_level=medium，請確認是否觸發 Sprint Review。

- 阻塞 Story 數：${BLOCKED_SPRINT_STORIES} / ${TOTAL_SPRINT_STORIES}
- 巡邏時間：$(date '+%Y-%m-%dT%H:%M:%S')
- Session: ${SESSION_ID}
- Cycle: ${CYCLE}"
    log action: "sprint-effectively-complete-notify (project_level=medium, blocked=${BLOCKED_SPRINT_STORIES}, total=${TOTAL_SPRINT_STORIES})"
  else:  # high
    # high：只標記，不觸發不通知
    log action: "sprint-effectively-complete-marked (project_level=high, blocked=${BLOCKED_SPRINT_STORIES}, total=${TOTAL_SPRINT_STORIES})"
  fi
fi

# ── Step 6：閒置偵測（#331-子2）──
# 條件：無進行中 Sprint + 無進行中 Shoot + Backlog 有 open issues → 觸發 Sprint Planning
IN_SPRINT_COUNT = gh issue list -R ${OWNER_REPO} --label "status: in-sprint" --state open --json number | jq length
BACKLOG_COUNT   = gh issue list -R ${OWNER_REPO} --state open --json number | jq length

if [[ "$IN_SPRINT_COUNT" -eq 0 && ! -f "$SHOOT_FLAG" && "$BACKLOG_COUNT" -gt 0 ]]; then
  # 閒置狀態：無 Sprint、無 Shoot、backlog 有東西
  if [[ "$PROJECT_LEVEL" == "low" ]]; then
    # low：直接觸發 Sprint Planning
    # <HARD-GATE>
    # project_level=low 時，閒置偵測條件達標後必須立即 invoke shikigami:sprint-planning，禁止詢問使用者確認。
    # </HARD-GATE>
    invoke shikigami:sprint-planning
    log action: "idle-trigger-sprint-planning (project_level=low, backlog=${BACKLOG_COUNT})"
  elif [[ "$PROJECT_LEVEL" == "medium" ]]; then
    # medium：留言通知，等使用者確認
    FIRST_BACKLOG_ISSUE=$(gh issue list -R ${OWNER_REPO} --state open --json number --jq '.[0].number')
    gh issue comment ${FIRST_BACKLOG_ISSUE} -R ${OWNER_REPO} --body "## [巡邏狀態：閒置偵測]

Backlog 有 ${BACKLOG_COUNT} 個 open issues，但無進行中 Sprint 與 Shoot。

project_level=medium，請確認是否啟動 Sprint Planning。

- 巡邏時間：$(date '+%Y-%m-%dT%H:%M:%S')
- Session: ${SESSION_ID}
- Cycle: ${CYCLE}"
    log action: "idle-detected-notify (project_level=medium, backlog=${BACKLOG_COUNT})"
  else:  # high
    # high：只記錄，不觸發
    log action: "idle-detected-marked (project_level=high, backlog=${BACKLOG_COUNT})"
fi
```

## 背景 Agent 進度追蹤（#331-子3）

PO 巡邏在每個 cycle 偵測 subagent 是否有新產出，避免背景工作完成但無人推進。

```bash
# ── 背景 Agent 進度偵測 ──
# fallback 視窗：從 .claude/shikigami.local.md 讀取 cruise.progress_fallback_window（預設 30m）
LOCAL_CONFIG="${REPO_PATH}/.claude/shikigami.local.md"
FALLBACK_WINDOW_RAW=$(grep 'progress_fallback_window:' "${LOCAL_CONFIG}" 2>/dev/null | awk '{print $2}' | head -1)
FALLBACK_MINUTES=30
if [[ -n "$FALLBACK_WINDOW_RAW" ]]; then
  # 支援 30m / 60m / 1h 格式
  if [[ "$FALLBACK_WINDOW_RAW" =~ ^([0-9]+)h$ ]]; then
    FALLBACK_MINUTES=$(( ${BASH_REMATCH[1]} * 60 ))
  elif [[ "$FALLBACK_WINDOW_RAW" =~ ^([0-9]+)m$ ]]; then
    FALLBACK_MINUTES="${BASH_REMATCH[1]}"
  fi
fi

# 上次巡邏時間：從 JSONL log 讀取，取最近一筆 timestamp；首次 cycle 用 fallback 視窗前
LAST_PATROL_TIME=$(jq -r 'select(.type=="po-patrol") | .timestamp' "${CRUISE_LOG}" 2>/dev/null \
  | sort | tail -1)
if [[ -z "$LAST_PATROL_TIME" ]]; then
  LAST_PATROL_TIME=$(date -d "${FALLBACK_MINUTES} minutes ago" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null \
    || date -v-${FALLBACK_MINUTES}M '+%Y-%m-%dT%H:%M:%S' 2>/dev/null \
    || date '+%Y-%m-%dT%H:%M:%S')
fi

# 1. 偵測 git log 新 commit（自上次巡邏以來）
NEW_COMMITS=$(git -C "${REPO_PATH}" log --since="${LAST_PATROL_TIME}" --oneline 2>/dev/null)

# 2. 偵測 docs/sprints/subagent-results/ 新增檔案（自上次巡邏以來）
SUBAGENT_RESULTS_DIR="${REPO_PATH}/docs/sprints/subagent-results"
NEW_RESULT_FILES=""
if [[ -d "$SUBAGENT_RESULTS_DIR" ]]; then
  NEW_RESULT_FILES=$(find "$SUBAGENT_RESULTS_DIR" -newer "${CRUISE_LOG}" -name "*.md" 2>/dev/null \
    | sort | tr '\n' ' ')
fi

# 3. 有新進度 → 對相關 Issue 留言更新狀態
if [[ -n "$NEW_COMMITS" || -n "$NEW_RESULT_FILES" ]]; then
  echo "[PO] 偵測到新進度，更新相關 Issue 狀態"
  # 從 commit message 或 subagent result 檔名推導 issue number
  # 留言格式：「## [巡邏狀態：進度更新] ...」
fi
```

## Auto-shoot 連續派遣

詳見 [auto-shoot.md](./auto-shoot.md)

## 留言語意狀態表（#340）

PO 巡邏每 cycle 判斷 Issue 當前所處狀態，選擇對應語意模板留言。此表**取代**原有的固定催促留言模板（SSOT）。

| 狀態 | 判斷依據 | 留言語意 | 留言範例 |
|------|---------|---------|---------|
| **未處理** | 無 assignee + 無留言或留言超過 threshold | 催促/提醒 | 「此 Issue 已逾期未更新，請相關負責人確認狀態」 |
| **等待回覆** | `awaiting-reply` label | 告知等待對象 | 「等待 @someone 補充環境資訊」 |
| **排隊中** | Issue 為 actionable + `SHOOT_FLAG` 存在（另一 shoot 進行中） | 告知排序 | 「已排入修復佇列，前方有 1 個修復進行中」 |
| **處理中** | Issue 為當前 auto-shoot 目標（`SHOOT_FLAG` 內容 = 此 issue number） | 進度回報 | 「已派工修復，shoot 執行中…」 |
| **PR 已開** | 關聯 PR 存在且 state=open | 交付追蹤 | 「PR #N 已開，待 review」 |
| **已修復** | 關聯 PR merged + CI passing | 結案確認 | 「修復已合併，CI 恢復正常」 |

**狀態判斷順序**（優先高→低）：
1. 已修復（PR merged + CI pass）→ 留言結案
2. PR 已開 → 留言追蹤 PR
3. 處理中（SHOOT_FLAG 內容 = issue number）→ 留言進度
4. 排隊中（actionable + SHOOT_FLAG 存在）→ 留言排序
5. 等待回覆（`awaiting-reply` label）→ 留言等待對象
6. 未處理（default）→ 催促/提醒

**冪等規則**：同一狀態下，若上一則留言已是該狀態的自動留言，不重複留言。狀態轉換時（如「排隊中」→「處理中」），留一則新狀態留言。

**留言操作選擇規則（#409）**：每次巡邏前，先判斷 Issue 最後一則留言的作者是否為當前巡邏 bot。若是，則**編輯既有留言**追加本次巡邏資訊，而非發新留言（避免通知噪音）。只有在其他人於上次巡邏後回應過，才發新留言。

| 情境 | 操作 | 指令 |
|------|------|------|
| 最後留言作者 = 巡邏 bot 且狀態未變 | 編輯既有留言（PATCH） | `gh api -X PATCH repos/{owner}/{repo}/issues/comments/{comment_id} -f body="..."` |
| 最後留言作者 = 巡邏 bot 且狀態改變 | 編輯既有留言，更新狀態標題 | `gh api -X PATCH repos/{owner}/{repo}/issues/comments/{comment_id} -f body="..."` |
| 最後留言作者 ≠ 巡邏 bot（他人已回應） | 發新留言（POST） | `gh issue comment <issue_number> -R ${OWNER_REPO} --body "..."` |
| Issue 尚無任何留言 | 發新留言（POST） | `gh issue comment <issue_number> -R ${OWNER_REPO} --body "..."` |

```bash
# 留言操作邏輯（#409：編輯優先）
COMMENTS=$(gh issue view <issue_number> -R ${OWNER_REPO} --json comments -q '.comments')
LAST_COMMENT_AUTHOR=$(echo "$COMMENTS" | jq -r '.[-1].author.login // empty')
LAST_COMMENT_ID=$(echo "$COMMENTS" | jq -r '.[-1].databaseId // empty')
BOT_ACTOR="${GITHUB_ACTOR:-github-actions[bot]}"  # 巡邏 bot 的 login

PATROL_BODY="## [巡邏狀態：<狀態名稱>]

<對應語意的留言內容>

- 巡邏時間：$(date '+%Y-%m-%dT%H:%M:%S')
- Session: ${SESSION_ID}
- Cycle: ${CYCLE}"

if [[ -n "$LAST_COMMENT_ID" && "$LAST_COMMENT_AUTHOR" == "$BOT_ACTOR" ]]; then
  # 最後留言是自己的巡邏留言 → 編輯（不發新通知）
  gh api -X PATCH "repos/${OWNER_REPO}/issues/comments/${LAST_COMMENT_ID}" \
    -f body="${PATROL_BODY}"
else
  # 尚無留言，或他人已回應 → 發新留言
  gh issue comment <issue_number> -R ${OWNER_REPO} --body "${PATROL_BODY}"
fi
```

## 交付推進自動化（#338：per-repo delivery_chain）

**交付鏈深度**由 `delivery_chain` per-repo 設定控制（詳見 ADR-029）：

| `delivery_chain` 值 | 交付終點 |
|--------------------|---------|
| `production`（預設） | `staging → E2E → tag → production → close`（完整鏈） |
| `pr` | PR merge 即視為交付完成，直接 close Issue |
| `none` | 跳過交付追蹤，不推進交付步驟 |

PR merge 後若交付鏈卡住，自動推進下一步：

```bash
# 偽碼：PR merge → 自動推進交付鏈（per-repo delivery_chain）
SPRINT_FILE=$(ls ${REPO_PATH}/docs/sprints/sprint_*.md 2>/dev/null | sort -V | tail -1)
# 讀取 Sprint Backlog，找出狀態為「PR merged / 待部署」的 Story

# 取得此 repo 的 delivery_chain 設定（步驟 4.6 定義的 get_delivery_chain 函式）
REPO_DELIVERY_CHAIN=$(get_delivery_chain "${OWNER_REPO}")

if [[ "$REPO_DELIVERY_CHAIN" == "none" ]]; then
  # none → 跳過交付追蹤
  log: "skip delivery-chain for ${OWNER_REPO}：delivery_chain=none"
else:
  for each story in backlog:
    pr_status = gh pr view <pr_number> -R ${OWNER_REPO} --json merged,mergedAt,state
    if pr_status.merged == true:
      if [[ "$REPO_DELIVERY_CHAIN" == "pr" ]]; then
        # pr → PR merge 即完成，直接結案
        gh issue close <story.issue> -R ${OWNER_REPO} \
          --comment "## [交付完成] PR 已合併，delivery_chain=pr，結案。"
        log action: "delivery-close #<story.issue>（delivery_chain=pr）"
      else:  # production（預設）→ 完整交付鏈
        # 前置條件檢查（推進前檢查，避免跳步）
        # 1. staging：確認 PR merge 已完成 + CI 狀態為 passing
        # 2. E2E：確認 staging 部署成功
        # 3. tag：確認 E2E 通過
        # 4. production：確認 tag 建立
        # 5. close：確認 production 部署完成

        next_step = determine_next_delivery_step(story)
        if next_step and precondition_met(next_step):
          execute_delivery_step(next_step)
          log action: "push-delivery #<story.issue> → <next_step>"
        else:
          log: "skip push-delivery #<story.issue>：precondition not met for <next_step>"
```

## 交付追蹤

確認 in-sprint Story 進度：

```bash
# 搜尋當前 Sprint 的 Story
SPRINT_FILE=$(ls ${REPO_PATH}/docs/sprints/sprint_*.md 2>/dev/null | sort -V | tail -1)
# 讀取 Sprint Backlog，確認各 Story 狀態
# 對「進行中」超過預期天數的 Story 留言確認
```

## PO 巡邏結果格式

```json
{
  "session_id": "<SESSION_ID>",
  "cycle": <N>,
  "timestamp": "<ISO8601>",
  "type": "po-patrol",
  "repo": "<OWNER_REPO>",
  "strict": true,
  "threshold_days": <THRESHOLD_DAYS>,
  "project_level": "<PROJECT_LEVEL>",
  "summary": "掃描 <X> 個 open issues，發現 <Y> 個逾期，<Z> 個無回應",
  "actions": ["triage #<N1>", "auto-shoot #<N2>", "sprint-candidate #<N3>", "awaiting-reply #<N4>", "pending #<N5>", "close #<N6>", "close-pending-approval #<N7>", "auto-close #<N8>", "waiting #<N9>: Xh elapsed", "skipped #<N10>: stakeholder-issue"],
  "actionable_issues": [<issue_numbers>],
  "sprint_candidates": [<issue_numbers>]
}
```

> **嚴格模式備注**：`strict` 時 `"strict": true`，`threshold_days: 0`；預設模式 `"strict": false`，`threshold_days: 3`。

---

## 安全邊界

### Stakeholder Issue — 不自動行動

**判斷標準**：Issue 帶有 `stakeholder` label → 視為 Stakeholder Issue。

**行為規則**：

| 條件 | 行動 |
|------|------|
| Issue 有 `stakeholder` label | **只記錄**至 cruise log，不執行任何自動行動 |
| Issue 無 `stakeholder` label | 正常執行 PO Issue 處置決策表 |

**Log 格式**：

```json
{
  "actions": ["skipped #<N>: stakeholder-issue"]
}
```

即 `"skipped"` 欄位標注 `"stakeholder-issue"`，標示 Stakeholder Issue 已被掃描但跳過自動行動。

**設計理由**：Stakeholder Issue 涉及外部關係，由 PO 人工判斷後介入，避免自動行動造成不當回覆或影響關係管理。

---

**PO 巡邏 actions 行動類型說明**（#343）：

| 類型 | 說明 |
|------|------|
| `"triage"` | 無 label Issue，PO 自主加分類 label |
| `"cruise-feedback-routed"` | 帶 `cruise-feedback` label 的 Issue，自動轉送建 Issue 至目標 repo（project_level=low）（#339） |
| `"cruise-feedback-pending-confirm"` | 帶 `cruise-feedback` label 的 Issue，留言確認後等人轉送（project_level=medium/high）（#339） |
| `"cruise-feedback-skip"` | 帶 `cruise-feedback` label 的 Issue，目標 repo 已有相同 Issue，跳過重複建立（#339） |
| `"auto-shoot"` | Size=S Issue 標記為 actionable，供主 loop 連續派工 |
| `"sprint-candidate"` | Size=M+ Issue，加 `sprint-candidate` label |
| `"awaiting-reply"` | 缺資訊，加 `awaiting-reply` label + 留言 |
| `"pending"` | 暫停，加 `pending` label + 留言 |
| `"close"` | 已修復未關，結案 |
| `"auto-close"` | `awaiting-reply`/`pending` 超過 2h 未回應，自動關閉（AC-4） |
| `"waiting"` | `awaiting-reply`/`pending` 未超時，維持等待（AC-1 全覆蓋） |
| `"skipped"` | Stakeholder Issue 跳過（含 reason） |

# ── Step 5.6：Backlog 健康度檢查與信號消費（#698）──

## Backlog 健康度信號消費

Sprint Review 流程（`skills/sprint-review/SKILL.md` §2.7）在完成 Issue 狀態回寫後，執行 Backlog 健康度檢查，若 sprint-candidate 數量低於閾值，產生 `[BACKLOG-REPLENISH-TRIGGER]` 信號。

**信號消費流程**（cruise PO-patrol 偵測）：

```bash
# 偽碼：PO-patrol 掃描完成後，檢查是否有待消費的 [BACKLOG-REPLENISH-TRIGGER] 信號
# 信號來源：前次 Sprint Review 的 cruise log 中 type="backlog-health" 且 signal="[BACKLOG-REPLENISH-TRIGGER]"

# 讀取最新 backlog-health log entry
LATEST_BACKLOG_LOG=$(tail -50 docs/cruise-logs/*.jsonl | grep '"type":"backlog-health"' | tail -1)

if [[ -n "$LATEST_BACKLOG_LOG" ]] && echo "$LATEST_BACKLOG_LOG" | jq -e '.signal == "[BACKLOG-REPLENISH-TRIGGER]"' > /dev/null 2>&1; then
  # 信號已偵測，執行信號消費
  SPRINT_CANDIDATE_COUNT=$(echo "$LATEST_BACKLOG_LOG" | jq '.sprint_candidate_count')
  THRESHOLD=$(echo "$LATEST_BACKLOG_LOG" | jq '.threshold')
  
  echo "[BACKLOG-REPLENISH-TRIGGER] 偵測到：sprint-candidate=$SPRINT_CANDIDATE_COUNT < threshold=$THRESHOLD"
  
  # 根據 project_level 執行 Backlog Discovery
  if [[ "$PROJECT_LEVEL" == "low" ]]; then
    # low：自動觸發 Backlog Discovery
    echo "project_level=low，自動執行 Backlog Discovery"
    invoke shikigami:backlog-discovery
    log action: "backlog-replenish-triggered (project_level=low, sprint_candidate=${SPRINT_CANDIDATE_COUNT})"
  elif [[ "$PROJECT_LEVEL" == "medium" ]]; then
    # medium：留言通知，等確認
    gh issue comment <最新 sprint-candidate Issue> -R ${OWNER_REPO} --body "## [Backlog 補充通知]

Backlog 健康度檢查：sprint-candidate Issues 數量 ${SPRINT_CANDIDATE_COUNT} < 閾值 ${THRESHOLD}

Backlog 已不足，建議執行 Backlog Discovery 補充新的候選項目。

project_level=medium，請確認是否執行 Backlog Discovery。"
    log action: "backlog-replenish-notify (project_level=medium, sprint_candidate=${SPRINT_CANDIDATE_COUNT})"
  else:  # high
    # high：只標記
    log action: "backlog-replenish-marked (project_level=high, sprint_candidate=${SPRINT_CANDIDATE_COUNT})"
fi
```

**信號來源**（詳見 `skills/sprint-review/SKILL.md` §2.7）：

Sprint Review 完成 Issue 狀態回寫（§2.6）後，執行 Backlog 健康度檢查：
1. 讀取 `.claude/shikigami.local.md` 中 `backlog_health.threshold`（預設 8）
2. 統計當前 open sprint-candidate Issues 數量
3. 若 count < threshold，產生信號 `[BACKLOG-REPLENISH-TRIGGER]`；否則產生 `[BACKLOG-HEALTH-OK]`
4. cruise PO-patrol 將本次檢查結果寫入 JSONL log 為 `type="backlog-health"` entry

**日誌格式**（詳見 `skills/cruise/references/log-format.md`）：

```jsonl
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T11:00:00+0800","type":"backlog-health","repo":"KCTW/shikigami","sprint_candidate_count":5,"threshold":8,"signal":"[BACKLOG-REPLENISH-TRIGGER]","action":"trigger-discovery"}
```

**非阻塞降級（AC5）**：若 gh API 失敗（無法取得 sprint-candidate 計數），Sprint Review 輸出 `[BACKLOG-HEALTH-WARN]` 並繼續，不中斷 Review 流程。cruise log 記錄此次失敗。
