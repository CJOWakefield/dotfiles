ZSH=$HOME/.oh-my-zsh

# Suppress missing completion file errors (e.g., Docker via Docker Desktop)
fpath=(${fpath:#/usr/share/zsh/vendor-completions})

# History configuration
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS    # Don't record duplicates
setopt HIST_FIND_NO_DUPS       # Don't show duplicates when searching
setopt HIST_SAVE_NO_DUPS       # Don't write duplicates to history file
setopt SHARE_HISTORY           # Share history between sessions
setopt EXTENDED_HISTORY        # Add timestamps to history

# You can change the theme with another one from https://github.com/robbyrussell/oh-my-zsh/wiki/themes
ZSH_THEME="robbyrussell"

# Useful oh-my-zsh plugins
# IMPORTANT: Plugin order matters!
# - fzf-tab must load BEFORE autosuggestions and syntax-highlighting
# - syntax-highlighting should be near the end
plugins=(
  git
  gitfast
  last-working-dir
  common-aliases
  ssh-agent
  fzf-tab
  zsh-autosuggestions
  history-substring-search
  zsh-syntax-highlighting
)

# (macOS-only) Prevent Homebrew from reporting
export HOMEBREW_NO_ANALYTICS=1

# Disable warning about insecure completion-dependent directories
ZSH_DISABLE_COMPFIX=true

# Actually load Oh-My-Zsh
source "${ZSH}/oh-my-zsh.sh"
unalias rm # No interactive rm by default (brought by plugins/common-aliases)

# =============================================================================
# Terminal Focus Event Handling (fixes ^[[I appearing in VS Code terminal)
# =============================================================================
# Disable terminal focus reporting to prevent escape sequences leaking through
# This must be done at shell init, before each command, and after each command
_disable_focus_reporting() { printf '\e[?1004l' }
_disable_focus_reporting

# Disable focus reporting before running any command (prevents leak during execution)
preexec_functions+=(_disable_focus_reporting)

# Re-disable after command completes (in case something re-enabled it)
precmd_functions+=(_disable_focus_reporting)

# Bind focus in/out sequences to nothing so they don't print if received during line editing
bindkey -s '\e[I' ''
bindkey -s '\e[O' ''
unalias lt # we need `lt` for https://github.com/localtunnel/localtunnel

# =============================================================================
# PATH Configuration
# =============================================================================
# NOTE: relative entries (./bin, ./node_modules/.bin) intentionally removed —
# CWD-relative PATH allows command hijacking when cd-ing into untrusted repos.
# For per-project node binaries use `npx <cmd>` or direnv (PATH_add ./node_modules/.bin).
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:${PATH}:/usr/local/sbin"

# =============================================================================
# fnm - Fast Node Manager (replaces nvm)
# =============================================================================
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
fi

# =============================================================================
# uv - Python package and environment manager (replaces pyenv/pip)
# =============================================================================
# uv aliases for Python management
alias pyls="uv python list"
alias pyadd="uv add"
alias pyremove="uv remove"
alias pyrun="uv run"
alias pysync="uv sync"
alias pylock="uv lock"

# Create new Python project with uv
uvnew() {
  local name=${1:-.}
  local python=${2:-3.12}
  uv init "$name" --python "$python"
  if [ "$name" != "." ]; then
    cd "$name"
  fi
  echo "Created Python $python project: $name"
}

# Create virtual environment with uv (for non-project dirs)
uvenv() {
  local python=${1:-3.12}
  uv venv --python "$python"
  source .venv/bin/activate
  echo "Created and activated Python $python virtual environment"
}

# Quick pip via uv (faster) — prefer pyadd/pysync over pip habits
alias pip="uv pip"

# =============================================================================
# rbenv - Ruby version manager
# =============================================================================
export PATH="${HOME}/.rbenv/bin:${PATH}"
# Lazy-load rbenv — only runs init when first invoked (saves ~50-100ms per shell)
rbenv() {
  unfunction rbenv
  eval "$(command rbenv init -)"
  rbenv "$@"
}

# =============================================================================
# Modern CLI Tools (Rust-based replacements)
# =============================================================================
# eza - modern ls replacement
if command -v eza &> /dev/null; then
  alias ls="eza --icons --git --group-directories-first"
  alias ll="eza -la --icons --git --group-directories-first"
  alias la="eza -a --icons --git --group-directories-first"
  alias lt="eza --tree --level=2 --icons --git"
  alias lta="eza --tree --level=3 --icons --git -a"
fi

# bat - modern cat replacement (Ubuntu names it batcat)
if command -v batcat &> /dev/null; then
  alias cat="batcat --paging=never"
  alias bat="batcat"
  export MANPAGER="sh -c 'col -bx | batcat -l man -p'"
elif command -v bat &> /dev/null; then
  alias cat="bat --paging=never"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# fd - modern find replacement (Ubuntu names it fdfind)
if command -v fdfind &> /dev/null; then
  alias fd="fdfind"
fi

# ripgrep - modern grep replacement (use 'rg' directly, don't alias grep)
# Aliasing grep breaks scripts that expect standard grep behavior

# zoxide - smarter cd
# Skip in non-interactive shells and Claude Code to avoid warnings
if command -v zoxide &> /dev/null && [[ -z "$CLAUDECODE" ]] && [[ -o interactive ]]; then
  eval "$(zoxide init zsh --cmd cd)"
fi

# =============================================================================
# fzf - Fuzzy finder
# =============================================================================
if command -v fzf &> /dev/null; then
  # Load fzf keybindings and completion
  [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
  [ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh

  # Use fd for fzf (respects .gitignore, faster)
  if command -v fdfind &> /dev/null; then
    export FZF_DEFAULT_COMMAND="fdfind --hidden --strip-cwd-prefix --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fdfind --type=d --hidden --strip-cwd-prefix --exclude .git"
  fi

  # Preview with bat if available
  if command -v batcat &> /dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'batcat -n --color=always --line-range :500 {}'"
  elif command -v bat &> /dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
  fi

  # fzf theme (catppuccin-style)
  export FZF_DEFAULT_OPTS="--height 50% --layout=reverse --border --info=inline"
fi

# =============================================================================
# atuin - SQLite-backed shell history (context-rich, directory/session search)
# =============================================================================
# Must init AFTER fzf so atuin's Ctrl-R binding takes precedence.
# Installed to ~/.atuin/bin; --disable-up-arrow keeps the up arrow as plain
# history (atuin owns Ctrl-R only), preserving history-substring-search on up.
[ -f "$HOME/.atuin/bin/env" ] && source "$HOME/.atuin/bin/env"
if command -v atuin &> /dev/null; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

# =============================================================================
# zsh-autosuggestions Configuration
# =============================================================================
# Accept suggestion with right arrow or end key
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(end-of-line vi-end-of-line vi-add-eol)
# Partial accept with forward-word
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS=(forward-word forward-char vi-forward-word vi-forward-word-end vi-forward-blank-word vi-forward-blank-word-end)
# Use history first, then completion
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# Async mode for better performance
ZSH_AUTOSUGGEST_USE_ASYNC=1
# Suggestion highlight style (subtle gray)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6c7086"

# =============================================================================
# fzf-tab Configuration
# =============================================================================
# Disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# Set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# Set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# Force zsh not to show completion menu, let fzf-tab handle it
zstyle ':completion:*' menu no
# Preview directory contents with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'
# Preview file contents for common commands
zstyle ':fzf-tab:complete:*:*' fzf-preview 'batcat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || eza -la --color=always --icons $realpath 2>/dev/null || echo $realpath'
# Switch between groups with < and >
zstyle ':fzf-tab:*' switch-group '<' '>'
# Minimum completion items to trigger fzf-tab (default: 0)
zstyle ':fzf-tab:*' fzf-min-height 15

# =============================================================================
# Navigation Aliases
# =============================================================================
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# Quick folder size check
alias duf="du -sh *"
alias dua="du -sh .[^.]*"

# =============================================================================
# Git Aliases
# =============================================================================
alias gs="git status"
alias gd="git diff"
alias gca="git commit -am"
alias gc="git checkout"
alias gcb="git checkout -b"
alias gpush="git push"
alias gpull="git pull"
alias gst="git stash"
alias gstp="git stash pop"
alias lg="lazygit"

# =============================================================================
# Directory Shortcuts
# =============================================================================
alias projects='cd ~/code/CJOWakefield/projects'
alias leetcode='cd ~/code/CJOWakefield/projects/leetcode'
alias lw='cd ~/code/CJOWakefield'

# =============================================================================
# Jupyter Shortcuts
# =============================================================================
alias jnb='jupyter notebook'
alias jnbcode='cd ~/code/CJOWakefield/projects && jupyter notebook'
alias jlab="jupyter lab"
alias jlabcode="cd ~/code/CJOWakefield/projects && jupyter lab"
alias jkill="jupyter notebook stop"
alias jlist="jupyter notebook list"

# Convert Jupyter notebooks to other formats
nb2py() {
  jupyter nbconvert --to python "$1"
}

nb2html() {
  jupyter nbconvert --to html "$1"
}

# Create a new data science notebook with template
function jnote() {
    local dir=~/code/CJOWakefield/projects/${1:-.}
    local name=${2:-notebook_$(date +%Y%m%d)}
    mkdir -p "$dir"
    cat > "$dir/$name.ipynb" << 'NOTEBOOK_EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Data Analysis Notebook\n",
    "\n",
    "## Overview\n",
    "- Purpose: \n",
    "- Data source: \n",
    "- Key questions: \n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Standard imports\n",
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "\n",
    "# Display settings\n",
    "pd.set_option('display.max_rows', 100)\n",
    "pd.set_option('display.max_columns', 100)\n",
    "%matplotlib inline\n",
    "plt.style.use('ggplot')\n",
    "plt.rcParams['figure.figsize'] = (12, 8)"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
NOTEBOOK_EOF
    jupyter notebook "$dir/$name.ipynb"
}

# =============================================================================
# System Aliases
# =============================================================================
alias meminfo="free -m -l -t"
alias cpuinfo="lscpu"
alias update="sudo apt update && sudo apt upgrade -y"
alias clean="sudo apt autoremove -y && sudo apt autoclean"

# =============================================================================
# Environment & Locale
# =============================================================================
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export BUNDLER_EDITOR=code
export EDITOR=code
export PYTHONBREAKPOINT=ipdb.set_trace

# =============================================================================
# Terminal Close Cleanup (prevent orphaned Claude/Node sessions)
# =============================================================================
# When a terminal is closed, zsh sends SIGHUP (HUP option, on by default) but
# Node.js/Claude processes may catch and ignore it. This trap sends SIGTERM to
# all direct child processes of this shell on exit, ensuring clean shutdown.
# Scoped to this shell's children only — won't affect other terminals.
trap 'pkill -TERM -P $$ 2>/dev/null' EXIT

# =============================================================================
# PATH Deduplication (clean up duplicate entries)
# =============================================================================
typeset -U PATH path  # Remove duplicates, keep first occurrence

# =============================================================================
# Additional Integrations
# =============================================================================
# direnv - per-project environment management
command -v direnv &> /dev/null && eval "$(direnv hook zsh)"

# Load external aliases
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# Load secrets (credentials, tokens) - NOT version controlled
[[ -f "$HOME/.secrets" ]] && source "$HOME/.secrets"

# bun completions
[ -s "/home/christian/.bun/_bun" ] && source "/home/christian/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
