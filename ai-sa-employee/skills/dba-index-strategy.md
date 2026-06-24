---
name: dba-index-strategy
description: >-
  Designs and audits index strategies for database tables — covering indexes,
  filtered indexes, included columns, composite key ordering, index intersection,
  and unused index detection. Balances read performance against write overhead.
  Use this skill when the operator mentions index, covering index, filtered index,
  missing index, index bloat, write penalty, or when execution plan analysis
  surfaces index gaps.
---

# dba-index-strategy

Designs indexes that serve actual access patterns — not theoretical ones. Every
recommended index must trace back to a real query or access pattern. The skill
balances read speed against write cost, and flags over-indexing as aggressively
as under-indexing.

Engine-aware: defaults to SQL Server (nonclustered, filtered, included columns,
columnstore). Notes PostgreSQL (partial indexes, GIN/GiST), MySQL (prefix indexes,
invisible indexes) differences where relevant.

---

## Trigger

Invoke when:
- Execution plan analysis reveals missing indexes
- The operator says "index strategy", "which indexes do we need", "index audit"
- A new schema is being designed (proactive index planning)
- Write performance is degrading (possible over-indexing)
- DMVs show high-impact missing indexes or unused indexes

---

## Steps

### 1. Inventory existing indexes

Gather the current index state:

```sql
-- SQL Server: all indexes on user tables
SELECT  OBJECT_NAME(i.object_id) AS TableName,
        i.name AS IndexName, i.type_desc,
        i.is_unique, i.is_primary_key, i.has_filter, i.filter_definition,
        STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS KeyColumns,
        STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN c.name END, ', ')
            WITHIN GROUP (ORDER BY ic.key_ordinal) AS IncludedColumns
FROM    sys.indexes i
JOIN    sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN    sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE   i.object_id > 100 AND i.type > 0
GROUP BY i.object_id, i.name, i.type_desc, i.is_unique, i.is_primary_key,
         i.has_filter, i.filter_definition
ORDER BY OBJECT_NAME(i.object_id), i.name;
```

```sql
-- PostgreSQL equivalent:
SELECT tablename, indexname, indexdef FROM pg_indexes
WHERE schemaname = 'public' ORDER BY tablename, indexname;
```

### 2. Map access patterns to index needs

For each table, identify the access patterns (from process interview, drill, or
application code) and determine what indexes each pattern needs:

| Table | Access Pattern | WHERE / JOIN columns | ORDER BY | SELECT columns | Index needed |
|---|---|---|---|---|---|
| tProjects | List by program | ProgramId | ProjectId | Id, ProjectId, IsPublished | IX on (ProgramId) INCLUDE (ProjectId, IsPublished) |
| tProjects | Filter by group | ProjectGroupFK | ProjectId | Id, ProjectId | IX on (ProjectGroupFK) WHERE ProjectGroupFK IS NOT NULL |

### 3. Apply index design principles

#### Column ordering in composite indexes

The leftmost column must be the one with the highest selectivity in equality
predicates. The general rule:

```
(equality columns by selectivity DESC, inequality/range column, ORDER BY columns)
INCLUDE (non-predicate SELECT columns)
```

Example: `WHERE Status = 'Active' AND CreatedDate > '2026-01-01' ORDER BY Name`
→ `IX_... ON (Status, CreatedDate) INCLUDE (Name)` — not `(CreatedDate, Status)`.

#### Filtered indexes

Use when a significant portion of queries filter on the same predicate:

```sql
-- Only 5% of rows are active — filtered index is small + fast:
CREATE NONCLUSTERED INDEX IX_tProjects_Active
ON dbo.tProjects (ProgramId, ProjectId)
WHERE IsDeleted = 0;
```

**When to use:** soft-delete patterns (IsDeleted = 0), status filters (Status = 'Active'),
nullable FK columns (WHERE FK IS NOT NULL).

**Caveat:** parameterized queries must include the filter predicate literally for SQL
Server to use the filtered index. EF Core and Dapper may need `OPTION (RECOMPILE)` or
literal predicates.

#### Covering indexes

An index "covers" a query if it contains all columns the query needs — eliminating
Key Lookups:

```sql
-- Query: SELECT Name, Email FROM tUsers WHERE DepartmentId = 5
-- Covering index:
CREATE NONCLUSTERED INDEX IX_tUsers_Dept_Cover
ON dbo.tUsers (DepartmentId)
INCLUDE (Name, Email);
```

**Rule of thumb:** if execution plans show Key Lookups with high EstimateExecutions,
add the looked-up columns as INCLUDE columns on the existing index.

#### Index intersection

SQL Server can combine two indexes via hash/merge join. But this is slower than one
composite index — don't rely on intersection for hot-path queries.

### 4. Detect over-indexing

Too many indexes hurt write performance. Check for:

