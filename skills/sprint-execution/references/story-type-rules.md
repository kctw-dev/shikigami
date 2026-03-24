# story_type 規則與 Contract 區塊定義

<!-- SSOT：story-lifecycle-prompt.md 輸入格式 story_type 相關規則已移至此處（Sprint 127 #485 模組化拆分） -->
<!-- US-204 Story Template 更新 — Sprint 76 -->

## story_type 欄位說明（AC1）

`story_type` 為必填欄位，值域為以下 6 種 Type（定義詳見 `skills/sprint-planning/SKILL.md` §8）：

| 值 | 說明 | Contract Owner |
|----|------|---------------|
| `FEATURE` | 新功能或現有功能增強 | Architect |
| `DESIGN` | UI/UX 設計相關 | UI/UX Designer |
| `INFRA` | 基礎設施、部署、環境設定 | SRE |
| `SECURITY` | 安全掃描、權限控制、漏洞修復 | Security Engineer |
| `INTEGRATION` | 跨系統整合、API 串接 | Architect |
| `RESEARCH` | 探索性調查、POC、技術選型 | N/A（需 Spike Report） |

## story_type 路由規則（US-244 AC2 補充）

<!-- US-244 Story 類型識別規則補充 DESIGN 類派遣 — Sprint 88 -->

**DESIGN type Story 的識別與派遣規則：**

| 識別條件 | 派遣目標 | 說明 |
|---------|---------|------|
| `story_type=DESIGN` | **UI/UX Designer subagent**（`skills/uiux-designer/SKILL.md`） | 視覺設計、規格書、Figma Prototype 相關 Story |
| `story_type=FEATURE` 且涉及前端修改 | **Developer subagent**（開發）+ **UIUX/QA 視覺一致性審查**（交付前） | FEATURE Story 中含 UI 實作需求，需在交付前進行視覺一致性審查（見 §4.7） |
| 其他 `story_type` | Developer subagent（一般路徑） | 不涉及前端修改 |

**DESIGN Story 識別標準（以下任一即判定為 DESIGN type）：**

- Story 的主要交付物為 Figma Prototype、Design Spec、視覺規格文件
- AC 描述的輸出物為設計稿、Design Token、Component Library 規格
- 主 session 在 Sprint Planning 已標注 `story_type=DESIGN`

> **注意**：`story_type=DESIGN` 必須在 Sprint Planning 時由 PO/Architect 明確標注。若 `story_type` 缺失但 AC 描述明顯為設計交付物，本 subagent 輸出告警 `[STORY-TYPE-SUGGEST] AC 描述為設計交付物，建議將 story_type 設為 DESIGN` 並 fallback 至 FEATURE 路徑執行（不自動改變 story_type）。

---

## story_type Fallback 規則（AC5）

**向後相容**：當 `story_type` 欄位缺失或值為空時，自動 fallback 至 `FEATURE` type，行為如下：

```
若 story_type 缺失或空白：
  → story_type = "FEATURE"（fallback）
  → 輸出告警：[STORY-TYPE-FALLBACK] story_type 未指定，自動套用 FEATURE type。
    建議在下次 Sprint Planning 時由 PO/Architect 補充 story_type。
  → 繼續執行，不中斷流程
  → 依 FEATURE type 的 DoR/DoD（見 sprint-planning/SKILL.md §10）執行
```

**有效值驗證**：若 `story_type` 有值但不屬於以上 6 種（如拼字錯誤），視同缺失，觸發相同 fallback 規則，並在告警中列出實際傳入值。

## story_type 與 doc_only 的關係（AC6）

某些 Story Type 與 `doc_only` 欄位有隱含關係，規則如下：

| story_type | 隱含 doc_only 傾向 | 說明 |
|------------|-------------------|------|
| `RESEARCH` | **隱含 doc_only=true** | RESEARCH 的產出物為 Spike Report，無程式碼交付物，應設為 doc_only=true |
| `DESIGN` | **通常 doc_only=true** | 設計稿、規格書屬文件產出，若無程式碼交付物應設為 doc_only=true |
| `FEATURE` | doc_only=false（預設） | 有程式碼交付物 |
| `INFRA` | 視情況 | 若僅修改配置文件（YAML、Terraform）可為 doc_only=false；若為純文件說明則 doc_only=true |
| `SECURITY` | doc_only=false（預設） | 通常涉及程式碼修改 |
| `INTEGRATION` | doc_only=false（預設） | 涉及 API 串接程式碼 |

**衝突處理規則**：

| 組合 | 處理方式 |
|------|---------|
| `story_type=RESEARCH` 且 `doc_only=false` | **警告**：RESEARCH type 通常應為 doc_only=true。輸出告警 `[STORY-TYPE-CONFLICT] RESEARCH type 建議設為 doc_only=true`，但**不阻塞**執行，保留傳入值 |
| `story_type=FEATURE` 且 `doc_only=true` | 合法組合：doc-only FEATURE 不涉及 API，Contract 欄填「不適用」，按 doc_only=true 路徑執行（跳過 TDD） |
| `story_type=DESIGN` 且 `doc_only=false` | 合法組合，但提示確認是否有程式碼交付物。不阻塞執行 |
| 其他 Type 與 doc_only 任意組合 | 合法，無特殊處理 |

## Contract 區塊（AC2）

<!-- US-204 Contract 區塊定義 — Sprint 76 -->

當 `story_type` 不為 `RESEARCH` 且 Story 涉及 API 或跨系統協議時，Contract 區塊應由 Contract Owner 在開發開始前完成填寫。

**Contract 區塊格式**（位於 sprint_N.md 對應 Story 區段）：

```markdown
### Contract

**Contract Owner**：{Architect / UI/UX Designer / SRE / Security Engineer / N/A}
**Contract 狀態**：{Draft / Reviewed / Accepted}
**API 契約引用**：{契約文件路徑或 N/A（不涉及 API 時填 N/A）}

{契約摘要描述，如：定義 /api/stories/{id} PUT 端點的 request/response schema}
```

**Contract 狀態說明**：

| 狀態 | 含義 | 開發限制 |
|------|------|---------|
| `Draft` | Contract Owner 已起草但未審查 | 可開始開發，但有風險 |
| `Reviewed` | 已審查，待最終確認 | 可開始開發 |
| `Accepted` | Contract Owner 已正式接受 | 無限制 |
| N/A | 本 Story 不涉及 API 契約 | 無限制 |

**Contract 缺失時的行為**：若 Sprint_file 中無 Contract 區塊，且 Story AC 明確涉及 API 新增或修改，依現有 API 契約 Hard Gate（§3 Green 階段）處理，不額外阻塞。
