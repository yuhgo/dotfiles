---
name: infisical-cli
description: 環境変数・シークレット管理の総合ガイド。Infisical Cloud（および self-hosted Infisical）を中心に、ローカル開発・CI/CD・本番環境でのシークレットの安全な取り扱いを定義する。.env ファイルへの直書きやハードコードよりも `infisical run` による環境変数注入を優先する。本番環境へのシークレット設定時は、各プラットフォームの CLI（vercel env, wrangler secret, aws ssm, gcloud secrets）と Infisical を組み合わせて使用する。「infisical」「infisical run」「infisical secrets」「infisical login」「Universal Auth」「Machine Identity」「INFISICAL_CLIENT_ID」「INFISICAL_CLIENT_SECRET」「INFISICAL_TOKEN」「OIDC Auth」「IAM Auth」「シークレット管理」「シークレット注入」「環境変数」「APIキー」「.env」「env」「本番シークレット」「CI/CDシークレット」「vercel env」「wrangler secret」「aws ssm」「gcloud secrets」などの話題が会話に出てきた場合にトリガーする。
allowed-tools: Bash, Read
---

# 環境変数・シークレット管理ガイド (Infisical)

シークレット（API キーなど）の安全な取り扱い方を定義するスキル。
ローカル開発では **Infisical CLI（`infisical`）** を使い、本番環境では**各プラットフォームのシークレットストア**を使う。

## 設計思想：なぜ `.env` ではなく `infisical run` を使うのか

AI エージェント（Claude Code など）は `.env` ファイルを `Read` ツールで読み取れてしまう。
`infisical run` を使えば：

- シークレットが**ファイルとして存在しない**ため、ファイル読み取りで漏洩しない
- **子プロセスの環境変数にだけ注入**されるため、AI エージェントから直接アクセスしにくい
- コマンド終了後は環境変数も消えるため、**残留リスクがない**

### 基本方針

- `.env` ファイルにシークレットをべた書きしない
- ローカル開発では **`infisical run`** で環境変数を注入する
- 本番環境では**各プラットフォームのシークレットストア**を使う
- `.env` / `.env.*` は `.gitignore` 済み（`.env.example` のみ追跡対象）

### セキュリティリスクと対策

| リスク | 対策 |
|--------|------|
| `.env` ファイルへのべた書き | `.gitignore` 済み + `infisical run` を使う |
| AI エージェントによるファイル読み取り | `infisical run` でファイルに書かない |
| AI エージェントによる `echo $VAR` 実行 | Claude Code 自体のプロセスにはキーを渡さず、`infisical run` の子プロセスにだけ渡す |
| Git への誤コミット | `.gitignore` で `.env` / `.env.*` を除外済み |
| 本番シークレットの漏洩 | 各プラットフォームの暗号化ストレージに保存。コードやファイルに残らない |
| ローカル認証情報自体の管理（鶏卵問題） | `infisical login` 方式（ブラウザ OAuth）で機械可読なトークンを持たない。スクリプト用は Universal Auth → 認証情報は Bitwarden 等に隔離 |

## ⚠️ Claude Code セキュリティルール（必須）

**Claude はシークレットの value を絶対に読んではならない。**

以下のルールを厳守すること：

1. **`infisical secrets get <KEY>` を直接実行してはならない**（出力に value が含まれるため）
2. **`infisical secrets` の `--plain` / `-o env` / `-o yaml` / `-o dotenv` を使ってはならない**（value が出る）
3. **`infisical export` 系コマンドを使ってはならない**（シークレット全体がダンプされる）
4. **一覧表示は `--silent` を付けた**通常のテーブル出力（**SECRET VALUE 列も出るが key 一覧の確認用にのみ使い、値は読まない**）か、後述の jq 経由で key だけ抜き出す
5. **`infisical run` は安全**（value が Claude のコンテキストに入らないため）
6. **`infisical secrets set` は安全**（value を書き込むだけで読まないため、ただし**コマンドラインに value を渡すと shell 履歴に残る**ので `--type=shared` + 標準入力 / Bitwarden からの注入を使う）

### 安全なコマンドパターン

