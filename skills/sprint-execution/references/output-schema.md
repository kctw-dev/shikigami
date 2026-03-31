# §9 輸出格式（Output Schema）

<!-- SSOT：story-lifecycle-prompt.md §9 已移至此處（Sprint 127 #485 模組化拆分） -->
<!-- US-249 Subagent 結果暫存 — context compaction 後結果復原機制 — Sprint 92 -->

## §9.0 Live Log — 回傳結果（US-269，US-323 AC-4/6/7）

在執行暫存寫入前：
1. 寫入 live log：`echo "[$(date +%H:%M:%S)] [${story_id}] 結果：PASS|FAIL|ESCALATE" >> "${LIVE_LOG_FILE}" 2>/dev/null || true`
2. stdout 標記（AC-4）：`echo "[SHIKIGAMI] event=story_end story=${story_id} status=PASS|FAIL" || true`
3. Issue 留言（AC-6，opt-in）：`SHIKIGAMI_LIVE_NOTIFY=true` 時，用 `gh issue comment` 送出結果（`|| true` 防阻塞）
4. Trace span（ADR-033）：用 `printf` 寫 JSON 至 `${TRACE_LOG_FILE}` — `action=tdd-implement, status=completed|failed`

## §9.1 暫存寫入（回傳前必執行）

**在回傳標準化摘要給主 session 之前**，必須先將結果寫入暫存文件，供主 session 在 context compaction 後復原使用。

**觸發時機**：所有執行路徑均適用（一般路徑、doc-only 路徑、DESIGN 路徑），無豁免。

**執行步驟**：

```
1. 確認暫存目錄存在：docs/sprints/subagent-results/
   若目錄不存在 → 建立目錄（mkdir -p docs/sprints/subagent-results/）

2. 將標準化摘要寫入：docs/sprints/subagent-results/{story_id}.md
   （複用 §9 PASS / FAIL / ESCALATE 回傳格式，內容與回傳主 session 的摘要一致）

3. 暫存寫入完成後，繼續回傳摘要給主 session（不阻塞主流程）

4. 若暫存寫入失敗（磁碟錯誤等），輸出 [CACHE-WRITE-FAIL] 告警，繼續回傳摘要（不阻塞）
```

**暫存文件格式**：

```markdown
# Subagent Result — {story_id}

<!-- 自動產生，供 context compaction 後結果復原使用 -->
<!-- 寫入時間：{ISO 8601 timestamp} -->

{複製 §9 PASS / FAIL / ESCALATE 的完整回傳內容}
```

**注意**：暫存文件不加入 git commit（僅為執行期暫存），在 Sprint Review 完成並 git commit 後可安全清除（見 SKILL.md §3.2 暫存文件清除時機）。

## YAML 輸出契約

```yaml
# Story-Lifecycle Subagent 輸出契約（ADR-007 §AC2 Phase 1）
status: "PASS"          # 必填：PASS | FAIL | ESCALATE
summary: ""             # 必填：≤50 字的結果說明
modified_files: []      # 必填：所有被修改的檔案清單（含變更描述）
commit_sha: ""          # PASS 時必填；FAIL 時若有部分 commit 填最後 SHA，否則 N/A
escalation: null        # 升級時必填：DESIGN_ISSUE | CONTEXT_OVERFLOW | REQUIREMENT_AMBIGUITY | DEPENDENCY_MISSING | SECURITY_CRITICAL | DEBATE_DESIGN_ISSUE
uncertainty_check:      # 必填：不確定性三問檢查結果（US-214，開始前準備步驟 7）
  assumptions: []       # 第 (1) 項：假設清單（若無則為空陣列）
  uncertain_items: []   # 第 (2) 項：[UNCERTAIN] 標記項目清單（含驗證方式與驗證結果）
  queries_needed: []    # 第 (3) 項：需查閱的項目清單（若無則為空陣列）
  assumption_violation: false  # 若 Spec Compliance FAIL 且三問(2)(3)均為「無」→ true，輸出 [ASSUMPTION-VIOLATION]
team_debate:            # Team Debate 結果（§7.8，ADR-031，豁免時填 null）
  status: null          # PASS | UNRESOLVED | SKIPPED | null
  rounds: 0             # 執行批判輪數（0 = 豁免）
  final_verdict: null   # Critic 最終 Verdict（PASS / FAIL / null）
  critique_files: []    # 批判紀錄檔案路徑清單（如 .claude/debate/critique-round-1.md）
# --- Phase 2 欄位（AC3 抽樣邏輯已實作，schema 啟用待後續版本）---
# sampling_triggered: false   # Phase 2 AC3：是否觸發外部抽樣審查
# batch_index: null           # Phase 2 AC4：M/L size 分批執行批次索引
# total_batches: null         # Phase 2 AC4：總批次數
```

