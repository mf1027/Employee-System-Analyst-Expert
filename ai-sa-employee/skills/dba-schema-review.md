---
name: dba-schema-review
description: >-
  Structured review of a database schema for normalization violations, referential
  integrity gaps, type inconsistencies, naming problems, and missing constraints.
  Core rule: FLAG violations with evidence, do NOT silently fix them. Every finding
  is presented as "here is what's wrong, here is the impact, here are your options"
  — the operator/developer decides which to act on.
---

# dba-schema-review

The DBA's code-review equivalent — but for database schemas. Produces a structured
findings report with severity, impact, and options. Does NOT auto-fix.

---

## Trigger

Invoke when:
- A schema has been ingested (dba-schema-ingest) and needs quality review
- The operator says "review the schema", "check for issues", "normalize this"
- Before locking a recommended schema
- After the data flow trace reveals gaps

---

## Prerequisites

| Skill | Must be done first | Why |
|---|---|---|
| dba-schema-ingest | Yes | Need the real table/column/type inventory |
| dba-process-interview | Recommended | Helps distinguish "redundancy by design" from "redundancy by accident" |

---

## Review dimensions (check ALL of these)

### 1. Normalization (1NF → 3NF)

| Form | What to check | Common violations |
|---|---|---|
| **1NF** | Every column stores a single atomic value | CSV-delimited ID lists (`ActionIds nvarchar(2000)`), JSON blobs in nvarchar columns, repeated column groups (`Year1`, `Year2`, `Year3`) |
| **2NF** | Every non-key column depends on the WHOLE key (composite PKs only) | Column depends on only part of a composite PK |
| **3NF** | No non-key column depends on another non-key column | `StatusCode` + `StatusName` stored together (name depends on code, not on PK); denormalized parent names (`ProvinceName` in a city table that has `ProvinceFK`) |

**For each violation:** state the affected table/columns, the dependency that's wrong,
the impact (update anomaly, data drift, join hazard), and two options:
- **Normalize** (create a lookup, remove the transitive column)
- **Keep as intentional denormalization** (document as ADR, accept the trade-off)

**NEVER silently create a new table to fix a violation.** Ask first: "does a lookup
already exist for this?"

### 2. Referential integrity

| Check | What to look for |
|---|---|
| FK declarations | Count of declared FOREIGN KEY constraints (if zero: "ALL integrity is app-enforced") |
| Orphan risk | For each parent-child relationship: what prevents inserting a child with a non-existent parent? |
| Cascade behavior | On DELETE: does the DB cascade, restrict, or do nothing? Is this documented? |
| Cross-table type consistency | Does `child.FK_column` have the same type/length as `parent.PK_column`? |

### 3. Type consistency

For columns that represent the same concept across multiple tables:
- Same type? (`int` vs `nvarchar` for the same status code = join hazard)
- Same length? (`nvarchar(10)` vs `nvarchar(20)` = truncation risk)
- Same nullability? (NN in one table, NULL in another = insert failures on migration)

### 4. Primary key coverage

- Every table should have a PK
- Flag tables with no PK (cannot be uniquely identified, cannot be reliably joined)
- Flag tables where the PK is just an IDENTITY with no business-key UK

### 5. Naming consistency

| Pattern | What to check |
|---|---|
| Table naming | Consistent prefix convention (e.g., `t` prefix, `tOption` for lookups) |
| Column naming | Same concept = same name everywhere (not `ProjectId` in one table and `ReferenceId` in another) |
| FK naming | FKs should be distinguishable from the column they reference (e.g., `ProjectFK` vs `ProjectId`) |
| Casing | Consistent PascalCase vs snake_case (mixed = two generations, flag which is live) |

### 6. Missing constraints / defaults

- Columns that should have DEFAULT values (e.g., `IsDeleted DEFAULT 0`)
- Columns that should have CHECK constraints (e.g., `Percentage BETWEEN 0 AND 100`)
- Columns that should be NOT NULL but are nullable

### 7. Index coverage (light pass)

- Are the most common FK columns indexed?
- Are filtered indexes used for soft-delete patterns (`WHERE IsDeleted = 0`)?
- Are there obvious missing indexes based on the read patterns from the process interview?

### 8. Data type safety

