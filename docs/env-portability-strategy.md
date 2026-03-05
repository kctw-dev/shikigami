# 開發環境可攜性策略 — 方向選定文件

**版本**：v1.0.0
**建立日期**：2026-03-05
**關聯 ADR**：[ADR-012](adr/ADR-012-max-account-rotation.md)（Claude Max 多開發環境認證架構決策）
**關聯 Story**：US-95（Issue #90，Sprint 46）

---

## 概覽

本文件依 US-95 Acceptance Criteria AC1 要求，評估四個候選方向並選定低複雜度方向，作為多 GCE 開發環境可攜性策略的決策依據。

ADR-012 §環境管理考量明確指出，多 GCE 開發模式在解決 Claude Max 用量瓶頸的同時，引入了設置成本、維護成本、同步成本等 operational overhead，並建議後續由 Issue #90 追蹤改善。本文件即為此追蹤任務的交付成果。

---

## 候選方向評估

### 方向 A：Dotfiles Repo

**概念**：將 shell config（`.bashrc`/`.zshrc`）、git config、editor config、Claude Code settings 等開發者設定統一納入 git 管理的 dotfiles repository，新 GCE 透過 clone 與執行安裝腳本，快速重建個人開發環境。

**優點**：
- 複雜度最低，純 git + bash，無需額外工具
- 設定版本可追蹤、可回溯（git 歷史）
- 啟動成本極低（clone + run script 即可）
- 與 ADR-012 §環境管理考量 建議「Dotfiles 統一管理」直接對齊
- 跨機器設定一致性，防止 Snowflake Server 現象
- 腳本可冪等設計（多次執行無副作用）

**缺點**：
- 僅管理設定層，不包含工具安裝狀態（需搭配安裝腳本）
- 認證資訊（OAuth Token、API Key）不能納入 dotfiles（安全考量，需另行處理）
- 不包含磁碟層級的狀態（開發中的工作目錄、cache 等）

**評估**：低複雜度 / 高可行性 / 與 ADR-012 直接對齊

---

### 方向 B：GCE Snapshot

**概念**：對現有 GCE 建立磁碟快照（GCE Disk Snapshot），新機器從快照建立，繼承完整磁碟狀態，包含已安裝的工具、設定、工作目錄。

**優點**：
- 復原最完整（包含工具鏈、系統設定、工作狀態）
- 無需手動安裝個別工具
- 首次設定後，複製成本低（GCP Console 幾個點擊）

**缺點**：
- 快照體積大，儲存成本隨時間增加（每 GB-month 計費）
- 快照點靜態，兩次快照之間的環境漂移無法自動同步
- 個人認證資訊（OAuth Token、`~/.claude/` config）存在快照中，需在每台新機器上手動清除並重新認證，操作有洩露風險
- 快照管理需 GCP Console / `gcloud` CLI 操作，非開發者日常工作流程
- 不能納入 git 版控，無法審計環境變更歷史
- 環境修改後須重建快照，維護成本隨環境成熟度增加

**評估**：中複雜度 / 安全疑慮（認證資訊殘留）/ 成本不可控

---

### 方向 C：IaC（Infrastructure as Code）

**概念**：使用 Terraform 或 Ansible 管理 GCE VM 的建立與設定，透過 IaC 工具宣告式定義開發環境狀態。

**優點**：
- 環境完全可重現、可審計
- 支援多環境管理（staging、production 等）
- 業界最佳實踐

**缺點**：
- 複雜度最高，需學習 Terraform / Ansible
- 引入新技術選型，需通過 ADR 流程（US-95 方向約束明確排除）
- 開發者個人環境的 overhead 遠超收益
- 設置與維護成本在單一開發者情境下難以攤銷

**評估**：高複雜度 / 超出本 Sprint scope / US-95 方向約束明確排除

---

### 方向 D：Container-based

**概念**：將開發環境封裝為 Docker container（或 Dev Container），透過 `docker run` 或 VS Code Dev Containers 啟動一致的開發環境。

**優點**：
- 環境隔離性最佳
- 跨機器一致性最高

**缺點**：
- Claude Code 在 container 內的認證流程（互動式 OAuth）較複雜
- Claude Code session 的狀態（`~/.claude/`）需 volume mount，增加管理複雜度
- 引入 Docker 作為新工具層，需通過 ADR 流程（US-95 方向約束明確排除）
- 開發者 GCE 使用 container-in-VM 模式，對 GCE 環境重量增加不必要的層次

