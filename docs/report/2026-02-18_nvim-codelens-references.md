# Neovim コードレンズ（参照数表示）機能 セッションレポート

> **日付**: 2026-02-18
> **ブランチ**: `feat/nvim-codelens-references`
> **ステータス**: 未完了（表示されない問題が未解決）

---

## 目的

VS Codeのコードレンズ機能をNeovimで再現する。
TypeScript (.ts) / TypeScript React (.tsx) ファイルで、関数・メソッド・インターフェース・型定義の定義行の上に「参照数」を表示する。

---

## プラグイン選定

| 候補 | 評価 | 備考 |
|------|------|------|
| **symbol-usage.nvim** (採用) | ◎ | `textDocument/references` ベースで ts_ls と動作。表示カスタマイズが柔軟 |
| lsp-lens.nvim | ○ | 似た機能だがメンテナンス頻度が低め |
| vim.lsp.codelens（ビルトイン） | △ | ts_ls の codeLens サポートが限定的 |

**選定理由**: symbol-usage.nvim は `textDocument/codeLens` をサポートしない LSP サーバーでも動作する。`textDocument/references` と `textDocument/documentSymbol` を使って参照数を取得するため、ts_ls でも確実に動く設計。

---

## 実装内容

### 作成したファイル

#### `nvim/lua/plugins/symbol-usage.lua`

```lua
return {
  {
    "Wansmer/symbol-usage.nvim",
    event = "BufReadPre",
    opts = {
      vt_position = "above",
    },
    keys = {
      { "<leader>uR", function() require("symbol-usage").toggle_globally() end, desc = "Toggle Reference Count" },
    },
  },
}
```

**注意**: 現在はデバッグのため最小構成にしている。元々の設定には以下が含まれていた：
- `kinds` で対象シンボル種別を制限（Function, Method, Interface, TypeParameter, Class）
- `disable.cond` で TypeScript/TSX のみに絞る
- `text_format` でカスタム表示（`󰌹 N references` 形式）
- `request_pending_text = false` でちらつき防止
- `references`, `definition`, `implementation` の有効/無効設定

#### `tmp/codelens-test/` （検証用データ）

| ファイル | 内容 |
|---------|------|
| types.ts | Interface, Type, Class, 関数の定義（参照元） |
| service.ts | types.ts の型・クラス・関数を参照 |
| App.tsx | TSX でコンポーネント定義 + types.ts を参照 |
| tsconfig.json | TypeScript プロジェクト設定 |

---

## 発生した問題と調査結果

### 問題: 参照数が表示されない

#### 調査 1: プラグインの認識状態

```
symbol-usage.nvim | loaded: false | dir: ~/.local/share/nvim/lazy/symbol-usage.nvim
```
- lazy.nvim に認識されている
- 遅延ロード状態（イベント待ち）

#### 調査 2: TypeScript ファイルでの状態

```
require ok: true
filetype: typescript
clients: 0  (ヘッドレスモードではLSPが自動起動しない)
```

#### 調査 3: 手動LSP起動での動作

手動で `ts_ls` を起動した場合：
```
active: true
buffers: { 1 }
workers: 1
```
- プラグインはアクティブ
- ワーカーが1つ起動

#### 調査 4: extmarks（virtual text）の状態

```
symbol-usage extmarks: 0
virt_line at row 42: { "loading...", "SymbolUsageText" }
virt_line at row 46: { "loading...", "SymbolUsageText" }
virt_line at row 50: { "loading...", "SymbolUsageText" }
...（他の行も同様）
```

**全行が "loading..." のまま** — 15秒待っても解決しない。

#### 調査 5: キーマップの衝突

- `<leader>cl` は LazyVim のデフォルトで「Lsp Info」に使われていた → `<leader>uR` に変更
- `<leader>uR` はヘッドレスモードで正しく登録されている
- ただし、ユーザー報告では `<Space>u` メニューに `R` が表示されない

---

## 未解決の問題

### 1. LSP レスポンスが返らない

symbol-usage.nvim のワーカーが LSP に `textDocument/references` リクエストを送信しているが、レスポンスが返ってこない（"loading..." のまま）。

**仮説**:
- ヘッドレスモードでの非同期処理の問題（通常Neovimでは異なる可能性）
- `ts_ls` の `root_dir` が `~`（ホームディレクトリ）になっていて、プロジェクトスコープが広すぎる
- `tmp/codelens-test/` に `node_modules` がなく、TypeScript のモジュール解決が失敗している

### 2. which-key に `<leader>uR` が表示されない

lazy.nvim の `keys` で定義したキーマップがプロキシ登録されているが、which-key のメニューに表示されない。

**仮説**:
- LazyVim の which-key 設定で `<leader>u` グループの表示がフィルタリングされている
- プラグインがまだロードされていない状態でのプロキシキーマップが which-key に認識されない

---

## 次のステップ（推奨）

### 優先度: 高

1. **通常の Neovim で動作確認**
   - `nvim tmp/codelens-test/types.ts` を開く
   - `:Lazy load symbol-usage.nvim` で手動ロード
   - `:lua require('symbol-usage').refresh()` でリフレッシュ
   - `:messages` でエラーを確認

2. **ログ有効化で原因特定**
   ```lua
   opts = {
     vt_position = "above",
     log = { enabled = true },
   }
   ```
   ログは `:messages` または LSP ログファイルに出力される

3. **ts_ls の root_dir 問題の調査**
   - `:LspInfo` で `Root directory` が適切か確認
   - `tmp/codelens-test/` に `package.json` を追加して root_dir を明示的に設定

### 優先度: 中

4. **node_modules の追加**
   ```bash
   cd tmp/codelens-test && npm init -y && npm install typescript @types/react
   ```

5. **別のプラグイン（lsp-lens.nvim）での検証**
   - symbol-usage.nvim 固有の問題か、LSP 側の問題かを切り分ける

### 優先度: 低

6. **元の詳細設定を復元**
   - 最小構成で動作確認できた後、`kinds`, `disable.cond`, `text_format` を1つずつ戻す

---

## コミット履歴

| コミット | 内容 |
|---------|------|
| `9333a11` | feat: symbol-usage.nvimでTS/TSXファイルにVS Code風の参照数表示を追加 |

---

## 関連ファイル

- `nvim/lua/plugins/symbol-usage.lua` — プラグイン設定
- `nvim/lua/plugins/lsp.lua` — LSP サーバー設定（ts_ls）
- `nvim/lua/plugins/lspsaga.lua` — LSPSaga 設定
- `nvim/lua/config/keymaps.lua` — カスタムキーマップ
- `tmp/codelens-test/` — 検証用データ
- `Plans.md` — タスク管理（T501-T506）
