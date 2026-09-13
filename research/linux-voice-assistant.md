# Research interest — a voice assistant for Linux

**Started:** 2026-09-12
**Status:** research and planning. No code written.
**Full repository:** `androbat11/vox-research` (private)

## The idea

Build what Cortana is on Windows, but for Linux, and local-first: press a key
(or say a wake word), speak, and get a spoken answer back. Speech recognition
and speech synthesis run on the machine; only text ever leaves it, and only if
the user opts in. Written in Rust, as a single binary rather than a pile of
Python services.

## Why it's interesting now

Three things became true recently that weren't before:

1. Local speech-to-text is good enough on a CPU (Whisper-class models).
2. Local text-to-speech stopped sounding robotic (Piper and similar).
3. LLMs removed the hard part — rigid intent grammars, which is what made
   earlier assistants brittle, are simply not needed anymore.

So the components exist. What's missing is something that assembles them into
one fast, well-behaved desktop program.

## There's already a working prototype

The `audio` skill in this repo (`skills/audio/SKILL.md`) is a shell-and-Python
version of exactly this pipeline, in daily use: hold-SPACE capture,
faster-whisper transcription, Piper speech output via an editor hook.

It works — and it's the main argument for building the real thing. It also
produced a set of genuinely non-obvious failure modes (a daemon that killed
speech mid-sentence after exactly 5 seconds; a 28-second-versus-4-second gap
between buffered and streamed synthesis) that are written up in the research
repo and are worth reading on their own.

## The honest state of it

Two findings that shape everything:

- **The hardware is the constraint.** 7.5GB RAM and Intel integrated graphics.
  A 7B local model is out of reach in practice, and the iGPU can't help —
  token generation is limited by memory bandwidth, which the iGPU shares with
  the CPU. That's researched and settled, not assumed.
- **It might not be worth building.** An interrupted survey turned up a strong
  lead that the Open Home Foundation may already ship an official Linux voice
  assistant. Phase 0 of the plan is explicitly *decide whether to build this at
  all* — contributing to something good would be a better outcome than
  duplicating it.

## What's in the research repo

| Document | What it covers |
|---|---|
| `README.md` | Vision, design principles, explicit non-goals |
| `docs/hardware-constraints.md` | Measured target machine and what it rules out |
| `docs/lessons-from-the-prototype.md` | Failure modes from the working version |
| `docs/llm-layer.md` | Intel iGPU verdict (settled); local vs remote design |
| `docs/architecture.md` | Streaming pipeline behind swappable interfaces |
| `docs/roadmap.md` | Six phases, each independently useful |
| `docs/research-prompt.md` | Prompts for AI deep-research platforms |
| `docs/local-model-setup.md` | Running a small local model in 7.5GB |
| `docs/open-questions.md` | What's undecided, and what would settle it |
| `docs/research-links.md` | Annotated links, marked verified vs unconfirmed |

## Next

1. Investigate OHF-Voice — does an official Linux assistant already exist?
2. Read the source of `Handy`, a Rust push-to-talk dictation tool.
3. Re-run the deep research that got cut short by a rate limit.
