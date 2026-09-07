#!/usr/bin/env python3
"""
Generate one Obsidian vault note per canonical memory entry (ADR-/RISK-/ASS-).

ADR-111, Phase 2. The vault becomes the navigable full-memory surface; the lane files stay
the store. This generator is the one-directional bridge: canonical -> vault, never the reverse.

WHY one-directional: two hand-maintained surfaces drift (SKL-044, and this engagement's own
history). Generated nodes cannot drift -- a difference becomes a mechanical diff, not a
judgement call. Never hand-edit a generated node; edit the lane file and re-run.

READ-ONLY on canonical memory. Writes ONLY inside the vault's MYPS folder, and only into the
two generated subfolders. Never touches the vault's own hand-authored ADR-0001..0003 (4-digit,
a deliberately separate namespace) or any other note.

Usage:
    python tools/generate-vault-memory-nodes.py [--dry-run]
"""

import argparse
import re
import sys
from datetime import date
from pathlib import Path

WORKSPACE = Path(r"c:\Users\Msi\Desktop\LLM\Employee-System-Analyst-Expert")
LANE_DIR = WORKSPACE / "memory" / "clients" / "myps" / "myps-system"
VAULT_MYPS = Path(r"C:\Users\Msi\Desktop\LLM\Obsidian\MYPS_Obsidian_Vault\MYPS")

# Generated nodes live in their own subfolders so they are never confused with, and can never
# overwrite, the vault's hand-authored notes (notably ADR-0001..0003 in the parent folder).
ADR_OUT = VAULT_MYPS / "16 - Technical Decisions" / "Canonical ADRs"
RISK_OUT = VAULT_MYPS / "17 - Risks & Technical Debt" / "Canonical Risks"

TODAY = date.today().isoformat()

# Windows-forbidden filename chars, plus the ones Obsidian treats specially in links.
BAD_CHARS = re.compile(r'[\\*?"<>|\[\]#^]')
# Status emoji belong in the note body, not in a filename that links must match exactly.
EMOJI = re.compile("[\U0001F300-\U0001FAFF☀-➿⬀-⯿️]")


def slug(text: str, max_len: int = 60) -> str:
    """Filename-safe, link-safe short title."""
    text = EMOJI.sub("", text)
    text = text.replace(":", " -").replace("/", "-")  # keep meaning; ':' '/' are path-illegal
    text = BAD_CHARS.sub("", text)
    text = re.sub(r"\s+", " ", text).strip(" .-")
    if len(text) > max_len:
        cut = text[:max_len].rsplit(" ", 1)[0]
        text = cut if len(cut) > max_len * 0.6 else text[:max_len]
    return text.strip(" .-")


def strip_md(text: str) -> str:
    """Flatten inline markdown so YAML/summaries stay clean."""
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)
    text = re.sub(r"`(.+?)`", r"\1", text)
    return re.sub(r"\s+", " ", text).strip()


def parse_entries(path: Path, prefix: str):
    """Split a lane file into (id, raw_title, body) per '## <PREFIX>-NNN ...' heading."""
    if not path.exists():
        print(f"  !! missing lane file: {path}", file=sys.stderr)
        return []
    text = path.read_text(encoding="utf-8", errors="replace")
    pattern = re.compile(rf"^## ({prefix}-\d+[a-z]?)\s*(?:—|-|–)?\s*(.*)$", re.M)
    hits = list(pattern.finditer(text))
    out = []
    for i, m in enumerate(hits):
        end = hits[i + 1].start() if i + 1 < len(hits) else len(text)
        out.append((m.group(1), m.group(2).strip(), text[m.end():end].strip()))
    return out


STATUS_MAP = [
    ("\U0001F534", "open-critical"), ("\U0001F7E1", "open"), ("\U0001F7E2", "resolved"),
    ("\u2705", "resolved"), ("\u2B1C", "moot"), ("\u23F8", "on-hold"),
]


def detect_state(title: str, body: str) -> str:
    blob = title + " " + body[:400]
    for emoji, state in STATUS_MAP:
        if emoji in title:
            return state
    low = blob.lower()
    for kw, state in (("resolved", "resolved"), ("superseded", "superseded"),
                      ("mitigated", "mitigated"), ("moot", "moot"), ("open", "open")):
        if kw in low:
            return state
    return "unknown"


