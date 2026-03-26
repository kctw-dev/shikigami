# measure-complexity.sh Fixture Directory

This directory contains fixture structures for testing the `measure-complexity.sh` script in isolation.

## Structure

- `minimal/` — 最小化 repo 結構（用於測試基本計數）
- `full/` — 完整 repo 結構（用於複雜場景測試）

## Usage

Fixture 隔離確保測試不會修改真實 repo 檔案，所有測試案例在臨時目錄下建立，測試完成後自動清除。

## Notes

- 每個測試案例動態建立所需的 fixture
- 不在 VCS 中提交實際的 fixture 內容，僅保留 README 說明
- Fixture 目錄本身用作 test hooks 的參考位置
