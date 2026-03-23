# Product Brief: Kill Switch — High 自治模式緊急停止機制

**Issue 來源：** #342 研究報告 Issue #7
**優先級：** 低
**日期：** 2026-03-23
**PB 狀態：** Draft

---

## 1. 問題陳述

Shikigami 在 high 自治模式下，所有 subagent 在接近無人監督的情況下長時間執行複雜任務。若發生以下情況，目前缺乏有效的緊急介入手段：
- Security 角色偵測到高風險行為（例如 prompt injection 成功）
- Agent 執行方向偏離 Stakeholder 的預期，需要立即叫停
- 系統超出預設執行時間，可能陷入無限迴圈或資源失控

業界 2026 年治理研究顯示，僅有 40% 的組織具備有效的 AI Kill Switch 能力，此能力被視為 AI Governance 的核心基礎設施。隨著 Shikigami 的 high 自治模式能力提升，缺乏緊急停止機制的風險不對稱性持續擴大。

---

## 2. 目標使用者

**主要使用者：** 在 high 自治模式下使用 Shikigami 的 Operator 與開發者
- 需要能在發現問題時立即停止所有 subagent，而不是等待當前 Sprint 自然結束
- 需要停止後的狀態報告，以便決定是否及如何繼續執行

**次要使用者：** 企業環境中的 AI 治理負責人
- 需要可稽核的緊急停止記錄，作為 AI Governance 合規依據
- 需要可配置的自動觸發條件，以符合組織風險政策

---

## 3. 商業假設

**假設外顯化（三問）：**

1. **我們假設 high 自治模式的使用者確實需要緊急停止能力** — 使用者在 high 自治模式下執行 Sprint 時，曾遭遇或擔憂「AI 行為失控但無法立即介入」的場景。[UNCERTAIN] 若目前使用者的 high 自治模式 Sprint 執行時間均短（< 15 分鐘），緊急停止的緊迫性可能被高估。需透過使用者訪談或 Sprint 執行時間分佈確認實際場景。

2. **我們假設「原子操作完成後停止」能避免資料損毀** — Kill Switch 觸發後，各 subagent 完成當前原子操作（例如一次檔案寫入）再停止，不強制中斷，此策略能確保工作目錄的一致性。[UNCERTAIN] 若某個原子操作本身耗時很長（例如大型程式碼重構），使用者等待超過 30 秒的感知可能難以接受。

3. **我們假設斷點續跑（從 Kill Switch 狀態恢復執行）是高價值功能** — 使用者在緊急停止後，不希望從頭重跑整個 Sprint，而是希望從停止點繼續。[UNCERTAIN] 實作斷點續跑的技術複雜度顯著高於單純停止，若使用者接受重跑，此功能的 ROI 可能不足以支撐優先實作。

---

## 4. 提案解決方向

實作 `SHIKIGAMI_EMERGENCY_STOP` 訊號機制：

**觸發條件（任一即可）：**
- Security 角色輸出 CRITICAL 風險評級（自動觸發）
- Stakeholder 在任何時間點發出停止指令（手動觸發）
- 超過設定的最大執行時間（configurable，預設 30 分鐘，自動觸發）

**Kill Switch 執行序列：**
1. 廣播停止訊號至所有 active subagent（透過共享狀態檔案 `kill-switch-{session_id}.flag`）
2. 各 subagent 在當前原子操作完成後讀取訊號並停止（Graceful shutdown，避免檔案損毀）
3. 儲存所有 agent 的當前狀態快照（`emergency-stop-snapshot-{session_id}.json`）
4. 輸出 Emergency Stop Report：說明已完成哪些任務、哪些被中斷、中斷點狀態

**設計原則：** Kill Switch 機制本身不依賴 LLM 執行（純 signal/flag 機制），確保在 LLM 失控時仍可有效停止。

---

## 5. 成功指標

- **停止時間：** Kill Switch 觸發後，所有 subagent 在 30 秒內完成安全停止（Graceful shutdown SLA）
- **停止後報告完整率：** 每次 Kill Switch 事件均產出 Emergency Stop Report，包含每個 subagent 的最後狀態（100% 完整率）
- **資料一致性：** Kill Switch 停止後，工作目錄無損毀或半寫入的檔案（零資料損毀率）
- **恢復能力（[UNCERTAIN]，需 PoC 驗證）：** 從 Kill Switch 狀態恢復執行後，Sprint 能從停止點繼續而非重跑（目標：> 80% 的中斷任務可恢復）

---

## 6. 排除範圍

- **不含遠端觸發介面：** Kill Switch 透過本地訊號觸發，不建立 Web UI 或 REST API 遠端控制端點（此為後續治理功能）
- **不含 subagent 白名單（部分停止）：** 此版本為全量停止，不支援「停止特定 subagent 但讓其他繼續執行」的細粒度控制
- **不含自動 Root Cause Analysis：** Emergency Stop Report 記錄狀態，不自動分析停止原因
- **斷點續跑為可選功能：** 基本版本僅確保安全停止與報告，斷點續跑視 PoC 複雜度決定是否納入此版本

---

## 7. 依賴與風險

**依賴：**
- Issue #1（Structured Trace Log）：Kill Switch 觸發後的狀態快照需整合 trace log 資料，Emergency Stop Report 才能提供完整的執行歷程
- Issue #2（Prompt Injection Defense）：Security CRITICAL 評級為 Kill Switch 的自動觸發來源之一，兩者需要介面定義
- 共享狀態檔案（`kill-switch-*.flag`）的位置與命名慣例需全框架統一，符合 CLAUDE.md 多機器多 session 原則

**技術風險：**
- **訊號廣播可靠性風險：** 若 subagent 因執行忙碌未及時讀取停止訊號，可能無法在 30 秒 SLA 內完成停止。需設計 polling 間隔與 timeout 保護
- **斷點續跑複雜度風險：** 各 subagent 的內部狀態（尤其是 LLM context window）難以完整序列化，斷點續跑的實作複雜度可能超過預估
- **誤觸發風險：** 自動觸發條件（尤其是 CRITICAL 評級）若靈敏度過高，可能在正常 Sprint 中誤觸發，造成工作中斷

**商業風險：**
- Kill Switch 本身是「保險機制」，平常不使用。若 high 自治模式的實際問題發生率極低，此功能的感知價值難以量化，但不能因此忽略治理需求