def find_refs(text: str, prefix: str, exclude: str):
    ids = sorted(set(re.findall(rf"\b{prefix}-\d+[a-z]?\b", text)))
    return [i for i in ids if i != exclude]


def summarize(body: str, limit: int = 700) -> str:
    """First substantive prose from the entry -- skips tables, quotes, blank lines, and
    standalone label lines ('Resolution summary:'), which otherwise ended the summary before
    it began."""
    parts = []
    for line in body.splitlines():
        s = line.strip()
        if not s or s.startswith(("|", ">", "#", "---", "```")):
            if parts:
                break
            continue
        bare = strip_md(s)
        if bare.endswith(":") and len(bare) < 60:   # a label, not content
            continue
        parts.append(s)
        if sum(len(p) for p in parts) > limit:
            break
    out = strip_md(" ".join(parts))
    return (out[:limit].rsplit(" ", 1)[0] + " …") if len(out) > limit else out


def node_filename(eid, title):
    s = slug(strip_md(title))
    return f"{eid} - {s}.md" if s else f"{eid}.md"


def link_to(eid, linkmap):
    """Wikilink to a generated node. MUST use the real filename -- linking to the bare ID
    produces an unresolved link, because every node filename carries its title."""
    entry = linkmap.get(eid)
    if not entry:
        return None
    sub, folder, name = entry
    return f"[[MYPS/{sub}/{folder}/{name[:-3]}|{eid}]]"


def build_note(eid, title, body, kind, lane_file, linkmap):
    clean_title = strip_md(title)
    state = detect_state(title, body)
    adr_refs = find_refs(title + body, "ADR", eid)
    risk_refs = find_refs(title + body, "RISK", eid)
    authority = "memory-adr" if kind == "adr" else "memory-risk"
    node_type = "adr" if kind == "adr" else "risk"

    fm = [
        "---",
        "client: MYPS",
        f"type: {node_type}",
        "status: current",
        f"{'decision' if kind == 'adr' else 'risk'}-state: {state}",
        "confidence: high",
        f"source-authority: {authority}",
        f"last-verified: {TODAY}",
        "generated: true",
        f"canonical-source: {lane_file}",
        f"related-adr: [{', '.join(adr_refs[:12])}]",
        f"related-risk: [{', '.join(risk_refs[:12])}]",
        f"tags: [client/myps, {node_type}, generated]",
        "---",
        "",
        f"# {eid} — {clean_title}",
        "",
        "> [!info] Generated node — do not hand-edit",
        f"> Generated {TODAY} from `myps-system/{lane_file}`, which remains the authority and holds",
        f"> the full entry. Edit the lane file and re-run `tools/generate-vault-memory-nodes.py`;",
        "> edits made here are overwritten and do not reach canonical memory.",
        "",
        "## Summary",
        "",
        summarize(body) or "_(no prose summary extractable — see the canonical entry.)_",
        "",
    ]
    links, unresolved = [], []
    for r in adr_refs[:12] + risk_refs[:12]:
        lk = link_to(r, linkmap)
        (links if lk else unresolved).append(lk or r)
    if links or unresolved:
        fm += ["## Related", ""]
        fm += [f"- {lk}" for lk in links]
        if unresolved:
            # Referenced but has no entry of its own in the lane file (e.g. RISK-001..059,
            # cited in prose but never given a '## ' heading). Naming them honestly beats
            # emitting a link that silently resolves to nothing.
            fm.append(f"- _Referenced without a canonical entry: {', '.join(unresolved)}_")
        fm.append("")
    fm += ["## Canonical entry", "",
           f"Full text: `memory/clients/myps/myps-system/{lane_file}` → `## {eid}`", ""]
    return "\n".join(fm)


def dedupe(entries):
    """An ID can legitimately appear twice: the lane files keep a superseded original beneath its
    resolution ('## RISK-069 (original entry, superseded by the resolution above)'). These files
    are newest-first, so the FIRST occurrence is the current one. Taking the last would publish
    the superseded text as if it were current -- caught live on RISK-069."""
    seen, out, dropped = set(), [], []
    for eid, title, body in entries:
        if eid in seen:
            dropped.append(eid)
            continue
        seen.add(eid)
        out.append((eid, title, body))
    return out, dropped


