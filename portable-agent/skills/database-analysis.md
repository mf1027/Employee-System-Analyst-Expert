# Database Analysis

## Purpose
Analyse database schema, queries, stored procedures, views, and data models for correctness, performance, security, and migration safety. Frame findings in business terms first — what breaks for users, what it costs — then provide technical detail.

## When to use
Invoke when asked about database design, schema review, query performance, migration planning, normalization, data model assessment, stored procedures, or when any change touches database objects, queries, or data integrity.

## Prerequisites
- Access to the schema, queries, or database objects being analysed.
- Identify the actual database engine/version from the live connection, configuration or supplied DDL. Never assume an engine from prior context.
- Existing ERD, data dictionary, or migration history (if available).

## Procedure

1. **Read existing context.** Review schema documentation, ERD, migration history, known issues, and relevant requirements.
2. **Schema analysis:**
   a. Map tables, columns, types, nullability, defaults, and constraints.
   b. Check primary/business keys and uniqueness expectations; justify heaps or keyless staging structures where they are intentional.
   c. Check enforced foreign keys and logical relationships separately; record cascade behavior and orphan risk without assuming every relationship is physically constrained.
   d. Identify indexes: covering indexes for common queries, missing indexes for frequent JOINs/WHEREs.
   e. Check normalization: identify 1NF/2NF/3NF violations with business impact.
   f. Check naming conventions: consistency, clarity, engine-appropriate casing.
3. **Query/procedure analysis:**
   a. Review execution plan (actual, not estimated where possible).
   b. Identify full scans, implicit conversions and missing/ineffective indexes only where actual plans and workload support the finding.
   c. Check for N+1 patterns, cursor abuse, unnecessary DISTINCT/ORDER BY.
   d. Assess parameter sniffing risks in stored procedures.
   e. Check transaction scope: too wide (blocking), too narrow (inconsistency).
4. **Data integrity assessment:**
   a. Check constraints: NOT NULL, CHECK, UNIQUE, DEFAULT where business rules require them.
   b. Identify columns that allow invalid state (nullable FK, unchecked status values).
   c. Assess temporal consistency: audit columns (created/modified), soft delete patterns.
5. **Migration safety assessment:**
   a. Classify change: additive (safe) vs destructive (requires planning).
   b. Identify locking impact: ALTER TABLE on large tables, index rebuilds.
   c. Assess rollback strategy: can the migration be reversed?
   d. Estimate downtime (if any) and data volume impact.
   e. Check for existing data that violates new constraints.
6. **Security check:**
   a. PII/sensitive data: identified, encrypted at rest, masked in non-production.
   b. Permissions: least privilege and the project-approved application access pattern (direct table access, views or procedures as appropriate).
   c. Dynamic SQL: parameterised or injection-safe.
   d. Audit trail: changes to sensitive data are logged.
7. **Performance baseline:**
   a. Table sizes, row counts, growth projections.
   b. Query frequency and response time expectations.
   c. Index fragmentation and maintenance schedule.

## Output contract
- Schema findings table: Table | Finding | Severity | Business Impact | Recommendation
- Query/procedure findings with execution plan evidence where available.
- Migration risk assessment (if applicable).
- Security findings (if applicable).
- Prioritised recommendations.

## Safety and approval gates
- Database analysis is analysis — do not execute DDL, DML, or schema changes without authorization.
- Never invent schema objects, columns, or relationships that are not in the actual database.
- Never run UPDATE/DELETE/DROP in production without explicit authorization and rollback plan.
- Verify the real schema before recommending changes. Read the actual objects, not memory.

## Verification
- Findings reference actual schema objects (table names, column names, constraint names).
- Performance findings are supported by execution plan evidence or measurable metrics.
- Migration recommendations include rollback strategy.
- Business impact is stated for every finding above Low severity.

## Consolidated DBA specialist procedures

Use these procedures as scoped sections of this skill rather than creating competing DBA skills. Invoke only the sections required by evidence and scope.

### Schema and object intake
1. Identify the target engine/version, active database, environment and permitted access. Confirm the active target before relying on an earlier connection or environment label.
2. Inspect existing project deliverables, decisions, schema history and prior analysis before calling a design undocumented or new.
3. Locate table/view/procedure/function/trigger DDL and relevant data exports. Parse large DDL mechanically with a repeatable script rather than relying on visual inspection. Check source encoding (for example UTF-16 SSMS exports versus UTF-8) and spreadsheet/CSV identifier columns for scientific-notation corruption.
4. Inventory tables, columns, types, nullability, defaults, keys, constraints, indexes, views, procedures, functions, triggers, synonyms and dependencies that actually exist.
5. Use view joins and observed query paths as relationship evidence when physical foreign keys are absent. State physical FK count explicitly; do not infer that no relationship exists from no FK.
6. For an as-built/source-derived system, query the actual source for enum values, generated-ID formats, derivation rules and process-guaranteed cardinality. DDL proves structure, not business meaning. Distinguish lookup values from generated formats and calculated values.
7. Reconcile parsed DDL against ERDs/data dictionaries. Report missing, extra, renamed or type-mismatched objects with evidence; do not silently normalize the diagram to match an assumption.
8. Capture source, timestamp, query/command, result and coverage limits. Distinguish an absent object from an inaccessible or unqueried object. Preserve snapshots/changelogs only in the project's canonical documentation location.

