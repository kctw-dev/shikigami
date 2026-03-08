# Sprint 59

**狀態**：完成
**期間**：2026-03-08 ~ 2026-03-14
**Sprint Goal**：鞏固 M5 穩定化 — 修補已知 plugin 載入問題的框架端文件缺口（TROUBLESHOOTING.md shallow clone 根因文件化）。
**ADR 依賴**：無
**總計**：1 Stories / 1 Points

---

## Sprint Backlog

| Story ID | Issue # | 標題 | Size | Points | doc-only | 狀態 |
|----------|---------|------|------|--------|----------|------|
| US-157 | #101 | Plugin 載入失敗 Workaround 正式文件化 — TROUBLESHOOTING.md 新增 shallow clone 根因分析與操作 SOP | S | 1 | 是 | 完成 |

**Sprint 容量**：1 Points（1 Story）

---

## 平行分群方案

| Phase | Stories | 說明 |
|-------|---------|------|
| Phase 1 | US-157 | 僅 1 個 Story，單獨執行。無 Phase 2。 |

---

## Story 詳細 AC

---

### US-157：Plugin 載入失敗 Workaround 正式文件化 — TROUBLESHOOTING.md 新增 shallow clone 根因分析與操作 SOP

**來源**：Issue #101 — bug: /plugin 間歇性載入失敗
**Issue**：#101
**Size**：S / 1 Point
**QA doc-only 判定**：Yes（純文件更新）
**前置依賴**：無（Phase 1，單獨執行）

**User Story**

As a developer using the Shikigami plugin, I want a documented troubleshooting guide that explains the root cause of intermittent plugin loading failures and provides a clear SOP to resolve them, so that I can quickly recover from a broken plugin state without needing to investigate the underlying platform issue myself.

**Acceptance Criteria**

| # | 類型 | 條件 | 通過標準 |
|---|------|------|----------|
| AC1 | 靜態 | TROUBLESHOOTING.md 新增段落存在且完整 | `docs/tutorial/TROUBLESHOOTING.md` 新增段落包含四個子要素：(a) 根因說明（出現「shallow clone」或「depth=1」字樣）；(b) 觸發條件（git push 後開啟新 Session）；(c) 操作 SOP（含可複製執行的 `/plugin install shikigami` 指令）；(d) 預防建議（里程碑式版號更新降低 push 頻率） |
| AC2 | 靜態 | Issue #101 body 根因更新 | Issue #101 body「可能原因」區段從「待調查」更新為已確認根因（shallow clone + gitCommitSha 不匹配），並包含指向 TROUBLESHOOTING.md 新段落的連結或引用 |

**Done 定義**

- [ ] `docs/tutorial/TROUBLESHOOTING.md` 已新增段落，包含 (a) shallow clone / depth=1 根因說明、(b) 觸發條件、(c) `/plugin install shikigami` SOP 指令、(d) 預防建議（AC1）
- [ ] Issue #101 body「可能原因」區段已更新為已確認根因，並包含 TROUBLESHOOTING.md 連結或引用（AC2）

---

## Sprint Notes

- **Velocity 目標**：1 pt（本 Sprint 為 Backlog 嚴重枯竭期間的過渡 Sprint，以穩定交付單一高價值修補為目標）
- **Backlog 背景**：Backlog 嚴重枯竭。本 Sprint 僅能承接 1 個 Story。US-158（Issue #59 衍生，Beta 招募機制文件化）因與 2026-03-03 MEMORY 決策衝突（M5 條件 (a) 外部使用者觸及已非活躍優先）遭 Architect 退回，需 PO 先釐清策略意圖後才能重新評估。
- **建議**：Sprint 執行期間同步安排 Backlog Grooming Session，識別新的 Story 候選（可從 M5 穩定化 ADR 衍生項目、Issue 清單中挖掘），避免 Sprint 60 同樣陷入 Backlog 枯竭困境。
- **US-158 處置**：暫緩，等 PO 明確策略方向後重新評估。若 2026-03-03 決策（open-sourcing 延後至 2028）維持不變，US-158 可能直接 DROP。
