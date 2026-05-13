
The OS Interaction Layer is the lowest boundary of WatchEngine. Its sole responsibility is to translate raw, platform-specific kernel notifications into a single unified event stream that the rest of the Core can consume without knowing anything about the underlying OS.

Every OS exposes a different mechanism for notifying a userspace process that something changed on disk. All three mechanisms below tap into the **VFS (Virtual File System)** — the kernel abstraction that sits between file operations (`write`, `rename`, `unlink`) and the actual disk driver. They differ in *how* they surface those notifications to userspace.

---

## FSEvents (macOS)

`FSEvents` is a **kernel-level framework** built into the macOS XNU kernel, introduced in macOS 10.5 (Leopard).

**How it works internally:**
1. The XNU kernel's VFS layer intercepts every syscall that mutates the file system (`write`, `rename`, `unlink`, etc.).
2. Mutations are coalesced into a **journal** inside the kernel.
3. Your process opens a `FSEventStream` via the C API (`FSEventStreamCreate`), registering a callback and one or more directory paths to watch.
4. The kernel delivers batched events through a **CFRunLoop** (Core Foundation's event loop), passing: the path, a set of flags (`kFSEventStreamEventFlagItemCreated`, `...Modified`, `...Removed`, etc.), and an `eventId` — a monotonically increasing 64-bit integer used for historical replay.

**Key characteristics:**
- **Directory-granular** — you register at the directory level; the kernel tells you which file within it changed.
- **Coalescing** — rapid changes to the same file are merged into one event, reducing noise.
- **Historical replay** — pass a `sinceWhen` eventId to receive all events since a past point (useful for catching changes that occurred while your process was offline).
- **No polling** — purely interrupt-driven; zero CPU overhead while idle.

```
XNU Kernel VFS
  │  intercepts write()/rename()/unlink() syscalls
  ▼
FSEvents Journal (kernel) — coalesces + batches
  ▼
CFRunLoop delivers to FSEventStreamCallback
  │  { path: "/src/main.ts", flags: Modified, eventId: 9821 }
  ▼
[macOS Adapter]  ──▶  RawFileEvent
```

---

## inotify (Linux)

`inotify` is a **Linux kernel subsystem** introduced in kernel 2.6.13 (2005). It provides file system event notification at the **inode** level.

**How it works internally:**
1. Your process calls `inotify_init()` — the kernel returns a **file descriptor** representing an inotify instance.
2. You call `inotify_add_watch(fd, path, mask)` to register interest in a path. The `mask` is a bitmask of events: `IN_CREATE`, `IN_MODIFY`, `IN_DELETE`, `IN_MOVED_FROM`, `IN_MOVED_TO`, etc. The kernel returns a **watch descriptor (wd)** integer.
3. The kernel attaches a notification hook to the **inode** (not the path string). When any VFS operation touches that inode, the kernel writes a `struct inotify_event` record into a kernel-side buffer.
4. Your process reads events by calling `read(fd, buf, size)` on the inotify fd — a standard blocking or non-blocking read. The Reactor places this fd inside an `epoll` loop so it can wait on multiple fds simultaneously without blocking.

**Key characteristics:**
- **Inode-based** — watches are attached to inodes, so they survive renames of the watched directory's parent. However, they do not follow symlinks automatically.
- **Not recursive by default** — watching a directory tree requires calling `inotify_add_watch` for every subdirectory. Libraries like `fsnotify` automate this.
- **Kernel buffer overflow** — if events pile up faster than your process reads them, the kernel drops events and emits `IN_Q_OVERFLOW`. WatchEngine must respond with a full directory re-scan.
- **Cookie mechanism** — `IN_MOVED_FROM` and `IN_MOVED_TO` events share the same `cookie` integer, allowing the Adapter to correlate a rename as one atomic move rather than a delete + create pair.

```
Linux Kernel VFS
  │  intercepts write()/rename()/unlink() on watched inodes
  ▼
inotify kernel buffer (per inotify_instance fd)
  │  struct inotify_event { wd, mask, cookie, name }
  ▼
epoll/read() in Reactor event loop
  │  { wd → path lookup, mask → kind, name: "main.ts" }
  ▼
[Linux Adapter]  ──▶  RawFileEvent
```

---

## ReadDirectoryChangesW (Windows)

`ReadDirectoryChangesW` is a **Win32 API function** available since Windows NT 4.0. It monitors a directory handle for file system changes.

**How it works internally:**
1. Your process calls `CreateFile` on a *directory* (with `FILE_FLAG_BACKUP_SEMANTICS`) to obtain a directory handle.
2. You call `ReadDirectoryChangesW(hDir, buffer, bufferLen, bWatchSubtree, dwNotifyFilter, ...)`. The `dwNotifyFilter` bitmask selects event categories: `FILE_NOTIFY_CHANGE_FILE_NAME`, `FILE_NOTIFY_CHANGE_LAST_WRITE`, `FILE_NOTIFY_CHANGE_SIZE`, etc.
3. The call can be used in two modes:
   - **Synchronous** — the calling thread blocks until a change occurs.
   - **Asynchronous (IOCP / Overlapped I/O)** — an `OVERLAPPED` structure is passed along with an I/O Completion Port; the kernel posts a completion packet when changes arrive. WatchEngine uses this mode so the Reactor thread is never blocked.
4. The kernel fills the output buffer with a linked list of `FILE_NOTIFY_INFORMATION` structs: `{ NextEntryOffset, Action, FileNameLength, FileName[] }`. `Action` is one of `FILE_ACTION_ADDED`, `FILE_ACTION_REMOVED`, `FILE_ACTION_MODIFIED`, `FILE_ACTION_RENAMED_OLD_NAME`, `FILE_ACTION_RENAMED_NEW_NAME`.

**Key characteristics:**
- **Natively recursive** — passing `bWatchSubtree = TRUE` watches the entire directory tree with a single call, unlike inotify.
- **Buffer overflow** — if the internal kernel buffer overflows due to rapid changes, `ERROR_NOTIFY_ENUM_DIR` is returned. WatchEngine must re-enumerate the directory on this error.
- **Renamed pairs** — renames produce two consecutive `FILE_NOTIFY_INFORMATION` entries (`RENAMED_OLD_NAME` + `RENAMED_NEW_NAME`) that the Adapter must pair into a single rename event.
- **IOCP model** — fits naturally into Windows' I/O Completion Port concurrency model, the same model used by Node.js's libuv internally.

```
Windows NTFS / kernel I/O Manager
  │  intercepts NtWriteFile / NtSetInformationFile etc.
  ▼
IOCP completion queue (kernel → userspace)
  │  FILE_NOTIFY_INFORMATION { Action, FileName }
  ▼
GetQueuedCompletionStatus() in Reactor thread
  │  { action → kind, fileName: "main.ts" }
  ▼
[Windows Adapter]  ──▶  RawFileEvent
```

---

## The Unified Interface

All three mechanisms are hidden behind a single interface the rest of the Core uses:

```typescript
interface IFSWatcher {
  watch(path: string, recursive: boolean): void;
  unwatch(path: string): void;
  on(event: "change", handler: (e: RawFileEvent) => void): void;
}

type RawFileEvent = {
  path: string;
  kind: "create" | "modify" | "delete" | "rename";
  oldPath?: string; // only populated on rename
};
```

Each OS Adapter translates its native structs into `RawFileEvent` and emits them. From the Reactor's perspective, the OS doesn't exist — only the stream of `RawFileEvent` objects does.

| | FSEvents | inotify | ReadDirectoryChangesW |
|---|---|---|---|
| **OS** | macOS | Linux | Windows |
| **Unit watched** | Directory tree | Inode | Directory handle |
| **Recursive?** | Always | Manual per-dir | Optional flag |
| **Delivery** | CFRunLoop callback | `read()` on fd via epoll | IOCP completion packet |
| **Overflow behavior** | Auto-coalesces | `IN_Q_OVERFLOW` event | `ERROR_NOTIFY_ENUM_DIR` |
| **Rename tracking** | Single event with flags | Cookie-paired events | Consecutive `OLD`/`NEW` entries |
| **Polling?** | No | No | No |
