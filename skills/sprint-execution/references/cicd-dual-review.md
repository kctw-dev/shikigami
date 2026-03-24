# §6.8 CI/CD 雙審查 Gate（條件觸發）

<!-- SSOT：story-lifecycle-prompt.md §6.8 已移至此處（Sprint 127 #485 模組化拆分） -->
<!-- US-189 CI/CD 變更強制 QA + SRE 雙審查 Gate — Sprint 72 -->

<HARD-GATE>
**QA/SRE 角色載入 Hard Gate**：進入 CI/CD 雙審查前，必須使用 Read 工具讀取 `agents/qa-engineer.md`（QA regression check 視角）與 `agents/sre-engineer.md`（SRE infrastructure config 視角），載入兩個角色的完整決策權與方法論。此 Gate 不受 bypass=true 豁免。
</HARD-GATE>

**觸發條件**：commit 前，偵測到以下任一 CI/CD 相關路徑被修改時觸發。無相關路徑變更則 SKIP。

## CI/CD 路徑 Pattern

以下路徑 pattern 符合任一即視為 CI/CD 變更：

| Pattern | 範例 |
|---------|------|
| `.github/workflows/**` | `.github/workflows/deploy.yml` |
| `scripts/deploy*.sh` | `scripts/deploy-prod.sh` |
| `scripts/add_secret.sh` | `scripts/add_secret.sh` |
| `Dockerfile*` | `Dockerfile`、`Dockerfile.prod` |
| `cloudbuild*.yaml` | `cloudbuild.yaml`、`cloudbuild-staging.yaml` |
| `docker-compose*.yml` | `docker-compose.yml`、`docker-compose.prod.yml` |

## 偵測方式

在 commit 前，執行以下 bash 指令取得已修改的檔案清單，並比對上述 pattern：

```bash
# 取得 staged 與 unstaged 變更的檔案清單
git diff --name-only HEAD
git diff --name-only --cached
```

比對規則（滿足任一即視為 CI/CD 變更）：

```
檔案路徑符合以下任一 glob pattern：
  - .github/workflows/**
  - scripts/deploy*.sh
  - scripts/add_secret.sh
  - Dockerfile*
  - cloudbuild*.yaml
  - docker-compose*.yml
```

## 雙審查流程

偵測到 CI/CD 變更後，**必須依序完成 QA + SRE 雙審查，兩者均 PASS 後才允許執行 commit**。

### QA 審查（regression check）

**目的**：確認 CI/CD 變更不會破壞既有部署流程。

QA subagent 執行以下審查項目：

```
CI/CD 變更 QA Regression Check — {story_id}

變更檔案：
- {列出所有符合 CI/CD pattern 的變更檔案}

審查項目：
- [ ] QA-CICD-1：工作流程語法正確性
  → 檢查 YAML 語法無誤（縮排、key 格式等）
  → 通過標準：無明顯語法錯誤
- [ ] QA-CICD-2：既有 CI/CD 步驟保留
  → 確認原有必要步驟（build、test、deploy）未被移除
  → 通過標準：與修改前相比，核心 job/step 均保留
- [ ] QA-CICD-3：觸發條件正確
  → 確認 workflow trigger（on: push/pull_request 等）符合預期
  → 通過標準：觸發條件不過於寬鬆（如不得使用 on: "*"）
- [ ] QA-CICD-4：環境變數參照完整
  → 確認 workflow 引用的 env var / secret 名稱與 step 宣告一致
  → 通過標準：無引用未宣告的 env var / secret

整體結論：PASS / FAIL
```

**QA FAIL 時**：禁止執行 commit，在本 subagent 內部修復後重新審查（最多 3 次）。連續 3 次 FAIL → 回傳 `ESCALATE: DESIGN_ISSUE`。

### SRE 審查（infrastructure config correctness）

**目的**：確認基礎設施配置正確性（secret 掛載、IAM、環境變數完整性）。

SRE subagent 執行以下審查項目：

```
CI/CD 變更 SRE Infrastructure Config Check — {story_id}

變更檔案：
- {列出所有符合 CI/CD pattern 的變更檔案}

審查項目：
- [ ] SRE-CICD-1：Secret 掛載正確性
  → 確認 Dockerfile / docker-compose / cloudbuild / workflow 中引用的 secret 均以正規方式掛載
  → 禁止事項：secret 值以明文 hardcode 寫入任何 CI/CD 檔案
  → 通過標準：所有 secret 透過環境變數、Secret Manager 或 CI/CD secrets 機制引用
- [ ] SRE-CICD-2：IAM 最小權限原則
  → 確認 service account / role 設定遵循最小權限原則
  → 通過標準：無不必要的 Owner / Editor 廣域角色賦予
- [ ] SRE-CICD-3：環境變數完整性
  → 確認部署必要的環境變數均已宣告，無缺漏
  → 通過標準：執行時所需的 env var 均已在 CI/CD 配置中宣告或透過 secret 傳入
- [ ] SRE-CICD-4：映像來源安全
  → 確認 Docker base image 來源可信（非 latest 或不明來源）
  → 通過標準：base image 標記明確版本，非 `latest`

整體結論：PASS / FAIL
```

**SRE FAIL 時**：禁止執行 commit，在本 subagent 內部修復後重新審查（最多 3 次）。連續 3 次 FAIL → 回傳 `ESCALATE: SECURITY_CRITICAL`（若為安全問題）或 `ESCALATE: DESIGN_ISSUE`。

## 雙審查結論彙整

```
CI/CD 雙審查 Gate — {story_id}

偵測到 CI/CD 變更：{是/否}
變更檔案清單：
  - {file1} （符合 pattern: {pattern}）
  - ...

QA 審查（regression check）：PASS / FAIL / SKIP
SRE 審查（infrastructure config check）：PASS / FAIL / SKIP

整體結論：PASS（允許 commit）/ FAIL（禁止 commit）/ SKIP（無 CI/CD 變更）
```

<HARD-GATE>
**CI/CD 雙審查 Hard Gate**：偵測到 CI/CD 路徑變更時，QA 審查與 SRE 審查**兩者均必須 PASS**，才允許執行 git commit。任一審查 FAIL → 禁止 commit，必須修復後重新審查通過。
</HARD-GATE>
