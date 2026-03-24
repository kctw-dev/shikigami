# 複雜度預算機制（#462）

## 背景

Sprint 121–123 連續三個 Sprint 出現「框架過於複雜」的 Retro Problem。為防止框架無限膨脹，建立量化的複雜度預算機制，在 Sprint Planning 時強制評估新增功能對整體複雜度的影響。

## 度量指標

| 指標 | 說明 | 預設門檻 | 環境變數覆蓋 |
|------|------|---------|-------------|
| `SKILL_COUNT` | `skills/` 子目錄數量 | 40 | `COMPLEXITY_SKILL_BUDGET` |
| `AGENT_COUNT` | `agents/*.md` 數量 | 15 | `COMPLEXITY_AGENT_BUDGET` |
| `HOOK_COUNT` | `hooks/**/*.sh` 數量 | 35 | `COMPLEXITY_HOOK_BUDGET` |
| `TOTAL_LINES` | SKILL.md + Agent + Hook 總行數 | 25000 | `COMPLEXITY_LINES_BUDGET` |

## 度量腳本

```bash
# 輸出當前基線
bash scripts/measure-complexity.sh

# 與基線比較（PR 複雜度變化報告）
bash scripts/measure-complexity.sh --diff docs/complexity-baseline.txt

# 超出門檻時輸出 WARNING（stderr），exit 0 不阻塞流程
COMPLEXITY_SKILL_BUDGET=30 bash scripts/measure-complexity.sh
```

## Sprint Planning 執行步驟（#462 AC3）

1. Sprint Planning 開始時，執行 `bash scripts/measure-complexity.sh` 取得當前複雜度基線
2. 對每個新增 Skill/Agent 的 Story，評估對 `SKILL_COUNT`/`AGENT_COUNT` 的影響
3. 若新功能會導致某指標超出預算門檻，**必須**同步評估刪減等量舊功能（Replace, not Add）
4. Sprint Planning 結束時，記錄當次複雜度數值至 Sprint 文件

## PR 複雜度變化報告（#462 AC4）

每個新增功能 PR 的 description 應包含：

```
## 複雜度變化
SKILL_COUNT: +N / -M（當前 X，門檻 40）
AGENT_COUNT: ±0（當前 Y，門檻 15）
HOOK_COUNT:  +N（當前 Z，門檻 35）
TOTAL_LINES: +N（當前 W，門檻 25000）
```

可用 `bash scripts/measure-complexity.sh --diff <baseline>` 自動產生此報告。

## 向後相容保證

- 腳本不修改任何現有 Skill/Agent/Hook 定義
- 超出門檻僅輸出 WARNING，不阻塞 CI（exit 0）
- 現有框架結構（29 Skills / 8 Agents / 21 Hooks）均在預設門檻內
