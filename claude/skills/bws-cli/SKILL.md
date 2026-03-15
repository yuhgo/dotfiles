---
name: bws-cli
description: Bitwarden Secrets Manager CLI（bws）のコマンドリファレンスと、Claude Codeとの安全な連携ワークフロー。環境変数の設定やシークレット情報の読み書きには極力 bws を使用すること。.envファイルへの直書きやハードコードよりも bws run による環境変数注入や bws secret get による取得を優先する。「bws」「secrets manager」「シークレット管理」「bws run」「bws secret」「bws project」「BWS_ACCESS_TOKEN」「環境変数」「APIキー」「トークン管理」「シークレット取得」などBWS CLI関連のコマンドや、環境変数・シークレット情報の読み書きに関する話題が会話に出てきた場合もトリガーする。既存の bitwarden-cli スキル（bw コマンド）とは別ツール。
allowed-tools: Bash, Read
---

# BWS CLI スキル（Bitwarden Secrets Manager CLI）

`bws` コマンドによるシークレット管理のリファレンス。
`bw`（Password Manager CLI）とは別のツールで、マシンアカウント向けに設計されている。

## bw との違い

| 項目 | `bw`（Password Manager） | `bws`（Secrets Manager） |
|------|--------------------------|--------------------------|
| 用途 | 個人のパスワード管理 | マシン/CI/自動化向けシークレット管理 |
| 認証 | マスターパスワード + セッション | アクセストークン（期限付き可） |
| 権限 | ボールト全体 | プロジェクト単位で制限可能 |
| Claude Code 連携 | 不向き（広すぎる権限） | 最適（最小権限で運用可能） |

## 認証

### アクセストークン設定

```bash
# 環境変数で設定（推奨）
export BWS_ACCESS_TOKEN=0.48c78342-1635-48a6-accd-afbe01336365.C0tMmQqHnAp1h0gL...

# コマンドごとにインラインで指定
bws secret list --access-token <TOKEN>
```

- Bitwarden Secrets Manager の Web UI で**組織 → プロジェクト → マシンアカウント**を作成
- マシンアカウントに対して**プロジェクト単位で権限を付与**できる
- アクセストークンには**有効期限を設定可能**（漏洩時の被害を限定）

### プロファイル

```bash
# プロファイル別にサーバー設定
bws config server-base https://my-server.com --profile prod

# プロファイル指定でコマンド実行
bws secret list --profile prod
```

## ⚠️ Claude Code セキュリティルール（必須）

**Claude はシークレットの value を絶対に読んではならない。**

以下のルールを厳守すること：

1. **`bws secret list` や `bws secret get` を直接実行してはならない**（出力に value が含まれるため）
2. **一覧表示は必ず jq で value を除外してから出力する**
3. **`bws run` は安全**（value が Claude のコンテキストに入らないため）
4. **`bws secret create` / `bws secret edit` / `bws secret delete` は安全**（value を書き込むだけで読まないため）

### 安全なコマンドパターン

```bash
# ✅ 一覧表示（value を除外）
bws secret list | jq '[.[] | {id, key, organizationId, projectId, creationDate, revisionDate}]'

# ✅ 特定プロジェクトの一覧（value を除外）
bws secret list <PROJECT_ID> | jq '[.[] | {id, key, organizationId, projectId, creationDate, revisionDate}]'

# ✅ 個別シークレットのメタ情報のみ（value を除外）
bws secret get <SECRET_ID> | jq '{id, key, organizationId, projectId, creationDate, revisionDate}'

# ✅ bws run による環境変数注入（value は子プロセスにのみ渡される）
bws run --project-id <PROJECT_ID> -- <COMMAND>

# ❌ 禁止: value が Claude に見える
bws secret list --output table
bws secret get <SECRET_ID> --output table
bws secret list --output env
bws secret list --output yaml
bws secret get <SECRET_ID>
```

## コマンドリファレンス

### シークレット管理（bws secret）

| コマンド | 説明 |
|---------|------|
| `bws secret list [PROJECT_ID] \| jq '[.[] \| {id, key, organizationId, projectId, creationDate, revisionDate}]'` | シークレット一覧（**value除外必須**） |
| `bws secret get <SECRET_ID> \| jq '{id, key, organizationId, projectId, creationDate, revisionDate}'` | メタ情報取得（**value除外必須**） |
| `bws secret create <KEY> <VALUE> <PROJECT_ID> --note "note"` | シークレット作成 |
| `bws secret edit <SECRET_ID> --key <KEY> --value <VALUE> --note <NOTE> --project-id <PID>` | 編集 |
| `bws secret delete <SECRET_ID> [<ID2> ...]` | 削除（複数指定可） |

### プロジェクト管理（bws project）

| コマンド | 説明 |
|---------|------|
| `bws project list` | プロジェクト一覧 |
| `bws project get <PROJECT_ID>` | プロジェクト取得 |
| `bws project create <NAME>` | プロジェクト作成 |
| `bws project edit <PROJECT_ID> --name <NEW_NAME>` | 名前変更 |
| `bws project delete <PROJECT_ID> [<ID2> ...]` | 削除 |

