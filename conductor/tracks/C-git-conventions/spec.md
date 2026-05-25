# Track C — git-conventions skill

## Goal

Single SKILL.md documenting commit/branch/PR conventions.

## Deliverable

`skills/git-conventions/SKILL.md` with:

### Frontmatter

```yaml
---
name: git-conventions
description: >
  Use when writing commit messages, PR descriptions, or branch names.
---
```

### Body

- Conventional commits format: `<type>(<scope>): <subject>`
- Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`, `ci`
- Rules: subject ≤72 chars, imperative mood, body explains WHY not WHAT, footer for issue refs (`Refs: #123`)
- Branch naming: `<type>/<short-description>` (e.g. `feat/user-auth`)
- PR template: What, Why, How, Testing

## Acceptance

- File exists at correct path
- Frontmatter parses as valid YAML
- Body covers all listed conventions
