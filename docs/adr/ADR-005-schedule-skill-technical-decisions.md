# ADR-005：Schedule Skill 技術決策

**狀態**：Accepted
**日期**：2026-03-02
**決策者**：Architect
**挑戰者**：QA Engineer
**關聯 Issue**：#46（shikigami:schedule — Sprint 排程執行 + 權限 bypass 機制）

---

## 背景

Issue #46 要求實作 `shikigami:schedule` Skill，讓 Shikigami 的 Sprint 執行任務能以非互動式排程方式自動運行。此 Skill 涉及五個獨立但相互關聯的技術決策域：

1. **排程工具選型**：選擇在 Linux/macOS 使用者環境下觸發 Skill 執行的排程機制
2. **互斥鎖機制**：防止同一 Skill 因排程頻率設定不當而並行執行
3. **allowedTools 白名單權限模型**：非互動式環境下的工具授權策略
4. **API Key 注入策略**：cron 環境不繼承互動式 shell 環境變數的認證挑戰
5. **Post-deploy 回滾原子性策略**：排程部署失敗時的安全復原機制

這五個決策域均影響系統的安全性、可維護性與故障容忍度，需要明確的架構記錄。

---

## 決策域一：排程工具選型

### 決策問題

在 Linux/macOS 使用者環境下，`shikigami:schedule` 應採用什麼排程工具來觸發 Skill 執行？

### 選項分析

#### 選項 A：cron（採用）

Unix 標準排程工具，透過 `crontab` 管理週期性任務。

- 優點：Linux 與 macOS 環境均原生支援，無需安裝；crontab 語法廣為人知，學習門檻低；對 MVP 的週期性需求已足夠；使用者可透過 `crontab -l` 直接查看所有排程項目，透明度高
- 缺點：語法對初學者不直觀（五欄位格式）；缺乏內建的依賴管理（任務間無法宣告前置條件）；cron 環境的環境變數與互動式 shell 不同，需要額外處理
- 風險：若使用者系統未啟動 cron daemon（尤其是最小化安裝的 Linux），排程無法執行；macOS 上 cron 在 Ventura 後可能因 launchd 優先而被弱化

#### 選項 B：systemd timer

使用 systemd `.timer` unit 搭配 `.service` unit 實作排程。

- 優點：比 cron 更精確的時間控制；可利用 `systemctl` 查看排程狀態與歷史；支援 `OnBootSec` 等啟動後延遲觸發
- 缺點：僅適用於 Linux，macOS 不支援；需要寫入 `~/.config/systemd/user/` 並執行 `systemctl --user enable`，安裝步驟複雜；對非 Linux 使用者完全排除
- 風險：Shikigami 明確支援 macOS 使用者環境，systemd timer 無法跨平台，引入平台分歧

#### 選項 C：at 命令

使用 `at` 執行一次性延遲任務，搭配自我重新排程實作循環。

- 優點：部分發行版原生支援；可執行一次性任務
- 缺點：非週期性工具，自我重新排程實作脆弱；若任務失敗則排程中斷；`atd` daemon 在現代 Linux 發行版中常為未啟動狀態
- 風險：自我重新排程設計複雜度高，故障恢復能力低，維護負擔不成比例

#### 選項 D：自實作排程器

以 Bash 或 Python 實作常駐行程，定時觸發 Skill 執行。

- 優點：完全控制排程邏輯與錯誤處理
- 缺點：需要管理常駐行程的生命週期（啟動、停止、崩潰恢復）；實作複雜度與維護負擔最高；使用者需要額外步驟啟動常駐行程
- 風險：常駐行程崩潰後不會自動恢復，可靠性低於 OS 原生排程工具；YAGNI——MVP 階段完全沒有必要自建排程器

### 決策

**採用選項 A（cron）。**

理由：

