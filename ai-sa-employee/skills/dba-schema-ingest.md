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

### 0. Design preflight — read the project's OWN prior deliverables first (SKL-011)

**Before any design interview, check whether the module is already (partly) designed.** The
as-built source (SKL-006/008) is one ground truth; the **project's own confirmed deliverables are
another** — and re-deriving a design that already exists wastes the operator's time and risks
building something *different* from what was agreed.

For the module in scope, scan the client/project folder before asking design questions:

| Where | Look for |
|---|---|
| `deliverables/diagrams/*.md` | C4 models, process-flow diagrams, ERDs for THIS module |
| `deliverables/documents/*.md` | design specs, developer handoffs, functional specs |
| `decisions.md` | an ADR that already locked this module's design |
| `database.md` module table | status lines like "C4 model done", "flows done" — **open and read those files, don't just note the label** |

Grep the module name (and its synonyms) across the project folder. If confirmed design exists:
- **Start from it**, reconcile deltas against the operator's latest answers (operator wins on
  conflict), and note what changed — do **not** re-interview from scratch.
- A status label such as *"interview pending"* is **not** proof no design exists — a prior client
  meeting may have produced confirmed rules. Verify by opening the artifacts, not by trusting the label.

Only when no prior confirmed design is found (or the operator says start fresh) proceed to interview.

> Caught live (SKL-011): a full `tLumpSumDetails` schema interview ran ~10 turns before the
> confirmed `tLSWallets` C4 model + 8 process flows (client-meeting 2026-06-16) were found — only
> because the operator said "check the md files." The signal ("C4 model done") was already in
> `database.md` and got read past.

**Mechanism-level preflight (SKL-035) — the same discipline extends past table shapes to procedural
logic.** SKL-011 above catches a re-derived *schema*; this catches a re-derived *algorithm*. Before
writing any non-trivial procedural logic in a new mock/drill/proc — ID construction, stage-advance /
copy-forward loops, state-machine transitions, any multi-step sequence with a locked spec — **grep
the spec docs AND the prior mock/drill files for the same mechanism first.** A working, already-correct
implementation may already exist, and a locked spec doc (e.g. `project-id-generation-spec.md`) is the
authority, not memory. Two related traps:
- **Reference impl already exists.** Reconstructing a loop from memory when a correct one is already
  filed re-does work and risks diverging from the agreed behavior.
- **A drill that checks "did it run" is not a spec-compliance check.** "IDs were generated" and "IDs
  match the documented format" are *distinct* assertion categories — a drill that only proves the
  former gives false confidence. When a locked format/spec exists, assert the output against it
  explicitly (byte/format match), not just existence.

> Caught live (SKL-035): rebuilt `myps-mock-full-lifecycle.sql`'s BP→P `ProjectId` swap +
> year-zero-padding loops from scratch when a correct reference impl already existed in
> `myps-mock-program-lifecycle.sql`, and never re-read the locked `project-id-generation-spec.md`.
> Shipped a "23/23 PASS" drill that never checked ID *format* compliance. Operator: *"do you have no
> records or knowledge about the generation of the ProjectId?! it looks like you didn't plan
> thoroughly."* The records existed and weren't consulted.

### 1. Locate the DDL files

Check `reference/` for `.sql` files. Identify:
- Table schema DDL (CREATE TABLE)
- View DDL (CREATE VIEW) — ground-truth for relationships if no FKs
- Stored procedure DDL — defer unless needed for business-logic mining

### 2. Check encoding

SSMS exports are typically **UTF-16 LE with BOM**. Python's `open(f, 'r')` defaults
to UTF-8 and will fail. Always use `encoding='utf-16'` for SSMS-exported scripts.

**If the reference material is a spreadsheet export (CSV/xlsx), also precheck code/ID columns for
Excel scientific-notation corruption (SKL-030).** Excel silently rewrites any long numeric-looking
string (an ID, a hierarchical code) as scientific notation the moment a column isn't explicitly
typed as text — `104305000` → `1.03171E+12`. This destroys the exact value a join/business key
depends on, and a quick eyeball of a few rows won't catch it (short codes survive; only the long
ones corrupt). Before treating any such column as authoritative:

```
grep -c 'E+' the_file.csv     # or a per-column scan if multiple code columns exist
```

Any non-zero count means that column cannot be used as a join key until the source is re-exported
with it forced to text — reformatting the corrupted value back is lossy once precision is lost past
~15 significant digits. Caught live twice on the same domain: 74 `CityMunicipality.Code` values in
one AAMS export, then 1,620/1,643 city rows + 46/257 district rows (99%/18%) in a second,
independently-supplied CSV set months later — this recurs with every fresh Excel-touched export of
the same source data, so it's a standing check, not a one-time fix.

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

6. **A parent-shaped column proves a linkage exists, not what kind (SKL-024).** If a table carries
   only one column that looks like a parent reference (e.g. `ProvinceGdbId` on a district-office
   table), it's tempting to wire it as *the* hierarchy `ParentId`. But a table can sit at the
   intersection of more than one hierarchy — organizational, geographic, financial — and only one
   of them is the real tree parent. Ask the operator (or `dba-process-interview` Q6) explicitly:
   *which* relationship is the org-chart/hierarchy parent, not just *whether* a parent-shaped column
   exists. Caught live (MYPS admin-area, 2026-07-08): a district office's `ProvinceGdbId` was wired
   as `ParentId` on the assumption it was the only candidate — it was a geographic fact, not the
   organizational parent (which turned out to be the Region, sourced from an external authoritative
   file after the fact).

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
- [ ] If source is a spreadsheet export, code/ID columns prechecked for `E+`/`e+` scientific-notation corruption (SKL-030)
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
