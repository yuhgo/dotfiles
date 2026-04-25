# AGENTS.md - Claude Code グローバル設定

`~/.claude/` にシンボリックリンクされる Claude Code のグローバル設定。

> `~/.claude` → `/Users/yamamotoyugo/ghq/github.com/yuhgo/dotfiles/claude` のシンボリックリンク。
> 設定変更は必ず dotfiles 側を編集すること。

## 方針の要点

- **agents / commands / skills は原則プラグインで賄う**（SuperClaude 系の旧 `agents/` `commands/` は 2026-04 に撤去済み）
- **プラグイン: `claude-code-harness` を中核に、`codex`・`example-skills` を併用**
- **記憶係は `harness-mem` に一本化**（`claude-mem` / `claude-mem-japanese` は使っていない。下記「非アクティブなプラグイン」参照）
- **MCP: 最小構成**（`obsidian-vault`・`google-calendar` のみを dotfiles 側 `.mcp.json` で管理。他は Claude 本体や各プラグイン側）

## Plan モードのルール

- Plan ファイルを作成するときは、**内容を要約した日本語のファイル名**にする
- 例: `認証機能の実装計画.md`、`API設計のリファクタリング.md`、`バグ修正_ログイン画面.md`
- ランダムな英数字や意味のないファイル名は使わない
- 保存先: `./docs/plan/`（`plansDirectory` で設定済み）

## インストール済みプラグイン

`settings.json#enabledPlugins` と `plugins/installed_plugins.json` で管理。

| プラグイン | バージョン | 役割 |
|-----------|-----------|------|
| `claude-code-harness@claude-code-harness-marketplace` | 4.1.1 | メインのワークフローハーネス（plan / work / review / release） |
| `codex@openai-codex` | 1.0.3 | Codex CLI 連携（rescue / 2nd opinion） |
| `example-skills@anthropic-agent-skills` | b0cbd3d… | Anthropic 公式スキル集（pdf/xlsx/pptx/docx ほか） |

> 過去に併用していた `claude-mem@thedotmack` / `claude-mem-japanese@claude-mem-jp` は 2026-04 に撤去済み（記憶係は `harness-mem` に一本化）。

### プラグイン提供の agents（Task ツール経由で呼び出し）

`claude-code-harness` が提供する統合エージェント群:

| エージェント | 役割 |
|-------------|------|
| `claude-code-harness:scaffolder` | プロジェクト分析・足場構築・状態更新 |
| `claude-code-harness:worker` | 実装 → preflight 自己点検 → 検証 → コミット準備 |
| `claude-code-harness:reviewer` | sprint-contract を基準に static/runtime/browser 観点でレビュー |
| `claude-code-harness:advisor` | 実行せず方針だけ返すアドバイザー |
| `claude-code-harness:team-composition` | 上記の編成・オーケストレーション |

`codex` プラグインが提供:

| エージェント | 役割 |
|-------------|------|
| `codex:codex-rescue` | Claude が詰まったとき Codex CLI に投げて 2nd opinion / 別実装を得る |

### プラグイン提供の主な skills

`claude-code-harness` 側（抜粋）:

| skill | 用途 |
|-------|------|
| `harness-plan` / `harness-work` / `harness-review` / `harness-release` | Plans.md ベースの PDCA 本体 |
| `harness-setup` / `harness-sync` / `maintenance` | 初期化・進捗同期・アーカイブ |
| `memory` | SSOT（decisions.md / patterns.md）管理。`harness-mem` との橋渡しもここ |
| `session-init` / `session-state` / `session-control` / `session-memory` | セッション状態遷移の内部ワークフロー |
| `harness-loop` / `breezing` | 長時間・並列チーム実行 |
| `ci` / `cc-update-review` / `claude-codex-upstream-update` | CI 赤対応・CC/Codex アップストリーム取り込み |
| `ui` / `auth` / `crud` | ボイラープレート生成 |
| `agent-browser` | ブラウザ操作 |
| `principles` / `workflow-guide` / `vibecoder-guide` | 原則・ガイド |
| `cc-cursor-cc` | Cursor PM ↔ Claude Code の 2-Agent ラウンドトリップ |