| Problem | Detection | Action |
|---|---|---|
| **Duplicate indexes** | Two indexes with same key columns (one may have extra INCLUDEs) | Drop the narrower one |
| **Unused indexes** | `dm_db_index_usage_stats.user_seeks = 0 AND user_scans = 0` for > 30 days | Consider dropping (verify no seasonal queries) |
| **Wide indexes** | Index with > 5 key columns | Question whether a narrower index + INCLUDE would work |
| **Write-heavy tables with many indexes** | High `user_updates` relative to `user_seeks` | Audit — each index adds overhead to every INSERT/UPDATE/DELETE |

```sql
-- SQL Server: indexes with zero seeks/scans (potential drop candidates)
SELECT  OBJECT_NAME(ius.object_id) AS TableName,
        i.name AS IndexName, i.type_desc,
        ius.user_seeks, ius.user_scans, ius.user_lookups, ius.user_updates
FROM    sys.dm_db_index_usage_stats ius
JOIN    sys.indexes i ON ius.object_id = i.object_id AND ius.index_id = i.index_id
WHERE   ius.database_id = DB_ID()
  AND   ius.user_seeks = 0 AND ius.user_scans = 0
  AND   i.is_primary_key = 0 AND i.is_unique = 0
ORDER BY ius.user_updates DESC;
```

### 5. Produce the index recommendation

For each recommended index:

```
IDX-NNN: [Action: CREATE / DROP / MODIFY]
  Table: [dbo.tTableName]
  Statement: CREATE NONCLUSTERED INDEX [IX_name] ON [dbo.tTable] ([cols]) INCLUDE ([cols]) WHERE [filter];
  Serves: [EP-N pattern name, or query description]
  Read benefit: [Scan → Seek, eliminates Key Lookup, supports ORDER BY]
  Write cost: [low (lookup table, rare writes) / medium / high (transaction table, frequent INSERTs)]
  Priority: Critical / High / Medium / Low
```

---

## Index type reference (SQL Server)

| Type | Use case | Key limit |
|---|---|---|
| **Clustered** | 1 per table — usually the PK. Determines physical row order | 900 bytes, 16 columns |
| **Nonclustered** | Most common. B-tree on selected columns, leaf nodes point to clustered key | 1700 bytes, 16 key + 1023 include columns |
| **Filtered** | Nonclustered with a WHERE clause — smaller, faster for subset queries | Same as nonclustered. Filter must be simple (column comparisons, IS [NOT] NULL, AND/OR) |
| **Unique** | Enforces uniqueness. Can be clustered or nonclustered | Same as above |
| **Columnstore** | Analytics / reporting. Column-oriented storage, batch mode processing | Not for OLTP point queries. SQL Server 2016+ supports nonclustered columnstore on OLTP tables |
| **Full-text** | CONTAINS / FREETEXT searches on text columns | Separate catalog. Not for LIKE '%term%' queries |

**PostgreSQL equivalents:** Partial index = Filtered index. GIN = inverted index (arrays, JSONB, full-text). GiST = spatial/range types. BRIN = block-range (very large sequential tables).

---

## Output format

```
INDEX STRATEGY: [Context]
Client: [name] | Project: [name] | Engine: [engine] | Date: [YYYY-MM-DD]
---
Tables analyzed: [N]
Existing indexes: [N]
Recommendations: [N] (Create: N, Drop: N, Modify: N)

CURRENT INDEX INVENTORY:
| Table | Index | Type | Key Columns | Included | Filtered | Seeks | Scans | Updates |
|-------|-------|------|-------------|----------|----------|-------|-------|---------|

ACCESS PATTERN → INDEX MAP:
| Pattern | Table(s) | Predicate | Order | Needed Index | Exists? |
|---------|----------|-----------|-------|-------------|---------|

RECOMMENDATIONS:
[IDX-001] CREATE — ...
[IDX-002] DROP  — ...

OVER-INDEXING CHECK:
| Table | Index Count | Write Ratio | Duplicates | Unused |
|-------|-------------|-------------|------------|--------|
```

---

## Rules

1. **Every index traces to an access pattern.** No speculative "might be useful" indexes.
2. **Write cost is real.** For every CREATE recommendation, state the write-cost impact.
3. **Filtered indexes for soft-delete.** If IsDeleted exists and queries filter on it,
   a filtered index is almost always the right answer.
4. **Column order matters.** Equality columns first, range columns second, ORDER BY last.
5. **INCLUDE before widening.** Prefer adding INCLUDE columns over adding key columns.
6. **Drop unused indexes.** An index nobody reads but every write maintains is pure cost.

---

## Quality checklist

- [ ] Current index inventory gathered (or stated as unavailable)
- [ ] Access patterns mapped to index needs
- [ ] Every recommendation has a full CREATE/DROP statement
- [ ] Write cost assessed for every new index
- [ ] Filtered indexes considered for soft-delete patterns
- [ ] Over-indexing check performed (duplicates, unused)
- [ ] Column ordering justified (selectivity, equality vs range)
- [ ] Engine-specific behavior noted where relevant

## Failure exit

"Cannot design an index strategy without knowing the tables and access patterns.
Provide the schema (or run dba-schema-ingest) and describe the key queries."
