# Timeshift

Timeshift is a system restore tool for Linux that creates incremental snapshots of the filesystem. It works similarly to Windows System Restore or macOS Time Machine, allowing you to roll back your system to a previous state if something goes wrong.

## How It Works

Timeshift supports two snapshot backends:

### RSYNC (default)
- Uses `rsync` + hard links to create incremental snapshots
- Snapshots are stored as regular directories on the filesystem
- Only changed files consume additional space; unchanged files are hard-linked from previous snapshots
- Works on any Linux filesystem (ext4, xfs, btrfs, etc.)
- Snapshots are stored at `/run/timeshift/backup/timeshift-btrfs/snapshots/` or a custom location

### BTRFS
- Uses native Btrfs subvolume snapshots (`btrfs subvolume snapshot`)
- Requires the root filesystem to be Btrfs with `@` and `@home` subvolumes
- Snapshots are near-instant and extremely space-efficient (copy-on-write)
- Stored as Btrfs subvolumes alongside `@` and `@home`

### What Gets Snapshotted
By default, Timeshift snapshots **system files only** (`/`, `/usr`, `/etc`, `/opt`, etc.).
`/home` is **excluded by default** to avoid overwriting personal data on restore. This can be configured.

Excluded by default:
- `/home/**` (user data)
- `/root/**`
- `/media`, `/mnt`, `/tmp`, `/proc`, `/sys`, `/dev`

### Snapshot Schedule
Timeshift can create snapshots automatically on a schedule:
- **Boot** — on every boot
- **Hourly / Daily / Weekly / Monthly** — via a background daemon

---

## Installation

### Fedora / RHEL-based
```bash
sudo dnf install timeshift
```

### Ubuntu / Debian-based
```bash
sudo apt install timeshift
```

### Arch Linux
```bash
sudo pacman -S timeshift
# or from AUR:
yay -S timeshift
```

### Enable and start the daemon (for scheduled snapshots)
```bash
sudo systemctl enable --now cronie   # Fedora/Arch (uses cron)
sudo systemctl enable --now cron     # Debian/Ubuntu
```

---

## Basic Usage

### GUI
Launch `timeshift-gtk` (or search "Timeshift" in your app menu) and follow the setup wizard.

### CLI

Create a snapshot manually:
```bash
sudo timeshift --create --comments "Before system update"
```

List existing snapshots:
```bash
sudo timeshift --list
```

Restore a snapshot:
```bash
sudo timeshift --restore --snapshot "2025-01-01_12-00-00"
```

Delete a snapshot:
```bash
sudo timeshift --delete --snapshot "2025-01-01_12-00-00"
```

---

## Btrfs Setup Requirements

For the Btrfs backend, your partition layout must use the standard subvolume layout:

| Subvolume | Mount point |
|-----------|-------------|
| `@`       | `/`         |
| `@home`   | `/home`     |

You can verify with:
```bash
sudo btrfs subvolume list /
```

---

## Restore from Live USB

If the system is unbootable, boot from a Live USB, install Timeshift on the live session, and restore from there:

```bash
sudo timeshift --restore
```

Timeshift will detect snapshots on connected drives and guide you through the restore process.
