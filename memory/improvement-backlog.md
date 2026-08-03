# Improvement Backlog

Agent self-improvement log. Managed by the `self-improvement` skill (`/check-improvements`).
**System-level, not client-specific** — this tracks how the *agent* evolves, so it is pushed.

- **Breadcrumbs** are cheap, passive records of friction. One line, no analysis, no ID.
- **Proposals (`SKL-`)** are minted only when `/check-improvements` promotes a breadcrumb.
- **Resolved** holds breadcrumbs/proposals that were acted on or consciously declined.

Format for a breadcrumb:
`- YYYY-MM-DD · <pattern> · <one-line observation> · [client or "system"]`

Patterns: `repeated-manual-work` · `ad-hoc-process` · `skill-fell-short` ·
`recurring-error` · `manual-bridge` · `post-mortem`

---

Next-ID: SKL-038
Next-WFC: WFC-011

> **2026-06-26 — `workflow-capture` merged into `self-improvement`.** The two are now one
> dual-lens skill: Lane A (friction → `SKL-`), Lane B (successful workflows → `WFC-`).
> `/check-improvements` runs both; `/capture-workflow` is an alias. Backlog keeps both
> *Breadcrumbs* (Lane A) and *Workflow candidates* (Lane B) sections.

---

## Breadcrumbs (awaiting `/check-improvements` — Lane A)

- 2026-07-24 · recurring-error · **`sys.sql_modules`-based consumer scans are structurally blind to standalone `.sql` drill files.** ADR-057's rename of `tOptionProjectComponent` → `tOptionProjectComponentType` ran a consumer sync scoped to `sys.sql_modules` (live views/functions/procs) and fixed 2 broken views — but 3 historical drills (`drill-full-lifecycle.sql`, `drill-project-detail.sql`, `drill-project-groups.sql`) still referenced the old table name in a seed line, invisible to that scan since drill files aren't DB objects. Caught hours later, during an unrelated ADR-060 column-reorder's full regression sweep, not by ADR-057's own sync. · myps → candidate: any table/column RENAME's consumer-impact scan (`dba-cross-domain-impact`) needs a second pass — a plain-text grep across the drill/mock `.sql` file directory for the old name — alongside the `sys.sql_modules` DB-object scan, since the two cover disjoint consumer populations.
- 2026-07-24 · recurring-error · **4 more drills assumed self-cleaning turned out not to be** (`drill-full-lifecycle.sql`, `drill-multi-revision.sql`, `drill-project-detail.sql`, `drill-project-groups.sql`) — left 5 extra programs + full detail chains + `tProjectGroups` rows + 43 orphaned `tTransactionLog` rows behind after a routine regression sweep (ADR-060 Path B). This is the 3rd+ occurrence of "assumed self-cleaning, wasn't" this session (SKL-036 was built from the first 2 earlier today) — but this time the blast radius was bigger (cross-table `tTransactionLog` orphans, not just row-count inflation) and the cleanup itself needed 2 attempts (missed the revision-mirror detail tables + `tRevisionDocuments` on the first pass, causing FK-violation errors; missed `tTransactionLog` on the second, causing a re-run drill to regress from PASS to FAIL). · myps → candidate: SKL-036's "verify a drill's real cleanup behavior before a sweep" rule should extend to "when cleaning up discovered residue, enumerate EVERY FK-child table (not just the ones touched by the CURRENT task) before writing the DELETE cascade — reuse the same full-dependency-map discipline Phase 1 of a schema rebuild already requires, don't hand-reconstruct a shorter list from memory."

> **2026-07-24 `/check-improvements` pass:** promoted 4 clusters → SKL-035 (mechanism-level preflight,
> 🔴, from the 2026-07-20 ProjectId-from-scratch breadcrumb), SKL-036 (drill-sweep trust discipline,
> from the two 2026-07-22 breadcrumbs), SKL-037 (T-SQL variable-scope traps, from 2026-07-20
> table-type-var + 2026-07-17 shared-`@cc`), and WFC-010 (surgical-change-through-a-lock playbook,
> logged/watch). The promoted breadcrumbs below are tagged `[→ SKL-0XX, applied]`; left in place for
> the trail rather than deleted. Un-promoted ones remain live watch items.

