# rsync — Remote Sync

Pronounced **"are-sink"** — think of it as a **smart copy machine** that only copies what changed, not the whole thing.

## What Is It?

`rsync` is a **file synchronization and transfer tool** for Linux. Instead of blindly copying everything, it calculates *exactly what's different* between the source and destination, and **only transfers the delta (the difference)**.

> **Mnemonic — "rsync = Really Smart ync (sync)"**: A normal `cp` is a dumb photocopier — it copies everything every time. rsync is the smart copier that asks *"what's new?"* before printing anything.

It works:
- **Locally** — syncing two folders on the same machine
- **Remotely** — syncing to/from another machine over SSH
- **As a daemon** — a background service listening for sync requests

---

## The Big Picture — How rsync Works

```
┌─────────────────────────────────────────────────────────────┐
│                      rsync BRAIN                            │
│                                                             │
│   SOURCE                         DESTINATION                │
│  ┌────────┐                      ┌────────┐                 │
│  │file.txt│  ──── checksum ────▶ │file.txt│                 │
│  │v2      │  ◀─── "I have v1" ── │v1      │                 │
│  │        │  ──── only diff ───▶ │        │                 │
│  └────────┘       (delta)        └────────┘                 │
│                                                             │
│   Result: destination becomes identical to source           │
│   Cost: only the changed bytes travel over the wire         │
└─────────────────────────────────────────────────────────────┘
```

> **Mnemonic — "Git for files"**: rsync does for file transfers what git does for code — it tracks changes and only moves what's new.

---

## Core Concept: The Delta Algorithm

rsync uses the **rsync algorithm** (invented by Andrew Tridgell):

```
Step 1: Destination splits file into fixed-size BLOCKS
        [Block 1][Block 2][Block 3][Block 4]
              ↓
Step 2: Destination sends CHECKSUMS of each block to source
        checksum1, checksum2, checksum3, checksum4
              ↓
Step 3: Source compares its version with those checksums
        "Block 1 ✓  Block 2 ✓  Block 3 CHANGED ✗  Block 4 ✓"
              ↓
Step 4: Source sends ONLY the changed block(s)
        → sends only Block 3
              ↓
Step 5: Destination reconstructs the file using old blocks + new delta
        [Block 1][Block 2][NEW Block 3][Block 4] ✓
```

> **Mnemonic — "Puzzle piece replacement"**: Imagine a 1000-piece puzzle. Instead of shipping a new puzzle when one piece changes, rsync says "I see you already have 999 pieces — here is only the one that changed."

---

## Basic Syntax

```bash
rsync [OPTIONS] SOURCE DESTINATION
```

**The slash matters — a lot:**

```bash
# WITH trailing slash on source → copies CONTENTS of dir/
rsync -av photos/   /backup/photos/
# Result: /backup/photos/img1.jpg  /backup/photos/img2.jpg

# WITHOUT trailing slash → copies the dir ITSELF
rsync -av photos    /backup/
# Result: /backup/photos/img1.jpg  /backup/photos/img2.jpg
```

```
  SOURCE             DESTINATION
  photos/            /backup/photos/       ← trailing slash: "pour contents here"
  ┌──────────┐       ┌──────────────┐
  │ img1.jpg │  ──▶  │ img1.jpg     │
  │ img2.jpg │  ──▶  │ img2.jpg     │
  └──────────┘       └──────────────┘

  photos             /backup/              ← no slash: "put the folder here"
  ┌──────────┐       ┌──────────────────┐
  │ photos/  │  ──▶  │ photos/          │
  │  img1.jpg│       │  img1.jpg        │
  │  img2.jpg│       │  img2.jpg        │
  └──────────┘       └──────────────────┘
```

---

## The Essential Flags

| Flag | Long form         | What it does                                              |
|------|-------------------|-----------------------------------------------------------|
| `-a` | `--archive`       | **Archive mode** = preserves permissions, timestamps, symlinks, owner, group. The "safe copy" flag. |
| `-v` | `--verbose`       | Show files being transferred                              |
| `-z` | `--compress`      | Compress data during transfer (useful over slow networks) |
| `-P` | `--progress --partial` | Show progress + resume incomplete transfers          |
| `-n` | `--dry-run`       | **Simulate** — show what WOULD happen, change nothing     |
| `-r` | `--recursive`     | Copy directories recursively (included in `-a`)           |
| `--delete` | —          | Delete files at destination that no longer exist at source |
| `-e` | `--rsh`           | Specify the shell/protocol (usually `-e ssh`)             |
| `--exclude` | —       | Skip files matching a pattern                             |
| `--checksum` | —      | Force checksum comparison instead of size+timestamp       |

