# Sprint 74

**Sprint Goal**：使用者體驗與開發流程雙強化 — README 首印象重塑 + API 契約 Hard Gate 落地 + E2E 測試基礎設施補齊
**期間**：2026-03-11 ~ 2026-03-18
**ADR 依賴**：無

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-194：feat: README 資訊架構重設計 — 30 秒內讓人知道怎麼開始用 | #194 | M | 2 | 完成 |
| US-195：feat: API 契約 Hard Gate — 涉及 API 的 Story 無契約不得進入開發 | #191 | M | 2 | 待開始 |
| US-196：docs: E2E 測試 Client 端教學手冊 — CDP 穿隧 + 本地瀏覽器連接 SOP | #193 | S | 1 | 完成 |
| US-197：feat: E2E 測試 Server 端模板 — Playwright workflow + CI 登入自動化模板 | #192 | L | 3 | 待開始 |

**總計**：8 points（2M + 1S + 1L）

**權重調整記錄**：歷史趨勢穩定（Sprint 70-73 完成率均 100%），8 points 為近期最高負載但全為 doc-only 或模板類工作，風險可控。

**Architect 平行分群建議**：
- Phase 1（平行）：US-194 / US-195 / US-196 — 三者修改完全不同檔案群，無依賴衝突
- Phase 2（序列）：US-197 — 等 US-196 完成後啟動（US-197 Server 端模板參照 US-196 Client 端教學的穿隧方案）

**Architect 方法論適用性評估摘要**：
- US-194（README 重設計）：doc-only，無技術風險，無 ADR 需求
- US-195（API 契約 Hard Gate）：doc-only，修改 3 個 SKILL.md，修改範圍明確，無 ADR 需求
- US-196（E2E Client 教學）：doc-only，純文件撰寫，無 ADR 需求
- US-197（E2E Server 模板）：涉及 GitHub Actions workflow 模板 + CI 登入腳本模板，Confidence 60%（Firebase Token 方案需考慮不同認證），無 ADR 需求但實作時需留意泛用性

---

## 各 Story 詳情

### US-194：feat: README 資訊架構重設計 — 30 秒內讓人知道怎麼開始用

**Issue**：#194
**MoSCoW**：Must
**Size**：M（2pt）
**doc-only**：YES

**User Story**：As a 第一次看到 Shikigami 的開發者，I want README 在 30 秒內告訴我這是什麼、怎麼裝、怎麼用，so that 我不需要讀完整份文件就能開始嘗試。

**Acceptance Criteria**：

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | 30 秒區塊 | README 前 20 行內包含：一句話說明 + 安裝指令 + 第一個可執行的命令 |
| AC2 | 資訊分層 | README 採用漸進式揭露：Quick Start → 功能概覽 → 進階設定。詳細內容移至 docs/ |
| AC3 | 移除內部細節 | 版本歷史、Sprint 記錄、開發者備忘等內部資訊從 README 移至 docs/CHANGELOG.md 或 docs/CONTRIBUTING.md |
| AC4 | 使用情境範例 | 提供至少 2 個「我想要 X，所以我執行 Y」的具體使用情境（非功能列表） |
| AC5 | 視覺層次清晰 | 使用 badges、區塊引用、折疊區段等 Markdown 元素建立視覺層次，避免純文字牆 |

**Done 定義**：
- [x] AC1-AC5 全部通過
- [x] QA Review PASS

---

### US-195：feat: API 契約 Hard Gate — 涉及 API 的 Story 無契約不得進入開發

**Issue**：#191
**MoSCoW**：Must
**Size**：M（2pt）
**doc-only**：YES

**User Story**：As a Developer，I want 涉及 API 互動的 Story 在進入開發前必須有 Architect 產出的 API 契約，so that 前後端開發有共同參照基準，避免欄位名/型別不一致的問題在 Review 才被發現。

