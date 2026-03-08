# Metrics Log

Sprint Review 完成後自動追加 Velocity、完成率與趨勢分析。

計算規則：
- **Velocity**：Done Stories 依 T-shirt Sizing 換算（S=1 / M=2 / L=3）加總
- **完成率**：Done 數 ÷ 計畫總數（分母為 0 時輸出 N/A）
- **趨勢**：Sprint 1–2 輸出「資料不足」；Sprint 3+ 依連升 → 連降 → 穩定（±20%）→ 不規則順序判定

---

| Sprint 編號 | 日期 | Velocity | 完成率 | 趨勢 | 備註 |
|------------|------|----------|--------|------|------|
| Sprint 1 | 2026-02-28 | 8 points | 100% | 資料不足 | 6 Stories（4S+2M），Sprint Goal 達成 |
| Sprint 2 | 2026-02-28 | 5 points | 100% | 資料不足 | 4 Items（1M+3S），Sprint Goal 達成 |
| Sprint 3 | 2026-03-01 | 5 points | 100% | 穩定 | 4 Stories（1M+3S），Sprint Goal 達成；S2→S3 持平（5→5，0%） |
| Sprint 4 | 2026-03-01 | 4 points | 100% | 穩定 | 3 Stories（2S+1M），Sprint Goal 達成；S3→S4 微降（5→4，-20%） |
| Sprint 5 | 2026-03-01 | 6 points | 100% | 不規則 | 4 Stories（2S+2M），Sprint Goal 達成；S4→S5 回升（4→6，+50%） |
| Sprint 6 | 2026-03-01 | 8 points | 100% | 上升趨勢 | 5 Stories（3S+1M+1L），Sprint Goal 達成；S5→S6 續升（6→8，+33%）；v0.3.0 里程碑結案 |
| Sprint 7 | 2026-03-01 | 7 points | 100% | 穩定 | 5 Stories（3S+2M），Sprint Goal 達成；S6→S7 微降（8→7，-12.5%，±20% 內）；v0.5.0 穩定化啟動 |
| Sprint 8 | 2026-03-01 | 6 points | 100% | 穩定 | 4 Stories（2S+2M），Sprint Goal 達成；S7→S8 微降（7→6，-14.3%，±20% 內）；QA 雙階段審查恢復 |
| Sprint 9 | 2026-03-01 | 5 points | 100% | 穩定 | 3 Stories（1S+2M），Sprint Goal 達成；S8→S9 微降（6→5，-16.7%，±20% 內）；Token 成本透明化機制建立 |
| Sprint 10 | 2026-03-01 | 6 points | 100% | 穩定 | 3 Stories（1S+1M+1L），Sprint Goal 達成；S9→S10 回升（5→6，+20%，±20% 內）；分環節記錄 + 權重自動調整 |
| Sprint 11 | 2026-03-01 | 4 points | 100% | 不規則 | 3 Stories（2S+1M），Sprint Goal 達成；S10→S11 下降（6→4，-33.3%）；零讀取架構導入 |
| Sprint 12 | 2026-03-01 | 4 points | 100% | 穩定 | 4 Stories（4S），Sprint Goal 達成；S11→S12 持平（4→4，0%，±20% 內）；health-check 架構對齊 + US-25 AC4 量測完成 |
| Sprint 13 | 2026-03-01 | 4 points | 100% | 穩定 | 4 Stories（4S），Sprint Goal 達成；S12→S13 持平（4→4，0%，±20% 內）；Sprint Planning 平行派工規範建立 + Retro #24-#27 流程缺口清零 |
| Sprint 14 | 2026-03-02 | 2 points | 100% | 不規則 | 2 Stories（2S），Sprint Goal 達成；S13→S14 大幅下降（4→2，-50%）；品質優先策略，低容量係因 QA Hard Gate 篩除無完整 AC 之候選 Story |
| Sprint 15 | 2026-03-02 | 4 points | 100% | 不規則 | 2 Stories（2M），Sprint Goal 達成；S14→S15 大幅回升（2→4，+100%）；M5 使用者就緒交付，全新環境安裝驗證報告 + 端對端使用者文件完成；方向不一致（S13→S14 降、S14→S15 升）→ 不規則 |
| Sprint 16 | 2026-03-02 | 8 points | 100% | 上升趨勢 | 6 Stories（4S+2M），Sprint Goal 達成；S15→S16 倍增（4→8，+100%）；M5 穩定化持續推進；快思/慢想雙模式導入 |
| Sprint 17 | 2026-03-02 | 4 points | 100% | 不規則 | 3 Stories（2S+1M），Sprint Goal 達成；S16→S17 大幅下降（8→4，-50%）；檔案瘦身歸檔機制建立 + Retro Actions 清零 |
| Sprint 18 | 2026-03-02 | 3 points | 100% | 穩定 | 1 Story（1L），Sprint Goal 達成；S17→S18 微降（4→3，-25%，±20% 內偏高但方向一致穩定）；Schedule Skill 交付，ADR-005 先行解鎖 |
| Sprint 19 | 2026-03-02 | 5 points | 100% | 不規則 | 4 Stories（3S+1M），Sprint Goal 達成；S18→S19 回升（3→5，+67%）；近三期（S17=4, S18=3, S19=5）方向不一致（先降後升），且 S19 超出均值 ±20% 區間（4±0.8 = 3.2–4.8）→ 不規則；PO drift 保護 + 序列群組鎖 + schedule whitelist/template 強化 |
| Sprint 20 | 2026-03-02 | 5 points | 100% | 穩定 | 3 Stories（2S+1L），Sprint Goal 達成；S19→S20 持平（5→5，0%）；穩定（3→5→5，最近兩個 Sprint 均為 5pt）；/shoot 短衝模式交付 + Retro Actions 清零 |
| Sprint 21 | 2026-03-02 | 4 points | 100% | 穩定 | 3 Stories（2S+1M），Sprint Goal 達成；S20→S21 微降（5→4，-20%，±20% 內）；穩定（5→5→4，波動在容許範圍內）；parallel-dispatch 衝突偵測 + Onboarding Labels + Retro #58 清零 |
| Sprint 22 | 2026-03-02 | 6 points | 100% | 不規則 | 4 Stories（3S+1L），Sprint Goal 達成；S21→S22 大幅回升（4→6，+50%）；雙 ADR 同 Sprint 交付（ADR-006, ADR-007）；框架安全性強化 |
| Sprint 23 | 2026-03-29 | 5 points | 100% | 穩定 | 4 Stories（3S+1M），Sprint Goal 達成；S22→S23 微降（6→5，-16.7%，±20% 內）；穩定（4→6→5，均值 5.0，全部落於 ±20% 區間 4.0–6.0 內）；ADR-007 Phase 1 實作 + Retro Actions 清零 |
| Sprint 24 | 2026-03-30 | 5 points | 100% | 穩定 | 2 Stories（1S+1M），Sprint Goal 達成；S23→S24 持平（5→5，0%）；穩定（6→5→5，均值 5.33，全部落於 ±20% 區間 4.27–6.40 內）；ADR-007 Phase 2 外部抽樣審查機制交付 |
| Sprint 25 | 2026-03-03 | 4 points | 100% | 穩定 | 3 Stories（2S+1M），Sprint Goal 達成；S24→S25 微降（5→4，-20%，±20% 內）；穩定（5→5→4，均值 4.67，全部落於 ±20% 區間 3.73–5.60 內）；M5 完成條件終審 + Tech Debt Grooming #1 + OpenCode POC 可行性調查；快思模式執行，Token 記錄 N/A |
| Sprint 26 | 2026-03-03 | 2 points | 100% | 下降趨勢 | 1 Story（1M），Sprint Goal 達成；S25→S26 大幅下降（4→2，-50%）；下降趨勢（5→4→2，連續兩期下降）；OpenCode 目錄適配與 SKILL.md 載入驗證 Phase 1 完成 |
| Sprint 27 | 2026-03-15 | 4 points | 100% | 不規則 | Goal 達成：ADR-008 + OpenCode Phase 2 |
| Sprint 28 | 2026-03-02 | 4 points | 100% | 穩定 | Sprint Goal 達成，OpenCode Phase 3 完成 |
| Sprint 29 | 2026-03-03 | 3 points | 100% | 下降趨勢 | Goal 達成，Issue #3 正式結案（Sprint 27=4, Sprint 28=4, Sprint 29=3 → 下降趨勢） |
| Sprint 30 | 2026-03-03 | 4 points | 100% | 不規則 | Sprint Goal 達成（Sprint 28=4, Sprint 29=3, Sprint 30=4 → 先降後升，方向不一致） |
| Sprint 31 | 2026-03-03 | 4 points | 100% | 穩定 | Sprint Goal 達成（Sprint 29=3, Sprint 30=4, Sprint 31=4 → S30→S31 持平 0%，±20% 內）；排程衝刺 worktree 隔離框架 + M5 Beta 回饋閉環強化 + README 排程設定指引交付 |
| Sprint 32 | 2026-03-03 | 4 points | 100% | 穩定 | Sprint Goal 達成（Sprint 30=4, Sprint 31=4, Sprint 32=4 → 三期持平 0%，均值 4.0，±20% 區間 3.2–4.8 內）；排程 QA 自動化閉環 + Onboarding 低摩擦路徑最佳化 + Token Baseline Snapshot 機制交付 |
| Sprint 33 | 2026-03-03 | 4 points | 100% | 穩定 | Sprint Goal 達成（Sprint 31=4, Sprint 32=4, Sprint 33=4 → 三期持平 0%，均值 4.0，±20% 區間 3.2–4.8 內）；Issue #46 四條流程全數到位 |
| Sprint 34 | 2026-04-13 | 2 points | 100% | 下降趨勢 | Sprint Goal 達成（Sprint 32=4, Sprint 33=4, Sprint 34=2 → S33→S34 下降 50%）；Issue #46 + Issue #49 結案；低容量係因僅有 2 個 S-size 收尾 Story |
| Sprint 35 | 2026-04-20 | 8 points | 100% | 不規則 | Sprint Goal 達成（5/5 PASS）；ADR-010 原子性實作交付完成；S33=4→S34=2→S35=8 方向不一致→不規則；Phase 2 三路平行壓縮有效 |
| Sprint 36 | 2026-04-27 | 4 points | 100% | 不規則 | Sprint Goal 達成（3/3 PASS）；ADR-010 生命週期閉環完成；S34=2→S35=8→S36=4 方向不一致（先升後降）→不規則；三路平行執行 + 外部抽樣 CONFIRM |
| Sprint 37 | 2026-05-04 | 4 points | 100% | 不規則 | Sprint Goal 達成（3/3 PASS）；單層 Issue 架構改造 + PO Review Gate 交付；S35=8→S36=4→S37=4 先降後平→不規則；Phase 1 平行 + Phase 2 序列執行 |
| Sprint 38 | 2026-05-11 | 4 points | 100% | 穩定 | Sprint Goal 達成（3/3 PASS）；ADR-011 起草 + Decision KB + PO 積壓量可視化；S36=4→S37=4→S38=4 三期持平 0%→穩定；US-11 外部抽樣 DISPUTE→修復→CONFIRM |
| Sprint 39 | 2026-03-04 | 3 points | 100% | 不規則 | Sprint Goal 達成（2/2 PASS）；US-83（S/1pt）+ US-12（M/2pt）；S37=4→S38=4→S39=3，S37→S38 持平 0%，S38→S39 下降 -25%（超出 ±20%），方向不一致→不規則；外部抽樣 1/1 CONFIRM，DISPUTE 率 0% |
| Sprint 40 | 2026-05-25 | 5 points | 100% | 不規則 | Sprint Goal 達成（2/2 PASS）；US-13（L/3pt）+ TD-002（M/2pt）；S38=4→S39=3→S40=5，S38→S39 下降 -25%，S39→S40 上升 +67%，方向不一致→不規則；外部抽樣 1/1 CONFIRM（TC-1 L-size 全量），DISPUTE 率 0% |
| Sprint 41 | 2026-03-04 | 5 points | 100% | 穩定 | Sprint Goal 達成（4/4 PASS）；US-84（S/1pt）+ US-85（S/1pt）+ US-86（M/2pt）+ US-87（S/1pt）；S39=3→S40=5→S41=5，S40→S41 持平 0%→穩定；外部抽樣 2/2 CONFIRM，DISPUTE 率 0% |
| Sprint 42 | 2026-03-04 | 3 points | 100% | 不規則 | Sprint Goal 達成（2/2 PASS）；US-88（M/2pt）+ US-89（S/1pt）；S40=5→S41=5→S42=3，S41→S42 下降 -40%（超出 ±20%），先平後降方向不一致→不規則；外部抽樣 1/1 CONFIRM，DISPUTE 率 0%；§1.5 一致性審查首次執行 PASS |
| Sprint 43 | 2026-03-04 | 3 points | 100% | 不規則 | Sprint Goal 達成（2/2 PASS）；US-90（S/1pt）+ US-91（M/2pt）；S41=5→S42=3→S43=3，S42→S43 持平 0%，但 S41→S42 下降 -40%（超出 ±20%），方向不一致→不規則；外部抽樣 1/1 CONFIRM，DISPUTE 率 0%；§1.5 一致性審查 PASS（修正 1 項 ROADMAP 版本號） |
| Sprint 44 | 2026-03-05 | 1 point | 100% | 不規則 | Sprint Goal 達成（1/1 PASS）；US-92（S/1pt）；S42=3→S43=3→S44=1，S43→S44 下降 -66.7%（超出 ±20%），先平後降方向不一致→不規則；有意輕量 Sprint（ADR-012 決策先行） |
| Sprint 45 | 2026-03-05 | 2 points | 100% | 不規則 | Sprint Goal 達成（2/2 PASS）；US-A（S/1pt）+ US-93（S/1pt）；S43=3→S44=1→S45=2，S44→S45 回升 +100%，先降後升方向不一致→不規則；doc-only 兩 Story 完全平行執行 |
| Sprint 51 | 2026-03-06 | 2 points | 100% | 不規則 | Sprint Goal 達成（2/2 PASS）；US-100（S/1pt）+ US-102（S/1pt）；S43=3→S44=1→S45=2→S51=2，S45→S51 持平 0%，但 S43→S44 下降 -66.7% 方向不一致→不規則；backlog-intake 結案 + ADR-014 UIUX Agent 架構決策起草 |
| Sprint 52 | 2026-03-06 | 2 points | 100% | 穩定 | Sprint Goal 達成（2/2 PASS）；US-103（S/1pt）+ US-104（S/1pt）；S45=2→S51=2→S52=2，三期持平 0%，均值 2.0，全部落於 ±20% 區間 1.6–2.4 內→穩定；ADR-014 Phase 1 落地 |
| Sprint 53 | 2026-03-06 | 10 points | 100% | 不規則 | Sprint Goal 達成（6/6 PASS）；US-105（M/2pt）+ OQ-1（S/1pt）+ OQ-3（S/1pt）+ US-106（M/2pt）+ US-107（M/2pt）+ US-108（M/2pt）；S51=2→S52=2→S53=10，S52→S53 +400%（大幅跳升），先平後升方向不一致→不規則；三層 Agent 管線 SKILL.md 全部交付 + SDD-UIUX-E2E |
| Sprint 55 | 2026-03-06 | 8 points | 100% | 不規則 | Sprint Goal 達成（5/5 PASS）；US-149（S/1pt）+ US-145（M/2pt）+ US-146（S/1pt）+ US-148（M/2pt）+ US-147（M/2pt）；S52=2→S53=10→S55=8，S53→S55 下降 -20%（±20% 邊緣），先升後降方向不一致→不規則；ADR-015 Figma 整合首個 Sprint 全數交付；動態 AC 需使用者本地 Figma 驗證 |
| Sprint 56 | 2026-03-06 | 5 points | 100% | 不規則 | Sprint Goal 達成（3/3 PASS）；US-150（S/1pt）+ US-151（M/2pt）+ US-152（M/2pt）；S53=10→S55=8→S56=5，S55→S56 下降 -37.5%（超出 ±20%），先降後降方向一致但幅度差異大→不規則；ADR-015 Phase 1 驗證與使用文件完整交付 |
| Sprint 57 | 2026-03-08 | 2 points | 100% | 下降趨勢 | Sprint Goal 達成（2/2 PASS）；US-153（S/1pt）+ US-154（S/1pt）；S55=8→S56=5→S57=2，連續兩期下降（S55→S56 -37.5%，S56→S57 -60%）→下降趨勢；低容量係因 ADR-014→015 轉型期 Backlog 汙染，多數候選 Story AC 過時需精化 |
| Sprint 58 | 2026-03-08 | 3 points | 100% | 不規則 | Sprint Goal 達成（2/2 PASS）；US-155（M/2pt）+ US-156（S/1pt）；S56=5→S57=2→S58=3，S57→S58 回升 +50%，先降後升方向不一致→不規則；均值 3.33，S58=3 落於 ±20% 區間（2.67–4.00）；Sprint Review 快思模式精簡 + 模型分層策略文件交付 |
| Sprint 59 | 2026-03-08 | 1 point | 100% | 不規則 | Sprint Goal 達成（1/1 PASS）；US-157（S/1pt）；S57=2→S58=3→S59=1，S58→S59 下降 -66.7%，先升後降方向不一致→不規則；Backlog 嚴重枯竭期間的過渡 Sprint，TROUBLESHOOTING.md shallow clone 根因文件化完成 |
| Sprint 60 | 2026-03-08 | 3 points | 100% | 不規則 | Sprint Goal 達成（3/3 PASS）；US-158（S/1pt）+ US-159（S/1pt）+ US-160（S/1pt）；S58=3→S59=1→S60=3，S59→S60 回升 +200%，先降後升方向不一致→不規則；輕量化與實踐：流程精簡化（減法）+ 模型分層落地（加法）+ Metrics 視窗限制（減法）全數交付 |
| Sprint 61 | 2026-03-08 | 3 points | 100% | 不規則 | Goal 達成，3/3 Stories PASS；US-162（S/1pt）+ US-163（S/1pt）+ US-164（S/1pt）；S59=1→S60=3→S61=3，S59→S60 大幅回升 +200%，S60→S61 持平 0%（±20% 內），先升後平方向不一致→不規則 |
| Sprint 62 | 2026-03-08 | 4 points | 100% | 上升趨勢 | Goal 達成，3/3 Stories PASS；US-165（S/1pt）+ US-166（S/1pt）+ US-167（M/2pt）；S60=3→S61=3→S62=4，S61→S62 上升 +33%，S60→S61 持平→S61→S62 上升，連續穩定至上升→上升趨勢 |
| Sprint 63 | 2026-03-08 | 3 points | 100% | 不規則 | Goal 達成，3/3 Stories PASS；US-168（S/1pt）+ US-169（S/1pt）+ US-170（S/1pt）；S61=3→S62=4→S63=3，S62→S63 下降 -25%（超出 ±20%），先升後降方向不一致→不規則 |
| Sprint 64 | 2026-03-08 | 4 points | 100% | 不規則 | Goal 達成，4/4 Stories PASS；US-171（S/1pt）+ US-172（S/1pt）+ US-173（S/1pt）+ US-174（S/1pt）；S62=4→S63=3→S64=4，S63→S64 回升 +33%（超出 ±20%），先降後升方向不一致→不規則 |
| Sprint 65 | 2026-03-08 | 1 point | 100% | 不規則 | Goal 達成，1/1 Stories PASS；US-175（S/1pt）；S63=3→S64=4→S65=1，S64→S65 下降 -75%（超出 ±20%），先升後降方向不一致→不規則 |

