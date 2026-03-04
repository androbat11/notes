# Remote Desktop Protocol (RDP)

## What is RDP?

**Remote Desktop Protocol (RDP)** is a proprietary protocol developed by **Microsoft** that provides a user with a graphical interface to connect to another computer over a network connection. The user employs RDP client software to connect to a remote computer running RDP server software.

> Mnemonic: **"RDP = Remote Display Pipeline"** — it pipes your display, keyboard, and mouse to a remote machine.

---

## Key Facts

| Property        | Value                              |
|-----------------|------------------------------------|
| Developer       | Microsoft                          |
| Default Port    | **3389** (TCP and UDP)             |
| Transport       | TCP (primarily), UDP (RDP 8.0+)    |
| Encryption      | TLS (since RDP 6.0)                |
| OSI Layer       | Application Layer (Layer 7)        |
| Protocol Family | T.128 / T.Share (ITU-T based)      |

> Mnemonic for port: **"33 = double three, 89 = Microsoft's lucky number"** → **3389**

---

## How RDP Works — The CAGE Model

Use **CAGE** to remember the core phases:

| Letter | Phase        | Description                                                                 |
|--------|--------------|-----------------------------------------------------------------------------|
| **C**  | Connect      | Client initiates TCP connection to server on port 3389                      |
| **A**  | Authenticate | Credentials verified (NLA, TLS, or legacy RDP security)                    |
| **G**  | Graphical    | Server captures screen, compresses, and sends bitmap/vector updates to client |
| **E**  | Exchange     | Bidirectional exchange: client sends mouse/keyboard; server sends display   |

---

## Authentication Methods

Three main methods — remember **"OLD"**:

- **O** — **Old/Classic RDP Security** (RC4 encryption, no server cert, vulnerable)
- **L** — **Legacy NTLMv2** (inside TLS tunnel, password-based)
- **D** — **Defense-grade NLA** (Network Level Authentication — Kerberos/NTLM before session starts)

### NLA (Network Level Authentication)

- Authenticates the **user before** the remote desktop session is established.
- Reduces attack surface (no desktop shown to unauthenticated users).
- Uses **CredSSP** (Credential Security Support Provider) protocol.

> Mnemonic: **NLA = "No Login, No Access"** — you must prove who you are before seeing anything.

---

## RDP Components

Remember **"SCRIM"**:

| Letter | Component             | Role                                                          |
|--------|-----------------------|---------------------------------------------------------------|
| **S**  | Server (RDS/RDSH)     | Hosts the desktop/session; runs `TermService`                 |
| **C**  | Client (mstsc.exe)    | The app used to connect (`mstsc` = Microsoft Terminal Services Client) |
| **R**  | Redirections          | Clipboard, drives, printers, audio, USB forwarded to client   |
| **I**  | Input channels        | Keyboard, mouse, touch sent from client to server             |
| **M**  | Multiple channels     | RDP uses **virtual channels** to multiplex data types         |

---

## Virtual Channels

RDP multiplexes data over **virtual channels**. Each channel handles a specific type of data:

- **rdpdr** — Device redirection (drives, printers)
- **rdpsnd** — Audio redirection
- **cliprdr** — Clipboard
- **drdynvc** — Dynamic Virtual Channels (extensible)

> Mnemonic: **"RACD"** = Redirection, Audio, Clipboard, Dynamic

---

## RDP Security Layers

Three layers, remember **"TEN"**:

1. **T** — **TLS** — Full TLS encryption wraps the session (modern default)
2. **E** — **Enhanced RDP Security** — Hybrid: TLS or CredSSP for auth, RDP for session
3. **N** — **Native RDP Security** — Legacy RC4 encryption (insecure, avoid)

---

## Common Vulnerabilities

Remember **"BLEND"**:

| Letter | Vulnerability         | Description                                                         |
|--------|-----------------------|---------------------------------------------------------------------|
| **B**  | BlueKeep (CVE-2019-0708) | Pre-auth RCE, wormable, affects RDP on older Windows              |
| **L**  | Listen port exposure  | Port 3389 open to internet = massive attack surface                 |
| **E**  | EsteemAudit           | NSA exploit targeting RDP on Windows XP/2003                        |
| **N**  | NLA bypass            | Credential relay attacks if NLA misconfigured                       |
| **D**  | DejaBlue              | Follow-up to BlueKeep family (CVE-2019-1181/1182)                  |

---

## RDP vs. Similar Protocols

| Protocol | Developer  | Port | OS Focus      | Notes                              |
|----------|------------|------|---------------|------------------------------------|
| **RDP**  | Microsoft  | 3389 | Windows       | Rich features, NLA, GPU support    |
| **VNC**  | Open-source| 5900 | Cross-platform| Simpler, sends raw pixel data      |
| **NX**   | NoMachine  | 4000 | Linux/Cross   | Efficient compression              |
| **SPICE**| Red Hat    | 5900+| VMs (KVM/QEMU)| Optimized for virtual machines     |
| **X11**  | MIT        | 6000+| Linux/Unix    | Network-transparent windowing      |

> Mnemonic: **"RDP Wins Native eXperiences"** → RDP, VNC, NX, SPICE, X11

---

## RDP on Linux

On Linux, RDP can be used via:

- **Client side**: `rdesktop`, `freerdp` (`xfreerdp`), `Remmina`
- **Server side**: `xrdp` — open-source RDP server for Linux

### xrdp Quick Reference

```bash
# Install xrdp
sudo apt install xrdp       # Debian/Ubuntu
sudo dnf install xrdp       # Fedora/RHEL

# Enable and start
sudo systemctl enable --now xrdp

# Check status
sudo systemctl status xrdp

# Default config
/etc/xrdp/xrdp.ini

# Allow firewall (Fedora/RHEL)
sudo firewall-cmd --add-port=3389/tcp --permanent
sudo firewall-cmd --reload
```

### freerdp (Client) Quick Reference

```bash
# Connect to Windows RDP host
xfreerdp /v:192.168.1.100 /u:Administrator /p:password

# With NLA
xfreerdp /v:192.168.1.100 /u:user /p:pass +auth-only

# Full screen, with clipboard
xfreerdp /v:host /u:user /f /clipboard
```

---

## RDP Handshake — Step by Step

Remember **"CONN-SEC-CAP-CHAN-ACT"**:

1. **CONN** — TCP connection on port 3389
2. **SEC** — Security negotiation (TLS/NLA chosen)
3. **CAP** — Capability exchange (resolution, color depth, features)
4. **CHAN** — Virtual channels established
5. **ACT** — Active session begins (screen updates flow)

---

## Key Concepts Summary — The "GRAPE" card

| Letter | Concept      | One-liner                                              |
|--------|--------------|--------------------------------------------------------|
| **G**  | Graphical    | Transmits graphical desktop over the network           |
| **R**  | Redirection  | Redirects local devices (drives, printers, clipboard)  |
| **A**  | Auth via NLA | Authenticates before session using CredSSP/Kerberos    |
| **P**  | Port 3389    | Default TCP/UDP port                                   |
| **E**  | Encryption   | TLS wraps all traffic in modern implementations        |

---

## Quick Self-Test Questions

1. What port does RDP use by default?
2. What does NLA stand for and why is it more secure than classic RDP security?
3. Name three types of virtual channels in RDP.
4. What is BlueKeep and what makes it especially dangerous?
5. What Linux package acts as an RDP server?
6. What protocol does NLA use to deliver credentials before session setup?
7. How does RDP differ from VNC in terms of what is transmitted over the network?
8. List the five phases of the RDP handshake in order.
