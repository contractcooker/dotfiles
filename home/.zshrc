# =============================================================================
# .zshrc - Zsh Configuration
# =============================================================================
# This file is symlinked from ~/repos/dev/dotfiles/home/.zshrc
# Edit there, not here.

# -----------------------------------------------------------------------------
# Path
# -----------------------------------------------------------------------------

# uv tools (Python CLI apps like pre-commit)
export PATH="$HOME/.local/bin:$PATH"

# Homebrew (Apple Silicon)
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# -----------------------------------------------------------------------------
# Version Managers
# -----------------------------------------------------------------------------

# fnm (Node.js version manager)
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd --shell zsh)"
fi

# -----------------------------------------------------------------------------
# Prompt
# -----------------------------------------------------------------------------

# Starship prompt (https://starship.rs)
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# -----------------------------------------------------------------------------
# Plugins
# -----------------------------------------------------------------------------

# Syntax highlighting (must be sourced before autosuggestions)
if [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Autosuggestions
if [[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# List files
alias ll="ls -lah"
alias la="ls -la"

# Git shortcuts
alias gs="git status"
alias gd="git diff"
alias gl="git log --oneline -20"
alias gp="git pull"

# Safety
alias rm="rm -i"
alias mv="mv -i"
alias cp="cp -i"

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Search Gmail
gmail() {
    ~/repos/personal/gmail-search/venv/bin/python ~/repos/personal/gmail-search/search.py "$@"
}

# -----------------------------------------------------------------------------
# Local overrides (not version controlled)
# -----------------------------------------------------------------------------

# Source local config if it exists (for machine-specific settings)
if [[ -f ~/.zshrc.local ]]; then
    source ~/.zshrc.local
fi
