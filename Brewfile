# Brewfile - Homebrew dependencies for development environment
#
# Format: brew/cask "name" # [category] Description
#
# Categories:
#   [base]          - Essential everywhere (including servers)
#   [desktop]       - Requires GUI environment (not for servers)
#   [dev]           - Development tools
#   [gaming]        - Games and gaming platforms
#   [personal]      - Personal apps (not for work)
#   [browser]       - Web browsers
#   [communication] - Chat and video apps
#   [utility]       - System utilities
#
# Profiles determine which categories are installed:
#   Personal - base, desktop, dev, gaming, personal, browser, communication, utility
#   Work     - base, desktop, dev, browser, communication, utility
#   Server   - base only
#
# Usage:
#   ./scripts/install-packages.sh                   # Interactive
#   ./scripts/install-packages.sh --profile personal
#   brew bundle --file=Brewfile                     # Install everything

# =============================================================================
# Base (installed everywhere, including servers)
# =============================================================================

brew "git"                        # [base] Version control
brew "gh"                         # [base] GitHub CLI
brew "jq"                         # [base] JSON processor
brew "gum"                        # [base] Terminal UI for scripts
brew "mas"                        # [base] Mac App Store CLI
brew "fnm"                        # [base] Node.js version manager
brew "uv"                         # [base] Python version/package manager

# =============================================================================
# Desktop (requires GUI, not for servers)
# =============================================================================

cask "1password"                  # [desktop] Password manager
brew "1password-cli"              # [desktop] 1Password CLI (needs app for SSH agent)
cask "dropbox"                    # [desktop] File sync
mas "1Password for Safari", id: 1569813296    # [desktop] Browser extension

# =============================================================================
# Development Tools
# =============================================================================

brew "gitleaks"                   # [dev] Scan repos for secrets
brew "git-filter-repo"            # [dev] Rewrite git history (remove secrets/files)
brew "bash"                       # [dev] Updated bash (macOS has old 3.x)
brew "zsh-autosuggestions"        # [dev] Fish-like autosuggestions
brew "zsh-syntax-highlighting"    # [dev] Fish-like syntax highlighting
brew "starship"                   # [dev] Cross-shell prompt
brew "ollama"                     # [dev] Run LLMs locally
brew "minicom"                    # [dev] Serial port terminal
brew "google-cloud-sdk"           # [dev] Google Cloud CLI
brew "android-platform-tools"     # [dev] adb, fastboot, etc.

cask "visual-studio-code"         # [dev] Code editor
cask "jetbrains-toolbox"          # [dev] JetBrains IDE manager
cask "iterm2"                     # [dev] Terminal emulator
cask "transmit"                   # [dev] SFTP/S3 client
cask "beyond-compare"             # [dev] File/folder comparison
cask "serial"                     # [dev] Serial port terminal (GUI)

mas "Xcode", id: 497799835                    # [dev] Apple IDE
mas "Developer", id: 640199958                # [dev] Apple developer resources
mas "Swift Playgrounds", id: 1496833156       # [dev] Learn/prototype Swift

# =============================================================================
# Gaming
# =============================================================================

cask "steam"                      # [gaming] Steam platform
cask "gog-galaxy"                 # [gaming] GOG launcher
cask "epic-games"                 # [gaming] Epic Games launcher
cask "geforce-now"                # [gaming] Cloud gaming

mas "Mini Motorways", id: 1456188526          # [gaming] Puzzle game

# =============================================================================
# Personal (not for work machines)
# =============================================================================

cask "pages"                      # [personal] Word processor
cask "numbers"                    # [personal] Spreadsheets
cask "keynote"                    # [personal] Presentations
cask "ticktick"                   # [personal] Task manager

cask "signal"                     # [personal] Encrypted messaging
cask "spotify"                    # [personal] Music streaming
cask "plex-media-server"          # [personal] Media server

mas "Final Cut Pro", id: 424389933            # [personal] Video editor
mas "Logic Pro", id: 634148309                # [personal] Audio workstation
mas "Compressor", id: 424390742               # [personal] Video encoder
mas "GarageBand", id: 682658836               # [personal] Music creation
mas "CARROT Weather", id: 993487541           # [personal] Weather with personality
mas "Paprika Recipe Manager 3", id: 1303222628  # [personal] Recipe organizer

# =============================================================================
# Browser
# =============================================================================

cask "google-chrome"              # [browser] Chrome
cask "orion"                      # [browser] WebKit + extensions

mas "Kagi Search", id: 1622835804             # [browser] Kagi Safari extension

# =============================================================================
# Communication
# =============================================================================

cask "slack"                      # [communication] Team chat
cask "discord"                    # [communication] Voice/text chat
cask "zoom"                       # [communication] Video conferencing

# =============================================================================
# Utility
# =============================================================================

cask "rectangle"                  # [utility] Window management
cask "appcleaner"                 # [utility] App uninstaller
cask "daisydisk"                  # [utility] Disk space analyzer
cask "coconutbattery"             # [utility] Battery health monitor
cask "balenaetcher"               # [utility] Disk image flasher
cask "sd-card-formatter"          # [utility] SD card formatter
cask "microsoft-remote-desktop"   # [utility] Remote desktop client

mas "Dynamic Wallpaper", id: 1453504509       # [utility] Animated wallpapers
mas "AJA System Test Lite", id: 1092006274    # [utility] Disk speed testing
