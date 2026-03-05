# Retrospective Log

> 歷史 Retro 記錄：[RETRO_ARCHIVE](archive/RETRO_ARCHIVE.md)（Sprint 1–42）

---

## Sprint 48 — 2026-03-05

**Sprint Goal**：解決 ADR-013 高優先級開放問題（OQ-1、OQ-2），驗證 drawio-mcp-server stdio local 環境可行性，為 shikigami:diagram SKILL.md 實作提供可信的技術基礎

### Good（保持做的事）

1. US-97 PASS，OQ-1/OQ-2 均成功回填至 ADR-013，技術前提完整建立，子 Story B 進入可實作狀態；Sprint 48 解鎖了整個 #89 技能鏈的後續執行
2. 重要架構發現（v1.8.0 不需 headless Chrome）被正確記錄至 ADR-013 並更新影響範疇：對 ADR-012 多 GCE 環境、CI 跳過決策的影響均已分析完整，知識管理品質高
3. 連續 48 個 Sprint 100% 完成率，Sprint Goal 達成（1/1 Story PASS），執行紀律持續穩定

### Problem（需改進的事）

1. drawio-mcp-server v1.8.0 的 OQ-2 解答揭示技能設計重要限制：v1.8.0 不直接產出 PNG/SVG（無 headless Chrome rendering），技能實作模式需從「產出圖片檔案」調整為「操控 Draw.io diagram 狀態」，子 Story B 的 AC 需依此重新定義雙格式輸出的可行路徑
2. AC4（claude mcp list 通訊驗證）標注「需手動驗證」，屬動態 AC 尚未完整自動化，後續技能實作完成後應補足此驗證方式

### Action Items

1. Sprint 49 Planning 需將子 Story B AC2（雙格式輸出）的通過標準對齊 v1.8.0 實際能力，明確定義「雙格式輸出」在目前工具限制下的可行範圍與 Done 定義

---

## Sprint 47 — 2026-03-05

**Sprint Goal**：為 shikigami:diagram 技能建立架構決策基礎 — 起草 ADR-013，評估 MCP 整合架構

### Good（保持做的事）

1. ADR-013 完成四決策域系統性論證（部署形態、MCP Transport、CI 整合策略、安全考量），分析架構嚴謹完整，將 Issue #89 實作風險從 L 降至 M 的可能性，為後續 Sprint 奠定可信的技術前提
2. stdio local 方案決策有理有據：YAGNI 原則、維護成本、技術成熟度、CI 相容性四個維度一致指向同一結論，決策品質高，Stakeholder 接受度強
3. 連續 47 個 Sprint 100% 完成率，Goal 達成（1/1 Story PASS），Sprint 執行紀律持續穩定

### Problem（需改進的事）

1. Backlog 接近耗盡：目前僅剩 Issue #89（L-size，ADR 前置已完成），需在後續 Sprint Planning 中補充候選 Stories，避免 Backlog 乾涸影響 Sprint 持續性

### Action Items

本 Sprint 無新增 Action Items。

---

## Sprint 46 — 2026-03-05

**Sprint Goal**：確保多 GCE 開發架構穩定落地 — 建立版號三檔同步安全網，並完成開發環境可攜性與可重建性方案

### Good（保持做的事）

1. 兩個 Story（US-94、US-95）完全平行執行，無共享資源衝突，零衝突完成，Phase 1 分群策略再次驗證有效
2. bump-version.sh 原子操作設計正確：單一指令同步三檔，徹底消除 Sprint 45 Retro Action Item #1 識別的版號漏更新根因
3. 環境可攜性方向（Dotfiles Repo）與 ADR-012 §環境管理考量完美對齊，架構前置決策投資在本 Sprint 得到完整回報

### Problem（需改進的事）

本 Sprint 無明顯問題。

### Action Items

本 Sprint 無新增 Action Items。

---

## Sprint 45 — 2026-03-05

**Sprint Goal**：完善多開發環境操作文件 — 建立 GCE 認證設定指引與 CI/CD workflow 拆分指引

### Good（保持做的事）

1. 兩個 Story 完全平行派遣執行，Architect 分群策略零衝突，Sprint 執行效率高
2. doc-only Story 識別正確，TDD 豁免節省執行時間，雙階段 QA 維持品質門禁
3. ADR-012 前置決策完整，US-A 的 AC 修訂方向明確，PO/Architect/QA 三方協作順暢

### Problem（需改進的事）

