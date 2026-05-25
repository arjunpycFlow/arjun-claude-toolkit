# Tracks Registry

| Status      | Track ID | Title                              | Created    | Updated    |
| ----------- | -------- | ---------------------------------- | ---------- | ---------- |
| completed   | A        | Repo scaffold + .gitignore         | 2026-05-22 | 2026-05-22 |
| completed   | B        | python-codemap skill               | 2026-05-22 | 2026-05-22 |
| completed   | C        | git-conventions skill              | 2026-05-22 | 2026-05-22 |
| completed   | D        | python-codemap hook                | 2026-05-22 | 2026-05-22 |
| completed   | E        | python-code-reviewer agent         | 2026-05-22 | 2026-05-22 |
| completed   | F        | pull.sh CLI                        | 2026-05-22 | 2026-05-22 |
| completed   | G        | README                             | 2026-05-22 | 2026-05-22 |
| completed   | H        | Test sequence verification         | 2026-05-22 | 2026-05-22 |
| pending     | I        | git init + commit                  | 2026-05-22 | 2026-05-22 |

## Dependency Graph

```
A → B, C, D, E
B, D → F (F needs at least one skill + hook to test)
E → F
F → G (README documents pull.sh usage)
G → H
H → I
```

## Notes

- Tracks A–E can ship in parallel after A. Track F gates on B, D, E producing real artifacts so install paths exist to test.
- Track H is the integration acceptance gate. Track I requires explicit user approval.
- Track F shipped with one bug fixed during Track H: `[ $any -eq 0 ] && echo` failed under `set -e` when condition was false. Replaced with `if/then`.
