# ADR-032：交付路徑分層（/commit vs /shoot vs /sprint-execution）

**日期**：2026-03-23
**狀態**：Accepted
**相關 Issue**：#391
**提案者**：Architect Agent
**關聯 ADR**：ADR-023（PR-based Git Flow）、ADR-029（Cruise Close Policy + Delivery Chain）

---

## 背景

### 問題陳述

Shikigami 目前提供兩條交付路徑：

| 路徑 | 品質閘門 | 適用場景 |
|------|---------|---------|
| `/shoot` | 完整 QA gate（Spec Compliance + Code Quality + pr-review-toolkit）→ PR → merge | 功能需求、Bug 修復 |
| `/sprint-execution` | Sprint 儀式 + 完整審查 → PR → merge | Sprint 規劃下的 Story 交付 |

然而，部分改動（如文件修正、設定更新、版號 bump）使用 `/shoot` 或 `/sprint-execution` 明顯過重：

1. **文件修正**（typo、格式、描述補充）：無需程式碼審查，QA gate 成本高但收益趨近於零
2. **設定檔更新**（`*.json`、`*.yaml` 非邏輯變更）：無需功能審查，走完整 QA 浪費資源
3. **版號 bump**（僅更新版本字串）：已定義規格，無額外決策，完整 Sprint 儀式毫無必要
4. **快速 hotfix 文件**：緊急修正說明文件，流程越輕量越好

缺乏最輕量交付路徑導致：
- Agent 在輕量改動時走過重流程，浪費 context 和時間
- 或直接跳過流程直推 main（違反 ADR-023），製造潛在問題

Issue #391 背景為 PB quick-ship 前置條件，需決定 `/commit` scope、品質保護、ADR-023 相容性。

---

## 決策問題

是否引入第三條最輕量交付路徑 `/commit`，明確定義三條路徑的層級、適用 scope 與品質保護機制？

---

## 考慮的選項

### 決策 1：三層交付路徑分層架構

**選定方案：建立三層路徑，以 scope 邊界嚴格區分**

```
Layer 1 — /commit（最輕）
  └─ 適用：doc-only 或 config-only 改動
  └─ 流程：lint + format → commit → push（豁免 PR gate）

Layer 2 — /shoot（中等）
  └─ 適用：功能實作、Bug 修復、有程式碼邏輯的改動
  └─ 流程：完整 QA gate → branch → PR → review loop → merge

Layer 3 — /sprint-execution（最重）
  └─ 適用：Sprint 規劃下的 Story，需完整儀式與歷史追蹤
  └─ 流程：Sprint 儀式 + 完整審查 → branch → PR → review loop → merge
```

**各層定義摘要**：

| 屬性 | `/commit` | `/shoot` | `/sprint-execution` |
|------|-----------|---------|---------------------|
| QA Gate | 無（lint only） | 完整（Spec + Code + PR Review） | 完整（同 shoot） |
| PR | 無（豁免，直推） | 有（feature branch + PR） | 有（feature branch + PR） |
| Sprint 儀式 | 無 | 無 | 有（Planning / Review / Retro） |
| Scope 限制 | 嚴格（doc/config-only） | 寬鬆（功能性改動） | Sprint Story scope |
| 主要使用者 | Developer（小改動）| Developer（功能交付）| Sprint Execution 主 session |

### 決策 2：`/commit` 的 scope 邊界定義

**選定方案：以檔案類型 + 變更性質雙重判定**

`/commit` 僅適用於下列改動類型（必須同時滿足）：

**允許的檔案類型**（whitelist）：

| 類型 | 範例路徑 | 說明 |
|------|---------|------|
| ADR 文件 | `docs/adr/*.md` | 架構決策紀錄 |
| Sprint 文件 | `docs/sprints/**` | Sprint 狀態、紀錄 |
| KM 文件 | `docs/km/**` | 知識管理 |
| Tutorial 文件 | `docs/tutorial/**` | 教學說明 |
| SDD 文件 | `docs/sdd/**` | 系統設計文件 |
| 其他 docs | `docs/**` | 一般文件（非 Skill/Agent .md） |
| 設定檔 | `*.json`（非邏輯）、`*.yaml`、`*.yml`、`.env.*` | 純設定，無程式邏輯 |
| 版號 bump | `plugin.json`、`marketplace.json`、`gemini-extension.json`、`README.md` | 版本字串更新 |

**明確排除的檔案類型**（blacklist）：

