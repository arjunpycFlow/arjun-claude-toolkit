# Tech Stack

## Languages

- **Python 3.14** (primary) — via `uv` virtualenv, already active
- **Bash** — `pull.sh` CLI and other shell glue
- **Go** — allowed when Python/bash are insufficient (e.g. cross-platform binaries, performance-critical tools)

## Runtime / Tooling

- `uv` for Python env management
- `pytest >= 9.0.3` (dev)
- `ruff >= 0.15.14` (dev)
- Stdlib `ast`, `re`, `hashlib`, `json` for codemap parsing
- Optional: `pyyaml` (graceful skip if absent)

## Frontend / Backend / DB

None. CLI + static config files only.

## Infrastructure

- Local git repo. No deploy target.
- Consumed by other projects via `pull.sh` invocation pointing `TOOLKIT_DIR` at this repo.

## Key Dependencies

- No required runtime deps beyond Python stdlib.
- All optional deps must wrap in try/except and continue on import failure.
- Go modules (if introduced) live under their own subdir with own `go.mod`.

## Language Selection Rule

1. Default: Python.
2. Shell glue, install scripts, hook commands: Bash.
3. Reach for Go when: portable single-binary needed, perf matters, or stdlib Python lacks the primitive.