1. 版號更新遺漏：打 v0.28.1 patch 時只更新 plugin.json，漏了 marketplace.json 與 gemini-extension.json，導致 CI Structural Validation 失敗
2. Issue #87 原始 AC 與 ADR-012 決策存在結構性矛盾：Planning 時需全面重寫 AC（從 API Key Pool 改為文件化工作），增加 Planning 時間成本

### Action Items

| # | Action | Owner | 驗收方式 | Issue |
|---|--------|-------|----------|-------|
| 1 | 版號更新流程建立 checklist 或自動化腳本，確保 plugin.json / marketplace.json / gemini-extension.json 三檔同步 | Developer | 下次版號更新時驗證三檔一致 | #94 |

---

## Sprint 44 — 2026-03-05

### Good
- 連續 44 個 Sprint 100% 完成率（1/1 Story PASS），Sprint Goal 達成：ADR-012 起草完成並於 Sprint Review 中升級為 Accepted，多 GCE 平行開發認證架構決策落地
- 輕量 Sprint 策略（1pt）證明正確：ADR-012 經歷多輪迭代討論（API Key Rotation → Max 帳號輪換 → 多 GCE 平行開發 + 工作移動），實際工作量遠超 1pt 估點但成果品質因充分討論而顯著提升
- ADR-012 ToS 合規分析誠實面對 MEDIUM-LOW 風險評級，未刻意美化使用情境（「工作流向有可用額度的機器」而非嚴格的「耗完即停」），決策品質因透明度而提升
- §1.5 一致性審查機制連續第三個 Sprint 驗證有效（攔截 3 項：ROADMAP 遺漏 US-92、Issue #86 標題不一致、版本號 v0.26.0→v0.27.0 未更新），Sprint 38-40 Problem 引發的改進閉環持續穩定
- Stakeholder 建議 ADR-012 直接升級為 Accepted（原為 Proposed），加速後續 Sprint 45 US-A 實作啟動，決策效率佳

### Problem
- ADR-012 初始範圍定義錯誤（API Key Rotation vs Max 訂閱帳號輪換），導致整份 ADR 需完全重寫。根因：Sprint Planning 時 Story 標題描述不夠精確，「API Key Rotation」未準確反映使用者實際需求（Max 訂閱帳號管理）
- ADR-012 經歷 3 次完全重寫（API Key → 單機帳號輪換 → 多 GCE 平行開發），迭代次數偏高。雖最終品質佳，但反映 ADR 起草前的需求探索不夠充分

### Action Items

本 Sprint 無新增 Action Items。

> Problem 1 與 Problem 2 均在 Sprint 執行過程中透過與使用者反覆討論解決，最終 ADR 品質經 QA 5/5 AC PASS 與 Stakeholder 接受確認。根因為 Story 標題精確度不足，屬 Sprint Planning 階段可改善項目，但因 ADR 類 Story 本質上需要探索性討論，非結構性缺陷，無需獨立追蹤。

---

## Sprint 43 — 2026-03-04

### Good
- 連續 43 個 Sprint 100% 完成率（2/2 Stories PASS），Sprint Goal 達成：Issue #69 精化為 3 個量化子主題（API Key Rotation RICE:4.2、Model Tiering RICE:1.0、Cross-vendor Fallback RICE:0.36）+ M5 觸及診斷完成（回饋數 0、安裝阻力 4 項已修正）
- M5 觸及診斷閉環（US-91）：4 個 doc-level 安裝阻力（README 版本 v0.19.0→v0.26.0、Sprint 計數、Skills 計數、GETTING_STARTED 版本）在單一 Story 內全數修正，「診斷即修復」高效閉環
- Phase 1 全平行執行零衝突，Architect 分群策略連續第十五個 Sprint 有效（Sprint 28–43）
- 外部抽樣審查 1/1 CONFIRM（US-91），DISPUTE 率 0%，自審品質持續無偏差
- §1.5 一致性審查機制連續第二個 Sprint 驗證有效（攔截 1 項 ROADMAP 版本號後 PASS），Sprint 38-40 Problem 引發的改進閉環持續穩定
- Backlog 精化品質提升：Issue #69 從模糊描述精化為 RICE 量化優先級子主題，決策有數據依據

### Problem

本 Sprint 無 Problem。

> 連續三個 Sprint（Sprint 41-43）Problem 區塊均為空或僅有格式性觀察。框架改進閉環（§1.5 一致性審查 + Done checkbox 更新）建立後持續驗證有效，問題修正無退化。

### Action Items

本 Sprint 無新增 Action Items。

---