- 2026-07-22 · recurring-error · `[→ SKL-036, applied 2026-07-24]` Second time this session a drill's documented "self-cleaning" claim was wrong: `drill-project-list-views.sql`'s `database.md` entry said "self-seeding/self-cleaning" but the file has only an idempotent pre-cleanup, no cleanup at the end — it silently inflated `tPrograms`/`tProjects` row counts by +1/+1, breaking two unrelated drills' `COUNT(*)` assertions in the same regression pass that also caught `drill-revision-full.sql`'s undocumented truncate-and-reseed behavior (see the entry below). Neither was destructive individually, but together they show the drill suite's own self-description (in `database.md`) can't be trusted at face value — **verify a drill's actual cleanup behavior by reading the file, not by trusting its registry entry**, especially when a regression sweep's assertions depend on exact global counts. Same candidate DBA-chain rule as below, now with 2 independent occurrences. · myps
- 2026-07-22 · post-mortem · `[→ SKL-036, applied 2026-07-24]` Ran `drill-revision-full.sql` as part of a routine regression sweep without reading its header first — it's a "truncate + seed + validate, leaves data in place" script (own header says so), and it silently wiped the standard 6-program/14-project full-lifecycle mock that 2 earlier drills that same session had confirmed 26/26 PASS against. `database.md` already had a partial warning ("only drill-revision-full does [full-truncate]", written 2026-07-01/07/10) but it predated the full-lifecycle mock (ADR-052, 2026-07-20) and I didn't read down to it before acting. Recoverable (myps_db is dev/mock-only, reseed script exists), RISK-051 logged, database.md updated. Pattern: **before including ANY drill in a "safe" regression sweep, read its header/content first** — don't assume `drill-*.sql` implies non-destructive/self-contained just because most drills this session followed that convention. Candidate for a standing DBA-chain rule (dba-schema-drill.md). · myps
- 2026-07-22 · post-mortem · LS Wallet Phase-1 grounding caught 4 stale column assumptions in a "locked" field-spec doc before any DDL (funding col names Source/Agreement → SourceOrg/AgreementCode, OU width 40→20, tProjects-has-no-IsDeleted, funding-is-per-revision-not-project) + the drill then caught a 5th (AgreementCode/SourceOrg carry enforced option-lookup FKs). Reinforces: re-ground live types at build even when a field doc says "canonical/locked" — a doc locked weeks earlier drifts from as-built. Pattern worth a standing DBA-chain note. · myps
- 2026-07-21 · recurring-error · `(x IS NULL) <> (y IS NULL)` is not valid T-SQL (predicate isn't a comparable value) — a migration validation gate silently failed to *parse* (Msg 102) rather than raising, so the safety check was a no-op; DDL happened to be correct anyway (verified post-hoc via drill), but a bad gate would have looked identical to a passing one · myps
- 2026-07-20 · skill-fell-short · `[→ SKL-035, applied 2026-07-24]` **operator-caught, not self-caught**: built
  `myps-mock-full-lifecycle.sql`'s stage-advance loops from scratch (BP→P `ProjectId` swap, year-
  segment zero-padding) without checking whether a reference implementation already existed —
  it did, correctly, in `myps-mock-program-lifecycle.sql` (pre-ADR-050, historical:
  `N'P' + RIGHT(@Id, LEN(@Id)-2)` for the swap, `RIGHT(N'000'+CAST(...),3)` for the padding). Also
  never re-read `project-id-generation-spec.md` before writing the ID-construction logic, despite
  it being the exact locked, operator-confirmed spec for this. Shipped an "23/23 PASS" drill that
  never checked ID *format* compliance, only that IDs were "real generated." Operator: *"do you
  have or do you have no records or knowledge about the generation of the ProjectId?! it looks
  like you didn't plan thoroughly."* Correct — the records existed, weren't consulted · [myps] →
  **Promote.** SKL-011 ("design preflight — read your own prior deliverables first") was written
  for *schema* design specifically; this shows the same discipline is needed for **mechanism-level
  logic** (ID generation, stage-advance sequencing, any multi-step algorithm with a locked spec
  doc) — not just table shapes. Candidate rule: before writing any non-trivial procedural logic
  (loops, ID construction, state-machine transitions) in a new mock/drill, grep the spec docs AND
  prior mock/drill files for the same mechanism first — a working, already-correct implementation
  may already exist. Also: a drill that only checks "did generation run" without checking "does
  the output match the documented format" gives false confidence — format/spec-compliance checks
  are a distinct category from existence/behavior checks and shouldn't be assumed covered by the
  latter.
- 2026-07-20 · skill-fell-short · `[→ SKL-037, applied 2026-07-24]` a `dbo.RevisionMapType` table-type variable declared inside a
  `WHILE` loop (`DECLARE @RevMapA dbo.RevisionMapType;` re-executed each iteration, matching the
  scalar-variable pattern used successfully everywhere else this session e.g. `@ncid`/`@nwid`) does
  **NOT** reset between iterations — rows silently accumulate across hops. Confirmed via an isolated
  3-line repro (3 loop iterations → 1, 2, 3 accumulated rows). This caused `pCopyProjectDetailChain`,
  called once per stage-advance hop in `myps-mock-full-lifecycle.sql`, to re-copy an ever-growing,
  already-duplicated revision map — component/work-item counts inflated 3→92 across 6 hops before
  caught · [myps] → fixed by declaring the table variable ONCE outside the loop and adding an
  explicit `DELETE FROM @t;` as the loop's first statement. **Promote** — candidate rule for
  `dba-schema-drill.md`: scalar variables (`DECLARE @x TYPE = val;`) DO reset on each loop-body
  re-execution; user-defined TABLE TYPE variables do NOT — any drill/mock calling a
  `RevisionMapType`-style proc in a multi-hop loop must explicitly clear the table variable each
  iteration, never rely on re-DECLARE alone. First time this proc has been called in a loop at all
  this session (prior drills only called it single-hop) — the bug was latent, not previously
  triggerable.
- 2026-07-17 · recurring-error · `[→ SKL-037, applied 2026-07-24]` a shared component-Id variable (`@cc`) reused across sequential
  sibling `INSERT`s (CW→ROW→LS) got silently overwritten by the later inserts, so a subsequent
  statement needing "the first (CW1) component's Id" specifically picked up the wrong (last-
  inserted) one instead — found independently in TWO files this session (`drill-revision-full.sql`
  and `myps-mock-data.sql`), same root cause both times · [myps] → fixed both by capturing the
  needed Id into a dedicated variable (`@cc1CW`) immediately after its own `INSERT`, before any
  sibling `INSERT` can overwrite the shared one. Promote — candidate rule for
  `dba-schema-drill.md`'s authoring conventions: when a fixture inserts multiple sibling rows in
  sequence and a later step needs a *specific* one of them (not just "the most recent"), capture
  that one's Id into its own uniquely-named variable right after its INSERT — never rely on a
  shared/reused variable surviving past the next sibling insert.
- 2026-07-17 · post-mortem · the persistent `MOCK_PRG_SKIP`/`MOCK_PRG_FULL` mocks (seeded and
  validated 24/24 checks earlier this same session, per the ADR-049 cascade-fix pass) were
  silently wiped by an unrelated `myps-mock-data.sql` run during that same cascade-fix's
  verification pass — this is the exact SKL-031 trap (re-seed persistent mocks before validating,
  never assume they survived an unrelated script run) recurring in the same session SKL-031 was
  written and marked Resolved · [myps] → one occurrence so far post-SKL-031, but it recurred
  *immediately* (same session), which is a stronger signal than the usual "watch and see." Worth
  promoting alongside SKL-031's own follow-up: SKL-031 tells you to reseed before validating a
  persistent mock, but doesn't yet warn that *any* other script sharing the same core tables
  (`tPrograms`/`tProjects`/etc.) run in between can invalidate that reseed without any error —
  there's no cross-mock collision guard, only per-mock isolated-key conventions (SKL-032).
