#!/usr/bin/env python3
"""Generate `.claude/codemap.md` — a structural map of a Python codebase."""

from __future__ import annotations

import argparse
import ast
import hashlib
import json
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

IGNORED_DIRS = {
    ".git", "__pycache__", ".venv", "venv", "node_modules",
    ".claude", "dist", "build", "target", "dbt_packages",
}
MAX_FILE_BYTES = 500 * 1024
MAX_FUNCS_PER_FILE = 20
LOG_PREFIX = "[codemap]"


def log(msg: str) -> None:
    print(f"{LOG_PREFIX} {msg}")


# ---------- file walking + hashing ----------

def iter_source_files(root: Path):
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        if any(part in IGNORED_DIRS for part in path.parts):
            continue
        if path.suffix not in {".py", ".sql", ".yml", ".yaml"}:
            continue
        try:
            if path.stat().st_size > MAX_FILE_BYTES:
                continue
        except OSError:
            continue
        yield path


def hash_file(path: Path) -> str:
    h = hashlib.md5()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


# ---------- parsers ----------

@dataclass
class PyFunction:
    name: str
    line: int
    is_async: bool
    decorators: list[str]
    args: list[str]


@dataclass
class PyClass:
    name: str
    line: int
    bases: list[str]


@dataclass
class PyParsed:
    classes: list[PyClass] = field(default_factory=list)
    functions: list[PyFunction] = field(default_factory=list)
    imports: list[str] = field(default_factory=list)


def _decorator_name(dec: ast.expr) -> str:
    if isinstance(dec, ast.Name):
        return dec.id
    if isinstance(dec, ast.Attribute):
        return _decorator_name(dec.value) + "." + dec.attr
    if isinstance(dec, ast.Call):
        return _decorator_name(dec.func)
    return ast.unparse(dec)


def _base_name(b: ast.expr) -> str:
    try:
        return ast.unparse(b)
    except Exception:
        return "<base>"


def parse_python(path: Path) -> PyParsed:
    out = PyParsed()
    try:
        src = path.read_text(encoding="utf-8", errors="replace")
        tree = ast.parse(src, filename=str(path))
    except (SyntaxError, ValueError):
        return out

    for node in ast.walk(tree):
        if isinstance(node, ast.ClassDef):
            out.classes.append(PyClass(
                name=node.name,
                line=node.lineno,
                bases=[_base_name(b) for b in node.bases],
            ))
        elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            args = [a.arg for a in node.args.args][:5]
            out.functions.append(PyFunction(
                name=node.name,
                line=node.lineno,
                is_async=isinstance(node, ast.AsyncFunctionDef),
                decorators=[_decorator_name(d) for d in node.decorator_list],
                args=args,
            ))

    for node in ast.iter_child_nodes(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                out.imports.append(alias.name)
        elif isinstance(node, ast.ImportFrom):
            mod = node.module or ""
            for alias in node.names:
                out.imports.append(f"{mod}.{alias.name}" if mod else alias.name)

    return out


@dataclass
class SqlParsed:
    refs: list[str] = field(default_factory=list)
    sources: list[tuple[str, str]] = field(default_factory=list)
    ctes: list[str] = field(default_factory=list)
    macros: list[str] = field(default_factory=list)


_RE_REF = re.compile(r"ref\(\s*['\"]([^'\"]+)['\"]\s*\)")
_RE_SOURCE = re.compile(r"source\(\s*['\"]([^'\"]+)['\"]\s*,\s*['\"]([^'\"]+)['\"]\s*\)")
_RE_CTE = re.compile(r"\b(\w+)\s+AS\s*\(", re.IGNORECASE)
_RE_MACRO = re.compile(r"\{\{\s*(\w+)\s*\(")


def parse_sql(path: Path) -> SqlParsed:
    out = SqlParsed()
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return out
    out.refs = _RE_REF.findall(text)
    out.sources = _RE_SOURCE.findall(text)
    out.ctes = _RE_CTE.findall(text)
    out.macros = _RE_MACRO.findall(text)
    return out


def parse_yaml_file(path: Path) -> dict[str, Any]:
    try:
        import yaml  # type: ignore
    except ImportError:
        return {}
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
        data = yaml.safe_load(text)
        if isinstance(data, dict):
            return {"top_keys": sorted(data.keys())}
    except Exception:
        return {}
    return {}


# ---------- cache ----------

def cache_paths(root: Path) -> tuple[Path, Path]:
    claude = root / ".claude"
    return claude / ".codemap_hashes.json", claude / ".codemap_data.json"


def load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}


def save_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")


# ---------- import graph ----------

def resolve_local_import(import_name: str, source_file: Path, root: Path) -> Path | None:
    """Resolve `foo.bar` to `<root>/.../foo/bar.py` or `<root>/.../foo/bar/__init__.py`."""
    parts = import_name.split(".")
    if not parts or not parts[0]:
        return None

    candidates_dirs = [source_file.parent, root]
    for cd in candidates_dirs:
        base = cd
        candidate = base.joinpath(*parts).with_suffix(".py")
        if candidate.exists():
            return candidate
        pkg_init = base.joinpath(*parts) / "__init__.py"
        if pkg_init.exists():
            return pkg_init
        # also try first segment as module
        first = base / f"{parts[0]}.py"
        if first.exists() and len(parts) == 1:
            return first
    return None


def build_import_graph(parsed: dict[str, dict], root: Path) -> dict[str, list[str]]:
    graph: dict[str, list[str]] = {}
    for rel, data in parsed.items():
        if data.get("kind") != "py":
            continue
        source = root / rel
        edges = []
        for imp in data.get("imports", []):
            target = resolve_local_import(imp, source, root)
            if target is None:
                continue
            target_rel = str(target.relative_to(root))
            if target_rel != rel:
                edges.append(target_rel)
        graph[rel] = sorted(set(edges))
    return graph


