# Log 格式完整範例

**單一 repo 模式**（`"repo"` 欄位仍存在，值為該 repo 的 owner/repo）：

```jsonl
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:00+0800","type":"po-patrol","repo":"KCTW/shikigami","strict":false,"threshold_days":3,"summary":"掃描 15 個 open issues，處置完畢","actions":["triage #301","auto-shoot #310","sprint-candidate #312","auto-close #315","waiting #320: 1h elapsed","skipped #321: stakeholder-issue"],"actionable_issues":[310],"sprint_candidates":[312]}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:05+0800","type":"sre-inspection","repo":"KCTW/shikigami","summary":"檢查 10 筆 CI run，發現 1 個 CI failure，建立 1 個 Issue","actions":["create-issue-with-debug #321"]}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:10+0800","type":"auto-shoot-completed","repo":"KCTW/shikigami","cycle":1,"issue":310,"result":"success"}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:31:00+0800","type":"trigger-sprint-planning","repo":"KCTW/shikigami","reason":"count=3"}
```

**多 repo 模式**（每個 repo 各一筆 log entry）：

```jsonl
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:00+0800","type":"po-patrol","repo":"KCTW/shikigami","strict":false,"threshold_days":3,"summary":"掃描 15 個 open issues，處置完畢","actions":["triage #301","auto-shoot #310"],"actionable_issues":[310],"sprint_candidates":[]}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:02+0800","type":"sre-inspection","repo":"KCTW/shikigami","summary":"檢查 10 筆 CI run，無異常","actions":[]}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:04+0800","type":"po-patrol","repo":"KCTW/project-x","strict":false,"threshold_days":3,"summary":"掃描 8 個 open issues，處置完畢","actions":["sprint-candidate #50"],"actionable_issues":[],"sprint_candidates":[50]}
{"session_id":"abc123","cycle":1,"timestamp":"2026-03-21T10:30:06+0800","type":"sre-inspection","repo":"KCTW/project-x","summary":"檢查 5 筆 CI run，發現 1 個 failure","actions":["create-issue-with-debug #45"]}
```

## 主 loop 寫入的 log entry 類型（#343 修正 #340）

| 類型 | 說明 |
|------|------|
| `"auto-shoot-completed"` | shoot 完成，含 result（success/failed） |
| `"auto-shoot-escalated"` | 同一 Issue 連續 2 次 shoot fail，升級為 sprint-candidate（AC-5） |
| `"auto-shoot-stale-cleared"` | SHOOT_FLAG 殘留超過 30 分鐘，強制清除 |
| `"trigger-sprint-planning"` | sprint-candidate ≥ 3 或 1 個超過 30min，觸發 Sprint Planning（AC-3） |
