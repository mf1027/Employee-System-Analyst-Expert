# Memory — AI SA Employee

## Operator Profile

| Field | Value |
|---|---|
| Name | Michael Angelo A. Ferrer (Newbie) |
| Company | ERGONS |
| Role | Full-stack developer + AI employee project owner |
| Comms style | Taglish; concrete examples preferred; tap-friendly options over open interrogation |
| Real projects | MYPS, Khen Panel, Binance bots |
| Approval preference | Always propose before creating/modifying files — explicit go-ahead required |
| Core values | Token efficiency, speed, generality, honest limitations |

## Employee Behavior Notes

- **Triple-lens** on every deliverable: SA (requirements + process) + PM (risk + governance) + DBA (data + schema)
- **Understanding Check** TIERED (2026-06-12) — Tier 1 hard gate for deliverables/file changes/client-facing/estimates; Tier 2 direct answer for read-only informational asks
- **Auto-capture** — decisions, requirements, risks, assumptions logged mid-conversation without being asked
- **Meeting notes** = immediate extraction: ADR / REQ / RISK / action items / open questions
- **Client outputs** — drafts only, never sent directly; operator reviews before sending
- **RED risks** — escalated immediately per `memory/communication.md`; never left unaddressed

## Working Memory

> Updated each session — current task state. Clear when stale (>2 sessions old).

### Active Tasks

| Task | Client/Project | Status | Next action | RAG |
|---|---|---|---|---|
| — | — | — | — | — |

### Last Session

- **Date:** 2026-06-15 — PDF workflow upgrade. Added `pdf-source/` (gitignored) as the default
  PDF drop folder. Rewrote `pdf2md.ps1`/`.sh` with smart input resolution: no-arg → batch
  `pdf-source/`; bare name → `pdf-source/` then cwd then error; explicit path or folder also
  supported; `-Recurse`/`RECURSE=1` for subfolders; per-file summary. **Caught a real latent bug:**
  pdf2md called the extensionless opendataloader shim (no-ops on Windows) and trusted a stale
  exit code → reported false success while writing nothing. Fixed: resolve the Windows `.cmd`
  shim + judge success by the **output file existing**. Discovered `@opendataloader/pdf` needs
  **Java** (not installed here) — so it falls back to pypdf (text-only) and now says so honestly.
  Corrected CLAUDE.md's false "Java auto-installed via npm" claim. All paths tested green.
  Also reworded README's "does not do" line for clarity.
- **Date:** 2026-06-15 (later) — Added Java to pre-install. setup §3b now installs OpenJDK 21
  (winget `Microsoft.OpenJDK.21` / brew `temurin` / apt `default-jre`) alongside LibreOffice +
  Poppler. Installed it here and verified: `pdf2md` now tags `[opendataloader]` (high-fidelity),
  no longer the pypdf text-only fallback. CLAUDE.md + README updated to reflect Java is auto-installed.
- **Date:** 2026-06-13 (PM) — Phase 2 hardening + restructure (approved plan, all 5 phases):
  (1) Consolidated `skills/` and `document-skills/` under `ai-sa-employee/` via `git mv` — one
  self-contained package; ~64 path refs updated; CLAUDE.md declared canonical. (2) Hybrid engine
  strategy: `engines/` folder (gitignored) + patched `get_soffice_cmd()` in all 3 soffice.py to
  resolve engines/ → PATH → system; precedence tested both ways. (3) `scripts/fetch-libreoffice-local.ps1`
  (msiexec /a extract, no admin). (4) setup §3b idempotent + in-project fallback + auto-runs verify.
  (5) `scripts/verify-engines.ps1/.sh` — 9/9 PASS. **Bug caught:** had installed an unnecessary PyPI
  `validators` package that shadowed the skill's local `office/validators/` — uninstalled; correct
  dep count is 7 packages. Engines unchanged on disk (LibreOffice 26.2.4 system, Poppler 25.07.0).
- **Date:** 2026-06-13 (AM) — Phase 2 document engines first install: LibreOffice + Poppler via
  winget, packages installed, pipeline verified, setup §3b added, skills flipped to ✅ Ready.
- **Previous (2026-06-12):**
- **What happened:** System upgrade — RISK-001 (backup scripts), REC-001 (canonical source
  + drift fixes), REC-002 (session-close audit in end-of-task), REC-003 (calibration.md,
  10th project file), REC-004 (env check step 0), REC-005 (Next-ID headers), REC-006
  (weekly-review skill), REC-007 (system-drill skill), REC-008 (tiered Understanding Check).
  README updated. Skill count now 30.
- **Next step:** Run `scripts/backup.ps1` once to create the first backup; run a system
  drill ("run a drill") to validate the upgraded pipeline before the next real client.

## Client Index

| Client | Industry | Active Projects | Record |
|---|---|---|---|
| — | — | — | `memory/clients/[name].md` |

## Knowledge Base Summary

> Distilled KB entries stored in claude-mem — retrieve with `mem search [topic]`.
> This section lists CATEGORIES only; full entries retrieved on demand.

| Category | Count | Key topics |
|---|---|---|
| — | — | — |
