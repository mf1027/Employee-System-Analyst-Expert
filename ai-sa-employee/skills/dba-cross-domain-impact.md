---
name: dba-cross-domain-impact
description: >-
  Analyzes the ripple effects of a schema change across domain boundaries —
  identifies which drills, views, stored procedures, INSERT scripts, migration
  files, and downstream consumers are affected. Produces a checklist of files
  to update before the change is safe to lock. Use this skill when a schema
  change touches a table owned by another domain, adds/removes/renames a column
  on a shared table, or modifies a constraint that other domains depend on.
---

# dba-cross-domain-impact

When a schema change in Domain A touches a table that Domain B depends on, things
break silently — drills fail, views return wrong columns, INSERT scripts miss the
new column. This skill prevents that by systematically mapping the blast radius
before the change is applied.

---

## Trigger

Invoke when:
- A schema change adds/removes/renames a column on a table used by other domains
- An FK is added from one domain's table to another domain's table
- A constraint (UNIQUE, CHECK, DEFAULT) is added or modified on a shared table
- A table is being merged, split, or dropped that other domains reference
- A view or SP references tables from multiple domains
- The operator says "what else does this affect", "ripple check", "cross-domain"

---

## Steps

### 1. Identify the change and the affected table(s)

State clearly:
- **What changed:** column added/removed/renamed/retyped, FK added, table dropped, etc.
- **Which table(s):** the specific tables being modified
- **Which domain owns the table:** the schema file that defines it

### 2. Map all consumers of the affected table(s)

Search for every file that references the affected table by name:

| Consumer type | Where to search | What to look for |
|---|---|---|
| **Schema files** (.sql) | `deliverables/documents/*schema*.sql` | CREATE TABLE, ALTER TABLE, FK REFERENCES |
| **Drill files** (.sql) | `deliverables/documents/drill-*.sql` | INSERT INTO, UPDATE, DELETE FROM, SELECT FROM |
| **View definitions** (.sql) | `deliverables/documents/*views*.sql` | SELECT FROM, JOIN ... ON |
| **Stored procedures** (.sql) | `deliverables/documents/*sp*.sql`, `*proc*.sql` | Any reference to the table |
| **Migration scripts** (.sql) | `migration/` | ALTER TABLE, data migration scripts |
| **ERD / diagram files** (.md) | `deliverables/diagrams/` | Mermaid entity references |
| **Documentation** (.md) | `database.md`, `decisions.md`, README files | Table/column mentions |
| **Application code** (if accessible) | Source repos | Entity classes, repository queries, Dapper SQL |

For each consumer, note:
- **File path**
- **Line(s) affected** (or "references table but column not used")
- **Impact:** BREAKS (uses the changed column directly), NEEDS UPDATE (must add new column),
  or UNAFFECTED (references table but not the changed column)

### 3. Classify impact severity

| Severity | Meaning | Example |
|---|---|---|
| **Breaking** | Consumer will fail (SQL error, constraint violation, wrong results) | Drill INSERT missing a new NOT NULL column |
| **Incomplete** | Consumer works but doesn't cover the new column/behavior | Drill doesn't test the new FK; view doesn't include the new column |
| **Cosmetic** | Documentation or comments are stale but nothing breaks | ERD diagram doesn't show the new column |
| **None** | Consumer references the table but is unaffected by this change | View SELECTs other columns from the same table |

### 4. Produce the impact checklist

For each affected consumer, state what needs to change:

```
IMPACT CHECKLIST:

[IC-001] BREAKING — drill-full-lifecycle.sql
  Lines: INSERT INTO dbo.tProjects (line 47, 89, 132)
  Issue: New column [ProjectGroupFK] not in INSERT column list.
         INSERT will succeed (column is nullable) but drill doesn't test the feature.
  Action: Add ProjectGroupFK to INSERT statements where group membership is tested.
  Priority: High

[IC-002] INCOMPLETE — myps-views.sql → vProjectLatest
  Lines: SELECT (line 12-35)
  Issue: View doesn't include ProjectGroupFK — group membership not queryable via view.
  Action: Add ProjectGroupFK to the view's SELECT list and GROUP BY.
  Priority: Medium

[IC-003] COSMETIC — myps-erd-asbuilt-from-sql.md
  Lines: tProjects entity definition
  Issue: ERD doesn't show new ProjectGroupFK column.
  Action: Update Mermaid ERD with new column and relationship line.
  Priority: Low
```

