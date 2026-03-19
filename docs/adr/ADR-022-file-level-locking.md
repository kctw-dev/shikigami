# ADR-022：檔案級別鎖定機制 — 多 Session 同時編輯衝突防護

**狀態**：Accepted
**日期**：2026-03-19
**決策者**：Architect（技術選型）+ QA Decision Challenger
**關聯 ADR**：ADR-007（Story Lifecycle Subagent）
**關聯 Issue**：#311（檔案級鎖定）、#312（Issue/Story 級 claim 機制）

---

## 背景

### 問題陳述

#312 已建立 Issue/Story 級別的 claim 機制（git refs + flock + GitHub assignee），確保同一個 Issue 不會被多個 Session 同時認領。然而，parallel-dispatch 場景中，多個 subagent 可能被派遣處理不同 Story，但這些 Story 的實作可能涉及同一檔案：

```
Session A（Story #301）──→ 修改 skills/sprint-execution/developer-prompt.md
Session B（Story #302）──→ 也要修改 skills/sprint-execution/developer-prompt.md
                          ↑ Issue claim 不衝突，但檔案層級衝突
```

**現況缺口**：

1. **Issue claim 粒度不足**：兩個不同 Issue 可以同時被 claim，但可能觸碰同一檔案
2. **parallel-dispatch 的「無共享狀態」假設**：SKILL.md 明確要求「不存取同一份資料、不寫入同一個檔案」，但目前無機制強制檢查
3. **git merge conflict 是事後發現**：衝突要等到 commit/push 才暴露，回滾成本高

### #312 claim 機制現況

| 組件 | 機制 | 範圍 |
|------|------|------|
| 遠端鎖 | `refs/claims/<issue_id>` git ref | 跨機器（透過 remote） |
| 本地鎖 | `flock /tmp/shikigami-claims-*.lock` | 單機 |
| Stale 偵測 | ref commit time > 2h → 強制清除 | 自動 |
| 釋放 | `session-end-release.sh` hook | SessionEnd 自動 |
| 展示層 | GitHub assignee + label | 可視化 |

---

## 決策問題

應採用何種機制實現檔案級別鎖定，防止多 Session 同時編輯同一檔案？

---

## 考慮的選項

### 選項 A：檔案系統 flock + lock 目錄

在本地建立 lock 目錄（如 `/tmp/shikigami-file-locks/`），對每個被編輯的檔案路徑做 hash，用 `flock` 鎖定對應的 lock file。

```
/tmp/shikigami-file-locks/
├── <sha256(relative_path)>.lock    # flock 鎖定
├── <sha256(relative_path)>.meta    # JSON：session_id, timestamp, path
└── ...
```

**優點**：
- 實作簡單，與 #312 的 flock 模式一致
- 無網路依賴，延遲極低
- lock 語義清晰（POSIX flock）

**缺點**：
- **僅限單機**：不同機器上的 Session 無法互斥（Kotodama 跨機器場景失效）
- 進程意外終止時 flock 自動釋放，但 `.meta` 可能殘留
- `/tmp` 重啟後清空，需要重建

### 選項 B：MCP Server 集中管理

新增 MCP Server（或擴展現有 `quality-observer`），提供 `file-lock/acquire`、`file-lock/release`、`file-lock/list` 等 tool。

**優點**：
- 天然跨機器（MCP Server 可部署為網路服務）
- 可提供豐富的 lock 資訊（owner、duration、queue）
- 與未來 Kotodama 多機器場景無縫整合

**缺點**：
- **需要額外基礎設施**：MCP Server 必須持續運行，增加部署複雜度
- 單點故障風險（MCP Server 掛掉 → 所有 Session 無法取得鎖）
- 與 #312 claim 機制完全獨立，兩套鎖定系統增加認知負擔
- 目前 Shikigami 的 MCP Server 使用 stdio transport，不支援跨進程共享狀態

### 選項 C：擴展既有 #312 claim 機制（建議）

複用 #312 的 git refs 架構，新增 `refs/file-locks/<path-hash>` namespace，將檔案路徑 hash 後作為 ref 名稱推送到 remote。

