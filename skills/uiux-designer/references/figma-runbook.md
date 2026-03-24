# Figma MCP 環境健康檢查 Runbook

> 摘錄自 `skills/uiux-designer/SKILL.md` §13
> <!-- US-209：ADR-016 OQ-4 Figma MCP 環境健康檢查 Runbook — Sprint 79 -->

**目的**：DESIGN Story 啟動前，依序確認 4 個依賴項均正常運作。任一依賴失敗即中止啟動，執行對應恢復步驟後重新從頭驗證。

**執行時機**：
- DESIGN Story 進入 Sprint 執行前（§4.1 啟動前提確認）
- `story-lifecycle-prompt.md` §4.5 DESIGN path pre-flight 檢查
- 任何 Figma MCP 工具呼叫出現連線異常後

---

## 檢查序列總覽

```
依賴 1：Figma Desktop App 啟動
  ↓ PASS
依賴 2：Plugin 連接（cursor-talk-to-figma-plugin 已載入並回應）
  ↓ PASS
依賴 3：CLI Server 啟動（WebSocket Server 監聽 ws://localhost:3000）
  ↓ PASS
依賴 4：MCP 連接（talk-to-figma-mcp 已連接至 Claude Code）
  ↓ PASS
環境就緒，DESIGN Story 可啟動
```

**重要**：必須按順序執行。依賴 2 需要依賴 1 就緒，依賴 3 需要獨立啟動，依賴 4 需要依賴 3 就緒。

---

## 依賴 1：Figma Desktop App

| 項目 | 內容 |
|------|------|
| 說明 | Figma Desktop App 是 Plugin API 的唯一執行環境。Plugin 無法在 Figma Web 版運行，因此 Figma Desktop App 必須啟動且目標設計文件已載入 |
| 檢查方式 | 視覺確認：Figma Desktop App 視窗已開啟，目標設計文件（專案 Figma 文件）可見於 Tab 列 |
| 預期正常結果 | Figma Desktop App 視窗可見，設計文件已載入，畫布可操作 |

**失敗恢復步驟**：

