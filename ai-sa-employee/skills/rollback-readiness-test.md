# rollback-readiness-test

Use this skill when the owner asks to prove a backend/database module is working through the
same evidence style used for MYPS Code Tables and Revision testing: source audit, DB metadata
verification, rollback-only CRUD drills, build checks, evidence capture, and a cautious readiness
verdict.

## Shared Claude/Codex contract

This agent-local contract owns the readiness tiers, no-auth-bypass rule, DB-target reconciliation,
SQL SET-option requirements, rollback proof, prior-verdict reconciliation, scope-boundary
requirement, and Obsidian completion gate for this employee repository. Do not depend on legacy
external paths or a machine-global copy. “100% working” is permitted only with Deployment-ready
evidence.

This is a proof/testing skill. It does not authorize code changes, schema changes, git operations,
or permanent database mutation.

## When to invoke

Invoke for phrases such as:

- "test this thoroughly like Code Tables"
- "make sure this controller is 100% working"
- "run rollback-only tests"
- "deployment-readiness test"
- "backend/database readiness"
- "prove this module works"

Chain from `code-behavior-audit` when behavior must be understood before testing. Do not replace
`code-behavior-audit`; use it as the source/process tracing layer, then use this skill as the
evidence and rollback-readiness layer.

## Hard safety rules

