---
name: dba-process-interview
description: >-
  MANDATORY first step before any schema design or restructuring. Interviews the
  operator/developer about the business process that the schema supports — what
  operations exist, what data changes at each step, what history is needed, and
  what the read patterns are. Prevents the #1 DBA failure mode: optimizing
  structure without understanding behavior. Must complete BEFORE dba-schema-review
  or any schema recommendation.
---

# dba-process-interview

The DBA's equivalent of the SA's "gather-requirements" skill. No schema work
begins until this interview is done. Every assumption made without asking becomes
a revision cycle later.

---

## Trigger

Invoke BEFORE any of these:
- Schema design or redesign
- Table restructure, merge, or split
- Column rename, move, or removal
- New entity recommendation
- Any recommendation that changes the shape of a table

**Hard gate:** if this skill has not been run for the entity in question, schema
recommendations are blocked. Flag: "Process interview not completed for [entity] —
running dba-process-interview first."

**Prerequisite:** `dba-schema-ingest` should run BEFORE this interview (if DDL
exists). You can't ask sharp questions about a schema you haven't seen — ingest
gives you the real table/column/type structure to ask about. If no DDL is
available, proceed but flag: "Interview conducted without DDL — answers are
descriptive only, not validated against real structure."

**Loop-back:** If new behavioral facts surface during `dba-data-flow-trace` or
`dba-schema-drill`, return here and amend the affected questions. This is
expected, not a failure.

---

## The 7 Questions

Ask ALL of these for every entity being designed/restructured. Do not skip any.
Use the ingested schema to ask SPECIFIC questions (name actual tables and columns),
not generic ones.

### Q1 — Operations
"What are ALL the operations on this entity?"
- Create, read, edit, delete, import, export, clone, fork, archive?
- Who performs each? (Which role/actor?)

### Q2 — What changes and when
"Which fields change at each operation?"
- On create: which fields are set?
- On edit: which fields can the user change? Which are locked?
- On stage/state advance: which fields change automatically?
- On delete: hard delete or soft delete? When is each allowed?

### Q3 — Temporal / history needs
"Does the user ever need to see previous values?"
- If yes: which fields? At what granularity? (per-edit? per-stage? per-day?)
- Is this "nice to have" or "must have"?
- Can the audit log serve this, or is structured per-stage data needed?

### Q4 — Intended vs actual behavior
"Is the current structure working as designed, or is the app using it differently?"
- If a table is always 1:1 with its parent: is that by design, or should it
  accumulate multiple rows?
- If a column is always NULL: is it unused, or awaiting a future feature?
- If a column is always the same value: is it redundant, or a reserved field?

### Q5 — Read patterns
"What are the 5 most common queries against this data?"
- List views (which columns shown? filtered by what?)
- Detail views (JOIN depth? how many tables?)
- Reports (aggregation level? cross-entity joins?)
- Does the user ever need to filter/group by a specific column? (index signal)

### Q6 — Relationships and dependencies
"What other entities depend on this one?"
- Parent: what does this belong to?
- Children: what belongs to this?
- Siblings: what else is created/deleted together?
- External: does any external system read/write this? (linked servers, APIs, exports)

### Q7 — Edge cases
"What happens in unusual situations?"
- Can this entity exist without a parent? (orphan risk)
- Can it be moved between parents? (re-parenting)
- Can it be duplicated/cloned?
- What if the user starts an operation and abandons it mid-way? (partial state)
- Is there a "draft" state before it becomes official?

### Q8 — Data volume and growth
"How much data does this entity produce?"
- How many rows today? Expected in 1 year? 5 years?
- What's the growth rate? (e.g., 100 new programs/year × 50 projects × 7 stages = 35,000 project-revision rows/year)
- Are old rows ever archived or purged, or do they accumulate forever?
- What's the largest single query result set? (e.g., "all projects in Region X at GAA-R" — how many rows?)

**Why this matters:** Index strategy, partitioning, and archive policy depend on volume.
Designing for 1,000 rows and discovering 10 million is a performance emergency. A 5-minute
volume estimate prevents it.

