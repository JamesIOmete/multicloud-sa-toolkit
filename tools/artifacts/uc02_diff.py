#!/usr/bin/env python3
"""
UC02 artifact diff.

Compares two normalized UC02 inventories (out/artifacts/inventory.json) and
produces a human-readable SUMMARY_DIFF.md.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Tuple


def utc_now_rfc3339() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def read_json(p: Path) -> Dict[str, Any]:
    return json.loads(p.read_text(encoding="utf-8"))


def write_text(p: Path, s: str) -> None:
    p.write_text(s.rstrip() + "\n", encoding="utf-8")


def get_in(d: Dict[str, Any], path: Tuple[str, ...], default: Any) -> Any:
    cur: Any = d
    for k in path:
        if not isinstance(cur, dict) or k not in cur:
            return default
        cur = cur[k]
    return cur


def flatten_counts(inv: Dict[str, Any]) -> Dict[str, int]:
    out: Dict[str, int] = {}
    counts = inv.get("counts", {})
    if not isinstance(counts, dict):
        return out
    for group, vals in counts.items():
        if not isinstance(vals, dict):
            continue
        for k, v in vals.items():
            if isinstance(v, bool):
                continue
            if isinstance(v, int):
                out[f"{group}.{k}"] = v
    return out


def fmt_delta(delta: int) -> str:
    if delta > 0:
        return f"+{delta}"
    return str(delta)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--old", required=True, help="Path to old normalized inventory.json")
    ap.add_argument("--new", required=True, help="Path to new normalized inventory.json")
    ap.add_argument("--out", default="SUMMARY_DIFF.md", help="Output Markdown path")
    args = ap.parse_args()

    old_path = Path(args.old).resolve()
    new_path = Path(args.new).resolve()
    out_path = Path(args.out).resolve()

    old = read_json(old_path)
    new = read_json(new_path)

    old_scope = old.get("scope", {}) if isinstance(old.get("scope"), dict) else {}
    new_scope = new.get("scope", {}) if isinstance(new.get("scope"), dict) else {}
    cloud = (new_scope.get("cloud") or old_scope.get("cloud") or "unknown").upper()

    old_gen = get_in(old, ("meta", "generated_at"), "unknown")
    new_gen = get_in(new, ("meta", "generated_at"), "unknown")

    old_counts = flatten_counts(old)
    new_counts = flatten_counts(new)
    keys = sorted(set(old_counts.keys()) | set(new_counts.keys()))

    changed = []
    for k in keys:
        o = old_counts.get(k, 0)
        n = new_counts.get(k, 0)
        if o != n:
            changed.append((k, o, n, n - o))

    # Keep output compact and SA-friendly.
    lines = []
    lines.append(f"# UC02 Artifact Diff ({cloud})")
    lines.append("")
    lines.append(f"- Generated: `{utc_now_rfc3339()}`")
    lines.append(f"- Old inventory: `{old_path}` (generated `{old_gen}`)")
    lines.append(f"- New inventory: `{new_path}` (generated `{new_gen}`)")
    lines.append("")

    # Scope changes (helpful when users accidentally compare the wrong environment).
    scope_keys = sorted(set(old_scope.keys()) | set(new_scope.keys()))
    scope_changes = []
    for k in scope_keys:
        if old_scope.get(k) != new_scope.get(k):
            scope_changes.append((k, old_scope.get(k), new_scope.get(k)))

    if scope_changes:
        lines.append("## Scope Changes")
        for k, o, n in scope_changes:
            lines.append(f"- `{k}`: `{o}` -> `{n}`")
        lines.append("")

    if not changed:
        lines.append("## Summary")
        lines.append("- No count deltas detected.")
        write_text(out_path, "\n".join(lines))
        return

    lines.append("## Count Deltas")
    # Render as a simple list (no nested bullets).
    for k, o, n, d in changed:
        lines.append(f"- `{k}`: {o} -> {n} ({fmt_delta(d)})")
    lines.append("")

    # Provide a small "top movers" view to focus attention.
    top = sorted(changed, key=lambda x: abs(x[3]), reverse=True)[:10]
    lines.append("## Top Movers")
    for k, o, n, d in top:
        lines.append(f"- `{k}`: {o} -> {n} ({fmt_delta(d)})")
    lines.append("")

    write_text(out_path, "\n".join(lines))


if __name__ == "__main__":
    main()

