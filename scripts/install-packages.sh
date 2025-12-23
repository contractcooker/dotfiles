#!/bin/zsh
# Install Homebrew packages with interactive selection
#
# Parses Brewfile for packages tagged with [core] or [category].
# Core packages install automatically, optional packages shown in picker.
#
# Usage:
#   ./install-packages.sh              # Interactive mode
#   ./install-packages.sh --all        # Install everything
#   ./install-packages.sh --core-only  # Only core packages

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_PATH="$(dirname "$SCRIPT_DIR")"
BREWFILE="$DOTFILES_PATH/Brewfile"

# Parse arguments
INSTALL_ALL=false
CORE_ONLY=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --all) INSTALL_ALL=true; shift ;;
        --core-only) CORE_ONLY=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo ""
echo "======================================"
echo "  Package Installation"
echo "======================================"

# -----------------------------------------------------------------------------
# Step 1: Install Homebrew
# -----------------------------------------------------------------------------
echo ""
echo "==> Checking Homebrew"

if command -v brew &> /dev/null; then
    echo "    ✓ Homebrew installed"
else
    echo "    Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for this session
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    echo "    ✓ Homebrew installed"
fi

# -----------------------------------------------------------------------------
# Step 2: Parse Brewfile
# -----------------------------------------------------------------------------

# Arrays to hold parsed packages
typeset -a CORE_FORMULAE
typeset -a CORE_CASKS
typeset -a CORE_MAS           # "name|id"
typeset -A OPTIONAL_FORMULAE  # name -> "category|description"
typeset -A OPTIONAL_CASKS     # name -> "category|description"
typeset -A OPTIONAL_MAS       # "name|id" -> "category|description"

