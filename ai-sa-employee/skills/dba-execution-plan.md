---
name: dba-execution-plan
description: >-
  Analyzes estimated and actual execution plans for database queries — identifies
  Table Scans, missing indexes, expensive operators, implicit conversions, and
  cardinality estimation errors. Produces a structured findings report with
  concrete index recommendations. Use this skill whenever the operator mentions
  execution plan, query plan, slow query, SET SHOWPLAN, SET STATISTICS, scan vs
  seek, missing index, or when a drill needs performance validation.
---

# dba-execution-plan

Reads execution plans (estimated or actual) and translates optimizer decisions into
actionable findings. The goal is not to explain every operator — it's to surface
the 3–5 things that matter for performance and produce concrete fixes.

Engine-aware: defaults to SQL Server (SHOWPLAN_ALL / SHOWPLAN_XML / STATISTICS IO).
Adapts to PostgreSQL (EXPLAIN ANALYZE), MySQL (EXPLAIN FORMAT=JSON), Oracle
(DBMS_XPLAN) when specified.

---

## Trigger

Invoke when:
- The operator says "execution plan", "query plan", "explain", "why is this slow"
- A drill needs performance validation (post-functional-pass)
- The operator shares SHOWPLAN output or asks for index recommendations
- After schema changes that may affect query performance
- When `dba-schema-drill` reaches the execution plan section

---

## Prerequisites

| Input | Required | Why |
|---|---|---|
| The query (or queries) to analyze | Yes | Can't analyze without the SQL |
| The schema (tables, indexes, constraints) | Yes | Needed to interpret operator choices |
| Row estimates or actual row counts | Recommended | Distinguishes small-table noise from real problems |
| Access patterns (which queries run most often) | Recommended | Prioritizes which plans matter most |

---

## Steps

### 1. Identify the access patterns to test

Before generating plans, define which queries represent real-world usage:

| Pattern type | Example | Why it matters |
|---|---|---|
| **List view** | SELECT with GROUP BY + COUNT for list pages | Runs on every page load — must be fast |
| **Detail view** | Multi-table JOIN for a single entity | Runs on every click — JOIN chain matters |
| **Filter** | WHERE on non-PK columns (status, type, date range) | May expose missing indexes |
| **Aggregation** | SUM/COUNT across large tables | May expose full scans |
| **Reverse lookup** | Find parent from child FK | Common in detail pages |
| **Write path** | INSERT/UPDATE with FK validation | FK checks can trigger unexpected scans |

For each pattern, write one representative query using realistic WHERE values (not
`WHERE 1=1` — use actual filter values so the optimizer can estimate selectivity).

### 2. Generate execution plans

**SQL Server:**
```sql
-- Estimated plan (does NOT execute the query):
SET SHOWPLAN_ALL ON;
GO
<query>
GO
SET SHOWPLAN_ALL OFF;
GO

-- Actual plan (executes the query + shows real vs estimated rows):
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
<query>
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
```

**PostgreSQL:**
```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) <query>;
```

**MySQL:**
```sql
EXPLAIN FORMAT=JSON <query>;
```

**Important:** SHOWPLAN_ALL/OFF must each be the only statement in their batch (GO
separator required in SQL Server). Queries between them are analyzed but not executed.

### 3. Read the plan — what to look for

Analyze each plan for these signals, in priority order:

#### Critical (fix immediately)

| Signal | What it means | Fix |
|---|---|---|
| **Table Scan** on a fact/data table | No usable index for the query's WHERE/JOIN | Add an index on the filtered/joined column |
| **Clustered Index Scan** on a large table | PK scan = full table read | Add a nonclustered index on the predicate columns |
| **Key Lookup** with high EstimateExecutions | Index found the rows but needs to fetch extra columns from the clustered index | Add INCLUDE columns to the nonclustered index to make it covering |
| **Implicit Conversion** (CONVERT_IMPLICIT) | Column type doesn't match the parameter/literal type — prevents index seek | Fix the type mismatch (parameter or column) |
| **Sort** operator with high EstimateRows | No index supports the ORDER BY — engine must sort in memory/tempdb | Add an index that matches the ORDER BY |

#### Warning (investigate)

| Signal | What it means | Fix |
|---|---|---|
| **Hash Match** on small result sets | Optimizer chose hash join over nested loop — may indicate missing index on join column | Check if the inner table has an index on the join column |
| **Spool** (Table Spool / Index Spool) | Optimizer caches intermediate results — may indicate repeated subquery evaluation | Rewrite the subquery as a JOIN or CTE |
| **Parallelism** (Distribute Streams / Gather Streams) | Query exceeds cost threshold for parallelism | Not always bad — but if it's a simple lookup, the cost estimate may be inflated |
| **Estimated vs Actual row mismatch** (actual plans only) | Cardinality estimation error — optimizer chose wrong plan shape | UPDATE STATISTICS or add a filtered index to improve estimates |
| **Nested Loops with no inner index** | O(n×m) complexity on the inner side | Add an index on the inner table's join column |

#### Informational (note but don't block)

| Signal | What it means |
|---|---|
| **Index Seek** | Optimal — using an index to go directly to the right rows |
| **Clustered Index Seek** | Optimal — direct PK/clustered key access |
| **Stream Aggregate** | Efficient aggregation — data arrives pre-sorted |
| **Nested Loops** with Index Seek on inner | Optimal for small outer sets |

### 4. Check index utilization

If a live database is available, query the DMVs:

