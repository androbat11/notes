## What is a File?

At the OS level, a file is:

- A named sequence of bytes stored on disk
- Managed by the **filesystem** (ext4, NTFS, APFS, etc.)
- Accessed through **file descriptors** (integer handles)

## File Permissions (Unix/Linux)

Every file has three ownership attributes:

```bash
$ ls -la file.ts
-rw-r--r-- 1 mreyes developers 1024 Jan 27 10:00 file.ts
│├─┤├─┤├─┤   │      │
│ │  │  │    │      └── Group owner
│ │  │  │    └── User owner
│ │  │  └── Others: r-- (read only)
│ │  └── Group: r-- (read only)
│ └── User: rw- (read + write)
└── File type (- = regular file)
```

## Permission Bits

| Symbol | Octal | Meaning                     |
| ------ | ----- | --------------------------- |
| `r`    | 4     | Read: can view contents     |
| `w`    | 2     | Write: can modify contents  |
| `x`    | 1     | Execute: can run as program |

Your Program                     Operating System
┌─────────────┐                  ┌─────────────────┐
│ fd = 3      │ ───────────────► │ File Table      │
│             │   "I want to     │ ┌─────────────┐ │
│ read(fd)    │    read from     │ │ 0: stdin    │ │
│ write(fd)   │    handle 3"     │ │ 1: stdout   │ │
│ close(fd)   │                  │ │ 2: stderr   │ │
└─────────────┘                  │ │ 3: file.ts ◄┼─┼── actual file on disk
                                 │ └─────────────┘ │
                                 └─────────────────┘