def emit(entries, outdir, kind, lane_file, dry, linkmap):
    outdir.mkdir(parents=True, exist_ok=True)
    written, index = 0, []
    for eid, title, body in entries:
        name = node_filename(eid, title)
        target = outdir / name
        content = build_note(eid, title, body, kind, lane_file, linkmap)
        index.append((eid, name, detect_state(title, body), strip_md(title)))
        if not dry:
            # Stable-name guard: an earlier run may have used a different title slug.
            for old in outdir.glob(f"{eid} - *.md"):
                if old.name != name:
                    old.unlink()
            target.write_text(content, encoding="utf-8")
        written += 1
    return written, index


def write_index(index, outdir, kind, dry):
    label = "ADR" if kind == "adr" else "Risk"
    rows = ["---", "client: MYPS", "type: index", "status: current",
            "confidence: high",
            f"source-authority: {'memory-adr' if kind == 'adr' else 'memory-risk'}",
            f"last-verified: {TODAY}", "generated: true",
            f"tags: [client/myps, {'adr' if kind == 'adr' else 'risk'}, index, generated]",
            "---", "", f"# Canonical {label} Index", "",
            f"All {len(index)} canonical {label} entries, generated {TODAY}. "
            f"The lane file remains the authority.", ""]
    if kind == "adr":
        rows += ["> [!warning] Two ADR namespaces exist",
                 "> These are the engagement-wide canonical ADRs (`ADR-094`, 3-digit, unpadded).",
                 "> The vault also has its own `ADR-0001`–`ADR-0003` (4-digit, zero-padded,",
                 "> Revision-domain only) in the parent folder. They are different systems —",
                 "> always name which one you mean.", ""]
    rows += ["| ID | State | Title |", "|---|---|---|"]
    folder = "Canonical ADRs" if kind == "adr" else "Canonical Risks"
    sub = "16 - Technical Decisions" if kind == "adr" else "17 - Risks & Technical Debt"
    for eid, name, state, title in sorted(index, key=lambda r: r[0], reverse=True):
        # No |alias here: a wikilink alias separator is a raw '|', which conflicts with a
        # Markdown table cell's own '|' delimiters. An escaped '\|' (the first version of this
        # code) is not valid Obsidian syntax and left every index row unresolved. Simplest
        # correct fix: no alias needed -- the note's own title already starts with the ID.
        link = f"[[MYPS/{sub}/{folder}/{name[:-3]}]]"
        rows.append(f"| {link} | {state} | {title[:110]} |")
    rows.append("")
    if not dry:
        (outdir / f"Canonical {label} Index.md").write_text("\n".join(rows), encoding="utf-8")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    if not VAULT_MYPS.exists():
        print(f"FATAL: vault not found at {VAULT_MYPS}", file=sys.stderr)
        return 2

    specs = (
        ("ADR", ADR_OUT, "adr", "decisions.md", "16 - Technical Decisions", "Canonical ADRs"),
        ("RISK", RISK_OUT, "risk", "risks.md", "17 - Risks & Technical Debt", "Canonical Risks"),
        ("ASS", RISK_OUT, "risk", "risks.md", "17 - Risks & Technical Debt", "Canonical Risks"),
    )

    # PASS 1 -- parse everything and build the ID -> filename map BEFORE writing any note.
    # Cross-links must target real filenames (which carry titles); resolving them against bare
    # IDs produced 100% broken Related links on the first run.
    parsed, linkmap = {}, {}
    for prefix, _out, _kind, lane, sub, folder in specs:
        entries, dropped = dedupe(parse_entries(LANE_DIR / lane, prefix))
        parsed[prefix] = (entries, dropped)
        for eid, title, _body in entries:
            linkmap[eid] = (sub, folder, node_filename(eid, title))

    # PASS 2 -- write.
    total = 0
    for prefix, outdir, kind, lane, _sub, _folder in specs:
        entries, dropped = parsed[prefix]
        n, index = emit(entries, outdir, kind, lane, args.dry_run, linkmap)
        note = f"  (kept first of {len(dropped)} dup: {', '.join(dropped)})" if dropped else ""
        print(f"  {prefix}: {n} nodes -> {outdir.name}/{note}")
        if prefix in ("ADR", "RISK"):
            write_index(index, outdir, kind, args.dry_run)
        total += n

    print(f"\n  TOTAL: {total} nodes {'(dry run, nothing written)' if args.dry_run else 'written'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