| 類型 | 範例路徑 | 理由 |
|------|---------|------|
| Agent 定義 | `agents/*.md` | Skill/Agent .md 等同框架行為變更（參見 CLAUDE.md 開發紅線） |
| Skill 定義 | `skills/*/SKILL.md`、`skills/**/*.md` | 同上 |
| Hook 腳本 | `hooks/*.sh`、`hooks/hooks.json` | 影響框架執行行為 |
| MCP Server | `mcp-servers/**` | 程式碼邏輯 |
| 測試腳本 | `tests/*.sh` | 驗證邏輯 |
| 驗證腳本 | `scripts/*.sh` | 驗證邏輯 |
| Command 定義 | `commands/*.md` | 框架行為定義 |

**變更性質限制**：
- 允許：文字修正、說明補充、格式調整、純設定值更新、版號字串更新
- 不允許：新增邏輯分支、新增流程步驟、影響 Agent 行為的描述變更

### 決策 3：`/commit` 流程設計

**選定方案：輕量三步流程，無 QA gate，無 PR**

```
[/commit 流程]
  1. scope 邊界驗證（強制）
     → 確認所有變更檔案均在 whitelist 範圍內
     → 確認無 blacklist 檔案
     → 若驗證失敗 → 輸出 [COMMIT-SCOPE-VIOLATION] → 升級至 /shoot 或 /sprint-execution

  2. lint + format（輕量品質保護）
     → Markdown lint（如有設定）
     → JSON format 驗證（jq 解析）
     → 版號一致性檢查（如涉及版號文件）

  3. commit + push（直推 main）
     → git add <specified-files>（明確指定，不用 git add -A）
     → git commit -m "<conventional-commit-prefix>: <描述>"
     → git push origin main
     → 輸出 [COMMIT-DONE] <commit-hash>
```

**與 ADR-023 豁免清單的相容性**：

ADR-023 決策 2 定義了 PreToolUse hook 豁免清單，`/commit` 路徑需納入：

| 豁免條件 | 判定邏輯 | 新增理由 |
|----------|---------|---------|
| 狀態文件直推 | 變更僅限 `docs/sprints/**` 或 `docs/PROJECT_BOARD.md` | 原有豁免 |
| Claim/Release ref | `git push origin refs/claims/` | 原有豁免 |
| git tag push | `git push origin --tags` 或 `v*` | 原有豁免 |
| `/commit` 路徑 | commit message 含 `[commit-path]` 標記 | **新增豁免** |

`/commit` 路徑執行 push 前，commit message 必須附加 `[commit-path]` 標記，供 `main-protect.sh` hook 識別豁免。

### 決策 4：`/commit` 濫用防護

**選定方案：使用頻率追蹤 + PO 巡邏提醒**

為防止 `/commit` 被濫用（繞過 QA 推送非文件類型變更），建立追蹤機制：

**頻率追蹤**：

- 每次 `/commit` 成功後，在 `docs/sprints/live-log/` 當日 session log 記錄一筆 `[COMMIT-PATH-USAGE]` 事件
- 記錄格式：`[COMMIT-PATH-USAGE] <timestamp> <commit-hash> <files-changed>`

**告警門檻**：

| 條件 | 動作 |
|------|------|
| 單一 session 內 `/commit` 使用 ≥ 5 次 | 輸出 `[COMMIT-FREQ-WARN] /commit 使用頻率異常，建議確認是否應改用 /shoot` |
| Cruise 巡邏發現 `[COMMIT-PATH-USAGE]` 筆數超過 Sprint 總 Story 數的 50% | PO Agent 巡邏時輸出提醒，建議 Stakeholder 審視使用模式 |

**人工審查觸發點**：

- PO Agent 在 Sprint Review 時統計本 Sprint `/commit` 使用次數
- 若超過閾值（10 次/Sprint），在 Sprint Review 摘要中標注，提供使用清單供 Stakeholder 審視

### 決策 5：路徑選擇決策樹

**選定方案：明確決策樹，供 Agent 快速判斷**

```
開始交付任務
  │
  ├─ 是否在 Sprint Planning 規劃範圍內的 Story？
  │   └─ 是 → /sprint-execution
  │
  ├─ 變更是否包含 blacklist 檔案（agents/、skills/、hooks/、mcp-servers/、tests/、scripts/）？
  │   └─ 是 → /shoot
  │
  ├─ 變更是否包含程式碼邏輯（新增分支、修改流程步驟、影響 Agent 行為）？
  │   └─ 是 → /shoot
  │
  └─ 變更是否全部在 /commit whitelist 範圍（doc-only 或 config-only）？
      ├─ 是 → /commit（最輕量）
      └─ 否 → /shoot（預設安全選擇）
```

