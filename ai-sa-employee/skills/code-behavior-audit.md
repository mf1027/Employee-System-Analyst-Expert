# Skill: code-behavior-audit

## Shared Claude/Codex contract

Follow the same authority reconciliation, evidence labels, DB safety gate, pattern sweep, transaction/concurrency questions, prior-verdict reconciliation, and scope-boundary rules as `C:\Users\khen\.agents\skills\code-behavior-audit\SKILL.md`. This skill identifies behavior defects; it does not establish deployment readiness.

Every report must include a scope boundary and identify any prior verdict that remains open.

## Purpose
Review **existing, already-shipped application code** for latent behavior bugs by tracing realistic
inputs through source, config, database contracts, and downstream consumers to a concrete predicted
output or failure.

This skill is for behavior auditing, not PR/diff review and not implementation. It supplies the
code/config/DB verification mechanics that `deep-analysis.md` names as top evidence, then delegates
RCA, gap analysis, adversarial review, and verdict back to `deep-analysis`.

## Trigger
Invoke when the operator says "audit this code for bugs", "trace this for issues", "check this
controller/function for defects", "will this break in production", "find bugs in [file]", or when a
FULL-tier `deep-analysis` task needs to trace **existing application code**.

**Not the same as "code review."** A PR/diff review is static and change-scoped. This skill audits
already-existing behavior by following real execution paths and validating assumptions against the
active project's approved evidence sources.

## Minimum context required
- The file, class, function, API endpoint, SQL object, or workflow to audit.
- Read access to source, callers/consumers, active config, project memory/docs, and DB metadata when
  DB behavior affects the finding.

If missing: ask one crisp question naming the exact missing target, then stop.

---

## Steps

### 0. Tier — reuse `deep-analysis` Step 0 exactly
Don't re-derive tiering. FULL for money, IDs, auth, data-integrity, schema/DB contracts, concurrency,
or multi-file workflows; ABBREVIATED for scoped single-function audits; SKIP for pure lookups.

### 1. Authority reconciliation — do this before tracing or DB access
Before assuming which code, config, or DB is authoritative, reconcile:

1. **Live code**: target file, callers, downstream consumers, shared helpers/base classes.
2. **Active config**: environment files such as `appsettings*.json`, launch profiles, DI wiring,
   connection factories, feature flags, and job configuration.
3. **Memory/decision records**: ADRs, risks, requirements, database notes, and current task handoffs.
4. **Mind-map / navigation docs**: function index, SQL object index, code-to-SQL traceability, and
   change-impact maps when the project has them.
5. **DB metadata**: only after the approved target is resolved and read-only access is permitted.

If these sources conflict, report the conflict explicitly before DB connection or verdict. Use this
format:

```text
Authority conflict:
- Code/config says:
- Memory/docs say:
- Mind-map says:
- Operator/task says:
- Safe next step:
```

Never let an older memory rule silently override the current task or active config. Never let
config alone authorize a risky/live DB connection if project safety rules or the operator prohibit
it.

### 2. Understand — delegate to `deep-analysis` Step 1
Check the project's own lane files before treating anything as new. Trace upstream → target →
downstream: every caller, the target itself, every consumer, plus inherited/shared infrastructure.
Don't stop at the named file if the behavior depends on helpers, filters, middleware, EF models,
SQL objects, queues/jobs, or external integrations.

### 3. Input → output tracing
For each entry point in scope:

1. Enumerate realistic scenarios: happy path, null/empty/default values, unknown enum/string,
   missing/soft-deleted FK, stale config, malformed DB result, timeout, duplicate request,
   concurrent callers, and retry.
2. Trace the control flow **by hand, statement by statement** to a concrete predicted output,
   write, rollback, exception, external call, or silent no-op.
3. Cite the exact file/function/line where behavior diverges from the method name, comments,
   business rule, API contract, or caller expectation.
4. Label every traced finding `UNVALIDATED` until confirmed by DB metadata, test/build evidence,
   log evidence, or operator confirmation.

### 4. Pattern-consistency sweep
When N≥3 structurally similar blocks exist, check **all occurrences**, not a sample.

Examples: repeated CRUD branches, switch/if chains by type, parallel validation branches, repeated
SQL call patterns, import row handlers, document/status handlers, or option-table mappings.

For every divergence, determine which version is correct using evidence: framework behavior, current
business rule, DB contract, most recent ADR/RISK, or operator confirmation.

### 5. DB and external verification gate
Run DB checks only when DB state/metadata determines whether the traced behavior is reachable or
dangerous.

Before connecting:

- Resolve the DB target from the current task + active config + project safety rules + operator
  confirmation.
- Prefer read-only metadata first: `sys.objects`, `sys.columns`, `sys.indexes`,
  `INFORMATION_SCHEMA`, object definitions, execution plans with no mutation, and safe row counts.
- Do **not** execute stored procedures/functions that allocate IDs, reserve counters, publish data,
  enqueue jobs, send notifications, mutate status, or touch external systems unless explicitly
  authorized for that exact call.
- If DB is unreachable, label the finding `CODE-CONFIRMED / DB-UNVERIFIED` and provide the exact
  read-only query the operator can run manually.