- 2026-07-16 · post-mortem · `database.md`'s Drills registry lists `drill-revision-views.sql`
  (21 checks) as an active, valid drill, but it had been silently missing from every "full suite
  re-run" this session (my own re-run command lists were built from memory/habit, not by
  re-checking the registry each time) — only caught while doing an unrelated `AlternateId`
  cascade-fix sweep. Also: my own new `drill-alternateid-relocation.sql` isn't self-cleaning (it
  validates real persistent mock data, like `drill-program-lifecycle.sql`/
  `drill-program-project-mock.sql`), but I put it in the reset-preceded self-cleaning loop anyway
  and got a spurious FAIL from my own sequencing mistake · [myps] → two related slips in one pass:
  (1) "full suite" lists should be regenerated from `database.md`'s registry each time, not carried
  forward from memory; (2) before adding a new drill to a suite-run loop, check whether it's
  self-cleaning (goes in the reset loop) or persistent-mock-validating (goes after a reseed,
  never after a reset). Promote — both are cheap, mechanical checks that would have caught this
  before execution instead of after.
- 2026-07-16 · recurring-error · broad `LIKE 'MOCK_PRG_%'`/`LIKE 'MOCK_PRJ_%'` wildcards in
  `myps-mock-program-projects.sql`'s cleanup AND `drill-program-project-mock.sql`'s assertions
  both accidentally matched a second, unrelated persistent mock's namespace
  (`MOCK_PRG_SKIP`/`MOCK_PRG_FULL`/`MOCK_PRJ_SKIP_%`/`MOCK_PRJ_FULL_%`, added same session) — the
  cleanup threw FK violations and partially wiped the other mock's `tProjectStages`; the drill's
  counts silently inflated (17 programs instead of 15) once both coexisted · [myps] → 2nd
  occurrence of the same root cause within one session (seed script, then the validation drill
  right after) — hit the exact same "broad wildcard doesn't isolate coexisting namespaces" trap
  twice in a row. Fixed both by narrowing to `MOCK_PRG_0%`/`MOCK_PRJ_0%` (the numbered series only).
  Promote — SKL-014's "isolated keys" drill-authoring convention needs an explicit rule: a mock's
  key prefix must be chosen so `LIKE 'prefix_%'` can never match a sibling mock's rows, not just
  "use a distinct-looking prefix."
- 2026-07-16 · post-mortem · re-running the full drill suite (each drill preceded by
  `reset-transactional.sql`) silently wiped the persistent `myps-mock-program-projects.sql`
  deliverable (15 programs + 35 projects) that had been delivered to the operator as "live data"
  earlier the same session — caught only by re-checking row counts after the suite finished, not
  anticipated beforehand · [myps] → one-off so far, fixed by re-running the seed script. Pattern
  to watch: "any full-suite re-run after this point should re-seed persistent mock deliverables
  afterward, not just re-verify drills." Promote if this recurs.
- 2026-07-07 · post-mortem · paused mid-execution of an already-approved destructive action (Pass-column
  drop) partway through dependent-checks, needed a "you stopped" nudge to finish · [system] → one-off,
  no proposal — an approved action with passing dependent-checks should run to completion without a
  restart prompt. Promote if this recurs. **2026-07-16 check:** a "you stopped" nudge appeared again
  during Components-domain planning, but conditions don't clearly match (that pause wasn't a
  destructive DB write with passing dependent-checks, more likely a conversational-momentum stop) —
  not promoted on incomplete evidence. Still watching for a clean match.
- 2026-07-16 · recurring-error · `sp_rename` failed on a bare unique index treated like a named
  constraint (Msg 15225) — fixed same message with the `'INDEX'` object-type qualifier · [myps] →
  true one-off, self-corrected in seconds, not promoted (threshold: pattern not one-off).
- 2026-07-08 · post-mortem · superseding the ADR-027/028 admin-area migration chain (ADR-029's re-split)
  broke the from-scratch rebuild order — the new migration script reads from a table no remaining
  rebuild step creates · [myps] → one-off, flagged in database.md not fixed. Pattern to watch: "when
  superseding migration files, verify the remaining chain still runs from empty." Promote if recurs.
- 2026-07-09 · manual-bridge · ADR-026's `tUserGroupMemberships` CSV→junction-table refactor broke the
  external ERGONS backend's `UpdateUser` controller (still wrote `.GroupIds = dto.UserGroupIds` against
  a table that no longer has that column) — dba-cross-domain-impact only scans in-repo consumers
  (drills/views/procs/docs), so an out-of-repo application controller consumer wasn't caught until the
  operator hit it directly · [myps] → one-off, fixed on request. Pattern to watch: "schema changes with
  known external app consumers should prompt an explicit 'check the backend controllers too' reminder,
  not just the in-repo scan." Promote if recurs.
## Workflow candidates (awaiting `/check-improvements` — Lane B)

- 2026-07-24 · `[→ WFC-010, logged/watch]` Surgical schema-change-through-a-locked-read-model
  playbook: ground consumers (`sys.sql_modules`) + data-loss precheck → gate (SKL-017) → guarded
  migrate → rewrite the exact locked readers → invert/retarget the drill IN PLACE + `sp_refreshview`
  → SCOPED (not full) regression → supersede prior ADR + sync docs same pass · [myps] → observed 2×
  same session (ADR-058 relocation, ADR-059 type change), both green, no rework. Promote on a 3rd
  independent sighting; the two novel bits to codify are "scoped-not-full regression" and "invert an
  existing drill in place."
- 2026-07-08 · Dual-layer workflow doc pass (user action + system operation per step, over an
  already-locked design) directly surfaced RISK-033 — a schema-blocking unspecified mechanism
  (frozen-Used at publish) that 4 prior higher-altitude docs (ADR, C4 model, schema doc, dynamic
  flows) all missed · [myps] → candidate, observed once (LS Wallet). Only execution-order
  granularity forces "and what exactly does the system write here?" Promote if a second module's
  workflow pass catches something comparable.
