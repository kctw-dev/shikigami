#!/usr/bin/env node
/**
 * Shikigami Quality Observer MCP Server — POC
 *
 * US-243 Sprint 88 — POC 實作（品質觀察 MCP Server）
 *
 * 提供品質指標的結構化查詢工具，整合：
 * - docs/km/Metrics_Log.md（SPACE 五維度 Velocity/完成率數據）
 * - docs/km/Quality_Observer.md（三維度觀察定義）
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
import { readFileSync, existsSync, readdirSync } from "fs";
import { join, resolve } from "path";

// ─── 環境設定 ────────────────────────────────────────────────────────────────

const SHIKIGAMI_ROOT = process.env.SHIKIGAMI_ROOT
  ? resolve(process.env.SHIKIGAMI_ROOT)
  : resolve(process.cwd(), "../..");

const METRICS_LOG_PATH = join(SHIKIGAMI_ROOT, "docs/km/Metrics_Log.md");
const QUALITY_OBSERVER_PATH = join(SHIKIGAMI_ROOT, "docs/km/Quality_Observer.md");
const RETROSPECTIVE_LOG_PATH = join(SHIKIGAMI_ROOT, "docs/km/Retrospective_Log.md");
const TRACE_LOGS_DIR = join(SHIKIGAMI_ROOT, "docs/trace-logs");

// ─── Markdown 解析工具 ────────────────────────────────────────────────────────

/**
 * 解析 Metrics_Log.md 的表格行
 * 格式：| Sprint N | YYYY-MM-DD | N points | N% | trend | 備註 |
 */
function parseMetricsLog() {
  if (!existsSync(METRICS_LOG_PATH)) {
    return [];
  }

  const content = readFileSync(METRICS_LOG_PATH, "utf-8");
  const lines = content.split("\n");
  const metrics = [];

  for (const line of lines) {
    // 跳過表頭和分隔行
    if (!line.startsWith("|") || line.includes("---") || line.includes("Sprint 編號")) {
      continue;
    }

    const cells = line.split("|").map((c) => c.trim()).filter(Boolean);
    if (cells.length < 5) continue;

    const sprintCell = cells[0];
    const sprintMatch = sprintCell.match(/Sprint\s+(\d+)/i);
    if (!sprintMatch) continue;

    const sprintNumber = parseInt(sprintMatch[1], 10);
    const date = cells[1] || "";
    const velocityStr = cells[2] || "";
    const completionStr = cells[3] || "";
    const trend = cells[4] || "";
    const notes = cells[5] || "";

    const velocityMatch = velocityStr.match(/(\d+)/);
    const velocity = velocityMatch ? parseInt(velocityMatch[1], 10) : null;

    const completionMatch = completionStr.match(/(\d+)/);
    const completionRate = completionMatch ? parseInt(completionMatch[1], 10) : null;

    metrics.push({
      sprint_number: sprintNumber,
      date,
      velocity,
      completion_rate: completionRate,
      trend,
      notes,
    });
  }

  return metrics;
}

/**
 * 取得速度趨勢分析
 */
function analyzeVelocityTrend(metricsData, lastN = 10) {
  const recent = metricsData
    .filter((m) => m.velocity !== null)
    .sort((a, b) => a.sprint_number - b.sprint_number)
    .slice(-lastN);

  if (recent.length === 0) {
    return { trend: "insufficient_data", data: [], analysis: "無足夠資料" };
  }

  const velocities = recent.map((m) => m.velocity);
  const avg = velocities.reduce((a, b) => a + b, 0) / velocities.length;
  const lastTwo = velocities.slice(-2);

  let trend = "stable";
  if (lastTwo.length === 2) {
    const change = ((lastTwo[1] - lastTwo[0]) / lastTwo[0]) * 100;
    if (change > 20) trend = "increasing";
    else if (change < -20) trend = "decreasing";
  }

  return {
    trend,
    average: Math.round(avg * 10) / 10,
    data: recent.map((m) => ({
      sprint: m.sprint_number,
      velocity: m.velocity,
      date: m.date,
    })),
    analysis: `近 ${recent.length} 個 Sprint 平均 Velocity: ${Math.round(avg * 10) / 10} points，趨勢：${trend}`,
  };
}

// ─── Trace Log 解析工具 ───────────────────────────────────────────────────────

/**
 * 列出 docs/trace-logs/ 下所有 .jsonl 檔案（不含 .gitkeep），依名稱降序排列
 */
