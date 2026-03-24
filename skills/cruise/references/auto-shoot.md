# Auto-shoot 連續派遣

SHOOT_FLAG **只防併發，不防連續**。shoot 完成後立即檢查下一個 actionable，不等下一 cycle：

```bash
# 偽碼：shoot 完成後立即 re-check（在主 loop 內）
#
# 重要（#346）：auto-shoot 與 close 的區分
#   - auto-shoot（有程式碼修改）→ 必須 invoke shikigami:shoot（完整 QA gates）
#   - close（已修復結案）→ 直接 gh issue close，不走 shoot
#   - 禁止直接派 Developer Agent 跳過 shoot 流程

# Step 1：先處理 close 處置（不走 shoot，直接關閉）
for ISSUE in CLOSE_ISSUES:
  gh issue close ${ISSUE} -R ${OWNER_REPO} --comment "<結案理由>"
  log: "close #${ISSUE}"

# Step 2：連續 auto-shoot（走完整 /shoot 流程）
while ACTIONABLE_ISSUES is not empty:
  if SHOOT_FLAG 不存在:
    ISSUE = ACTIONABLE_ISSUES.shift()  # 取出第一個
    echo "$ISSUE" > SHOOT_FLAG
    # !! 必須 invoke shikigami:shoot，不是派 Developer Agent !!
    # 更新對應 Story Task 狀態為 in-progress（#513 AC3）
    TaskUpdate subject="Story #${ISSUE}:*" status=in-progress
    invoke shikigami:shoot with args=#${ISSUE}  # 完整 QA + Architect + PR + CI Gate
    等待 shoot 完成
    if shoot 成功:
      rm -f SHOOT_FLAG
      SHOOT_FAIL_COUNT[ISSUE] = 0
      # 更新對應 Story Task 狀態為 completed（#513 AC3）
      TaskUpdate subject="Story #${ISSUE}:*" status=completed
      log: "auto-shoot-completed #${ISSUE} success"
    else:
      rm -f SHOOT_FLAG
      SHOOT_FAIL_COUNT[ISSUE] += 1
      if SHOOT_FAIL_COUNT[ISSUE] >= 2:  # AC-5：連續 2 次 fail → 升級
        gh issue edit ${ISSUE} -R ${OWNER_REPO} --add-label sprint-candidate
        # 更新對應 Story Task 狀態為 failed（#513 AC3）
        TaskUpdate subject="Story #${ISSUE}:*" status=failed
        log: "auto-shoot-escalated #${ISSUE} → sprint-candidate (2 consecutive failures)"
      else:
        log: "auto-shoot-completed #${ISSUE} failed (attempt ${SHOOT_FAIL_COUNT[ISSUE]})"
  # 立即繼續下一個，不 sleep
```

**actionable 優先序**（從 ACTIONABLE_ISSUES 中排序）：
1. `sre-auto-debug` label（CI failure，最緊急）
2. `bug` label
3. 其餘 Size=S Issue

**主 loop 寫入的 log entry 類型**（#343 修正 #340）：

| 類型 | 說明 |
|------|------|
| `"auto-shoot-completed"` | shoot 完成，含 result（success/failed） |
| `"auto-shoot-escalated"` | 同一 Issue 連續 2 次 shoot fail，升級為 sprint-candidate（AC-5） |
| `"auto-shoot-stale-cleared"` | SHOOT_FLAG 殘留超過 30 分鐘，強制清除 |
| `"trigger-sprint-planning"` | sprint-candidate ≥ 3 或 1 個超過 30min，觸發 Sprint Planning（AC-3） |
