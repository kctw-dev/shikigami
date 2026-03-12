#!/usr/bin/env node
/**
 * Shikigami Process Management MCP Server — Phase 1
 *
 * US-245 Sprint 89 — Sprint 流程狀態機 MCP Server
 *
 * 提供三個 MCP tools：
 * - get_current_step：取得當前流程步驟
 * - advance_step：推進至下一流程步驟（狀態持久化）
 * - get_remaining_steps：取得剩餘流程步驟清單
 *
 * 設計約束（ADR-019）：
 * - C1：MCP 不可達時 agent 可降級回直接讀取 sprint 文件
 * - C2：狀態持久化至檔案系統，重啟後恢復
 * - C3：零外部依賴，僅使用 @modelcontextprotocol/sdk
 *
 * Transport: stdio（與 ADR-013 決策一致）
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
  ErrorCode,
  McpError,
} from "@modelcontextprotocol/sdk/types.js";
import { resolve } from "node:path";
import { ProcessManager } from "./process-manager.js";

// ─── 環境設定 ─────────────────────────────────────────────────────────────────

const SHIKIGAMI_ROOT = process.env.SHIKIGAMI_ROOT
  ? resolve(process.env.SHIKIGAMI_ROOT)
  : resolve(import.meta.dirname, "../..");

const STATE_DIR = resolve(import.meta.dirname, "state");

// ─── 初始化 ProcessManager ────────────────────────────────────────────────────

const processManager = new ProcessManager({
  stateDir: STATE_DIR,
  shikiRoot: SHIKIGAMI_ROOT,
});

// ─── MCP Server 設定 ──────────────────────────────────────────────────────────

const server = new Server(
  {
    name: "shikigami-process-management",
    version: "0.1.0",
  },
  {
    capabilities: {
      tools: {},
      resources: {},
    },
  }
);

// ─── Tools 定義 ───────────────────────────────────────────────────────────────

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "get_current_step",
        description:
          "取得當前 Sprint 流程步驟。回傳當前步驟名稱、描述與剩餘步驟清單。" +
          "適用於 context compaction 後 agent 重新查詢流程位置，無需重新載入完整 sprint 文件。",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "advance_step",
        description:
          "推進至下一個 Sprint 流程步驟，並持久化狀態至檔案系統（C2）。" +
          "回傳 previous_step、current_step 與 is_final 標記。",
        inputSchema: {
          type: "object",
          properties: {
            sprint_number: {
              type: "number",
              description: "當前 Sprint 編號（可選，用於狀態記錄）",
            },
          },
        },
      },
      {
        name: "get_remaining_steps",
        description:
          "取得當前步驟之後的所有剩餘流程步驟清單，包含步驟名稱與描述。" +
          "適用於 agent 評估剩餘工作量與規劃執行序列。",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "get_fallback_info",
        description:
          "Fallback 機制（C1）：當 MCP Server 不可達時，此 tool 提供降級路徑資訊。" +
          "直接讀取 sprint 文件並回傳基本狀態資訊，讓 agent 能不中斷地繼續執行。",
        inputSchema: {
          type: "object",
          properties: {
            sprint_number: {
              type: "number",
              description: "Sprint 編號（如 89）",
            },
          },
          required: ["sprint_number"],
        },
      },
    ],
  };
});

// ─── Tool 執行邏輯 ────────────────────────────────────────────────────────────

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  switch (name) {
    case "get_current_step": {
      const result = processManager.getCurrentStep();
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(result, null, 2),
          },
        ],
      };
    }

    case "advance_step": {
      // 可選：更新 sprint_number
      if (args?.sprint_number != null) {
        processManager.setState({ sprintNumber: args.sprint_number });
      }

      const result = processManager.advanceStep();
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(result, null, 2),
          },
        ],
      };
    }

    case "get_remaining_steps": {
      const result = processManager.getRemainingSteps();
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(result, null, 2),
          },
        ],
      };
    }

    case "get_fallback_info": {
      const sprintNumber = args?.sprint_number;
      if (sprintNumber == null) {
        throw new McpError(ErrorCode.InvalidParams, "sprint_number 為必要參數");
      }

      const result = processManager.getFallbackInfo(sprintNumber);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(result, null, 2),
          },
        ],
      };
    }

    default:
      throw new McpError(ErrorCode.MethodNotFound, `未知工具：${name}`);
  }
});

// ─── Resources 定義 ───────────────────────────────────────────────────────────

server.setRequestHandler(ListResourcesRequestSchema, async () => {
  return {
    resources: [
      {
        uri: "process://current-step",
        name: "當前流程步驟",
        description: "當前 Sprint 流程步驟狀態（等同 get_current_step tool）",
        mimeType: "application/json",
      },
      {
        uri: "process://remaining-steps",
        name: "剩餘流程步驟",
        description: "當前步驟之後的剩餘步驟清單（等同 get_remaining_steps tool）",
        mimeType: "application/json",
      },
      {
        uri: "process://all-steps",
        name: "完整流程步驟定義",
        description: "Sprint 流程狀態機的完整步驟定義清單",
        mimeType: "application/json",
      },
    ],
  };
});

server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const { uri } = request.params;

  switch (uri) {
    case "process://current-step": {
      const result = processManager.getCurrentStep();
      return {
        contents: [
          {
            uri,
            mimeType: "application/json",
            text: JSON.stringify(result, null, 2),
          },
        ],
      };
    }

    case "process://remaining-steps": {
      const result = processManager.getRemainingSteps();
      return {
        contents: [
          {
            uri,
            mimeType: "application/json",
            text: JSON.stringify(result, null, 2),
          },
        ],
      };
    }

    case "process://all-steps": {
      const steps = processManager.getAllSteps();
      return {
        contents: [
          {
            uri,
            mimeType: "application/json",
            text: JSON.stringify({ steps }, null, 2),
          },
        ],
      };
    }

    default:
      throw new McpError(ErrorCode.InvalidRequest, `未知資源：${uri}`);
  }
});

// ─── 啟動 ─────────────────────────────────────────────────────────────────────

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  // MCP stdio server 不輸出 stdout（會干擾 MCP 協議）
  // 僅在 stderr 輸出狀態資訊
  process.stderr.write("Shikigami Process Management MCP Server 已啟動\n");
  process.stderr.write(`SHIKIGAMI_ROOT: ${SHIKIGAMI_ROOT}\n`);
  process.stderr.write(`STATE_DIR: ${STATE_DIR}\n`);
}

main().catch((err) => {
  process.stderr.write(`Fatal error: ${err.message}\n`);
  process.exit(1);
});
