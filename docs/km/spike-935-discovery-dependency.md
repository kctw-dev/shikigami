# Spike Report: Discovery/RESEARCH Story 序列依賴優化

## 背景

**觸發時機**：Sprint 174 Retro（2026-03-26）

**關鍵發現**：spike-887 已完成增量 Discovery 流程設計（Sprint 174 #887），輸出成果高效可行（50 分鐘 SOP，0.5pt），但在實踐中仍存在序列依賴瓶頸。本 Spike 基於 spike-887 結論，聚焦**未解決的序列依賴問題**，識別並優化不必要的依賴。

**基線**：[spike-887-discovery-optimization.md](spike-887-discovery-optimization.md) — 增量 Discovery 流程設計的成功實踐（Sprint 174 #919, #887 均已交付）

---

## 調查範圍

**分析時段**：Sprint 171–174（4 個 Sprint）

**聚焦維度**：
1. Discovery/RESEARCH Story 的序列依賴案例
2. Story 之間的前置關係（data dependency、process dependency）
3. 平行化可能性與解耦機會

---

## 分析結果

### 案例一：#887 依賴 #919 的數據前置

**現象**：Sprint 174 中，#887（Backlog Discovery 流程最佳化 — RESEARCH Story）排期於 Phase 2，依賴 #919（Backlog Discovery 補充 — DISCOVERY Story）完成後的 sprint-candidate 水位資料。

**根本原因**：
- #919 執行增量 Discovery，產出 8 個新 sprint-candidates（#923–#930）
- #887 需要分析「實際 Discovery 執行後的水位狀態」來驗證 spike-887 設計的實效
- 雙方無法完全平行，#887 需等待 #919 提供「before/after 水位」數據

**序列依賴類型**：**數據前置依賴**

**Sprint 174 排序**：
```
Batch 1（並行）：#919 + #922
  ↓ （等待 #919 完成）
Phase 2（順序）：#887
Batch 2（獨立）：#872
```

**實際耗時**：
- #919：S(1pt) ≈ 30 分鐘（DISCOVERY，直接 commit）
- #922：S(1pt) ≈ 20 分鐘（INFRA，無依賴）
- #887：S(1pt) ≈ 30 分鐘（RESEARCH，依賴數據，實際需等待）
- 瓶頸：Batch 1 完成 → #887 啟動，總耗時延長 20+ 分鐘

**優化建議**（見方案 B）：#887 可產出「預期分析 + 條件化驗證」，無需強制等待

---

### 案例二：Retro Action 轉化的 RESEARCH Story 序列依賴

**現象**（假設場景）：若要評估「增量 Discovery 執行頻率對 Backlog 健康度的影響」，需先完成 1-2 次增量 Discovery 並積累歷史數據。

**根本原因**：
- RESEARCH Story（如 #887）通常需要**足夠的真實數據樣本**來驗證假設
- 不能靠單次執行判斷，需要多 Sprint 的觀測資料
- 導致 RESEARCH Story 無法在初次提出時立即執行

**序列依賴類型**：**觀測數據前置依賴**

**風險**：RESEARCH Story 因資料不足而被迫延後，形成「決策阻塞」

**優化建議**（見方案 A）：分階段設計 RESEARCH，先驗證「第一階段假設」，後續根據數據迭代

---

### 案例三：ADR 審查的隱性序列依賴

**背景**（Sprint 172–173）：
- Sprint 172 #882（Backlog Health 自動告警）涉及 GitHub Actions workflow 修改
- Sprint 173 #886（驗證腳本整合測試補齊）涉及測試框架擴充
- 兩個 Story 無顯式依賴，但都涉及基礎設施（CI/測試框架），若執行順序不當可能引發隱性衝突

**根本原因**：
- **隱性架構依賴**：無 ADR 標注的基礎設施 Story，缺乏明確的「影響分析」
- 串聯執行（#882 → #886）時，後執行者需要確認前置修改不會破壞自己的環境
- Sprint Planning 沒有對「基礎設施 Story 的執行順序」做出結構化決策

**序列依賴類型**：**隱性架構依賴**（無 ADR）

