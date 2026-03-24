# §5.5 序列鎖（Sequential Group Lock）使用說明

## 問題背景

Planning 與 Execution 兩個 Skill 若同時觸發，會造成共享檔案（如 `sprint_N.md`）的讀寫衝突與競態條件。序列鎖機制透過 group 綁定，確保同群組內的 Skill 不會平行執行。

## 觸發語法

```bash
# 將 sprint-planning 綁定至 sprint-cycle 群組
/schedule sprint-planning --interval 1h --sequential-group sprint-cycle

# 將 sprint-execution 綁定至同一群組
/schedule sprint-execution --interval 1h --sequential-group sprint-cycle
```

## Group 綁定方式

使用 `--sequential-group <group-name>` 將 Skill 加入指定群組。同一群組名稱的所有 Skill 共享一把群組鎖（group lock），任一時刻只有一個 Skill 能持有此鎖並執行。

**group-name 命名規範**：與 skill-name 相同的白名單規則——小寫英文、數字、連字號，不可以連字號開頭，最長 64 字元。

## 鎖行為描述

| 情境 | 行為 |
|------|------|
| 群組無任何 Skill 執行中 | 取得 group lock，繼續執行 |
| 同群組另一 Skill 正在執行（group lock 被佔用） | 立即退出（SKIPPED），不等待 |
| 無 `--sequential-group` 參數 | 只使用 skill-level lock，行為與 Sprint 18 完全一致 |

## 鎖檔案命名（ADR-005 決策域二）

```
/tmp/shikigami-group-<project-hash>-<group-name>.lock
```

Group lock 在 skill-level lock 之前取得，確保群組層級的互斥先於 Skill 層級的互斥：

```
1. 嘗試取得 group lock（/tmp/shikigami-group-<hash>-<group>.lock）
   └── 失敗 → SKIPPED（log group lock 被佔用），exit 0
2. 嘗試取得 skill lock（/tmp/shikigami-schedule-<hash>-<skill>.lock）
   └── 失敗 → SKIPPED（log skill lock 被佔用），exit 0
3. 執行 Skill
```

## 使用範例

```bash
# 設定 Planning + Execution 序列排程（同屬 sprint-cycle 群組）
claude -p "/schedule sprint-planning --interval 1h --sequential-group sprint-cycle"
claude -p "/schedule sprint-execution --interval 1h --sequential-group sprint-cycle"

# 兩者不會平行執行：sprint-planning 執行中時，sprint-execution 觸發後會 SKIPPED
```
