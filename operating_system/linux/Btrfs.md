# Btrfs (B-Tree File System)

Pronounced **"Butter FS"** — think of it as the filesystem that makes your data **smooth like butter**.

## What Is It?

Btrfs is a **copy-on-write (CoW) filesystem** for Linux. It was designed to replace ext4 by adding modern features like snapshots, checksums, and built-in RAID — things that traditionally required separate tools (LVM, mdadm, fsck).

> **Mnemonic — "Btrfs = Better FS"**: It aims to be a *better filesystem* by bundling storage management features directly into the filesystem layer.

## Core Concepts

### 1. Copy-on-Write (CoW)

Instead of overwriting data in place, Btrfs writes changes to a **new location** and then updates the pointer.

> **Mnemonic — "Never erase, just relocate"**: Imagine writing on sticky notes instead of erasing a whiteboard. You write the new note, stick it on, and remove the old one. The old data is never half-erased.

**Why it matters:**
- No partial writes — if power fails mid-write, the old data is still intact
- Enables instant snapshots (just keep the old pointers around)

```
Traditional:  [Block A] → overwrite → [Block A'] (risky if interrupted)
Btrfs CoW:    [Block A] stays, writes [Block A'] elsewhere, then swaps pointer
```

### 2. Subvolumes

A subvolume is like a **mini filesystem inside Btrfs**. Each one can be mounted independently and snapshotted separately.

> **Mnemonic — "Drawers in a dresser"**: The Btrfs partition is the dresser. Each subvolume is a drawer — they share the same piece of furniture but you can open, organize, or lock each one independently.

```bash
# Create a subvolume
sudo btrfs subvolume create /mnt/data/projects

# List subvolumes
sudo btrfs subvolume list /mnt/data

# Delete a subvolume
sudo btrfs subvolume delete /mnt/data/projects
```

A typical layout:

```
/           → @          (root subvolume)
/home       → @home      (home subvolume)
/snapshots  → @snapshots (snapshot storage)
```

### 3. Snapshots

A snapshot is a **frozen copy of a subvolume at a point in time**. Because of CoW, creating one is instant and costs almost no extra space — it just preserves the existing pointers.

> **Mnemonic — "Photograph, not a photocopy"**: A snapshot is like taking a photo of your room. It's instant and takes no extra room space. Only when you start *changing* things does extra space get used (to keep both the old and new version).

```bash
# Create a read-only snapshot
sudo btrfs subvolume snapshot -r /mnt/data/@home /mnt/data/@snapshots/home-2026-02-13

# Create a writable snapshot (for testing changes)
sudo btrfs subvolume snapshot /mnt/data/@home /mnt/data/@snapshots/home-test

# Restore: just delete the broken subvolume and snapshot back
sudo btrfs subvolume delete /mnt/data/@home
sudo btrfs subvolume snapshot /mnt/data/@snapshots/home-2026-02-13 /mnt/data/@home
```

### 4. Checksums (Data Integrity)

Btrfs calculates a **checksum for every block of data and metadata**. On every read, it verifies the checksum. If it detects corruption (bit rot), it can auto-repair from a RAID mirror.

> **Mnemonic — "Built-in lie detector"**: Every piece of data carries its own fingerprint. If the data changes behind your back (disk rot, bad RAM), Btrfs catches the lie immediately.

### 5. Built-in RAID

Btrfs can manage **multiple disks** and apply RAID levels without needing mdadm.

> **Mnemonic — "One tool, not three"**: Traditional Linux needs `mdadm` (RAID) + `LVM` (volumes) + `ext4` (filesystem). Btrfs replaces all three — it's the Swiss Army knife of filesystems.

```bash
# Create a RAID1 (mirror) filesystem across two drives
sudo mkfs.btrfs -d raid1 -m raid1 /dev/sdb /dev/sdc

# Add a new device to an existing filesystem
sudo btrfs device add /dev/sdd /mnt/data

# Rebalance data across all devices
sudo btrfs balance start /mnt/data
```

| RAID Level | Data Copies | Min Disks | Use Case                    |
|------------|-------------|-----------|------------------------------|
| raid0      | 1 (striped) | 2         | Performance, no redundancy   |
| raid1      | 2 (mirrored)| 2         | Redundancy for important data|
| raid10     | 2 (striped mirrors) | 4 | Performance + redundancy    |

> **Note:** Btrfs RAID5/6 is still considered unstable — avoid for production.

### 6. Compression

Btrfs can transparently compress data on the fly.

> **Mnemonic — "Vacuum-sealed storage"**: Like vacuum bags for clothes — everything takes less space, and you don't notice the difference when you pull it out.

```bash
# Mount with zstd compression (best balance of speed and ratio)
sudo mount -o compress=zstd /dev/sdb /mnt/data

# Or set it in /etc/fstab
UUID=xxx  /mnt/data  btrfs  defaults,compress=zstd  0  0
```

| Algorithm | Speed   | Compression Ratio | Best For              |
|-----------|---------|--------------------|-----------------------|
| lzo       | Fastest | Lowest             | Fast storage, SSDs    |
| zlib      | Slow    | Highest            | Archival              |
| zstd      | Fast    | High               | General use (default) |

## Common Commands Cheat Sheet

```bash
# Create a Btrfs filesystem
sudo mkfs.btrfs /dev/sdb

# Show filesystem usage
sudo btrfs filesystem usage /mnt/data

# Scrub — verify all checksums and fix errors from mirrors
sudo btrfs scrub start /mnt/data
sudo btrfs scrub status /mnt/data

# Defragment a file or directory
sudo btrfs filesystem defragment -r /mnt/data

# Show all Btrfs filesystems
sudo btrfs filesystem show
```

## When to Use Btrfs

| Scenario                        | Btrfs? | Why                                       |
|---------------------------------|--------|-------------------------------------------|
| Desktop / workstation           | Yes    | Snapshots before updates = easy rollback  |
| NAS / file server               | Yes    | Checksums + RAID + compression            |
| Database server (heavy writes)  | Maybe  | CoW can cause fragmentation; use `nodatacow` for DB files |
| Tiny embedded system            | No     | Overhead too high; use ext4 or squashfs   |

## Quick Mental Model

```
                        Btrfs
                 "Butter makes it smooth"
                          |
         ┌────────┬───────┼────────┬──────────┐
         │        │       │        │          │
       CoW    Subvolumes  │    Checksums    RAID
   "sticky    "drawers    │   "lie          "Swiss
    notes"    in dresser" │   detector"     Army knife"
                          │
                      Snapshots
                   "photograph,
                  not photocopy"
```

## Btrfs vs ext4 at a Glance

| Feature          | ext4           | Btrfs                  |
|------------------|----------------|------------------------|
| Copy-on-Write    | No             | Yes                    |
| Snapshots        | No (needs LVM) | Built-in               |
| Checksums        | Metadata only  | Data + metadata        |
| Compression      | No             | lzo, zlib, zstd        |
| Multi-device     | No (needs mdadm)| Built-in RAID         |
| Max file size    | 16 TB          | 16 EB                  |
| Maturity         | Very stable    | Stable (except RAID5/6)|