### 5. Check for transitive impacts

A change to Table A may affect View V which is used by SP P which is called by
Application Code C. Trace the chain:

```
tProjects (column added)
  → vProjectLatest (uses tProjects) → needs column added to SELECT
    → [Application] ProjectListPage (uses vProjectLatest) → may need UI update
  → drill-full-lifecycle.sql (INSERTs into tProjects) → needs column in INSERT
  → drill-multi-revision.sql (INSERTs into tProjects) → needs column in INSERT
```

### 6. Verify no constraint conflicts

When adding an FK from Domain A to Domain B:
- Does Domain B's table exist in the database? (or is it deferred?)
- Does the FK column's type match the referenced PK's type **exactly — including length/scale**?
  SQL Server rejects `FK NVARCHAR(100) → PK NVARCHAR(10)` with a length-mismatch error.
  Check width, not just type. (Caught live: `ComponentType NVARCHAR(100)` → lookup `NVARCHAR(10)`.)
- If the referenced table uses a business key (NVARCHAR) as PK, does the FK use
  the same type and length?
- Will existing data in Domain A satisfy the new FK? (NULL values OK if nullable)

When adding a UNIQUE constraint:
- Does existing data have duplicates that would violate it?

**SQL batch rules when deploying multi-statement DDL:** `CREATE VIEW/PROCEDURE/FUNCTION/TRIGGER`
must be the **first statement in its batch** — separate each with `GO`. A combined deploy script
that omits `GO` before a `CREATE VIEW` fails with "must be the first statement in a query batch."

### 6b. Cascade rename — the paired-list trap

A bulk column rename (e.g. ADR-018 renaming ProgramId→ProgramPK + 3 others at once) has a failure
mode plain reference-search misses: **automated find-replace desyncs paired column lists.** The
rename touches one side of a pair but not the other, and the SQL still parses — so it fails at
runtime or, worse, silently moves the wrong data.

Check every place columns come in *matched pairs*, both sides:

| Construct | The trap |
|---|---|
| `INSERT (cols…) SELECT (cols…)` | Rename updated the INSERT list but **not the SELECT source** (or vice-versa) → positional mismatch, wrong column loads |
| `JOIN a ON a.X = b.X` | One side renamed, the other not → join on stale column |
| Dynamic SQL / string-built queries | Find-replace skips columns inside string literals |
| Seed/`tRevisionRules` JSON field names | Renamed schema columns but **not** the JSON keys that mirror them |
| `ORDER BY` / `GROUP BY` / `WHERE` using old name | Parser error or stale reference |

**Rule for renames:** for each renamed column, grep the *old* name AND the *new* name across all
consumers. Any file containing both is a desync suspect. Any file with only the old name is unmigrated.
Verify INSERT↔SELECT and JOIN both-sides pairing by reading the statement, not just matching the name.

**Homonym trap (SKL-015):** before a global find-replace, check whether the old name *also* names a
column on a **different, unrelated table**. `TransactionId` was dropped from `tTransactionLog` but is a
live column on `tRevisionDetails` — a blind replace-all of `TransactionId` would have silently corrupted
the `tRevisionDetails` INSERT. Renames must disambiguate **by table**, never by bare column name. After
editing, grep the *old* name one more time and confirm every survivor sits on a table that legitimately
still owns it — a straggler most often hides in the one syntactic position your edits didn't target
(a `WHERE`/`DELETE` filter, not the INSERT/SELECT you were focused on). Caught live: a `WHERE
TransactionId IN (…)` cleanup line survived a rename pass; only the drill re-run (SKL-013) flagged it.

### 7. Recommend execution order

If multiple files need updating, state the order:

```
EXECUTION ORDER:
1. Create tProjectGroups table (schema-project-groups.sql)
2. ALTER tProjects ADD ProjectGroupFK (schema-project-groups.sql)
3. Update drill-full-lifecycle.sql (add ProjectGroupFK to INSERTs + cleanup)
4. Update drill-multi-revision.sql (same)
5. Update myps-views.sql → vProjectLatest (add column to SELECT)
6. Update ERD diagram (cosmetic)
7. Run the ENTIRE drill suite to green — clean-slate per drill (SKL-013/014), not just affected ones
```

---

## Output format