```
refs/claims/311          ← Issue 級 claim（#312 既有）
refs/file-locks/a1b2c3d4 ← 檔案級 lock（本 ADR 新增）
```

Lock ref 的 commit message 或 tag annotation 攜帶 metadata：
```
session=<session_id>
path=<relative_file_path>
timestamp=<unix_epoch>
issue=<issue_id>
```

**優點**：
- **複用既有基礎設施**：git remote 已存在，無需額外部署
- **跨機器互斥**：透過 `git push` 原子性，不同機器的 Session 自然互斥
- **與 #312 架構一致**：lock/release/stale-detect 三件套可直接套用
- **SessionEnd hook 可統一處理**：`session-end-release.sh` 擴展為同時清除 `refs/claims/*` 和 `refs/file-locks/*`
- **TTL 機制直接複用**：ref commit time > N 分鐘 → stale，強制清除

**缺點**：
- 每次 lock/release 需要 `git push`/`git push --delete`，有網路延遲（約 1-3 秒）
- `refs/file-locks/` 數量可能較多（一個 Story 可能觸碰 5-10 個檔案），需注意清理
- path hash 需要額外的 reverse mapping（hash → 原始路徑）

---

## 決策

**選擇選項 C：擴展既有 #312 claim 機制。**

理由：

1. **架構一致性**：與 #312 使用相同的 git refs + flock + stale-detect 架構，團隊只需學習一套鎖定模式
2. **跨機器支援**：git remote 天然提供跨機器互斥，為未來 Kotodama 場景做準備
3. **最小新增依賴**：不需要額外的 MCP Server 或新的基礎設施
4. **TTL + SessionEnd 統一管理**：stale lock 偵測和 session 結束時自動釋放可與 #312 共用邏輯
5. **選項 A 的單機限制**是硬傷——parallel-dispatch 目前雖在同機運行，但 Kotodama 的多機器協調已在 Roadmap 上
6. **選項 B 的 MCP Server 方案**過度工程——目前 stdio transport 不支援跨進程狀態共享，改為 SSE/HTTP 的遷移成本過高

---

## 實作設計

### 核心腳本

| 檔案 | 功能 |
|------|------|
| `hooks/acquire-file-lock.sh <path> [issue_id]` | 取得檔案鎖（lock） |
| `hooks/release-file-lock.sh <path>` | 釋放檔案鎖（unlock） |
| `hooks/file-lock-check.sh <path>` | 查詢檔案鎖狀態（non-blocking） |

### Ref 命名規則

```
refs/file-locks/<sha256(relative_path)[0:16]>
```

- 使用相對路徑（相對於 repo root）計算 hash，確保不同 clone 位置的一致性
- 取 sha256 前 16 字元，碰撞機率極低且 ref 名稱簡潔

### Metadata 編碼

Lock 建立時，在 `/tmp/shikigami-file-locks-<repo_fp>/` 存放 metadata 檔案：

```json
{
  "session_id": "abc-123",
  "path": "skills/sprint-execution/developer-prompt.md",
  "issue_id": "311",
  "timestamp": 1742403289,
  "ref": "refs/file-locks/a1b2c3d4e5f6g7h8"
}
```

同時 metadata 以 commit message 形式編碼到 ref 的 commit 中，供跨機器 stale 偵測使用。

### TTL 機制

| 情境 | TTL | 行為 |
|------|-----|------|
| 正常操作 | 無限（由 SessionEnd 釋放） | session-end-release.sh 統一清除 |
| Stale 偵測 | 30 分鐘 | ref commit time > 30min → 強制清除（檔案鎖比 Issue claim 的 2h 更短，因為檔案操作應該更快完成） |
| 手動釋放 | 立即 | `file-unlock.sh` 直接刪除 ref |

### parallel-dispatch 整合

在 parallel-dispatch SKILL 的 Step 1（識別獨立領域）增加檔案衝突預檢：

