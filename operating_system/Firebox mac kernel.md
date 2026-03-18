# macOS Kernel Panic — Deep Dive Learning Session

> **Machine:** MacBookPro16,1 · Intel UHD 630 (Kaby Lake)
> **OS:** macOS Tahoe BETA · Darwin 25.3.0 · January 2026
> **Crash:** Kernel panic type 14 (page fault) · pid 1131 (Firefox GPU Helper)
> **Fault address:** `CR2: 0xfffffface6f0b628`
> **Crash chain:** IOSurface → IOAcceleratorFamily2 → AppleIntelKBLGraphics
> **Context:** Docker Desktop running → memory pressure

---

## How to use this note

This is a structured, bottom-up learning session. Each section introduces one concept, anchors it to the real crash above, includes diagrams, and ends with **metacognition questions**. Answer them before reading the next section — that's the whole point.

---

## Concept 1 — What Is a Kernel Panic, and Why Can't the Kernel Recover?

### The two worlds: kernel space vs. user space

Your Mac runs two fundamentally different "worlds" of code at all times.

```
┌─────────────────────────────────────────────────────────┐
│                     USER SPACE                          │
│                                                         │
│   Firefox.app   Docker Desktop   Terminal   Spotify     │
│       pid 1131      pid 872       pid 540    pid 210    │
│                                                         │
│   Each process thinks it owns all of memory.            │
│   Each process can crash without affecting others.      │
│   The OS can kill any of them and keep running.         │
├─────────────────────────────────────────────────────────┤
│              KERNEL SPACE  (ring 0)                     │
│                                                         │
│   Virtual Memory Manager    Scheduler    File System    │
│   IOKit (driver framework)  Network Stack               │
│   AppleIntelKBLGraphics.kext  IOSurface.kext            │
│                                                         │
│   One shared address space. One crash = everything      │
│   crashes. No one can catch the exception from outside. │
└─────────────────────────────────────────────────────────┘
```

The CPU enforces this boundary in hardware using **privilege rings**. Ring 3 (user space) cannot directly touch hardware or other processes' memory. Ring 0 (kernel) can do anything — and that's exactly why a bug there is catastrophic.

---

### What a kernel panic actually is

A kernel panic is the kernel detecting that it is in an **unrecoverable inconsistent state** and choosing to halt immediately rather than continue.

Think of it like this: you're a surgeon mid-operation and you suddenly realize the patient has a condition that makes continuing the surgery more dangerous than stopping. You stop. You don't wing it.

The kernel's version of "stopping" is:
1. Freeze all CPUs
2. Write a panic log to NVRAM
3. Reboot (or halt, depending on settings)

```
Normal execution
      │
      ▼
[Fault detected — e.g., invalid memory access in kernel]
      │
      ├─ Is it in user space? → YES → Kill the process, keep running
      │
      └─ Is it in kernel space? → YES
              │
              ▼
       Can we recover safely?
              │
              └─ Almost always: NO
                      │
                      ▼
              ┌──────────────────────┐
              │    KERNEL PANIC      │
              │  1. Freeze all CPUs  │
              │  2. Dump panic log   │
              │  3. Reboot           │
              └──────────────────────┘
```

---

### Why "no choice but to halt"

The kernel is the root of trust for everything. It manages:
- Which memory belongs to which process
- Whether a write to disk actually hits the right file
- Whether the network packet goes to the right socket

If the kernel's own data structures are corrupted (e.g., a pointer in the virtual memory manager points to garbage), **any** decision the kernel makes going forward could be wrong — silently wrong. Continuing would be worse than stopping because:

- You could corrupt files on disk (permanent data loss)
- You could leak one process's secrets to another (security breach)
- You could silently return wrong data to every program on the system

The kernel panics because **known death is safer than unknown corruption**.

---

### Anchored to your crash

Your panic was triggered in **kernel space**, not in Firefox itself. Here's what happened at the boundary:

```
Firefox (pid 1131) — USER SPACE
  │
  │  "Hey GPU, render this web content"
  │  [syscall / IOKit user client call]
  ▼
IOSurface.kext — KERNEL SPACE
  │
  ▼
IOAcceleratorFamily2.kext — KERNEL SPACE
  │
  ▼
AppleIntelKBLGraphics.kext — KERNEL SPACE
  │
  │  ← BOOM: page fault type 14 at 0xfffffface6f0b628
  │     The driver dereferenced an invalid pointer.
  │     We are deep in kernel space. No recovery possible.
  ▼
KERNEL PANIC
```