```bash
# ✅ key 一覧だけを取得（jq で value 列を捨てる）
infisical secrets --env=dev --projectId=<PROJECT_ID> --silent -o json \
  | jq -r '.[].secretKey' | sort

# ✅ メタ情報のみ（key / type / 更新日時など、value 以外）
infisical secrets --env=dev --projectId=<PROJECT_ID> --silent -o json \
  | jq '[.[] | {secretKey, type, version, updatedAt}]'

# ✅ infisical run による環境変数注入（value は子プロセスにのみ渡される）
infisical run --env=dev --projectId=<PROJECT_ID> -- <COMMAND>

# ✅ シークレット作成（値を **環境変数経由** で渡す → shell 履歴に残らない）
SECRET_VALUE=$(bw get item ... | jq -r '.fields[]...') \
  infisical secrets set <KEY> "$SECRET_VALUE" \
  --env=dev --projectId=<PROJECT_ID> --type=shared

# ❌ 禁止: value が Claude に見える
infisical secrets get <KEY> --env=dev --projectId=<PID>
infisical secrets --env=dev --projectId=<PID> --plain
infisical secrets --env=dev --projectId=<PID> -o env
infisical secrets --env=dev --projectId=<PID> -o dotenv
infisical secrets --env=dev --projectId=<PID> -o yaml
infisical export --env=dev --projectId=<PID>
```

> **補足**: `infisical secrets` のデフォルトテーブル出力は `SECRET VALUE` 列を含む。
> 短い値（数文字）であれば見えてしまうため、**Claude が直接叩く時は必ず `-o json | jq` で `secretKey` のみ抽出する**こと。

## 認証方式の使い分け

Infisical の認証は環境ごとに使い分ける。**「ローカル＝ブラウザログイン、機械＝最小権限の Machine Identity」が原則**。

| 環境 | 認証方式 | 使う理由 |
|------|---------|---------|
| ローカル開発 | `infisical login`（OAuth ブラウザ） | 機械可読なトークンを手元に置かない。鶏卵問題が発生しない |
| CI/CD（GitHub Actions / GitLab CI） | **OIDC Auth** | プロバイダ側の OIDC トークンを直接交換できる。長寿命の secret を CI に置かない |
| AWS（EC2 / ECS / Lambda） | **IAM Auth** | インスタンスプロファイルや IAM ロールを使う。資格情報を一切外に出さない |
| 上記に当てはまらないスクリプト・ジョブ・本番ワーカー | **Universal Auth** | `INFISICAL_CLIENT_ID` / `INFISICAL_CLIENT_SECRET` のペアで認証。資格情報自体は別所（Bitwarden / Vercel env 等）で管理 |

### 認証情報自体の置き場所（鶏卵問題）

| 認証方式 | client_id / client_secret 等の置き場所 |
|---------|----------------------------------------|
| `infisical login` | 不要（ブラウザ側でセッション管理） |
| OIDC Auth | 不要（プロバイダの OIDC トークンを使う） |
| IAM Auth | 不要（IAM ロールを使う） |
| Universal Auth | **Bitwarden** や **Vercel env / Cloudflare secret / AWS SSM** など、Infisical 自身に入れない場所に保管（Infisical に入れたら鶏卵） |

## 環境別ワークフロー

### ローカル開発

```bash
# 初回だけ：ブラウザで OAuth ログイン
infisical login

# 各プロジェクトのルートで：infisical init で workspace 紐付け
infisical init

# infisical run で環境変数を注入してコマンド実行
infisical run --env=dev -- npm run dev
infisical run --env=dev -- npm test
infisical run --env=dev -- python manage.py runserver
infisical run --env=dev -- 'docker compose up'

# infisical init していない場合は --projectId を渡す
infisical run --env=dev --projectId=<PID> -- npm run dev
```

こうするとシークレットがプロセスの環境変数として渡される。ファイルには一切書き込まれない。

### CI/CD（OIDC Auth 推奨）

CI 環境では OIDC を使い、長寿命の secret を CI に置かない：

```yaml
# 例: GitHub Actions（OIDC）
permissions:
  id-token: write    # OIDC トークン発行のため必須
  contents: read

steps:
  - uses: Infisical/secrets-action@v1
    with:
      method: oidc
      identity-id: ${{ vars.INFISICAL_IDENTITY_ID }}   # secret ではなく vars で OK
      project-slug: my-project
      env-slug: <ENV_SLUG>    # テストなら dev / staging、デプロイ前検証なら prod
  - run: npm test    # この時点で secrets が env に入っている
```

> **環境スラグの選び方**: テストは `dev` / `staging`、production deploy 直前の smoke test だけ `prod`。
> CI で本番 secret を読む頻度を最小化する（漏洩リスクの面でも、Infisical のレート制限の面でも）。

OIDC が使えない CI（古いプラットフォーム等）では Universal Auth で `INFISICAL_CLIENT_ID` / `INFISICAL_CLIENT_SECRET` を CI のシークレットストアに登録：

