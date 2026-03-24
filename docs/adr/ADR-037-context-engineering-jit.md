# ADR-037：Context Engineering — Just-in-Time Retrieval 架構決策

**日期**：2026-03-24
**狀態**：Accepted
**相關 Issue**：#602（ADR RESEARCH）、#400（feat: Context Engineering JIT Retrieval）
**提案者**：Architect Agent（Sprint 135 ADR RESEARCH）
**關聯 ADR**：ADR-007（Story-Lifecycle Subagent）、ADR-026（Cruise Mode）

---

## 背景

### 問題陳述

Shikigami 各 agent 在 session 啟動時透過 `session-start` hook 預先注入大量 context（SKILL.md、ADR、Sprint 紀錄等），這種「全量預載」策略造成：

1. **Context rot**：Token window 被非即時相關內容佔據，模型對關鍵指令的注意力品質下降
2. **成本浪費**：每次呼叫都攜帶本次任務不需要的背景知識，token 消耗不成比例
3. **更新滯後**：預載的文件快照可能已過期，agent 仍依賴舊版內容做決策
4. **可觀測性差**：無法知道 agent 實際「讀了哪些」context，難以優化

Anthropic 官方 Context Engineering 文章明確指出：給模型「剛好夠用的資訊、在剛好需要的時機」才能維持高品質輸出。

### 決策需求

選定 JIT context 載入機制，確立 session-start hook 注入策略與 fallback 行為。

---

## 選項比較

### 方向 A：Agent Context Manifest（context-manifest.yaml）

為每個 agent 定義 `context-manifest.yaml`，列舉可能需要的資源路徑與觸發條件。任務開始時依條件 lazy load。

| 維度 | 評估 |
|------|------|
| **載入精準度** | 高（依條件精確載入） |
| **維護成本** | 高（每個 agent 需維護 manifest，隨文件變動快速過期） |
| **實作複雜度** | 高（需新格式、新解析邏輯） |
| **Shikigami 整合** | 需修改 agent 定義結構（侵入性高） |
| **回退機制** | 需額外設計 |

**優點**：最精確的 context 控制，細粒度 always/on-demand 分類
**缺點**：維護負擔高，manifest 本身可能成為 stale 資訊源

---

### 方向 B：SKILL.md 內嵌 JIT 標記

在 SKILL.md 中標記哪些區段是「執行時必讀」，哪些是「參考備查」。Agent 按標記決定是否預載。

| 維度 | 評估 |
|------|------|
| **載入精準度** | 中（依段落標記，不依任務動態調整） |
| **維護成本** | 中（修改 SKILL.md 格式，需統一 29 個 Skill）|
| **實作複雜度** | 中（需定義標記語法與解析規則） |
| **Shikigami 整合** | 中（修改 Skill Schema，但與現有 Markdown 結構兼容） |
| **回退機制** | 自然回退（標記缺失則使用預設全量載入） |

**優點**：與現有 SKILL.md 文件結構緊密結合
**缺點**：需修改全部 29 個 Skill 的格式，範圍大，引入 regression 風險高

---

### 方向 C：Read-on-Demand Hook（session-start 路徑清單）

session-start hook 只注入「路徑清單」（輕量引用索引），agent 在執行具體任務前自行呼叫 Read 工具載入必要文件。

| 維度 | 評估 |
|------|------|
| **載入精準度** | 中（agent 依任務語義自主判斷需讀哪些文件） |
| **維護成本** | 低（路徑清單比 manifest 輕量，只需列出資源路徑）|
| **實作複雜度** | 低（修改 session-start hook 注入內容，不改 Skill 格式）|
| **Shikigami 整合** | 低侵入性（不改 agent 定義，只改 hook 行為）|
| **回退機制** | 自然回退（路徑清單不存在時退回全量預載）|
| **現有能力支援** | agent 已有能力自主呼叫 Read 工具 ✓ |

**優點**：最低侵入性，快速驗證假設，不改 Skill/Agent 格式
**缺點**：agent 可能誤判「不需要載入」，遺漏關鍵 context

---

## 決策

**選擇方向 C（Read-on-Demand Hook）**，作為 Phase 1 實作，驗證假設後視結果決定是否推進方向 A 或 B。

### 理由

1. **最低侵入性原則**：方向 C 只修改 `hooks/session-start/` 的注入內容，不改動 29 個 Skill 和 8 個 Agent 的定義格式。對現有框架行為的影響面最小，可快速上線驗證。

