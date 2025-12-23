#!/bin/zsh
# Configure development environment
#
# Standalone script for re-configuring dev tools.
# This is called by setup-mac.sh but can also be run independently.
#
# What it does:
#   - Node.js via fnm
#   - Claude Code
#   - Python via uv
#   - Git identity (from config/identity.json)
#   - SSH config (from config/hosts.json)
#
# Usage:
#   ./configure-dev.sh

set -e

REPOS_ROOT="$HOME/repos"
CONFIG_PATH="$REPOS_ROOT/dev/config"
DOTFILES_PATH="$REPOS_ROOT/dev/dotfiles"

echo ""
echo "======================================"
echo "  Dev Environment Configuration"
echo "======================================"

# -----------------------------------------------------------------------------
# Node.js via fnm
# -----------------------------------------------------------------------------
echo ""
echo "==> Node.js (fnm)"

if ! command -v fnm &> /dev/null; then
    echo "    ⚠ fnm not installed (brew install fnm)"
else
    eval "$(fnm env --use-on-cd --shell zsh)"

    if fnm list 2>/dev/null | grep -q "lts"; then
        fnm use lts-latest 2>/dev/null || true
        echo "    ✓ Node.js LTS"
    else
        echo "    Installing Node.js LTS..."
        fnm install --lts
        fnm use lts-latest
        fnm default lts-latest
    fi
fi

# -----------------------------------------------------------------------------
# Claude Code
# -----------------------------------------------------------------------------
echo ""
echo "==> Claude Code"

if command -v node &> /dev/null; then
    if command -v claude &> /dev/null; then
        echo "    ✓ Claude Code installed"
    else
        echo "    Installing Claude Code..."
        npm install -g @anthropic-ai/claude-code
    fi

    # Configure Claude settings
    CLAUDE_DIR="$HOME/.claude"
    CLAUDE_SETTINGS="$CLAUDE_DIR/CLAUDE.md"
    CLAUDE_SOURCE="$DOTFILES_PATH/claude/global.md"
    mkdir -p "$CLAUDE_DIR"
    if [[ -f "$CLAUDE_SOURCE" ]]; then
        if [[ ! -f "$CLAUDE_SETTINGS" ]]; then
            cp "$CLAUDE_SOURCE" "$CLAUDE_SETTINGS"
            echo "    ✓ Claude settings configured"
        elif diff -q "$CLAUDE_SOURCE" "$CLAUDE_SETTINGS" &>/dev/null; then
            echo "    ✓ Claude settings up to date"
        else
            echo "    ⚠ Claude settings differ (keeping local)"
        fi
    fi
else
    echo "    ⚠ Node.js not available"
fi

# -----------------------------------------------------------------------------
# Python via uv
# -----------------------------------------------------------------------------
echo ""
echo "==> Python (uv)"

if ! command -v uv &> /dev/null; then
    echo "    ⚠ uv not installed (brew install uv)"
else
    if uv python list --only-installed 2>/dev/null | grep -q "cpython"; then
        echo "    ✓ Python installed"
    else
        echo "    Installing Python..."
        uv python install
    fi

    if uv tool list 2>/dev/null | grep -q "pre-commit"; then
        echo "    ✓ pre-commit installed"
    else
        echo "    Installing pre-commit..."
        uv tool install pre-commit
    fi
fi

# -----------------------------------------------------------------------------
# Git identity
# -----------------------------------------------------------------------------
echo ""
echo "==> Git Configuration"

if [[ -f "$CONFIG_PATH/identity.json" ]]; then
    GIT_NAME=$(jq -r '.name' "$CONFIG_PATH/identity.json")
    GIT_EMAIL=$(jq -r '.email' "$CONFIG_PATH/identity.json")

    cat > "$HOME/.gitconfig.local" << EOF
# Local git identity (not version controlled)
# Generated from config/identity.json

[user]
    name = $GIT_NAME
    email = $GIT_EMAIL
EOF
    echo "    ✓ Git identity: $GIT_NAME <$GIT_EMAIL>"
else
    echo "    ⚠ identity.json not found"
fi

# -----------------------------------------------------------------------------
# SSH config
# -----------------------------------------------------------------------------
echo ""
echo "==> SSH Configuration"

SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [[ -f "$SSH_CONFIG" ]]; then
    echo "    ✓ SSH config exists"
    echo "    To regenerate, delete ~/.ssh/config and re-run"
else
    if [[ -f "$CONFIG_PATH/hosts.json" ]]; then
        HOMELAB_DOMAIN=$(jq -r '.homelab_domain' "$CONFIG_PATH/hosts.json")
        HOMELAB_USER=$(jq -r '.homelab_user' "$CONFIG_PATH/hosts.json")

        cat > "$SSH_CONFIG" << EOF
# Git services
Host github.com
  HostName github.com
  User git

# Homelab servers
Host *.$HOMELAB_DOMAIN
  User $HOMELAB_USER

# Default - 1Password SSH agent
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
        echo "    ✓ SSH config created"
    else
        cat > "$SSH_CONFIG" << 'EOF'
# Git services
Host github.com
  HostName github.com
  User git

# Default - 1Password SSH agent
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
        echo "    ✓ SSH config created (minimal)"
    fi
    chmod 600 "$SSH_CONFIG"
fi

echo ""
echo "======================================"
echo "  Done"
echo "======================================"
echo ""
