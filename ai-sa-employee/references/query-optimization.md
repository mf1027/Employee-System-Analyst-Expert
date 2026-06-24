# Playbook: Query Optimization

Use for slow queries, execution-plan review, index strategy, SARGability, N+1, and
EF Core/Dapper data-layer patterns. Default engine: SQL Server.

## Table of contents
1. The diagnosis order
2. Reading an execution plan
3. SARGability — the silent index killer
4. Index strategy
5. EF Core & Dapper patterns
6. Recommendation format
7. Worked example

---

## 1. The diagnosis order

Work outside-in; don't jump straight to "add an index":

1. **Measure first.** Get the actual execution plan and real timings
   (`SET STATISTICS IO, TIME ON`), not estimates. Logical reads matter more than wall
   clock for finding the hotspot.
2. **Find the most expensive operator** in the plan (scans, key lookups, sorts, spills).
3. **Check SARGability** (section 3) — a non-SARGable predicate makes any index useless.
4. **Check the indexes** (section 4) — missing, redundant, or wrong-order.
5. **Check the query shape** — N+1 from the app, `SELECT *`, implicit conversions,
   functions on columns, OR-heavy predicates, parameter sniffing (see `sql-objects.md`).
6. **Only then** recommend changes, each with a measurable target.

---

## 2. Reading an execution plan

Red flags, roughly in order of how often they're the culprit:

- **Table/Clustered Index Scan** where you expected a Seek → missing index or
  non-SARGable predicate.
- **Key Lookup (Bookmark Lookup)** → the nonclustered index found the row but had to go
  back to the clustered index for extra columns. Fix with a covering index (`INCLUDE`).
- **Sort / Hash with spill to tempdb** (warning triangle) → under-estimated memory grant,
  often downstream of a bad cardinality estimate (mTVF, stale stats, parameter sniffing).
- **Nested Loops over a large outer input** → fine for small sets, pathological for big
  ones; check the estimated-vs-actual row counts (a big gap = bad estimate).
- **Implicit Conversion warning** → type mismatch (often `NVARCHAR` vs `VARCHAR` or a
  parameter typed wider than the column) silently disabling a seek.

Always compare **estimated vs actual rows**. A large divergence is the root cause more
often than the operator itself — fix the estimate (stats, query shape) before the symptom.

---

## 3. SARGability — the silent index killer

A predicate is **SARGable** (Search-ARGument-able) if the engine can seek an index for
it. Wrapping the *column* in a function or expression kills the seek:

| Non-SARGable (scan) | SARGable rewrite (seek) |
|---|---|
| `WHERE YEAR(created_at) = 2026` | `WHERE created_at >= '2026-01-01' AND created_at < '2027-01-01'` |
| `WHERE UPPER(status) = 'OPEN'` | store/compare consistent case, or use proper collation |
| `WHERE total * 1.12 > 100` | `WHERE total > 100 / 1.12` |
| `WHERE CAST(project_id AS varchar) = @x` | match the parameter type to the column |
| `WHERE col LIKE '%term%'` | leading wildcard can't seek — consider full-text search |

Implicit conversions count too: a `WHERE varchar_col = @nvarchar_param` forces a scan.
This is why matching FK/parameter types to column types (schema-design.md §5) matters.

---

## 4. Index strategy

- **Cover the query.** A nonclustered index whose key columns match the `WHERE`/`JOIN`
  and whose `INCLUDE` columns supply the `SELECT` lets the engine answer entirely from
  the index — no key lookups.
- **Key column order matters:** equality predicates first, then range, then the columns
  you sort by. An index on `(status, created_at)` serves
  `WHERE status=@s AND created_at>@d ORDER BY created_at` perfectly; reversed, it doesn't.
- **Index every FK** (SQL Server doesn't do it automatically) — speeds joins and
  prevents slow cascading deletes.
- **Don't over-index.** Each index is write overhead and storage. Find and flag
  **redundant/duplicate** indexes and **unused** ones (`sys.dm_db_index_usage_stats`).
- **Keep stats fresh.** Stale statistics → bad estimates → bad plans. Recommend an
  update if a big table's stats are old and estimates are off.

State index recommendations as concrete DDL with the predicted effect, e.g.
"`CREATE INDEX IX_orders_customer_id ON orders(customer_id) INCLUDE (status, total)` →
removes the key lookup, est. 800ms → <20ms".

---

## 5. EF Core & Dapper patterns

Since the operator's data layer is EF Core + Dapper, watch for ORM-shaped problems the
DB can't fix on its own:

- **N+1 queries** — a loop that lazy-loads a related entity per iteration fires one query
  per row. Fix with `.Include()`/`.ThenInclude()` (eager load) or a projection. This is
  an app-side RISK- with a DB symptom (thousands of tiny identical queries in the trace).
- **Client-side evaluation** — an EF query that can't translate a C# expression pulls the
  whole table to memory and filters in app. Flag any `AsEnumerable()`/`ToList()` placed
  *before* the filtering.
- **`SELECT *` via untyped entities / `SELECT N+1` projections** — project to exactly the
  columns needed (`.Select(x => new { ... })`) so a covering index can serve it.
- **Cartesian explosion** from multiple collection `Include`s — recommend split queries
  (`AsSplitQuery()`) when joining several one-to-many relations.
- **Dapper** sidesteps EF's translation but reintroduces the SARGability/index issues
  above directly — review the raw SQL it sends with sections 3–4.

---

## 6. Recommendation format

Every query rec carries a **before → after** target so the operator can verify it landed:

```
REC-DB0X — [the change] — Priority
[What it fixes in the plan]. Target: [metric before] → [metric after].
Business impact: [page/report/job that gets faster; timeout risk removed].
```

---

## 7. Worked example

```
DATABASE ANALYSIS: Slow project-search query
Engine: SQL Server 2019
---
Bottom line (business): The project search behind the planning dashboard takes ~6s and
intermittently times out for users filtering by year. The cause is a date function that
disables the index; a one-line rewrite plus one covering index should bring it under
~200ms with no schema change and no downtime.

Findings:
- WHERE YEAR(created_at) = @yr is non-SARGable → Clustered Index Scan over 1.4M rows.
- SELECT pulls 14 columns; existing IX on created_at doesn't cover them → key lookups.
- Estimated 1 row vs actual 38k (stats last updated 4 months ago).

Recommendations:
| ID | Recommendation | Impact (business) | Priority |
|---|---|---|---|
| REC-DB06 | Rewrite to created_at >= @start AND < @end (SARGable) | enables index seek | High |
| REC-DB07 | CREATE INDEX IX_proj_created INCLUDE (the 12 select cols); UPDATE STATISTICS | removes scan + lookups; 6s → ~200ms | High |
```