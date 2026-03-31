# shoot 外部獨立審查規則

本文件定義 `/shoot` 的外部獨立審查規則，由 `skills/shoot/SKILL.md` 按需載入。

---

## 外部獨立審查（步驟 5.3）

<!-- Issue #257 — 移植 sprint-execution/SKILL.md §3-4 外部獨立審查機制 -->

在 QA Post-check 通過後、CI/CD 雙審查 Gate 前，由**獨立 QA subagent**（非執行實作的 agent）重新驗證品質。

### 與 Sprint Execution 的差異

| 面向 | Sprint Execution | Shoot |
|------|-----------------|-------|
| 審查率 | **100% 全量**（#958 修正） | **固定 100%**（單任務，無抽樣意義） |
| 審查內容 | Spec Compliance + Code Quality | **相同** |
| DISPUTE 處理 | 回傳缺陷 → 修復 → 二審 | **相同** |
| 審查 agent | 獨立 sonnet subagent | **相同** |

### 執行流程

1. 派遣獨立 QA subagent（model: sonnet），傳入：
   - 原始任務描述 / AC
   - 實作修改的檔案清單與 diff
2. 獨立 subagent 執行 Spec Compliance + Code Quality 審查
3. 回傳結果：**CONFIRM** 或 **DISPUTE**

### CONFIRM 路徑

記錄結果，繼續步驟 5.5（CI/CD 雙審查 Gate）。

### DISPUTE 路徑

1. 回傳結構化缺陷清單（含嚴重度：Critical / Major / Minor）
2. 實作者修復缺陷
3. **強制第二輪外部審查**（無論缺陷嚴重度）
4. 第二輪結果：
   - CONFIRM → 繼續
   - DISPUTE → 升級至 Architect，exit code 非 0，終止

### 輸出格式

```
── 外部獨立審查 ───────────────────────
  [CONFIRM] Spec Compliance + Code Quality 通過
```

DISPUTE 時：

```
── 外部獨立審查 ───────────────────────
  [DISPUTE] 發現以下缺陷：
    - [Critical] AC3 實作偏離描述：預期回傳 404，實際回傳 500
    - [Minor] 函式 processOrder 超過 20 行

  修復中...

── 外部獨立審查（第二輪） ─────────────
  [CONFIRM] 缺陷已修復，品質通過
```

<HARD-GATE>
**外部獨立審查 Hard Gate（/shoot）**：固定 100% 外部獨立審查。DISPUTE 後強制二審，二審仍 DISPUTE → 升級 Architect，exit code 非 0，禁止 commit。
</HARD-GATE>
