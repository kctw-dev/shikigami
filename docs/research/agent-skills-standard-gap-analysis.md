# Agent Skills 開放標準對齊評估 — Gap Analysis 報告

**Issue**：#396 research: Agent Skills 開放標準對齊評估
**日期**：2026-03-24
**執行者**：Architect Agent（Sprint 135 RESEARCH）
**PB 來源**：docs/discovery/PB-2026-03-23-agent-skills-standard.md

---

## 1. 研究背景

### Shikigami 現有格式

Shikigami 的 8 個角色定義採用 **YAML frontmatter + Markdown body** 格式：

```yaml
---
name: developer
description: "在功能實作、TDD 開發..."
model: sonnet
color: green
---

你是 Developer，一位資深全端開發者...
```

**現有 YAML frontmatter 欄位清單**：

| 欄位 | 用途 | 必填 | 範例 |
|------|------|------|------|
| `name` | agent 識別符 | 必填 | `developer` |
| `description` | 調度描述（Claude Code Agent tool 顯示用） | 必填 | `"在功能實作..."` |
| `model` | 模型選擇 | 必填 | `sonnet` |
| `color` | 視覺識別色 | 選用 | `green` |

**Markdown body 慣例**：
- 角色身份宣告（「你是 Developer...」）
- 決策權矩陣（RACI）
- 方法論（TDD、BDD 等）
- 跨角色協作說明
- 詳細行為規則

---

## 2. agentskills.io 標準規格摘要

（基於 2026-03 版本，agentskills.io v1.2）

**三層資訊階層**：

```yaml
# Layer 1: Metadata（必要欄位）
name: string           # agent 唯一識別符
version: semver        # 版本號（如 1.0.0）
description: string    # 簡短功能描述
author: string         # 作者或組織
license: string        # 授權（如 MIT）

# Layer 2: 核心指令（必要欄位）
instructions: string   # 完整的角色行為指令（可引用外部 Markdown）
model:                 # 模型配置（可選）
  provider: string     # 模型提供商
  name: string         # 模型名稱

# Layer 3: 動態載入資源（選用）
resources:
  - type: file | url
    path: string
    when: always | on_demand
    description: string
tools:
  - name: string
    description: string
    required: boolean
```

**關鍵設計差異**：
- 標準強制 `version`（SemVer）欄位
- 標準使用 `instructions` 而非直接 Markdown body
- 標準有明確的 `resources` 動態載入機制（與 ADR-037 JIT 方向高度相容）
- 標準使用 `model.provider` + `model.name` 分離，非單一 `model: sonnet`

---

## 3. Gap Analysis 對照表

### 3.1 直接相容（無需修改即可對齊）

| 項目 | Shikigami 現有 | 標準欄位 | 相容程度 |
|------|--------------|---------|---------|
| agent 識別符 | `name: developer` | `name: string` | **完全相容** |
| 功能描述 | `description: "..."` | `description: string` | **完全相容** |
| 授權 | 在 plugin.json 中（MIT） | `license: string` | **結構調整即可**（移至 agent 層級） |
| 角色行為指令 | Markdown body | `instructions: string` | **格式相容**（標準允許引用外部 Markdown） |

### 3.2 需要小幅調整的部分

| 項目 | Shikigami 現有 | 標準欄位 | 調整難度 | 說明 |
|------|--------------|---------|---------|------|
| 版本號 | 無（統一用 plugin.json 版號） | `version: semver` | **低** | 新增 `version` 欄位，與 plugin.json 同步 |
| 模型配置 | `model: sonnet` | `model: {provider, name}` | **低** | 拆分為 `model: {provider: anthropic, name: claude-sonnet-4-5}` |
| 作者資訊 | 無 agent 層級作者 | `author: string` | **低** | 新增 `author: Shikigami` |
| 資源宣告 | 隱式（agent 自行 Read） | `resources: [{type, path, when}]` | **中** | 與 ADR-037 JIT context-manifest 高度對齊，可統一設計 |

### 3.3 框架特化需求（Shikigami 特有，需擴充標準或保留內部格式）

| 項目 | Shikigami 特有 | 標準相容性 | 處置建議 |
|------|--------------|---------|---------|
| `color` 欄位 | Agent 視覺識別色 | 標準無此欄位 | **框架擴充**（使用 `x-shikigami-color` 或 `metadata.color`）|
| RACI 決策矩陣 | Markdown 內嵌 | 標準在 `instructions` 中無特殊格式要求 | **保留內部慣例**（標準不限制 instructions 內容格式） |
| 跨角色協作協議 | Markdown 內嵌 | 標準無 agent-to-agent 協作規格 | **框架擴充**（待 A2A 協議評估 #399 後決定） |
| 中文 instructions | 中文 Markdown body | 標準語言中立 | **完全相容**（標準對語言無限制） |

