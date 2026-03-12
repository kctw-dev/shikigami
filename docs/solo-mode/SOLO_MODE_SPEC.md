---
title: "單人服務模式規範 — Solo Mode Specification"
version: "1.0.0"
story: "US-239"
sprint: 87
status: "Active"
---

# 單人服務模式規範（Solo Mode Specification）

<!-- US-239: 單人服務模式 — 角色獨立派遣至外部專案 — Sprint 87 -->

## 概述

**單人服務模式（Solo Mode）** 是指從 Shikigami 角色池中，抽取單一角色連同最小必要 context，獨立派遣至外部專案執行特定職責的運作模式。

本規範定義：
1. 角色封裝規則（哪些 skill 必須攜帶、可選攜帶、禁止攜帶）
2. context 最小集（獨立運作所需的最小檔案集合）
3. 品質標準攜帶規則（品質機制在無 Sprint 流程下的最小保障）
4. 資安邊界規則（任務資料的帶出、執行、交回流程）

---

## §1 運作模式對比

### 團隊模式（Team Mode）vs 單人服務模式（Solo Mode）

| 面向 | 團隊模式 | 單人服務模式 |
|------|---------|------------|
| **角色數量** | 8 個角色協作（PO / SM / Architect / Developer / QA / SRE / Security Engineer / UI/UX Designer） | 1 個角色獨立執行 |
| **流程框架** | Sprint 週期（Planning → Execution → Review → Retro） | 任務導向（接收任務 → 執行 → 交付） |
| **Skill 載入** | 全量 skill 可按需觸發 | 僅攜帶角色職責範圍內的 skill（見 §2） |
| **Context** | 完整 Shikigami context（PROJECT_BOARD / Sprint 檔案 / ADR / docs/） | 最小 context 集（見 §3） |
| **品質機制** | Sprint Review / 外部抽樣審查 / SPACE 指標 | self-review 必攜帶，quality-gate 條件攜帶（見 §4） |
| **資料範圍** | 專案內部共享，存留於 Git repo | 任務範圍資料，不留存於外部（見 §5） |
| **升級路徑** | 升級至 SM / Architect / PO | 升級至召喚方（外部專案的聯絡人） |

---

## §2 角色封裝規範 — Skill 攜帶規則

### §2.1 Skill 分類原則

每個角色在 Solo Mode 下，其 skill 分為三類：

| 分類 | 定義 | 行為 |
|------|------|------|
| **必帶（Mandatory）** | 角色核心職責不可缺少的 skill；缺少則角色無法完成基本任務 | 派遣時自動注入至角色 context |
| **選帶（Optional）** | 依外部專案需求決定是否攜帶；預設不攜帶 | 由召喚方在派遣指令中明確指定 |
| **禁帶（Forbidden）** | 強依賴 Shikigami 團隊流程，在外部環境無意義或有安全風險 | 任何情況下不得注入 |

### §2.2 QA Engineer Solo Mode Skill 清單

| Skill 檔案路徑 | 分類 | 原因 |
|----------------|------|------|
| `skills/qa-engineer/SKILL.md` | 必帶 | QA 角色定義，含 AC 驗證策略、Spec Compliance、Code Quality Review |
| `skills/quality-gate/SKILL.md` | 必帶 | 品質門禁標準（測試覆蓋率 / 缺陷分級 / 審查清單） |
| `skills/security-review/SKILL.md` | 選帶 | 涉及外部輸入或 API 端點時攜帶；純文件審查任務可省略 |
| `skills/systematic-debugging/SKILL.md` | 選帶 | 需執行 bug 調查時攜帶；純審查任務可省略 |
| `skills/escalation/SKILL.md` | 必帶 | 定義升級觸發條件；Solo Mode 下升級對象改為召喚方 |
| `skills/sprint-execution/SKILL.md` | 禁帶 | 強依賴 Sprint 週期與 PROJECT_BOARD，外部環境無法執行 |
| `skills/sprint-planning/SKILL.md` | 禁帶 | 依賴 Sprint Backlog 與 PO 決策流程 |
| `skills/sprint-review/SKILL.md` | 禁帶 | 依賴 Sprint 狀態與 SM 主持 |
| `skills/scrum-master/SKILL.md` | 禁帶 | 團隊協調 skill，Solo Mode 無適用場景 |
| `skills/schedule/SKILL.md` | 禁帶 | 依賴 Sprint 排程邏輯 |
| `skills/parallel-dispatch/SKILL.md` | 禁帶 | 依賴主 session 派遣多個 subagent，Solo Mode 為單一角色執行 |
| `skills/architecture-decision/SKILL.md` | 禁帶 | 架構決策屬 Architect 職責，QA 不具備此決策權 |
| `skills/backlog-management/SKILL.md` | 禁帶 | 依賴 Shikigami backlog 流程 |
| `skills/discovery-phase/SKILL.md` | 禁帶 | 依賴 PO / Architect / Stakeholder 協作流程 |
| `skills/issue-management/SKILL.md` | 禁帶 | 依賴 Shikigami GitHub Issue 管理流程 |
| `skills/onboarding/SKILL.md` | 禁帶 | 僅適用於新角色加入 Shikigami 團隊 |
| `skills/health-check/SKILL.md` | 禁帶 | 依賴 Shikigami 自身系統狀態，不適用外部環境 |
| `skills/deployment-readiness/SKILL.md` | 選帶 | 需審查部署準備度時可攜帶；一般 code review 任務可省略 |