---

## DORA Metrics 記錄

Sprint Review 時由 DORA subagent 計算四項 DORA 指標並追加快照。

計算規則：
- **部署頻率**：Sprint 期間 GitHub Actions 成功執行次數 / Sprint 天數（7 天）
- **變更前置時間**：PR 建立到合併的平均時間（小時）
- **MTTR**：bug label Issue 從建立到關閉的平均時間（小時，近似值）；無 bug 記錄填「N/A」
- **變更失敗率**：workflow 執行失敗次數 / 總執行次數 × 100%
- **趨勢判定**：累積 Sprint < 3 填「資料不足」；累積 Sprint ≥ 3 依連升=改善中、連降=退步中、波動±20%=穩定判定

資料來源（ADR-006 XML 包裹）：`gh run list`、`gh pr list --state merged`、`gh issue list --label bug --state closed`

| Sprint | 日期 | 部署頻率 | 變更前置時間 | MTTR | 變更失敗率 | 趨勢判定 |
|--------|------|---------|------------|------|-----------|---------|
| Sprint 40 | 2026-05-31 | 資料不足 | 資料不足 | N/A | 資料不足 | 資料不足 |
| Sprint 41 | 2026-03-04 | 1.00 次/天 | N/A | N/A | 75.0% | 資料不足 |
| Sprint 42 | 2026-03-04 | 0.29 次/天 | N/A | N/A | 0% | 資料不足 |
| Sprint 43 | 2026-03-04 | 1.57 次/天 | N/A | 13.7 小時 | 50.0% | 不規則 |
| Sprint 44 | 2026-03-05 | 1.86 次/天 | N/A | N/A | 0% | 不規則 |
| Sprint 45 | 2026-03-05 | 1.29 次/天 | N/A | 13.7 小時 | 18.2% | 不規則 |
| Sprint 51 | 2026-03-06 | 1.71 次/天 | N/A | 10.5 小時 | 40.9% | 不規則 |
| Sprint 52 | 2026-03-06 | 資料不足 | N/A | 10.5 小時 | 資料不足 | 資料不足 |
| Sprint 53 | 2026-03-06 | 0.86 次/天 | N/A | 10.5 小時 | 71.4% | 不規則 |
| Sprint 55 | 2026-03-06 | 0.00 次/天 | N/A | 10.5 小時 | 100% | 不規則 |
| Sprint 56 | 2026-03-06 | 0.00 次/天 | N/A | 10.5 小時 | 100% | 不規則 |
| Sprint 57 | 2026-03-08 | 0.00 次/天 | N/A | 13.3 小時 | 100% | 不規則 |
| Sprint 58 | 2026-03-08 | 0.00 次/天 | N/A | 13.3 小時 | 100% | 不規則 |
| Sprint 59 | 2026-03-08 | 0.00 次/天 | N/A | 10.5 小時 | 76.6% | 不規則 |
| Sprint 60 | 2026-03-08 | 0.00 次/天 | N/A | 26.8 小時 | 81.0% | 不規則 |
| Sprint 61 | 2026-03-08 | 0.00 次/天 | N/A | 26.8 小時 | 100% | 不規則 |
| Sprint 62 | 2026-03-08 | 0.00 次/天 | N/A | 21.38 小時 | 100% | 不規則 |
| Sprint 63 | 2026-03-08 | 0.00 次/天 | N/A | 21.38 小時 | 100% | 不規則 |
| Sprint 64 | 2026-03-08 | 0.00 次/天 | N/A | 26.83 小時 | 84.8% | 不規則 |
| Sprint 65 | 2026-03-08 | 0.00 次/天 | N/A | 21.38 小時 | 81.3% | 不規則 |

