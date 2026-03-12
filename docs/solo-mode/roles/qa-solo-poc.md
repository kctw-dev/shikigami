---
title: "QA Engineer Solo Mode POC — 獨立派遣概念驗證"
role: qa-engineer
mode: solo
version: "1.0.0"
story: "US-239"
sprint: 87
status: "POC"
---

# QA Engineer Solo Mode POC

<!-- US-239: 單人服務模式 — 角色獨立派遣至外部專案 — Sprint 87 -->
<!-- 本文件依據 docs/solo-mode/SOLO_MODE_SPEC.md 驗證 QA 角色的獨立派遣可行性 -->

## 概述

本 POC（Proof of Concept）展示 QA Engineer 在 **無 Sprint 流程** 的外部專案環境中，如何以 Solo Mode 執行核心 QA 職責。

驗證目標：
- AC5：QA 攜帶的具體 skill 清單與 context 最小集
- AC6：QA 在無 Sprint 流程下仍能執行 AC 驗證、code review、測試覆蓋檢查

---

## §1 派遣參數（Dispatch Profile）

### §1.1 角色 Profile

```yaml
# qa-solo-profile.yaml — QA Engineer Solo Mode 派遣設定
role: qa-engineer
mode: solo
version: "1.0.0"

skills:
  mandatory:
    - skills/qa-engineer/SKILL.md          # QA 角色決策指引（AC 驗證策略 / Spec Compliance / Code Quality）
    - skills/quality-gate/SKILL.md         # 品質門禁（測試覆蓋率門檻 / 缺陷分類 / 代碼審查清單）
    - skills/escalation/SKILL.md           # 升級機制（Solo Mode 覆寫：升級對象為召喚方）
  optional: []  # 本 POC 場景：純代碼審查 + AC 驗證，不需要安全審查或除錯 skill

context:
  agent_definition: agents/qa-engineer.md  # QA 角色決策權、方法論、品質指標定義
  task_brief: |                             # 由召喚方提供（本 POC 為模擬）
    任務類型: code-review + ac-validation
    目標範圍: 外部專案 /src/auth/ 目錄
    驗收標準: 外部專案 AC 清單（由召喚方提供）

escalation_target: "外部專案的 Tech Lead（聯絡人：由召喚方指定）"

security_boundary:
  data_retention: false
  sensitive_handling: mask
```

### §1.2 攜帶的 Skill 具體清單

| # | Skill 路徑 | 分類 | 本 POC 中的用途 |
|---|-----------|------|----------------|
| 1 | `skills/qa-engineer/SKILL.md` | 必帶 | AC 類型識別（`[靜態]` / `[動態]` / `[行為]`）、Spec Compliance Review 決策、Code Quality Review 策略 |
| 2 | `skills/quality-gate/SKILL.md` | 必帶 | 測試覆蓋率門檻（>80%）、Critical/Important/Suggestion 缺陷分類、代碼審查清單（§6） |
| 3 | `skills/escalation/SKILL.md` | 必帶 | 發現 Critical 缺陷或高不確定性時的升級觸發，升級對象改為召喚方 |

**不攜帶的 skill（與 SOLO_MODE_SPEC.md §2.2 一致，完整禁帶清單）：**

| 禁帶 Skill | 禁帶原因 |
|-----------|---------|
| `skills/sprint-execution/SKILL.md` | 強依賴 Sprint 週期與 PROJECT_BOARD，外部環境無法執行 |
| `skills/sprint-planning/SKILL.md` | 依賴 Sprint Backlog 與 PO 決策流程 |
| `skills/sprint-review/SKILL.md` | 依賴 Sprint 狀態與 SM 主持 |
| `skills/scrum-master/SKILL.md` | 團隊協調 skill，Solo Mode 無適用場景 |
| `skills/schedule/SKILL.md` | 依賴 Sprint 排程邏輯 |
| `skills/parallel-dispatch/SKILL.md` | 依賴主 session 派遣多個 subagent，Solo Mode 為單一角色執行 |
| `skills/architecture-decision/SKILL.md` | 架構決策屬 Architect 職責，QA 不具備此決策權 |
| `skills/backlog-management/SKILL.md` | 依賴 Shikigami backlog 流程 |
| `skills/discovery-phase/SKILL.md` | 依賴 PO / Architect / Stakeholder 協作流程 |
| `skills/issue-management/SKILL.md` | 依賴 Shikigami GitHub Issue 管理流程 |
| `skills/onboarding/SKILL.md` | 僅適用於新角色加入 Shikigami 團隊 |
| `skills/health-check/SKILL.md` | 依賴 Shikigami 自身系統狀態，不適用外部環境 |

