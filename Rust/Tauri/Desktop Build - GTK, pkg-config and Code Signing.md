---
title: Tauri Desktop Build — GTK, pkg-config & Code Signing
description: ''
author: generic-claude-agent
created: 2026-09-10T00:00:00.000000+00:00
remargin_pending: 0
remargin_pending_for: []
remargin_last_activity: null
---

# Tauri Desktop Build — GTK, pkg-config & Code Signing

Notes from debugging a real `pnpm build` failure in a Tauri desktop app (Kivo) on Fedora Linux. Covers, in the order they showed up: why a Rust *-sys crate needs a C library at build time, how Tauri's Linux backend depends on GTK/WebKitGTK, how the updater's code-signing works, and what the produced `.rpm`/`.deb` files actually are.

---

## 1. The build pipeline — where Rust build scripts fit

`pnpm build` for a Tauri app runs two stages:

1. `vite build` — bundles the JS/TS frontend into `dist/`. Pure Node tooling, nothing OS-specific.
2. `cargo build --release` (invoked by the Tauri CLI) — compiles the Rust backend and links it against native system libraries.

Stage 2 is where things broke. Many Rust crates ship a `build.rs` — a "custom build command" that Cargo compiles and *runs* before your actual crate code compiles. It's used for codegen, feature detection, or (most commonly for FFI crates) locating a system library.

```
error: failed to run custom build command for `gdk-sys v0.18.2`
Caused by:
  process didn't exit successfully: `.../build-script-build` (exit status: 1)
```

This error means: Cargo got past downloading/parsing the crate, but the crate's *own* setup logic failed — not a compile error in the usual sense.

