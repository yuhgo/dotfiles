---
name: daily-report-tsv
description: 指定した月・指定したリポジトリのGitコミット履歴とharness-memの作業記録から、日報用TSVデータをスプレッドシートにコピペできる形式で出力する
allowed-tools: Bash, mcp__harness__harness_mem_search, mcp__harness__harness_mem_timeline, mcp__harness__harness_mem_get_observations
---

# daily-report-tsv

指定した月と指定したリポジトリのGitコミット履歴、およびharness-memの作業記録を取得し、日ごとにグループ化してスプレッドシートにコピペ可能なTSV形式で出力する。

## パラメータ

### 必須パラメータ
- **対象年月**: 取得する年月（例: `2026-02`）
- **リポジトリパス**: コミット履歴を取得したいGitリポジトリのパス（1つまたは複数）

### オプションパラメータ
- **ユーザー名**: Gitのauthor名（デフォルト: `yugo|yuhgo|yamamoto|Yamamoto`）
- **リポジトリ略称**: 出力時に使う短い名前（例: `dotfiles`）。未指定の場合はディレクトリ名を使用
- **定例会議**: 追加する定例会議の情報（日付、開始時間、終了時間、名称）
- **出力ファイルパス**: TSVファイルの保存先（デフォルト: `<プロジェクトルート>/daily-report/YYYY-MM_日報データ.tsv`）

## 実行フロー

### Step 1: パラメータ確認

ユーザーに以下を確認する（会話の中で既に指定されていればスキップ）:

1. 対象年月（必須）
2. リポジトリパス（必須、複数可）
3. リポジトリ略称（オプション）
4. ユーザー名（オプション、デフォルトあり）
5. 定例会議（オプション）

### Step 2: Gitコミット履歴取得

各リポジトリに対して以下のコマンドを実行:

```bash
cd [リポジトリパス] && git log \
  --author="ユーザー1\|ユーザー2" \
  --since="YYYY-MM-01" \
  --until="YYYY-MM+1-01" \
  --pretty=format:"%aI|%s" \
  --no-merges \
  --all
```

- `%aI`: ISO 8601形式のauthor date（タイムゾーン付き）
- `%s`: コミットメッセージ1行目

### Step 3: harness-memから作業記録を取得

対象月の作業記録を `harness_mem_search` で検索する:

1. `harness_mem_search` で月全体を検索:
   - `query`: "実装 追加 修正 変更 調査 設定 レビュー 作成 更新 fix feat update refactor"
   - `since`: 対象月の初日（YYYY-MM-01）
   - `until`: 対象月の翌月初日（YYYY-MM+1-01）
   - `limit`: 50
2. 必要に応じて `harness_mem_timeline` で詳細を展開
3. 必要に応じて `harness_mem_get_observations` で個別observationの詳細を取得

以下のタイプを重点的に取得:
- ✅ (change): コードの変更・実装
- 🔴 (bugfix): バグ修正
- 🔵 (discovery): 調査・発見（コミットを伴わない作業）

### Step 4: 情報の統合・整形

#### コミットメッセージの整形
- Conventional Commitsのprefix（`feat:`, `fix:`, `chore:`, `refactor:`, `style:`, `docs:`, `test:`, `ci:`, `build:`, `perf:`）を除去
- 複数リポジトリの場合、先頭にリポジトリ略称を付与

#### 作業時間推定ロジック

Gitコミットの場合、コミット時刻を終了時間とし、作業内容から開始時間を逆算する:

| カテゴリ | 基準時間 | ばらつき範囲 | キーワード例 |
|---------|---------|-------------|-------------|
| 短い作業 | 20分 | ±7分 | ロゴ、画像差し替え、サイズ調整、typo |
| やや短い作業 | 35分 | ±10分 | 非表示、位置ずれ、マーカー、設定変更 |
| 中程度の作業 | 50分 | ±12分 | レスポンシブ、レイアウト、コンポーネント |
| やや長い作業 | 75分 | ±15分 | リデザイン、コンポーネント分離、リファクタ |
| 長い作業 | 90分 | ±18分 | フォールバック、ダイアログ、新機能追加 |
| デフォルト | 45分 | ±12分 | 上記に該当しないもの |

harness-memの記録は、observationのタイムスタンプから開始時間を推定し、作業内容から終了時間を推定する（30分をデフォルトとする）。

#### 重複排除
- Gitコミットとharness-memで同じ作業が記録されている場合は1つにまとめる
  - 判定基準: 同一日に同じキーワードを含む記録がある場合
