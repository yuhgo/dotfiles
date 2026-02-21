---
name: next-lighthouse-loop
description: Next.jsプロジェクトに対してLighthouseベースのパフォーマンス改善ループを実行する。計測→分析→修正→再計測を対話的に反復し、スコアを改善する。
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Task
---

# Next.js Lighthouse パフォーマンス改善ループ

Next.jsプロジェクトに対してLighthouse計測→分析→修正→再計測のサイクルを回し、
対話的にパフォーマンスを改善する。各改善提案はユーザーの承認を得てから適用する。

## 前提条件

- Next.js（App Router）プロジェクトであること
- Chrome/Chromium がインストール済みであること
- `npx lighthouse` が実行可能であること

## 全体フロー

```
Phase 1: ベースライン計測
  ↓
Phase 2: コードベース分析（Next.js特有のアンチパターン検出）
  ↓
Phase 3: 改善ループ（提案→承認→適用→再計測 を繰り返し）
  ↓
Phase 4: レポート生成
```

---

## Phase 1: ベースライン計測

### Step 1.1: 計測対象URLの確認
- AskUserQuestionで「計測するURLを入力してください」と質問する
  - 選択肢:
    - 「localhost:3000（開発環境）」
    - 「localhost（カスタムポート）」
  - ユーザーは「Other」で任意のURLを入力可能
- 引数でURLが既に指定されている場合はこのステップをスキップする

### Step 1.2: production buildの確認
- localhostの場合、AskUserQuestionで確認する:
  - 「production buildで計測しますか？（推奨：dev serverはパフォーマンスが大幅に低下します）」
  - 選択肢: 「はい（ビルド＆起動する）」「いいえ（現在のサーバーをそのまま使う）」
- 「はい」の場合:
  1. プロジェクトのパッケージマネージャを検出する（bun.lockb → bun, pnpm-lock.yaml → pnpm, yarn.lock → yarn, それ以外 → npm）
  2. `{{pm}} run build && {{pm}} run start &` を実行
  3. サーバー起動を確認: `curl -s -o /dev/null -w "%{http_code}" {{URL}}` で200が返るまで最大30秒リトライ

### Step 1.3: MobileとDesktop両方のベースライン計測
- Mobile と Desktop の両方で計測する（固定、選択不要）
- Chrome はヘッドレスモードで実行する
- Task ツールでバックグラウンド実行し、並列計測してよい

```bash
# Mobile
npx lighthouse "{{URL}}" \
  --output=json --output=html \
  --output-path="/tmp/lh-loop-baseline-mobile-$(date +%Y%m%d-%H%M%S)" \
  --chrome-flags="--headless --no-sandbox" \
  --only-categories=performance

# Desktop
npx lighthouse "{{URL}}" \
  --output=json --output=html \
  --output-path="/tmp/lh-loop-baseline-desktop-$(date +%Y%m%d-%H%M%S)" \
  --chrome-flags="--headless --no-sandbox" \
  --preset=desktop \
  --only-categories=performance
```

- タイムアウトは 300秒（5分）に設定する

### Step 1.4: ベースライン結果の表示
- JSON結果を Read で読み込み、以下をパースして表示する:

```
## ベースライン計測結果

| Metric | Mobile | Desktop |
|--------|--------|---------|
| **Performance Score** | {{score}} | {{score}} |
| FCP | {{値}} | {{値}} |
| **LCP** | **{{値}}** | **{{値}}** |
| TBT | {{値}} | {{値}} |
| CLS | {{値}} | {{値}} |
| Speed Index | {{値}} | {{値}} |

### LCP要素の詳細

| 項目 | 値 |
|------|-----|
| LCP Element | {{要素のセレクタ/テキスト}} |
| Load Delay | {{値}} |
| Load Time | {{値}} |
| Render Delay | {{値}} |
```

#### LCP詳細のJSON取得パス
- LCP Element: `audits['largest-contentful-paint-element'].details.items[0]`
- LCP Breakdown: `audits['lcp-lazy-loaded']` および `audits['largest-contentful-paint'].displayValue`
- Render Blocking: `audits['render-blocking-resources'].details.items`
- Unused CSS: `audits['unused-css-rules'].details`
- Unused JS: `audits['unused-javascript'].details`

