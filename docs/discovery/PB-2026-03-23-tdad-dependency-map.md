# Product Brief: TDAD Dependency Map — 精準 TDD 執行

**Issue 來源：** #342 研究報告 Issue #3
**優先級：** 🟡 中
**日期：** 2026-03-23
**PB 狀態：** Draft

---

## 1. 問題陳述

Shikigami Developer 角色目前執行 Red→Green→Refactor TDD 循環時，每次程式碼變更後可能觸發全量測試執行。這造成兩個問題：一是耗費不必要的 token 與等待時間；二是反饋訊號不精準，開發者難以判斷「是哪個測試因此次變更而 fail」。

2026 年 3 月 arxiv 發表的 TDAD（Test-Driven Agentic Development）論文揭示關鍵洞察：讓 agent 知道「哪些測試要驗」比告訴它「怎麼做 TDD」更有效。單純的 TDD prompting 反而增加 9.94% 的 regression，但加入 source↔test 依賴圖後顯著改善。

---

## 2. 目標使用者

**主要使用者：** 使用 Shikigami Developer 角色執行 Sprint 任務的開發者
- 任務涉及修改已有測試覆蓋的程式碼模組
- 希望 TDD 循環快速反饋，不希望等待全量測試

**次要使用者：** QA 角色
- 需要在 Developer 完成 Refactor 後，確認最終全量測試通過
- 依賴 Developer 輸出的受影響測試清單，快速理解變更範圍

---

## 3. 商業假設

**假設外顯化（三問）：**

1. **我們假設 Developer subagent 執行全量測試的成本是使用者感知到的痛點** — 使用者確實因為測試時間過長而感到困擾，並認為這影響了 Sprint 效率。[UNCERTAIN] 若目前使用者的 codebase 測試數量較少（< 100 個測試），全量執行的時間差異可能微不足道，需確認實際使用者的 codebase 規模。

2. **我們假設靜態依賴分析能準確識別受影響的測試** — 對於常見的 Python 和 TypeScript 專案，import 圖分析能涵蓋 > 90% 的實際依賴關係，沒有大量動態 import 或 metaprogramming 混淆的情況。[UNCERTAIN] 若目標 codebase 大量使用動態載入，靜態分析的準確性可能不足。

3. **我們假設 Developer 角色在 Pre-TDD Dependency Analysis 步驟有能力分析依賴圖** — Developer 角色可以透過 tool call 執行依賴分析腳本，而不需要人工引導。[UNCERTAIN] 依賴分析工具的整合方式需要 Architect 評估技術可行性。

---

## 4. 提案解決方向

在 Developer subagent 的 TDD 執行流程中插入「Pre-TDD Dependency Analysis」步驟：

```
1. 接收任務（例：修改 file_A.py）
2. [新增] 建立 dependency map：掃描哪些 test_*.py 直接或間接 import file_A
3. Red phase：只執行受影響的測試，確認 fail
4. Green phase：實作最小修改讓測試通過
5. Refactor phase：重構，再次執行受影響測試確認
6. 最終 QA Gate：全量測試（觸發一次，由 QA 角色執行）
7. 輸出 summary（包含哪些測試被執行、是否全部通過）
```

技術要求：
- 依賴分析支援 Python（基於 AST import 分析）與 TypeScript（基於 `tsc` module resolution）
- dependency map 輸出為結構化清單，納入 trace log
- 全量測試僅在 Refactor 完成後的最終 QA Gate 觸發，不在 Red/Green phase 執行

---

## 5. 成功指標

- **精準度：** Developer 在每次 code change 前輸出受影響測試清單，清單準確率（實際 fail 的測試均在清單內）> 90%
- **效率提升：** TDD 循環中 Red/Green phase 的測試執行時間相較全量執行縮短 > 40%（在測試數 > 50 的 codebase 上量測）
- **Regression 率：** 導入 TDAD 後的 regression 率不高於導入前（確保「精準但不漏」）
- **Summary 輸出率：** Developer 每次 TDD 循環 100% 產出含受影響測試清單的 summary

---

## 6. 排除範圍

- **不含 Java / C++ / Go 等語言**：初始版本僅支援 Python 與 TypeScript，其他語言為後續擴充
- **不含動態依賴分析**：僅做靜態 import 圖分析，不追蹤 runtime 的動態 import 或 monkey-patching
- **不含測試優先序排列**：受影響測試以集合形式輸出，不做執行順序最佳化
- **不含跨 repo 依賴追蹤**：依賴分析範圍限於當前 repo，不處理 monorepo 跨 package 依賴

---

## 7. 依賴與風險

**依賴：**
- Architect 角色需評估依賴分析工具（例：`pydeps`、`madge`）整合的技術可行性
- Issue #1（Structured Trace Log）：dependency map 與測試執行結果應納入 trace log
- QA 角色需更新協作流程，明確 Developer 負責精準測試、QA Gate 負責全量測試的邊界

**風險：**
- **語言覆蓋不足風險：** 若使用者的 codebase 以 Go 或 Java 為主，本功能無法提供幫助，使用者感知價值為零
- **依賴分析錯誤風險：** 靜態分析產生漏報（missing dependency），導致 Developer 認為測試通過但實際有 regression。[UNCERTAIN] 需在 PoC 階段以真實 codebase 驗證準確性
- **流程複雜度增加：** Developer 角色的執行步驟增加，若框架無法自動化依賴分析，可能反而拖慢 Sprint