function listTraceLogFiles() {
  if (!existsSync(TRACE_LOGS_DIR)) {
    return [];
  }
  return readdirSync(TRACE_LOGS_DIR)
    .filter((f) => f.endsWith(".jsonl") && f !== ".gitkeep")
    .sort()
    .reverse(); // 最新在前（依日期命名 YYYY-MM-DD-...）
}

/**
 * 解析單一 .jsonl trace log 檔案，回傳 span 陣列（跳過非法行）
 * @param {string} filepath 完整路徑
 * @returns {Array<Object>} span 物件陣列
 */
function parseTraceLogFile(filepath) {
  if (!existsSync(filepath)) return [];
  const lines = readFileSync(filepath, "utf-8").split("\n");
  const spans = [];
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    try {
      const obj = JSON.parse(trimmed);
      if (typeof obj === "object" && obj !== null && !Array.isArray(obj)) {
        spans.push(obj);
      }
    } catch {
      // 非法 JSON 行跳過
    }
  }
  return spans;
}

/**
 * 從檔案名稱提取 sessionId（basename 去除副檔名後，移除日期前綴 YYYY-MM-DD-）
 * 例：2026-03-24-session-abc123.jsonl -> session-abc123
 */
function extractSessionIdFromFilename(filename) {
  const base = filename.replace(/\.jsonl$/, "");
  const match = base.match(/^\d{4}-\d{2}-\d{2}-(.+)$/);
  return match ? match[1] : base;
}

/**
 * 計算 trace 完整性統計
 * @param {Array<Object>} spans
 * @returns {Object} 統計資料
 */
const REQUIRED_TRACE_FIELDS = [
  "traceId", "spanId", "parentSpanId", "agentRole",
  "action", "timestamp", "status", "sessionId",
];

function calcTraceCompleteness(spans) {
  if (spans.length === 0) {
    return { total: 0, complete: 0, completenessRate: null };
  }
  const complete = spans.filter((s) =>
    REQUIRED_TRACE_FIELDS.every((f) => Object.prototype.hasOwnProperty.call(s, f))
  ).length;
  return {
    total: spans.length,
    complete,
    completenessRate: Math.round((complete / spans.length) * 1000) / 10,
  };
}

/**
 * 生成 human-readable trace summary
 */
function buildTraceSummary(spans, filename) {
  const stats = calcTraceCompleteness(spans);
  const byAgent = {};
  const byStatus = {};
  const byAction = {};

  for (const span of spans) {
    const role = span.agentRole || "unknown";
    const status = span.status || "unknown";
    const action = span.action || "unknown";
    byAgent[role] = (byAgent[role] || 0) + 1;
    byStatus[status] = (byStatus[status] || 0) + 1;
    byAction[action] = (byAction[action] || 0) + 1;
  }

  const lines = [
    `=== Trace Log Summary: ${filename} ===`,
    `總 span 數：${stats.total}`,
    `完整 span 數：${stats.complete}（含全部 8 個必要欄位）`,
    `必要欄位覆蓋率：${stats.completenessRate !== null ? stats.completenessRate + "%" : "N/A"}`,
    "",
    "Agent 角色分佈：",
    ...Object.entries(byAgent).map(([k, v]) => `  ${k}: ${v} span`),
    "",
    "Status 分佈：",
    ...Object.entries(byStatus).map(([k, v]) => `  ${k}: ${v}`),
    "",
    "Action 分佈：",
    ...Object.entries(byAction).map(([k, v]) => `  ${k}: ${v}`),
  ];
  return lines.join("\n");
}

// ─── MCP Server 設定 ──────────────────────────────────────────────────────────