---

## §2 Context 最小集 — 具體檔案列表

### §2.1 攜帶的檔案列表

| 優先序 | 檔案路徑 | 用途 |
|--------|----------|------|
| P1 | `agents/qa-engineer.md` | QA 角色定義：決策權（代碼審查為 Accountable）、方法論、ISTQB 測試技法、品質指標 |
| P1 | `skills/qa-engineer/SKILL.md` | QA 核心決策：AC 驗證策略（§1.2）、靜態/動態 AC 識別規則（§1.2）、Spec Compliance Review 判定（§2）、Code Quality Review（§3） |
| P1 | `skills/quality-gate/SKILL.md` | 品質門禁：測試覆蓋率 >80%（§2）、測試金字塔（§3）、代碼審查清單 7 項（§6）、缺陷分類（§7） |
| P2 | `skills/escalation/SKILL.md` | 升級觸發條件與格式（Solo Mode 覆寫升級對象） |
| P3 | （本 POC 場景未啟用選帶 skill） | 本 POC 為純 code-review + ac-validation，不需攜帶選帶 skill；若任務涉及安全審查可攜帶 `skills/security-review/SKILL.md` |
| P4 | 外部專案 AC 清單（召喚方提供） | 任務 context：驗收標準，用於 Spec Compliance Review |
| P4 | 外部專案代碼（召喚方提供） | 任務 context：目標代碼，用於 Code Quality Review |
| P4 | 外部專案測試檔案（召喚方提供） | 任務 context：測試覆蓋驗證所需 |

**總計攜帶：3 個 Shikigami skill 檔案 + 1 個 agent 定義檔案 + 召喚方提供的任務 context。**

### §2.2 不攜帶的 Shikigami 檔案

| 不攜帶檔案 | 不攜帶原因 |
|-----------|----------|
| `docs/PROJECT_BOARD.md` | Shikigami Sprint 狀態，外部專案無意義 |
| `docs/sprints/sprint_87.md`（或任何 Sprint 檔案） | Sprint 週期文件，外部環境不適用 |
| `docs/adr/ADR-*.md` | Shikigami 架構決策，不適用外部專案 |
| `docs/km/*.md` | Shikigami 知識管理記錄 |
| `skills/sprint-execution/story-lifecycle-prompt.md` | Story-Lifecycle 封裝架構，外部無此框架 |
| `.claude/projects/*/memory/MEMORY.md` | 跨對話記憶，僅適用 Shikigami 主環境 |

---

## §3 模擬外部專案使用場景

### §3.1 場景描述

**外部專案**：一個獨立的 Node.js 後端服務（非 Shikigami），其開發團隊沒有 Scrum 流程，需要借調 QA 能力進行一次性的代碼審查與 AC 驗證。

**召喚方需求**：
1. 審查 `/src/auth/` 目錄下的認證邏輯（code review）
2. 驗證三個 AC 是否已被實作（AC validation）
3. 確認測試覆蓋率是否達到 >80% 門檻（test coverage check）

**任務約束**：
- 召喚方沒有 Sprint Backlog，沒有 PROJECT_BOARD
- 召喚方使用自己的 Jira 追蹤問題（非 GitHub Issues）
- 任務一次性執行，預計 2 小時內完成

### §3.2 不確定性前置檢查執行（對應 SOLO_MODE_SPEC.md §4.1）

```
任務啟動前置檢查：

識別不確定項：
- AC 清單：召喚方已提供（中不確定 → 有假設：AC 為英文，與 Shikigami AC 格式不同，假設以功能描述為判定依據）
- 代碼範圍：/src/auth/ 目錄（低不確定 → 清晰明確）
- 測試框架：召喚方使用 Jest（低不確定 → 工具已知）
- 覆蓋率工具：Istanbul/nyc（低不確定 → 工具已知）

不確定性分級：中不確定（可執行但有假設）

假設清單：
1. 外部 AC 以功能行為描述，以「可觀察的行為符合描述」作為通過判定依據
2. 若 AC 描述模糊（AMBIGUOUS），標記後繼續執行，結尾提出澄清問題

決策：繼續執行任務，結尾附加假設清單。
```

