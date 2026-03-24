# §13-14 輸出工作流程

## §13 自動嵌入 Markdown 文件（AC1）

diagram 操控完成後，可將產出的圖片嵌入至專案 Markdown 文件。本節說明完整流程。

### 13.1 匯出路徑規範

所有 diagram 產出物統一儲存於 `docs/diagrams/` 目錄：

| 格式 | 路徑 | 說明 |
|------|------|------|
| Draw.io 原始檔 | `docs/diagrams/<name>.drawio` | 可編輯原始格式，來源由 drawio-mcp-server 操控 |
| PNG 圖片 | `docs/diagrams/<name>.png` | 供 Markdown 嵌入，透過手動匯出（§5.2）取得 |
| SVG 圖片 | `docs/diagrams/<name>.svg` | 向量格式，適用於高解析度場景 |

**命名規範**：

- 使用小寫字母與連字號（kebab-case），例如 `system-overview`、`gcp-deployment`
- 名稱應反映 diagram 內容，避免使用 `diagram1`、`test` 等無意義命名
- 範例：
  - `docs/diagrams/system-overview.drawio`
  - `docs/diagrams/system-overview.png`

### 13.2 Markdown 圖片語法

在 Markdown 文件中使用相對路徑引用圖片：

```markdown
![<alt 文字>](diagrams/<name>.png)
```

**範例**：

```markdown
![系統整體架構圖](diagrams/system-overview.png)

![GCP 部署架構](diagrams/gcp-deployment.png)
```

**說明**：

- `<alt 文字>`：描述圖片內容的替代文字，提升可及性
- 路徑使用**相對路徑**（從 `docs/` 目錄下的 `.md` 文件相對於 `docs/diagrams/`）
- 若 Markdown 文件位於專案根目錄，路徑調整為 `docs/diagrams/<name>.png`

### 13.3 插入目標文件定位

將圖片引用插入 Markdown 文件的步驟：

**步驟 1**：確認目標 Markdown 文件位置

```
docs/architecture.md          # 架構說明文件
docs/adr/ADR-013.md           # 特定 ADR 文件
README.md                     # 專案首頁
```

**步驟 2**：定位插入位置

在目標文件中找到適合嵌入圖片的位置，通常是：
- 架構說明章節的開頭（在文字描述之後）
- ADR 文件的 Context 或 Decision 章節
- README 的 Architecture Overview 區塊

**步驟 3**：插入圖片語法

在目標位置插入以下內容：

```markdown
## 架構圖

![系統整體架構圖](diagrams/system-overview.png)

> 圖片由 `shikigami:diagram` 技能自動生成，原始檔：`docs/diagrams/system-overview.drawio`
```

**步驟 4**：確認圖片可正常顯示

在 GitHub 或本地 Markdown 預覽器中確認圖片路徑正確、圖片可正常載入。

---

## §14 GitHub Issue 回覆附圖（AC2）

在 GitHub Issue 或 Pull Request 的 comment 中附上 diagram 圖片，可提升溝通效率。本節說明完整流程。

### 14.1 使用 gh CLI 上傳圖片並附圖

`gh` CLI 目前不直接支援圖片上傳至 GitHub CDN，建議使用以下方式：

**方法一：在 comment 文字中引用已上傳至 repo 的圖片**

若 PNG 已透過 `git add/commit/push` 上傳至遠端 repo，可使用 raw URL：

```bash
# 格式：https://raw.githubusercontent.com/<owner>/<repo>/<branch>/docs/diagrams/<name>.png
IMAGE_URL="https://raw.githubusercontent.com/owner/shikigami/main/docs/diagrams/system-overview.png"

gh issue comment 89 --body "架構圖如下：

![系統整體架構圖](${IMAGE_URL})"
```

**方法二：使用 gh api 上傳圖片至 GitHub CDN（Issue comment 拖曳上傳方式）**

GitHub 不提供純 API 方式上傳圖片至 CDN（需透過瀏覽器拖曳）。若需要 GitHub CDN URL，執行以下步驟：

1. 開啟瀏覽器，前往 GitHub Issue 頁面
2. 在 comment 輸入框中拖曳或貼上圖片
3. GitHub 自動上傳圖片至 CDN，產生形如以下的 URL：

```
https://github.com/user-attachments/assets/<uuid>
```

4. 複製該 URL 後可在任何 comment 中使用

### 14.2 取得圖片 URL

| 方式 | URL 格式 | 適用場景 |
|------|---------|---------|
| Git repo raw URL | `https://raw.githubusercontent.com/<owner>/<repo>/<branch>/docs/diagrams/<name>.png` | 圖片已 commit 至 repo |
| GitHub CDN（拖曳上傳） | `https://github.com/user-attachments/assets/<uuid>` | 需要持久化 CDN URL |

### 14.3 使用 Markdown 語法在 Issue comment 附圖

取得圖片 URL 後，使用 `gh issue comment` 附上圖片：

```bash
# 附圖至指定 Issue（以 Issue #89 為例）
gh issue comment 89 --body "$(cat <<'EOF'
## 架構圖

![系統整體架構圖](https://raw.githubusercontent.com/owner/shikigami/main/docs/diagrams/system-overview.png)

此圖由 \`shikigami:diagram\` 技能生成，展示系統整體部署架構。
EOF
)"
```

**附圖至 Pull Request**：

```bash
# 附圖至指定 PR
gh pr comment 42 --body "![部署架構圖](https://raw.githubusercontent.com/owner/shikigami/main/docs/diagrams/gcp-deployment.png)"
```

### 14.4 完整附圖流程總結

```
[步驟 1] diagram 操控完成（shikigami:diagram 執行）
  ↓
[步驟 2] 手動匯出 PNG（§5.2 Draw.io UI 匯出）
  → 儲存至 docs/diagrams/<name>.png
  ↓
[步驟 3] 將圖片加入 git 並 push
  → git add docs/diagrams/<name>.png
  → git commit -m "docs: 新增 <name> 架構圖"
  → git push
  ↓
[步驟 4] 取得 raw URL 或上傳至 GitHub CDN
  → raw URL：https://raw.githubusercontent.com/<owner>/<repo>/main/docs/diagrams/<name>.png
  ↓
[步驟 5] 使用 gh CLI 在 Issue/PR comment 中附圖
  → gh issue comment <number> --body "![<alt>](<url>)"
```
