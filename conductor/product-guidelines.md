# Product Guidelines

## Voice and Tone

- Concise and direct. Imperative mood in docs and CLI output.
- Output style: every CLI line prefixed with `[toolkit]`. Colors: green=success, yellow=warning/notes, red=error (to stderr), cyan=info.

## Design Principles

1. **Pull only what you need** — no auto-install of unused tools.
2. **Copy not link** — copies are standalone; deleting the toolkit does not break target projects.
3. **Hooks merge not replace** — never destroy user-authored hook config.
4. **Re-pull is explicit** — user runs `pull.sh add ...` again to update.

## Standards

- Idempotency: every `add` is safe to re-run.
- Stdlib only for required Python deps. Optional deps degrade gracefully.
- No external bash deps beyond `bash`, `cp`, `rm`, `mkdir`, `python3`.
- Error handling: non-zero exit on failure, helpful suggestion when tool name not found.
