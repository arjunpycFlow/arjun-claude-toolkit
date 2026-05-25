# Track H — Test sequence verification

## Goal

Integration acceptance test. All 10 commands below pass with zero errors before commit.

## Sequence

```bash
# From arjun_claude_toolkit/
mkdir _test_project && cd _test_project

TOOLKIT_DIR=.. bash ../pull.sh list
TOOLKIT_DIR=.. bash ../pull.sh add skill python-codemap
TOOLKIT_DIR=.. bash ../pull.sh add skill git-conventions
TOOLKIT_DIR=.. bash ../pull.sh add hook python-codemap
TOOLKIT_DIR=.. bash ../pull.sh add agent python-code-reviewer
TOOLKIT_DIR=.. bash ../pull.sh status
TOOLKIT_DIR=.. bash ../pull.sh list   # all four show [installed]

cat .claude/settings.json   # hooks + _toolkit_hooks present

TOOLKIT_DIR=.. bash ../pull.sh remove hook python-codemap
cat .claude/settings.json   # hooks + _toolkit_hooks gone

TOOLKIT_DIR=.. bash ../pull.sh add hook python-codemap
TOOLKIT_DIR=.. bash ../pull.sh add hook python-codemap   # second time no duplicate
cat .claude/settings.json   # _toolkit_hooks has exactly one entry

cd .. && rm -rf _test_project
```

## Acceptance

- Every command exits 0
- `cat` outputs match expectations described in inline comments above
- No leftover `_test_project/` after cleanup

## Failure Handling

If any step fails, do NOT proceed to Track I. Fix the upstream track (likely F), re-run from scratch.
