# Windows Pre-Installation

Quick reference for creating a debloated Windows 11 installation on unsupported hardware.

## Overview

| Step | Tool | Purpose |
|------|------|---------|
| 1 | MicroWin | Create debloated ISO |
| 2 | Rufus | Create bootable USB with bypasses |
| 3 | winutil | Post-install tweaks |

## Hardware: Z270i / i7-7700K / 3080 Ti

The i7-7700K is blocked from Windows 11 due to:
- CPU not on supported list (7th gen)
- TPM 2.0 requirement (Z270 has TPM 1.2)

**However**: Windows 11 runs fine on this hardware. Users report stable daily use with all updates working.

## Step 1: Create Debloated ISO with MicroWin

MicroWin is built into [winutil](https://github.com/ChrisTitusTech/winutil). It creates a clean ISO before installation (cleaner than post-install scripts).

### Get Windows ISO
1. Download official ISO from [Microsoft](https://www.microsoft.com/software-download/windows11)
2. Or use [UUPDump](https://uupdump.net/) for Enterprise edition (cleanest option)

### Run MicroWin
```powershell
# Run from elevated PowerShell on any Windows machine
irm "https://christitus.com/win" | iex
```

1. Go to **MicroWin** tab
2. Click **Select Windows ISO**
3. Select edition: **Windows 11 Pro**
4. Check these options:
   - [x] Remove Edge
   - [x] Remove Microsoft Copilot (Recall)
   - [x] Disable Telemetry
   - [x] Disable WiFi-Sense
   - [x] Skip OOBE (bypass Microsoft account)
5. Click **Start the process**
6. Wait for ISO creation (~5-10 min)

## Step 2: Create Bootable USB with Rufus

[Rufus](https://rufus.ie/) creates the USB and bypasses hardware checks.

1. Download Rufus (portable is fine)
2. Insert USB drive (8GB+)
3. Select your MicroWin ISO
4. Click **START**
5. When prompted, check:
   - [x] Remove requirement for 4GB+ RAM, Secure Boot and TPM 2.0
   - [x] Remove requirement for an online Microsoft account
   - [x] Disable data collection

## Step 3: Install Windows

1. Boot from USB (F11 or F12 on MSI boards)
2. If any hardware check fails, use registry bypass:
   - Press **Shift+F10** to open cmd
   - Run `regedit`
   - Navigate to `HKEY_LOCAL_MACHINE\SYSTEM\Setup`
   - Create key: `LabConfig`
   - Create DWORDs (value=1):
     - `BypassTPMCheck`
     - `BypassSecureBootCheck`
     - `BypassCPUCheck`
3. Continue installation normally
4. Create local account (skip Microsoft account)

## Step 4: Post-Install with winutil

After first boot, run winutil for remaining tweaks:

```powershell
# Run as Administrator
irm "https://christitus.com/win" | iex
```

### Tweaks Tab - Recommended
Navigate to **Tweaks** and apply:

**Essential Tweaks** (click preset or select manually):
- [x] Disable Telemetry
- [x] Disable Activity History
- [x] Disable Location Tracking
- [x] Disable Homegroup
- [x] Disable GameDVR (keep Xbox Game Bar)

**Additional Tweaks**:
- [x] Set Services to Manual
- [x] Enable Dark Mode
- [x] Show File Extensions
- [x] Show Hidden Files

**Do NOT disable** (gaming rig):
- Xbox Game Bar
- Game Mode

### Install Tab
Use for quick app installs via winget/chocolatey, but we'll use our own `setup-windows.ps1` instead.

## Step 5: NVIDIA Drivers

For the 3080 Ti:
1. Let Windows Update install basic driver first
2. Download latest Game Ready Driver from [NVIDIA](https://www.nvidia.com/drivers)
3. Or install via winget: `winget install Nvidia.GeForceExperience`

## Receiving Future Updates

Unsupported hardware won't receive feature updates via Windows Update automatically. Options:

1. **Manual ISO upgrade**: Download new ISO yearly and run setup.exe
2. **Registry workaround**: Set target release version in registry (advanced)
3. **Accept it**: Security updates still work, just not feature updates

## Troubleshooting

### "This PC doesn't meet requirements" during install
- Use Rufus with bypass options
- Or apply registry bypass during setup (Shift+F10)

### Updates failing
- Run `sfc /scannow` and `DISM /Online /Cleanup-Image /RestoreHealth`
- Check Windows Update troubleshooter

### Black screen after install (3080 Ti)
- Boot to safe mode, install NVIDIA drivers
- Or wait ~5 minutes for Windows to auto-install basic driver

## References

- [MicroWin Documentation](https://winutil.christitus.com/userguide/microwin/)
- [winutil GitHub](https://github.com/ChrisTitusTech/winutil)
- [Rufus](https://rufus.ie/)
- [TPM Bypass Guide - Tom's Hardware](https://www.tomshardware.com/how-to/bypass-windows-11-tpm-requirement)