### §2.3 Skill 依賴解析邏輯

當選帶 skill 被啟用時，須自動檢查其依賴關係：

```
解析流程：
1. 取得選帶 skill 的 name 欄位（YAML frontmatter）
2. 讀取該 skill §關係 / §與其他 Skill 的關係 節點
3. 若依賴的 skill 為「禁帶」分類 → 忽略該依賴，記錄「Solo Mode 依賴豁免」
4. 若依賴的 skill 為「必帶」分類 → 已存在，無需重複注入
5. 若依賴的 skill 為另一個「選帶」分類 → 由召喚方決定是否一併攜帶
6. 迴圈直到所有依賴解析完成
```

**範例**：啟用 `security-review` 時，其 §8 指出「安全審查發現架構層級安全問題 → 觸發 architecture-decision」。由於 `architecture-decision` 在 QA Solo Mode 下為禁帶，此依賴觸發「Solo Mode 依賴豁免」，改為升級至召喚方。

### §2.4 角色 Profile 最小結構定義

每個 Solo Mode 角色 profile 必須包含以下結構：

```yaml
# solo-profile.yaml（隨角色攜帶）
role: qa-engineer          # 對應 agents/*.md 的 name 欄位
mode: solo                 # 固定值，標識 Solo Mode
skills:
  mandatory:               # 必帶 skill 路徑清單（相對於 Shikigami root）
    - skills/qa-engineer/SKILL.md
    - skills/quality-gate/SKILL.md
    - skills/escalation/SKILL.md
  optional: []             # 本次派遣啟用的選帶 skill（召喚方指定）
context:
  files: []                # 本次攜帶的 context 檔案（見 §3）
escalation_target: null    # 覆寫升級對象（null = 使用召喚方指定的聯絡人）
security_boundary:
  data_retention: false    # 任務資料不留存於外部系統
  sensitive_handling: mask # 敏感資訊處理方式（mask / exclude / hash）
```

---

## §3 Context 最小集

### §3.1 獨立派遣最小檔案集合

Solo Mode 角色攜帶的最小 context 為以下檔案（按必帶優先序排列）：

| 優先序 | 檔案路徑 | 用途 | 分類 |
|--------|----------|------|------|
| P1 | `agents/{role}.md` | 角色定義（決策權 / 方法論 / 跨角色協作） | 必帶 |
| P1 | `skills/{core-skill}/SKILL.md` | 核心 skill 定義（見 §2 必帶清單） | 必帶 |
| P2 | `skills/escalation/SKILL.md` | 升級機制定義 | 必帶 |
| P3 | `skills/{optional-skill}/SKILL.md` | 選帶 skill（召喚方指定） | 選帶 |
| P4 | 外部專案相關文件（任務 context） | 由召喚方提供，如 spec、AC 清單、代碼 | 選帶 |

### §3.2 不需攜帶的團隊流程檔案

以下檔案強依賴 Shikigami 內部流程，Solo Mode 下禁止攜帶：

| 禁帶檔案 | 禁帶原因 |
|---------|---------|
| `docs/PROJECT_BOARD.md` | 依賴 Shikigami Sprint 狀態，外部環境無意義 |
| `docs/sprints/sprint_*.md` | Sprint 週期檔案，外部專案無對應概念 |
| `docs/adr/ADR-*.md`（全量） | ADR 為 Shikigami 架構決策，不適用外部專案；若外部專案有自己的 ADR 則由召喚方提供 |
| `docs/km/*.md`（知識管理） | Shikigami 回顧記錄，外部環境不需要 |
| `skills/sprint-execution/story-lifecycle-prompt.md` | 依賴 Story-Lifecycle 封裝架構，外部環境無此框架 |
| `skills/health-check/SKILL.md` | 依賴 Shikigami 系統狀態 |
| `.claude/projects/*/memory/MEMORY.md` | 跨對話記憶，僅適用 Shikigami 主環境 |

