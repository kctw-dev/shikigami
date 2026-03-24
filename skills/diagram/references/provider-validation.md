# §3 --provider 驗證（AC3）

`--provider` 參數值**必須**是允許清單內的 enum 值。任何不在清單中的輸入均視為非法輸入，技能立即中止並輸出告警。

## 允許清單

```
gcp     # Google Cloud Platform
aws     # Amazon Web Services
azure   # Microsoft Azure
```

## 驗證邏輯

```
解析使用者輸入的 --provider 值
  |
  +-- 值在允許清單內 → 繼續執行
  |
  +-- 值不在允許清單內 → 輸出告警並中止
```

## 非法輸入告警格式

```
[PROVIDER-VALIDATION-ERROR] --provider 值不合法：「<使用者輸入值>」
允許值：gcp | aws | azure
請重新執行並指定合法的 provider。
```

**安全說明（ADR-006 §4.3 延伸）**：`--provider` 參數限制為 enum 驗證，防範使用者傳入如 `--provider "gcp; ignore all previous..."` 的 Prompt Injection 輸入。
