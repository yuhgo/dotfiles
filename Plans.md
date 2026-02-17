# Plans.md - タスク管理

> **プロジェクト**: dotfiles
> **最終更新**: 2026-02-17
> **更新者**: Claude Code
> **ブランチ**: `feat/nvim-codelens-references`

---

## 🔴 進行中のタスク

### Neovim コードレンズ（参照数表示）機能の実装

> **目的**: VS Codeのように、関数・メソッド・インターフェース・型定義の定義行の上に「参照数」を表示する
> **対象ファイル**: TypeScript (.ts) / TypeScript React (.tsx)
> **表示位置**: 定義行の上（VS Code風）
> **ブランチ**: `feat/nvim-codelens-references`（作成済み）
> **使用プラグイン**: [symbol-usage.nvim](https://github.com/Wansmer/symbol-usage.nvim)

#### Phase 1: symbol-usage.nvim の導入と基本設定 ★必須

- [x] T501: symbol-usage.nvim プラグイン設定ファイルの作成 `cc:完了`
- [x] T502: 表示フォーマットのカスタマイズ `cc:完了`

#### Phase 2: 動作確認とチューニング ★推奨

- [x] T503: TypeScript/TSXファイルでの動作確認 `cc:完了`
- [x] T504: パフォーマンスチューニング `cc:完了`

#### Phase 3: 仕上げ ★任意

- [x] T505: トグルキーマップの追加 `cc:完了`
- [ ] T506: コミットとPR作成 `cc:WIP`
