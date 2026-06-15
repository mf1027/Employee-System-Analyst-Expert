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

- **Date:** 2026-06-16 (later) — Added the **`conversion-analysis`** skill (32nd skill) — the
  **conversion/migration project profile**. For projects that rewrite/port an existing app to a new
  language or stack (engagement type C, or a stack-rewrite type-B): scaffolds a **dual document
  resource** `[project]/migration/legacy/` + `migration/target/` (project-scoped, never mixed) and a
  single rich `conversion.md` holding the **Parity Matrix** (new **`PAR-NNN`** ID — every legacy
  capability → target equivalent → migration status → verification, so nothing is silently dropped),
  stack delta, divergence log (intentional change → ADR), equivalence verification (golden-master /
  parallel run), and cutover/rollback + legacy decommission. Data migration reuses `database.md`
  (DBA lens). Closes 10 named loopholes (old/new conflation via `system:legacy`/`system:target`
  claude-mem tags, silent feature loss, undocumented legacy logic, data loss, integration breakage,
  scope creep, no rollback, NFR regression, decommission, multi-project mixups). Wired into 8 files:
  new-client-setup (type-C detection), new-project (conditional `migration/` scaffold §4b),
  ingest-reference (legacy/target routing + `system:` tag), skills.md (A13 + index), root CLAUDE.md
  (trigger + `PAR-` ID + SA-skills list + project-structure tree), SKILL.md (trigger + `PAR-` ID),
  ai-sa-employee/CLAUDE.md (skill-chain + deliverables + project-type feature). Counts 31→32 everywhere.
  **Synthetic conversion drill (`_drill`/`legacy-convert`, PHP/Laravel+MySQL → Node/NestJS+PostgreSQL):
  7/7 PASS, cleanup CLEAN.** Validated: 10-file scaffold + `migration/legacy` + `migration/target` +
  `conversion.md`; Parity Matrix with `PAR-001..003` and Next-ID correctly bumped to `PAR-004`; all
  three statuses (In progress/Migrated/Dropped); dropped SOAP item tied to `ADR-002` with Sponsor
  sign-off (no silent loss); divergence log → ADR; `system:legacy`/`system:target` tags in the
  legacy/target READMEs; conversion risk seeds (behavioral drift, lost business logic, data loss,
  scope creep) in risks.md; data migration + reconciliation reused in `database.md`. **Cleanup proved
  the REC-DRILL fix:** ran all shell steps with repo-root absolute paths, never `cd` into
  `memory/clients/*` → no stray claude-mem store spawned → `Remove-Item` removed `_drill` fully on
  first try AND swept the previous drill's locked `smoke-test/.claude-mem` leftover. git clean
  (gitignored), Client Index row removed.
- **Date:** 2026-06-16 — Added the **`scrum-master`** skill (31st skill). Self-contained
  `ai-sa-employee/skills/scrum-master.md` at senior PSM/CSP caliber: Scrum Guide 2020 fidelity
  (3 accountabilities, 5 events, 3 artifacts + 3 commitments, 5 values, empiricism), four coaching
  stances, flow metrics with an explicit **velocity-misuse guard**, impediment management via new
  **`IMP-NNN`** ID, scaling/Scrumban awareness, an anti-pattern catalogue, and a **boundary note vs
  `plan-project`** (adaptive vs predictive; how they coexist on hybrid projects). Wired into every
  routing surface: root `CLAUDE.md` (Identity PM hat, 2 trigger rows, PM-skills list, ID list #7,
  build status), `ai-sa-employee/SKILL.md` (trigger row + `IMP-` in ID table), `skills.md` (B10
  enriched + §6 index), `ai-sa-employee/CLAUDE.md` (skill-chain + deliverables). Corrected all
  "30 skills" counts → 31 across CLAUDE.md/SKILL.md/README.md. Reuses existing scaffold
  (`tasks.md`/`plan.md`/`calibration.md`/`risks.md`) — only one new ID prefix introduced.
  **System drill run (synthetic `_drill`/`smoke-test`):** 6/7 PASS — onboarding (10 files +
  deliverables), ID minting + Next-ID increments (REQ-F02/RISK-002/ASS-002/ADR-002/TASK-002/IMP-002
  all bumped correctly), mode write-lanes, calibration ratio (3d→4d=1.33), resume reconstruction.
  **Scrum-master enhancement validated end-to-end:** Sprint Goal, sprint backlog, `IMP-001`
  impediment, sprint row laddering to milestone, velocity (forecasting-only label), retro `REC-001`.
  Memory-sync step = DEGRADED (first session, claude-mem empty, no mem-search tool exposed).
  Cleanup = PARTIAL: all drill `.md` data deleted + Client Index row removed + git clean (gitignored),
  but a `.claude-mem/` scaffold remained under the project folder, held open by the live claude-mem
  process — frees on session end. **REC-DRILL:** don't `cd` shell into `memory/clients/*` folders;
  `CLAUDE_MEM_DATA_DIR=./.claude-mem` makes claude-mem spawn a project-local store at CWD. Use
  absolute paths from repo root in drill/backup shell steps. Leftover (no client data):
  `memory/clients/_drill/smoke-test/.claude-mem/` — delete after restarting the session.
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
