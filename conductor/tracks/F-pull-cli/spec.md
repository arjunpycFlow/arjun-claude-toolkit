# Track F — pull.sh CLI

## Goal

Single self-contained bash script that lists, installs, and removes toolkit items in a target project.

## Deliverable

`pull.sh` at repo root. Bash + inline Python heredocs only. No external bash deps beyond `bash`, `cp`, `rm`, `mkdir`, `python3`.

## Commands

```
pull.sh list
pull.sh status
pull.sh add skill <name>
pull.sh add hook <name>
pull.sh add agent <name>
pull.sh remove skill <name>
pull.sh remove hook <name>
pull.sh remove agent <name>
```

## Env Vars

- `TOOLKIT_DIR` — path to this repo. Default: dir containing `pull.sh` (via `${BASH_SOURCE[0]}` resolve).
- `PROJECT_DIR` — target. Default: `$(pwd)`.

## Per-Command Behavior

### `list`
Three sections: Skills, Hooks, Agents. For each entry show name + description.
- Skill desc: read `SKILL.md` frontmatter `description:` field
- Hook desc: read `_description` key
- Agent desc: read frontmatter `description:` field
- Suffix `[installed]` (green) if already in `PROJECT_DIR`

### `status`
Show only toolkit-managed items installed in `$PROJECT_DIR`. Detect:
- Skill: dir exists in `.claude/skills/<name>/`
- Hook: name in `_toolkit_hooks` array in `settings.json`
- Agent: `.md` exists in `.claude/agents/<name>.md`

### `add skill <name>`
- Copy `skills/<name>/` → `$PROJECT_DIR/.claude/skills/<name>/`
- If skill dir contains `.py` or `.sh` files alongside SKILL.md, also copy those to `$PROJECT_DIR/scripts/` (create if needed)
- Print `.install-notes` if present
- Prompt overwrite (`y/N`) if already installed

### `add hook <name>`
- Deep-merge `hooks/<name>.json` into `$PROJECT_DIR/.claude/settings.json`
- Strip `_name`, `_description`, `_install_notes` before merging
- Hook arrays **concatenate**, never replace
- Track installed in `_toolkit_hooks: []` array in settings.json
- Print `_install_notes` value
- Skip silently if name already in `_toolkit_hooks`
- Create settings.json as `{}` if missing

### `add agent <name>`
- Copy `agents/<name>.md` → `$PROJECT_DIR/.claude/agents/<name>.md`
- Prompt overwrite if already installed

### `remove skill <name>`
- Delete `$PROJECT_DIR/.claude/skills/<name>/`

### `remove hook <name>`
- Python heredoc removes only the matching hook entries from settings.json by comparing against the fragment
- Removes name from `_toolkit_hooks`
- Does not touch any other keys

### `remove agent <name>`
- Delete `$PROJECT_DIR/.claude/agents/<name>.md`

## Output

- Every line prefixed `[toolkit]`
- Colors via ANSI: green=success, yellow=warning/notes, red=error (stderr), cyan=info
- Use `echo -e`

## Error Cases

- Tool not found → red error + "Run: pull.sh list"
- Missing args → print usage
- Exit 0 on success, non-zero on error

## Idempotency

All `add` commands check before acting.

## Acceptance

The Track H test sequence (10 documented commands) all pass with zero errors.
