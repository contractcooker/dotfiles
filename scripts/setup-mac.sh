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

    # Install 1Password (cask)
    if brew list --cask 1password &> /dev/null; then
        echo "    [SKIP] 1password (already installed)"
    else
        echo "    Installing 1password..."
        brew install --cask 1password
        echo "    [OK] 1password"
    fi
fi

# Step 3: Configure 1Password SSH Agent
echo ""
echo "==> 1Password SSH Agent Setup"
echo ""
echo "    ACTION REQUIRED:"
echo "      1. Open 1Password"
echo "      2. Go to Settings > Developer"
echo "      3. Enable 'Use the SSH Agent'"
echo ""
read -p "    Press Enter when done"
echo "    [OK] 1Password SSH Agent configured"

# Step 4: Install Node.js (via fnm) and Claude Code
echo ""
echo "==> Setting up Node.js and Claude Code"

if brew list fnm &> /dev/null; then
    echo "    [SKIP] fnm (already installed)"
else
    echo "    Installing fnm (Node version manager)..."
    brew install fnm
    echo "    [OK] fnm installed"
fi

# Initialize fnm for this session
eval "$(fnm env --use-on-cd --shell bash)"

# Add fnm to shell profile if not already there
SHELL_PROFILE="$HOME/.zshrc"
if [ -f "$SHELL_PROFILE" ]; then
    if ! grep -q "fnm env" "$SHELL_PROFILE"; then
        echo "" >> "$SHELL_PROFILE"
        echo "# fnm (Node version manager)" >> "$SHELL_PROFILE"
        echo 'eval "$(fnm env --use-on-cd --shell zsh)"' >> "$SHELL_PROFILE"
        echo "    [OK] fnm added to .zshrc"
    else
        echo "    [SKIP] fnm already in .zshrc"
    fi
else
    echo '# fnm (Node version manager)' > "$SHELL_PROFILE"
    echo 'eval "$(fnm env --use-on-cd --shell zsh)"' >> "$SHELL_PROFILE"
    echo "    [OK] .zshrc created with fnm"
fi

# Install Node.js LTS
if fnm list 2>/dev/null | grep -q "lts"; then
    fnm use lts-latest 2>/dev/null
    echo "    [SKIP] Node.js LTS (already installed)"
else
    echo "    Installing Node.js LTS..."
    fnm install --lts
    fnm use lts-latest
    fnm default lts-latest
    echo "    [OK] Node.js LTS installed"
fi

# Install Claude Code
if npm list -g @anthropic-ai/claude-code &> /dev/null; then
    echo "    [SKIP] Claude Code (already installed)"
else
    echo "    Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
    echo "    [OK] Claude Code installed"
fi

# Step 5: Authenticate GitHub CLI
echo ""
echo "==> Authenticating GitHub CLI"

if gh auth status &> /dev/null; then
    echo "    [SKIP] Already authenticated with GitHub"
else
    echo "    Opening browser for GitHub authentication..."
    gh auth login --web --git-protocol ssh --skip-ssh-key
    echo "    [OK] GitHub authenticated"
fi

# Step 6: Clone config repo (private - needs auth first)
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

# Step 7: Configure Git from config
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

# Step 8: Clone dotfiles and other repos
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

# Step 9: SSH config for 1Password
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

# Step 10: Install full Brewfile (optional)
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
