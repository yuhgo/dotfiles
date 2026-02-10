#!/bin/bash
# save-ghostty-tab.sh - SessionStart時に現在アクティブなGhosttyタブのインデックスを保存する
#
# Claude Codeのhooksの SessionStart イベントで呼ばれる。
# 保存されたインデックスは focus-ghostty.sh がタブ復帰に使う。

# stdinからJSONを読み取り
INPUT=$(cat)

# session_idを取得（フォールバック: cwdのハッシュ）
SESSION_ID=$(echo "$INPUT" | grep -o '"session_id" *: *"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
if [[ -z "$SESSION_ID" ]]; then
    CWD=$(echo "$INPUT" | grep -o '"cwd" *: *"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
    SESSION_ID=$(echo "${CWD:-unknown}" | md5 -q 2>/dev/null || echo "default")
fi

STATE_FILE="/tmp/ghostty-tab-state-${SESSION_ID}"

# 現在アクティブなタブのインデックスを取得
ACTIVE_INDEX=$(osascript -e '
tell application "System Events"
    tell application process "Ghostty"
        if (count of windows) = 0 then return ""
        try
            set tg to tab group 1 of window 1
            set tabs to radio buttons of tg
            set idx to 1
            repeat with t in tabs
                if (value of t) is true then
                    return idx as text
                end if
                set idx to idx + 1
            end repeat
        end try
        return ""
    end tell
end tell
' 2>/dev/null)

echo "$(date): save session=$SESSION_ID index=$ACTIVE_INDEX" >> /tmp/ghostty-hook-debug.log

if [[ -n "$ACTIVE_INDEX" ]]; then
    echo "$ACTIVE_INDEX" > "$STATE_FILE"
fi