1. **跨平台是首要條件**：Shikigami 的目標環境明確涵蓋 Linux 與 macOS 使用者環境，systemd timer 在此約束下自動排除
2. **MVP 原則**：cron 的功能完全滿足週期性排程需求，引入更複雜的方案違反 YAGNI 原則
3. **生態系熟悉度**：crontab 語法是開發者的通識技能，降低使用者的認知負擔
4. **OS 可靠性繼承**：排程可靠性由 OS cron daemon 保障，不需要 Shikigami 自行管理行程生命週期

---

## 決策域二：互斥鎖機制

### 決策問題

當排程週期設定短於 Skill 實際執行時間時，如何防止同一 Skill 的多個執行個體並行運行？

### 選項分析

#### 選項 A：flock（採用）

使用 `flock` 命令搭配鎖檔案建立排他鎖。

```bash
flock -n /tmp/shikigami-schedule-<project-hash>-<skill-name>.lock claude --skill ...
```

- 優點：進程死亡時 OS 自動釋放鎖，不殘留孤兒鎖；`-n`（non-blocking）模式在鎖被佔用時立即返回，而非等待；Linux 與 macOS 均原生支援；實作簡潔，一行完成
- 缺點：`flock` 是鎖定檔案描述符而非鎖定檔案本身，需確保包裝命令正確繼承 fd；macOS 上 `flock` 需透過 Homebrew 安裝（`brew install util-linux`），並非原生指令
- 風險：macOS 原生不帶 `flock`，需在 Preflight 中檢查可用性

#### 選項 B：lockfile 命令

使用 `lockfile`（procmail 套件）建立鎖檔案。

- 優點：Unix 傳統工具
- 缺點：進程崩潰後鎖檔案不自動清除，殘留的孤兒鎖導致後續執行永久阻塞；需安裝 procmail；殭屍鎖的手動清理增加維運負擔
- 風險：孤兒鎖問題在無人值守的排程環境中是嚴重的可靠性缺陷

#### 選項 C：mkdir 原子性

利用 `mkdir` 的原子性（僅能被一個行程成功建立）實作鎖。

- 優點：零外部依賴；跨平台
- 缺點：與 `lockfile` 相同的孤兒鎖問題——進程崩潰後目錄不自動清除；需要額外實作鎖過期機制（如記錄 PID 並偵測行程存活狀態）
- 風險：自製鎖機制複雜度增加，每個邊緣情況（PID 回收、NFS 掛載等）都需要額外處理

#### 選項 D：Redis 分散式鎖

使用 Redis 的 `SET NX PX` 命令實作鎖。

- 優點：支援跨機器分散式場景；TTL 自動過期
- 缺點：引入 Redis 外部依賴，完全不符合 Shikigami 的使用者環境假設；過度設計——單機排程場景完全不需要分散式鎖
- 風險：YAGNI 的極端反例，維護 Redis 基礎設施對個人開發者工具毫無意義

### 決策

**採用選項 A（flock）。**

理由：

1. **孤兒鎖自動清理是關鍵需求**：排程環境無人值守，進程崩潰後殘留鎖在選項 B、C 中會導致後續執行永久靜默失敗——這是最危險的故障模式。`flock` 的 fd 繫結語意由 OS 保障，不需要實作額外的清理機制
2. **一行實作、零維護**：`flock` 包裝整個命令，實作複雜度最低
3. **macOS 相容性風險可控**：在 Preflight 中偵測 `flock` 可用性，若不存在則提示使用者安裝（`brew install util-linux`），並在無 `flock` 時降級為警告後繼續（接受並行風險，明確記錄於文件）

**鎖檔案命名規範**：

```
/tmp/shikigami-schedule-<project-hash>-<skill-name>.lock
```

其中 `<project-hash>` 為專案目錄路徑的 MD5 前 8 碼，確保同一台機器上不同專案的鎖不會撞名：

```bash
PROJECT_HASH=$(echo "$PROJECT_DIR" | md5sum | cut -c1-8)
LOCK_FILE="/tmp/shikigami-schedule-${PROJECT_HASH}-${SKILL_NAME}.lock"
```

