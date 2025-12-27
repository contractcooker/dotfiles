#!/bin/zsh
# Install Homebrew packages with profile-based selection
#
# Parses Brewfile for packages. Base packages install automatically.
# Optional packages filtered by profile.
#
# Profiles:
#   Personal - base, desktop, dev, gaming, personal, browser, communication, utility
#   Work     - base, desktop, dev, browser, communication, utility
#   Server   - base only (CLI tools)
#
# Usage:
#   ./install-packages.sh                      # Interactive profile selection
#   ./install-packages.sh --profile personal   # Use specific profile
#   ./install-packages.sh --all                # Install everything
#   ./install-packages.sh --base-only          # Only base packages

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_PATH="$(dirname "$SCRIPT_DIR")"
BREWFILE="$DOTFILES_PATH/Brewfile"

# Parse arguments
INSTALL_ALL=false
BASE_ONLY=false
PROFILE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --all) INSTALL_ALL=true; shift ;;
        --base-only) BASE_ONLY=true; shift ;;
        --profile)
            PROFILE="${2:u}"  # Uppercase
            shift 2
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Profile categories mapping
typeset -A PROFILE_CATEGORIES
PROFILE_CATEGORIES=(
    Personal "desktop dev gaming browser communication personal utility"
    Work "desktop dev browser communication utility"
    Server ""
)

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

    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    echo "    ✓ Homebrew installed"
fi

# -----------------------------------------------------------------------------
# Step 2: Install gum
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
# Step 3: Profile Selection
# -----------------------------------------------------------------------------
echo ""
echo "==> Profile Selection"

if [[ -z "$PROFILE" && "$INSTALL_ALL" == false && "$BASE_ONLY" == false ]]; then
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
            2) PROFILE="Work" ;;
            3) PROFILE="Server" ;;
            *) PROFILE="Personal" ;;
        esac
    fi
fi

if [[ -n "$PROFILE" ]]; then
    echo "    ✓ Profile: $PROFILE"
fi

# -----------------------------------------------------------------------------
# Step 4: Parse Brewfile
# -----------------------------------------------------------------------------

typeset -a BASE_FORMULAE
typeset -a BASE_CASKS
typeset -a BASE_MAS           # "name|id"
typeset -A OPTIONAL_FORMULAE  # name -> "category|description"
typeset -A OPTIONAL_CASKS     # name -> "category|description"
typeset -A OPTIONAL_MAS       # "name|id" -> "category|description"

parse_brewfile() {
    if [[ ! -f "$BREWFILE" ]]; then
        echo "Error: Brewfile not found at $BREWFILE"
        exit 1
    fi

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" == \#* ]] && continue

        # Match: brew "name" # [tag] description
        if [[ "$line" =~ "^brew[[:space:]]+\"([^\"]+)\"[[:space:]]*#[[:space:]]*\[([^]]+)\][[:space:]]*(.*)" ]]; then
            name="${match[1]}"
            tag="${match[2]}"
            desc="${match[3]}"

            if [[ "$tag" == "base" ]]; then
                BASE_FORMULAE+=("$name")
            else
                OPTIONAL_FORMULAE[$name]="${tag}|${desc}"
            fi
        fi

        # Match: cask "name" # [tag] description
        if [[ "$line" =~ "^cask[[:space:]]+\"([^\"]+)\"[[:space:]]*#[[:space:]]*\[([^]]+)\][[:space:]]*(.*)" ]]; then
            name="${match[1]}"
            tag="${match[2]}"
            desc="${match[3]}"

            if [[ "$tag" == "base" ]]; then
                BASE_CASKS+=("$name")
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

            if [[ "$tag" == "base" ]]; then
                BASE_MAS+=("${name}|${app_id}")
            else
                OPTIONAL_MAS["${name}|${app_id}"]="${tag}|${desc}"
            fi
        fi
    done < "$BREWFILE"
}

echo ""
echo "==> Parsing Brewfile"
parse_brewfile
echo "    ✓ Found ${#BASE_FORMULAE[@]} base formulae, ${#BASE_CASKS[@]} base casks, ${#BASE_MAS[@]} base mas"
echo "    ✓ Found ${#OPTIONAL_FORMULAE[@]} optional formulae, ${#OPTIONAL_CASKS[@]} optional casks, ${#OPTIONAL_MAS[@]} optional mas"

# -----------------------------------------------------------------------------
# Step 5: Install base packages
# -----------------------------------------------------------------------------
echo ""
echo "==> Installing base packages"

for pkg in "${BASE_FORMULAE[@]}"; do
    if brew list "$pkg" &> /dev/null; then
        echo "    ✓ $pkg"
    else
        echo "    Installing $pkg..."
        brew install "$pkg"
    fi
done

for pkg in "${BASE_CASKS[@]}"; do
    if brew list --cask "$pkg" &> /dev/null; then
        echo "    ✓ $pkg"
    else
        echo "    Installing $pkg..."
        brew install --cask "$pkg" || echo "    ⚠ $pkg (may already be installed outside Homebrew)"
    fi
done

for entry in "${BASE_MAS[@]}"; do
    name="${entry%%|*}"
    app_id="${entry#*|}"
    if mas list | grep -q "^${app_id}"; then
        echo "    ✓ $name"
    else
        echo "    Installing $name..."
        mas install "$app_id" || echo "    ⚠ $name (may require App Store sign-in)"
    fi