**Acceptance Criteria**：

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | Architect SKILL.md 新增 API 契約產出職責 | `skills/architect/SKILL.md` 技術評估步驟明確要求：涉及 API 互動的 Story 必須產出 API 契約（endpoint / method / request schema / response schema） |
| AC2 | API 契約模板格式定義 | `skills/architect/SKILL.md` 內嵌標準化契約模板（Markdown 表格格式，含 endpoint / method / request schema / response schema 欄位） |
| AC3 | Sprint Planning 輸出新增 API 契約欄位 | `skills/sprint-planning/SKILL.md` Architect 評估輸出表格新增「API 契約」欄位（有/無/不適用） |
| AC4 | Story-Lifecycle Hard Gate | `skills/sprint-execution/story-lifecycle-prompt.md` §3 Green 前新增 Hard Gate：涉及 API 的 Story 若無 API 契約，阻擋開發並升級至 Architect |
| AC5 | 不涉及 API 的 Story 不受影響 | Architect 技術評估表格中「API 契約」欄位標記為「不適用」的 Story，Story-Lifecycle subagent 跳過此 Gate，不觸發阻擋 |

**Done 定義**：
- [ ] AC1-AC5 全部通過
- [ ] QA Review PASS

---

### US-196：docs: E2E 測試 Client 端教學手冊 — CDP 穿隧 + 本地瀏覽器連接 SOP

**Issue**：#193
**MoSCoW**：Could
**Size**：S（1pt）
**doc-only**：YES

**User Story**：As a 消費端開發者，I want 一份 CDP 穿隧設定和本地瀏覽器連接的 step-by-step 教學，so that 我能在 Sprint Review 時用本地 Chrome 進行探索性 E2E 驗證。

**Acceptance Criteria**：

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | CDP 穿隧 SOP | `docs/tutorial/` 新增 CDP 穿隧教學：Chrome remote debugging 啟動 → SSH reverse tunnel → Playwright connectOverCDP |
| AC2 | 前置條件清單 | 明確列出需要的工具（Chrome、SSH、Playwright）和環境需求 |
| AC3 | 快速驗證步驟 | 提供 3 步內可驗證「穿隧是否成功」的測試指令 |
| AC4 | Troubleshooting | 常見問題（port 衝突、防火牆、WSL 特殊設定）至少 3 條 |

**Done 定義**：
- [x] AC1-AC4 全部通過
- [x] QA Review PASS

---

### US-197：feat: E2E 測試 Server 端模板 — Playwright workflow + CI 登入自動化模板

**Issue**：#192
**MoSCoW**：Could
**Size**：L（3pt）
**doc-only**：NO

**User Story**：As a 消費端專案使用者，I want Shikigami 提供可直接複製使用的 E2E 測試 GitHub Actions workflow 模板和 CI 環境登入模板，so that 我能快速建立 tag-triggered E2E 測試管線，不需從零設計。

**Acceptance Criteria**：

| # | 條件 | 通過標準 |
|---|------|---------|
| AC1 | Playwright E2E workflow 模板 | 提供 `.github/workflows/e2e.yml` 模板，tag-only 觸發，含 Playwright 安裝 + headless 執行 + artifact 上傳 |
| AC2 | Firebase Custom Token CI 登入模板 | 提供 `docs/templates/ci-firebase-login.js` 腳本模板，用 Service Account 產 custom token → 換 ID token |
| AC3 | deployment-readiness 整合 | `skills/deployment-readiness/SKILL.md` 新增 L3 E2E 驗證步驟（可選，非 Hard Gate），指向模板 |
| AC4 | 模板為泛用格式 | 模板使用 `YOUR_VARIABLE_NAME` 大寫佔位符格式（如 `YOUR_PROJECT_ID`、`YOUR_TEST_URL`），非硬編碼特定專案 |

**Done 定義**：
- [ ] AC1-AC4 全部通過
- [ ] QA Review PASS
