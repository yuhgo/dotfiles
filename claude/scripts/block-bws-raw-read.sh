#!/bin/bash
# PreToolUse hook: bws secret list / bws secret get の直接実行をブロック
# jq で value を除外していないコマンドを禁止する

# 標準入力から JSON を読み取る
INPUT=$(cat)

# tool_input.command の値を grep で抽出（jq 不要）
COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/^"command"[[:space:]]*:[[:space:]]*"//;s/"$//')

# 空なら何もしない
[ -z "$COMMAND" ] && exit 0

# bws secret list または bws secret get が含まれているか確認
if echo "$COMMAND" | grep -qE 'bws\s+secret\s+(list|get)'; then
  # jq でフィルタしている場合は許可
  if echo "$COMMAND" | grep -q '| jq'; then
    exit 0
  fi
  # フィルタなしの直接実行はブロック（stderr に出力）
  echo "BLOCK: bws secret list/get を直接実行するとシークレットの value が Claude に見えてしまいます。'| jq' で value を除外してください。" >&2
  echo "例: bws secret list | jq '[.[] | {id, key, organizationId, projectId, creationDate, revisionDate}]'" >&2
  exit 2
fi

exit 0