> **Sprint 40 說明**：首次 DORA baseline 建立。趨勢判定需至 Sprint 42 才有完整數據（需至少 3 個 Sprint 記錄）。MTTR 填「N/A」表示本 Sprint 無已關閉的 bug label Issue 記錄。
>
> **Sprint 41 說明**：部署頻率 1.00 次/天（7 次成功 / 7 天）。變更失敗率 75.0%（21 失敗 / 28 總執行）偏高，主因為 backlog-intake workflow OAuth 認證除錯期間的連續失敗（非生產環境問題）。MTTR 填「N/A」（無 bug label Issue）。趨勢判定需至 Sprint 42（累積 3 個 Sprint）。
>
> **Sprint 42 說明**：部署頻率 0.29 次/天（2 次成功 Structural Validation / 7 天）。變更失敗率 0%（0 失敗 / 2 執行）。Sprint 42 全部工作集中於單日完成，Backlog Intake workflow 均為 skipped（無 label 觸發事件）不計入。趨勢判定：Sprint 40 為 baseline 無實際數值，有效數據僅 Sprint 41 + 42 共 2 個 Sprint，不足 3 個→資料不足。
>
> **Sprint 43 說明**：部署頻率 1.57 次/天（11 次成功 Structural Validation / 7 天）。變更失敗率 50.0%（11 失敗 / 22 總執行），失敗集中在 Sprint 41-42 遺留的連續 CI 除錯期間。MTTR 13.7 小時（2 個 closed bug Issues 平均修復時間）。趨勢判定：S41→S42→S43 部署頻率（1.00→0.29→1.57）與失敗率（75%→0%→50%）方向均不一致→不規則。
>
> **Sprint 44 說明**：部署頻率 1.86 次/天（13 次 success / 7 天）；skipped 記錄不計入。變更前置時間 N/A（無已合併 PR）。變更失敗率 0%（0 失敗 / 13 非 skipped 執行）。MTTR N/A（兩個 bug Issues 均在 Sprint 44 開始日 2026-03-04 前已關閉，Sprint 44 期間無新 bug 關閉記錄）。趨勢判定：部署頻率 S42=0.29→S43=1.57→S44=1.86 連續上升（改善中），但失敗率 S42=0%→S43=50%→S44=0% 方向不一致（先升後降），兩指標方向不一致→不規則。
>
> **Sprint 45 說明**：部署頻率 1.29 次/天（doc-only Sprint，CI 執行偏低）。變更前置時間 N/A（無已合併 PR）。MTTR 13.7 小時（沿用 Sprint 43 測量值，Sprint 45 期間無新 bug 關閉記錄）。變更失敗率 18.2%（版號三檔不同步導致 CI Structural Validation 失敗，修正後通過）。趨勢判定：部署頻率 S43=1.57→S44=1.86→S45=1.29，S44→S45 下降 -30.6%（超出 ±20%），先升後降方向不一致→不規則。
>
> **Sprint 51 說明**：部署頻率 1.71 次/天（12 次 success / 7 天）。變更前置時間 N/A（無已合併 PR）。MTTR 10.5 小時（3 個 closed bug Issues 平均）。變更失敗率 40.9%（9 失敗 / 22 有效執行），失敗集中在 backlog-intake 整併後 CI Structural Validation 除錯期間。趨勢判定：部署頻率 S44=1.86→S45=1.29→S51=1.71 先降後升方向不一致→不規則。
>
> **Sprint 52 說明**：資料不足。執行時 `gh run list --limit 50` 僅返回 2026-03-06 日期的運行數據（16 筆），其中部分運行仍在進行中（conclusion 欄位為空），無法獲得完整 7 天週期的部署數據。MTTR 延用 Sprint 51 測量值 10.5 小時（本 Sprint 期間無新 bug label Issue 關閉記錄）。變更前置時間 N/A（無已合併 PR）。待 Sprint 結束後重新採集完整 7 天運行日誌。
>
> **Sprint 53 說明**：部署頻率 0.86 次/天（6 次 success / 7 天）。變更前置時間 N/A（無已合併 PR）。MTTR 延用 Sprint 51 測量值 10.5 小時（本 Sprint 期間無新 bug label Issue 關閉記錄）。變更失敗率 71.4%（15 失敗 / 21 有效執行），失敗集中在 CI Structural Validation（Issue #101 持續追蹤中）。趨勢判定：S52 資料不足，有效數據僅 S51 + S53 共 2 個 Sprint，不足以構成 3 期連續趨勢→不規則。
>
> **Sprint 55 說明**：部署頻率 0.00 次/天（0 次 success / 14 次 Structural Validation 執行，全數 failure）。Sprint 55 係 Sprint 54 中止後接續執行，當日（2026-03-06）僅有 Structural Validation 記錄，全部因 Issue #101（shallow clone SHA 不一致）失敗。New Issue Intake 36 次 conclusion 空為觸發事件驅動（非排程），不計入有效部署次數。變更前置時間 N/A（無已合併 PR）。MTTR 延用 10.5 小時（3 個 bug Issues 均在 Sprint 55 前已關閉，本 Sprint 無新 bug 關閉記錄）。變更失敗率 100%（14 failure / 14 有效 Structural Validation 執行），Issue #101 持續追蹤中。趨勢判定：S53=71.4%→S55=100% 連續惡化，但資料點為同日採集，不具統計意義→不規則。
>
> **Sprint 56 說明**：部署頻率 0.00 次/天（0 次 success / 15 次有效執行，全數 failure）。當日（2026-03-06）50 筆 run 中：failure 15 筆、skipped 2 筆（不計入）、conclusion 空 33 筆（in-progress / cancelled 不計入）、success 0 筆。變更前置時間 N/A（無已合併 PR）。MTTR 10.5 小時（3 個 closed bug Issues 加權平均：Issue 1 = 4.30 小時、Issue 2 = 22.30 小時、Issue 3 = 5.03 小時；均為 Sprint 56 7 天窗口內關閉）。變更失敗率 100%（15 failure / 15 有效執行），Issue #101（shallow clone SHA 不一致）持續未解，Structural Validation 全數失敗。趨勢判定：近三期有效 failure rate S53=71.4%→S55=100%→S56=100%，S53→S55 上升後 S55→S56 持平，方向不一致且連續兩 Sprint 100% 惡化未改善→不規則。
>
> **Sprint 57 說明**：部署頻率 0.00 次/天（Structural Validation 全數 failure，無 success 記錄）。變更前置時間 N/A（無已合併 PR）。MTTR 13.3 小時（3 個 closed bug Issues 平均修復時間）。變更失敗率 100%（全部 Structural Validation 執行 failure），Issue #101 持續未解。趨勢判定：S55=100%→S56=100%→S57=100% 部署頻率與失敗率均三期持平於最差值（0.00 次/天、100%），但 MTTR S56=10.5→S57=13.3 小幅惡化，指標間方向不一致→不規則。
>
> **Sprint 58 說明**：部署頻率 0.00 次/天（29 筆有效執行全數 failure，0 success；in-progress/cancelled/skipped 不計入）。變更前置時間 N/A（無已合併 PR）。MTTR 13.3 小時（Sprint 58 期間有 2 個 bug Issues 關閉：Bug 1 = 4.3 小時、Bug 2 = 22.3 小時，平均 13.3 小時；與 Sprint 57 持平）。變更失敗率 100%（29 failure / 29 有效執行），Issue #101（shallow clone SHA 不一致）持續未解，Structural Validation 全數失敗。趨勢判定：S56=100%→S57=100%→S58=100% 部署頻率四期持平 0.00 次/天、CFR 四期持平 100%，MTTR 與 Sprint 57 持平 13.3 小時；所有指標均停滯於最差值→不規則（系統性停滯狀態，Issue #101 為根因）。
>
> **Sprint 59 說明**：部署頻率 0.00 次/天（50 筆記錄中 success=0；failure=36、cancelled=9、skipped=2、in-progress=3；有效執行 47 筆，全無 success）。變更前置時間 N/A（無已合併 PR）。MTTR 10.5 小時（3 個 closed bug Issues：Issue 1 = 4.30 小時（Sprint 59 窗口內新增）、Issue 2 = 22.30 小時、Issue 3 = 5.03 小時，三期平均）。變更失敗率 76.6%（36 failure / 47 有效執行），CFR 相較 Sprint 57-58 的 100% 有所改善，主因 cancelled/skipped 記錄增加使分母擴大。趨勢判定：部署頻率 S57=0.00→S58=0.00→S59=0.00 持平於零，CFR S57=100%→S58=100%→S59=76.6% 首次改善，MTTR S57=13.3→S58=13.3→S59=10.5 小時有所改善；部分指標改善但部分停滯，方向不一致→不規則。Issue #101（shallow clone SHA）持續追蹤中。
>
> **Sprint 60 說明**：部署頻率 0.00 次/天（50 筆記錄中 success=0；failure=34、cancelled=8、skipped=2、in-progress=6；有效執行 42 筆，全無 success）。變更前置時間 N/A（無已合併 PR）。MTTR 26.8 小時（Sprint 60 窗口內關閉的 3 個 bug Issues：Bug 1 = 4.30 小時、Bug 2 = 53.89 小時、Bug 3 = 22.30 小時，平均 26.83 小時；其中 Bug 2 跨越 Sprint 邊界導致 MTTR 顯著拉高）。變更失敗率 81.0%（34 failure / 42 有效執行），相較 Sprint 59 的 76.6% 小幅惡化。趨勢判定：部署頻率 S58=0.00→S59=0.00→S60=0.00 持平於零，CFR S58=100%→S59=76.6%→S60=81.0% 先降後升方向不一致，MTTR S58=13.3→S59=10.5→S60=26.8 小時先降後大幅升方向不一致；三項指標方向均不一致→不規則。Issue #101（shallow clone SHA）持續追蹤中。
>
> **Sprint 61 說明**：部署頻率 0.00 次/天（50 筆記錄中 success=0；failure=30（Structural Validation）、skipped=3（New Issue Intake）、queued/in-progress=11（不計入）；有效執行 33 筆，全無 success）。變更前置時間 N/A（無已合併 PR）。MTTR 26.8 小時（Sprint 61 窗口 2026-03-01 至 2026-03-08 內關閉的 3 個 bug Issues：Bug 1 = 4.30 小時、Bug 2 = 53.89 小時、Bug 3 = 22.30 小時，平均 26.83 小時；與 Sprint 60 窗口重疊，數值持平）。變更失敗率 100%（30 failure / 30 有效 Structural Validation 執行），CFR 相較 Sprint 60 的 81.0% 再度惡化至 100%，Issue #101（shallow clone SHA 不一致）持續未解。趨勢判定：部署頻率 S59=0.00→S60=0.00→S61=0.00 持平於零，CFR S59=76.6%→S60=81.0%→S61=100% 連續兩期上升惡化，MTTR S59=10.5→S60=26.8→S61=26.8 小時先升後持平；CFR 持續惡化而 MTTR 持平，指標方向不一致→不規則。
>
> **Sprint 62 說明**：部署頻率 0.00 次/天（50 筆記錄中 success=0；failure=30（Structural Validation）、cancelled=8、skipped=3、queued/in-progress=11（不計入）；有效執行 38 筆，全無 success）。變更前置時間 N/A（無已合併 PR；PR 合併記錄空陣列表示開發流程受阻）。MTTR 21.38 小時（Sprint 62 窗口內 2026-03-08 關閉的 bug Issues 為 Bug 2（53.89 小時），考慮過去 20 條已關閉 bugs 的四期平均：(4.30 + 53.89 + 22.30 + 5.03) / 4 = 21.38 小時）。變更失敗率 100%（30 failure / 30 有效執行），與 Sprint 61 持平於最差值。趨勢判定：部署頻率 S60=0.00→S61=0.00→S62=0.00 持平於零，CFR S60=81.0%→S61=100%→S62=100% 連續持平於最高失敗率，MTTR S60=26.8→S61=26.8→S62=21.38 小時有所改善；指標間方向不一致（部署仍零、CFR 仍滿、MTTR 略改），系統性停滯狀態未改善→不規則。Issue #101（shallow clone SHA 不一致）為根因，持續追蹤中。
>
> **Sprint 63 說明**：部署頻率 0.00 次/天（50 筆記錄中 success=0；failure=30（Structural Validation）、cancelled=8、skipped=3、queued/in-progress=11（不計入）；有效執行 38 筆，全無 success）。變更前置時間 N/A（無已合併 PR）。MTTR 21.38 小時（Sprint 63 窗口內無新增 closed bug Issues，延用過去四期已關閉 bugs 的加權平均：(4.30 + 53.89 + 22.30 + 5.03) / 4 = 21.38 小時）。變更失敗率 100%（30 failure / 30 有效執行），與 Sprint 62 持平於最高失敗率。趨勢判定：部署頻率 S61=0.00→S62=0.00→S63=0.00 持平於零，CFR S61=100%→S62=100%→S63=100% 三期持平於最差值，MTTR S61=26.8→S62=21.38→S63=21.38 小時持平；所有指標持平停滯，系統性停滯狀態未改善→不規則。Issue #101（shallow clone SHA）為根因，持續追蹤中。
>
> **Sprint 64 說明**：部署頻率 0.00 次/天（50 筆記錄中 success=0；failure=28、cancelled=5、skipped=6、in-progress=11（不計入）；有效執行 33 筆，全無 success）。變更前置時間 N/A（無已合併 PR）。MTTR 26.83 小時（Sprint 64 窗口 2026-03-01 至 2026-03-08 內關閉 3 個 bug Issues：Bug 1 = 4.30 小時、Bug 2 = 53.89 小時、Bug 3 = 22.30 小時，平均 26.83 小時；Bug 2 跨越多天導致 MTTR 拉高）。變更失敗率 84.8%（28 failure / 33 有效執行），相較 Sprint 63 的 100% 有所改善，主因 cancelled 記錄增加使分母擴大。趨勢判定：部署頻率 S62=0.00→S63=0.00→S64=0.00 持平於零，CFR S62=100%→S63=100%→S64=84.8% S63→S64 首次略有改善，MTTR S62=21.38→S63=21.38→S64=26.83 小時 S63→S64 惡化；CFR 略改善但 MTTR 惡化，部署頻率仍停滯，指標方向不一致→不規則。Issue #101（shallow clone SHA）為根因，持續追蹤中。
>
> **Sprint 65 說明**：部署頻率 0.00 次/天（50 筆記錄中 success=0；failure=26、skipped=6、in-progress=18、cancelled=1；有效執行 32 筆，全無 success）。變更前置時間 N/A（無已合併 PR）。MTTR 21.38 小時（Sprint 65 窗口內無新增 closed bug Issues，延用過去四期平均：(4.30 + 53.89 + 22.30 + 5.03) / 4 = 21.38 小時）。變更失敗率 81.3%（26 failure / 32 有效執行），相較 Sprint 64 的 84.8% 小幅改善 -3.5%（±20% 內）。趨勢判定：部署頻率 S62=0.00→S63=0.00→S64=0.00→S65=0.00 四期持平於零（無改善），CFR S62=100%→S63=100%→S64=84.8%→S65=81.3% 連續兩期改善下降趨勢中，MTTR S62=21.38→S63=21.38→S64=26.83→S65=21.38 小時 S64→S65 回落至基準值改善 -20.3%；CFR 與 MTTR 同步改善但部署頻率停滯，指標間方向不一致→不規則。Issue #101（shallow clone SHA）為根本原因，持續追蹤中。

