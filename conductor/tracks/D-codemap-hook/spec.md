# Track D — python-codemap hook

## Goal

Hook config consumed by `pull.sh add hook` that wires codemap regen into PostToolUse + SessionStart.

## Deliverable

`hooks/python-codemap.json`:

```json
{
  "_name": "python-codemap",
  "_description": "Auto-regenerates .claude/codemap.md on file writes and session start. Python projects only.",
  "_install_notes": "Bootstrap first: python3 scripts/generate_codemap.py . --force",
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "[ -f scripts/generate_codemap.py ] && python3 scripts/generate_codemap.py . --trigger-file \"$TOOL_INPUT_file_path\" || true",
            "async": true,
            "timeout": 15000
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "[ -f scripts/generate_codemap.py ] && python3 scripts/generate_codemap.py . --force || true",
            "timeout": 30000
          }
        ]
      }
    ]
  }
}
```

## Acceptance

- File parses as valid JSON (`python3 -c "import json; json.load(open('hooks/python-codemap.json'))"`)
- Contains `_name`, `_description`, `_install_notes`, `hooks` top-level keys
