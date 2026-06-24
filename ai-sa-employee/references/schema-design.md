# Playbook: Schema Design & 3NF Restructuring

Use for new tables, new-feature schemas, normalizing or restructuring existing tables,
ERD review, constraints, and naming. Default engine: SQL Server.

## Table of contents
1. New-feature schema design
2. Restructuring an existing table toward 3NF
3. Keeping existing SPs/views/functions conflict-free during a restructure
4. Normalization reference (1NF → 3NF, and when to stop)
5. Constraints, keys, and data types
6. Naming conventions
7. Compliance & audit columns
8. Worked examples

---

## 1. New-feature schema design

When the operator hands you a new feature ("we're adding project milestones"):

1. **Extract the entities and relationships** from the requirement. Name the nouns
   (Project, Milestone, Assignee) and the verbs that connect them (a Project *has many*
   Milestones). Sketch the ERD in text before any DDL.
2. **Identify the natural key vs. surrogate key.** Prefer a surrogate PK
   (`INT IDENTITY` or `BIGINT`, or a sequential GUID via `NEWSEQUENTIALID()` if a GUID
   is required) plus a UNIQUE constraint on the natural key. Random `NEWID()` GUIDs as
   clustered PKs cause page splits and index fragmentation — flag this if you see it.
3. **Design to 3NF first** (section 3). Denormalize only with a documented reason.
4. **Add the constraints up front** (section 4) — they're far cheaper to add at
   creation than to backfill onto live data later (which is itself a migration risk).
5. **Plan the indexes** with the read patterns in mind, not just the writes. Every FK
   column is an index candidate; so is every column that will appear in a `WHERE`,
   `JOIN`, or `ORDER BY` on a hot path. See `query-optimization.md` for index strategy.
6. **Add audit/compliance columns** (section 6) if the table holds anything regulated
   or anything you'll need to trace (most transactional tables).

**SA-lens question to always ask:** does this schema actually satisfy the stated NFRs
(retention, auditability, concurrency, reporting)? A schema that's clean but can't
answer the reporting questions the business needs is a gap — log it as a RISK-.

---

## 2. Restructuring an existing table toward 3NF

This is the high-risk, high-value case: a denormalized or "grew organically" table that
needs to be split. Treat it as **schema design + a migration** — read
`migration-safety.md` alongside this.

Process:

1. **Profile the current table.** Row count, the columns, and crucially the
   *functional dependencies* — which non-key columns depend on the whole key vs. only
   part of it vs. on another non-key column. The transitive dependencies are what
   violate 3NF.
2. **Find the repeating groups and update anomalies.** Symptoms: the same descriptive
   text repeated across many rows (e.g. a `client_name` stored on every order),
   multi-value columns (`tags` as a comma-joined string), or columns that are NULL for
   whole categories of rows. Each is a normalization target.
3. **Propose the target tables** with the FKs that re-link them, and a *backfill plan*:
   how existing rows map into the new structure, and how you'll verify row counts and
   totals match before and after.
4. **Sequence the cutover** to avoid a big-bang lock. The expand/contract pattern is
   safest:
   - **Expand:** create the new tables and constraints; backfill; add a trigger or
     dual-write so both old and new stay in sync.
   - **Migrate reads:** point queries/SPs/views at the new structure.
   - **Contract:** drop the old columns/table once nothing reads them.
   This lets each step be reversible. A single `ALTER` that drops columns is not.
5. **Validation queries** are part of the deliverable, not an afterthought. Provide the
   row-count and checksum/total comparisons the operator runs to prove no data was lost.

**Always flag:** the locking and data-loss risk of the contract step as a RISK-DB entry,
with the row count and estimated lock duration. See the worked example in
`migration-safety.md`.

---

## 3. Keeping existing SPs/views/functions conflict-free during a restructure

When you split or drop columns, **every stored procedure, view, and function that reads
those columns will break the moment they vanish.** The restructure isn't "done" until
those readers are migrated. This section is the safety net — always produce it as part
of a restructure deliverable.

1. **Discover every reader first — never guess.** Before touching anything, enumerate
   what depends on the columns you're about to change:
   ```sql
   -- every module (SP/view/function/trigger) referencing the table or its old columns
   SELECT OBJECT_SCHEMA_NAME(object_id) AS schema_name,
          OBJECT_NAME(object_id)        AS object_name,
          o.type_desc
   FROM sys.sql_modules m
   JOIN sys.objects o ON o.object_id = m.object_id
   WHERE m.definition LIKE '%orders%'                 -- the table
     AND ( m.definition LIKE '%tags%'                 -- the columns being retired
        OR m.definition LIKE '%customer_name%'
        OR m.definition LIKE '%customer_city%' );
   -- also: sys.dm_sql_referencing_entities('dbo.orders','OBJECT') for hard dependencies
   ```
   This list **is** your migration work-list. The restructure is finished only when this
   query returns no rows that still read the retired columns.

2. **Ship a compatibility view that reconstructs the old shape.** This is the key move
   that lets legacy readers keep working while the physical schema changes underneath
   them. Expose a view with the *old* column names, rebuilt from the new normalized
   tables:
   ```sql
   CREATE VIEW dbo.vw_orders_compat AS
   SELECT o.id, o.customer_id,
          c.name  AS customer_name,         -- was orders.customer_name
          c.city  AS customer_city,         -- was orders.customer_city
          ( SELECT STRING_AGG(t.name, ',')  -- was orders.tags
            FROM order_tag ot JOIN tag t ON t.id = ot.tag_id
            WHERE ot.order_id = o.id )       AS tags
   FROM orders o
   JOIN customer c ON c.id = o.customer_id;
   ```
   Now repoint readers at `vw_orders_compat` (or directly at the new tables where you can
   improve them) **one at a time**, testing each against the work-list — nothing breaks
   because the old physical columns still exist during the whole window.

