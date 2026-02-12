---
name: farm-in-daily-report
description: farm-in案件の複数リポジトリからGitコミット履歴を抽出し、日報用TSVデータをスプレッドシートにコピペできる形式で出力
allowed-tools: Bash, AskUserQuestion
---

# farm-in 日報作成スキル

farm-in案件の複数Gitリポジトリからコミット履歴を抽出し、日報（スプレッドシート）にコピペできるTSV形式で出力する。

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

コマンドを実行する前にAskUserQuestionで以下を確認する：

1. **リポジトリパス**（必須）
2. **ユーザー名**（必須）
3. **対象年月**（必須）
4. **リポジトリ略称**（オプション）
5. **定例会議**（オプション）

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
MEETING_DAYS = [5, 19, 26]
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
            for prefix in ["feat: ", "fix: ", "style: ", "chore: ", "refactor: "]:
                if message.startswith(prefix):
                    message = message[len(prefix):]
                    break
            label = REPOS[repo_name]
            content = f"{label} {message}"
            work_minutes = estimate_work_time(content)
            end_time = dt.strftime("%H:%M")
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

all_commits = []
for repo_name in REPOS:
    all_commits.extend(get_commits(repo_name))

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

all_commits.sort(key=lambda x: x["datetime"])

def date_to_japanese(date_str):
    dt = datetime.strptime(date_str, "%Y-%m-%d")
    weekdays = ["月", "火", "水", "木", "金", "土", "日"]
    return f"{dt.month}月{dt.day}日({weekdays[dt.weekday()]})"

with open("/tmp/excel_work/日報データ.tsv", 'w', encoding='utf-8') as f:
    for c in all_commits:
        f.write(f"{date_to_japanese(c['date'])}\t{c['start_time']}\t{c['end_time']}\t{c['message']}\n")
```

## スプレッドシートへの貼り付け

1. TSVファイルを開く（`open /tmp/excel_work/日報データ.tsv`）
2. 全選択（Cmd+A）
3. コピー（Cmd+C）
4. スプレッドシートの開始セルを選択
5. 貼り付け（Cmd+V）

## 注意事項

- 各リポジトリパスが正しいGitリポジトリであることを確認
- TSVファイルはタブ区切りでスプレッドシートに直接貼り付け可能
- 開始時間はコミット時間から作業時間を逆算して推定
- 作業時間は内容に応じて自然なばらつきを持たせる
