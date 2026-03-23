# shoot QA 完整品質審查規則

本文件定義 `/shoot` 的 QA 審查規則，由 `skills/shoot/SKILL.md` 按需載入。

---

## QA 完整品質審查（與 Sprint Execution 對齊）

<!-- Issue #257 — Shoot QA 補齊：與 Sprint Execution 品質對齊 -->

### 第一階段：QA Pre-flight

在實作前由 QA subagent 執行預審，確認：

- 任務範圍明確，不超過 Size=S
- 無安全疑慮（外部輸入、認證、授權）
- 無架構影響（若有，升級至 Architect 處理）

**輸出格式**：

```
── QA Pre-flight ──────────────────────
  [PASS/FAIL] 任務範圍檢查
  [PASS/FAIL] 安全疑慮檢查
  [PASS/FAIL] 架構影響檢查
```

### 第二階段：QA Post-check（Spec Compliance + Code Quality）

實作完成後由 QA subagent 執行完整品質審查，**與 sprint-execution story-lifecycle 的 §5-§6 審查標準一致**。

#### Spec Compliance 審查

- 逐一讀取原始任務 AC / Issue 描述，對照實作逐條驗證
- 邊界條件檢查（`[動態]` AC 執行、Edge case、錯誤路徑）
- 行為範例驗證（`[行為]` AC 的 Given-When-Then 場景）

#### Code Quality 審查

**通用靜態分析**：命名可讀性、結構設計（函式 < 20 行）、測試品質（Arrange-Act-Assert）、安全性基礎

**條件觸發的品質清單**（與 story-lifecycle-prompt.md §6 一致）：

| 清單 | 觸發條件 | 檢查項目 |
|------|---------|---------|
| **CQ-NEW** | 新增程式碼 | CQ-NEW-1 測試覆蓋率、CQ-NEW-2 舊測試一致性 |
| **CQ-MOCK** | 使用 Mock/Stub | CQ-MOCK-1 回應格式一致性、CQ-MOCK-2 資料範圍合理性、CQ-MOCK-3 錯誤情境覆蓋、CQ-MOCK-4 Mock 範圍最小化 |
| **CQ-SMOKE** | 涉及外部資源 | CQ-SMOKE-1 外部資源識別、CQ-SMOKE-2 Smoke test 存在、CQ-SMOKE-3 使用真實資料、CQ-SMOKE-4 假設覆蓋 |
| **CQ-DATA** | 涉及靜態資料檔 | CQ-DATA-1 覆蓋率指標定義、CQ-DATA-2 實際覆蓋率達標（**Hard Gate**）、CQ-DATA-3 Blast Radius 評估、CQ-DATA-4 測試集代表性 |

完整判定標準請參照 `skills/sprint-execution/story-lifecycle-prompt.md` §6。

#### 修復閉環

- FAIL 時若為 **Critical** 缺陷，進入 CRITICAL 互動決策點（選項 A/B/C，規則參見 `skills/quality-gate/SKILL.md` §7.1）
- 選擇 A（修復）後內部修復，不升級
- 選擇 B/C 強制寫入 `docs/km/quality-gate-decisions.md`（格式參見 `skills/quality-gate/SKILL.md` §7.2）
- 連續失敗 3 次（選擇 A 後仍 FAIL）→ 終止，exit code 非 0
- 同一任務連續選擇 B/C 超過 2 次 → 升級 Architect 審查

**輸出格式**：

```
── QA Post-check ──────────────────────
  Spec Compliance：
    [PASS/FAIL] AC 逐條驗證
    [PASS/FAIL] 邊界條件檢查
    [PASS/FAIL] 行為範例驗證（若適用）
  Code Quality：
    [PASS/FAIL] 通用靜態分析
    [PASS/FAIL] CQ-NEW 測試覆蓋（若適用）
    [PASS/FAIL] CQ-MOCK Mock 假設驗證（若適用）
    [PASS/FAIL] CQ-SMOKE Smoke 測試（若適用）
    [PASS/FAIL] CQ-DATA 靜態資料覆蓋（若適用）
```

### Architect 審查

由 Architect subagent 確認：

- 實作方向符合既有架構
- 無需 ADR 觸發
- 技術選型合規

**Layer Compliance checklist**（分層合規檢查）：

- [ ] Layer Compliance 共用常數/設定層級檢查：常數與設定值置於正確的共用層，不得散落於業務邏輯層或個別模組
- [ ] Layer Compliance 跨模組 import 方向檢查：import 方向必須符合分層架構單向依賴原則，不得出現跨層或逆向 import
- [ ] Layer Compliance Single Source of Truth 檢查：語意相同的常數或設定不得在多處重複定義，必須維持單一來源

**領域模型審查**（DM checklist，見 `skills/architect/SKILL.md` §10）：