1. 啟動 Figma Desktop App（若未安裝，從 [figma.com/downloads](https://www.figma.com/downloads/) 下載安裝）
2. 登入 Figma 帳號
3. 開啟目標設計文件（從 Recent 或 Figma 雲端文件清單選取）
4. 等待文件完全載入（畫布顯示設計內容，非載入 spinner）
5. 回到依賴 1 確認：視窗可見且文件已載入 → PASS

---

## 依賴 2：Plugin 連接

| 項目 | 內容 |
|------|------|
| 說明 | `cursor-talk-to-figma-plugin`（KCTW fork Plugin）必須在 Figma Desktop App 內載入並與 CLI Server 建立 WebSocket 連線。Plugin 作為 Figma Plugin API 與外部 CLI Server 的橋接層 |
| 檢查方式 | 在 Figma Desktop App 中：選單 Plugins → Development → cursor-talk-to-figma-plugin → 確認 Plugin UI 顯示連線狀態 |
| 預期正常結果 | Plugin UI 顯示 "Connected"（或綠色連線指示燈），Channel ID 已分配 |

**失敗恢復步驟**：

**情境 A：Plugin 未安裝**
1. 在 Figma Desktop 中：Plugins → Development → Import plugin from manifest
2. 選取 `KCTW/talk-to-figma-mcp` repo 中的 Plugin 目錄（`cursor-talk-to-figma-plugin/manifest.json`）
3. 重新啟動 Plugin：Plugins → Development → cursor-talk-to-figma-plugin

**情境 B：Plugin 已安裝但顯示 "Disconnected" 或無法開啟**
1. 先確認依賴 3（CLI Server）是否已啟動——Plugin 連線需要 CLI Server 先就緒
2. CLI Server 就緒後，在 Figma 中關閉並重新開啟 Plugin
3. 若仍顯示 Disconnected，檢查 Plugin console（Plugins → Development → Open Console）確認錯誤訊息
4. 常見錯誤：`WebSocket connection failed` → CLI Server 未啟動（先解決依賴 3）
5. 常見錯誤：`Authentication failed` → ECDSA P-256 金鑰不匹配，確認 CLI Server 與 Plugin 使用相同金鑰設定

**情境 C：Plugin 顯示 Connected 但無回應**
1. 關閉 Plugin，等待 3 秒後重新開啟
2. 若仍無回應，重新載入 Figma 文件（File → Reload File）
3. 重新開啟 Plugin

---

## 依賴 3：CLI Server

| 項目 | 內容 |
|------|------|
| 說明 | `talk-to-figma-mcp` 的 WebSocket CLI Server 必須在本機啟動並監聽 `ws://localhost:3000`。CLI Server 是 Plugin（Figma 端）與 MCP Server（Claude Code 端）的中間層 |
| 檢查方式 | 在 terminal 執行：`curl -s --max-time 3 http://localhost:3000/health` 或 `nc -zv localhost 3000` |
| 預期正常結果 | curl 回傳 HTTP 200 響應（或 nc 顯示 `Connection succeeded`），表示 port 3000 正在監聽 |

**失敗恢復步驟**：

**情境 A：CLI Server 未啟動**
1. 進入 `KCTW/talk-to-figma-mcp` 目錄
2. 啟動 CLI Server：
   ```bash
   cd /path/to/talk-to-figma-mcp
   npm run socket
   # 或依專案設定使用
   node src/socket.js
   ```
3. 確認 terminal 輸出 `WebSocket server listening on port 3000`
4. 重新執行檢查指令確認 port 3000 已監聽

**情境 B：Port 3000 被其他程序佔用**
1. 找出佔用程序：`lsof -i :3000` 或 `ss -tlnp | grep 3000`
2. 若為舊版 CLI Server 程序：`kill <PID>` 後重新啟動
3. 若為其他程序且無法釋放 port：修改 CLI Server 設定使用其他 port（並同步更新 MCP 連線設定）

**情境 C：CLI Server 啟動後立即崩潰**
1. 確認 Node.js 版本相容性（建議 Node.js 18+）：`node --version`
2. 確認依賴已安裝：`npm install`
3. 查看 CLI Server 錯誤 log，解決對應錯誤後重試

---

## 依賴 4：MCP 連接

| 項目 | 內容 |
|------|------|
| 說明 | `talk-to-figma-mcp` MCP Server 必須已在 Claude Code 的 MCP 設定中啟用，且已成功連接至 CLI Server。MCP Server 是 Claude Code 呼叫 Figma 工具的入口 |
| 檢查方式 | 在 Claude Code 中嘗試呼叫任意 `talk-to-figma-mcp` 工具，例如：`get_document_info` 或 `get_local_components`，確認工具有回應（非 timeout 或 MCP 錯誤） |
| 預期正常結果 | 工具呼叫成功回傳結果（即使文件無內容也會回傳空結果，而非連線錯誤） |

**失敗恢復步驟**：

**情境 A：MCP Server 未在 Claude Code 設定中啟用**
1. 開啟 Claude Code MCP 設定（`~/.claude/claude_desktop_config.json` 或對應設定檔）
2. 確認 `talk-to-figma-mcp` 已加入 `mcpServers` 清單：
   ```json
   {
     "mcpServers": {
       "talk-to-figma-mcp": {
         "command": "node",
         "args": ["/path/to/talk-to-figma-mcp/build/index.js"]
       }
     }
   }
   ```
3. 重新啟動 Claude Code 使設定生效
4. 重新執行工具呼叫確認

**情境 B：MCP Server 已設定但連線失敗（timeout 或 connection refused）**
1. 先確認依賴 3（CLI Server）是否正常運作——MCP Server 連線需要 CLI Server 就緒
2. CLI Server 正常後，在 Claude Code 中重新載入 MCP 連線（若支援 MCP reload 指令）
3. 若無法 reload，重新啟動 Claude Code

**情境 C：MCP 工具呼叫回傳認證錯誤（ECDSA P-256 相關）**
1. 確認 MCP Server 與 CLI Server 使用相同的 ECDSA P-256 金鑰設定
2. 若金鑰不一致，依 `KCTW/talk-to-figma-mcp` 文件重新生成並設定金鑰對
3. 重啟 CLI Server 與 Claude Code 後重試

---

## Health Check 執行清單（快速版）

```
Figma MCP Health Check — DESIGN Story 啟動前確認

依賴 1：Figma Desktop App
- [ ] Figma Desktop App 視窗已開啟
- [ ] 目標設計文件已載入（畫布可見）
→ PASS / FAIL（執行依賴 1 恢復步驟）

依賴 2：Plugin 連接
- [ ] cursor-talk-to-figma-plugin 已在 Figma 中開啟
- [ ] Plugin UI 顯示 "Connected"
→ PASS / FAIL（執行依賴 2 恢復步驟）

依賴 3：CLI Server
- [ ] ws://localhost:3000 正在監聽（curl/nc 確認）
→ PASS / FAIL（執行依賴 3 恢復步驟）

依賴 4：MCP 連接
- [ ] talk-to-figma-mcp 工具呼叫成功回傳結果
→ PASS / FAIL（執行依賴 4 恢復步驟）

整體結論：READY（4 項全 PASS）/ NOT READY（任一 FAIL，解決後重新從頭確認）
```

**READY 後方可啟動 DESIGN Story 執行流程（§4）。**
