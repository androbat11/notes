---
name: audio
description: Voice input/output pipeline for a terminal LLM session — Claude Code, opencode, and Gemini CLI are all directly supported (same SKILL.md format for all three), and any other CLI-based coding agent can follow it too. Works on Linux, macOS, or Windows. Installs a local speech-to-text engine (faster-whisper) and a local neural text-to-speech engine (Piper on Linux) if missing, wires up hold-SPACE-to-talk voice input, and reads responses aloud in full. Linux and macOS are first-class; Windows is supported.
disable-model-invocation: false
argument-hint: "install | on | off | response-on | response-off | status"
---

# Voice I/O pipeline for terminal LLM agents (v1.1)

> Status: working end-to-end on Linux/Wayland (Fedora), verified in live use.
> Output engine is Piper (neural), voice `en_US-lessac-high`, length-scale
> 1.15 — all three chosen by listening tests, not defaults. The
> troubleshooting section near the end is worth reading before changing the
> speech path; several non-obvious failure modes are documented there with
> the evidence that identified them.

## Goal

Let the user speak instead of type, and optionally hear the agent's answers
spoken back, in Claude Code or any other terminal-based LLM tool, on Linux,
macOS, or Windows. Assume nothing described below is installed until you've
actually checked for it — this skill installs everything it needs the first
time it runs, and simply verifies (does nothing) on later runs.

This is a general-purpose skill, not tied to one LLM product. If you are
Claude Code specifically, some steps below tell you to prefer a native
mechanism that already exists instead of duplicating it — follow those
branches. If you are a different agent/CLI, use this skill's own
input/output pipeline in full.

Read this whole file before doing anything, then execute the steps in
order. If a step's check already passes, skip its install and move on —
don't reinstall or reconfigure things that already work.

### Running privileged (sudo/admin) commands

This skill's whole point is to install everything for the user
automatically — don't make them copy-paste commands into their own
terminal unless you genuinely can't proceed otherwise. **Run `sudo`
commands directly.** On a normal interactive terminal, sudo prompts for
the password right there and the user types it directly into their own
terminal — it never passes through you. Only fall back to printing the
command and asking the user to run it themselves if `sudo` actually fails
with an error indicating no interactive terminal is available (e.g. `sudo:
a terminal is required to read the password` / `a password is required`
with no prompt shown) — that specifically means the environment you're
running in has no real TTY for sudo to use, which is a property of the
harness, not something to work around by asking for the password yourself.
Never ask the user to type their password to you or into a command you
construct.

### Installing this skill itself, across tools

This file works unmodified as a Claude Code skill, an opencode skill, and a
Gemini CLI skill — all three now share the same `SKILL.md` convention, and
this was verified directly (not just documented) by actually installing it
on a machine with all three CLIs present:

1. Put this file at `~/.claude/skills/audio/SKILL.md` (create the
   directories if needed). This is the canonical single copy — don't
   duplicate it elsewhere.
2. **Claude Code** discovers it there natively — nothing else to do.
3. **opencode** auto-loads external skills from that exact path too
   (confirmed via `opencode debug skill`, which listed it with
   `"location": "/home/sm/.claude/skills/audio/SKILL.md"` after removing a
   separate opencode-local copy — the single path was sufficient on its
   own). No copying into `~/.config/opencode/skill/` needed.
4. **Gemini CLI** has no auto-load path into `~/.claude/skills`, but ships
   a first-class skill system as of the version tested (`gemini skills
   <command>`, with `list`/`link`/`install`/`enable`/`disable`). Link the
   same folder in directly:
   ```bash
   gemini skills link ~/.claude/skills/audio
   ```
   This prompts a one-time `Do you want to continue? [Y/n]` trust
   confirmation (answer it interactively — don't silently auto-confirm on
   the user's behalf if you're doing this on someone else's machine; do
   confirm it yourself if you're setting this up for the person who is
   right here asking for it). It creates a symlink at
   `~/.gemini/skills/audio/SKILL.md`; confirm with `gemini skills list
   --all`.
5. If a project-scoped install is wanted instead of global, the equivalent
   per-tool project paths are `.claude/skills/audio/SKILL.md`,
   `.opencode/skill(s)/audio/SKILL.md` (opencode also reads this directly,
   no need to rely on the external auto-load path there), and
   `gemini skills link <path> --scope project` (not tested here — this
   machine only has a global gemini install; verify the flag name before
   relying on it).

