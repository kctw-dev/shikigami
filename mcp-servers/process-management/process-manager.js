/**
 * ProcessManager — Sprint 流程狀態機核心邏輯
 *
 * US-245 Sprint 89 — Process Management MCP Server Phase 1
 *
 * 職責：
 * - 管理 Sprint 流程步驟狀態機（get_current_step / advance_step / get_remaining_steps）
 * - 狀態持久化至檔案系統（C2：重啟後狀態不遺失）
 * - Fallback 機制：MCP 不可達時提供 sprint 文件讀取路徑（C1）
 *
 * 設計原則：
 * - 零外部依賴（C3）：僅使用 Node.js 內建模組
 * - 檔案為 source of truth，進程為快取層
 *
 * ADR-019 §3 決策引用
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { join, resolve } from "node:path";

// ─── Sprint 流程步驟定義 ──────────────────────────────────────────────────────

/**
 * Sprint 流程步驟清單（狀態機節點）
 * 代表 Sprint 生命週期中的關鍵節點序列
 */
const SPRINT_STEPS = [
  {
    step: "sprint_planning",
    description: "Sprint Planning — 確認 Sprint Goal、Story 分配與 AC 釐清",
  },
  {
    step: "story_execution",
    description: "Story Execution — TDD 開發循環（Red → Green → Refactor）",
  },
  {
    step: "spec_review",
    description: "Spec Compliance Review — 逐條驗證 AC，確認實作符合規格",
  },
  {
    step: "quality_review",
    description: "Code Quality Review — 命名、結構、測試品質自審",
  },
  {
    step: "sprint_review",
    description: "Sprint Review — Demo 交付物，Stakeholder 驗收",
  },
  {
    step: "sprint_retrospective",
    description: "Sprint Retrospective — 回顧本 Sprint，記錄改善行動",
  },
  {
    step: "sprint_complete",
    description: "Sprint Complete — 所有流程節點完成，Sprint 關閉",
  },
];

const STEP_NAMES = SPRINT_STEPS.map((s) => s.step);
const STATE_FILE_NAME = "process-state.json";

// ─── ProcessManager 類別 ─────────────────────────────────────────────────────

export class ProcessManager {
  /**
   * @param {object} options
   * @param {string} options.stateDir  — 狀態文件目錄（預設 ./state/）
   * @param {string} options.shikiRoot — Shikigami 工作根目錄（用於 fallback 讀取 sprint 文件）
   */
  constructor({ stateDir, shikiRoot } = {}) {
    this.stateDir = stateDir || resolve(import.meta.dirname, "state");
    this.shikiRoot = shikiRoot || resolve(import.meta.dirname, "../..");
    this.stateFile = join(this.stateDir, STATE_FILE_NAME);

    // 確保 stateDir 存在
    if (!existsSync(this.stateDir)) {
      mkdirSync(this.stateDir, { recursive: true });
    }

    // 從檔案載入狀態（若不存在則使用初始狀態）
    this._state = this._loadState();
  }

  // ─── Public API ──────────────────────────────────────────────────────────

  /**
   * 取得所有定義的流程步驟
   * @returns {Array<{step: string, description: string}>}
   */
  getAllSteps() {
    return [...SPRINT_STEPS];
  }

  /**
   * 取得當前流程步驟
   * @returns {{ step: string, description: string, remaining_steps: Array, sprint_number: number|null }}
   */
  getCurrentStep() {
    const idx = this._state.currentStepIndex;
    const current = SPRINT_STEPS[idx] || SPRINT_STEPS[SPRINT_STEPS.length - 1];
    const remaining = SPRINT_STEPS.slice(idx + 1);

    return {
      step: current.step,
      description: current.description,
      remaining_steps: remaining,
      sprint_number: this._state.sprintNumber,
    };
  }

