# Brewfile - Homebrew dependencies for development environment
#
# Format: brew/cask "name" # [tag] Description
#   [core]     = installed automatically
#   [category] = optional, shown in interactive picker grouped by category
#
# Usage:
#   ./scripts/install-packages.sh    # Interactive (parses this file)
#   brew bundle --file=Brewfile      # Install everything

# =============================================================================
# Formulae
# =============================================================================

brew "git"                        # [core] Version control
brew "gh"                         # [core] GitHub CLI
brew "jq"                         # [core] JSON processor
brew "gum"                        # [core] Terminal UI for scripts
brew "mas"                        # [core] Mac App Store CLI

brew "gitleaks"                   # [security] Scan repos for secrets
brew "bash"                       # [shell] Updated bash (macOS has old 3.x)
brew "zsh-autosuggestions"        # [shell] Fish-like autosuggestions
brew "zsh-syntax-highlighting"    # [shell] Fish-like syntax highlighting
brew "starship"                   # [shell] Cross-shell prompt
brew "uv"                         # [languages] Python version/package manager
brew "fnm"                        # [core] Node.js version manager
brew "ollama"                     # [ai] Run LLMs locally
brew "minicom"                    # [hardware] Serial port terminal
brew "google-cloud-sdk"           # [cloud] Google Cloud CLI
brew "android-platform-tools"     # [mobile] adb, fastboot, etc.

# brew "ansible"                  # [cloud] Configuration management
# brew "terraform"                # [cloud] Infrastructure as code

# =============================================================================
# Casks
# =============================================================================

cask "1password"                  # [core] Password manager
cask "1password-cli"              # [core] 1Password CLI
cask "dropbox"                    # [core] File sync

cask "visual-studio-code"         # [dev] Code editor
cask "jetbrains-toolbox"          # [dev] JetBrains IDE manager
cask "iterm2"                     # [dev] Terminal emulator
cask "transmit"                   # [dev] SFTP/S3 client
cask "beyond-compare"             # [dev] File/folder comparison
cask "serial"                     # [dev] Serial port terminal (GUI)

cask "rectangle"                  # [utility] Window management
cask "appcleaner"                 # [utility] App uninstaller
cask "daisydisk"                  # [utility] Disk space analyzer
cask "coconutbattery"             # [utility] Battery health monitor
cask "balenaetcher"               # [utility] Disk image flasher
cask "sd-card-formatter"          # [utility] SD card formatter

cask "google-chrome"              # [browser] Chrome
cask "orion"                      # [browser] WebKit + extensions

cask "slack"                      # [communication] Team chat
cask "discord"                    # [communication] Voice/text chat
cask "signal"                     # [communication] Encrypted messaging
cask "zoom"                       # [communication] Video conferencing

cask "spotify"                    # [media] Music streaming
cask "plex-media-server"          # [media] Media server
cask "steam"                      # [gaming] Steam platform
cask "gog-galaxy"                 # [gaming] GOG launcher
cask "epic-games"                 # [gaming] Epic Games launcher
cask "geforce-now"                # [gaming] Cloud gaming
