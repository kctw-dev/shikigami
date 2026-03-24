# Sprint 開始時 API 文件版本驗證（US-221）

<!-- US-221 知識老化偵測 — Sprint 84 -->

Sprint Execution **第一個 Story 取出之前**，自動執行 API 文件版本驗證，確保已內化的關鍵 API 文件版本與當前 Sprint 所需版本一致。此步驟為**知識老化偵測三層機制**的「事件觸發」層，於每個 Sprint 啟動時自動觸發。

## 驗證流程

```
Sprint Execution 開始（CI 快掃完成後）
  |
  v
讀取 docs/km/Knowledge_Staleness_Detection.md §2 已內化知識清單
  |-- 檔案不存在 --> [KS-SKIP] 靜默略過，不阻塞（輸出告警後繼續）
  +-- 檔案存在
        |
        v
篩選「關鍵 API 文件」（priority = HIGH 的條目）
  |-- 無 HIGH 條目 --> [KS-SKIP] 靜默略過
  +-- 有 HIGH 條目
        |
        v
對每個 HIGH 條目驗證版本新鮮度
  |-- 所有條目均 FRESH（≤ 30 天）  --> [KS-PASS] 繼續執行
  |-- 有條目為 STALE（31–90 天）   --> [KS-WARN] 輸出告警，繼續執行（不阻塞）
  +-- 有條目為 EXPIRED（> 90 天）  --> [KS-FAIL] 輸出告警，要求確認
        |-- 使用者確認繼續 --> 繼續執行（記錄風險）
        +-- 使用者拒絕    --> 暫停 Sprint，觸發知識更新流程後重試
```

## 輸出格式

```
[KS-PASS] API 文件版本驗證通過，{N} 個 HIGH 優先條目均在新鮮度閾值內
[KS-WARN] API 文件版本告警 — {文件名稱} 已 {天數} 天未驗證（STALE），建議於本 Sprint 內排程更新
[KS-FAIL] API 文件版本過期 — {文件名稱} 已 {天數} 天未驗證（EXPIRED），使用過期知識開發存在風險
請確認是否繼續？（y/n）
[KS-SKIP] 無法執行 API 文件版本驗證（{原因}），繼續執行
```

## 執行位置

此步驟插入 §3 流程的以下位置：

```
CI 狀態快掃
  |
  v
[此處] API 文件版本驗證（US-221）
  |
  v
Sprint Backlog 中取出 Story
```

## 降級策略

- `docs/km/Knowledge_Staleness_Detection.md` 不存在或格式不符 → `[KS-SKIP]` 靜默略過，不阻塞
- 驗證過程中發生讀取錯誤 → `[KS-SKIP]` 靜默略過，輸出錯誤原因後繼續執行
- 所有降級情境均不阻塞 Sprint 執行