### Step 1.5: 改善目標の確認
- AskUserQuestionで確認する:
  - 「目標スコアを設定しますか？」
  - 選択肢:
    - 「Mobile 90以上」
    - 「Mobile 80以上」
    - 「できる限り改善」
  - ユーザーは「Other」で任意の目標を入力可能

---

## Phase 2: コードベース分析（Next.js特有アンチパターン検出）

以下の分析を自動で実行し、検出した問題を優先度付きで一覧表示する。
コードの変更はしない（分析のみ）。

### Check 2.1: フォント分析 [High Impact]

**チェック対象**: ルートレイアウトファイル（Glob で `**/layout.tsx` を検索して特定）

```
検出パターン:
- next/font/google のインポートで複数ウェイト（3つ以上）が指定されている
  → 各ウェイト×unicode-rangeサブセット でフォントファイルが爆発する
  → 修正: 使用する最小限のウェイトに絞る（1-2ウェイトが理想）
- display: 'swap' が設定されていない
  → レンダリングがフォントロード完了まで遅延する（FOIT）
  → 修正: display: 'swap' を追加
- preload: false が設定されていない（装飾用フォント等）
  → 不要なフォントがrender-blockingになる
  → 修正: 非クリティカルフォントに preload: false を追加
```

**推定インパクト計算**:
- ウェイト数 >= 3 → High（フォントファイル爆発の可能性大）
- ウェイト数 2 → Medium
- ウェイト数 1 + display:'swap' あり → 問題なし

### Check 2.2: LCP要素のレンダリングパス分析 [High Impact]

Phase 1で特定したLCP要素から逆算してコンポーネントを特定する。

```
手順:
1. LCP要素のテキストまたはセレクタで Grep 検索
2. 該当コンポーネントを Read で読み込む
3. 以下をチェック:
   - 'use client' ディレクティブの有無
   - Framer Motion / React Spring 等のJSアニメーションライブラリ使用
   - opacity: 0 の初期状態（JSで解除するパターン）
   - AnimatePresence / motion.div 等のラッパー
   - 動的import (next/dynamic) の使用
```

**検出パターン**:
- LCP要素がJSアニメーション（Framer Motion等）で opacity: 0 → 1 のトランジションを持つ
  → Lighthouseの4x CPU throttlingでアニメーション完了まで数十秒かかる
  → 修正: CSS animation に変換し、Server Componentに変換する
- LCP要素を含むコンポーネントに 'use client' がある
  → SSRされてもhydrationまでレンダリングが遅延する可能性
  → 修正: Server Componentに変換、またはクライアント部分を分離

### Check 2.3: ヒーロー画像の最適化 [Medium Impact]

```
手順:
1. LCPが画像の場合、該当のImage/imgコンポーネントを特定
2. 以下をチェック:
   - next/image を使用しているか（生の <img> ではないか）
   - priority prop または fetchPriority="high" が設定されているか
   - 画像がFramer Motionラッパー内にある場合、最初の描画で隠されていないか
```

### Check 2.4: Next.js画像設定の確認 [Medium Impact]

**チェック対象**: `next.config.mjs`（または `next.config.js` / `next.config.ts`）

```
検出パターン:
- images.formats に 'image/avif' が含まれていない
  → 修正: formats: ['image/avif', 'image/webp'] を追加
- images.deviceSizes / imageSizes が未設定
  → 修正: 適切なサイズを設定
- images.minimumCacheTTL が未設定または短い
  → 修正: 31536000（1年）を推奨
- experimental.optimizeCss が false または未設定
  → 修正: true に設定
```

### Check 2.5: クライアントコンポーネント分析 [Medium Impact]

```
手順:
1. Grep で 'use client' を含むファイルを一覧取得
2. ファーストビュー（above-fold）に含まれるコンポーネントを特定
3. 'use client' が本当に必要か（useState/useEffect/イベントハンドラ等を使用しているか）をチェック
```

### Check 2.6: Render-blocking リソースの確認 [Medium Impact]

Lighthouse JSON の `audits['render-blocking-resources']` から:
- render-blocking CSS/JS の一覧を表示
- 推定ブロック時間を表示

### Check 2.7: バンドルサイズ分析 [Low Impact]