done

if [[ "$BASE_ONLY" == true ]]; then
    echo ""
    echo "==> Base packages installed (--base-only)"
    exit 0
fi

if [[ "$PROFILE" == "SERVER" ]]; then
    echo ""
    echo "==> Server profile complete (base only)"
    exit 0
fi

# -----------------------------------------------------------------------------
# Step 6: Build allowed categories
# -----------------------------------------------------------------------------
echo ""
echo "==> Building package list"

ALLOWED_CATEGORIES=""
if [[ -n "$PROFILE" ]]; then
    ALLOWED_CATEGORIES="${PROFILE_CATEGORIES[$PROFILE]}"
fi

echo "    ✓ Categories: ${ALLOWED_CATEGORIES:-all}"

# -----------------------------------------------------------------------------
# Step 7: Optional packages
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

# Filter function
is_allowed_category() {
    local category="$1"
    if [[ "$INSTALL_ALL" == true ]]; then
        return 0
    fi
    if [[ -z "$ALLOWED_CATEGORIES" ]]; then
        return 0  # No profile = all allowed
    fi
    [[ " $ALLOWED_CATEGORIES " == *" $category "* ]]
}

if [[ "$INSTALL_ALL" == true ]]; then
    echo "    Installing all optional packages (--all)"
    echo ""

    for pkg in "${(@k)OPTIONAL_FORMULAE}"; do
        local data="${OPTIONAL_FORMULAE[$pkg]}"
        local category="${data%%|*}"
        if is_allowed_category "$category"; then
            install_formula "$pkg"
        fi
    done

    for pkg in "${(@k)OPTIONAL_CASKS}"; do
        local data="${OPTIONAL_CASKS[$pkg]}"
        local category="${data%%|*}"
        if is_allowed_category "$category"; then
            install_cask "$pkg"
        fi
    done

    for entry in "${(@k)OPTIONAL_MAS}"; do
        local data="${OPTIONAL_MAS[$entry]}"
        local category="${data%%|*}"
        if is_allowed_category "$category"; then
            name="${entry%%|*}"
            app_id="${entry#*|}"
            install_mas "$name" "$app_id"
        fi
    done
else
    # Interactive selection with gum

    echo ""
    echo "    Select formulae to install (space=toggle, enter=confirm):"
    echo ""

    # Build formula options (only show uninstalled and allowed categories)
    FORMULA_OPTIONS=()
    for pkg in "${(@k)OPTIONAL_FORMULAE}"; do
        if ! brew list "$pkg" &> /dev/null; then
            local data="${OPTIONAL_FORMULAE[$pkg]}"
            local category="${data%%|*}"
            local desc="${data#*|}"
            if is_allowed_category "$category"; then
                FORMULA_OPTIONS+=("$pkg - [$category] $desc")
            fi
        fi
    done

    if [[ ${#FORMULA_OPTIONS[@]} -gt 0 ]]; then
        SORTED_FORMULAE=("${(@f)$(printf '%s\n' "${FORMULA_OPTIONS[@]}" | sort -t'[' -k2)}")
        SELECTED=$(printf '%s\n' "${SORTED_FORMULAE[@]}" | gum choose --no-limit --header "Formulae:" || true)

        if [[ -n "$SELECTED" ]]; then
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

    # Build cask options
    CASK_OPTIONS=()
    for pkg in "${(@k)OPTIONAL_CASKS}"; do
        if ! brew list --cask "$pkg" &> /dev/null; then
            local data="${OPTIONAL_CASKS[$pkg]}"
            local category="${data%%|*}"
            local desc="${data#*|}"
            if is_allowed_category "$category"; then
                CASK_OPTIONS+=("$pkg - [$category] $desc")
            fi
        fi
    done

    if [[ ${#CASK_OPTIONS[@]} -gt 0 ]]; then
        SORTED_CASKS=("${(@f)$(printf '%s\n' "${CASK_OPTIONS[@]}" | sort -t'[' -k2)}")
        SELECTED=$(printf '%s\n' "${SORTED_CASKS[@]}" | gum choose --no-limit --header "Casks (Applications):" || true)

        if [[ -n "$SELECTED" ]]; then
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

    # Build mas options
    MAS_OPTIONS=()
    for entry in "${(@k)OPTIONAL_MAS}"; do
        name="${entry%%|*}"
        app_id="${entry#*|}"
        if ! mas list | grep -q "^${app_id}"; then
            local data="${OPTIONAL_MAS[$entry]}"
            local category="${data%%|*}"
            local desc="${data#*|}"
            if is_allowed_category "$category"; then
                MAS_OPTIONS+=("${name}|${app_id} - [$category] $desc")
            fi
        fi
    done

    if [[ ${#MAS_OPTIONS[@]} -gt 0 ]]; then
        SORTED_MAS=("${(@f)$(printf '%s\n' "${MAS_OPTIONS[@]}" | sort -t'[' -k2)}")
        SELECTED=$(printf '%s\n' "${SORTED_MAS[@]}" | gum choose --no-limit --header "App Store:" || true)

        if [[ -n "$SELECTED" ]]; then
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
