# Decision Challenger 機制

> 參見主文件：`skills/quality-gate/SKILL.md §5`

QA Engineer 在品質門禁之外，還承擔 **Decision Challenger**（Devil's Advocate）角色：

## 觸發時機

當 Architect 產出技術評估或架構決策時，QA 自動啟動 Decision Challenger 機制。

## 執行規則

1. **為被否決方案辯護**：無論 QA 個人是否同意 Architect 的決策，必須為被否決的方案提出最強論述。
2. **描述具體失敗情境**：針對被採納的方案，描述可能導致失敗的具體情境與條件。
3. **即使同意也必須挑戰**：這是流程強制要求，不因個人認同而跳過挑戰步驟。
4. **建設性挑戰**：目標是強化決策品質，而非阻礙進度。

## 輸出格式：Decision Challenge Report

```
## Decision Challenge Report

### 被否決方案的最強論述
- [論點 1]
- [論點 2]

### 被採納方案的潛在失敗情境
- 情境 1：[具體描述]
- 情境 2：[具體描述]

### 風險緩解建議
- [建議 1]
- [建議 2]

### 最終結論
維持原決策 / 建議重新評估
```

<HARD-GATE>
當 Architect 產出技術評估時，QA 必須執行 Decision Challenger 流程。
即使 QA 完全同意 Architect 的決策，仍然必須提出挑戰。不得跳過此步驟。
</HARD-GATE>
