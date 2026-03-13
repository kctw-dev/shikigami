# Sprint 94

**Sprint Goal**：修復版號一致性測試技術債 — 確保 CI 驗證腳本在缺少 `jq` 環境下正確報告失敗，恢復 4 個 FAIL 測試至 PASS 狀態
**日期**：2026-03-13
**容量**：1 point
**狀態**：進行中

## Sprint Backlog

| Story | Issue | Size | Points | 狀態 |
|-------|-------|------|--------|------|
| US-256：retro: 修復版號一致性測試 — Sprint 93 既有 FAIL 技術債清理 | #253 | S | 1 | 待開發 |

## Acceptance Criteria 摘要

### US-256

- **AC1**：`tests/test-validate-version.sh` 全數測試 PASS（0 FAIL）
- **AC2**：`validate-version.sh` 在 `jq` 不存在時輸出含安裝建議的錯誤訊息並 exit 1，且 `test-validate-version.sh` 含對應測試案例
- **AC3**：修復後 CI 整合驗證通過
- **AC4**：版本提取結果為空字串時，腳本 FAIL 而非靜默 PASS
- **NFR1**：腳本執行時間 < 5s
- **NFR2**：不引入新外部依賴（或依賴需於 preflight 明確驗證）

## 技術評估摘要

- US-256：S/1pt，INFRA type。修復 `validate-version.sh` 在 `jq` 缺失環境下的錯誤處理，補充空字串 FAIL 邏輯，新增對應測試案例。修改範圍：`/scripts/validate-version.sh`、`/tests/test-validate-version.sh`。無 ADR 需求，無 API 契約。

## Refinement 記錄

- US-256：S-size 豁免，無需 Refinement