- [ ] DM-1 業務邏輯封裝：業務邏輯封裝在 Service 層，Router 只做 I/O
- [ ] DM-2 Single Source of Truth：相同業務邏輯只有一個實作來源
- [ ] DM-3 狀態轉換統一：狀態轉換有統一對照表，不散落各處
- [ ] DM-4 共享寫入入口：共享資源有唯一寫入入口（Gateway），類別圖標示依賴方向

### 任一 FAIL 時的三個可觀察驗收點

當 QA Pre-flight、Architect 審查、QA Post-check、外部獨立審查或 CI/CD 雙審查 Gate 任一回傳 FAIL 時：

| 可觀察點 | 說明 |
|---------|------|
| (a) exit code 非 0 | process 以錯誤碼結束 |
| (b) Shoot_Log.md 中該次任務無 PASS 記錄 | log 筆數不增加，Shoot_Log.md 保持不變 |
| (c) 不執行 `shoot:` 前綴的 git commit | commit 狀態為未提交 |

---

## 測試可寫性檢查（步驟 1.5）

<!-- Issue #257 — 移植 story-lifecycle-prompt.md §3 TC-W1~W5 -->

在任務解析完成後、QA Pre-flight 之前，**檢查任務描述 / AC 是否可轉化為測試**。此步驟與 sprint-execution story-lifecycle 的測試可寫性檢查完全一致。

### 檢查條件

| 條件 | 判斷標準 | 說明 |
|------|---------|------|
| **TC-W1** | AC 描述模糊無法寫 assertion | 使用「適當」、「正確」、「合理」等主觀詞，無法轉化為可驗證斷言 |
| **TC-W2** | AC 缺少輸入/輸出定義 | 未定義輸入資料格式、邊界值、或預期的輸出值/狀態碼/回應結構 |
| **TC-W3** | AC 涉及未定義的外部依賴 | 依賴尚未定義的外部系統行為、API 契約、或第三方服務規格 |
| **TC-W4** | AC 之間存在邏輯矛盾 | 多個 AC 相互排斥，無法同時滿足 |
| **TC-W5** | AC 完成標準無法量測 | 驗收標準為主觀定性判斷，無法轉化為自動化測試 |

### 處理流程

- 任一 AC 觸發 TC-W1 ~ TC-W5 → 測試可寫性檢查 FAIL
- 輸出結構化問題清單，要求釐清後重新執行
- **禁止進入實作**（Hard Gate）

### 輸出格式

```
── 測試可寫性檢查 ─────────────────────
  [PASS] 所有 AC 可轉化為測試
```

FAIL 時：

```
── 測試可寫性檢查 ─────────────────────
  [FAIL] 以下 AC 無法轉化為測試：
    - AC2：觸發 TC-W1（「適當處理」無法寫 assertion）
    - AC5：觸發 TC-W2（未定義預期回應格式）

[ERROR] 測試可寫性檢查 FAIL，終止執行
  請釐清以上問題後重新執行 /shoot
```

<HARD-GATE>
**測試可寫性 Hard Gate（/shoot）**：TC-W1 ~ TC-W5 任一觸發 → 禁止進入實作，exit code 非 0。
</HARD-GATE>

---

## 測試執行 + Systematic Debugging（步驟 4.5）

<!-- Sprint 90 — 新增寫完程式立即測試 + systematic debugging 觸發點 -->

在步驟 4（實作）完成後、步驟 5（QA Post-check）之前，**立即執行本地測試**，確保程式碼在 commit 前就通過測試，不等到 CI Gate 才發現問題。

### 執行步驟

1. **執行本地測試**：跑 unit test / integration test（依專案測試框架）
2. **測試全部通過** → 繼續步驟 5（QA Post-check）
3. **測試失敗** → 觸發 `invoke shikigami:systematic-debugging`，告知目的為「shoot 實作後測試失敗根因排查」
4. **修復後重新測試**：systematic debugging 完成修復後，重新執行測試
   - 通過 → 繼續步驟 5
   - 仍失敗 → exit code 非 0，Shoot_Log.md 無 PASS 記錄，終止

### 與 CI Gate 的關係

步驟 4.5 在 commit **之前**攔截測試失敗，CI Gate 在 push **之後**攔截 CI 環境特有的失敗（如環境差異、依賴衝突）。兩者互補：

| 觸發點 | 時機 | 抓的問題 |
|--------|------|---------|
| 步驟 4.5（本地測試） | commit 前 | 邏輯錯誤、回歸、型別錯誤 |
| CI Gate | push 後 | 環境差異、CI 專屬檢查（lint rules、coverage threshold） |

兩處測試失敗均可觸發 `invoke shikigami:systematic-debugging` 進行根因排查。
