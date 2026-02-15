---
name: lighthouse
description: 指定URLに対してLighthouse（Google製パフォーマンス計測ツール）を実行し、結果を分析・レポートする。Webサイトのパフォーマンス・アクセシビリティ・SEOなどの改善に活用する。
allowed-tools: Bash, Read, AskUserQuestion
---

# Lighthouse パフォーマンス計測スキル

指定されたURLに対してLighthouseを実行し、スコアの確認と改善提案を行う。
全てのオプションはAskUserQuestionを使ってユーザーに確認する。

## 実行フロー

### Step 1: 計測対象URLの確認
- AskUserQuestionで「計測するURLを入力してください」と質問する
  - 選択肢:
    - 「localhost（開発環境）」: `http://localhost:3000` を使用
    - 「localhost（カスタムポート）」: ポート番号をOtherで入力してもらう
  - ユーザーは「Other」で任意のURLを入力可能
- 引数でURLが既に指定されている場合はこのステップをスキップする
- URLが `http://` または `https://` で始まっていない場合は `https://` を付与する

### Step 2: 計測カテゴリの選択
- AskUserQuestionで「計測するカテゴリを選択してください」と質問する（multiSelect: true）
  - 選択肢:
    - 「全カテゴリ（推奨）」: Performance, Accessibility, Best Practices, SEO を全て計測
    - 「Performance のみ」: パフォーマンスのみ計測
    - 「Accessibility のみ」: アクセシビリティのみ計測
    - 「SEO のみ」: SEO のみ計測

### Step 3: デバイスの選択
- AskUserQuestionで「デバイスを選択してください」と質問する
  - 選択肢:
    - 「Mobile（推奨）」: モバイルエミュレーション（Lighthouseデフォルト）
    - 「Desktop」: デスクトップ設定で計測
    - 「両方」: モバイルとデスクトップ両方で計測

### Step 4: Chrome起動モードの選択
- AskUserQuestionで「Chromeの起動モードを選択してください」と質問する
  - 選択肢:
    - 「ヘッドレス（推奨）」: バックグラウンドで実行。ブラウザウィンドウは表示されない
    - 「通常モード」: Chromeウィンドウを表示して実行。計測の様子が見える
  - 「ヘッドレス」の場合: `--chrome-flags="--headless --no-sandbox"` を付与
  - 「通常モード」の場合: `--chrome-flags` を付与しない（デフォルトのChromeが開く）

### Step 5: Lighthouseの実行
- `npx lighthouse` コマンドで計測を実行する
- 出力形式は `--output=json` を使用し、結果ファイルを `/tmp/lighthouse-report-{timestamp}.json` に保存する
- HTML レポートも `--output=html` で同時に生成し `/tmp/lighthouse-report-{timestamp}.html` に保存する
- タイムアウトは 300秒（5分）に設定する

```bash
# ヘッドレス + モバイル（デフォルト）
npx lighthouse "{{URL}}" \
  --output=json --output=html \
  --output-path="/tmp/lighthouse-report-$(date +%Y%m%d-%H%M%S)" \
  --chrome-flags="--headless --no-sandbox" \
  --only-categories={{カテゴリ}}

# ヘッドレス + デスクトップ
npx lighthouse "{{URL}}" \
  --output=json --output=html \
  --output-path="/tmp/lighthouse-report-$(date +%Y%m%d-%H%M%S)" \
  --chrome-flags="--headless --no-sandbox" \
  --preset=desktop \
  --only-categories={{カテゴリ}}

# 通常モード + モバイル
npx lighthouse "{{URL}}" \
  --output=json --output=html \
  --output-path="/tmp/lighthouse-report-$(date +%Y%m%d-%H%M%S)" \
  --only-categories={{カテゴリ}}

# 通常モード + デスクトップ
npx lighthouse "{{URL}}" \
  --output=json --output=html \
  --output-path="/tmp/lighthouse-report-$(date +%Y%m%d-%H%M%S)" \
  --preset=desktop \
  --only-categories={{カテゴリ}}
```

#### カテゴリのマッピング
- 全カテゴリ: `performance,accessibility,best-practices,seo`
- Performance のみ: `performance`
- Accessibility のみ: `accessibility`
- SEO のみ: `seo`

### Step 6: 結果の解析とレポート
- JSON結果ファイルを Read で読み込み、以下の形式でレポートする

#### レポートフォーマット

```
## Lighthouse 計測結果

**URL**: {{URL}}
**デバイス**: {{Mobile / Desktop}}
**Chromeモード**: {{ヘッドレス / 通常}}
**計測日時**: {{YYYY-MM-DD HH:MM}}

### スコア一覧

| カテゴリ | スコア | 評価 |
|---------|--------|------|
| Performance | {{0-100}} | {{色アイコン}} |
| Accessibility | {{0-100}} | {{色アイコン}} |
| Best Practices | {{0-100}} | {{色アイコン}} |
| SEO | {{0-100}} | {{色アイコン}} |

### 主な指標（Performance）

| 指標 | 値 | 評価 |
|------|-----|------|
| First Contentful Paint (FCP) | {{値}} | {{色アイコン}} |
| Largest Contentful Paint (LCP) | {{値}} | {{色アイコン}} |
| Total Blocking Time (TBT) | {{値}} | {{色アイコン}} |
| Cumulative Layout Shift (CLS) | {{値}} | {{色アイコン}} |
| Speed Index | {{値}} | {{色アイコン}} |

### 改善が必要な項目（上位5件）

1. **{{項目名}}** - {{説明}} (推定改善: {{値}})
2. ...

### HTMLレポート
ファイルパス: `/tmp/lighthouse-report-{{timestamp}}.html`
ブラウザで開く: `open /tmp/lighthouse-report-{{timestamp}}.html`
```

#### スコア評価の基準
- 90-100: 良好（緑）
- 50-89: 改善の余地あり（黄）
- 0-49: 要改善（赤）

### Step 7: HTMLレポートを開くか確認
- AskUserQuestionで「HTMLレポートをブラウザで開きますか？」と質問する
  - 選択肢:
    - 「開く」: `open /tmp/lighthouse-report-{{timestamp}}.html` を実行
    - 「開かない」: そのまま終了

## 注意事項
- Lighthouse はChromeを使用するため、Chrome/Chromium がインストールされている必要がある
- 計測結果はネットワーク状況やマシンの負荷により変動する
- 認証が必要なページは計測できない（ログインが必要な場合はその旨をユーザーに伝える）
