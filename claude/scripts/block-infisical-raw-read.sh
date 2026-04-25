#!/bin/bash
# PreToolUse hook: infisical で value を直接読み出すコマンドをブロック
# - infisical secrets get
# - infisical secrets ... --plain
# - infisical secrets ... -o {env,dotenv,yaml}
# - infisical export

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/^"command"[[:space:]]*:[[:space:]]*"//;s/"$//')

[ -z "$COMMAND" ] && exit 0

# 1. infisical secrets get … は常にブロック（出力に value が含まれる）
if echo "$COMMAND" | grep -qE 'infisical\s+secrets\s+get(\s|$)'; then
  echo "BLOCK: 'infisical secrets get' は value を出力するため Claude のコンテキストに値が入ります。" >&2
  echo "代替: 動作確認は 'infisical run --env=<E> --projectId=<PID> -- <CMD>' を使う、" >&2
  echo "       存在確認は 'infisical secrets ... --silent -o json | jq -r .[].secretKey' を使う、" >&2
  echo "       目視は Infisical UI を使ってください。" >&2
  exit 2
fi

# 2. infisical secrets ... に value 出力フラグが付いている場合をブロック
#    --plain / -o env / -o dotenv / -o yaml
if echo "$COMMAND" | grep -qE 'infisical\s+secrets(\s|$)'; then
  if echo "$COMMAND" | grep -qE '(\s|^)--plain(\s|$)'; then
    echo "BLOCK: 'infisical secrets --plain' は value を出力します。" >&2
    echo "代替: '--silent -o json | jq -r .[].secretKey' で key だけ抽出してください。" >&2
    exit 2
  fi
  if echo "$COMMAND" | grep -qE '(\s|^)(-o|--output)\s+(env|dotenv|yaml)(\s|$)'; then
    echo "BLOCK: 'infisical secrets -o env|dotenv|yaml' は value を出力します。" >&2
    echo "代替: '-o json' を使い jq で value 列を捨ててください。" >&2
    exit 2
  fi
fi

# 3. infisical export はシークレット全体をダンプするので常にブロック
if echo "$COMMAND" | grep -qE 'infisical\s+export(\s|$)'; then
  echo "BLOCK: 'infisical export' はシークレット全体をダンプします。" >&2
  echo "目的が移行・バックアップなら、Claude を介さず別ターミナルで実行してください。" >&2
  exit 2
fi

exit 0
