# Ghosttyタブ移動ショートカット追加計画

## 概要
Ghosttyの設定にタブ移動のキーバインドを追加する

## 追加するショートカット
| キー | アクション | 説明 |
|------|-----------|------|
| `cmd+h` | `previous_tab` | 前のタブへ移動 |
| `cmd+l` | `next_tab` | 次のタブへ移動 |

## 変更対象ファイル
- `/Users/yamamotoyugo/ghq/github.com/yuhgo/dotfiles/ghostty/config`

## 変更内容
55行目（ペイン間移動の設定の後）に以下を追加：

```
# タブ間移動
keybind = cmd+h=previous_tab
keybind = cmd+l=next_tab
```

## 確認方法
1. Ghosttyを再起動（または設定を再読み込み）
2. 複数のタブを開く（Cmd+Tなど）
3. Cmd+l で次のタブ、Cmd+h で前のタブに移動できることを確認