- Never run git commit, push, reset, checkout, or staging commands.
- Never mutate production databases.
- Never connect to a live/prod DB. For MYPS specifically, the approved target and forbidden
  names/hosts change over time (revised 2026-08-25 — see
  `memory/clients/myps/myps-system/CODEX_SYNC_STARTUP.md`'s "DB safety rules" for the current
  standing target; don't hardcode a specific host/DB name here, it will go stale).
- Never perform permanent DB writes by default.
- Rollback drills require an explicitly approved target database for the current task.
- For MYPS, do not create or modify handover/planning Markdown inside `project_myps`.
- Do not touch frontend implementation files unless the owner explicitly includes FE.

If the task, config, memory, and mind-map disagree about the DB target, stop and report the
authority conflict before connecting.

## Readiness tiers and forbidden language

Use these tiers exactly:

- **Internal-ready** — source/build checks, static audit, DB metadata verification, and rollback drills passed. This proves internal backend/database mechanics only; API/auth/runtime middleware is not proven.
- **API-ready** — authenticated HTTP endpoint tests passed through the normal login/session/token flow. This proves controller binding, `_Session`, authorization, response envelopes, exception handling, and observable DB side effects for the scoped endpoints.
- **Deployment-ready** — Internal-ready + API-ready + negative/error cases + integration boundary behavior + mind-map sync evidence passed. Only this tier can support “100% working” language.

Never say **100% working**, **fully ready**, or unconditional **GO** when authenticated API tests, negative/error cases, or integration-boundary checks are applicable but missing. If build + DB metadata + rollback drills pass but API/auth is not tested, the verdict is **GO WITH CONDITIONS** at most.

## Required workflow

1. **Authority reconciliation** — read in this order (matches the vault's own Authority Order,
   MYPS `Claude + Codex Real-Time Sync Protocol.md`: operator instruction → live code/DB →
   Obsidian → formal lane files → historical docs).
   - Mind-map/navigation docs first: Function Index, SQL Object Index, Code-to-SQL Traceability,
     Change Impact Map, and **`14 - Testing/Backend Deployment Readiness.md`** specifically — the
     readiness verdict's primary written home; read it before writing anything new into it.
   - Live source code: controller/helper/service/model/job/report paths.
   - Active config: `appsettings.*.json`, launch/runtime settings, connection strings.
   - Memory/docs: ADRs, risks, database notes, handoffs, current task notes — the evidence record,
     not the primary written home.
   - DB metadata: only after the approved target is resolved and read-only access is permitted.

2. **Non-mutating checks first**
   - Map public endpoints/functions, DTOs, EF models, DbSets, raw SQL, views, functions, and stored procedures.
   - Run static sweeps for repeated branches, copy/paste divergence, exact-identity risks, broad `Contains`, missing guards, and inconsistent logs.
   - Run backend build checks that avoid frontend execution unless FE is explicitly in scope.
   - Verify DB object/column/index/FK metadata with read-only queries.

3. **Rollback-only drills**
   - Ask for or confirm approval for the exact DB target before running.
   - Use a unique run label.
   - Use required SQL drill SET options before test DML: `SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF; SET XACT_ABORT ON;`.
   - `BEGIN TRAN`.
   - Create/update/delete test rows in dependency order.
   - Verify expected state inside the transaction.
   - `ROLLBACK`.
   - Verify surviving test rows are zero.
   - If a failure occurs, prove rollback occurred or report the exact cleanup risk.

4. **Authenticated API/runtime gate**
   - Required for controller/API readiness claims.
   - Use the normal login/session/token flow; do not bypass auth, fake `_Session`, or call controller methods directly as a substitute for endpoint testing.
   - Test every endpoint/action in scope through HTTP.
   - Verify `_Session`, permissions, request binding, response envelope, exception handler behavior, and DB side effects.
   - If this layer cannot run, record the blocker and downgrade the verdict; rollback drills prove DB behavior, not controller/middleware behavior.

5. **Evidence capture**
   - Build/test output summary.
   - DB metadata checks.
   - Static sweep counts and divergent lines.
   - Rollback test cases and row counts.
   - Skipped tests and why.
   - Remaining risks and follow-up tests.

6. **Prior-verdict reconciliation + vault sync (ADR-124, 2026-08-27).** Full canonical rule:
   MYPS `Claude + Codex Real-Time Sync Protocol.md` → "Completion Gate". Two sub-steps, both
   mandatory before writing a verdict:
   - **6a. Prior-verdict reconciliation.** Search `Backend Deployment Readiness.md` (and any other
     target note from the completion-gate table) for an existing entry covering the same
     controller/module/blocker. Resolve it explicitly — resolved (say so, dated), still open (carry
     it into this verdict's blocker list), or superseded (say why) — never append a fresh verdict
     beside an unreconciled older one. *Why this exists:* a 2026-08-25 `ProjectGroupController` run
     logged a `PIS:BypassLogin` blocker in that note and left it open; a 2026-08-27
     `RevisionGroupId 13` run hit the identical blocker, solved it independently, and never noticed
     the prior entry — 2 days unresolved, found only by accident. Both wrote to the same note.
     If both entries carry an explicit `Scope boundary:` (step 7), diff the two lists first — it's
     the fast path to seeing whether they actually overlap before re-reading either in full.
   - **6b. Mechanical freshness check.** Run `tools/check-related-vault-notes.py <keywords for this
     module>`. Update or explicitly note reviewed-and-not-stale every hit, in the final response.

7. **Readiness verdict**
   - `GO`: deployment-ready evidence exists: source/build, DB metadata, rollback drills, authenticated API tests, required negative/error cases, integration boundaries, and mind-map sync (step 6) all pass.
   - `GO WITH CONDITIONS`: internal-ready evidence passes, but API/auth/integration, negative/error, or another non-critical verification layer remains untested.
   - `NO-GO`: build, schema, rollback, data integrity, or confirmed process behavior fails.

Do not claim "100% working" unless Deployment-ready evidence exists and all applicable source, DB, rollback, authenticated API, integration, negative/error, and mind-map sync checks have passed.

**Scope boundary is mandatory on every verdict (ADR-125, 2026-08-27) — `GO`, `GO WITH CONDITIONS`,
and `NO-GO` alike, whenever anything narrower than the full module/controller was tested.**
Explicitly enumerate the modules/paths/endpoints/variant-branches (e.g. other `RevisionGroupId`
values, other HTTP verbs on the same controller, other environments) that were NOT tested or NOT
in scope — never leave this implicit. *Why this is mandatory, not optional:* ADR-123's GO verdict
for the `RevisionGroupId 13` continuation fork had no such field; the operator had to ask directly
whether GO meant the whole revision flow worked (it didn't — only one narrow path was tested), and
a Scope Boundary section was added to the record only after that question, not before. See
ADR-123's own "Scope boundary" section for a worked example of the required level of detail — reuse
that shape, don't invent a new one.

## MYPS-specific testing pattern

For MYPS backend/database modules:

- Resolve the active DB target from the current task and active config first; do not reuse an old DB assumption.
- Prefer `appsettings.Development.json` only when the owner says the development config is the target.
- Start with read-only metadata checks before rollback drills.
- Treat controller-level validation as important even when SQL has partial FK coverage.
- Verify transaction logs separately from direct SQL drills; SQL-only rollback tests do not prove API audit logging.
- Record business/data caveats, such as duplicate option grouping, as readiness conditions instead of hiding them.

## Output format

```text
Tier: FULL / ABBREVIATED
Readiness tier: Internal-ready / API-ready / Deployment-ready / Not-ready

Verdict:
GO / GO WITH CONDITIONS / NO-GO — one sentence.

Scope boundary:
- Modules/paths/endpoints/variants NOT tested or NOT in scope (mandatory whenever narrower than the full module was tested; see step 7):

Authority reconciliation:
- Mind-map (read first):
- Code/config:
- Memory/docs:
- DB target/status:
- Conflicts:

Checks performed:
- Source/build:
- DB metadata:
- Rollback drills:
- Authenticated API/runtime:
- Negative/error cases:
- Integration boundaries:
- Prior-verdict reconciliation (step 6a):
- Mind-map freshness check (step 6b):

Findings:
- File/object/function:
- Evidence:
- Severity:
- Fix or follow-up:

Rollback proof:
- Run label:
- Rows created inside transaction:
- Rows surviving after rollback:

Remaining blockers:
- ...

Confidence:
High / Medium / Low. Not checked:
```

## Failure exit

"I cannot give a readiness verdict yet. The missing blocker is: [DB target approval / DB metadata
access / build result / rollback proof / API auth test / integration fake]. Current confidence:
[Low/Medium]."
