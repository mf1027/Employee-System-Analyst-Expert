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
- Does the FK column's type match the referenced PK's type exactly?
- If the referenced table uses a business key (NVARCHAR) as PK, does the FK use
  the same type and length?
- Will existing data in Domain A satisfy the new FK? (NULL values OK if nullable)

When adding a UNIQUE constraint:
- Does existing data have duplicates that would violate it?

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
7. Run all affected drills to validate
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
5. **Run the drills.** The final step is always: execute all affected drills and verify
   they still pass. Paper analysis is not enough.

---

## Quality checklist

- [ ] All consumer types searched (schema, drills, views, SPs, ERDs, docs)
- [ ] Every affected file listed with specific lines and impact severity
- [ ] Transitive impacts traced (table → view → SP → app)
- [ ] Constraint compatibility verified (type match, existing data, deferred FKs)
- [ ] Execution order specified
- [ ] Breaking impacts have concrete fix actions
- [ ] Drills re-run after all changes applied

## Failure exit

"Cannot analyze cross-domain impact without knowing what changed and which table(s)
are affected. Describe the schema change and the table(s) involved."
