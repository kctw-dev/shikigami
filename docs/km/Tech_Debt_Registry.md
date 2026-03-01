# Tech Debt Registry

## 概述

Tech Debt Registry 是跨 Sprint 追蹤技術債的標準化紀錄文件。每筆條目記錄技術債的來源、影響範圍、嚴重度及解決狀態，使團隊能夠在 Sprint Planning 前做出資料驅動的決策，避免技術債累積侵蝕系統品質。

---

## 欄位定義

| 欄位 | 說明 |
|------|------|
| **ID** | 唯一識別碼，格式為 `TD-XXX`（三位數流水號） |
| **描述** | 技術債的具體說明，包含問題所在位置與影響 |
| **引入 Story** | 產生此技術債的 User Story ID（格式：`US-XX`） |
| **解決 Story** | 預計或已解決此技術債的 User Story ID（未排入則填 `TBD`） |
| **嚴重度** | `H`（高）/ `M`（中）/ `L`（低），定義見下方嚴重度基準 |
| **建議解法** | 解決此技術債的具體行動方案或方向 |
| **RICE** | 優先級分數 = (Reach × Impact × Confidence) ÷ Effort，用於排序解決順序 |
| **狀態** | `Active`（未解決）/ `Resolved`（已解決）/ `Accepted`（已知悉，暫不處理） |

### 嚴重度基準

| 嚴重度 | 定義 |
|--------|------|
| **H（高）** | 直接影響生產穩定性、安全性或阻礙後續開發 |
| **M（中）** | 降低開發效率或代碼可維護性，但系統可正常運行 |
| **L（低）** | 輕微的代碼品質問題，短期影響有限 |

---

## 趨勢判定規則

Grooming 完成後，依照以下規則計算本次 Active 條目趨勢：

| 情況 | 趨勢標籤 |
|------|----------|
| 前兩次 Grooming 資料不足（少於 2 次歷史紀錄） | **資料不足** |
| 連續 2 次 Grooming Active 條目總數增加 | **增加中** |
| 連續 2 次 Grooming Active 條目總數減少 | **減少中** |
| Active 條目總數未變動（含持平波動） | **穩定** |

> 趨勢判定以「連續 2 次 Grooming 的 Active 總數差值」為依據。單次變動不足以判定趨勢，需連續兩次同向變動才能標記「增加中」或「減少中」。

---

## Registry 表格

| ID | 描述 | 引入 Story | 解決 Story | 嚴重度 | 建議解法 | RICE | 狀態 |
|----|------|------------|------------|--------|----------|------|------|
| TD-001 | [EXAMPLE] 使用者認證模組缺乏單元測試覆蓋，目前依賴端對端測試，重構風險高 | US-03 | TBD | H | 補充 unit test，覆蓋所有認證路徑與邊界條件；目標覆蓋率 > 80% | 7.5 | Active |

---

## Grooming 歷史紀錄

> 每次 Tech Debt Grooming（於 Sprint Planning 前執行）記錄一筆，格式如下。

### 範例格式

```
### Grooming #N — YYYY-MM-DD（Sprint S-XX 前）

**Active 條目**：X 筆
**Resolved 條目**：Y 筆（本次新增 Z 筆解決）
**本次變化量**：相對上次 Grooming Active 總數差值（+N / -N / 0）
**趨勢判定**：增加中 / 減少中 / 穩定 / 資料不足

#### Active 條目清單
- TD-XXX：{描述摘要}（嚴重度：H/M/L）

#### 本次解決條目
- TD-XXX：{描述摘要}（由 US-XX 解決）

#### 逾期未解決警示（Active 超過 3 個 Sprint 未排入解決 Story）
- TD-XXX：已 Active {N} 個 Sprint，建議本 Sprint Planning 強制排入
```

---

## 維護指引

1. **新增條目**：Developer 在 DoD 自檢時，若有取捷徑情況，依 `[TECH-DEBT]` 標記格式（見 `skills/sprint-execution/developer-prompt.md` 的 Tech Debt 區段）記錄，並於當次 Sprint 結束前新增至本 Registry。
2. **更新狀態**：當某 Story 解決了對應的技術債，Developer 需更新條目狀態為 `Resolved` 並填入「解決 Story」。
3. **Grooming 觸發**：每次 Sprint Planning 開始前，由 Scrum Master 主持 Tech Debt Review，掃描所有 Active 條目並標記逾期未解決項目。
