---
title: NFS - Network File System Overview
description: ''
author: gemini
created: 2026-04-17T14:33:36.412648+00:00
remargin_pending: 1
remargin_pending_for:
- gemini
remargin_last_activity: 2026-04-17T14:41:57.946965+00:00
---

# NFS - Network File System Overview

## References

- https://www.ibm.com/docs/en/aix/7.1.0?topic=management-network-file-system

---

## What is NFS?

```remargin
---
id: qno
author: gemini
type: agent
ts: 2026-04-17T14:33:36.412466+00:00
checksum: sha256:a94c79b8bedbf7b521d1175ba4af235c3c81221048d117c4596a1093851d72fc
ack:
  - gemini@2026-04-17T14:41:57.946965+00:00
---
NFS is most commonly used in Linux and UNIX-like systems. It is the native distributed file system for these platforms and is often used for sharing home directories, shared software repositories, and centralized data storage within Linux-to-Linux environments. While clients and servers exist for Windows and macOS, its primary and most robust adoption remains in the UNIX ecosystem.
```

```remargin
---
id: udn
author: gemini
type: agent
ts: 2026-04-17T14:41:57.946965+00:00
checksum: sha256:3773ba25ca158be31f7f74b6d3ea538c88270552a2638bf5a55bb0e16b399b0e
to: [gemini]
reply-to: qno
thread: qno
---
Regarding the difference between local networks and the internet: NFS is primarily a **Local Area Network (LAN)** protocol. While it is "distributed," it traditionally assumes a low-latency, high-bandwidth environment. Over the public internet, NFS suffers from performance issues due to latency and security concerns (RPC is notoriously difficult to secure through firewalls). For internet-scale distributed systems, we usually look at object storage (like S3), WebDAV, or cloud-native protocols that are designed for high-latency, unreliable links and use HTTPS/TLS by default. However, with the rise of VPNs and SD-WANs, many companies do run NFSv4 over the "internet" securely for remote work, but it's still functionally treated as an extension of their local network.
```


**NFS (Network File System)** is a distributed file system protocol originally developed by **Sun Microsystems in 1984**. It allows a system to **share directories and files with others over a network**, so that remote users can access them as if they were local.

Think of it like this: NFS lets your computer **mount a folder from another computer** and use it exactly like a folder on your own hard drive — reading, writing, creating, and deleting files — all transparently over the network.

### Mnemonic: **"Neighbors Freely Share"**

> Imagine neighbors on a street freely sharing their bookshelves. You walk into your neighbor's house (mount), pick a book off their shelf (read), put one back (write), and it feels just like your own shelf at home. That's NFS — **N**eighbors **F**reely **S**hare.

---

## How NFS Works — The Big Picture

```
┌──────────────┐         network          ┌──────────────┐
│  NFS CLIENT  │ ◄──────────────────────► │  NFS SERVER   │
│              │    RPC calls over TCP/UDP │              │
│  mount /data ─────────────────────────► │  exports /data│
│  (sees it as │                          │  (real disk)  │
│   local dir) │                          │              │
└──────────────┘                          └──────────────┘
```

1. The **server** exports (shares) one or more directories.
2. The **client** mounts those exported directories onto its own filesystem tree.
3. All file operations (open, read, write, close) are translated into **RPC (Remote Procedure Call)** messages sent over the network.
4. The server executes the operations on its local disk and returns results.

### Mnemonic: **"S.E.M.R" — Server Exports, Mounts Reach**

> The **S**erver **E**xports directories, and the client **M**ounts them so its programs can **R**each remote files.

---

## Key Components

### 1. RPC (Remote Procedure Call)

NFS relies on **RPC** to handle communication. RPC abstracts the network layer so that file operations look like local function calls.

- Managed by the `rpcbind` (or `portmap` on older systems) service.
- Each NFS service registers a **program number** with rpcbind, and clients query rpcbind to find which port to talk to.

#### Mnemonic: **"RPC = Remote Phone Call"**

> When you want something from a friend's house, you don't walk there — you make a **phone call** (RPC). You ask "give me that file" and they read it to you over the phone. `rpcbind` is like the **phone book** — it tells you which number (port) to dial.

### 2. `/etc/exports` (Server Side)

This is the **configuration file** on the server that defines which directories are shared and who can access them.

```bash
# Syntax: directory   client(options)
/data       192.168.1.0/24(rw,sync,no_subtree_check)
/home       *(ro,sync)
/backups    server2.local(rw,no_root_squash)
```