  /**
   * 推進至下一個流程步驟
   * @returns {{ success: boolean, previous_step: string, current_step: string, is_final: boolean }}
   */
  advanceStep() {
    const prevIdx = this._state.currentStepIndex;
    const prevStep = SPRINT_STEPS[prevIdx];

    // 已是最後步驟（sprint_complete）
    if (prevIdx >= SPRINT_STEPS.length - 1) {
      return {
        success: true,
        previous_step: prevStep.step,
        current_step: "sprint_complete",
        is_final: true,
      };
    }

    // 推進
    const nextIdx = prevIdx + 1;
    this._state.currentStepIndex = nextIdx;
    this._state.lastAdvancedAt = new Date().toISOString();
    this._persistState();

    const nextStep = SPRINT_STEPS[nextIdx];
    const isFinal = nextIdx === SPRINT_STEPS.length - 1;

    return {
      success: true,
      previous_step: prevStep.step,
      current_step: nextStep.step,
      is_final: isFinal,
    };
  }

  /**
   * 取得剩餘流程步驟清單
   * @returns {{ remaining_steps: Array<{step: string, description: string}>, total_remaining: number }}
   */
  getRemainingSteps() {
    const idx = this._state.currentStepIndex;
    const remaining = SPRINT_STEPS.slice(idx + 1);

    return {
      remaining_steps: remaining,
      total_remaining: remaining.length,
    };
  }

  /**
   * 直接設定狀態（測試用）
   * @param {object} stateOverride
   */
  setState(stateOverride) {
    this._state = { ...this._state, ...stateOverride };
    this._persistState();
  }

  /**
   * Fallback 機制：MCP 不可達時，直接讀取 sprint 文件提供基本資訊（C1）
   * @param {number} sprintNumber — Sprint 編號
   * @returns {{ sprint_number: number, fallback_mode: boolean, sprint_file_path?: string, message?: string, fallback_error?: string }}
   */
  getFallbackInfo(sprintNumber) {
    const sprintFilePath = join(
      this.shikiRoot,
      "docs",
      "sprints",
      `sprint_${sprintNumber}.md`
    );

    if (!existsSync(sprintFilePath)) {
      return {
        sprint_number: sprintNumber,
        fallback_mode: true,
        fallback_error: `Sprint 文件不存在：${sprintFilePath}`,
        message: "MCP Server 不可達，且無法找到對應的 Sprint 文件。請確認 sprint 編號與 SHIKIGAMI_ROOT 設定。",
      };
    }

    // 讀取 sprint 文件（fallback 模式：直接讀取原始文件）
    const content = readFileSync(sprintFilePath, "utf-8");
    const titleMatch = content.match(/^#\s+Sprint\s+(\d+)/m);
    const statusMatch = content.match(/>\s*狀態：(.+)/);

    return {
      sprint_number: sprintNumber,
      fallback_mode: true,
      sprint_file_path: sprintFilePath,
      sprint_title: titleMatch ? `Sprint ${titleMatch[1]}` : `Sprint ${sprintNumber}`,
      sprint_status: statusMatch ? statusMatch[1].trim() : "unknown",
      message: `MCP Server 不可達，已降級至直接讀取 Sprint 文件（${sprintFilePath}）。請查閱文件了解流程狀態。`,
      raw_content_preview: content.slice(0, 500),
    };
  }

  // ─── Private Methods ─────────────────────────────────────────────────────

  /**
   * 從檔案載入狀態，若不存在則回傳初始狀態
   */
  _loadState() {
    if (!existsSync(this.stateFile)) {
      return this._initialState();
    }

    try {
      const raw = readFileSync(this.stateFile, "utf-8");
      const parsed = JSON.parse(raw);
      // 驗證 currentStepIndex 範圍
      if (
        typeof parsed.currentStepIndex !== "number" ||
        parsed.currentStepIndex < 0 ||
        parsed.currentStepIndex >= SPRINT_STEPS.length
      ) {
        return this._initialState();
      }
      return parsed;
    } catch {
      return this._initialState();
    }
  }

  /**
   * 持久化當前狀態至檔案
   */
  _persistState() {
    writeFileSync(this.stateFile, JSON.stringify(this._state, null, 2), "utf-8");
  }

  /**
   * 初始狀態
   */
  _initialState() {
    return {
      currentStepIndex: 0,
      sprintNumber: null,
      lastAdvancedAt: null,
      createdAt: new Date().toISOString(),
    };
  }
}
