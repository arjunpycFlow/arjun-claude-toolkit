---
name: python-codemap
description: >
  Use when asked about Python codebase structure, file relationships, where something
  is defined, what imports what, or before starting work that touches multiple
  files. Also use for "what does X call", "what depends on Y", "hub files".
  Python-specific: parses .py files via AST, .sql via regex. Add a language-specific
  codemap skill for other stacks.
---

# Python Codemap

`.claude/codemap.md` is auto-maintained whenever you edit a file (via the `python-codemap` hook) and is regenerated at session start. Read it before any task that spans more than one file.

## How to use

1. **Locate symbols.** The *Python Symbols* section lists classes and functions per file with line numbers. Use it instead of grepping when asked "where is `Foo` defined?".
2. **Trace impact.** The *Import Relationships* section shows local module edges. Before editing a file, scan upstream and downstream edges to estimate blast radius.
3. **Spot high-risk edits.** The *Hub Files* section ranks the most-imported files. Touching one of these affects many downstream callers — review with extra care.
4. **Check the header.** The *Changed files this run* list shows what changed since the last regeneration, useful when resuming work after a context break.

## When to manually regenerate

Run the underlying script with `--force` after:

- `git pull` (many files changed at once, hook only fires on local edits)
- branch switch
- large IDE-driven refactor that bypassed Claude's edit tools

```bash
# plain Python
python3 scripts/generate_codemap.py . --force

# uv-managed project
uv run python scripts/generate_codemap.py . --force
```

The script is stdlib-only, so either invocation works. Use `uv run` when your project pins Python via `uv` and you want toolkit commands to honor the project's interpreter.

## What this does NOT replace

- **Semantic search.** The map is structural — symbol names and import edges only. For "what code handles auth retries?" use grep / read.
- **Dynamic imports.** `importlib.import_module(name)` calls aren't traced.
- **Type resolution.** No inheritance walks, no protocol matching, no call-graph beyond imports.

The map is a navigation aid, not a substitute for reading code.
