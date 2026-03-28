#!/usr/bin/env bash
# Claude Code Statusline
# 4-line display: session info, 5h usage, 7d usage, harness-mem
# Colors: TrueColor gradient (green → yellow → red)

set -euo pipefail

input=$(cat)

# ── Colors (Kanagawa Wave base) ──
GRAY="\033[38;2;114;113;105m"    # fujiGray    #727169
BLUE="\033[38;2;126;156;216m"    # crystalBlue #7E9CD8
CYAN="\033[38;2;127;180;202m"    # springBlue  #7FB4CA
ORANGE="\033[38;2;255;160;102m"  # surimiOrange #FFA066
GREEN="\033[38;2;152;187;108m"   # springGreen #98BB6C
YELLOW="\033[38;2;230;195;132m"  # carpYellow  #E6C384
RED="\033[38;2;255;93;98m"       # peachRed    #FF5D62
RESET="\033[0m"

# ── TrueColor gradient (springGreen → yellow → red) ──
# 0%: rgb(152,187,108) = Kanagawa springGreen (same as +lines color)
# 50%: rgb(255,187,108) = warm yellow
# 100%: rgb(255,0,60) = deep red
gradient_color() {
  local pct=$1
  if (( pct < 50 )); then
    # r: 152 → 255 as pct goes 0 → 50
    local r=$(( 152 + pct * 103 / 50 ))
    printf '\033[38;2;%d;187;108m' "$r"
  else
    # g: 187 → 0, b: 108 → 60 as pct goes 50 → 100
    local g=$(( 187 - (pct - 50) * 187 / 50 ))
    local b=$(( 108 - (pct - 50) * 48 / 50 ))
    (( g < 0 )) && g=0
    (( b < 60 )) && b=60
    printf '\033[38;2;255;%d;%dm' "$g" "$b"
  fi
}

# ── Fine Bar + Gradient (█ filled, ░ dimmed dot pattern for empty) ──
progress_bar() {
  local pct=$1
  local width=10
  (( pct < 0 )) && pct=0
  (( pct > 100 )) && pct=100

  # Same logic as Python reference: filled = pct * width / 100
  local filled_x1000=$(( pct * width * 10 ))
  local full=$(( filled_x1000 / 1000 ))
  local frac_part=$(( filled_x1000 % 1000 ))
  local frac=$(( frac_part * 8 / 1000 ))

  # Gradient RGB (same as gradient_color)
  local r g b
  if (( pct < 50 )); then
    r=$(( 152 + pct * 103 / 50 ))
    g=187; b=108
  else
    r=255
    g=$(( 187 - (pct - 50) * 187 / 50 ))
    b=$(( 108 - (pct - 50) * 48 / 50 ))
    (( g < 0 )) && g=0
    (( b < 60 )) && b=60
  fi

  local blocks=(" " "▏" "▎" "▍" "▌" "▋" "▊" "▉" "█")
  local bar=""

  # Filled: █ with gradient foreground
  bar+="\033[38;2;${r};${g};${b}m"
  for ((i=0; i<full; i++)); do bar+="█"; done

  # Partial + empty (only if not fully filled)
  if (( full < width )); then
    if (( frac > 0 )); then
      bar+="${blocks[$frac]}"
      local empty_count=$(( width - full - 1 ))
    else
      local empty_count=$(( width - full ))
    fi
    # Empty: ░ with dimmed gradient color (1/3 brightness)
    bar+="\033[38;2;$((r/3));$((g/3));$((b/3))m"
    for ((i=0; i<empty_count; i++)); do bar+="░"; done
  fi

  bar+="\033[0m"
  printf '%b' "$bar"
}

# ── Line 1: Session info ──
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // ""')
session_id=$(echo "$input" | jq -r '.session_id // ""')

# Context percentage (integer)
ctx_int=0
if [ -n "$used_pct" ]; then
  printf -v ctx_int "%.0f" "$used_pct" 2>/dev/null || ctx_int="${used_pct%%.*}"
fi
ctx_color=$(gradient_color "$ctx_int")

