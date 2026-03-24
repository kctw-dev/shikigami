# SECURITY_RULES.md — Prompt Injection Defense 規則集

<!-- Story #393: Prompt Injection Defense — Security Gate 擴充 -->
<!-- ADR-006 §Security Gate 擴充章節 -->

**版本**：v1.0（初始規則集）
**日期**：2026-03-24
**維護者**：Security Engineer Agent

---

## 說明

本檔案定義 Prompt Injection Defense Gate 的偵測規則。規則為外部化設計，可由 Operator 視場景調整，無需修改 SKILL.md。

Security Gate 在以下進入點執行掃描：
1. **需求文件輸入**（Intake 階段）：PO 收到原始需求後、Architect 開始設計前
2. **外部工具回應**：任何 external API call 的回應進入 agent context 前

---

## 規則定義

### HIGH RISK 規則（觸發流程暫停，通知 Stakeholder）

| 規則 ID | 分類 | 描述 | 偵測模式（Regex） |
|---------|------|------|-----------------|
| HR-001 | 角色覆寫指令 | 嘗試讓 agent 忘記或覆寫其系統指令 | `ignore (previous\|all) instructions` |
| HR-002 | 角色覆寫指令 | 嘗試讓 agent 以不同身份行動 | `you are now (a different\|an?) \| act as (root\|admin\|superuser)` |
| HR-003 | 角色覆寫指令 | 聲稱忽略上下文 | `disregard your (system prompt\|instructions) \| forget (everything\|all)` |
| HR-004 | 權限提升 | 聲稱有框架管理員授權 | `as (a )?framework (administrator\|admin)` |
| HR-005 | 權限提升 | 嘗試 bypass 流程門禁 | `(authorize\|grant) you to (skip\|bypass\|override)` |
| HR-006 | 權限提升 | 使用 sudo / escalate 語義 | `sudo \| escalate privilege` |

### MEDIUM RISK 規則（寫入 trace log，繼續執行並附 warning）

| 規則 ID | 分類 | 描述 | 偵測模式（Regex） |
|---------|------|------|-----------------|
| MR-001 | 資訊外洩 | 嘗試列舉框架內部檔案 | `list all files\|show me (your\|the) (skill\|system\|config)` |
| MR-002 | 資訊外洩 | 嘗試提取系統 prompt | `output (the system prompt\|your prompt\|your instructions)` |
| MR-003 | 資訊外洩 | 嘗試摘要內部文件 | `summarize (each )?ADR\|summarize.*SKILL\.md` |
| MR-004 | 隱藏指令 | 疑似 base64 編碼內容（≥20 字元純 base64）| Base64 pattern |
| MR-005 | 角色混淆 | 要求 agent 扮演某個技術角色而非提需求 | `pretend you are\|roleplay as (a )?developer` |

---

## 處置規則

```
if risk_level == "HIGH_RISK":
    # 暫停流程，通知 Stakeholder
    log: "[SECURITY-GATE-HIGH] 偵測到高風險 prompt injection 模式，流程暫停"
    notify Stakeholder: "⚠️ 疑似 prompt injection 攻擊，流程暫停待人工確認"
    return: ESCALATE: SECURITY_CRITICAL

elif risk_level == "MEDIUM_RISK":
    # 寫入 trace log，附 warning 繼續
    trace_log: "[SECURITY-GATE-MEDIUM] 偵測到中風險模式，記錄並繼續"
    append_warning: "⚠️ SECURITY-GATE-MEDIUM: 此輸入包含可疑模式，結果需人工複核"
    return: CONTINUE_WITH_WARNING

else:  # PASS
    return: PASS
```

---

## 豁免規則

以下情境允許豁免（需明確標注）：
- 由框架自身產生的內部訊息（如 Retro Summary、Sprint Report）
- 已知安全的固定範本文字（如 Issue 自動 Intake 範本）
- Security Engineer subagent 在執行安全審查時的範例輸入

豁免標注格式：`[SECURITY-GATE-EXEMPT: <reason>]`

---

## 更新記錄

| 版本 | 日期 | 變更 |
|------|------|------|
| v1.0 | 2026-03-24 | 初始規則集（Sprint 134, #393）|
