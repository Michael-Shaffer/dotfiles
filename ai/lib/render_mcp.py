#!/usr/bin/env python3
"""Render ai/mcp/servers.json into an MCP client's config file.

Called by ai/render.sh; not usually run by hand.

Two things make this more than a copy:

  * The client configs hold machine state next to the server list. Claude
    Desktop keeps `preferences` (account ids, trusted folders, window layout)
    in the same file, and ~/.claude.json is mostly session history. So this
    merges into the `mcpServers` key and leaves every other key untouched.

  * Placeholders are substituted after the template is parsed, not before, so
    a Windows path like C:\\Users\\me survives: json.dump re-escapes the
    backslashes. Text substitution would emit invalid JSON.

Unset placeholders are an error. envsubst would quietly write an empty string
and hand you a config that fails at launch with no explanation.
"""

from __future__ import annotations

import argparse
import difflib
import json
import os
import re
import shutil
import sys
import time
from pathlib import Path

PLACEHOLDER = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}")


def die(msg: str) -> None:
    print(f"render_mcp: {msg}", file=sys.stderr)
    sys.exit(1)


# --------------------------------------------------------------------------
# Placeholder substitution
# --------------------------------------------------------------------------

def to_windows_path(value: str) -> str:
    """Normalise a path for a config that a Windows application will read.

        /mnt/c/Users/me -> C:\\Users\\me      (WSL)
        /c/Users/me     -> C:\\Users\\me      (Git Bash)
        C:/Users/me     -> C:\\Users\\me      (separator fix)

    The third case is not redundant. MSYS rewrites POSIX-looking environment
    variables into `C:/...` form before handing them to a native Windows
    Python, so by the time we see them the drive prefix is already gone but
    the separators are still wrong.

    Anything that is not a recognisable drive path is returned unchanged.
    """
    m = re.match(r"^/(?:mnt/)?([a-zA-Z])(/.*)?$", value)
    if m:
        drive, rest = m.group(1).upper(), m.group(2) or "/"
        return f"{drive}:" + rest.replace("/", "\\")

    m = re.match(r"^([a-zA-Z]):[\\/](.*)$", value, re.DOTALL)
    if m:
        drive, rest = m.group(1).upper(), m.group(2)
        return f"{drive}:\\" + rest.replace("/", "\\")

    return value


def substitute(node, env: dict[str, str], missing: set[str], winpaths: bool):
    """Walk the parsed template, expanding ${VAR} in every string."""
    if isinstance(node, dict):
        return {
            k: substitute(v, env, missing, winpaths)
            for k, v in node.items()
            if not k.startswith("//")  # drop the doc comments
        }
    if isinstance(node, list):
        return [substitute(v, env, missing, winpaths) for v in node]
    if not isinstance(node, str):
        return node

    def repl(m: re.Match) -> str:
        name = m.group(1)
        if name not in env or env[name] == "":
            missing.add(name)
            return m.group(0)
        return env[name]

    out = PLACEHOLDER.sub(repl, node)
    if winpaths and out != node:
        # Only convert values we actually substituted, so literal args in the
        # template ("run", "--frozen") are never touched.
        out = to_windows_path(out)
    return out


# --------------------------------------------------------------------------
# Merge
# --------------------------------------------------------------------------

def load_json(path: Path):
    if not path.exists() or path.stat().st_size == 0:
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        die(f"{path} is not valid JSON ({e}); refusing to overwrite it")


def merge(target: dict, rendered: dict, prune: bool) -> dict:
    """Set our servers in target['mcpServers']; leave all other keys alone."""
    out = dict(target)
    managed = rendered.get("mcpServers", {})
    existing = dict(out.get("mcpServers", {}))

    if prune:
        kept = {}
    else:
        kept = {k: v for k, v in existing.items() if k not in managed}

    out["mcpServers"] = {**kept, **managed}
    return out


def write_atomic(path: Path, data: dict, backup: bool) -> Path | None:
    path.parent.mkdir(parents=True, exist_ok=True)
    bak = None
    if backup and path.exists():
        bak = path.with_suffix(path.suffix + f".bak.{time.strftime('%Y%m%d-%H%M%S')}")
        shutil.copy2(path, bak)

    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    os.replace(tmp, path)
    return bak


# --------------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--template", required=True, type=Path)
    ap.add_argument("--target", required=True, type=Path)
    ap.add_argument("--windows-paths", action="store_true",
                    help="convert POSIX paths to Windows form (Windows-side target under WSL)")
    ap.add_argument("--prune", action="store_true",
                    help="drop servers in the target that this repo does not define")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--no-backup", action="store_true")
    args = ap.parse_args()

    if not args.template.exists():
        die(f"template not found: {args.template}")

    template = load_json(args.template)
    missing: set[str] = set()
    rendered = substitute(template, dict(os.environ), missing, args.windows_paths)

    if missing:
        names = ", ".join(sorted(missing))
        die(
            f"unset placeholder(s): {names}\n"
            f"  define them in ~/.config/dotfiles/mcp.env "
            f"(start from ai/mcp/mcp.env.example)"
        )

    if not rendered.get("mcpServers"):
        die("template defines no mcpServers")

    current = load_json(args.target)
    if not isinstance(current, dict):
        die(f"{args.target} is not a JSON object")

    merged = merge(current, rendered, args.prune)

    before = json.dumps(current, indent=2, sort_keys=True).splitlines()
    after = json.dumps(merged, indent=2, sort_keys=True).splitlines()
    if before == after:
        print(f"  = {args.target} (already up to date)")
        return 0

    if args.dry_run:
        print(f"  ~ {args.target} (dry run)")
        diff = difflib.unified_diff(
            before, after, fromfile="current", tofile="rendered", lineterm=""
        )
        for line in diff:
            print(f"    {line}")
        return 0

    bak = write_atomic(args.target, merged, backup=not args.no_backup)
    names = ", ".join(sorted(rendered["mcpServers"]))
    print(f"  ~ wrote {args.target}  [{names}]")
    if bak:
        print(f"    backup: {bak.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