- 路徑使用 `/tmp/`：重開機自動清除，不汙染使用者 home 目錄
- 格式固定，方便排查：`ls /tmp/shikigami-schedule-*.lock` 可一次列出所有 Skill 的鎖狀態
- 加入 project-hash：同一台 VM 上多個專案排程相同 Skill 時不會互搶鎖

### 跨 Skill 序列鎖子節（US-36）

#### 背景

Schedule Skill 的 skill-level lock 只能防止同一 Skill 的多個執行個體並行——但當 Planning 與 Execution 兩個不同 Skill 同時觸發時，兩者會讀寫相同的共享檔案（如 `sprint_N.md`），產生讀寫競態條件。需要一個跨 Skill 的互斥機制。

#### 決策

引入 **group-level lock（群組鎖）**，透過 `--sequential-group <group-name>` 參數將多個 Skill 綁定至同一群組，共享一把群組鎖，確保群組內的 Skill 序列執行。

**group 鎖檔案命名規範**：

```
/tmp/shikigami-group-<project-hash>-<group-name>.lock
```

其中 `<project-hash>` 與 skill-level lock 相同（專案目錄路徑 MD5 前 8 碼）；`<group-name>` 為使用者指定的群組名稱：

```bash
GROUP_LOCK_FILE="/tmp/shikigami-group-${PROJECT_HASH}-${GROUP_NAME}.lock"
```

**鎖取得順序**（group lock 先於 skill lock）：

```
1. 嘗試 group lock（exec 201）— 若失敗則 SKIPPED，exit 0
2. 嘗試 skill lock（exec 200）— 若失敗則 SKIPPED，exit 0
3. 執行 Skill
```

group lock 優先於 skill lock 的理由：group lock 是更高層級的資源保護，必須在低層級的 Skill 互斥之前建立。若順序顛倒，可能導致 Skill 取得 skill lock 後，因 group lock 失敗而 SKIPPED，造成 skill lock 被持有而 Skill 未實際執行（group lock 不持有但 skill lock 持有的不一致狀態）。

**條件啟用**：group lock 僅在指定 `--sequential-group` 時啟用。未指定時腳本不含 group lock 邏輯，與 Sprint 18 行為完全相同（零破壞性變更）。

**鎖格式一覽**：

| 鎖類型 | 路徑格式 | fd | 保護範圍 |
|--------|----------|----|----------|
| skill-level lock | `/tmp/shikigami-schedule-<hash>-<skill-name>.lock` | 200 | 防止同 Skill 並行執行 |
| group-level lock | `/tmp/shikigami-group-<hash>-<group-name>.lock` | 201 | 防止同群組跨 Skill 並行執行 |

**Pre-flight group 衝突偵測**：

部署時若指定 `--sequential-group`，Pre-flight 額外檢查同群組是否已有執行中的排程（lock file 存在且被持有）。衝突時阻擋部署，要求使用者先移除衝突的 Skill 排程，防止在設計層面引入並行衝突。

---

## 決策域三：allowedTools 白名單權限模型

### 決策問題

`shikigami:schedule` 在非互動式環境（cron）呼叫 `claude` CLI 時，必須傳入 `--allowedTools` 參數以限制 AI 可使用的工具。需要決定：

1. Skill 如何聲明自己所需的工具集（`requiredTools`）
2. schedule 腳本如何讀取此聲明並轉換為 `--allowedTools` 參數
3. 若 Skill 無聲明，預設白名單為何
4. 版本化管理策略，避免 Skill 演進後排程靜默失敗

### 背景

此決策是整個 Schedule Skill 中安全性影響最大的技術選型。`--allowedTools` 是防止 claude CLI 在無人監督環境下執行超出預期範圍操作的唯一防線。設計缺陷會導致兩種對立的故障模式：

- **過於寬鬆**：AI 可能執行破壞性操作（如大範圍刪除檔案）而無人察覺
- **過於嚴格**：Skill 因缺少必要工具而靜默失敗，且使用者難以診斷原因

### 選項分析

#### 選項 A：SKILL.md frontmatter 聲明（採用）

在每個 SKILL.md 的 YAML frontmatter 新增 `requiredTools` 欄位：