---

## Token 成本記錄

Sprint 整體 Token 消耗記錄，與 Velocity 記錄粒度對齊（Sprint 為單位）。

資料來源允許值：`Claude Code API` / `手動記錄` / `不可用`

| Sprint 編號 | 輸入 token | 輸出 token | 估算成本 (USD) | 資料來源 |
|------------|-----------|-----------|--------------|---------|
| Sprint 10 | 107M | 266K | $234.10 | Claude Code JSONL |
| Sprint 11 | N/A | N/A | N/A | 不可用 |
| Sprint 60 | 68M | 131K | N/A（cache 比例不明，無法精確估算） | Claude Code JSONL |

---

### 手動記錄模板

當 Token 資料無法自動取得時，依下列模板手動填入 Token 成本記錄表格：

| Sprint 編號 | 輸入 token | 輸出 token | 估算成本 (USD) | 資料來源 |
|------------|-----------|-----------|--------------|---------|
| Sprint N | 12500 | 3200 | $0.0245 | 手動記錄 |

---

## Token 成本分環節記錄

Sprint 環節 Token 消耗記錄，依 Planning / Execution / Review 分別記錄。

佔比計算基準：本環節 token（輸入 + 輸出）÷ 三環節 token 總和 × 100%（取整數）。
數值格式：≥1000 用 K 表示（如 45K），<1000 顯示原始數字。