### SQL object-chain and data-flow trace
1. Start from the observed entry object or business operation and identify its purpose before proposing SQL.
2. Trace callers, referenced objects, dynamic SQL, triggers, views, procedures, functions and downstream consumers.
3. For each lifecycle operation (create, edit, state transition, delete/archive, import/export, clone/fork/publish/approve where applicable), trace the exact object operations, key predicates, row scope and state changes.
4. Record direction, dependency type, key columns, caller/consumer and evidence for every edge. For views, inspect explicit projections and joins; for procedures, inspect parameters, transaction/error handling and output contract; for functions, inspect return/null semantics and caller patterns.
5. Check temporal/history requirements: snapshots, audit logs, per-stage records, effective dates and whether old values must remain queryable.
6. Mark unresolved dynamic/runtime dependencies as unknown; do not infer a complete graph from static references alone.

### Cross-domain impact
Classify each affected consumer as **Breaking**, **Incomplete**, **Cosmetic** or **None** only when evidence supports the label. Include affected object/caller, failure mechanism, evidence, required compatibility action and execution order. Check API/application callers, reports, ETL/import/export, permissions, jobs, views/procedures, tests and operational scripts where they exist. Do not duplicate a separate system-analysis inventory; link the relevant end-to-end trace.

### Execution-plan and index analysis
1. Capture the exact query, parameters, engine/version, representative data volume and plan source.
2. Inspect estimated/actual plan evidence, scans/seeks, joins, cardinality estimates, sorts, spills, lookups, memory grants and warnings where exposed by the engine.
3. Use workload frequency/selectivity and write overhead before proposing indexes. Check existing indexes and overlapping prefixes first.
4. State expected benefit, write/storage cost, deployment risk and a measurable before/after baseline. Never promise an improvement without measurement.

### Performance baseline
Record representative query/workload, data size, concurrency, duration/latency, logical reads/CPU/IO metrics where available, plan identifier and environment. Repeat comparable runs and disclose noise. A single timing is not a reliable baseline.

### Migration and rollback readiness
1. Confirm source/target versions, object/data scope, row counts, constraints, dependencies and downtime/locking assumptions.
2. Design an idempotent or safely restartable migration where possible.
3. Define backup/restore or compensating rollback; identify irreversible transformations and retention needs.
4. Preview affected rows and counts; use transaction boundaries appropriate to the engine and operation.
5. Validate post-migration counts, constraints, representative values, application compatibility and performance.
6. Do not execute production or destructive changes without explicit target-specific approval.

### DBA security review
Check database principals, roles, grants, ownership, elevated execution, secrets/configuration, encryption, network exposure, audit/logging, backup access and least privilege where evidence is available. Coordinate with `security-review`; database-analysis owns the actual database object and privilege evidence.

### DBA interview and business-rule capture
Before recommending a table/entity shape, capture the process facts with the operator or authoritative business owner. Ask only questions relevant to the entity, but cover these ten dimensions:

1. **Operations:** create/read/edit/delete/import/export/clone/archive and which actor performs each.
2. **Changes and timing:** fields set on create, editable/locked fields, automatic state-transition changes, and hard versus soft delete.
3. **Temporal/history needs:** which values must be retained, at what granularity, and whether an audit log is sufficient.
4. **Intended versus observed behavior:** whether 1:1 relationships, always-null columns or constant values are guarantees, accidental patterns or future placeholders.
5. **Read patterns:** list/detail/report queries, filters, grouping and expected joins.
6. **Relationships/dependencies:** parent, children, siblings, external systems, exports and APIs.
7. **Edge cases:** orphan possibility, re-parenting, duplication, abandoned operations, partial state and draft lifecycle.
8. **Volume/growth:** current rows, 1-year/5-year projection, growth rate, retention/archive policy and largest result set.
9. **Concurrency:** peak users, batch operations, lock hotspots and serialization/queue behavior.
10. **Types/precision:** money, percentages, measurements, Unicode/collation, precision and rounding requirements.

Record the exact rule, source/owner, examples, exceptions, effective dates, null/empty semantics and unresolved contradictions. Treat user-provided rules as evidence, then reconcile them with approved requirements, application behavior and source data. Unknown answers remain explicit assumptions/open questions; never invent answers to complete a schema.


### Schema review and lifecycle drills
1. Review normalization, key/cardinality, constraints, data types/precision, null semantics, naming, audit columns, soft-delete behavior and state validity against actual requirements.
2. Check whether application-enforced relationships are guaranteed by the real process; distinguish that from DB-enforced constraints.
3. Build lifecycle test scenarios from the actual process, including boundary/error/partial-state cases and the full required parent/child entity graph.
4. Use clean, isolated fixtures for each drill where shared business keys or cleanup can interfere. Verify both that SQL executes and that business/contract behavior is correct.
5. Execute read-only checks by default. Any write, rollback drill or destructive operation requires target-specific authorization and an appropriate transaction/backup/rollback plan.
6. Re-run all materially affected drills after a schema/object change; do not report a change complete based only on editing a test script or seeing a stale green result.

### Schema change history
Use the project's existing schema version/changelog and decision record. Record date, approved decision reference, exact object delta, compatibility impact, consumers updated and validation evidence. Do not invent a new ID scheme or duplicate the project's canonical decision ledger.

### Output contract for DBA work
For each material finding provide: object/operation, environment, evidence, current behavior, risk/impact, proposed change, dependencies, migration/rollback, validation query/test and approval boundary. Keep unknown dependencies explicit.
