
## What is a terminal?

A **terminal** was originally a physical device — a keyboard + screen (or printer) connected to a mainframe. You typed commands, the mainframe ran them, the terminal showed results.

Modern Linux has no physical terminals (usually). Instead, it has **terminal emulators** — programs that *pretend* to be that old hardware, but inside a window.

```
Historical (1970s):
  ┌──────────────┐      serial cable      ┌──────────────┐
  │  Physical    │ ──────────────────────▶ │   Mainframe  │
  │  Terminal    │                         │   (shell)    │
  │ (VT100, etc) │ ◀────────────────────── │              │
  └──────────────┘                         └──────────────┘

Modern (today):
  ┌──────────────┐      PTY (virtual)      ┌──────────────┐
  │  Terminal    │ ──────────────────────▶ │    Shell     │
  │  Emulator   │                         │  (bash/zsh)  │
  │(GNOME Term.) │ ◀────────────────────── │              │
  └──────────────┘                         └──────────────┘
```

---

## The key distinction: Terminal vs Shell

These are two **separate programs** that work together. People often confuse them.

```
┌──────────────────────────────────────────────────────────┐
│                    Terminal Emulator                     │
│                                                          │
│  • Draws text on screen                                  │
│  • Captures keyboard input                               │
│  • Handles colors, cursor movement, scrollback buffer    │
│  • Examples: GNOME Terminal, Alacritty, kitty, xterm     │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │                      Shell                        │  │
│  │                                                    │  │
│  │  • Interprets commands you type                    │  │
│  │  • Manages environment variables, history         │  │
│  │  • Launches programs (ls, grep, vim...)            │  │
│  │  • Examples: bash, zsh, fish, dash                 │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

> **Key insight**: The terminal is the *display + input layer*. The shell is the *interpreter*. You can attach any shell to any terminal.

---

## The PTY — how they actually communicate

The magic glue between the terminal emulator and the shell is the **PTY (pseudo-terminal)**. It is a kernel abstraction that simulates a serial cable.

```
┌──────────────────────────────────────────────────────────────┐
│                         Kernel                               │
│                                                              │
│   ┌─────────────┐    PTY pair    ┌─────────────────────┐    │
│   │  PTY master │◀──────────────▶│    PTY slave        │    │
│   │  (fd in     │                │  appears as /dev/pts │    │
│   │  emulator)  │                │  e.g. /dev/pts/0     │    │
│   └─────────────┘                └─────────────────────┘    │
│          ▲                                  ▲                │
└──────────┼──────────────────────────────────┼────────────────┘
           │                                  │
   Terminal Emulator                       Shell (bash)
   reads/writes here                   stdin/stdout/stderr
   (renders output,                    all point to this
    sends keystrokes)                  /dev/pts/X device
```

**How the PTY pair works:**
- The kernel creates a **master/slave** pair when a terminal opens
- The **master** end is held by the terminal emulator
- The **slave** end (`/dev/pts/N`) is given to the shell as its stdin/stdout/stderr
- Everything written by the shell to its stdout travels through the slave → kernel → master → terminal emulator renders it

---

## Full data flow: you press a key

```
You press 'l' 's' Enter
        │
        ▼
┌──────────────────┐
│ Terminal Emulator │  ← receives raw key event from display server (X11/Wayland)
└────────┬─────────┘
         │  writes 'ls\n' to PTY master fd
         ▼
┌──────────────────┐
│   PTY master     │  ← kernel receives it
└────────┬─────────┘
         │  kernel echoes 'ls' back to master (so emulator shows what you typed)
         │  forwards 'ls\n' to PTY slave
         ▼
┌──────────────────┐
│   PTY slave      │  ← shell's stdin; line discipline buffers until \n
│  /dev/pts/0      │
└────────┬─────────┘
         │  line is ready → shell reads "ls\n"
         ▼
┌──────────────────┐
│      Shell        │  ← parses "ls", forks a child process
└────────┬─────────┘
         │  child inherits PTY slave as stdout
         ▼
