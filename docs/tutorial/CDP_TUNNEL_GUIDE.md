# CDP 穿隧教學手冊 — 本地 Chrome 連接遠端 E2E 驗證

**最後更新**：2026-03-11（US-196 Sprint 74）

本教學說明如何透過 CDP（Chrome DevTools Protocol）穿隧，將本地 Chrome 瀏覽器連接至遠端伺服器，進行探索性 E2E 驗證。適用於 Sprint Review 時需要用本地瀏覽器操作遠端環境的場景。

---

## 前置條件

在開始之前，請確認以下工具和環境均已就緒：

### 必要工具

| 工具 | 版本需求 | 確認指令 |
|------|---------|---------|
| Google Chrome / Chromium | 任意版本（建議 115+） | `google-chrome --version` 或 `chromium --version` |
| SSH 客戶端 | 含 `-R` reverse tunnel 支援 | `ssh -V` |
| Node.js | 16+ | `node --version` |
| Playwright | 1.30+ | `npx playwright --version` |

### 環境需求

- **本地機器**：能執行 Chrome 並有 SSH 存取遠端伺服器的權限
- **遠端伺服器**：CDP port（預設 9222）未被其他程序佔用
- **SSH 存取**：可使用 key-based 或密碼認證登入遠端伺服器
- **WSL 使用者**：需額外設定（見 [Troubleshooting](#troubleshooting) 章節）

---

## 步驟一：啟動 Chrome Remote Debugging

在**本地機器**上以 remote debugging 模式啟動 Chrome，讓 Chrome 監聽 CDP 連線請求。

**Linux / WSL：**

```bash
google-chrome \
  --remote-debugging-port=9222 \
  --remote-debugging-address=127.0.0.1 \
  --no-first-run \
  --no-default-browser-check \
  --user-data-dir=/tmp/chrome-debug-profile
```

**macOS：**

```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 \
  --remote-debugging-address=127.0.0.1 \
  --no-first-run \
  --no-default-browser-check \
  --user-data-dir=/tmp/chrome-debug-profile
```

**Windows（Command Prompt）：**

```cmd
"C:\Program Files\Google\Chrome\Application\chrome.exe" ^
  --remote-debugging-port=9222 ^
  --remote-debugging-address=127.0.0.1 ^
  --no-first-run ^
  --no-default-browser-check ^
  --user-data-dir=C:\Temp\chrome-debug-profile
```

> Chrome 啟動後會在終端機輸出類似 `DevTools listening on ws://127.0.0.1:9222/...` 的訊息，代表 CDP 已就緒。

---

## 步驟二：建立 SSH Reverse Tunnel

在另一個終端機視窗，建立 SSH reverse tunnel，將**遠端伺服器**的 port 9222 對應到**本地機器**的 port 9222。

```bash
ssh -N -R 9222:127.0.0.1:9222 your_user@your-remote-server.example.com
```

**參數說明：**

| 參數 | 說明 |
|------|------|
| `-N` | 不執行遠端指令（只建立 tunnel） |
| `-R 9222:127.0.0.1:9222` | 遠端 9222 port → 本地 127.0.0.1:9222 |
| `your_user@your-remote-server.example.com` | SSH 登入資訊 |

執行後終端機會保持連線狀態（無輸出為正常）。**請保持此視窗開啟**，關閉視窗會中斷 tunnel。

**指定非標準 SSH port（如 2222）：**

```bash
ssh -N -p 2222 -R 9222:127.0.0.1:9222 your_user@your-remote-server.example.com
```

---

## 步驟三：使用 Playwright connectOverCDP 連線

在遠端伺服器上（或在 CI/測試腳本中），使用 Playwright 透過 CDP 連接本地 Chrome。

**Node.js 測試腳本範例：**

```javascript
const { chromium } = require('@playwright/test');

async function connectToLocalChrome() {
  // 透過 CDP 連接本地 Chrome（經由 SSH reverse tunnel）
  const browser = await chromium.connectOverCDP('http://127.0.0.1:9222');

  const context = browser.contexts()[0];
  const page = context.pages()[0] || await context.newPage();

  // 現在可以操作本地 Chrome 的頁面
  console.log('目前頁面 URL：', page.url());

  await page.goto('https://your-app-url.example.com');
  await page.screenshot({ path: 'screenshot.png' });

  console.log('截圖已儲存至 screenshot.png');
  await browser.close();
}

connectToLocalChrome().catch(console.error);
```

**Playwright Test 格式：**

```javascript
import { test, expect, chromium } from '@playwright/test';

test('透過 CDP 連接本地 Chrome', async () => {
  const browser = await chromium.connectOverCDP('http://127.0.0.1:9222');
  const context = browser.contexts()[0];
  const page = context.pages()[0] || await context.newPage();

  await page.goto('https://your-app-url.example.com');
  await expect(page).toHaveTitle(/預期標題/);

  await browser.close();
});
```

---

## 快速驗證穿隧是否成功

完成上述三個步驟後，執行以下 3 步驟確認穿隧正常運作：

**步驟 1**：確認本地 Chrome CDP endpoint 可存取

```bash
# 在遠端伺服器上執行
curl http://127.0.0.1:9222/json/version
```

預期輸出（含 Chrome 版本資訊）：

```json
{
  "Browser": "Chrome/120.0.6099.71",
  "Protocol-Version": "1.3",
  "User-Agent": "...",
  "V8-Version": "...",
  "WebKit-Version": "...",
  "webSocketDebuggerUrl": "ws://127.0.0.1:9222/devtools/browser/..."
}
```

**步驟 2**：列出目前 Chrome 開啟的分頁

```bash
# 在遠端伺服器上執行
curl http://127.0.0.1:9222/json/list
```

預期輸出：一個 JSON 陣列，每個元素代表一個分頁，含 `url`、`title`、`webSocketDebuggerUrl` 欄位。

**步驟 3**：執行最小 Playwright CDP 連線測試

```bash
# 在遠端伺服器上建立測試檔案並執行
node -e "
const { chromium } = require('@playwright/test');
chromium.connectOverCDP('http://127.0.0.1:9222').then(browser => {
  console.log('CDP 連線成功，瀏覽器版本：', browser.version());
  return browser.close();
}).catch(err => {
  console.error('CDP 連線失敗：', err.message);
  process.exit(1);
});
"
```

三步全部成功即代表穿隧設定正確，可進行 E2E 驗證。

---

## Troubleshooting

### T1：Port 衝突（port 9222 已被佔用）

**症狀**：Chrome 啟動時出現 `Address already in use` 或 SSH tunnel 建立失敗。

**確認方式：**

```bash
# 確認 9222 port 是否被佔用
lsof -i :9222
# 或
ss -tlnp | grep 9222
```

**解決步驟：**

1. 若是舊的 Chrome 程序，先關閉：`pkill -f "remote-debugging-port=9222"`
2. 若是其他程序佔用，改用不同 port（如 9223）：
   - Chrome 啟動加上 `--remote-debugging-port=9223`
   - SSH tunnel 改為 `-R 9223:127.0.0.1:9223`
   - Playwright 連線改為 `connectOverCDP('http://127.0.0.1:9223')`

---

### T2：防火牆阻擋 SSH Tunnel

**症狀**：`ssh -R` 指令無回應或連線逾時；`curl http://127.0.0.1:9222` 返回 `Connection refused`。

**確認方式：**

```bash
# 測試 SSH 連線是否正常
ssh -v your_user@your-remote-server.example.com echo "ok"

# 確認遠端 sshd 允許 reverse tunnel（GatewayPorts 設定）
ssh your_user@your-remote-server.example.com \
  "grep -E 'GatewayPorts|AllowTcpForwarding' /etc/ssh/sshd_config"
```

**解決步驟：**

1. 確認遠端伺服器的防火牆允許 SSH port（預設 22）入站連線
2. 若 `GatewayPorts` 為 `no` 或未設定，確認 tunnel 只需 loopback（`127.0.0.1`）即可，不需修改 sshd 設定
3. 若公司防火牆封鎖 SSH，可改用 443 port 的 SSH：`ssh -p 443 -R ...`（需遠端伺服器支援）
4. 若使用 VPN，確認 VPN 不會攔截 SSH 連線的 port forwarding

---

### T3：WSL（Windows Subsystem for Linux）特殊設定

**症狀**：在 WSL 中執行 Chrome 失敗，或從 WSL 建立的 SSH tunnel 本地無法存取 CDP。

**根本原因**：WSL 與 Windows 宿主機網路為不同虛擬網路介面，`127.0.0.1` 在 WSL 內指向 WSL 本身，而非 Windows 宿主機。

**解決方案 A（推薦）：在 Windows 宿主機啟動 Chrome**

1. 在 Windows PowerShell 或 Command Prompt 啟動 Chrome（見[步驟一](#步驟一啟動-chrome-remote-debugging)的 Windows 指令）
2. 取得 WSL 的 Windows 宿主機 IP：

```bash
# 在 WSL 中執行
cat /etc/resolv.conf | grep nameserver | awk '{print $2}'
# 或
ip route show | grep -i default | awk '{ print $3}'
```

3. 在 WSL 中建立 SSH tunnel，指向 Windows 宿主機 IP：

```bash
# 將 WINDOWS_HOST_IP 替換為上一步取得的 IP（通常形如 172.x.x.x）
ssh -N -R 9222:WINDOWS_HOST_IP:9222 your_user@your-remote-server.example.com
```

**解決方案 B：在 WSL 中使用 Chromium**

若必須在 WSL 中執行 Chrome：

```bash
# 安裝 Chromium（Debian/Ubuntu）
sudo apt-get install chromium-browser

# 啟動（需 WSL2 且已設定 X11 或 Wayland 顯示）
chromium-browser \
  --remote-debugging-port=9222 \
  --remote-debugging-address=0.0.0.0 \
  --headless \
  --no-sandbox \
  --user-data-dir=/tmp/chrome-debug-profile
```

> WSL2 Headless Chrome 使用 `--remote-debugging-address=0.0.0.0` 讓 tunnel 能正確路由，但需確認此設定不會暴露至非預期網路介面。

---

### T4：Playwright 連線逾時

**症狀**：執行 `connectOverCDP` 時收到 `Timeout` 或 `ECONNREFUSED` 錯誤。

**解決步驟：**

1. 先執行快速驗證的步驟 1 和步驟 2（`curl` 指令），確認 CDP endpoint 可存取
2. 確認 Playwright 版本支援 CDP 連線：`npx playwright --version`（需 1.30+）
3. 若 `curl` 成功但 Playwright 失敗，嘗試增加逾時設定：

```javascript
const browser = await chromium.connectOverCDP('http://127.0.0.1:9222', {
  timeout: 30000  // 30 秒
});
```

4. 確認 Chrome 尚未因閒置被系統關閉（Chrome 預設在無互動後可能休眠分頁）

---

## 完整操作流程總覽

```
本地機器                          遠端伺服器
─────────────────                ─────────────────────────────
[Chrome]                         [Playwright 測試腳本]
  ↓ CDP port 9222                      ↓ connectOverCDP
[localhost:9222] ←─ SSH Reverse Tunnel ─← [127.0.0.1:9222]
                  ssh -R 9222:127.0.0.1:9222
```

---

## 相關文件

- [Tutorial 目錄](./README.md) — 所有教學文件入口
- [GETTING_STARTED.md](./GETTING_STARTED.md) — Shikigami 安裝與第一個 Sprint
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) — 常見問題排查
- [US-197：E2E Server 端模板](../sprints/sprint_74.md) — 對應的 Server 端 Playwright workflow 模板
