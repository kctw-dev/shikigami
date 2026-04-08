# Sprint 178

**Sprint Goal：鞏固 Sprint 177 Retro 行動項目 — worktree 生命週期改善、AC 前置品質強化、框架驗證工具鏈補強**

**開始日期**：2026-04-09
**結束日期**：2026-04-16
**容量**：6 pts
**Velocity 基準**：avg 6 pts（Sprint 175=6, Sprint 176=6, Sprint 177=6）

---

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 | 負責 | Routing Tier |
|-------|-------|------|--------|------|------|-------------|
| retro: PR merge 後自動清理 worktree | #969 | S | 1 | DONE | PR#971 | haiku（Score 4, RETRO） |
| retro: worktree 平行執行時確保 branch 從乾淨 base 建立 | #968 | S | 1 | DONE | PR#972 | haiku（Score 4, RETRO） |
| retro: sprint-candidate issue 應在 Grooming 階段補齊 AC | #967 | S | 1 | DONE | PR#975 | haiku（Score 3, RETRO） |
| chore: backlog-health-alert MIN_CANDIDATES 同步 | #947 | S | 1 | DONE | PR#970 | haiku（Score 3, CHORE） |
| feat: validate-xrefs.sh 擴充 skill-to-skill 路徑驗證 | #949 | S | 1 | DONE | PR#973 | haiku（Score 4, FEAT） |
| chore: sprint-checkpoint.json 過期偵測 | #950 | S | 1 | DONE | PR#974 | haiku（Score 4, CHORE） |

**總計**：6 Stories / 6 pts

---

## 驗收標準摘要

### #969 retro: PR merge 後自動清理 worktree
- AC-1：Sprint Execution Skill 的 PR merge 後步驟，加入 `git worktree remove <path>` 指令
- AC-2：worktree cleanup 在 branch delete 之前執行，確保刪除不失敗
- AC-3：若 worktree remove 失敗（目錄不存在），graceful skip 不中斷流程

### #968 retro: worktree 平行執行時確保 branch 從乾淨 base 建立
- AC-1：worktree 建立時 branch 從 main HEAD 切出，不從其他 worktree branch 切出
- AC-2：建立前執行 `git fetch origin main` 確保 base 最新
- AC-3：平行 worktree 測試場景驗證無 commit 交叉污染

### #967 retro: sprint-candidate issue 應在 Grooming 階段補齊 AC
- AC-1：Backlog Grooming 流程加入 AC 檢查步驟
- AC-2：缺少 AC 的 sprint-candidate 自動標記待補齊
- AC-3：Sprint Planning 拒絕選入無 AC 的 Story

### #947 chore: backlog-health-alert MIN_CANDIDATES 同步
- AC-1：backlog-health-alert.yml MIN_CANDIDATES 預設值與 ADR-043 閾值 10 同步
- AC-2：文件引用一致性驗證通過

### #949 feat: validate-xrefs.sh 擴充 skill-to-skill 路徑驗證
- AC-1：validate-xrefs.sh 新增 skill-to-skill 交叉引用路徑檢查
- AC-2：偵測到 broken skill 引用時 exit code 非零
- AC-3：現有測試不退化

### #950 chore: sprint-checkpoint.json 過期偵測
- AC-1：偵測 sprint-checkpoint.json 中殘留的舊 Sprint 資料
- AC-2：過期閾值可配置
- AC-3：自動清除或告警（依配置）

---

## 技術評估摘要

| Story | T-shirt | ADR | Schema Contract | Related SDDs | 平行分群 |
|-------|---------|-----|----------------|-------------|---------|
| #969 | S | 不需要 | 無 | 無 | Wave 1 |
| #947 | S | 不需要 | 無 | 參考 ADR-043 | Wave 1 |
| #968 | S | 不需要 | 無 | 無 | Wave 2 |
| #949 | S | 不需要 | 無 | 無 | Wave 2 |
| #967 | S | 不需要 | 無 | 無 | Wave 3 |
| #950 | S | 不需要 | 無 | 無 | Wave 3 |

## 平行分群

> **SHIKIGAMI_MAX_PARALLEL=2**

**Wave 1（2 worktrees 平行）**：#969 (haiku) + #947 (haiku)
**Wave 2（Wave 1 完成後）**：#968 (haiku) + #949 (haiku)
**Wave 3（Wave 2 完成後）**：#967 (haiku) + #950 (haiku)