```
検出パターン:
- バレルインポート（例: import { Button } from '@heroui/react'）
  → 修正: 個別パッケージからインポート（例: import { Button } from '@heroui/button'）
- 重いライブラリがクリティカルパスにある
  → 修正: dynamic import でコード分割
```

### 分析結果の表示

全チェック完了後、以下の形式で一覧表示する:

```
## コードベース分析結果

| # | 問題 | 影響度 | 推定改善 | ファイル |
|---|------|--------|----------|----------|
| 1 | フォント5ウェイト → 1ウェイトに削減 | 🔴 High | LCP -30〜60s (mobile) | layout.tsx |
| 2 | LCPテキストのFramer Motion → CSS化 | 🔴 High | LCP -10〜50s (mobile) | hero-section.tsx |
| 3 | フォント display:'swap' 追加 | 🟡 Medium | FCP -0.5s | layout.tsx |
| 4 | Hero画像 fetchPriority="high" | 🟡 Medium | LCP -0.5s | hero-carousel.tsx |
| 5 | Next.js image formats AVIF追加 | 🟡 Medium | 転送量削減 | next.config.mjs |
| 6 | バレルインポートの分割 | 🟢 Low | バンドル-50KB | 複数ファイル |

※ 影響度は過去の実績データに基づく推定
```

---

## Phase 3: 改善ループ（対話的）

分析結果を影響度 High → Medium → Low の順に処理する。
同一ファイルへの変更は可能な限りバッチ化する。

### Step 3.1: git状態の確認

変更を適用する前に、現在の状態がコミット済みであることを確認する。
未コミットの変更がある場合はユーザーに警告し、コミットまたはstashを促す。

```bash
git status --porcelain
```

### Step 3.2: 改善提案の提示

各問題について、以下の情報を提示する:

```
### 改善 #{{番号}}: {{問題の概要}}

**影響度**: 🔴 High / 🟡 Medium / 🟢 Low
**対象ファイル**: {{ファイルパス}}
**推定改善効果**: {{具体的な数値}}

**現在のコード**:
（該当箇所を Read で読み込み表示）

**提案する変更**:
（具体的な変更内容をコード付きで表示）

**変更理由**:
（なぜこの変更がパフォーマンスを改善するかの説明）
```

### Step 3.3: ユーザーの承認
- AskUserQuestionで「この改善を適用しますか？」と質問する
  - 選択肢:
    - 「適用する」
    - 「スキップする」
    - 「改善ループを終了する」
  - ユーザーは「Other」で変更内容の修正指示を入力可能

### Step 3.4: 変更の適用
- 「適用する」の場合: Edit / Write ツールで変更を適用する
- 「スキップする」の場合: スキップした改善として記録し、次の提案に進む
- 「改善ループを終了する」の場合: Phase 4に進む

### Step 3.5: バッチ再計測の判断

以下のいずれかの条件を満たしたら再計測する:
- High Impact の変更を1つ適用した直後
- Medium/Low Impact の変更を2-3個まとめて適用した後
- ユーザーが明示的に再計測を要求した場合

再計測手順:
1. localhostの場合: 既存のNext.jsプロセスを停止し、再ビルド＆起動する
2. サーバー起動を待機
3. Mobile + Desktop で Lighthouse を実行

```bash
# イテレーションN の計測
npx lighthouse "{{URL}}" \
  --output=json --output=html \
  --output-path="/tmp/lh-loop-iter{{N}}-mobile-$(date +%Y%m%d-%H%M%S)" \
  --chrome-flags="--headless --no-sandbox" \
  --only-categories=performance

npx lighthouse "{{URL}}" \
  --output=json --output=html \
  --output-path="/tmp/lh-loop-iter{{N}}-desktop-$(date +%Y%m%d-%H%M%S)" \
  --chrome-flags="--headless --no-sandbox" \
  --preset=desktop \
  --only-categories=performance
```

### Step 3.6: Before/After比較の表示

