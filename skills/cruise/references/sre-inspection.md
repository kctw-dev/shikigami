# SRE 巡檢指引

**觸發**：每個 cruise cycle 由 Task tool 派遣 SRE Agent 執行
**Repo context**：subagent 接收 `REPO_PATH` 與 `OWNER_REPO` 參數，所有 `gh` 指令加 `-R ${OWNER_REPO}`

## cruise-feedback label 標註規則（#339）

SRE 建立 Issue 時，若判斷問題**屬於框架層級**（非 repo 特定，而是 Cruise Skill 本身的限制或設計缺陷），在 `--label` 參數中加入 `cruise-feedback`。

判斷依據：

| 情境 | 加 `cruise-feedback`？ | 說明 |
|------|----------------------|------|
| Cruise Skill 行為有缺陷（如 routing 邏輯錯誤） | 是 | 屬於框架層級，需回報 kctw-dev/shikigami |
| 某 repo CI 設定問題 | 否 | Repo 特定問題，不屬框架層級 |
| 某 runner offline | 否 | 基礎設施問題，非 Cruise Skill 問題 |
| Cruise 對某類 Issue 誤判（如誤標 sprint-candidate） | 是 | 屬於框架層級判斷邏輯問題 |

加上 `cruise-feedback` label 後，PO 巡邏在下一個 cycle 會透過 Feedback Routing 機制（Step 1.5）自動轉送或留言確認。

## CI/CD 狀態檢查

```bash
# 列出最近 10 筆 GitHub Actions run
gh run list -R ${OWNER_REPO} --limit 10 --json status,conclusion,name,databaseId,createdAt
# 篩選 failure / cancelled
FAILED_RUNS=$(gh run list -R ${OWNER_REPO} --limit 10 --json status,conclusion,name,databaseId \
  | jq '[.[] | select(.conclusion == "failure" or .conclusion == "cancelled")]')
```

## Runner 健康檢查

> **前置條件**：查詢 org-level runner 需要 `admin:org` scope（`gh auth refresh -s admin:org`）。若缺少此 scope 將自動 fallback 至 repo-level。

```bash
# Step 1：偵測 owner 類型（org vs user）
# OWNER_REPO 由主 loop 帶入（如 "KCTW/shikigami"）
OWNER=$(echo "${OWNER_REPO}" | cut -d'/' -f1)
REPO=$(echo "${OWNER_REPO}" | cut -d'/' -f2)
OWNER_TYPE=$(gh api /orgs/${OWNER} --jq '.type' 2>/dev/null || echo "User")

if [[ "$OWNER_TYPE" == "User" ]]; then
  # 個人帳號 repo — 直接走 repo-level，不嘗試 org API
  echo "[SRE] owner 為 User，使用 repo-level runner API"
  gh api /repos/${OWNER}/${REPO}/actions/runners --jq '.runners[] | {name, status, busy}' 2>/dev/null || true
else
  # Step 2：org-level API 優先（需 admin:org scope）
  RUNNERS=$(gh api /orgs/${OWNER}/actions/runners --jq '.runners[] | {name, status, busy}' 2>/dev/null)
  ORG_EXIT=$?

  if [[ $ORG_EXIT -ne 0 ]]; then
    # Step 3：fallback 至 repo-level（403 或 404）
    echo "[SRE] org-level API 不可用，fallback 至 repo-level（可能缺少 admin:org scope）"
    gh api /repos/${OWNER}/${REPO}/actions/runners --jq '.runners[] | {name, status, busy}' 2>/dev/null || true
  else
    echo "$RUNNERS"
  fi
fi
```

## VM 數量變化查證

> 發現 GCP VM 數量與上次巡檢不同時，必須查證原因，**禁止推測**。

