# 第三方 AI 開發流程研究報告
> 對照 Shikigami 框架的差異分析與強化建議

---

## 一、對方流程的本質架構

### 五層 Pipeline

```
Figma + 客戶文件
       ↓
需求化簡（Gemini）→ E2E Story（Happy Path / Edge Case）
       ↓
兩輪 Review（多家 Agent 比對批判，只給建議不直接改）
       ↓
Schema 定義（前後端介面 + 資料流向 + 事件驅動分界）
       ↓
各組平行開發（前端 / 資料庫 / 雲端 / 後端）
```

### 核心設計原則

- **Review 層與執行層強制分離**：Reviewer 只輸出建議清單，不直接動手修改。避免 agent 在自我修正時產生局部最優但整體漂移的問題。
- **Schema 先行**：所有組別動手前先定 Schema，明確資料流向與事件驅動分界，確保各組共享同一個介面基準。
- **Figma 作為 ground truth**：視覺比對不依賴主觀判斷，有外部基準強制校正。
- **夜間無人值守 Loop**：晚上開 Loop，早上收成，依賴 Watchdog + Bypass + 足夠的 context 文件。

---

## 二、各組的執行模式

### 前端組
- Figma 務必開 Dev Mode（不是 viewer）
- 雙 Agent Team：一組開發，一組截圖對比 Figma 批判，輪流兩次
- 有手機版插裝置或開模擬器截圖

### 資料庫組
- Agent 針對 Schema 互相辯論
- 強制意識到：交易鎖、讀寫高頻、併發、合規識別化設計、快取層

### 雲端組
- AWS CDK / Terraform，遵循最佳實踐
- 拆分：Config / 常數 / SSM 區 / CDK Stack
- 設定 CI/CD PROD 變動自我部署

### 後端組
- 針對前端組與資料庫組產出進行開發
- 強制塞入「零信任」設計原則
- 型別與測試至上，容器化文件獨立驗證

---

## 三、Orchestration 架構（龍蝦）

### 三層結構

```
龍蝦（Orchestrator / Claude Code）
    ↓
TMUX Session（= Agent Team，同職能）
    └── 內部 Subagent：Developer × N
    └── 內部 Subagent：Reviewer
    └── 內部 Subagent：Devil's Advocate
    └── 至少 5 個 agent
```

### 關鍵設計

- **同職能 Team 內部 Debate**：每個 session 是同一職能的小組，在同一知識體系裡深挖，Devil's Advocate 的批判是精準的。
- **Devil's Advocate Prompt Suffix**：
  ```
  "At least 5 agents in team and including Devil's Advocates."
  ```
  聲明式設計，agent 自己根據 context 決定批判角色與批判方向。
- **Watchdog Pingpong**：監控 session 存活狀態，自動 restart，解決長時間 loop 無聲掛掉的問題。
- **NX Monorepo 範本**：所有 Skills、Hooks、Script、弱掃、Code Smell 綁在範本上，每個新專案從範本出發，不從零開始。

---

## 四、對方流程的實質限制

### 「一天一個企業級 App」的真相
- 一天能完成的只有**生成**，不包含真正理解業務邏輯、驗證真實負載行為、確認客戶實際需求。
- 「最後一哩路」是所有積累誤差集中爆發的地方，因為中間沒有收斂循環。
- 實質交付物是**高品質原型**，不是可交付產品。

### 治理層是隱性的
- 治理裝在他腦子裡，他本人在隱性地扮演治理層。
- 治理品質依賴那個人的認知上限與當下狀態。
- 隨案子數量增加，治理負載線性增長，不可擴展。

### TMUX 過度設計
- TMUX 的可觀測性是為了讓人放心，但 30 個 session 同時跑，人根本看不完。
- 夜間無人值守的場景中，視覺化優勢完全發揮不出來。
- Log 檔反而更有用：跑完才看、searchable、可餵給 agent 做事後分析。
- `nohup` 或 `screen` + Log 寫檔即可達到同等效果，資源更省。

