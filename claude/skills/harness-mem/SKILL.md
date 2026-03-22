---
name: harness-mem
description: harness-mem（セッション跨ぎ記憶デーモン）の管理・トラブルシューティング用スキル。デーモンの起動・停止・診断、構成確認、nodeバージョン切替時の対応など。「harness-mem」「harness-memd」「記憶デーモン」「daemon_unavailable」「セッション記憶」「メモリデーモン」「harness-mem doctor」などの話題が出たときにトリガーする。
allowed-tools: Bash, Read
---

# harness-mem スキル

`@chachamaru127/harness-mem` によるセッション間の学習・記憶永続化の管理リファレンス。

## 概要

- 過去のガードレール発動、実装パターン、バグ修正履歴をセッション跨ぎで活用
- `impl` / `review` / `verify` / `session-init` スキルが過去の知見を自動参照
- 重要な学びは SSOT（`decisions.md` / `patterns.md`）に昇格可能

## デーモン管理

| コマンド | 説明 |
|---------|------|
| `harness-memd start` | デーモン起動（port 37888） |
| `harness-memd stop` | デーモン停止 |
| `harness-memd restart` | 再起動 |
| `harness-memd status` | 稼働状態確認 |
| `harness-memd doctor` | 診断（bun/curl/pid/health/ui チェック） |
| `harness-memd cleanup-stale` | stale な PID/ロックファイルを除去 |

## 構成

| 項目 | パス |
|------|------|
| 状態ディレクトリ | `~/.harness-mem/` |
| SQLite DB | `~/.harness-mem/harness-mem.db` |
| デーモンログ | `~/.harness-mem/daemon.log` |
| Health API | `http://127.0.0.1:37888/health` |
| UI | `http://127.0.0.1:37901` |

## 環境変数

| 変数 | デフォルト | 説明 |
|------|-----------|------|
| `HARNESS_MEM_HOME` | `~/.harness-mem` | 状態ディレクトリ |
| `HARNESS_MEM_DB_PATH` | `$HARNESS_MEM_HOME/harness-mem.db` | DB パス |
| `HARNESS_MEM_HOST` | `127.0.0.1` | バインドホスト |
| `HARNESS_MEM_PORT` | `37888` | デーモンポート |
| `HARNESS_MEM_UI_PORT` | `37901` | UI ポート |
| `HARNESS_MEM_ENABLE_UI` | `true` | UI 起動の有無 |

## インストール

```bash
npm install -g @chachamaru127/harness-mem
```

mise でnodeバージョンを切り替える場合、**各バージョンごとにグローバルインストールが必要**。

```bash
# 例: node 22 と 24 の両方にインストール
~/.local/share/mise/installs/node/22.20.0/bin/npm install -g @chachamaru127/harness-mem
~/.local/share/mise/installs/node/24.14.0/bin/npm install -g @chachamaru127/harness-mem
```

## MCP ツール

harness MCP サーバー経由で以下のツールが利用可能:

| ツール | 説明 |
|--------|------|
| `harness_mem_health` | デーモンヘルスチェック |
| `harness_mem_search` | 記憶の検索 |
| `harness_mem_record_event` | イベント記録 |
| `harness_mem_record_checkpoint` | チェックポイント記録 |
| `harness_mem_get_observations` | 観測値の取得 |
| `harness_mem_resume_pack` | セッション再開用コンテキスト取得 |
| `harness_mem_finalize_session` | セッション終了処理 |
| `harness_mem_sessions_list` | セッション一覧 |
| `harness_mem_timeline` | タイムライン表示 |

## harness-mem CLI サブコマンド

| コマンド | 説明 |
|---------|------|
| `harness-mem setup` | 初期セットアップ（デーモン起動 + スモークテスト） |
| `harness-mem doctor` | 配線・ヘルスの検証（`--fix` で修復） |
| `harness-mem versions` | 各ツールのバージョンスナップショット |
| `harness-mem update` | グローバルパッケージの更新 |
| `harness-mem smoke` | スモークテスト（record/search の動作確認） |
| `harness-mem uninstall` | 配線除去（DB 削除オプション付き） |
| `harness-mem import-claude-mem` | Claude-mem からのインポート |
| `harness-mem migrate-from-claude-mem` | Claude-mem からの完全移行 |
| `harness-mem promote` | バックエンドモード昇格（local → hybrid → managed） |

## トラブルシューティング

### `daemon_unavailable` エラー

```bash
# 1. 診断
harness-memd doctor

# 2. stale ファイル除去
harness-memd cleanup-stale

# 3. 起動
harness-memd start
```

### node バージョン切替後にコマンドが見つからない

```bash
# 現在のnodeバージョンを確認
node --version
which harness-memd

# 見つからない場合、そのバージョンにインストール
npm install -g @chachamaru127/harness-mem
```

### ポート競合

```bash
# ポート使用状況を確認
lsof -nP -tiTCP:37888 -sTCP:LISTEN
lsof -nP -tiTCP:37901 -sTCP:LISTEN
```

### DB が肥大化した場合

```bash
# DB サイズ確認
ls -lh ~/.harness-mem/harness-mem.db

# 古いセッションの整理は harness-mem admin 経由
```