**Further reading**
- [Cargo Book — Build Scripts](https://doc.rust-lang.org/cargo/reference/build-scripts.html) — canonical reference for `build.rs`: inputs, outputs, `cargo:` directives.
- [The Cargo Book — Build Script Examples](https://doc.rust-lang.org/cargo/reference/build-script-examples.html) — the "Linking to system libraries" example is exactly this case.

---

## 2. `pkg-config` and the `*-sys` crate pattern

The actual failing command, from the build log:

```
pkg-config exited with status code 1
> PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 pkg-config --libs --cflags gdk-3.0 'gdk-3.0 >= 3.22'

The system library `gdk-3.0` required by crate `gdk-sys` was not found.
The file `gdk-3.0.pc` needs to be installed and the PKG_CONFIG_PATH
environment variable must contain its parent directory.
```

**`pkg-config`** is a Linux/Unix tool that answers one question for compilers and linkers: *"where are this C library's headers and shared object files?"* It answers by reading `.pc` metadata files (e.g. `gdk-3.0.pc`) installed alongside the library's dev package. `PKG_CONFIG_PATH` tells it which directories to search.

**`gdk-sys`** is not GTK itself — it's a *raw FFI binding crate* that declares Rust function signatures matching the C library `libgdk-3.0.so`. It doesn't reimplement anything; at build time it must find and link against the real system library, which is why a pure `cargo build` can't just download it like a normal crate. This is the `gtk-rs` project's pattern: `glib-sys` → `gobject-sys` → `gdk-sys`/`gio-sys` → `gtk-sys`, each layer binding one C library.

Root cause on this machine: GTK3's dev package (which ships `gdk-3.0.pc`) wasn't installed, so `PKG_CONFIG_PATH` had nothing to search.

**Further reading**
- [freedesktop.org — pkg-config](https://www.freedesktop.org/wiki/Software/pkg-config/) — what `.pc` files are and how the tool resolves them.
- [`pkg-config` crate docs (docs.rs)](https://docs.rs/pkg-config/latest/pkg_config/) — the Rust crate that `build.rs` scripts use to shell out to system `pkg-config`.
- [gtk-rs project](https://gtk-rs.org/) — the Rust/GTK bindings ecosystem; explains the `-sys` vs. high-level crate split.
- [GTK3 documentation](https://docs.gtk.org/gtk3/) — the C library `gdk-3.0` actually binds to.

---

## 3. Why Tauri needs GTK3 at all

Tauri doesn't ship its own browser engine (unlike Electron, which bundles Chromium). It embeds the OS's native webview:

| OS      | Webview engine |
|---------|----------------|
| macOS   | WKWebView |
| Windows | WebView2 |
| Linux   | **WebKitGTK** (built on GTK3) |

So the dependency chain on Linux is: **Tauri** → `tao`/`wry` (Tauri's windowing/webview crates) → `webkit2gtk` → **GTK3** → `gdk-sys`/`gtk-sys`. That's why a Tauri build on a fresh Linux machine needs GTK3 + WebKitGTK *dev* packages installed via the system package manager — `pnpm install` can't provide these, they're not JS or crates.io dependencies.

Fix used here (Fedora):
```bash
sudo dnf install gtk3-devel webkit2gtk4.1-devel libappindicator-gtk3-devel librsvg2-devel patchelf
```

**Further reading**
- [Tauri docs](https://tauri.app/) — main documentation.
- [Tauri — Prerequisites](https://tauri.app/start/prerequisites/) — per-OS system dependency list.
- [WebKitGTK](https://webkitgtk.org/) — the Linux webview engine itself.

---

## 4. Updater code signing (minisign)

After the GTK issue was fixed, the build succeeded and produced `.deb`/`.rpm` bundles — but a *second* build (with the updater bundle target) failed differently:

```
A public key has been found, but no private key.
Make sure to set `TAURI_SIGNING_PRIVATE_KEY` environment variable.
```

The project's `tauri.conf.json` has the updater plugin enabled with a `pubkey` already configured. When enabled, Tauri produces a signature file (`.sig`) alongside each bundle so a running app can verify an update came from the real publisher before installing it — this is an **asymmetric signing scheme (minisign)**:

- **Public key** → committed in `tauri.conf.json`, safe to share.
- **Private key** → must be supplied only at build time, via `TAURI_SIGNING_PRIVATE_KEY` (and optionally `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`), never committed.

Since only the public key existed locally, signing failed. The private key (generated once via the Tauri CLI's `signer generate` command) should live in a secrets manager / CI secret, not the repo.

**Further reading**
- [Tauri — Updater plugin](https://tauri.app/plugin/updater/) — config shape, how signing/verification works end to end.
- [minisign](https://jedisct1.github.io/minisign/) — the underlying signing tool/format Tauri's updater is built on.

---

## 5. What the `.rpm`/`.deb` output actually is

A successful bundle step produces platform-native installers, e.g.:

```
target/release/bundle/deb/Kivo_0.4.1_amd64.deb
target/release/bundle/rpm/Kivo-0.4.1-1.x86_64.rpm
```

These aren't required for local testing — the same compiled binary is runnable directly at `target/release/kivo`. Installing the package (`sudo dnf install ./Kivo-....rpm` on Fedora — the `.deb` is for Debian/Ubuntu and won't install via `dnf`) is only needed to validate the actual end-user install experience: desktop entry, icon registration, uninstall via the package manager.

**Further reading**
- [RPM Packaging Guide](https://rpm-packaging-guide.github.io/) — what's inside an `.rpm` and how install/removal works.
- [dnf documentation](https://dnf.readthedocs.io/) — the package manager used on Fedora.
- [Debian Policy Manual](https://www.debian.org/doc/debian-policy/) — `.deb` format reference, for comparison.

---

## Mental Model

```
pnpm build
 ├─ vite build            → dist/ (pure JS, no OS deps)
 └─ cargo build --release → Rust backend, needs native libs
      └─ gdk-sys build.rs → pkg-config gdk-3.0 → needs GTK3 dev headers installed
           (because Tauri's Linux webview = WebKitGTK, built on GTK3)
      └─ bundler          → .deb / .rpm (installable) + .sig (if updater signing key present)
```

## Suggested reading order
1. Cargo build scripts (section 1) — understand *why* a crate can fail before compiling your code
2. pkg-config + `-sys` crates (section 2) — understand *what* was actually missing
3. Tauri prerequisites (section 3) — understand *why* Tauri specifically needs it on Linux
4. Updater/minisign (section 4) — separate concern, only relevant once packaging works
5. RPM/dnf (section 5) — only needed if you want the full install experience, not for dev iteration
