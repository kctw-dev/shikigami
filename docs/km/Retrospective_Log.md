# Retrospective Log

> 歷史 Retro 記錄：[RETRO_ARCHIVE](archive/RETRO_ARCHIVE.md)（Sprint 1–17）

---

## Sprint 22 — 2026-03-03

**參與角色**：PO、Architect、Developer、QA、Security、Stakeholder

### Good

1. 連續 22 個 Sprint 100% 完成率，Sprint 22 Velocity 6pt 為近 10 Sprint 最高
2. ADR-006（Prompt Injection Protection）與 ADR-007（Story-Lifecycle Subagent）雙 ADR 同 Sprint 交付，首次在單一 Sprint 內完成兩個架構決策記錄
3. 61 個新測試（US-33: 13, US-37: 17, US-38: 12, US-39: 19），測試覆蓋持續擴展
4. 4 Stories 全部 Phase 1 平行執行零衝突，排程模式偵測端到端閉環驗證（cron template → SKILL.md HARD-GATE）

### Problem

1. US-33 Code Quality Review 發現 onboarding SKILL.md §2.3 仍寫「3 個核心範本」但實際已為 4 個（Medium，stale count），以及 BACKLOG_DONE.md template 使用「管理者」而非「擁有者」（Low，用語不一致）
2. US-37 ADR-006 承諾的 JSON schema output validation TECH-DEBT 未登錄至 Tech_Debt_Registry.md（Medium，DoD 合規缺口）
3. US-38 `export SHIKIGAMI_SCHEDULED=true` 在 cron template 中為無條件注入所有 Skill，未限定 sprint-planning（Medium，環境變數洩漏風險）
4. #56 和 #57 連續 2 Sprint 未關閉，觸發 Stakeholder 升級（逾期 Action Items 處理延遲）

### Action Items

| # | Action | Owner | 驗收方式 | Issue | 狀態 |
|---|--------|-------|----------|-------|------|
| — | 無新增 Action Items | — | — | — | — |

> 所有 Problem 均為 Low/Medium 嚴重度，可於後續 Sprint 正常 Story 執行中處理，不建立新 Action Item。已升級項目（#56, #57）已在 GitHub Issues 追蹤中。

---

## Sprint 21 — 2026-03-02

**參與角色**：PO、Architect、Developer、QA、Stakeholder

### Good

1. 完成率 100% 連續 21 個 Sprint 維持（Sprint 1-21 全數達成）
2. Phase 1 全平行派遣（3 Stories 零衝突）— Architect 分群準確，所有 Story 修改不同檔案
3. Sprint 20 Retro Action Item #58 即時清零（1 Sprint 關閉速度），維持 Action Items 高效追蹤
4. 測試覆蓋持續擴展 — Sprint 21 新增 39 個測試（9 lsize + 15 conflict-detection + 15 setup-labels），品質門禁穩固
5. US-34 setup-labels.sh 為新用戶 Onboarding 補齊最後一塊拼圖，減少手動 Label 配置時間

### Problem

1. Code Quality Review 發現多個測試腳本缺少 `-e` flag（`set -uo pipefail` 而非 `set -euo pipefail`），測試基礎設施防禦性撰寫仍有改善空間
2. US-32 告警格式僅示範 2 個 Story 同時衝突，未說明 3+ Story 同時衝突同一檔案時的格式擴展規則（Code Quality Medium 建議）

### Action Items

| # | Action | Owner | 驗收方式 | Issue | 狀態 |
|---|--------|-------|----------|-------|------|
| — | 無新增 Action Items | — | — | — | — |

> Problem 1 屬 Low 嚴重度改善建議，不建立 Action Item，後續 Sprint 遇到時順手修正即可。
> Problem 2 屬 Medium 建議但影響範圍有限（3+ Story 同時衝突罕見），納入 Backlog 候選而非強制 Action。

---

## Sprint 20 — 2026-03-02

**參與角色**：PO、Architect、Developer、QA、Security、Stakeholder

### Good

1. 完成率 100% 連續 20 個 Sprint 維持（Sprint 1-20 全數達成）
2. Phase 平行派遣持續有效 — Retro #56 + Retro #57 平行無衝突
3. US-31 /shoot 短衝模式從 Sprint 17 Retro 起跨 3 Sprint 終於完成交付，Stakeholder 滿意
4. Sprint 19 Retro Action Items 全數清零（#56, #57 均在 Sprint 20 完成）
5. 測試覆蓋持續擴展 — Sprint 20 新增 74 個測試（62 shoot + 12 conflict），總計 238 個測試