```bash
# 前置判斷：確認 gcloud 可用
if ! gcloud version 2>/dev/null; then
  echo "[SRE] gcloud 不可用，跳過 MIG 查證"
  # 不阻塞後續流程，直接跳過
else
  # 查詢 MIG autoscaler 狀態（MIG_NAME 由環境變數或 SRE config 帶入）
  MIG_INFO=$(gcloud compute instance-groups managed describe "${MIG_NAME}" \
    --format="yaml(autoscaler.recommendedSize,targetSize)" 2>/dev/null)

  if [[ $? -ne 0 ]]; then
    echo "[SRE] gcloud 不可用，跳過 MIG 查證"
  else
    RECOMMENDED_SIZE=$(echo "$MIG_INFO" | grep 'recommendedSize' | awk '{print $2}')
    TARGET_SIZE=$(echo "$MIG_INFO" | grep 'targetSize' | awk '{print $2}')
    PREVIOUS_VM_COUNT="${PREVIOUS_VM_COUNT:-$TARGET_SIZE}"  # fallback 至 targetSize

    if [[ "$RECOMMENDED_SIZE" -lt "$PREVIOUS_VM_COUNT" ]]; then
      # autoscaler 主動縮減 — 正常行為
      echo "[SRE] VM 數量變化原因：autoscaler 縮減（正常）recommendedSize=${RECOMMENDED_SIZE} < 之前=${PREVIOUS_VM_COUNT}"
      VM_HEALTH_STATUS="autoscaler-scale-in"
      VM_HEALTH_NOTE="autoscaler 縮減（正常）：recommendedSize=${RECOMMENDED_SIZE}，之前 VM 數=${PREVIOUS_VM_COUNT}"
    elif [[ "$RECOMMENDED_SIZE" -eq "$PREVIOUS_VM_COUNT" ]]; then
      # recommendedSize 未變但 VM 少了 — SPOT 回收或故障（異常）
      echo "[SRE] VM 數量變化原因：SPOT 回收或故障（異常）recommendedSize=${RECOMMENDED_SIZE} = 之前=${PREVIOUS_VM_COUNT}，但 VM 實際減少"
      VM_HEALTH_STATUS="spot-preemption-or-failure"
      VM_HEALTH_NOTE="SPOT 回收或故障（異常）：recommendedSize=${RECOMMENDED_SIZE}，之前 VM 數=${PREVIOUS_VM_COUNT}，實際 VM 數減少"
      # 建立 Issue（異常情況）
      ISSUE_TITLE="[SRE] VM 異常減少：${MIG_NAME}"
      EXISTING=$(gh issue list -R ${OWNER_REPO} \
        --search "\"${ISSUE_TITLE}\"" \
        --state all \
        --json number,title \
        2>/dev/null || echo "[]")
      if echo "$EXISTING" | jq -e '. | length > 0' &>/dev/null; then
        echo "[SRE] 跳過重複 Issue：$ISSUE_TITLE"
        log action: "跳過重複 Issue: ${ISSUE_TITLE}"
      else
        gh issue create -R ${OWNER_REPO} \
          --title "$ISSUE_TITLE" \
          --body "## SRE 巡檢發現 VM 異常減少

**發現時間**：$(date '+%Y-%m-%dT%H:%M:%S')
**Session**：${SESSION_ID}
**MIG**：${MIG_NAME}
**recommendedSize**：${RECOMMENDED_SIZE}
**之前 VM 數**：${PREVIOUS_VM_COUNT}

### 判斷依據
- recommendedSize = 之前 VM 數 → autoscaler 未主動縮減
- 但實際 VM 數減少 → 推測為 SPOT 回收或 VM 故障

### 建議排查
1. 確認 GCP Console MIG 事件記錄（preemption / health check fail）
2. 確認 SPOT VM 回收通知
3. 執行 \`/systematic-debugging\` 進行系統性排查

> 此 Issue 由 SRE Cruise Agent 自動建立。請勿重複建立。" \
          --label "sre,vm-anomaly,needs-triage"
        log action: "create-issue-vm-anomaly #<new_issue_number>"
      fi
    fi
  fi
fi
```

**VM 查證結論分類**：

| 情況 | 判斷條件 | 結論 | 行動 |
|------|----------|------|------|
| autoscaler 縮減 | `recommendedSize < 之前 VM 數` | 正常（autoscaler scale-in） | 記錄，不建 Issue |
| SPOT 回收或故障 | `recommendedSize = 之前 VM 數` 但 VM 實際減少 | 異常 | 記錄 + 建 Issue |
| gcloud 不可用 | `gcloud version` 失敗 | 跳過（不阻塞） | 記錄 `[SRE] gcloud 不可用，跳過 MIG 查證` |

## Warnings 掃描

```bash
# 掃描最近 commit 的 CI logs 是否有 WARNING
gh run view <run_id> -R ${OWNER_REPO} --log 2>/dev/null | grep -i 'warning\|WARN\|deprecated' | head -20
```

## 自動行動決策表（SRE）

**發現即處理**：SRE 巡檢發現問題時自動建立 Issue + 附加指引，不在 cruise loop 內同步執行修復（保持 cruise 輕量、松耦合）。

