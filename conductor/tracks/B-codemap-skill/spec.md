# Track B — python-codemap skill

## Goal

Skill that auto-maintains `.claude/codemap.md` for any Python project it's copied into.

## Deliverables

1. `skills/python-codemap/generate_codemap.py` — CLI: `python3 scripts/generate_codemap.py [root_dir] [--trigger-file <path>] [--force]`
2. `skills/python-codemap/SKILL.md` — frontmatter + body per spec
3. `skills/python-codemap/.install-notes` — 4–6 line setup hint

## generate_codemap.py Behavior

- Walk dir. Ignore: `.git`, `__pycache__`, `.venv`, `venv`, `node_modules`, `.claude`, `dist`, `build`, `target`, `dbt_packages`. Skip files > 500KB.
- Parse `.py` via stdlib `ast`: classes (name, bases, line), functions/methods (name, line, is_async, decorators, args first 5), imports. Cap 20 funcs/file in output.
- Parse `.sql` via `re`: `ref('x')`, `source('a','b')`, CTE names `word AS (`, macros `{{ word(`.
- Parse `.yml/.yaml` via `yaml` if importable, else skip gracefully (try/except, never crash).
- MD5 hash cache: `.claude/.codemap_hashes.json`. Only re-parse changed files. Persist parsed data in `.claude/.codemap_data.json`.
- `--force`: ignore cache, full re-parse.
- Build import graph; resolve local imports to file paths; emit `file_a → file_b` edges.
- Render `.claude/codemap.md` sections:
  1. Header: timestamp, total file count, list of changed files this run
  2. Summary table: Python files, SQL files, YAML files, import edge count
  3. Python Symbols: per file, class list (bases+line), function list (async marker + decorators + line)
  4. Import Relationships: fenced code block, `src/file.py → src/other.py` lines
  5. Hub Files: top 8 most-imported, descending
- Log `[codemap] <message>` prefixed lines.
- No-change + no `--force`: print `[codemap] No changes detected. Skipping.` and exit 0.
- Zero required external deps. `pyyaml` optional.

## SKILL.md Frontmatter

```yaml
---
name: python-codemap
description: >
  Use when asked about Python codebase structure, file relationships, where something
  is defined, what imports what, or before starting work that touches multiple
  files. Also use for "what does X call", "what depends on Y", "hub files".
  Python-specific: parses .py files via AST, .sql via regex. Add a language-specific
  codemap skill for other stacks.
---
```

## SKILL.md Body Must Cover

- `.claude/codemap.md` is auto-maintained
- How to use: read before multi-file tasks; Symbols → find defs; Imports → trace impact; Hub Files → high-risk edits
- When to manually run `--force` (after git pull, branch switch)
- What it does NOT replace: semantic search, dynamic imports, type resolution

## .install-notes

4–6 lines telling user to:
- Bootstrap: `python3 scripts/generate_codemap.py . --force`
- Gitignore: `.claude/codemap.md`, `.claude/.codemap_hashes.json`, `.claude/.codemap_data.json`
- Add `## Codebase Map` block to project `CLAUDE.md`

## Acceptance

- Run `python3 skills/python-codemap/generate_codemap.py . --force` from repo root → creates `.claude/codemap.md` without error
- Re-run without `--force` → prints "No changes detected. Skipping."
- Editing any `.py` file changes the hash and triggers a partial re-parse on next run
