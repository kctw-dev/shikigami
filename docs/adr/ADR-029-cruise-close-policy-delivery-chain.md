# ADR-029：Cruise Close Policy + Delivery Chain Per-Repo 可定義

**日期**：2026-03-23
**狀態**：Accepted
**相關 Issue**：#338
**提案者**：Architect Agent

---

## 背景

Issue #338 提出兩個需求：

1. **Issue 關閉政策**：Cruise PO 巡邏直接 close Issue 過度自動化，發 Issue 的人可能不同意。需要在確認流程中加入發 Issue 人同意機制（`require_creator_approval`）。

2. **交付鏈深度**：不同 repo 成熟度不同，固定的 `staging → E2E → tag → production → close` 交付鏈不適用所有 repo（如純原型、只需到 PR merge 的 repo）。

---

## 決策

### 決策 1：Close Policy 設定 schema

在 `.claude/shikigami.local.md` YAML frontmatter 新增 `close_policy` 區段：

```yaml
shikigami:
  project_level: low
  close_policy:
    require_creator_approval: false   # 預設 false（現有行為，向後相容）
    default_timeout: 2h               # 等待確認的 timeout（預設 2h）
    per_repo:
      KCTW/kinun: 4h                  # 個別 repo 可覆蓋 timeout
      LinGeorge2/AIO-System: 2h
```

**行為語意**：

- `require_creator_approval: false`（預設）→ 直接 close（維持現有行為）
- `require_creator_approval: true` → 留言建議關閉 + 加 `awaiting-reply` label → 超時機制統一處理

**豁免規則**：

- PO 自建 Issue → 豁免 `require_creator_approval`，直接 close（自己關自己的 OK）
- `stakeholder` label 的 Issue → 安全邊界已涵蓋，不受 close_policy 影響

### 決策 2：Delivery Chain 設定 schema

在 `.claude/shikigami.local.md` YAML frontmatter 新增 `delivery_chain` 區段：

```yaml
shikigami:
  project_level: low
  delivery_chain:
    default: production               # 預設完整交付鏈
    per_repo:
      KCTW/kinun: production          # 完整鏈：staging → E2E → tag → production → close
      LinGeorge2/AIO-System: pr       # PR merge 即交付完成
      kctw-dev/seiryu: none           # 純原型，無交付鏈
      kctw-dev/tenjin: none
      kctw-dev/taba: none
```

**交付終點語意**：

| 值 | 行為 |
|----|------|
| `production`（預設） | 完整交付鏈：`staging → E2E → tag → production → close` |
| `pr` | PR merge 即視為交付完成，直接 close Issue |
| `none` | 跳過交付追蹤，不推進交付步驟 |

### 決策 3：Schema 向下相容性

- 新增欄位均為可選（optional），不填等同預設值
- 預設值 = 現有行為（`require_creator_approval: false`、`delivery_chain.default: production`）
- 無 `close_policy` 區段 → 行為與現有完全相同
- 無 `delivery_chain` 區段 → 行為與現有完全相同
- 現有只有 `project_level` 的設定檔 → 完全向後相容

### 決策 4：Timeout 精度

- 使用 `issue.updatedAt`（GitHub API 欄位）近似 label 加入時間
- 已知限制：Issue 更新觸發 `updatedAt` 改變，可能延後 timeout 計算
- 可接受理由：timeout 機制目的是防止無限期等待，±1小時的精度誤差對此目標無影響
- 與現有 `awaiting-reply` 超時機制（Step 2）使用相同精度，一致性好

---

## 替代方案考量

| 方案 | 優點 | 缺點 | 決策 |
|------|------|------|------|
| 設定集中在 `.claude/shikigami.local.md` | SSOT，單一設定入口 | 需解析 YAML frontmatter | 採用 |
| 設定分散在各 repo 的設定檔 | repo 自治 | 需跨 repo 讀取，複雜度高 | 否決 |
| 新增獨立設定檔 | 清晰分離 | 新增檔案管理成本 | 否決 |
| `require_creator_approval` 整合進 `project_level` | 設定更少 | project_level 語意混濁 | 否決 |

---

## 影響

1. **修改**：`skills/cruise/SKILL.md`
   - Step 3（已修復未關 → 結案）：加入 `close_policy.require_creator_approval` 判斷
   - 交付推進自動化：加入 `delivery_chain` per-repo 設定讀取
2. **修改**：`.claude/shikigami.local.md` — 加入示範設定
3. **新增讀取邏輯**：Cruise 啟動流程加入 `close_policy` + `delivery_chain` 讀取步驟

---

## 附錄：close_policy 與現有 auto-close 的關係

| 機制 | 觸發條件 | 目的 |
|------|---------|------|
| Step 2 自動關閉（現有） | `awaiting-reply` / `pending` label + 超時 | 缺資訊或明確暫停後等待逾時 |
| Step 3 close_policy（新增） | 已修復未關 + `require_creator_approval: true` | 修復後結案需發 Issue 人確認 |

兩者用**觸發條件**區分，不衝突：
- Step 2：缺資訊或暫停等待，等待對象是任何回覆
- Step 3（新）：修復結案，等待對象是發 Issue 人確認