| 情境 | 判斷條件 | 自動行動 | label | log action 類型 |
|------|----------|----------|-------|-----------------|
| **CI failure** | CI run 結果為 failure / cancelled | 建 Issue + body 含 `/systematic-debugging` 指引 | `sre,sre-auto-debug,needs-triage` | `"create-issue-with-debug"` |
| **Deploy failure** | deploy job 失敗（conclusion=failure，job name 含 deploy） | 建 Issue + body 含 @mention PO | `sre,deploy-failure,needs-triage` | `"create-issue-deploy"` |
| **Runner offline** | runner status=offline（repo-level fallback） | 建 Issue | `sre,runner-offline,needs-triage` | `"create-issue-runner"` |
| **VM 異常減少** | `recommendedSize = 之前 VM 數` 但 VM 實際減少 | 建 Issue + 記錄原因 + 證據 | `sre,vm-anomaly,needs-triage` | `"create-issue-vm-anomaly"` |

## CI failure → Issue + /systematic-debugging 指引

```bash
# Issue 重複防護：建 Issue 前先搜尋（跨機器冪等）
ISSUE_TITLE="[SRE] CI failure: ${RUN_NAME}"
EXISTING=$(gh issue list -R ${OWNER_REPO} \
  --search "\"${ISSUE_TITLE}\"" \
  --state all \
  --json number,title \
  2>/dev/null || echo "[]")

if echo "$EXISTING" | jq -e '. | length > 0' &>/dev/null; then
  echo "[SRE] 跳過重複 Issue：$ISSUE_TITLE"
  log action: "跳過重複 Issue: ${ISSUE_TITLE}"
else
  gh issue create -R ${OWNER_REPO} \
    --title "$ISSUE_TITLE" \
    --body "## SRE 巡檢發現 CI failure

**發現時間**：$(date '+%Y-%m-%dT%H:%M:%S')
**Session**：${SESSION_ID}
**Repo**：${OWNER_REPO}
**問題描述**：CI pipeline 執行失敗

### 詳情
- Run ID: ${RUN_ID}
- Run Name: ${RUN_NAME}
- 狀態: failure

### 建議排查
執行 \`/systematic-debugging\` 進行系統性排查。

> 此 Issue 由 SRE Cruise Agent 自動建立（松耦合 — 不在 cruise loop 內同步執行 debugging）。請勿重複建立。" \
    --label "sre,sre-auto-debug,needs-triage"
  log action: "create-issue-with-debug #<new_issue_number>"
fi
```

## Deploy failure → Issue + 通知 PO

```bash
# deploy failure：偵測 job name 含 deploy 且 conclusion=failure
DEPLOY_FAILED_RUNS=$(gh run list -R ${OWNER_REPO} --limit 10 --json status,conclusion,name,databaseId \
  | jq '[.[] | select(.conclusion == "failure") | select(.name | test("deploy"; "i"))]')

for run in $(echo "$DEPLOY_FAILED_RUNS" | jq -r '.[].databaseId'); do
  RUN_INFO=$(gh run view "$run" -R ${OWNER_REPO} --json name,databaseId,createdAt)
  RUN_NAME=$(echo "$RUN_INFO" | jq -r '.name')
  ISSUE_TITLE="[SRE] Deploy failure: ${RUN_NAME}"

  # Issue 重複防護：建立前搜尋（EXISTING deploy）
  EXISTING=$(gh issue list -R ${OWNER_REPO} \
    --search "\"${ISSUE_TITLE}\"" \
    --state all \
    --json number,title \
    2>/dev/null || echo "[]")

  if echo "$EXISTING" | jq -e '. | length > 0' &>/dev/null; then
    echo "[SRE] 跳過重複 Issue：$ISSUE_TITLE"
    log action: "跳過重複 Issue: ${ISSUE_TITLE}"
  else
    # PO_MENTION：從 CODEOWNERS 或 team 設定讀取，預設 @po
    PO_MENTION="${PO_GITHUB_LOGIN:-@po}"
    gh issue create -R ${OWNER_REPO} \
      --title "$ISSUE_TITLE" \
      --body "## SRE 巡檢發現 Deploy failure

**發現時間**：$(date '+%Y-%m-%dT%H:%M:%S')
**Session**：${SESSION_ID}
**Repo**：${OWNER_REPO}
**問題描述**：Deploy pipeline 執行失敗，需 PO 確認

### 詳情
- Run ID: ${RUN_ID}
- Run Name: ${RUN_NAME}
- 狀態: failure

### 通知
${PO_MENTION} 請確認此次部署失敗情況並決定後續行動。

> 此 Issue 由 SRE Cruise Agent 自動建立。請勿重複建立。" \
      --label "sre,deploy-failure,needs-triage"
    log action: "create-issue-deploy #<new_issue_number>"
  fi
done
```

