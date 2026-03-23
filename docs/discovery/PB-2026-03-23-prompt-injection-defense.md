# Product Brief: Prompt Injection Defense — Security Gate

**Issue 來源：** #342 研究報告 Issue #2
**優先級：** 🔴 高
**日期：** 2026-03-23
**PB 狀態：** Draft

---

## 1. 問題陳述

Shikigami 的 Security 角色目前負責 Code Security Review，但外部輸入（使用者需求文件、User Story、外部 API 回應）在進入 Architect / Developer pipeline 前，沒有經過 prompt injection 掃描。惡意構造的需求文件可能夾帶指令，劫持 agent 行為，繞過角色分工設計，造成框架行為失控。

業界研究（2026）指出：63% 的組織無法有效控制自己的 AI，model-level guardrail（system prompt 層級）無法防禦 prompt injection，必須在 infrastructure 層面加入輸入清洗機制。Shikigami 在 High 自治模式下自主執行複雜任務的風險面更大。

---

## 2. 目標使用者

**主要使用者：** 在開放環境中使用 Shikigami 的 Operator 與開發者
- 接收來自外部利害關係人或第三方服務的需求文件
- 使用 Shikigami 整合外部 API，讓 agent 消費 API 回應

**次要使用者：** 企業組織的 AI 治理負責人
- 需要可稽核的 security gate 記錄，用於合規審計
- 需要可配置的防禦規則，以符合組織內部安全政策

---

## 3. 商業假設

**假設外顯化（三問）：**

1. **我們假設 prompt injection 是 Shikigami 使用者實際面對的威脅** — 使用者確實會將外部未受信任的文件餵入 Shikigami pipeline，而非僅使用自己撰寫的需求文件。[UNCERTAIN] 若目前使用者均為個人開發者且需求文件自撰，此功能的緊迫性可能被高估，需透過使用者場景調查確認。

2. **我們假設 Security 角色的 scan gate 不會顯著拖慢 Sprint 流程** — 加入 injection scan 後，整體 Sprint 執行時間的增加在使用者可接受範圍內（例如 < 10%）。[UNCERTAIN] 若 scan 本身需要大量 token 消耗，對 cost-sensitive 使用者可能是阻力。

3. **我們假設規則外部化到 SECURITY_RULES.md 能提升採用意願** — 可配置的防禦規則比寫死 prompt 更受使用者信任，因為使用者可以檢視與調整。[UNCERTAIN] 若多數使用者不會讀或改規則檔，外部化的價值可能有限。

---

## 4. 提案解決方向

在兩個關鍵進入點前插入 Security 角色的 prompt injection 防禦 gate：

**進入點 1：** 需求文件輸入 — PO 收到原始需求後、Architect 開始設計前，Security 執行掃描
**進入點 2：** 外部工具回應 — 任何 external API call 的回應進入 agent context 前執行掃描

防禦檢查清單（定義於外部 `SECURITY_RULES.md`，可配置）：
- 是否包含角色覆寫指令（例：`ignore previous instructions`、`disregard your system prompt`）
- 是否嘗試提升權限（例：`you are now admin`、`act as root`）
- 是否包含隱藏指令（white text、base64 encoded content、homoglyph 字符替換）

風險分級：HIGH RISK 觸發流程暫停並通知 Stakeholder，MEDIUM RISK 記錄 log 並繼續執行但加入 warning。

---

## 5. 成功指標

- **覆蓋率：** 所有外部輸入進入 pipeline 前 100% 通過 Security gate（不可 bypass）
- **誤報率（False Positive Rate）：** HIGH RISK 誤判率 < 5%（過度觸發會造成流程中斷疲勞）
- **漏報率（False Negative Rate）：** 已知 injection pattern 的偵測率 > 95%（需建立測試用例集）
- **使用者感知：** Operator 對 security gate 的信任度評分（Sprint Review 後問卷，目標 > 4/5）

---

## 6. 排除範圍

- **不含輸入內容語意分析**：本 PB 定義基於規則的模式比對，不引入 ML 分類器
- **不含 agent 內部互傳訊息的掃描**：進入點僅限外部輸入，agent 間內部溝通不在此次範圍
- **不含自動修復機制**：發現 injection 後僅暫停並通知，不自動嘗試清洗或修改原始輸入
- **不含 rate limiting 或 abuse detection**：請求頻率管控屬獨立 infra 課題

---

## 7. 依賴與風險

**依賴：**
- Issue #1（Structured Trace Log）：scan 結果應寫入 trace log，形成可稽核記錄
- SECURITY_RULES.md 需在此功能實作前先定義初始規則集，作為 PoC 基準

**風險：**
- **高誤報風險：** 過於嚴格的規則可能頻繁觸發 HIGH RISK，造成工作流中斷，削弱使用者信任。[UNCERTAIN] 需在測試期間以真實需求文件樣本校準規則靈敏度
- **規避風險：** 攻擊者可能使用規則未覆蓋的新型 injection 手法。規則庫需定期更新，否則保護效果隨時間衰退
- **效能成本：** Security scan 為每次外部輸入增加 latency，若使用者在 tight loop 中頻繁輸入，累積成本明顯

