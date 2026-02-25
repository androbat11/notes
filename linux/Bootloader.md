# Bootloader

## What is a Bootloader?

A **bootloader** is a small program that runs immediately after the hardware is powered on, before the operating system starts. It lives in a specific location on storage (typically the first sector of a disk or a dedicated EFI partition) and its sole responsibility is to load the operating system kernel into memory and hand over control to it.

The bootloader bridges the gap between raw hardware and a running OS. When you press the power button, the CPU has no OS to rely on — the bootloader is what makes the transition possible.

## Boot Sequence Overview

```
Power ON
   └── Firmware (BIOS / UEFI)
           └── POST (Power-On Self-Test)
                   └── Bootloader (e.g., GRUB2)
                           └── Kernel loaded into RAM
                                   └── init / systemd
                                           └── User Space
```

### Firmware Stage (BIOS / UEFI)

- **BIOS** (Basic Input/Output System): Legacy firmware. Reads the first 512 bytes of the boot disk (the **MBR** — Master Boot Record) to find the bootloader.
- **UEFI** (Unified Extensible Firmware Interface): Modern replacement for BIOS. Reads bootloader executables (`.efi` files) from a dedicated **ESP** (EFI System Partition), usually mounted at `/boot/efi`.

## Main Purpose of a Bootloader

1. **Locate the kernel** — Find the OS kernel file (e.g., `/boot/vmlinuz`) on the filesystem.
2. **Load the kernel into RAM** — Copy the kernel image from disk into memory so the CPU can execute it.
3. **Pass parameters to the kernel** — Provide boot options such as the root partition, runlevel, or debug flags (kernel command line arguments).
4. **Load the initial RAM disk** — Load `initrd` / `initramfs`, a temporary root filesystem used by the kernel to mount the real root filesystem.
5. **Transfer control** — Jump execution to the kernel entry point, ending the bootloader's role entirely.

A secondary but important purpose is providing a **boot menu** — allowing the user to choose between multiple kernels or operating systems (dual-boot scenarios).

## Bootloader Storage Locations

| Firmware | Location of Bootloader |
|----------|------------------------|
| BIOS/MBR | First 446 bytes of disk (MBR), stage 2 in disk gaps or `/boot` |
| UEFI/GPT | EFI System Partition (ESP) as a `.efi` executable |

## Common Linux Bootloaders

- **GRUB2** (Grand Unified Bootloader v2) — The standard bootloader on most Linux distributions.
- **systemd-boot** — A lightweight UEFI-only bootloader, increasingly used on Arch and Fedora.
- **SYSLINUX / ISOLINUX** — Often used for live USBs and embedded systems.
- **LILO** (Linux Loader) — Legacy, largely obsolete.

## Key Files (GRUB2 on Linux)

| File | Purpose |
|------|---------|
| `/boot/grub2/grub.cfg` | Main GRUB configuration (auto-generated) |
| `/etc/default/grub` | User-editable GRUB settings |
| `/boot/vmlinuz-*` | Compressed Linux kernel |
| `/boot/initramfs-*` | Initial RAM filesystem |
| `/boot/efi/EFI/` | UEFI bootloader executables |

---

## Metacognition Questions

1. **In your own words**, what is the difference between the firmware (BIOS/UEFI) and the bootloader? Why are they two separate stages instead of one?

2. If the bootloader is missing or corrupted, what happens when you power on the machine? What would you need to do to recover it?

3. What is the role of `initramfs` and why does the kernel need a temporary filesystem before it can mount the real root partition?

4. What are the key differences between a BIOS/MBR setup and a UEFI/GPT setup from the bootloader's perspective? Which one would you prefer for a new installation and why?