```
## イテレーション {{N}} 結果

### 適用した変更
- {{変更1の概要}}
- {{変更2の概要}}

### スコア推移

| Metric | Baseline | Iter {{N-1}} | Iter {{N}} | 変化 |
|--------|----------|--------------|------------|------|
| Performance (M) | {{値}} | {{値}} | {{値}} | {{+/-}} |
| Performance (D) | {{値}} | {{値}} | {{値}} | {{+/-}} |
| LCP (M) | {{値}} | {{値}} | {{値}} | {{+/-}} |
| LCP (D) | {{値}} | {{値}} | {{値}} | {{+/-}} |
| FCP (M) | {{値}} | {{値}} | {{値}} | {{+/-}} |
| TBT (M) | {{値}} | {{値}} | {{値}} | {{+/-}} |
| CLS (M) | {{値}} | {{値}} | {{値}} | {{+/-}} |
| Speed Index (M) | {{値}} | {{値}} | {{値}} | {{+/-}} |
```

### Step 3.7: 継続判断
- 目標スコアに達した場合: 「目標スコアに達しました！」と表示
- AskUserQuestionで「改善を続けますか？」と質問する
  - 選択肢:
    - 「次の改善に進む」
    - 「改善ループを終了してレポートを生成する」

---

## Phase 4: レポート生成

### Step 4.1: レポートファイルの出力先確認
- AskUserQuestionで「レポートの出力先を選択してください」と質問する
  - 選択肢:
    - 「docs/report/（プロジェクト内）」
    - 「/tmp/（一時ディレクトリ）」
  - ユーザーは「Other」で任意のパスを入力可能

### Step 4.2: レポート生成

以下の形式で Markdown レポートを Write で出力する:

```markdown
# Performance Optimization Report

## Overview

{{プロジェクト名}}のLighthouse Performanceスコア改善レポート。

**計測環境**: {{URL}}, Lighthouse CLI, headless Chrome
**実施日**: {{YYYY-MM-DD}}
**イテレーション数**: {{N}}

---

## Results Summary

### Before (Baseline)

| Metric | Mobile | Desktop |
|--------|--------|---------|
| **Performance** | {{score}} | {{score}} |
| FCP | {{値}} | {{値}} |
| **LCP** | **{{値}}** | **{{値}}** |
| TBT | {{値}} | {{値}} |
| CLS | {{値}} | {{値}} |
| Speed Index | {{値}} | {{値}} |

### After (Final)

| Metric | Mobile | Desktop |
|--------|--------|---------|
| **Performance** | **{{score}} ({{+/-}})** | **{{score}} ({{+/-}})** |
| FCP | {{値}} ({{+/-}}) | {{値}} ({{+/-}}) |
| **LCP** | **{{値}} ({{+/-}})** | **{{値}} ({{+/-}})** |
| TBT | {{値}} ({{+/-}}) | {{値}} ({{+/-}}) |
| CLS | {{値}} ({{+/-}}) | {{値}} ({{+/-}}) |
| Speed Index | {{値}} ({{+/-}}) | {{値}} ({{+/-}}) |

---

## Root Cause Analysis

（Phase 2で検出した主要な問題をまとめる）

---

## Changes Made

### {{N}}. {{変更タイトル}}

**File**: `{{ファイルパス}}`

- {{変更内容の説明}}

**Before**:
（変更前のコード）

**After**:
（変更後のコード）

---

## Skipped Improvements

| # | 提案 | 影響度 | スキップ理由 |
|---|------|--------|-------------|
| {{N}} | {{概要}} | {{影響度}} | ユーザー判断 |

---

## Iteration Log

| Iteration | Change | Mobile Perf | Mobile LCP | Desktop Perf | Desktop LCP |
|-----------|--------|-------------|------------|--------------|-------------|
| Baseline | (none) | {{値}} | {{値}} | {{値}} | {{値}} |
| Iter 1 | {{変更概要}} | {{値}} | {{値}} | {{値}} | {{値}} |

---

## Remaining Optimization Opportunities

| Category | Estimated Savings |
|----------|------------------|
| {{項目}} | {{推定削減量}} |

### Possible Next Steps

1. {{次のステップ1}}
2. {{次のステップ2}}
3. {{次のステップ3}}
```

### Step 4.3: HTMLレポートの確認
- AskUserQuestionで「最終計測のHTMLレポートをブラウザで開きますか？」と質問する
  - 選択肢: 「開く」「開かない」
- 「開く」の場合: `open {{最終計測のHTMLレポートパス}}` を実行

---

