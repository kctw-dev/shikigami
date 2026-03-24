# Skill Description 寫作規範

## 格式規則

1. 統一以英文 `"Use when..."` 開頭
2. 列舉 2-4 個具體觸發場景，用逗號分隔
3. 長度控制在 80-200 字元
4. 可用 em dash（`—`）接補充說明
5. 避免實作細節（不寫 "Handles..."、"Performs..."、"Returns..."）
6. 避免中文（Claude Code skill matching 引擎以英文為主）
7. 內部機制型 Skill 仍用 `"Use when..."`，描述框架內部觸發場景

## 範例

**Good**:
```
"Use when backlog grooming is needed, requirements change, new stories need RICE scoring, or backlog health maintenance is due"
```

**Good**（含補充說明）:
```
"Use when starting cruise mode, automated patrol, periodic issue scanning, or background monitoring — enables PO patrol + SRE inspection loops"
```

**Bad**（中文）:
```
"Backlog 管理工具。處理需求變更、RICE 評分、健康度監控。"
```

**Bad**（實作細節）:
```
"Use when executing tasks. Handles task selection, QA gates, implementation, and lightweight logging."
```

**Bad**（太廣泛）:
```
"Use when starting any conversation"
```

## 驗證指令

```bash
# 確認 29/29 均以 "Use when" 開頭、無中文
grep -r 'description:' skills/*/SKILL.md | grep -v 'Use when'
# 應回傳空（無不符項目）
```
