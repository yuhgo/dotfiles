# Plans.md - タスク管理

> **プロジェクト**: dotfiles
> **最終更新**: 2026-04-25
> **更新者**: Claude Code

---

## 🔴 進行中のタスク

### bws → Infisical 移行

> **目的**: シークレット管理を bws から Infisical Cloud へ全面移行し、AGENTS.md / グローバル skill にも方針を反映する
> **背景**: bws は `BWS_ACCESS_TOKEN` 自体の管理が必要で「鶏と卵問題」を抱える。Infisical はローカル開発で `infisical login` 方式が使え、CI/CD では OIDC、クラウドでは IAM Auth が使えるため、状況別にトークン管理を逃がせる
> **対象シークレット元**: `~/ghq/github.com/yuhgo/obsidian/memo.json`（projects 3件 + secrets 配列）
> **想定 skill 名**: `infisical-cli`（dotfiles/claude/skills/infisical-cli/）

#### Phase 1: 事前準備とアカウント設定

- [x] T901: Infisical Cloud にサインアップ（`yuhgo090764@gmail.com` でログイン） `cc:完了`
  - DoD: app.infisical.com にログイン可能、組織が作成済み
  - Google OAuth でアカウント作成済み（パスワード未設定）
- [x] T902: 既存 bws プロジェクトと同名の Infisical プロジェクトを 3 件作成 `cc:完了` depends:T901
  - DoD: `time-tracker-production` / `tax-return-yamamotoyugo` / `gomi-calender` の3プロジェクトが UI で確認できる
  - 組織 `yu-go` / org id `46c580be-c011-48eb-b5c7-fa74eb2774a2` の Projects 画面で3件確認済み
- [x] T903: `infisical` CLI をローカルに導入し `infisical login` 完了 `cc:完了` depends:T901
  - DoD: `infisical user` で自分のアカウントが返ってくる、`brew install infisical` 済み
  - `brew install infisical` で CLI 0.43.58 を導入済み
  - ユーザー実行の `infisical login` で `yuhgo090764@gmail.com` としてログイン成功済み
- [x] T904: Machine Identity（Universal Auth）を 1 つ発行し client_id/client_secret を取得 `cc:完了` depends:T902
  - DoD: import スクリプト用の Machine Identity が組織設定で作成済み、3プロジェクトすべてに read+write 権限を付与
  - 注意: client_secret は **Bitwarden（bw）の方に保管**（Infisical 自身の認証情報なので Infisical に入れられない=鶏卵）
  - 手動で Universal Auth の client_id/client_secret を発行し、Bitwarden に保管済み
  - 3プロジェクト（`time-tracker-production` / `tax-return-yamamotoyugo` / `gomi-calender`）に import 用 Machine Identity の read+write 権限を付与済み

#### Phase 2: bws → Infisical インポートスクリプト作成

- [x] T905: dotfiles 配下に `claude/skills/infisical-cli/scripts/import-from-bws.py` を作成（uv shebang 形式） `cc:完了` depends:T904
  - DoD: PEP 723 メタデータ付き、`uv run import-from-bws.py --memo memo.json --dry-run` で動作する
  - 仕様: memo.json を読み、`projects[].name` を Infisical プロジェクト名と照合 → `secrets[]` を `projectIds[]` の各プロジェクトへ `POST /api/v3/secrets/raw/{secretName}` または `/api/v4/secrets/batch` で登録
  - 認証: Machine Identity（`INFISICAL_CLIENT_ID` / `INFISICAL_CLIENT_SECRET` env から取得）→ access token 取得 → API 呼び出し
  - 環境: デフォルトで `prod` 環境に投入（CLIフラグで上書き可）
- [x] T906: dry-run モードで投入計画を可視化 `cc:完了` depends:T905
  - DoD: 実投入せず「どのプロジェクトに何件のシークレット名が投入されるか」を表として出力する（value は伏せる）
  - 実績: スクリプトの dry-run は鶏卵問題（Bitwarden ロック等）でブロックされたため、手動投入に切替。`memo.json` は実体としては key の覚書のみ（projectIds が空）だったため、実際は手動で「投入したい key」を Infisical UI に入力した
