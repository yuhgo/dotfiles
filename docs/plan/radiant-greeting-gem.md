# claude-mem の CLAUDE.md / AGENTS.md をグローバル gitignore で管理する

## Context

claude-mem プラグインが作業したディレクトリごとに `CLAUDE.md` を自動生成する。
サブディレクトリの CLAUDE.md が git status を汚染している。
AGENTS.md も同様にサブディレクトリに生成される可能性があるため、同じ対策をする。

**現状の問題：**
- グローバル gitignore に `CLAUDE.md` はあるが `AGENTS.md` はない
- dotfiles の `.gitignore` の `!CLAUDE.md` がサブディレクトリにもマッチして無視を上書きしている

## 変更内容

### 1. `~/.gitignore_global` に AGENTS.md を追加

```diff
 CLAUDE.md
+AGENTS.md
```

### 2. `.gitignore` を修正

```diff
 # claude関連
-!CLAUDE.md
+!/CLAUDE.md
+!/AGENTS.md
```

- `/` プレフィックスでルート直下のみ追跡対象にする
- サブディレクトリのものはグローバル gitignore で無視される

## 対象ファイル
- `~/.gitignore_global` (AGENTS.md 追加)
- `/Users/yamamotoyugo/ghq/github.com/yuhgo/dotfiles/.gitignore` (9行目を修正、AGENTS.md 追加)

## 検証
```bash
git check-ignore -v nvim/CLAUDE.md       # → グローバル gitignore で無視
git check-ignore -v CLAUDE.md            # → 無視されない（追跡対象）
git check-ignore -v some/dir/AGENTS.md   # → グローバル gitignore で無視
git check-ignore -v AGENTS.md            # → 無視されない（追跡対象）
git status                                # → サブディレクトリの CLAUDE.md が消える
```
