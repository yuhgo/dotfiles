---
name: inkdrop:diary-summarize
description: Inkdropの日記ノートを読み取り、原文を保持しつつわかりやすくまとめる
---

## 概要

Inkdropのノートを読み取り、原文を`<details><summary>`タグで折りたたみ可能な形で保持しつつ、わかりやすくまとめた内容を冒頭に追加する。

## 引数

`$ARGUMENTS`: noteのtitleまたはnoteId
- `note:`で始まる場合 → noteIdとして直接取得
- それ以外 → titleとして検索

## 実行フロー

1. **引数の判定**
   - `$ARGUMENTS`が`note:`で始まるかどうかを確認

2. **ノート取得**
   - noteIdの場合: `mcp__inkdrop__read-note`で直接取得
   - titleの場合: `mcp__inkdrop__search-notes`で検索 → `mcp__inkdrop__read-note`で全文取得

3. **内容の分析とまとめ作成**
   - ノートの内容を分析し、カテゴリ別に整理
   - 重要なポイントを箇条書きでまとめる
   - 専門用語やキーワードは太字でハイライト

4. **ノート更新**
   - 冒頭にまとめを追加
   - 区切り線(`---`)を挿入
   - 原文を`<details><summary>原文</summary>`タグで保持
   - `mcp__inkdrop__update-note`で更新

## 出力形式

```markdown
# [タイトル]のまとめ

## [カテゴリ1]
- ポイント1
- **重要キーワード**: 説明

## [カテゴリ2]
- ポイント1
- ポイント2

---

<details>
<summary>原文</summary>

[原文内容をそのまま保持]

</details>
```

## 使用例

```bash
# タイトルで指定
/inkdrop:diary-summarize 2026-01-01

# noteIdで指定
/inkdrop:diary-summarize note:fQMhCzw7
```

## 注意事項

- 原文は一切変更せず、そのまま保持する
- まとめは内容に応じて適切なカテゴリに分類する
- 既に`<details>`タグでまとめ済みの場合は、既存のまとめを更新する
