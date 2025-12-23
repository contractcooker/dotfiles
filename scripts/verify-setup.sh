#!/bin/bash
# Verify macOS Development Environment Setup
#
# Run this after setup-mac.sh to confirm everything is working,
# or anytime to check the health of your development environment.

REPOS_ROOT="$HOME/repos"
CONFIG_PATH="$REPOS_ROOT/dev/config"
DOTFILES_PATH="$REPOS_ROOT/dev/dotfiles"

PASS=0
FAIL=0
WARN=0

pass() {
    echo "✓ $1"
    ((PASS++))
}

fail() {
    echo "✗ $1"
    ((FAIL++))
}

warn() {
    echo "⚠ $1"
    ((WARN++))
}

echo ""
echo "======================================"
echo "  Environment Verification"
echo "======================================"
echo ""

# Homebrew
echo "==> Package Management"
if command -v brew &> /dev/null; then
    pass "Homebrew installed ($(brew --version | head -1))"
else
    fail "Homebrew not installed"
fi

# Core CLI tools
echo ""
echo "==> Core Tools"
for cmd in git gh jq gum; do
    if command -v "$cmd" &> /dev/null; then
        pass "$cmd installed"
    else
        fail "$cmd not installed"
    fi
done

# fnm and Node
echo ""
echo "==> Node.js"
if command -v fnm &> /dev/null; then
    pass "fnm installed"

    # Check if fnm is initialized (node available)
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version 2>/dev/null)
        NODE_PATH=$(which node 2>/dev/null)
        if [[ "$NODE_PATH" == *".fnm"* ]]; then
            pass "Node $NODE_VERSION (via fnm)"
        else
            warn "Node $NODE_VERSION found but not via fnm ($NODE_PATH)"
        fi
    else
        fail "Node not installed (run: fnm install --lts)"
    fi
else
    fail "fnm not installed"
fi

# uv and Python
echo ""
echo "==> Python"
if command -v uv &> /dev/null; then
    pass "uv installed"

    # Check for Python installed via uv
    if uv python list --only-installed 2>/dev/null | grep -q "cpython"; then
        PYTHON_VERSION=$(uv python list --only-installed 2>/dev/null | head -1 | awk '{print $1}')
        pass "Python $PYTHON_VERSION (via uv)"
    else
        fail "Python not installed (run: uv python install)"
    fi

    # Check for pre-commit
    if uv tool list 2>/dev/null | grep -q "pre-commit"; then
        pass "pre-commit installed (via uv)"
    else
        warn "pre-commit not installed (run: uv tool install pre-commit)"
    fi
else
    fail "uv not installed"
fi

# Claude Code
echo ""
echo "==> Claude Code"
if command -v claude &> /dev/null; then
    pass "Claude Code installed"
else
    fail "Claude Code not installed (run: npm install -g @anthropic-ai/claude-code)"
fi

if [ -f "$HOME/.claude/CLAUDE.md" ]; then
    pass "Claude global settings configured"
else
    warn "Claude global settings not found (~/.claude/CLAUDE.md)"
fi

# Git configuration
echo ""
echo "==> Git Configuration"
GIT_NAME=$(git config user.name 2>/dev/null)
GIT_EMAIL=$(git config user.email 2>/dev/null)

if [ -n "$GIT_NAME" ]; then
    pass "Git user.name: $GIT_NAME"
else
    fail "Git user.name not set"
fi

if [ -n "$GIT_EMAIL" ]; then
    pass "Git user.email: $GIT_EMAIL"
else
    fail "Git user.email not set"
fi

# GitHub CLI
echo ""
echo "==> GitHub CLI"
if gh auth status &> /dev/null; then
    GH_USER=$(gh api user --jq '.login' 2>/dev/null)
    pass "GitHub authenticated as $GH_USER"
else
    fail "GitHub CLI not authenticated (run: gh auth login)"
fi

# SSH
echo ""
echo "==> SSH Configuration"
if [ -f "$HOME/.ssh/config" ]; then
    pass "SSH config exists"

    # Check for 1Password agent config
    if grep -q "1password" "$HOME/.ssh/config" 2>/dev/null; then
        pass "1Password SSH agent configured"
    else
        warn "1Password SSH agent not in SSH config"
    fi
else
    fail "SSH config not found (~/.ssh/config)"
fi

# Test GitHub SSH connection
echo ""
echo "==> SSH Connectivity"
SSH_OUTPUT=$(ssh -T git@github.com 2>&1)
if echo "$SSH_OUTPUT" | grep -q "successfully authenticated"; then
    GH_SSH_USER=$(echo "$SSH_OUTPUT" | sed -n 's/.*Hi \([^!]*\).*/\1/p')
    pass "GitHub SSH working${GH_SSH_USER:+ ($GH_SSH_USER)}"
else
    fail "GitHub SSH not working (check 1Password SSH agent)"
    echo "      Response: $SSH_OUTPUT"
fi

# Repos
echo ""
echo "==> Repository Structure"
if [ -d "$CONFIG_PATH" ]; then
    pass "Config repo exists"
else
    fail "Config repo not found ($CONFIG_PATH)"
fi

if [ -d "$DOTFILES_PATH" ]; then
    pass "Dotfiles repo exists"
else
    fail "Dotfiles repo not found ($DOTFILES_PATH)"
fi

if [ -d "$REPOS_ROOT" ]; then
    REPO_COUNT=$(find "$REPOS_ROOT" -maxdepth 3 -name ".git" -type d 2>/dev/null | wc -l | tr -d ' ')
    pass "$REPO_COUNT repositories in ~/repos/"
fi

# Dotfiles
echo ""
echo "==> Dotfiles"
if [ -L "$HOME/.zshrc" ]; then
    pass ".zshrc symlinked"
else
    if [ -f "$HOME/.zshrc" ]; then
        warn ".zshrc exists but not symlinked"
    else
        fail ".zshrc not found"
    fi
fi

if [ -L "$HOME/.gitconfig" ]; then
    pass ".gitconfig symlinked"
else
    if [ -f "$HOME/.gitconfig" ]; then
        warn ".gitconfig exists but not symlinked"
    else
        fail ".gitconfig not found"
    fi
fi

if [ -f "$HOME/.gitconfig.local" ]; then
    pass ".gitconfig.local exists (identity)"
else
    warn ".gitconfig.local not found (run configure-dev.sh)"
fi

# macOS Settings (spot check key dev settings)
echo ""
echo "==> macOS Settings"

# Check if show all extensions is enabled
if [ "$(defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null)" = "1" ]; then
    pass "Show all file extensions"
else
    warn "Show all file extensions disabled"
fi

# Check if key repeat is enabled (ApplePressAndHoldEnabled = false)
if [ "$(defaults read NSGlobalDomain ApplePressAndHoldEnabled 2>/dev/null)" = "0" ]; then
    pass "Key repeat enabled (press-and-hold disabled)"
else
    warn "Press-and-hold enabled (key repeat disabled)"
fi

# Check if auto-correct is disabled
if [ "$(defaults read NSGlobalDomain NSAutomaticSpellingCorrectionEnabled 2>/dev/null)" = "0" ]; then
    pass "Auto-correct disabled"
else
    warn "Auto-correct enabled"
fi

# Summary
echo ""
echo "======================================"
echo "  Summary"
echo "======================================"
echo ""
echo "  Passed:   $PASS"
echo "  Failed:   $FAIL"
echo "  Warnings: $WARN"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "  ✓ Environment looks good!"
else
    echo "  Some checks failed. Review above for details."
fi
echo ""