```yaml
env:
  INFISICAL_CLIENT_ID: ${{ secrets.INFISICAL_CLIENT_ID }}
  INFISICAL_CLIENT_SECRET: ${{ secrets.INFISICAL_CLIENT_SECRET }}
steps:
  - run: |
      export INFISICAL_TOKEN=$(infisical login --method=universal-auth \
        --client-id=$INFISICAL_CLIENT_ID --client-secret=$INFISICAL_CLIENT_SECRET --silent --plain)
      infisical run --env=prod --projectId=<PID> -- npm test
```

### 本番環境へのシークレット設定

本番環境では各プラットフォームのシークレットストアを使用する。
**Infisical からシークレットを取得し、各プラットフォームの CLI でセットする**のが基本パターン。

#### 手順

1. `infisical secrets ... -o json | jq '.[].secretKey'` でメタ情報を確認（value は見ない）
2. 各プラットフォームの CLI で対話的にシークレットを登録（値は手動入力、または `infisical run` 経由で注入）

#### プラットフォーム別コマンド

**Vercel**:
```bash
# 対話的に値を入力
vercel env add <KEY_NAME> production

# infisical run 経由で自動設定
infisical run --env=prod --projectId=<PID> -- \
  sh -c 'echo "$KEY_NAME" | vercel env add KEY_NAME production'
```

**Cloudflare Workers**:
```bash
# 対話的に値を入力
npx wrangler secret put <KEY_NAME>

# infisical run 経由で自動設定
infisical run --env=prod --projectId=<PID> -- \
  sh -c 'echo "$KEY_NAME" | npx wrangler secret put KEY_NAME'
```

**AWS Systems Manager Parameter Store**:
```bash
# infisical run 経由で自動設定
infisical run --env=prod --projectId=<PID> -- \
  sh -c 'aws ssm put-parameter --name "/app/KEY_NAME" --value "$KEY_NAME" --type SecureString --overwrite'
```

**Google Cloud Secret Manager**:
```bash
# infisical run 経由で自動設定
infisical run --env=prod --projectId=<PID> -- \
  sh -c 'echo -n "$KEY_NAME" | gcloud secrets create KEY_NAME --data-file=-'
```

#### シークレットの確認（値は表示されない）

```bash
vercel env ls                           # Vercel
npx wrangler secret list                # Cloudflare Workers
aws ssm get-parameters-by-path --path "/app/" --query "Parameters[].Name"  # AWS
gcloud secrets list                     # GCP
```

> **環境分離は 1 プロジェクト × 複数環境**で運用する。`--env` フラグの指定漏れは事故の元（`dev` / `staging` / `prod` を別プロジェクトにしない）。

## infisical コマンドリファレンス

### infisical run（環境変数注入）

`infisical run` はシークレットを環境変数として注入した状態でコマンドを実行する。
Claude Code との連携で最も重要な機能。

```bash
# プロジェクト内の指定環境の全シークレットを環境変数として注入
infisical run --env=<ENV_SLUG> --projectId=<PROJECT_ID> -- <COMMAND>

# infisical init 済みなら --projectId 省略可
infisical run --env=<ENV_SLUG> -- <COMMAND>

# 特定 path だけ注入（Infisical の folder 構造を活用）
infisical run --env=prod --path=/api -- node server.js
```

### シークレット管理（infisical secrets）

| コマンド | 説明 |
|---------|------|
| `infisical secrets --env=<E> --projectId=<PID> --silent -o json \| jq '[.[] \| {secretKey, type}]'` | 一覧（**value 除外必須**） |
| `infisical secrets get <KEY> ...`（**禁止**） | 単一取得（value が出る） |
| `infisical secrets set <KEY> <VALUE> --env=<E> --projectId=<PID> --type=shared` | 作成・更新 |
| `infisical secrets delete <KEY> --env=<E> --projectId=<PID>` | 削除 |
| `infisical secrets folders ... ` | folder 操作 |

### 環境・workspace 操作

```bash
# プロジェクトの workspace 紐付け（.infisical.json を生成）
infisical init

# domain 指定（self-hosted や EU Cloud）
infisical login --domain=https://eu.infisical.com/api
# または env で
export INFISICAL_API_URL=https://eu.infisical.com/api
```

`.infisical.json` には `workspaceId` と `defaultEnvironment` が入る。**コミット可**（プロジェクト ID は秘匿情報ではない）。

## セットアップ