## Next.js パフォーマンス最適化ナレッジベース

実績データに基づく優先度付きパターン集。分析・提案時にこの知識を活用する。

### 優先度: High（最大の改善効果）

#### 1. フォントウェイト削減
- **問題**: next/font/google で複数ウェイトを指定するとフォントファイルが爆発する
- **実績**: 5ウェイト→1ウェイトで 244 files (7.5MB) → 6 files (127KB)、Performance +20ポイント
- **修正**: 実際に使用するウェイトのみに絞る（通常1-2ウェイトで十分）
- **検出**: layout.tsx の next/font インポートでウェイト配列のサイズを確認
- **注意**: フォントウェイト削減は見た目に影響する。適用前にユーザーに確認し、適用後に視覚的な確認を促す

#### 2. LCP要素のJSアニメーション排除
- **問題**: Framer Motion等で opacity:0→1 のアニメーションがLCP要素にあると、CPU throttling環境で数十秒の遅延
- **実績**: TextEffect(Framer Motion) → CSS animation で LCP 99.7s → 4.5s
- **修正**: CSS animation に変換 + Server Componentに変換
- **検出**: LCP要素を含むコンポーネントで motion / AnimatePresence / opacity の使用を確認
- **CSS animationの例**:
  ```css
  @keyframes hero-text-reveal {
    from { opacity: 0; transform: translateY(8px); }
    to { opacity: 1; transform: translateY(0); }
  }
  .hero-text-reveal {
    animation: hero-text-reveal 0.6s ease-out forwards;
    opacity: 0;
  }
  ```

#### 3. SSRファーストレンダリング
- **問題**: 'use client' コンポーネント内のLCP要素はhydration待ちでレンダリング遅延
- **修正**: LCPパス上のコンポーネントを Server Component に変換、またはクライアント部分を子コンポーネントに分離
- **検出**: above-fold コンポーネントの 'use client' 使用を確認

#### 4. フォント display:'swap' と preload:false
- **問題**: デフォルトでフォント読み込み完了までテキスト非表示（FOIT）
- **修正**: `display: 'swap'`（テキスト即表示）、装飾用フォントに `preload: false`
- **検出**: next/font 設定で display / preload オプションの有無を確認

### 優先度: Medium（中程度の改善効果）

#### 5. Next.js image optimization設定
- **修正**: `formats: ['image/avif', 'image/webp']`、適切な deviceSizes、`minimumCacheTTL: 31536000`
- **検出**: next.config の images 設定を確認

#### 6. Hero画像の優先ロード
- **修正**: `priority` prop または `fetchPriority="high"` を設定
- **検出**: ヒーローセクションの Image コンポーネントで priority の有無を確認

#### 7. experimental.optimizeCss
- **修正**: next.config に `experimental: { optimizeCss: true }` を追加
- **検出**: next.config の experimental 設定を確認

#### 8. コンポーネントレベルのコード分割
- **修正**: above-fold に不要な重いライブラリを next/dynamic で遅延ロード
- **検出**: import文で大きなライブラリ（地図、チャート等）がトップレベルにあるか確認

### 優先度: Low（小規模の改善効果）

#### 9. 未使用CSS/JS削減
- **修正**: バレルインポートを個別インポートに変更、tree-shaking改善
- **検出**: Lighthouse の unused-css-rules / unused-javascript の値を確認

#### 10. Critical CSS インライニング
- **修正**: above-fold の CSS をインライン化
- **検出**: render-blocking CSS のサイズを確認

#### 11. 個別パッケージインポート
- **修正**: `@heroui/react` → `@heroui/button` 等の個別パッケージ
- **検出**: node_modules のバレルエクスポートの使用を確認

---

## 注意事項

- Lighthouse のスコアは計測ごとに変動する（特にMobileは変動幅が大きい）。5ポイント以上の変化のみ有意な改善とみなす
- production build での計測を強く推奨する。dev server ではHMR等のオーバーヘッドでスコアが著しく低下する
- localhost計測はネットワーク遅延を含まないため、実際のユーザー体験とは異なる場合がある
- 変更適用前に必ず git の状態を確認し、ロールバック可能な状態にする
- フォントウェイト削減は見た目に影響する可能性がある。適用前に視覚的な確認を促す
