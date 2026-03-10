# Sprint 71

**Sprint Goal**：建立 QA 測試覆蓋驗證機制第一層 — Story-level 測試覆蓋 checklist
**期間**：2026-03-10 ~ 2026-03-17
**ADR 依賴**：無

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-182：QA 測試覆蓋驗證 — 第一層 Story-level checklist | #182 | M | 2 | 完成 |

---

## US-182：QA 測試覆蓋驗證 — 第一層 Story-level checklist

**User Story**

身為 QA Engineer，我需要在每個 Story 的 QA Review 階段驗證測試覆蓋率與舊測試一致性，以便及早發現測試缺口，避免累積測試債務。

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | [靜態] | `skills/sprint-execution/story-lifecycle-prompt.md` 的 QA self-review 段落新增測試覆蓋 checklist（CQ-NEW 兩項） | 文件可在指定位置找到 CQ-NEW 測試覆蓋率 checklist；包含判定標準說明 |
| AC2 | [靜態] | `skills/qa-engineer/SKILL.md` §1.x 子節新增「測試覆蓋驗證職責」說明，明確指定插入位置為 §1 QA 角色職責 的子節 | 在 qa-engineer/SKILL.md §1 之下可找到測試覆蓋驗證子節，內容與 story-lifecycle-prompt.md 的 checklist 一致 |
| AC3 | [靜態] | CQ-NEW 第一項「測試覆蓋率」：判定標準明確涵蓋 API 端點、資料庫查詢、業務邏輯三類場景 | checklist 中「測試覆蓋率」條目含三類場景的判定說明 |
| AC4 | [靜態] | CQ-NEW 第二項「舊測試一致性」：補充可操作判定標準，明確定義「測試通過但與實作矛盾」的偵測方式 | 判定標準至少包含：(a) 檢查測試是否斷言已移除的 UI 元素 / API 端點；(b) 確認 Story 描述的行為變更是否已反映在測試更新中 |
| AC5 | [動態] | QA Engineer 在下一個含業務邏輯的 Story 執行 Review 時，可按 checklist 完成測試覆蓋驗證 | QA Review 產出中包含 CQ-NEW 兩項的明確 PASS/FAIL 判定 |

**Out of Scope**

- 第二層：e2e-test Skill 新建（`skills/e2e-test/SKILL.md`）
- `skills/sprint-execution/SKILL.md` e2e-test 觸發點新增
- `skills/scrum-master/SKILL.md` 路由新增
- 自動化測試執行流程（Step 1–6 完整 E2E 流程）
- PASS/FAIL 判定標準完整矩陣（Critical/High/Low 分級）

**實作範圍**

| 檔案 | 修改說明 |
|------|----------|
| `skills/sprint-execution/story-lifecycle-prompt.md` | QA self-review 新增 CQ-NEW 測試覆蓋 checklist（2 項） |
| `skills/qa-engineer/SKILL.md` | §1 之下新增 §1.x 子節：測試覆蓋驗證職責 |

**Definition of Done**

- [x] AC1–AC4 靜態驗證：文件修改可在指定位置找到對應內容
- [x] AC5 動態驗證：下一個含業務邏輯的 Story QA Review 使用新 checklist
- [x] ADR-003 Code Quality Self-Review 完成
