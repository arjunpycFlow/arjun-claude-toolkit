# Track F — Plan

## Tasks

1. Top of `pull.sh`: shebang, `set -euo pipefail`, resolve `TOOLKIT_DIR`, default `PROJECT_DIR`.
2. ANSI color constants + `log_*` helpers (info/success/warn/err).
3. Frontmatter/description readers:
   - `read_skill_desc(name)` — bash; extract `description:` from `skills/<name>/SKILL.md` between first two `---`
   - `read_hook_desc(name)` — python heredoc reads `_description` from JSON
   - `read_agent_desc(name)` — bash; same approach as skill
4. Install detectors:
   - `skill_installed(name)`, `hook_installed(name)`, `agent_installed(name)`
5. Commands (each in its own function):
   - `cmd_list`
   - `cmd_status`
   - `cmd_add_skill`
   - `cmd_add_hook` — python heredoc does the deep merge
   - `cmd_add_agent`
   - `cmd_remove_skill`
   - `cmd_remove_hook` — python heredoc
   - `cmd_remove_agent`
6. Usage function + dispatcher in `main`.
7. Make executable: `chmod +x pull.sh`.
8. Smoke test before Track H: `bash pull.sh list` from repo root.

## Key Implementation Notes

- Frontmatter parsing in bash: `awk` between `---` markers, grep `^description:` and handle multi-line `>` block by reading until next `^[a-z]:` or `^---`.
- For multi-line description, join lines and strip leading whitespace.
- Hook merge python: load existing settings, merge each event array via concatenation, add name to `_toolkit_hooks` (create if absent).
- Hook remove python: load both files, for each event in fragment, filter out matching entries (compare matcher+command), remove name from `_toolkit_hooks`.
- Use `tput colors` check or just emit ANSI unconditionally per spec (simpler).
- `read -r -p "...overwrite? [y/N]: " ans` for prompts. Treat empty as N.