## PASS 回傳格式（Markdown 文字輸出）

```
## Story-Lifecycle 完成摘要

**Story ID**：US-#N
**結論**：PASS
**一句話摘要**：{≤50 字的結果說明}

**修改檔案清單**：
- `path/to/file1.md` — {變更描述}
- `path/to/file2.sh` — {變更描述}

**Commit SHA**：{最後一個 commit 的完整 SHA}

**DoD 狀態**：全部通過 / 有例外（{說明}）

**Review 摘要**：
- Spec Compliance：PASS（{一句話說明}）
- Code Quality：PASS（{一句話說明}）
- Security：PASS / SKIP（{一句話說明或「未觸發安全審查條件」}）
- Team Debate：{PASS-R1 / PASS-R2 / UNRESOLVED / SKIPPED}（{一句話說明或豁免原因}）

**不確定性三問摘要**（uncertainty_check）：
- 假設：{假設清單，若無則填「無」}
- 不確定項目：{[UNCERTAIN] 項目清單與驗證結果，若無則填「無」}
- 需查閱項目：{查閱項目清單，若無則填「無」}
- 腦補行為判定：{無 / [ASSUMPTION-VIOLATION] + 說明}
```

## ESCALATE 回傳格式（升級通知）

```
## Story-Lifecycle 升級通知

**Story ID**：US-#N
**結論**：ESCALATE
**升級原因**：{升級類型}
**升級詳情**：{具體說明}

升級類型：
  - DESIGN_ISSUE：同一審查階段連續失敗 3 次，可能存在架構/設計問題
  - CONTEXT_OVERFLOW：subagent context 接近上限（Phase 2 §AC4 fallback 策略）
  - REQUIREMENT_AMBIGUITY：AC 描述模糊或存在矛盾，無法判斷完成標準
  - DEPENDENCY_MISSING：依賴的文件、資源或前置條件不存在
  - SECURITY_CRITICAL：發現 Critical 安全問題，需 Security Engineer 人工介入
  - DEBATE_DESIGN_ISSUE：Team Debate 2 輪仍 FAIL 且含 HIGH severity 設計問題，需 Architect 介入
```

**升級決策規則（主 session 職責）：**

| 升級類型 | 主 session 預設處置 |
|----------|---------------------|
| DESIGN_ISSUE | 暫停 Sprint 執行，升級至 Architect 評估 |
| CONTEXT_OVERFLOW | 觸發 ADR-007 §AC4 fallback 策略（待後續 Sprint 實作） |
| REQUIREMENT_AMBIGUITY | 暫停 Sprint 執行，升級至 PO 釐清 AC |
| DEPENDENCY_MISSING | 暫停 Sprint 執行，解決依賴後重試 |
| SECURITY_CRITICAL | 暫停 Sprint 執行，觸發 security-review Skill |
| DEBATE_DESIGN_ISSUE | 暫停 Sprint 執行，升級至 Architect 評估（Team Debate 未解決設計問題） |

## §9.2 A2A Protocol JSON Block（ADR-044，#801 Sprint 162）

<!-- #801 A2A Protocol 結構化輸出 — Sprint 162 -->

在回傳 Markdown 摘要後，**必須附加** A2A JSON Block，供主 session 機器可讀解析（ADR-044 v1.0）。

**完整格式**：

```json
<!-- A2A-RESULT -->
{
  "protocol_version": "1.0",
  "story_id": <整數>,
  "actor": "<developer|architect|qa|po|security|sm>",
  "result": "<PASS|FAIL|ESCALATE>",
  "summary": "<≤200 字結果說明>",
  "artifacts": [
    {"type": "<file|pr|adr|test|doc>", "path": "<路徑或URL>", "description": "<說明>"}
  ],
  "metrics": {
    "tests_total": <整數>,
    "tests_passed": <整數>,
    "files_created": <整數>,
    "files_modified": <整數>
  },
  "pr": {"number": <整數>, "url": "<PR URL>", "merge_commit": null},
  "escalation": {"type": "<升級類型>", "reason": "<說明>"},
  "timestamp": "<ISO 8601，如 2026-03-25T22:00:00Z>"
}
```

**必填欄位**：`protocol_version`、`story_id`、`actor`、`result`、`summary`、`timestamp`

**條件必填**：`escalation`（當 `result=ESCALATE` 時必填）

**驗證**：`bash scripts/validate-a2a-schema.sh <result-file.json>`

**Schema 定義**：`docs/adr/ADR-044-a2a-protocol.md`
