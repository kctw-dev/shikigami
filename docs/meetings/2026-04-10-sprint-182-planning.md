# Sprint 182 Planning 會議紀錄

**日期**：2026-04-10
**類型**：Sprint Planning
**主持**：PO（sonnet fallback — opus 拒絕後降級）
**參與**：PO、Architect（評估）、QA（AC 審查）

---

## Sprint Goal

強化 QA 品質防線三要素 — PO 輸出自律（#994）、API 容錯自動化（#995）、閾值彈性化（#996），加上 Skill 依賴驗證補強（#940）

**日期**：2026-04-10 / 2026-04-17
**容量**：6 pts
**Velocity 基準**：Sprint 179/180/181 皆 6 pts

---

## Stories Selected

| Story | Issue | Points | Wave | Routing |
|-------|-------|--------|------|---------|
| PO Prompt Template 禁用軟性字樣 | #994 | 1 | Wave 1 | haiku |
| rule-ratio-measure.sh 支援 per-prompt THRESHOLD | #996 | 1 | Wave 1 | haiku |
| Subagent API Error Fallback | #995 | 3 | Wave 2 | sonnet |
| Skill 依賴宣告一致性驗證 | #940 | 1 | Wave 2 | haiku |

**總計**：4 Stories / 6 pts

---

## Wave 規劃

- **Wave 1（haiku 平行）**：#994（修改 po-prompt.md）+ #996（修改 rule-ratio-measure.sh + dispatch-preflight.sh）。修改目錄不重疊，平行安全。
- **Wave 2（sonnet + haiku 平行）**：#995（修改 SKILL.md §2.1）+ #940（新建 validate-skill-deps.sh）。修改範圍不重疊，平行安全。

---

## Risk Notes

- **#995 SKILL.md 衝突**：#995 修改 `skills/sprint-execution/SKILL.md` §2.1，Sprint 181 #989/#988 修改 §3 line 418 區塊。執行前需確認 base 為最新 main（PR#991/PR#992/PR#993 全數合入後）。
- **#996 依賴 dispatch-preflight.sh**：Sprint 181 #990 建立的 `dispatch-preflight.sh`（PR#993）需已合入 main 才能讓 #996 AC-5 正確修改。
- **#940 validate-all.sh 整合**：若 `validate-all.sh` 不存在，subagent 需建立並整合全部 validate-*.sh。

---

## 核心決策記錄

### 1. Sprint 181 Retro 三個 Action Items 全部選入

Sprint 181 Retro 識別三個 Action Item：

| Action Item | 對應 Story |
|------------|-----------|
| PO AC 輸出含軟性字樣導致 QA 打回 NEEDS_REVISION | #994（Wave 1） |
| rule-ratio-measure.sh THRESHOLD 硬編碼，無法按 step 設定門檻 | #996（Wave 1） |
| opus API 拒絕無自動 fallback，每次須人工介入 | #995（Wave 2） |

三個 Action Item 100% 選入 Sprint 182，補入 #940（sprint-candidate 已就緒）湊足 6 pts。

### 2. Planning 本身遇到 opus 拒絕，fallback 至 sonnet（#995 活證據）

Sprint 182 Planning 執行期間，主 session 嘗試以 opus 執行 PO Round 2 和 Architect 評估，遭遇 usage policy 拒絕，手動降級至 sonnet 繼續執行。

此事件直接驗證 #995 的必要性：
- 事件描述：`[MODEL-FALLBACK-MANUAL] planning from=opus to=sonnet reason=usage-policy`
- #995 AC-1 設計的自動化策略若已到位，此次降級將自動完成，無需人工介入

### 3. QA 發現 3 個 issue body 因特殊字元截斷，用 --body-file 重寫

Sprint 182 Planning Round 1 期間，QA 審查發現 #994、#995、#996 三個 issue 的 body 存在截斷問題（原因：body 含冒號、星號等 YAML 特殊字元，`--body "..."` 模式導致截斷）。

處置方式：
- 全部改用 `--body-file` 模式重寫
- 重寫後 AC 同步升級為硬性版本（移除所有軟性字樣，補上具體數值和測試條件）
- 符合 CLAUDE.md 第 13 條規定：「GitHub Actions workflow 中建立或更新 Issue body 時，禁止直接以 `--body "..."` 傳入多行字串」

---

## 附記

- Sprint 182 Planning 文件：`docs/sprints/sprint_182.md`
- Project Board 更新：`docs/PROJECT_BOARD.md`
- Sprint 181 已標記為完成（3/3 DONE，Velocity 6 pts，PR#991/PR#992/PR#993 全部 MERGED）
