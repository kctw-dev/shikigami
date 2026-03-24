# §7 圖標集使用說明（--provider）

drawio-mcp-server 提供多個圖形庫分類。使用 `get_shape_categories` 確認可用分類，再以 `get_shapes_in_category` 查詢特定雲端服務圖標。

## GCP 圖標查詢範例

```
呼叫：get_shape_categories
  → 取得所有可用圖形庫分類清單

呼叫：get_shapes_in_category("gcp")
  → 取得 GCP 服務圖標清單（Cloud Run、Cloud SQL、GKE 等）

呼叫：get_shape_by_name("gcp_cloud_run")
  → 取得 Cloud Run 圖標詳細資訊

呼叫：add_cell_of_shape(name="gcp_cloud_run", label="API Service", x=100, y=100)
  → 在 diagram 中新增 Cloud Run 元件
```

## Provider 與圖形庫分類對應

| Provider | 查詢分類關鍵字 | 說明 |
|---------|--------------|------|
| `gcp` | `gcp` | Google Cloud Platform 官方圖標 |
| `aws` | `aws` | Amazon Web Services 官方圖標 |
| `azure` | `azure` | Microsoft Azure 官方圖標 |

> 實際可用分類名稱以 `get_shape_categories` 回傳為準，上表為參考方向。