`codex` 側: `codex:setup`・`codex:rescue` など。
`example-skills` 側: `pdf` / `xlsx` / `pptx` / `docx` / `skill-creator` / `mcp-builder` ほか。

## dotfiles 直営の skills (`skills/`)

プラグインに寄せきれない、個人ワークフロー特化のスキル。

| skill | 用途 |
|-------|------|
| `harness-mem` | `@chachamaru127/harness-mem` **デーモン**の管理リファレンス（start/stop/doctor/mise node 切替対応）。claude-code-harness の `memory` skill とは役割が別（後述） |
| `git-commit-message` | Conventional Commits 形式の日本語コミットメッセージ生成 |
| `git-pr` | PR 作成フロー |
| `claudemd-generator` | リポジトリ分析して CLAUDE.md を自動生成・更新 |
| `empirical-prompt-tuning` | agent向けプロンプトをサブエージェントで検証して反復改善 |
| `zero-base-review` | SSOT / シンプルさ観点のゼロベース設計レビュー |
| `next-best-practices` / `next-lighthouse-loop` / `lighthouse` | Next.js 運用・計測 |
| `playwright-cli` / `dogfood` | ブラウザ自動化・探索的テスト |
| `infisical-cli` | シークレット管理（Infisical Cloud / `infisical run` / `infisical secrets`） |
| `bitwarden-cli` / `vercel-env-sync` | パスワード保管庫 / Vercel env 同期 |
| `csv-from-sample` / `sales-and-payment-csv` | 確定申告 CSV 生成 |
| `farm-in-daily-report` / `daily-report-tsv` / `obsidian-fill-daily-done` | 日報・Obsidian 連携 |
| `find-skills` | インストール可能 skill の発見（シンボリックリンク） |

### `harness-mem` skill と claude-code-harness の関係

claude-code-harness は `harness-mem` を**オプション依存**として扱う:

- **harness-mem なし**: イベントは `.claude/state/memory-bridge-events.jsonl` にローカル記録（外部依存ゼロ）
- **harness-mem あり**: MCP (`mcp__harness__harness_mem_*`) 経由でセッション横断の検索・resume pack が可能

役割分担:

| レイヤー | 担当 | 内容 |
|---------|------|------|
| デーモン運用（start/stop/doctor/port/mise） | dotfiles `skills/harness-mem` | `@chachamaru127/harness-mem` パッケージ本体の面倒を見る |
| SSOT 管理（decisions.md / patterns.md） | `claude-code-harness:memory` | プロジェクト固有の意思決定を永続化し、`harness-mem` を検索ソースとして使う |
| セッション跨ぎの記憶 | `harness-mem` デーモン | 作業履歴・resume pack・横断検索を MCP (`mcp__harness__harness_mem_*`) 経由で提供 |

→ **記憶係は `harness-mem` に一本化**している（かつて併用していた `claude-mem` プラグインは廃止）。
独自の `skills/harness-mem` は **削除しない**（デーモン管理リファレンスとして必要）。
claude-code-harness 内蔵の `memory` skill とは役割が別（SSOT 管理 vs デーモン運用）。

## 設定ファイル

| ファイル | 内容 |
|---------|------|
| `settings.json` | 権限（allow/deny）、hooks、statusLine、有効化プラグイン、`plansDirectory`、`CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` ほか |
| `.mcp.json` | MCP サーバー定義（obsidian-vault / google-calendar のみ） |
| `statusline.ts` | コンテキスト使用率・git 状態・コスト・harness-mem 接続状態を表示 |
| `mcp-templates.json` | MCP テンプレート集（任意利用） |
| `scripts/block-infisical-raw-read.sh` | `infisical secrets get` 等の value 直読みを PreToolUse でブロック |
| `scripts/save-ghostty-tab.sh` | SessionStart で Ghostty タブ情報を保存 |
| `scripts/upgrade-claude.sh` | Claude Code 本体の Homebrew アップグレード |