- Gitコミットを優先し、harness-memのみに記録されている作業（ブラウザ調査、設定確認、レビューなど）はソース列を `harness-mem` として追加

### Step 5: TSV生成・出力

以下の形式でTSVファイルを生成する:

```
日付	開始時間	終了時間	作業内容
1月5日(月)	10:30	10:45	朝会
	15:00	16:00	ZDC定例
1月6日(火)	14:48	16:11	決済画面 購入履歴画面の月額/年額表示を修正
	17:20	17:50	harness-mem API設計の調査・検討
```

#### 出力ルール

- 同一日の最初の行にのみ日付を表示し、2行目以降の日付列は空にする
- 時刻はJST（UTC+9）で表示
  - Gitコミット: author dateを変換
  - harness-mem: observationのタイムスタンプを変換
- 同一日内は開始時間の昇順でソート
- 作業がない日は出力しない
- 曜日は日本語表記: 月, 火, 水, 木, 金, 土, 日
- 月の最初から最後まで日付順に出力
- 日付フォーマット: `M月D日(曜日)`（例: `1月5日(月)`）

### Step 6: ファイル出力とクリップボード

#### 出力先ディレクトリ

TSVファイルはプロジェクトルート直下の `daily-report/` ディレクトリに出力する。
ファイル名は対象年月を含める: `YYYY-MM_日報データ.tsv`

```
<プロジェクトルート>/
├── daily-report/
│   ├── 2026-01_日報データ.tsv
│   ├── 2026-02_日報データ.tsv
│   └── ...
```

```bash
# プロジェクトルートを取得
PROJECT_ROOT=$(git rev-parse --show-toplevel)
OUTPUT_DIR="${PROJECT_ROOT}/daily-report"
OUTPUT_FILE="${OUTPUT_DIR}/YYYY-MM_日報データ.tsv"

mkdir -p "${OUTPUT_DIR}"
# TSVファイルを保存
cat > "${OUTPUT_FILE}" << 'EOF'
（TSVデータ）
EOF
# macOSの場合、クリップボードにもコピー
cat "${OUTPUT_FILE}" | pbcopy
```

出力後、ユーザーに以下を案内:
- TSVファイルのパス（例: `<プロジェクトルート>/daily-report/2026-02_日報データ.tsv`）
- クリップボードにコピー済みであること
- スプレッドシートの開始セルを選択して貼り付け（Cmd+V）で利用可能

## Pythonスクリプトテンプレート

