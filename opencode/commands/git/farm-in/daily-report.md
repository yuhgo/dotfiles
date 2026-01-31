---
description: "複数リポジトリのGitコミット履歴から日報用TSVデータを生成し、スプレッドシートにコピペできる形式で出力"
---

## 概要

複数のGitリポジトリからコミット履歴を抽出し、日報（スプレッドシート）にコピペできるTSV形式で出力します。

# Git日報作成コマンド

このコマンドは、指定された複数のGitリポジトリから特定ユーザーのコミット履歴を取得し、日報形式（日付・開始時間・終了時間・作業内容）のTSVデータを生成します。

## 実行フロー

1. **パラメータ確認**: リポジトリパス、ユーザー名、期間の取得
2. **リポジトリ検証**: 各パスがGitリポジトリかどうか確認
3. **コミット履歴取得**: git logコマンドでユーザーのコミット履歴を抽出（Mergeコミット除外）
4. **作業時間推定**: タスク内容に応じた現実的な作業時間を推定
5. **定例会議追加**: 指定された曜日・日付に定例会議を追加
6. **TSV生成**: スプレッドシートにコピペ可能な形式で出力

## パラメータ

### 必須パラメータ
- **リポジトリパス（複数可）**: コミット履歴を取得したいGitリポジトリのパス
- **ユーザー名**: コミット履歴を取得したいGitユーザー名（複数指定可、OR検索）
- **対象年月**: 取得する年月（例: 2026-01）

### オプションパラメータ
- **リポジトリ略称**: 各リポジトリの日本語略称（例: delivery-article → 配達LP）
- **定例会議**: 追加する定例会議の情報（日付、開始時間、終了時間、名称）
- **出力ファイルパス**: TSVファイルの保存先（デフォルト: /tmp/excel_work/日報データ.tsv）

## ユーザーへの質問

コマンドを実行する前に必ず、以下の順序でユーザーに確認します。

### 質問1: リポジトリパス（必須）
```
日報を作成したいリポジトリのパスを入力してください。（複数指定可、カンマ区切り）
例: /path/to/repo1, /path/to/repo2
```

### 質問2: ユーザー名（必須）
```
コミット履歴を取得したいGitユーザー名を入力してください。（複数指定可、カンマ区切り）
例: ゆうご, yuhgo, yamamoto
```

### 質問3: 対象年月（必須）
```
取得する年月を指定してください。
例: 2026-01
```

### 質問4: リポジトリ略称（オプション）
```
各リポジトリの日本語略称を指定しますか？
例: delivery-article=配達LP, delivery-backoffice=配送BO
```

### 質問5: 定例会議（オプション）
```
追加する定例会議はありますか？
例:
- 朝会: 毎週月曜 10:30-10:45（対象日: 5,19,26）
- ZDC定例: 毎週月曜 15:00-16:00（対象日: 5,19,26）
```

## 実装詳細

### Python仮想環境のセットアップ
```bash
mkdir -p /tmp/excel_work
cd /tmp/excel_work
python3 -m venv venv
source venv/bin/activate
pip install openpyxl --quiet
```

### Git Logコマンド仕様
```bash
cd [リポジトリパス] && git log \
  --author="ユーザー1\|ユーザー2\|ユーザー3" \
  --since="[開始日]" \
  --until="[終了日]" \
  --pretty=format:"%aI|%s" \
  --no-merges
```

### 作業時間推定ロジック

タスクの内容に応じて現実的な作業時間を推定し、自然なばらつきを追加：

| カテゴリ | 基準時間 | ばらつき範囲 | キーワード例 |
|---------|---------|-------------|-------------|
| 短い作業 | 20分 | ±7分 | ロゴ、画像差し替え、サイズ調整 |
| やや短い作業 | 35分 | ±10分 | 非表示、位置ずれ、マーカー |
| 中程度の作業 | 50分 | ±12分 | レスポンシブ、レイアウト |
| やや長い作業 | 75分 | ±15分 | リデザイン、コンポーネント分離 |
| 長い作業 | 90分 | ±18分 | フォールバック、ダイアログ |