| Check | What to look for | Severity |
|---|---|---|
| **float for money** | Any column storing monetary amounts (`Cost`, `Amount`, `Total`, `Budget`) or percentages that must sum to exactly 100% typed as `float` or `real` → must be `decimal(18,2)` or `decimal(5,2)` | **High** — silent rounding errors in financial reports; passes every test until it doesn't |
| **nvarchar(max) for short values** | Columns like GUIDs, codes, or IDs typed as `nvarchar(max)` instead of `nvarchar(N)` → wastes storage, blocks indexing (max columns can't be index keys) | **Medium** |
| **datetime vs datetime2** | Columns using `datetime` (3.33ms precision) where `datetime2` (100ns) or `date` (date-only) would be more appropriate | **Low** — functional but less precise |
| **timestamp/rowversion misuse** | Any `timestamp` column intended to store dates → `timestamp` is a binary row-version in SQL Server, NOT a date | **High** — silent data corruption |

### 9. Collation awareness

- What collation does the database use? (`SELECT DATABASEPROPERTYEX(DB_NAME(), 'Collation')`)
- Are business-key comparisons (ProgramId, ProjectId) case-sensitive or not?
- If the DB is CI (case-insensitive), do any UK/FK values depend on case distinction?
- If mixed collations exist across tables, flag potential collation-conflict errors on JOINs.

Not every project needs a deep collation audit, but **checking the database collation once** at
the start of schema work prevents a class of subtle JOIN/WHERE bugs.

### 10. Temporal-table evaluation (SQL Server 2016+)

If the schema uses a **manual snapshot pattern** (one row per stage/version, linked by a
RevisionId or similar), evaluate whether SQL Server **system-versioned temporal tables** could
replace it:

```sql
-- Temporal tables provide automatic row-level history with zero manual snapshot code:
CREATE TABLE tExample (
    Id INT PRIMARY KEY, Col1 NVARCHAR(100),
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START,
    ValidTo   DATETIME2 GENERATED ALWAYS AS ROW END,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.tExampleHistory));
```

| When temporal fits | When manual snapshots are better |
|---|---|
| Every edit should be tracked (full audit trail) | Only specific events (stage advances) create history |
| History granularity = every change | History granularity = per-stage only (edits within a stage should NOT create history) |
| Point-in-time queries by datetime (`AS OF '2026-01-15'`) | Point-in-time queries by stage name (`JOIN stages ON RevisionId`) |
| No need to control which columns are versioned | Some columns are mutable (per-stage) while others are immutable (on shell) |

**Flag it as a design option** with the trade-off table above. Don't assume it's better or
worse — let the operator see both options. For MYPS, manual snapshots were chosen because
history is per-stage (not per-edit) and the shell/snapshot split needs explicit control.
Document the evaluation even when the answer is "manual snapshots win."

---

## Output format

```
SCHEMA REVIEW: [Database / Entity]
Client: [name] | Project: [name] | Date: [YYYY-MM-DD]
---
Tables reviewed: [count]
Findings: [count] (Critical: N, High: N, Medium: N, Low: N)

FINDINGS:

[F-001] [Severity: Critical/High/Medium/Low]
  Table(s): [affected]
  Issue: [what's wrong]
  Evidence: [column names, types, or values that prove it]
  Impact: [what breaks for users/data]
  Options:
    A. [Normalize / fix — what to change]
    B. [Keep as-is — document as intentional, accept trade-off]
  Decision: [PENDING — operator must choose]

[F-002] ...

SUMMARY:
  Normalization: [N violations]
  Referential integrity: [N gaps]
  Type consistency: [N mismatches]
  Type safety: [float-for-money, nvarchar(max), timestamp misuse]
  PK coverage: [N tables without PK]
  Naming: [N inconsistencies]
  Constraints: [N missing]
  Indexes: [N recommendations]
  Pagination: [keyset-ready or offset-only?]
  Temporal: [evaluated — manual snapshots / temporal tables / not applicable]
```

---

## Rules

1. **Flag, don't fix.** Present findings with options. The operator/developer decides.
2. **Ask "does it already exist?"** Before recommending a new lookup table, check the
   DDL for an existing one (e.g., `tOptionPCMAStatus` before inventing `tOptionConstructionStatus`).
3. **Distinguish design from accident.** Use the process interview to tell whether a
   denormalization is intentional (performance, snapshot) or accidental (copy-paste, tech debt).
4. **No finding without evidence.** Every finding cites specific table.column + type/value.
5. **Severity is about impact, not aesthetics.** A naming inconsistency is Low; a type
   mismatch on a JOIN column is High; a missing PK on a high-traffic table is Critical.
6. **Keep pre-gate "target shapes" to a sketch, not a migration.** When the interview
   hasn't cleared yet, it's fine to show *what* a fix would look like — but keep it to a
   brief illustrative shape (a one- or two-line column sketch), clearly marked "illustrative,
   not locked." Do NOT write full `CREATE TABLE` + seed `INSERT`s + `ALTER`/migration scripts
   before the gate. Why: a complete, copy-pasteable migration *reads as a decision already
   made* — it nudges the operator (and you) toward executing it before the questions that
   should shape it are answered. The full DDL belongs in `dba-schema-drill`, after the
   interview locks the design. A terse sketch communicates the option without pre-committing
   to it.

---

## Quality checklist

- [ ] All 7 review dimensions checked
- [ ] Every finding has severity + evidence + impact + options
- [ ] No new entities invented without asking "does it already exist?"
- [ ] Pre-gate fixes shown as a brief sketch only — no full CREATE/seed/migration DDL before the interview clears
- [ ] Process-interview context used to distinguish intentional vs accidental patterns
- [ ] Type mismatches explicitly checked across tables for shared concepts
- [ ] Data type safety checked: no float-for-money, no nvarchar(max) for short values, no timestamp-as-date
- [ ] Collation checked (at least database-level collation known)
- [ ] Temporal-table evaluation documented (even if answer is "manual snapshots win")
- [ ] Pagination readiness checked: keyset-pagination-friendly PKs/indexes exist on list-query tables
- [ ] FK count stated (especially if zero)

## Failure exit

"Cannot review schema without a schema inventory (dba-schema-ingest). Run that first.
Process interview (dba-process-interview) is recommended for context but not blocking."
