#!/bin/zsh
# macOS Development Environment Setup
#
# Optimized order:
#   1. Homebrew           - foundation
#   2. Profile selection  - determines package categories
#   3. 1Password          - enables all auth
#   4. 1Password SSH      - configure agent
#   5. Core CLI tools     - git, gh, jq, gum, fnm
#   6. GitHub CLI auth    - via SSH
#   7. Clone repos        - config + dotfiles
#   8. Link dotfiles      - shell/git config
#   9. Node + Claude      - troubleshooting available!
#   10. Git + SSH config  - from config repo
#   11. Python/uv         - dev tools
#   12. Clone all repos   - everything ready
#   13. Optional packages - interactive
#   14. Dropbox           - file sync (skipped for Server)
#   15. macOS prefs       - cosmetic
#
# Profiles:
#   Personal - base, desktop, dev, gaming, personal, browser, communication, utility
#   Work     - base, desktop, dev, browser, communication, utility
#   Server   - base only (CLI tools)
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/contractcooker/dotfiles/main/scripts/setup-mac.sh | zsh
#   ./setup-mac.sh                      # Interactive
#   ./setup-mac.sh --profile personal   # Use specific profile
#   ./setup-mac.sh --all                # Non-interactive, all packages

set -e

REPOS_ROOT="$HOME/repos"
CONFIG_PATH="$REPOS_ROOT/dev/config"
DOTFILES_PATH="$REPOS_ROOT/dev/dotfiles"
SCRIPT_DIR="$DOTFILES_PATH/scripts"

# Parse arguments
INSTALL_ALL=false
PROFILE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --all) INSTALL_ALL=true; shift ;;
        --profile)
            PROFILE="${2:u}"  # Uppercase
            shift 2
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo ""
echo "======================================"
echo "  macOS Development Setup"
echo "======================================"

# =============================================================================
# 1. HOMEBREW
# =============================================================================
echo ""
echo "==> [1/15] Homebrew"

if command -v brew &> /dev/null; then
    echo "    ✓ Already installed"
else
    echo "    Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew is in PATH for this session
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# =============================================================================
# 2. PROFILE SELECTION
# =============================================================================
echo ""
echo "==> [2/15] Profile Selection"

# Install gum if needed for interactive selection
if ! command -v gum &> /dev/null; then
    echo "    Installing gum for interactive menus..."
    brew install gum
fi

if [[ -z "$PROFILE" ]]; then
    if command -v gum &> /dev/null; then
        SELECTED=$(printf "Personal - Full setup with personal apps, gaming optional\nWork - Work-focused, no gaming or personal apps\nServer - CLI only, base packages" | gum choose --header "Select machine profile:")
        PROFILE="${SELECTED%% *}"
        PROFILE="${PROFILE:u}"
    else
        echo "    Select profile:"
        echo "      1. Personal - Full setup"
        echo "      2. Work - Work-focused"
        echo "      3. Server - CLI only"
        read "choice?    Enter choice [1]: "
        case $choice in
            2) PROFILE="WORK" ;;
            3) PROFILE="SERVER" ;;
            *) PROFILE="PERSONAL" ;;
        esac
    fi
fi

echo "    ✓ Profile: $PROFILE"

# =============================================================================
# 3. 1PASSWORD
# =============================================================================
echo ""
echo "==> [3/15] 1Password"

if brew list --cask 1password &> /dev/null || [[ -d "/Applications/1Password.app" ]]; then
    echo "    ✓ Already installed"
else
    echo "    Installing 1Password..."
    brew install --cask 1password || echo "    ⚠ Install manually if needed"
fi

# Also install CLI
if brew list 1password-cli &> /dev/null; then
    echo "    ✓ 1Password CLI installed"
else
    echo "    Installing 1Password CLI..."
    brew install 1password-cli || true
fi