```yaml
---
name: sprint-execution
description: "..."
requiredTools:
  - Read
  - Glob
  - Grep
  - Edit
  - Write
  - Bash
  - mcp__github__create_issue
---
```

schedule 腳本在生成 crontab 項目時，從 SKILL.md frontmatter 解析 `requiredTools` 清單，組裝為 `--allowedTools` 參數。

- 優點：聲明與 Skill 定義在同一檔案，版本控制原子性——SKILL.md 更新時 `requiredTools` 同步更新，不存在聲明與實作不同步的問題；frontmatter YAML 格式與現有慣例一致（`name`、`description` 欄位已採用此格式）；解析實作簡單（awk 提取 frontmatter 區塊）
- 缺點：frontmatter 解析需要正確處理 YAML 格式（特別是清單語法）；若 Skill 開發者忘記更新 `requiredTools`，排程可能因缺少工具而失敗
- 風險：frontmatter 格式錯誤（如縮排錯誤）導致解析失敗時，排程腳本需要有明確的錯誤處理路徑

#### 選項 B：獨立的 `schedule-manifest.yaml` 檔案

在每個 Skill 目錄下建立獨立的 `schedule-manifest.yaml`，集中宣告排程相關參數。

```yaml
# skills/sprint-execution/schedule-manifest.yaml
requiredTools:
  - Read
  - Edit
schedule:
  default: "0 9 * * 1"
```

- 優點：關注點分離——排程配置與 Skill 定義分開
- 缺點：新增檔案類型，增加 Skill 目錄的複雜度；使用者需要同時維護 `SKILL.md` 與 `schedule-manifest.yaml`，同步成本增加；不符合現有 Shikigami 的「SKILL.md 是唯一真相來源」原則
- 風險：兩個檔案描述同一 Skill 的屬性，長期維護容易出現不一致

#### 選項 C：schedule 腳本硬編碼每個 Skill 的工具清單

在 schedule 腳本內部維護一個 skill-to-tools 的映射表。

```bash
declare -A SKILL_TOOLS
SKILL_TOOLS["sprint-execution"]="Read Glob Edit Write Bash"
SKILL_TOOLS["backlog-management"]="Read Edit Write"
```

- 優點：實作最簡單
- 缺點：Skill 演進時必須同時更新 schedule 腳本，跨檔案維護，極易遺漏；schedule 腳本成為所有 Skill 的知識中心，違反單一職責原則；新增 Skill 時需修改 schedule 腳本，否則無法排程
- 風險：版本不同步是此選項的本質缺陷，無法透過流程規範根本解決

### 決策

**採用選項 A（SKILL.md frontmatter 聲明）。**

理由：

1. **版本控制原子性**：`requiredTools` 聲明與 Skill 實作在同一檔案，git commit 保證兩者同步更新，是三個選項中唯一能在架構層面防止版本漂移的方案
2. **符合現有慣例**：frontmatter YAML 格式是 Shikigami 框架既有標準，不引入新的檔案類型或格式
3. **SKILL.md 是唯一真相來源**：選項 B 和選項 C 均在 Skill 定義之外建立第二個知識來源，違反 DRY 原則

**預設白名單（當 SKILL.md 無 `requiredTools` 聲明時）**：

```
Read Glob Grep Edit Write Bash
```

理由：此六項工具涵蓋 Shikigami 絕大多數 Skill 的基本操作（讀檔、搜尋、編輯、執行）。選擇保守的預設值而非寬泛的白名單，符合最小權限原則（Principle of Least Privilege）。MCP 工具（如 `mcp__github__*`）不納入預設白名單，必須在 SKILL.md 中明確聲明。

**版本化管理策略**：

schedule 腳本在生成 crontab 項目時，記錄當時讀取的 SKILL.md 的 `requiredTools` 雜湊值（`md5sum` 或 `sha256sum`），並儲存於生成腳本的注釋區塊：

```bash
# shikigami-schedule-generated
# skill: sprint-execution
# requiredTools-hash: abc123def456
# generated-at: 2026-03-02T09:00:00
```

