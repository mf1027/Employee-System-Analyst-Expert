---
name: dba-data-flow-trace
description: >-
  Traces how data flows through the system for a specific entity — what gets
  INSERTed, UPDATEd, and DELETEd at each lifecycle step. Combines the process
  interview answers (dba-process-interview) with the schema inventory
  (dba-schema-ingest) to produce a step-by-step table-operation map. This is
  where schema design mistakes become visible — before they ship.
---

# dba-data-flow-trace

The bridge between "what the business does" (process interview) and "what the
database does" (schema). For each lifecycle step, this skill documents exactly
which tables receive which operations, proving the schema supports the business
process — or exposing where it doesn't.

---

## Trigger

Invoke when:
- A schema has been designed/restructured and needs validation
- The operator says "walk me through what happens when..."
- After dba-process-interview and dba-schema-ingest are complete
- Before any schema is marked "locked"

---

## Prerequisites

| Skill | Must be done first | Provides |
|---|---|---|
| dba-schema-ingest | Yes (step 1) | The real table inventory, columns, types, relationships |
| dba-process-interview | Yes (step 2) | The lifecycle steps, operations, temporal needs — informed by the ingest |

If either is missing, flag and run them in order (ingest → interview → then trace).

**Loop-back trigger:** If the trace reveals a behavioral fact that the interview
didn't capture (e.g., "this column changes per stage but the interview said it
doesn't") → return to `dba-process-interview`, amend Q2/Q3, then re-run the trace.

---

## Steps

### 1. List every lifecycle step from the process interview

From dba-process-interview Q1/Q2, enumerate:
- Create
- Edit (per distinct edit scenario)
- State change / stage advance
- Delete (hard vs soft, with boundary conditions)
- Import (if applicable)
- Any other operation (clone, fork, publish, approve)

### 2. For each step, trace the exact table operations

Document:

```
STEP: [name]
TRIGGER: [what the user does]
TABLES:
  [table] → INSERT / UPDATE / DELETE
    Columns affected: [list]
    Values: [source — form input / computed / copied from parent / SCOPE_IDENTITY]
  [table] → UNTOUCHED (explicitly state this)
TRANSACTION: required? (if multiple tables touched)
GUID/KEY FLOW: which keys are generated/captured/passed
```

### 3. Validate temporal needs

For each field the process interview (Q3) flagged as "user needs to see previous values":
- Is there a snapshot mechanism? (per-stage row, history table, audit log)
- Does the current schema preserve the old value, or overwrite it?
- If overwritten: **flag as a schema gap**

### 4. Check for partial-state risk

For each step that touches multiple tables:
- What happens if the operation fails after table 2 of 4?
- Is there a transaction boundary?
- What inconsistent state results from a partial failure?
- Flag each multi-table operation that lacks a transaction wrapper.

### 5. Produce the operation summary table

| Step | tTableA | tTableB | tTableC | Transaction? |
|---|---|---|---|---|
| Create | INSERT | INSERT | INSERT | Yes (3 tables) |
| Edit | — | UPDATE | — | No (1 table) |
| Advance | UPDATE (GUID) | INSERT | INSERT ×N | **Yes (N+2 tables)** |
| Delete (soft) | UPDATE | — | — | No (1 table) |
| Delete (hard) | — | DELETE | DELETE | Yes (children first) |

### 6. Produce the cumulative row count

At each lifecycle milestone (e.g., "at creation", "at GAA-R", "after first revision"),
show the expected row count per table. This validates the schema produces the right
number of rows — catches "always 1:1 but should be N" problems.

---

## Output format

```
DATA FLOW TRACE: [Entity]
Client: [name] | Project: [name] | Date: [YYYY-MM-DD]
---
Prerequisites: process interview [done/missing], schema ingest [done/missing]

Step-by-step trace:
  [Step 1: Create]
    [table operations with columns and value sources]
  [Step 2: Edit]
    ...

Temporal validation:
  [field]: history preserved? [yes — per-stage snapshot / no — overwritten]

Partial-state risks:
  [Step N]: touches [X] tables, no transaction → [describe inconsistent state]

Operation summary:
  [table with INSERT/UPDATE/DELETE per step]

Cumulative row count:
  [at creation]: [counts]
  [at GAA-R]:    [counts]
  [after revision]: [counts]
```

---

## Rules

1. **Every table must appear.** For each step, explicitly state whether each
   relevant table is INSERT/UPDATE/DELETE/**UNTOUCHED**. Silence is ambiguity.
2. **Show the key flow.** Which IDENTITY is captured via SCOPE_IDENTITY()? Which
   business key is passed to children? Which GUID changes?
3. **Flag every multi-table operation without a transaction.** This is the #1
   data-integrity risk in app-enforced schemas.
4. **Validate against the process interview.** If the interview says "Name changes
   per stage" but the trace shows "Name is UPDATE'd in-place with no snapshot" —
   that's a gap. Flag it immediately.

---

## Quality checklist

- [ ] Every lifecycle step from the process interview is traced
- [ ] Every relevant table shows its operation (or explicitly "UNTOUCHED")
- [ ] Temporal fields validated: snapshot mechanism exists or gap flagged
- [ ] Multi-table operations checked for transaction boundaries
- [ ] Cumulative row counts match expected behavior
- [ ] No step left as "obvious" — every INSERT/UPDATE is explicit

## Failure exit

"Cannot trace data flow without a process interview (dba-process-interview) and a
schema inventory (dba-schema-ingest). Run those first."
