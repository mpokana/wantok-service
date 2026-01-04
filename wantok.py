#!/usr/bin/env python3
# Wantok INI CLI (MVP)
# Language: Python

import configparser
import fnmatch
import hashlib
import os
import json
from pathlib import Path
from typing import Dict, List, Tuple

CONFIG_FILE = "wantok.ini"

def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def parse_multiline_list(value: str) -> List[str]:
    # ConfigParser collapses multiline; we store each glob on its own line with indentation
    lines = [ln.strip() for ln in value.splitlines() if ln.strip()]
    return lines

def matches_any(path_str: str, patterns: List[str]) -> bool:
    return any(fnmatch.fnmatch(path_str, p) for p in patterns)

def collect_files(repo_root: Path, includes: List[str], excludes: List[str], max_kb: int) -> List[Path]:
    results = []
    for root, dirs, files in os.walk(repo_root):
        # Skip excluded dirs quickly
        root_rel = str(Path(root).relative_to(repo_root)).replace("\\", "/")
        if root_rel == ".":
            root_rel = ""
        # If any exclude pattern matches the directory prefix, skip
        # (simple heuristic; still fine for MVP)
        if root_rel and matches_any(root_rel + "/", excludes):
            dirs[:] = []
            continue

        for name in files:
            p = Path(root) / name
            rel = str(p.relative_to(repo_root)).replace("\\", "/")

            if excludes and matches_any(rel, excludes):
                continue
            if includes and not matches_any(rel, includes):
                continue

            try:
                size_kb = p.stat().st_size // 1024
            except OSError:
                continue

            if size_kb > max_kb:
                continue

            results.append(p)

    return results

def load_snapshot(snapshot_path: Path) -> Dict[str, str]:
    if snapshot_path.exists():
        return json.loads(snapshot_path.read_text(encoding="utf-8"))
    return {}

def save_snapshot(snapshot_path: Path, data: Dict[str, str]) -> None:
    snapshot_path.parent.mkdir(parents=True, exist_ok=True)
    snapshot_path.write_text(json.dumps(data, indent=2), encoding="utf-8")

def main() -> None:
    repo_root = Path(".").resolve()
    cfg_path = repo_root / CONFIG_FILE
    if not cfg_path.exists():
        raise SystemExit(f"Missing {CONFIG_FILE} in {repo_root}")

    cp = configparser.ConfigParser()
    cp.read(cfg_path, encoding="utf-8")

    includes = parse_multiline_list(cp.get("context", "include_globs", fallback=""))
    excludes = parse_multiline_list(cp.get("context", "exclude_globs", fallback=""))
    max_kb = cp.getint("context", "max_file_size_kb", fallback=512)

    snapshot_dir = Path(cp.get("memory", "snapshot_dir", fallback=".wantok/snapshots"))
    snapshot_path = repo_root / snapshot_dir / "snapshot.json"

    files = collect_files(repo_root, includes, excludes, max_kb)
    old = load_snapshot(snapshot_path)

    new: Dict[str, str] = {}
    changed: List[str] = []
    added: List[str] = []
    removed: List[str] = []

    for p in files:
        rel = str(p.relative_to(repo_root)).replace("\\", "/")
        digest = sha256_file(p)
        new[rel] = digest
        if rel not in old:
            added.append(rel)
        elif old[rel] != digest:
            changed.append(rel)

    for rel in old.keys():
        if rel not in new:
            removed.append(rel)

    save_snapshot(snapshot_path, new)

    print("Wantok INI — Project scan complete")
    print(f"Files tracked: {len(files)}")
    if added:
        print("\nAdded:")
        for x in added[:50]:
            print(f"  + {x}")
        if len(added) > 50:
            print(f"  ... {len(added)-50} more")
    if changed:
        print("\nChanged:")
        for x in changed[:50]:
            print(f"  ~ {x}")
        if len(changed) > 50:
            print(f"  ... {len(changed)-50} more")
    if removed:
        print("\nRemoved:")
        for x in removed[:50]:
            print(f"  - {x}")
        if len(removed) > 50:
            print(f"  ... {len(removed)-50} more")

if __name__ == "__main__":
    main()
