#!/usr/bin/env python3
"""
Verify the ADR-111 generated vault-node layer (Phase 2 of the memory-architecture plan).

Read-only. Imports the generator's own parsing so this can never silently drift from what
generate-vault-memory-nodes.py actually produces.

Checks:
  1. Node coverage — every canonical ADR/RISK/ASS heading has a generated node file.
  2. No orphaned generated nodes — every generated file still traces to a live heading
     (catches a lane-file entry that was deleted/renamed after the last generation).
  3. Every [[wikilink]] inside the generated folders resolves within the vault.
  4. Every [[wikilink]] to a "Canonical " node from OUTSIDE the generated folders (mindmaps,
     START HERE, hand-authored notes) also resolves — this is what a hand-typed link like the
     Database Mindmap's RISK-090/091 references must pass; a title-truncation mismatch here is
     exactly the class of bug this check exists to catch.
  5. The two Index notes are internally consistent with the folders they index.

Exit 0 / all checks pass. Exit 1 / print FAILURES otherwise.
"""

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from importlib import import_module
gen = import_module("generate-vault-memory-nodes".replace("-", "_")) if False else None
# The generator's filename has hyphens, which aren't a valid module name -- load it by path.
import importlib.util
spec = importlib.util.spec_from_file_location("gen", Path(__file__).parent / "generate-vault-memory-nodes.py")
gen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gen)

VAULT_ROOT = gen.VAULT_MYPS.parent  # Obsidian's real root is the parent of MYPS/

checks = 0
failures = []


def check(cond, msg):
    global checks
    checks += 1
    print(("PASS: " if cond else "FAIL: ") + msg)
    if not cond:
        failures.append(msg)


def all_vault_files():
    return {p.name for p in VAULT_ROOT.rglob("*.md")}


def resolve_link(target: str, all_files: set) -> bool:
    if "../" in target:
        return False
    base = target.rsplit("/", 1)[-1]
    return (
        (VAULT_ROOT / f"{target}.md").exists()
        or f"{base}.md" in all_files
        or base in all_files
    )


def main():
    specs = (
        ("ADR", gen.ADR_OUT, "decisions.md"),
        ("RISK", gen.RISK_OUT, "risks.md"),
        ("ASS", gen.RISK_OUT, "risks.md"),
    )

    all_files = all_vault_files()

    # 1 & 2: coverage both directions.
    for prefix, outdir, lane in specs:
        entries, _dropped = gen.dedupe(gen.parse_entries(gen.LANE_DIR / lane, prefix))
        expected = {gen.node_filename(eid, title) for eid, title, _b in entries}
        on_disk = {p.name for p in outdir.glob(f"{prefix}-*.md")} if outdir.exists() else set()
        missing = expected - on_disk
        orphans = on_disk - expected
        check(not missing, f"{prefix}: node coverage complete ({len(expected)} canonical, {len(missing)} missing)")
        if missing:
            for m in sorted(missing)[:10]:
                print(f"    missing: {m}")
        check(not orphans, f"{prefix}: no orphaned generated nodes ({len(orphans)} found)")
        if orphans:
            for o in sorted(orphans)[:10]:
                print(f"    orphan: {o}")

    # 3: links inside generated notes resolve.
    for _prefix, outdir, _lane in specs:
        if not outdir.exists():
            continue
        for f in sorted(outdir.glob("*.md")):
            text = f.read_text(encoding="utf-8", errors="replace")
            for m in re.finditer(r"\[\[([^\]|]+)(\|[^\]]+)?\]\]", text):
                target = m.group(1).strip()
                check(resolve_link(target, all_files),
                      f"generated link resolves: [[{target}]] (in {f.name})")

    # 4: hand-typed links FROM outside the generated layer TO a "Canonical " node resolve.
    # This is the exact bug class caught live: a hand-typed link using a longer title than
    # the generator's truncated filename.
    generated_dirs = {gen.ADR_OUT.resolve(), gen.RISK_OUT.resolve()}
    for f in VAULT_ROOT.rglob("*.md"):
        if f.resolve().parent in generated_dirs:
            continue
        text = f.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(r"\[\[([^\]|]+)(\|[^\]]+)?\]\]", text):
            target = m.group(1).strip()
            if "Canonical ADRs/" in target or "Canonical Risks/" in target:
                check(resolve_link(target, all_files),
                      f"hand-authored link to generated node resolves: [[{target}]] (in {f.relative_to(VAULT_ROOT)})")

    # 5: index notes list exactly the entries on disk.
    for prefix, outdir, _lane in specs:
        if prefix == "ASS":
            continue
        label = "ADR" if prefix == "ADR" else "Risk"
        idx = outdir / f"Canonical {label} Index.md"
        if not idx.exists():
            check(False, f"{label} index exists: {idx}")
            continue
        idx_text = idx.read_text(encoding="utf-8", errors="replace")
        # Scope to table rows only ('| [[...ID...]] | state | title |'). The ADR index also
        # deliberately warns about the SEPARATE ADR-0001..0003 vault namespace in prose above
        # the table -- scanning the whole document double-counted that warning as if it were
        # a table entry.
        table_rows = [ln for ln in idx_text.splitlines() if ln.startswith("| [[")]
        idx_ids = set()
        for ln in table_rows:
            idx_ids.update(re.findall(rf"\b{prefix}-\d+[a-z]?\b", ln))
        disk_ids = {p.stem.split(" ", 1)[0] for p in outdir.glob(f"{prefix}-*.md")}
        check(idx_ids == disk_ids, f"{label} index lists exactly the {len(disk_ids)} nodes on disk")

    print(f"\n{checks - len(failures)} / {checks} checks passed")
    if failures:
        print("\nFAILURES:")
        for f in failures:
            print(f"  - {f}")
    else:
        print("All checks passed.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
