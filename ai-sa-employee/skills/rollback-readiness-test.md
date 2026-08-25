# rollback-readiness-test

Use this skill when the owner asks to prove a backend/database module is working through the
same evidence style used for MYPS Code Tables and Revision testing: source audit, DB metadata
verification, rollback-only CRUD drills, build checks, evidence capture, and a cautious readiness
verdict.

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

1. **Authority reconciliation**
   - Live source code: controller/helper/service/model/job/report paths.
   - Active config: `appsettings.*.json`, launch/runtime settings, connection strings.
   - Memory/docs: ADRs, risks, database notes, handoffs, current task notes.
   - Mind-map/navigation docs: Function Index, SQL Object Index, Code-to-SQL Traceability, Change Impact Map.
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

6. **Readiness verdict**
   - `GO`: deployment-ready evidence exists: source/build, DB metadata, rollback drills, authenticated API tests, required negative/error cases, integration boundaries, and mind-map sync all pass.
   - `GO WITH CONDITIONS`: internal-ready evidence passes, but API/auth/integration, negative/error, or another non-critical verification layer remains untested.
   - `NO-GO`: build, schema, rollback, data integrity, or confirmed process behavior fails.

Do not claim "100% working" unless Deployment-ready evidence exists and all applicable source, DB, rollback, authenticated API, integration, negative/error, and mind-map sync checks have passed.

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

Authority reconciliation:
- Code/config:
- Memory/docs:
- Mind-map:
- DB target/status:
- Conflicts:

Checks performed:
- Source/build:
- DB metadata:
- Rollback drills:
- Authenticated API/runtime:
- Negative/error cases:
- Integration boundaries:
- Mind-map sync:

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

