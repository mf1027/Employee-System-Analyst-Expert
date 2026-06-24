---
name: dba-performance-baseline
description: >-
  Captures before/after performance metrics for database queries — execution plan
  costs, I/O statistics, row counts, timing, and operator types as a snapshot.
  Produces a structured diff report after schema or index changes. Use this skill
  before and after any schema change, index modification, or query rewrite to
  measure actual impact rather than relying on gut feel.
---

# dba-performance-baseline

Performance optimization without measurement is guessing. This skill captures a
numbered snapshot of query metrics BEFORE a change, then captures the same metrics
AFTER, and produces a diff that shows exactly what improved, regressed, or stayed flat.

---

## Trigger

Invoke when:
- About to make a schema change that may affect query performance
- About to add, drop, or modify indexes
- About to rewrite a query, view, or stored procedure
- After a change, to verify it actually helped
- The operator says "baseline", "before/after", "measure the impact"

---

## Steps

### 1. Define the query set

Identify the queries to measure. These should be the same access patterns from
`dba-execution-plan` — the real-world queries that matter:

| Q# | Pattern | Query | Expected frequency |
|----|---------|-------|--------------------|
| Q1 | List view | SELECT ... GROUP BY ... | Every page load |
| Q2 | Detail view | SELECT ... JOIN ... WHERE Id = @id | Every click |
| Q3 | Filter | SELECT ... WHERE Status = @s | Frequent |

### 2. Capture the BEFORE snapshot

For each query, capture:

**SQL Server:**
```sql
-- Estimated plan costs:
SET SHOWPLAN_ALL ON;
GO
<query>
GO
SET SHOWPLAN_ALL OFF;
GO

-- Actual I/O and timing:
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO
<query>
GO
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
```

**Record these metrics per query:**

| Metric | Source | What it tells you |
|---|---|---|
| TotalSubtreeCost | SHOWPLAN_ALL (root node) | Optimizer's estimated cost (unitless, relative) |
| EstimateRows | SHOWPLAN_ALL (root node) | How many rows the optimizer expects |
| Logical reads | STATISTICS IO | Pages read from buffer cache (the key I/O metric) |
| Physical reads | STATISTICS IO | Pages read from disk (cold cache) |
| CPU time (ms) | STATISTICS TIME | CPU consumed |
| Elapsed time (ms) | STATISTICS TIME | Wall-clock time |
| Key operators | SHOWPLAN_ALL | Scan/Seek/Hash/Sort/Spool — the plan shape |

**PostgreSQL:**
```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) <query>;
-- Record: Planning Time, Execution Time, Buffers hit/read, Rows
```

**Store the snapshot in a structured format:**

```
BASELINE SNAPSHOT: BEFORE [change description]
Date: YYYY-MM-DD HH:MM
Engine: SQL Server 2025 Express
Row counts: tProjects=1000, tProjectRevisions=7000, tProjectGroups=50

| Q# | Pattern | SubtreeCost | EstRows | Logical Reads | CPU ms | Elapsed ms | Key Operator |
|----|---------|-------------|---------|---------------|--------|------------|--------------|
| Q1 | List    | 0.0100      | 50      | 12            | 0      | 1          | Index Seek   |
| Q2 | Detail  | 0.0178      | 1       | 8             | 0      | 0          | Cl.Idx Seek  |
| Q3 | Filter  | 0.0066      | 10      | 4             | 0      | 0          | Index Scan   |
```

### 3. Apply the change

Make the schema change, index modification, or query rewrite.

### 4. Capture the AFTER snapshot

Run exactly the same queries with exactly the same parameters. Record the same metrics.

### 5. Produce the diff report

Compare BEFORE and AFTER side by side:

