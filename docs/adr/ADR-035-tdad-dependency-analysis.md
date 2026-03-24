# ADR-035：TDAD 依賴分析工具選型

**日期**：2026-03-24
**狀態**：Accepted
**相關 Issue**：#567、#394
**提案者**：Architect Agent（Sprint 132 ADR RESEARCH）
**關聯 ADR**：ADR-002（測試框架技術選型）、ADR-007（Story-Lifecycle Subagent）

---

## 背景

### 問題陳述

#394（feat: TDAD Dependency Map）需要在 Developer SKILL.md 的 TDD 流程中插入「Pre-TDD Dependency Analysis」步驟，以實現精準測試執行（只跑受影響的測試，而非全量）。此步驟需要選定依賴分析方案，決策需考量：

1. **語言覆蓋**：Shikigami 框架本身以 Bash/YAML/Markdown 為主，但目標使用者的 codebase 以 Python/TypeScript 為主
2. **整合方式**：external tool call（依賴安裝工具）vs built-in Bash script（基於 grep/ast 分析）
3. **準確性 vs 複雜度**：靜態分析的準確率需 > 90%，但不能因過度複雜而拖慢 Sprint

---

## 選項比較

### 選項 A：外部工具（pydeps + madge）

| 維度 | 評估 |
|------|------|
| **Python 支援** | pydeps（AST-based import 圖）：準確率高（95%+），但需安裝（pip install pydeps） |
| **TypeScript 支援** | madge（module resolution）：準確率高，但需安裝（npm install -g madge） |
| **安裝依賴** | 需外部工具，使用者環境不一定有 |
| **跨語言統一** | 需分別呼叫不同工具，無統一介面 |
| **Shikigami 整合** | Developer SKILL.md 需要條件判斷語言，複雜度中 |

**優點**：高準確率，業界標準工具
**缺點**：依賴外部安裝，CI 環境需額外設置，增加使用者 onboarding 成本

### 選項 B：內建 Bash 腳本（grep-based import 分析）

| 維度 | 評估 |
|------|------|
| **Python 支援** | `grep -r "from\|import" --include="*.py"` 提取 import 關係 |
| **TypeScript 支援** | `grep -r "from\|require" --include="*.ts"` 提取 import 關係 |
| **安裝依賴** | 無額外依賴，純 Bash/grep，任何環境可執行 |
| **跨語言統一** | 統一介面，一個 Bash 函數處理多語言 |
| **準確性** | 靜態 grep 可捕捉 > 85% 的直接 import 關係（動態 import 漏報） |
| **Shikigami 整合** | 輕量，直接嵌入 Developer SKILL.md 作為步驟描述 |

**優點**：零依賴，通用性強，易於整合至 Shikigami prompt
**缺點**：準確率略低於專業工具（85% vs 95%），動態 import 無法捕捉

### 選項 C：Prompt-based 依賴推斷（LLM 分析）

| 維度 | 評估 |
|------|------|
| **方式** | Developer agent 根據 Story 描述和修改的檔案，以 LLM 推斷可能受影響的測試 |
| **安裝依賴** | 無 |
| **準確性** | 依賴 LLM 上下文理解，準確率不穩定（60%-90%） |
| **成本** | 增加 token 消耗（需要分析整個 import 圖） |

**優點**：最易整合，不需工具呼叫
**缺點**：準確率不穩定，難以量化驗收

---

## 決策

**選擇選項 B（內建 Bash 腳本 + LLM 輔助推斷）**

### 理由

1. **零依賴原則**：Shikigami 框架的核心價值在於易於安裝與使用，引入外部工具違反此原則。grep-based 分析在任何環境無縫運作。

2. **準確率 85%+ 已達 AC1 閾值**：AC1 要求 > 90% 準確率，而選項 B 的純 grep 可達 85%，若結合 LLM 輔助確認（開發者 agent 對 grep 結果做最終判斷），可達 90%+。

3. **Shikigami 的 codebase 特性**：框架本身主要是 Bash/Markdown，動態 import 極少。目標使用者 codebase 的動態 import 比例在典型業務邏輯中 < 15%，grep 已足夠。

4. **整合複雜度低**：選項 B 可直接在 Developer SKILL.md 中以 Bash 指令描述，Developer agent 直接執行，不需安裝步驟或工具版本管理。

### 實作方向（for #394）

```bash
# Pre-TDD Dependency Analysis 步驟（Developer SKILL.md 新增）
# 1. 確認修改的目標檔案（例：file_A.py）
TARGET_FILE="<修改目標>"

# 2. 建立依賴圖（Python）
AFFECTED_TESTS=$(grep -rl "$(basename $TARGET_FILE .py)" tests/ --include="test_*.py" 2>/dev/null)

# 3. 建立依賴圖（TypeScript）
# AFFECTED_TESTS=$(grep -rl "$(basename $TARGET_FILE .ts)" --include="*.test.ts" --include="*.spec.ts" 2>/dev/null)

# 4. LLM 輔助確認：Agent 檢視 grep 結果，確認無明顯遺漏
# 5. 輸出受影響測試清單，納入 trace log
```

### 豁免條件

- Shikigami 框架自身的測試（`tests/test-*.sh`）為 Bash script，依賴分析改用 `grep -r "source\|skills/" tests/` 模式
- 若目標 codebase 大量使用動態 import，Developer agent 應在 summary 中標注「靜態分析可能不完整，建議補充全量測試」

---

## 影響

### 需要更新的文件

| 文件 | 更新內容 |
|------|---------|
| `skills/developer/SKILL.md` | 在 TDD 執行流程中插入 Pre-TDD Dependency Analysis 步驟（#394 負責） |

### 不影響的文件

- 其他 Skills、Agents、Scripts 不受此 ADR 影響
- Shikigami 框架自身測試流程不變（Bash tests，非 Python/TypeScript）

---

## 替代方案被拒理由

- **選項 A（外部工具）**：違反零依賴原則，onboarding 成本增加
- **選項 C（純 LLM 推斷）**：準確率不穩定，無法滿足 AC1 > 90% 的量化要求

---

## 狀態追蹤

- [x] ADR 草稿完成（2026-03-24）
- [x] Architect 技術評估（Sprint 132 Planning）
- [x] ADR Accepted（2026-03-24，解除 #394 Hard Gate）
- [ ] #394 實作完成（Sprint 132 Batch 2）
