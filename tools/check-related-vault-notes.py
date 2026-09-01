#!/usr/bin/env python3
"""
Surface pre-existing hand-authored vault notes that mention terms from a just-completed task,
so they can be checked for staleness before an Obsidian-sync gate is declared done.

Companion to verify-vault-memory-nodes.py, not a replacement: that script proves the AUTO-
GENERATED Canonical ADR/Risk node layer is internally consistent (813/813 checks passing as of
2026-08-27). This script covers the population that layer does NOT touch — hand-authored notes
(workflow docs, the Function/SQL/Traceability indexes, mindmaps, the Testing/Change-Management
notes, the Current State Dashboard) that can silently go stale when new work lands, with nothing
that currently checks them. Built after a real miss: an identical `PIS.BypassLogin` blocker sat
open, unclosed, in `14 - Testing/Backend Deployment Readiness.md` for 2 days across two sessions,
found only by accident (2026-08-27, ADR-123/SKL-055).

Read-only. Reuses the generator's own VAULT_MYPS/ADR_OUT/RISK_OUT constants so this can never
silently point at a different vault root than the generator does.

Usage:
    python check-related-vault-notes.py <keyword> [<keyword> ...]

Exit code is always 0 -- this is a discovery tool, not a pass/fail gate. A non-empty result means
a human/agent must review each hit for genuine staleness (see the Standing Task-Execution
Protocol's Obsidian-sync step) -- a note correctly describing history is not automatically stale.
"""

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import importlib.util
spec = importlib.util.spec_from_file_location("gen", Path(__file__).parent / "generate-vault-memory-nodes.py")
gen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gen)

VAULT_MYPS = gen.VAULT_MYPS
EXCLUDED_DIRS = {gen.ADR_OUT.resolve(), gen.RISK_OUT.resolve()}


def scannable_files():
    for path in sorted(VAULT_MYPS.rglob("*.md")):
        if any(excluded in path.resolve().parents for excluded in EXCLUDED_DIRS):
            continue
        yield path


def main():
    keywords = sys.argv[1:]
    if not keywords:
        print("Usage: check-related-vault-notes.py <keyword> [<keyword> ...]")
        print("Pass the ADR/RISK/feature terms from the task you just completed -- table names,")
        print("controller/function names, error messages, config keys.")
        sys.exit(0)

    patterns = [(kw, re.compile(re.escape(kw), re.IGNORECASE)) for kw in keywords]
    total_hits = 0

    for path in scannable_files():
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        lines = text.splitlines()
        file_hits = []
        for lineno, line in enumerate(lines, start=1):
            for kw, pat in patterns:
                if pat.search(line):
                    file_hits.append((lineno, kw, line.strip()))
        if file_hits:
            total_hits += len(file_hits)
            rel = path.relative_to(VAULT_MYPS.parent)
            print(f"\n{rel}")
            for lineno, kw, line in file_hits:
                print(f"  {lineno}: [{kw}] {line}")

    print(f"\n{total_hits} match(es) across the hand-authored vault population "
          f"(auto-generated Canonical ADR/Risk nodes excluded -- see verify-vault-memory-nodes.py).")
    if total_hits:
        print("Review each hit: update if stale, or note reviewed-and-not-stale in the final response.")
    sys.exit(0)


if __name__ == "__main__":
    main()