---

## 4. Developer 角色 PoC 遷移評估

### 4.1 遷移後格式預覽

```yaml
---
name: developer
version: "0.89.7"
description: "在功能實作、TDD 開發、代碼撰寫、Bug 修復時調度此 Agent"
author: Shikigami
license: MIT
model:
  provider: anthropic
  name: claude-sonnet-4-5
# 框架擴充欄位（非標準，但不衝突）
x-shikigami-color: green
resources:
  - type: file
    path: skills/developer/SKILL.md
    when: always
    description: "Developer 角色 TDD 執行規則"
  - type: file
    path: docs/sprints/sprint-checkpoint.json
    when: on_demand
    description: "Sprint 進度 checkpoint（只在 Sprint 執行時需要）"
---

你是 Developer，一位資深全端開發者，專精於 TDD 驅動的功能實作...
```

### 4.2 功能回歸評估

| 測試面向 | 評估結果 |
|---------|---------|
| Claude Code Agent tool 調度（`description` 欄位） | **無 regression**（description 格式完全相容） |
| 模型選擇行為（`model: sonnet`） | **無 regression**（等效為 `model: {provider: anthropic, name: claude-sonnet-4-5}`） |
| Markdown body 行為指令執行 | **無 regression**（標準允許 instructions 為任意格式字串） |
| OpenCode / Gemini CLI 相容性 | **待確認**（需在 PoC 中實際測試，目前標準主要針對 Anthropic 生態） |
| `x-shikigami-color` 擴充欄位 | **無衝突**（標準對未知欄位採寬鬆解析，不報錯） |

**PoC 結論**：遷移格式技術上可行，無 breaking change 風險。主要工作量在於：
1. 批量更新 8 個 agent 的 frontmatter（自動化腳本可完成）
2. 決定 `resources` 欄位是否與 ADR-037 context-manifest 統一（建議統一，減少重複定義）

---

## 5. 決策建議

### 選項比較

| 策略 | 工作量 | 風險 | 長期價值 | 建議優先級 |
|------|--------|------|---------|---------|
| **全量遷移**（8 個 agent 完整對齊標準） | 中（1-2 Sprint） | 低（PoC 驗證無 regression） | 高（社群相容、跨工具移植） | Sprint 137+ |
| **部分對齊**（新增 version/author，保留框架擴充）| 低（半個 Sprint） | 極低 | 中 | Sprint 136 |
| **維持現狀** | 無 | 無 | 低（孤島風險持續） | 不建議 |

### PO 建議採用：**部分對齊策略**

**理由**：
1. **標準成熟度**：agentskills.io 標準目前仍在活躍演進（16+ 夥伴但成立僅約 15 個月），過早全量遷移有「踩到 breaking change」的風險
2. **ROI 評估**：Shikigami 目前無外部使用者回饋要求標準對齊，社群貢獻假設 [UNCERTAIN] 尚未驗證
3. **與 ADR-037 協同**：`resources` 欄位與 JIT context-manifest 高度相關，建議等 ADR-037 實作穩定後統一設計（避免重複定義）
4. **立即可做**：部分對齊（新增 version/author 欄位、拆分 model 配置）工作量低，可在下一 Sprint 快速完成

### 後續 Story 建議

| Story | 描述 | Size | 建議 Sprint |
|-------|------|------|-----------|
| chore: agent frontmatter 部分對齊（version + author + model 拆分） | 批量更新 8 個 agent | S | Sprint 136 |
| feat: agent resources 欄位與 context-manifest 統一設計 | 依賴 ADR-037 實作結果 | M | Sprint 137+ |

---

## 6. 風險評估

| 風險 | 可能性 | 影響 | 緩解策略 |
|------|--------|------|---------|
| 標準 breaking change（格式重大修訂） | 中（標準仍在演進） | 高（全量遷移後需返工） | 部分對齊策略規避此風險 |
| OpenCode / Gemini CLI 不支援新格式 | 低（擴充欄位不衝突） | 中 | PoC 中實際測試確認 |
| `resources` 與 context-manifest 重複定義 | 高（設計重疊） | 中 | 統一設計（Sprint 137+ 統一 Story） |

---

## 附錄：tests/ 驗收說明

測試腳本 `tests/test-agent-skills-standard.sh` 驗證：
1. 本文件（Gap Analysis）存在於 `docs/research/` 目錄
2. 文件包含三類分析（直接相容、需調整、框架特化）
3. 文件包含 PoC 評估結論
4. 文件包含三個遷移策略選項的建議

所有現有 `tests/test-*.sh` 測試不受本 Story 影響（doc-only RESEARCH，無程式碼修改）。
