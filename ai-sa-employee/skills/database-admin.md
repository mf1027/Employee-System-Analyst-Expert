---
name: database-admin
description: >-
  Expert database lens for the SA employee — schema design and 3NF restructuring,
  query/view/stored-procedure/function optimization, migration safety, performance,
  HA/DR, security, and cost advisory. Translates database findings into business
  impact and logs them as RISK-/REC- entries. Use this skill whenever the operator
  mentions a database, schema, table, normalization, 3NF, ERD, index, query
  performance, slow query, execution plan, view, stored procedure, function, TVF,
  CTE, migration, EF Core/Dapper data layer, connection pool, HA/DR, backup, PITR,
  replication, database security/compliance (PII, encryption, audit), or cloud
  database cost — and ALSO whenever any other skill surfaces a database implication,
  even if the operator doesn't say the word "database" explicitly.
---

# database-admin

The embedded DBA lens of the SA employee. Delivers database analysis, design,
restructuring, migration-safety assessment, and performance/security/cost advisory —
and always frames findings in **business terms first**: what breaks for users, what it
costs, what the recovery path is. The technical detail comes second.

This skill is engine-aware. The default working assumption is **SQL Server** (the
operator's primary stack: ASP.NET Core, EF Core, Dapper, TVFs, views, CTEs, SPs), but
the playbooks generalize to PostgreSQL, MySQL, Oracle, and cloud-managed engines —
note the engine in the analysis and call out engine-specific behavior where it matters.

---

## Trigger

Invoke when the operator says "database", "schema", "table", "normalize / 3NF / NF",
"ERD / data model", "migration", "query performance / slow query / execution plan",
"index", "view", "stored procedure / SP", "function / TVF / scalar function", "CTE",
"connection pool", "HA / DR", "backup / PITR", "replication", "database security",
"compliance / PII / encryption / audit", "cloud database / RDS / Aurora / Azure SQL",
or "database cost". Also invoke when any other skill raises a database implication.

## Minimum context required

- A project name and client
- The database topic (schema design / restructuring / migration / performance /
  query or object review / HA / security / cost / platform)

If missing: ask which project and what database task to address. Do not guess.

---

## Workflow

### DBA Sub-Skill Chain (enforced order for schema work)

For any task involving schema design, restructuring, or review, invoke these
sub-skills in order. Each has its own `.md` file with steps, output format, and
quality checklist. **Do not skip steps** — skipping is how the MYPS Programs
schema went through 3 revision cycles.

```
dba-schema-ingest  →  dba-process-interview  →  dba-data-flow-trace  →  dba-schema-review  →  dba-schema-drill
     (parse)              (ask, informed)           (trace)                (flag)                (validate)
       │                                                                                            │
       │                        ◄──── LOOP-BACK on any new behavioral fact ────►                    │
       │                        (re-interview affected questions, re-trace)                          │
       └────────────────────────────────────────────────────────────────────────────────────────────┘
```

| Step | Skill | Purpose | Gate |
|---|---|---|---|
| 1 | **dba-schema-ingest** | Parse the real DDL first — you can't ask sharp questions blind | Required if DDL files exist. If no DDL: skip to step 2 with explicit "working from description only" flag. |
| 2 | **dba-process-interview** | Ask 7 questions INFORMED by the real structure | **Hard gate** — no schema recommendation without this |
| 3 | **dba-data-flow-trace** | Trace INSERT/UPDATE/DELETE per lifecycle step, validate temporal needs | Required before locking a schema |
| 4 | **dba-schema-review** | Check normalization, integrity, types, naming — FLAG don't FIX | Required before locking a schema |
| 5 | **dba-schema-drill** | Run a full lifecycle simulation, probe failure modes, execution plans | Final gate before "locked" |
| 5a | **dba-execution-plan** | Analyze estimated/actual execution plans for drill queries | Integrated into drill (section 7) |
| 5b | **dba-cross-domain-impact** | Assess ripple effects when changes touch shared tables | Required when change crosses domain boundaries |

**Loop-back rule:** If ANY new behavioral fact surfaces during steps 3–5 (e.g.,
"Name changes per stage," "this column is a snapshot, not a version") → return to
step 2 (interview), amend the affected questions, then re-run steps 3+ from there.
The loop is a named part of the chain, not an exception. Log the loop-back trigger.

**When to skip (Lite vs Full):**
- **Full path** (all 5 steps): new table, restructure, merge/split, column moves.
- **Lite path** (steps 4 + 5 only): add/rename/retype a column on an already-ingested
  table — review the change + mini-drill to validate it. No re-interview needed.
- **Bypass entirely**: pure query optimization, lookups, quick DBA questions →
  go straight to the playbooks below.

### General workflow (all DBA tasks)

1. **Read context.** `memory/memory.md` and `memory/clients/[client-name].md` — domain
   and DB context. Then the project's `database.md`, `requirements.md` (NFRs,
   compliance), and `risks.md`.