┌──────────────────┐
│    ls (child)    │  ← executes, writes directory listing to its stdout (slave)
└────────┬─────────┘
         │
         ▼
      PTY slave → PTY master → Terminal Emulator renders text on screen
```

---

## The line discipline — the hidden layer

Between master and slave lives the **line discipline** (n_tty). It is kernel code that:

- **Buffers** your keystrokes until you press Enter (cooked mode)
- **Echoes** characters back so you see what you type
- Handles **Ctrl+C** → sends SIGINT to the foreground process
- Handles **Ctrl+Z** → sends SIGTSTP (pause/background)
- Handles **Backspace** → erases the last character from the buffer
- Handles **Ctrl+D** → sends EOF

```
   Keystroke
      │
      ▼
┌──────────────────────────────────┐
│          Line Discipline         │
│                                  │
│  raw bytes ──▶  process them:    │
│                 • echo back?      │
│                 • signal? (^C)    │
│                 • erase? (⌫)     │
│                 • buffer until \n │
│                        │         │
└───────────────────────┼──────────┘
                         │
                         ▼
                  shell reads clean line
```

**Modes:**
| Mode | Description | Used by |
|---|---|---|
| **Cooked / canonical** | Line buffered, echo on, special chars active | Normal shell usage |
| **Raw** | Every keystroke sent immediately, no echo | vim, htop, games |
| **Cbreak** | Like raw but some signals still work | Interactive programs |

---

## TTY types in Linux

```
┌──────────────────────────────────────────────────────────────┐
│                         TTY types                            │
│                                                              │
│  ┌─────────────────┐   ┌──────────────┐   ┌──────────────┐  │
│  │  Virtual        │   │   PTY        │   │  Serial TTY  │  │
│  │  Consoles       │   │   (pseudo)   │   │  /dev/ttyS0  │  │
│  │  /dev/tty1..6   │   │  /dev/pts/N  │   │              │  │
│  │                 │   │              │   │              │  │
│  │  Switch with    │   │  Used by     │   │  Hardware    │  │
│  │  Ctrl+Alt+F1..6 │   │  terminal    │   │  serial port │  │
│  │                 │   │  emulators   │   │  (rare now)  │  │
│  └─────────────────┘   └──────────────┘   └──────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

- **Virtual consoles** (`/dev/tty1`–`/dev/tty6`): full-screen text sessions managed by the kernel directly. Switch with `Ctrl+Alt+F1`. No graphical server needed.
- **PTYs** (`/dev/pts/N`): used by terminal emulators running inside a GUI.
- **`/dev/tty`**: always refers to the *current* controlling terminal of the calling process.

---

## Process groups, sessions, and job control

The terminal is also the anchor for **job control** — how you run things in the background.

```
Session (SID = shell PID)
│
├── Foreground process group  ← gets keyboard signals (Ctrl+C, Ctrl+Z)
│   └── ls, vim, grep...
│
└── Background process groups  ← cannot receive terminal input
    ├── job 1: sleep 100 &
    └── job 2: find / -name foo &
```

```
$ sleep 100      ← runs in foreground, shell waits
  Ctrl+Z         ← SIGTSTP → process suspended
$ bg             ← resumes it in background
$ jobs           ← lists background jobs
[1]+  Running    sleep 100 &
$ fg             ← brings it back to foreground
```

The kernel tracks which **process group** owns the terminal. Only the foreground group receives signals from keystrokes.

---

## How a terminal emulator opens a shell — step by step

```
1. User launches GNOME Terminal
        │
        ▼
2. Emulator calls posix_openpt() or open("/dev/ptmx")
   → kernel allocates a new PTY master/slave pair
   → slave appears as /dev/pts/N
        │
        ▼
3. Emulator calls fork()
        │
        ├──── Parent (emulator) keeps PTY master fd
        │     → event loop: read master fd → render text
        │                    write keystrokes → master fd
        │
        └──── Child process:
                  setsid()              ← start new session
                  open("/dev/pts/N")    ← slave becomes controlling terminal
                  dup2(slave, STDIN_FILENO)
                  dup2(slave, STDOUT_FILENO)
                  dup2(slave, STDERR_FILENO)
                  close(slave)
                  execve("/bin/bash")   ← replace child with shell
```