**評估**：高複雜度 / 超出本 Sprint scope / US-95 方向約束明確排除

---

## 評估矩陣

| 評估維度 | 方向 A（Dotfiles Repo） | 方向 B（GCE Snapshot） | 方向 C（IaC） | 方向 D（Container-based） |
|---------|----------------------|----------------------|-------------|------------------------|
| 實作複雜度 | **低** | 中 | 高 | 高 |
| 安全風險 | 低（認證資訊明確排除） | **中-高**（快照含認證殘留） | 低 | 低-中 |
| 維護成本 | **低** | 中-高（快照過期問題） | 高 | 中-高 |
| Git 版控支援 | **是** | 否 | 是 | 是 |
| 新 GCE 建立時間 | 5-10 分鐘（腳本執行） | 3-5 分鐘（快照復原） | 15-30 分鐘 | 10-20 分鐘 |
| ADR-012 對齊 | **直接對齊** | 部分 | N/A | N/A |
| Sprint scope 內 | **是** | 是 | **否**（排除） | **否**（排除） |
| 儲存成本 | 無額外成本 | 每 GB-month 計費 | 需 GCS backend | 需 Container Registry |

---

## 選定方向

**選定：方向 A（Dotfiles Repo）**

### 選定理由

1. **與 ADR-012 直接對齊**：ADR-012 §環境管理考量 明確建議「Dotfiles 統一管理：將 shell config、git config 等納入 dotfiles repo，各 GCE clone 同一來源」。選定 Dotfiles Repo 方向直接實現此建議，無架構風險。

2. **最低複雜度**：純 git + bash 實作，無需引入新技術或通過額外 ADR 流程，符合 KISS 原則與 YAGNI 原則。

3. **安全性最佳**：Dotfiles Repo 明確將認證資訊（OAuth Token、API Key）排除在外，由 `gce-auth-guide.md` 的認證流程另行處理，不存在 GCE Snapshot 方案中的認證資訊殘留風險。

4. **Git 版控**：環境設定的每次修改均有 git 歷史可查，防止 Snowflake Server 現象（無法追溯的手動修改累積），符合 ADR-012 §環境可重建性 建議「避免 Snowflake Server：不在 GCE 上進行手動的全域修改；所有環境變更應可追溯、可重現」。

5. **冪等性**：安裝腳本設計為冪等（多次執行無副作用），可在任何時間點執行以同步設定，不破壞現有工作環境。

### 排除替代方向的理由

| 方向 | 排除理由 |
|------|---------|
| GCE Snapshot（方向 B） | 認證資訊殘留於快照中存在安全風險；快照體積大且儲存成本隨時間增加；環境漂移問題無法透過快照自動解決；不支援 git 版控審計 |
| IaC（方向 C） | US-95 方向約束明確排除；需引入新技術（Terraform / Ansible）並通過 ADR 流程；單一開發者情境下複雜度過高 |
| Container-based（方向 D） | US-95 方向約束明確排除；Claude Code OAuth 認證在 container 內的操作複雜度不值得引入；需通過 ADR 流程 |

---

## ADR-012 對齊確認（AC4）

本選定方向與 ADR-012 §環境管理考量 的一致性對照：

| ADR-012 §環境管理考量 建議 | 本策略實作 |
|--------------------------|---------|
| Dotfiles 統一管理：將 shell config、git config 等納入 dotfiles repo | Dotfiles Repo 方向即為此建議的直接實作 |
| 定期清理：防止磁碟膨脹 | 環境重建腳本包含 cache 清理步驟文件化 |
| 避免 Snowflake Server | Dotfiles 版控確保所有環境修改可追溯、可重現 |
| 工作可攜性需求（Repository clone、Dotfiles、Claude Code config、開發工具鏈） | `scripts/setup-dev-env.sh` 腳本涵蓋全部四類資產 |

**ADR-012 對齊狀態：PASS**

---

## 相關文件

- [ADR-012：Claude Max 多開發環境認證架構決策](adr/ADR-012-max-account-rotation.md)
- [GCE 認證設定指引](gce-auth-guide.md)
- [環境重建流程文件](env-rebuild-guide.md)
- 實作腳本：`scripts/setup-dev-env.sh`