### コミットメッセージの整形

prefix（feat:, fix:, style:, chore:, refactor:）を除去し、リポジトリ略称を付与：
```
入力: feat: LPヒーローセクションの画像を差し替え
出力: 配達LP LPヒーローセクションの画像を差し替え
```

### 日付フォーマット
```
2026-01-05 → 1月5日(月)
```

## 出力TSVフォーマット

```
日付	開始時間	終了時間	作業内容
1月5日(月)	10:30	10:45	朝会
1月5日(月)	15:00	16:00	ZDC定例
1月6日(火)	14:48	16:11	決済画面 購入履歴画面の月額/年額表示を修正
1月7日(水)	11:21	13:03	決済画面 購入履歴画面での月額/年額表示を請求サイクルに依存しない形式に変更
```

## 実行例

### ユーザー入力例
```
リポジトリパス:
  - /Users/user/ghq/github.com/org/delivery-article
  - /Users/user/ghq/github.com/org/delivery-backoffice
  - /Users/user/ghq/github.com/org/godoor-lp
  - /Users/user/ghq/github.com/org/gosales
  - /Users/user/ghq/github.com/org/delivery

ユーザー名: ゆうご, yuhgo, yugo, yamamoto, Yamamoto

対象年月: 2026-01

リポジトリ略称:
  delivery-article: 配達LP
  delivery-backoffice: 配送BO
  godoor-lp: 総合LP
  gosales: 営業LP
  delivery: 決済画面

定例会議:
  - 朝会: 10:30-10:45（対象日: 5, 19, 26）
  - ZDC定例: 15:00-16:00（対象日: 5, 19, 26）
```

### システム応答例
```
📋 日報データを生成しています...

✅ リポジトリ確認完了:
  - delivery-article: 9件
  - delivery-backoffice: 5件
  - godoor-lp: 5件
  - gosales: 12件
  - delivery: 3件

📊 合計: 34件のコミット + 6件の定例会議

📝 TSVファイルを生成中...
✅ 出力完了: /tmp/excel_work/日報データ.tsv

ファイルを開きます。全選択してコピーし、スプレッドシートに貼り付けてください。
```

## Pythonスクリプトテンプレート

