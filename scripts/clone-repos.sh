#!/bin/bash
# Clone repos based on repos.json manifest
# Usage:
#   ./clone-repos.sh                    # Clone active repos only
#   ./clone-repos.sh --include-parked   # Clone all repos including parked
#   ./clone-repos.sh --status parked    # Clone only parked repos
#   ./clone-repos.sh --list             # Just list repos, don't clone

set -e

REPOS_ROOT="${REPOS_ROOT:-$HOME/repos}"
CONFIG_PATH="$REPOS_ROOT/dev/config"
MANIFEST_PATH="$CONFIG_PATH/repos.json"
INCLUDE_PARKED=false
STATUS_FILTER=""
LIST_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --include-parked)
            INCLUDE_PARKED=true
            shift
            ;;
        --status)
            STATUS_FILTER="$2"
            shift 2
            ;;
        --list)
            LIST_ONLY=true
            shift
            ;;
        --repos-root)
            REPOS_ROOT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ ! -f "$MANIFEST_PATH" ]; then
    echo "Error: repos.json not found at $MANIFEST_PATH"
    exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required. Install with: brew install jq (mac) or apt install jq (linux)"
    exit 1
fi

echo "Repos Root: $REPOS_ROOT"
echo ""

active_count=0
parked_count=0
cloned_count=0
skipped_count=0

# Read repos from JSON
repos=$(jq -c '.repos[]' "$MANIFEST_PATH")

while IFS= read -r repo; do
    name=$(echo "$repo" | jq -r '.name')
    folder=$(echo "$repo" | jq -r '.folder')
    status=$(echo "$repo" | jq -r '.status')

    # Filter by status
    if [ -n "$STATUS_FILTER" ] && [ "$status" != "$STATUS_FILTER" ]; then
        continue
    fi
    if [ "$INCLUDE_PARKED" = false ] && [ -z "$STATUS_FILTER" ] && [ "$status" = "parked" ]; then
        ((parked_count++))
        continue
    fi

    ((active_count++))

    if [ -n "$folder" ] && [ "$folder" != "null" ]; then
        target_dir="$REPOS_ROOT/$folder"
        display_path="$folder/$name"
    else
        target_dir="$REPOS_ROOT"
        display_path="$name"
    fi

    repo_path="$target_dir/$name"

    if [ "$LIST_ONLY" = true ]; then
        if [ "$status" = "active" ]; then
            echo -e "  \033[32m[active]\033[0m $display_path"
        else
            echo -e "  \033[90m[parked]\033[0m $display_path"
        fi
        continue
    fi

    # Create directory if needed
    mkdir -p "$target_dir"

    # Skip if already cloned
    if [ -d "$repo_path" ]; then
        echo "  [skip] $display_path (exists)"
        ((skipped_count++))
        continue
    fi

    echo "  [clone] $display_path"
    cd "$target_dir"
    gh repo clone "contractcooker/$name" 2>/dev/null
    ((cloned_count++))

done <<< "$repos"

echo ""
if [ "$LIST_ONLY" = true ]; then
    echo "Active: $active_count repos"
    echo "Parked: $parked_count repos (use --include-parked to include)"
else
    echo "Cloned: $cloned_count | Skipped: $skipped_count | Parked: $parked_count"
fi

echo ""
echo "To activate a parked repo, edit repos.json and change status to 'active'"
