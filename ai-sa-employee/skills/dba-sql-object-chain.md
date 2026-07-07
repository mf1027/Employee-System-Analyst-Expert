---
name: dba-sql-object-chain
description: >-
  Design chain for views, stored procedures, functions (TVFs, scalar), and CTEs —
  analogous to the schema sub-skill chain but for SQL objects. Covers purpose
  definition, dependency mapping, draft writing, execution plan validation, and
  drill integration. Use this skill when the operator says view, stored procedure,
  SP, function, TVF, CTE, or when a schema change requires a new or updated SQL object.
---

# dba-sql-object-chain

The schema chain (ingest → interview → trace → review → drill) ensures tables are
right before they're locked. SQL objects (views, SPs, functions) deserve the same
rigor — they sit between the schema and the application, and a bad view is as
harmful as a bad table.

---

## Trigger

Invoke when:
- Creating a new view, SP, function, or CTE
- Modifying an existing SQL object after a schema change
- The operator says "create a view", "write an SP", "optimize this function"
- A drill or execution plan reveals a problematic SQL object
- dba-cross-domain-impact identifies a view/SP that needs updating

---

## Chain steps

### 1. Purpose — what does this object do and who calls it?

Before writing any SQL, answer:

| Question | Why it matters |
|---|---|
| What does this object return? | Defines the SELECT list / output shape |
| Who calls it? (app code, another view, a report, ad-hoc) | Determines performance requirements |
| How often is it called? (every page load, nightly batch, on-demand) | Determines acceptable cost |
| What parameters does it take? (SP/function) | Defines the interface contract |
| Does it write data or is it read-only? | View = read-only. SP can write. Function should not (side effects). |

### 2. Dependency map — what tables/objects does it touch?

List every table, view, function, or SP that the object depends on:

```
vProjectLatest
  ├── tProjects (direct)
  ├── tProjectRevisions (direct)
  ├── tProjectStages (direct)
  ├── tProjectGroups (direct — via FK on tProjects)
  └── tRevisionApprovals (direct — via pivot)
```

Check:
- Do all referenced tables exist?
- Are the column names correct (no renames since last version)?
- Are there circular dependencies? (View A → View B → View A)
- Will schema changes to any dependency break this object?

### 3. Draft — write the SQL

Follow these conventions:

**Views:**
- Always use `CREATE OR ALTER VIEW` (SQL Server 2016+) or `CREATE VIEW` + `DROP IF EXISTS`
- Schema-qualify all table references (`dbo.tProjects`, not `tProjects`)
- Alias all columns clearly — no ambiguous column names in JOINs
- Include only columns the consumers actually need (no `SELECT *`)
- For "latest revision" patterns, use `ROW_NUMBER()` or `MAX(Id)` subquery — document which

**Stored procedures:**
- Use `CREATE OR ALTER PROCEDURE`
- Declare all parameters with types and defaults
- Include `SET NOCOUNT ON` at the top
- Wrap writes in explicit transactions
- Return meaningful result codes or output parameters

**Functions:**
- Prefer inline TVFs over multi-statement TVFs (multi-statement forces row-by-row execution)
- Avoid scalar UDFs in WHERE clauses (forces row-by-row evaluation in SQL Server)
- If a scalar function is needed, consider converting to an inline TVF with CROSS APPLY

**CTEs:**
- Use CTEs for readability, not for performance (CTEs are not materialized in SQL Server)
- Recursive CTEs: always include a `MAXRECURSION` option to prevent infinite loops
- For CTEs referenced multiple times, consider a temp table instead (CTE re-executes each time)

### 4. Execution plan validation

Run the object's primary query through `dba-execution-plan`:
- Generate an estimated execution plan
- Check for Table Scans, Key Lookups, Sort operators
- Verify indexes are being used as expected
- For views: test both direct `SELECT * FROM vMyView` and
  `SELECT ... FROM vMyView WHERE filter` (the filter may not push down)

