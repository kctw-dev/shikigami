# shoot test → review → PR 管道規則

本文件定義 `/shoot` 的 test → review → PR 完整管道，由 `skills/shoot/SKILL.md` §7.1 按需載入。

關聯 Story：#388

---

## 管道概覽

`/shoot #N`（或任意觸發模式）實作完成後，自動進入三階段品質管道：

```
[test]  → bash tests/test-*.sh（步驟 4.5）
  ↓ PASS
[review] → pr-review-toolkit 外部獨立審查（步驟 5.3 + 5.4）
  ↓ PASS
[PR]    → gh pr create + squash merge（步驟 6.4 + 6.6）
```

各階段 FAIL 時立即中止，不進入下一階段。

---

## 階段 1：test（步驟 4.5）

執行 `bash tests/test-*.sh` 及其他本地測試。

**PASS** → 進入 review 階段。

**FAIL** → 觸發 `invoke shikigami:systematic-debugging`，修復後重試。
- 重試仍 FAIL → **管道中止**，exit code 非 0，不進入 review，不建立 PR。
- 輸出：`[ERROR] test 失敗，管道中止。請修復後重新執行 /shoot`

<HARD-GATE>
**test Hard Gate（/shoot pipeline）**：test 失敗且修復後仍失敗 → 管道中止，exit code 非 0，禁止進入 review 與 PR 階段。
</HARD-GATE>

---

## 階段 2：review（步驟 5.3 + 5.4）

test PASS 後，依序執行：
1. 外部獨立審查（步驟 5.3）— 規則見 `references/external-review.md`
2. pr-review-toolkit 補充審查（步驟 5.4）— 規則見 `references/pr-review-integration.md`

**回退修復機制**（AC3）：

review 發現 CRITICAL/HIGH 問題時：
1. 標記問題，回退至實作修復
2. 修復完成後，重新執行 **test + review**（從階段 1 重跑）
3. 二審仍有 CRITICAL/HIGH → 升級 Architect，管道中止

```
review FAIL
  └─→ [回退] 修復問題（實作修正）
       └─→ [重跑] bash tests/test-*.sh
            ├─→ test FAIL → 管道中止
            └─→ test PASS → 重新 review
                 ├─→ 仍 CRITICAL/HIGH → 升級 Architect，管道中止
                 └─→ PASS → 進入 PR 階段
```

<HARD-GATE>
**review 回退 Hard Gate（/shoot pipeline）**：二審仍 CRITICAL/HIGH → 升級 Architect，exit code 非 0，管道中止，禁止建立 PR。
</HARD-GATE>

---

## 階段 3：PR 建立（步驟 6）

review PASS 後，自動執行：

```bash
# 6.1 建立 branch
git checkout -b shoot/<issue-or-desc>

# 6.2 commit
git commit -m "shoot: <任務標題>"

# 6.3 push
git push

# 6.4 PR 建立
gh pr create --title "<任務標題>" --body "Closes #N"

# 6.5 Code Review Loop（pr-review-toolkit）
# 6.55 Self-Review（shoot.self_review=true 時）

# 6.6 squash merge（shoot.skip_merge=false 時）
gh pr merge --squash --delete-branch
```

PR 建立後的 merge 行為受 `shoot.skip_merge` 配置控制（詳見 SKILL.md §1）。

---

## 管道狀態輸出

每個階段結束後輸出管道狀態：

```
── /shoot 管道狀態 ──────────────────────
  [PASS] test        bash tests/test-*.sh 全部通過
  [PASS] review      外部獨立審查 + pr-review-toolkit PASS
  [PASS] PR          #<PR_NUMBER> 建立完成，squash merged
```

任一階段 FAIL：

```
── /shoot 管道狀態 ──────────────────────
  [PASS] test        bash tests/test-*.sh 全部通過
  [FAIL] review      code-reviewer 發現 HIGH issue（已中止）
  [SKIP] PR          review 未通過，不建立 PR

[ERROR] /shoot 管道中止於 review 階段
```
