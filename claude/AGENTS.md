# AGENTS.md - Claude Code グローバル設定

`~/.claude/` にシンボリックリンクされるClaude Code のグローバル設定。

## Plan モードのルール

- Plan ファイルを作成するときは、**内容を要約した日本語のファイル名**にすること
- 例: `認証機能の実装計画.md`、`API設計のリファクタリング.md`、`バグ修正_ログイン画面.md`
- ランダムな英数字や意味のないファイル名は使わない
- 保存先: `./docs/plan/`（`plansDirectory` で設定済み）

## エージェント (`agents/`)

専門特化型エージェント20種。Taskツール経由で呼び出される。

| エージェント | 用途 |
|-------------|------|
| `code-reviewer` | コードレビュー、バグ・セキュリティ問題検出 |
| `backend-architect` | バックエンド設計、データ整合性、フォールトトレランス |
| `frontend-architect` | フロントエンドUI設計、UX |
| `system-architect` | システムアーキテクチャ設計 |
| `plan-creator` / `plan-executor` | 実装計画の作成と実行 |
| `pm-agent` | プロジェクト管理、ドキュメント維持、ミス分析 |
| `deep-research-agent` | 包括的な調査 |
| `technical-writer` | 技術ドキュメント作成 |
| `requirements-analyst` | 要件定義・分析 |
| `performance-engineer` | パフォーマンス最適化 |
| `security-engineer` | セキュリティ脆弱性検出 |
| `quality-engineer` | テスト戦略・品質保証 |
| `refactoring-expert` | リファクタリング・技術的負債削減 |
| `devops-architect` | インフラ・デプロイ自動化 |
| `root-cause-analyst` | 根本原因分析 |
| `python-expert` | Python開発 |
| `learning-guide` | プログラミング教育 |
| `socratic-mentor` | ソクラテス式指導 |
| `business-panel-experts` | ビジネス戦略パネル |

## コマンド (`commands/`)

| カテゴリ | コマンド | 説明 |
|---------|---------|------|
| SuperClaude | `/sc:*` (27種) | analyze, build, design, implement, review, test 等 |
| Git | `/git:branch-name` | ブランチ名候補を生成 |
| Git | `/git:commit-message` | コミットメッセージ書式ルール |
| Git | `/git:pr` | PR作成 |
| Git | `/git:history` | コミット履歴をユーザー別に出力 |
| Git | `/git:farm-in:daily-report` | 複数リポの日報TSVデータ生成 |
| 計画 | `/create-plan` | 実装計画書を作成 |
| 計画 | `/start-plan` | 計画書に沿って実装を実行 |
| ユーティリティ | `/serena` | Serena MCP連携 |
| ユーティリティ | `/update-claude-md` | CLAUDE.md を最新状態に更新 |
| ユーティリティ | `/upgrade-claude` | Homebrew で Claude Code をアップグレード |

## 設定ファイル

| ファイル | 内容 |
|---------|------|
| `settings.json` | 権限設定（allow/deny）、通知フック、ステータスライン、言語設定 |
| `statusline-git.sh` | コンテキスト使用率、gitブランチ/差分、セッションコスト表示 |
| `mcp-templates.json` | MCPサーバーテンプレート |

## 注意事項

- 設定を変更する際はこのリポジトリの `claude/` 配下を編集すること（`~/.claude/` を直接編集しない）
- `.local`/`.private` 拡張子ファイルはgitignore対象（機密情報用）
- `sudo`, `rm`, `git push` 等は権限設定で明示的に禁止済み