```
Step 0.5: 檔案衝突預檢
  - 列出各 subagent 預計觸碰的檔案清單
  - 若有重疊 → 標記為「有共享狀態」→ 不適用平行派遣
  - 若無重疊 → 各 subagent 在開始時 lock 所需檔案
```

### SessionEnd hook 擴展

`session-end-release.sh` 擴展為同時處理兩種 ref：

```bash
# 既有：release issue claims
git ls-remote origin "refs/claims/*" ...

# 新增：release file locks
git ls-remote origin "refs/file-locks/*" ...
```

### 降級策略（AC-6 精神延續）

| 失敗情境 | 行為 |
|---------|------|
| git remote 不可用 | 降級為本地 flock-only（選項 A 行為），輸出 `[WARN]` |
| flock 不可用（macOS） | 直接走遠端 ref 鎖 |
| lock 取得失敗 | 輸出 `[FILE-LOCK-BLOCKED]`，由上層決定是否等待或放棄 |

### 輸出標記

```
[FILE-LOCK-OK] refs/file-locks/<hash>        — 成功取得鎖
[FILE-LOCK-BLOCKED] refs/file-locks/<hash>   — 已被其他 session 鎖定
[FILE-LOCK-STALE] refs/file-locks/<hash>     — stale lock 清除後重新鎖定
[FILE-UNLOCK-OK] refs/file-locks/<hash>      — 成功釋放鎖
[WARN] <原因>                                — 降級警告
```

---

## 實作影響

### 需修改的檔案

| 檔案 | 修改內容 |
|------|---------|
| `hooks/acquire-file-lock.sh`（新增） | 檔案鎖 acquire 腳本 |
| `hooks/release-file-lock.sh`（新增） | 檔案鎖 release 腳本 |
| `hooks/file-lock-check.sh`（新增） | 檔案鎖狀態查詢腳本 |
| `hooks/session-end-release.sh` | 擴展為同時清除 `refs/file-locks/*` |
| `hooks/hooks.json` | 註冊新 hook 腳本 |
| `skills/parallel-dispatch/SKILL.md` | 新增 Step 0.5 檔案衝突預檢 |
| `tests/test-file-lock.sh`（新增） | 檔案鎖機制測試 |

### 與 #312 的關係

```
#312 claim 機制              #311 file-lock 機制
────────────────            ────────────────────
refs/claims/<issue_id>      refs/file-locks/<path-hash>
粒度：Issue/Story           粒度：單一檔案
TTL：2 小時                 TTL：30 分鐘
用途：防止重複認領 Story     用途：防止同時編輯同一檔案
觸發：SubagentStart hook    觸發：檔案寫入前
釋放：SessionEnd hook       釋放：SessionEnd hook（共用）
```

兩套機制共用基礎架構（git refs + flock + stale-detect + SessionEnd release），但各自獨立的 namespace 和 TTL 策略。

---

## 後果

### 正面

- **統一鎖定架構**：Issue claim 和 file lock 使用相同的 git refs 模式，學習曲線低
- **跨機器支援**：為 Kotodama 多機器協調預留能力，無需架構變更
- **自動清理**：TTL + SessionEnd 雙重保障，死鎖風險極低
- **parallel-dispatch 安全性提升**：從「假設無共享狀態」升級為「強制檢查無共享狀態」

### 負面

- **網路延遲**：每次 lock/unlock 需要 git push 操作（1-3 秒），頻繁鎖定時可能影響效率
- **ref 清理**：大量檔案操作後 `refs/file-locks/` 可能累積殘留 ref，需定期清理
- **hash 碰撞**：16 字元 sha256 prefix 碰撞機率極低（~1/2^64），但非零

### 風險緩解

| 風險 | 緩解措施 |
|------|---------|
| 網路延遲影響效率 | 批次 lock（一次 push 多個 ref）+ 本地 flock 做快速路徑 |
| ref 殘留累積 | SessionEnd hook 統一清除 + stale TTL 30 分鐘自動回收 |
| hash 碰撞 | metadata 中保存原始路徑，碰撞時 log 警告並降級為不鎖定 |
| git remote 暫時不可用 | 降級為本地 flock-only，不阻塞作業（AC-6 精神） |