若 Skill 演進導致 `requiredTools` 變更，下次執行 `shikigami:schedule update` 時，腳本比對雜湊值，偵測到差異後提示使用者重新生成排程，防止靜默失敗。

**實作細節**：

frontmatter 解析採用 `awk` 提取 `---` 區塊後，以行掃描方式解析 `requiredTools` 清單，避免依賴 YAML 解析器：

```bash
parse_required_tools() {
  local skill_md="$1"
  awk '
    /^---/ { fm_count++; next }
    fm_count == 1 && /^requiredTools:/ { in_list=1; next }
    fm_count == 1 && in_list && /^  - / { gsub(/^  - /, ""); print; next }
    fm_count == 1 && in_list && !/^  - / { in_list=0 }
    fm_count == 2 { exit }
  ' "$skill_md"
}
```

---

## 決策域四：API Key 注入策略

### 決策問題

cron 環境不繼承互動式 shell 的環境變數（包含 `ANTHROPIC_API_KEY`）。`claude` CLI 支援兩種認證模式：API Key（`ANTHROPIC_API_KEY` 環境變數）與 OAuth（`~/.claude/` 目錄下的認證檔案）。需要決定 cron 環境下採用哪種認證策略。

### 背景

Issue #46 規格中出現 `unset ANTHROPIC_API_KEY` 的操作，其語意是：**主動清除 API Key 環境變數，強制 claude CLI 使用 OAuth 認證路徑**，而非將 API Key 注入 cron 環境。這是一個刻意的安全設計——避免 API Key 出現在 crontab 明文或腳本中。

### 選項分析

#### 選項 A：OAuth 認證（`~/.claude/` 認證檔案）（採用）

排程腳本不設定 `ANTHROPIC_API_KEY`，明確 `unset` 此環境變數，依賴 `~/.claude/` 目錄下的 OAuth 認證資料。

- 優點：認證資料不出現在腳本明文或 crontab 中，安全性最高；`~/.claude/` 的認證檔案在使用者登入後持久有效，不受 shell session 結束影響；符合 claude CLI 的設計意圖（互動式登入一次，後續自動使用）
- 缺點：OAuth token 有過期機制，若長期未使用，token 失效後排程靜默失敗；`~/.claude/` 認證狀態難以在腳本中程式化檢測
- 風險：OAuth token 過期是此策略最大的維運風險，必須在 Preflight 中明確檢測認證可用性

#### 選項 B：環境變數注入 API Key

在排程腳本中明文設定 `ANTHROPIC_API_KEY`，或從加密的金鑰儲存讀取後注入。

```bash
# 方式一：明文（危險）
export ANTHROPIC_API_KEY="sk-ant-..."

# 方式二：從檔案讀取
export ANTHROPIC_API_KEY=$(cat ~/.config/shikigami/api-key)
```

- 優點：認證不依賴 OAuth token 有效期，API Key 長期有效（直到手動撤銷）
- 缺點：API Key 出現在腳本或設定檔中，若腳本被意外讀取（如 `cat` 輸出至 log、git 意外追蹤），Key 洩漏風險高；即便加密儲存，解密過程在腳本中仍有安全疑慮；與 Issue #46 規格的 `unset ANTHROPIC_API_KEY` 設計方向相反
- 風險：API Key 洩漏對使用者帳號安全影響嚴重（可能產生未預期費用或資料外洩）

#### 選項 C：混合策略（優先 OAuth，fallback API Key）

先嘗試 OAuth，若認證不可用則 fallback 至環境變數中的 API Key。

- 優點：認證容錯性高
- 缺點：增加實作複雜度；fallback 路徑若靜默觸發，使用者可能不知道當前使用的是哪種認證方式；兩種認證路徑並存使 Preflight 檢測邏輯複雜化
- 風險：混合策略的複雜度不符合 KISS 原則，且 fallback 路徑引入的 API Key 安全風險並未消除

### 決策

**採用選項 A（OAuth 認證，`~/.claude/` 認證檔案）。**

理由：

