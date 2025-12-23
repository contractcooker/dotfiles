# Windows Pre-Installation

Quick reference for creating a debloated Windows 11 installation on unsupported hardware.

## Overview

| Step | Tool | Purpose |
|------|------|---------|
| 1 | Ventoy | Create multi-boot USB |
| 2 | MicroWin | Create debloated ISO |
| 3 | Boot & Install | Install Windows |
| 4 | winutil | Post-install tweaks |

## Hardware: Z270i / i7-7700K / 3080 Ti

The i7-7700K is blocked from Windows 11 due to:
- CPU not on supported list (7th gen)
- TPM 2.0 requirement (Z270 has TPM 1.2)

**However**: Windows 11 runs fine on this hardware. Users report stable daily use with all updates working.

---

## Step 1: Set Up Ventoy USB

Ventoy lets you boot multiple ISOs from a single USB drive - no reflashing needed.

### Install Ventoy

```powershell
# Download from https://ventoy.net/en/download.html
# Or via winget:
winget install Ventoy.Ventoy
```

### Create Ventoy USB

1. Plug in USB drive (32GB+ recommended)
2. Run **Ventoy2Disk.exe**
3. Select your USB drive
4. Click **Install** (wipes drive)
5. Done - USB now has a large exFAT partition for ISOs

### Using Ventoy

Just copy any bootable ISO to the USB:
```
E:\                          (Ventoy USB)
├── Windows11-Debloated.iso
├── Ubuntu-24.04.iso
├── Hiren-BootCD.iso
└── whatever.iso
```

Boot from USB → Ventoy menu → pick an ISO → it boots.

---

## Step 2: Create Debloated ISO with MicroWin

