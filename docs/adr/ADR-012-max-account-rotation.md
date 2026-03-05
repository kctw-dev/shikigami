# ADR-012：Claude Max 多開發環境認證架構決策

**狀態**：Accepted
**日期**：2026-03-05
**決策者**：Architect
**關聯 Issue**：#86（US-92）、#87（US-A — 認證架構實作）
**關聯 Story**：US-92（本 ADR 起草）、US-A（Sprint 45 候選，本 ADR 結論的主要消費者）
**關聯 ADR**：ADR-006（Prompt Injection 防護）、ADR-011（GitHub Actions 整合）

---

## 背景

Shikigami 框架的開發者在日常開發中使用 Claude Code CLI，並透過 Claude Max 訂閱帳號認證。隨著框架自動化範圍擴大（Sprint Execution、Backlog Intake、GitHub Actions CI/CD），單一 Max 訂閱帳號的用量上限成為實際瓶頸：

- **Claude Max 用量限制結構**：Max 計劃有兩個層級（Max 5x：$100/月、Max 20x：$200/月），用量以 5 小時為一個重置窗口，另有每週與每月上限
- **Claude Code 共享額度**：Max 訂閱的用量上限在 Claude.ai 網頁介面與 Claude Code CLI 之間共享，本地開發消耗會壓縮 CI/CD 可用額度
- **高峰期瓶頸**：Sprint Execution 期間的大量 subagent 並行呼叫，加上日常開發使用，容易在單一 5 小時窗口內觸及上限
- **備援方案成本過高**：Extra Usage 與 API Key 備援均以 API 費率計費（如 Opus：$15/$75 per MTok），重度使用下月費可達數百美元，經濟上不可持續

### 開發環境現況

開發者維護多台 GCE（Google Compute Engine）開發機，各自獨立運行不同的開發任務。這些開發機**同時平行工作**，開發者在多台工作站之間自然移動，將工作分配到有可用額度的機器上。工作的分配主要基於開發需求，額度狀態為次要考量。

本 ADR 旨在：
1. 釐清此「多 GCE 平行開發、各自訂閱」模式的 ToS 合規性（**ToS 合規性分析**）
2. 評估至少 2 個技術方案（**方案分析**）
3. 為 Sprint 45 US-A 的實作提供明確的架構前提

---

## ToS 合規性分析（AC1）

### 研究方法

本分析參考以下文件（截至 2026-03-05）：