opencode does **not** auto-invoke skills by matching the description
against every message (confirmed from its own docs) — the agent has to
explicitly decide to use the `audio` skill by name, e.g. because the user
asked for voice input/output. Gemini CLI's built-in skills are worded like
Claude Code's auto-invoked ones ("Use when the user asks…"), which
suggests it may do description-matching too, but this wasn't directly
confirmed here — verify by asking a voice-related question without naming
the skill and see if it gets pulled in on its own; if not, tell the user
to invoke it explicitly.

---

## Step 0 — detect the environment

Run and record the results before proceeding:

- OS: `uname -s` → `Linux` / `Darwin`. On Windows, you are most likely
  running inside PowerShell — check `$env:OS` (will read
  `Windows_NT`) instead.
- Linux only, display server: `echo $XDG_SESSION_TYPE` → `wayland` or
  `x11`. This changes which hold-to-talk mechanism and clipboard tool to
  use later (Steps 4 and 6).
- Are you Claude Code? If so, check `~/.claude/settings.json` for
  `"voiceEnabled": true` / `"voice": {"enabled": true}`. If that's present,
  Claude Code already has native hold-SPACE voice **input** — tell the user
  to just use that directly instead of this skill's own capture path for
  input (Step 4). Still install and use this skill's voice **output**
  path (Step 6), since Claude Code has no native equivalent for that.
  If you are not Claude Code, or Claude Code's native voice input is off,
  install and use this skill's full input pipeline too.

---

## Step 1 — install/verify the text-to-speech (TTS) engine

Check first, per OS, before installing anything.

### Linux — primary engine: Piper (neural)

**Install Piper first; it is the engine this skill actually uses on Linux.**
Piper is a local neural TTS: markedly clearer and more natural than RHVoice
(which is itself only a concatenative synth built from CMU ARCTIC
recordings), and — just as important — it needs **no speech-dispatcher
daemon at all**. It synthesizes straight to audio, which permanently retires
the entire class of "daemon idle-timeout kills the speech mid-sentence"
failures documented in the troubleshooting section below. This was a direct
A/B decision by the user, who compared both engines out loud and chose
Piper.

Check: `python3 -c "import piper" 2>/dev/null && ls ~/.local/share/piper-voices/*.onnx`

If missing:
```bash
python3 -m pip install --user piper-tts
mkdir -p ~/.local/share/piper-voices
```
Then fetch a voice model. `en_US-lessac-high` is the tested default (~114MB
for the model plus a small JSON config beside it — **both files are
required**, and the `.json` must sit next to the `.onnx` with the matching
name):
```bash
cd ~/.local/share/piper-voices
BASE="https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/high"
curl -sSL --retry 6 --retry-delay 5 --retry-all-errors \
  -O "$BASE/en_US-lessac-high.onnx" \
  -O "$BASE/en_US-lessac-high.onnx.json"
```
`python3 -m piper.download_voices en_US-lessac-high` is the official route
but was rate-limited (HTTP 429) during testing; the `curl --retry` form
above succeeded where it failed, so prefer it. Verify both files landed and
that the `.onnx` is ~100MB+ — a 0-byte `.onnx` next to a valid `.json` is
the signature of a partial 429'd download, and it fails silently at speak
time.

Other voices (same URL pattern, substituting the name/quality path):
`en_US-amy-medium`, `en_US-ryan-high` (male), `en_GB-alba-medium` (British).
`medium` models synthesize roughly 2-3x faster than `high` at some quality
cost — worth offering if the user finds the startup delay noticeable.

Verify:
```bash
printf 'Piper voice test.' | python3 -m piper \
  -m ~/.local/share/piper-voices/en_US-lessac-high.onnx --output-raw \
  | aplay -q -r 22050 -f S16_LE -c 1 -t raw -
```

### Linux — fallback engine: RHVoice

Only needed as a fallback for machines where Piper isn't available (the
wrapper below falls back to it automatically). Skip this entirely if Piper
installed cleanly.

Check: `command -v spd-say >/dev/null && spd-say -O 2>/dev/null | grep -q rhvoice`

If that fails, install RHVoice (much clearer than the default espeak-ng
formant synthesis) via COPR:

```bash
sudo dnf copr enable cuintle/RHVoice -y
sudo dnf install -y rhvoice rhvoice-speech-dispatcher-plugin
```
(Debian/Ubuntu: RHVoice publishes .deb packages and an apt repo at
rhvoice.org/linux — use that instead of COPR. Confirm the exact repo line
with the user before adding a third-party apt source.)

