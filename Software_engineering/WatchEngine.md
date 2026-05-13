
# WatchEngine Design & Architecture

WatchEngine is a generic file-watching system designed to support multiple programming language environments through a plugin-based configuration (e.g., `--typescript`, `--javascript`).

## Primary Architecture: Microkernel (Plug-in)
The system is divided into a **Core Engine** (Microkernel) and **Language Plugins**. The Core provides the "engine plumbing" (OS interaction, event loop, registry), while the Plugins provide the "feature implementation" (compilation, linting, custom actions).

---

## 1. Design Patterns Integration

### A. Core Engine Patterns (The Plumbing)
*   **Reactor Pattern:** The primary engine loop. It demultiplexes OS-level file events (read/write/create) and dispatches them to the Core's event coordinator.
*   **Adapter Pattern:** Essential for cross-platform support. The Core uses Adapters to wrap different OS APIs (`fsevents` on Mac, `inotify` on Linux, `ReadDirectoryChangesW` on Windows) into a unified internal interface.
*   **Factory Method:** Used by the **Plugin Registry** to instantiate the correct language plugin based on user flags or file extensions.

### B. Communication & Dispatch Patterns
*   **Strategy Pattern:** The Core uses this to select the appropriate "execution strategy" for a file. If `main.ts` changes, the Strategy decides whether to call the TypeScript Plugin or a Generic Watcher.
*   **Observer Pattern:** Used within the Core to allow multiple internal systems (e.g., a Logger, a UI Dashboard, and the Language Plugin) to react to the same file change event simultaneously.
*   **Command Pattern:** Encapsulates the action to be taken by a plugin (e.g., "Run Build", "Run Test") as a standalone object. This allows the Core to queue, delay, or log actions easily.

### C. Optimization & Refinement Patterns
*   **Proxy Pattern (Smart Proxy):** Implements **Throttling and Debouncing**. The Proxy intercepts high-frequency file events from the Reactor and only forwards a single "settled" event to the Plugin to prevent CPU spikes.
*   **Decorator Pattern:** Used to dynamically add features to Plugins, such as adding "Performance Timing" or "Error Notification" wrappers around a basic `compile()` command without changing the plugin's code.

---

## 2. Core Engine Internals

### OS Interaction Layer
The Core Engine communicates with the operating system through platform-specific **file system event APIs**. Each OS exposes a different mechanism for telling a userspace process "something changed on disk." The three mechanisms below are how the kernel pushes those notifications up to our process.

---

#### FSEvents (macOS)
`FSEvents` is a **kernel-level framework** built into the macOS XNU kernel (introduced in macOS 10.5 Leopard).

