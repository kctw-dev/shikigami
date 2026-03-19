# Sprint 106

**Sprint Goal**：建立版號智慧策略與首階段績效可視化（會議紀錄）
**日期**：2026-03-20
**容量**：3 points
**狀態**：已完成

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| INFRA：版號策略 — 當日 minor 降級 patch | #305 | S | 1 | 完成 |
| FEATURE：Sprint 儀式會議紀錄自動產生（#317 P1） | #317 | M | 2 | 完成 |

## Acceptance Criteria

### #305 — 版號策略：當日 minor 降級 patch（S, 1pt）

> **方法論**：規則嵌入
> **修改範圍**：`skills/deployment-readiness/SKILL.md`（非 sprint-review）

**AC-1：當日已有 minor bump 時，後續 bump 降級為 patch**
- 查詢 `git tag --sort=-creatordate` 取得最新 tag
- 若最新 tag 的日期為今天且為 minor bump → 後續 bump 改為 patch
- 範例：今天已有 `v0.74.0` → 下次 bump 為 `v0.74.1`

**AC-2：跨日第一次 bump 維持 minor（不受影響）**
- 若最新 tag 日期為昨天或更早 → 正常 minor bump
- 範例：昨天最後 tag 為 `v0.74.1` → 今天第一次為 `v0.75.0`

**AC-3：`git tag --sort=-creatordate` 查詢可正常運作**
- tag 查詢指令在專案環境中可正確排序
- 無 tag 時降級為正常 minor bump（不報錯）

### #317 Phase 1 — Sprint 儀式會議紀錄自動產生（M, 2pt）

> **方法論**：Skill 流程擴充
> **修改範圍**：`skills/sprint-planning/SKILL.md` + `skills/sprint-review/SKILL.md`
> **Phase 1 範圍**：sprint-planning / sprint-review / retro 三種會議紀錄

**AC-1：sprint-planning 完成後自動產生 `docs/meetings/YYYY-MM-DD-sprint-planning.md`**
- 會議紀錄在 Sprint Planning commit 前產生
- 檔名格式：`YYYY-MM-DD-sprint-planning.md`（日期用 `date` 指令取得）

**AC-1.1：紀錄含 frontmatter**
- YAML frontmatter 必須包含：`type`、`sprint`、`date`、`start_time`、`end_time`、`participants`
- `type` 值為 `sprint-planning` / `sprint-review` / `retrospective`

**AC-1.2：紀錄含結論**
- Sprint Planning 紀錄包含：Sprint Goal、選入 Stories 清單
- Sprint Review 紀錄包含：各 Story 驗收結果、Velocity
- Retrospective 紀錄包含：Good / Problem / Action Items

**AC-1.3：sprint-review 和 retro 同樣產生對應紀錄**
- `YYYY-MM-DD-sprint-review.md`
- `YYYY-MM-DD-retrospective.md`
- 格式與 frontmatter 結構一致

## 技術評估摘要

### Architect 備注

- **不需要 ADR** — 規則嵌入與流程擴充，不涉及架構變更
- #305 修改 `deployment-readiness/SKILL.md`（非 sprint-review）
- #317 P1 修改 `sprint-planning/SKILL.md` + `sprint-review/SKILL.md`
- 會議紀錄格式：YAML frontmatter + Markdown body
- 兩個 Story 可完全平行執行

### QA 備注

- **所有 AC 可驗證**
- #305：3 項 AC 皆為規則型，可用 tag 查詢指令驗證
- #317 P1：4 項 AC 皆為檔案產出型，可用檔案存在性 + 內容解析驗證
- `docs/meetings/` 目錄尚不存在，實作時需建立
- **DoR**：PASS
- **防漂移基準**：2 Stories, 3 pts

---

## §2 Sprint Review（2026-03-20）

### §2.1 PO Demo

| Story | Issue | 結果 | 測試 |
|-------|-------|------|------|
| INFRA：版號策略 — 當日 minor 降級 patch | #305 | PASS | 10/10 |
| FEATURE：Sprint 儀式會議紀錄自動產生（P1） | #317 | PASS | 10/10 |

### §2.2 QA 邊界（輕量）

- #305：3 項規則型 AC 全數通過；`git tag --sort=-creatordate` 查詢正常；無 tag 時降級邏輯正確
- #317：4 項 AC 皆通過；frontmatter 欄位完整（type/sprint/date/start_time/end_time/participants）；三種會議紀錄格式一致

### §2.3 Stakeholder 確認

- #317 外部審查：CONFIRM（50% 抽樣，1/2）
- 整體 DISPUTE 率：0%

### §2.4 Architect 亮點

- #305 實作位置修正：sprint-review → deployment-readiness（Architect 主動識別並修正）
- #317 Phase 1 覆蓋 sprint-planning + sprint-review + retro 三種會議紀錄

### §2.5 未完成範圍

- #317 Phase 2（其他儀式會議紀錄）、Phase 3（整合/自動化）尚未實作

### §2.6 Issue 狀態回寫

- #305：關閉（INFRA 完成，規則已嵌入 deployment-readiness/SKILL.md）
- #317：保持 open（Phase 2/3 待後續 Sprint）

---

## §3 Retrospective（2026-03-20）

### Good

- 正式討論流程充分：PO → Architect → QA → PO R2，各角色職責清晰
- Architect 主動修正 #305 實作位置（sprint-review → deployment-readiness），避免概念混淆
- 兩個 Story 完全平行執行，效率高

### Problem

- 無顯著問題

### Action Items

- 無

---

## Metrics

| 指標 | 數值 |
|------|------|
| Velocity | 3 points |
| 完成率 | 100%（2/2） |
| 外部抽樣 CONFIRM | 50%（1/2） |
| DISPUTE 率 | 0% |

**版本 bump**：v0.75.1 → v0.76.0（minor，新功能：Sprint 儀式會議紀錄 #317）