### Problem

1. US-31 Code Quality Review 識別 shoot SKILL.md 的 grep 示例與「大小寫不敏感」聲明矛盾、sprint-review §2.5 日期來源未明確 — L size Story 的規格品質仍需 QA 多輪捕捉
2. 快思模式跳過 Token 記錄持續為 N/A — 成本可見性仍有盲區（延續 Sprint 18 Problem 趨勢）

### Action Items

| # | Action | Owner | 驗收方式 | Issue | 狀態 |
|---|--------|-------|----------|-------|------|
| 1 | L-size Story SKILL.md 規格品質強化 — QA 增加示例一致性檢查項 | QA | QA Code Quality Review Checklist 新增示例一致性檢查項，L-size Story 強制多輪審查 | #58 | Closed（Sprint 21） |

> Problem 2 不建立新 Issue（此為長期結構性問題，快思模式設計即跳過 Token 記錄，非 Action Item）

---

## Sprint 19 — 2026-03-02

**參與角色**：PO、Architect、Developer、QA、Security、Stakeholder

### Good

1. 完成率 100%（連續 Sprint 15-19 五個 Sprint），4/4 Stories 全數 PASS
2. Phase 1 平行派遣零衝突，Retro #54 + US-30 同時執行無檔案衝突
3. QA Code Quality Review 有效攔截 US-30 空表格邊緣案例與 US-36 group-name 未驗證缺陷，回饋後快速修復
4. Security Review 觸發正確（US-36 涉及外部輸入 + crontab 配置），全面通過
5. 上 Sprint Retro Action Items 清零（#53、#54、#48 全部 Sprint 19 關閉）

### Problem

1. 測試基礎設施不穩定：`assert_contains` 使用 `echo $VAR | grep` 管道在大型變數下有 SIGPIPE 非確定性失敗（pre-existing，Sprint 19 新增區段改用 `assert_file_contains` 迴避但未修復根因）
2. Developer subagent 修改 PROJECT_BOARD.md / sprint_19.md 狀態欄被覆蓋：主 session 更新狀態後 Developer commit 時檔案已變更導致狀態回退，需手動重新修正

### Action Items

| # | Action | Owner | 驗收方式 | Issue | 狀態 |
|---|--------|-------|----------|-------|------|
| 1 | 修復 test-schedule.sh assert_contains SIGPIPE 非確定性失敗 | Developer | test-schedule.sh 連續執行 10 次零失敗 | #56 | Open |
| 2 | Developer subagent 狀態更新衝突防護 — sprint-execution 主 session 狀態鎖機制 | Architect | Developer subagent 不再覆蓋主 session 已更新的狀態欄 | #57 | Open |

---

## Sprint 18 — 2026-03-02

**參與角色**：PO、Architect、Developer、QA、Security、Stakeholder

### Good

1. 完成率 100%（連續 Sprint 15-18 四個 Sprint），US-35 全部 9 項 AC 通過驗收，74 項測試零失敗
2. Stakeholder 即時發現 multi-project lock collision bug（ADR-005 鎖名撞名）並修正，角色制衡有效
3. ADR-005 先行完成解鎖 Hard Gate 零阻塞，5 個技術決策域全部 Accepted
4. 三階段 QA 審查（Spec Compliance + Code Quality + Security）全 PASS，Security Review 首次觸發運作正常

### Problem

1. Security Review 發現 skill name 缺少字元白名單驗證（中嚴重度），Developer 實作與 QA Code Quality Review 均未攔截此輸入驗證缺口
2. Code Quality Review 發現 `set -uo pipefail` 缺少 `-e` flag，模板基礎品質有改善空間
3. Token 記錄持續為 N/A（快思模式跳過 Token 測量），成本可見性仍為長尾問題

### Action Items

| # | Action | Owner | 驗收方式 | Issue | 狀態 |
|---|--------|-------|----------|-------|------|
| 1 | schedule skill — skill name 字元白名單驗證，Pre-flight 入口加入正則 `^[a-z0-9][a-z0-9-]{0,63}$` | Developer | 測試套件覆蓋非法字元場景 | #53 | Open |
| 2 | schedule skill — 模板品質強化（`set -euo pipefail` + crontab 備份 `mktemp` + `chmod 600`） | Developer | 模板修正後測試套件驗證 | #54 | Open |


