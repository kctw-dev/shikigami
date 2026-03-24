# API 契約產出（US-195）— 詳細規則

> 本文件由 `skills/architect/SKILL.md §7` 拆出。主文件保留觸發條件，詳細規則在此。

<!-- US-195 API 契約 Hard Gate — Sprint 74 -->

## 觸發條件

Architect 在技術評估階段，**若 Story 涉及以下任一情境，必須產出 API 契約**：

- Story 新增或修改 API 端點（REST / GraphQL / WebSocket）
- Story 涉及前端與後端之間的資料交換（request / response schema 變更）
- Story 跨越 Client / Server 邊界且傳輸結構化資料

**不涉及 API 的 Story**（純前端 UI、純後端業務邏輯、doc-only、工具腳本等）：在 Architect 技術評估表格的「API 契約」欄位填入「不適用」，並於 Sprint Planning 輸出中明確標注，Story-Lifecycle subagent 將跳過 API 契約 Hard Gate，不觸發阻擋。

## API 契約標準模板

Architect 產出的 API 契約必須使用以下 Markdown 表格格式：

```markdown
### API 契約：{端點路徑}

| 欄位 | 內容 |
|------|------|
| Endpoint | `{HTTP_METHOD} /api/v1/{path}` |
| Method | `GET` / `POST` / `PUT` / `PATCH` / `DELETE` |
| Auth | Bearer Token / API Key / 無 |
| Content-Type | `application/json` |

**Request Schema**

| 欄位名稱 | 型別 | 必填 | 說明 |
|---------|------|------|------|
| `{field_name}` | `string` / `number` / `boolean` / `object` / `array` | 是/否 | {欄位說明} |

**Response Schema（成功 2xx）**

| 欄位名稱 | 型別 | 說明 |
|---------|------|------|
| `{field_name}` | `string` / `number` / `boolean` / `object` / `array` | {欄位說明} |

**錯誤回應**

| HTTP 狀態碼 | 錯誤代碼 | 說明 |
|------------|---------|------|
| `400` | `INVALID_REQUEST` | {說明} |
| `401` | `UNAUTHORIZED` | {說明} |
| `404` | `NOT_FOUND` | {說明} |
| `500` | `INTERNAL_ERROR` | {說明} |
```

> **最小必要欄位**：Endpoint、Method、Request Schema、Response Schema 為必填欄位。Auth、Content-Type、錯誤回應表格為建議填寫，若確無需求可省略。

## Architect 技術評估表格輸出格式

Sprint Planning Architect Round 2 輸出的技術評估結果，必須包含「API 契約」欄位：

| Story | T-shirt | ADR 需求 | API 契約 | 說明 |
|-------|---------|---------|---------|------|
| US-#N | M | 無需 ADR | **有**（見下方契約定義） | {說明} |
| US-#M | S | 無需 ADR | **無**（需補充，阻擋開發） | {說明} |
| US-#K | S | 無需 ADR | **不適用** | doc-only，無 API 互動 |

**欄位說明：**

| 值 | 意義 |
|----|------|
| 有 | Architect 已產出 API 契約，Developer 可直接進入開發 |
| 無 | Story 涉及 API 但 Architect 尚未產出契約，Story-Lifecycle Hard Gate 將阻擋開發 |
| 不適用 | Story 不涉及 API 互動，Hard Gate 自動跳過 |