### Q9 — Concurrency
"How many users hit this data simultaneously?"
- Peak concurrent users? (e.g., 20 DEOs encoding projects at the same time)
- Are there batch operations that lock many rows? (e.g., stage advance updates all projects under a program)
- Is there a queue or serialization mechanism, or is it fully concurrent?

**Why this matters:** A stage-advance UPDATE that locks the program row blocks all concurrent
project encoders. The locking strategy (row-level vs page-level, optimistic vs pessimistic)
depends on concurrency.

### Q10 — Data types and precision
"Are there monetary values, percentages, or measurements?"
- Any column that stores money? → must be `decimal(18,2)`, NOT `float` (approximate type = rounding errors in financial calculations)
- Any column that stores percentages that must sum to exactly 100%? → `decimal(5,2)`, not `float`
- Any column that stores coordinates, distances, or physical measurements? → `float` is acceptable here (approximate is fine for geo)
- What character sets are in the data? (Filipino names, special characters) → confirms `nvarchar` and collation needs

**Why this matters:** `float` for money is one of the most common, most damaging, and most
silent schema defects — it passes every test until the rounding error hits a financial report.
Asking this question catches it at design time, not in production.

---

## Output format

```
DBA PROCESS INTERVIEW: [Entity name]
Client: [name] | Project: [name] | Date: [YYYY-MM-DD]
---

Q1 — Operations:
[Bulleted answers]

Q2 — What changes and when:
[Table: operation → fields affected]

Q3 — Temporal / history needs:
[Answer + implication for schema design: snapshot table? audit log? neither?]

Q4 — Intended vs actual:
[Any gaps between current schema behavior and intended behavior]

Q5 — Read patterns:
[Top queries + index implications]

Q6 — Relationships:
[Parent/child/sibling/external map]

Q7 — Edge cases:
[Unusual situations + schema implications]

Q8 — Data volume and growth:
[Row counts, growth rate, archive policy]

Q9 — Concurrency:
[Peak users, batch operations, locking implications]

Q10 — Data types and precision:
[Money columns, percentage columns, measurement columns, character sets]

---
Schema design can now proceed. Findings feed into: dba-schema-review, dba-data-flow-trace.
```

---

## Rules

1. **Ask, don't assume.** If the operator doesn't know an answer, log it as an
   assumption (ASS-NNN) and flag it — don't silently fill in a guess.
2. **Structure before optimization.** The answers to Q1-Q7 determine the table
   structure. Normalization and performance come AFTER the structure is right.
3. **One entity at a time.** Don't batch multiple entities — each gets its own
   interview. Cross-entity relationships are captured in Q6.
4. **Re-run on scope change.** If the operator reveals new behavior mid-design
   (e.g., "actually, the Name changes per stage"), re-run the affected questions
   before continuing schema work.

---

## What this prevents

| Failure mode | How this skill prevents it |
|---|---|
| Merging tables that need separate rows | Q3 catches temporal needs before merge |
| Inventing entities that don't exist | Q4 catches intended vs actual |
| Wrong column placement (shell vs content) | Q2 identifies what changes when |
| Missing per-stage snapshots | Q3 explicitly asks about history |
| Schema that doesn't match read patterns | Q5 aligns structure with queries |
| Orphan risk from missing cascade logic | Q6 maps dependencies, Q7 catches partial state |

---

## Quality checklist

- [ ] All 10 questions answered for the entity
- [ ] Any unknown answer logged as ASS-NNN, not silently assumed
- [ ] Temporal needs explicitly stated (not inferred from structure)
- [ ] Intended vs actual behavior confirmed with operator (not assumed from current state)
- [ ] Read patterns captured (not deferred to "later")
- [ ] Data volume estimated (rows now, in 1yr, in 5yr) — not left to "we'll see"
- [ ] Concurrency pattern known (peak users, batch-lock risk)
- [ ] Money columns identified → `decimal`, not `float`

## Failure exit

"Cannot proceed with schema design/restructuring for [entity] without a process
interview. Running dba-process-interview first."
