# Retro-Action 連續未完成自動觸發 Grooming

> 此文件定義：當同一個 `retro-action` Issue 連續多個 Sprint 排入但未完成時，自動觸發 Backlog Grooming 重評估的偵測規則與處置流程。
>
> 來源：Sprint 126 Retrospective — Action Item #4（#493）
> 觸發案例：#452（連續 5 Sprint 排入但未完成）

---

## 1. 偵測規則（AC1）

### 1.1 偵測目標

掃描帶有 `retro-action` label 且狀態為 **open** 的 GitHub Issues。

```bash
gh issue list \
  --label "retro-action" \
  --state open \
  --json number,title,labels,milestone \
  --limit 100
```

### 1.2 連續未完成定義

**連續未完成**：同一個 `retro-action` Issue 在**連續 2 個**（含）以上 Sprint 中均排入 Sprint Backlog（具有 `status: in-sprint` label 或對應 Sprint milestone），但每次 Sprint 結束時 Issue 仍為 open 狀態。

| 情境 | 判定 |
|------|------|
| Sprint N 排入，Sprint N 結束後關閉 | 正常完成，不觸發 |
| Sprint N 排入未完成，Sprint N+1 排入完成 | 連續 1 Sprint 未完成，不觸發 |
| Sprint N 排入未完成，Sprint N+1 排入未完成 | **連續 2 Sprint 未完成，觸發** |
| Sprint N 排入未完成，Sprint N+1 未排入，Sprint N+2 排入未完成 | 中斷，重新計算，不觸發 |

> **閾值：連續 2 個 Sprint 排入但未完成** → 觸發 Grooming 重評估。

### 1.3 偵測方式

在 Sprint Review §4（Action Items 驗收機制）執行期間，對每個 open 的 `retro-action` Issue 執行以下判定：

1. 讀取 Issue 的 milestone 歷史（透過 GitHub API）
2. 取最近 3 個 Sprint 的 milestone 記錄
3. 計算連續排入且未完成的 Sprint 數量
4. 若連續數量 ≥ 2，觸發 `[RETRO-GROOMING-TRIGGER]`

**簡化判定（無法取得完整 milestone 歷史時的回退方案）**：

若 Issue 具有 `deferred` label 且建立日期距今超過 2 個 Sprint 週期（約 14 天），視為「可能連續未完成」，輸出警示並建議人工確認。

---

## 2. 觸發告警格式

偵測到連續未完成時，輸出以下格式的機器可解析告警：

```
[RETRO-GROOMING-TRIGGER] Issue #N 連續 M 個 Sprint 排入但未完成，觸發 Backlog Grooming 重評估。

Issue：#N — {標題}
連續 Sprint 數：M（Sprint X, Sprint X+1, ...）
建議處置：{見 §3}
```

---

## 3. 處置選項（Grooming 重評估）

偵測到 `[RETRO-GROOMING-TRIGGER]` 後，在下一次 Sprint Planning 中執行 Backlog Grooming，處置選項如下：

| 選項 | 適用情境 | 動作 |
|------|---------|------|
| **升級 priority** | Issue 重要但因容量不足持續延遲 | 將 label 從 `priority: should` 升為 `priority: must`，強制排入下一 Sprint |
| **強制排入** | Issue 已是 `priority: must` 但仍未完成 | 在 Sprint Planning 中作為 Hard Gate，不得因容量問題跳過 |
| **拆分 Story** | Issue 過大導致無法在一個 Sprint 完成 | 與 PO 協商拆分為更小的子 Issue，各自排入 Sprint |
| **關閉並記錄** | Issue 已不再相關或已被其他方式解決 | 加 `wont-fix` label 並關閉，在 Retro Log 記錄原因 |

---

## 4. 觸發案例：#452

**Issue #452** 為本機制的設計觸發案例：

- 狀態：`retro-action` label，連續多個 Sprint 排入但未完成
- 歷史：Sprint 121–125 均排入，每次 Sprint 結束後仍 open
- 本機制實施後，#452 應在 Sprint Review 中觸發 `[RETRO-GROOMING-TRIGGER]`
- 建議處置：執行 Grooming 重評估，選擇「強制排入」或「拆分 Story」

---

## 5. Sprint Review 整合點

本偵測邏輯整合至 **Sprint Review §4 Action Items 驗收機制**：

```
§4 原有文字：
  每次 Sprint Review 前逐項確認：完成 → close；未完成 → deferred label；
  連續兩 Sprint open → 升級 Stakeholder。

§4 新增（#493）：
  連續兩 Sprint open 的 retro-action Issue → 同時觸發 [RETRO-GROOMING-TRIGGER]，
  在下次 Sprint Planning 中執行 Backlog Grooming 重評估（詳見本文件）。
```

---

## 6. Sprint Planning 整合點

Sprint Planning PO Round 1 在 Backlog 掃描時，**必須**優先處理帶有 `[RETRO-GROOMING-TRIGGER]` 的 Issues：

1. 掃描是否有 `retro-action` Issues 觸發了 Grooming 告警
2. 對每個觸發告警的 Issue，執行 §3 處置選項中的一項
3. 處置結果記錄於 Sprint Planning 會議紀錄

```bash
# Sprint Planning 掃描指令（PO Round 1 前執行）
gh issue list \
  --label "retro-action" \
  --label "deferred" \
  --state open \
  --json number,title,labels \
  --limit 50
```
