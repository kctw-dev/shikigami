# Sprint 166

**Sprint Goal**：強化流程紀律與工具品質 — PR 強制化、haiku 路由規則自動化、Backlog 健康度觸發、validate-xrefs 測試覆蓋

**開始日期**：2026-03-26
**結束日期**：2026-04-02
**狀態**：進行中

---

## Velocity 計算

| Sprint | Velocity |
|--------|---------|
| Sprint 163 | 7 pts |
| Sprint 164 | 4 pts |
| Sprint 165 | 5 pts |
| **平均** | **5.33 pts** |
| **建議容量** | **4-6 pts（上限 6 pts）** |

> 腳本輸出：`[CAPACITY] avg_velocity=5pts, recommended_capacity=5pts (±20% range: 4-6pts)`

---

## Backlog 健康度

`[BACKLOG-OK]` sprint-candidate: 10 個，健康度正常，正常選入。

---

## Sprint Backlog

| # | Story | Issue | Points | Status | Owner |
|---|-------|-------|--------|--------|-------|
| 1 | retro: 測試腳本 Story 必須走 PR 流程 | #853 | 1 | DONE (#856) | Developer |
| 2 | retro: haiku 路由比例偏低 — ADR-039 Score 4-5 TEST/DOC 強制 haiku 規則 | #854 | 2 | DONE (#856) | Developer |
| 3 | retro: Backlog 候選不足導致 velocity 波動 — 自動補充觸發機制 | #855 | 2 | DONE (#856) | Developer |
| 4 | feat: validate-xrefs.sh 自動化測試 — 交叉引用驗證完整性 | #840 | 1 | DONE (#856) | Developer |

**Total: 6 pts**

---

## Architect 技術評估

| Story | T-shirt | ADR 需求 | API 契約 | Related SDDs | 說明 |
|-------|---------|---------|---------|-------------|------|
| #853 | S | 無需 ADR | 不適用 | — | 修改 skills/sprint-execution/SKILL.md + story-lifecycle-prompt.md；PR 強制化規則 |
| #854 | M | 修改現有 ADR-039（非新建）| 不適用 | — | ADR-039 新增 Score 4-5 TEST/DOC/LOG 強制 haiku 規則；agents prompt 補充 |
| #855 | M | 無需 ADR | 不適用 | — | 修改 skills/sprint-review/SKILL.md + skills/cruise/references/po-patrol.md；Step 5.6 延伸強化 |
| #840 | S | 無需 ADR | 不適用 | — | 新建 tests/test-validate-xrefs.sh，使用 fixture，無架構影響 |

**複雜度影響**：預計 TOTAL_LINES ~10274（+250），遠低於門檻 25000 → PASS

**平行分群**：所有 4 Stories 修改不同檔案，可平行派遣（SHIKIGAMI_MAX_PARALLEL=2 分兩批）。

---

## QA 驗收確認

| Story | 結論 | Path Verification | 備註 |
|-------|------|-------------------|------|
| #853 | APPROVE | PASS | QA Minor 建議：補 AC4（Sprint 166 起立即生效） |
| #854 | APPROVE | PASS | QA Minor 建議：補 AC4（防 over-correction 規則） |
| #855 | APPROVE | PASS | QA Minor 建議：補 AC4（冪等性保障） |
| #840 | APPROVE | N/A（新建）| NFR1 < 3 秒可測 |

---

## DoD（Definition of Done）

- [ ] 所有 AC 通過驗收
- [ ] **PR created & merged**（#853 規則生效：所有 Story 含 test-only 須走 PR）
- [ ] git commit + push 完成
- [ ] 相關 Issues 更新 `status: in-sprint` label

---

## 不入選 Stories

| Issue | 原因 |
|-------|------|
| #843 | 超出容量上限（6 pts），移至下 Sprint |
| #846, #841, #848, #849, #842 | 優先級 could，容量不足，留 Backlog |
| #854, #855 | 優先 should，選入（已列入上方） |

---

## 複雜度快照

```
SKILL_COUNT=31（門檻 40）
AGENT_COUNT=8（門檻 15）
HOOK_COUNT=30（門檻 35）
TOTAL_LINES=10024（門檻 25000）
RESULT: PASS
```