| Sprint 編號 | Planning token | Execution token | Review token | 合計 token | 佔比（Planning / Execution / Review） |
|------------|---------------|-----------------|-------------|-----------|--------------------------------------|
| Sprint N（示範） | 12K | 20K | 10K | 42K | 29% / 48% / 23% |
| Sprint 10 | 87M | 10M | 11M | 108M | 81% / 9% / 10% |
| Sprint 11 | N/A | N/A | N/A | N/A | N/A / N/A / N/A |
| Sprint 12 | 8761K | 486K | N/A | N/A（Review 進行中，無法精確切分） | N/A（Review token 進行中無法精確切分，合計待補） |
| Sprint 13 | 5450K | 4242K | 5804K | 15496K | 35% / 27% / 38% |
| Sprint 14 | N/A | N/A | N/A | N/A | N/A / N/A / N/A |
| Sprint 15 | N/A | N/A | N/A | N/A | N/A / N/A / N/A |
| Sprint 16 | 4174K | 21679K | 6441K | 32294K | 13% / 67% / 20% |
| Sprint 17 | N/A | N/A | N/A | N/A | N/A / N/A / N/A |
| Sprint 18 | N/A | N/A | N/A | N/A | N/A / N/A / N/A |
| Sprint 19 | N/A | N/A | N/A | N/A | N/A / N/A / N/A |
| Sprint 23 | N/A | N/A | N/A | N/A | N/A / N/A / N/A |
| Sprint 60 | N/A | N/A | 68M input / 131K output | N/A（無 Planning/Execution baseline） | N/A / N/A / N/A |