**How it works internally:**
1. The kernel's VFS (Virtual File System) layer intercepts every syscall that mutates the file system (`open`, `write`, `rename`, `unlink`, etc.).
2. These mutations are coalesced into a **journal** inside the kernel.
3. Your process opens a `FSEventStream` via the C API (`FSEventStreamCreate`), registering a callback and one or more directory paths to watch.
4. The kernel delivers batched events to your callback through a **CFRunLoop** (Core Foundation's event loop), passing: the path, a set of flags (`kFSEventStreamEventFlagItemCreated`, `...Modified`, `...Removed`, etc.), and an `eventId` (monotonically increasing 64-bit integer for replay).

**Key characteristics:**
- **Directory-granular, not file-granular by default** — you watch a directory tree; the kernel tells you *which file* changed.
- **Coalescing** — rapid changes to the same file are merged into one event.
- **Historical replay** — pass a `sinceWhen` eventId to get all events since a past point (useful when your process was offline).
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
[macOS Adapter]
```

---

#### inotify (Linux)
`inotify` is a **Linux kernel subsystem** (since kernel 2.6.13, 2005) that provides file system event notification at the **inode** level.

**How it works internally:**
1. Your process calls `inotify_init()` — the kernel returns a **file descriptor** (an inotify instance).
2. You call `inotify_add_watch(fd, path, mask)` to register interest in a path. The `mask` is a bitmask: `IN_CREATE`, `IN_MODIFY`, `IN_DELETE`, `IN_MOVED_FROM`, `IN_MOVED_TO`, etc. Returns a **watch descriptor (wd)** integer.
3. The kernel attaches a hook to the **inode** (not the path string). When a VFS operation touches that inode, the kernel writes a `struct inotify_event` record into a kernel buffer.
4. Your process reads events via `read(fd, buf, size)` on the inotify fd — standard blocking/non-blocking read. The Reactor places this fd inside an `epoll` loop.

**Key characteristics:**
- **Inode-based** — watches survive renames of the watched file's parent directory, but don't follow symlinks automatically.
- **Not recursive by default** — to watch a directory tree, you must call `inotify_add_watch` for every subdirectory (libraries like `fsnotify` handle this).
- **Kernel buffer overflow** — if events pile up faster than your process reads them, the kernel sends `IN_Q_OVERFLOW`. WatchEngine must handle this with a full re-scan.
- **Cookie mechanism** — `IN_MOVED_FROM` and `IN_MOVED_TO` share the same `cookie` integer, letting you correlate a rename as a single atomic move rather than a delete + create.

```
Linux Kernel VFS
  │  intercepts write()/rename()/unlink() on watched inodes
  ▼
inotify kernel buffer (per inotify_instance fd)
  │  struct inotify_event { wd, mask, cookie, name }
  ▼
epoll/read() in Reactor event loop
  │  { wd→path lookup, mask→kind, name: "main.ts" }
  ▼
[Linux Adapter]
```

---

#### ReadDirectoryChangesW (Windows)
`ReadDirectoryChangesW` is a **Win32 API function** (since Windows NT 4.0) that monitors a directory handle for changes.

**How it works internally:**
1. Your process calls `CreateFile` on a *directory* (with `FILE_FLAG_BACKUP_SEMANTICS`) to get a directory handle.
2. You call `ReadDirectoryChangesW(hDir, buffer, bufferLen, bWatchSubtree, dwNotifyFilter, ...)`. The `dwNotifyFilter` bitmask selects what to watch: `FILE_NOTIFY_CHANGE_FILE_NAME`, `FILE_NOTIFY_CHANGE_LAST_WRITE`, `FILE_NOTIFY_CHANGE_SIZE`, etc.
3. Two modes:
   - **Synchronous** — the thread blocks until a change occurs.
   - **Asynchronous (IOCP / Overlapped I/O)** — an `OVERLAPPED` structure + an I/O Completion Port is used; the kernel posts a completion packet when changes arrive. WatchEngine uses this mode so the Reactor thread is never blocked.
4. The kernel fills the buffer with a linked list of `FILE_NOTIFY_INFORMATION` structs: `{ NextEntryOffset, Action, FileNameLength, FileName[] }`. `Action` is one of `FILE_ACTION_ADDED`, `FILE_ACTION_REMOVED`, `FILE_ACTION_MODIFIED`, `FILE_ACTION_RENAMED_OLD_NAME`, `FILE_ACTION_RENAMED_NEW_NAME`.

**Key characteristics:**
- **Natively recursive** — passing `bWatchSubtree = TRUE` watches the entire subtree without extra calls (unlike inotify).
- **Buffer overflow risk** — if the internal kernel buffer overflows, `ERROR_NOTIFY_ENUM_DIR` is returned; WatchEngine must re-enumerate the directory.
- **Renamed pairs** — renames produce two consecutive entries (`RENAMED_OLD_NAME` + `RENAMED_NEW_NAME`) that must be paired by the Adapter.
- **IOCP integration** — fits into Windows' Completion Port concurrency model (the same model used by Node.js's libuv under the hood).

```
Windows NTFS / kernel I/O Manager
  │  intercepts NtWriteFile / NtSetInformationFile etc.
  ▼
IOCP completion queue (kernel → userspace)
  │  FILE_NOTIFY_INFORMATION { Action, FileName }
  ▼
GetQueuedCompletionStatus() in Reactor thread
  │  { action→kind, fileName: "main.ts" }
  ▼
[Windows Adapter]
```

---

#### The Unified Interface
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

The Adapter for each OS translates its native structs into `RawFileEvent` and emits them. From the Reactor's perspective, the OS doesn't exist — only the stream of `RawFileEvent` objects does.

### Plugin Registry
The Registry is the **central catalogue of all loaded plugins**. It is responsible for:

1. **Registration** — plugins call `registry.register(plugin: IWatchPlugin)` at startup (or when a flag like `--typescript` is passed).
2. **Lookup** — given a file extension (e.g. `.ts`), the Registry returns every plugin whose `extensions` array matches.
3. **Instantiation** — the Registry uses the **Factory Method** pattern to construct plugin instances, keeping the Core decoupled from concrete plugin classes.
4. **Lifecycle management** — it calls `plugin.setup(config)` once on load and can tear down plugins gracefully on exit.

```
CLI flags / file extensions
        │
        ▼
[Plugin Registry]
   ├── "typescript-build"  →  TypeScriptPlugin  { extensions: [".ts",".tsx"] }
   ├── "eslint"            →  ESLintPlugin       { extensions: [".ts",".js"] }
   └── "generic-watcher"  →  GenericPlugin      { extensions: ["*"] }
```

When a `FILE_CHANGED` event arrives, the Reactor queries the Registry for matching plugins and hands the event to each one via `onEvent(event)`.

---

## 3. Architectural Styles
*   **Event-Driven Architecture (EDA):** The entire system flow is reactive. Nothing happens until a file event is "emitted" from the OS layer.
*   **Hexagonal Architecture (Ports and Adapters):** Ensures the Core logic is isolated. The "File System" is an input port, and the "Language Tooling" is an output port. This makes the Core easily testable in isolation.
*   **Publisher-Subscriber (Pub/Sub):** Used for decoupling. The Core "Publishes" a `FILE_CHANGED` topic, and any loaded Plugin "Subscribes" to extensions it cares about.

---

## 4. The "WatchEngine" Contract (The Interface)
The Core defines the following interface that all plugins must implement:

```typescript
interface IWatchPlugin {
  readonly id: string;           // e.g., "typescript-build"
  readonly extensions: string[]; // e.g., [".ts", ".tsx"]
  
  // Lifecycle hooks
  setup(config: Config): Promise<void>;
  
  // Execution hook
  onEvent(event: FileEvent): void;
}
```