# Git branch & repo name
git_branch=""
repo_name=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  repo_name=$(basename "$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)
fi

sep="${GRAY} | ${RESET}"

line1="🤖 ${CYAN}${model}${RESET}${sep}${ctx_color}📊 ${ctx_int}%${RESET}${sep}✏️ ${GREEN}+${lines_added}${RESET}/${RED}-${lines_removed}${RESET}"
if [ -n "$repo_name" ]; then
  line1+="${sep}📁 ${BLUE}${repo_name}${RESET}"
fi
if [ -n "$git_branch" ]; then
  line1+="${sep}🔀 ${ORANGE}${git_branch}${RESET}"
fi

# ── Rate limits from stdin ──
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
five_reset_epoch=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty' 2>/dev/null)
seven_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' 2>/dev/null)
seven_reset_epoch=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty' 2>/dev/null)

# Format reset time for 5h window: "Resets 5pm (Asia/Tokyo)"
format_5h_reset() {
  local epoch=$1
  [ -z "$epoch" ] && return
  LC_ALL=en_US.UTF-8 TZ="Asia/Tokyo" date -r "$epoch" +"Resets %-l%p (Asia/Tokyo)" 2>/dev/null | sed 's/AM/am/;s/PM/pm/'
}

# Format reset time for 7d window: "Resets Mar 6 at 12pm (Asia/Tokyo)"
format_7d_reset() {
  local epoch=$1
  [ -z "$epoch" ] && return
  LC_ALL=en_US.UTF-8 TZ="Asia/Tokyo" date -r "$epoch" +"Resets %b %-d at %-l%p (Asia/Tokyo)" 2>/dev/null | sed 's/AM/am/;s/PM/pm/'
}

line2=""
line3=""

if [ -n "$five_pct" ]; then
  printf -v five_int "%.0f" "$five_pct" 2>/dev/null || five_int="${five_pct%%.*}"
  five_color=$(gradient_color "$five_int")
  five_bar=$(progress_bar "$five_int")
  five_reset_str=""
  if [ -n "$five_reset_epoch" ]; then
    five_reset_str=$(format_5h_reset "$five_reset_epoch")
  fi
  line2="${five_color}🕐 5h${RESET}  ${five_bar}  ${five_color}${five_int}%${RESET}"
  if [ -n "$five_reset_str" ]; then
    line2+="  ${GRAY}${five_reset_str}${RESET}"
  fi
fi

if [ -n "$seven_pct" ]; then
  printf -v seven_int "%.0f" "$seven_pct" 2>/dev/null || seven_int="${seven_pct%%.*}"
  seven_color=$(gradient_color "$seven_int")
  seven_bar=$(progress_bar "$seven_int")
  seven_reset_str=""
  if [ -n "$seven_reset_epoch" ]; then
    seven_reset_str=$(format_7d_reset "$seven_reset_epoch")
  fi
  line3="${seven_color}📅 7d${RESET}  ${seven_bar}  ${seven_color}${seven_int}%${RESET}"
  if [ -n "$seven_reset_str" ]; then
    line3+="  ${GRAY}${seven_reset_str}${RESET}"
  fi
fi

# ── Line 4: harness-mem status ──
line4=""
hmem_health=$(curl -sf --max-time 1 "http://127.0.0.1:37888/health" 2>/dev/null || true)
if [ -n "$hmem_health" ]; then
  hmem_ok=$(echo "$hmem_health" | jq -r '.ok // false' 2>/dev/null)
  if [ "$hmem_ok" = "true" ]; then
    # Fetch latest observation for current session
    hmem_title=""
    hmem_ago=""
    hmem_created=""
    hmem_has_session_data=false

    if [ -n "$session_id" ]; then
      # Search current session to get latest_interaction from meta
      hmem_search=$(curl -sf --max-time 1 -X POST "http://127.0.0.1:37888/v1/search" \
        -H "Content-Type: application/json" \
        -d "{\"query\":\"*\",\"session_id\":\"${session_id}\",\"limit\":1}" 2>/dev/null || true)
      if [ -n "$hmem_search" ]; then
        hmem_count=$(echo "$hmem_search" | jq -r '.meta.count // 0' 2>/dev/null)
        if [ "$hmem_count" -gt 0 ] 2>/dev/null; then
          hmem_has_session_data=true
          # Use latest_interaction.response for the most recent entry
          hmem_title=$(echo "$hmem_search" | jq -r '.meta.latest_interaction.response.title // .items[0].title // ""' 2>/dev/null)
          hmem_created=$(echo "$hmem_search" | jq -r '.meta.latest_interaction.response.created_at // .items[0].created_at // ""' 2>/dev/null)
          hmem_content=""
          # For generic titles, use content summary instead
          if [ "$hmem_title" = "assistant_response" ] || [ "$hmem_title" = "user_prompt" ]; then
            hmem_content=$(echo "$hmem_search" | jq -r '.meta.latest_interaction.response.content // .items[0].content // ""' 2>/dev/null)
            if [ -n "$hmem_content" ]; then
              hmem_title=$(printf '%s' "$hmem_content" | sed 's/^#* *//' | sed 's/\*\*//g' | sed 's/`//g' | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//')
            fi
          fi
        fi
      fi
    fi

    # Calculate time ago
    if [ -n "$hmem_created" ]; then
      hmem_epoch=$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "${hmem_created%%.*}" +%s 2>/dev/null || true)
      if [ -n "$hmem_epoch" ]; then
        now_epoch=$(date +%s)
        diff_sec=$(( now_epoch - hmem_epoch ))
        if (( diff_sec < 60 )); then
          hmem_ago="${diff_sec}s ago"
        elif (( diff_sec < 3600 )); then
          hmem_ago="$(( diff_sec / 60 ))m ago"
        elif (( diff_sec < 86400 )); then
          hmem_ago="$(( diff_sec / 3600 ))h ago"
        else
          hmem_ago="$(( diff_sec / 86400 ))d ago"
        fi
      fi
    fi

    # Truncate title to 40 chars
    if [ -n "$hmem_title" ] && [ ${#hmem_title} -gt 40 ]; then
      hmem_title="${hmem_title:0:39}…"
    fi

    # Build line
    line4="${GREEN}🧠 mem ✓${RESET}"
    if [ "$hmem_has_session_data" = true ]; then
      if [ -n "$hmem_title" ]; then
        line4+="  ${CYAN}${hmem_title}${RESET}"
      fi
      if [ -n "$hmem_ago" ]; then
        line4+="  ${GRAY}${hmem_ago}${RESET}"
      fi
    else
      line4+="  ${YELLOW}no captures in current session${RESET}"
    fi
  else
    line4="${RED}🧠 mem ✗ unhealthy${RESET}"
  fi
else
  line4="${RED}🧠 mem ✗ offline${RESET}"
fi

# ── Output ──
printf '%b' "$line1"
if [ -n "$line2" ]; then
  printf '\n%b' "$line2"
fi
if [ -n "$line3" ]; then
  printf '\n%b' "$line3"
fi
if [ -n "$line4" ]; then
  printf '\n%b' "$line4"
fi
