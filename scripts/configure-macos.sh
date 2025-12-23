#!/bin/bash
# Configure macOS system preferences
#
# Three sections:
#   1. Dev Settings - Recommended for development workflows
#   2. Debloat - Disable telemetry, Siri, and unnecessary services
#   3. Personal Settings - Subjective preferences (optional)
#
# Usage:
#   ./configure-macos.sh              # Interactive mode
#   ./configure-macos.sh --all        # Apply all settings
#   ./configure-macos.sh --dev-only   # Only dev settings
#   ./configure-macos.sh --debloat    # Only debloat settings

set -e

# Parse arguments
APPLY_ALL=false
DEV_ONLY=false
DEBLOAT_ONLY=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --all) APPLY_ALL=true; shift ;;
        --dev-only) DEV_ONLY=true; shift ;;
        --debloat) DEBLOAT_ONLY=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo ""
echo "======================================"
echo "  macOS System Preferences"
echo "======================================"

# =============================================================================
# DEV SETTINGS
# =============================================================================

apply_dev_settings() {
    echo ""
    echo "==> Applying Dev Settings"

    # -------------------------------------------------------------------------
    # Finder
    # -------------------------------------------------------------------------
    echo "    Finder:"

    # Show all file extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    echo "      ✓ Show all file extensions"

    # Show path bar
    defaults write com.apple.finder ShowPathbar -bool true
    echo "      ✓ Show path bar"

    # Show status bar
    defaults write com.apple.finder ShowStatusBar -bool true
    echo "      ✓ Show status bar"

    # Default to list view
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    echo "      ✓ Default to list view"

    # Disable extension change warning
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    echo "      ✓ Disable extension change warning"

    # Show hidden files
    defaults write com.apple.finder AppleShowAllFiles -bool true
    echo "      ✓ Show hidden files"

    # -------------------------------------------------------------------------
    # Keyboard
    # -------------------------------------------------------------------------
    echo "    Keyboard:"

    # Faster key repeat
    defaults write NSGlobalDomain KeyRepeat -int 2
    echo "      ✓ Fast key repeat"

    # Shorter delay until repeat
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    echo "      ✓ Short repeat delay"

    # Disable press-and-hold for keys (enable key repeat)
    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
    echo "      ✓ Disable press-and-hold (enable repeat)"

    # -------------------------------------------------------------------------
    # Text Input
    # -------------------------------------------------------------------------
    echo "    Text Input:"

    # Disable auto-correct
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    echo "      ✓ Disable auto-correct"

    # Disable auto-capitalization
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    echo "      ✓ Disable auto-capitalization"

    # Disable smart quotes
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    echo "      ✓ Disable smart quotes"

    # Disable smart dashes
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    echo "      ✓ Disable smart dashes"

    # Disable auto period substitution
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    echo "      ✓ Disable period substitution"

    # -------------------------------------------------------------------------
    # Screenshots
    # -------------------------------------------------------------------------
    echo "    Screenshots:"

    # Save screenshots to Downloads
    defaults write com.apple.screencapture location -string "$HOME/Downloads"
    echo "      ✓ Save to ~/Downloads"

    # Save as PNG
    defaults write com.apple.screencapture type -string "png"
    echo "      ✓ Format: PNG"

    # Disable shadow in screenshots
    defaults write com.apple.screencapture disable-shadow -bool true
    echo "      ✓ Disable window shadows"

    # -------------------------------------------------------------------------
    # Misc
    # -------------------------------------------------------------------------
    echo "    Misc:"

    # Expand save panel by default
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
    echo "      ✓ Expand save dialogs"

    # Expand print panel by default
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
    echo "      ✓ Expand print dialogs"

    # Disable "Are you sure you want to open this app?"
    defaults write com.apple.LaunchServices LSQuarantine -bool false
    echo "      ✓ Disable app open confirmation"

    # -------------------------------------------------------------------------
    # Time Machine Exclusions
    # -------------------------------------------------------------------------
    echo "    Time Machine:"

    # Exclude repos (version controlled, no backup needed)
    if [ -d "$HOME/repos" ]; then
        tmutil addexclusion "$HOME/repos" 2>/dev/null || true
        echo "      ✓ Exclude ~/repos"
    fi

    # Exclude Homebrew cache
    if [ -d "$HOME/Library/Caches/Homebrew" ]; then
        tmutil addexclusion "$HOME/Library/Caches/Homebrew" 2>/dev/null || true
        echo "      ✓ Exclude Homebrew cache"
    fi

    # Exclude npm cache
    if [ -d "$HOME/.npm" ]; then
        tmutil addexclusion "$HOME/.npm" 2>/dev/null || true
        echo "      ✓ Exclude npm cache"
    fi
}