### 無收斂循環
- 人介入點只有開始與結束，中間沒有校正機會。
- 客戶需求變動、認知偏差全部積累到最後才發現。
- 無法真正做到人機協作。

---

## 五、與 Shikigami 的對比

| 維度 | 對方流程 | Shikigami |
|------|---------|-----------|
| **定位** | 執行框架（怎麼做） | 治理框架（誰有權做、何時做） |
| **角色模型** | 功能組（前端組 / 後端組 / 資料庫組） | 職責角色（Architect / QA / Security / UI-UX） |
| **批判機制** | Devil's Advocate + 雙 Team 交替審查 | Parliament Veto + QA Gate |
| **品質門檻** | 視覺 Diff + E2E 影片 | Test Contract GREEN + Story Sub-state |
| **人工介入點** | Demo 前最後一哩路 | 感知層美學判斷 + Sprint 收斂 |
| **收斂循環** | 無 | Sprint → 收斂 → Sprint |
| **人機協作** | 無 | 每個 Sprint 邊界皆可介入 |
| **治理層** | 隱性（在人腦中） | 顯性（結構化、可複製） |
| **治理負載擴展性** | 線性增長 | 恆定（結構扛住） |
| **Schema Ownership** | 模糊 | Architect 擁有技術 Contract |
| **Orchestration** | 龍蝦 + TMUX | Onmyoji → delegate.sh |

### 本質差異

**他從執行層往上建**：先有流程，再有治理。
**Shikigami 從治理層往下建**：先有角色和規則，再有執行。

對方的天花板是那個人的認知上限。
Shikigami 的天花板是結構本身，可以持續升級。

---

## 六、Shikigami 可強化的點

### 🔴 最高優先：補上同職能 Team 內部 Debate 這一層

**現狀**：Shikigami 的 worker subagent 產出直接進 veto gate，等於個人作業直接交審。

**強化後**：

```
Onmyoji 派任 Story
    ↓
【新增】同職能 Team 內部 Debate
    ├── Developer × N（同職能）
    ├── Reviewer（同職能視角）
    └── Devil's Advocate（同職能視角）
    ↓
產出交跨職能 Veto Gate（現有流程）
```

每個 Role 從「單一 subagent」升級成「小型 team」，但對外還是一個聲音。
品質基線從個人作業提升為小組共識。

### 🟡 中優先：強化 Review 的內容厚度

**現狀**：Shikigami 的 veto 是二元 gate（通過 / 不通過）。

**強化後**：veto 之前先有**建議清單**，Developer 拿著清單自己決定怎麼改，保留決策權，veto 作為最終門檻。

```
Review 產出建議清單
    ↓
Developer 自行決定接受 / 部分接受 / 反駁
    ↓
Veto Gate 最終確認
```

### 🟢 長期：GAD 接入 Delivery Phase

將雙 Team 交替審查機制接入 Shikigami 的 Delivery phase：

```
Test Contract GREEN
    +
Agent A 實作 → Agent B 截圖對比 Figma + Contract Spec → 批判報告 → Agent A 修正
    ↓
QA Veto Gate：tests GREEN + visual diff PASS
```

QA veto gate 從「tests GREEN」升級成「tests GREEN + visual diff PASS」。

---

## 七、總結

對方的流程是一個**聰明的人把自己的直覺系統化**的結果，在快速出原型的場景下非常有效。

Shikigami 的核心差距在於：

1. **治理顯性化**：把隱性的人腦治理變成可複製的結構
2. **收斂循環**：Sprint 邊界是校正點，誤差不會積累到最後才爆發
3. **人機協作**：人可以在任何 Sprint 邊界注入新的認知
4. **治理負載恆定**：多案子同時跑，治理品質不稀釋

唯一需要補的缺口是**同職能 Team 內部 Debate**這一層。補完之後，Shikigami 在結構完整性上沒有明顯缺口。
