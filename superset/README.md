# Superset 設定管理

[Superset](https://docs.superset.sh/) のうち、**ファイルベースで管理できる範囲** だけをここに集約する。
残りは Superset アプリ内の **Settings 画面** で設定する必要があり、`Settings Sync`（ログイン同期）で端末間共有する。

## 設定ファイルで管理できる範囲

| カテゴリ | ファイル | 配置 | Git 管理 | 備考 |
|---------|---------|------|---------|------|
| **テーマ** | `theme-*.json` | 本ディレクトリに保管 → Settings → Appearance → Theme → **Import Theme** で取り込み | ✅ | Base File を DL して編集、UI/ターミナル色をオーバーライド |
| **キーボードショートカット** | `keybindings.json`（任意名） | Settings → Keyboard Shortcuts → **Export/Import** | ✅ | Export したものをここに置けばよい |
| **プロジェクトスクリプト** | `.superset/config.json` | **各プロジェクトのリポジトリ直下** に配置（dotfiles ではない） | ✅ | `setup` / `teardown` / `run` スクリプトのみ |
| **プロジェクトスクリプト上書き** | `.superset/config.local.json` | 各プロジェクト直下 | ❌ (gitignore) | チーム共有ファイルを個人で上書き |
| **ユーザーオーバーライド** | `~/.superset/projects/<project-id>/config.json` | ホーム配下 | ❌ (任意で dotfiles に symlink) | project-id は Settings → Projects で確認 |
| **MCP/外部ツール連携** | `.mcp.json`, `.amp/settings.json` | プロジェクト直下 | プロジェクト判断 | 手動編集 |
| **環境変数** | `.zshrc` など、または Settings → Env | シェル設定 or アプリ内 | ✅ (zsh 側) | ワークスペース単位は UI 側 |

### `.superset/config.json` の優先順位（マージされない／最初にヒットしたものが全採用）

1. `~/.superset/projects/<project-id>/config.json`（ユーザー個別オーバーライド）
2. `<worktree>/.superset/config.json`（worktree 固有）
3. `<repo>/.superset/config.json`（リポジトリ標準、チーム共有）

### 例: プロジェクトの `.superset/config.json`

```json
{
  "setup": ["bun install", "cp \"$SUPERSET_ROOT_PATH/.env\" .env"],
  "teardown": ["docker-compose down"],
  "run": ["./.superset/run.sh"]
}
```

## ファイルで管理できない範囲（Settings 画面のみ）

以下はファイルで一括管理する手段がなく、**Settings Sync に委ねる**：

- Appearance（テーマ切替・Marketplace 取得）
- Terminal → Manage Presets（ターミナルプリセット）
- Agents（各 AI エージェントの挙動）
- Notifications（通知音・カスタムリングトーン）
- Env（ワークスペース単位の環境変数、シェル側で管理する方針なら不要）
- プロジェクト設定（project-id 表示など）

> `superset_config.py` のような一括設定ファイルや、全設定を操作する CLI は **存在しない**（2026-04 時点）。

## このディレクトリの内容

- `theme-kanagawa.json` … Kanagawa Wave テーマ（Neovim `kanagawa.nvim` / Ghostty 設定と配色を統一）

## 運用フロー

1. **テーマ更新**: Superset で Download Base File → 本ディレクトリで編集 → Import Theme で再取り込み
2. **ショートカット更新**: Superset で Export → 本ディレクトリにコミット → 別端末で Import
3. **プロジェクト固有スクリプト**: dotfiles ではなく各プロジェクトリポジトリで管理