- 2026-06-25 · 4-diagram module documentation set (workflow state + data-flow + ERD + module-map) · [myps]
  → candidate, observed once — keep observing before codifying
- 2026-07-01 · User-level process walkthrough (plain-language ①–⑧ flow, confirm each step) before schema
  design on a business-rule-heavy module · [myps] → **log only, reviewed 2026-07-07** — the RBAC build
  ran process-first too, but that was `dba-process-interview` (the existing DBA chain) doing its job,
  not self-initiated freehand work. For DB modules this is already covered — only still a live
  candidate for **non-DB** modules where no chain currently mandates a process walkthrough first.

## Proposals (`SKL-` / `WFC-`)

| ID | Title | Priority | Recommendation | Status |
|---|---|---|---|---|
| SKL-035 | Mechanism-level design preflight — grep spec docs + prior mock/drill files before writing procedural logic (extends SKL-011 from schema to algorithms) | 🔴 | Applied: `dba-schema-ingest.md` §0 (mechanism-level preflight, beside the SKL-011 schema preflight) + `CLAUDE.md` §9 — before writing any non-trivial procedural logic (ID construction, stage-advance/copy-forward loops, state-machine transitions), grep the spec docs AND prior mock/drill files for the same mechanism first; a drill that checks "did it run" is NOT a spec-compliance check — assert output against the documented format explicitly. Operator-caught: rebuilt `ProjectId` BP→P swap + zero-padding loops from scratch when a correct reference existed, shipped a green drill that never checked format. | **Resolved** 2026-07-24 |
| SKL-036 | Drill-sweep trust discipline — read the drill's real behavior + read output unfiltered | 🟡 | Applied: `dba-schema-drill.md` rule 14 (registry tag/header is a HINT — verify a drill's real destructiveness/cleanup by reading it before a sweep, correct the registry if wrong) + rule 11 extended (filtered `PASS\|FAIL` output HIDES setup-phase `Msg` errors — on any unexpected FAIL, re-run UNFILTERED and diagnose Msg errors top-down first) + 2 checklist items. Clusters 2 occurrences (2026-07-22 `drill-project-list-views` false self-cleaning claim + `drill-revision-full` undocumented full-truncate wipe) + this session's `CW1` silent-FK-break diagnosis. Extends SKL-031/SKL-026. | **Resolved** 2026-07-24 |
| SKL-037 | Drill-authoring T-SQL variable-scope traps (extends SKL-014) | 🟡 | Applied: `dba-schema-drill.md` rule 15 + checklist item — (1) a user-defined TABLE-TYPE variable does NOT reset per `WHILE` iteration (unlike scalars): declare once outside + `DELETE FROM @t;` as the first loop statement; (2) a shared `SCOPE_IDENTITY()` variable is overwritten by sibling INSERTs: capture a needed sibling's Id into its own variable right after its own INSERT. Both confirmed-with-repro, both caused silent data inflation/wrong-row. 2026-07-20 (table-type var, counts 3→92) + 2026-07-17 (shared `@cc` across CW→ROW→LS, found in 2 files). | **Resolved** 2026-07-24 |
| WFC-010 | Surgical schema-change-through-a-locked-read-model playbook | 🟢 | **Logged, not built** 2026-07-24 — pattern ran cleanly 2× same session (ADR-058 relocation, ADR-059 type change): ground consumers via `sys.sql_modules` + data-loss precheck → gate (SKL-017) → guarded migrate → rewrite the exact locked readers → invert/retarget the drill IN PLACE + `sp_refreshview` → SCOPED (not full) regression → supersede prior ADR + sync docs same pass. The two novel bits not yet written anywhere: "scoped-not-full regression" and "invert an existing drill in place vs. new file." 2 same-session occurrences = minimum bar; hold for one more independent sighting before codifying into `dba-cross-domain-impact`/`dba-schema-changelog`. | **Logged, watch** 2026-07-24 |
| SKL-030 | CSV code-integrity precheck (Excel sci-notation corruption of long code/ID columns) | 🟡 | Applied: `dba-schema-ingest.md` §2 + checklist, `data-migration-playbook.md` stage 2 + WFC-007 step 6 + checklist — scan code/ID columns for `E+`/`e+` before trusting them as a join key; non-zero count requires a text re-export, not a reformat-back (lossy past ~15 digits). Same family as SKL-023. 2 occurrences (ADR-029 74 codes, ADR-047 99% of city HierarchyCodes). | **Resolved** 2026-07-17 |
| SKL-031 | Drill-suite runs from the registry + self-cleaning-vs-persistent routing | 🟡 | Applied: `dba-schema-drill.md` rules 12–13 + checklist — regenerate suite lists from `database.md`'s Drills registry each run (never from memory); tag each drill self-cleaning \| persistent-validator, reset-loop only for the former, reseed-first for the latter. Clusters 2 breadcrumbs (2026-07-16). Operationalizes SKL-013. | **Resolved** 2026-07-17 |
| SKL-032 | Mock key-prefix must be un-matchable by a sibling's `LIKE` (tighten SKL-014) | 🟢 | Applied: `dba-schema-drill.md` SKL-014 conventions rule 2 + checklist — choose a prefix so `LIKE 'prefix%'` can never match a sibling mock's rows (numbered `_0%` / distinct stem), not just "looks distinct." 2 occurrences same session; fix already applied ad-hoc this session (SADVPRG-/PUBPRG-). | **Resolved** 2026-07-17 |
| SKL-033 | `QUOTED_IDENTIFIER` is captured at proc/view-CREATE time, not runtime (Msg 1934 variant) | 🟢 | Applied: `dba-sql-object-chain.md` rule 8 + SP checklist — `SET QUOTED_IDENTIFIER ON`/`ANSI_NULLS ON` must precede `CREATE OR ALTER PROCEDURE/VIEW` (a SET inside the body does nothing against a filtered index); verify via `OBJECTPROPERTY(..., 'ExecIsQuotedIdentOn')=1`. New variant of the Msg-1934 family (SKL-005/019). Hit on `pRecomputeProjectPublishable` (ADR-045). | **Resolved** 2026-07-17 |
| SKL-034 | Pausing mid-approved-multi-phase execution ("you stopped") | 🟢 | **Deferred, not applied** — partly harness-driven (long tool sequences, compaction); 3 loose occurrences (07-07, 07-16, 07-17×2), weakest evidence of the batch. Operator confirmed proceeding with the other 5; this one stays a watch item. Promote only if it recurs with a clearer, consistent trigger. | **Logged, not built** 2026-07-17 |
| WFC-009 | Read-only structural-validation drill archetype for a reference-data lock | 🟢 | Applied: `dba-schema-drill.md` Reusable Techniques — new WFC-009, beside WFC-001 (transactional) / WFC-002 (seed-split): assert structure + constraints + view correctness + hierarchy integrity + real-data-untouched against live data, no fixture/mutation/cleanup. 1 clean occurrence (`drill-admin-area-v3.sql`, 12/12). | **Resolved** 2026-07-17 |
| WFC-008 | Dynamic lookup-value selection for drill fixtures | 🟢 | Applied: `dba-schema-drill.md` Reusable Techniques section — select real lookup values at drill-runtime (`SELECT TOP 1 NameId FROM tOptionXxx WHERE IsActive=1`) instead of hardcoding literals for app-enforced (no-FK) columns. Extension of SKL-006/008 to drill authoring specifically. Caught live: `drill-project-list-views.sql`, 11 lookup columns, 9/9 PASS first run, zero rework. | **Resolved** 2026-07-16 |
| SKL-029 | Schema-review findings must cross-check database.md before being flagged as gaps | 🔴 | Applied: `dba-schema-review.md` new Step 0 (preflight) + Rule 0 + checklist item — before any finding candidate becomes text, grep `database.md`/`decisions.md` for the table/column; if already documented as intentional, it isn't a finding. Distinct from SKL-011 (fires at interview kickoff only) — this fires at the review step itself. Caught live: 2 findings on `tProjectMajorWorkItem.ComponentId`/"ComponentId homonym" were both already documented in `database.md:196` — 3rd occurrence of the same root cause (LS Wallet C4-model miss, Lumpsum re-ask). Operator: "this kind of issue should not be happening multiple times." | **Resolved** 2026-07-16 |
| SKL-028 | Enumeration scoped by NAME-pattern silently drops in-domain objects | 🟡 | Applied: `dba-cross-domain-impact.md` Step 2 — domain-object enumeration must be scoped by catalog dependency (`sys.sql_modules` / `sys.dm_sql_referenced_entities` / `sys.foreign_keys`), never by name-pattern; name is a lossy filter that drops correctly-in-domain objects named otherwise. Caught live: porting "the user/permission views" by name (filtering on "User"/"Permission") missed `vAppModules` and would have missed `vAPIPermissions` too — 2 operator corrections in one task before a full `sys.sql_modules` sweep closed the search and surfaced 2 more candidates to assess-and-exclude. Same completeness-failure family as SKL-009/SKL-020, different mechanism (name-filter vs. catalog-dependency). | **Resolved** 2026-07-09 |
| SKL-027 | BOM-less UTF-8 + Windows PowerShell 5.1 = silently unrunnable scripts | 🟢 | Applied: root `CLAUDE.md` Tool Dependencies section — two new notes: (1) repo `.ps1` files stay ASCII-only or UTF-8-with-BOM, since PS 5.1 misreads BOM-less UTF-8 via the system codepage and the reported parse-error line number is misleading; (2) the engine-status table ("✅ Installed") reflects whichever machine last ran setup, not a global fact — re-run `verify-engines.ps1` after any machine move, don't trust the doc blind. Caught live: a single stray em-dash in `scripts/setup.ps1` broke its parser entirely, and `CLAUDE.md` claimed LibreOffice/Poppler were installed on a machine where they genuinely weren't (leftover from this repo's prior `khen`-user machine). | **Resolved** 2026-07-08 |
| WFC-007 | Client-file → embedded-staging reconciliation recipe | 🟢 | Applied: `data-migration-playbook.md` new "Reusable techniques" section, WFC-007 — 8-step recipe (script-read, bidirectional diff, math-check totals before executing, verify join-key uniqueness before joining, chunk staging INSERTs ≤500 rows, NULL-don't-guess for source corruption, self-contained embedded staging, drill+log-gaps not chase-to-zero). Promotion condition from the ADR-028 candidate ("promote on recurrence") was met by the ADR-029 AAMS backfill — hardened with 3 corrections that weren't visible after only 1 occurrence: the 1000-row VALUES limit, 108 cross-province town-name collisions (a name-only join would have silently cross-wired data), and the NULL-vs-guess rule for source-corrupted cells. | **Resolved** 2026-07-08 |
| SKL-026 | Drill scripts are code too — mismatched-column UNION causes phantom cascading failures | 🟡 | Applied: `dba-schema-drill.md` rules 10–11 + checklist — verification SELECTs must be per-table (never UNION across tables with different columns, which forces a phantom-column compile error that silently kills the whole seeding batch); on a first drill run, diagnose any compile-level Msg error top-down before trusting individual PASS/FAILs below it. Caught live: `drill-admin-area-v2.sql`'s own STEP 1 referenced a nonexistent `RegionId` column on the Region table — one compile error produced nine phantom FAILs shadowing the one real bug. This is the recurrence the 2026-07-08 breadcrumb ("promote if it recurs") predicted — happened within the same session. | **Resolved** 2026-07-08 |
| SKL-025 | Merge-then-split cycle — domain-cohesion signal documented but not surfaced as a recommendation | 🟡 | Applied: `dba-schema-review.md` new review dimension 11 (domain cohesion) + checklist item — before recommending/building a table merge, check for disjoint natural-key namespaces, different sync sources, different consumers, or type-conditional hierarchy; if 2+ signals present, present the split as the primary recommendation with the merge as a documented alternative, not the other way around. Caught live: ADR-027 merged 8 admin-area tables into 1 on a one-line operator request; the ADR-027 DDL's own header already noted "two separate natural-key namespaces coexist" — the signal was written down but never escalated into a counter-recommendation. ADR-029 split it back into 5 tables one session later after the merged `ParentId` semantics produced a real bug. | **Resolved** 2026-07-08 |
| SKL-024 | Hierarchy edges inferred from column presence, not confirmed per-edge kind | 🟡 | Applied: `dba-process-interview.md` Q6 — for tree/hierarchy entities, ask per edge which relationship is organizational vs. geographic vs. other, not just whether a parent-shaped column exists. `dba-schema-ingest.md` §5 rule 6 — same caveat, FK-like columns prove linkage existence not kind. Caught live: MYPS admin-area DEO's `ProvinceGdbId` was wired as `ParentId` on the "only candidate column" assumption — it was geographic, not organizational; the real org-parent (Region) needed an external authoritative file to surface, costing a full second reconciliation pass (ADR-028). | **Resolved** 2026-07-08 |
| SKL-023 | Post-deploy metadata drift + as-built NULL/domain profiling before seed | 🟡 | Applied: `dba-schema-drill.md` new Step 0 (metadata assert — cascade actions, nullability, uniqueness vs. deployed reality) + rule 9 + checklist item. `data-migration-playbook.md` stage 2 (TRANSFORM) + step 3 + checklist — profile source NULLs/domains against every target column that tightens a constraint before the load runs. Caught live: `tUserGroupMemberships` FKs deployed `NO_ACTION` vs documented `CASCADE` (caught by a pre-drill metadata query); seed `Msg 515` from `tGroups.CreatedDate` nullable-in-source/NOT-NULL-in-target (cost a full children-first reseed). Both from the same RBAC deployment session. **Addendum 2026-07-08:** extended both files + checklists — size-check discriminator/enum columns against your OWN planned literal set too, not just migrated data (a self-authored label can't be caught by profiling the source, since it never existed there). Caught live: `OrgType NVARCHAR(20)` truncated the self-authored label `'CongressionalDistrict'` (21 chars) — I'd just applied the original SKL-023 rule correctly to source data and missed applying it to my own invented literals. | **Resolved** 2026-07-07, addendum 2026-07-08 |
| SKL-022 | claude-mem MCP tools unreachable — documented everywhere, absent in practice | 🟡 | **Diagnosed, fix pending user action.** Root cause found (not "plugin is dead"): claude-mem's worker process is genuinely healthy (`.claude-mem/worker.pid` → live PID on port 37777), but its MCP server (`'.mcp.json'`, command `"sh"`) never registers because `sh.exe` (`C:\Program Files\Git\bin\sh.exe` / `...\Git\usr\bin\sh.exe`) is **not on the Windows system PATH** — only `C:\Program Files\Git\cmd` is, which has `git` but not `sh`. Claude Code spawns MCP servers as native Windows processes, so the `sh -c "..."` command silently fails to launch and the tools never surface, even though `enabledPlugins` says `true` and the plugin is correctly installed at `C:\Users\Msi\.claude\plugins\cache\thedotmack\claude-mem\13.4.0`. Confirmed live: `sh` resolves fine inside the Bash tool's Git Bash environment but `Get-Command sh` fails in native PowerShell. **Fix (one-time, operator action):** add `C:\Program Files\Git\bin` to the Windows System PATH (System Properties → Environment Variables → Path → New), then restart Claude Code. Not applied automatically — editing the machine-wide PATH is a persistent, machine-wide change outside repo scope, and its effect can't be verified until a fresh session start (MCP servers load once at session start). Docs (`CLAUDE.md` memory-tier table, `memory-hygiene.md`) left as-is pending verification — re-documenting to "claude-mem may be absent" would be premature given the fix is this concrete and cheap. | **Diagnosed 2026-07-07 — still awaiting PATH fix (confirmed unreachable again 2026-07-10 and 2026-07-17, 3rd consecutive `/check-memory` run blocked on the same root cause; no re-diagnosis needed, fix unchanged)** |
| SKL-017 | Tier-1 plan-gate drift — crisp instruction treated as confirmation | 🔴 | Applied: `CLAUDE.md` Standing Instruction #1 — multi-file or DB-mutating work requires a numbered plan + explicit go signal; a crisp request is not itself confirmation. Caught live: operator had to say "plan first, wait for my go" 3× in two days before this became the default. | **Resolved** 2026-07-07 |
| SKL-018 | Concurrent-session lane-file writes — no convention, near-miss | 🟡 | Applied: `CLAUDE.md` Standing Instruction #7 — re-read the lane file (and its `Next-ID` header) immediately before writing, never from stale context; merge alongside unexpected rows, never overwrite. Caught live: two parallel sessions both mutated `tasks.md`/`decisions.md` in the same window; no data lost only because the harness surfaced the diff. | **Resolved** 2026-07-07 |
| SKL-019 | T-SQL authoring + verification traps (sqlcmd bracket-strip, STRING_AGG, content-vs-count drills) | 🟡 | Applied: `dba-sql-object-chain.md` rules 6–7 (STRING_AGG WITHIN GROUP over undefined `@var += ORDER BY`; classic ODBC sqlcmd silently drops `[`-leading first lines of PRINT output — guard by never letting a bracket line be first). `dba-schema-drill.md` rule 8 + checklist — assert generated output CONTENT, not just row counts/LEN. Caught live: an hour chasing a vanished `[Table(...)]` line that two "green" checks (row counts, LEN) never would have caught. | **Resolved** 2026-07-07 |
| SKL-020 | Traceability gate missing from developer-handoff (RISK-026 root cause) | 🟡 | Applied: `developer-handoff.md` step 6 — bidirectional coverage check (forward REQ→ticket, reverse ticket→REQ; unbacked functions minted as DRAFT REQ- on the spot) as a standing handoff-time step, not audit-only. Closes RISK-026's recommendation (`myps/risks.md`). Caught live: 2 functions (incl. Program's most complex capability) shipped with zero requirement citation, found only on a later re-audit. | **Resolved** 2026-07-07 |
| SKL-021 | Design scatter — module spec re-assembled from 5+ docs, 3 separate times | 🟡 | Applied: `solution-design.md` step 12 + `database-admin.md` rule 7 — once a module's spec spans 3+ docs, build one canonical `<module>-schema.md` (wins on conflict, others point to it) proactively, not after a 3rd re-ask. Modeled on `ls-wallet-schema.md`, built 2026-07-07 after the operator asked for the same LS Wallet field list a third time. | **Resolved** 2026-07-07 |
| WFC-006 | Consumer-sync pass + terminal stale-term consistency grep | 🟢 | Applied: `dba-cross-domain-impact.md` Definition-of-Done rule 6 — after editing every consumer, grep the superseded concept's exact terms across all touched files; done only at zero live hits, reported as evidence. Merges the 2026-07-01 "consumer-suite audit-and-repair" candidate (same root pattern). Observed 2×: 07-01 drill-suite repair (6/6 green) and the 07-06/07 nine-document LS Wallet rewrite — both caught real stragglers the grep found that a read-through missed. | **Resolved** 2026-07-07 |
| WFC-005 | Module delivery pack: developer-handoff → test-strategy → FE/BE breakdown → user-level QA plan → board cards | 🟢 | Applied: documented as a "natural chain" in `developer-handoff.md` (Trigger section) + a pointer in `skills.md` §6 for both `developer-handoff.md` and `test-strategy.md`. No new skill built — the chain reuses 4 existing skills; only the sequencing + the two success factors (sync consumers same pass; one owner per shared service) needed writing down. Observed 6× (Program/Project-Components/Groups/Revision/tTransactionLog in this thread + LS Wallet in a parallel session — independent re-derivation was the strongest promotion signal). | **Resolved** 2026-07-03 |
| SKL-016 | New-skill "done" = ALL five consumers updated (wrapper, CLAUDE.md, skills.md, README, counts) | 🟡 | Applied: consumer checklist added to `new-skill` step 6 (slash wrapper + CLAUDE.md + skills.md + README + counts); all 52 skills registered as `.claude/commands/` wrappers same day (SKL-012 visibility resolved). Caught live: task-board build declared done with README stale — SKL-010's lesson recurring for skill additions. | **Resolved** 2026-07-03 |
| SKL-015 | Homonym trap: renamed column shares its name with a live column on another table | 🟢 | Applied: homonym caveat added to `dba-cross-domain-impact` §6b (cascade-rename). A global find-replace of a renamed column is unsafe when the old name still legitimately names a column on a *different* table (`TransactionId` dropped from tTransactionLog but live on tRevisionDetails) — disambiguate by table, then re-grep the old name and confirm every survivor's table still owns it; stragglers hide in the WHERE/DELETE filter position, not the INSERT/SELECT you edited. Caught live: `WHERE TransactionId IN (…)` cleanup line survived the rename; drill re-run (SKL-013) flagged it. | **Resolved** 2026-07-01 |
| SKL-013 | Re-run EVERY drill + verify green after any schema change (extends SKL-010) | 🔴 | Applied: DoD gate extended in `dba-cross-domain-impact` (rules 5–6 + checklist), `dba-schema-changelog` (DoD + rule 6), `dba-schema-drill` (rule 6 + checklist), `CLAUDE.md` §9. Drills are executable consumers — execute EVERY drill to green after a schema change; no doc labels a drill valid without an execution. Caught live: 5/6 broken while docs vouched for all 6. | **Resolved** 2026-07-01 |
| SKL-014 | Drill-authoring hygiene: isolated keys + self-seed/clean-slate + `QUOTED_IDENTIFIER` | 🟡 | Applied: `dba-schema-drill` new "Drill-authoring conventions (SKL-014)" section + rule 7 + checklist (header SET options, unique business-ID namespace, self-seed FK parents, full-truncate/clean-slate, idempotent). Shipped reusable `memory/clients/myps/myps-system/scripts/reset-transactional.sql` (children-first, `QUOTED_IDENTIFIER ON`). Enables SKL-013 to run cleanly. | **Resolved** 2026-07-01 |
| SKL-012 | Trigger table says "Invoke X" but employee skills aren't registered Skill-tools | 🟢 | Applied 2026-07-01: one-line note in `skills.md` §6 — employee skills are read-not-invoked; `Skill()` returns *Unknown skill*, read the `.md` file instead. **Superseded 2026-07-03:** the actual visibility gap was closed by SKL-016 — all 52 skills registered as `.claude/commands/` wrappers, so they now appear as real slash commands. The read-not-invoked note stays valid for the `Skill()` tool path. | **Resolved** 2026-07-01 (fix completed 2026-07-03, see SKL-016) |
| SKL-005 | Standardize sqlcmd invocation across shells | 🟡 | Applied: standing instruction in `CLAUDE.md` §9 — always run sqlcmd via PowerShell (`& sqlcmd … -Q`/`-i`), never Git Bash (the `-i` path throws a misleading "-E and -U/-P mutually exclusive" error). 4th+ recurrence, 0 failures once switched. | **Resolved** 2026-07-01 |
| SKL-011 | Design preflight: read the project's OWN prior deliverables before re-interviewing a module | 🔴 | Applied: `dba-schema-ingest` §0 (design preflight) + `CLAUDE.md` §9 standing rule. A NEW circle beyond SKL-006/008 — ground in your own confirmed deliverables, not just the source system. Caught live: ~10-turn `tLumpSumDetails` interview when confirmed `tLSWallets` C4 model + 8 flows already existed. | **Resolved** 2026-07-01 |
| SKL-006 | Ground in the as-built source before building | 🔴 | Applied: `dba-schema-ingest` §5 + `CLAUDE.md` §9 + cross-session memory | **Resolved** 2026-06-25 |
| SKL-007 | Drills must use full-content fixtures, not hollow | 🔴 | Applied: `dba-schema-drill` §7 + §1 + fail criteria + checklist | **Resolved** 2026-06-25 |
| SKL-008 | Extend grounding to generated FORMATS + derivation rules | 🔴 | Applied: `dba-schema-ingest` §5.5 + `CLAUDE.md` §9 — verify generated IDs (e.g. `BP01000001LZ`) + rollups, not just enum values. Caught after SKL-006 "resolved" (invented ProjectId). | **Resolved** 2026-06-26 |
| SKL-009 | Completeness must enumerate the FULL child graph | 🔴 | Applied: `dba-schema-drill` §7 — assert every FK-child (funding/costs/cost-yr/work/locations/statuses), not a hand-picked subset. Caught after SKL-007 "resolved" (component-depth gap). | **Resolved** 2026-06-26 |
| WFC-001 | Transactional routing drill (force→verify→ROLLBACK) | 🟢 | Applied: codified as a technique in `dba-schema-drill` (Reusable techniques). Proven 4+ times across revision views. | **Resolved** 2026-06-26 |
| WFC-002 | Seed / drill split (reusable fixture + validation gate) | 🟢 | Applied: convention in `dba-schema-drill` (Reusable techniques). `*-mock-data.sql` (persistent seed) + `drill-*.sql` (validate). | **Resolved** 2026-06-26 |
| SKL-010 | Schema change isn't "done" until consumer docs updated (same pass) | 🔴 | Applied: definition-of-done gate in `dba-cross-domain-impact` + `dba-schema-changelog` + `CLAUDE.md` §9; step-6 widened to FK width + GO-batch checks. Operator prompted 2× re docs this session — docs are consumers, not follow-ups. | **Resolved** 2026-06-27 |
| WFC-003 | Synonym-based env-switch for external dependencies | 🟢 | Applied: pattern note in `references/integrations.md`. dev (Mock_PCMA) vs prod (linked server) via one synonym; views never hardcode environment. | **Resolved** 2026-06-27 |
| WFC-004 | Live-overlay view for externally-owned data (don't store) | 🟢 | Applied: pattern note in `references/integrations.md`. External-system-owned fields (PCMA construction status) → read-time view overlay, not stored columns. | **Resolved** 2026-06-27 |

**SKL-010 root cause (definition-of-done gap):** the *grounding* lessons (SKL-006/008) landed —
this session I verified ComponentId/casing/FK against the real source before designing. But the
*"done means consumers updated"* lesson hadn't: I changed the schema, declared done, left 6 docs
stale until the operator asked twice. The skill (`dba-cross-domain-impact`) already lists docs as
consumers — the gap was not firing it. Fix makes consumer-update part of definition-of-done.

**Root cause (SKL-006/007/008/009): circular validation** — generating data from assumption X,
building code assuming X, drilling against that data. All share X, so the drill can't catch a
wrong X. Only an external source (as-built system, operator) breaks the circle. SKL-006/007
fixed the *enum* and *snapshot* cases; SKL-008/009 extended the same principle to *generated
formats* and the *full child graph* after the operator caught both recurrences in the same session.
The deeper fix is behavioral: confirm formats + graph shape with the operator **up front**, before
building — cheaper than any post-hoc drill assertion. See [[verify-against-as-built-before-building]].

## Resolved

| ID | Source breadcrumb | Outcome | Date |
|---|---|---|---|
| SKL-001 | repeated-manual-work: migrated 40 lookup tables by hand + post-mortem: seed circular-dependency | Built `data-migration-playbook` skill (map→transform→order→validate→rollback; circular-dep trap designed out) | 2026-06-24 |
| SKL-002 | manual-bridge: schema→developer handoff done freehand | Built `developer-handoff` skill (`DEV-` tickets, acceptance criteria, build order, coverage check) | 2026-06-24 |
| SKL-003 | skill-fell-short: create-diagram Mermaid-only, needed C4 | Enhanced `create-diagram` with C4 Context/Container + Data Flow Diagram templates | 2026-06-24 |
| SKL-004 | recurring-error: column-mismatch bugs after ADR-018 bulk rename | Enhanced `dba-cross-domain-impact` with the cascade-rename paired-list trap (grep old+new name, verify INSERT↔SELECT/JOIN pairing) | 2026-06-24 |
| — | ad-hoc-process: building views/TVFs with no guiding skill | **No new skill** — already covered by existing `dba-sql-object-chain` (purpose→deps→draft→plan→drill); declined as duplicate | 2026-06-24 |

> Also built in the same enhancement (plan-driven, not breadcrumb-driven): the meta-skill trio
> `self-improvement` / `workflow-capture` / `memory-hygiene`, plus `api-contract-design`,
> `test-strategy`, and `calibration-review`. Full record in root `CLAUDE.md` → Build Status.

- [breadcrumb 2026-07-17] Recurring data-quality error: Excel mangles long numeric codes into scientific notation (e.g. `1.03171E+12`). Bitten twice now — 74 CityMunicipality.Code values in the ADR-029 AAMS backfill, then 99% of HierarchyCode in the ADR-047 source CSVs (AdminArea*). Any operator-supplied CSV with long numeric ID/code columns should be validated for `E+` before load, and the export should force those columns to text. Candidate SKL: a standing "CSV-code-integrity precheck" step in dba-schema-ingest / ingest-reference. **→ Promoted to SKL-030 (proposed 2026-07-17, awaiting go).**

- [breadcrumb 2026-07-17] Recurring pattern: a seed/drill script reuses ONE variable (e.g. `@cc`) across sequential sibling INSERTs (CW component -> ROW component -> LS component), each overwriting it via `SET @cc=SCOPE_IDENTITY()` — by the time a LATER statement needs "the first (CW1) component's Id" specifically, the variable silently points at the wrong (last-inserted) row instead. Found independently in 2 files (`drill-revision-full.sql`, `myps-mock-data.sql`) during the ADR-049 work-item/location restructure. Fixed both by capturing the needed component's Id in its OWN variable immediately after its INSERT, before any sibling INSERT can overwrite the shared one. Candidate rule for dba-schema-drill.md: when a fixture inserts 2+ sibling rows via the same `SCOPE_IDENTITY()`-capturing variable, and a LATER statement needs one specific (non-last) sibling's Id, capture it into a dedicated variable at that point — never assume the shared variable still holds it.