3. **Re-index for the new readers.** As SPs/views move onto the new tables, their access
   paths change — the FK columns and junction tables now need indexes that the old flat
   table didn't. Index `orders.customer_id`, the junction PK `(order_id, tag_id)`, and
   the reverse `(tag_id, order_id)` for "orders with tag X" lookups. Validate the
   migrated readers' execution plans (see `query-optimization.md`) before contract.

4. **Only contract once the work-list is empty.** Re-run the step-1 query; when nothing
   reads the retired columns, the `DROP COLUMN` is safe. Until then it is a RED RISK-
   (data loss + lock — see `migration-safety.md`).

**Deliverable reminder:** a restructure analysis that doesn't include the reader
work-list query and a compatibility plan is incomplete — flag the missing piece rather
than implying the restructure is conflict-free.

---

## 4. Normalization reference (1NF → 3NF)

- **1NF** — atomic values, no repeating groups. The comma-joined `tags` column fails
  1NF; split it into a child table.
- **2NF** — 1NF *and* every non-key column depends on the **whole** composite key, not
  part of it. Only relevant when the PK is composite. If `order_line(order_id,
  product_id)` stores `product_name`, that depends only on `product_id` → 2NF violation,
  move `product_name` to a `product` table.
- **3NF** — 2NF *and* no **transitive** dependency: non-key columns must not depend on
  other non-key columns. If `order` stores `customer_id` *and* `customer_city`, the city
  depends on the customer, not the order → move it to `customer`.
- **BCNF** — a stricter 3NF for edge cases with overlapping candidate keys. Mention it
  only when it actually applies; don't over-engineer.

**When to stop / denormalize on purpose.** 3NF is the target, but read-heavy reporting
paths sometimes justify denormalization: a materialized/indexed view, a precomputed
rollup column, or a reporting table fed by a job. That's fine — but it must be a
*documented decision* (an ADR / REC- entry) stating the read pattern it serves, the
write cost it adds, and how the redundant data stays consistent. Undocumented
denormalization is a 3NF violation; documented denormalization is an architecture choice.

---

## 5. Constraints, keys, and data types

- **PK** on every table. Surrogate `INT/BIGINT IDENTITY` clustered by default in SQL
  Server; ensure the clustering key is narrow, static, and ever-increasing.
- **FK** on every relationship, with an explicit `ON DELETE` rule chosen deliberately
  (`NO ACTION`/`CASCADE`/`SET NULL`) — and remember to index the FK column (SQL Server
  does **not** auto-index FKs, a very common cause of slow deletes and joins).
- **NOT NULL** wherever a value is logically required — pushed into the schema, not
  enforced only in app code.
- **UNIQUE** on natural keys and any "should never repeat" combination.
- **CHECK** for domain rules (status in a known set, amount ≥ 0). Cheaper and more
  reliable than app-side validation.
- **Data types:** right-size them. `DATETIME2` over `DATETIME`; `DECIMAL(p,s)` for money
  (never `FLOAT`); `NVARCHAR(n)` with a real bound, not `NVARCHAR(MAX)` for short text;
  match FK types exactly to their referenced PK to avoid implicit conversions that kill
  index usage (see SARGability in `query-optimization.md`).

---

## 6. Naming conventions

Consistency beats any single convention. Default house style:

- Tables: singular or plural — pick one and hold it. `snake_case` or `PascalCase` per
  the existing codebase; match what's already there rather than introducing a second
  style.
- Columns: `snake_case`, no reserved words (`order`, `user`, `key`, `status` unquoted
  can bite). PK as `id`, FKs as `<referenced_table>_id`.
- Avoid prefixes like `tbl_` / `sp_`. In SQL Server, **never** prefix a stored procedure
  with `sp_` — that name triggers a master-database lookup first and is a real
  perf/ambiguity trap.

Flag naming inconsistency as a low-priority REC-, not a RISK- — it's maintainability,
not data integrity.

---

## 7. Compliance & audit columns

For any table holding regulated or traceable data, check for:

- **Audit columns:** `created_at`, `created_by`, `updated_at`, `updated_by`, and a
  soft-delete (`is_deleted` / `deleted_at`) where hard deletes would lose audit trail.
- **PII flags:** identify columns holding personal data (names, emails, gov IDs). These
  drive encryption-at-rest and data-residency requirements — cross-check
  `references/operations.md` and log a RISK- if encryption/audit is absent where the
  NFRs require it.
- **Temporal needs:** if the business needs "what did this row look like on date X",
  recommend SQL Server **system-versioned temporal tables** rather than a hand-rolled
  history table.

---

## 8. Worked examples

**Example A — 3NF violation in a new design:**
```
RISK-DB02 — order table stores customer_city (transitive dependency) — P3×I3=9 🟡 — Mitigate
customer_city depends on customer_id, not on the order → 3NF violation; updating a
customer's city requires touching every order row (update anomaly).
Recommendation (REC-DB02): move customer_city to the customer table; join when needed.
Business impact: removes a class of data-inconsistency bugs in customer reporting.
```

**Example B — restructuring deliverable shape:**
```
Findings:
- orders.tags is a comma-joined string → fails 1NF. Target: order_tag(order_id, tag_id) + tag(id, name).
- Backfill: SPLIT_STRING over existing rows; validation = SUM of tag counts old vs new must match.
- Cutover: expand (create + dual-write) → migrate reads in vw_order_tags and usp_order_search → contract.
- Contract step locks orders ~Ns at 1.4M rows → see RISK-DB03, schedule in maintenance window.
```