```
PERFORMANCE DIFF: [change description]
Date: YYYY-MM-DD
Change: [what was changed — e.g., "Added IX_tProjects_ProjectGroupFK filtered index"]

| Q# | Metric         | Before | After  | Delta  | Verdict    |
|----|----------------|--------|--------|--------|------------|
| Q1 | SubtreeCost    | 0.0234 | 0.0100 | -57%   | Improved   |
| Q1 | Logical Reads  | 45     | 12     | -73%   | Improved   |
| Q1 | Key Operator   | Cl.Scan| Idx Seek| —     | Improved   |
| Q2 | SubtreeCost    | 0.0178 | 0.0178 | 0%     | Unchanged  |
| Q3 | SubtreeCost    | 0.0066 | 0.0066 | 0%     | Unchanged  |
| Q3 | Logical Reads  | 4      | 4      | 0%     | Unchanged  |
```

**Verdicts:**
- **Improved:** metric decreased (lower cost, fewer reads, faster)
- **Unchanged:** within ±5% — noise, not signal
- **Regressed:** metric increased — investigate why
- **Plan changed:** different operator type (e.g., Scan → Seek) — note even if cost is similar

### 6. Assess write-side impact (for index changes)

If indexes were added, also measure write performance:

```sql
-- Measure INSERT time with STATISTICS TIME:
SET STATISTICS TIME ON;
INSERT INTO dbo.tProjects (...) VALUES (...);
SET STATISTICS TIME OFF;
-- Compare before/after: each new index adds overhead to every INSERT/UPDATE/DELETE
```

### 7. Archive the snapshot

Store the baseline in the project's `database.md` or a dedicated performance log:

```markdown
## Performance Baselines

### Baseline 2026-06-23 — Before Project Groups schema
[snapshot table]

### Baseline 2026-06-23 — After Project Groups schema + IX_tProjects_ProjectGroupFK
[snapshot table]
[diff table]
```

---

## Output format

```
PERFORMANCE BASELINE: [Context]
Client: [name] | Project: [name] | Engine: [engine] | Date: [YYYY-MM-DD]
---
Change: [description of what is being measured]
Queries: [N]
Row counts: [key table sizes]

BEFORE SNAPSHOT:
| Q# | Pattern | Cost | Reads | CPU | Elapsed | Operator |
|----|---------|------|-------|-----|---------|----------|

AFTER SNAPSHOT:
[same format]

DIFF:
| Q# | Metric | Before | After | Delta | Verdict |
|----|--------|--------|-------|-------|---------|

WRITE IMPACT: [if indexes changed]
| Operation | Before ms | After ms | Delta |
|-----------|-----------|----------|-------|

CONCLUSION: [1-2 sentences: did the change help, hurt, or have no effect?]
```

---

## Rules

1. **Same queries, same parameters.** BEFORE and AFTER must use identical SQL and
   parameter values to be comparable.
2. **Warm the cache.** Run each query twice before measuring — the first run may include
   cold-cache physical reads that skew the comparison.
3. **Row counts matter.** Always state the row counts of key tables — a query that's
   fast on 100 rows may be slow on 100,000.
4. **Relative, not absolute.** TotalSubtreeCost is unitless — compare it to itself
   before/after, not to a universal threshold.
5. **Logical reads is the best single metric.** It measures how many 8KB pages the query
   touches — fewer reads = faster query, regardless of timing noise.
6. **Don't optimize what doesn't matter.** If Q3 runs once a month and takes 50ms,
   don't spend an hour optimizing it.

---

## Quality checklist

- [ ] Query set defined with access patterns and expected frequency
- [ ] BEFORE snapshot captured with all metrics
- [ ] AFTER snapshot captured with identical queries and parameters
- [ ] Diff produced with per-query verdict
- [ ] Write impact assessed (if indexes changed)
- [ ] Row counts stated for key tables
- [ ] Cache warmed before measurement
- [ ] Snapshot archived in project documentation

## Failure exit

"Cannot produce a performance baseline without queries to measure and a database
to run them against. Provide the queries and DB connection."