# =============================================================================
# 4. 1PASSWORD SSH AGENT
# =============================================================================
echo ""
echo "==> [4/15] 1Password SSH Agent"
echo ""
echo "    ┌─────────────────────────────────────────────┐"
echo "    │  IMPORTANT: Enable SSH Agent now            │"
echo "    │                                             │"
echo "    │  1. Open 1Password                          │"
echo "    │  2. Sign in to your account                 │"
echo "    │  3. Settings → Developer                    │"
echo "    │  4. Enable 'Use the SSH Agent'              │"
echo "    │                                             │"
echo "    │  This is required for GitHub authentication │"
echo "    └─────────────────────────────────────────────┘"
echo ""

if command -v gum &> /dev/null; then
    gum confirm "    SSH Agent enabled?" || echo "    ⚠ Remember to enable it!"
else
    read "?    Press Enter when done (or to continue anyway) "
fi

# =============================================================================
# 5. CORE CLI TOOLS
# =============================================================================
echo ""
echo "==> [5/15] Core CLI Tools"

CORE_TOOLS=(git gh jq gum fnm)
for tool in "${CORE_TOOLS[@]}"; do
    if brew list "$tool" &> /dev/null; then
        echo "    ✓ $tool"
    else
        echo "    Installing $tool..."
        brew install "$tool"
    fi
done

# =============================================================================
# 6. GITHUB CLI AUTH
# =============================================================================
echo ""
echo "==> [6/15] GitHub Authentication"

if gh auth status &> /dev/null; then
    GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "unknown")
    echo "    ✓ Authenticated as $GH_USER"
else
    echo "    Authenticating with GitHub..."
    echo "    (Using SSH protocol with 1Password agent)"
    gh auth login --web --git-protocol ssh --skip-ssh-key
fi

# =============================================================================
# 7. CLONE CONFIG + DOTFILES
# =============================================================================
echo ""
echo "==> [7/15] Clone Repositories"

mkdir -p "$REPOS_ROOT/dev"

if [[ -d "$CONFIG_PATH" ]]; then
    echo "    ✓ config repo exists"
else
    echo "    Cloning config..."
    cd "$REPOS_ROOT/dev"
    gh repo clone config
fi

if [[ -d "$DOTFILES_PATH" ]]; then
    echo "    ✓ dotfiles repo exists"
else
    echo "    Cloning dotfiles..."
    cd "$REPOS_ROOT/dev"
    gh repo clone dotfiles
fi

# =============================================================================
# 8. LINK DOTFILES
# =============================================================================
echo ""
echo "==> [8/15] Link Dotfiles"

if [[ -f "$SCRIPT_DIR/link-dotfiles.sh" ]]; then
    "$SCRIPT_DIR/link-dotfiles.sh"
else
    echo "    ⚠ link-dotfiles.sh not found"
fi

# =============================================================================
# 9. NODE + CLAUDE CODE
# =============================================================================
echo ""
echo "==> [9/15] Node.js + Claude Code"

# Initialize fnm for this session
eval "$(fnm env --use-on-cd --shell zsh)"

# Install Node LTS
if fnm list 2>/dev/null | grep -q "lts"; then
    fnm use lts-latest 2>/dev/null || true
    echo "    ✓ Node.js LTS"
else
    echo "    Installing Node.js LTS..."
    fnm install --lts
    fnm use lts-latest
    fnm default lts-latest
fi

# Install Claude Code
if command -v claude &> /dev/null; then
    echo "    ✓ Claude Code"
else
    echo "    Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
fi

# Configure Claude settings (if source exists and target doesn't or matches)
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

echo ""
echo "    ┌─────────────────────────────────────────────┐"
echo "    │  Claude Code is now available!              │"
echo "    │  Run 'claude' if you need help from here.   │"
echo "    └─────────────────────────────────────────────┘"

# =============================================================================
# 10. GIT + SSH CONFIG
# =============================================================================
echo ""
echo "==> [10/15] Git + SSH Configuration"

