#!/bin/bash
# focus-ghostty.sh - Claude Code実行中のGhosttyタブにフォーカスを戻す
#
# 仕組み:
#   1. SessionStart時に save-ghostty-tab.sh で現在のタブインデックスを記録
#   2. Stop/Notification時にこのスクリプトが呼ばれ、記録したタブをクリックして戻す
#
# 必要条件:
#   システム設定 > プライバシーとセキュリティ > アクセシビリティ で
#   Ghostty（またはターミナル）にアクセスを許可しておくこと

# stdinからJSONを読み取り
INPUT=$(cat)

# session_idを取得（フォールバック: cwdのハッシュ）
SESSION_ID=$(echo "$INPUT" | grep -o '"session_id" *: *"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
if [[ -z "$SESSION_ID" ]]; then
    CWD=$(echo "$INPUT" | grep -o '"cwd" *: *"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
    SESSION_ID=$(echo "${CWD:-unknown}" | md5 -q 2>/dev/null || echo "default")
fi

STATE_FILE="/tmp/ghostty-tab-state-${SESSION_ID}"

if [[ -f "$STATE_FILE" ]]; then
    SAVED_INDEX=$(cat "$STATE_FILE")
else
    SAVED_INDEX=""
fi

echo "$(date): focus session=$SESSION_ID index=$SAVED_INDEX" >> /tmp/ghostty-hook-debug.log

osascript -e "
on run
    set savedIndex to \"$SAVED_INDEX\"

    tell application \"System Events\"
        tell application process \"Ghostty\"
            set frontmost to true

            if (count of windows) = 0 then return

            perform action \"AXRaise\" of window 1

            -- タブ復帰を試みる
            if savedIndex is not \"\" then
                try
                    set tabIdx to savedIndex as integer
                    set tg to tab group 1 of window 1
                    set tabs to radio buttons of tg
                    if tabIdx > 0 and tabIdx ≤ (count of tabs) then
                        perform action \"AXPress\" of radio button tabIdx of tg
                    end if
                end try
            end if
        end tell
    end tell
end run
"
