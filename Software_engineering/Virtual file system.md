# Virtual File System (VFS)

A **Virtual File System** is a kernel-internal abstraction layer that provides a single, uniform interface for all file system operations — regardless of what actual file system is underneath (ext4, APFS, NTFS, btrfs, tmpfs, etc.).

When your program calls `open()`, `read()`, `write()`, or `rename()`, it never talks to a specific file system driver directly. It talks to the VFS. The VFS then routes the call to the correct driver.

```
Userspace process
  │  open("/src/main.ts", O_WRONLY)
  ▼
VFS (kernel abstraction layer)
  │  which file system owns this path?
  ├──▶ ext4 driver     (Linux root partition)
  ├──▶ APFS driver     (macOS volume)
  ├──▶ NTFS driver     (Windows volume)
  ├──▶ tmpfs driver    (in-memory FS)
  └──▶ NFS driver      (network mount)
        │
        ▼
     Physical disk / network / memory
```

---

## Core Concepts

### Inode
An **inode** (index node) is the kernel's internal data structure representing a file or directory. It stores metadata: permissions, owner, size, timestamps, and pointers to the actual data blocks on disk. Crucially, **an inode has no name** — the name lives in the directory entry that points to it. This is why `inotify` on Linux watches inodes, not paths: the inode persists even if the file is renamed.

### Dentry (Directory Entry)
A **dentry** is the in-memory object that maps a path component (e.g. `main.ts`) to an inode. The VFS caches dentries aggressively so that path lookups (`/src/main.ts` → split into `src` + `main.ts` → resolve each to an inode) don't hit the disk every time.

### File Object
When a process calls `open()`, the VFS creates a **file object** — a per-process, per-open-call structure that tracks the current file offset and open flags. Multiple file objects can point to the same inode (multiple processes reading the same file simultaneously).

### Superblock
The **superblock** is the VFS representation of a mounted file system. It holds global metadata: block size, total inodes, free space, and a pointer to the file system driver's operation table.

---

## How VFS Intercepts Syscalls

Every mutating syscall goes through the VFS before reaching a driver:

```
write(fd, buf, len)
  │
  ▼ kernel entry point
VFS: resolve fd → file object → inode → superblock → driver
  │
  ▼ calls driver's .write() method
ext4_write() / apfs_write() / ntfs_write() ...
  │
  ▼
disk I/O
```

This interception point is exactly what `FSEvents`, `inotify`, and `ReadDirectoryChangesW` hook into — they register inside the VFS (or just below it) to observe these operations as they pass through, then surface them to userspace via their respective notification APIs.

---

## VFS as the Source of All File Watch Events

```
Userspace write("/src/main.ts")
        │
        ▼
   VFS layer  ◀──── notification hooks fire here
        │                  │
        │            ┌─────┴──────────────┐
        │        FSEvents            inotify / ReadDirectoryChangesW
        │        (macOS)             (Linux / Windows)
        ▼
   FS Driver
```

The notification APIs don't watch the disk — they watch the VFS. This means they fire on *any* file system type (local, network, virtual) as long as the operation passes through the VFS. A write to an NFS-mounted file triggers `inotify` just as a write to ext4 does.

---

## VFS Operations Table (Simplified)

Each file system driver registers a table of function pointers the VFS calls:

| VFS Operation | Triggered by syscall | Notification APIs observe |
|---|---|---|
| `inode_ops.create` | `open()` with `O_CREAT` | `IN_CREATE` / `FILE_ACTION_ADDED` |
| `file_ops.write` | `write()` / `pwrite()` | `IN_MODIFY` / `FILE_ACTION_MODIFIED` |
| `inode_ops.rename` | `rename()` / `mv` | `IN_MOVED_FROM + IN_MOVED_TO` / `RENAMED_*` |
| `inode_ops.unlink` | `unlink()` / `rm` | `IN_DELETE` / `FILE_ACTION_REMOVED` |
| `inode_ops.setattr` | `chmod()` / `chown()` / `touch` | `IN_ATTRIB` / `FILE_NOTIFY_CHANGE_ATTRIBUTES` |

---

## What VFS Does NOT Do

- It does not define *how* data is stored on disk — that is the file system driver's job.
- It is not accessible from userspace directly — there is no "VFS API" to call.
- It does not handle network protocols — that is handled by file system drivers like NFS or SMB that happen to sit behind the VFS interface.

---

## Relation to WatchEngine

WatchEngine never interacts with the VFS directly. The VFS is referenced here because it explains *why* `FSEvents`, `inotify`, and `ReadDirectoryChangesW` all observe the same logical events (create, modify, rename, delete) despite being completely different APIs — they all tap into the same kernel interception point.

See: [[OS interation layer]]