1. **安全性優先**：API Key 明文出現在排程環境是不可接受的安全風險。OAuth 認證符合最小暴露原則——認證資料由 claude CLI 管理，不在 Shikigami 腳本的控制範圍內
2. **符合 Issue #46 規格意圖**：`unset ANTHROPIC_API_KEY` 的操作明確體現了設計者選擇 OAuth 路徑的意圖，本 ADR 確認並記錄此設計決策
3. **Preflight 必須含認證可用性驗證**：OAuth token 過期風險透過強制 Preflight 緩解——schedule 腳本在部署前（及每次執行前）驗證 `claude` CLI 能成功認證，若認證失敗則排程部署被阻止，並提示使用者執行 `claude auth login` 重新認證

**Preflight 認證驗證實作**：

```bash
preflight_check_auth() {
  # 主動清除 API Key，強制使用 OAuth 路徑
  unset ANTHROPIC_API_KEY

  # 驗證 claude CLI 認證狀態（使用最小化測試呼叫）
  if ! claude --version >/dev/null 2>&1; then
    echo "[ERROR] claude CLI 不可用，請確認安裝狀態"
    return 1
  fi

  # 驗證 OAuth 認證有效性
  if ! claude auth status >/dev/null 2>&1; then
    echo "[ERROR] claude OAuth 認證無效或已過期"
    echo "[INFO]  請執行: claude auth login"
    return 1
  fi

  echo "[PASS] 認證狀態驗證通過（OAuth）"
  return 0
}
```

**crontab 環境設定**：

生成的 crontab 項目明確清除 API Key 環境變數，並設定必要的 PATH：

```cron
# shikigami-schedule: sprint-execution
PATH=/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin
0 9 * * 1 unset ANTHROPIC_API_KEY; /path/to/shikigami-schedule-sprint-execution.sh
```

---

## 決策域五：Post-deploy 失敗回滾原子性策略

### 決策問題

`shikigami:schedule deploy` 執行過程包含多個副作用操作（生成腳本、更新 crontab）。若部署中途失敗，系統可能處於不一致狀態（腳本已生成但 crontab 未更新，或 crontab 已更新但腳本損毀）。需要定義回滾操作的順序、失敗時的 fallback 行為，以及使用者通知機制。

### 選項分析

#### 選項 A：無回滾（記錄錯誤後退出）

部署失敗時僅輸出錯誤訊息，不執行清理。

- 優點：實作最簡單
- 缺點：系統留在不一致狀態；crontab 可能指向損毀或不存在的腳本，導致後續排程靜默失敗；使用者必須手動清理
- 風險：靜默失敗是此選項最嚴重的問題——crontab 項目存在但腳本損毀，排程「看起來正常」但實際不執行

#### 選項 B：原子性回滾（採用）

部署前建立 crontab 快照，失敗時依固定順序回滾：先還原 crontab 快照，再刪除生成的腳本。

部署操作順序（建立順序）：
```
1. 建立 crontab 快照（crontab -l > /tmp/shikigami-crontab-backup-<timestamp>.bak）
2. 生成排程腳本（~/.shikigami/schedules/<skill-name>.sh）
3. 設定腳本執行權限（chmod +x）
4. 更新 crontab（crontab <new-crontab>）
```

回滾操作順序（反建立順序）：
```
1. 還原 crontab 快照（crontab /tmp/shikigami-crontab-backup-<timestamp>.bak）
2. 刪除生成的腳本（rm ~/.shikigami/schedules/<skill-name>.sh）
```

回滾順序的設計理由：**先還原 crontab，再刪除腳本**——確保在回滾過程中，crontab 不會指向一個正在被刪除的腳本（避免在回滾窗口期觸發的排程執行損毀腳本）。

- 優點：系統在失敗後回到部署前的確定狀態；回滾順序有明確設計理由，可稽核
- 缺點：回滾本身也可能失敗（磁碟滿、權限問題），需要定義 fallback 行為
- 風險：crontab 快照檔案儲存在 `/tmp/`，極少情況下可能被系統清除（此風險在快速部署場景中可接受）

