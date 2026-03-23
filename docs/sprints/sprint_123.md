# Sprint 123 — Cruise 穩定性修復 + 雙模式交付 + CI 主動偵測

**Sprint Goal**：消除 Cruise Mode 隨機阻斷 + 交付 Cruise 雙模式（Loop + Once） + 強化 CI 主動偵測能力
**期間**：2026-03-23 ~ 2026-03-30
**Velocity 目標**：9 pts（Sprint 122: 5 pts，恢復正常節奏）

## Sprint Backlog

| # | Story | Size | Points | MoSCoW | 狀態 | 執行順序 |
|---|-------|------|--------|--------|------|----------|
| #446 | [Bug] PreToolUse prompt hooks 隨機擋住所有 Bash 指令 | S | 1 | Must | 完成（PR #455） | 1 |
| #449 | cruise: Flag file in /tmp cleared by systemd-tmpfiles-clean | S | 1 | Must | 完成（PR #454） | 1 |
| #430 | feat: Cruise 雙模式 — Loop Mode + Once Mode（Phase 1：Loop + Once only） | M | 3 | Must | 進行中 | 2 |
| #450 | feat: CI 健康檢查腳本 — 主動偵測 CI 故障點 | M | 2 | Should | 待辦 | 2 |
| #451 | docs: 並行安全規則矩陣 — 明文化多 Agent 同時操作邊界 | M | 2 | Should | 待辦 | 2 |

## PO 決策紀錄

### 為何選入 #451（非 Architect+QA 正式評估）

- #451 是 Sprint 122 Retrospective Action Item #2，具明確 AC 與清楚範圍
- SM 在 Planning Round 2 明確提出作為 Option C 候選
- 性質為文件型（並行安全矩陣），低技術風險，與其他 Stories 無檔案衝突
- 與 #450（CI 健康檢查）同為 Retro Action，一併交付可完整 close Sprint 122 改善循環
- 9 pts 接近目標 10 pts，比 7 pts 更健康

### 為何排除 #383

- Architect 評估 NOT_READY：ADR-031 缺失 + 無 Acceptance Criteria + Product Backlog 草稿階段
- 強行選入違反 READY 標準，破壞計畫紀律

### 執行順序（QA 建議整合）

1. **Phase 1（優先修 Bug，可平行）**：#446 + #449 — 修復後 Cruise 才能穩定運行
2. **Phase 2（功能交付，可平行）**：#430 + #450 + #451 — Bug 修復後再交付功能

## 技術決策

- #446 將 3 個 prompt hooks 改為 command hooks（shell script grep），消除 model 判斷不穩定性
- #449 將 flag file 從 /tmp 移至專案目錄（或每 cycle touch），避免 systemd-tmpfiles-clean 清理
- #430 Phase 1 限縮：僅實作 Loop Mode + Once Mode，不含 /schedule 排程指令
- #450 整合 validate-ci-versions.sh，新增 GitHub App 狀態偵測 + apt 套件檢查
- #451 盤點所有 Agent 共用資源，建立操作衝突矩陣，整合進 ADR 或 docs/sdd/

## 獨立性評估

| Story | 修改檔案 | 獨立性 |
|-------|---------|--------|
| #446 | hooks/hooks.json + hooks 腳本 | 獨立 |
| #449 | skills/cruise/SKILL.md（flag 路徑） | 獨立 |
| #430 | skills/cruise/SKILL.md（雙模式邏輯） | 與 #449 有檔案重疊，建議 #449 先完成 |
| #450 | scripts/ci-health-check.sh（新建） | 獨立 |
| #451 | docs/（新建矩陣文件） | 獨立 |

## 平行分群

### Phase 1（Bug fix，可平行）
| Story | 標題 | Size | 說明 |
|-------|------|------|------|
| #446 | prompt hooks 修復 | S | hooks.json 修改 |
| #449 | /tmp flag 修復 | S | cruise flag 路徑修正 |

### Phase 2（功能，可平行）
| Story | 標題 | Size | 說明 |
|-------|------|------|------|
| #430 | Cruise 雙模式 | M | Phase 1 限縮版（Loop + Once） |
| #450 | CI 健康檢查 | M | 新建腳本 |
| #451 | 並行安全矩陣 | M | 新建文件 |

**注意**：#430 與 #449 共用 cruise SKILL.md，#449 應先完成再開始 #430。

## 風險

| 風險 | 影響 | 緩解 |
|------|------|------|
| #446 hooks 改為 command 後行為差異 | 中 | 測試覆蓋三個 gate 場景 |
| #430 Phase 1 scope creep（加入 /schedule） | 中 | AC 明確限縮 Loop + Once only |
| #449 + #430 cruise SKILL.md 衝突 | 低 | 序列執行，#449 先合併 |
