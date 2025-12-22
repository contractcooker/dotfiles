# Dropbox Sync Strategy

Cross-platform file sync using Dropbox to share Desktop, Documents, and Downloads between Mac and Windows machines.

## Overview

- **Subscription**: 1TB via Rekordbox (Cloud Option DJ team)
- **Primary machine**: Mac (creates the folder structure)
- **Sync method**: Mac uses Dropbox backup feature, Windows redirects shell folders

## Folder Structure

```
Dropbox (Cloud Option DJ team Dropbox)/
└── Thomas Barron/
    └── Mac/
        ├── Desktop/
        ├── Documents/
        └── Downloads/
```

Both Mac and Windows point to these same folders, enabling true two-way sync.

## Mac Configuration

Mac uses Dropbox's built-in "Back up folders" feature:

1. **Install Dropbox** (via Homebrew or download)
2. **Sign in** to your Dropbox account
3. **Enable folder backup**:
   - Click Dropbox menu bar icon → Settings (gear icon)
   - Go to "Backups" tab
   - Click "Set up" or "Manage backup"
   - Enable Desktop, Documents, Downloads
4. **Wait for initial sync** to complete

### What this does

- Moves your folders into `~/Dropbox/.../Mac/`
- Creates aliases at `~/Desktop`, `~/Documents`, `~/Downloads` pointing to Dropbox
- Folder names automatically include "Mac" (cannot be changed)

### Verify setup

```bash
# Check where Documents actually points
ls -la ~/Documents
# Should show: Documents -> /Users/husker/Library/CloudStorage/Dropbox-.../Mac/Documents
```

## Windows Configuration

Windows redirects shell folders to the Mac-created Dropbox folders:

1. **Install Dropbox** (via winget or download)
2. **Sign in** to your Dropbox account
3. **Wait for Dropbox to sync** the folder structure
4. **Redirect each folder** (Documents, Desktop, Downloads):

### Redirect Documents

1. Open File Explorer
2. Right-click "Documents" in sidebar → Properties
3. Go to "Location" tab
4. Click "Move..."
5. Navigate to: `C:\Users\<username>\Cloud Option DJ team Dropbox\Thomas Barron\Mac\Documents`
6. Click "Select Folder" → "OK"
7. When prompted to move files, click "Yes"

### Redirect Desktop

Same process, selecting the `Mac\Desktop` folder.

### Redirect Downloads

Same process, selecting the `Mac\Downloads` folder.

### Verify setup

```powershell
# Check Documents location
(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders').Personal
# Should show the Dropbox path
```

## What Gets Synced

| Content | Synced | Notes |
|---------|--------|-------|
| Documents | Yes | All documents available on both |
| Desktop | Yes | Desktop icons/files shared |
| Downloads | Yes | Downloaded files appear on both |
| Screenshots | Yes | If saved to Desktop/Documents |
| App configs in Documents | Yes | Some apps store settings here |

## What Stays Local

| Content | Location | Notes |
|---------|----------|-------|
| Git repos | `~/repos` | Git handles versioning |
| Applications | System folders | Installed separately |
| System configs | Various | Platform-specific |

## Exclusions and Selective Sync

Consider excluding from sync (in Dropbox preferences → Selective Sync):

- Large downloads you don't need everywhere
- Platform-specific app caches
- Temporary files

Files to consider adding to Dropbox's ignore list:
- `.DS_Store` (Mac)
- `Thumbs.db` (Windows)
- `*.tmp`

## Troubleshooting

### Conflicted copies

If you see files named `filename (conflicted copy).ext`:
- Both machines edited the file simultaneously
- Review both versions and keep the correct one
- Delete the conflicted copy

### Sync not working

1. Check Dropbox is running (menu bar / system tray)
2. Check you're signed in to the correct account
3. Verify internet connection
4. Check Dropbox has finished syncing (green checkmarks)

### Windows folder not redirecting

- Ensure Dropbox has fully synced before redirecting
- The target folder must exist in Dropbox
- Run File Explorer as Administrator if permission denied

## Automation Notes

### Mac

Dropbox backup feature requires manual setup through the GUI. The setup script:
- Installs Dropbox via Homebrew
- Prompts user to complete configuration manually

### Windows

Folder redirection can be partially automated via PowerShell, but requires:
- Dropbox to be installed and synced first
- User confirmation (moving files is destructive if wrong)

The setup script:
- Installs Dropbox via winget
- Prompts user to complete folder redirection manually