**Sprint 172 實際排序**（技術評估中）：
```
Group A（順序）：#907 → #908（同檔案修改，強制序列）
Group B（並行聲稱）：#882, #895, #894（但 #882 涉及 CI，隱性影響）
```

**優化建議**（見方案 A）：建立「基礎設施 Story 依賴矩陣」

---

### 案例四：Feature/Retro Action 的可平行化機會

**現象**（Sprint 171–173）：
- Sprint 171：6 個 Story，分 3 個 Group，其中 Group A（#899, #900）和 Group B（#874, #869, #876）標記「可平行」
- 實際**資料依賴分析**：
  - #899（NFR 補充）：編輯 3 個 Issue body，純 Issue 操作，無文件交叉引用
  - #900（文件新建）：新建 `docs/guides/script-testability-guide.md`，不涉及代碼
  - #874、#869、#876：新建 3 個不同的腳本檔案，零交集

**結論**：標記「可平行」但**實際依賴分析不足**，沒有明確列出「為何可平行」的依賴證據

**優化建議**（見方案 A）：強制記錄「平行決策的依賴證據」

---

## 優化方案

### 方案 A：結構化依賴管理 — 引入顯式依賴矩陣

**核心理念**：在 Sprint Planning 與 Backlog Grooming 中引入結構化的「依賴分析文件」，提前識別並可視化序列依賴，避免隱性阻塞。

#### 實施步驟

1. **新建 `docs/specs/story-dependency-matrix.md`**（每 Sprint 更新一次）
   
   ```markdown
   # Story 依賴矩陣 — Sprint N
   
   ## 依賴類型定義
   
   | 類型 | 說明 | 可平行 | 備註 |
   |------|------|-------|------|
   | **None** | 無依賴 | ✓ | 可完全平行執行 |
   | **Data** | B 需要 A 的輸出數據 | ✗ | 必須 A→B 順序 |
   | **File** | 同檔案編輯衝突 | ✗ | 必須 A→B 順序 |
   | **Process** | B 邏輯依賴 A 的完成信號 | ✗ | 必須 A→B 順序 |
   | **Architecture** | 隱性架構依賴（如 CI 修改） | △ | 需評估風險，可考慮解耦 |
   | **Knowledge** | B 需要 A 的知識產出 | △ | 可並行開發，串聯評審 |
   
   ## Sprint N Backlog 依賴矩陣
   
   | Story A | Story B | 依賴類型 | 理由 | 建議 |
   |---------|---------|---------|------|------|
   | #919 | #887 | Data | #887 需要 #919 的 sprint-candidate 水位 | 見「方案 B：條件化驗證」 |
   | #907 | #908 | File | 同修改 `docs/guides/script-testability-guide.md` | 保持序列 |
   | #882 | #886 | Architecture | #882 CI workflow 修改可能影響 #886 測試框架 | 風險評估後可並行 |
   | #874 | #869 | None | 不同腳本，無交集 | 平行執行 |
   | #919 | #922 | None | 不同檔案修改 | 平行執行 |
   
   ## 平行策略決策
   
   - **Group A（順序）**：#907 → #908（文件衝突）
   - **Group B（可並行）**：#882 + #886（架構依賴，評估風險後可容納）
   - **Group C（可並行）**：#874 + #869 + #876（零交集）
   ```

2. **Sprint Planning 時強制執行依賴矩陣檢查**
   - Architect 在技術評估後（AC2.1），補充 `story-dependency-matrix.md`
   - 列出 Sprint Backlog 中所有 2 Story 對，分析依賴關係
   - 對 `Architecture` 類型的依賴，標注「風險評估結論」

3. **Backlog Grooming 時應用**
   - 新 Issue 開立時，PO 必須記錄其依賴的既有 Story
   - 依賴矩陣成為 RICE 評分的參考（高依賴的 Story 優先級可上調）

#### Trade-off

| 優點 | 缺點 |
|------|------|
| 提前識別所有序列依賴，避免 Sprint 中途發現 | 增加 Planning 工作量（+5 分鐘依賴檢查） |
| 可視化平行機會，提高資源利用率 | 矩陣維護需人工確認（無法完全自動化） |
| 隱性架構依賴浮出，便於後續決策 | 對小 Story 可能過度分析 |
| 為後續「自動平行派遣」奠定基礎 | 需要團隊共識（依賴定義不一致會引發爭議） |

