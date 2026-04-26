# ADR 歸檔政策（D5）

**狀態**：Accepted
**生效日期**：2026-04-27
**Owner**：Architect

> 本政策定義何時、如何、由誰把休眠或被取代的 ADR 移到 `docs/adr/archive/`，避免 ADR 目錄無限擴張造成認知負擔。

---

## 為何要歸檔

Shikigami 已累積 45+ 個 ADR。其中：

- 大部分仍主動驅動執行面（被 skills / scripts / hooks 引用）
- 少數已被後續決策取代（Superseded）
- 少數雖未被取代，但其決策已內化或失去主動參考價值（Dormant）

若這些 ADR 持續留在主目錄，會讓人誤以為它們仍是現行決策。歸檔不是刪除 — **是把它們從主動決策面移到歷史面**。

---

## 歸檔分類（與 `scripts/audit-adr-references.sh` 對應）

| 類別 | 定義 | 處理 |
|------|------|------|
| **ACTIVE** | 在 `skills/` `scripts/` `hooks/` `agents/` `commands/` `CLAUDE.md` `README.md` 中被引用 ≥ 1 次 | 留在主目錄 |
| **DOCS-ONLY** | 只在 `docs/` 內部其他文件被互引；無執行面引用 | 留在主目錄（暫不歸檔，待觀察期） |
| **DORMANT** | 完全無任何引用 | **archive 候選**（需 review） |
| **SUPERSEDED** | ADR 內文以下列格式之一明確標記：<br>`**狀態**：Superseded` ／<br>`**[Superseded by ADR-NN]`** ／<br>行首 `Superseded by ADR-NN` | **archive 立即可執行** |

---

## 歸檔流程

### Step 1 — 定期稽核

每季 Architect 執行：

```bash
bash scripts/audit-adr-references.sh --candidates
```

輸出列表為候選清單（DORMANT + SUPERSEDED）。

### Step 2 — 候選審查

| 候選類別 | 審查問題 |
|---------|---------|
| SUPERSEDED | 取代者 ADR 是否確實涵蓋全部決策域？若部分仍有效，保留標注並暫不歸檔 |
| DORMANT | 是否被 onboarding / tutorial 文件隱性依賴？是否將在下個 Sprint 重新啟用？ |

審查結果由 Architect 與當初決策的提案者（若可追溯）共同確認。

### Step 3 — 歸檔操作

通過審查的 ADR：

1. `git mv docs/adr/ADR-NNN.md docs/adr/archive/ADR-NNN.md`
2. 在 `docs/adr/ADR-NNN.md` 原位置建立 **forwarding stub**（含取代者連結 + 歸檔日期 + 為何不直接刪除）
3. 在 `docs/adr/README.md`（自動產生的索引）中標記為 `Archived`，並從主索引表移到 Archived 區段
4. 執行 `bash scripts/audit-adr-references.sh` 確認 DORMANT/SUPERSEDED 計數已更新
5. Commit message 格式：`docs(adr): archive ADR-NNN — <reason>`

### Step 4 — 連結回填

被歸檔 ADR 在他處的引用：

- 自動產生的索引：`scripts/update-adr-index.sh` 重跑後會自動處理
- 手寫文件中的連結：保持指向原位置（forwarding stub 會帶讀者去 archive/）
- 不主動修改其他文件的連結（避免大量 churn）

---

## 為何不直接刪除歸檔 ADR

| 理由 | 說明 |
|------|------|
| **歷史脈絡可追溯** | 新成員 onboarding 時仍可閱讀決策推理 |
| **避免外部連結 404** | 部落格、會議紀錄、PR 描述可能有舊連結 |
| **取代者解讀依賴** | 後續 ADR 在「拒絕的替代方案」段落常引用前人 ADR |
| **歸檔成本低** | `git mv` 即可，反向回滾也容易 |

---

## 反例 — 不該歸檔的情境

以下情況**不應**自動歸檔，即使引用數低：

| 情境 | 為何保留 |
|------|---------|
| ADR 描述「拒絕了 X 方案」但 X 方案後來被討論時可能再被提及 | 歷史否決理由仍是現行決策的一部分 |
| ADR 被某個 skills/X/SKILL.md 隱性依賴但未明寫引用 | 稽核腳本可能漏判，需人工複核 |
| 0 引用但僅 7 天內建立 | 新 ADR 觀察期未滿，不立即判定 DORMANT |
| RESEARCH-type 的 ADR（探索性質） | 探索結論本身就不會在執行面被引用，但仍是有效決策 |

---

## 索引維護

`docs/adr/README.md` 由 `scripts/update-adr-index.sh` 自動產生。歸檔操作後重跑該腳本即可同步索引。

歸檔的 ADR 應在 README 中以獨立 `## 已歸檔 ADR` 段落列出，包含：
- ADR 編號 + 標題
- 歸檔日期
- 取代者（若有）
- forwarding stub 連結

---

## 第一次套用記錄

| ADR | 類別 | 取代者 | 歸檔日期 |
|-----|------|--------|---------|
| ADR-009 — Backlog Intake 自動化技術決策 | SUPERSEDED | ADR-010 | 2026-04-27（D5）|

未來歸檔請追加於此表。
