# File System

## What is a File System?

A **file system** is the layer of an operating system that manages how data is stored, organized, and retrieved on a storage device. It defines:

- How files are named, structured, and located
- How space is allocated and freed
- Metadata (permissions, timestamps, ownership)
- The interface between the OS and raw disk storage

Without a file system, a disk is just a flat sequence of bytes with no structure.

```
Without FS:                      With FS:
┌──────────────────────┐        ┌──────────────────────┐
│ 0x4A 0x2F 0x00 0xAB  │        │  /home/user/file.txt │
│ 0xFF 0x12 0x88 0x3C  │  --->  │  /etc/config.conf    │
│ 0x01 0x7E 0xC4 0x5D  │        │  /bin/bash           │
│ ...raw bytes...      │        │  structured tree      │
└──────────────────────┘        └──────────────────────┘
```

---

## Linux File System

### The Unified Virtual File System (VFS)

Linux uses a **Virtual File System (VFS)** abstraction layer. This lets the kernel expose a single, uniform interface regardless of what the underlying file system actually is (ext4, btrfs, tmpfs, etc.).

```
User Space
  │
  │  open("/home/user/file.txt")
  ▼
┌─────────────────────────────────────────┐
│             VFS Layer (kernel)          │
│  - Unified API: open/read/write/close   │
│  - Manages inodes, dentries, file objs  │
└────────────┬───────────┬───────────────┘
             │           │
    ┌─────────▼───┐  ┌────▼──────┐  ┌──────────┐
    │    ext4     │  │   btrfs   │  │  tmpfs   │
    └─────────────┘  └───────────┘  └──────────┘
             │
    ┌─────────▼───────────┐
    │   Block Device Layer│
    │   (disk, SSD, etc.) │
    └─────────────────────┘
```

---

### The Filesystem Hierarchy Standard (FHS)

Linux organizes everything under a **single root `/`**. Every device, file, and directory is part of this tree — unlike Windows which uses drive letters (C:\, D:\).

```
/
├── bin/      → Essential user binaries (ls, cp, bash)
├── boot/     → Bootloader, kernel images
├── dev/      → Device files (disks, terminals, null)
├── etc/      → System-wide configuration files
├── home/     → User home directories
│   └── manuel/
├── lib/      → Shared libraries
├── mnt/      → Temporary mount points
├── opt/      → Optional/third-party software
├── proc/     → Virtual FS: running processes & kernel info
├── root/     → Home for the root user
├── srv/      → Data for system services
├── sys/      → Virtual FS: hardware/kernel objects
├── tmp/      → Temporary files (cleared on reboot)
├── usr/      → User utilities and applications
│   ├── bin/
│   ├── lib/
│   └── share/
└── var/      → Variable data: logs, caches, databases
```

---

### How Storage is Organized: Inodes

Every file and directory is represented by an **inode** (index node). The inode stores metadata but **not** the filename.

```
  Directory Entry          Inode Table             Data Blocks
┌──────────────────┐    ┌──────────────────┐    ┌──────────────┐
│ "file.txt" → 42  │--->│ inode #42        │--->│ Block 1001   │
└──────────────────┘    │  size: 1024 B    │    │ "Hello Wor"  │
                        │  uid: 1000       │    ├──────────────┤
                        │  permissions:    │    │ Block 1002   │
                        │   rw-r--r--      │    │ "ld..."      │
                        │  atime, mtime,   │    └──────────────┘
                        │  ctime           │
                        │  block ptrs:     │
                        │  [1001, 1002]    │
                        └──────────────────┘
```

Key insight: **filenames live in directories, not in inodes**. This is how hard links work — two directory entries pointing to the same inode.

---

### Disk Layout of ext4 (most common Linux FS)

ext4 divides the disk into **block groups**. Each group is self-contained with its own superblock copy, bitmaps, and inode table.

```
Disk
┌──────────┬──────────────────────────────────────────────────┐
│  Boot    │         Partition                                 │
│  Block   │                                                   │
└──────────┴──────────────────────────────────────────────────┘

Partition Layout:
┌────────────┬──────────────┬──────────────┬──────────────────┐
│ Superblock │ Block Group 0│ Block Group 1│ Block Group N... │
└────────────┴──────────────┴──────────────┴──────────────────┘

Block Group Layout:
┌────────────┬───────────┬────────────┬────────────┬──────────┐
│ Superblock │   Group   │   Inode    │   Inode    │  Data    │
│  (backup)  │ Descriptor│  Bitmap    │   Table    │  Blocks  │
└────────────┴───────────┴────────────┴────────────┴──────────┘
```

- **Superblock**: Global metadata (total blocks, free blocks, FS type, UUID)
- **Inode Bitmap**: Tracks which inodes are free/used
- **Block Bitmap**: Tracks which data blocks are free/used
- **Inode Table**: Array of all inodes in this group
- **Data Blocks**: Actual file contents

---

### Mounting

Linux doesn't use drive letters. Instead, you **mount** a device at a directory (the **mount point**), attaching its tree into the global hierarchy.

