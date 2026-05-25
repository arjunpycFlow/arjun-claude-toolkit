# arjun-claude-toolkit

Personal Claude Code tooling registry. Reusable skills, hooks, and agents live here. `pull.sh` selectively copies only what a target project needs. Nothing is installed globally.

## Setup

```bash
git clone <repo-url> ~/code/arjun_claude_toolkit
# Optional: alias for convenience
echo 'alias toolkit="bash ~/code/arjun_claude_toolkit/pull.sh"' >> ~/.zshrc
```

By default `pull.sh` resolves its own toolkit dir. Override with `TOOLKIT_DIR=<path>` if you keep the repo elsewhere. The target project defaults to `$PWD`; override with `PROJECT_DIR=<path>`.

## Usage

```bash
# inside any target project
toolkit list                           # show everything available
toolkit status                         # show what's installed here

toolkit add skill python-codemap       # copy skill into .claude/skills/
toolkit add skill git-conventions
toolkit add hook python-codemap        # merge into .claude/settings.json
toolkit add agent python-code-reviewer # copy into .claude/agents/

toolkit remove skill python-codemap
toolkit remove hook  python-codemap
toolkit remove agent python-code-reviewer
```

## Available tools

### Skills

| Name              | Description                                                                                  |
| ----------------- | -------------------------------------------------------------------------------------------- |
| `python-codemap`  | Auto-maintained map of Python codebase structure (`.claude/codemap.md`). Uses AST + caching. |
| `git-conventions` | Conventional commits, branch naming, and PR template guidance.                               |

### Hooks

| Name             | Description                                                                                  |
| ---------------- | -------------------------------------------------------------------------------------------- |
| `python-codemap` | Regenerates `.claude/codemap.md` on `Edit`/`Write`/`MultiEdit` and at `SessionStart`.        |

### Agents

| Name                   | Description                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------------- |
| `python-code-reviewer` | Senior Python reviewer — correctness, edge cases, security. Not style.                       |

## Directory structure

```
arjun_claude_toolkit/
├── pull.sh
├── README.md
├── .gitignore
├── skills/
│   ├── python-codemap/
│   │   ├── SKILL.md
│   │   ├── generate_codemap.py
│   │   └── .install-notes
│   └── git-conventions/
│       └── SKILL.md
├── hooks/
│   └── python-codemap.json
├── agents/
│   └── python-code-reviewer.md
└── conductor/                  # project context (specs, tracks, plans)
```

## Adding a new tool

### Skill

```
skills/<name>/
├── SKILL.md          # required, with YAML frontmatter (name, description)
├── <optional>.py     # optional helper, copied to scripts/ on install
├── <optional>.sh     # optional helper, copied to scripts/ on install
└── .install-notes    # optional, printed after install
```

Minimal `SKILL.md`:

```markdown
---
name: my-skill
description: >
  One-sentence trigger condition for when Claude should use this.
---

# My Skill

How to use it.
```

### Hook

```
hooks/<name>.json
```

Wrap the actual hook fragment in a JSON object with these meta keys:

```json
{
  "_name": "my-hook",
  "_description": "One sentence for `pull.sh list`.",
  "_install_notes": "Anything the user must do after install.",
  "hooks": { /* the real hooks payload */ }
}
```

Hook entries **concatenate** with existing `settings.json` arrays. They never replace.

### Agent

```
agents/<name>.md
```

Standard agent file with frontmatter (`name`, `description`, optional `tools`, `model`).

## What to commit in a target project

After `pull.sh add ...`:

- **Commit** `.claude/skills/<name>/`, `.claude/agents/<name>.md`, and the changes to `.claude/settings.json`.
- **Commit** any `scripts/*.py` helpers copied alongside skills.
- **Gitignore** generated state (e.g. `.claude/codemap.md`, `.claude/.codemap_*.json`).

Toolkit-installed items are tracked via `_toolkit_hooks` inside `settings.json` so future `remove` calls know what to clean up.

## Philosophy

- **Pull only what you need.** No tool is installed until you ask for it.
- **Copy not link.** Each target project carries its own copy. Deleting this repo doesn't break consumers.
- **Hooks merge not replace.** Your existing `settings.json` is preserved; new entries are appended.
- **Re-pull is explicit.** Updates from the toolkit do not auto-propagate. Run `pull.sh add ...` again to refresh.