# Git identity from config repo
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

# SSH config
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [[ -f "$SSH_CONFIG" ]]; then
    echo "    ✓ SSH config exists"
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
        echo "    ✓ SSH config created (with homelab)"
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
        echo "    ✓ SSH config created"
    fi
    chmod 600 "$SSH_CONFIG"
fi

# =============================================================================
# 11. PYTHON / UV
# =============================================================================
echo ""
echo "==> [11/15] Python (uv)"

if brew list uv &> /dev/null; then
    echo "    ✓ uv installed"
else
    echo "    Installing uv..."
    brew install uv
fi

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

# =============================================================================
# 12. CLONE ALL REPOS
# =============================================================================
echo ""
echo "==> [12/15] Clone All Repositories"

if [[ -f "$SCRIPT_DIR/clone-repos.sh" ]]; then
    "$SCRIPT_DIR/clone-repos.sh"
else
    echo "    ⚠ clone-repos.sh not found"
fi

# =============================================================================
# 13. OPTIONAL PACKAGES
# =============================================================================
echo ""
echo "==> [13/15] Optional Packages"

PROFILE_ARG=""
[[ -n "$PROFILE" ]] && PROFILE_ARG="--profile ${PROFILE:l}"

if [[ "$INSTALL_ALL" == true ]]; then
    "$SCRIPT_DIR/install-packages.sh" $PROFILE_ARG --all
else
    if command -v gum &> /dev/null; then
        if gum confirm "Install optional packages now?"; then
            "$SCRIPT_DIR/install-packages.sh" $PROFILE_ARG
        else
            echo "    Skipped (run install-packages.sh later)"
        fi
    else
        read "REPLY?    Install optional packages? [y/N] "
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            "$SCRIPT_DIR/install-packages.sh" $PROFILE_ARG
        else
            echo "    Skipped"
        fi
    fi
fi

# =============================================================================
# 14. DROPBOX
# =============================================================================
echo ""
echo "==> [14/15] Dropbox"

if [[ "$PROFILE" == "SERVER" ]]; then
    echo "    Skipped (Server profile)"
else
    if brew list --cask dropbox &> /dev/null || [[ -d "/Applications/Dropbox.app" ]]; then
        echo "    ✓ Dropbox installed"
    else
        echo "    Installing Dropbox..."
        brew install --cask dropbox || echo "    ⚠ Install manually if needed"
    fi

    echo ""
    echo "    Configure Dropbox folder sync:"
    echo "      1. Open Dropbox and sign in"
    echo "      2. Menu bar → Settings → Backups"
    echo "      3. Enable Desktop, Documents, Downloads"
    echo ""

    if command -v gum &> /dev/null; then
        gum confirm "    Open Dropbox now?" && open -a Dropbox || true
    fi
fi

# =============================================================================
# 15. MACOS PREFERENCES
# =============================================================================
echo ""
echo "==> [15/15] macOS Preferences"

if [[ "$INSTALL_ALL" == true ]]; then
    "$SCRIPT_DIR/configure-macos.sh" --all
else
    if command -v gum &> /dev/null; then
        if gum confirm "Configure macOS preferences?"; then
            "$SCRIPT_DIR/configure-macos.sh"
        else
            echo "    Skipped (run configure-macos.sh later)"
        fi
    else
        read "REPLY?    Configure macOS preferences? [y/N] "
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            "$SCRIPT_DIR/configure-macos.sh"
        else
            echo "    Skipped"
        fi
    fi
fi

# =============================================================================
# DONE
# =============================================================================
echo ""
echo "======================================"
echo "  Setup Complete!"
echo "======================================"
echo ""
echo "  Verify: $SCRIPT_DIR/verify-setup.sh"
echo "  Repos:  ~/repos/"
echo ""

if command -v gum &> /dev/null; then
    gum confirm "Run verification?" && "$SCRIPT_DIR/verify-setup.sh" || true
fi
