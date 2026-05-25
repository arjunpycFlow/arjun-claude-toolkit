#!/usr/bin/env bash
# pull.sh — selectively install toolkit skills/hooks/agents into a target project.
# See README.md for usage.

set -euo pipefail

# ---------- resolve dirs ----------

_script_path="${BASH_SOURCE[0]}"
# follow symlinks
while [ -L "$_script_path" ]; do
  _dir="$(cd -P "$(dirname "$_script_path")" && pwd)"
  _script_path="$(readlink "$_script_path")"
  [[ "$_script_path" != /* ]] && _script_path="$_dir/$_script_path"
done
TOOLKIT_DIR="${TOOLKIT_DIR:-$(cd -P "$(dirname "$_script_path")" && pwd)}"
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"

# ---------- colors ----------

C_RESET=$'\033[0m'
C_GREEN=$'\033[32m'
C_YELLOW=$'\033[33m'
C_RED=$'\033[31m'
C_CYAN=$'\033[36m'
C_BOLD=$'\033[1m'

log_info()    { echo -e "${C_CYAN}[toolkit]${C_RESET} $*"; }
log_ok()      { echo -e "${C_GREEN}[toolkit]${C_RESET} $*"; }
log_warn()    { echo -e "${C_YELLOW}[toolkit]${C_RESET} $*"; }
log_err()     { echo -e "${C_RED}[toolkit]${C_RESET} $*" >&2; }
log_section() { echo -e "${C_BOLD}[toolkit] $*${C_RESET}"; }

# ---------- frontmatter readers ----------

# Read `description:` from a markdown frontmatter file.
# Handles both single-line and folded (`>`) multi-line descriptions.
read_md_description() {
  local file="$1"
  [ -f "$file" ] || { echo "(file missing)"; return; }
  python3 - "$file" <<'PYEOF'
import sys, re
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
m = re.search(r"^---\s*\n(.*?)\n---\s*\n", text, re.DOTALL | re.MULTILINE)
if not m:
    print("(no frontmatter)")
    sys.exit(0)
fm = m.group(1)
# Find description key
lines = fm.splitlines()
desc_lines = []
in_desc = False
indent = None
for i, line in enumerate(lines):
    if not in_desc:
        m2 = re.match(r"^description:\s*(.*)$", line)
        if m2:
            val = m2.group(1).strip()
            if val in (">", "|", ">-", "|-"):
                in_desc = True
                continue
            elif val:
                desc_lines.append(val)
                break
            else:
                in_desc = True
                continue
    else:
        if re.match(r"^\S", line):  # next top-level key
            break
        stripped = line.strip()
        if stripped:
            desc_lines.append(stripped)
joined = " ".join(desc_lines).strip()
print(joined or "(no description)")
PYEOF
}

read_hook_description() {
  local file="$1"
  [ -f "$file" ] || { echo "(file missing)"; return; }
  python3 - "$file" <<'PYEOF'
import sys, json
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
    print(d.get("_description", "(no description)"))
except Exception as e:
    print(f"(parse error: {e})")
PYEOF
}

read_hook_install_notes() {
  local file="$1"
  [ -f "$file" ] || return
  python3 - "$file" <<'PYEOF'
import sys, json
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
    notes = d.get("_install_notes")
    if notes:
        print(notes)
except Exception:
    pass
PYEOF
}

# ---------- install detectors ----------

skill_installed()  { [ -d "$PROJECT_DIR/.claude/skills/$1" ]; }
agent_installed()  { [ -f "$PROJECT_DIR/.claude/agents/$1.md" ]; }
hook_installed() {
  local name="$1"
  local settings="$PROJECT_DIR/.claude/settings.json"
  [ -f "$settings" ] || return 1
  python3 - "$settings" "$name" <<'PYEOF'
import sys, json
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
    if sys.argv[2] in d.get("_toolkit_hooks", []):
        sys.exit(0)
    sys.exit(1)
except Exception:
    sys.exit(1)
PYEOF
}

# ---------- list / status ----------

list_skill_names() {
  [ -d "$TOOLKIT_DIR/skills" ] || return
  for d in "$TOOLKIT_DIR"/skills/*/; do
    [ -d "$d" ] || continue
    basename "$d"
  done
}

list_hook_names() {
  [ -d "$TOOLKIT_DIR/hooks" ] || return
  for f in "$TOOLKIT_DIR"/hooks/*.json; do
    [ -f "$f" ] || continue
    basename "$f" .json
  done
}

list_agent_names() {
  [ -d "$TOOLKIT_DIR/agents" ] || return
  for f in "$TOOLKIT_DIR"/agents/*.md; do
    [ -f "$f" ] || continue
    basename "$f" .md
  done
}

cmd_list() {
  log_section "Skills"
  for name in $(list_skill_names); do
    local desc; desc="$(read_md_description "$TOOLKIT_DIR/skills/$name/SKILL.md")"
    local suffix=""
    skill_installed "$name" && suffix=" ${C_GREEN}[installed]${C_RESET}"
    echo -e "  ${C_BOLD}$name${C_RESET}${suffix}"
    echo -e "    $desc"
  done

  log_section "Hooks"
  for name in $(list_hook_names); do
    local desc; desc="$(read_hook_description "$TOOLKIT_DIR/hooks/$name.json")"
    local suffix=""
    hook_installed "$name" && suffix=" ${C_GREEN}[installed]${C_RESET}"
    echo -e "  ${C_BOLD}$name${C_RESET}${suffix}"
    echo -e "    $desc"
  done

  log_section "Agents"
  for name in $(list_agent_names); do
    local desc; desc="$(read_md_description "$TOOLKIT_DIR/agents/$name.md")"
    local suffix=""
    agent_installed "$name" && suffix=" ${C_GREEN}[installed]${C_RESET}"
    echo -e "  ${C_BOLD}$name${C_RESET}${suffix}"
    echo -e "    $desc"
  done
}

cmd_status() {
  log_info "PROJECT_DIR=$PROJECT_DIR"
  log_section "Installed skills"
  local any=0
  for name in $(list_skill_names); do
    if skill_installed "$name"; then echo "  - $name"; any=1; fi
  done
  if [ $any -eq 0 ]; then echo "  (none)"; fi

  log_section "Installed hooks"
  any=0
  for name in $(list_hook_names); do
    if hook_installed "$name"; then echo "  - $name"; any=1; fi
  done
  if [ $any -eq 0 ]; then echo "  (none)"; fi

  log_section "Installed agents"
  any=0
  for name in $(list_agent_names); do
    if agent_installed "$name"; then echo "  - $name"; any=1; fi
  done
  if [ $any -eq 0 ]; then echo "  (none)"; fi
}

# ---------- add ----------

confirm_overwrite() {
  local what="$1"
  read -r -p "$(echo -e "${C_YELLOW}[toolkit]${C_RESET} $what already installed. Overwrite? [y/N]: ")" ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

cmd_add_skill() {
  local name="$1"
  local src="$TOOLKIT_DIR/skills/$name"
  if [ ! -d "$src" ]; then
    log_err "Skill not found: $name. Run: pull.sh list"
    exit 1
  fi
  local dest="$PROJECT_DIR/.claude/skills/$name"
  if [ -d "$dest" ]; then
    confirm_overwrite "Skill '$name'" || { log_warn "Skipped."; return; }
    rm -rf "$dest"
  fi
  mkdir -p "$dest"
  cp -R "$src"/. "$dest"/
  log_ok "Installed skill: $name"

  # Also copy .py / .sh siblings to scripts/
  local copied_scripts=0
  for f in "$src"/*.py "$src"/*.sh; do
    [ -f "$f" ] || continue
    mkdir -p "$PROJECT_DIR/scripts"
    cp "$f" "$PROJECT_DIR/scripts/$(basename "$f")"
    copied_scripts=1
  done
  [ $copied_scripts -eq 1 ] && log_ok "Copied helper scripts to $PROJECT_DIR/scripts/"

  if [ -f "$src/.install-notes" ]; then
    echo
    log_warn "Install notes:"
    cat "$src/.install-notes" | sed 's/^/    /'
    echo
  fi
}

cmd_add_hook() {
  local name="$1"
  local src="$TOOLKIT_DIR/hooks/$name.json"
  if [ ! -f "$src" ]; then
    log_err "Hook not found: $name. Run: pull.sh list"
    exit 1
  fi
  local settings="$PROJECT_DIR/.claude/settings.json"
  mkdir -p "$(dirname "$settings")"
  [ -f "$settings" ] || echo "{}" > "$settings"

  if hook_installed "$name"; then
    log_warn "Hook '$name' already installed. Skipping."
    return
  fi

  python3 - "$settings" "$src" "$name" <<'PYEOF'
import sys, json
settings_path, src_path, name = sys.argv[1], sys.argv[2], sys.argv[3]
settings = json.load(open(settings_path, encoding="utf-8"))
fragment = json.load(open(src_path, encoding="utf-8"))
# strip meta
for k in ("_name", "_description", "_install_notes"):
    fragment.pop(k, None)

frag_hooks = fragment.get("hooks", {})
settings.setdefault("hooks", {})
for event, entries in frag_hooks.items():
    settings["hooks"].setdefault(event, [])
    # concatenate — never replace
    settings["hooks"][event].extend(entries)

settings.setdefault("_toolkit_hooks", [])
if name not in settings["_toolkit_hooks"]:
    settings["_toolkit_hooks"].append(name)

with open(settings_path, "w", encoding="utf-8") as f:
    json.dump(settings, f, indent=2, sort_keys=False)
    f.write("\n")
PYEOF

  log_ok "Installed hook: $name"
  local notes; notes="$(read_hook_install_notes "$src")"
  if [ -n "$notes" ]; then
    echo
    log_warn "Install notes:"
    echo "    $notes"
    echo
  fi
}

cmd_add_agent() {
  local name="$1"
  local src="$TOOLKIT_DIR/agents/$name.md"
  if [ ! -f "$src" ]; then
    log_err "Agent not found: $name. Run: pull.sh list"
    exit 1
  fi
  local dest="$PROJECT_DIR/.claude/agents/$name.md"
  mkdir -p "$(dirname "$dest")"
  if [ -f "$dest" ]; then
    confirm_overwrite "Agent '$name'" || { log_warn "Skipped."; return; }
  fi
  cp "$src" "$dest"
  log_ok "Installed agent: $name"
}

# ---------- remove ----------

cmd_remove_skill() {
  local name="$1"
  local dest="$PROJECT_DIR/.claude/skills/$name"
  if [ ! -d "$dest" ]; then
    log_warn "Skill '$name' not installed in $PROJECT_DIR. Nothing to do."
    return
  fi
  rm -rf "$dest"
  log_ok "Removed skill: $name"
}

cmd_remove_hook() {
  local name="$1"
  local src="$TOOLKIT_DIR/hooks/$name.json"
  local settings="$PROJECT_DIR/.claude/settings.json"
  if [ ! -f "$src" ]; then
    log_err "Hook source not found: $name (need it to know what to remove)."
    exit 1
  fi
  if [ ! -f "$settings" ]; then
    log_warn "No settings.json in $PROJECT_DIR. Nothing to do."
    return
  fi

  python3 - "$settings" "$src" "$name" <<'PYEOF'
import sys, json
settings_path, src_path, name = sys.argv[1], sys.argv[2], sys.argv[3]
settings = json.load(open(settings_path, encoding="utf-8"))
fragment = json.load(open(src_path, encoding="utf-8"))
for k in ("_name", "_description", "_install_notes"):
    fragment.pop(k, None)
frag_hooks = fragment.get("hooks", {})

settings_hooks = settings.get("hooks", {})
for event, entries in frag_hooks.items():
    if event not in settings_hooks:
        continue
    # filter out entries that match by (matcher, hooks payload)
    def matches(existing, candidate):
        return existing == candidate
    settings_hooks[event] = [
        e for e in settings_hooks[event]
        if not any(matches(e, c) for c in entries)
    ]
    if not settings_hooks[event]:
        del settings_hooks[event]

if not settings_hooks:
    settings.pop("hooks", None)
else:
    settings["hooks"] = settings_hooks

tk = settings.get("_toolkit_hooks", [])
if name in tk:
    tk.remove(name)
if not tk:
    settings.pop("_toolkit_hooks", None)
else:
    settings["_toolkit_hooks"] = tk

with open(settings_path, "w", encoding="utf-8") as f:
    json.dump(settings, f, indent=2, sort_keys=False)
    f.write("\n")
PYEOF
  log_ok "Removed hook: $name"
}

cmd_remove_agent() {
  local name="$1"
  local dest="$PROJECT_DIR/.claude/agents/$name.md"
  if [ ! -f "$dest" ]; then
    log_warn "Agent '$name' not installed in $PROJECT_DIR. Nothing to do."
    return
  fi
  rm -f "$dest"
  log_ok "Removed agent: $name"
}

# ---------- usage ----------

usage() {
  cat <<EOF
Usage:
  pull.sh list
  pull.sh status
  pull.sh add    skill|hook|agent <name>
  pull.sh remove skill|hook|agent <name>

Env:
  TOOLKIT_DIR   Path to this toolkit (default: dir containing pull.sh)
  PROJECT_DIR   Target project (default: \$PWD)

Current:
  TOOLKIT_DIR=$TOOLKIT_DIR
  PROJECT_DIR=$PROJECT_DIR
EOF
}

# ---------- dispatcher ----------

main() {
  local cmd="${1:-}"
  case "$cmd" in
    list)     shift; cmd_list "$@" ;;
    status)   shift; cmd_status "$@" ;;
    add)
      shift
      local kind="${1:-}"; local name="${2:-}"
      if [ -z "$kind" ] || [ -z "$name" ]; then
        log_err "Missing args. Usage: pull.sh add skill|hook|agent <name>"
        exit 1
      fi
      case "$kind" in
        skill) cmd_add_skill "$name" ;;
        hook)  cmd_add_hook  "$name" ;;
        agent) cmd_add_agent "$name" ;;
        *) log_err "Unknown kind: $kind"; exit 1 ;;
      esac
      ;;
    remove)
      shift
      local kind="${1:-}"; local name="${2:-}"
      if [ -z "$kind" ] || [ -z "$name" ]; then
        log_err "Missing args. Usage: pull.sh remove skill|hook|agent <name>"
        exit 1
      fi
      case "$kind" in
        skill) cmd_remove_skill "$name" ;;
        hook)  cmd_remove_hook  "$name" ;;
        agent) cmd_remove_agent "$name" ;;
        *) log_err "Unknown kind: $kind"; exit 1 ;;
      esac
      ;;
    ""|-h|--help|help)
      usage
      ;;
    *)
      log_err "Unknown command: $cmd"
      usage
      exit 1
      ;;
  esac
}

main "$@"
