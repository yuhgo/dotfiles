# Starship
eval "$(starship init zsh)"

## zsh-completions, zsh-autosuggestions
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
  source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  autoload -Uz compinit && compinit
fi

# 下記を追記する
export GOPATH=$HOME
export PATH=$PATH:$GOPATH/bin

# ghq, fzf関連の設定
function g () {
  local selected_dir=$(ghq list -p | fzf --preview 'ls -la --color=always {}' --preview-window=right:40%)
  if [ -n "$selected_dir" ]; then
    cd ${selected_dir}
  fi
}

## General
alias c='clear'
alias cs='cursor'
alias ca='cursor-agent'
# claude コマンドのラッパー関数
# デフォルトで --dangerously-skip-permissions を付与
# --safe オプションで無効化可能
function claude() {
  local skip_permissions=true
  local args=()
  for arg in "$@"; do
    if [[ "$arg" == "--safe" ]]; then
      skip_permissions=false
    else
      args+=("$arg")
    fi
  done
  if $skip_permissions; then
    command claude --dangerously-skip-permissions "${args[@]}"
  else
    command claude "${args[@]}"
  fi
}
alias ccc='cs ~/.claude'
alias kf='keifu'
alias yzi='yazi'
alias yz='yazi'
alias oc='opencode'

# Ghostty設定ファイルをCursorで開く
# Library/Application\ Support/com.mitchellh.ghostty/config
function gt() {
  if [[ "$1" == "-d" ]]; then
    cursor ~/Library/Application\ Support/com.mitchellh.ghostty
  else
    cursor ~/Library/Application\ Support/com.mitchellh.ghostty/config
  fi
}
function ghostty() {
  cursor ~/Library/Application\ Support/com.mitchellh.ghostty/config
}

# rmをtrashに置き換え（Coding Agent安全対策）
rm() {
  while [[ "$1" == -* ]]; do
    shift
  done
  command trash "$@"
}

alias u='cd ..'
alias 2root='cd ~'
alias 2dev='cd /Users/yamamotoyugo/Documents/develop'
alias 2g='cd ~/ghq'
alias 2claude='cd ~/.claude'
# alias g='ghq'

## Karabina
alias keymac='"/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli" --select-profile "Mac"'
alias keyball='"/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli" --select-profile "KBL39"'

## JetBrains
alias ws='open -na "WebStorm.app" --args "$@"'
export PATH="$HOME/.volta/bin:$PATH"

## Shopify
# alias sh='shopify'

## pnpm
alias pn='pnpm'
alias p='pnpm'
alias px='pnpm dlx'

## Docker
alias dcb='docker-compose build'
alias dcu='docker-compose up -d'
alias dcd='docker-compose down'
alias dcdu='dcd && dcu'
alias dce='docker-compose exec'
alias dcl='docker-compose logs'
# alias docker-compose='docker compose'
## ALOALO用
alias dclf='docker-compose logs -f aloalo-pwa-frontend-dev'
alias dclb='docker-compose logs -f aloalo-pwa-backend-dev'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# bun completions
[ -s "/Users/yamamotoyugo/.bun/_bun" ] && source "/Users/yamamotoyugo/.bun/_bun"
export PATH="/Users/yamamotoyugo/.bun/bin:$PATH"

# export TERM=xterm-color256
# vim/neovim
alias vi='nvim'
alias vim='nvim'
alias nvm='nvim'
alias nv='nvim'

# gitコマンド
alias lg='lazygit'
alias gst='git status'
alias ga='git add'
alias gm='git commit -m'
alias gmn='git commit -n -m'
alias gb='git branch'
alias gc='git checkout'
alias gd='git diff'
alias gcmain='git checkout main'
alias gp='git pull'
alias gpmain='git pull origin main'
alias gw='git worktree'

## shopify alias
alias spdev='shopify theme dev --store https://dev-farmin.myshopify.com/ '

# コマンドの履歴を表示
alias his='(){history $1 $2}'

## direnv
export EDITOR='/usr/local/bin/cursor'
eval "$(direnv hook zsh)"
eval "$(mise activate zsh)"
export OTEL_EXPORTER_OTLP_PROTOCOL=http/json

# ===================================
# SSH 関連の設定
# ===================================
# SSH Agent の自動設定
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)" > /dev/null
fi

# macOS の場合、キーチェーンからキーを自動読み込み
ssh-add --apple-load-keychain 2>/dev/null
export PATH="$HOME/.local/bin:$PATH"

# Claude Code 自動更新を無効化
export DISABLE_AUTOUPDATE=1

export PATH="$HOME/.local/bin:$PATH"

# brew版claude codeを優先
export PATH="/opt/homebrew/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/yamamotoyugo/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Added by Antigravity
export PATH="/Users/yamamotoyugo/.antigravity/antigravity/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

alias claude-mem='bun "/Users/yamamotoyugo/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'

# Homebrew auto-update check を無効化
export HOMEBREW_NO_AUTO_UPDATE=1

# マシン固有の設定（秘密情報など）を読み込む
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