```python
import subprocess
import os
import random
from datetime import datetime, timedelta, timezone

# 設定（実行時にパラメータから設定）
REPOS = {
    # "リポジトリ名": "略称"
}
AUTHORS = ["yugo", "yuhgo", "yamamoto", "Yamamoto"]
YEAR_MONTH = "YYYY-MM"
MEETINGS = []  # [{"date": day, "start": "HH:MM", "end": "HH:MM", "name": "会議名"}, ...]
JST = timezone(timedelta(hours=9))

def estimate_work_time(message):
    """タスク内容から作業時間を推定（ランダムなばらつき付き）"""
    msg = message.lower()
    if any(word in msg for word in ["ロゴ", "画像", "差し替え", "サイズ", "typo"]):
        base, variation = 20, [-5, -3, 0, 2, 5, 7]
    elif any(word in msg for word in ["非表示", "位置ずれ", "マーカー", "設定"]):
        base, variation = 35, [-7, -4, 0, 3, 8, 10]
    elif any(word in msg for word in ["レスポンシブ", "レイアウト", "コンポーネント", "sp表示"]):
        base, variation = 50, [-8, -5, 0, 5, 10, 12]
    elif any(word in msg for word in ["リデザイン", "分離", "リファクタ"]):
        base, variation = 75, [-12, -8, 0, 5, 10, 15]
    elif any(word in msg for word in ["フォールバック", "ダイアログ", "新機能"]):
        base, variation = 90, [-10, -7, 0, 5, 12, 18]
    else:
        base, variation = 45, [-8, -5, 0, 5, 8, 12]
    return max(10, base + random.choice(variation))

def get_commits(repo_path, repo_label):
    """リポジトリからコミット履歴を取得"""
    author_pattern = "\\|".join(AUTHORS)
    year, month = YEAR_MONTH.split("-")
    next_month = int(month) + 1
    next_year = int(year)
    if next_month > 12:
        next_month = 1
        next_year += 1
    start_date = f"{year}-{month}-01"
    end_date = f"{next_year}-{next_month:02d}-01"
    cmd = f'cd "{repo_path}" && git log --author="{author_pattern}" --since="{start_date}" --until="{end_date}" --pretty=format:"%aI|%s" --no-merges --all'
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    commits = []
    for line in result.stdout.strip().split('\n'):
        if line and '|' in line:
            datetime_str, message = line.split('|', 1)
            dt = datetime.fromisoformat(datetime_str).astimezone(JST)
            for prefix in ["feat: ", "fix: ", "style: ", "chore: ", "refactor: ", "docs: ", "test: ", "ci: ", "build: ", "perf: "]:
                if message.startswith(prefix):
                    message = message[len(prefix):]
                    break
            content = f"{repo_label} {message}" if len(REPOS) > 1 else message
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
                "source": "git",
            })
    return commits

# harness-memから取得した記録をマージする関数
def add_harness_mem_entries(entries, all_commits):
    """harness-memの記録をコミットリストに追加（重複排除済み）"""
    for entry in entries:
        dt = datetime.fromisoformat(entry["timestamp"]).astimezone(JST)
        # 重複チェック: 同一日に類似キーワードを含むGitコミットがあればスキップ
        date_str = dt.strftime("%Y-%m-%d")
        title_words = set(entry["title"].split())
        is_duplicate = False
        for c in all_commits:
            if c["date"] == date_str and c["source"] == "git":
                if len(title_words & set(c["message"].split())) >= 2:
                    is_duplicate = True
                    break
        if not is_duplicate:
            start_time = dt.strftime("%H:%M")
            end_minutes = dt.hour * 60 + dt.minute + 30  # デフォルト30分
            end_time = f"{min(23, end_minutes // 60):02d}:{end_minutes % 60:02d}"
            all_commits.append({
                "datetime": dt,
                "date": date_str,
                "start_time": start_time,
                "end_time": end_time,
                "message": f"harness-mem {entry['title']}",
                "source": "harness-mem",
            })

# メイン処理
all_commits = []
for repo_path, repo_label in REPOS.items():
    all_commits.extend(get_commits(repo_path, repo_label))

# 定例会議を追加
year, month = YEAR_MONTH.split("-")
for meeting in MEETINGS:
    dt = datetime(int(year), int(month), meeting["date"], tzinfo=JST)
    all_commits.append({
        "datetime": dt.replace(hour=int(meeting["end"].split(":")[0]), minute=int(meeting["end"].split(":")[1])),
        "date": dt.strftime("%Y-%m-%d"),
        "start_time": meeting["start"],
        "end_time": meeting["end"],
        "message": meeting["name"],
        "source": "meeting",
    })

# harness-memの記録はここでadd_harness_mem_entriesを呼び出して追加

all_commits.sort(key=lambda x: x["datetime"])

def date_to_japanese(date_str):
    dt = datetime.strptime(date_str, "%Y-%m-%d")
    weekdays = ["月", "火", "水", "木", "金", "土", "日"]
    return f"{dt.month}月{dt.day}日({weekdays[dt.weekday()]})"

project_root = subprocess.run("git rev-parse --show-toplevel", shell=True, capture_output=True, text=True).stdout.strip()
output_path = os.path.join(project_root, "daily-report", f"{YEAR_MONTH}_日報データ.tsv")
os.makedirs(os.path.dirname(output_path), exist_ok=True)
with open(output_path, 'w', encoding='utf-8') as f:
    prev_date = None
    for c in all_commits:
        date_jp = date_to_japanese(c['date'])
        if date_jp == prev_date:
            date_col = ""
        else:
            date_col = date_jp
            prev_date = date_jp
        f.write(f"{date_col}\t{c['start_time']}\t{c['end_time']}\t{c['message']}\n")

print(f"TSVファイルを保存しました: {output_path}")
```

## エラーハンドリング

| ケース | 対応 |
|--------|------|
| harness-memに接続できない | Gitコミット履歴のみからTSVを生成し、harness-memが利用不可だった旨を報告 |
| Gitリポジトリにアクセスできない | harness-memの情報のみからTSVを生成 |
| 対象月の作業履歴が0件 | 「対象月の作業履歴が見つかりませんでした」と報告 |

## スプレッドシートへの貼り付け

1. クリップボードにコピー済みの場合はそのまま貼り付け（Cmd+V）
2. またはTSVファイルを開く（`open <プロジェクトルート>/daily-report/YYYY-MM_日報データ.tsv`）
3. 全選択（Cmd+A）→ コピー（Cmd+C）
4. スプレッドシートの開始セルを選択 → 貼り付け（Cmd+V）
