# Playbook: Views, Stored Procedures & Functions

Use when writing or reviewing views (including indexed/materialized), stored procedures,
table-valued functions (inline and multi-statement), scalar functions, and CTEs.
Default engine: SQL Server — the perf traps below are SQL Server-specific where noted.

## Table of contents
1. Choosing the right object
2. Views (incl. indexed views)
3. Stored procedures
4. Functions — the perf hierarchy (this is where most damage happens)
5. CTEs and window functions
6. Review checklist
7. Worked examples

---

## 1. Choosing the right object

| Need | Reach for | Avoid |
|---|---|---|
| Reusable read shape, no params | **View** | A scalar UDF returning one column |
| Reusable read shape that takes a param | **Inline TVF** | A multi-statement TVF or a view + outer filter |
| Encapsulated write/business logic, multiple statements | **Stored procedure** | Doing it in a function |
| A computed value reused in many queries | **Inline TVF** (`CROSS APPLY`) or a persisted computed column | **Scalar UDF** |
| Precomputed expensive aggregate | **Indexed view** or a rollup table | Re-aggregating on every read |

The single most important rule on SQL Server: **prefer inline table-valued functions
over scalar UDFs and multi-statement TVFs.** Sections 4 explains why — it's the most
common source of mystery slowdowns in the operator's stack.

---

## 2. Views

- A view is a saved query, not a stored result — it has no performance magic by itself;
  it inlines into the calling query's plan. Use views to standardize a join/projection,
  enforce column-level security, or hide normalization detail from the app.
- **Watch nesting:** views that select from views that select from views produce
  bloated plans and make the optimizer's job harder. Flag views nested >2 deep.
- **`SELECT *` in a view** is a maintenance and binding hazard (schema drift,
  `SCHEMABINDING` breakage) — recommend explicit column lists.
- **Indexed (materialized) views**: when a costly aggregate/join is read far more than
  written, a view `WITH SCHEMABINDING` + a unique clustered index physically stores the
  result and auto-maintains it. Trade-off: it adds write cost and has strict
  requirements (no outer joins, no non-deterministic functions). Recommend it as a REC-
  with the read/write ratio that justifies it.

---

## 3. Stored procedures

- Use SPs for write paths and multi-step logic. Keep one responsibility per SP where
  practical.
- **`SET NOCOUNT ON`** at the top — avoids extra round-trip messages, a small but free win.
- **Parameter sniffing:** SQL Server caches a plan based on the first parameter values,
  which can be terrible for later calls with different cardinality. If the operator
  reports "the SP is fast sometimes and slow other times," this is the prime suspect —
  remedies include `OPTIMIZE FOR`, `OPTION (RECOMPILE)` on the offending statement, or
  splitting into separate code paths. Flag it; don't sprinkle `RECOMPILE` blindly (it
  trades plan-reuse for compile cost).
- **Never prefix with `sp_`** (master-DB lookup, see schema-design.md naming).
- **Error handling:** wrap multi-statement writes in `BEGIN TRY / BEGIN CATCH` with an
  explicit transaction and `THROW` so failures roll back cleanly. A write SP without
  transaction handling that does several DML statements is a data-integrity RISK-.
- **Avoid `RBAR`** (row-by-agonizing-row) cursors/`WHILE` loops where a set-based
  statement would do — this is the #1 SP performance smell.

---

## 4. Functions — the perf hierarchy

This is the section that most often turns a green analysis red. Order of preference,
best to worst, on SQL Server:

1. **Inline TVF (iTVF)** — a single `RETURN (SELECT ...)`. The optimizer inlines it into
   the calling query, so it can use indexes and parallelism. **This is the good one.**
   Use `CROSS APPLY`/`OUTER APPLY` to call it per row efficiently.
2. **Multi-statement TVF (mTVF)** — declares a `@table` variable, fills it, returns it.
   The optimizer historically estimates **1 row** (or 100 in newer versions), wrecking
   join order on anything larger. Rewrite as an iTVF wherever possible.
3. **Scalar UDF** — called once *per row*, often defeating set-based execution and
   forcing serial plans. On pre-2019 SQL Server especially, a scalar UDF in a `SELECT`
   or `WHERE` over a big table can turn milliseconds into minutes. SQL Server 2019+ can
   *inline* some scalar UDFs automatically, but many patterns block inlining — don't
   rely on it. Prefer: an iTVF via `CROSS APPLY`, a computed column, or just inline
   expression.

**Reviewer reflex:** any scalar UDF or multi-statement TVF on a hot path is a RISK-DB
(type: Perf) with a concrete rewrite recommendation. Quantify it where you can
("scalar UDF on 2M-row SELECT → serial plan, ~40s; iTVF rewrite → parallel, target <2s").

---

## 5. CTEs and window functions

- A CTE is **syntactic** — it does not materialize or cache by default; referencing a
  CTE twice can execute it twice. If a CTE is reused multiple times over expensive work,
  consider a `#temp` table instead and say why.
- **Recursive CTEs** are right for hierarchies (org charts, BOM, project trees) but cap
  them with `OPTION (MAXRECURSION n)` and watch the plan — deep recursion over wide rows
  gets expensive.
- **Window functions** (`ROW_NUMBER`, `SUM() OVER`, `LAG/LEAD`) usually beat
  self-joins and correlated subqueries for running totals, dedup, and "latest row per
  group." Recommend them in place of those patterns. Make sure the `PARTITION BY` /
  `ORDER BY` columns are supported by an index so the sort can be avoided.

---

## 6. Review checklist

- [ ] Right object for the job (view vs iTVF vs SP vs function)?
- [ ] No scalar UDF or multi-statement TVF on a hot path (or a rewrite is recommended)?
- [ ] Views: explicit columns, nesting ≤2, indexed view considered for hot aggregates?
- [ ] SPs: `SET NOCOUNT ON`, transaction + TRY/CATCH on writes, no `sp_` prefix, no RBAR?
- [ ] Parameter-sniffing risk assessed on SPs with variable cardinality?
- [ ] CTE not silently re-executed; recursion capped; window functions used over self-joins?
- [ ] Every recommendation has a before→after target where measurable?

---

## 7. Worked examples

**Scalar UDF rewrite:**
```
RISK-DB04 — fn_GetClientName scalar UDF called per row in usp_ProjectReport — P4×I4=16 🔴 — Mitigate
Called once per result row over ~900k projects → serial plan, ~35s report.
Trigger: any run of the projects report. Mitigation: rewrite as inline TVF and CROSS APPLY,
or join the client table directly. Target: <2s, parallel plan.
Contingency: if rewrite slips, cache the report in a nightly rollup table.
```

**View nesting:**
```
REC-DB05 — flatten vw_ProjectFull (nested 4 views deep) — Med
Nested views inflate the plan and hide a duplicate join to dbo.Program.
Recommend a single SCHEMABINDING view with explicit columns; consider indexing it
(read:write ≈ 50:1 on this object). Business impact: dashboard load time, fewer timeouts.
```