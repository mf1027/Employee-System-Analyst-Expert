---
name: dba-schema-ingest
description: >-
  Parse the real database DDL (CREATE TABLE, ALTER TABLE, constraints, indexes)
  mechanically into a structured inventory. Produces: table list with column
  counts/types/PK/UK/identity, FK edges, and diagnostic flags (missing PKs, type
  mismatches, orphan-risk tables). Never trust hand-drawn ERDs or approximations —
  the DDL is the source of truth. Reusable parser scripts output stays out of
  context (ctx_execute_file or standalone scripts).
---

# dba-schema-ingest

The DBA's "ingest-reference" — but for database schemas specifically. Turns raw
DDL files into a structured, searchable inventory that all downstream DBA skills
depend on. Hand-drawn ERDs and diagrams are treated as **approximations** until
validated against the DDL.

---

## Trigger

Invoke when:
- The operator provides SQL DDL files (schema scripts, SSMS exports)
- A new database or schema needs to be cataloged
- The operator says "here's the schema", "I added the SQL files", "parse the DDL"
- Any DBA skill needs to reference table structure and the DDL hasn't been ingested yet

---

## Steps

### 1. Locate the DDL files

Check `reference/` for `.sql` files. Identify:
- Table schema DDL (CREATE TABLE)
- View DDL (CREATE VIEW) — ground-truth for relationships if no FKs
- Stored procedure DDL — defer unless needed for business-logic mining

### 2. Check encoding

SSMS exports are typically **UTF-16 LE with BOM**. Python's `open(f, 'r')` defaults
to UTF-8 and will fail. Always use `encoding='utf-16'` for SSMS-exported scripts.

**Tooling fallback:** the preferred way to parse a large DDL is `ctx_execute_file`
(keeps the raw bytes out of context). But that tool reads the file as UTF-8 and will
choke on the UTF-16 BOM, and `ctx_execute` may be permission-denied in some sessions.
When either happens, fall back to a standalone parser script (`scripts/parse-*.py`,
opened with `encoding='utf-16'`) run via the shell, or to content-filtered `Grep`/`Read`
against the DDL — same result, raw bytes still kept out of context because only the
structured summary is printed. Don't get stuck on the preferred tool; the goal is the
structured inventory, not the mechanism.

### 3. Parse mechanically (script, not eyeball)

Use or create a parser script (e.g., `scripts/parse-myps-schema.py`) that extracts:

| Output | What it captures |
|---|---|
| **Table inventory** | Name, column count, PK columns, UK columns, IDENTITY columns |
| **Column detail** | Name, type (with length), nullability, IDENTITY flag — per table |
| **FK edges** | child.column → parent.column (from ALTER TABLE ... FOREIGN KEY and inline CONSTRAINT) |
| **ALTER TABLE** | DEFAULT constraints, CHECK constraints |
| **Diagnostic flags** | Tables with no PK, columns with `varchar(max)` typed IDs, type mismatches across tables |

### 4. Parse views for relationship evidence

If the DDL declares **zero foreign keys** (common in legacy/app-enforced schemas),
parse the View DDL for JOIN/ON conditions — these are ground-truth relationship
evidence. Map alias → table and extract `a.col = b.col` edges.

### 5. As-built semantics verification (when deriving from a source system)

**Hard gate when the target schema derives from an as-built system** (e.g. myps_db from LOCAL-MYPS):
the DDL gives only *structure*. The source system + operator are the ground truth for *semantics*.
Before designing any object that depends on a status, enum, or lookup value:

1. **Query the source system** for the real values, not just the column types:
   ```sql
   SELECT * FROM [SOURCE-DB].dbo.tOptionRevisionStatus;
   ```
2. **Record the meaning** of each value — not just the row, but what the process uses it for.
   A column named `Status INT` with values 0-5 means nothing until you know 0=Pending, 1=Submitted, etc.
3. **Cross-check your assumptions.** If you planned to use `Status=4` for "Approved" but the source
   uses `Status=1`, your downstream objects (views, drills, routing logic) will all be wrong —
   and drills will pass because they test your assumption against itself.
4. **Interview the operator** on the process flow that *produces* the data, not just its shape.
   The schema tells you `tRevisionProjectSnapshot` has a `RevisionDetailFK`; only the operator
   tells you that every submitted revision MUST have a snapshot (no hollow parents).