MicroWin is built into [winutil](https://github.com/ChrisTitusTech/winutil). It creates a clean ISO before installation.

### Run MicroWin

```powershell
# Run from elevated PowerShell (or type 'winutil' if alias is set up)
irm "https://christitus.com/win" | iex
```

Go to the **MicroWin** tab.

### Initial Setup

| Option | Action | Notes |
|--------|--------|-------|
| **Download oscdimg.exe** | Click to download | Required tool for ISO creation. CTT hosts it so you don't need full Windows ADK |
| **Scratch directory** | Leave default | Temp files location. Check "Use ISO directory" only if C: drive is low on space |
| **Get Windows ISO** | Click "Download" | Downloads latest Windows 11. Wait for completion |

Select edition: **Windows 11 Pro**

### Configure Windows ISO Options

| Option | Recommendation | Notes |
|--------|---------------|-------|
| **Inject drivers** | Skip (usually) | For exotic hardware needing drivers during install. Z270/7700K/3080Ti don't need this |
| **Import Drivers from current system** | Check if building universal ISO | Exports all drivers from current machine into ISO |
| **Include VirtIO drivers** | Skip | Only for VMs (Proxmox, QEMU). Not needed for bare metal |
| **Copy to Ventoy** | Check | Copies finished ISO directly to your Ventoy USB |
| **User name** | Set if desired | Pre-creates local account. Leave password blank for easy initial setup |

### Tweaks Section

| Option | Recommendation | Notes |
|--------|---------------|-------|
| **Disable Windows Platform Binary Table** | Check | Prevents BIOS from injecting OEM bloatware. Good hygiene |
| **Allow this PC to upgrade to Windows 11** | Check | Bakes in TPM/CPU bypass for future Windows Updates on unsupported hardware |
| **Convert to ESD** | Skip | Smaller file but slower to create/install. Not worth it |
| **Skip First Logon Animation** | Check | Skips "Hi, we're getting things ready" animation. No downside |
| **WinUtil Configuration file** | Skip | Can bake in winutil tweaks. Better to run winutil post-install for flexibility |

### Start the Process

1. Click **Start the process**
2. Wait for ISO creation (~5-10 min)
3. ISO is copied to Ventoy USB (if option checked)

---

## Step 3: Install Windows

1. Boot from Ventoy USB (F11 or F12 on MSI boards)
2. Select your debloated ISO from Ventoy menu
3. Install Windows normally
4. Create local account (or use pre-configured one)

### If Hardware Check Fails (shouldn't with MicroWin ISO)

Fallback registry bypass:
1. Press **Shift+F10** to open cmd
2. Run `regedit`
3. Navigate to `HKEY_LOCAL_MACHINE\SYSTEM\Setup`
4. Create key: `LabConfig`
5. Create DWORDs (value=1):
   - `BypassTPMCheck`
   - `BypassSecureBootCheck`
   - `BypassCPUCheck`

---

## Step 4: Post-Install with winutil

After first boot:

```powershell
# Run as Administrator (or just type 'winutil' if alias set up)
irm "https://christitus.com/win" | iex
```

### Recommended Tweaks

Navigate to **Tweaks** tab:

**Essential Tweaks:**
- [x] Disable Telemetry
- [x] Disable Activity History
- [x] Disable Location Tracking
- [x] Disable Homegroup

**Keep enabled (gaming rig):**
- Xbox Game Bar
- Game Mode

---

## Step 5: NVIDIA Drivers (3080 Ti)

1. Let Windows Update install basic driver first
2. Download latest Game Ready Driver from [NVIDIA](https://www.nvidia.com/drivers)
3. Or: `winget install Nvidia.GeForceExperience`

---

## Building a Universal ISO (Multiple Machines)

Create one ISO that works on different hardware by combining drivers.

### Export Drivers from Each Machine

Run on each Windows machine:
```powershell
# Export third-party drivers to a folder
Export-WindowsDriver -Online -Destination "D:\Drivers\MachineName"
```

### Organize Driver Folders

```
D:\Drivers\
├── Laptop\
│   ├── intel-wifi\
│   ├── realtek-audio\
│   └── ...
└── Desktop-Z270i\
    ├── intel-chipset\
    ├── realtek-lan\
    └── ...
```

### Create Universal ISO

In MicroWin:
1. Check **"Inject drivers (I know what I'm doing)"**
2. Point to `D:\Drivers` parent folder
3. MicroWin includes all drivers from all subfolders

Windows detects hardware at install time and uses matching drivers.

---

## ISO Naming Convention

```
Win11-Pro-24H2-MicroWin.iso
Win11-Pro-25H2-MicroWin-2025-10.iso   (with date for tracking rebuilds)
```

Format: `Win11-[Edition]-[Version]-MicroWin[-Date].iso`

---

## Saving Your Config for Future Rebuilds

When a new Windows version drops, you'll rebuild the ISO. Save your settings to make this quick.

### Export WinUtil Config

After dialing in your settings in winutil:
1. Go to the config/export area
2. Export to JSON
3. Save as `dotfiles/windows/winutil-config.json`

### Rebuild Workflow (New Windows Version)

1. Run `winutil` → MicroWin tab
2. Download new Windows ISO
3. Import your saved JSON config
4. Create ISO → Copy to Ventoy
5. Delete old ISO from Ventoy (or keep for rollback)

### Version Your Configs

```
dotfiles/windows/
├── winutil-config.json           ← current config
└── archive/
    ├── winutil-config-24H2.json  ← old versions
    └── winutil-config-25H2.json
```

---

## Receiving Future Updates

With "Allow this PC to upgrade to Windows 11" checked, updates should come through Windows Update normally.

If updates are blocked:
1. Download new ISO from Microsoft
2. Run setup.exe from within Windows to upgrade

---

## Troubleshooting

### "This PC doesn't meet requirements" during install
- Shouldn't happen with MicroWin ISO
- Use registry bypass (Shift+F10 → regedit → LabConfig)

### Black screen after install (3080 Ti)
- Wait ~5 min for Windows to auto-install basic driver
- Or boot to safe mode and install NVIDIA drivers

### Updates failing
```powershell
sfc /scannow
DISM /Online /Cleanup-Image /RestoreHealth
```

---

## Automating Post-Install Setup

MicroWin doesn't have built-in support for custom post-install scripts, but you can inject one after creating the ISO.

### How It Works

MicroWin creates `C:\Windows\FirstStartup.ps1` which runs on first user login. We append our setup script call to it.

### Option A: Modify WIM on Ventoy (Recommended)

If you use Ventoy, extract the ISO to a folder and modify the WIM directly:

```
E:\                           (Ventoy USB)
└── Win11-MicroWin\           (extracted ISO folder)
    └── sources\
        └── install.wim       ← modify this
```

```powershell
# Run as Administrator
.\scripts\inject-postinstall.ps1 -WimPath "E:\Win11-MicroWin\sources\install.wim"
```

Ventoy can boot from extracted ISO folders, not just .iso files.

### Option B: Create New ISO

If you need a standalone .iso file:

```powershell
# Run as Administrator
.\scripts\inject-postinstall.ps1 `
    -IsoPath "C:\ISOs\Win11-MicroWin.iso" `
    -OutputIso "C:\ISOs\Win11-MicroWin-Custom.iso"
```

Requires `oscdimg.exe` (MicroWin can download this for you).

### What Gets Injected

The script appends to FirstStartup.ps1:

```powershell
# Downloads and runs setup-windows.ps1 on first login
irm https://raw.githubusercontent.com/contractcooker/dotfiles/main/scripts/setup-windows.ps1 | iex
```

### Workflow for New Machines

1. Create MicroWin ISO (Step 2 above)
2. Before copying to Ventoy, run `inject-postinstall.ps1`
3. Copy modified ISO/folder to Ventoy USB
4. Boot and install Windows
5. On first login, setup runs automatically

### Testing Without Modifying

Use `-DryRun` to see what would change:

```powershell
.\scripts\inject-postinstall.ps1 -WimPath "E:\sources\install.wim" -DryRun
```

---

## References

- [Ventoy](https://ventoy.net/)
- [MicroWin Documentation](https://winutil.christitus.com/userguide/microwin/)
- [winutil GitHub](https://github.com/ChrisTitusTech/winutil)