> **Mnemonic — "a-v-z-P-n = Always Very Zealously Preview aNything"**: The five flags you use most.

---

## The `-a` Flag Unpacked

`-a` is actually shorthand for `-rlptgoD`:

```
-a expands to:
  -r  recursive
  -l  copy symlinks as symlinks
  -p  preserve permissions
  -t  preserve timestamps
  -g  preserve group
  -o  preserve owner
  -D  preserve device files + special files
```

> **Mnemonic — "Archive = Authentic Copy"**: `-a` means "make the destination an authentic replica — same permissions, same owner, same timestamps. Not just the bytes."

---

## Use Cases with Examples

### 1. Local Backup

```bash
# Sync ~/Documents to an external drive
rsync -av ~/Documents/ /mnt/usb/Documents/

# Dry run first to preview
rsync -avn ~/Documents/ /mnt/usb/Documents/
```

### 2. Mirror (with delete)

```bash
# Make destination an EXACT mirror of source
rsync -av --delete ~/projects/ /backup/projects/
```

```
SOURCE              DESTINATION (before)     DESTINATION (after --delete)
projects/           projects/                projects/
  app.py              app.py         ✓         app.py
  utils.py            utils.py       ✓         utils.py
  (gone) old.py       old.py        ──────▶    (deleted)
```

### 3. Remote Sync over SSH

```bash
# Push: local → remote
rsync -avz -e ssh ~/projects/ user@192.168.1.10:/home/user/projects/

# Pull: remote → local
rsync -avz -e ssh user@192.168.1.10:/home/user/projects/ ~/projects/

# With custom SSH port
rsync -avz -e "ssh -p 2222" ~/data/ user@server.com:/backup/
```

```
LOCAL MACHINE                      REMOTE MACHINE
┌──────────────┐                   ┌──────────────┐
│              │  SSH tunnel       │              │
│  ~/projects/ │ ════════════════▶ │  /backup/    │
│              │  (encrypted)      │              │
└──────────────┘                   └──────────────┘
     rsync client                    rsync server (via SSH)
```

### 4. Exclude Patterns

```bash
rsync -av --exclude='node_modules' --exclude='.git' ~/projects/ /backup/
rsync -av --exclude-from='exclude.txt' ~/projects/ /backup/
```

```
# exclude.txt
node_modules/
.git/
*.log
__pycache__/
.env
```

### 5. Resume Interrupted Transfer

```bash
rsync -avP ~/large-video.mkv user@server:/media/
# -P = show progress bar + allow resuming if interrupted
```

---

## rsync on Fedora

### Install

```bash
rsync --version          # check if installed
sudo dnf install rsync   # install if missing
```

### rsync as a Daemon (rsyncd)

On Fedora you can run rsync as a **background service** — no SSH needed. Clients connect directly on port **873**.

```
WITHOUT daemon (SSH mode):
  Client ──── SSH (port 22) ────▶ Server runs rsync via SSH shell

WITH daemon (rsyncd mode):
  Client ──── TCP (port 873) ───▶ rsyncd listens permanently
                                  (faster, no SSH overhead)
```

```bash
sudo systemctl start rsyncd
sudo systemctl enable rsyncd   # start on boot
sudo systemctl status rsyncd

# Open firewall port 873
sudo firewall-cmd --add-service=rsyncd --permanent
sudo firewall-cmd --reload
```

Config file: `/etc/rsyncd.conf`

```ini
[backup]
    path = /srv/backups
    comment = Backup storage
    read only = false
    auth users = backupuser
    secrets file = /etc/rsyncd.secrets
```

```bash
# Connect to a daemon (note double colon ::)
rsync -av /data/ backupuser@server::backup
#                            ↑↑
#                  double colon = daemon mode (not SSH)
```

> **Mnemonic — "Double colon = Direct connection"**: One colon `:` = SSH tunnel. Two colons `::` = direct daemon. More colons = more direct.

---

## rsync vs cp vs scp