### 設定（bws config）

```bash
# セルフホストサーバー接続
bws config server-base https://my-bitwarden.example.com

# プロファイル付き
bws config server-base https://dev-server.com --profile dev

# 代替設定ファイル使用
bws config server-base https://server.com --config-file ~/.bws/alt_config --profile alt
```

設定ファイルは `~/.bws/config` に保存される。

### bws run（環境変数注入）

`bws run` はシークレットを環境変数として注入した状態でコマンドを実行する。
`.env` ファイルにシークレットを書く必要がなくなるため、Claude Code との連携で最も重要な機能。

```bash
# プロジェクト内の全シークレットを環境変数として注入してコマンド実行
bws run --project-id <PROJECT_ID> -- npm test
bws run --project-id <PROJECT_ID> -- 'docker compose up'
bws run --project-id <PROJECT_ID> -- python manage.py runserver
```

## 出力オプション

`-o` / `--output` フラグで出力形式を指定できる。

| 形式 | 説明 | 用途 |
|------|------|------|
| `json` | JSON（デフォルト） | プログラム処理 |
| `yaml` | YAML | 読みやすい表示 |
| `table` | ASCII テーブル | ターミナル確認 |
| `tsv` | タブ区切り | スプレッドシート連携 |
| `env` | KEY=VALUE 形式 | `.env` ファイル生成 |
| `none` | エラー/警告のみ | スクリプト用 |

```bash
# ⚠️ Claude Code からは以下の形式を直接使わないこと（value が見える）
# bws secret list --output table
# bws secret list --output env

# ✅ Claude Code からはjqでvalue除外して使う
bws secret list | jq '[.[] | {id, key, organizationId, projectId, creationDate, revisionDate}]'
```

## グローバルオプション

| オプション | 説明 |
|-----------|------|
| `-t, --access-token <TOKEN>` | アクセストークンを直接指定 |
| `--profile <NAME>` | 使用するプロファイル |
| `--config-file <PATH>` | 設定ファイルパス |
| `--server-url <URL>` | サーバーURL上書き |
| `-c, --color <yes\|no\|auto>` | 色出力制御 |
| `-o, --output <FORMAT>` | 出力形式 |
| `-h, --help` | ヘルプ表示 |
| `--version` | バージョン表示 |

## 環境変数

| 変数 | 用途 |
|------|------|
| `BWS_ACCESS_TOKEN` | アクセストークン（設定必須） |

## Claude Code 連携ワークフロー

### 設計思想：「短く狭い鍵を、必要なときだけ渡す」

Claude Code にシークレットを安全に扱わせるための3段階モデル：

1. **`.env` にシークレットを置かない** — ファイルベースの管理をやめ、漏洩リスクを排除
2. **専用 machine account で最小権限を付与** — Claude Code 用のアカウントを作り、必要なプロジェクトだけにアクセス権を設定
3. **`bws run` で必要なときだけ注入** — コマンド実行時のみシークレットが環境変数として存在し、終了後は消える

### セットアップ手順

```bash
# 1. BWS CLIのインストール（macOS）
brew install bitwarden/bws/bws

# 2. Bitwarden Secrets Manager Web UI で以下を準備：
#    - 組織の作成
#    - プロジェクトの作成（例: "claude-code-dev"）
#    - マシンアカウントの作成
#    - マシンアカウントにプロジェクトへの権限を付与
#    - 期限付きアクセストークンの発行

# 3. アクセストークンの設定
export BWS_ACCESS_TOKEN="<発行されたトークン>"

# 4. 接続確認
bws project list
```

### 日常的な使い方

```bash
# シークレットを注入してアプリ起動
bws run --project-id <PID> -- npm run dev

# シークレットを注入してテスト実行
bws run --project-id <PID> -- npm test

# シークレット一覧確認（value除外）
bws secret list <PROJECT_ID> | jq '[.[] | {id, key, organizationId, projectId, creationDate, revisionDate}]'

# 個別シークレットのメタ情報確認（value除外）
bws secret get <SECRET_ID> | jq '{id, key, organizationId, projectId, creationDate, revisionDate}'
```

### セキュリティのベストプラクティス

- アクセストークンには**短い有効期限**を設定する
- machine account には**必要最小限のプロジェクト権限**のみ付与
- `BWS_ACCESS_TOKEN` を `.env` や設定ファイルにハードコードしない
- CI/CD では環境変数やシークレットストアを経由してトークンを渡す
- 定期的にトークンをローテーションする

## トラブルシューティング

```bash
# バージョン確認
bws --version

# ヘルプ表示
bws --help
bws secret --help
bws run --help

# 認証エラー時：トークンの有効期限を確認
# → Secrets Manager Web UI でトークンを再発行

# レート制限エラー時：短時間に大量リクエストを避ける
```
