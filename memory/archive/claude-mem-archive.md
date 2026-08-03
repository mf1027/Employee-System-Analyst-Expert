# Memory Archive — Cold Storage

> Managed by `memory-hygiene` (`/check-memory`). Zero injection cost — never auto-loaded at
> session start. Read on demand only (searchable history). Append-only: nothing here is ever
> destroyed, only moved here from the hot (`memory/memory.md`) or warm (claude-mem) tiers.

---

## Archived 2026-07-17 — `memory/memory.md` "Last Session" entry (2026-07-08 → 2026-07-10)

> Compacted out of the hot tier (retention rule: clear when >2 sessions stale). claude-mem MCP
> tools were unreachable this hygiene pass too (SKL-022, PATH fix still pending operator action) —
> this archive move was done on `memory/memory.md` only, same as the two prior hygiene passes below.

- **2026-07-08 → 2026-07-10:** Admin Area re-split into 5 tables + AAMS backfill (ADR-029, 4 real
  bugs caught); RBAC ported to junction-schema views then fully reverted to LOCAL-MYPS's as-is
  CSV-blob shape (ADR-030 → ADR-031, backend-fidelity trigger: RISK-035/036); RISK-018 re-opened/
  re-accepted, RISK-034 retired; 7 views rewritten as optimized re-implementations, proven
  byte-identical via a 15-check cross-DB parity drill. LS Wallet workflow doc completed (RISK-033
  found). Module 12 Multi-Year: second draft ingested, reconciled against the existing URD, put
  ON HOLD pending client discussion. Full detail in `memory/clients/myps/myps-system/decisions.md`
  (ADR-027–031), `risks.md`, `requirements.md`, `multi-year-planning-draft-urd.md`.
  **Superseded 2026-07-17:** the Admin Area schema (ADR-029) was itself restructured and locked
  (ADR-047) — see the newer archive entry / current `memory.md` Last Session for that pass.

---

## Archived 2026-07-10 — `memory/memory.md` "Last Session" entry (2026-07-07)

> Compacted out of the hot tier (retention rule: clear when >2 sessions stale). claude-mem MCP
> tools were unreachable this hygiene pass (SKL-022, PATH fix still pending) — this archive move
> was done on `memory/memory.md` only. The 2026-06-12→06-16 entry that sat alongside this one in
> the hot tier was already a compacted pointer to the archive entry below (archived 2026-07-07) —
> not re-archived here, only this newer entry is new to cold storage.

- **2026-07-07:** MYPS User Permissions (RBAC) module fully shipped (ADR-026 — junction-table
  redesign, schema+seed+drill green). Superseded 2026-07-10 by ADR-031 (reverted to LOCAL-MYPS's
  as-is CSV-blob shape — see `memory/clients/myps/myps-system/decisions.md` ADR-031).

---

## Archived 2026-07-07 — `memory/memory.md` "Last Session" entries (2026-06-12 → 2026-06-16)

> Compacted out of the hot tier because they were >2 sessions stale (the file's own retention
> rule) and their durable facts already live in root `CLAUDE.md`'s Build Status table. Full
> original narrative preserved below for on-demand recall.

- **Date:** 2026-06-16 (latest) — Docs cleanup + boundary clarification. (1) Rewrote
  `reference/README.md` as the ingestion **inbox** with a "where does a file belong?" table
  (workspace `reference/` · client `reference/` · conversion `migration/legacy|target`); removed
  the misleading "subfolder suggestion" that overlapped the client store. Added the reciprocal
  boundary note to `conversion-analysis` (client-wide docs stay in `reference/`). (2) **Reconciled
  the two deliverables locations** → canonical is per-project `memory/clients/[client]/[project]/
  deliverables/`; repo-root `deliverables/` demoted to fallback for ad-hoc/non-client docs. Updated
  `document-specialist-skill`, `create-diagram`, `skills.md` index, root CLAUDE.md structure note,
  `deliverables/README.md`. (3) Deleted superseded `archive/oldcustomemployee.md` (pre-restructure
  CLAUDE.md pointing at dead paths; git-recoverable). (4) **Per-context ingestion logs (fixed):**
  `ingest-reference` now updates the `## Ingestion Log` table in the README **co-located with the
  ingested file** (repo-root `reference/`, client `reference/`, or `migration/legacy|target/`) — no
  longer always the repo-root one; `new-client-setup` now scaffolds a client `reference/README.md`
  with an ingestion-log table at onboarding; repo-root `reference/README.md` gained its own log
  table. Standard log columns: `File | Type | Summary | claude-mem entries | Date ingested`.
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
- **Next step (superseded):** Run `scripts/backup.ps1` once to create the first backup; run a
  system drill ("run a drill") to validate the upgraded pipeline before the next real client.
  (Superseded — MYPS became the real client shortly after this entry; backup/drill cadence has
  run many times since across the myps-system engagement.)
