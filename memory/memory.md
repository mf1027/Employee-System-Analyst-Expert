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
| LS Wallet (Module 11) | MYPS / myps-system | Design locked (ADR-025); workflow doc completed 2026-07-08; build not started | Resume schema/build session when prioritized | 🟡 |
| Multi-Year Planning (Module 12) | MYPS / myps-system | **ON HOLD 2026-07-10** — 2 independently-sourced drafts reconciled (REQ-F101–F122 vs. new user-stories file); 1 unresolved mechanism conflict (auto PIP-sync vs. manual AIP-linking) | Dedicated client/operator reconciliation session before any further design | 🟡 |
| Bulk project import (Excel → background) | MYPS / myps-system | ✅ Core mechanism BUILT 2026-07-16 (ADR-043) — `tImportJob` hard-reject lock + `tProjectIdSequence`/`pReserveProjectIdBlock` atomic ID allocation, drilled 10/10. Hangfire REC (2026-07-15) still the recommended queue layer. | Kafka/SignalR/EF Core backend integration is specified (`project-import-kafka-signalr-flow.md`) but **not yet implemented** — dev/infra lane. Category-range exhaustion deliberately deferred (operator decision). | 🟢 |
| Mock lookup integrity + traps | MYPS / myps-system | ✅ **DONE 2026-08-04 (ADR-069)** — all geography/office columns now resolve to REAL lookups AND are internally consistent (was `'10-001'` ×135, in no lookup table). `drill-mock-lookup-integrity.sql` 9/9. `AlternateId` = user free-text, never lookup-bound (CHK8 guards it). | **Mock run order is now 4 STEPS** — seed 1→2→3 then `_mock-lookup-normalization-block.sql`; step 1 self-checks and warns if incomplete. **⚠️ `drill-revision-full.sql` is DESTRUCTIVE but now INTERLOCKED** (defaults to abort). Open: AlternateId format unconfirmed, GAP-2 orphan LS project. | 🟢 |
| Mock data coverage (GAP-1 overlay) | MYPS / myps-system | ✅ **CLOSED 2026-08-04 (ADR-068)** — `PRG-2026-K001` + K1/K2/K3 make the ADR-062 approved-revision overlay execute in the PERSISTENT mock for the first time (was 0 projects). 14/14 drill PASS + permanent tripwire. GAP-3/GAP-6 closed on the same rows. 3rd leaky drill fixed. | Remaining mock gaps: GAP-2 (1 orphan LS project), Phase B (projects under G/H/I/J — blocked on ProjectPK format for non-BP-starting programs). **⚠️ `drill-revision-full.sql` is DESTRUCTIVE (truncates all projects/programs) — never include in a bulk sweep.** | 🟢 |
| Program type → stage gating | MYPS / myps-system | ✅ **BUILT 2026-08-03 (ADR-067)**, schema + 15/15 drill PASS. **Mock Q1 also done same day** — 4 new programs (G/H/I/J) proving the rule, incl. J = first data where raw `StageId` order ≠ real process order (RISK-054 made concrete). | **Backend wiring not done** (app-side enforcement). Mock **Phase B (projects) still deferred** — needs ProjectPK format rule for a non-BP-starting program. Also open: `StageId`-vs-`StageHierarchy` ordering ADR; RISK-058/059 logged; **2nd drill-residue leak found** (`drill-full-lifecycle.sql`, joins `drill-component-lifecycle.sql` in the held rebuild plan's P0). | 🟢 |
| ~~Program type → stage gating (plan)~~ | MYPS / myps-system | ⏸️ ~~ON HOLD 2026-08-03~~ — superseded by the row above — full plan written + grounded against live legacy DB, **zero DDL executed** (`program-type-stage-gating-plan.md`). Design settled: new `tProgramTypeStages` junction + `tOptionProgramType.Code` + `tOptionProgramStage.ProgramGroup` + missing `FK_tPrograms_Type` + 2 views mirroring the `vAPIPermissions` pattern. **Key finding that stands regardless: this ANSWERS RISK-054 — program stages are (B) parallel tracks, not linear** (`T`→`TF`/`TF-R` only; `E`/`A`→`GAA`/`GAA-R` only; only `R` walks the full pipeline). | Answer the 5 questions in plan §8 — **Q5 is the blocker**: confirm with operator/client whether External & Automatic Appropriation really skip `BP`→`HGAB`. Rule comes only from retired-system data, never human-confirmed. Then execute P1–P8. | 🟡 |
| Data-access filtering (`ApplyFilter`, program + project level) | MYPS / myps-system | ⏸️ **UNBLOCKED 2026-07-17** — was on hold (RISK-046) pending the admin-area lock, which is now done (ADR-047). The region resolver (`vAdminOfficeRegion`) this depends on already exists. | Resume via the DBA interview chain (operator's chosen path) when prioritized — open questions + deliverable shape in `data-access-filtering-onhold.md` | 🟡 |

### Last Session

- **2026-08-30 — `ProjectController.cs` first-ever audit (ADR-130), verdict NO-GO.** Canonical
  top-of-stack: `decisions.md` → ADR-130 (`Next-ID: ADR-131`), `risks.md` → RISK-106
  (`Next-ID: RISK-107`). 15 live defects found (static sweep + 2 independently source/DB-verified).
  Authorized fix applied: `[AllowAnonymous]` removed from 5 of 7 sites, live-verified (401
  unauthenticated); 2 sites deliberately left anonymous after a pre-flight permission-coverage
  check caught a real would-be outage (576/579 users lack rows) — RISK-104. 3 confirmed write-path
  defects not fixed (audit + verify only, operator's choice) — RISK-106. Independently re-confirmed
  and extended a 2026-08-24 handover RCA on ProjectId generation, superseding RISK-072 with a
  narrower, live-verified finding — RISK-105. One static finding (F-09) corrected after reading the
  live proc, not left as originally assessed. Also closed out: the 2026-08-28 Codex-hooks probe —
  confirmed NO-GO across multiple genuine fresh sessions (not a timing artifact), fully rolled back
  to exact pre-probe state, RISK-095 updated with the addendum (including correcting its own stale
  "out of scope" justification against ADR-121). Full detail: `decisions.md` (ADR-130), `risks.md`
  (RISK-104/105/106, RISK-095 addendum).
- **2026-08-28 — Formal Revision Part 2: repeat-cycle drill clean; Group-13 fork found
  structurally unreachable, calling ADR-123's GO into question.** **Canonical top-of-stack is now:
  `decisions.md` → ADR-129 (`Next-ID: ADR-130`), `risks.md` → RISK-103 (`Next-ID: RISK-104`).**
  Operator spotted 2 gaps in the just-reported ADR-128 matrix (re-revising an already-completed
  project; revising a Group-13 `-A` forked project) and asked to test both — plan-gated (re-entered
  plan mode), approved, executed. **S13 passed clean**: a real second revision cycle on
  `P01100001LZ`, PCMA publish confirmed via `PCMARevisionCount` 1→2, no document-numbering
  collision (one cosmetic double-dot filename artifact noted, not chased). **S14 blocked by a real
  defect, not a fixture gap**: recreating the Group-13/Reason-47 fork failed at the CO-approval
  step that should trigger it. Root-caused to source: `RequestRevision` unconditionally deactivates
  the only prior-active `tRevisionProjects` snapshot the moment ANY new revision is requested
  (including the fork's own), while the fork's precondition check needs that row still active, and
  the row that would satisfy it only activates in code downstream of the failing check — a
  structural deadlock. Confirmed via `git show 6ed40cd4` that this logic predates this session (the
  exact commit ADR-123 verified as its drilled code) — not a new regression, but not reconciled
  against how ADR-123's own drill supposedly got a non-null precondition. **This calls ADR-123's
  "GO, live-drilled twice" verdict on the fork into question** — logged as RISK-103, flagged for
  operator reconciliation rather than unilaterally overturned. Also fixed, same turn: added
  `Main/Resources/UploadedFiles/` to `project_myps/.gitignore` per operator request (157
  pre-existing tracked files unaffected, only stops future runtime uploads from showing as
  untracked noise — closes the loop on ADR-128's own 17-PDF side-effect finding). Mind-map synced:
  `Backend Deployment Readiness.md`, `MYPS Current State Dashboard.md`, `MYPS Revision Mindmap.md`,
  `Risk Register.md` (including a direct cross-reference added to the existing RISK-078 row, not a
  silent rewrite). Full detail: `decisions.md` (ADR-129), `risks.md` (RISK-103).
- **2026-08-27/28 — Formal Revision approval state machine: full 12-scenario condition-coverage
  drill, RO-approver audit-trail defect fixed and proven live.** **Canonical top-of-stack is now:
  `decisions.md` → ADR-128 (`Next-ID: ADR-129`), `risks.md` → RISK-102 (`Next-ID: RISK-103`).**
  Operator-directed: exercise every condition in the Revision approval backend (create → RO → CO,
  for-correction cycles incl. multiple, rejects, resubmits, guards), not just single-path testing.
  Mapping the machine before planning found one real, previously-invisible defect:
  `ApproveRevision`'s RO branch committed `Approver`/`ApprovedDate` as NULL (the restore block sat
  inside the CO-only branch) — fixed and proven live (S1: `Approver='afundardb'`, not NULL). All 12
  scenarios DB-verified via real authenticated `PIS.BypassLogin` HTTP + a genuinely-validated PDF
  (no bypass of document validation). **New RISK-102** (significant, not fixed): CO-creator
  auto-approve in `RequestRevision` can reach `IsFullyApproved=1` without ever calling
  `PublishRevisionAsync` — MYPS reports "fully approved" while PCMA is never told, silently, no
  error signal. 3 minor findings also logged, not fixed (no guard against double
  `ForCorrectionRevision` without resubmit; the in-method permission check is very likely dead code,
  the real gate is `AuthorizeSessionAttribute`; a cosmetic "corrupted" vs. "required" message gap on
  a missing approval document). **Unanticipated side effect, honestly reported:** the drill's real
  document uploads wrote 17 physical PDF files to disk (`Main/Resources/UploadedFiles/Revisions/`)
  — not covered by the operator's "leave test revisions in the DB" decision (framed around DB rows),
  left in place under the same retention logic, flagged as a gap against the plan's own stated
  Verification expectation rather than silently absorbed. 12 test revisions retained live on
  `myps_db_dev` per the operator's explicit choice (overriding this session's own Recommended
  cleanup-after-each-scenario option). Verdict: **GO**, Deployment-ready for the approved fix scope
  — RISK-102 is a new, separate finding awaiting its own operator go/no-go, not a blocker on this
  pass's GO. Mind-map synced: `Backend Deployment Readiness.md`, `MYPS Current State Dashboard.md`,
  `MYPS Revision Mindmap.md`, `Risk Register.md`, `MYPS Backend Mindmap.md` — plus 2 pre-existing
  frontmatter staleness gaps fixed in passing (`Backend Deployment Readiness.md` and
  `Risk Register.md` were both missing ADR-123/125/126 from `related-adr`). Full detail:
  `decisions.md` (ADR-128), `risks.md` (RISK-102).
- **2026-08-27 — `RevisionGroupId 13`/`ReasonId 47` continuation fork built, live-drilled, GO;
  session-wide sync-verification guard added.** **Canonical top-of-stack is now: `decisions.md` →
  ADR-123 (`Next-ID: ADR-124`), `risks.md` → RISK-099 (`Next-ID: RISK-100`).** Implemented the
  8-table fork cascade in `RevisionController.ApproveRevision` (literal `{ProjectPK}-A` identity,
  full funding/cost/work-item/work-location/document copy, operator-confirmed scope) — found/fixed
  2 real bugs via a live authenticated-HTTP drill (`SaveChangesAsync` FK-ordering; a phantom
  `tRevisionDocuments` row), then an adversarial re-audit closed both named readiness gaps and
  revised the verdict to **GO** (ADR-123, closing RISK-078). Found new **RISK-099** (database-wide:
  every `tRevisionDocuments` row on `myps_db_dev` references a missing file) as a side effect,
  unrelated to the fork — logged, not fixed, operator decision needed. `RevisionController.cs` is
  **committed and pushed** — `6ed40cd4` on `project_myps` branch `dp-deployment`
  (`origin/dp-deployment`), confirmed by direct git-log/diff comparison to match the drilled code
  exactly (same fixes, same comments); not yet merged into `main`. (This correction is itself the
  first real catch from the sync-verification guard built this same session — the "uncommitted"
  claim above was true when first drafted, then went stale within the same turn.) Separately, added
  3 users
  (`ferrermaa`/`yabutgj`/`asisjnt`) via a durable SQL script. **Process finding:** closing out this
  work's documentation surfaced a 2-day-old identical unresolved blocker
  (`PIS.BypassLogin`) sitting unclosed in a hand-authored vault note (`Backend Deployment
  Readiness.md`) that no mechanical check ever covers — the existing generated-node verifier
  (ADR-111/117) only covers auto-mirrored ADR/RISK nodes, not hand-authored ones. Built
  `tools/check-related-vault-notes.py` + a new Standing Task-Execution Protocol sub-step
  (`CODEX_SYNC_STARTUP.md`/`CLAUDE.md`) requiring it before any Obsidian-sync gate is declared
  done — see that ADR/SKL entry for detail. Full detail: `decisions.md` (ADR-118–123),
  `risks.md` (RISK-096–099), `improvement-backlog.md` (SKL-055).
- **2026-08-25 — Full cross-surface memory-conflict + sync-mechanism + unnecessary-files audit**
  (operator request: "check all conflicts, check real-time sync, check unnecessary files"). 3
  Explore agents + 1 Plan agent investigated; findings executed same session. **Canonical
  top-of-stack is now: `decisions.md` → ADR-117 (`Next-ID: ADR-118`), `risks.md` → RISK-095
  (`Next-ID: RISK-096`).** Preceded by two `ProgramController.cs` Batch-function fixes earlier the
  same session (RISK-092/093 — a call to a nonexistent stored procedure, and a restore action that
  set its own "undo" flag backwards — both DB-metadata- and rollback-drill-verified). Work this
  pass: (1) **new RISK-094** — a live Gmail app-password found exposed in the same git-tracked
  `appsettings.Development.json` RISK-090 already tracks for its DB credential; rotation is an
  operator action, flagged, not performed here. (2) **new RISK-095** — the sync mechanism
  (`session-sync.ps1`/ADR-113) is SessionStart-only, its `memory.md` check is a crude ADR-number
  heuristic, and its vault check was git-status-only (couldn't see the Obsidian vault's generated
  ADR/RISK indexes were 5/2 entries stale despite a clean repo) — documented as an accepted
  limitation, not a build-a-new-mechanism mandate. (3) **new ADR-117** — wired
  `tools/verify-vault-memory-nodes.py` into `session-sync.ps1` as a read-only check, closing that
  one specific vault-staleness blind spot; verified live (synthetic-stdin invocation, both before
  [WARNING, caught the real gap] and after [OK] the vault regeneration). (4) ran
  `verify-vault-memory-nodes.py` → `generate-vault-memory-nodes.py` → verify again: vault now 0
  missing nodes (was 6 ADR + 4 RISK missing). (5) fixed `myps.md`'s precedence paragraph, which had
  been saying the opposite of the current (2026-08-24) Obsidian-first model since 2026-08-21 — the
  exact class of stale cross-reference this audit exists to catch, found in the file that describes
  the precedence rule itself. (6) fixed `CODEX_SYNC_STARTUP.md`'s RISK-081/083 status table, stale
  since 2026-08-21 despite a 2026-08-23 refresh pass touching other parts of the same file; that fix
  also surfaced that RISK-081 already independently flagged (2026-08-21) the exact SP-name
  regression RISK-092 refound and refixed 2026-08-24/25 — cross-referenced both entries. (7) pruned
  the Active Tasks table below per its own stated policy — 5 rows removed whose Next Action
  literally said "None" (were fully superseded by canonical `decisions.md`); left every row that
  still lists residual open items, even ones marked done/built. Full detail:
  `memory/clients/myps/myps-system/decisions.md` (ADR-117), `risks.md` (RISK-092–095).
- **2026-08-23 — Memory-architecture audit (ADR-110/111). This section had been 10 days and
  17 ADRs stale**, still naming ADR-093 as "the latest decision" while canonical was at ADR-110.
  A staleness check is now step 2 of the session-start gate in `CLAUDE.md` so this is caught
  rather than inherited. **Canonical top-of-stack is now: `decisions.md` → ADR-110
  (`Next-ID: ADR-111`), `risks.md` → RISK-091 (`Next-ID: RISK-092`).** Work done: ran a real
  read-only drill (`tools/verify-function-sql-mindmap.ps1` 47/52 → **49/49 green** after
  un-staling its ADR-107/108 assumptions and tightening its wikilink check, which exposed 13
  genuinely broken links); fixed 6 vault anchor notes citing a deleted source file; **initialized
  a local-only git repo for `memory/clients/`** — the canonical lane files previously had *no*
  version history at all while both subordinate surfaces did; **formally dropped the system to
  Tier 0** (claude-mem confirmed dead since 2026-07-02, SKL-022). **New: RISK-091 🔴 Critical** —
  the RISK-090 `sa` credential exists in 6 locations, not 2, incl. a paste-ready `sqlcmd` line
  pushed to 3 remote branches; rotation is the operator's decision, nothing was deleted.
  ⚠️ The Active Tasks table below is still **not** re-verified — it remains historical.
- **2026-08-13 — Client resumed via `resume-client`.** `ai-sa-employee/` framework and
  `memory/clients/myps/` were found populated on disk (not freshly copied by this session, but
  not yet registered/read this session either). Working Memory above was stale by ~4 weeks
  relative to the project files — `decisions.md`/`risks.md`/`database.md`/`tasks.md` all carry
  entries through 2026-08-13, while this section's last entry stopped at 2026-07-17. Read
  `myps.md`, `requirements.md`, `risks.md` (head), `plan.md`, `tasks.md`, `decisions.md` (head —
  ADR-091/092/093), `database.md` (head — ADR-092 re-baseline banner), `calibration.md` (still an
  empty scaffold). **Current top-of-stack state:** ADR-093 (Kafka dropped, Hangfire+SignalR
  confirmed for import dispatch) is the latest decision; RISK-072 (`tProjectIdSequence` desync,
  🔴 silent `P`-suffix ID collision) is **open, investigation paused**, blocking on operator
  confirmation of whether a legacy `MAX+1`-style query is still live anywhere in app code;
  RISK-070/071 (two reporting-proc defects — dead `@region` filter + a fully commented-out
  `WHERE` clause in `usp_extract_PC_MIOW_list`) are open, unfixed, unowned. Task board (`board.md`,
  509KB) and full `decisions.md`/`risks.md`/`database.md` were not read in full this pass — see
  those files directly for anything not summarized here. This Working Memory section's Active
  Tasks table below is **not** re-verified against current state as part of this resume; treat it
  as historical until spot-checked against `tasks.md`/`board.md`.
- **2026-07-15 → 2026-07-17:** Bulk Project Import System built (ADR-043 — `tImportJob` hard-reject
  lock + `tProjectIdSequence`/`pReserveProjectIdBlock` atomic ID allocation, replacing the as-built
  full-scan+race mechanism). AlternateId relocated to `tProjects` (ADR-044). Canonical
  `projects-and-revisions-design.md` written (consolidates ADR-037–046, SKL-021). `IsPublishable`
  moved from an app-side C# batch-loop to a proven SQL proc, `pRecomputeProjectPublishable`
  (ADR-045) — found + fixed a likely AsNoTracking non-persist bug in the original C# (RISK-044), then
  found the *replacement* C# integration draft repeat the same failure class on the caller side
  (RISK-045, corrected pattern given, not yet confirmed applied). Detail-chain stage-advance copy
  (funding/components/per-year/work-items/locations/docs/notes) moved to a set-based proc,
  `pCopyProjectDetailChain` (ADR-046) — remap via `MERGE...OUTPUT`, scoped for 100K+ projects/program.
  **Admin Area schema locked** (ADR-047) after the full DBA chain: `GdbId` dropped from all 5 tables
  (zero DB deps, SKL-028), geography re-keyed on `Code`, 8 per-OfficeType views + a region resolver
  built — RISK-031 closed won't-fix ("region-only is enough"), RISK-032 (Ñ-encoding) resolved by a
  fresh operator-supplied source. That source's own Excel scientific-notation corruption + missing
  Pangasinan deferred to a data-backfill pass (not a schema blocker). **Data-access filtering
  (`ApplyFilter`, program + project level) put ON HOLD** (RISK-046) pending the admin-area lock —
  now unblocked, ready to resume; full findings in `data-access-filtering-onhold.md`. Self-improvement
  pass: 6 proposals raised, 5 applied (SKL-030–033, WFC-009 — CSV code-integrity precheck, drill-suite
  registry discipline, mock-prefix isolation, `QUOTED_IDENTIFIER`-at-CREATE-time, a new read-only
  reference-lock drill archetype), 1 deferred (SKL-034, weak evidence). Full detail in
  `memory/clients/myps/myps-system/decisions.md` (ADR-043–047), `risks.md`, `improvement-backlog.md`.
- **2026-07-08 → 2026-07-10:** Admin Area re-split into 5 tables (ADR-029, since restructured/locked
  under ADR-047 — see above); RBAC reverted to LOCAL-MYPS's as-is CSV-blob shape (ADR-031); LS Wallet
  workflow doc completed (RISK-033); Module 12 Multi-Year put on hold. Archived —
  `memory/archive/claude-mem-archive.md`.
- **2026-06-12 → 2026-07-07:** Prior work (system build-out, RBAC's original ADR-026 build) —
  archived at `memory/archive/claude-mem-archive.md`.

## Client Index

| Client | Industry | Active Projects | Record |
|---|---|---|---|
| MYPS | Government (DPWH, Philippines) | myps-system (SQL Server rebuild + conversion) | `memory/clients/myps/myps.md` |

## Knowledge Base Summary

> **⚠️ SUPERSEDED 2026-08-23 (ADR-111).** This section previously said "retrieve with
> `mem search [topic]`". That store is **not operational** — last written 2026-07-02, MCP tools
> do not connect (SKL-022, diagnosed 2026-07, never resolved). The table below was always empty,
> so nothing was lost — but the instruction pointed readers at a dead retrieval path.
>
> **Where engagement knowledge actually lives:** the per-client lane files under
> `memory/clients/[client]/[project]/` — `decisions.md` (ADR-), `risks.md` (RISK-/ASS-),
> `requirements.md` (REQ-), `database.md`, `board.md`. Those are the knowledge base.
> The system runs at **Tier 0 — file memory only**.
