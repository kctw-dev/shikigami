# ADR-044: A2A Protocol — Agent-to-Agent 結構化通訊協議標準化

**狀態**：Accepted
**日期**：2026-03-25
**決策者**：Architect Agent + Developer Agent
**觸發 Story**：#801（feat: A2A Protocol — Agent-to-Agent 結構化通訊協議標準化）
**Unblocks**：Sprint 162 自動化解析與 CI 驗證流程

---

## 背景與問題

Sprint 162 之前，subagent 回傳結果為純文字 Markdown 格式（§9 輸出格式），主 session 透過人工讀取摘要的方式解析結果。此方式存在以下問題：

1. **解析不可靠**：純文字結構依賴正則表達式，遇格式差異即失敗
2. **自動化困難**：CI pipeline 無法直接驗證 subagent 結果品質
3. **欄位未標準化**：不同 agent 角色（developer/architect/qa）回傳格式不一致
4. **缺乏機器可讀性**：跨 session compaction 後結果復原依賴文字解析，風險高

---

## 決策內容

### 選項 A：JSON Schema 標準化（選定）

定義 A2A 通訊協議 JSON Schema，所有 subagent 在回傳前輸出一個 JSON block，作為機器可讀的結構化摘要。

**優點**：
- 機器可解析，CI 可驗證
- 欄位明確，schema 可版本化演進
- 向後相容：既有 Markdown 摘要保留，JSON block 為附加輸出

**缺點**：
- Subagent prompt 需更新（§9 輸出格式變更）

### 選項 B：YAML 格式（未選）

採用 YAML 格式取代 JSON。未選擇原因：JSON 有嚴格語法、現有工具鏈（python3 json 模組）直接支援，YAML 解析邊界問題較多。

---

## A2A Schema 定義

版本：`1.0`

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "A2A Protocol Schema",
  "description": "Shikigami Agent-to-Agent 結構化通訊協議 v1.0",
  "type": "object",
  "required": ["protocol_version", "story_id", "actor", "result", "summary", "timestamp"],
  "properties": {
    "protocol_version": {
      "type": "string",
      "const": "1.0",
      "description": "A2A 協議版本號，當前固定為 1.0"
    },
    "story_id": {
      "type": "integer",
      "description": "對應的 GitHub Issue 編號（整數）"
    },
    "actor": {
      "type": "string",
      "enum": ["developer", "architect", "qa", "po", "security", "sm"],
      "description": "執行本 Story 的 agent 角色"
    },
    "result": {
      "type": "string",
      "enum": ["PASS", "FAIL", "ESCALATE"],
      "description": "Story 執行結果"
    },
    "summary": {
      "type": "string",
      "maxLength": 200,
      "description": "結果說明（≤200 字）"
    },
    "artifacts": {
      "type": "array",
      "description": "產出物清單（可選）",
      "items": {
        "type": "object",
        "required": ["type", "path"],
        "properties": {
          "type": {
            "type": "string",
            "enum": ["file", "pr", "adr", "test", "doc"],
            "description": "產出物類型"
          },
          "path": {
            "type": "string",
            "description": "檔案路徑或 URL"
          },
          "description": {
            "type": "string",
            "description": "產出物說明"
          }
        }
      }
    },
    "metrics": {
      "type": "object",
      "description": "執行指標（可選）",
      "properties": {
        "tests_total": {
          "type": "integer",
          "description": "測試總數"
        },
        "tests_passed": {
          "type": "integer",
          "description": "通過測試數"
        },
        "files_created": {
          "type": "integer",
          "description": "新建檔案數"
        },
        "files_modified": {
          "type": "integer",
          "description": "修改檔案數"
        }
      }
    },
    "pr": {
      "type": "object",
      "description": "Pull Request 資訊（PASS 且有 PR 時填入）",
      "properties": {
        "number": {
          "type": "integer",
          "description": "PR 編號"
        },
        "url": {
          "type": "string",
          "description": "PR URL"
        },
        "merge_commit": {
          "type": "string",
          "description": "Merge commit SHA"
        }
      }
    },
    "escalation": {
      "type": "object",
      "description": "升級資訊（result=ESCALATE 時必填）",
      "properties": {
        "type": {
          "type": "string",
          "enum": [
            "DESIGN_ISSUE",
            "CONTEXT_OVERFLOW",
            "REQUIREMENT_AMBIGUITY",
            "DEPENDENCY_MISSING",
            "SECURITY_CRITICAL",
            "DEBATE_DESIGN_ISSUE"
          ],
          "description": "升級類型"
        },
        "reason": {
          "type": "string",
          "description": "升級原因說明"
        }
      }
    },
    "timestamp": {
      "type": "string",
      "format": "date-time",
      "description": "回傳時間（ISO 8601 格式，含時區）"
    }
  }
}
```

---

## 使用規範

### Subagent 輸出規則

1. **必填欄位**：`protocol_version`、`story_id`、`actor`、`result`、`summary`、`timestamp`
2. **條件必填**：`escalation` 在 `result=ESCALATE` 時必填
3. **向後相容（NFR1）**：既有 Markdown 摘要格式（§9 PASS/FAIL/ESCALATE 模板）必須保留，JSON block 以 `<!-- A2A-RESULT -->` 標記附加於摘要末尾
4. **時間格式**：`timestamp` 使用 `date -u +"%Y-%m-%dT%H:%M:%SZ"` 或帶時區 ISO 8601

### 輸出範例

```json
{
  "protocol_version": "1.0",
  "story_id": 801,
  "actor": "developer",
  "result": "PASS",
  "summary": "A2A Protocol 標準化完成，ADR-044 建立，§9 更新，驗證腳本就緒",
  "artifacts": [
    {"type": "adr", "path": "docs/adr/ADR-044-a2a-protocol.md", "description": "A2A Protocol 架構決策"},
    {"type": "file", "path": "scripts/validate-a2a-schema.sh", "description": "Schema 驗證腳本"},
    {"type": "test", "path": "tests/test-a2a-protocol.sh", "description": "驗收測試"}
  ],
  "metrics": {
    "tests_total": 17,
    "tests_passed": 17,
    "files_created": 3,
    "files_modified": 1
  },
  "pr": {
    "number": 822,
    "url": "https://github.com/kctw-dev/shikigami/pull/822",
    "merge_commit": ""
  },
  "timestamp": "2026-03-25T22:00:00Z"
}
```

---

## 驗證

- **驗證腳本**：`scripts/validate-a2a-schema.sh <file>`
- **驗收測試**：`tests/test-a2a-protocol.sh`
- **§9 引用**：`skills/sprint-execution/story-lifecycle-prompt.md` §9 及 `skills/sprint-execution/references/output-schema.md`

---

## 決策理由

1. **機器可讀**：JSON 格式允許 CI pipeline 自動驗證 subagent 輸出品質
2. **向後相容**：附加方式不破壞既有 Markdown 摘要消費者
3. **版本化演進**：`protocol_version` 欄位允許未來擴展而不破壞舊 consumer
4. **工具鏈簡單**：bash + python3 json 即可驗證，無需額外依賴

---

## 參照

- **ADR-007**：`docs/adr/ADR-007-story-lifecycle-subagent.md`（Story Lifecycle 介面契約）
- **ADR-033**：`docs/adr/ADR-033-structured-trace-log.md`（Structured Trace Log，同為結構化輸出）
- **§9 Output Schema**：`skills/sprint-execution/references/output-schema.md`
