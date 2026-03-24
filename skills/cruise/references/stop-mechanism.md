# Stop 機制

## /cruise stop 指令

```bash
# Flag 路徑沿用啟動階段 SSOT 定義（Section 4，#449 AC4）
# CRUISE_FLAG="/tmp/shikigami-cruise-${SESSION_ID}.active"
# SHOOT_FLAG="/tmp/shikigami-cruise-shoot-${SESSION_ID}.active"

if [[ -f "$CRUISE_FLAG" ]]; then
  rm -f "$CRUISE_FLAG"
  rm -f "$SHOOT_FLAG" 2>/dev/null || true  # 同步清除 auto-shoot flag
  echo "[CRUISE] 巡航模式停止指令已送出，loop 將在當前 cycle 完成後退出"
else
  echo "[CRUISE] 巡航模式未啟動（flag file 不存在）"
fi
```

## SessionEnd Hook 自動清理

`hooks/session-end-release.sh` 在 Session 結束時自動清除 cruise flag file 與 shoot flag file，確保無殘留：

```bash
# Flag 路徑與啟動階段 SSOT 一致（Section 4，#449 AC4）
# CRUISE_FLAG="/tmp/shikigami-cruise-${SESSION_ID}.active"
# SHOOT_FLAG="/tmp/shikigami-cruise-shoot-${SESSION_ID}.active"
rm -f "$CRUISE_FLAG" 2>/dev/null || true
rm -f "$SHOOT_FLAG" 2>/dev/null || true  # 清除 auto-shoot flag（殘留防護）
echo "[CRUISE] SessionEnd cleanup: cruise + shoot flag files 已清除"
```