5. **Verify generated FORMATS and derivation rules, not just lookup values (SKL-008).** Enum
   values live in lookup tables; *generated identifiers* and *derived values* do not — they live
   in business logic, so they're the easiest thing to invent. Before seeding or designing around any:
   - **Generated identifier** (e.g. a project/document code like `BP01000001LZ`) — get the exact
     format, segment widths, and generation algorithm from the operator or by inspecting real rows
     in the source system. Never infer the format from one example.
   - **Derived/rolled-up value** (e.g. a project status computed from component statuses) — get the
     precedence/derivation rule, not just the output column.
   Inspect real source rows to confirm: `SELECT TOP 20 [GeneratedIdCol] FROM [SOURCE-DB].dbo.[t];`

**Why this exists:** in the MYPS revision session, 6 errors were caught by the operator — not the
drill — because the fixture encoded the same wrong assumptions as the code. An enum was invented
instead of queried; 7/8 revisions were seeded without the snapshots the process guarantees; and the
ProjectId format (`BP01000001LZ`) was invented as `01-2026-F0001-C` because it's a *generated format*,
not a lookup value, so the enum-checking step missed it. A green drill on wrong assumptions is worse
than no drill. See memory: [[verify-against-as-built-before-building]].

**Output:** append an "As-Built Semantics" section to the ingest output:
```
AS-BUILT SEMANTICS (queried from [SOURCE-DB]):
  [table]: [value] = [meaning in the process]
  ...
  Process guarantees: [e.g. every tRevisionDetails has exactly 1 tRevisionProjectSnapshot]
```

### 6. Domain classification

Assign every table to a domain (e.g., Core, Detail, Revision, Lookups, Admin,
User/RBAC, Infra, Logs, Counters, Legacy/Dead). Flag any unclassified tables for
review.

### 7. Reconcile against existing ERDs

If hand-drawn ERDs exist, compare:
- Tables in DDL but NOT in ERD = **missing from the diagram**
- Tables in ERD but NOT in DDL = **invented / approximate**
- Column types that differ between DDL and ERD = **type mismatch**
- Table names that differ = **renamed in the diagram**

Log discrepancies. The DDL wins.

---

## Output format

```
SCHEMA INGEST: [Database name]
Client: [name] | Project: [name] | Date: [YYYY-MM-DD]
---
Source files: [list]
Encoding: [UTF-16 / UTF-8]
Tables: [count]
Views: [count]
Foreign keys declared: [count] (if 0: "ALL relationships are app-enforced")
Indexes declared: [count]

Domain classification:
  [Domain]: [table list]
  ...
  Legacy/Dead: [table list]
  Unclassified: [table list] (if any — review these)

Diagnostic flags:
  [N] tables with no primary key: [list]
  [N] type mismatches across tables: [details]
  [N] tables in DDL but not in existing ERDs: [list]

Parser script: [path to reusable script]
```

---

## Rules

1. **Parse, don't read.** The DDL should be processed by a script, not by reading
   2000+ lines into conversation context. Only the structured output enters context.
2. **DDL wins.** When hand-drawn ERDs conflict with the DDL, the DDL is authoritative.
   Update the ERD to match, not the other way around.
3. **Flag, don't fix.** If the parse finds missing PKs, type mismatches, or no FKs —
   log them as findings. Don't silently fix them in the output.
4. **Reusable scripts.** Save parser scripts to `scripts/` so they can be re-run when
   the DDL changes. Never hand-parse a second time.

---

## Quality checklist

- [ ] Every table in the DDL is accounted for (no silent omissions)
- [ ] Encoding handled correctly (UTF-16 for SSMS, UTF-8 for others)
- [ ] FK count stated explicitly (especially if zero)
- [ ] View JOINs parsed if FKs are absent
- [ ] Domain classification covers all tables
- [ ] Discrepancies with existing ERDs logged
- [ ] As-built semantics queried from source system (if deriving) — no invented enums
- [ ] Process guarantees documented (e.g. parent→child cardinality the process enforces)
- [ ] Parser script saved and reusable

## Failure exit

"Cannot ingest schema without DDL files. Provide the SQL schema scripts
(CREATE TABLE, optionally CREATE VIEW) in reference/ or specify the file paths."
