# Sprint 116 — Cruise 治理邊界完善 + SRE 診斷 SOP

**Sprint Goal**：完善 Cruise 治理邊界（close policy + 交付鏈配置 + feedback routing），補強 SRE 診斷 SOP

**期間**：2026-03-23 ~ 2026-03-30
**Velocity 目標**：10 pts（Sprint 115: 8 pts）

## Sprint Backlog

| # | Story | Size | Points | MoSCoW | 狀態 |
|---|-------|------|--------|--------|------|
| #338 | [Cruise] Issue 關閉需發 Issue 人同意 + 交付鏈深度 per-repo 可定義 | M | 5 | Must | 完成 |
| #339 | [Cruise] 回報對象應成為工作流的一部份 | S | 3 | Should | 完成 |
| #329 | SRE 巡檢：VM 消失原因不可推測，必須查證 | S | 2 | Should | 完成 |

## 技術決策（Architect）

- #338 需要 ADR（ADR-026 附錄或 ADR-029）：per-repo 設定 schema（close_policy + delivery_chain）
- 平行策略：#329 可與 #338 平行，#339 在 #338 合併後再開始
- awaiting-reply 語意區分：「缺資訊等補充」vs「修復後結案等確認」用觸發條件區分

## QA 阻塞疑問決策

| 疑問 | 決策 |
|------|------|
| #338 PO 自建 Issue 是否豁免 close policy | 豁免（發 Issue 人 = 當前 session → 直接 close） |
| #338 現有 auto-close vs 新 close policy 衝突 | 不衝突：auto-close 用於「缺資訊超時」，close policy 用於「修復後結案」 |
| #338 delivery_chain 值定義 | `pr`=PR merge 即 close；`none`=跳過交付追蹤 |
| #339 pattern 辨識條件 | 不做 AI 辨識，改為 label-based（`cruise-feedback` label 路由） |
| #339 確認機制 | 走 project_level 控制（low=直接建 Issue，medium=留言確認） |
| #329 gcloud 查詢失敗 fallback | 跳過 + 記錄 `[SRE] gcloud 不可用，跳過 MIG 查證` |

## Sprint 116 Review 結果

**Review 日期**：2026-03-23
**版本**：v0.79.0
**Sprint Goal 達成**：是

| # | Story | PR | 驗收 | 備注 |
|---|-------|----|------|------|
| #329 | SRE 巡檢：VM 消失原因不可推測，必須查證 | #356 | PASS | VM 數量變化查證 SOP + gcloud MIG 查證 + autoscaler/SPOT 分類 + fallback 落地 |
| #338 | [Cruise] Issue 關閉需發 Issue 人同意 + 交付鏈深度 per-repo 可定義 | #361 | PASS | close_policy + delivery_chain per-repo 配置、awaiting-reply 流程、ADR-029 落地 |
| #339 | [Cruise] 回報對象應成為工作流的一部份 | #363 | PASS | cruise-feedback label routing、feedback_routing 設定、project_level 控制 |

## Sprint 116 統計

- Velocity：10 pts（目標 10，達成率 100%）
- 完成率：100%（3/3 Stories PASS）
- Sprint 外 Shoots（本 session）：#333, #340, #343, #346, #348, #350, #352, #354, #357, #359