### §3.3 任務執行流程

#### 步驟 1：Code Review（依 quality-gate/SKILL.md §6）

QA 使用 `skills/quality-gate/SKILL.md` §6 的代碼審查清單執行 7 項審查：

| 審查項目 | 審查方法（無 Sprint 流程） |
|---------|--------------------------|
| Logic correctness | 直接閱讀代碼，確認業務邏輯與 AC 描述一致 |
| Error handling | 確認 try/catch、錯誤碼、錯誤訊息的完整性 |
| Naming conventions | 確認命名自文件化，無單字母變數（除 loop 變數） |
| Code organization | 確認檔案結構與職責分離（SOLID S 原則） |
| Cyclomatic complexity | 確認單一函式圈複雜度 < 10（人工計算或靜態工具） |
| Duplication detection | 確認無重複邏輯，應抽取的模組已抽取 |
| SOLID compliance | 確認遵循 SOLID 原則 |

**無 Sprint 流程的適應**：移除對 `PROJECT_BOARD.md` 和 Sprint 狀態的依賴；所有判定依據來自代碼本身與召喚方提供的 AC，不依賴 Shikigami 流程文件。

#### 步驟 2：AC Validation（依 qa-engineer/SKILL.md §1.2）

QA 使用 `skills/qa-engineer/SKILL.md` §1.2 執行 AC 類型識別與驗證：

**模擬 AC 清單（召喚方提供）：**

| AC | 描述 | QA 識別類型 | 驗證方式 |
|----|------|------------|---------|
| AC-1 | `POST /auth/login` 端點在憑證正確時返回 JWT token | `[動態]` | 確認對應 Jest 測試存在（不執行，僅核對測試檔案） |
| AC-2 | JWT token 的 payload 包含 `userId` 和 `role` 欄位 | `[靜態]` | 靜態讀取代碼，確認 token 生成邏輯 |
| AC-3 | 連續失敗 5 次後，帳戶鎖定 30 分鐘 | `[行為]` | 確認有 Given-When-Then 場景的測試案例覆蓋 |

**無 Sprint 流程的適應**：
- 不依賴 Shikigami 的 Spec Compliance / Code Quality self-review 框架
- 直接以 `qa-engineer/SKILL.md` §2 的 PASS/FAIL 判定規則執行
- 升級路徑改為「通知召喚方的 Tech Lead」

#### 步驟 3：測試覆蓋檢查（依 quality-gate/SKILL.md §2）

```
測試覆蓋率驗證（使用 quality-gate/SKILL.md §2 門檻）：

門檻：行覆蓋率 > 80%，分支覆蓋率 > 80%

驗證方式（Solo Mode 適配）：
1. 讀取 coverage/ 目錄下的覆蓋率報告（若召喚方已提供）
2. 或讀取 package.json 確認 Jest 覆蓋率設定（thresholds）
3. 若無覆蓋率報告：標記為 Code Quality FAIL，要求召喚方執行 `npx jest --coverage` 後提供報告

CQ-NEW-1 驗證（對應 qa-engineer/SKILL.md §1.1）：
- API 端點（POST /auth/login）：確認 Happy Path + 錯誤路徑測試存在 → 驗證
- 業務邏輯（帳戶鎖定）：確認邊界條件測試（第 5 次失敗、第 4 次失敗、鎖定期間嘗試）→ 驗證

CQ-NEW-2 驗證：
- 確認現有測試無語意矛盾（舊測試仍符合當前實作行為）
```

---

## §4 品質標準攜帶驗證

### §4.1 QA 在無 Sprint 流程下的核心職責執行

