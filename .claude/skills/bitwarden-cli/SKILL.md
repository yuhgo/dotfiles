---
name: bitwarden-cli
description: Bitwarden CLIの主要コマンド・オプション・ワークフローのリファレンス。bwコマンド、パスワード管理、シークレット取得、TOTP、ボールト操作、パスワード生成、Send機能、API認証に関する質問や作業で必ず使用すること。「bw get」「bw login」「bw generate」などBitwarden CLI関連のコマンドが会話に出てきた場合もトリガーする。
allowed-tools: Bash, Read
---

# Bitwarden CLI スキル図

`bw` コマンドによるパスワード管理のリファレンス。

## 認証フロー

```
[未認証] --bw login--> [ログイン済・ロック中] --bw unlock--> [アンロック済]
                                                                    |
                                                              BW_SESSION 設定
                                                                    |
                                                              コマンド実行可能
                                                                    |
                                              bw lock <--+---> bw logout
                                          [ロック中に戻る]    [未認証に戻る]
```

### ログイン方法

```bash
# 対話的ログイン（通常利用）
bw login

# APIキー認証（自動化・CI向け）
bw login --apikey

# SSO認証
bw login --sso
```

### セッション管理

```bash
# アンロック → セッションキー取得
bw unlock
export BW_SESSION="<返されたセッションキー>"

# パスワードを環境変数から読み取ってアンロック
bw unlock --passwordenv BW_PASSWORD

# ロック（セッション無効化、ログイン状態は維持）
bw lock

# ログアウト（完全にセッション破棄）
bw logout

# 状態確認
bw status
```

## 主要コマンド一覧

### ボールト操作（CRUD）

| コマンド | 説明 | 例 |
|---------|------|-----|
| `bw list items` | アイテム一覧 | `bw list items --search github` |
| `bw list folders` | フォルダ一覧 | |
| `bw list collections` | コレクション一覧 | |
| `bw get item <名前/ID>` | アイテム取得 | `bw get item "GitHub"` |
| `bw get password <名前/ID>` | パスワードのみ取得 | `bw get password "GitHub"` |
| `bw get username <名前/ID>` | ユーザー名のみ取得 | |
| `bw get uri <名前/ID>` | URIのみ取得 | |
| `bw get totp <名前/ID>` | TOTP コード取得 | `bw get totp "GitHub"` |
| `bw get notes <名前/ID>` | メモ取得 | |
| `bw create item` | アイテム作成 | （テンプレート + jq + encode） |
| `bw edit item <ID>` | アイテム編集 | （get + jq + encode） |
| `bw delete item <ID>` | アイテム削除 | |

### テンプレートを使った作成・編集

```bash
# アイテム作成
bw get template item | jq '.name="My Login" | .login.username="user@example.com" | .login.password="pass123"' | bw encode | bw create item

# フォルダ作成
bw get template folder | jq '.name="Work"' | bw encode | bw create folder

# パスワード変更
bw get item <ID> | jq '.login.password="new_password"' | bw encode | bw edit item <ID>
```

### 検索とフィルタ

```bash
# 名前で検索
bw list items --search "github"

# フォルダIDでフィルタ
bw list items --folderid <FOLDER_ID>

# コレクションIDでフィルタ
bw list items --collectionid <COLLECTION_ID>

# 組織IDでフィルタ
bw list items --organizationid <ORG_ID>

# URLで検索
bw list items --url "https://github.com"
```

### ユーティリティ

| コマンド | 説明 | 例 |
|---------|------|-----|
| `bw generate` | パスワード生成 | `bw generate -ulns --length 20` |
| `bw encode` | Base64エンコード（パイプ用） | |
| `bw sync` | サーバーと同期 | `bw sync` |
| `bw export` | ボールトエクスポート | `bw export --format json` |
| `bw import` | ボールトインポート | |
| `bw config` | 設定変更 | `bw config server https://...` |
| `bw update` | CLI更新チェック | |

### パスワード生成オプション

```bash
# フルオプション
bw generate -ulns --length 20

# オプション説明:
#   -u  大文字 (uppercase)
#   -l  小文字 (lowercase)
#   -n  数字 (numbers)
#   -s  特殊文字 (special characters)
#   --length <N>  文字数指定

# パスフレーズ生成
bw generate --passphrase --words 4 --separator "-"
```

### Send（安全な共有）

```bash
# テキストSend作成
bw send create --name "shared-secret" --text "機密情報"

# ファイルSend作成
bw send create --name "document" --file ./secret.pdf

# Send一覧
bw send list

# Send削除
bw send delete <ID>
```

## グローバルオプション

| オプション | 説明 |
|-----------|------|
| `--pretty` | JSON出力を整形表示 |
| `--raw` | 生データのみ出力（スクリプト向け） |
| `--quiet` | 標準出力を抑制 |
| `--session <key>` | セッションキーを直接指定 |
| `--nointeraction` | 対話プロンプトを無効化（CI向け） |
| `--response` | API応答をそのまま返す |

## 環境変数

| 変数 | 用途 |
|------|------|
| `BW_SESSION` | アクティブなセッションキー |
| `BW_CLIENTID` | APIキー認証の client_id |
| `BW_CLIENTSECRET` | APIキー認証の client_secret |
| `BW_PASSWORD` | `--passwordenv` 用マスターパスワード |
| `BITWARDENCLI_APPDATA_DIR` | データディレクトリの指定 |
| `NODE_EXTRA_CA_CERTS` | 自己署名証明書パス |

## よく使うワークフロー

### 日常利用

```bash
# 1. アンロック
export BW_SESSION=$(bw unlock --raw)

# 2. パスワード取得してクリップボードへ（macOS）
bw get password "GitHub" | pbcopy

# 3. TOTP取得
bw get totp "GitHub"

# 4. 作業終了
bw lock
```

### スクリプト・自動化

```bash
# APIキーでログイン + アンロック
export BW_CLIENTID="client_id_xxxxx"
export BW_CLIENTSECRET="client_secret_xxxxx"
bw login --apikey
export BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw)

# パスワード取得して利用
DB_PASS=$(bw get password "Production DB")
```

### 新規アイテム登録

```bash
# テンプレートからアイテム作成
bw get template item | jq '
  .type = 1 |
  .name = "New Service" |
  .login.username = "myuser" |
  .login.password = "'$(bw generate -ulns --length 20)'" |
  .login.uris = [{"uri": "https://example.com"}]
' | bw encode | bw create item
```

## トラブルシューティング

```bash
# 状態確認
bw status

# 強制同期
bw sync --force

# セルフホストサーバー設定
bw config server https://your-bitwarden.example.com

# ヘルプ表示
bw --help
bw <command> --help
```