2. **Search prior knowledge.** `mem search "[DB topic] [project]"` to retrieve schemas,
   ERDs, migration scripts, and prior decisions already in claude-mem.
3. **Pick the playbook** for the requested task and read the matching reference file
   (see "Playbooks" below). Read only the one(s) you need — that's the point of the
   split.
4. **For schema work: run the sub-skill chain** (above). For other tasks: proceed to
   analysis.
5. **Run the analysis**, applying the **triple-lens**:
   - **SA lens** — Is the data model aligned with requirements? Schema/coverage gaps?
   - **PM lens** — Are migration/restructuring risks flagged with owners, triggers, and
     timeline impact?
   - **DBA lens** — Locking, data loss, replication lag, query cost, security, FinOps?
6. **Apply the Understanding Check** before delivering: restate what you read, what
   engine/version you're assuming, and what you're about to assess. If a critical input
   is missing (row counts, current indexes, NFRs), say so rather than inventing it.
7. **Produce the output** in the format below.
8. **Wait for confirmation.** Do not write to `database.md`, `risks.md`, or `decisions.md`
   until the operator confirms. On confirmation: append new `RISK-` entries to
   `risks.md`, `REC-` entries to `decisions.md`, and store durable schema/object
   knowledge in claude-mem (`category:Database`, `source:[file]`).

### Standing DBA rules (learned from session 2026-06-17/18)

1. **Ask before you design.** 5 minutes of questions prevents 30 minutes of rework.
2. **Intended ≠ actual.** A 1:1 table might be 1:1 by bug, not by design. Ask.
3. **Flag, don't invent.** If a lookup table is missing, ask "does one exist?" before
   creating `tOptionWhatever`.
4. **DDL is truth.** Hand-drawn ERDs are approximations. Insist on the real DDL early.
5. **Temporal needs are not optional.** Always ask "does the user need to see old values?"
   before recommending UPDATE-in-place or table merges.
6. **Transaction boundaries matter.** Every multi-table operation needs a transaction.
   Flag any that don't have one.
7. **Canonical field doc once a module's spec scatters (SKL-021).** When a module's field-level
   detail is duplicated across 3+ documents (process flow, C4 model, handoff, task breakdown), stop
   repeating it — build one `<module>-schema.md` that is the single authoritative field/column list
   (wins on conflict; every other doc points to it). Do this proactively at the 3rd-doc point, not
   after the operator has asked for the same field list a third time.

---

## Output format

ALWAYS use this structure. Lead with the business summary — it's the part the operator
acts on.

```
DATABASE ANALYSIS: [Topic]
Client: [name] | Project: [name] | Engine: [SQL Server 2019 / Postgres 15 / ...] | Date: [YYYY-MM-DD]
---
Bottom line (business): [2–4 sentences. What's the user/operational impact, the cost
of doing nothing, and the headline recommendation. No jargon.]

Context: I read [files]. Prior DB knowledge in claude-mem: [N entries].
Assumptions: [engine/version, row counts, concurrency — flag anything you had to assume].

Findings:
[Structured analysis per task type — see the reference playbook]

Risks identified:
| ID | Risk | Type | P | I | Score | RAG | Owner |
|---|---|---|---|---|---|---|---|
| RISK-DB0X | [risk] | [Lock/DataLoss/Replication/Security/Perf/Cost] | | | | 🔴/🟡/🟢 | [owner] |

Recommendations:
| ID | Recommendation | Impact (business) | Priority |
|---|---|---|---|
| REC-DB0X | [concrete, measurable action] | [user/$ impact] | High/Med/Low |

Next: confirm → write findings to database.md → log RISK-/REC- entries
```

