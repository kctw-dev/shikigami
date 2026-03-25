# Version Management — 版本 Tag 管理

**抽出自**：deployment-readiness/SKILL.md §4

Sprint Review 驗收通過後，由 SRE subagent 負責打 tag 與更新版號。

## 版號策略（Semantic Versioning）

| 事件 | 版號變化 | 範例 |
|------|----------|------|
| Sprint Review 通過 | minor +1 | `v0.1.0` → `v0.2.0` |
| Hotfix（Sprint 外緊急修復） | patch +1 | `v0.2.0` → `v0.2.1` |
| 正式穩定版（外部使用者驗證） | major | `v0.x.y` → `v1.0.0` |

## 執行步驟

1. 更新 `.claude-plugin/plugin.json` 的 `version` 欄位
2. 更新 `.claude-plugin/marketplace.json` 的 `version` 欄位
3. Commit：`chore: bump version to vX.Y.Z`
4. 打 tag：`git tag vX.Y.Z`
5. Push：`git push && git push --tags`
6. 建立 GitHub Release：`gh release create vX.Y.Z --title "vX.Y.Z" --notes "<release notes>" --latest`

## 觸發時機

```
sprint-review 驗收通過
  → 觸發 deployment-readiness
    → SRE subagent 執行版本 Tag 流程
    → 部署就緒檢查（若有部署需求）
```

<HARD-GATE>
`plugin.json` 與 `marketplace.json` 的版號必須一致。
Tag 名稱必須與 `plugin.json` 的 version 欄位一致（加 `v` 前綴）。
</HARD-GATE>

## 版本 Tag 決策規則

在執行版本 Tag 流程前，SRE subagent 必須依下列規則判定版號 bump 類型。

### 決策矩陣

| 條件 | 決策 | 版號變化 |
|------|------|----------|
| Sprint Review 通過 + 所有 Stories 完成 + 無安全掃描失敗 | **Minor bump** | `vX.Y.0` → `vX.(Y+1).0` |
| ROADMAP 里程碑完成（所有里程碑 Stories 均已交付）+ PO 確認 + 無安全掃描失敗 | **Major bump** | `vX.Y.Z` → `v(X+1).0.0` |
| Hotfix（Sprint 外緊急修復，標注 `[EMERGENCY]`） | **Patch bump** | `vX.Y.Z` → `vX.Y.(Z+1)` |
| 以下任一禁止條件成立 | **禁止 bump** | 不更新版號 |

### Minor Bump 觸發條件（vX.Y+1.0）

以下**全部**條件成立時，執行 Minor bump：

- Sprint Review 驗收通過（PO Subagent 確認）
- Sprint Backlog 中所有計畫 Stories 均已完成（無「未完成」狀態 Story）
- 安全掃描已通過（Security subagent 確認）
- sprint-review SKILL.md §7 執行檢查清單全部打勾

### 當日重複 Minor 降級為 Patch

當 Minor Bump 觸發條件全部滿足，但**當日已存在一個 minor bump tag** 時，本次 bump 自動降級為 **Patch bump**，以避免同一天內打出多個 minor tag。

**判斷邏輯（SRE subagent 執行）**：

```bash
LATEST_TAG=$(git tag --sort=-creatordate | head -1)
TAG_DATE=$(git log -1 --format='%cd' --date=short "$LATEST_TAG" 2>/dev/null)
TODAY=$(date '+%Y-%m-%d')
if [[ "$TAG_DATE" == "$TODAY" ]]; then
  # 當日已有 tag → 降級為 patch bump
  BUMP_TYPE="patch"
else
  # 跨日或無 tag → 正常 minor bump
  BUMP_TYPE="minor"
fi
```

**決策規則**：

| 情況 | 最新 Tag 日期 | bump 類型 |
|------|--------------|-----------|
| 當日已有 minor bump | 今天 | **patch** |
| 跨日第一次 bump | 昨天或更早 | **minor**（正常） |
| 無任何 tag | N/A | **minor**（不報錯） |

**範例**：

- 今天 `2026-03-20` 已存在 `v0.74.0`（minor bump）→ 本次 bump 為 `v0.74.1`（patch）
- 最新 tag `v0.74.1` 日期為 `2026-03-19` → 本次 bump 為 `v0.75.0`（minor）

<HARD-GATE>
當日重複 Minor 降級邏輯必須在打 tag 前執行。
無 tag 時不得報錯，應視為跨日情況，執行正常 minor bump。
</HARD-GATE>

### Major Bump 觸發條件（vX+1.0.0）

以下**全部**條件成立時，**且已符合 Minor Bump 條件**，升級為 Major bump：

- `docs/prd/ROADMAP.md` 某個里程碑下的所有 Stories 均已標記完成
- PO 明確確認該里程碑達成（口頭或 Sprint Review 記錄）
- sprint-review SKILL.md 的 ROADMAP 里程碑對齊檢查確認里程碑完成
- 安全掃描已通過

### 禁止 Bump 條件

以下任一條件成立時，**不得執行任何版號 bump**：

- Sprint Backlog 有任何 Story 狀態為「未完成」
- 安全掃描未通過或尚未執行
- 部署 Checklist 有未勾選項目
- sprint-review SKILL.md §7 執行檢查清單有未完成項目

### PO Override 機制

當自動決策規則判定「禁止 bump」，但 PO 認為基於商業原因應執行 bump 時，PO 可啟動覆蓋機制。

**觸發條件**：自動規則建議禁止 bump，但 PO 明確指示應執行 bump。

**執行步驟**：

1. PO 提供覆蓋原因（必須是具體商業原因，例如：「僅有文件性 Story 未完成，不影響功能穩定性」）
2. SRE subagent 在執行 bump 前在 commit message 中標注：
   ```
   chore: bump version to vX.Y.Z [PO-OVERRIDE]

   覆蓋原因：<PO 提供的覆蓋原因>
   覆蓋時間：YYYY-MM-DD
   覆蓋決策者：PO
   ```
3. 同步將覆蓋記錄寫入 `docs/km/Metrics_Log.md` 的備注欄（格式：`[PO-OVERRIDE] vX.Y.Z — <原因摘要>`）
4. Sprint Review Retrospective 的 Problem 區塊記錄此次覆蓋事件，確保下個 Sprint 追蹤根因

**限制**：

- PO Override 不得用於規避安全掃描未通過的限制——安全掃描失敗是絕對禁止條件，PO 無法覆蓋
- 連續兩個 Sprint 使用 PO Override 時，自動升級至 Stakeholder 審查

<HARD-GATE>
安全掃描未通過時，禁止任何版號 bump，包括 PO Override 情況。
PO Override 必須標注 [PO-OVERRIDE] 於 commit message，且同步記錄至 Metrics_Log.md。
</HARD-GATE>