### 5. Drill integration

Add test queries for the object to the relevant drill file:
- For views: SELECT from the view and verify it returns expected rows/columns
- For SPs: EXEC the SP and verify output
- For functions: SELECT from the function and verify return values
- Include edge cases: empty result sets, NULL parameters, boundary values

---

## Object-specific checklists

### View checklist
- [ ] All columns explicitly listed (no SELECT *)
- [ ] All tables schema-qualified (dbo.tTable)
- [ ] JOIN conditions verified against FK definitions
- [ ] "Latest revision" logic correct (MAX, ROW_NUMBER, or TOP 1)
- [ ] Execution plan shows seeks, not scans on fact tables
- [ ] WHERE filter pushdown verified (if view is filtered externally)
- [ ] Column names are unambiguous (aliased where needed)
- [ ] SCHEMABINDING considered (prevents accidental table drops)

### Stored procedure checklist
- [ ] SET NOCOUNT ON included
- [ ] Parameters declared with correct types matching column types
- [ ] Write operations wrapped in transactions
- [ ] Error handling with TRY/CATCH (for write SPs)
- [ ] Output parameters or return codes documented
- [ ] No dynamic SQL unless necessary (SQL injection risk)
- [ ] Execution plan validated for the primary code path

### Function checklist
- [ ] Inline TVF preferred over multi-statement TVF
- [ ] No scalar UDFs used in WHERE clauses
- [ ] Return type documented
- [ ] NULL handling explicit (what happens with NULL input?)
- [ ] CROSS APPLY pattern documented for consumers

---

## Output format

```
SQL OBJECT DESIGN: [Object name]
Type: [VIEW / SP / FUNCTION / CTE]
Client: [name] | Project: [name] | Engine: [engine] | Date: [YYYY-MM-DD]
---
Purpose: [1-2 sentences]
Caller: [who/what calls this]
Frequency: [how often]

DEPENDENCIES:
  [table/object list with relationship]

SQL:
  [the CREATE statement]

EXECUTION PLAN:
  [key findings from plan analysis]

DRILL COVERAGE:
  [which drill file tests this, what checks are added]
```

---

## Rules

1. **Purpose before SQL.** Define what the object does before writing it.
2. **No SELECT * in views.** Explicit column lists prevent surprises on schema changes.
3. **Inline TVF over multi-statement.** Multi-statement TVFs are performance traps.
4. **Schema-qualify everything.** `dbo.tTable`, not `tTable`.
5. **Plan-validate before shipping.** Every new object gets an execution plan check.
6. **`SELECT @var += expr ... ORDER BY` is undefined behavior (SKL-019).** Building a string by
   accumulating a variable across rows with an `ORDER BY` is not guaranteed by SQL Server — a plan
   recompile can silently change or drop the accumulated content. Use `STRING_AGG(expr, sep) WITHIN
   GROUP (ORDER BY ...)` instead — it's the documented, deterministic equivalent. Cast the
   expression to `NVARCHAR(MAX)` if any branch could exceed `STRING_AGG`'s 8000-byte default.
7. **Classic ODBC sqlcmd eats leading `[bracket]` output lines (SKL-019).** `sqlcmd` (the older
   ODBC-driver build, not the newer Go rewrite) silently drops the **first line** of a `PRINT`
   message when that line starts with `[` — the same logic it uses to strip its own
   `[Microsoft][ODBC Driver...]` prefixes. A generated object whose first line is an attribute like
   `[Table(...)]` or `[Key]` vanishes from both console and `-o` file output with no error. This is
   a **display-layer** bug, not a SQL bug — SSMS is unaffected. If a helper proc prints generated
   code, guard it: when a print chunk's first character is `[`, prepend a blank line so the bracket
   line is never the message's first line.

## Failure exit

"Cannot design a SQL object without knowing its purpose, consumers, and the underlying
schema. Describe what the object should do and which tables it needs."
