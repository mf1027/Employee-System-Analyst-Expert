# Phase 2 Plan — Document Engines + Restructure

**Status:** ✅ COMPLETE (2026-06-13)
**Decisions:** Engine strategy = **Hybrid** · Restructure depth = **Consolidate skills**

This is the durable record of the Phase 2 plan so it is not re-litigated. If the
employee or a future session questions "why is it structured this way," read here.

---

## The four requests and how they were resolved

| # | Request | Resolution |
|---|---|---|
| 1 | LibreOffice "installed directly here in the project" | **Hybrid.** A gitignored `engines/` folder can hold a project-local LibreOffice (`scripts/fetch-libreoffice-local.ps1` extracts the official MSI via `msiexec /a` — no admin, no system install). The patched `get_soffice_cmd()` resolves **engines/ → PATH → system install**, so the in-project copy wins when present. System install stays the default fast path and keeps cross-platform working. |
| 2 | Add to pre-installation script | `setup.ps1`/`setup.sh` §3b is idempotent (detect → skip → install), installs LibreOffice + Poppler + 7 Python packages, falls back to the in-project fetch when winget is unavailable, and auto-runs `verify-engines` at the end. |
| 3 | Fully check and test | `scripts/verify-engines.ps1`/`.sh` runs the real chain (txt→docx→pdf→png, csv→xlsx, openpyxl create, pypdf read) and prints a PASS/FAIL checklist. Result: **9/9 PASS**. Reusable on every machine. |
| 4 | Restructure (skills/document-skills were scattered) | Consolidated under `ai-sa-employee/` so there is **one self-contained package**. `git mv` preserved history; ~64 path references updated; CLAUDE.md declared the canonical source of truth. |

## Why "in-project install" became "Hybrid" (the honest reasoning)

Bundling the full system LibreOffice in the repo was the wrong mechanism: it is
~0.67 GB, Windows-only, and gitignored anyway (so it would not travel via git). The
real goal was "don't re-fix the engine on every machine." Hybrid delivers that:
- In-project `engines/` copy (literal request) — rides in the backup zip, zero install on a new Windows machine.
- System auto-install (default) — cross-platform, smallest footprint.
- Resolver checks both, automatically, forever.

## Final structure

```
ai-sa-employee/          ← self-contained: SKILL.md, CLAUDE.md, references/, skills/ (30), document-skills/ (6)
engines/                 ← gitignored portable LibreOffice (resolver checks first)
memory/                  ← unchanged (memory.md, communication.md, clients/)
scripts/                 ← setup, pdf2md, fetch-libreoffice-local, verify-engines, backup
```

## Engine facts (verified 2026-06-13)

- LibreOffice 26.2.4 (system install; in-project `engines/` copy optional via fetch script)
- Poppler 25.07.0 (winget, on PATH)
- 7 Python packages: defusedxml, lxml, openpyxl, pdf2image, pdfplumber, pillow, pypdf
- Resolver order: `engines/` → PATH → system install dir (tested on both branches)

## Known note (not a defect)

The vendored Anthropic document-skills reference each other via `/mnt/skills/public/...`
(their cloud-sandbox path convention). This is upstream and pre-existing — the employee's
entry point `document-specialist-skill.md` uses correct `ai-sa-employee/document-skills/...`
paths, and the actual conversion scripts are local and verified working. Rewriting the
`/mnt/` references was deliberately NOT done: it would diverge from upstream and make future
re-vendoring harder, for no functional gain.
