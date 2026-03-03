# Sprint 30

**狀態**：進行中
**期間**：2026-03-16 ~ 2026-03-22
**Sprint Goal**：以 Issue #46 排程 PR 偵測為最高優先，同步修正 README 準確性並強化版本 Tag 策略，確保框架在開源延後期間的自我一致性與維護品質
**總計**：3 Stories / 4 Points

---

## Sprint Backlog

| Story ID | 標題 | Size | Points | QA doc-only 判定 | 狀態 |
|----------|------|------|--------|-----------------|------|
| US-54 | 互動 Session 自動偵測待審排程 PR + Scrum Master 提醒機制（Issue #46 子 Story #1） | S | 1 | No | 完成 |
| US-55 | README 準確性修正 — 版本號、Skill 數量、版本歷史對齊 | S | 1 | No | 完成 |
| US-56 | Deployment Readiness 版本 Tag 決策規則強化（Issue #36） | M | 2 | No | 待辦 |

**Sprint 容量**：4 Points

---

## Story 詳細 AC

---

### US-54：互動 Session 自動偵測待審排程 PR + Scrum Master 提醒機制（Issue #46 子 Story #1）

**來源**：GitHub Issue #46 子 Story #1
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As a Scrum Master running an interactive session, I want the system to automatically detect pending scheduled PRs and remind me at session start, so that I never miss reviewing a queued scheduled execution PR and the team's Sprint cadence remains unblocked.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | scrum-master SKILL.md 新增 PR 偵測步驟 | `skills/scrum-master/SKILL.md` 互動 Session 啟動段落新增排程 PR 偵測步驟 |
| AC2 | [靜態] | 有待審 PR 時的提醒格式 | 標準提醒區塊（PR 數量摘要 + 各 PR 編號/標題/建立時間 + 三選項） |
| AC3 | [靜態] | label 標準化定義 | `skills/schedule/SKILL.md` 腳本生成模板補充 `scheduled` label |
| AC4 | [靜態] | ADR-003 Checklist 通過 | 修改 skills/ 下 SKILL.md 前確認 ADR-003 四項條件 |

---

### US-55：README 準確性修正 — 版本號、Skill 數量、版本歷史對齊

**來源**：Architect 建議（Sprint 30 Planning）
**Size**：S / 1 Point
**Owner**：Developer

**User Story**
As an external user reading the README, I want the version number, Skill count, version history, and Sprint streak to accurately reflect the current project state, so that I can trust the documentation and make informed decisions about adopting Shikigami.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 版本號更新 | `README.md` 版本號（v0.3.9→v0.13.0 或最新 plugin.json 版本）更新；版本號與 `plugin.json` version 一致 |
| AC2 | [靜態] | Skill 數量與清單對齊 | 「17 個 Skills」→「21 個 Skills」（對齊 skills/ 目錄計數）；清單補入 schedule 與 shoot |
| AC3 | [靜態] | 版本歷史表格對齊 | 版本歷史表格補充 Sprint 16-29 交付里程碑 |
| AC4 | [靜態] | Sprint 連勝數更新 | 「連續 15 個 Sprint / 56 Stories / 4 ADR」更新為截至 Sprint 29 正確數值 |
| AC5 | [靜態] | ADR-003 Not Triggered | README.md 為說明文件，ADR-003 不適用 |

---

### US-56：Deployment Readiness 版本 Tag 決策規則強化（Issue #36）

**來源**：GitHub Issue #36 / Architect 建議（Sprint 30 Planning）
**Size**：M / 2 Points
**Owner**：Developer

