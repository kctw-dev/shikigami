# shoot CI/CD Gate 規則

本文件定義 `/shoot` 的 CI/CD 相關 Gate 規則，由 `skills/shoot/SKILL.md` 按需載入。

---

## CI/CD 雙審查 Gate（條件觸發）

<!-- US-189 CI/CD 變更強制 QA + SRE 雙審查 Gate — Sprint 72 -->

在 QA Post-check 通過後、執行 `shoot:` commit 前，偵測本次任務修改的檔案是否包含 CI/CD 相關路徑。

### CI/CD 路徑 Pattern

| Pattern | 範例 |
|---------|------|
| `.github/workflows/**` | `.github/workflows/deploy.yml` |
| `scripts/deploy*.sh` | `scripts/deploy-prod.sh` |
| `scripts/add_secret.sh` | `scripts/add_secret.sh` |
| `Dockerfile*` | `Dockerfile`、`Dockerfile.prod` |
| `cloudbuild*.yaml` | `cloudbuild.yaml`、`cloudbuild-staging.yaml` |
| `docker-compose*.yml` | `docker-compose.yml`、`docker-compose.prod.yml` |

### 審查規則

偵測到 CI/CD 變更後，**QA regression check 與 SRE infra config check 兩者均必須 PASS，才允許執行 `shoot:` commit**。

完整審查項目定義請參照 `skills/sprint-execution/story-lifecycle-prompt.md` §6.8「CI/CD 雙審查 Gate」。

<HARD-GATE>
**CI/CD 雙審查 Hard Gate（/shoot）**：偵測到 CI/CD 路徑變更時，QA regression check 與 SRE infra config check **兩者均必須 PASS**，才允許執行 `shoot:` git commit。任一 FAIL → exit code 非 0，禁止 commit。
</HARD-GATE>

---

## CI Gate（US-241）

<!-- US-241 shoot CI Gate — CI pass 才標 PASS — Sprint 88 -->

在 `shoot:` commit + `git push` 完成後、寫 `Shoot_Log.md` PASS 前，執行 CI 狀態等待與驗證。

### Doc-only 跳過規則

若本次修改的檔案**全部**符合以下 pattern，視為 doc-only 變更，**跳過 CI Gate**：

| Pattern | 說明 |
|---------|------|
| `docs/**` | 文件目錄 |
| `**/*.md` | 所有層級的 Markdown 文件 |
| `skills/**/*.md` | Skill 定義文件 |
| `agents/**/*.md` | Agent 定義文件 |
| `templates/**/*.md` | 範本文件 |

輸出：
```
── CI Gate ────────────────────────────
  [SKIP] Doc-only 變更，跳過 CI Gate
```

### 執行步驟

```bash
# Step 1：取得最新的 CI run（push 後觸發的 workflow）
CI_RUN=$(gh run list --limit 1 --json databaseId,name,status,conclusion,url \
  2>/dev/null)

# Step 2：若 run 尚在執行中，等待完成（最多 10 分鐘）
RUN_ID=$(echo "$CI_RUN" | jq -r '.[0].databaseId // empty')
if [[ -n "$RUN_ID" ]]; then
  gh run watch "$RUN_ID" --exit-status 2>/dev/null
  CONCLUSION=$(gh run view "$RUN_ID" --json conclusion -q '.conclusion' 2>/dev/null)
fi
```

### CI Gate 判斷規則

| 情況 | CONCLUSION 值 | 行為 |
|------|---------------|------|
| CI PASS | `success` | 繼續，寫 Shoot_Log.md PASS |
| CI FAIL | `failure` / `cancelled` / `timed_out` | 觸發 `invoke shikigami:systematic-debugging`（CI FAIL 根因排查）；修復成功 → 重新 commit + push + 等待 CI；修復失敗 → **不寫 PASS**，輸出失敗資訊，exit code 非 0，終止 |
| CI 不可用 | — | 依降級行為處理（見下方） |

### CI FAIL 輸出格式

```
── CI Gate ────────────────────────────
  [FAIL] CI 檢查未通過，中止寫入 Shoot_Log PASS
  Workflow：<workflow 名稱>
  Run URL ：<run URL>
  結論    ：<conclusion>

[ERROR] CI Gate FAIL，終止執行
  - exit code：1（非 0）
  - Shoot_Log.md 未更新（無 PASS 記錄）
```

### CI 不可用時的降級行為

CI 不可用情境包括：`gh` CLI 未安裝、未認證、repo 無 CI workflow 配置、`gh run list` 回傳空結果。

| 情境 | 偵測條件 | 降級行為 |
|------|---------|---------|
| `gh` CLI 未安裝 | `command -v gh` 失敗 | 輸出 `[WARN] gh CLI 未安裝，跳過 CI Gate`，繼續寫 PASS |
| `gh` CLI 未認證 | `gh auth status` 失敗 | 輸出 `[WARN] gh CLI 未認證，跳過 CI Gate`，繼續寫 PASS |
| repo 無 CI workflow | `gh run list` 回傳 `[]` | 輸出 `[WARN] 無 CI workflow，跳過 CI Gate`，繼續寫 PASS |
| `gh run list` 執行失敗 | exit code 非 0 | 輸出 `[WARN] CI 狀態查詢失敗，跳過 CI Gate`，繼續寫 PASS |

降級輸出格式：

```
── CI Gate ────────────────────────────
  [WARN] <降級原因>，跳過 CI Gate
  CI Gate 已略過，手動確認 CI 狀態後再繼續
```

<HARD-GATE>
**CI Gate Hard Gate（/shoot）**：git push 完成後，CI PASS 才允許寫入 Shoot_Log.md PASS。CI FAIL → exit code 非 0，Shoot_Log.md 不寫 PASS 記錄，不輸出完成訊息。CI 不可用時採降級行為（輸出 WARN，繼續執行）。
</HARD-GATE>