```bash
# 1. Infisical CLI のインストール（macOS）
brew install infisical

# 2. ブラウザログイン
infisical login

# 3. プロジェクトディレクトリで workspace 紐付け
cd my-project
infisical init

# 4. 接続確認（key 一覧だけ）
infisical secrets --env=dev --silent -o json | jq '[.[] | {secretKey}]'
```

### Universal Auth セットアップ（スクリプト用）

```bash
# 1. Infisical UI で Machine Identity を作成
#    Settings → Access Control → Machine Identities → Create Identity
#    → Auth Method: Universal Auth
#    → 必要なプロジェクトに read / write 権限を付与
# 2. Client ID / Client Secret を発行
# 3. 認証情報を Infisical 以外の場所に保管（鶏卵回避）
#    例: Bitwarden に Secure Note + custom field で client_id / client_secret
# 4. 必要時に env に注入して使う
export INFISICAL_CLIENT_ID=$(bw get item "Infisical Machine Identity" | jq -r '.fields[] | select(.name=="client_id").value')
export INFISICAL_CLIENT_SECRET=$(bw get item "Infisical Machine Identity" | jq -r '.fields[] | select(.name=="client_secret").value')
```

## セキュリティのベストプラクティス

- **Universal Auth の secret は短命のものを優先**（できれば自動ローテーション）
- **Machine Identity には必要最小限のプロジェクト権限**のみ付与（read-only / 特定 env のみ）
- `INFISICAL_CLIENT_SECRET` を `.env` や設定ファイルに**ハードコードしない**
- CI/CD では **OIDC Auth を最優先**。Universal Auth のフォールバックは最後の手段
- ローカルでは `infisical login` の OAuth セッションを使い、機械可読なトークンを手元に置かない
- 認証情報そのものは **Infisical 以外**（Bitwarden / 1Password / Vercel env / Cloudflare secret / AWS SSM）に保管（鶏卵回避）
- 定期的に Machine Identity の credential をローテーション

## トラブルシューティング

```bash
# バージョン確認
infisical --version

# ヘルプ表示
infisical --help
infisical secrets --help
infisical run --help

# ログイン状態確認
infisical user

# ログアウト・再ログイン
infisical logout
infisical login

# domain ミスマッチ（EU Cloud / self-hosted）
infisical login --domain=https://eu.infisical.com/api
# または環境変数
export INFISICAL_API_URL=https://eu.infisical.com/api
```

### よくあるエラー

| エラー | 原因 | 対処 |
|--------|-----|------|
| `Error: must be logged in` | `infisical login` 未実行 | `infisical login` を再実行 |
| `Error: project not found` | `--projectId` 不一致 or `infisical init` 未実行 | UI で project ID を再確認 |
| `Error: environment not found` | `--env` のスラグ違い | UI で環境スラグ（`dev` / `staging` / `prod`）を確認 |
| `401 Unauthorized` | Universal Auth の credential 不正 / 権限不足 | Machine Identity の権限と client_secret を確認 |
| `429 Too Many Requests` | レート制限 | 短時間の大量 API 呼び出しを避ける |

## 参考：出力オプション

`-o` / `--output` フラグで出力形式を指定できる。

| 形式 | 説明 |
|------|------|
| `json` | JSON（**Claude が叩くならこれ + jq で key だけ抽出**） |
| `yaml` | YAML（value が見える、Claude は禁止） |
| `dotenv` | KEY=VALUE 形式（value が見える、Claude は禁止） |
| `table`（デフォルト） | ASCII テーブル（value 列も出る、Claude が叩く時は値を読まない運用） |

## 参考：グローバルオプション

| オプション | 説明 |
|-----------|------|
| `--domain <URL>` | Infisical instance URL（self-hosted / EU Cloud 用） |
| `--silent` | tip / info メッセージ抑制（CI/CD 推奨） |
| `--telemetry=false` | テレメトリ無効化 |
| `-l, --log-level <LEVEL>` | ログレベル（trace / debug / info / warn / error / fatal） |
| `-h, --help` | ヘルプ表示 |
| `--version` | バージョン表示 |

## 参考：環境変数

| 変数 | 用途 |
|------|------|
| `INFISICAL_TOKEN` | Universal Auth で取得した access token（短期） |
| `INFISICAL_CLIENT_ID` | Universal Auth client ID |
| `INFISICAL_CLIENT_SECRET` | Universal Auth client secret |
| `INFISICAL_API_URL` | API エンドポイント（self-hosted / EU 用） |
| `INFISICAL_DISABLE_UPDATE_CHECK` | アップデート通知抑制 |