**User Story**
As a Scrum Master running sprint review, I want deployment-readiness SKILL.md to define clear version Tag decision rules including a PO Override mechanism, and sprint-review SKILL.md to verify ROADMAP milestone alignment before deployment, so that the team has deterministic governance over version tagging and avoids accidental or inconsistent releases.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | 版本號選擇規則定義 | `skills/deployment-readiness/SKILL.md` 新增「版本 Tag 決策規則」段落 |
| AC2 | [靜態] | sprint-review SKILL.md 整合 ROADMAP 對齊檢查 | sprint-review deployment-readiness 步驟前新增里程碑對齊子步驟 |
| AC3 | [靜態] | 緊急覆蓋機制 | 定義 PO Override 機制，覆蓋行為標注 [PO-OVERRIDE] |
| AC4 | [動態] | Issue #36 關閉 | GitHub Issue #36 留言說明解決內容並關閉 |
| AC5 | [靜態] | ADR-003 Checklist 通過 | 修改兩個 SKILL.md 前通過 ADR-003 四項條件 |

---

## 平行分群（Architect 建議）

### Phase 1 — 可平行執行

| 群組 | Stories | 說明 |
|------|---------|------|
| Phase 1（平行） | US-55 | README 準確性修正，無 Hard Gate，完全獨立，可與 US-54 平行執行 |
| Phase 1（序列） | US-54 | 修改 scrum-master/SKILL.md + schedule/SKILL.md；需 ADR-003 Checklist 通過 |

### Phase 2 — US-54 完成後執行

| 群組 | Stories | 說明 |
|------|---------|------|
| Phase 2 | US-56 | 修改 deployment-readiness/SKILL.md + sprint-review/SKILL.md；依賴 US-54 完成（ADR-003 Checklist 確認模式已建立），需 ADR-003 Checklist 通過 |

**執行順序說明**：
- US-55 可在 Sprint 任意時間點平行執行，不阻塞任何其他 Story
- US-54 需完成 ADR-003 Checklist 確認後再修改 SKILL.md
- US-56 需在 US-54 完成後啟動，確保 SKILL.md 修改模式一致性；同時需通過 ADR-003 Checklist

---

## 工作容量

| 項目 | 數值 |
|------|------|
| Sprint 期間 | 2026-03-16 ~ 2026-03-22（7 天） |
| 總 Stories | 3 |
| 總 Points | 4 |
| 平行分群 | Phase 1（US-55 獨立平行 + US-54 序列）→ Phase 2（US-56，US-54 完成後） |

---

## ADR 觸發清單

| Story | ADR 編號 | 說明 |
|-------|----------|------|
| US-54 | 無新 ADR | 修改 SKILL.md，需通過 ADR-003 Checklist；無新架構決策 |
| US-55 | 無 | ADR-003 NOT triggered（README.md 為說明文件，非 SKILL.md 框架文件） |
| US-56 | 無新 ADR | 修改兩個 SKILL.md，需通過 ADR-003 Checklist；無新架構決策 |

**本 Sprint 無新建 ADR。**

---

## Sprint Planning 簽核

- **PO Round 1**：完成（Story 選取：US-54 S/1pt + US-55 S/1pt（替換原 QA 退回的 US-55）；Sprint Goal 確定；總計 2pt）
- **QA 退回**：US-55（原版本）— AC 不夠明確，退回重寫
- **Architect Round 1**：完成（追加 README 準確性修正 + Issue #36 版本 Tag 策略強化建議；US-54 S/1pt 確認，ADR-003 適用；US-55（新）S/1pt 確認，ADR-003 NOT triggered for README.md；US-56 M/2pt 確認，ADR-003 適用；平行分群：Phase 1 US-55 獨立平行 + US-54 序列，Phase 2 US-56）
- **QA Round 2**：完成（US-54 PASS；US-55（新 Story）AC 明確，PASS；US-56（新 Story）AC 明確，PASS；全部 Stories doc-only 判定：No — US-54/US-56 修改 skills/ 目錄，US-55 修改 README.md（根目錄，非 docs/））
- **PO Round 2**：完成（整合 Architect/QA 反饋；US-56 納入最終 Sprint Backlog；總計 4pt / 3 Stories；Sprint Backlog 最終確認）
