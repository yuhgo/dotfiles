#!/usr/bin/env bash
# Claude Code Statusline
# 3-line display: session info, 5h usage, 7d usage
# Colors: Kanagawa Wave palette

set -euo pipefail

input=$(cat)

# ── Colors (Kanagawa Wave) ──
GREEN="\033[38;2;152;187;108m"   # springGreen #98BB6C
YELLOW="\033[38;2;230;195;132m"  # carpYellow  #E6C384
RED="\033[38;2;255;93;98m"       # peachRed    #FF5D62
GRAY="\033[38;2;114;113;105m"    # fujiGray    #727169
BLUE="\033[38;2;126;156;216m"    # crystalBlue #7E9CD8
CYAN="\033[38;2;127;180;202m"    # springBlue  #7FB4CA
ORANGE="\033[38;2;255;160;102m"  # surimiOrange #FFA066
RESET="\033[0m"

color_for_pct() {
  local pct=$1
  if (( pct >= 80 )); then
    printf '%s' "$RED"
  elif (( pct >= 50 )); then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$BLUE"
  fi
}

# ── Progress bar (10 segments) ──
progress_bar() {
  local pct=$1
  local filled=$(( pct / 10 ))
  local empty=$(( 10 - filled ))
  local color
  color=$(color_for_pct "$pct")
  local bar=""
  bar+=$(printf '%b' "$color")
  for ((i=0; i<filled; i++)); do bar+="▆"; done
  bar+=$(printf '%b' "$GRAY")
  for ((i=0; i<empty; i++)); do bar+="▆"; done
  bar+=$(printf '%b' "$RESET")
  printf '%s' "$bar"
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
ctx_color=$(color_for_pct "$ctx_int")

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

# ── Usage API (OAuth, cached 360s) ──
CACHE_FILE="/tmp/claude-usage-cache.json"
CACHE_TTL=360

fetch_usage() {
  # Get OAuth token from macOS Keychain
  local token
  token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null || true)
  if [ -z "$token" ]; then
    return 1
  fi

  # Token is stored as JSON with nested structure
  local access_token
  access_token=$(echo "$token" | jq -r '.claudeAiOauth.accessToken // .accessToken // .access_token // empty' 2>/dev/null || true)
  if [ -z "$access_token" ]; then
    return 1
  fi

  local response
  response=$(curl -sf --max-time 5 \
    -H "Authorization: Bearer ${access_token}" \
    -H "anthropic-beta: oauth-2025-04-20" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null) || return 1

  # Write cache with timestamp
  local now
  now=$(date +%s)
  echo "$response" | jq --arg ts "$now" '. + {cached_at: ($ts | tonumber)}' > "$CACHE_FILE" 2>/dev/null
  echo "$response"
}

get_usage() {
  local now
  now=$(date +%s)

  # Check cache
  if [ -f "$CACHE_FILE" ]; then
    local cached_at
    cached_at=$(jq -r '.cached_at // 0' "$CACHE_FILE" 2>/dev/null || echo "0")
    local age=$(( now - cached_at ))
    if (( age < CACHE_TTL )); then
      jq -r 'del(.cached_at)' "$CACHE_FILE" 2>/dev/null
      return 0
    fi
  fi

  fetch_usage
}

# Convert ISO 8601 to epoch seconds (macOS compatible)
iso_to_epoch() {
  local iso_time=$1
  local stripped="${iso_time%%.*}"
  TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null || echo ""
}

# Format reset time for 5h window: "Resets 5pm (Asia/Tokyo)"
format_5h_reset() {
  local iso_time=$1
  local epoch
  epoch=$(iso_to_epoch "$iso_time")
  [ -z "$epoch" ] && return
  LC_ALL=en_US.UTF-8 TZ="Asia/Tokyo" date -r "$epoch" +"Resets %-l%p (Asia/Tokyo)" 2>/dev/null | sed 's/AM/am/;s/PM/pm/'
}

# Format reset time for 7d window: "Resets Mar 6 at 12pm (Asia/Tokyo)"
format_7d_reset() {
  local iso_time=$1
  local epoch
  epoch=$(iso_to_epoch "$iso_time")
  [ -z "$epoch" ] && return
  LC_ALL=en_US.UTF-8 TZ="Asia/Tokyo" date -r "$epoch" +"Resets %b %-d at %-l%p (Asia/Tokyo)" 2>/dev/null | sed 's/AM/am/;s/PM/pm/'
}

line2=""
line3=""

usage_json=$(get_usage 2>/dev/null || true)

if [ -n "$usage_json" ]; then
  five_util=$(echo "$usage_json" | jq -r '.five_hour.utilization // empty' 2>/dev/null)
  five_reset=$(echo "$usage_json" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
  seven_util=$(echo "$usage_json" | jq -r '.seven_day.utilization // empty' 2>/dev/null)
  seven_reset=$(echo "$usage_json" | jq -r '.seven_day.resets_at // empty' 2>/dev/null)

  if [ -n "$five_util" ]; then
    printf -v five_int "%.0f" "$five_util" 2>/dev/null || five_int="${five_util%%.*}"
    five_color=$(color_for_pct "$five_int")
    five_bar=$(progress_bar "$five_int")
    five_reset_str=""
    if [ -n "$five_reset" ]; then
      five_reset_str=$(format_5h_reset "$five_reset")
    fi
    line2="${five_color}🕐 5h${RESET}  ${five_bar}  ${five_color}${five_int}%${RESET}"
    if [ -n "$five_reset_str" ]; then
      line2+="  ${GRAY}${five_reset_str}${RESET}"
    fi
  fi

  if [ -n "$seven_util" ]; then
    printf -v seven_int "%.0f" "$seven_util" 2>/dev/null || seven_int="${seven_util%%.*}"
    seven_color=$(color_for_pct "$seven_int")
    seven_bar=$(progress_bar "$seven_int")
    seven_reset_str=""
    if [ -n "$seven_reset" ]; then
      seven_reset_str=$(format_7d_reset "$seven_reset")
    fi
    line3="${seven_color}📅 7d${RESET}  ${seven_bar}  ${seven_color}${seven_int}%${RESET}"
    if [ -n "$seven_reset_str" ]; then
      line3+="  ${GRAY}${seven_reset_str}${RESET}"
    fi
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