Then configure speech-dispatcher per-user (no root needed for this part).
Create `~/.config/speech-dispatcher/` from the system config if it doesn't
exist yet:
```bash
mkdir -p ~/.config/speech-dispatcher/modules
[ -f ~/.config/speech-dispatcher/speechd.conf ] || \
  cp /etc/speech-dispatcher/speechd.conf ~/.config/speech-dispatcher/speechd.conf
echo "# rhvoice module config (no options needed)" \
  > ~/.config/speech-dispatcher/modules/rhvoice.conf
cp ~/.config/speech-dispatcher/modules/rhvoice.conf ~/.config/speech-dispatcher/rhvoice.conf
```
In `~/.config/speech-dispatcher/speechd.conf`, ensure these two lines are
present and uncommented (add if missing, don't duplicate if already there):
```
AddModule "rhvoice"  "sd_rhvoice"   "rhvoice.conf"
DefaultModule rhvoice
```
Restart the daemon so it picks up the change: `pkill -f -u "$USER" speech-dispatcher`
(it auto-respawns on the next `spd-say` call).

Verify: `spd-say -r 0 -p 0 "voice output is working"` should be audible and
clear, not robotic.

### macOS

Check: `command -v say`. This ships with macOS — nothing to install.

### Windows

Nothing to install — SAPI (`System.Speech`) ships with Windows.

### The wrapper (all OSes) — pick the clearest, most human-sounding voice available

The goal (per the user's own instruction) is that the default voice should
be the most human and clear one available, not just whatever the engine
defaults to — the entire point of this skill was replacing a robotic
espeak-ng voice with something actually understandable.

**Linux (Piper — the actual default):** use `en_US-lessac-high`. Chosen by
the user in a direct A/B listening test against RHVoice, so don't quietly
downgrade it. Two implementation details in the wrapper below are not
optional:

- **Stream with `--output-raw`, never render to a file first.** Piper
  synthesizes a long answer roughly 3.8x faster than realtime, but it still
  has to finish the *whole* text before a file is playable: measured on a
  ~1800-character answer, full-file mode took **28 seconds of dead silence**
  before a single sound, while streaming started in **~4 seconds** and then
  played continuously with no stalls.
- **Read the sample rate from the model's own `.json`**, don't hardcode
  22050. Swapping in a different Piper voice with another rate would
  otherwise play everything at the wrong pitch and speed.

**Linux (RHVoice — fallback only):** use **`slt`**, not `clb`. RHVoice's
English voices (`bdl`, `clb`, `slt`) are all built from the same CMU ARCTIC
recordings; `slt` is the one most commonly used as the reference/demo voice
across TTS research. `bdl` (male) is the alternative. Whenever calling
`spd-say`, `-w` is mandatory — see the troubleshooting section.

**macOS (`say`):** the plain system default can be a low-quality "compact"
voice unless a higher-quality one is installed. Prefer, in order:
`Ava (Premium)` / `Ava` → `Samantha (Enhanced)` / `Samantha` → `Alex`,
falling back to whatever `say` picks with no `-v` at all if none of those
exist. Check availability first with `say -v '?'` rather than hardcoding
one name that might not be installed on this particular Mac.

**Windows (SAPI):** `System.Speech.Synthesis.SpeechSynthesizer` can also
see newer, clearer "OneCore" neural voices (registered under
`HKLM\SOFTWARE\Microsoft\Speech_OneCore\Voices\Tokens`) on modern Windows
10/11, not just the older, more robotic "Desktop" voices (David/Zira/Mark)
— enumerate what's actually installed and prefer a OneCore/neural one
instead of hardcoding a Desktop voice name.

```bash
#!/usr/bin/env bash
# ~/.local/bin/voice-speak "text to say"
text="$1"

# Piper (neural TTS) is the primary engine on Linux — clearer and far more
# natural than RHVoice, and it needs no speech-dispatcher daemon at all,
# which retires the whole class of "daemon idle-timeout kills speech
# mid-sentence" bugs that plagued the spd-say path.
PIPER_MODEL="${PIPER_MODEL:-$HOME/.local/share/piper-voices/en_US-lessac-high.onnx}"

# Speaking speed. Piper's --length-scale stretches the audio: values above
# 1.0 are SLOWER, below 1.0 faster, 1.0 is the model default. 1.15 was
# chosen by the user from a four-way listening test (0.85 / 1.0 / 1.15 /
# 1.3) as the most intelligible.
PIPER_LENGTH_SCALE="${PIPER_LENGTH_SCALE:-1.15}"

case "$(uname -s)" in
  Linux)
    if [ -f "$PIPER_MODEL" ] && python3 -c "import piper" 2>/dev/null; then
      # Read the sample rate from the model's own config so swapping in a
      # different Piper voice doesn't silently play at the wrong pitch.
      rate="$(python3 -c "
import json,sys
try:
    print(json.load(open('$PIPER_MODEL.json'))['audio']['sample_rate'])
except Exception:
    print(22050)
" 2>/dev/null)"
      [ -n "$rate" ] || rate=22050

      # --output-raw streams audio out sentence by sentence instead of
      # rendering the entire answer first. On a ~1800-character answer that
      # is ~4s to first audio instead of ~28s of dead silence. Synthesis
      # runs ~3.8x faster than playback, so it never stalls mid-answer.
      printf '%s' "$text" \
        | python3 -m piper -m "$PIPER_MODEL" \
            --length-scale "$PIPER_LENGTH_SCALE" --output-raw 2>/dev/null \
        | aplay -q -r "$rate" -f S16_LE -c 1 -t raw -
    else
      # Fallback for a machine where Piper isn't installed yet. -w is
      # mandatory here: without it spd-say disconnects immediately, the
      # speech-dispatcher idle timer (default 5s) fires, and the daemon
      # kills itself mid-utterance so only the first sentence is heard.
      spd-say -w -o rhvoice -y slt -r 0 -p 0 "$text"
    fi
    ;;
  Darwin)
    voice=""
    for candidate in "Ava (Premium)" "Ava" "Samantha (Enhanced)" "Samantha" "Alex"; do
      if say -v '?' | grep -q "^$candidate "; then voice="$candidate"; break; fi
    done
    if [ -n "$voice" ]; then say -v "$voice" "$text"; else say "$text"; fi
    ;;
esac
```
`chmod +x ~/.local/bin/voice-speak`

Windows equivalent, `voice-speak.ps1` — prefers a OneCore/neural voice if
one is installed, otherwise falls back to whatever's available:
```powershell
param([string]$Text)
Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer

$preferred = @("Aria", "Jenny", "Guy", "Ana", "Emma", "Zira")
$installed = $synth.GetInstalledVoices() | ForEach-Object { $_.VoiceInfo.Name }
$chosen = $null
foreach ($name in $preferred) {
    $match = $installed | Where-Object { $_ -like "*$name*" } | Select-Object -First 1
    if ($match) { $chosen = $match; break }
}
if ($chosen) { $synth.SelectVoice($chosen) }

$synth.Rate = 0
$synth.Volume = 100
$synth.Speak($Text)
```
This was not tested on an actual Windows machine (none available here) —
verify `$synth.GetInstalledVoices()` actually lists OneCore voices in
practice on whatever Windows box this runs on, and adjust the `$preferred`
list to match what's really installed there.

---

## Step 2 — install/verify the speech-to-text (STT) engine (all OSes)

One engine everywhere: **faster-whisper** (pip-installable, prebuilt wheels
for Linux/macOS/Windows — no PyTorch, no per-OS native package needed).

Check: `python3 -c "import faster_whisper" 2>/dev/null`

If missing, check `python3 -m pip --version` first — a plain system Python
often has no `pip` at all (`No module named pip`). If so, bootstrap it
without needing root: `python3 -m ensurepip --user`. Then:
```bash
python3 -m pip install --user -U faster-whisper
```
(Windows, from PowerShell: `py -m pip install --user -U faster-whisper`)

Model: use **`small.en`**, not the smaller `base.en`/`tiny.en` defaults —
this pipeline is mainly for dictating instructions/commands to a coding
agent, where misheard technical words (package names, flags, identifiers)
are costly, and the extra accuracy is worth the few extra seconds of CPU
transcription time. It downloads automatically on first use (~500MB, one
time).

Write `~/.local/bin/voice-transcribe.py`:
```python
#!/usr/bin/env python3
import sys
from faster_whisper import WhisperModel

model = WhisperModel("small.en", device="cpu", compute_type="int8")
segments, _ = model.transcribe(sys.argv[1], vad_filter=True)
print(" ".join(s.text.strip() for s in segments))
```
`vad_filter=True` matters — without it, Whisper hallucinates plausible-
sounding phrases (e.g. "Thanks for watching!") on silence/background noise
instead of returning nothing, confirmed by actually recording a few
seconds of silence and transcribing it during testing. With the filter,
silence correctly produces an empty string.

---

## Step 3 — install/verify the microphone recorder (all OSes)

Check: `command -v ffmpeg`. If missing:
- Linux: `sudo dnf install -y ffmpeg` (or `apt`/`pacman` equivalent)
- macOS: `brew install ffmpeg`
- Windows: `winget install ffmpeg`

Recording command differs only in the input flag:
- Linux: `ffmpeg -f alsa -i default -y <file>`
- macOS: `ffmpeg -f avfoundation -i ":0" -y <file>`
- Windows: `ffmpeg -f dshow -i audio="<device name>" -y <file>`

**Windows-only one-time step:** there is no generic `"default"` input
device name on Windows like Linux/macOS have — it's whatever the user's
sound card is literally named, and differs per machine. Before first use,
run:
```powershell
ffmpeg -list_devices true -f dshow -i dummy
```
This prints the available audio devices to stderr. Ask the user which one
is their microphone, and save it to `~/.config/audio-skill/windows-mic.txt`
(or `%LOCALAPPDATA%\audio-skill\windows-mic.txt`) so future runs don't ask
again.

---

## Step 4 — the capture script: hold SPACE to talk (all OSes)

Same key everywhere, matching Claude Code's own native binding: **press
and hold SPACE to record, release it to stop and transcribe.**

How "hold" (true press vs. release, not just a toggle) is detected differs
by platform — pick the right one per Step 0's detection:

### Windows, macOS, Linux+X11 → use `pynput`

On Linux, `pynput` pulls in `evdev` as a dependency, which is a C
extension and will fail to build (`fatal error: Python.h: No such file or
directory`) unless headers and a compiler are present — confirmed by this
failing on a fresh machine during testing. Check first:
`python3 -c "import pynput" 2>/dev/null`. If missing, install the build
prerequisites (run directly, per the sudo note above), then pynput:
```bash
sudo dnf install -y python3-devel gcc      # Fedora/RHEL
# sudo apt install -y python3-dev gcc      # Debian/Ubuntu
python3 -m pip install --user pynput
```
macOS/Windows don't need this — wheels are prebuilt there.

`~/.local/bin/voice-capture.py`:
```python
#!/usr/bin/env python3
import subprocess, sys, tempfile, platform, os
from pynput import keyboard

MIC_NAME_FILE = os.path.expanduser("~/.config/audio-skill/windows-mic.txt")
tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False).name
recording = None

def record_cmd():
    system = platform.system()
    if system == "Linux":
        return ["ffmpeg", "-f", "alsa", "-i", "default", "-y", tmp]
    if system == "Darwin":
        return ["ffmpeg", "-f", "avfoundation", "-i", ":0", "-y", tmp]
    if system == "Windows":
        with open(MIC_NAME_FILE) as f:
            mic = f.read().strip()
        return ["ffmpeg", "-f", "dshow", "-i", f"audio={mic}", "-y", tmp]
    raise RuntimeError(f"unsupported OS: {system}")

def start():
    global recording
    recording = subprocess.Popen(record_cmd(), stdout=subprocess.DEVNULL,
                                  stderr=subprocess.DEVNULL)

def stop_and_transcribe():
    recording.terminate()
    recording.wait()
    text = subprocess.check_output(
        [sys.executable, os.path.expanduser("~/.local/bin/voice-transcribe.py"), tmp]
    ).decode().strip()
    copy_to_clipboard(text)
    print(text)

def copy_to_clipboard(text):
    system = platform.system()
    try:
        if system == "Darwin":
            subprocess.run(["pbcopy"], input=text.encode())
        elif system == "Windows":
            subprocess.run(["powershell", "-Command", "Set-Clipboard"],
                            input=text.encode())
        elif os.environ.get("XDG_SESSION_TYPE") == "wayland":
            subprocess.run(["wl-copy"], input=text.encode())
        else:
            subprocess.run(["xclip", "-selection", "clipboard"], input=text.encode())
    except FileNotFoundError:
        pass  # clipboard tool missing — printed stdout still works

def on_press(key):
    if key == keyboard.Key.space and recording is None:
        start()

def on_release(key):
    if key == keyboard.Key.space:
        stop_and_transcribe()
        return False  # stop listener after one capture

with keyboard.Listener(on_press=on_press, on_release=on_release) as l:
    l.join()
```

### Linux + Wayland → raw `evdev` fallback (pynput cannot listen globally under Wayland)

Wayland's security model blocks apps from listening to keystrokes
system-wide (unlike X11), so the only way to detect true press/release is
reading the raw keyboard device directly. This needs a one-time permission
grant:

```bash
sudo usermod -aG input "$USER"
```
The current session won't see this membership yet (`groups` still won't
list `input`, confirmed by testing) — but a full logout/login is **not**
actually required. Run the capture script through `sg input -c "..."`,
which applies the group for that one command immediately:
```bash
sg input -c "python3 $HOME/.local/bin/voice-capture-evdev.py"
```
Confirmed working: `sg input -c "python3 -c 'from evdev import list_devices; print(list_devices())'"`
returns real devices right after `usermod`, with no logout needed. A full
logout/login is only needed if you want plain (non-`sg`-wrapped) commands
to see the group membership too.

`~/.local/bin/voice-capture-evdev.py` (same start/stop logic as above, only
the listener differs):
```python
from evdev import InputDevice, ecodes, list_devices
# ... reuse start(), stop_and_transcribe(), copy_to_clipboard() from above ...

def find_keyboard():
    # Don't just match KEY_SPACE — confirmed during testing that mice with
    # programmable buttons (e.g. Logitech M720) advertise a near-complete
    # keyboard keymap, including KEY_SPACE, KEY_A, KEY_ENTER. The reliable
    # distinguisher is that an actual keyboard has no pointer axes: exclude
    # any matching device that also has EV_REL (mouse movement) or EV_ABS
    # (touchpad/absolute pointer) capability.
    for path in list_devices():
        dev = InputDevice(path)
        caps = dev.capabilities()
        keys = caps.get(ecodes.EV_KEY, [])
        if ecodes.KEY_SPACE not in keys:
            continue
        if ecodes.EV_REL in caps or ecodes.EV_ABS in caps:
            continue
        return dev
    raise RuntimeError(
        "No dedicated keyboard device found. If list_devices() returned "
        "nothing at all, you're likely not in the `input` group yet."
    )

kbd = find_keyboard()

for event in kbd.read_loop():
    if event.type == ecodes.EV_KEY and event.code == ecodes.KEY_SPACE:
        if event.value == 1:
            start()
        elif event.value == 0:
            stop_and_transcribe()
            break
```
Install (needs the same `python3-devel`/`gcc` prerequisite as above if not
already installed): `python3 -m pip install --user evdev`

**Known limitation, tell the user plainly:** this evdev-based fallback
listens to the spacebar *system-wide*, not just while this terminal is
focused (same as any push-to-talk app, e.g. Discord) — it cannot be scoped
to "only when this window is focused" on Wayland without cooperation from
the compositor, which generic scripts don't get. The `pynput` path
(Windows/macOS/X11) has the same characteristic — this is a fundamental
property of global hold-to-talk, not a bug specific to one platform.

---

## Step 5 — toggle commands and state

State lives in a plain directory, not tied to any one LLM tool:
- Linux/macOS: `~/.cache/llm-voice/`
- Windows: `$env:LOCALAPPDATA\llm-voice\`

Flags (presence = on, absence = off):
- `input.flag` — voice input capture is active
- `output.flag` — responses should be spoken aloud

Commands this skill exposes (as Claude Code slash-args, or just describe
the equivalent shell actions if you are a different agent):

- **`/audio install`** — run Steps 1-4 (idempotent; safe to re-run).
- **`/audio on`** → `touch input.flag`. If you are Claude Code, tell the
  user to use Claude Code's own native hold-SPACE input instead (Step 0)
  when that's available; otherwise, before waiting on the next user turn,
  run `voice-capture.py` (Windows/macOS/Linux+X11), or on Linux+Wayland run
  `sg input -c "python3 $HOME/.local/bin/voice-capture-evdev.py"` (no
  logout needed — see Step 4), and treat its stdout as the user's message
  for that turn.
- **`/audio off`** → remove `input.flag`.
- **`/voice-response-on`** → `touch output.flag`. If you are Claude Code,
  also wire the automatic `Stop` hook now (see Step 6) — don't just set an
  inert flag the user has to separately remember to enable elsewhere.
- **`/voice-response-off`** → remove `output.flag`. If the `Stop` hook was
  installed, leave the hook registration in place (it checks the flag
  itself and no-ops when it's absent) — no need to edit settings.json again.
- **`/audio status`** → report both flags, and whether the `Stop` hook is
  registered.

For any non-Claude-Code agent/CLI: there's no hook mechanism to lean on, so
`/voice-response-on` just means "speak every final answer" — do it directly
at the end of each turn per Step 6 instead of relying on an external hook.

For input on a non-Claude-Code tool: run the capture script manually
(hold SPACE, release), then paste the clipboard content into that tool's
prompt — there is no reliable, permission-free way to auto-type into an
arbitrary focused window (especially on Wayland), so clipboard-and-paste is
the honest mechanism here, not a corner cut.

---

## Step 6 — speaking the output

When `output.flag` exists: before finishing your turn, take your answer,
strip things that read badly aloud (fenced code blocks → replace with a
short spoken description like "a short Python function that does X" rather
than reading code character by character; markdown syntax; long file paths
and URLs → describe them in words), condense to roughly 1-4 plain sentences
unless the user explicitly asked for the literal text, then:

```bash
voice-speak "<condensed text>"
```
(or `voice-speak.ps1 -Text "..."` on Windows)

Still print the normal written response too — voice is additive, not a
replacement for text output.

This condense-to-1-4-sentences step applies only to this manual path (an
agent with no hook mechanism calling `voice-speak` itself). The automatic
`Stop`-hook path below does NOT condense or truncate — it speaks the full
answer, however long, since a user may deliberately ask a question that
needs a long spoken answer and losing part of it silently is worse than a
long reply. (An earlier version of the hook's cleanup script truncated at
400 characters, which cut off long answers — that cap has been removed;
don't reintroduce a length cap there.)

### Wiring the `Stop` hook (Claude Code only, for automatic persistent speaking)

A skill cannot re-invoke itself after the turn ends — only a hook can run
automatically once Claude finishes responding. When `/voice-response-on`
runs inside Claude Code, merge this into `~/.claude/settings.json` (merge
the `hooks` key in — do not overwrite the rest of the file; read the
existing file first, since it may already contain `model`, `theme`, or
other keys):

```json
{
  "hooks": {
    "Stop": [
      { "hooks": [ { "type": "command", "command": "~/.local/bin/voice-speak-hook.sh" } ] }
    ]
  }
}
```

`~/.local/bin/voice-speak-hook.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
FLAG="$HOME/.cache/llm-voice/output.flag"
[ -f "$FLAG" ] || exit 0

payload="$(cat)"
transcript_path="$(printf '%s' "$payload" | jq -r '.transcript_path // empty')"
[ -n "$transcript_path" ] && [ -f "$transcript_path" ] || exit 0

# A single logical reply is split across multiple separate "assistant"
# JSONL entries (thinking / tool_use / text interleaved) — grabbing only
# the last "text" block in the whole transcript (e.g. via `tail -n 1`)
# truncates any answer that has more than one text segment. Instead, scope
# to only the current turn (everything after the last real, human-typed
# user message — tool-result entries are also type "user" but have array
# content, so a real prompt is identified by string content) and join all
# of that turn's text blocks. Parse each line independently and drop any
# that fail (`fromjson? // empty`) instead of letting one malformed/partial
# line (e.g. the harness still mid-write on the last line when the hook
# fires) abort the whole pipeline under `set -e` and produce total silence.
extract_text() {
  jq -R -c 'fromjson? // empty' "$transcript_path" 2>/dev/null | jq -s -r '
    (to_entries | map(select(.value.type=="user" and (.value.message.content|type)=="string")) | last | .key) as $idx
    | if $idx == null then empty else
        .[($idx+1):]
        | map(select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text)
        | join(" ")
      end
  '
}

# The Stop hook can fire while the harness is still incrementally appending
# this turn's content — a multi-paragraph/bullet answer is written as
# several separate sequential JSONL lines, not one atomic write. Checking
# only "is there any text yet" and stopping on the first non-empty read is
# WRONG (confirmed live): it can catch the file after just the intro
# paragraph has landed and declare success, speaking only that fragment —
# a real reply was cut short this way even though the fully-written
# transcript, read moments later, contained the complete answer the whole
# time. Instead wait for the extraction to come back identical on two
# consecutive reads (i.e. the transcript has stopped growing) before
# treating it as the final answer.
prev=""
text=""
for _ in 1 2 3 4 5 6 7 8 9 10; do
  cur="$(extract_text)"
  if [ -n "$cur" ] && [ "$cur" = "$prev" ]; then
    text="$cur"
    break
  fi
  prev="$cur"
  sleep 0.15
done
# Exhausted retries without two identical reads in a row: fall back to the
# last (most complete) read seen rather than staying silent.
[ -n "$text" ] || text="$prev"
[ -n "$text" ] || exit 0

clean="$(printf '%s' "$text" | python3 -c '
import re, sys
t = sys.stdin.read()
t = re.sub(r"```.*?```", " code omitted ", t, flags=re.DOTALL)
t = re.sub(r"`([^`]*)`", r"\1", t)
t = re.sub(r"!\[[^\]]*\]\([^)]*\)", "", t)
t = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", t)
t = re.sub(r"^#{1,6}\s*", "", t, flags=re.MULTILINE)
t = re.sub(r"^[-*+]\s+", "", t, flags=re.MULTILINE)  # list markers
t = re.sub(r"^>\s?", "", t, flags=re.MULTILINE)      # blockquote markers
t = re.sub(r"\*\*([^*]+)\*\*", r"\1", t)             # bold
t = re.sub(r"\*([^*]+)\*", r"\1", t)                 # italic
t = re.sub(r"_([^_]+)_", r"\1", t)                   # italic (underscore)
t = re.sub(r"\s+", " ", t).strip()
print(t)
')"
[ -n "$clean" ] || exit 0

# `spd-say` hands the text to the speech-dispatcher daemon and returns
# almost immediately — actual audio playback continues in the background,
# independent of this script. If the harness cleans up this hook's whole
# process group shortly after the script exits (common hook sandboxing),
# that can kill the just-autospawned daemon mid-playback, cutting the
# answer off partway even though everything upstream produced the full
# text (confirmed separately: RHVoice rendered a previously-cut-off answer
# to a WAV file directly, offline, and it came out completely intact and
# full-length — so the truncation was not in the text or the synthesizer).
# Detach into a new session (setsid) with stdio fully closed so playback
# survives after this script — and the harness's cleanup of it — is gone.
setsid ~/.local/bin/voice-speak "$clean" >/dev/null 2>&1 < /dev/null &
disown
```
`chmod +x` both scripts.

---

## Full flow (once everything above is wired up)

mic (hold SPACE) → local Whisper transcription (`small.en`) → text handed
to the agent as input (directly, if this skill drove the capture; via
clipboard-paste, if a non-Claude-Code tool) → agent answers → if
`output.flag` is set: the answer is spoken **in full, never condensed or
truncated**, via Piper on Linux (`say` on macOS, SAPI on Windows), driven
automatically by the `Stop` hook in Claude Code; otherwise printed as
normal text, same as without this skill at all.

---

## Known limitations (be upfront with the user about these, don't hide them)

1. Hold-to-talk is a **global** hotkey wherever it isn't natively scoped by
   the host app (i.e., everywhere except Claude Code's own native
   mechanism) — pressing SPACE anywhere on the system will start/stop
   recording while this is armed, not just inside the target terminal.
2. Linux+Wayland needs the `input` group (one-time `sudo usermod -aG input
   "$USER"`); running the capture script via `sg input -c "..."` avoids
   needing a full logout/login (confirmed working during testing).
3. Windows needs a one-time microphone device name lookup; it cannot be
   guessed.
4. None of this works over SSH without a forwarded audio device — it needs
   local mic and speaker hardware.

## Verifying a fresh install end-to-end

1. `voice-speak "test"` — confirm audible, clear speech. This exercises the
   real path (Piper on Linux); testing the engine directly with `spd-say` /
   `say` only proves the fallback works.
2. Record a few seconds with `voice-capture.py` (or the evdev variant),
   confirm the printed/transcribed text roughly matches what was said.
3. `/voice-response-on`, ask a question, confirm the answer is both
   printed and spoken. Make it a question whose answer takes **longer than
   ~10 seconds to read aloud** — short test phrases pass even when the
   pipeline is badly broken (see below).
4. `/audio status` — confirm flags reflect reality.

## Troubleshooting: "it only speaks the first sentence"

**This applies to the RHVoice/`spd-say` fallback path only** — Piper, the
default, has no daemon and cannot fail this way. If the symptom appears
while Piper is the active engine, the cause is something else; jump to the
layered debug order below.

The highest-value debugging lesson from this skill's own history. If speech
starts correctly but cuts off after roughly one sentence, do NOT start by
suspecting the text pipeline — check the **daemon's own log** first:

```bash
grep -E "started and waiting|Terminating\.\.\.|is_speaking error" \
  /run/user/$(id -u)/speech-dispatcher/log/speech-dispatcher.log | tail -20
```

If each daemon lifecycle is *exactly* 5 seconds long and ends on
`output_module_is_speaking error`, the cause is speech-dispatcher's idle
`Timeout` (default 5s) killing the daemon mid-utterance because `spd-say`
disconnected immediately after handing off the text. The fix is `spd-say -w`
(see the wrapper above); `Timeout 0` in `speechd.conf` is an alternative but
leaves a daemon running forever.

Debug the layers in this order — each one rules out everything below it:

1. **Daemon lifetime** (the log above) — by far the most likely culprit, and
   invisible from the text side.
2. **Synthesis**, tested offline with no audio at all:
   `RHVoice-test -p slt -i text.txt -o out.wav`, then check the WAV's
   duration matches a sane reading pace (~150 wpm). If the WAV is complete,
   neither the text nor the synthesizer is at fault.
3. **Text extraction** — run the hook manually against a saved transcript
   and print `$clean` instead of speaking it.

Two testing rules learned the hard way: a short test phrase proves nothing
(anything under ~5 seconds completes even when fully broken), and never
verify by playing long audio through the user's speakers — render to a WAV
file and measure its duration instead.