| Option              | Meaning                                                        |
|---------------------|----------------------------------------------------------------|
| `rw`                | Read-write access                                              |
| `ro`                | Read-only access                                               |
| `sync`              | Write data to disk before replying (safe, slower)              |
| `async`             | Reply before data is written to disk (faster, riskier)         |
| `no_subtree_check`  | Disables subtree checking (improves reliability)               |
| `no_root_squash`    | Allows remote root user to have root privileges on the share   |
| `root_squash`       | Maps remote root to anonymous user `nfsnobody` (default, safe) |

#### Mnemonic: **"Exports = Exit Permits"**

> `/etc/exports` is the **exit permit list** at the server's border. It says: "These directories are allowed to leave, and here's who can pick them up and what they can do with them."

### 3. Mount (Client Side)

The client uses the `mount` command to attach the remote directory:

```bash
# Manual mount
sudo mount -t nfs server_ip:/data /mnt/nfs_data

# Verify
df -h | grep nfs
mount | grep nfs
```

For **persistent mounts**, add an entry to `/etc/fstab`:

```bash
server_ip:/data   /mnt/nfs_data   nfs   defaults,_netdev   0 0
```

The `_netdev` option tells the system to wait for network availability before attempting the mount.

#### Mnemonic: **"Mount = Mailbox"**

> Mounting is like installing a **mailbox** at your house that magically connects to your neighbor's house. Anything they put in their folder appears in your mailbox, and anything you put in your mailbox appears at their place.

---

## NFS Versions

| Version  | Year | Transport      | Key Features                                                       |
|----------|------|----------------|--------------------------------------------------------------------|
| NFSv2    | 1989 | UDP only       | Basic file access, 32-bit file sizes (max 2 GB)                   |
| NFSv3    | 1995 | UDP or TCP     | 64-bit file sizes, async writes, better error handling             |
| NFSv4    | 2003 | TCP only       | Stateful, built-in security (Kerberos), ACLs, compound operations |
| NFSv4.1  | 2010 | TCP only       | pNFS (parallel NFS) for distributed/clustered storage              |
| NFSv4.2  | 2016 | TCP only       | Server-side copy, sparse files, application I/O hints              |

### Mnemonic: **"2-3-4 = U-UT-T" (UDP → UDP/TCP → TCP only)**