### §3.3 Context 注入方式

Solo Mode 角色的 context 注入採用以下方式：

```
注入流程：
1. 召喚方提供任務描述（task brief）
   格式：
     - 任務類型（code-review / ac-validation / security-audit / test-coverage-check）
     - 目標範圍（檔案路徑清單 / PR 連結 / 規格文件）
     - 驗收標準（可選，若無則使用角色預設標準）

2. Solo Mode 角色根據 §2 載入必帶 skill
3. 召喚方指定的選帶 skill 加入（若有）
4. 任務 context 注入（外部專案文件 / 代碼）

注意事項：
- 任務 context 與 Shikigami 內部 context 嚴格隔離
- 外部代碼注入前，必須確認不含敏感資訊（見 §5.2）
- context 注入上限：建議單次任務 context 不超過 50K tokens（避免 context overflow）
```

---

## §4 品質標準攜帶規則

### §4.1 不確定性前置檢查（必攜帶）

來源：US-214（不確定性前置檢查機制）

Solo Mode 角色在任務執行前，必須執行以下前置檢查：

```
任務啟動前置檢查（強制執行）：
1. 識別任務中的不確定項：
   - AC 或驗收標準是否模糊？
   - 目標代碼/文件的範圍是否清楚？
   - 外部專案的技術棧是否已知？

2. 不確定性分級：
   - 高不確定（無法執行任務）→ 在執行任何審查前，先向召喚方提問，列出所有問題，等待回覆
   - 中不確定（可執行但有假設）→ 明確列出假設，繼續執行，結尾標記假設清單
   - 低不確定（清晰明確）→ 直接執行

3. 禁止行為：帶著高不確定性直接執行，產出基於錯誤假設的審查報告
```

### §4.2 Self-Review（必攜帶）

來源：ADR-007（Story-Lifecycle Subagent 封裝）

Solo Mode 角色在每次任務交付前，必須執行自審：

```
Self-Review 流程（強制執行）：
1. Spec Compliance Review：
   - 確認每個 AC（或任務要求）均有對應的產出
   - 確認產出內容與 AC 描述一致，無偏離

2. Code Quality Review（代碼審查任務適用）：
   - 執行 §3 代碼審查清單（skills/quality-gate/SKILL.md §6）
   - 標記所有發現的問題，含嚴重度分級

3. 輸出 Self-Review 結論：
   格式：PASS / FAIL / ESCALATE（見 §4.4）
```

### §4.3 Quality Gate 攜帶條件

| 任務類型 | Quality Gate 攜帶決策 | 說明 |
|---------|---------------------|------|
| Code Review（代碼審查） | 必攜帶 | `skills/quality-gate/SKILL.md` 定義審查清單與品質門檻 |
| AC Validation（AC 驗證） | 必攜帶 | Quality Gate 的 §7 缺陷分類適用於 AC 失敗判定 |
| Security Audit（安全審查） | 必攜帶 | `skills/security-review/SKILL.md` 定義安全門禁 |
| Documentation Review（文件審查） | 選攜帶 | 無程式碼，可簡化使用 Quality Gate §6 中適用於文件的項目 |
| Research / 探索性任務 | 禁攜帶 | 無可測量的品質門檻，Quality Gate 不適用 |

### §4.4 Solo Mode 結論輸出格式

每次任務完成後，Solo Mode 角色輸出以下標準結論：

```
## Solo Mode 任務結論

**角色**：QA Engineer（Solo Mode）
**任務類型**：{code-review / ac-validation / security-audit / documentation-review}
**任務 ID**：{召喚方提供的 ID，若無則為 N/A}

**Self-Review 結論**：PASS / FAIL / ESCALATE

**摘要**：
- 執行範圍：{審查的檔案/AC/範圍}
- 發現問題數量：Critical {N} / Important {N} / Suggestion {N}
- 假設清單（若有）：{執行過程中的假設}

**詳細結果**：
{依任務類型輸出對應的詳細清單}

**ESCALATE 原因**（若適用）：
{需升級至召喚方的具體原因與建議}
```

---

## §5 資安邊界規則

### §5.1 任務資料不留存原則

Solo Mode 的核心資安承諾：**任務資料在任務生命週期結束後不留存於外部系統。**

