Add the last30days skill to my home tixgraft config so it installs into ~/.claude/skills.

The skill lives at github.com/mvanhorn/last30days-skill, branch main, directory skills/last30days.

If ~/tixgraft.yaml does not exist, create it with exactly this content:

pulls:
  - repository: "git@github.com:mvanhorn/last30days-skill.git"
    tag: "main"
    source: "skills/last30days"
    target: "./.claude/skills/last30days"
    reset: true
    requireCleanTarget: false

If ~/tixgraft.yaml already exists, append that same pull entry to its `pulls:` list and leave every existing entry untouched. If the file has no `pulls:` list (for example it only has `children:`), add one.

Target paths in tixgraft resolve relative to the config file's directory, so with the file in ~ the skill lands in ~/.claude/skills/last30days.

Then run `cd ~ && tixgraft` and confirm ~/.claude/skills/last30days/SKILL.md exists with `name: last30days` in its frontmatter. Do not edit anything under ~/.claude/skills by hand; that directory is build output and `reset: true` overwrites it on every run.