2. **現有能力完全支援**：Shikigami agent 已具備自主呼叫 Read 工具的能力，Read-on-Demand 不需要新增任何基礎設施，直接可用。

3. **漸進式驗證策略**：方向 C 是最小可行改動（MVP），可在一個 Sprint 內完成並量測效果。若效果顯著（input token 降低 20%+、品質不下降），再投資方向 A 的精確化；若效果不明顯，代表問題不在 context 載入策略。

4. **方向 A 的維護成本風險**：context-manifest.yaml 本身需要人工維護，若 Skill/Agent 頻繁更新但 manifest 未同步，會製造新的 stale 資訊源，違背 JIT 的初衷。

5. **方向 B 的範圍風險**：修改全部 29 個 Skill 的格式是高風險操作，容易引入 regression，且需要多個 Sprint 才能完成，不適合作為初始方向。

### Graceful Fallback 策略（AC5 對應）

實作 `context-manifest` 機制時，**必須**設計以下 fallback 鏈：

```
1. context-manifest 路徑清單存在 → JIT 模式（agent 按清單 Read 所需文件）
2. context-manifest 路徑清單不存在 → 退回全量預載模式（現有行為，不中斷執行）
3. JIT 模式下 Read 失敗（文件不存在）→ 靜默跳過，繼續執行（不阻塞）
```

此 fallback 確保 JIT 機制失敗不影響 agent 正常工作能力。

---

## 實作方向（for #400）

### Phase 1 實作範圍

```
hooks/session-start/
├── context-manifest.yaml        # 新增（路徑清單，列出 always/on-demand 資源）
└── inject-context.sh            # 修改（只注入路徑清單，不全量載入）

# Context Manifest 格式（方向 C 輕量版）
always:
  - path: agents/{role}.md
    reason: "角色定義，每次 session 必讀"
on_demand:
  - path: docs/sprints/sprint_N.md
    reason: "Sprint 詳情，執行 sprint 任務時才需要"
  - path: docs/adr/*.md
    reason: "ADR，架構決策討論時才需要"
```

### 驗收重點（#400 AC）

- AC1：session-start hook 只注入路徑清單，不全量預載所有 SKILL.md
- AC2：至少 1 個 agent 有對應 context-manifest.yaml（列出 always/on-demand 兩類資源）
- AC3：`tests/test-context-engineering.sh` 驗證 manifest 格式正確，路徑存在
- AC4：此 ADR 文件狀態為 Accepted，#400 留言確認已參照
- AC5：context-manifest 指向路徑不存在時，退回全量預載模式，不中斷執行

---

## 影響

### 需要更新的文件

| 文件 | 更新內容 |
|------|---------|
| `hooks/session-start/` | 修改 hook 注入行為（只注入路徑清單） |
| `agents/{role}.md`（至少 1 個）| 新增對應 context-manifest.yaml |
| `tests/test-context-engineering.sh` | 新建，驗證 manifest 格式與路徑存在性 |

### 不影響的文件

- 所有 `skills/*/SKILL.md`（不修改 Skill 格式，方向 C 的核心優勢）
- 所有 `agents/*.md` 的現有定義結構（只新增 manifest，不修改現有格式）

### 後續演進路線

| Phase | 內容 | 觸發條件 |
|-------|------|---------|
| Phase 1（本 ADR） | 方向 C：Read-on-Demand Hook | 立即實作 |
| Phase 2（待定） | 方向 A：精確化 context-manifest | Phase 1 量測 input token 降低 20%+ 且品質不下降 |
| Phase 3（待定） | 方向 B：SKILL.md 標記整合 | Phase 2 驗證後，若需要更細粒度控制 |

---

## 替代方案被拒理由

- **方向 A（Context Manifest 完整版）**：維護成本高，manifest 過期風險；保留為 Phase 2 候選
- **方向 B（SKILL.md 標記）**：修改範圍過大（29 個 Skill），regression 風險高；保留為 Phase 3 候選

---

## 狀態追蹤

- [x] ADR 草稿完成（2026-03-24）
- [x] Architect 技術評估（Sprint 135 ADR RESEARCH #602）
- [x] ADR Accepted（2026-03-24，解除 #400 Hard Gate）
- [ ] #400 實作完成（Sprint 135 Batch 2）