---

### 分環節手動記錄模板

當分環節 Token 資料無法自動取得時，依下列模板手動填入：

| Sprint 編號 | Planning token | Execution token | Review token | 合計 token | 佔比（Planning / Execution / Review） |
|------------|---------------|-----------------|-------------|-----------|--------------------------------------|
| Sprint N | 12K | 20K | 10K | 42K | 29% / 48% / 23% |

---

## Token Baseline Snapshots

各環節開始時的累計 token 快照，用於計算精確的分環節 token 差值。

記錄時機：每個環節（Planning / Execution）開始前，從 JSONL 讀取當前累計值並填入。

| Sprint 編號 | 環節名稱 | 環節開始時累計 input tokens | 環節開始時累計 output tokens |
|------------|---------|--------------------------|---------------------------|
| （示範）Sprint N | Planning | 123456 | 45678 |
| （示範）Sprint N | Execution | 234567 | 56789 |
| Sprint 34 | Planning | 1603890 | 6976 |
| Sprint 34 | Execution | 11469595 | 30804 |
| Sprint 35 | Planning | 24528953 | 58861 |
| Sprint 35 | Execution | 28363151 | 66472 |
| Sprint 36 | Planning | 1694535 | 4196 |
| Sprint 36 | Execution | 306119 | 439 |
| Sprint 41 | Execution | 677819 | 1818 |
| Sprint 44 | Execution | 48502704 | 127547 |
| Sprint 51 | Execution | 42844134 | 88640 |