#### 影響範圍

- **主要改變**：Sprint Planning Architect 評估階段（+5 分鐘）
- **文件新增**：`docs/specs/story-dependency-matrix.md`（每 Sprint 一份）
- **流程改變**：Backlog Grooming 時需記錄 Issue 依賴

#### 預期收益

- 避免 Sprint 中途因隱性依賴而產生阻塞
- 提高平行度：從「試驗性分群」→「數據驅動分群」
- 為 AI 團隊自動派遣奠定基礎（後續 Story #XXX 可實現「依賴感知派遣」）

---

### 方案 B：條件化驗證設計 — RESEARCH Story 解耦

**核心理念**：RESEARCH Story（尤其是 Spike 類）可分階段設計，先驗證「核心假設」（無需前置數據），後續根據實際執行結果迭代分析。改變「等數據再開始」的被動模式，改為「邊執行邊驗證」的主動模式。

#### 實施步驟

1. **RESEARCH Story 設計原則更新**
   
   ```markdown
   # RESEARCH Story 設計 — 3 層模型
   
   ## 層級 1：核心假設驗證（無依賴）
   
   **定義**：根據已有領域知識與前一個 Spike 的結論，推導出「可實現的優化點」。
   
   **特性**：
   - 不依賴新數據，可立即執行
   - 產出「理論分析」与「條件化建議」
   - 明確標注：「此建議待驗證，需執行 XX 後確認」
   
   **例子（#887 改進版）**：
   ```
   層級 1 AC1：產出「3 個優化方案」，含理論分析與 trade-off
   層級 1 AC2：標注「方案 A 需 3+ 次增量 Discovery 執行驗證」「方案 B 可立即實施」
   層級 1 AC3：建議後續 Story 優先實施「方案 B」
   
   容量：S(1pt) — 理論分析 + 條件化建議，無實驗
   ```

   ## 層級 2：初步驗證（單次執行）
   
   **定義**：執行 1 次新流程/機制，收集一輪數據，針對層級 1 提出的優化點進行初步檢驗。
   
   **特性**：
   - 依賴層級 1 的理論支撐
   - 依賴 1 次實際執行（可與其他並行 Story 並列排期）
   - 產出「第一輪反饋報告」
   
   **例子**：
   ```
   新 Story #XXX: retro: 增量 Discovery 初驗證 — 執行 1 次驗證「方案 B」的實效
   
   AC1: 執行 1 次增量 Discovery（按 spike-887 標準流程）
   AC2: 收集「時間消耗、Issue 品質、水位提升」3 項指標
   AC3: 對比 spike-887 預期 vs 實際，產出「驗證報告」
   
   容量：S(1pt) — 執行 + 觀測，不需完整分析
   ```

   ## 層級 3：系統驗證（多次執行 + 長期觀測）
   
   **定義**：執行 3+ 次流程迭代，積累足夠樣本，支撐系統性的改進決策。
   
   **特性**：
   - 跨越多個 Sprint 的長期 Retro 工作
   - 依賴層級 2 的初驗結果
   - 產出「系統優化建議」（可能改變流程標準）
   
   **例子**：
   ```
   新 Story（可能為 Sprint 177+ Retro）：
   增量 Discovery 效果長期分析 — 累積 3+ Sprint 執行數據
   
   AC1: 蒐集 Sprint N/N+1/N+2 的增量 Discovery 執行紀錄
   AC2: 分析「執行頻率 vs Backlog 健康度」相關性
   AC3: 建議 ADR 修訂或流程調整
   
   容量：M(2pts) — 數據分析 + 統計推論
   ```
   ```

