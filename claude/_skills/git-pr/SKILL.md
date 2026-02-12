---
name: git-pr
description: Pull Requestを作成する
allowed-tools: Bash, AskUserQuestion
---

# Pull Request 作成スキル

## 基本方針
- このスキルを実行したら「Create Pull Request!」と叫ぶ。

## 作成手順

### Step 1: 関連Issueの確認
- AskUserQuestionで「PRに紐づけるIssueはありますか？」と質問する
  - 選択肢: 「あり」「なし」
- 「あり」の場合:
  - AskUserQuestionで「Issueの表示ラベルを入力してください（例: #123 ログイン機能の実装）」と質問する
  - AskUserQuestionで「IssueのURLを入力してください」と質問する
- 「なし」の場合:
  - PRテンプレートの関連Issueセクションに「関連Issueなし」と記載する

### Step 2: マージ先ブランチの確認
- AskUserQuestionで「マージ先ブランチを選択してください」と質問する
  - 選択肢: 「main（デフォルト）」「develop」
  - ユーザーは「Other」で任意のブランチ名を入力可能

### Step 3: ドラフト or 正式PRの確認
- AskUserQuestionで「PRの種類を選択してください」と質問する
  - 選択肢: 「Draft（下書き）」「正式なPR」

### Step 4: pr-content.md出力の確認
- AskUserQuestionで「PRの内容をpr-content.mdファイルに出力しますか？」と質問する
  - 選択肢: 「出力する（PRは作成しない）」「出力しない（PRを直接作成する）」
- 「出力する」の場合:
  - プロジェクトルートにpr-content.mdを作成し、PRタイトル・本文・gh pr createコマンドを記載する
  - PRは作成しない
- 「出力しない」の場合:
  - Step 5に進み、PRを直接作成する

### Step 5: 差分の確認
- `git diff origin/{{マージ先ブランチ}}...HEAD | cat` でマージ先ブランチとの差分を確認

### Pull Request 作成とブラウザでの表示
- 以下のコマンドでpull requestを作成し、自動的にブラウザで開く
- PRタイトルおよびPRテンプレートはマージ先との差分をもとに適切な内容にする
- Step 3で「Draft」を選択した場合は`--draft`オプションを付与する
- `$'...'`構文を使用して改行文字を正しく解釈させる

```bash
# Draftの場合
git push origin HEAD && \
gh pr create --draft --title "{{PRタイトル}}" --body $'{{PRテンプレートを1行に変換}}' && \
gh pr view --web

# 正式なPRの場合
git push origin HEAD && \
gh pr create --title "{{PRタイトル}}" --body $'{{PRテンプレートを1行に変換}}' && \
gh pr view --web
```

### PRテンプレート

```
## 概要
{{概要}}

### 関連 Issue / ドキュメント
- {{Issueのリンク}}
※ 関連Issueが存在しない場合は、その理由を記載

### 変更内容
- {{変更内容}}

## レビュアーに特に見て欲しいところ
- {{レビュアーに特に見て欲しいところ}}

## 影響範囲
- {{影響範囲}}

## スクリーンショット
- {{スクリーンショット}}

## 動作確認手順
{{動作確認手順}}
```

#### 必須セクション
- 概要
- 関連Issue（存在しない場合はその理由を記載）
- 変更内容

#### オプションセクション
- レビュアーに特に見て欲しいところ
- 影響範囲
- スクリーンショット
- 動作確認手順
