#!/bin/bash
# macOS Development Environment Setup
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/contractcooker/dotfiles/main/scripts/setup-mac.sh | bash
#
# Or if you've already cloned dotfiles:
#   ./setup-mac.sh

set -e

SKIP_PACKAGES=false
SKIP_GIT_CONFIG=false
SKIP_REPOS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-packages) SKIP_PACKAGES=true; shift ;;
        --skip-git-config) SKIP_GIT_CONFIG=true; shift ;;
        --skip-repos) SKIP_REPOS=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

REPOS_ROOT="$HOME/repos"
CONFIG_PATH="$REPOS_ROOT/dev/config"
DOTFILES_PATH="$REPOS_ROOT/dev/dotfiles"

echo ""
echo "======================================"
echo "  macOS Development Setup"
echo "======================================"

# Step 1: Install Homebrew
echo ""
echo "==> Checking Homebrew"

if command -v brew &> /dev/null; then
    echo "    [SKIP] Homebrew (already installed)"
else
    echo "    Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for this session
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    echo "    [OK] Homebrew installed"
fi

# Step 2: Install core packages
if [ "$SKIP_PACKAGES" = false ]; then
    echo ""
    echo "==> Installing core packages"

    packages=(git gh jq)
    for pkg in "${packages[@]}"; do
        if brew list "$pkg" &> /dev/null; then
            echo "    [SKIP] $pkg (already installed)"
        else
            echo "    Installing $pkg..."
            brew install "$pkg"
            echo "    [OK] $pkg"
        fi
    done
fi

# Step 3: Authenticate GitHub CLI
echo ""
echo "==> Checking GitHub CLI authentication"

if gh auth status &> /dev/null; then
    echo "    [SKIP] Already authenticated with GitHub"
else
    echo "    Opening browser for GitHub authentication..."
    gh auth login --web --git-protocol ssh
    echo "    [OK] GitHub authenticated"
fi

# Step 4: Clone config repo (private - needs auth first)
echo ""
echo "==> Setting up config"

mkdir -p "$REPOS_ROOT/dev"

if [ ! -d "$CONFIG_PATH" ]; then
    echo "    Cloning config..."
    cd "$REPOS_ROOT/dev"
    gh repo clone config
    echo "    [OK] config cloned"
else
    echo "    [SKIP] config (already exists)"
fi

# Step 5: Configure Git from config
if [ "$SKIP_GIT_CONFIG" = false ]; then
    echo ""
    echo "==> Configuring Git"

    if [ -f "$CONFIG_PATH/identity.json" ]; then
        GIT_NAME=$(jq -r '.name' "$CONFIG_PATH/identity.json")
        GIT_EMAIL=$(jq -r '.email' "$CONFIG_PATH/identity.json")

        git config --global user.name "$GIT_NAME"
        git config --global user.email "$GIT_EMAIL"
        git config --global init.defaultBranch main

        echo "    [OK] Git configured"
        echo "    user.name: $GIT_NAME"
        echo "    user.email: $GIT_EMAIL"
        echo "    init.defaultBranch: main"
    else
        echo "    [ERROR] identity.json not found in config repo"
        exit 1
    fi
fi

# Step 6: Clone dotfiles and other repos
if [ "$SKIP_REPOS" = false ]; then
    echo ""
    echo "==> Setting up repos"

    # Clone dotfiles if not present
    if [ ! -d "$DOTFILES_PATH" ]; then
        echo "    Cloning dotfiles..."
        cd "$REPOS_ROOT/dev"
        gh repo clone dotfiles
        echo "    [OK] dotfiles cloned"
    else
        echo "    [SKIP] dotfiles (already exists)"
    fi

    # Run clone-repos script (reads from config/repos.json)
    echo "    Running clone-repos.sh..."
    "$DOTFILES_PATH/scripts/clone-repos.sh"
fi

# Step 7: SSH config for 1Password
echo ""
echo "==> SSH Configuration"

SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

mkdir -p "$SSH_DIR"

if [ ! -f "$SSH_CONFIG" ]; then
    if [ -f "$CONFIG_PATH/hosts.json" ]; then
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

# Default settings - 1Password agent for all connections
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
        echo "    [OK] SSH config created"
        echo "    Enable 1Password SSH Agent in 1Password settings to use"
    else
        echo "    [WARN] hosts.json not found, creating minimal SSH config"
        cat > "$SSH_CONFIG" << 'EOF'
# Git services
Host github.com
  HostName github.com
  User git

# Default settings - 1Password agent for all connections
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
        echo "    [OK] SSH config created (minimal)"
    fi
else
    echo "    [SKIP] SSH config (already exists)"
fi

# Step 8: Install full Brewfile (optional)
echo ""
echo "==> Brewfile"

BREWFILE="$DOTFILES_PATH/Brewfile"
if [ -f "$BREWFILE" ]; then
    echo "    To install all packages: brew bundle --file=$BREWFILE"
else
    echo "    [SKIP] Brewfile not found"
fi

# Done
echo ""
echo "======================================"
echo "  Setup Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "  1. Enable 1Password SSH Agent (Settings > Developer > SSH Agent)"
echo "  2. Test SSH: ssh -T git@github.com"
echo "  3. Optional: brew bundle --file=~/repos/dev/dotfiles/Brewfile"
echo ""
echo "Your repos are at: ~/repos/"
