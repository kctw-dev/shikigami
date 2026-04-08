# Sprint 177

**Sprint Goal：根治 LLM 規則衰減問題 — 交付 ADR-045 外部狀態機架構評估、sprint-execution PoC 驗證，同步完善 Backlog 自動化與 Discovery 序列依賴優化**

**開始日期**：2026-04-09
**結束日期**：2026-04-16
**容量**：6 pts
**Velocity 基準**：avg 6 pts（Sprint 174=6, Sprint 175=6, Sprint 176=6）

---

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 | 負責 | Routing Tier |
|-------|-------|------|--------|------|------|-------------|
| feat: 解決 LLM 規則衰減 — 外部狀態機 + 短命 Agent 架構 | #962 | L | 3 | TODO | — | opus（Score 10, FEATURE 架構變更） |
| retro: sprint-candidate label 應於 Sprint Planning 選入時自動移除 | #954 | S | 1 | TODO | — | haiku（Score 4, CHORE label 自動化） |
| retro: 評估 Discovery/RESEARCH Story 序列依賴優化機會 | #935 | M | 2 | TODO | — | haiku（Score 5, RESEARCH） |

**總計**：3 Stories / 6 pts

---

## 驗收標準摘要

### #962 feat: LLM 規則衰減解決方案
- AC1: 交付 ADR-045 評估外部狀態機 + 短命 Agent 技術可行性
- AC2: sprint-execution 前 3 步完成 PoC，由外部腳本驅動（AC1→AC2 序列依賴）
- AC3: PoC 有 test script 驗證 gate 條件
- AC4: ADR-045 評估與 scrum-master-state-graph.md 的一致性
- NFR1: 向後相容（scripts/state-machine/ 新目錄隔離）
- NFR2: 可觀測 log（含 step_name、exit_code、失敗原因）
- NFR3: 腳本執行 < 1s
- NFR4: 冪等重入

### #954 retro: sprint-candidate label 移除
- AC1: PO Round 2 選入 Story 後自動移除 sprint-candidate label
- AC2: 移除邏輯位於 gh issue edit 操作內
- AC3: 冪等性：無 label 不報錯

### #935 retro: Discovery 序列依賴優化
- AC1: Spike Report 產出至 docs/km/spike-935-discovery-dependency.md
- AC2: 至少 2 個優化方案（含 trade-off）
- AC3: 後續 Backlog Items 以 Issue draft 格式產出
- 時間盒：2 小時

---

## 技術評估摘要

| Story | T-shirt | ADR | Schema Contract | Related SDDs | 平行分群 |
|-------|---------|-----|----------------|-------------|---------|
| #962 | L | ADR-045（本 Sprint 交付）| 需要：state schema JSON | SDD-000, 新增 SDD-005 | Wave 1 |
| #954 | S | 不需要 | 無 | 無 | Wave 1 |
| #935 | M | 不需要 | 無 | 參考 SDD-000 §1.2 | Wave 2 |

## 平行分群

> **SHIKIGAMI_MAX_PARALLEL=2**

**Wave 1（2 worktrees 平行）**：#962 (opus) + #954 (haiku)
**Wave 2（Wave 1 完成後）**：#935 (haiku)
