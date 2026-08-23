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
| User Permissions (RBAC) module | MYPS / myps-system | ✅ Reverted to LOCAL-MYPS as-is shape 2026-07-10 (ADR-031, supersedes ADR-026 + ADR-030) — schema+views+drills green | None — done | 🟢 |
| LS Wallet (Module 11) | MYPS / myps-system | Design locked (ADR-025); workflow doc completed 2026-07-08; build not started | Resume schema/build session when prioritized | 🟡 |
| Multi-Year Planning (Module 12) | MYPS / myps-system | **ON HOLD 2026-07-10** — 2 independently-sourced drafts reconciled (REQ-F101–F122 vs. new user-stories file); 1 unresolved mechanism conflict (auto PIP-sync vs. manual AIP-linking) | Dedicated client/operator reconciliation session before any further design | 🟡 |
| Bulk project import (Excel → background) | MYPS / myps-system | ✅ Core mechanism BUILT 2026-07-16 (ADR-043) — `tImportJob` hard-reject lock + `tProjectIdSequence`/`pReserveProjectIdBlock` atomic ID allocation, drilled 10/10. Hangfire REC (2026-07-15) still the recommended queue layer. | Kafka/SignalR/EF Core backend integration is specified (`project-import-kafka-signalr-flow.md`) but **not yet implemented** — dev/infra lane. Category-range exhaustion deliberately deferred (operator decision). | 🟢 |
| `vProjectCivilWorkCosts` port | MYPS / myps-system | ✅ **DONE 2026-08-05 (ADR-072)** — ported from LOCAL-MYPS, redesigned approved-only (fixes a double-count bug the source had), `ExportToPCMA`-driven scope (6 types, not just Civil Works — name undersells scope, kept per operator's literal ask). 8/8 drill PASS, 18 active drills green overall. | None — closed. | 🟢 |
| Admin Area ProvinceId→ProvinceCode migration | MYPS / myps-system | ✅ **DONE 2026-08-04 (ADR-073)** — City/CongDist now key on `ProvinceCode`→`Province.Code` (business key), not surrogate `ProvinceId`. **Surfaced by a LIVE CONCURRENT SSMS schema change mid-session** — watch for more if the operator is actively editing this DB in parallel. 3 issues found+fixed: missing unique constraint on `Province.Code`, a blocking dependent index, and an unrelated dropped index (`IX_..._Code` on City) from the same concurrent session. 17/17 drills green. | None — closed. Data-quality issues (dup/NULL City codes) still pending `admin-area-code-repair-plan.md`. | 🟢 |
| LS Wallet mock coverage (GAP-2) | MYPS / myps-system | ✅ **DONE 2026-08-04 (ADR-071)** — D2 (the mock's only `ProjectType='LS'` project) now has a real wallet (Amount=50M matching its funding draw), `ParentWalletId` linked, `IsWalletDraw=1` fixed. `tLSWallets` added to mock cleanup (was missing). Uncovered+fixed 2 stale drill asserts that never exercised the wallet-sum formula (35M→85M, verified correct). 13/13 drills green; `drill-component-lifecycle.sql`'s separate wallet-less fixture confirmed unaffected by design. | None — closed. Remaining: `AlternateId` format, Phase B (blocked), backend wiring. | 🟢 |
| Stage ordering fix (RISK-054) | MYPS / myps-system | ✅ **DONE 2026-08-04 (ADR-070)** — 5 read-model objects now gate on `StageHierarchy` (process order) not `StageId` (surrogate order); `StageHierarchy` made NOT NULL. Guard drill 2 FAIL→4 PASS; equivalence proven 323=323, 0 diffs both ways. Was **latent, not live** (I had wrongly said 12 objects/live defect; actually 5 objects, 0 project rows above stage 7). BOM issue in both SQL files found+fixed same day, both cleanly re-runnable now. Rollback: `_rollback-stage-gate-definitions-20260804.sql`. | None — closed. | 🟢 |
| Mock lookup integrity + traps | MYPS / myps-system | ✅ **DONE 2026-08-04 (ADR-069)** — all geography/office columns now resolve to REAL lookups AND are internally consistent (was `'10-001'` ×135, in no lookup table). `drill-mock-lookup-integrity.sql` 9/9. `AlternateId` = user free-text, never lookup-bound (CHK8 guards it). | **Mock run order is now 4 STEPS** — seed 1→2→3 then `_mock-lookup-normalization-block.sql`; step 1 self-checks and warns if incomplete. **⚠️ `drill-revision-full.sql` is DESTRUCTIVE but now INTERLOCKED** (defaults to abort). Open: AlternateId format unconfirmed, GAP-2 orphan LS project. | 🟢 |
| Mock data coverage (GAP-1 overlay) | MYPS / myps-system | ✅ **CLOSED 2026-08-04 (ADR-068)** — `PRG-2026-K001` + K1/K2/K3 make the ADR-062 approved-revision overlay execute in the PERSISTENT mock for the first time (was 0 projects). 14/14 drill PASS + permanent tripwire. GAP-3/GAP-6 closed on the same rows. 3rd leaky drill fixed. | Remaining mock gaps: GAP-2 (1 orphan LS project), Phase B (projects under G/H/I/J — blocked on ProjectPK format for non-BP-starting programs). **⚠️ `drill-revision-full.sql` is DESTRUCTIVE (truncates all projects/programs) — never include in a bulk sweep.** | 🟢 |
| Program type → stage gating | MYPS / myps-system | ✅ **BUILT 2026-08-03 (ADR-067)**, schema + 15/15 drill PASS. **Mock Q1 also done same day** — 4 new programs (G/H/I/J) proving the rule, incl. J = first data where raw `StageId` order ≠ real process order (RISK-054 made concrete). | **Backend wiring not done** (app-side enforcement). Mock **Phase B (projects) still deferred** — needs ProjectPK format rule for a non-BP-starting program. Also open: `StageId`-vs-`StageHierarchy` ordering ADR; RISK-058/059 logged; **2nd drill-residue leak found** (`drill-full-lifecycle.sql`, joins `drill-component-lifecycle.sql` in the held rebuild plan's P0). | 🟢 |
| ~~Program type → stage gating (plan)~~ | MYPS / myps-system | ⏸️ ~~ON HOLD 2026-08-03~~ — superseded by the row above — full plan written + grounded against live legacy DB, **zero DDL executed** (`program-type-stage-gating-plan.md`). Design settled: new `tProgramTypeStages` junction + `tOptionProgramType.Code` + `tOptionProgramStage.ProgramGroup` + missing `FK_tPrograms_Type` + 2 views mirroring the `vAPIPermissions` pattern. **Key finding that stands regardless: this ANSWERS RISK-054 — program stages are (B) parallel tracks, not linear** (`T`→`TF`/`TF-R` only; `E`/`A`→`GAA`/`GAA-R` only; only `R` walks the full pipeline). | Answer the 5 questions in plan §8 — **Q5 is the blocker**: confirm with operator/client whether External & Automatic Appropriation really skip `BP`→`HGAB`. Rule comes only from retired-system data, never human-confirmed. Then execute P1–P8. | 🟡 |
| Data-access filtering (`ApplyFilter`, program + project level) | MYPS / myps-system | ⏸️ **UNBLOCKED 2026-07-17** — was on hold (RISK-046) pending the admin-area lock, which is now done (ADR-047). The region resolver (`vAdminOfficeRegion`) this depends on already exists. | Resume via the DBA interview chain (operator's chosen path) when prioritized — open questions + deliverable shape in `data-access-filtering-onhold.md` | 🟡 |

### Last Session

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