---

## The full layer stack

```
┌────────────────────────────────────────────────┐
│                  Hardware                      │
│           (keyboard, GPU, monitor)             │
└──────────────────────┬─────────────────────────┘
                       │
┌──────────────────────▼─────────────────────────┐
│              Linux Kernel                      │
│  • Input subsystem (evdev)                     │
│  • DRM/KMS (display)                           │
│  • PTY subsystem (/dev/ptmx, /dev/pts/N)        │
│  • TTY line discipline (n_tty)                 │
│  • Process/signal management                   │
└──────────────────────┬─────────────────────────┘
                       │
┌──────────────────────▼─────────────────────────┐
│          Display Server (X11 / Wayland)        │
│  • Routes keyboard events to focused window    │
│  • Composites windows on screen                │
└──────────────────────┬─────────────────────────┘
                       │
┌──────────────────────▼─────────────────────────┐
│           Terminal Emulator                    │
│  (Alacritty, GNOME Terminal, kitty, xterm)     │
│  • Holds PTY master fd                         │
│  • Renders text (font rendering, colors)       │
│  • Implements terminal escape codes (VT100+)   │
└──────────────────────┬─────────────────────────┘
                       │ PTY master ↔ PTY slave
┌──────────────────────▼─────────────────────────┐
│                  Shell                         │
│  (bash, zsh, fish)                             │
│  • Reads commands from PTY slave (stdin)       │
│  • Parses, expands, forks child processes      │
│  • Manages job control, environment            │
└──────────────────────┬─────────────────────────┘
                       │ fork + exec
┌──────────────────────▼─────────────────────────┐
│            User Programs                       │
│  (ls, vim, python, curl...)                    │
│  • stdin/stdout/stderr → PTY slave             │
└────────────────────────────────────────────────┘
```

---

## Terminal escape codes — how formatting works

Terminals understand special **escape sequences** (from the VT100 standard) embedded in output text. This is how programs produce colors, move the cursor, or clear the screen.

```
Normal output:     "hello\n"           → prints "hello"

Colored output:    "\033[31mhello\033[0m\n"
                     │    │       │
                     │    │       └── reset all formatting
                     │    └────────── red foreground color
                     └─────────────── ESC character (escape)
```

Common sequences:
| Sequence | Effect |
|---|---|
| `\033[2J` | Clear screen |
| `\033[H` | Move cursor to top-left |
| `\033[31m` | Red text |
| `\033[1m` | Bold |
| `\033[?25l` | Hide cursor |
| `\033[A` | Move cursor up one line |

Programs like `vim`, `htop`, and `fzf` use these extensively to build full TUI (text user interface) applications.

---

## Quick-reference mental model

```
  You type
     │
     ▼
  Terminal Emulator  ──── draws what you see
     │
     │  PTY  (kernel magic cable)
     │
     ▼
  Shell  ──── interprets commands
     │
     │  fork + exec
     │
     ▼
  Programs  ──── do the actual work
```

**One-liner**: The terminal emulator is the glass; the PTY is the pipe; the shell is the interpreter; the programs are the workers.

---

## Metacognition checkpoint

> **Before reading this, did you think "terminal" and "shell" were the same thing?**

Most beginners say "open a terminal" and mean the whole experience. Now you know there are at least **4 distinct layers**: display server, terminal emulator, PTY, and shell — each replaceable independently.

This is why `ssh` works: it creates a PTY on the remote machine and tunnels the master end over the network to your local terminal emulator. The shell on the remote side has no idea it is not locally attached.

---

## Reflection question

> You run `vim` in your terminal. Vim switches to raw mode, draws its interface, and your arrow keys move the cursor instead of being interpreted by the shell.
>
> **Question**: Which component flips the mode from cooked to raw? Who tells the kernel? And when you quit vim, how does cooked mode get restored?
>
> Trace the path through the layers described above.