parse_brewfile() {
    if [[ ! -f "$BREWFILE" ]]; then
        echo "Error: Brewfile not found at $BREWFILE"
        exit 1
    fi

    while IFS= read -r line; do
        # Skip empty lines and comments without packages
        [[ -z "$line" ]] && continue
        [[ "$line" == \#* ]] && continue

        # Match: brew "name" # [tag] description
        if [[ "$line" =~ "^brew[[:space:]]+\"([^\"]+)\"[[:space:]]*#[[:space:]]*\[([^]]+)\][[:space:]]*(.*)" ]]; then
            name="${match[1]}"
            tag="${match[2]}"
            desc="${match[3]}"

            if [[ "$tag" == "core" ]]; then
                CORE_FORMULAE+=("$name")
            else
                OPTIONAL_FORMULAE[$name]="${tag}|${desc}"
            fi
        fi

        # Match: cask "name" # [tag] description
        if [[ "$line" =~ "^cask[[:space:]]+\"([^\"]+)\"[[:space:]]*#[[:space:]]*\[([^]]+)\][[:space:]]*(.*)" ]]; then
            name="${match[1]}"
            tag="${match[2]}"
            desc="${match[3]}"

            if [[ "$tag" == "core" ]]; then
                CORE_CASKS+=("$name")
            else
                OPTIONAL_CASKS[$name]="${tag}|${desc}"
            fi
        fi

        # Match: mas "name", id: 123456 # [tag] description
        if [[ "$line" =~ "^mas[[:space:]]+\"([^\"]+)\",[[:space:]]*id:[[:space:]]*([0-9]+)[[:space:]]*#[[:space:]]*\[([^]]+)\][[:space:]]*(.*)" ]]; then
            name="${match[1]}"
            app_id="${match[2]}"
            tag="${match[3]}"
            desc="${match[4]}"

            if [[ "$tag" == "core" ]]; then
                CORE_MAS+=("${name}|${app_id}")
            else
                OPTIONAL_MAS["${name}|${app_id}"]="${tag}|${desc}"
            fi
        fi
    done < "$BREWFILE"
}

echo ""
echo "==> Parsing Brewfile"
parse_brewfile
echo "    ✓ Found ${#CORE_FORMULAE[@]} core formulae, ${#CORE_CASKS[@]} core casks, ${#CORE_MAS[@]} core mas"
echo "    ✓ Found ${#OPTIONAL_FORMULAE[@]} optional formulae, ${#OPTIONAL_CASKS[@]} optional casks, ${#OPTIONAL_MAS[@]} optional mas"

# -----------------------------------------------------------------------------
# Step 3: Install gum first (needed for interactive UI)
# -----------------------------------------------------------------------------
echo ""
echo "==> Checking gum"

if command -v gum &> /dev/null; then
    echo "    ✓ gum installed"
else
    echo "    Installing gum..."
    brew install gum
    echo "    ✓ gum installed"
fi

# -----------------------------------------------------------------------------
# Step 4: Install core packages
# -----------------------------------------------------------------------------
echo ""
echo "==> Installing core packages"

for pkg in "${CORE_FORMULAE[@]}"; do
    if brew list "$pkg" &> /dev/null; then
        echo "    ✓ $pkg"
    else
        echo "    Installing $pkg..."
        brew install "$pkg"
    fi
done

for pkg in "${CORE_CASKS[@]}"; do
    if brew list --cask "$pkg" &> /dev/null; then
        echo "    ✓ $pkg"
    else
        echo "    Installing $pkg..."
        brew install --cask "$pkg" || echo "    ⚠ $pkg (may already be installed outside Homebrew)"
    fi
done

for entry in "${CORE_MAS[@]}"; do
    name="${entry%%|*}"
    app_id="${entry#*|}"
    if mas list | grep -q "^${app_id}"; then
        echo "    ✓ $name"
    else
        echo "    Installing $name..."
        mas install "$app_id" || echo "    ⚠ $name (may require App Store sign-in)"
    fi
done

if [ "$CORE_ONLY" = true ]; then
    echo ""
    echo "==> Core packages installed (--core-only)"
    exit 0
fi

# -----------------------------------------------------------------------------
# Step 5: Optional packages
# -----------------------------------------------------------------------------
echo ""
echo "==> Optional packages"

install_formula() {
    local pkg="$1"
    if brew list "$pkg" &> /dev/null; then
        echo "    ✓ $pkg (already installed)"
    else
        echo "    Installing $pkg..."
        brew install "$pkg" || echo "    ⚠ Failed to install $pkg"
    fi
}

install_cask() {
    local pkg="$1"
    if brew list --cask "$pkg" &> /dev/null; then
        echo "    ✓ $pkg (already installed)"
    else
        echo "    Installing $pkg..."
        brew install --cask "$pkg" || echo "    ⚠ Failed to install $pkg"
    fi
}

install_mas() {
    local name="$1"
    local app_id="$2"
    if mas list | grep -q "^${app_id}"; then
        echo "    ✓ $name (already installed)"
    else
        echo "    Installing $name..."
        mas install "$app_id" || echo "    ⚠ Failed to install $name"
    fi
}

if [ "$INSTALL_ALL" = true ]; then
    echo "    Installing all optional packages (--all)"
    echo ""

    for pkg in "${(@k)OPTIONAL_FORMULAE}"; do
        install_formula "$pkg"
    done

    for pkg in "${(@k)OPTIONAL_CASKS}"; do
        install_cask "$pkg"
    done

    for entry in "${(@k)OPTIONAL_MAS}"; do
        name="${entry%%|*}"
        app_id="${entry#*|}"
        install_mas "$name" "$app_id"
    done
else
    # Build options for gum, grouped by category
    # Format: "package - [category] description"

    echo ""
    echo "    Select formulae to install (space=toggle, enter=confirm):"
    echo ""

    # Build formula options (only show uninstalled)
    FORMULA_OPTIONS=()
    for pkg in "${(@k)OPTIONAL_FORMULAE}"; do
        if ! brew list "$pkg" &> /dev/null; then
            local data="${OPTIONAL_FORMULAE[$pkg]}"
            local category="${data%%|*}"
            local desc="${data#*|}"
            FORMULA_OPTIONS+=("$pkg - [$category] $desc")
        fi
    done

    if [ ${#FORMULA_OPTIONS[@]} -gt 0 ]; then
        # Sort options by category
        SORTED_FORMULAE=("${(@f)$(printf '%s\n' "${FORMULA_OPTIONS[@]}" | sort -t'[' -k2)}")

        SELECTED=$(printf '%s\n' "${SORTED_FORMULAE[@]}" | gum choose --no-limit --header "Formulae:" || true)

        if [ -n "$SELECTED" ]; then
            while IFS= read -r line; do
                pkg=$(echo "$line" | cut -d' ' -f1)
                install_formula "$pkg"
            done <<< "$SELECTED"
        fi
    else
        echo "    All formulae already installed"
    fi

    echo ""
    echo "    Select casks to install (space=toggle, enter=confirm):"
    echo ""

    # Build cask options (only show uninstalled)
    CASK_OPTIONS=()
    for pkg in "${(@k)OPTIONAL_CASKS}"; do
        if ! brew list --cask "$pkg" &> /dev/null; then
            local data="${OPTIONAL_CASKS[$pkg]}"
            local category="${data%%|*}"
            local desc="${data#*|}"
            CASK_OPTIONS+=("$pkg - [$category] $desc")
        fi
    done

    if [ ${#CASK_OPTIONS[@]} -gt 0 ]; then
        # Sort options by category
        SORTED_CASKS=("${(@f)$(printf '%s\n' "${CASK_OPTIONS[@]}" | sort -t'[' -k2)}")

        SELECTED=$(printf '%s\n' "${SORTED_CASKS[@]}" | gum choose --no-limit --header "Casks (Applications):" || true)

        if [ -n "$SELECTED" ]; then
            while IFS= read -r line; do
                pkg=$(echo "$line" | cut -d' ' -f1)
                install_cask "$pkg"
            done <<< "$SELECTED"
        fi
    else
        echo "    All casks already installed"
    fi

    echo ""
    echo "    Select App Store apps to install (space=toggle, enter=confirm):"
    echo ""

    # Build mas options (only show uninstalled)
    MAS_OPTIONS=()
    for entry in "${(@k)OPTIONAL_MAS}"; do
        name="${entry%%|*}"
        app_id="${entry#*|}"
        if ! mas list | grep -q "^${app_id}"; then
            local data="${OPTIONAL_MAS[$entry]}"
            local category="${data%%|*}"
            local desc="${data#*|}"
            MAS_OPTIONS+=("${name}|${app_id} - [$category] $desc")
        fi
    done

    if [ ${#MAS_OPTIONS[@]} -gt 0 ]; then
        # Sort options by category
        SORTED_MAS=("${(@f)$(printf '%s\n' "${MAS_OPTIONS[@]}" | sort -t'[' -k2)}")

        SELECTED=$(printf '%s\n' "${SORTED_MAS[@]}" | gum choose --no-limit --header "App Store:" || true)

        if [ -n "$SELECTED" ]; then
            while IFS= read -r line; do
                entry=$(echo "$line" | cut -d' ' -f1)
                name="${entry%%|*}"
                app_id="${entry#*|}"
                install_mas "$name" "$app_id"
            done <<< "$SELECTED"
        fi
    else
        echo "    All App Store apps already installed"
    fi
fi

echo ""
echo "==> Package installation complete"
echo ""