# =============================================================================
# DEBLOAT SETTINGS
# =============================================================================

apply_debloat_settings() {
    echo ""
    echo "==> Applying Debloat Settings"

    # -------------------------------------------------------------------------
    # Siri
    # -------------------------------------------------------------------------
    echo "    Siri:"

    # Disable Siri
    defaults write com.apple.assistant.support "Assistant Enabled" -bool false
    echo "      ✓ Disable Siri"

    # Disable Siri voice feedback
    defaults write com.apple.assistant.backedup "Use device speaker for TTS" -int 3
    echo "      ✓ Disable Siri voice feedback"

    # Remove Siri from menu bar
    defaults write com.apple.Siri StatusMenuVisible -bool false
    echo "      ✓ Remove Siri from menu bar"

    # -------------------------------------------------------------------------
    # Analytics & Telemetry
    # -------------------------------------------------------------------------
    echo "    Analytics:"

    # Disable Apple analytics
    defaults write com.apple.analyticsd isOptedIn -bool false
    echo "      ✓ Disable Apple analytics"

    # Disable crash reporter
    defaults write com.apple.CrashReporter DialogType -string "none"
    echo "      ✓ Disable crash reporter dialogs"

    # Disable personalized ads
    defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
    echo "      ✓ Disable personalized ads"

    # Disable Spotlight suggestions (sends data to Apple)
    defaults write com.apple.spotlight orderedItems -array \
        '{"enabled" = 1;"name" = "APPLICATIONS";}' \
        '{"enabled" = 1;"name" = "DIRECTORIES";}' \
        '{"enabled" = 1;"name" = "PDF";}' \
        '{"enabled" = 1;"name" = "DOCUMENTS";}' \
        '{"enabled" = 1;"name" = "PRESENTATIONS";}' \
        '{"enabled" = 1;"name" = "SPREADSHEETS";}' \
        '{"enabled" = 1;"name" = "SOURCE";}' \
        '{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
        '{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
        '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'
    echo "      ✓ Disable Spotlight web suggestions"

    # -------------------------------------------------------------------------
    # Game Center
    # -------------------------------------------------------------------------
    echo "    Game Center:"

    # Disable Game Center
    defaults write com.apple.gamed Disabled -bool true
    echo "      ✓ Disable Game Center"

    # -------------------------------------------------------------------------
    # Safari (if used) - may fail on sandboxed Safari
    # -------------------------------------------------------------------------
    echo "    Safari:"

    # Disable Safari suggestions (may fail if Safari sandboxed)
    if defaults write com.apple.Safari UniversalSearchEnabled -bool false 2>/dev/null && \
       defaults write com.apple.Safari SuppressSearchSuggestions -bool true 2>/dev/null; then
        echo "      ✓ Disable Safari suggestions"
    else
        echo "      ⚠ Safari suggestions (configure in Safari → Settings)"
    fi

    # Don't send search queries to Apple
    if defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true 2>/dev/null; then
        echo "      ✓ Enable Do Not Track"
    else
        echo "      ⚠ Do Not Track (configure in Safari → Settings)"
    fi

    # -------------------------------------------------------------------------
    # Mail (if used) - may fail on sandboxed Mail
    # -------------------------------------------------------------------------
    echo "    Mail:"

    # Disable remote content in Mail (tracking pixels)
    if defaults write com.apple.mail-shared DisableURLLoading -bool true 2>/dev/null; then
        echo "      ✓ Disable remote content loading"
    else
        echo "      ⚠ Remote content (configure in Mail → Settings → Privacy)"
    fi

    # -------------------------------------------------------------------------
    # Misc
    # -------------------------------------------------------------------------
    echo "    Misc:"

    # Disable feedback assistant auto-gather
    defaults write com.apple.appleseed.FeedbackAssistant Autogather -bool false
    echo "      ✓ Disable Feedback Assistant auto-gather"

    # Note: Handoff left enabled for Universal Clipboard
    # Toggle: System Settings → General → AirDrop & Handoff

    echo ""
    echo "    Note: Some settings require logout or restart to take effect."
    echo "    For complete privacy, also check System Settings → Privacy & Security."
}

