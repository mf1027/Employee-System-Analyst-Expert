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
| ProjectExceptionReport (`IsPublishable` gap explainer) | MYPS / myps-system | 🔴 **REVERTED 2026-09-03** — built + audited + drilled (Internal-ready) 2026-09-02, then operator reverted the working-tree changes before frontend wiring. `git status` on `project_myps` (`dev-trunk`) confirmed clean; none of this code currently exists. | Re-apply from the preserved reference implementation in MYPS vault `14 - Testing/Backend Deployment Readiness.md` when resumed — design/DB rule set/drill evidence don't need re-deriving. | 🔴 |

### Last Session

- **2026-09-03 — `fRevisionQueue`, 4th same-day pass: `CurrentStage` always resolves to a real
  group now, `project_myps`.** After Pass 3 shipped, operator repeatedly re-ran
  `SELECT * FROM fRevisionQueue('caldokp', 0, 0)` reporting it still looked unfixed — turned out to
  be correct output each time (none of that user's real revisions were in an RPC/PS-Admin-pending
  state), confirmed via `sp_helptext` re-checks and rollback-only proof queries each round, until
  the operator made the actual ask explicit: `CurrentStage` should NEVER show `OWNER`/`REJECTED`/
  `DONE` — every branch should resolve to a real group. Grep confirmed no submitter-group check
  exists anywhere in this workflow. **Critical dependency caught before deploying**: the `WHERE`
  clause keyed visibility off `CurrentStage`'s string value (Pass 3's design) — collapsing it to
  just 2 values would have silently broken Pass 1's visibility fix. Fixed with an internal-only
  `StageBucket` column carrying Pass 3's exact classification under renamed literals, freeing
  `CurrentStage` for pure display. Mid-build, operator refined further: "For Correction" should
  show the **requestor's** group, not a reviewer's. This led to discovering `dbo.tUserGroups.
  GroupIds` (JSON array of Group IDs per user) → `dbo.tGroups` — a real, general-purpose
  user-to-group resolution mechanism neither I nor the earlier passes had found (confirmed live:
  `caldokp` resolves to group `DPC`). Final confirmed design (after one more clarifying round):
  `Rejected`/`Done` stay reviewer-based, `For Correction` uses the requestor's real group. Also
  independently caught: the repo's tracked `.sql` file had already drifted from what was actually
  deployed (missed applying Pass 3's own `StageBucket` rename to the `WHERE` clause) — corrected
  before layering this pass on. Proven via 2 rollback-only drills, deployed live with approval,
  `dotnet build` clean (SQL-only pass, no C# changes needed). Full detail: Obsidian vault
  `MYPS/14 - Testing/Backend Deployment Readiness.md` → "Revision readiness" 2026-09-03 entry,
  4th same-day pass.
- **2026-09-03 — `fRevisionQueue`, 3rd same-day pass: `CurrentStage` relabeled to real group
  identity + "Endorsement" terminology, `project_myps`.** Operator asked what the `CurrentStage`
  CASE was for; after explaining it, operator requested: display `RPC` instead of `RO`, `PS Admin`
  instead of `CO`, and `For Endorsement` instead of `For Approval` when `ROStatus=0`. A live,
  read-only `tGroups` query resolved the key ambiguity: `RPC`/`AUC` are real `GroupName` rows
  ("Regional Planning Coordinator"/"Application User Coordinator"), but **no "PS Admin" row exists
  anywhere** — it's purely a UserManual documentation term (60+ occurrences), so displaying it
  requires a hardcoded label, not a table lookup. 2 Explore agents confirmed `CurrentStage` is
  never shown in the frontend (safe to relabel) and that "Endorse" (vs. "Approve") is already an
  established FE-only term for RPC's action specifically because RPC only forwards to PS Admin,
  it doesn't finalize. Found a genuine conflict: "For Endorsement" doesn't match the frontend's
  fixed badge-color keyword list, so that state would render gray instead of yellow — surfaced via
  `AskUserQuestion` rather than resolved unilaterally. **Operator's explicit call: no frontend
  changes, ship the correct text, accept the color trade-off.** Implemented, drilled
  (`DRILL_REVQUEUE3_20260903`), deployed live with approval, re-verified, UserManual updated again
  in both copies (added a Terminology callout + a note documenting the accepted gray-badge
  trade-off). Full detail: Obsidian vault `MYPS/14 - Testing/Backend Deployment Readiness.md` →
  "Revision readiness" 2026-09-03 entry, 3rd same-day pass.
- **2026-09-03 — `fRevisionQueue` status/filtering, 2nd pass: correction + extension, `project_myps`.**
  Operator re-flagged the same UserManual quote from the pass below and pointed out "the display
  logic is not implemented" — investigation (plus one `AskUserQuestion` round to pin down which of
  3 plausible gaps they meant) confirmed: last pass's collapse of RO-pending and CO-pending to
  identical `For Approval` text made the RO→CO hand-off invisible, even though the underlying CASE
  logic already picked the correct value. Then operator asked for "a thorough analysis to see other
  gaps as well" — 2 more Explore agents exhaustively swept every `ROStatus`/`COStatus`-combining
  site in the backend (found nothing else broken; confirmed `fRevisionDetail()` was already correct
  despite a stale FE code comment claiming otherwise) and every other revision-status text
  producer/consumer including the frontend (read-only check, not modified — found a 3rd,
  independent, FE-side hand-maintained status mapping that currently happens to agree with the
  backend vocabulary by coincidence, flagged not touched). Fixed: CO-pending now reads `For
  Approval of Central Office` (distinct from RO-pending's plain `For Approval`, both still satisfy
  the frontend's yellow-badge keyword match). Same pass also completed the separately-requested
  Program Name filter + Revision Status dropdown work: `fRevisionQueue` gained
  `ProgramName`/`ProgramId`/`ProgramFK` via `LEFT JOIN vProjectLatest`, wired through
  `RevisionRequestsFilter`/`RevisionController.RevisionRequests` (partial-match filter), plus a new
  `ShowRevisionStatusDropdown` endpoint (static 5-value list — a `SELECT DISTINCT` would wrongly
  omit any status with zero current rows). Proven via a 2nd rollback-only drill against all 4 real
  revisions, deployed live with explicit approval, re-verified, `dotnet build` clean. UserManual
  updated again in both copies. Full detail: Obsidian vault `MYPS/14 - Testing/Backend Deployment
  Readiness.md` → "Revision readiness" 2026-09-03 entry (same-day 2nd-pass addendum).
- **2026-09-03 — `fRevisionQueue` status/visibility fixed, drilled, and deployed live to
  `myps_db_dev` for `project_myps`.** Operator flagged the UserManual's Revision List status-badge
  legend and RO/CO visibility rules didn't match reality. `/plan-analysis /code-behavior-audit
  /rollback-readiness-test` requested together; 3 Explore agents + live DB reads confirmed: the
  repo's checked-in `Revision.Queue.sql` had drifted completely from the live DB (wrong parameter
  signature, wrong status numbering, wrong text — redeploying it would have regressed the
  database); CO users could see zero Rejected/For-Correction/Approved revisions and RO couldn't see
  Approved ones (exactly matching the operator's mid-investigation report); and live status text
  didn't satisfy the frontend's fixed keyword-matching badge logic (yellow/dark-red unreachable in
  production). **Operator explicit constraint: backend-only, no frontend file touched.** Fixed
  `fRevisionQueue`'s `WHERE` clause (visibility) and 4 status strings (renamed to the UserManual's
  exact legend names, collapsed role-agnostic per operator confirmation), removed a dead `@IsRO=2`
  branch. Proved via a rollback-only drill against all 4 real revisions in `myps_db_dev`
  (2 states synthesized via temporary in-transaction UPDATEs), then **deployed for real**
  (operator-approved) and re-verified live — identical results. UserManual corrected in both
  near-duplicate copies (`FE/UserManual.md`, `documents/UserManual.md`) to describe the actual,
  now-fixed behavior. Verdict: GO WITH CONDITIONS — DB-level fix proven and live; authenticated
  HTTP test deferred because unrelated, pre-existing, uncommitted changes already sit in the same
  controller (not made this session — an `[AllowAnonymous]` addition, a null-guard reorder, a
  `pRecomputeProgramCost` argument fix — left untouched). Full detail: Obsidian vault
  `MYPS/14 - Testing/Backend Deployment Readiness.md` → "Revision readiness" 2026-09-03 entry.
- **2026-09-03 — ProjectExceptionReport (2026-09-02 build) reverted by the operator; documentation
  updated to reflect it.** Operator reverted all 4 changed files in `project_myps` (`Helpers/
  ProjectHelper.cs`, `WebAPI/Controllers/Programs/ProgramController.cs`,
  `WebAPI/Controllers/Programs/DTOProgram.cs`, `WebAPI/Controllers/Projects/ProjectController.cs`)
  — confirmed via `git status` on `dev-trunk`: fully clean, nothing was ever committed so no
  code-level revert was needed beyond discarding the working-tree edit. None of the built logic
  exists in the codebase as of this session. Per the operator's explicit "make sure this is well
  documented" instruction, updated the vault (`Backend Deployment Readiness.md`'s
  "ProjectExceptionReport Readiness" section, the Dashboard) to mark every prior "Built:"/status
  claim as historical, and added a full copy-paste-ready reference implementation (all 4 files,
  reconstructed from the session transcript) so a future re-implementation doesn't need to re-run
  the `sp_helptext`/rollback-drill DB investigation. The design finding itself remains valid and
  unaffected by the revert: `pAllowProjectPublishing`'s own "Detailed project validation" result
  set was (and still is, in the current unreverted code) being silently discarded by
  `ExecuteSqlInterpolatedAsync` in `BatchAllowPublish` — that gap is unchanged, only this session's
  fix for it was undone.
- **2026-09-02 — ProjectExceptionReport built for `project_myps` (real app repo, not this one),
  audited, drilled, put on hold pending frontend.** `/plan-analysis` requested to build a report
  validating projects against `ProjectController.UpdateProjectDetails`'s `#region Validations`;
  operator reframed mid-plan to its real purpose — for a selected project, explain what's still
  missing before `IsPublishable` can become true, because `ProgramController.BatchAllowPublish`
  lets a user force-allow publishing for a restricted project with zero visibility into why.
  Investigation found `pAllowProjectPublishing`'s own already-computed "Detailed project
  validation" result set was being silently discarded by `ExecuteSqlInterpolatedAsync`. Built
  read-only `GetProjectExceptionReport` in `Helpers/ProjectHelper.cs` (reuses the same 5 read-only
  TVFs both publishability procs already call — zero rule-drift risk, zero new writes); rewired
  `BatchAllowPublish` to capture the proc's own detail result set via Dapper; added 2 new read-only
  endpoints. `code-behavior-audit` (GO WITH CONDITIONS, 2 safe fixes applied) and
  `rollback-readiness-test` (Internal-ready — live rollback-only drill against `myps_db_dev`
  confirmed the new code's message wording matches the real proc's output word-for-word) both run
  per operator's explicit request. **On hold before frontend wiring** — the backend now computes
  the "why," but nothing displays it yet, so the operator's actual reported problem isn't visibly
  fixed. This is a **MYPS engagement task, not an advisory-repo decision** — per the 2026-09-01
  ledger cutover, no new ADR/RISK ID was minted here or in `decisions.md`/`risks.md`; full detail
  lives in the Obsidian vault: `MYPS/14 - Testing/Backend Deployment Readiness.md` →
  "ProjectExceptionReport Readiness - 2026-09-02", cross-referenced from the Current State
  Dashboard. Code changes uncommitted in `project_myps`.
- **2026-09-01 — Vendored `plan-analysis` into this repo + 3 `codex-behavior-parity.md` guardrail
  refinements (ADR-136).** Canonical top-of-stack: `decisions.md` → ADR-136 (`Next-ID: ADR-137`).
  Operator asked for "all necessary global skills" embedded so a clone of this repo is
  self-sufficient, then expanded to "fully inherit all the chatgpt skills and behavior if possible."
  5-pass research found the honest scope narrow: `plan-analysis` was the only skill referenced but
  missing (now vendored at `.claude/skills/plan-analysis/`, byte-identical, git-tracked — auto-
  discoverable on clone, no global-install step). gstack + its ~50-skill family deliberately
  excluded — the tool itself warns against being vendored into a project. Codex's 6 `.system/`
  skills evaluated individually, all skip (4 OpenAI-runtime-hardwired with no Claude equivalent, 2
  already superseded by Claude's native `/code-review` and this repo's own `new-skill.md`). Closed 2
  real behavior gaps in `codex-behavior-parity.md` (the `appsettings.Development.json` commit-gate
  rule and the widened ADR-107 footprint rule — both previously self-contained only in the
  operator's personal global config, not this repo, so a fresh clone wouldn't have inherited them).
  **Deferred, explicit:** `~/.codex/config.toml`/`hooks.json`/`rules/` not audited — secret-bearing-
  file caution. Status COMPLETE_WITH_RESIDUAL_RISKS. Not synced to Obsidian — agent-infrastructure,
  not MYPS domain knowledge, out of that vault's scope by design. Full detail: `decisions.md`
  (ADR-136).
- **2026-08-31 — RISK-111 found and fixed (ADR-135), RISK-105 resolved by the same fix: Program-
  stage BP-to-first-stage ProjectId swap had no cross-project collision check.** Canonical
  top-of-stack: `decisions.md` → ADR-135 (`Next-ID: ADR-136`), `risks.md` → RISK-111
  (`Next-ID: RISK-112`). Operator asked for a thorough `/plan-analysis` on "conflict imported
  projectid with the created projectid on the system itself." 3-agent research confirmed RISK-105/
  ADR-130 had already found the concurrency-race half; a fresh live DB check (the plan's own Step 0)
  found the other half was still open: `ProgramController.cs:859`'s `ReplaceFirst("BP", ...)` swap
  reuses existing digits with zero collision check, and both allocators (`pGenerateThirdSegment` and
  ADR-043's `pReserveProjectIdBlock`) key buckets by `Suffix` independently — proven live via 3 real
  colliding project pairs on `myps_db_dev` (`P01100001LZ`/`2LZ`/`3LZ`, each a manually-created
  project's post-swap value colliding with a separately-imported project's own directly-issued
  `ProjectPK`). Chained `/plan-analysis` → `/code-behavior-audit` → `/rollback-readiness-test` per
  the operator's own explicit request, with two `AskUserQuestion` decision points along the way
  (fix scope: explicit swap-site check vs. unifying the counters — operator chose the smaller,
  URD-format-safe option; go-ahead to implement). Fixed: `GenerateProjectID` rewired onto
  `pReserveProjectIdBlock` (closes RISK-105 too, restores validation deleted by the operator's own
  commit `446d6318`), fail-closed collision check added at the swap site. Verified: 7 new regression
  tests (full suite 13/13 green) + a live rollback-only drill against `myps_db_dev`. Readiness tier:
  Internal-ready, verdict GO WITH CONDITIONS (authenticated API test not yet run). **The 3 existing
  live collisions are NOT retroactively repaired** — flagged for an explicit operator remediation
  decision, not actioned. Code changes uncommitted (`Helpers/ProjectHelper.cs`,
  `WebAPI/Controllers/Programs/ProgramController.cs` +29, `MYPS.DatabaseTests/
  ProjectIdGenerationTests.cs` new). Full detail: `decisions.md` (ADR-135), `risks.md` (RISK-105
  resolved, RISK-111 opened/mitigated).
- **2026-08-31 — Ported Codex's `plan-analysis` skill to a global, model-agnostic Claude Code
  skill (ADR-134).** Canonical top-of-stack: `decisions.md` → ADR-134 (superseded above by ADR-135).
  Not a MYPS task per se — operator asked for the skill (previously Codex-only) to become usable
  globally, in Claude or any LLM. Installed at `~/.claude/skills/plan-analysis/` (global to every
  project on this machine, natively discoverable, no per-project registration). All 6 substantive
  source files ported (4 verbatim, 2 with light Claude-Code-integration adaptation); the 7th
  (`agents/openai.yaml`, Codex-only) deliberately not ported — `SKILL.md`'s own frontmatter serves
  that role in Claude. **Caught and corrected mid-execution, not shipped wrong:** the approved
  plan's Context section claimed 7 of 9 named review-adapter capabilities were confirmed installed
  globally, including `gstack-openclaw-office-hours` — a fresh, unfiltered `ls ~/.claude/skills/`
  during the port showed only 6 actually exist (`gstack-openclaw-office-hours` is not a real,
  separate skill on this machine); corrected in `review-adapters.md` before shipping, spot-checked
  twice. Verified with real evidence, not just written: `validate-artifacts.py` run standalone
  against a hand-built bundle — PASS on valid, specific errors on a broken heading and a missing
  file; ported files grepped for MYPS-coupling (found none functional, only comparative notes),
  confirming genuine global scope. Cross-referenced against this employee's own `deep-analysis.md`
  (distinct, narrower, both stay) in both `SKILL.md` and this project's own `CLAUDE.md` trigger
  table. Also fixed in passing: the SessionStart vault-coverage WARNING — regenerated vault nodes
  after ADR-134 (ADR side now 130/130); the residual RISK-index mismatch traced to a deliberate,
  pre-existing intentional duplicate (`RISK-069`'s superseded original kept "for the trail") — a
  verifier false-positive, not a new defect, left as-is (not this task's scope to restructure
  `risks.md`). Full detail: `decisions.md` (ADR-134).
- **2026-08-31 — RISK-108 fixed and verified (ADR-133): Program cost now recomputes correctly on
  Formal Revision CO approval.** Canonical top-of-stack: `decisions.md` → ADR-133
  (`Next-ID: ADR-134`), `risks.md` → RISK-110 (`Next-ID: RISK-111`). Fixed both defects: ALTERed
  `pRecomputeProgramCost` to read through the effective-revision overlay
  (`fProjectFundingProfile`), added the missing call in `ApproveRevision` (order-independent,
  gated on `IsFullyApproved` after the save). **Proven via a real rollback-only drill** — injected
  a revision-only funding override on live data, confirmed the recompute used the revision's value
  not the stale base, rolled back to exact original state. 2 new regression tests added, all 6 in
  the file pass. **Live HTTP end-to-end proof was blocked by a separate, newly-found defect
  (RISK-110)** — `RequestRevision` stamps a wrong Program link on 2 of 2 projects tried, invisible
  until this fix made anything finally validate it. Operator explicitly chose strict-fail over
  swallowing that error. RISK-109 (CO-before-RO not server-enforced) also found and deferred, same
  as RISK-102 (explicitly put on hold by the operator). Code changes uncommitted
  (`RevisionController.cs` +18, `RecomputeProgramCostTests.cs` +127/-7) — no commit requested.
  Full detail: `decisions.md` (ADR-133), `risks.md` (RISK-108 resolved, RISK-109/110 opened).
- **2026-08-31 — `ProjectController`/`RevisionController`: Program cost never recomputes on
  Formal Revision approval, two-layer defect confirmed live (ADR-132/RISK-108).** Canonical
  top-of-stack: `decisions.md` → ADR-132 (`Next-ID: ADR-133`), `risks.md` → RISK-108
  (`Next-ID: RISK-109`). Operator asked to compare
  `UpdateProjectDetails`'s `pRecomputeProgramCost` call against `ApproveRevision`'s CO branch.
  Confirmed: `pRecomputeProgramCost` has exactly one call site in the whole repo
  (`ProjectController.cs:4190`) — zero in `RevisionController.cs`, so a CO-approved revision that
  changes funding leaves the Program's cached total stale. Deeper: pulled the proc's live
  definition via `OBJECT_DEFINITION` — it joins directly to the base `tProjectFundingProfile`
  table, never through `fProjectFundingProfile`/`fProjectEffectiveRevision` (the revision-aware
  overlay the rest of the app correctly uses for reads) — so even adding the call would compute
  against the wrong data. No compensating trigger exists. Live data (5 approved revisions) doesn't
  show the symptom only by coincidence — all 5 are this session's own test drills where funding
  wasn't deliberately changed. Secondary: `RecomputeProgramCostTests.cs` tests an embedded copy of
  the proc already drifted from the live version, with no Formal-Revision fixture — wouldn't catch
  this if it tried. Audit + verify only, per the operator's request — not fixed. Full detail:
  `risks.md` (RISK-108).
- **2026-08-31 — Claude↔Codex sync investigation: root cause found, ON HOLD before a fix
  (ADR-131).** Canonical top-of-stack: `decisions.md` → ADR-131 (`Next-ID: ADR-132`), `risks.md` →
  RISK-107 (`Next-ID: RISK-108`). The 08-28 hook NO-GO was real but mis-diagnosed — actual cause is
  a per-hook trust gate separate from the feature flag; confirmed live via
  `codex exec --dangerously-bypass-hook-trust`'s own acknowledgment message, after `codex features
  list` showed `hooks` defaults on regardless of config. Unresolved: hooks still didn't fire in
  `exec` mode with trust bypassed; stopped by a real Codex usage-limit error before the TUI/Desktop
  path could be tried. Operator directed: hold, document fully — this entry is that. Also found:
  a live BrightData token in `~/.claude/settings.json`'s permission allow-list (RISK-107, reported
  not fixed). Rule-comparison findings locked for resume: port Codex's honesty/readiness rule to
  Claude globally (tiers stay MYPS-scoped); `plan-analysis` skill is a candidate import. Nothing
  changed on disk — all test edits reverted and diffed clean. Full detail: `decisions.md` (ADR-131),
  `risks.md` (RISK-095 2nd addendum, RISK-107).
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
