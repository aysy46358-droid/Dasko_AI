#!/usr/bin/env python3
"""Generate or validate the tracked-file inventory in docs/PROJECT_MAP.md."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path

BEGIN_MARKER = "<!-- BEGIN AUTO-GENERATED FILE INVENTORY -->"
END_MARKER = "<!-- END AUTO-GENERATED FILE INVENTORY -->"
DEFAULT_DOCUMENT = Path("docs/PROJECT_MAP.md")


def tracked_paths(repository_root: Path) -> list[str]:
    """Return paths in the Git index, sorted deterministically as bytes."""
    result = subprocess.run(
        ["git", "ls-files", "--cached", "-z"],
        cwd=repository_root,
        check=True,
        stdout=subprocess.PIPE,
    )
    paths = [os.fsdecode(path) for path in result.stdout.split(b"\0") if path]
    return sorted(set(paths), key=os.fsencode)


def markdown_code_span(value: str) -> str:
    """Render a path as a Markdown code span without breaking on backticks."""
    safe_value = value.replace("\r", "\\r").replace("\n", "\\n")
    longest_run = max((len(run) for run in safe_value.split(" ") if "`" in run), default=0)
    delimiter = "`" * (longest_run + 1)
    padding = " " if safe_value.startswith(("`", " ")) or safe_value.endswith(("`", " ")) else ""
    return f"{delimiter}{padding}{safe_value}{padding}{delimiter}"


def render_inventory(paths: list[str]) -> str:
    """Return a stable Markdown list for the supplied Git paths."""
    ordered_paths = sorted(set(paths), key=os.fsencode)
    if not ordered_paths:
        return "_لا توجد ملفات متتبعة في فهرس Git._"
    return "\n".join(f"- {markdown_code_span(path)}" for path in ordered_paths)


def replace_generated_block(document: str, generated: str) -> str:
    """Replace exactly one generated region while preserving surrounding prose."""
    begin_count = document.count(BEGIN_MARKER)
    end_count = document.count(END_MARKER)
    if begin_count != 1 or end_count != 1:
        raise ValueError("Expected exactly one begin marker and one end marker.")

    begin = document.index(BEGIN_MARKER) + len(BEGIN_MARKER)
    end = document.index(END_MARKER)
    if end < begin:
        raise ValueError("Generated block markers are in the wrong order.")

    return document[:begin] + "\n" + generated + "\n" + document[end:]


def write_atomically(path: Path, content: str) -> None:
    """Write a UTF-8 document through a temporary file in the same directory."""
    path.parent.mkdir(parents=True, exist_ok=True)
    temp_name: str | None = None
    try:
        with tempfile.NamedTemporaryFile(
            "w", encoding="utf-8", newline="\n", dir=path.parent, delete=False
        ) as temp_file:
            temp_name = temp_file.name
            temp_file.write(content)
        os.replace(temp_name, path)
    finally:
        if temp_name and os.path.exists(temp_name):
            os.unlink(temp_name)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate or check the Git-tracked file inventory in the project map."
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true", help="update the generated block")
    mode.add_argument("--check", action="store_true", help="check without writing")
    parser.add_argument(
        "--document",
        type=Path,
        default=DEFAULT_DOCUMENT,
        help=f"map document path (default: {DEFAULT_DOCUMENT})",
    )
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    document_path = args.document if args.document.is_absolute() else root / args.document
    try:
        current = document_path.read_text(encoding="utf-8")
        desired = replace_generated_block(current, render_inventory(tracked_paths(root)))
    except (OSError, subprocess.CalledProcessError, ValueError) as error:
        print(f"Project map check could not run: {error}", file=sys.stderr)
        return 2

    if args.write:
        if desired != current:
            write_atomically(document_path, desired)
            print(f"Updated generated inventory in {document_path.relative_to(root)}.")
        else:
            print("Project map inventory is already current.")
        return 0

    if desired != current:
        print(
            "Project map inventory is stale. Stage added/removed files, then run "
            "`python3 tooling/project_map.py --write` and review the diff.",
            file=sys.stderr,
        )
        return 1

    print("Project map inventory matches the Git index.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