```python
import subprocess
import os
import random
from datetime import datetime, timedelta, timezone

# 設定
REPOS = {
    "delivery-article": "配達LP",
    "delivery-backoffice": "配送BO",
    "godoor-lp": "総合LP",
    "gosales": "営業LP",
    "delivery": "決済画面",
}
BASE_PATH = "/path/to/repos"
AUTHORS = ["ゆうご", "yuhgo", "yugo", "yamamoto", "Yamamoto"]
YEAR_MONTH = "2026-01"
MEETING_DAYS = [5, 19, 26]  # 定例会議の日付
JST = timezone(timedelta(hours=9))

def estimate_work_time(message):
    """タスク内容から作業時間を推定（ランダムなばらつき付き）"""
    msg = message.lower()

    if any(word in msg for word in ["ロゴ", "画像", "差し替え", "サイズ"]):
        base, variation = 20, [-5, -3, 0, 2, 5, 7]
    elif any(word in msg for word in ["非表示", "位置ずれ", "マーカー"]):
        base, variation = 35, [-7, -4, 0, 3, 8, 10]
    elif any(word in msg for word in ["レスポンシブ", "レイアウト", "SP表示"]):
        base, variation = 50, [-8, -5, 0, 5, 10, 12]
    elif any(word in msg for word in ["リデザイン", "コンポーネント"]):
        base, variation = 75, [-12, -8, 0, 5, 10, 15]
    elif any(word in msg for word in ["フォールバック", "ダイアログ"]):
        base, variation = 90, [-10, -7, 0, 5, 12, 18]
    else:
        base, variation = 45, [-8, -5, 0, 5, 8, 12]

    return max(10, base + random.choice(variation))

def get_commits(repo_name):
    """リポジトリからコミット履歴を取得"""
    repo_path = os.path.join(BASE_PATH, repo_name)
    author_pattern = "\\|".join(AUTHORS)
    year, month = YEAR_MONTH.split("-")
    start_date = f"{year}-{month}-01"
    end_date = f"{year}-{month}-31"

    cmd = f'cd "{repo_path}" && git log --author="{author_pattern}" --since="{start_date}" --until="{end_date}" --pretty=format:"%aI|%s" --no-merges'
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)

    commits = []
    for line in result.stdout.strip().split('\n'):
        if line and '|' in line:
            datetime_str, message = line.split('|', 1)
            dt = datetime.fromisoformat(datetime_str)
            # prefix除去
            for prefix in ["feat: ", "fix: ", "style: ", "chore: ", "refactor: "]:
                if message.startswith(prefix):
                    message = message[len(prefix):]
                    break

            label = REPOS[repo_name]
            content = f"{label} {message}"
            work_minutes = estimate_work_time(content)
            end_time = dt.strftime("%H:%M")

            # 開始時間を計算
            total = dt.hour * 60 + dt.minute - work_minutes
            start_time = f"{max(0, total // 60):02d}:{total % 60:02d}"

            commits.append({
                "datetime": dt,
                "date": dt.strftime("%Y-%m-%d"),
                "start_time": start_time,
                "end_time": end_time,
                "message": content,
            })
    return commits

# メイン処理
all_commits = []
for repo_name in REPOS:
    all_commits.extend(get_commits(repo_name))

# 定例会議を追加
for day in MEETING_DAYS:
    dt = datetime(int(YEAR_MONTH.split("-")[0]), int(YEAR_MONTH.split("-")[1]), day, tzinfo=JST)
    all_commits.append({
        "datetime": dt.replace(hour=10, minute=45),
        "date": dt.strftime("%Y-%m-%d"),
        "start_time": "10:30",
        "end_time": "10:45",
        "message": "朝会",
    })
    all_commits.append({
        "datetime": dt.replace(hour=16, minute=0),
        "date": dt.strftime("%Y-%m-%d"),
        "start_time": "15:00",
        "end_time": "16:00",
        "message": "ZDC定例",
    })

# 日時順にソート
all_commits.sort(key=lambda x: x["datetime"])

# TSV出力
def date_to_japanese(date_str):
    dt = datetime.strptime(date_str, "%Y-%m-%d")
    weekdays = ["月", "火", "水", "木", "金", "土", "日"]
    return f"{dt.month}月{dt.day}日({weekdays[dt.weekday()]})"

with open("/tmp/excel_work/日報データ.tsv", 'w', encoding='utf-8') as f:
    for c in all_commits:
        f.write(f"{date_to_japanese(c['date'])}\t{c['start_time']}\t{c['end_time']}\t{c['message']}\n")
```

## エラーハンドリング

### リポジトリが見つからない場合
```
❌ エラー: 指定されたパスはGitリポジトリではありません
パス: /path/to/invalid

対処方法:
1. パスが正しいか確認してください
2. .gitディレクトリが存在するか確認してください
```

### openpyxlがインストールされていない場合
```
⚠️ openpyxlがインストールされていません

自動で仮想環境を作成してインストールします:
mkdir -p /tmp/excel_work && cd /tmp/excel_work && python3 -m venv venv && source venv/bin/activate && pip install openpyxl
```

## 注意事項

### 実行前の確認
- 各リポジトリパスが正しいGitリポジトリであることを確認
- ユーザー名が正確であることを確認
- 対象年月が正しいことを確認

### 出力について
- TSVファイルはタブ区切りでスプレッドシートに直接貼り付け可能
- 開始時間はコミット時間から作業時間を逆算して推定
- 作業時間は内容に応じて自然なばらつきを持たせる

### スプレッドシートへの貼り付け
1. TSVファイルを開く（`open /tmp/excel_work/日報データ.tsv`）
2. 全選択（Cmd+A）
3. コピー（Cmd+C）
4. スプレッドシートの開始セル（例: A8）を選択
5. 貼り付け（Cmd+V）