Goal: leave this machine with the `/teach` skill installed globally for Claude Code, grafted from its
original upstream repository using tixgraft, driven by a global graft config that can be re-run later
to refresh it. Assume nothing is installed yet. I have already authorized installing the Rust
toolchain and the tixgraft binary on this machine — do not ask again for those.

Step 1 — prerequisites
- `git --version`. If git is missing, print the install command (`sudo dnf install git`,
  `sudo apt install git`, or `xcode-select --install`) and let me run it. Never run sudo yourself.
- `cargo --version`. tixgraft is Rust edition 2024, so it needs Rust 1.85 or newer. If cargo is
  missing: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y` then
  `source "$HOME/.cargo/env"`. If it is older than 1.85: `rustup update stable`.

Step 2 — install tixgraft
tixgraft is not published on crates.io; install it from GitHub, and always with `--locked` (the repo
commits a Cargo.lock; without `--locked` cargo re-resolves dependencies and the build can break):

    cargo install --locked --git https://github.com/eburgos/tixgraft

Verify with `tixgraft --version`. If the shell reports "command not found", add `~/.cargo/bin` to
PATH and re-check.

Step 3 — write the global graft config
Create `~/tixgraft.yaml`. That is tixgraft's default config path, so running tixgraft from the home
directory with no arguments re-applies it. If `~/tixgraft.yaml` already exists, do NOT overwrite it —
append the teach entry to its existing `pulls:` list and leave everything else untouched.

    repository: "https://github.com/mattpocock/skills.git"
    tag: "main"

    pulls:
      # teach — stateful, multi-session teaching workspace (mattpocock/skills)
      - source: "skills/productivity/teach"
        target: "./.claude/skills/teach"
        reset: true
        requireCleanTarget: false

Why those fields: `target` resolves against the working directory, so this config must always be run
from `$HOME`; `reset: true` clears the target folder first so files deleted upstream do not linger;
`requireCleanTarget: false` is required because the home directory is not a git working tree.

Step 4 — graft

    cd ~ && tixgraft

The source is a public repo over HTTPS, so no GitHub SSH key, token, or login is needed. Use
`tixgraft --dry-run` first if you want to preview the operations.

Step 5 — verify, do not assume
- `ls ~/.claude/skills/teach/` should list SKILL.md, MISSION-FORMAT.md, LEARNING-RECORD-FORMAT.md,
  RESOURCES-FORMAT.md, GLOSSARY-FORMAT.md and an `agents/` directory.
- `head -5 ~/.claude/skills/teach/SKILL.md` should show frontmatter with `name: teach` and
  `disable-model-invocation: true` — meaning it runs only when I type `/teach`, never automatically.
- Claude Code discovers `~/.claude/skills/<name>/SKILL.md` on its own: no plugin, no marketplace, no
  settings edit. Start a fresh Claude Code session and confirm `/teach` appears in the slash-command
  list.

Report the tixgraft version, the config path you wrote, and the verification output. If a step fails,
fix the underlying cause — do not skip it and do not hand-copy the skill files as a workaround.

To update the skill later: `cd ~ && tixgraft`.