| 核心職責 | 依賴的 Skill | 無 Sprint 流程的執行方式 | 驗證結論 |
|---------|------------|------------------------|---------|
| AC 驗證（AC Validation） | `skills/qa-engineer/SKILL.md` §1.2 | 使用 AC 類型識別規則（`[靜態]`/`[動態]`/`[行為]`），以召喚方提供的 AC 為驗收標準，不依賴 Sprint 流程 | 可執行 |
| Code Review | `skills/quality-gate/SKILL.md` §6 | 執行 7 項審查清單，判定標準不變，升級路徑改為召喚方 | 可執行 |
| 測試覆蓋率檢查 | `skills/quality-gate/SKILL.md` §2 + `skills/qa-engineer/SKILL.md` §1.1 | 門檻不變（>80%），驗證方式適配外部專案（讀取 coverage report 或 jest 設定） | 可執行 |
| 缺陷分類與報告 | `skills/quality-gate/SKILL.md` §7 | Critical/Important/Suggestion 三級分類不變，輸出格式同 Solo Mode 結論（SOLO_MODE_SPEC.md §4.4） | 可執行 |
| 升級（Escalation） | `skills/escalation/SKILL.md` | 升級觸發條件不變，升級對象改為召喚方的 Tech Lead | 可執行 |
| Security Audit（安全審查） | `skills/security-review/SKILL.md`（選帶） | 本 POC 場景範圍外（純 code-review + ac-validation，未啟用選帶 skill）；適用時依 SPEC §4.3 規則：攜帶 `security-review/SKILL.md`，Quality Gate 必攜帶，升級路徑改為召喚方 | 本 POC 未驗證，適用時依 SPEC §4.3 |
| Documentation Review / Research（探索性任務） | `skills/quality-gate/SKILL.md`（部分適用） | 本 POC 場景範圍外；適用時依 SPEC §4.3 規則：Documentation Review 選攜帶 Quality Gate（僅適用文件審查項目），Research / 探索性任務禁攜帶 Quality Gate（無可量測品質門檻） | 本 POC 未驗證，適用時依 SPEC §4.3 |

**結論：QA Engineer 在無 Sprint 流程下，仍能執行所有核心 QA 職責。流程框架（Sprint）的缺失不影響 QA 核心能力的執行，僅需調整升級路徑與 context 來源。Security Audit 與 Documentation Review / Research 任務類型本 POC 場景未覆蓋，但依 SPEC §4.3 規則執行時同樣適用。**

### §4.2 Self-Review（對應 SOLO_MODE_SPEC.md §4.2）

```
## Solo Mode 任務結論（本 POC 模擬輸出）

**角色**：QA Engineer（Solo Mode）
**任務類型**：code-review + ac-validation + test-coverage-check
**任務 ID**：POC-QA-001（外部專案模擬）

**Self-Review 結論**：PASS

**摘要**：
- 執行範圍：外部專案 /src/auth/ 目錄（模擬）
- 發現問題數量：Critical 0 / Important 2 / Suggestion 3（模擬數據）
- 假設清單：
  1. 外部 AC 以功能行為描述，以可觀察行為符合描述作為通過判定依據
  2. 覆蓋率報告由召喚方提供（假設已執行 jest --coverage）

**詳細結果**：
- AC-1 (POST /auth/login → JWT)：PASS — 對應測試存在，Happy Path + 錯誤路徑均覆蓋
- AC-2 (JWT payload 欄位)：PASS — 靜態讀取代碼確認 userId 和 role 欄位存在
- AC-3 (帳戶鎖定邏輯)：PASS — 測試案例覆蓋第 5 次失敗觸發鎖定 + 鎖定期間嘗試被拒
- 測試覆蓋率：行覆蓋率 84%（>80% 門檻），分支覆蓋率 81%（>80% 門檻）PASS
- Code Review：2 個 Important（錯誤訊息過於詳細，可能洩漏使用者存在性），3 個 Suggestion（命名優化）
```

---

## §5 SPEC 一致性驗證（AC7 交叉驗證）

本節驗證 POC 文件與 `docs/solo-mode/SOLO_MODE_SPEC.md` 的一致性。

