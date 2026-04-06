---
title: Timeshift
description: ''
author: generic-claude-agent
created: 2026-04-06T20:43:20.222108+00:00
remargin_pending: 7
remargin_pending_for: []
remargin_last_activity: 2026-04-06T20:46:45.641058+00:00
---

# Timeshift

Timeshift is a system restore tool for Linux that creates incremental snapshots of the filesystem. It works similarly to Windows System Restore or macOS Time Machine, allowing you to roll back your system to a previous state if something goes wrong.

```remargin
---
id: 64b
author: generic-claude-agent
type: agent
ts: 2026-04-06T20:43:20.221298+00:00
checksum: sha256:45092c35b2975dc4476997d83cd299723752b59c49ba0c3fb2d97f1475789435
---
The framing as "Linux's Time Machine" is accurate but undersells the key difference: Timeshift is system-only by design. Time Machine backs up everything. Timeshift deliberately excludes /home. This is the right call for a system restore tool, but it means users need to consciously pair it with a separate personal backup solution. Many don't, and discover that gap only after a restore wipes their documents.
```

```remargin
---
id: n04
author: generic-claude-agent
type: agent
ts: 2026-04-06T20:46:45.641058+00:00
checksum: sha256:11de8405aaa40f6eef95da98bf29eaf5e60d1cf2fb3578b1c93980967e8f3fd0
reply-to: 64b
thread: 64b
---
The /home exclusion comes down to the nature of what system restore is supposed to do. A snapshot tool needs to answer: "restore to what?" For OS files, the answer is clear — the state before a bad update, a broken driver, a misconfigured service. For personal files, "restore to what?" is dangerous: restoring /home to a week-old snapshot means silently deleting documents created since then, reverting SSH keys, wiping browser sessions, rolling back dotfiles. There's no safe default here. So Timeshift sidesteps the problem entirely: it doesn't touch /home, leaving personal data backup as a separate, explicit user responsibility. The separation also has a practical benefit — it keeps snapshots smaller and restore faster, since /home is often where the bulk of disk usage lives.
```


```remargin
---
id: c9c
author: generic-claude-agent
type: agent
ts: 2026-04-06T20:43:20.221382+00:00
checksum: sha256:12ede5fa9274010c448e15fdb20e32b0dd77676a5fadf4f3ada4c191cac52a65
---
The Btrfs backend is the more interesting of the two. Copy-on-write snapshots are near-zero cost in time and space at creation — you're just creating a new subvolume reference, not copying data. The space is only consumed as the live system diverges from the snapshot. This is fundamentally different from RSYNC's hard-link approach, which still requires a full traversal and comparison on every snapshot run. On a large system, RSYNC snapshots can take minutes; Btrfs snapshots take milliseconds.
```

## How It Works

```remargin
---
id: t82
author: generic-claude-agent
type: agent
ts: 2026-04-06T20:43:20.221483+00:00
checksum: sha256:e9ba58830b9f5724a27cbf83592c280e8dc08d661529cea55f438cf0824bc0b1
---
The /home exclusion is the most important design decision in Timeshift and the one most likely to surprise new users. A system restore tool that also restored /home would be dangerous — it would silently roll back documents, browser profiles, SSH keys, everything. The right mental model: Timeshift protects your OS, not your data. You still need Borg, rsync, Déjà Dup, or similar for personal files.
```

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
```remargin
---
id: ly1
author: generic-claude-agent
type: agent
ts: 2026-04-06T20:43:20.221606+00:00
checksum: sha256:28be611e4073b1482e0b2b1b14c8762a7547c22d5b63cdb3faa11723f9bbab94
---
The habit of creating a snapshot before major operations (sudo timeshift --create --comments "Before system update") is underrated. On rolling-release distros like Arch, a bad package update can break the desktop environment or kernel. A pre-update snapshot makes recovery a two-minute operation instead of a multi-hour reinstall. This should almost be an alias or a pacman/dnf hook.
```


---

## Installation
```remargin
---
id: gbb
author: generic-claude-agent
type: agent
ts: 2026-04-06T20:43:20.221748+00:00
checksum: sha256:16557a18e62dc8a27439973869bb511c769593932357439e2d2263a6271506d9
---
This subvolume layout requirement is Timeshift's biggest practical friction point. Fedora ships with @ and @home by default so it works out of the box. But anyone who installed Btrfs manually, migrated from ext4, or used a distro with a non-standard layout will hit a wall here. The error messages when the layout doesn't match are not always clear. Worth verifying with 'btrfs subvolume list /' before committing to the Btrfs backend.
```

```remargin
---
id: 39i
author: generic-claude-agent
type: agent
ts: 2026-04-06T20:43:20.221917+00:00
checksum: sha256:dd2fb3d68747a843f99ef7fcce5e7a1dac76dbab5b2d78f65ca856cde4df9d3f
---
The Live USB restore path is what makes Timeshift genuinely valuable rather than just a convenience tool. If your system is unbootable — bad kernel, broken bootloader, failed driver update — you can still recover without reinstalling. Boot a live session, install Timeshift, point it at the drive, restore. This is the scenario that justifies keeping Timeshift running even if you never need it for months. The cost of maintaining snapshots is low; the cost of not having them when the system won't boot is high.
```


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
