#!/bin/bash
# Link dotfiles from repo to home directory
#
# Creates symlinks for all files in the home/ directory.
# Existing files are backed up to ~/.dotfiles-backup/
#
# Usage:
#   ./link-dotfiles.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_HOME="$(dirname "$SCRIPT_DIR")/home"
BACKUP_DIR="$HOME/.dotfiles-backup"

echo ""
echo "======================================"
echo "  Link Dotfiles"
echo "======================================"
echo ""

# Check if home directory exists
if [ ! -d "$DOTFILES_HOME" ]; then
    echo "Error: $DOTFILES_HOME not found"
    exit 1
fi

# Find all files in home/ (dotfiles and nested configs like .config/starship.toml)
cd "$DOTFILES_HOME"
FILES=$(find . -type f | sed 's|^\./||')

if [ -z "$FILES" ]; then
    echo "No dotfiles found in $DOTFILES_HOME"
    exit 0
fi

echo "==> Linking dotfiles"
echo ""

for file in $FILES; do
    SOURCE="$DOTFILES_HOME/$file"
    TARGET="$HOME/$file"

    # Ensure parent directory exists
    mkdir -p "$(dirname "$TARGET")"

    # Check if target already exists
    if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
        # Check if it's already the correct symlink
        if [ -L "$TARGET" ] && [ "$(readlink "$TARGET")" = "$SOURCE" ]; then
            echo "    ✓ $file (already linked)"
            continue
        fi

        # Backup existing file
        mkdir -p "$BACKUP_DIR"
        BACKUP_FILE="$BACKUP_DIR/$file.$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$(dirname "$BACKUP_FILE")"

        if [ -L "$TARGET" ]; then
            # It's a symlink pointing elsewhere
            echo "    → $file (updating symlink)"
            rm "$TARGET"
        else
            # It's a real file, back it up
            echo "    → $file (backing up to $BACKUP_FILE)"
            mv "$TARGET" "$BACKUP_FILE"
        fi
    else
        echo "    → $file (creating)"
    fi

    # Create symlink
    ln -sf "$SOURCE" "$TARGET"
done

echo ""
echo "==> Done"

if [ -d "$BACKUP_DIR" ]; then
    BACKUP_COUNT=$(find "$BACKUP_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$BACKUP_COUNT" -gt 0 ]; then
        echo ""
        echo "    Backups saved to: $BACKUP_DIR"
    fi
fi

echo ""