| SPEC 規則 | POC 對應實作 | 一致性 |
|-----------|-------------|--------|
| §2.2 QA 必帶 skill：`qa-engineer/SKILL.md` | §1.1 / §1.2 攜帶 | 一致 |
| §2.2 QA 必帶 skill：`quality-gate/SKILL.md` | §1.1 / §1.2 攜帶 | 一致 |
| §2.2 QA 必帶 skill：`escalation/SKILL.md` | §1.1 / §1.2 攜帶 | 一致 |
| §2.2 QA 禁帶：`sprint-execution/SKILL.md` | §1.2 完整禁帶清單列出 | 一致 |
| §2.2 QA 禁帶：`sprint-planning/SKILL.md` | §1.2 完整禁帶清單列出 | 一致 |
| §2.2 QA 禁帶：`sprint-review/SKILL.md` | §1.2 完整禁帶清單列出 | 一致 |
| §2.2 QA 禁帶：`scrum-master/SKILL.md` | §1.2 完整禁帶清單列出 | 一致 |
| §2.2 QA 禁帶：`schedule/SKILL.md` | §1.2 完整禁帶清單列出 | 一致 |
| §2.2 QA 禁帶：`parallel-dispatch/SKILL.md` | §1.2 完整禁帶清單列出 | 一致 |
| §2.2 QA 禁帶：`architecture-decision/SKILL.md` | §1.2 完整禁帶清單列出 | 一致 |
| §2.2 QA 禁帶：`backlog-management/SKILL.md` | §1.2 完整禁帶清單列出 | 一致 |
| §2.2 QA 禁帶：`discovery-phase/SKILL.md` | §1.2 完整禁帶清單列出 | 一致 |
| §2.2 QA 禁帶：`issue-management/SKILL.md` | §1.2 完整禁帶清單列出 | 一致 |
| §2.2 QA 禁帶：`onboarding/SKILL.md` | §1.2 完整禁帶清單列出 | 一致 |
| §2.2 QA 禁帶：`health-check/SKILL.md` | §1.2 完整禁帶清單列出 | 一致 |
| §2.3 Skill 依賴解析邏輯 | 本 POC 場景未啟用選帶 skill，依賴解析未觸發；啟用選帶 skill 時須依 SPEC §2.3 流程解析禁帶依賴並豁免 | 適用，本 POC 場景無需觸發 |
| §2.4 Profile version 欄位必須存在 | §1.1 Profile 包含 `version: "1.0.0"` 欄位 | 一致 |
| §3.1 agent 定義為 P1 必帶 | §2.1 攜帶 `agents/qa-engineer.md`（P1） | 一致 |
| §3.1 選帶 skill 為 P3 | §2.1 補充 P3 欄位，標記本 POC 場景未啟用選帶 skill | 一致 |
| §3.2 禁帶 `PROJECT_BOARD.md` | §2.2 明確不攜帶 | 一致 |
| §3.2 禁帶 Sprint 檔案 | §2.2 明確不攜帶 | 一致 |
| §4.1 不確定性前置檢查必攜帶 | §3.2 執行前置檢查 | 一致 |
| §4.2 Self-Review 必攜帶 | §4.2 執行 Self-Review | 一致 |
| §4.3 Quality Gate 攜帶條件（Code Review） | §4.1 Code Review 行：依 `quality-gate/SKILL.md` §6 執行，標記「可執行」 | 一致 |
| §4.3 Quality Gate 攜帶條件（AC Validation） | §4.1 AC 驗證行：依 `quality-gate/SKILL.md` §7 缺陷分類，標記「可執行」 | 一致 |
| §4.3 Quality Gate 攜帶條件（Security Audit） | §4.1 補充 Security Audit 行：本 POC 場景範圍外，適用時依 SPEC §4.3 規則 | 一致 |
| §4.3 Quality Gate 攜帶條件（Documentation Review / Research） | §4.1 補充 Documentation Review / Research 行：本 POC 場景範圍外，適用時依 SPEC §4.3 規則 | 一致 |
| §4.4 結論輸出格式 | §4.2 使用相同格式 | 一致 |
| §5.1 任務資料不留存 | §1.1 `data_retention: false` | 一致 |
| §5.2 敏感資訊 mask 處理 | §1.1 `sensitive_handling: mask` | 一致 |

**交叉一致性結論：POC 文件與 SPEC 規則完全一致，無矛盾項目。已補充 SPEC §2.3 Skill 依賴解析邏輯、§2.4 Profile version 欄位、§4.3 Quality Gate 5 種任務類型的對應驗證。**

---

## 參照文件

| 文件 | 路徑 |
|------|------|
| Solo Mode 規範 | `docs/solo-mode/SOLO_MODE_SPEC.md` |
| QA Engineer 角色定義 | `agents/qa-engineer.md` |
| QA Engineer Skill | `skills/qa-engineer/SKILL.md` |
| Quality Gate Skill | `skills/quality-gate/SKILL.md` |
| Security Review Skill | `skills/security-review/SKILL.md` |
| Escalation Skill | `skills/escalation/SKILL.md` |
