# Shikigami Quality Observer MCP Server（POC）

> US-243 Sprint 88 — 品質觀察 MCP Server POC 實作

## 概覽

本 MCP Server 為 Shikigami MCP 三層架構中「品質觀察層」的 POC 實作，提供品質指標的結構化查詢能力，整合 `docs/km/Metrics_Log.md` 與 `docs/km/Quality_Observer.md`。

Transport 採用 **stdio**（與 ADR-013 決策一致）。

## 可用工具（Tools）

| Tool | 說明 |
|------|------|
| `get_velocity_trend` | 取得最近 N 個 Sprint 的 Velocity 趨勢分析 |
| `get_metrics_by_sprint` | 取得指定 Sprint 的完整指標數據 |
| `get_health_status` | 取得系統健康狀態快速評估（healthy/warning/critical） |
| `get_quality_observer_definition` | 取得 Quality Observer 角色定義文件內容 |

## 可用資源（Resources）

| Resource URI | 說明 |
|-------------|------|
| `quality://health/current` | 當前系統健康狀態 |
| `quality://trend/velocity` | 近 10 Sprint Velocity 趨勢 |
| `quality://observer/definition` | Quality Observer 角色定義 |

## 安裝與設定

### 1. 安裝依賴

```bash
cd mcp-servers/quality-observer
npm install
```

### 2. 在 .mcp.json 中加入設定

```json
{
  "mcpServers": {
    "shikigami-quality-observer": {
      "type": "stdio",
      "command": "node",
      "args": ["mcp-servers/quality-observer/index.js"],
      "env": {
        "SHIKIGAMI_ROOT": "${workspaceFolder}"
      }
    }
  }
}
```

### 3. 驗證

啟動後 stderr 應輸出：
```
Shikigami Quality Observer MCP Server 已啟動
SHIKIGAMI_ROOT: /path/to/shikigami-dev
```

## 環境變數

| 變數 | 說明 | 預設值 |
|------|------|--------|
| `SHIKIGAMI_ROOT` | Shikigami 專案根目錄路徑 | 相對路徑 `../..` |

## POC 限制

本 POC 為 US-243 RESEARCH Spike 的驗證實作，存在以下限制：

1. **只讀**：僅實作查詢 tools，不包含寫入（update/append）操作
2. **Metrics_Log 格式假設**：解析器假設固定的表格格式（Sprint N | 日期 | Velocity | 完成率 | 趨勢 | 備註）
3. **無快取**：每次 tool 呼叫都重新讀取文件
4. **無認證**：stdio 本機模式，無需認證（符合 ADR-013 §安全考量）

## 架構參考

- ADR-013：MCP 整合架構決策（stdio transport 決策來源）
- ADR-019：MCP 三層架構決策（本 POC 的決策輸出目標）
- US-228：Quality Observer 角色定義
- US-243：本 POC 起源 Story