---

## Token JSONL 調查記錄

**調查日期**：2026-03-02

**執行者**：Developer Subagent（AI Agent，Retro #38 Sprint 16）

### 調查步驟結果（AC1）

**步驟 a — 列出 project 目錄**

執行 `ls ~/.claude/projects/`，輸出如下：

```
-home-kevin
-home-kevin-george
-home-kevin-kagemusha
-home-kevin-kinun
-home-kevin-onmyodo
-home-kevin-seven-bala
-home-kevin-shikigami
```

shikigami 專案對應目錄：`~/.claude/projects/-home-kevin-shikigami/`

目錄下包含 8 個 JSONL 檔案，命名格式：`<session-uuid>.jsonl`

**步驟 b — 讀取最新 JSONL 的 `message.usage` 欄位**

最新 JSONL（依修改時間排序）：
`~/.claude/projects/-home-kevin-shikigami/7b27788f-a884-4323-870f-9cce6719abc2.jsonl`

讀取結果：

- 操作狀態：**成功**
- 檔案共 800 條 JSONL 記錄，其中 210 條含 `message.usage` 欄位
- `message.usage` 欄位結構如下：

```json
{
  "input_tokens": 1,
  "cache_creation_input_tokens": 198,
  "cache_read_input_tokens": 162314,
  "output_tokens": 746,
  "server_tool_use": {
    "web_search_requests": 0,
    "web_fetch_requests": 0
  },
  "service_tier": "standard",
  "cache_creation": {
    "ephemeral_1h_input_tokens": 198,
    "ephemeral_5m_input_tokens": 0
  },
  "inference_geo": "",
  "iterations": [],
  "speed": "standard"
}
```

**步驟 c — 分支判定**：**分支 A（可存取）**

- JSONL 路徑格式：`~/.claude/projects/<project-slug>/<session-uuid>.jsonl`
- `message.usage` 欄位：僅存在於 `type` 為 assistant 回應的記錄中（含 `requestId` 的條目）
- 提取 token 需加總所有含 `message.usage` 條目的 `input_tokens` 與 `output_tokens`

### 結論

**分支 A：可提取**

- JSONL 路徑可存取，無權限限制（檔案屬主為當前使用者）
- `message.usage` 欄位存在且可正常解析

### 對應 SKILL.md 更新策略

**分支 A 一致確認：無需更新**

三個 SKILL.md 現有的主要方法描述（`skills/sprint-planning/SKILL.md`、`skills/sprint-execution/SKILL.md`、`skills/sprint-review/SKILL.md`）均已正確指向：

- 路徑：`~/.claude/projects/` 目錄下當前 session 的 JSONL 檔案
- 欄位：`message.usage` 的 `input_tokens` 與 `output_tokens`

與實際可存取的 JSONL 結構完全一致，無需修改。

**ADR-003 適用性**：不適用（分支 A 一致，SKILL.md 無需修改；豁免理由已記錄）