Firefox didn't crash the kernel — it just asked the GPU driver to do something. The GPU driver (a kext, living in kernel space) had a bug or hit unexpected memory conditions and accessed an invalid address. At that point, the kernel had no choice.

---

### Metacognition checkpoint

Before moving to the next concept (virtual memory + page faults), answer these:

**Q1.** Firefox itself didn't kernel panic — it was the GPU driver. Yet Firefox's process ID (pid 1131) shows up in the panic log. Why does a user-space process ID appear in a kernel panic caused by kernel-space code?

**Q2.** I said "the kernel can kill a user-space process and keep running, but it can't recover from its own fault." What property of kernel space makes self-recovery so hard? (Hint: think about what the kernel would need in order to catch its own exception.)

**Q3.** The kernel froze **all CPUs** during the panic, not just the one that faulted. Why all of them? What bad thing could happen if the other CPUs kept running while one had just detected a fatal inconsistency?

---
*Answer these before continuing. Next section: [[#Concept 2 — Virtual Memory and the Page Fault]]*

---

## Concept 2 — Virtual Memory and the Page Fault

*(Unlock after answering Concept 1 questions)*

### Why virtual memory exists

Every process on your Mac — Firefox, Docker, Terminal — believes it has access to a large, contiguous address space starting at address 0. On a 64-bit system, that's theoretically 16 exabytes of address space per process. Obviously your 16 GB of RAM can't provide that. Virtual memory is the illusion that makes this work.

```
Firefox thinks it sees:               Physical RAM (16 GB real):
┌──────────────────┐                 ┌──────────────────┐
│ 0x000000000000   │                 │  Page A (4 KB)   │ ← Firefox stack
│ Firefox stack    │ ─────────────►  ├──────────────────┤
├──────────────────┤                 │  Page B (4 KB)   │ ← Docker heap
│ 0x000000010000   │      ┌────────► ├──────────────────┤
│ Firefox heap     │      │          │  Page C (4 KB)   │ ← Firefox heap
├──────────────────┤      │          ├──────────────────┤
│ 0x000000020000   │ ─────┘          │  (swap on disk)  │
│ Firefox code     │                 └──────────────────┘
└──────────────────┘

Docker sees its OWN virtual address 0x000000010000
mapping to a COMPLETELY DIFFERENT physical page.
```

The hardware unit that performs this translation is the **MMU (Memory Management Unit)**. It uses a data structure called a **page table** maintained by the kernel.

---

### Pages and the page table

Memory is divided into fixed-size chunks called **pages** (typically 4 KB on x86, 16 KB on Apple Silicon). The page table is a multi-level structure that maps virtual page numbers → physical page frames.

```
Virtual Address: 0xfffffface6f0b628  (your CR2 fault address)
                 │
                 ▼
        ┌─────────────────┐
        │   Page Table    │  (per-process, maintained by kernel)
        │                 │
        │  0xfffffface6f0b  →  ???  NOT FOUND / NOT PRESENT
        └─────────────────┘
                 │
                 ▼
        MMU raises: PAGE FAULT
        CPU saves state, jumps to kernel fault handler
```

---

### The three kinds of page fault

Not all page faults are errors. The kernel distinguishes:

```
PAGE FAULT
    │
    ├─ 1. VALID but NOT PRESENT
    │      → Page was swapped to disk
    │      → Kernel loads it back from disk ("page in")
    │      → Resume execution transparently
    │      → This is NORMAL and happens constantly
    │
    ├─ 2. VALID, PRESENT, WRONG PERMISSIONS
    │      → Write to read-only page (e.g., code segment)
    │      → Kernel sends SIGSEGV to process
    │      → Process can handle or die — OS survives
    │
    └─ 3. COMPLETELY INVALID ADDRESS
           → No mapping exists at all
           → In user space: SIGSEGV → process dies, OS fine
           → In kernel space: PANIC (type 14 = this one)
                              ← YOUR CRASH
```

**Fault type 14** on x86-64 means:
- Page not present (bit 0 = 0)
- Write access attempted (bit 1 = 1)
- Occurred in kernel mode (bit 2 = 0)
- Reserved bits violated (bit 3 = 1) — this signals something especially wrong

---

### Your CR2 address decoded

`CR2` is a CPU register that the hardware automatically sets to the **faulting virtual address** whenever a page fault occurs. It's the address that couldn't be translated.

```
CR2: 0xfffffface6f0b628

0xffff...  → High canonical address range
             On macOS (x86-64), kernel space lives above 0xffffff8000000000
             So this IS a kernel-space address — the driver tried to
             dereference a kernel pointer that was invalid/stale.
```

The most likely explanation: the Intel Kaby Lake GPU driver held a **pointer to a kernel object** (probably an IOSurface buffer descriptor). Under memory pressure from Docker, that object was freed or moved. The driver then used the stale pointer — and the MMU found no valid mapping at that address anymore. Fault type 14. Panic.

```
Timeline of your crash:

t=0  Docker allocates large memory → system under pressure
t=1  Kernel frees/compacts some GPU-related kernel objects
t=2  Firefox asks GPU driver to render
t=3  AppleIntelKBLGraphics reads stale pointer: 0xfffffface6f0b628
t=4  MMU: "That address has no mapping" → fault type 14
t=5  Fault handler: "We're in kernel mode. No recovery."
t=6  KERNEL PANIC
```

---

### Metacognition checkpoint

**Q1.** I said page faults of type "valid but not present" are completely normal and happen constantly. Give me an analogy from your own experience as a developer where something is "logically available" but needs to be fetched before you can use it. Then explain how the kernel's handling of this mirrors that pattern.

**Q2.** Why does the kernel maintain a **separate page table per process**? What would go wrong if all processes shared one page table?

**Q3.** The CR2 address `0xfffffface6f0b628` starts with `0xffff...`. I told you kernel space on macOS x86-64 starts above `0xffffff8000000000`. Does that mean this address is in kernel space or user space? And if a **kernel driver** faulted on a **kernel-space address**, what does that tell us about where the bug likely is — in Firefox, in the kernel itself, or in the driver?

---
*Answer these before continuing. Next section: [[#Concept 3 — Kernel Extensions (kexts) and Why They're Dangerous]]*



---

## Concept 3 — Kernel Extensions (kexts) and Why They're Dangerous

*(Unlock after answering Concept 2 questions)*

### What a kext is

A **kernel extension** (kext) is a dynamically loadable bundle of code that runs directly in kernel space — ring 0, full privileges, shared address space with the kernel itself.

```
macOS Kernel address space:
┌────────────────────────────────────────┐
│  XNU kernel core (Mach + BSD + IOKit)  │
├────────────────────────────────────────┤
│  IOSurface.kext          (Apple)       │
│  IOAcceleratorFamily2.kext (Apple)     │
│  AppleIntelKBLGraphics.kext  ← YOURS  │  Third-party or Apple OEM
│  com.docker.driver.*.kext   ← Docker  │  drivers loaded here
│  ...other kexts...                     │
├────────────────────────────────────────┤
│  Shared kernel data structures         │
│  (vm_map, ipc_space, page tables...)   │
└────────────────────────────────────────┘

All kexts share this space. A bug in ANY kext can
corrupt ANY kernel data structure.
```

Kexts exist because hardware drivers need direct access to hardware registers, DMA memory, and interrupt handlers — things that cannot be done from user space for performance and access reasons.

---

### Why they're uniquely dangerous

In user space, each process is sandboxed. A bug in Firefox corrupts Firefox's memory, and only Firefox dies. The kernel is untouched.

In kernel space, everything shares one address space with no internal protection:

```
User space bug:                    Kernel space bug (kext):

 Firefox ──[bug]──► corrupts       AppleIntelKBLGraphics
 Firefox's own heap                  ──[bug]──► can corrupt:
                                        │
 Result: Firefox crashes               ├─ page tables (now ALL
 Everything else: fine                 │  processes' memory is
                                       │  potentially wrong)
                                       │
                                       ├─ scheduler queues (wrong
                                       │  process gets CPU time)
                                       │
                                       ├─ file system buffers
                                       │  (disk writes go to wrong
                                       │  location)
                                       │
                                       └─ security tokens (privilege
                                          escalation possible)

                                   Result: KERNEL PANIC (best case)
                                           Silent corruption (worst case)
```

This is why Apple has been moving drivers **out** of kernel space into **DriverKit** (user-space drivers, introduced in macOS Catalina). But GPU drivers, for performance reasons, still largely live as kexts.

---

### The kext loading chain in your crash

```
AppleIntelKBLGraphics.kext
    │
    │  Provides: Intel Kaby Lake GPU acceleration
    │  Loaded by: IOKit matching when GPU hardware detected at boot
    │  Depends on:
    ▼
IOAcceleratorFamily2.kext
    │
    │  Provides: Generic GPU acceleration framework
    │  The "middle layer" between specific GPU kexts and IOSurface
    ▼
IOSurface.kext
    │
    │  Provides: Shared GPU memory buffers between processes and GPU
    │  IOSurface buffers are how Firefox hands pixel data to the GPU
    ▼
IOKit (core framework)
    │
    │  Provides: C++ driver framework, device matching, power mgmt
    ▼
XNU Kernel core
```

Firefox's GPU Helper process (pid 1131) opened a **user client** connection to this stack. The actual rendering work happened inside these kexts, in kernel space. When the Kaby Lake kext dereferenced a stale pointer, the fault propagated upward through this stack until the CPU's MMU fired the page fault — type 14 — and the kernel had no choice.

---

### The beta factor

`AppleIntelKBLGraphics.kext` in macOS Tahoe BETA (Darwin 25.3.0, January 2026) is in active development. Intel's integrated GPU support on older Intel Macs tends to receive less testing investment as Apple transitions fully to Apple Silicon. A beta kext in a production-like workload (Firefox hardware acceleration + Docker memory pressure) hit a path the beta engineers hadn't hardened yet.

---

### Metacognition checkpoint

**Q1.** I mentioned Apple is moving drivers to **DriverKit** (user-space drivers). If a DriverKit driver has a bug and accesses invalid memory, what happens compared to a kext with the same bug? What does the system lose by moving drivers to user space?

**Q2.** Docker Desktop also has kernel components (a hypervisor, and on older Docker versions, a kext). Could Docker's kernel code have **directly** caused the page fault that showed up in the Intel GPU driver? Or is there a simpler explanation for Docker's role? Walk me through your reasoning.

**Q3.** The crash chain is: `IOSurface → IOAcceleratorFamily2 → AppleIntelKBLGraphics`. Does this chain represent the **call stack at the time of the crash** (i.e., IOSurface called IOAcceleratorFamily2 which called AppleIntelKBLGraphics), or does it represent the **dependency graph** (IOSurface depends on IOAcceleratorFamily2 depends on AppleIntelKBLGraphics)? Why does the distinction matter when debugging?

---
*Answer these before continuing. Next section: [[#Concept 4 — What Is GPU Acceleration and Why Browsers Use It]]*

---

## Concept 4 — What Is GPU Acceleration and Why Browsers Use It

*(Unlock after answering Concept 3 questions)*

### The CPU is a sprinter. The GPU is a marching band.

Before understanding why Firefox uses a GPU at all, you need a mental model of what makes a GPU fundamentally different from a CPU.

```
CPU (Intel Core i9-9880H in your MacBook Pro):
┌────────────────────────────────────────────────────────┐
│  Core 0   Core 1   Core 2   Core 3                     │
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐                   │
│ │ ALU  │ │ ALU  │ │ ALU  │ │ ALU  │  8 cores total     │
│ │ FPU  │ │ FPU  │ │ FPU  │ │ FPU  │  ~5 GHz each       │
│ │ OOO* │ │ OOO* │ │ OOO* │ │ OOO* │  huge caches       │
│ └──────┘ └──────┘ └──────┘ └──────┘  deep branch pred. │
│                                                         │
│  *OOO = out-of-order execution                          │
│  Good at: complex, branchy, sequential logic            │
│  Bad at: doing the same simple thing a million times    │
└────────────────────────────────────────────────────────┘

GPU (Intel UHD 630 integrated in your MacBook Pro):
┌────────────────────────────────────────────────────────┐
│  EU  EU  EU  EU  EU  EU  EU  EU                        │
│  EU  EU  EU  EU  EU  EU  EU  EU   24 Execution Units   │
│  EU  EU  EU  EU  EU  EU  EU  EU   ~300–1200 MHz each   │
│                                   no branch prediction  │
│  Each EU = simple shader processor                      │
│  All 24 run simultaneously, in parallel                 │
│                                                         │
│  Good at: doing the SAME simple operation on            │
│           millions of data points at once               │
│  Bad at: complex branchy logic, sequential dependencies │
└────────────────────────────────────────────────────────┘
```

Painting a 2560×1600 display means computing the color of **4,096,000 pixels**. Each pixel's color is a relatively simple math operation (blend layers, apply shadows, interpolate gradients). That's exactly the GPU's strength — not smarter, just wider.

---

### Why rendering a webpage is a parallel problem

A web page is made of **layers** — the background, a scrolling text area, a video, a floating dropdown, a CSS animation. The browser doesn't paint the page as one flat image. It maintains each layer independently and **composites** them together at the end.

```
DOM + CSS
    │
    ▼ Layout engine
Render Tree  (every element: position, size, z-index, opacity)
    │
    ▼ Paint step
Per-layer paint commands  (vector drawing instructions, not pixels yet)
    │
    │
    ├──── WITHOUT GPU ACCELERATION (software rendering) ────────────┐
    │                                                               │
    │     CPU rasterizes each layer (paint cmds → pixels)          │
    │     CPU composites all layers (blend, clip, transform)        │
    │     CPU writes final bitmap to display framebuffer            │
    │     Sequential. One core doing most of the work.             │
    │     Slow on heavy pages. High CPU usage. Drains battery.      │
    │                                                               │
    └──── WITH GPU ACCELERATION (hardware rendering) ───────────────┤
                                                                    │
         CPU uploads layer textures to GPU memory (via IOSurface)  │
         GPU rasterizes all layers in parallel                      │
         GPU composites layers using dedicated blend hardware        │
         Result already in GPU framebuffer → display directly       │
         Fast. Low CPU usage. GPU idle power is minimal.            │
                                                                    ▼
                                                              Screen output
```

This is why "disable hardware acceleration" in Firefox exists — it's a fallback to the slow-but-reliable software path. Your crash is a perfect example of when that tradeoff is worth it.

---

### The Firefox multi-process GPU architecture

Firefox doesn't render GPU commands from the main browser process. It uses **process isolation** — a dedicated GPU Helper process:

```
┌────────────────────────────────────────────────────────────────┐
│  USER SPACE                                                    │
│                                                                │
│  ┌──────────────────┐     ┌──────────────────┐                │
│  │  Firefox Main    │     │  Firefox GPU     │                │
│  │  Process         │     │  Helper          │                │
│  │                  │     │  pid 1131  ←─────┼── YOUR CRASH   │
│  │  - JS engine     │ IPC │                  │                │
│  │  - DOM/layout    │────►│  - WebRender     │                │
│  │  - networking    │     │  - OpenGL/Metal  │                │
│  │  - UI logic      │     │  - IOKit calls   │                │
│  │                  │     │  - IOSurface mgmt│                │
│  └──────────────────┘     └────────┬─────────┘                │
│                                    │ IOKit user client         │
└────────────────────────────────────┼───────────────────────────┘
                                     │ user/kernel boundary
┌────────────────────────────────────▼───────────────────────────┐
│  KERNEL SPACE                                                  │
│  IOSurface → IOAcceleratorFamily2 → AppleIntelKBLGraphics      │
└────────────────────────────────────────────────────────────────┘
```

The separation exists for **fault isolation**: if the GPU helper crashes (e.g., a bad GPU command hangs or segfaults), the main Firefox process survives and can restart the GPU helper. Tabs don't die. Your session is preserved.

But notice the critical implication: **the GPU helper is the only Firefox process that ever touches the kernel GPU driver stack**. The main Firefox process never calls IOKit directly. So when the kernel panic happened, it was the GPU helper's IOKit calls — not Firefox's JS engine, not the DOM engine — that walked down into `AppleIntelKBLGraphics.kext` and hit the stale pointer.

---

### What "hardware acceleration" means at each layer

The term gets used loosely. Here's what it actually means at each level of the stack:

```
Level               What is accelerated           What does the GPU do?
─────────────────────────────────────────────────────────────────────
CSS Transforms      2D/3D matrix math             Matrix multiply per vertex
CSS Animations      Interpolation between frames  Shader runs each frame
Canvas 2D           Path rasterization            Parallel fill operations
WebGL / WebGPU      Arbitrary GPU programs        Runs your shader code
Video decode        H.264/H.265 decode            Fixed-function HW decoder
Compositing         Layer blending + clipping      Fixed blend pipeline
─────────────────────────────────────────────────────────────────────

Your crash scenario:
Firefox was compositing web content layers.
→ GPU Helper called into IOAcceleratorFamily2 to schedule a
  compositing command buffer.
→ The command buffer referenced an IOSurface (a shared texture).
→ AppleIntelKBLGraphics tried to write metadata about that surface.
→ Stale pointer. Fault type 14. Panic.
```

---

### The cost model: why acceleration is a tradeoff

```
Software rendering (CPU):
  PRO: Runs entirely in user space
       No kernel driver involvement
       Bugs crash Firefox, not the OS
  CON: Slow on complex pages
       High CPU usage → hot, loud, battery drain
       Can't do WebGL at all

Hardware acceleration (GPU):
  PRO: Fast — orders of magnitude for compositing
       Frees CPU for JS/networking
       Enables WebGL, hardware video decode
  CON: Requires crossing user/kernel boundary
       Depends on GPU driver correctness (kext quality)
       Beta/buggy kext + edge case = kernel panic
       One bad driver = whole OS down
```

This is the tradeoff Firefox's "Use hardware acceleration when available" setting exposes. On stable macOS with stable drivers, the cost is negligible and the benefits are huge. On macOS Tahoe BETA with a beta Intel kext, the cost was your system crashing.

---

### Anchored to your crash

```
Firefox GPU Helper (pid 1131)
    │
    │  Compositing a web page with hardware acceleration ON
    │
    ├─ Calls Metal/OpenGL → translates to IOKit command
    │
    ▼
IOAcceleratorFamily2.kext
    │
    │  Schedules GPU command buffer
    │  Command buffer references IOSurface texture at: 0xfffffface6f0b628
    │
    ▼
AppleIntelKBLGraphics.kext
    │
    │  Tries to write to IOSurface descriptor (metadata update)
    │  Pointer is stale — Docker caused the kernel to reclaim that page
    │
    ▼
MMU: page not present → fault type 14

  ↑
  This entire path only exists BECAUSE hardware acceleration was enabled.
  Disable it → Firefox never calls this code → no panic.
```

---

### Metacognition checkpoint

**Q1.** The CPU in your MacBook has 8 cores running at ~5 GHz. The Intel UHD 630 has 24 Execution Units at ~300–1200 MHz — slower clock, not that many more units. Yet compositing a 4-million-pixel display is dramatically faster on the GPU. What is the architectural reason the GPU wins here, even with slower individual units? (Hint: think about what "compositing layers" actually means at the per-pixel level.)

**Q2.** Firefox isolates GPU work in a separate helper process (pid 1131). I said this is for "fault isolation" — if the GPU helper crashes, Firefox survives. But in your case, the GPU helper didn't just crash — it caused a **kernel panic** that took down the entire OS. What does this tell you about the limits of process isolation as a safety mechanism? What kind of fault can process isolation protect against, and what kind can it not?

**Q3.** "Hardware acceleration" is often presented as a simple on/off toggle that just makes things faster. But given what you now know about the full kernel stack — IOKit, kexts, IOMMU, shared GPU memory — describe in your own words what disabling hardware acceleration **actually** changes about the execution path. Be specific about which layers of the stack get bypassed. Why does bypassing those layers make the system more stable even if it makes rendering slower?

---
*Answer these before continuing. Next section: [[#Concept 5 — The macOS GPU Driver Stack End-to-End]]*

---

## Concept 5 — The macOS GPU Driver Stack End-to-End

*(Unlock after answering Concept 4 questions)*

### From "draw a div" to "photons leave the screen"

When Firefox renders a webpage element with hardware acceleration, here is the full path — every layer, from JavaScript to the GPU hardware:

```
┌─────────────────────────────────────────────────────────┐
│  FIREFOX (pid 1131) — USER SPACE                        │
│                                                         │
│  JS Engine: "paint this element"                        │
│       ↓                                                 │
│  Gecko Compositor                                       │
│       ↓                                                 │
│  WebRender (Rust-based GPU renderer)                    │
│       ↓                                                 │
│  OpenGL / Metal API calls                               │
└────────────────────┬────────────────────────────────────┘
                     │  User/Kernel boundary crossing
                     │  (Mach IPC / IOKit user client)
┌────────────────────▼────────────────────────────────────┐
│  KERNEL SPACE                                           │
│                                                         │
│  IOSurface.kext                                         │
│  → Allocates shared GPU-accessible memory buffer        │
│  → Buffer is mapped into both Firefox's virtual space   │
│    AND the GPU's address space                          │
│       ↓                                                 │
│  IOAcceleratorFamily2.kext                              │
│  → Schedules GPU command buffer                         │
│  → Manages GPU timeline / fences / synchronization      │
│       ↓                                                 │
│  AppleIntelKBLGraphics.kext                             │
│  → Translates commands to Intel GEN9 GPU microcode      │
│  → Programs GPU hardware registers directly             │
│  → Manages GPU virtual address space (IOMMU)            │
└────────────────────┬────────────────────────────────────┘
                     │  PCI Express bus
┌────────────────────▼────────────────────────────────────┐
│  HARDWARE                                               │
│                                                         │
│  Intel UHD 630 GPU (integrated, shared LPDDR4 memory)  │
│  → Executes shader programs                             │
│  → Writes pixels to framebuffer                         │
│       ↓                                                 │
│  Display engine → USB-C/Thunderbolt → monitor           │
└─────────────────────────────────────────────────────────┘
```

---

### IOSurface: the key shared memory abstraction

IOSurface deserves special attention because it's the **handoff point** between user space and the GPU.

```
Firefox process            Kernel               GPU
    │                        │                   │
    │── "create IOSurface" ──►│                   │
    │                        │ allocates memory   │
    │◄─ IOSurface handle ────│ maps into GPU IOMMU│
    │                        │                   │
    │   [Firefox writes       │                   │
    │    pixel data into      │                   │
    │    the surface via      │                   │
    │    its virtual mapping] │                   │
    │                        │                   │
    │── "GPU, render this" ──►│                   │
    │                        │──── command ──────►│
    │                        │             [GPU reads
    │                        │              same memory
    │                        │              via IOMMU mapping]
    │                        │                   │
    │◄── "done" ─────────────│◄──── fence ───────│
    │                        │                   │
```

The IOSurface buffer exists at one physical memory location but is **mapped into multiple address spaces simultaneously**: Firefox's virtual address space, and the GPU's own virtual address space (managed via the IOMMU — Input-Output Memory Management Unit). This zero-copy design is why GPU rendering is fast.

---

### Where the fault occurred and why memory pressure matters

```
Normal state (enough memory):
  IOSurface buffer descriptor: {
    kernel_va: 0xfffffface6f0b628  ← valid, present in page table
    gpu_iommu_va: 0x...
    ref_count: 3
  }

Under Docker memory pressure:
  Kernel reclaims memory aggressively.
  IF the Intel kext has a reference-counting bug:
    → Buffer freed prematurely (ref_count hits 0 wrongly)
    → Kernel reclaims the physical page
    → Page table entry removed

  Later, Intel kext still has old pointer:
    → Reads 0xfffffface6f0b628
    → MMU: "no page table entry for this address"
    → Fault type 14
    → PANIC
```

This is a **use-after-free** bug at the kernel level — one of the most common and dangerous bug classes in systems code, and exactly why Rust (which you know!) was invented. The Rust borrow checker makes use-after-free impossible at compile time. The C++ kernel code doesn't have that guarantee.

---

### Metacognition checkpoint

**Q1.** I described IOSurface as allowing Firefox and the GPU to share memory with "zero-copy." You know Node.js — can you think of an equivalent pattern in Node.js or the V8 engine where two components share a buffer to avoid copying? How does that compare to the IOSurface model?

**Q2.** The IOMMU (Input-Output Memory Management Unit) gives the GPU its own virtual address space, separate from the CPU's. Why is this important for security and stability? What attack or bug does it prevent?

**Q3.** I connected this crash to a **use-after-free** bug and mentioned Rust prevents this at compile time. Given what you know about Rust's ownership model, explain precisely *which* Rust rule would have caught this specific bug — the stale pointer to a freed kernel object — at compile time. Be as specific as you can about lifetimes and ownership.

---
*Answer these before continuing. Next section: [[#Concept 6 — How to Read a Kernel Panic Log]]*

---

## Concept 6 — How to Read a Kernel Panic Log

*(Unlock after answering Concept 5 questions)*

### Anatomy of a macOS kernel panic log

Panic logs live at: `/Library/Logs/DiagnosticReports/` and in Console.app under "Crash Reports."

```
Panic log structure:
┌──────────────────────────────────────────┐
│ 1. Header                                │
│    - Darwin version, machine model       │
│    - Panic string (the immediate cause)  │
│    - Triggering process / PID            │
├──────────────────────────────────────────┤
│ 2. CPU register state at time of fault   │
│    - CR2: faulting address               │
│    - RIP: instruction pointer (where)    │
│    - RSP/RBP: stack pointers             │
│    - Error code (fault type 14)          │
├──────────────────────────────────────────┤
│ 3. Kernel backtrace                      │
│    - Call stack at time of panic         │
│    - Shows exact function chain          │
│    - Includes kext names + offsets       │
├──────────────────────────────────────────┤
│ 4. Loaded kexts list                     │
│    - Every kext loaded at time of panic  │
│    - Versions, load addresses            │
├──────────────────────────────────────────┤
│ 5. System memory state                   │
│    - Free pages, wired memory            │
│    - Compressor usage (memory pressure)  │
└──────────────────────────────────────────┘
```

---

### Reading your crash: key fields

**Panic string** (would look something like):
```
panic(cpu 0 caller 0xffffff...): Kernel trap at 0xffffff...,
type 14=page fault, registers:
CR2: 0xfffffface6f0b628, ...
Fault addr: 0xfffffface6f0b628, code: 0x0000000000000002
```

`code: 0x2` = binary `0010`:
- Bit 0 = 0 → page **not present**
- Bit 1 = 1 → **write** access (the driver was trying to write to this address)
- Bit 2 = 0 → fault in **kernel** mode (not user mode)

**RIP (Return Instruction Pointer):** The exact memory address of the CPU instruction that caused the fault. Matched against the kext load address, this tells you exactly which function and line in `AppleIntelKBLGraphics.kext` triggered it.

**Backtrace (example structure):**
```
Backtrace (CPU 0), Frame : Return Address
0xffffff... : AppleIntelKBLGraphics + 0x12a4   ← faulting instruction
0xffffff... : IOAcceleratorFamily2 + 0x8b31    ← called the above
0xffffff... : IOSurface + 0x3c12               ← called the above
0xffffff... : IOKit::IOUserClient::externalMethod ← from user call
0xffffff... : Mach trap handler                ← syscall entry
```

Reading bottom-up: Firefox made a Mach trap (syscall), IOKit routed it to IOSurface, which called IOAcceleratorFamily2, which called into the Intel GPU kext — which faulted.

---

### What Docker's fingerprint looks like in the log

In the memory state section:
```
VM page summary:
  Free pages: 142        ← Very low (normal: several thousand)
  Active pages: 892,341
  Compressor pages: 1,204,882  ← High: OS has compressed a lot to RAM
  Swapouts: 28,441       ← OS has been swapping heavily
```

Heavy swapping + compressor pressure = the exact condition that could trigger premature memory reclamation, leading to the stale pointer your Intel GPU kext dereferenced.

---

### How to prevent recurrence

```
Short term:
  ├─ Disable Firefox GPU acceleration
  │  (Settings → Performance → uncheck "Use hardware acceleration")
  │  Cost: slightly slower rendering
  │  Benefit: Firefox stays in user space, no kernel code path
  │
  └─ Don't run Docker on a macOS beta
     Cost: lose Docker on beta machine
     Benefit: remove memory pressure trigger

Long term:
  ├─ Wait for macOS Tahoe stable release
  │  (Apple will fix the beta kext bugs)
  │
  └─ Monitor: Activity Monitor → Memory Pressure gauge
     If it's red while doing GPU-heavy work on beta, expect instability
```

---

### Final metacognition checkpoint

**Q1.** Given what you now know about the full stack — from virtual memory to kexts to the GPU driver chain — write a one-paragraph explanation of your kernel panic as if you were explaining it to another senior developer who hasn't studied kernel internals. Use correct technical terms but no hand-waving.

**Q2.** The fault code `0x2` tells us the driver was performing a **write** to the invalid address. Does this change your mental model of the bug? A read-after-free is dangerous, but what additional damage could a write-after-free cause compared to a read?

**Q3.** Rust prevents use-after-free. Apple's new **DriverKit** framework moves drivers to user space. Are these solving the same problem, complementary approaches, or orthogonal? Explain the tradeoffs of each approach for the specific case of GPU drivers.

---

## Summary map

```
YOUR KERNEL PANIC — COMPLETE CAUSAL CHAIN

Docker Desktop
  └─ Memory pressure → kernel aggressively reclaims pages

Firefox GPU Helper (pid 1131)
  └─ Requests GPU rendering via IOKit user client

IOSurface.kext
  └─ Provides shared GPU memory buffer (IOSurface)
  └─ Under memory pressure: buffer descriptor potentially freed early

IOAcceleratorFamily2.kext
  └─ Schedules GPU commands, manages timelines

AppleIntelKBLGraphics.kext  [BETA, Intel Kaby Lake]
  └─ Holds stale pointer to freed buffer descriptor
  └─ Attempts write to: 0xfffffface6f0b628
  └─ MMU: no page table entry → fault type 14

Kernel fault handler
  └─ Detects: fault in kernel mode, unrecoverable
  └─ KERNEL PANIC: freeze CPUs, dump log, reboot
```

---

*This document is a living learning session. Add your answers below each checkpoint section as you work through them.*