Upgrade evidence only when warranted:

| Label | Meaning |
|---|---|
| `UNVALIDATED` | Hand trace only; plausible but not confirmed. |
| `CODE-CONFIRMED` | Verified from source/control flow, but not live DB/runtime. |
| `CONFIG-CONFIRMED` | Verified from active runtime config. |
| `DB-CONFIRMED` | Verified from approved DB metadata/query result. |
| `OPERATOR-CONFIRMED` | Confirmed by the operator as business/runtime truth. |
| `DB-UNVERIFIED` | DB check needed but not reachable/authorized. |
| `CONFLICT` | Two authoritative sources disagree. |

### 6. Concurrency / transaction drill for high-risk workflows
For IDs, imports, money, publishability, approval status, documents, and external publication,
answer these before recommending a fix:

- Where is the transaction boundary?
- What is inside vs. outside rollback?
- Is the DB allocator/update atomic under concurrent callers?
- Is there a unique/index/FK/check constraint proving safety?
- Can retries duplicate work?
- Can a partial failure leave files, rows, counters, documents, or external systems inconsistent?
- Does the code use exact identity or broad string matching?
- Does the code fail closed with a diagnostic message when assumptions are false?

### 7. Gap analysis + adversarial pass — delegate to `deep-analysis` Steps 3-4
Use `Gap → Impact → Required Change`. For schema-touching gaps, delegate to the DBA/cross-domain
impact skill or equivalent project process; do not improvise schema changes inside this audit.
Attack your own findings: stale docs, hidden callers, base-class handling, framework behavior,
concurrency, nullability, external retries, and simpler explanations.

### 8. Implementation-readiness classification
Separate recommendations into:

- **Safe code-only fix** — can be implemented without DB/schema/runtime confirmation.
- **Code fix with DB verification gate** — code can be hardened, but cannot be called complete until
  DB metadata/runtime behavior is checked.
- **DB/schema/process blocker** — implementation should stop or remain conditional until DB/process
  authority is resolved.
- **Out of scope** — real issue, but not required for the requested audit.

### 8.5. Readiness handoff to `rollback-readiness-test`

This skill can identify behavior defects, likely fixes, and implementation-readiness categories, but it must not claim a backend/database module is **100% working** or deployment-ready. For readiness claims, hand off to `rollback-readiness-test`, which requires DB metadata, rollback proof, authenticated HTTP/API tests, negative/error cases, integration boundary evidence, and mind-map sync. If API/auth was not run, say the audit is behavior-only and mark runtime readiness unproven.

### 9. Verdict — delegate to `deep-analysis` Step 6
GO / GO WITH CONDITIONS / NO-GO. A GO means the audit is complete enough to present findings or a
plan. It does **not** authorize code changes, DB changes, commits, pushes, or production access.

---

## Output format

```text
Tier: FULL / ABBREVIATED

## Verdict
GO / GO WITH CONDITIONS / NO-GO — one sentence.

## Authority reconciliation
- Code/config:
- Memory/docs:
- Mind-map:
- DB target/status:
- Conflict, if any:

## Traced findings
- [UNVALIDATED / CODE-CONFIRMED / DB-CONFIRMED / CONFLICT] Finding — file:function:line — predicted/observed behavior

## Pattern-consistency sweep
N blocks checked. Divergent: [list with line numbers] / Clean: no divergence found.

## DB / runtime verification
- Checked:
- Not checked:
- Manual read-only query needed, if blocked:

## Concurrency / transaction risks
- Risk → evidence → impact

## Recommendations
**Safe code-only fix:**
1. `file:line` — change — effort/impact
**Code fix with DB verification gate:**
1. ...
**DB/schema/process blocker:**
1. ...
**Structural improvement (flagged, not implemented):**
1. ...

## Confidence
High / Medium / Low. Not checked: [the main thing not verified].
```

---

## Quality checklist
- [ ] Tier stated; `deep-analysis` Step 0 reused
- [ ] Authority reconciliation completed before DB access or verdict
- [ ] Active config checked when runtime target/behavior depends on configuration
- [ ] Memory/docs and mind-map checked where the project has them
- [ ] Every traced finding walked through actual code, not pattern-matched
- [ ] Every traced finding labeled correctly; no DB claim upgraded without DB evidence
- [ ] Pattern sweep checked all repeated blocks when N≥3
- [ ] DB checks obeyed the current task's approved target and were read-only by default
- [ ] No allocator/publisher/mutating stored procedure executed without explicit authorization
- [ ] Concurrency/transaction drill completed for IDs/imports/money/status/publication workflows
- [ ] Recommendations separated by readiness and DB gates
- [ ] No 100%/deployment-ready claim made; readiness proof is delegated to `rollback-readiness-test` when needed
- [ ] No application code, DB object, commit, push, reset, checkout, or staging performed by the audit itself
- [ ] Verdict does not bypass the separate plan/approval gate

## Failure exit
"Nothing concrete to audit. Point me at the file, class, function, endpoint, SQL object, or workflow
— and if DB verification matters, confirm the approved read-only target."

