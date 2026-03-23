# Product Brief: QA FREE-MAD 挑戰韌性機制

**Issue 來源：** #342 研究報告 Issue #6
**優先級：** 低
**日期：** 2026-03-23
**PB 狀態：** Draft

---

## 1. 問題陳述

Shikigami QA 角色在執行制衡功能時存在一個系統性弱點：當 QA 挑戰 Architect 決策後，若 Architect 給出任何回應（即使回應只是重新解釋相同觀點，或訴諸權威），QA 角色傾向於接受並撤回挑戰。這本質上是多 agent 系統中的「群體盲思」現象。

2026 年 FREE-MAD（Consensus-Free Multi-Agent Debate）研究明確指出此問題：在 multi-agent debate 中，agent 因「多數意見壓力」撤回原本正確的異議，導致制衡機制失效。Shikigami 的 QA 角色被設計為制衡者，但若挑戰立場不夠韌性，制衡效果大打折扣。

---

## 2. 目標使用者

**主要使用者：** 使用 Shikigami 進行架構決策審查的技術 Lead 或 AI 團隊 Operator
- 依賴 QA 角色作為 Architect 決策的獨立制衡者
- 希望 QA 的異議是基於實質技術理由，而非被社交壓力壓制

**次要使用者：** Stakeholder 角色
- 在 QA 與 Architect 爭議升級為仲裁時，需要清楚了解雙方論點與爭議本質
- 需要 QA 維持挑戰的記錄作為仲裁的參考依據

---

## 3. 商業假設

**假設外顯化（三問）：**

1. **我們假設 QA 的挑戰過早撤回是現有系統中可觀測的問題** — 在目前的 Sprint 執行記錄中，存在 QA 挑戰後迅速撤回、但事後回顧發現挑戰是合理的案例。[UNCERTAIN] 若目前的 QA 挑戰機制運作正常（撤回的挑戰均確實不成立），引入 FREE-MAD 約束可能是過度工程。需在導入前先分析歷史 Sprint 中 QA 挑戰與撤回的模式。

2. **我們假設「明確反證才撤回」的約束能提升制衡品質而不破壞協作流暢度** — 強化 QA 立場韌性後，Sprint 整體品質提升，且不會因 QA 過度固執而造成議題停滯。[UNCERTAIN] 若 QA 在「無明確反證」標準下拒絕撤回，但其原始挑戰本身即有瑕疵，可能造成 Stakeholder 仲裁次數暴增，拖慢 Sprint。

3. **我們假設 Stakeholder 有意願且有能力在仲裁流程中做出決定** — 當 QA 維持挑戰超過 2 輪觸發仲裁時，Stakeholder 角色能提供有效裁決，而不是再次回避或模糊結論。[UNCERTAIN] 若 Stakeholder 本身的判斷力依賴外部使用者輸入，仲裁流程可能成為新的等待瓶頸。

---

## 4. 提案解決方向

在 QA 角色的 Challenge Protocol 中加入「明確反證門檻」約束：

```
[升級後的 QA Challenge Protocol]
1. QA 提出挑戰時，明確記錄挑戰的核心依據：
   - 引用具體 test case 或 spec 條文
   - 記錄挑戰編號與時間戳（納入 trace log）
2. 收到 Architect 回應後，依以下標準評估：
   - 可接受並撤回：回應包含 QA 未考慮到的新測試數據、新 spec 條文、或已驗證的技術事實
   - 不可接受（維持挑戰）：回應只是重新解釋相同觀點、訴諸設計哲學、或訴諸 Architect 的經驗權威
3. 若撤回：輸出「撤回原因說明」，引用 Architect 的具體論點
4. 若維持：繼續挑戰並記錄輪數
5. 維持挑戰超過 2 輪：自動升級觸發 Stakeholder 仲裁，附上完整的挑戰記錄
```

相關調整：Sprint Report 中新增 QA challenge 的回合數統計，作為制衡機制健康度的量化指標。

---

## 5. 成功指標

- **撤回品質：** QA 每次撤回挑戰均附有撤回原因說明，引用 Architect 具體論點（輸出完整率 100%）
- **制衡有效性（[UNCERTAIN]，需 3 個 Sprint 後量測）：** QA 挑戰最終被證明有效（後續驗收或 Bug 驗證）的比率，預期維持或高於導入前水準
- **仲裁觸發率：** QA 挑戰升級至 Stakeholder 仲裁的比率合理（預期 < 10% 的挑戰需要仲裁，過高表示 QA 過於固執）
- **Sprint Report 覆蓋率：** 每份 Sprint Report 100% 包含 QA challenge 回合數統計

---

## 6. 排除範圍

- **不含跨角色辯論（非 QA/Architect 的 pair）：** FREE-MAD 機制此版本僅應用於 QA 挑戰 Architect 的場景，不擴展至其他角色組合
- **不含自動裁決 AI：** 仲裁由 Stakeholder 角色執行，不引入第三方 LLM 作為仲裁者
- **不含挑戰內容的語意分析：** 不自動評估挑戰本身是否成立，判斷仍由角色自主執行
- **不含跨 Sprint 的挑戰模式分析：** 本版本僅在 Sprint 內追蹤，歷史挑戰趨勢分析為後續需求

---

## 7. 依賴與風險

**依賴：**
- Issue #1（Structured Trace Log）：挑戰記錄需納入 trace log，Stakeholder 仲裁時才有完整依據
- Stakeholder 角色定義需更新，明確增加「仲裁流程」的觸發條件與行為
- QA 角色定義更新屬框架行為變更，需走團隊流程（shoot / sprint-execution），完成後需 bump 版號

**技術風險：**
- **「新技術證據」標準模糊風險：** QA 判斷 Architect 回應是否構成「明確反證」本身是語意判斷，可能因 prompt 設計不精確而失效，需要清晰的判斷標準範例（few-shot 示例）
- **固執化風險：** 若 QA 誤用此機制拒絕所有撤回，Sprint 效率顯著下降。需在 QA 角色 prompt 中強調「高門檻撤回」而非「永不撤回」

**商業風險：**
- 優先級為「低」，反映此功能對 Sprint 速度的直接貢獻低於 Issue #1 和 #2。建議在 observability 和 security 基礎建設到位後再導入，確保仲裁記錄有 trace log 支撐
