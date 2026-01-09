#!/usr/bin/env python3
"""
Update GitHub OIDC subject patterns when a GitHub repo is renamed.

Replaces:
  repo:OLD_OWNER/OLD_REPO:
with:
  repo:NEW_OWNER/NEW_REPO:

Across common text files (Terraform, YAML, Markdown, JSON).

Usage:
  python3 tools/repo-rename/update_oidc_subjects.py \
    --old-full JamesIOmete/multicloud-sa-toolkit \
    --new-full <OWNER>/<NEW_REPO> \
    --apply
"""

from __future__ import annotations
import argparse
from pathlib import Path

TEXT_EXTS = {
    ".tf", ".tfvars", ".hcl",
    ".yml", ".yaml",
    ".md",
    ".json",
    ".txt",
    ".sh",
}

SKIP_DIRS = {
    ".git",
    ".terraform",
    "node_modules",
    ".venv",
    "venv",
    "__pycache__",
}

SKIP_FILES = {
    "terraform.tfstate",
    "terraform.tfstate.backup",
}

def iter_files(root: Path):
    for p in root.rglob("*"):
        if p.is_dir():
            # prune skip dirs
            if p.name in SKIP_DIRS:
                # prevent descending
                # rglob doesn't allow pruning easily; just skip by continuing
                continue
        if not p.is_file():
            continue
        if p.name in SKIP_FILES:
            continue
        if p.suffix.lower() not in TEXT_EXTS:
            continue
        # skip anything inside skip dirs
        if any(part in SKIP_DIRS for part in p.parts):
            continue
        yield p

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--old-full", required=True, help="e.g. JamesIOmete/old-repo")
    ap.add_argument("--new-full", required=True, help="e.g. JamesIOmete/new-repo")
    ap.add_argument("--apply", action="store_true", help="Write changes (otherwise dry-run)")
    args = ap.parse_args()

    old_token = f"repo:{args.old_full}:"
    new_token = f"repo:{args.new_full}:"

    root = Path(".").resolve()
    changed = []

    for f in iter_files(root):
        try:
            text = f.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            # skip non-utf8
            continue

        if old_token not in text:
            continue

        new_text = text.replace(old_token, new_token)

        changed.append(f)

        if args.apply:
            f.write_text(new_text, encoding="utf-8")

    if not changed:
        print("No files contained:", old_token)
        return

    print(("UPDATED" if args.apply else "WOULD UPDATE") + f" {len(changed)} file(s):")
    for f in changed:
        print(" -", f)

    if not args.apply:
        print("\nDry-run only. Re-run with --apply to write changes.")

if __name__ == "__main__":
    main()