# =============================================================================
# PERSONAL SETTINGS
# =============================================================================

apply_personal_settings() {
    echo ""
    echo "==> Applying Personal Settings"

    # -------------------------------------------------------------------------
    # Appearance
    # -------------------------------------------------------------------------
    echo "    Appearance:"

    # Dark mode
    defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
    echo "      ✓ Dark mode enabled"

    # 24-hour time
    defaults write NSGlobalDomain AppleICUForce24HourTime -bool true
    echo "      ✓ 24-hour time"

    # -------------------------------------------------------------------------
    # Dock
    # -------------------------------------------------------------------------
    echo "    Dock:"

    # Auto-hide dock
    defaults write com.apple.dock autohide -bool true
    echo "      ✓ Auto-hide dock"

    # Set dock size
    defaults write com.apple.dock tilesize -int 48
    echo "      ✓ Dock size: 48"

    # Don't show recent apps
    defaults write com.apple.dock show-recents -bool false
    echo "      ✓ Hide recent apps"

    # Minimize windows to application icon
    defaults write com.apple.dock minimize-to-application -bool true
    echo "      ✓ Minimize to app icon"

    # -------------------------------------------------------------------------
    # Trackpad
    # -------------------------------------------------------------------------
    echo "    Trackpad:"

    # Tap to click
    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    echo "      ✓ Tap to click"

    # Fast tracking speed
    defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2.5
    echo "      ✓ Fast tracking speed"

    # -------------------------------------------------------------------------
    # Desktop
    # -------------------------------------------------------------------------
    echo "    Desktop:"

    # Don't show hard drives on desktop
    defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
    echo "      ✓ Hide hard drives on desktop"

    # Show external drives on desktop
    defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
    echo "      ✓ Show external drives on desktop"

    # -------------------------------------------------------------------------
    # Security
    # -------------------------------------------------------------------------
    echo "    Security:"

    # Require password immediately after sleep
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
    echo "      ✓ Require password immediately"
}

# =============================================================================
# MAIN
# =============================================================================

if [ "$APPLY_ALL" = true ]; then
    apply_dev_settings
    apply_debloat_settings
    apply_personal_settings
elif [ "$DEV_ONLY" = true ]; then
    apply_dev_settings
elif [ "$DEBLOAT_ONLY" = true ]; then
    apply_debloat_settings
else
    # Interactive mode
    echo ""

    if command -v gum &> /dev/null; then
        CHOICES=$(gum choose --no-limit --selected="Dev Settings,Debloat" \
            "Dev Settings" \
            "Debloat" \
            "Personal Settings")

        if echo "$CHOICES" | grep -q "Dev Settings"; then
            apply_dev_settings
        fi

        if echo "$CHOICES" | grep -q "Debloat"; then
            apply_debloat_settings
        fi

        if echo "$CHOICES" | grep -q "Personal Settings"; then
            apply_personal_settings
        fi
    else
        echo "Select settings to apply:"
        echo ""
        read -p "    Apply Dev Settings? [Y/n] " DEV_CHOICE
        if [[ ! "$DEV_CHOICE" =~ ^[Nn]$ ]]; then
            apply_dev_settings
        fi

        read -p "    Apply Debloat Settings? [Y/n] " DEBLOAT_CHOICE
        if [[ ! "$DEBLOAT_CHOICE" =~ ^[Nn]$ ]]; then
            apply_debloat_settings
        fi

        read -p "    Apply Personal Settings? [y/N] " PERSONAL_CHOICE
        if [[ "$PERSONAL_CHOICE" =~ ^[Yy]$ ]]; then
            apply_personal_settings
        fi
    fi
fi

# Restart affected applications
echo ""
echo "==> Restarting affected applications"
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
echo "    ✓ Finder, Dock, and SystemUIServer restarted"

echo ""
echo "======================================"
echo "  macOS Configuration Complete"
echo "======================================"
echo ""
echo "Some changes may require logout/restart to take effect."
echo ""