#### 選項 C：二階段提交模擬

以「準備階段」與「提交階段」分離，準備階段生成腳本但不更新 crontab，驗證後才執行提交。

- 優點：在提交前有驗證視窗
- 缺點：Bash 腳本環境難以實現真正的二階段提交語意；驗證階段與實際執行環境差異可能導致驗證通過但執行失敗；複雜度遠超 MVP 需求
- 風險：模擬二階段提交的複雜度帶來更多潛在的實作 Bug，得不償失

### 決策

**採用選項 B（原子性回滾）。**

理由：

1. **靜默失敗是最危險的故障模式**：選項 A 的最大問題是系統在視覺上看似正常（crontab 項目存在）但實際排程失效，使用者難以察覺。選項 B 確保失敗後系統回到已知的乾淨狀態
2. **回滾順序有架構意義**：先還原 crontab 再刪除腳本的順序，防止在回滾窗口期觸發損毀腳本執行，這是一個有安全含義的設計決策
3. **複雜度可控**：原子性回滾在 Bash 中以 `trap ERR` 實作，不引入架構複雜度

**回滾本身失敗時的 Fallback 行為**：

回滾失敗通常發生於磁碟問題或系統異常，此時無法繼續自動化處理，必須將控制權交還使用者。Fallback 行為為：

```
1. 輸出明確的錯誤訊息，說明哪個回滾步驟失敗
2. 輸出手動回滾指引：
   - 手動還原 crontab：crontab /tmp/shikigami-crontab-backup-<timestamp>.bak
   - 手動刪除腳本：rm ~/.shikigami/schedules/<skill-name>.sh
3. 輸出快照檔案路徑，讓使用者可以手動操作
4. 以 exit code 2 退出（區別於正常失敗的 exit code 1）
```

**使用者通知機制**：

| 事件 | 通知方式 | 通知內容 |
|------|----------|----------|
| 部署成功 | stdout `[PASS]` 訊息 | 腳本路徑、crontab 項目預覽、下次執行時間 |
| 部署失敗，回滾成功 | stdout `[ERROR]` + `[INFO]` 訊息 | 失敗原因、已成功回滾至部署前狀態 |
| 部署失敗，回滾失敗 | stdout `[ERROR]` 訊息 + 手動指引 | 失敗原因、手動回滾步驟、快照檔案路徑 |
| 認證驗證失敗（Preflight） | stdout `[ERROR]` 訊息 | 認證失敗原因、`claude auth login` 指引 |

**實作骨架**：

```bash
CRONTAB_BACKUP=""
SCRIPT_GENERATED=false

rollback() {
  local exit_code=$?
  echo "[ERROR] 部署失敗（exit code: ${exit_code}），開始回滾..."

  # Step 1：還原 crontab（優先）
  if [[ -n "$CRONTAB_BACKUP" ]] && [[ -f "$CRONTAB_BACKUP" ]]; then
    if crontab "$CRONTAB_BACKUP"; then
      echo "[INFO] crontab 已還原至部署前狀態"
    else
      echo "[ERROR] crontab 還原失敗！請手動執行："
      echo "        crontab ${CRONTAB_BACKUP}"
      exit 2
    fi
  fi

  # Step 2：刪除生成的腳本
  if [[ "$SCRIPT_GENERATED" == "true" ]] && [[ -f "$SCHEDULE_SCRIPT_PATH" ]]; then
    rm -f "$SCHEDULE_SCRIPT_PATH"
    echo "[INFO] 排程腳本已刪除：${SCHEDULE_SCRIPT_PATH}"
  fi
}

trap rollback ERR
```

---

## 整體決策摘要

| 決策域 | 選擇 | 核心理由 |
|--------|------|----------|
| 排程工具 | cron | 跨平台（Linux/macOS）、零依賴、MVP 足夠 |
| 互斥鎖 | flock | 進程死亡自動釋放，不殘留孤兒鎖 |
| allowedTools | SKILL.md frontmatter `requiredTools` | 版本控制原子性，防止聲明與實作漂移 |
| API Key 注入 | OAuth（`~/.claude/`），明確 `unset ANTHROPIC_API_KEY` | 安全性優先，API Key 不出現在腳本明文 |
| Post-deploy 回滾 | 原子性回滾（先還原 crontab，再刪除腳本） | 防止靜默失敗，回滾順序有安全含義 |

