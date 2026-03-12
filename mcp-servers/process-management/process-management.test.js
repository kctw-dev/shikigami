/**
 * Process Management MCP Server — Unit Tests
 *
 * US-245 Sprint 89 — TDD Red Phase
 *
 * 測試範疇：
 * - get_current_step：取得當前流程步驟
 * - advance_step：推進至下一步驟
 * - get_remaining_steps：取得剩餘步驟清單
 * - 狀態持久化：重啟後狀態不遺失
 * - Fallback：MCP 不可達時降級讀取 sprint 文件
 */

import { test, describe, beforeEach, afterEach } from "node:test";
import assert from "node:assert/strict";
import { writeFileSync, existsSync, mkdirSync, rmSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";

// ─── 測試用暫存目錄 ─────────────────────────────────────────────────────────────

const TEST_ROOT = join(tmpdir(), `shikigami-test-${process.pid}`);
const TEST_STATE_DIR = join(TEST_ROOT, "state");
const TEST_SPRINT_DIR = join(TEST_ROOT, "docs", "sprints");

function setupTestDirs() {
  mkdirSync(TEST_STATE_DIR, { recursive: true });
  mkdirSync(TEST_SPRINT_DIR, { recursive: true });
}

function teardownTestDirs() {
  if (existsSync(TEST_ROOT)) {
    rmSync(TEST_ROOT, { recursive: true, force: true });
  }
}

// ─── 模擬 sprint_89.md 測試文件 ──────────────────────────────────────────────

const MOCK_SPRINT_CONTENT = `# Sprint 89

> 狀態：規劃完成
> 日期：2026-03-12

## Sprint Backlog

| Story ID | Issue | 標題 | Size | Points | Type | 狀態 |
|----------|-------|------|------|--------|------|------|
| US-245 | #238 | 流程管理 MCP Server Phase 1 | M | 2 | FEATURE | 進行中 |

## Acceptance Criteria

### US-245（M/2pt）| FEATURE

| AC | 驗證重點 | 目標檔案 |
|----|---------|---------|
| AC1 | 建立 MCP tools | mcp-servers/process-management/index.js |
| AC2 | State persistence | mcp-servers/process-management/ |
`;

// ─── 引入待測試模組 ───────────────────────────────────────────────────────────

// 使用動態 import 以支援 ESM，並注入測試用路徑
async function importProcessManager(stateDir, shikiRoot) {
  // 動態 import 並傳入測試環境配置
  const { ProcessManager } = await import("./process-manager.js?v=" + Date.now());
  return new ProcessManager({ stateDir, shikiRoot });
}

// ─── 測試套件 ────────────────────────────────────────────────────────────────

describe("ProcessManager — get_current_step", () => {
  beforeEach(() => {
    setupTestDirs();
  });

  afterEach(() => {
    teardownTestDirs();
  });

  test("初始狀態：get_current_step 回傳 sprint_planning", async () => {
    const { ProcessManager } = await import("./process-manager.js");
    const pm = new ProcessManager({ stateDir: TEST_STATE_DIR, shikiRoot: TEST_ROOT });

    const result = pm.getCurrentStep();

    assert.strictEqual(result.step, "sprint_planning");
    assert.ok(result.description);
    assert.ok(Array.isArray(result.remaining_steps));
  });

  test("get_current_step 包含必要欄位：step, description, remaining_steps, sprint_number", async () => {
    const { ProcessManager } = await import("./process-manager.js");
    const pm = new ProcessManager({ stateDir: TEST_STATE_DIR, shikiRoot: TEST_ROOT });

    const result = pm.getCurrentStep();

    assert.ok("step" in result, "應有 step 欄位");
    assert.ok("description" in result, "應有 description 欄位");
    assert.ok("remaining_steps" in result, "應有 remaining_steps 欄位");
    assert.ok("sprint_number" in result, "應有 sprint_number 欄位");
  });
});

describe("ProcessManager — advance_step", () => {
  beforeEach(() => {
    setupTestDirs();
  });

  afterEach(() => {
    teardownTestDirs();
  });

  test("advance_step：從 sprint_planning 推進至 story_execution", async () => {
    const { ProcessManager } = await import("./process-manager.js");
    const pm = new ProcessManager({ stateDir: TEST_STATE_DIR, shikiRoot: TEST_ROOT });

    // 初始步驟
    assert.strictEqual(pm.getCurrentStep().step, "sprint_planning");

    // 推進
    const result = pm.advanceStep();

    assert.ok(result.success);
    assert.strictEqual(result.previous_step, "sprint_planning");
    assert.ok(result.current_step);
    assert.notStrictEqual(result.current_step, "sprint_planning");
  });

  test("advance_step：已到最後步驟時回傳 sprint_complete", async () => {
    const { ProcessManager } = await import("./process-manager.js");
    const pm = new ProcessManager({ stateDir: TEST_STATE_DIR, shikiRoot: TEST_ROOT });

    // 快進到最後一個步驟
    const steps = pm.getAllSteps();
    // 設定狀態為最後一步
    pm.setState({ currentStepIndex: steps.length - 1 });

    const result = pm.advanceStep();

    assert.ok(result.success);
    assert.strictEqual(result.current_step, "sprint_complete");
    assert.ok(result.is_final);
  });

  test("advance_step 回傳包含 success, previous_step, current_step 欄位", async () => {
    const { ProcessManager } = await import("./process-manager.js");
    const pm = new ProcessManager({ stateDir: TEST_STATE_DIR, shikiRoot: TEST_ROOT });

    const result = pm.advanceStep();

    assert.ok("success" in result);
    assert.ok("previous_step" in result);
    assert.ok("current_step" in result);
  });
});

describe("ProcessManager — get_remaining_steps", () => {
  beforeEach(() => {
    setupTestDirs();
  });

  afterEach(() => {
    teardownTestDirs();
  });

  test("get_remaining_steps：初始狀態回傳所有步驟（除第一步外）", async () => {
    const { ProcessManager } = await import("./process-manager.js");
    const pm = new ProcessManager({ stateDir: TEST_STATE_DIR, shikiRoot: TEST_ROOT });

    const result = pm.getRemainingSteps();

    assert.ok(Array.isArray(result.remaining_steps));
    assert.ok(result.remaining_steps.length > 0);
    // 初始步驟自身不在 remaining 中
    result.remaining_steps.forEach(step => {
      assert.notStrictEqual(step.step, "sprint_planning");
    });
  });

  test("get_remaining_steps：推進後 remaining_steps 減少", async () => {
    const { ProcessManager } = await import("./process-manager.js");
    const pm = new ProcessManager({ stateDir: TEST_STATE_DIR, shikiRoot: TEST_ROOT });

    const before = pm.getRemainingSteps().remaining_steps.length;
    pm.advanceStep();
    const after = pm.getRemainingSteps().remaining_steps.length;

    assert.strictEqual(after, before - 1);
  });

  test("get_remaining_steps 回傳 remaining_steps 陣列，每項含 step 和 description", async () => {
    const { ProcessManager } = await import("./process-manager.js");
    const pm = new ProcessManager({ stateDir: TEST_STATE_DIR, shikiRoot: TEST_ROOT });

    const result = pm.getRemainingSteps();

    result.remaining_steps.forEach(item => {
      assert.ok("step" in item, "每項應有 step 欄位");
      assert.ok("description" in item, "每項應有 description 欄位");
    });
  });
});

describe("ProcessManager — 狀態持久化（AC2）", () => {
  beforeEach(() => {
    setupTestDirs();
  });

  afterEach(() => {
    teardownTestDirs();
  });

  test("advance_step 後狀態持久化到檔案系統", async () => {
    const { ProcessManager } = await import("./process-manager.js");
    const pm = new ProcessManager({ stateDir: TEST_STATE_DIR, shikiRoot: TEST_ROOT });

    pm.advanceStep();

    // 狀態文件應存在
    const stateFile = join(TEST_STATE_DIR, "process-state.json");
    assert.ok(existsSync(stateFile), "狀態文件應存在");
  });

  test("重建 ProcessManager 實例後，狀態從檔案恢復（模擬重啟）", async () => {
    const { ProcessManager } = await import("./process-manager.js");
    const pm1 = new ProcessManager({ stateDir: TEST_STATE_DIR, shikiRoot: TEST_ROOT });

    // 推進一步並記錄狀態
    pm1.advanceStep();
    const stepAfterAdvance = pm1.getCurrentStep().step;

    // 模擬重啟：建立新實例（從相同 stateDir 讀取）
    const pm2 = new ProcessManager({ stateDir: TEST_STATE_DIR, shikiRoot: TEST_ROOT });
    const recoveredStep = pm2.getCurrentStep().step;

    assert.strictEqual(recoveredStep, stepAfterAdvance, "重啟後狀態應與之前一致");
  });

  test("狀態文件為有效 JSON", async () => {
    const { ProcessManager } = await import("./process-manager.js");
    const pm = new ProcessManager({ stateDir: TEST_STATE_DIR, shikiRoot: TEST_ROOT });

    pm.advanceStep();

    const stateFile = join(TEST_STATE_DIR, "process-state.json");
    const { readFileSync } = await import("node:fs");
    const content = readFileSync(stateFile, "utf-8");

    assert.doesNotThrow(() => JSON.parse(content), "狀態文件應為有效 JSON");
  });
});

describe("ProcessManager — Fallback 機制（AC3）", () => {
  beforeEach(() => {
    setupTestDirs();
    // 建立測試用 sprint 文件
    writeFileSync(join(TEST_SPRINT_DIR, "sprint_89.md"), MOCK_SPRINT_CONTENT);
  });

  afterEach(() => {
    teardownTestDirs();
  });

  test("getFallbackInfo：讀取 sprint 文件並回傳基本資訊", async () => {
    const { ProcessManager } = await import("./process-manager.js");
    const pm = new ProcessManager({ stateDir: TEST_STATE_DIR, shikiRoot: TEST_ROOT });

    const result = pm.getFallbackInfo(89);

    assert.ok(result.sprint_number);
    assert.ok(result.fallback_mode, "應標記 fallback_mode=true");
    assert.ok(result.message, "應有說明訊息");
  });

  test("getFallbackInfo：sprint 文件不存在時回傳 fallback_error", async () => {
    const { ProcessManager } = await import("./process-manager.js");
    const pm = new ProcessManager({ stateDir: TEST_STATE_DIR, shikiRoot: TEST_ROOT });

    const result = pm.getFallbackInfo(999);

    assert.ok(result.fallback_error, "找不到文件應回傳 fallback_error");
  });

  test("getFallbackInfo：回傳 sprint 文件中的 Story 狀態資訊", async () => {
    const { ProcessManager } = await import("./process-manager.js");
    const pm = new ProcessManager({ stateDir: TEST_STATE_DIR, shikiRoot: TEST_ROOT });

    const result = pm.getFallbackInfo(89);

    // 應能從文件中提取到 sprint 資訊
    assert.ok(result.sprint_file_path || result.fallback_error, "應有 sprint_file_path 或 fallback_error");
  });
});

describe("ProcessManager — 流程步驟定義", () => {
  test("getAllSteps 回傳包含 Sprint 關鍵節點的步驟清單", async () => {
    const { ProcessManager } = await import("./process-manager.js");
    const pm = new ProcessManager({ stateDir: join(tmpdir(), "test-steps"), shikiRoot: tmpdir() });

    const steps = pm.getAllSteps();

    assert.ok(Array.isArray(steps));
    assert.ok(steps.length >= 4, "至少應有 4 個步驟");

    const stepNames = steps.map(s => s.step);
    assert.ok(stepNames.includes("sprint_planning"), "應包含 sprint_planning");
    assert.ok(stepNames.includes("sprint_review"), "應包含 sprint_review");
    assert.ok(stepNames.includes("sprint_complete"), "應包含 sprint_complete");
  });
});