## Runner offline → Issue

```bash
# runner offline：偵測 runner status=offline
OFFLINE_RUNNERS=$(echo "$RUNNERS" | jq '[.[] | select(.status == "offline")] // []')

for runner_name in $(echo "$OFFLINE_RUNNERS" | jq -r '.[].name'); do
  ISSUE_TITLE="[SRE] Runner offline: ${runner_name}"

  # Issue 重複防護：建立前搜尋（EXISTING runner）
  EXISTING=$(gh issue list -R ${OWNER_REPO} \
    --search "\"${ISSUE_TITLE}\"" \
    --state all \
    --json number,title \
    2>/dev/null || echo "[]")

  if echo "$EXISTING" | jq -e '. | length > 0' &>/dev/null; then
    echo "[SRE] 跳過重複 Issue：$ISSUE_TITLE"
    log action: "跳過重複 Issue: ${ISSUE_TITLE}"
  else
    gh issue create -R ${OWNER_REPO} \
      --title "$ISSUE_TITLE" \
      --body "## SRE 巡檢發現 Runner offline

**發現時間**：$(date '+%Y-%m-%dT%H:%M:%S')
**Session**：${SESSION_ID}
**Repo**：${OWNER_REPO}
**Runner 名稱**：${runner_name}

### 建議處理
請確認 runner 狀態並重新啟動（已有權限防護：repo-level fallback）。

> 此 Issue 由 SRE Cruise Agent 自動建立。請勿重複建立。" \
      --label "sre,runner-offline,needs-triage"
    log action: "create-issue-runner #<new_issue_number>"
  fi
done
```

## 跨機器冪等性（所有 Issue 類型）

多台機器同時執行 cruise 時，可能同時發現同一 failure。每種 Issue 類型在建立前均執行 `gh issue list -R ${OWNER_REPO} --search` 搜尋，確保同一問題只建一個 Issue：

- CI failure：`EXISTING` 搜尋防護 → 已存在則跳過
- Deploy failure：`EXISTING` 搜尋防護 → 已存在則跳過
- Runner offline：`EXISTING` 搜尋防護 → 已存在則跳過

**設計理由**：多 runner 同時發現同一 failure，因 GitHub Issue search 存在毫秒級競態，實務上極罕見建立重複；search 防護為主要冪等機制，已覆蓋所有新 Issue 類型。

## SRE 巡檢結果格式

```json
{
  "session_id": "<SESSION_ID>",
  "cycle": <N>,
  "timestamp": "<ISO8601>",
  "type": "sre-inspection",
  "repo": "<OWNER_REPO>",
  "summary": "檢查 <X> 筆 CI run，發現 <Y> 個 failure，建立 <Z> 個 Issue",
  "vm_health": {
    "status": "autoscaler-scale-in | spot-preemption-or-failure | no-change | skipped",
    "note": "<原因說明 + 證據>",
    "previous_vm_count": <N>,
    "current_vm_count": <N>,
    "recommended_size": <N>
  },
  "actions": ["create-issue-with-debug #<N1>", "create-issue-deploy #<N2>", "create-issue-runner #<N3>", "create-issue-vm-anomaly #<N4>", "跳過重複 Issue: <title>"]
}
```

**SRE 巡檢 actions 行動類型說明**：

| 類型 | 說明 |
|------|------|
| `"create-issue-with-debug"` | CI failure 建 Issue + `/systematic-debugging` 指引（松耦合，不同步 debug） |
| `"create-issue-deploy"` | Deploy failure 建 Issue + @mention PO |
| `"create-issue-runner"` | Runner offline 建 Issue |
| `"create-issue-vm-anomaly"` | VM 異常減少（SPOT 回收或故障）建 Issue + 原因 + 證據 |

**vm_health.status 說明**：

| 值 | 說明 |
|---|------|
| `"autoscaler-scale-in"` | autoscaler 主動縮減（正常），`recommendedSize < 之前 VM 數` |
| `"spot-preemption-or-failure"` | SPOT 回收或 VM 故障（異常），`recommendedSize = 之前 VM 數` 但 VM 減少 |
| `"no-change"` | VM 數量無變化，跳過查證 |
| `"skipped"` | gcloud 不可用，跳過 MIG 查證（`[SRE] gcloud 不可用，跳過 MIG 查證`） |