```
Before mounting /dev/sdb1:          After mounting /dev/sdb1 at /mnt/usb:

/                                   /
├── home/                           ├── home/
├── etc/                            ├── etc/
└── mnt/                            └── mnt/
    └── usb/  (empty dir)               └── usb/          ← /dev/sdb1 root
                                             ├── photos/
                                             └── docs/
```

```bash
# Mount a device
mount /dev/sdb1 /mnt/usb

# View all mounted filesystems
mount | column -t
df -h

# Unmount
umount /mnt/usb
```

---

### Permissions Model

Every file has owner, group, and world permissions:

```
  -  rw-  r--  r--
  │   │    │    │
  │   │    │    └── Others: read only
  │   │    └─────── Group: read only
  │   └──────────── Owner: read + write
  └──────────────── Type: - file, d dir, l symlink, b block dev
```

```
Octal: 644 = 110 100 100
              rw- r-- r--

chmod 755 file   →  rwxr-xr-x
chown user:group file
```

---

### Special File Types in `/dev` and `/proc`

```
/dev/sda      → Block device  (hard disk)
/dev/tty      → Character device (terminal)
/dev/null     → Discards all writes, reads return EOF
/dev/zero     → Returns infinite null bytes
/dev/urandom  → Returns random bytes

/proc/cpuinfo    → CPU info (virtual file, no disk storage)
/proc/meminfo    → Memory stats
/proc/1/         → Directory for PID 1 (init/systemd)
/sys/class/net/  → Network interfaces exposed as files
```

Everything in `/proc` and `/sys` is generated on-the-fly by the kernel — no data is actually stored on disk.

---

### How Reading a File Works (end-to-end)

```
open("/home/user/notes.txt", O_RDONLY)

1. VFS receives syscall
2. Resolve path: / → home/ → user/ → notes.txt
   (each step: lookup directory entry → get inode number)
3. Load inode for notes.txt from disk
4. Check permissions against calling process UID/GID
5. Create file descriptor in process file table
6. Return fd (e.g. 3) to user

read(3, buffer, 1024)

7. VFS delegates to ext4 driver
8. ext4 reads block pointers from inode
9. Block layer fetches blocks from disk (or page cache)
10. Data copied to user buffer
```

---

### Journaling

Without journaling, a crash mid-write can leave the filesystem in an inconsistent state (e.g. inode updated but data blocks not written). **Journaling** solves this by writing changes to a log (the **journal**) before applying them to the main filesystem.

```
Write sequence:
1. Write intent to journal  ← crash here = no corruption, just replay
2. Commit journal entry     ← crash here = replay on next boot
3. Apply changes to FS      ← crash here = replay from committed journal
4. Mark journal entry as done
```

Journaling modes in ext4:

| Mode       | What is journaled          | Speed    | Safety   |
|------------|----------------------------|----------|----------|
| `journal`  | Data + metadata            | Slowest  | Highest  |
| `ordered`  | Metadata only (data first) | Default  | Good     |
| `writeback`| Metadata only              | Fastest  | Weakest  |

Btrfs and ZFS use **Copy-on-Write** instead of journaling (see below), which provides even stronger guarantees.

---

### Copy-on-Write (CoW)

Traditional filesystems overwrite data in place. **CoW filesystems** (Btrfs, ZFS) never overwrite — they write new data to a new location, then atomically update the reference.

```
Traditional (overwrite in place):
  Block 500: [old data] → [new data]   ← if crash here, data is corrupt

Copy-on-Write:
  Block 500: [old data]  (untouched)
  Block 600: [new data]  ← written first
  Pointer updated: 500 → 600  ← atomic swap
  Block 500: freed       ← only after pointer is committed
```

Benefits of CoW:
- **Snapshots are free** — just keep a reference to old block pointers
- **No journaling needed** — old data is never overwritten, so crashes leave the FS consistent
- **Data integrity** — every block can have a checksum, detected on read

---

### Hard Links vs Symlinks

Both let multiple paths point to the same content, but they work differently at the inode level.

```
Hard link:
  "file.txt"  ──┐
                ├──► inode #42 ──► data blocks
  "backup.txt"──┘
  (same inode, reference count = 2)

Symlink:
  "link.txt" ──► inode #99 ──► "/path/to/file.txt" (just a string)
                                       │
                                       ▼
                              inode #42 ──► data blocks
```

| Property                      | Hard Link         | Symlink             |
|-------------------------------|-------------------|---------------------|
| Points to                     | inode             | path (string)       |
| Works across filesystems      | No                | Yes                 |
| Works on directories          | No (usually)      | Yes                 |
| Breaks if original is deleted | No                | Yes (dangling link) |
| `ls -l` shows                 | same as file      | `->` target path    |

```bash
ln file.txt backup.txt       # hard link
ln -s /path/file.txt link    # symlink
stat file.txt                # shows inode number and link count
```

---

### The Page Cache

Linux does not read from disk on every `read()` call. The kernel maintains a **page cache** in RAM: disk blocks are loaded once and kept in memory for subsequent reads.

