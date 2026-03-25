# INJECTION_RULES.md — Prompt Injection Defense 規則集（injection-scan.sh 專用）

<!-- Story #776 (Sprint 161) | ADR-006 延伸 -->

**版本**：v1.0
**日期**：2026-03-25
**維護者**：Security Engineer Agent
**關聯**：`scripts/injection-scan.sh`、`docs/definition/SECURITY_RULES.md`（母規則集）

---

## 說明

本檔案定義 `scripts/injection-scan.sh` 使用的輕量化 Prompt Injection 偵測規則，專為
Story body / 外部 API 回應掃描設計（pipeline 前置防護）。

規則為外部化設計，Operator 可調整，無需修改 SKILL.md 或 injection-scan.sh。

---

## HIGH RISK 規則（BLOCK — 流程停止，輸出 [INJECTION-GATE]）

| 規則 ID | 分類 | 描述 | 偵測關鍵字 |
|---------|------|------|-----------|
| HR-001 | 角色覆寫 | 忘記/覆寫系統指令 | `ignore (previous\|all) instructions` |
| HR-002 | 角色覆寫 | 以不同身份行動 | `you are now a different \| act as (root\|admin\|superuser)` |
| HR-003 | 角色覆寫 | 忽略上下文 | `disregard your (system prompt\|instructions) \| forget (everything\|all)` |
| HR-004 | 權限提升 | 聲稱管理員授權 | `as (a )?framework (administrator\|admin)` |
| HR-005 | 權限提升 | bypass 門禁 | `(authorize\|grant) you to (skip\|bypass\|override)` |
| HR-006 | 權限提升 | sudo 語義 | `\bsudo\b \| escalate privilege` |
| HR-007 | 規則覆寫 | 聲稱無規則 | `pretend you have no (rules\|safety guidelines\|restrictions\|instructions)` |
| HR-008 | 資訊竊取 | 要求揭露系統指令 | `reveal your (system instructions\|system prompt\|instructions to me)` |

## MEDIUM RISK 規則（WARN — 繼續執行，記錄警告）

| 規則 ID | 分類 | 描述 | 偵測關鍵字 |
|---------|------|------|-----------|
| MR-001 | 資訊外洩 | 列舉內部檔案 | `list all files \| show me (your\|the) (skill\|system\|config)` |
| MR-002 | 資訊外洩 | 提取系統 prompt | `output (the system prompt\|your prompt\|your instructions)` |
| MR-003 | 資訊外洩 | 摘要內部文件 | `summarize (each )?ADR \| summarize.*SKILL\.md` |
| MR-004 | 隱藏指令 | base64 編碼內容 | 20+ 字元純 base64 字串 |
| MR-005 | 角色混淆 | 扮演開發者 | `pretend you are \| roleplay as (a )?developer` |
| MR-006 | 模式切換 | 要求進入特權模式 | `enter (sudo\|elevated\|admin) mode` |

---

## 豁免規則

標注 `[SECURITY-GATE-EXEMPT: <reason>]` 的輸入跳過掃描。

適用場景：
- 框架自身產生的內部訊息（Retro Summary、Sprint Report）
- 已知安全的固定範本文字（Issue 自動 Intake 範本）
- Security Engineer subagent 執行安全審查時的範例輸入

---

## 更新記錄

| 日期 | 版本 | 變更 | 維護者 |
|------|------|------|--------|
| 2026-03-25 | v1.0 | 初始規則集建立（Story #776） | Security Engineer |