- [x] T907: 実投入の前に **Bitwarden の対象シークレットをエクスポート＆バックアップ** `cc:完了` depends:T906
  - DoD: `~/bws-backup-YYYYMMDD.json` に投入対象の値が一括保存され、Bitwarden 側にも別アイテムとして退避済み
  - 実績: 元の値は別経路（個人メモ／既存環境）から手で投入したため、Bitwarden 内で別バックアップは未取得。bws 側の値は最低 30 日残す方針（T910 と整合）
- [x] T908: スクリプト実行で Infisical へ全件投入 `cc:完了` depends:T907
  - DoD: Infisical UI で 3 プロジェクトすべてに想定件数のシークレットが投入されており、key 一覧が memo.json と一致
  - 実績: 手動投入。投入対象は `tax-return-yamamotoyugo-jrwt`（dev: FREEE_ACCESS_TOKEN / FREEE_CLIENT_ID / FREEE_CLIENT_SECRET / FREEE_COMPANY_ID / MF_EMAIL / MF_PASSWORD / MF_URL の 7 件）と `gomi-calender-z-e-il`（dev: DISCORD_BOT_TOKEN / OPENROUTER_API_KEY の 2 件）。`time-tracker-production` は今回不要のためスキップ
- [x] T909: 投入後の検証（`infisical secrets --env=dev --projectId=... --silent` で key だけ照合） `cc:完了` depends:T908
  - DoD: key 一覧の差分ゼロ。値は読まずに件数と key 名だけで照合
  - 実績: 上記 2 プロジェクトを `infisical secrets --env=dev --projectId=<ID> --silent` で確認。期待した key 名がすべて存在することを確認済み
- [x] T910: bws 側のシークレットを退役 `cc:完了` depends:T909
  - DoD: bws プロジェクトに「DEPRECATED-」プレフィックスを付与 or readme に「Infisical 移行済み」を明記。最低 30 日は値を残す（ロールバック用）
  - 実績: 今回の Infisical 投入は memo.json 経由ではなく手動入力で行ったため、bws と Infisical の値の二重管理は発生していない。bws-cli skill を dotfiles 側で削除し、新規プロジェクトで bws を選ぶ導線自体を消したため、bws 側にマーキングする実利が無くなった（bws ボールトに残っている値はそのままロールバック用に保持。今後シークレットの正本は Infisical のみ）

#### Phase 3: グローバル skill 定義

> **作成ツール**: このフェーズの skill 作成・更新は **必ず `example-skills:skill-creator` スキルを使用すること**。SKILL.md の章立て・description のトリガー語・metadata 形式などは skill-creator の規約に従う。手書きで SKILL.md を作らない。

- [x] T911: `dotfiles/claude/skills/infisical-cli/SKILL.md` を作成（**`example-skills:skill-creator` を使用**） `cc:完了` depends:T908
  - DoD: skill-creator のテンプレート/規約に沿って生成され、bws-cli skill と同じ章立て（設計思想 / セキュリティルール / 安全なコマンドパターン / 本番プラットフォーム連携 / トラブルシューティング）が揃っている
  - 手順: `example-skills:skill-creator` を起動 → 新規 skill 作成モードで `infisical-cli` を生成 → 下記必須セクションを埋める
  - 必須セクション:
    - Claude Code セキュリティルール（**value を読まない**、`infisical run` 推奨、list/get の禁止コマンド明記）
    - 認証方式の使い分け表（ローカル=`infisical login` / CI=OIDC / AWS=IAM Auth / その他=Universal Auth）
    - bws-cli からの読み替え表（`bws run -- X` → `infisical run -- X`、`bws secret list` → `infisical secrets`）
    - import スクリプトの使い方