---

## 影響

### 對 SKILL.md 格式的影響

所有計劃排程執行的 Skill 必須在 frontmatter 新增 `requiredTools` 欄位。此為**可選欄位**——無聲明時使用預設白名單，不影響現有 Skill 的正常互動式使用。

### 對 Preflight 的影響

schedule 腳本的 Preflight 必須驗證：

1. `flock` 可用性（macOS 可能需要 `brew install util-linux`）
2. `claude` CLI 已安裝
3. OAuth 認證狀態有效（`claude auth status`）
4. 目標 Skill 的 SKILL.md 存在且 frontmatter 格式正確

### 對維運的影響

- OAuth token 過期是主要的維運風險，使用者需要定期執行 `claude auth login` 更新認證
- lock file 存放於 `/tmp/`，重開機後自動清除，無需手動維護
- crontab 快照存放於 `/tmp/`，僅在部署操作期間需要，不作為長期備份

---

## Decision Challenge（QA Engineer）

**挑戰**：allowedTools 白名單的版本化雜湊機制被過度樂觀估計。雜湊比對僅在執行 `shikigami:schedule update` 時觸發，但 Skill 演進（新增工具需求）發生在任何 Sprint 的任何時刻。若使用者在 Skill 演進後忘記執行 `update`，排程會使用舊的 `--allowedTools` 繼續執行，導致 Skill 因缺少新增的工具而部分失敗——而這個失敗是靜默的，不會觸發任何警報。雜湊比對機制只有在使用者主動觸發時才有效，防護效力有限。

**反駁**：此挑戰精準指出了雜湊比對的條件性限制，但忽略了三個緩解層次。第一，`requiredTools` 的擴充在 Skill 演進時通常伴隨 AC 執行失敗——當 Skill 嘗試呼叫未在白名單中的工具時，claude CLI 會返回明確的工具拒絕錯誤，這個錯誤會出現在排程的執行日誌中，並非完全靜默。第二，雜湊比對是一個主動防護機制，覆蓋「使用者知道要更新但忘記觸發」的場景；執行日誌錯誤覆蓋「使用者不知道 Skill 已更新」的場景，兩者互補而非對立。第三，完全自動的偵測（如 inotify 監控 SKILL.md 變更後自動重新部署）屬於 YAGNI——在 MVP 階段引入檔案監控守護進程超出合理複雜度邊界。

**結論**：同意 ADR-005 的決策方向，建議將「Skill 演進後需執行 `shikigami:schedule update`」明確記錄於 schedule SKILL.md 的使用指引中，並在 Sprint Review 的 DoD checklist 新增「排程 Skill 的 requiredTools 是否與最新 SKILL.md 同步」的確認項目。

---

## Stakeholder Review 修訂記錄

### 修訂一：鎖檔案命名加入 project-hash（2026-03-02）

**提出者**：Stakeholder

**問題**：原始設計的鎖檔案命名為 `/tmp/shikigami-schedule-<skill-name>.lock`，僅以 Skill 名稱區分。若同一台 VM 上有多個 Shikigami 專案（例如 project-A 和 project-B）同時排程相同 Skill（如 `sprint-execution`），兩個專案會共用同一把鎖，導致其中一個被 flock 判定為「前一執行個體仍在跑」而 skip — 這是一個 Architect 與 QA 三輪審查均未識別的多租戶撞名缺陷。

**修正**：鎖檔案命名改為 `/tmp/shikigami-schedule-<project-hash>-<skill-name>.lock`，其中 `<project-hash>` 為專案目錄路徑的 MD5 前 8 碼，確保不同專案的鎖互不干涉。

**影響範圍**：決策域二（互斥鎖機制）的命名規範。決策本身（採用 flock）不變。