```
┌─────────┬──────────────┬───────────────┬───────────────────────┐
│ Tool    │ Smart delta? │ Remote?       │ Best for              │
├─────────┼──────────────┼───────────────┼───────────────────────┤
│ cp      │ No           │ No            │ Quick local copies    │
│ scp     │ No           │ Yes (SSH)     │ One-time remote copy  │
│ rsync   │ YES          │ Yes (SSH/own) │ Backups, sync, large  │
│         │              │               │ transfers, mirrors    │
└─────────┴──────────────┴───────────────┴───────────────────────┘
```

> **Mnemonic — "cp = copy, scp = secure copy, rsync = really smart copy"**

---

## Mental Model — The Full Picture

```
                         rsync
                   "Smart Synchronizer"
                           │
         ┌─────────────────┼──────────────────┐
         │                 │                  │
    Local sync        Remote sync         Daemon mode
  (two folders)     (SSH tunnel)        (port 873, no SSH)
  "backup drive"    "push to server"    "dedicated sync server"
         │                 │                  │
         └─────────────────┼──────────────────┘
                           │
                    Delta Algorithm
               "only send what changed"
                    ┌──────────────┐
                    │ checksums    │
                    │ block diff   │
                    │ reconstruct  │
                    └──────────────┘
                           │
                 ┌─────────┴──────────┐
                 │                    │
           Preserves             Controls
        -a (archive)          --delete (mirror)
        permissions           --exclude (filter)
        timestamps            --dry-run (preview)
        symlinks              -z (compress)
```

---

## Common Mistakes and Gotchas

| Mistake | What happens | Fix |
|---------|-------------|-----|
| Forgetting `/` on source | Copies the folder into destination, creating nesting | Add trailing slash: `source/` |
| Using `--delete` without dry run | Deletes files at destination you did not mean to | Always `--dry-run` first |
| No `-a` flag | Permissions and timestamps are lost | Always use `-a` for backups |
| Forgetting `-z` over slow networks | Transfer is slow | Add `-z` for remote transfers |
| Using single colon for daemon | "No such file" error | Use `::` for rsyncd daemon |

---

## Quick Cheat Sheet

```bash
# Local backup (safe mode)
rsync -avn ~/source/ /dest/          # dry run preview
rsync -av  ~/source/ /dest/          # actual run

# Local mirror (dangerous — deletes!)
rsync -avn --delete ~/source/ /dest/ # dry run FIRST
rsync -av  --delete ~/source/ /dest/

# Remote push (SSH)
rsync -avzP ~/data/ user@host:/remote/data/

# Remote pull (SSH)
rsync -avzP user@host:/remote/data/ ~/data/

# Exclude patterns
rsync -av --exclude='*.log' --exclude='.git' ~/src/ /dst/

# Resume interrupted transfer
rsync -avP ~/bigfile.iso user@host:/storage/
```

---

## Meta-Cognition Questions

**Test yourself — close the notes and answer these:**

### Conceptual Understanding
1. What problem does rsync solve that `cp` does not? Describe the delta algorithm in your own words.
2. Why does a trailing slash on the source matter? Draw a diagram of what happens with and without it.
3. What does `-a` actually do? Name at least 4 things it preserves.
4. What is the difference between `:` and `::` in an rsync command?

### Applied Thinking
5. You have a 50 GB video project folder that you sync daily to a backup drive. Only 3 files change per day. Why is rsync better than `cp` here?
6. You want to make your backup drive an exact mirror of your source — including deleting files you removed from the source. What flag do you add, and what precaution should you take first?
7. You are syncing files to a remote server over a slow 5 Mbps connection. Which flag reduces the data sent during transfer?
8. A colleague ran `rsync -av remote_data /backup/` and now has `/backup/remote_data/` instead of the files directly in `/backup/`. What did they do wrong?

### Fedora-Specific
9. What command installs rsync on Fedora?
10. What port does rsyncd use, and what firewalld command opens it?
11. What is the difference between SSH mode and daemon mode rsync?

### Synthesis
12. Design a daily backup script using rsync that:
    - Preserves permissions and timestamps
    - Excludes `node_modules/` and `.git/`
    - Mirrors the source (deletes orphaned files)
    - Runs a dry run first and asks for confirmation before the real run

---

> **Final Mnemonic — "rsync = Ruthlessly Smart, Never Yells, Copies"**: Smart enough to only copy the minimum, silent unless you ask for `-v`, and incredibly reliable for backups.
