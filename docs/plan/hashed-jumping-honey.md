# zshrc dotfiles管理 & claudeコマンド変更

## Context

現在の `.zshrc` はdotfilesリポジトリで管理されていない。
また `claude` コマンドがラッパー関数で `-dsp` オプションを `--dangerously-skip-permissions` に変換する仕組みだが、以下の変更が必要:

1. `cc` エイリアスではなく `claude` コマンドで起動するようにする（現状維持）
2. デフォルトで `--dangerously-skip-permissions` を付ける
3. スキップしたくない場合に外すオプションを用意する
4. `.zshrc` をdotfilesリポジトリで管理する

## 変更内容

### 1. `zsh/.zshrc` を作成

`~/.zshrc` の内容をそのまま `zsh/.zshrc` に配置する。

### 2. claude関数を変更

**変更前 (L27-40):**
```zsh
# claude コマンドのラッパー関数
function claude() {
  local args=()
  for arg in "$@"; do
    if [[ "$arg" == "-dsp" ]]; then
      args+=("--dangerously-skip-permissions")
    else
      args+=("$arg")
    fi
  done
  command claude "${args[@]}"
}
alias cc='claude'
```

**変更後:**
```zsh
# claude コマンドのラッパー関数
# デフォルトで --dangerously-skip-permissions を付与
# --safe オプションで無効化可能
function claude() {
  local skip_permissions=true
  local args=()
  for arg in "$@"; do
    if [[ "$arg" == "--safe" ]]; then
      skip_permissions=false
    else
      args+=("$arg")
    fi
  done
  if $skip_permissions; then
    command claude --dangerously-skip-permissions "${args[@]}"
  else
    command claude "${args[@]}"
  fi
}
```

- `cc` エイリアスを削除（`claude` で直接起動）
- `claude` → デフォルトで `--dangerously-skip-permissions` 付き
- `claude --safe` → パーミッションスキップなしで起動

### 3. `.gitignore` に追加不要

環境変数は `.zshrc` に含まれていないため、そのままコミット可能。

### 4. READMEにセットアップ手順を追加（既存のREADME.mdに追記）

```
### Zsh
ln -s $(pwd)/zsh/.zshrc ~/.zshrc
```

## 対象ファイル

| ファイル | 操作 |
|---------|------|
| `zsh/.zshrc` | 新規作成（~/.zshrcの内容をベースに変更） |
| `README.md` | セットアップ手順追記 |

## 検証方法

1. `zsh/.zshrc` を作成後、`~/.zshrc` をバックアップして `ln -s` でリンク
2. 新しいターミナルで `claude` → `--dangerously-skip-permissions` 付きで起動することを確認
3. `claude --safe` → パーミッション確認ありで起動することを確認
4. 既存のエイリアス（`lg`, `vi`, `nv` 等）が動作することを確認