```sql
-- Missing indexes the optimizer wants:
SELECT  mig.index_group_handle, mid.statement,
        mid.equality_columns, mid.inequality_columns, mid.included_columns,
        migs.avg_user_impact, migs.user_seeks, migs.user_scans
FROM    sys.dm_db_missing_index_details mid
JOIN    sys.dm_db_missing_index_groups mig ON mid.index_handle = mig.index_handle
JOIN    sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
WHERE   mid.database_id = DB_ID()
ORDER BY migs.avg_user_impact DESC;

-- Are existing indexes being used?
SELECT  OBJECT_NAME(ius.object_id) AS TableName,
        i.name AS IndexName, i.type_desc,
        ius.user_seeks, ius.user_scans, ius.user_lookups, ius.user_updates
FROM    sys.dm_db_index_usage_stats ius
JOIN    sys.indexes i ON ius.object_id = i.object_id AND ius.index_id = i.index_id
WHERE   ius.database_id = DB_ID()
ORDER BY ius.user_seeks + ius.user_scans DESC;
```

**PostgreSQL equivalent:**
```sql
SELECT * FROM pg_stat_user_indexes ORDER BY idx_scan DESC;
SELECT * FROM pg_stat_user_tables ORDER BY seq_scan DESC;
```

### 5. Produce recommendations

For each finding, produce a concrete recommendation:

```
EP-FINDING-NNN: [Signal] on [Table]
  Query: EP-N ([pattern name])
  Operator: [PhysicalOp] at NodeId [N]
  EstimateRows: [N] | EstimateIO: [N] | TotalSubtreeCost: [N]
  Impact: [what the user experiences — slow page load, timeout, etc.]
  Fix: CREATE [NONCLUSTERED] INDEX [IX_name] ON [table] ([columns]) [INCLUDE (...)]
       [or: rewrite query / fix type mismatch / update statistics]
  Priority: Critical / Warning / Informational
```

### 6. Integration with dba-schema-drill

When invoked as part of a drill, the execution plan section should:

1. Come AFTER all functional checks pass (don't analyze plans for broken queries)
2. Define 5–7 representative access pattern queries (EP-1 through EP-N)
3. Use `SET SHOWPLAN_ALL ON` in a separate batch (GO-delimited)
4. Use realistic WHERE values from the drill's test data
5. End with `SET SHOWPLAN_ALL OFF` and a printed summary of key signals

Template for drill integration:
```sql
/* ══ ESTIMATED EXECUTION PLANS ══════════════════════════════════════════ */
PRINT 'Queries below do NOT execute — SHOWPLAN_ALL shows the optimizer plan.';
GO
SET SHOWPLAN_ALL ON;
GO
/* ── EP-1: [PATTERN NAME] ── */
/* App: [when this query runs in the application] */
<query>;
GO
/* ── EP-2: ... ── */
...
GO
SET SHOWPLAN_ALL OFF;
GO
PRINT 'Review plans above. Key signals: Scan vs Seek, Sort, Key Lookup, Hash Match.';
GO
```

---

## Output format

```
EXECUTION PLAN ANALYSIS: [Context]
Client: [name] | Project: [name] | Engine: [engine + version] | Date: [YYYY-MM-DD]
---
Queries analyzed: [N]
Findings: [N] (Critical: N, Warning: N, Informational: N)

PLAN SUMMARY:
| EP# | Pattern | Key Operator | Table | Signal | Verdict |
|-----|---------|-------------|-------|--------|---------|
| 1   | List view | Index Seek on IX_... | tTable | Seek | Good |
| 2   | Filter   | Index Scan on UQ_... | tTable | Scan (LIKE '%x%') | Expected |
| 3   | Detail   | Clustered Index Scan | tBigTable | Full scan | Critical |

FINDINGS:
[EP-F001] [Critical] Table Scan on tBigTable
  ...

INDEX RECOMMENDATIONS:
| # | Index | Table | Columns | INCLUDE | Rationale | Priority |
|---|-------|-------|---------|---------|-----------|----------|
| 1 | IX_tBigTable_Status | tBigTable | (Status, CreatedDate) | (Name, Total) | EP-3 full scan → seek | Critical |

EXISTING INDEXES — UTILIZATION:
| Index | Seeks | Scans | Lookups | Unused? |
|-------|-------|-------|---------|---------|
| ... | ... | ... | ... | ... |
```

---

## Rules

1. **Concrete indexes, not vague advice.** Every finding that recommends an index must
   include the full CREATE INDEX statement — table, columns, INCLUDE, WHERE filter.
2. **Cost is relative.** TotalSubtreeCost is unitless — compare across queries, don't
   treat absolute values as good/bad.
3. **Small tables get a pass.** A Table Scan on a 10-row lookup table is fine. Only flag
   scans on tables expected to grow beyond ~1,000 rows.
4. **Filtered indexes for soft-delete.** If a table has IsDeleted and most queries filter
   `WHERE IsDeleted = 0`, recommend a filtered index.
5. **Don't over-index.** Every index costs write performance. Recommend only indexes that
   serve actual access patterns identified in step 1.
6. **Engine-specific.** SQL Server's Hash Match ≠ PostgreSQL's Hash Join. Note the engine
   and use engine-correct terminology.

---

## Quality checklist

- [ ] At least 5 representative access patterns identified and tested
- [ ] Every plan checked for: Table Scan, Key Lookup, Sort, Implicit Conversion, Hash Match
- [ ] Critical findings have concrete CREATE INDEX statements
- [ ] Small-table scans explicitly noted as acceptable (not false alarms)
- [ ] Filtered index recommended where soft-delete pattern exists
- [ ] DMV check included (if live DB available)
- [ ] Engine and version stated
- [ ] Integration section present if invoked as part of a drill

## Failure exit

"Cannot analyze execution plans without queries and schema. Provide the SQL
statements and the table/index definitions (or a live DB connection)."
