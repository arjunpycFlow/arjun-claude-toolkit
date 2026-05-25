---
name: git-conventions
description: >
  Use when writing commit messages, PR descriptions, or branch names.
---

# Git Conventions

## Commit messages — Conventional Commits

Format: `<type>(<scope>): <subject>`

**Types:** `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`, `ci`

**Rules:**

- Subject ≤ 72 chars.
- Imperative mood (`add user auth`, not `added user auth`).
- Body explains WHY, not WHAT. The diff is the WHAT.
- Footer for issue refs: `Refs: #123` or `Closes: #123`.

Example:

```
feat(auth): require email verification before first login

Spam signups doubled month-over-month. Verifying email gates the worst
of it without adding friction for real users.

Refs: #482
```

## Branch naming

Format: `<type>/<short-description>`

Examples:

- `feat/user-auth`
- `fix/csv-encoding`
- `refactor/payment-handler`

Use kebab-case in the description. Keep it under 40 chars.

## PR template

```markdown
## What
One-line summary of the change.

## Why
The motivation. What pain or opportunity prompted this?

## How
Approach taken. Trade-offs considered. Non-obvious decisions.

## Testing
- [ ] Automated tests added/updated
- [ ] Manual verification steps
- [ ] Edge cases considered: ...
```

Fill every section. "N/A" is acceptable when truly nothing applies.
