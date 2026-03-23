# Sprint 116 — Cruise 治理邊界完善 + SRE 診斷 SOP

**Sprint Goal**：完善 Cruise 治理邊界（close policy + 交付鏈配置 + feedback routing），補強 SRE 診斷 SOP

**期間**：2026-03-23 ~ 2026-03-30
**Velocity 目標**：10 pts（Sprint 115: 8 pts）

## Sprint Backlog

| # | Story | Size | Points | MoSCoW | 狀態 |
|---|-------|------|--------|--------|------|
| #338 | [Cruise] Issue 關閉需發 Issue 人同意 + 交付鏈深度 per-repo 可定義 | M | 5 | Must | 待開始 |
| #339 | [Cruise] 回報對象應成為工作流的一部份 | S | 3 | Should | 待開始 |
| #329 | SRE 巡檢：VM 消失原因不可推測，必須查證 | S | 2 | Should | 待開始 |

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