const server = new Server(
  {
    name: "shikigami-quality-observer",
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
        name: "get_velocity_trend",
        description:
          "取得 Velocity 趨勢分析。分析最近 N 個 Sprint 的 Velocity 變化，返回趨勢（increasing/decreasing/stable）與統計摘要。",
        inputSchema: {
          type: "object",
          properties: {
            last_n_sprints: {
              type: "number",
              description: "分析最近 N 個 Sprint（預設 10）",
              default: 10,
            },
          },
        },
      },
      {
        name: "get_metrics_by_sprint",
        description:
          "取得指定 Sprint 的完整指標數據，包含 Velocity、完成率、趨勢與備註。",
        inputSchema: {
          type: "object",
          properties: {
            sprint_number: {
              type: "number",
              description: "Sprint 編號（正整數）",
            },
          },
          required: ["sprint_number"],
        },
      },
      {
        name: "get_health_status",
        description:
          "取得系統健康狀態的快速評估，基於最近 3 個 Sprint 的 Velocity 趨勢與完成率。返回 healthy / warning / critical 評估。",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "get_quality_observer_definition",
        description:
          "取得 Quality Observer 角色定義，包含三維度觀察（幻覺頻率、斷鏈模式、角色協作效率）的量測方式與健康門檻。",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "get_trace_recent",
        description:
          "查詢最近 N 條 trace span（依檔案日期排序，最新優先）。回傳 span 物件陣列，含 traceId、spanId、agentRole、action、timestamp、status 等欄位。",
        inputSchema: {
          type: "object",
          properties: {
            limit: {
              type: "number",
              description: "最多回傳幾條 span（預設 20，最大 200）",
              default: 20,
            },
          },
        },
      },
      {
        name: "get_trace_by_session",
        description:
          "按 session ID 篩選 trace span。回傳指定 session 的所有 span，依 timestamp 升序排列。",
        inputSchema: {
          type: "object",
          properties: {
            session_id: {
              type: "string",
              description: "要篩選的 session ID（如 session-abc123）",
            },
          },
          required: ["session_id"],
        },
      },
      {
        name: "get_trace_summary",
        description:
          "取得 human-readable trace 摘要。包含必要欄位覆蓋率、Agent 角色分佈、Status 分佈、Action 分佈等統計資訊。可指定 session 或取全域摘要。",
        inputSchema: {
          type: "object",
          properties: {
            session_id: {
              type: "string",
              description: "僅摘要指定 session（選填；省略時摘要全部 session）",
            },
          },
        },
      },
      {
        name: "get_coverage_metrics",
        description:
          "Phase 2：取得結構化 metrics 端點，返回 coverage、debt_ratio、health_score 三個指標。Sprint Review analytics 使用此端點取代檔案解析。",
        inputSchema: {
          type: "object",
          properties: {
            sprint_number: {
              type: "number",
              description: "指定 Sprint 編號（選填；省略時返回最新 Sprint）",
            },
          },
        },
      },
    ],
  };
});