- [Anthropic Consumer Terms of Service](https://www.anthropic.com/legal/consumer-terms)
- [Anthropic Usage Policy (AUP)](https://www.anthropic.com/legal/aup)
- [Claude Max Plan 說明](https://support.claude.com/en/articles/11049741-what-is-the-max-plan)
- [Extra Usage 說明](https://support.claude.com/en/articles/12429409-extra-usage-for-paid-claude-plans)
- [Claude Code 與 Max 計劃](https://support.claude.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan)
- [The Register：Anthropic clarifies ban on third-party tool access to Claude](https://www.theregister.com/2026/02/20/anthropic_clarifies_ban_third_party_claude_access)（2026-02-20）

### 關鍵條款摘要

#### Consumer Terms of Service §2 — 帳號建立與存取

| 條款面向 | 原文摘要 | 與本 ADR 的關聯 |
|---------|---------|----------------|
| 帳號憑證禁止共享 | "You may not share your Account login information, Anthropic API key, or Account credentials with anyone else." | 禁止的是**與他人**共享；本場景為同一人在不同機器上使用各自帳號，不觸及此條款 |
| 帳號不得提供他人使用 | "You also may not make your Account available to anyone else." | 同上，限制對象為「anyone else」 |
| 多帳號明確限制 | **無明文禁止**單一自然人持有多個帳號的條款 | Consumer Terms 全文未見「每人限一帳號」的規定 |

#### Consumer Terms — OAuth 使用限制（2026-02 更新）

| 條款面向 | 原文摘要 | 與本 ADR 的關聯 |
|---------|---------|----------------|
| OAuth 第三方工具禁止 | "Using OAuth tokens obtained through Claude Free, Pro, or Max accounts in any other product, tool, or service — including the Agent SDK — is not permitted" | OAuth token 僅限在 **Claude Code** 與 **Claude.ai** 中使用 |
| 與本場景的關係 | 各 GCE 上的 Claude Code 為 Anthropic 官方產品 | 在 Claude Code 中使用 Max 帳號的 OAuth 認證**不違反**此限制 |

#### Usage Policy (AUP) — 多帳號相關條款

| 條款面向 | 原文摘要 | 本場景適用性 |
|---------|---------|------------|
| 多帳號協調 | "Coordinate malicious activity across multiple accounts to avoid detection or circumvent product guardrails" | **低**——關鍵字為「malicious activity」；平行開發非惡意活動，且各機器獨立工作、耗完即停，未繞過任何 guardrail |
| 封禁規避 | "Circumvent a ban through the use of a different account" | **不適用**——本場景非封禁規避 |
| 系統繞過 | "bypass any of our systems or protective measures" | **低**——每台機器獨立尊重各自帳號的用量上限，耗完即停，未 bypass 任何 protective measure |

#### Max Plan — 用量管理條款

| 條款面向 | 原文摘要 | 與本 ADR 的關聯 |
|---------|---------|----------------|
| 公平使用 | "to manage capacity and ensure fair access to all users, we may limit your usage in other ways, such as weekly and monthly caps" | 每個帳號獨立遵守各自的用量上限；開發者為每個帳號付費，Anthropic 已收取對應費用 |
| Extra Usage | 用量耗盡後可啟用 Extra Usage，以 API 費率計費 | 官方替代方案存在，但費用過高不具經濟可持續性 |

### 使用模式差異分析：輪換 vs 平行

本 ADR 需明確區分兩種本質不同的多帳號使用模式，因其 ToS 風險等級截然不同：

| 面向 | 單機帳號輪換（不採用） | 多機工作流動（本 ADR 場景） |
|------|---------------------|--------------------------|
| 行為模式 | 同一台機器上切換帳號 | 開發者在多台 GCE 之間自然移動，工作流向有額度的機器 |
| 觸發時機 | A 帳號耗盡 → 同機器切換至 B 帳號 | A 機器額度耗盡 → 開發者移動到 B 機器繼續其他工作 |
| 「circumvent」適用性 | **高**——明確的帳號切換動作繞過限制 | **中-低**——每台機器獨立遵守各自限制，但工作流動的動機部分源於額度管理 |
| 「bypass」適用性 | **高**——以切換動作繞過 protective measure | **中-低**——未在同一機器上 bypass，但整體開發容量因多訂閱而提升 |
| 類比 | 用完 A 信用卡額度，立刻刷 B | 有多間辦公室，哪間有空就去哪間工作 |
| Anthropic 偵測角度 | 同 IP、同機器、快速切換 → 可疑 | 不同 IP、不同機器、獨立 session → 正常的多裝置使用模式 |

### ToS 合規性結論

**結論：中低風險（MEDIUM-LOW RISK）**

| 分析維度 | 結論 | 說明 |
|---------|------|------|
| Consumer Terms 對多帳號的明文規定 | 無明文禁止 | Consumer Terms 未禁止單一自然人持有多個帳號 |
| AUP「circumvent product guardrails」適用性 | **中-低** | 每台機器獨立遵守各自帳號的用量上限；但工作流動的動機部分源於額度管理，整體效果為以多訂閱擴增開發容量，存在被認定為間接規避的可能 |
| AUP「bypass protective measures」適用性 | **中-低** | 未在同一機器上 bypass 任何措施，每個帳號的 protective measure 被完整尊重；但多訂閱的整體效果客觀上提升了單一開發者的總可用額度 |
| AUP「malicious activity」適用性 | **不適用** | 開發工作為正當用途，非惡意活動 |
| Anthropic 執法先例 | **不直接適用** | 2026-01 封號案例為第三方工具濫用 OAuth（pricing arbitrage），與多機器多訂閱的使用模式不同；但顯示 Anthropic 對定價機制繞過持積極執法態度 |
| 使用正當性 | **中-高** | 開發者為每個帳號支付完整訂閱費用；多開發機為常見的軟體工程實務；但額度管理作為工作分配的考量之一，降低了純粹「自然使用」的說服力 |
| 帳號封禁風險 | **低** | 不同 GCE IP、獨立 session、無同機器切換行為特徵，使用模式與正常多裝置使用模式接近 |

**風險評估**：多 GCE 開發、各自訂閱、工作流向有額度機器的合規風險屬於**中低（MEDIUM-LOW）**。此模式在技術表現上與正常的多裝置使用無異（不同 IP、不同機器、獨立 session），Consumer Terms 未明文禁止多帳號，且開發者為每個帳號付費。然而，需誠實承認：工作流動的動機部分源於額度管理，整體效果客觀上擴增了單一開發者的可用額度，這使得合規性不如純粹的「多機器各自獨立工作、耗完即停」模式。目前無已知的多訂閱封號案例，實際執法風險偏低。

**引用條款依據**：
- Consumer Terms §2（帳號憑證禁止共享——確認不適用於本場景）
- AUP「malicious activity」條款（確認不適用——開發工作非惡意活動）
- AUP「circumvent product guardrails」條款（適用性中-低——未在同機器繞過，但多訂閱整體效果擴增額度）
- AUP「bypass protective measures」條款（適用性中-低——每帳號獨立遵守限制，但工作流動受額度驅動）

---

## 決策問題

Shikigami 框架的單一開發者在多台 GCE 開發機與 CI/CD（GitHub Actions）環境中，應以何種認證架構管理 Claude 用量，在 ToS 合規的前提下確保開發生產力？

---

## 約束條件

| 約束 | 說明 |
|------|------|
| ADR-011 GitHub Actions 整合架構 | CI/CD 環境需與 ADR-011 的 Push-Based 事件觸發架構相容 |
| ADR-006 Prompt Injection 防護 | 外部輸入進入 Shikigami Skills 時，必須套用 ADR-006 的 XML 隔離標記 |
| 零硬編碼 Secrets | 所有認證資訊必須透過安全機制注入，不得硬編碼 |
| ToS 合規優先 | 技術方案不得以明確規避用量限制為設計目的 |
| YAGNI 原則 | MVP 方案以解決當前實際用量瓶頸為目標 |
| 單一開發者情境 | 所有帳號與認證資訊為同一自然人所有，非團隊共享 |
| 費用可持續性 | 備援方案的費用需在個人開發者可承受範圍內 |

---

## 選項分析（AC2）

### 選項 A：單一 Max 20x + Extra Usage

**概念**：維持單一 Max 20x 訂閱帳號（$200/月），當用量耗盡時自動啟用 Extra Usage，以 API 費率繼續使用。

#### 架構設計

```
所有 GCE 開發機（共用同一 Max 帳號）
    │
    │ OAuth 認證（Max 20x 訂閱）
    ▼
Claude Code ─── 用量在 5 小時窗口內 ─── 正常使用（訂閱包含）
    │
    └── 用量耗盡 ─── Extra Usage 啟動（API 費率計費）

GitHub Actions（CI/CD）
    │
    │ API Key 認證（Commercial Terms）
    ▼
Claude API ─── 依 API 用量計費
```

#### 優點

- **ToS 完全合規**：單一帳號 + 官方 Extra Usage 機制
- **管理最簡**：單一帳號、單一帳單

#### 缺點

- **Extra Usage 費用過高**：Opus $15/$75 per MTok，重度使用下月費可達數百美元，**經濟上不可持續**
- **所有機器共享額度**：多台 GCE 共用同一帳號的 5 小時窗口，額度消耗更快
- **費用不可預測**：Extra Usage 自動啟動，可能在不知不覺中累積高額費用

#### 費用估算

| 項目 | 月費 |
|------|------|
| Max 20x 訂閱 | $200 |
| Extra Usage（重度使用估算） | ~$100-500+ |
| API Key CI/CD | ~$10-30 |
| **合計** | **~$310-730+** |

---

### 選項 B：多 GCE 各自訂閱、平行開發（多開發環境架構）

**概念**：每台 GCE 開發機擁有獨立的 Max 訂閱帳號，各自平行工作。開發者在多台工作站之間自然移動，將工作分配到有可用額度的機器上。每台機器獨立遵守各自帳號的用量上限。CI/CD 使用獨立的 API Key。

#### 架構設計

```
GCE-A（開發機 A）                    GCE-B（開發機 B）
    │                                    │
    │ OAuth（帳號 A，Max 20x）             │ OAuth（帳號 B，Max 20x）
    ▼                                    ▼
Claude Code                          Claude Code
    │                                    │
    ├── 正常工作                          ├── 正常工作
    └── 額度耗盡 → 該機器停止              └── 額度耗盡 → 該機器停止

開發者在 GCE 之間自然移動，工作流向有可用額度的機器

GitHub Actions（CI/CD）
    │
    │ API Key 認證（Commercial Terms，獨立帳號）
    ▼
Claude API ─── 依 API 用量計費（與 Max 訂閱互不影響）
```

#### 使用原則

1. **平行工作**：多台 GCE 同時運行，各自處理開發任務
2. **工作流動**：開發者在多台工作站之間自然移動，哪裡有額度就在哪裡工作
3. **各自遵守限制**：每台機器獨立遵守各自帳號的用量上限，額度耗盡的機器停止 Claude Code 工作
4. **開發需求優先**：工作分配主要基於開發需求，額度狀態為次要考量

#### 認證管理

| 環境 | 認證方式 | 適用 Terms | 費用模式 |
|------|---------|-----------|---------|
| GCE-A | OAuth（帳號 A，Max 訂閱） | Consumer Terms | Max 訂閱月費 |
| GCE-B | OAuth（帳號 B，Max 訂閱） | Consumer Terms | Max 訂閱月費 |
| GitHub Actions | API Key（`secrets.ANTHROPIC_API_KEY`） | Commercial Terms | API 用量計費 |

#### 優點

- **ToS 合規風險中低**：如合規性分析所述，多機器獨立使用的模式在技術表現上與正常多裝置使用無異，風險可接受
- **費用可預測**：每個帳號為固定月費，無 Extra Usage 的費用驚喜
- **開發生產力最佳化**：多機器平行工作，有效開發容量倍增
- **自然的開發實務**：多開發機各有訂閱是軟體工程界的常見模式
- **容錯性**：一個帳號若遭遇問題，其他機器不受影響

#### 缺點

- **多帳號管理**：需管理多個 Anthropic 帳號（不同 email、付款方式可不同）
- **訂閱總費用增加**：N 台機器 × Max 20x 訂閱月費（如 2 × $200 = $400/月）
- **Context 不共享**：各機器的 Claude Code 對話 context 獨立，無法跨機器延續
- **ToS 殘餘風險**：雖然低，但 Anthropic 未來若新增「每人限一帳號」條款，需重新評估

#### 費用估算（2 台 GCE）

| 項目 | 月費 |
|------|------|
| GCE-A Max 20x 訂閱 | $200 |
| GCE-B Max 20x 訂閱 | $200 |
| API Key CI/CD | ~$10-30 |
| **合計** | **~$410-430** |

---

### 選項 C：Max 20x + API Key 混合認證（雙軌架構）

**概念**：單一 Max 20x 訂閱用於所有開發機，用量耗盡時手動切換至 API Key 認證繼續工作。CI/CD 始終使用 API Key。

#### 架構設計

```
所有 GCE 開發機
    │
    ├── 主要：OAuth 認證（Max 20x）
    │    └── 正常開發 ─── 訂閱包含用量
    │
    └── 備援：API Key 認證
         └── export ANTHROPIC_API_KEY=sk-ant-...
              └── Claude Code 自動使用 API Key（API 費率計費）

GitHub Actions（CI/CD）
    │
    └── API Key 認證（始終使用）
```

#### 優點

- **ToS 完全合規**：單一帳號 + 官方認證路徑
- **開發不中斷**：API Key 備援確保可繼續工作

#### 缺點

- **API Key 備援燒錢快**：與選項 A 的 Extra Usage 費率相同（API 費率），重度使用不可持續
- **所有機器共享額度**：多台 GCE 競爭同一帳號的用量窗口
- **手動切換**：需人工判斷何時切換至 API Key

#### 費用估算

| 項目 | 月費 |
|------|------|
| Max 20x 訂閱 | $200 |
| API Key 備援（重度使用估算） | ~$50-300+ |
| API Key CI/CD | ~$10-30 |
| **合計** | **~$260-530+** |

---

## 評估矩陣

| 評估維度 | 選項 A（Extra Usage） | 選項 B（多 GCE 各自訂閱） | 選項 C（混合認證） |
|---------|---------------------|------------------------|------------------|
| ToS 合規性 | 完全合規 | 中低風險 | 完全合規 |
| 帳號封禁風險 | 無 | 低 | 無 |
| 月費可預測性 | **低**（Extra Usage 費用不定） | **高**（固定訂閱月費） | **低**（API Key 費用不定） |
| 月費估算 | ~$310-730+ | **~$410-430** | ~$260-530+ |
| 開發生產力 | 中（額度共享瓶頸） | **高**（平行獨立工作） | 中（額度共享瓶頸） |
| 管理複雜度 | 最低 | 中（多帳號） | 中（手動切換） |
| CI/CD 支援 | 需額外 API Key | 需額外 API Key | 需額外 API Key |
| 費用可持續性 | **低** | **高** | **低** |
| YAGNI 符合度 | 是 | 是 | 是 |

---

## 決策（AC3）

**ADR Status：Accepted**

本 ADR 建議採用**選項 B（多 GCE 各自訂閱、平行開發）為主要方案**。

### 決策理由

#### 1. ToS 合規性可接受（風險 MEDIUM-LOW）

選項 B 的使用模式為「多台獨立開發機、各自訂閱、工作自然流向有額度的機器」，與 AUP 禁止的行為有重要區別，但需誠實承認殘餘風險：

**合規有利因素**：
- 每台機器**獨立遵守**各自帳號的用量上限
- 不同 GCE、不同 IP、獨立 session，技術表現與正常多裝置使用無異
- 開發者為每個帳號支付完整訂閱費用
- Consumer Terms 無「每人限一帳號」條款
- 無已知的多訂閱封號案例

**殘餘風險**：
- 工作流動的動機**部分源於額度管理**，整體效果客觀上擴增了單一開發者的可用額度
- 若 Anthropic 未來收緊政策或追溯執法，存在帳號風險

#### 2. 經濟可持續性（最務實的理由）

選項 A 與 C 在用量耗盡後的備援成本（Extra Usage / API Key）以 API 費率計費，重度使用下月費不可預測且可能遠超訂閱費用。選項 B 的費用為固定訂閱月費，完全可預測：

- 2 × Max 20x = **$400/月**
- 有效容量 ≈ 2 × Max 20x 的獨立窗口
- 無 Extra Usage 費用驚喜

#### 3. 開發生產力最佳化

多台 GCE 平行獨立工作，有效開發容量倍增。各機器有獨立的 5 小時重置窗口，不互相競爭額度。

#### 4. 自然的開發實務

多開發機各有訂閱是軟體工程界的常見模式（如工作筆電 + 個人桌機、辦公室桌機 + 家用桌機），不構成異常使用行為。

### 使用紀律（降低殘餘風險）

為降低 MEDIUM-LOW 風險中的殘餘部分，開發者應遵守以下紀律：

1. **開發需求優先**：工作分配主要基於開發需求（不同分支、不同專案），額度狀態為次要考量
2. **各自遵守限制**：每台機器獨立遵守各自帳號的用量上限，額度耗盡的機器停止 Claude Code 工作
3. **不在同機器切換帳號**：不使用 `CLAUDE_CONFIG_DIR` 或 logout/login 在同一台機器上輪換帳號
4. **獨立帳號**：各帳號使用不同 email 註冊，各自獨立管理

---

## 認證管理機制（AC4）

### GCE 開發環境

每台 GCE 獨立認證，使用各自的 Max 訂閱帳號：

```bash
# GCE-A：使用帳號 A 的 OAuth 認證
# 首次設定
claude auth login
# 使用帳號 A 的 email 登入

# GCE-B：使用帳號 B 的 OAuth 認證
# 首次設定
claude auth login
# 使用帳號 B 的 email 登入
```

**各 GCE 的認證狀態獨立，無需共享或同步。**

### GitHub Actions 環境

繼承 ADR-011 OQ-1 定義的認證方案，使用獨立的 API Key（Commercial Terms）：

```yaml
# .github/workflows/shikigami-*.yml
jobs:
  shikigami-skill:
    env:
      ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

| Secret 名稱 | 說明 | 必填 |
|------------|------|------|
| `ANTHROPIC_API_KEY` | Claude API Key（Commercial Terms） | 是 |

**GitHub Actions 不使用 Max 訂閱 OAuth 認證**——OAuth 認證需要互動式瀏覽器登入，不適用於 CI/CD 的非互動式環境。

### ADR-011 / ADR-006 繼承約束

- 零硬編碼 Secrets：API Key 只能透過環境變數或 GitHub Secrets 注入
- ADR-006 Injection 防護：認證資訊不進入 LLM prompt

---

### 環境管理考量

> **已知盲區**：本 ADR 決策聚焦於認證架構與 ToS 合規性分析，未充分評估多 GCE 環境的 operational overhead。本章節為事後補充，後續由 Issue #90 追蹤改善。

### 多 GCE 環境的管理成本

選項 B（多 GCE 各自訂閱）在解決用量瓶頸的同時，引入了以下環境管理成本：

| 成本類型 | 說明 | 嚴重度 |
|---------|------|--------|
| 設置成本 | 每台新 GCE 需獨立安裝開發工具（Node.js、Claude Code、git hooks 等） | 中 |
| 維護成本 | 工具版本分歧隨時間增長，各機器逐漸偏離一致性（Snowflake Server） | 中-高 |
| 同步成本 | 開發者在 GCE 之間移動時需手動同步 repo、dotfiles、Claude Code config | 中 |
| 磁碟膨脹 | 各機器累積不同的 cache、log、依賴套件，長期運行後磁碟空間不可控 | 低-中 |

### 工作可攜性需求

開發者在多 GCE 之間自然流動的模式，要求以下資產可快速重建：

- **Repository clone**：包含所有 branch、submodule 與 git hooks
- **Dotfiles**：shell config（.bashrc/.zshrc）、git config、editor config
- **Claude Code config**：`~/.claude/` 下的 settings、memory、project config
- **開發工具鏈**：Node.js 版本、npm global packages、CLI 工具

### 環境可重建性建議

1. **定期清理**：定期清除各 GCE 的 cache、log、未使用的 branch，防止磁碟膨脹
2. **IaC 或 Snapshot**：考慮使用 GCE Custom Image / Snapshot 或 IaC（Terraform）管理環境基線，確保新機器可快速建立
3. **Dotfiles 統一管理**：將 shell config、git config 等納入 dotfiles repo，各 GCE clone 同一來源
4. **避免 Snowflake Server**：不在 GCE 上進行手動的全域修改；所有環境變更應可追溯、可重現

### 後續追蹤

- **Issue #90**：開發環境可攜性與可重建性 — 多 GCE 環境管理策略

### ADR-003 審查記錄（補正）

本章節與 `skills/architect/SKILL.md` §4 的修改初次交付時未經 ADR-003 Hard Gate 審查（Issue #91 追蹤）。以下為補正審查記錄：

- **審查日期**：2026-03-05
- **QA 審查**：PASS — 內容完整、交叉引用正確、格式缺陷已修正（`### 來源` 移除、標題層級修正）
- **Architect 審查**：PASS — 觸發條件合理、三類成本覆蓋充分、判斷框架已補充啟發式規則
- **修正 commit**：`04f2a2d`（初始交付）→ 格式修正同 commit

---

## 後續行動（AC5）

### 對 US-A（Issue #87）的影響

US-A 的範圍從「API Key Rotation 實作」調整為「多開發環境認證架構設定」：

| 面向 | 本 ADR 結論 | US-A 實作邊界 |
|------|------------|--------------|
| GCE 認證 | 各 GCE 獨立 Max 訂閱 OAuth | 文件化各 GCE 的認證設定流程 |
| CI/CD 認證 | API Key（ADR-011 繼承） | 確認 GitHub Secrets 設定正確 |
| 使用紀律 | 平行獨立、耗完即停 | 文件化使用紀律規範 |
| 單機帳號輪換 | **不採用** | US-A 不實作帳號切換邏輯 |

#### US-A AC 建議修訂方向

1. **AC（GCE 認證設定）**：每台 GCE 開發機透過 `claude auth login` 完成獨立帳號認證
2. **AC（CI/CD 認證）**：GitHub Repository Secret `ANTHROPIC_API_KEY` 正確設定，workflow YAML 以 `${{ secrets.ANTHROPIC_API_KEY }}` 注入
3. **AC（使用紀律文件）**：開發者指南包含使用紀律規範（不輪換、自然分工、耗完即停）
4. **AC（安全規範）**：認證資訊不出現於版本控制追蹤的檔案中

#### 重新評估觸發條件

| 觸發條件 | 說明 |
|---------|------|
| Anthropic Consumer Terms 新增「每人限一帳號」條款 | 需立即切換至選項 A 或 C |
| Anthropic 對多訂閱使用者執行帳號封禁 | 需重新評估風險等級 |
| Claude Code 官方支援多帳號 profile 切換 | 技術基礎設施就緒，可簡化管理 |

---

## 風險評估

| 風險 | 可能性 | 影響 | 緩解策略 |
|------|--------|------|---------|
| Anthropic 未來新增多帳號限制條款 | 低 | 高（需遷移至單帳號方案） | 監控 Consumer Terms 更新；保留選項 A/C 作為備案 |
| 帳號被偵測為異常使用 | 低 | 高（帳號封禁） | 遵守使用紀律（不輪換、耗完即停）；各帳號獨立 IP |
| 多帳號管理負擔 | 中 | 低 | 帳號數量控制在 2-3 個；各帳號獨立管理 |
| GCE 運行成本 | 中 | 低 | 依開發需求調整 GCE 規格；閒置時關機 |

---

## 參考

- [Anthropic Consumer Terms of Service](https://www.anthropic.com/legal/consumer-terms)（§2 帳號憑證、OAuth 使用限制）
- [Anthropic Usage Policy](https://www.anthropic.com/legal/aup)（circumvent product guardrails、bypass protective measures、malicious activity）
- [Claude Max Plan](https://support.claude.com/en/articles/11049741-what-is-the-max-plan)（用量限制結構、公平使用條款）
- [Extra Usage](https://support.claude.com/en/articles/12429409-extra-usage-for-paid-claude-plans)（官方用量超限方案、API 費率）
- [Claude Code 與 Max 計劃](https://support.claude.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan)（認證方式、ANTHROPIC_API_KEY 優先邏輯）
- [The Register：Anthropic clarifies ban on third-party tool access to Claude](https://www.theregister.com/2026/02/20/anthropic_clarifies_ban_third_party_claude_access)（2026-02-20，執法先例——確認不適用於本場景）
- [Claude Code 多帳號 Feature Request](https://github.com/anthropics/claude-code/issues/24963)（官方尚未支援）
- ADR-006：Prompt Injection 防護
- ADR-011：GitHub Actions 整合架構決策