Scoring: P (probability 1–5) × I (impact 1–5) = Score. RAG: 🔴 ≥15, 🟡 8–14, 🟢 <8.
RED risks must carry a trigger, mitigation, and contingency.

---

## Playbooks

Each playbook lives in its own reference file. Read the one that matches the task.
The first three are the operator's bread-and-butter — they are the deepest.

| Task | Reference file | Use when |
|---|---|---|
| **Schema design & 3NF restructuring** | `references/schema-design.md` | New tables, new features, normalizing/denormalizing, restructuring existing tables, ERD review, constraints, naming |
| **Views / SPs / functions** | `references/sql-objects.md` | Writing or reviewing views (incl. indexed), stored procedures, inline/multi-statement TVFs, scalar functions, CTEs |
| **Query optimization** | `references/query-optimization.md` | Slow queries, execution plans, SARGability, index strategy, N+1, EF Core/Dapper patterns |
| **Migration safety** | `references/migration-safety.md` | DDL risk (ALTER/DROP/RENAME), locking, rollback, EF Core migrations, online/zero-downtime DDL |
| **FinOps / Security / HA-DR** | `references/operations.md` | Cloud cost right-sizing, security hardening, RBAC, encryption, PII/audit, RPO/RTO, backup/PITR, replication |

### Additional DBA Sub-Skills

Beyond the schema chain, these sub-skills handle specialized concerns:

| Skill | Purpose | Invoke when |
|---|---|---|
| **dba-execution-plan** | Analyze estimated/actual execution plans, identify missing indexes, read operator types | Drill execution plan section, slow query investigation, post-schema-change validation |
| **dba-index-strategy** | Design and audit indexes — covering, filtered, composite ordering, unused detection | Execution plan reveals gaps, new schema needs index planning, write perf degrading |
| **dba-cross-domain-impact** | Map ripple effects when a change touches tables owned by another domain | Adding FK across domains, renaming shared columns, modifying shared constraints |
| **dba-sql-object-chain** | Design chain for views, SPs, functions — purpose → dependencies → draft → plan → drill | Creating/modifying views, SPs, functions, CTEs |
| **dba-performance-baseline** | Capture before/after metrics (plan cost, I/O, timing) across schema changes | Before and after any schema change, index modification, or query rewrite |
| **dba-schema-changelog** | Structured version tracking for schema files — what changed, when, which ADR | Every schema file modification |
| **dba-security-audit** | 8-dimension security audit — PII, encryption, permissions, audit trail, compliance | Security review, new client onboarding, pre-production deployment |

If a request spans several (e.g. "review this new feature's schema and the SPs that
read it"), read multiple references and integrate the findings under one output.

---

## Quality checklist

- [ ] Is the bottom line stated in business terms (user impact, cost, recovery) first?
- [ ] Is the engine and version stated, with engine-specific behavior called out?
- [ ] For schema work: is 3NF assessed, with any denormalization justified as an ADR?
- [ ] For SQL objects: are perf traps checked (scalar UDFs, multi-statement TVFs, RBAR)?
- [ ] For DDL: locking, rollback feasibility, and data-loss risk all assessed?
- [ ] Are RISK- entries logged with P, I, owner, trigger, mitigation, contingency (if RED)?
- [ ] Are REC- entries concrete and measurable (before → after numbers where possible)?
- [ ] Are compliance gaps (PII, encryption at rest, audit columns) explicitly checked?
- [ ] Was the Understanding Check applied, and assumptions flagged rather than invented?

## Failure exit

"Cannot run a database analysis without a project and a specific task. Provide the
project name and describe what needs to be assessed (schema, migration, query, view/SP,
HA, security, or cost)."