2. **#887 重構案例**
   
   **原設計**（Sprint 174）：
   - AC1: Spike Report 含 3 個優化方案 + trade-off
   - AC2: 提出後續 Backlog Items
   - **依賴**：需要 #919 完成後的水位數據
   - **耗時**：等待 Phase 1 → Phase 2，總時 30–50 分鐘
   
   **改進設計**：
   - **層級 1 任務**（#887 本體，無依賴）：
     - AC1: 基於 spike-887 結論，推導「可立即實施的優化點」（方案 B）
     - AC2: 列舉「需驗證的假設」（方案 A 的依賴條件）
     - AC3: 建議「後續驗證 Story」的 AC
     - 耗時：20 分鐘，S(1pt)，**可與 #919 並行**
   
   - **層級 2 任務**（新增 Story，待 Sprint 175+）：
     - 執行 1 次增量 Discovery，驗證「方案 B 的實效」
     - 耗時：30 分鐘，S(1pt)
   
   **改進收益**：
   - #887 無需等待 #919 完成，可立即與 #919 + #922 並行（Batch 1）
   - 決策速度提升：從「等數據再決策」改為「先推導後驗證」
   - #887 仍可輸出 spike-887 層級的分析質量，但假設更明確

3. **新增「條件化驗證」標籤**
   
   在 GitHub Issue 中新增 optional label `research:staged`，標記採用分階段設計的 RESEARCH Story：
   ```
   #887：retro: Backlog Discovery 流程最佳化
   labels: [research, research:staged, spike-935-input]
   ```
   
   在 Issue body 中新增區段：
   ```markdown
   ## 驗證階段
   
   - **層級 1（本 Story）**：核心假設驗證 ✓
   - **層級 2（建議新 Story #XXX）**：初步驗證 — 待開立
   - **層級 3（未來 Retro）**：系統驗證 — 長期跟蹤
   
   ## 條件化建議
   
   - **方案 A** 可行但需層級 2 驗證
   - **方案 B** 可立即實施，建議 Sprint 175 試點
   ```

#### Trade-off

| 優點 | 缺點 |
|------|------|
| 消除「數據前置」阻塞，RESEARCH Story 可立即啟動 | 分析深度可能不如一次完整的 Spike |
| 決策更及時，避免被動等待 | 需要額外的「層級 2 驗證」Story（工作量變化） |
| 層級 1 的推導質量高，基於領域知識而非猜測 | 假設驗證過程需要新流程支撐 |
| 為「邊做邊學」的敏捷文化提供結構支撐 | 團隊需要轉變「完美資料 → 決策」的思維 |

#### 影響範圍

- **主要改變**：RESEARCH Story 設計模式（3 層模型）
- **流程改變**：Sprint Planning 時 PO 需確認「RESEARCH Story 採用哪個層級」
- **文件新增**：可選，在 Issue body 中新增「驗證階段」區段
- **標籤新增**：可選 label `research:staged`

#### 預期收益

- **並行度提升**：RESEARCH Story 無需等待前置 Story 完成
- **決策速度**：從 Spike 完成後下一 Sprint 才能驗證 → 當前 Sprint 立即推導方案
- **知識積累**：層級化設計支撐「長期學習」而非「一次性決策」

---

## 建議後續 Backlog Items

### Issue Draft 1

**Title**: refactor: 新增 Story 依賴矩陣檢查流程 — Sprint Planning 架構評估

**Body Outline**:
```markdown
## 使用者故事

As an Architect, I want an automated dependency matrix check during Sprint Planning,
so that parallel execution opportunities are identified and hidden architectural dependencies are surfaced.

## 問題

當前 Sprint Planning 中，Story 間的序列依賴無結構化管理。隱性架構依賴（如 CI 修改、測試框架擴充）
可能在 Execution 中才被發現，導致不必要的阻塞。

## Acceptance Criteria

- [ ] 在 Architect round 後，自動掃描 Sprint Backlog 中所有 Story 對，生成 `docs/specs/story-dependency-matrix.md`
- [ ] 矩陣應包含 5 種依賴類型（None/Data/File/Process/Architecture）與決策建議
- [ ] 對 Architecture 類型依賴標注風險評估結論
- [ ] 矩陣應被集成至 Sprint Planning 工作流（PO Round 2 前），作為最終確認的 checkpoint

## 非功能性需求

- NFR1: 依賴矩陣自動生成（基於 Sprint Backlog 掃描），減少人工負擔
- NFR2: 矩陣應在 Execution 開始前完成，支撐「依賴感知派遣」決策
```

**Suggested Size**: M (2pts)

---

### Issue Draft 2

**Title**: feat: RESEARCH Story 層級化設計支撐 — 核心假設驗證 → 初步驗證 → 系統驗證

