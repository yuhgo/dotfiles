---
name: bws-cli
description: 【DEPRECATED】Bitwarden Secrets Manager CLI（bws）の参照用ガイド。**新規プロジェクトでは `infisical-cli` skill を使うこと**。本 skill は既存 bws プロジェクトを触る必要がある場面（旧データの確認 / プロジェクト退役処理 / Infisical 移行作業のソース側参照）に限ってトリガーする。「bws」「BWS_ACCESS_TOKEN」「bws run」「bws secret」「bws project」など bws 固有のコマンドや「bws から Infisical への移行」が話題に出た場合のみ発動する。汎用のシークレット管理・環境変数・本番シークレット注入の話題は `infisical-cli` skill に任せる。
allowed-tools: Bash, Read
---

# 【DEPRECATED】環境変数・シークレット管理ガイド (bws)

> **⚠️ 移行済み**: 本リポジトリは 2026 年に `bws`（Bitwarden Secrets Manager）から Infisical Cloud へ全面移行した。
> **新規プロジェクトでは [`infisical-cli` skill](../infisical-cli/SKILL.md) を使うこと**。
>
> bws-cli skill は次の用途のみで残している:
> - 既存 bws プロジェクトの参照（移行が完了していないプロジェクト）
> - Infisical 移行スクリプト（`claude/skills/infisical-cli/scripts/import-from-bws.py`）の実行時にソース側の確認が必要な場面
> - bws プロジェクトを「DEPRECATED-」プレフィックス等で退役させる作業
>
> **新しいシークレットを bws に追加しないこと**。Infisical 側に直接追加する。

シークレット（APIキーなど）の安全な取り扱い方を定義するスキル。
ローカル開発では **Bitwarden Secrets Manager CLI（`bws`）** を使い、本番環境では**各プラットフォームのシークレットストア**を使う。

## 設計思想：なぜ `.env` ではなく `bws` を使うのか

AI エージェント（Claude Code など）は `.env` ファイルを `Read` ツールで読み取れてしまう。
`bws run` を使えば：

- シークレットが**ファイルとして存在しない**ため、ファイル読み取りで漏洩しない
- **子プロセスの環境変数にだけ注入**されるため、AI エージェントから直接アクセスしにくい
- コマンド終了後は環境変数も消えるため、**残留リスクがない**

### 基本方針

- `.env` ファイルにシークレットをべた書きしない
- ローカル開発では **`bws run`** で環境変数を注入する
- 本番環境では**各プラットフォームのシークレットストア**を使う
- `.env` / `.env.*` は `.gitignore` 済み（`.env.example` のみ追跡対象）

### セキュリティリスクと対策

| リスク | 対策 |
|--------|------|
| `.env` ファイルへのべた書き | `.gitignore` 済み + `bws run` を使う |
| AI エージェントによるファイル読み取り | `bws run` でファイルに書かない |
| AI エージェントによる `echo $VAR` 実行 | Claude Code 自体のプロセスにはキーを渡さず、`bws run` の子プロセスにだけ渡す |
| Git への誤コミット | `.gitignore` で `.env` / `.env.*` を除外済み |
| 本番シークレットの漏洩 | 各プラットフォームの暗号化ストレージに保存。コードやファイルに残らない |

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

## 環境別ワークフロー

### ローカル開発

```bash
# bws run で環境変数を注入してコマンド実行
bws run --project-id <PID> -- npm run dev
bws run --project-id <PID> -- npm test
bws run --project-id <PID> -- python manage.py runserver
bws run --project-id <PID> -- 'docker compose up'
```

こうするとシークレットがプロセスの環境変数として渡される。ファイルには一切書き込まれない。

### CI/CD

CI 環境では `BWS_ACCESS_TOKEN` を CI のシークレットストアに登録し、`bws run` で注入する。

```yaml
# 例: GitHub Actions
env:
  BWS_ACCESS_TOKEN: ${{ secrets.BWS_ACCESS_TOKEN }}
steps:
  - run: bws run --project-id <PID> -- npm test
```

### 本番環境へのシークレット設定

本番環境では各プラットフォームのシークレットストアを使用する。
**bws からシークレットを取得し、各プラットフォームの CLI でセットする**のが基本パターン。

#### 手順

1. `bws` でシークレットのメタ情報を確認（value は見ない）
2. 各プラットフォームの CLI で対話的にシークレットを登録（値は手動入力、または `bws run` 経由で注入）

#### プラットフォーム別コマンド

**Vercel**:
```bash
# 対話的に値を入力
vercel env add <KEY_NAME> production

# bws run 経由で自動設定
bws run --project-id <PID> -- sh -c 'echo "$KEY_NAME" | vercel env add KEY_NAME production'
```

**Cloudflare Workers**:
```bash
# 対話的に値を入力
npx wrangler secret put <KEY_NAME>

# bws run 経由で自動設定
bws run --project-id <PID> -- sh -c 'echo "$KEY_NAME" | npx wrangler secret put KEY_NAME'
```

**AWS Systems Manager Parameter Store**:
```bash
# bws run 経由で自動設定
bws run --project-id <PID> -- sh -c \
  'aws ssm put-parameter --name "/app/KEY_NAME" --value "$KEY_NAME" --type SecureString --overwrite'
```

**Google Cloud Secret Manager**:
```bash
# bws run 経由で自動設定
bws run --project-id <PID> -- sh -c \
  'echo -n "$KEY_NAME" | gcloud secrets create KEY_NAME --data-file=-'
```

#### シークレットの確認（値は表示されない）

```bash
vercel env ls                           # Vercel
npx wrangler secret list                # Cloudflare Workers
aws ssm get-parameters-by-path --path "/app/" --query "Parameters[].Name"  # AWS
gcloud secrets list                     # GCP
```

## bws コマンドリファレンス

### bws run（環境変数注入）

`bws run` はシークレットを環境変数として注入した状態でコマンドを実行する。
Claude Code との連携で最も重要な機能。

```bash
# プロジェクト内の全シークレットを環境変数として注入
bws run --project-id <PROJECT_ID> -- <COMMAND>
```

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
```

設定ファイルは `~/.bws/config` に保存される。

## セットアップ

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

## セキュリティのベストプラクティス

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

## 参考：bw との違い

| 項目 | `bw`（Password Manager） | `bws`（Secrets Manager） |
|------|--------------------------|--------------------------|
| 用途 | 個人のパスワード管理 | マシン/CI/自動化向けシークレット管理 |
| 認証 | マスターパスワード + セッション | アクセストークン（期限付き可） |
| 権限 | ボールト全体 | プロジェクト単位で制限可能 |
| Claude Code 連携 | 不向き（広すぎる権限） | 最適（最小権限で運用可能） |

## 参考：出力オプション

`-o` / `--output` フラグで出力形式を指定できる。

| 形式 | 説明 |
|------|------|
| `json` | JSON（デフォルト） |
| `yaml` | YAML |
| `table` | ASCII テーブル |
| `tsv` | タブ区切り |
| `env` | KEY=VALUE 形式 |
| `none` | エラー/警告のみ |

⚠️ Claude Code からは `table` / `env` / `yaml` 形式を直接使わないこと（value が見える）。

## 参考：グローバルオプション

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

## 参考：環境変数

| 変数 | 用途 |
|------|------|
| `BWS_ACCESS_TOKEN` | アクセストークン（設定必須） |