**不確定時的預設行為**：當 Agent 無法確定路徑時，預設選擇 `/shoot`（過重優於欠缺保護）。

---

## 決策

**建立三層交付路徑分層架構**，具體決策摘要：

| 決策項 | 結論 |
|--------|------|
| 三層架構 | `/commit`（輕）→ `/shoot`（中）→ `/sprint-execution`（重） |
| `/commit` scope | doc-only + config-only，whitelist/blacklist 雙重驗證 |
| `/commit` 流程 | scope 驗證 → lint/format → commit → 直推 main（無 PR） |
| ADR-023 相容性 | commit message 附加 `[commit-path]` 標記，納入 hook 豁免清單 |
| 濫用防護 | 使用頻率追蹤 + 門檻告警 + Sprint Review 統計 |
| 路徑選擇 | 決策樹，不確定時預設 `/shoot` |

---

## 實作影響

### 需新增的檔案

| 檔案 | 內容 |
|------|------|
| `skills/commit/SKILL.md` | `/commit` Skill 定義（scope 驗證、lint、commit、push 流程） |

### 需修改的檔案

| 檔案 | 修改內容 |
|------|---------|
| `hooks/main-protect.sh`（或等效腳本） | 新增 `[commit-path]` 標記豁免判定 |
| `agents/developer.md` | 新增交付路徑分層指引，引用決策樹 |
| `docs/adr/ADR-023-pr-based-git-flow.md` | 新增 Amendment：`/commit` 路徑豁免補充 |

### Hook 豁免新增（main-protect.sh）

```bash
# 新增豁免條件：/commit 路徑標記
if echo "$COMMIT_MESSAGE" | grep -q "\[commit-path\]"; then
  exit 0  # 豁免，允許直推 main
fi
```

---

## 後果

### 正面

- **交付效率提升**：文件類改動無需走完整 QA，節省 context 和時間
- **違規行為顯性化**：有了合法輕量路徑，直推 main 的「偷懶行為」更容易被識別為違規
- **明確邊界**：whitelist/blacklist + 決策樹消除模糊地帶，Agent 不需猜測
- **ADR-023 相容**：`[commit-path]` 標記機制與現有 hook 豁免清單設計一致
- **PB quick-ship 前置條件滿足**：提供輕量路徑供快速交付文件類 PB 項目

### 負面

- **新增流程複雜度**：三層路徑需要 Agent 學習決策樹
- **scope 誤判風險**：Agent 可能誤將應走 `/shoot` 的改動歸類為 `/commit`

### 風險緩解

| 風險 | 緩解措施 |
|------|---------|
| scope 誤判 | 決策樹「不確定時預設 /shoot」；blacklist 明確列舉高風險類型 |
| 濫用繞過 QA | 使用頻率追蹤 + Sprint Review 統計 + PO 巡邏提醒 |
| ADR-023 hook 相容性 | `[commit-path]` 標記由 Skill 強制附加，hook 豁免邏輯明確 |
| Skill/Agent .md 誤入 whitelist | blacklist 優先於 whitelist；`skills/`、`agents/` 路徑明確列為 blacklist |

---

## 附錄：三層路徑比較表

| 維度 | `/commit` | `/shoot` | `/sprint-execution` |
|------|-----------|---------|---------------------|
| 觸發方式 | 手動呼叫 `/commit` Skill | 手動呼叫 `/shoot` Skill | Sprint Execution 主 session 自動觸發 |
| Scope 驗證 | 強制（whitelist/blacklist） | 無（由使用者判斷） | Sprint Story scope |
| QA Gate | 無（lint only） | Spec Compliance + Code Quality + PR Review | 同 shoot |
| Branch | 無（直推 main） | `shoot/<issue-or-desc>` | `sprint-<N>/<story-id>` |
| PR | 無 | 有（squash merge） | 有（squash merge） |
| Sprint 儀式 | 無 | 無 | Planning / Review / Retro |
| Commit 標記 | `[commit-path]` | 無特殊標記 | 無特殊標記 |
| 使用頻率追蹤 | 有（防濫用） | 無 | 無 |
| 適用場景 | doc/config 小改動 | 功能交付、Bug 修復 | Sprint Story 交付 |
| 速度 | 最快（< 1 分鐘） | 中等（5-10 分鐘） | 最慢（含 Sprint 儀式） |