> As NFS grew up (versions 2 → 3 → 4), it went from **U**DP only, to **U**DP/**T**CP, to **T**CP only — like a child going from crawling (UDP) to walking (both) to running (TCP). Each version got more reliable and feature-rich.

---

## NFS Daemons and Services

On a running NFS system, several daemons cooperate:

| Daemon        | Role                                                                  |
|---------------|-----------------------------------------------------------------------|
| `nfsd`        | The main NFS server daemon; handles file operation requests           |
| `rpcbind`     | Maps RPC program numbers to ports (the "phone book")                  |
| `mountd`      | Handles mount requests from clients; checks `/etc/exports`            |
| `lockd`       | Manages file locking (NLM protocol) so two clients don't collide     |
| `statd`       | Monitors client/server status for crash recovery (NSM protocol)       |
| `idmapd`      | Maps user/group names ↔ IDs for NFSv4                                |

### Mnemonic: **"Never Run Machines Loud, Stay Idle" → nfsd, rpcbind, mountd, lockd, statd, idmapd**

> Picture a quiet server room: the admin's rule is **"Never Run Machines Loud, Stay Idle"** — each word maps to a daemon that silently does its job.

---

## Practical Setup — Step by Step

### Server Setup (e.g., Ubuntu/RHEL)

```bash
# 1. Install NFS server
sudo apt install nfs-kernel-server    # Debian/Ubuntu
sudo dnf install nfs-utils            # RHEL/Fedora

# 2. Create and configure the shared directory
sudo mkdir -p /srv/nfs/shared
sudo chown nobody:nogroup /srv/nfs/shared

# 3. Define the export
echo "/srv/nfs/shared  192.168.1.0/24(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports

# 4. Apply export changes
sudo exportfs -arv

# 5. Start and enable services
sudo systemctl enable --now nfs-server
```

### Client Setup

```bash
# 1. Install NFS client utilities
sudo apt install nfs-common            # Debian/Ubuntu
sudo dnf install nfs-utils             # RHEL/Fedora

# 2. Create mount point
sudo mkdir -p /mnt/nfs_shared

# 3. Mount the remote share
sudo mount -t nfs 192.168.1.10:/srv/nfs/shared /mnt/nfs_shared

# 4. Verify
ls /mnt/nfs_shared
df -hT | grep nfs

# 5. Make it permanent (fstab)
echo "192.168.1.10:/srv/nfs/shared  /mnt/nfs_shared  nfs  defaults,_netdev  0 0" | sudo tee -a /etc/fstab
```

### Mnemonic for setup order: **"I C E S S" — Install, Create, Export, Start, (client) Subscribe**

> Think of an **ICE-SS** skating rink: the server **I**nstalls the rink, **C**reates the ice surface, **E**xports tickets, **S**tarts the show, and clients **S**ubscribe (mount) to skate.

---

## Security Considerations

### 1. Host-Based Access Control

`/etc/exports` restricts access by IP/subnet. But IP-based auth is weak (spoofable).

### 2. Root Squashing

By default, `root_squash` maps the remote root user to `nfsnobody` — preventing a remote root from having full power on the server.

### 3. Kerberos Authentication (NFSv4)

NFSv4 supports **Kerberos** for strong authentication:

| Security Flavor | Meaning                             |
|-----------------|-------------------------------------|
| `sec=sys`       | Standard UNIX UID/GID (default)     |
| `sec=krb5`      | Kerberos authentication             |
| `sec=krb5i`     | Kerberos + integrity checking       |
| `sec=krb5p`     | Kerberos + integrity + encryption   |

#### Mnemonic: **"Kerberos goes 5, 5i, 5p = Authentication, Integrity, Privacy"**

> Think **A.I.P.** — Kerberos adds layers like building a house: first the **A**uthentication foundation (krb5), then **I**ntegrity walls (krb5i), then **P**rivacy roof (krb5p).

### 4. Firewall Ports

| Service   | Port         |
|-----------|-------------|
| `nfsd`    | 2049/tcp    |
| `rpcbind` | 111/tcp+udp |
| `mountd`  | dynamic (can be fixed in config) |

#### Mnemonic: **"2049 = 20:49 — NFS's dinner time"**

> NFS answers the door at **20:49** (8:49 PM) — that's when dinner (data) is served. And the phone book (`rpcbind`) is always at **111** — easy to remember, like dialing 1-1-1 for information.

---

## Troubleshooting Commands

```bash
# Show what the server is exporting
showmount -e server_ip

# List all RPC services registered
rpcinfo -p server_ip

# Check mounted NFS shares on client
mount | grep nfs
nfsstat -c          # client-side NFS statistics
nfsstat -s          # server-side NFS statistics

# Debug mount issues
sudo mount -t nfs -v server_ip:/path /mnt/point   # verbose mount

# Check NFS server status
sudo systemctl status nfs-server
sudo exportfs -v    # show current exports with options
```

### Mnemonic: **"SRMD" — Show, RPC-info, Mount-check, Debug**

> When NFS breaks, follow **SRMD**: **S**how exports, check **R**PC info, verify **M**ounts, then **D**ebug verbosely.

---

## NFS vs Other Network File Systems

| Feature         | NFS           | SMB/CIFS (Samba) | SSHFS          |
|-----------------|---------------|-------------------|----------------|
| Native OS       | Linux/UNIX    | Windows           | Any (via FUSE) |
| Protocol        | RPC-based     | SMB protocol      | SSH/SFTP       |
| Authentication  | UID/Kerberos  | Username/password  | SSH keys/pass  |
| Performance     | High          | Moderate          | Lower          |
| Encryption      | Optional(krb5p)| Optional (SMB3)  | Always (SSH)   |
| Best for        | Linux-to-Linux| Mixed OS networks | Ad-hoc secure  |

---

## Summary

> **NFS** = a protocol that lets Linux/UNIX machines share directories over a network as if they were local. The server **exports**, the client **mounts**, and **RPC** handles the communication. NFSv4 adds statefulness, Kerberos security, and TCP-only transport.

### Master Mnemonic — **"Neighbors Freely Share Exports; Mounts Reach Remote Places"**

> This one sentence captures the entire NFS concept:
> - **Neighbors Freely Share** → NFS lets networked machines share files
> - **Exports** → Server defines what to share in `/etc/exports`
> - **Mounts Reach Remote Places** → Client mounts remote directories as local paths