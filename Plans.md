# Plans.md - タスク管理

> **プロジェクト**: dotfiles
> **最終更新**: 2026-03-01
> **更新者**: Claude Code

---

## 🔴 進行中のタスク

### Bitwarden ボールト整理

> **目的**: 524件のアイテムを23カテゴリの新フォルダに再編し、命名統一・重複削除・不要データ整理を行う
> **詳細プラン**: `docs/plan/wobbly-noodling-piglet.md`
> **バックアップ**: `~/bw-backup-20260312.json`

#### Phase 1: バックアップと新フォルダ作成 ✅

- [x] T801: ボールトのJSONバックアップ `cc:完了`
  - `~/bw-backup-20260312.json` に保存済み
- [x] T802: 新フォルダ23個の作成 `cc:完了`
  - 仕事/5, 開発/3, 金融/4, 生活/7, エンタメ, 家族, Archive/2

#### Phase 2: アイテムのフォルダ振り分け ✅

- [x] T803: 旧フォルダのアイテムを新フォルダに移動 `cc:完了`
  - GD/*, Insight, 富士ソフト → Archive/仕事
  - ALOALO, Withたくちゃん, WordPress → Archive/プロジェクト
  - Agent Grow, Work → 仕事/フリーランス 等
- [x] T804: プライベートフォルダ140件の細分化 `cc:完了`
  - 銀行, カード, サブスク, ショッピング, 食事, インフラ, 健康, エンタメ等に振り分け
- [x] T805: 未分類229件のフォルダ振り分け `cc:完了`
  - farm in, ADiXi, Link, sic → 各仕事フォルダ
  - APIキー → 開発/API Keys, 開発ツール → 開発/開発ツール 等
  - 残り未分類: 6件（Happyhotel, ikea, jetbrains.com, Lifecard, MUSASI, ncobihori.co.jp）

#### Phase 3: 仕上げ ✅

- [x] T806: 残り6件の未分類アイテム振り分け `cc:完了`
  - Happyhotel→生活/交通・旅行, ikea→生活/ショッピング, jetbrains.com→開発/開発ツール, Lifecard→金融/カード, MUSASI→生活/その他, ncobihiro.co.jp→金融/銀行
  - 追加で9件（DMM, mrsgreenapple, oralb, unext.jp, あおやま, ニンテンドー, ホテルグレイスリー札幌x2, 快活クラブ）も振り分け
- [x] T807: 旧プライベートフォルダ残留1件の移動 `cc:完了`
  - Kuronekoyamato → 生活/ショッピング
- [x] T808: アイテム命名統一 `cc:完了`
  - 【】括弧10件 → サフィックス形式や括弧なしに統一
  - [farm in]プレフィックス4件 → フォルダ内なので外す
  - [メイン]/[仕事]プレフィックス4件 → サフィックスに統一
  - その他[]プレフィックス22件 → 整理
  - URL形式の名前20件 → サービス名に変更
  - 合計56件リネーム
- [x] T809: 旧フォルダの削除 `cc:完了`
  - 空フォルダ54個 + 壊れた`\u0010`フォルダ1個 = 55フォルダ削除
  - 78フォルダ → 23フォルダに整理
- [x] T810: 重複・不要アイテムの削除 `cc:完了`
  - localhost系6件 + ____[farm in]Google重複1件 = 7件削除
  - 残りの重複は異なるアカウント/コンテキストのため保持
- [x] T811: 最終検証と同期 `cc:完了`
  - 未分類: 0件 ✅
  - フォルダ数: 23（新構成通り）✅
  - 総アイテム数: 517件
  - `bw sync` サーバー同期完了 ✅

---

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