**Body Outline**:
```markdown
## 使用者故事

As a PO/Architect, I want a structured 3-tier RESEARCH Story design model,
so that Spike-type stories can be executed immediately without blocking on prerequisite data,
while maintaining analytical rigor.

## 問題

當前 RESEARCH Story 經常需要等待前置 Discovery/Feature Story 完成，導致「數據前置依賴」阻塞決策。
例如 #887 因需 #919 的水位數據而被排至 Phase 2，延遲了優化方案的推導。

## Acceptance Criteria

- [ ] 建立「3 層 RESEARCH 設計模型」文檔：層級 1（核心假設驗證）/ 層級 2（初步驗證）/ 層級 3（系統驗證）
- [ ] 更新 Backlog Grooming 指南，新增「RESEARCH Story 層級選擇」決策表
- [ ] 新增 Issue label `research:staged`，標記採用分階段設計的 RESEARCH Story
- [ ] 更新 Issue template，在 RESEARCH 類型 Issue 中新增「驗證階段」區段
- [ ] 試點應用於 Sprint 175+ 的 RESEARCH Story

## 非功能性需求

- NFR1: 層級模型應基於已有 Spike 案例（#887, #919）驗證可行性
- NFR2: Issue template 更新應對現有 RESEARCH 類型 Issue 向後相容
```

**Suggested Size**: M (2pts)

---

## 結論與建議

### 主要發現

1. **序列依賴存在但非必然**：Sprint 174 中 #887 對 #919 的依賴是「數據驗證需求」，但理論分析無需等待，可通過「層級化設計」解耦
2. **隱性架構依賴風險**：無 ADR 標注的基礎設施 Story（如 CI、測試框架修改）缺乏顯式依賴記錄，可能導致并行執行時的隱性衝突
3. **平行化空間未充分利用**：Sprint 171–173 雖標記「可平行」分群，但缺乏顯式的「依賴證據」和「風險評估」

### 優化策略（優先級）

| 方案 | 優先級 | 預期收益 | 實施周期 |
|------|--------|---------|---------|
| **方案 A**（依賴矩陣） | HIGH | 系統化依賴管理，為自動派遣奠基 | Sprint 176 Planning Skill 更新 |
| **方案 B**（層級化 RESEARCH） | HIGH | 消除「數據前置」阻塞，決策加速 | Sprint 175 Backlog（新 Issue） + Issue template 更新 |

### 直接可執行項

**Sprint 175 立即執行**（無需等待 Backlog Item 開立）：

1. 在 Architect 技術評估時，添加「依賴關係檢查」checklist
   ```bash
   # Sprint Planning Checklist 新增項
   - [ ] 依賴檢查：所有 Story 對的平行執行依賴已評估（File/Process/Data/Architecture）
   ```

2. RESEARCH Story 設計時採用「層級化」思路，在 Issue body 明確標注：
   ```markdown
   ## 層級設計
   - 層級 1（本 Story）：[描述]
   - 層級 2（待驗證）：[建議新 Story]
   ```

3. 新增 Issue label `research:staged`（GitHub 後台操作，無代碼）

### 後續觀測指標

實施方案後，建議在 Sprint Review 跟蹤以下指標：

| 指標 | 目標 | 驗證方式 |
|------|------|---------|
| **並行度提升** | 相同容量 Sprint 中，並行 Story 對數 +20% | 檢查 sprint_N.md 平行分群數量 |
| **隱性依賴浮出** | 依賴矩陣中 Architecture 依賴數 >= 2 對/Sprint | 檢查 story-dependency-matrix.md |
| **RESEARCH 解耦** | RESEARCH Story 無因數據缺失被延後的案例 | 檢查 Sprint Backlog 與實際執行序 |
| **決策速度** | RESEARCH Story 產出優化建議的時間 -1 Sprint | 對比 #887 與後續 RESEARCH Story 的推導週期 |

---

## 附錄：參考資料

- [spike-887-discovery-optimization.md](spike-887-discovery-optimization.md) — 基線 Spike Report
- Sprint 171–174 sprint files — 序列依賴案例來源
- `skills/sprint-planning/SKILL.md` — Planning 流程規範
- `skills/sprint-execution/SKILL.md` — Execution 平行執行規則

