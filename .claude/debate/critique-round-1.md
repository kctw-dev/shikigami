# Team Debate — Critic Round 1
**Story**: #495 feat: INFRA 回歸測試案例實作
**Branch**: sprint-128/495-infra-test-cases
**Critic Agent**: Developer Critic (Agent B)
**Date**: 2026-03-24

---

## Verdict: PASS

---

## 批判維度評估

### 1. 正確性（AC 覆蓋度）

| AC | 說明 | 評估 |
|----|------|------|
| AC2a (#423 OIDC) | U-3a/b/c 驗證 id-token:write、permissions 區塊、CLAUDE_CODE_OAUTH_TOKEN；I-4a/b/c 驗證 ci-health-check.sh 的 API endpoint、404/401 判斷 | PASS |
| AC2b (#442 unzip) | U-4a 冪等安裝（command -v unzip）、U-4b apt-get install -y unzip、U-4c sudo -n 退化偵測 | PASS |
| AC2c (#424 版本釘定) | I-3a 實際執行 validate-ci-versions.sh、I-3b 輸出 PASS 驗證、I-3c 掃描到 3 個 workflow | PASS |
| AC3 (CI pipeline) | S-3a/b/c/d 確認 infra-regression.yml 存在、觸發條件、checkout@v4 | PASS |

邊界條件檢查：
- 測試在各 workflow 檔案不存在時均有 `skip` fallback，不會誤 FAIL — 正確
- U-4c 正確排除 YAML 註解行（grep -vE "^[[:space:]]*#"）— 正確

### 2. 設計（SOLID / 耦合度 / 命名）

**正向觀察：**
- 新測試段落命名（U-3、U-4、I-3、I-4、S-3）沿用既有框架命名慣例，一致性佳
- 每個 `assert_contains` 都有具體的 fix_hint，符合框架 INFRA-DIAG 規範
- `infra-regression.yml` 使用 env 傳遞 `inputs.infra_test_level`（安全最佳實踐）
- `paths` filter 避免每次 push 都觸發，減少 CI noise

**可觀察的設計問題（LOW）：**

- `tests/test-infra-regression.sh` 第 470 行：`VALIDATE_EXIT=$?` 在 `set -uo pipefail` 環境中，若 subshell 本身出錯可能不如預期。不過此處已用 `2>&1` 捕獲 stderr，且腳本頂部是 `set -uo pipefail`（未含 `-e`），實際風險極低。
- `infra-regression.yml` 第 53 行：`runs-on: ubuntu-latest` — ubuntu-latest 版本會漂移。在強調版本釘定的專案中略顯矛盾，但屬已知取捨（現有 e2e.yml 亦同），無需在此 Story 修復。

### 3. 測試覆蓋

- 新增 12 個測試案例（U-3: 3個、U-4: 3個、I-3: 3個、I-4: 3個、S-3: 4個）
- 從 20 個擴充至 36 個，覆蓋率顯著提升
- TDD 流程：Red 階段發現了 U-4c 的真實問題（sudo -n 出現在 grep 結果中），並正確修正為排除注釋行 — 符合 TDD 精神
- 既有 20 個測試均繼續通過 — 無退化

### 4. 安全性

- `infra-regression.yml`：`permissions: contents: read`（最小權限）— 正確
- input 透過 env 傳遞，無命令注入風險（choice type + env 雙重防護）— 正確
- 無硬編碼 secrets — 正確
- validate-ci-versions.sh 透過 `CI_VERSIONS_REPO_ROOT` 環境變數注入，非直接 eval — 正確

---

## Issues Found

無 HIGH severity 問題。LOW 問題不影響 AC 完整性，已記錄供參考，不要求修復。

---

## Summary

Worker 正確實作了所有 4 個 AC：
- AC2a: U-3 (3 tests) + I-4 (3 tests) 覆蓋 #423 OIDC 配置
- AC2b: U-4 (3 tests) 覆蓋 #442 unzip 深度回歸
- AC2c: I-3 (3 tests) 覆蓋 #424 版本釘定實際執行
- AC3: S-3 (4 tests) + infra-regression.yml 覆蓋 CI pipeline 整合

TDD 流程嚴格執行（Red→Green 可追蹤），無安全漏洞，設計無重大問題。
