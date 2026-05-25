# Track B — Plan

## Tasks

1. Write `skills/python-codemap/generate_codemap.py`
   - Top-level: arg parsing (argparse), constants for ignored dirs/file size
   - `hash_file(path)` → md5
   - `parse_python(path)` → ast walk, return dict {classes, functions, imports}
   - `parse_sql(text)` → regex, return dict {refs, sources, ctes, macros}
   - `parse_yaml(path)` → try import yaml; on ImportError return {}
   - `load_cache()` / `save_cache()` for hashes + parsed data
   - `build_import_graph(parsed_dict)` → adjacency list
   - `render_markdown(stats, parsed, graph, changed_files)` → string
   - `main()` orchestration with `--force` and `--trigger-file` handling
2. Write `skills/python-codemap/SKILL.md`
3. Write `skills/python-codemap/.install-notes`
4. Manual verify: run against repo, inspect output, re-run idempotency

## Implementation Notes

- Use `pathlib.Path` throughout
- Resolve local imports: for `from foo import bar`, look for `foo.py` or `foo/__init__.py` relative to source file's dir, then walk up
- Skip files > 500KB by checking `path.stat().st_size`
- Hash cache key: relative path from root; value: md5 hex
