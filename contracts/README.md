# contracts/ — 跨角色共用交付合約

本目錄為專案的**統一合約查閱點**，存放跨角色共用的交付標準與檢查清單。

---

## 用途

`contracts/` 目錄的目的是：

1. 提供**單一查閱點**：所有角色均可在此找到共用的交付標準，無需分散查閱各角色的 SKILL.md
2. 定義**可驗收的交付門檻**：每份合約以 Markdown checkbox 格式列出具體可核查條件
3. 建立**跨角色共識**：合約一旦建立，所有 `applicable_roles` 列出的角色均受其約束

---

## 與 CLAUDE.md 的分工邊界

| 面向 | CLAUDE.md | contracts/ |
|------|-----------|------------|
| **定義範圍** | 框架層級的原則、角色定義、全域規範 | 特定領域的交付標準與驗收清單 |
| **適用對象** | 所有 AI Agent，框架層全局生效 | 特定角色（由 `applicable_roles` 定義），按需載入 |
| **更新頻率** | 低頻（框架架構調整時修改） | 中頻（隨業務需求演進，獨立維護） |
| **格式** | 自由格式說明文件 | 固定格式（YAML frontmatter + 檢查清單） |
| **觸發時機** | Session 啟動時全量載入 | Story 執行中按角色需求主動載入 |

---

## 命名慣例

合約檔案命名遵循 `{domain}-contract.md` 格式：

- `{domain}`：描述合約所涵蓋的業務領域或交付類型（使用英文小寫，單字間以連字號連接）
- 範例：`sow-delivery-contract.md`、`numerical-consistency-contract.md`

---

## 合約結構規範

每份合約必須包含：

1. **YAML frontmatter**（必要欄位）：
   - `title`：合約標題（中文）
   - `created`：建立日期（YYYY-MM-DD）
   - `last_updated`：最後更新日期（YYYY-MM-DD）
   - `applicable_roles`：適用角色清單

2. **`## 檢查清單` 區段**：以 Markdown checkbox 格式列出所有可核查條件

---

## 現有合約清單

| 合約檔案 | 說明 | 適用角色 |
|---------|------|---------|
| [sow-delivery-contract.md](./sow-delivery-contract.md) | SOW 交付合約——定義 SOW 文件必須包含的所有交付要素 | architect, qa-engineer, developer |
| [numerical-consistency-contract.md](./numerical-consistency-contract.md) | 數值一致性合約——確保數值修改後跨表同步驗證 | developer, qa-engineer, scrum-master |

---

## 合約載入方式

角色在執行 Story 時，依以下方式載入相關合約：

```
Read: contracts/{domain}-contract.md
```

載入時機：Story 執行開始時（取出 AC 後、開始實作前），確認相關合約條款後再進行開發。

詳細載入步驟請參閱各角色 SKILL.md 的「合約載入」章節。