## ディレクトリ構成（概略）

```
claude/
├── AGENTS.md                    # このファイル
├── CLAUDE.md                    # claude-mem によって動的に注入される
├── settings.json                # グローバル設定
├── .mcp.json                    # MCP サーバー定義
├── statusline.ts                # ステータスライン
├── mcp-templates.json           # MCP テンプレート
├── skills/                      # dotfiles 直営の skill（前述）
├── scripts/                     # hooks 用シェルスクリプト
├── customizations/              # プロジェクト横断のカスタマイズ（harness-review 等）
├── plugins/                     # プラグインキャッシュ（自動管理）
└── (その他 Claude 本体の実行時生成物)
```

## 運用ルール

- 設定変更は **必ず dotfiles 側** を編集する（`~/.claude/` は単なるシンボリックリンク）
- `.local` / `.private` 拡張子は gitignore 対象（機密情報用）
- `sudo` / `rm` / `git push` 等の破壊的操作は `settings.json` の `deny` で禁止済み
- `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` により Claude Code 本体の自動メモリは無効化し、記憶は `harness-mem` に一元化
- プラグインを追加するときは `settings.json#enabledPlugins` と `extraKnownMarketplaces` を更新

## 2-Agent Workflow（PM ↔ Impl）

詳細は `.claude/rules/workflow.md` 参照。タスクは `Plans.md` でマーカー管理（`pm:依頼中` / `cc:WIP` / `cc:完了` / `pm:確認済`）。

## セキュリティ

詳細は `.claude/rules/security-guidelines.md` 参照。認証・API・機密設定パスの変更は注意レベル付きで扱う。

## シークレット管理方針

シークレット（API キー / 認証情報 / DB 接続文字列など）の取り扱いは以下を厳守する。

### Infisical Cloud を使う

- **`infisical-cli` skill を使う**（`infisical run` で環境変数注入 / `infisical secrets` で管理）
- ローカル開発・CI/CD・本番でそれぞれ最適な認証方式を選べるため、長寿命の機械可読トークンを抱える鶏卵問題を回避できる

### 環境別の認証方式

| 環境 | 認証方式 | 補足 |
|------|---------|------|
| ローカル開発 | `infisical login`（ブラウザ OAuth） | 機械可読なトークンを手元に置かない |
| CI/CD（GitHub Actions / GitLab CI） | **OIDC Auth** | プロバイダの OIDC トークンを直接交換。長寿命 secret を CI に置かない |
| AWS（EC2 / ECS / Lambda） | **IAM Auth** | インスタンスプロファイル / IAM ロールを使う |
| 上記に当てはまらないスクリプト | Universal Auth | `INFISICAL_CLIENT_ID` / `INFISICAL_CLIENT_SECRET` は Bitwarden 等に保管（Infisical 自身に入れない＝鶏卵） |

### 本番環境

本番デプロイ先（Vercel / Cloudflare Workers / AWS / GCP）では、それぞれのプラットフォームのシークレットストアに**直接**入れる:

- Vercel: `vercel env add`
- Cloudflare Workers: `wrangler secret put`
- AWS: `aws ssm put-parameter --type SecureString`
- GCP: `gcloud secrets create`

Infisical はローカル開発と CI/CD のシークレット同期の起点として使い、本番ランタイムは各プラットフォームのストアを正とする。

### 禁止事項

- ❌ **`.env` / `.env.*` への直書き**（`.env.example` のみ追跡対象）
- ❌ **コード内ハードコード**（`const API_KEY = "..."`）
- ❌ Claude が `infisical secrets get` 等の **value 直読み系コマンドを実行する**こと
  - PreToolUse hook (`claude/scripts/block-infisical-raw-read.sh`) で機械的にブロック済み
- ❌ Infisical の Universal Auth 認証情報を `.env` や設定ファイルに入れること（鶏卵を生む）

詳細は `claude/skills/infisical-cli/SKILL.md` を参照。