```
First read:
  Process → kernel → page cache miss → read from disk → fill cache → return data

Subsequent reads:
  Process → kernel → page cache hit → return data (no disk I/O)

Write:
  Process → kernel → write to page cache (dirty page)
                   → background: flush to disk (pdflush/writeback)
```

- `free -h` shows cached memory under `buff/cache` — this is the page cache
- The kernel evicts pages under memory pressure (LRU policy)
- `sync` forces all dirty pages to be flushed to disk immediately

---

### Common Linux Filesystems

| Filesystem | Journaling | CoW | Snapshots | Max file size | Best for                        |
|------------|------------|-----|-----------|---------------|---------------------------------|
| **ext4**   | Yes        | No  | No        | 16 TB         | General purpose, most distros   |
| **btrfs**  | No (CoW)   | Yes | Yes       | 16 EB         | Snapshots, compression, Fedora  |
| **xfs**    | Yes        | No  | No        | 8 EB          | Large files, high throughput    |
| **zfs**    | No (CoW)   | Yes | Yes       | 16 EB         | Servers, NAS, data integrity    |
| **tmpfs**  | No (RAM)   | No  | No        | RAM size      | `/tmp`, fast ephemeral storage  |
| **exFAT**  | No         | No  | No        | 128 PB        | USB drives, cross-platform      |
| **squashfs**| No (RO)   | No  | No        | —             | Live ISOs, container layers     |

---

### FUSE — Filesystem in Userspace

Normally, filesystems run inside the kernel. **FUSE** lets you implement a filesystem as a regular user-space program, communicating with the kernel via a `/dev/fuse` device.

```
User process                Kernel
  │                           │
  │  read("/mnt/myfuse/file") │
  │ ─────────────────────────►│
  │                     VFS   │
  │                      │    │
  │                  FUSE driver
  │                      │
  │◄─ request ───────────┘
  │  (your program handles it)
  │─ response ──────────────►FUSE driver → VFS → user
```

Examples built on FUSE:
- `sshfs` — mount a remote directory over SSH
- `gocryptfs` — encrypted filesystem
- `rclone mount` — mount cloud storage (S3, Google Drive) as a local directory

---

### Common Filesystem Commands

```bash
# Disk usage
df -h                        # free/used space per mounted FS
du -sh /path                 # size of a directory

# Inode info
stat file.txt                # inode, permissions, timestamps, link count
ls -i file.txt               # show inode number
df -i                        # inode usage per FS

# Filesystem creation
mkfs.ext4 /dev/sdb1          # format as ext4
mkfs.btrfs /dev/sdb1         # format as btrfs

# Check and repair
fsck /dev/sdb1               # check filesystem (must be unmounted)
e2fsck -f /dev/sdb1          # force check ext4

# Mount options
mount -o ro /dev/sdb1 /mnt   # mount read-only
mount -o remount,rw /        # remount root as read-write
cat /proc/mounts             # all currently mounted filesystems

# Links
ln source dest               # hard link
ln -s target linkname        # symbolic link
readlink -f linkname         # resolve symlink to real path

# Tune ext4
tune2fs -l /dev/sda1         # print FS metadata/superblock info
```

---

## Quick Reference

| Concept       | Description                                      |
|---------------|--------------------------------------------------|
| inode         | Metadata for a file (no name, no data)           |
| dentry        | Directory entry: maps name → inode               |
| VFS           | Kernel abstraction unifying all FS types         |
| mount         | Attach a FS to a directory in the tree           |
| block group   | Subdivision of disk in ext4                      |
| superblock    | Global FS metadata (size, type, UUID)            |
| hard link     | Two names pointing to the same inode             |
| symlink       | File whose content is a path to another file     |
| page cache    | Kernel memory caching disk blocks for speed      |

---

## Metalearning Questions

1. Why does Linux use a single root tree (`/`) instead of drive letters? What problem does this solve for mounting?

2. If two hard links point to the same inode, what happens when you delete one of them? What does "deleting a file" actually mean at the inode level?

3. `/proc/cpuinfo` is a file but contains no data on disk. How does the kernel make it appear as a regular readable file?

4. What is the role of the VFS layer? Why would you want to mount an ext4, btrfs, and tmpfs filesystem on the same running system simultaneously?

5. When you run `chmod 644 file`, what exactly is being modified — the directory entry, the inode, or the data block?

6. A file has permissions `rw-r--r--` and is owned by `root`. You are logged in as a regular user. Can you read it? Can you delete it? Why or why not? *(Hint: think about where the file lives)*

7. What is the difference between `atime`, `mtime`, and `ctime` on an inode? Give a concrete example of an operation that updates each one independently.

8. Why does ext4 store multiple copies of the superblock across block groups? What failure scenario does this protect against?

9. What happens at the kernel level when you run `cat /dev/urandom > /dev/null`? Trace the path from syscall to device driver.

10. A symlink and a hard link both let you access the same file content. What are two concrete situations where their behavior differs?
