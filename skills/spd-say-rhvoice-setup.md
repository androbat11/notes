# Making `spd-say` sound clear (RHVoice setup)

By default, `spd-say` on this machine only had the **espeak-ng** output module
available, which uses formant (robotic-sounding) synthesis. This document
records how a natural-sounding voice was added using **RHVoice**, and how to
use it.

## What was installed

**RHVoice** — a free, open-source, offline speech synthesizer that produces
much clearer, more natural-sounding speech than espeak-ng's formant synthesis.
It plugs into `speech-dispatcher` (the service `spd-say` talks to) as an
additional output module.

Fedora 43 doesn't ship RHVoice in its official repos, so it came from a
third-party COPR repository:

```bash
sudo dnf copr enable cuintle/RHVoice -y
sudo dnf install -y rhvoice rhvoice-speech-dispatcher-plugin
```

This installed:
- `rhvoice` — the core synthesizer engine and libraries
- `rhvoice-american-english` — the American English voice data
- `rhvoice-speech-dispatcher-plugin` — the `sd_rhvoice` bridge that lets
  `speech-dispatcher` (and therefore `spd-say`) drive RHVoice

## Configuration

`speech-dispatcher` is configured per-user at
`~/.config/speech-dispatcher/speechd.conf` (a full copy of the system config
at `/etc/speech-dispatcher/speechd.conf`, so it doesn't require root to
maintain).

Two changes were made to that file:

1. Enabled the RHVoice module:
   ```
   AddModule "rhvoice"  "sd_rhvoice"  "rhvoice.conf"
   ```
2. Made it the default output module:
   ```
   DefaultModule rhvoice
   ```

The `rhvoice.conf` referenced above is just a placeholder file (RHVoice's
speech-dispatcher module needs no options) created at:
- `~/.config/speech-dispatcher/modules/rhvoice.conf`
- `~/.config/speech-dispatcher/rhvoice.conf`

After editing the config, the running `speech-dispatcher` daemon was killed
so it would restart and pick up the change:

```bash
pkill -f -u "$USER" speech-dispatcher
```

## Available voices

```bash
spd-say -o rhvoice -L
```

| Voice   | Description                     |
|---------|----------------------------------|
| `bdl`   | American English, male           |
| `clb`   | American English, female         |
| `slt`   | American English, female         |
| `evgeniy-eng` | English, Russian accent    |
| `lyubov`      | English, Russian accent    |

## Recommended usage

```bash
spd-say -r 0 -p 0 "your text here"
```

Since RHVoice is now the `DefaultModule`, plain `spd-say "your text here"`
already uses it — the `-r 0 -p 0` flags aren't strictly required, but it's
worth knowing what they do:

- **`-r` (`--rate`)** — speech **rate** (speed). Accepts `-100` to `+100`,
  where `0` is the module's normal/default speed. Negative values slow the
  speech down, positive values speed it up.
- **`-p` (`--pitch`)** — voice **pitch**. Also `-100` to `+100`, where `0` is
  the module's default pitch. Negative values lower the pitch, positive
  values raise it.

Passing `-r 0 -p 0` explicitly just pins both to their neutral/default
values — useful if you've previously changed the rate or pitch (they persist
across calls in the same speech-dispatcher session) and want to reset to the
clearest, most natural-sounding baseline before speaking.

To pick a specific voice explicitly:

```bash
spd-say -o rhvoice -y clb -r 0 -p 0 "your text here"
```

## Reverting to espeak-ng

```bash
spd-say -o espeak-ng "your text here"
```

or edit `~/.config/speech-dispatcher/speechd.conf` and change
`DefaultModule rhvoice` back to `DefaultModule espeak-ng`.