# ---------- serialization for cache ----------

def py_to_dict(p: PyParsed) -> dict:
    return {
        "kind": "py",
        "classes": [c.__dict__ for c in p.classes],
        "functions": [f.__dict__ for f in p.functions],
        "imports": p.imports,
    }


def sql_to_dict(s: SqlParsed) -> dict:
    return {
        "kind": "sql",
        "refs": s.refs,
        "sources": [list(t) for t in s.sources],
        "ctes": s.ctes,
        "macros": s.macros,
    }


def yaml_to_dict(y: dict) -> dict:
    return {"kind": "yaml", **y}


# ---------- markdown render ----------

def render_markdown(
    root: Path,
    parsed: dict[str, dict],
    graph: dict[str, list[str]],
    changed: list[str],
) -> str:
    py_files = [r for r, d in parsed.items() if d.get("kind") == "py"]
    sql_files = [r for r, d in parsed.items() if d.get("kind") == "sql"]
    yaml_files = [r for r, d in parsed.items() if d.get("kind") == "yaml"]
    edge_count = sum(len(v) for v in graph.values())
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

    lines: list[str] = []
    lines.append(f"# Codebase Map — `{root.name}`")
    lines.append("")
    lines.append(f"_Generated {ts}. Total files: {len(parsed)}._")
    lines.append("")
    if changed:
        lines.append("## Changed files this run")
        for c in changed:
            lines.append(f"- `{c}`")
        lines.append("")

    lines.append("## Summary")
    lines.append("")
    lines.append("| Kind | Count |")
    lines.append("| ---- | ----: |")
    lines.append(f"| Python files | {len(py_files)} |")
    lines.append(f"| SQL files | {len(sql_files)} |")
    lines.append(f"| YAML files | {len(yaml_files)} |")
    lines.append(f"| Import edges | {edge_count} |")
    lines.append("")

    if py_files:
        lines.append("## Python Symbols")
        lines.append("")
        for rel in sorted(py_files):
            data = parsed[rel]
            classes = data.get("classes", [])
            funcs = data.get("functions", [])
            if not classes and not funcs:
                continue
            lines.append(f"### `{rel}`")
            if classes:
                lines.append("")
                lines.append("**Classes:**")
                for c in classes:
                    bases = f"({', '.join(c['bases'])})" if c["bases"] else ""
                    lines.append(f"- `{c['name']}{bases}` — L{c['line']}")
            if funcs:
                lines.append("")
                lines.append("**Functions:**")
                for f in funcs[:MAX_FUNCS_PER_FILE]:
                    prefix = "async " if f["is_async"] else ""
                    decs = "".join(f"@{d} " for d in f["decorators"])
                    lines.append(f"- {decs}`{prefix}{f['name']}(...)` — L{f['line']}")
                if len(funcs) > MAX_FUNCS_PER_FILE:
                    lines.append(f"- _…and {len(funcs) - MAX_FUNCS_PER_FILE} more_")
            lines.append("")

    if graph:
        lines.append("## Import Relationships")
        lines.append("")
        lines.append("```")
        for src in sorted(graph):
            for dst in graph[src]:
                lines.append(f"{src} → {dst}")
        lines.append("```")
        lines.append("")

    # Hub files
    indeg: dict[str, int] = {}
    for src, dsts in graph.items():
        for dst in dsts:
            indeg[dst] = indeg.get(dst, 0) + 1
    if indeg:
        lines.append("## Hub Files")
        lines.append("")
        top = sorted(indeg.items(), key=lambda kv: (-kv[1], kv[0]))[:8]
        for path, count in top:
            lines.append(f"- `{path}` — imported by {count}")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


# ---------- main ----------

def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Generate .claude/codemap.md")
    p.add_argument("root", nargs="?", default=".", help="Project root (default: cwd)")
    p.add_argument("--trigger-file", default=None, help="File path that triggered this run")
    p.add_argument("--force", action="store_true", help="Ignore cache, re-parse everything")
    args = p.parse_args(argv)

    root = Path(args.root).resolve()
    if not root.is_dir():
        log(f"ERROR: root not a directory: {root}")
        return 2

    hashes_path, data_path = cache_paths(root)
    prev_hashes = load_json(hashes_path)
    prev_data = load_json(data_path)

    new_hashes: dict[str, str] = {}
    parsed: dict[str, dict] = {}
    changed: list[str] = []

    for path in iter_source_files(root):
        rel = str(path.relative_to(root))
        h = hash_file(path)
        new_hashes[rel] = h

        needs_reparse = args.force or prev_hashes.get(rel) != h or rel not in prev_data
        if needs_reparse:
            changed.append(rel)
            if path.suffix == ".py":
                parsed[rel] = py_to_dict(parse_python(path))
            elif path.suffix == ".sql":
                parsed[rel] = sql_to_dict(parse_sql(path))
            else:
                parsed[rel] = yaml_to_dict(parse_yaml_file(path))
        else:
            parsed[rel] = prev_data[rel]

    if not changed and not args.force:
        log("No changes detected. Skipping.")
        return 0

    if args.trigger_file:
        log(f"Trigger: {args.trigger_file}")
    log(f"Parsing {len(changed)} changed file(s) of {len(parsed)} total.")

    graph = build_import_graph(parsed, root)
    md = render_markdown(root, parsed, graph, changed)

    out_path = root / ".claude" / "codemap.md"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(md, encoding="utf-8")
    save_json(hashes_path, new_hashes)
    save_json(data_path, parsed)

    log(f"Wrote {out_path.relative_to(root)} ({len(parsed)} files).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