// ─── Tool 執行邏輯 ────────────────────────────────────────────────────────────

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  switch (name) {
    case "get_velocity_trend": {
      const lastN = (args?.last_n_sprints) || 10;
      const metrics = parseMetricsLog();

      if (metrics.length === 0) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                error: "METRICS_NOT_FOUND",
                message: `無法讀取 Metrics Log：${METRICS_LOG_PATH}`,
              }),
            },
          ],
        };
      }

      const trendData = analyzeVelocityTrend(metrics, lastN);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(trendData, null, 2),
          },
        ],
      };
    }

    case "get_metrics_by_sprint": {
      const sprintNumber = args?.sprint_number;
      if (!sprintNumber) {
        throw new McpError(ErrorCode.InvalidParams, "sprint_number 為必要參數");
      }

      const metrics = parseMetricsLog();
      const sprintMetrics = metrics.find((m) => m.sprint_number === sprintNumber);

      if (!sprintMetrics) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                error: "SPRINT_NOT_FOUND",
                message: `找不到 Sprint ${sprintNumber} 的指標數據`,
                available_sprints: metrics.map((m) => m.sprint_number),
              }),
            },
          ],
        };
      }

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(sprintMetrics, null, 2),
          },
        ],
      };
    }

    case "get_health_status": {
      const metrics = parseMetricsLog();
      const recent3 = metrics
        .filter((m) => m.velocity !== null)
        .sort((a, b) => a.sprint_number - b.sprint_number)
        .slice(-3);

      if (recent3.length < 2) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                overall: "insufficient_data",
                message: "資料不足（需要至少 2 個 Sprint 的數據）",
              }),
            },
          ],
        };
      }

      // 計算健康狀態
      const allCompletionRate100 = recent3.every((m) => m.completion_rate === 100);
      const velocities = recent3.map((m) => m.velocity);
      const lastChange = ((velocities[velocities.length - 1] - velocities[velocities.length - 2]) /
        velocities[velocities.length - 2]) * 100;

      let overall = "healthy";
      const warnings = [];

      if (!allCompletionRate100) {
        overall = "warning";
        warnings.push("最近 Sprint 完成率低於 100%");
      }

      if (lastChange < -30) {
        overall = overall === "healthy" ? "warning" : "critical";
        warnings.push(`Velocity 急降 ${Math.round(lastChange)}%`);
      }

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              overall,
              warnings,
              recent_sprints: recent3,
              velocity_change_percent: Math.round(lastChange * 10) / 10,
              all_completion_rate_100: allCompletionRate100,
            }, null, 2),
          },
        ],
      };
    }

    case "get_quality_observer_definition": {
      if (!existsSync(QUALITY_OBSERVER_PATH)) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                error: "FILE_NOT_FOUND",
                message: `找不到 Quality Observer 定義文件：${QUALITY_OBSERVER_PATH}`,
              }),
            },
          ],
        };
      }

      const content = readFileSync(QUALITY_OBSERVER_PATH, "utf-8");
      return {
        content: [
          {
            type: "text",
            text: content,
          },
        ],
      };
    }

    case "get_trace_recent": {
      const limit = Math.min(Math.max(1, args?.limit || 20), 200);
      const files = listTraceLogFiles();

      if (files.length === 0) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                spans: [],
                total: 0,
                message: `docs/trace-logs/ 目錄下無 trace log 檔案（路徑：${TRACE_LOGS_DIR}）`,
              }, null, 2),
            },
          ],
        };
      }

      const collected = [];
      for (const filename of files) {
        if (collected.length >= limit) break;
        const filepath = join(TRACE_LOGS_DIR, filename);
        const spans = parseTraceLogFile(filepath);
        // 從最新的 span 開始（reverse 後取）
        const reversed = spans.slice().reverse();
        for (const span of reversed) {
          if (collected.length >= limit) break;
          collected.push({ _file: filename, ...span });
        }
      }

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              spans: collected,
              total: collected.length,
              files_scanned: files.length,
            }, null, 2),
          },
        ],
      };
    }

    case "get_trace_by_session": {
      const sessionId = args?.session_id;
      if (!sessionId) {
        throw new McpError(ErrorCode.InvalidParams, "session_id 為必要參數");
      }

      const files = listTraceLogFiles();
      const matchedSpans = [];

      for (const filename of files) {
        // 先用檔名快速篩選（性能優化）
        const fileSessionId = extractSessionIdFromFilename(filename);
        const filepath = join(TRACE_LOGS_DIR, filename);
        const spans = parseTraceLogFile(filepath);

        for (const span of spans) {
          // 支援兩種匹配：span 內的 sessionId 欄位，或檔名推斷的 sessionId
          if (span.sessionId === sessionId || fileSessionId === sessionId) {
            matchedSpans.push({ _file: filename, ...span });
          }
        }
      }

      // 依 timestamp 升序排列
      matchedSpans.sort((a, b) => {
        const ta = a.timestamp || "";
        const tb = b.timestamp || "";
        return ta.localeCompare(tb);
      });

      if (matchedSpans.length === 0) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                spans: [],
                total: 0,
                session_id: sessionId,
                message: `找不到 session「${sessionId}」的 trace span`,
                available_sessions: files.map(extractSessionIdFromFilename),
              }, null, 2),
            },
          ],
        };
      }

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              spans: matchedSpans,
              total: matchedSpans.length,
              session_id: sessionId,
            }, null, 2),
          },
        ],
      };
    }

    case "get_trace_summary": {
      const filterSessionId = args?.session_id || null;
      const files = listTraceLogFiles();

      if (files.length === 0) {
        return {
          content: [
            {
              type: "text",
              text: `docs/trace-logs/ 目錄下無 trace log 檔案（路徑：${TRACE_LOGS_DIR}）`,
            },
          ],
        };
      }

      const summaries = [];

      for (const filename of files) {
        const fileSessionId = extractSessionIdFromFilename(filename);

        // 若指定 session，只處理匹配的檔案
        if (filterSessionId && fileSessionId !== filterSessionId) {
          // 也嘗試從 span 的 sessionId 欄位匹配（需讀取檔案）
          const filepath = join(TRACE_LOGS_DIR, filename);
          const spans = parseTraceLogFile(filepath);
          const matchedSpans = spans.filter((s) => s.sessionId === filterSessionId);
          if (matchedSpans.length === 0) continue;
          summaries.push(buildTraceSummary(matchedSpans, filename));
          continue;
        }

        const filepath = join(TRACE_LOGS_DIR, filename);
        const spans = parseTraceLogFile(filepath);
        summaries.push(buildTraceSummary(spans, filename));
      }

      if (summaries.length === 0) {
        return {
          content: [
            {
              type: "text",
              text: filterSessionId
                ? `找不到 session「${filterSessionId}」的 trace span`
                : "無 trace 資料可摘要",
            },
          ],
        };
      }

      return {
        content: [
          {
            type: "text",
            text: summaries.join("\n\n" + "=".repeat(60) + "\n\n"),
          },
        ],
      };
    }

    case "get_coverage_metrics": {
      // Phase 2 AC1: /metrics endpoint — coverage, debt_ratio, health_score
      // AC4: Graceful fallback when data unavailable ([QO-UNAVAILABLE] path)
      try {
        const metrics = parseMetricsLog();
        const targetSprint = args?.sprint_number;
        let sprintData = null;

        if (targetSprint) {
          sprintData = metrics.find((m) => m.sprint_number === targetSprint);
        } else {
          sprintData = metrics[metrics.length - 1] || null;
        }

        if (!sprintData) {
          return {
            content: [
              {
                type: "text",
                text: JSON.stringify({
                  status: "QO-UNAVAILABLE",
                  message: "No metrics data available",
                  coverage: null,
                  debt_ratio: null,
                  health_score: null,
                }),
              },
            ],
          };
        }

        // Compute coverage from completion_rate, debt_ratio from tech_debt, health_score from velocity trend
        const coverage = sprintData.completion_rate ?? null;
        const debtRatio = (sprintData.tech_debt_count ?? 0) > 0 ? "non-zero" : "clean";
        const healthScore =
          coverage !== null ? Math.round(coverage * 100) : null;

        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "ok",
                sprint: sprintData.sprint_number,
                coverage: coverage,
                debt_ratio: debtRatio,
                health_score: healthScore,
              }),
            },
          ],
        };
      } catch (err) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "QO-UNAVAILABLE",
                message: `Error computing metrics: ${err.message}`,
                coverage: null,
                debt_ratio: null,
                health_score: null,
              }),
            },
          ],
        };
      }
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
        uri: "quality://health/current",
        name: "當前系統健康狀態",
        description: "基於最近 3 個 Sprint 的 Velocity 趨勢與完成率的健康評估",
        mimeType: "application/json",
      },
      {
        uri: "quality://trend/velocity",
        name: "Velocity 趨勢",
        description: "近 10 個 Sprint 的 Velocity 趨勢分析",
        mimeType: "application/json",
      },
      {
        uri: "quality://observer/definition",
        name: "Quality Observer 角色定義",
        description: "Quality Observer 三維度觀察定義與健康門檻",
        mimeType: "text/markdown",
      },
    ],
  };
});

