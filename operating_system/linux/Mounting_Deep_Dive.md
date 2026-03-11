# Linux: The Architecture of Mounting (Mount/Umount)

In Linux, the filesystem is a **Unified Tree**. There are no "Drive Letters". This is one of the most elegant abstractions in systems engineering.

## 1. The Kernel Layer: VFS (Virtual File System)
The kernel doesn't care if your data is on an SSD, a network drive (NFS), or in RAM (tmpfs). It presents a **Standard Interface**.
**Metacognition:** Why? Because it allows a user program to use the same `open()` or `read()` syscalls regardless of the hardware.

## 2. Mounting: "Grafting" the Tree
When you run `mount /dev/sdb1 /mnt/data`:
1.  **Identify the Device:** `/dev/sdb1` (A "Block Device").
2.  **Point of Entry:** `/mnt/data` (An empty folder).
3.  **The Union:** The kernel "covers up" whatever was in `/mnt/data` with the root folder of the device.

## 3. Unmounting: "The Busy Lock"
If you try `umount /mnt/data` and it fails with `device is busy`, it's because:
-   A shell is `cd`'d into `/mnt/data`.
-   An application (like VLC) is reading a file from there.
-   A daemon (like `updatedb`) is indexing it.

**Senior Tool:** Use `lsof /mnt/data` or `fuser -m /mnt/data` to find the "zombie" process holding your partition hostage.

## 4. The `/etc/fstab` (File System Table)
This is the "Config File for Your Tree." It tells the kernel which branches to graft automatically during the **Bootloader** phase (which you have notes on!).

---

## How to use these exercises
1.  Navigate to `exercises/mounting/`.
2.  Each script (e.g., `01_mount_concepts.sh`) is a "interactive" quiz or simulation.
3.  Run them in your terminal:
    ```bash
    bash 01_mount_concepts.sh
    ```

## The Roadmap
-   [ ] Module 1: The Mount Command (5 Exercises)
-   [ ] Module 2: The Block Device vs File System (5 Exercises)
-   [ ] Module 3: Resolving "Device is Busy" (5 Exercises)
-   [ ] Module 4: Persistence with /etc/fstab (5 Exercises)