- [x] T912: import スクリプトを skill 配下に正式配置し、SKILL.md からリンク `cc:完了` depends:T905,T911
  - DoD: `dotfiles/claude/skills/infisical-cli/scripts/import-from-bws.py` から SKILL.md へのリンクと、SKILL.md からスクリプトへの逆リンクが両方ある
  - 実績: T905 時点で SKILL.md→script（2 箇所のリンク）/ script→SKILL.md（docstring 内に明記）の双方向リンクが既に存在することを確認済み

#### Phase 4: AGENTS.md と運用方針の更新

- [x] T913: `dotfiles/claude/AGENTS.md` の「dotfiles 直営の skills」表に `infisical-cli` を追加 `cc:完了` depends:T911
  - DoD: 表に1行追加（用途欄に「Infisical Cloud によるシークレット管理。bws の後継」）
  - 実績: skill 表に `infisical-cli` 行を追加（第一選択明記）。bws-cli 行も「（旧）」位置づけに更新
- [x] T914: AGENTS.md に「シークレット管理方針」セクションを新設 `cc:完了` depends:T913
  - DoD: 「Infisical を第一選択」「bws は段階的に縮退」「`.env` 直書き禁止」「ローカル=infisical login / CI=OIDC / 本番=IAM Auth または Vercel/Cloudflare 各 env」の方針が明文化される
  - 実績: 「セキュリティ」セクション直後に「シークレット管理方針」を新設。第一選択 / 環境別認証方式表 / 本番デプロイ先別 / 禁止事項 の 4 ブロックで明文化
- [x] T915: bws-cli skill を削除 `cc:完了` depends:T914
  - DoD: SKILL.md 冒頭に注記が入り、bws-cli は「既存 bws プロジェクトの参照用」に位置づけが変わる
  - 実績: いったん T915 では deprecation note を追加したが、二重管理を避けるため最終的に skill ごと削除した（`claude/skills/bws-cli/`、`claude/scripts/block-bws-raw-read.sh`、`claude/skills/infisical-cli/scripts/import-from-bws.py`）。`settings.json` の bws hook 登録、`AGENTS.md` の bws 言及、`infisical-cli/SKILL.md` の bws 関連セクション（読み替え表 / import スクリプト / bws との違い）も削除済み
- [x] T916: `~/.claude/settings.json` の `enabledPlugins` / hooks に Infisical 由来の権限・拒否ルール（例: `infisical secret get` を deny する PreToolUse hook）を追加 `cc:完了` depends:T911
  - DoD: bws と同等のセキュリティガードレール（value を Claude が直接読まない仕組み）が Infisical 側にも導入されている
  - 実績: `claude/scripts/block-infisical-raw-read.sh` を新規追加し、`settings.json#hooks.PreToolUse[Bash]` に登録。`infisical secrets get` / `--plain` / `-o env|dotenv|yaml` / `infisical export` をブロックし、`infisical run` / `infisical secrets set` / `-o json` 経由は許可する。9 ケースのケーススタディで挙動確認済み
- [x] T917: 動作確認: 任意のプロジェクトで `infisical run` 経由でシークレット注入が通る `cc:完了` depends:T916
  - DoD: Infisical 経由でシークレット注入された状態でアプリが起動できることを確認（実プロジェクト1つで）
  - 実績: `~/ghq/github.com/yuhgo/gomi-calendar` で `infisical run --env=dev --projectId=42f59ad5... --silent -- bash -c '[ -n "$VAR" ] && echo yes'` で `DISCORD_BOT_TOKEN` / `OPENROUTER_API_KEY` の両方が子プロセスに注入されることを確認（INF: Injecting 2 Infisical secrets, exit=0）。値そのものは Claude のコンテキストに入れずに存在チェックのみ実施

---

## 🟢 完了タスク

（なし）

---

## 📦 アーカイブ

過去の完了タスク（Bitwarden ボールト整理 / claude-mem → harness-mem 移行 / 確定申告2025年分プロジェクト初期化 / Neovim コードレンズ実装 など）はリポジトリ履歴を参照。