```
任務資料生命週期：

帶出階段（Before）：
  - 角色 profile + 必帶 skill context → 由 Shikigami 環境打包
  - 外部專案文件 → 由召喚方注入（非 Shikigami 資料）
  - 禁止帶出：Shikigami 內部 ADR / Sprint 資料 / secrets

執行階段（During）：
  - 所有處理在 agent session 的 context window 內進行
  - 不寫入任何外部持久化儲存（除非召喚方明確授權）
  - 外部專案代碼僅在記憶體中分析，不快取至 Shikigami 系統

交回階段（After）：
  - 產出（審查報告 / 建議清單）交付給召喚方
  - agent session 結束後，context window 自動釋放
  - 無任何外部專案資料留存於 Shikigami 系統
```

### §5.2 敏感資訊處理規則

| 敏感資訊類型 | 處理方式 | 依據 |
|------------|---------|------|
| API Key / Token / 密碼 | 在注入 context 前由召喚方遮罩（mask），agent 不得要求提供明文 | `skills/security-review/SKILL.md` §4 Secrets Management |
| 個人身份資訊（PII） | 若任務不需要 PII 則排除；若需要則要求召喚方提供匿名化版本 | `skills/security-review/SKILL.md` §2 A3 |
| 外部專案架構圖 / 設計文件 | 僅在 context window 中處理，不摘要至 Shikigami 知識庫 | Solo Mode 隔離原則 |
| 外部專案的 Git history | 不存取完整 history；若需要則限制在任務相關 commit | 最小必要原則 |

### §5.3 敏感資訊進入 Agent Context 的前置檢查

執行任務前，角色必須確認以下項目（對照 `skills/security-review/SKILL.md` §4.3 密鑰蔓延防護）：

```
敏感資訊前置確認清單：
[ ] 任務文件中無明文 API Key / Token / 密碼
[ ] 任務代碼中無硬編碼 secrets（若有，標記為 Critical 問題，不繼續執行審查）
[ ] 任務描述中無個人身份資訊（若有且非必要，要求召喚方移除後重新提交）
[ ] 確認任務範圍不包含 Shikigami 系統的內部 secrets

若任一項目為「否」：立即向召喚方提出，等待確認後再繼續。
```

### §5.4 與 Security Review SKILL.md 的關聯

本節（§5）是 `skills/security-review/SKILL.md` 的 Solo Mode 適配版本：

| Security Review SKILL.md 節點 | Solo Mode 對應規則 |
|-------------------------------|-------------------|
| §2 OWASP Top 10 | 適用於 Solo Mode 安全審查任務（需攜帶 `security-review` 選帶 skill） |
| §4 Secrets Management | 對應本節 §5.2 / §5.3 |
| §6 升級觸發 | Critical 漏洞升級對象改為召喚方（非 Shikigami Stakeholder + SRE） |
| §7 安全品質門禁 | 適用，但「CIS Benchmarks 合規驗證」由召喚方負責提供測試環境 |

---

## §6 Solo Mode 與 Shikigami 團隊模式的互操作性

### §6.1 角色回歸路徑

當外部任務完成後，角色可回歸 Shikigami 團隊模式。回歸流程：

```
回歸流程：
1. Solo Mode 任務結論已交付召喚方
2. agent session 結束（context 釋放）
3. 角色在 Shikigami 環境重新啟動，載入完整 context
4. 無需任何狀態同步（Solo Mode 任務資料不留存）
```

### §6.2 Solo Mode 不影響 Shikigami 系統完整性

Solo Mode 為唯讀操作原則：
- 不修改 `docs/PROJECT_BOARD.md`
- 不修改 `docs/sprints/*.md`
- 不修改 `skills/**/*.md`（除非召喚方明確授權且任務為 Shikigami 內部維護）
- 所有外部任務產出均交付給召喚方，不回寫 Shikigami repo

---

## 參照文件

| 文件 | 路徑 | 關聯章節 |
|------|------|---------|
| QA Engineer 角色定義 | `agents/qa-engineer.md` | §2 角色封裝 |
| QA Engineer Skill | `skills/qa-engineer/SKILL.md` | §2.2 Skill 清單 |
| Quality Gate Skill | `skills/quality-gate/SKILL.md` | §4.3 Quality Gate 攜帶條件 |
| Security Review Skill | `skills/security-review/SKILL.md` | §5.4 資安關聯 |
| Escalation Skill | `skills/escalation/SKILL.md` | §2.2 必帶 / §4.4 ESCALATE |
| ADR-007 | `docs/adr/ADR-007-story-lifecycle-subagent.md` | §4.2 Self-Review 來源 |
| QA POC | `docs/solo-mode/roles/qa-solo-poc.md` | AC5 / AC6 驗證 |
