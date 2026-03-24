# Health Check — 孤兒文件清理規範

## §6 孤兒文件清理規範（US-T09）

### 6.1 定義

**孤兒文件**（Orphan Document）：`docs/` 目錄下的 `.md` 文件，同時滿足以下兩個條件：

1. 未被任何其他 `.md` 文件以相對路徑引用（例如 `[title](./path/file.md)` 或 `[title](dir/file.md)`）
2. 不在豁免清單中（見下節）

### 6.2 豁免清單

以下 4 類文件自動豁免孤兒偵測，不產生 WARNING：

| 類別 | 規則 | 說明 |
|------|------|------|
| CLASS_1：Sprint 週期文件 | `docs/sprints/sprint_N.md`（N 為數字） | Sprint 文件為週期性產出，由 PROJECT_BOARD 管理，不需直接引用 |
| CLASS_2：度量紀錄 | `docs/km/Metrics_Log.md` | 自動累積的度量紀錄，不需其他文件引用 |
| CLASS_3：頂層文件 | `docs/` 直屬文件（無子目錄層，如 `docs/PROJECT_BOARD.md`） | 頂層導覽文件為入口點，不需被引用 |
| CLASS_4：ADR 文件 | `docs/adr/ADR-*.md` | ADR 文件由 Backlog 管理，不需在文件間相互引用 |

### 6.3 判定週期

每次 CI 執行時自動偵測，對應 `.github/workflows/validate.yml` 中的 `Validate Orphans` 步驟。

### 6.4 輸出格式

偵測到孤兒文件時，輸出以下格式的 WARNING（不阻塞 CI，exit code 為 0）：

```
[WARNING] <file_path>: 孤兒文件（無任何 .md 引用）
```

腳本位置：`scripts/validate-orphans.sh`

---

## §6.5 處置流程（AC3）

偵測到孤兒文件後，依照以下三步驟處置：

1. **列為 Problem**：開發者在最近一次 Sprint Retrospective 中，將孤兒文件列入 Problem 欄位，說明文件名稱與發現時間
2. **PO 裁定**：由 Product Owner 審視後選擇以下其中一個處置方式：
   - **刪除**：文件已無用途，直接移除
   - **補充引用**：在適當的 `.md` 文件中補充指向該文件的相對路徑引用
   - **加入豁免清單**：文件有保留必要但不適合被引用，在 `scripts/validate-orphans.sh` 的豁免規則中新增對應條件
3. **關閉 Issue**：執行裁定的處置動作後，關閉對應的 GitHub Issue（若已建立）