```
CROSS-DOMAIN IMPACT ANALYSIS: [Change description]
Client: [name] | Project: [name] | Date: [YYYY-MM-DD]
---
Change: [what changed]
Table(s): [affected tables]
Owner domain: [schema file]

CONSUMER MAP:
| # | File | Type | References | Impact | Severity |
|---|------|------|-----------|--------|----------|
| 1 | drill-full-lifecycle.sql | Drill | INSERT tProjects (L47,89) | Missing new column | Breaking |
| 2 | myps-views.sql | View | SELECT tProjects (L12) | Column not in SELECT | Incomplete |
| 3 | ERD diagram | Doc | tProjects entity | Column missing | Cosmetic |

IMPACT CHECKLIST:
[IC-001] ...
[IC-002] ...

TRANSITIVE CHAIN:
[chain diagram if applicable]

CONSTRAINT CHECK:
[FK type match, existing data compatibility, deferred references]

EXECUTION ORDER:
1. ...
2. ...

ESTIMATED EFFORT: [quick estimate — trivial/small/medium/large]
```

---

## Rules

1. **Search, don't guess.** Use grep/glob to find all references — don't rely on memory
   of which files reference a table.
2. **Nullable saves you.** A new nullable column won't break existing INSERTs — but the
   drill should still be updated to test it.
3. **Deferred FKs are OK.** If the referenced table doesn't exist yet (e.g., tGroups for
   User Management), document the FK as deferred and note when it should be wired.
4. **Breaking > Incomplete > Cosmetic.** Fix Breaking issues before merging. Incomplete
   can be a follow-up. Cosmetic can wait.
5. **Run the drills — ALL of them, to green (SKL-013).** The final step is always: execute
   **every** drill in the suite (not just the ones you think are affected) and confirm each runs
   green. Drills are executable consumers that rot silently: caught live — a PCMA refactor +
   ADR-018 rename left 5 of 6 drills broken while the docs listed all 6 as valid with check counts.
   Paper analysis is not enough; a drill is not "valid" until an execution proves it.
   Note the runner reality (SKL-014): targeted-cleanup drills can share business keys and can't
   always coexist — run each against a clean transactional slate.
6. **Definition of Done — docs are consumers (SKL-010); drills are EXECUTABLE consumers (SKL-013).**
   A schema change is NOT complete until **every** consumer is updated **in the same pass** — the
   documentation consumers (`database.md`, ERDs, data-flow diagrams, design specs, developer
   handoffs, consolidated process-flow) **and** every drill **re-executed to green**. Do not report
   a change "done" with stale docs or an un-run drill. (Caught live: a component rework left 6 docs
   stale until the operator asked — twice (SKL-010); a later PCMA refactor + rename left 5 of 6
   drills broken while docs vouched for them (SKL-013).)

   **Finish with a stale-term consistency sweep (WFC-006).** After editing every consumer in the
   pass, build a short list of terms/phrases that describe the **superseded** concept (the exact
   words the old design used — e.g. a dropped rule count, a removed table name, a retired process
   description) and grep every touched consumer for them. The pass isn't done until that grep comes
   back with **zero live hits** (matches inside "superseded"/"was X, now Y" explanatory notes are
   fine — those are supposed to still mention the old term). Report the grep as evidence, not just
   a claim of completeness. This has caught real stragglers twice: a 07-01 drill-suite repair and a
   07-06/07 nine-document rewrite each had 2–3 leftover mentions of the old design that a
   file-by-file read-through missed but the terminal grep caught immediately.

---

## Quality checklist

- [ ] All consumer types searched (schema, drills, views, SPs, ERDs, docs)
- [ ] Every affected file listed with specific lines and impact severity
- [ ] Transitive impacts traced (table → view → SP → app)
- [ ] Constraint compatibility verified (type match, existing data, deferred FKs)
- [ ] Execution order specified
- [ ] Breaking impacts have concrete fix actions
- [ ] **EVERY** drill re-executed to green (SKL-013) — not just the touched ones; no drill labeled "valid" in docs without an execution behind it
- [ ] FK width/length checked (not just type); CREATE VIEW/SP/FN GO-separated
- [ ] **Definition of Done:** docs/diagrams/specs/process-flow updated in the same pass (SKL-010)
- [ ] **Stale-term sweep run, zero live hits (WFC-006)** — grep the superseded concept's exact
      terms across every touched consumer; report the grep result as evidence

## Failure exit

"Cannot analyze cross-domain impact without knowing what changed and which table(s)
are affected. Describe the schema change and the table(s) involved."