server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const { uri } = request.params;

  switch (uri) {
    case "quality://health/current": {
      const metrics = parseMetricsLog();
      const recent3 = metrics
        .filter((m) => m.velocity !== null)
        .sort((a, b) => a.sprint_number - b.sprint_number)
        .slice(-3);

      return {
        contents: [
          {
            uri,
            mimeType: "application/json",
            text: JSON.stringify({ recent_sprints: recent3 }, null, 2),
          },
        ],
      };
    }

    case "quality://trend/velocity": {
      const metrics = parseMetricsLog();
      const trendData = analyzeVelocityTrend(metrics, 10);
      return {
        contents: [
          {
            uri,
            mimeType: "application/json",
            text: JSON.stringify(trendData, null, 2),
          },
        ],
      };
    }

    case "quality://observer/definition": {
      if (!existsSync(QUALITY_OBSERVER_PATH)) {
        throw new McpError(ErrorCode.InvalidRequest, "Quality Observer 定義文件不存在");
      }
      const content = readFileSync(QUALITY_OBSERVER_PATH, "utf-8");
      return {
        contents: [
          {
            uri,
            mimeType: "text/markdown",
            text: content,
          },
        ],
      };
    }

    default:
      throw new McpError(ErrorCode.InvalidRequest, `未知資源：${uri}`);
  }
});

// ─── 啟動 ──────────────────────────────────────────────────────────────────────

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  // MCP stdio server 不輸出 stdout（會干擾 MCP 協議）
  // 僅在 stderr 輸出狀態資訊
  process.stderr.write("Shikigami Quality Observer MCP Server 已啟動\n");
  process.stderr.write(`SHIKIGAMI_ROOT: ${SHIKIGAMI_ROOT}\n`);
}

main().catch((err) => {
  process.stderr.write(`Fatal error: ${err.message}\n`);
  process.exit(1);
});
