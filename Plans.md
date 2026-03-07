# Plans.md - タスク管理

> **プロジェクト**: dotfiles
> **最終更新**: 2026-03-01
> **更新者**: Claude Code

---

## 🔴 進行中のタスク

### claude-mem → harness-mem 移行

> **目的**: claude-mem（MCP記憶プラグイン）から harness-mem に安全に移行する
> **手順書**: 3ステップ段階的移行（import → verify → cutover）
> **claude-mem DB**: `~/.claude-mem/claude-mem.db`（約22MB）
> **前提ツール**: bun, node, curl, jq, rg（全て確認済み）

#### Phase 1: harness-mem のインストールとセットアップ ★必須

- [x] T601: harness-mem のグローバルインストール `cc:完了`
  - `npm install -g @chachamaru127/harness-mem`
  - インストール後バージョン確認
- [x] T602: harness-mem setup の実行 `cc:完了` depends:T601
  - `harness-mem setup --platform claude`
  - MCP設定の確認（`~/.claude.json` に harness エントリが追加されること）

#### Phase 2: データインポートと検証 ★必須

- [x] T603: ドライランでインポート内容を確認 `cc:完了` depends:T602
  - `harness-mem import-claude-mem --source ~/.claude-mem/claude-mem.db --dry-run`
  - 取り込み対象のレコード数・内容を確認
- [x] T604: 本番インポート実行 `cc:完了` depends:T603
  - 2,629件インポート成功（重複0, 失敗0）
  - **job_id**: `import_00mm1xggcf8290eb264dd118fa`
- [x] T605: インポートデータの検証 `cc:完了` depends:T604
  - `harness-mem verify-import --job <job_id>`
  - ステータスが `completed` であること確認

#### Phase 3: カットオーバーと動作確認 ★必須

- [x] T606: claude-mem の停止と harness-mem への完全移行 `cc:完了` depends:T605
  - settings.json バックアップ: `~/.claude/settings.json.pre-harness-cutover.1772017523`
- [x] T607: doctor コマンドで健全性チェック `cc:完了` depends:T606
  - Daemon: OK, MCP wiring: OK, Result: healthy
- [x] T608: 動作確認 `cc:完了` depends:T607
  - Daemon health: OK, Mem UI: 起動中 (http://127.0.0.1:37901)
  - MCP切替は次回セッション起動時に自動反映（現セッションはclaude-mem接続中のため）

---

## 🟢 完了タスク

### 確定申告2025年分プロジェクト初期化（MK急便）(2026-03-01)

- [x] T701: tax-return-mk-kyubin プロジェクトの作成 `cc:完了`
  - ~/ghq/github.com/yuhgo/tax-return-mk-kyubin にローカルプロジェクトを生成
  - README.md, .gitignore, .env.example, data/ receipts/ notes/ を作成
  - git init + 初期コミット完了（.env はgitignore済み）

---

## 📦 アーカイブ

### Neovim コードレンズ（参照数表示）機能の実装 (2026-02-17)

- [x] T501〜T505: symbol-usage.nvim 導入・設定・チューニング完了 `cc:完了`
- [ ] T506: コミットとPR作成 `cc:WIP`
