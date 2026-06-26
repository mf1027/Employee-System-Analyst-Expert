---
name: dba-schema-drill
description: >-
  Validates a schema by running a simulated lifecycle end-to-end — generates sample
  SQL (INSERT/UPDATE/DELETE) for every operation, shows the row state after each
  step, and systematically identifies failure modes ("what could go wrong"). The
  drill is the final gate before a schema is locked. Produces a runnable SQL script
  that can be executed against a real database to prove the schema works.
---

# dba-schema-drill

The schema's acceptance test. Walks through the full entity lifecycle with actual
SQL operations, validates row counts, checks history preservation, and probes
failure modes. If the drill passes, the schema can be locked.

---

## Trigger

Invoke when:
- A schema is ready to be locked (after review + data-flow-trace)
- The operator says "run a drill", "test the schema", "validate this"
- Before generating migration scripts for a recommended schema
- After any schema revision (to re-validate)

---

## Prerequisites

| Skill | Must be done first | Why |
|---|---|---|
| dba-process-interview | Yes | Defines the lifecycle steps to simulate |
| dba-schema-ingest | Yes | Provides the table structure |
| dba-data-flow-trace | Yes | Defines expected operations per step |

---

## Steps

### 1. Generate the lifecycle script (full-content fixtures — SKL-007)

For every step from the data-flow-trace, write actual T-SQL:
- Declare realistic test data (business keys, GUIDs, lookup codes)
- INSERT/UPDATE/DELETE with real column lists and values
- Capture SCOPE_IDENTITY() where needed
- Wrap multi-table operations in transactions

**Full-content fixture rule:** the seed must populate the **complete entity graph** that the
real process produces — not just the parent rows. If the process guarantees that every
`tRevisionDetails` has a `tRevisionProjectSnapshot` + funding + cost rows, the drill must
seed those too. A parent row without its process-guaranteed children is a **hollow fixture**
that makes the drill pass on data the process could never produce.

Ask (or verify from the as-built semantics ingest — step 5 of `dba-schema-ingest`):
*"What entity graph does each process step produce?"* Seed exactly that.

### 2. Show row state after each step

After each step, include SELECT statements that show the current state of all
affected tables. Use a consistent format:

```sql
SELECT 'STEP N' AS Step, 'tTableName' AS Tbl, [key columns], [state columns]
FROM dbo.tTableName WHERE [filter];
```

### 3. Validate against expected behavior

At each step, PRINT the expected state and compare:
- Row counts per table (expected vs actual)
- Key values (are GUIDs consistent? are FKs pointing to the right rows?)
- History preservation (are old snapshot rows untouched after advance?)

### 4. Probe failure modes

For each multi-table step, document:

```
FAILURE MODE: [description]
TRIGGER: [what causes it — timeout, deadlock, disk full, concurrent user]
AFFECTED STEP: [which step]
TABLES IN INCONSISTENT STATE: [which tables have partial data]
USER IMPACT: [what the user sees — wrong counts, missing rows, stale data]
MITIGATION: [transaction wrapper, retry logic, orphan detection query]
```

Standard failure categories to check:
- **Partial write** — multi-table operation succeeds on some tables, fails on others
- **Stale read** — concurrent user reads mid-operation, gets inconsistent state
- **Orphan creation** — child row created with non-existent parent key
- **Dual-update drift** — same value stored in two places, one update missed
- **Counter drift** — count column not updated atomically with the counted event
- **GUID mismatch** — stage GUID updated on parent but not propagated to all children
- **Delete without cascade** — parent deleted, children left behind (no FK enforcement)

### 5. Include cleanup + rollback scripts

At the end of the drill script, provide:
- A **cleanup block** (commented-out DELETE, children-first) so the drill can be re-run.
- A **paired rollback script** (or rollback section) for every structural change in the
  schema DDL — if the deploy fails at step 3 of 5, there is a scripted path back.

Every migration `.sql` ships with a `rollback-*.sql`. Forward-only schemas are a deployment
risk: if something breaks mid-migration, the DBA should not need to invent the rollback
under pressure.

### 6. Auto-seed lookup dependencies

Every drill must be self-contained — it must seed its own lookup data so it can run
against a freshly built schema. Use idempotent `IF NOT EXISTS` blocks:

```sql
/* ── Seed lookups (idempotent) ── */
IF NOT EXISTS (SELECT 1 FROM dbo.tOptionProgramStage WHERE Name=N'BP')
    INSERT dbo.tOptionProgramStage (NameId,Name,Description)
    VALUES (1,N'BP',N'Budget Proposal');
```

**Rules for auto-seeding:**
1. **Every lookup FK used by the drill must have a seed.** If the drill INSERTs a row
   with `Category = 1`, there must be a seed for the category lookup with value 1.
2. **Use `IF NOT EXISTS` — not blind INSERT.** The drill must be re-runnable.
3. **Seed at the top of the drill** — before any business-data INSERTs.
4. **Copy seeds between drills** when they share lookup dependencies. If drill-A seeds
   tOptionFundingSource and drill-B also needs it, both files carry the same seed block.
5. **Never depend on seeds from another drill.** Each drill runs independently.

### 7. Referential-completeness assertions (SKL-007 — anti-hollow-fixture gate)

After seeding and before any state-change tests, assert that the fixture is **complete** —
every parent has its process-guaranteed children. These are not FK checks (the DB does that);
they check the **cardinality the process enforces** that the schema can't express.

```sql
/* COMPLETENESS: every tRevisionDetails (submitted) must have exactly 1 snapshot */
IF EXISTS (
    SELECT rd.Id FROM dbo.tRevisionDetails rd
    LEFT JOIN dbo.tRevisionProjectSnapshot s ON s.RevisionDetailFK = rd.Id
    WHERE s.Id IS NULL
    -- exclude drafts (RO=0) if the process only creates snapshots on submit
)
BEGIN PRINT 'FAIL — hollow revision: detail without snapshot'; END
```

**Enumerate the full graph — don't hand-pick a subset (SKL-009).** Do not eyeball "a snapshot and
approvals." **List every FK-child the parent has** (from the schema's FK edges / the as-built
semantics ingest), then assert presence for each one the process guarantees. A hand-picked subset
under-specifies and lets a partially-hollow fixture pass.

For a revision aggregate, that means asserting **all** of:
- `tRevisionProjectSnapshot` (1 per revision)
- `tRevisionApprovals` (exactly 2: RO + CO)
- `tRevisionProjectFundingProfile` (≥1)
- `tRevisionProjectComponentCost` (≥1) → each with `tRevisionProjectComponentCostPerYear` (≥1)
- `tRevisionProjectMajorWorkItem` (≥1 where the component has work) → each with `…MajorWorkLocations`
- `tRevisionDetailsComponentsStatus` (≥1)

**Standard completeness patterns to assert** (adapt per domain):
- **Full child enumeration:** for each FK-child table of the aggregate root, assert the
  process-guaranteed cardinality — not just the one or two you remember
- Paired rows: every `tRevisionDetails` has exactly 2 `tRevisionApprovals` (RO + CO)
- Grandchildren too: every cost row has a cost-per-year; every work item has a location
- Lookup coverage: every FK value used in the fixture exists in the lookup table

**Why this step exists:** in the MYPS revision session this fired **twice**. First, 7 of 8
revisions were seeded without snapshots and the drill reported 15/15 PASS (no snapshot check).
After adding a snapshot check, the fixture *still* shipped without funding/costs/work-items —
because the completeness check was a hand-picked subset, and the operator caught the gap again.
The fix: enumerate the *whole* child graph, not the parts you happen to remember.

A drill that passes on data the process could never produce is worse than no drill.

### 8. Execution plan analysis section

After all functional checks pass, include an execution plan section that validates
query performance against the schema. Invoke `dba-execution-plan` for the methodology.

**Mandatory structure:**
1. Come AFTER the `DRILL COMPLETE` message and all functional verification
2. Define 5–7 representative access pattern queries (EP-1 through EP-N)
3. Each query has a comment explaining when it runs in the application
4. Use `SET SHOWPLAN_ALL ON` / `OFF` in separate GO-delimited batches
5. Use realistic WHERE values from the drill's test data
6. End with a printed summary of what to look for

```sql
/* ══ ESTIMATED EXECUTION PLANS ══ */
GO
SET SHOWPLAN_ALL ON;
GO
/* ── EP-1: LIST VIEW — [description] ── */
/* App: [when this runs] */
SELECT ...;
GO
/* ── EP-2: FILTER — [description] ── */
SELECT ...;
GO
SET SHOWPLAN_ALL OFF;
GO
PRINT 'Review plans: Seek=good, Scan=check, Sort=missing index, Key Lookup=add INCLUDE';
GO
```

**Access patterns to always include (if applicable):**
- List view with count/aggregation
- Filter by non-PK column
- Detail view with multi-table JOIN
- Map/spatial query (if location data exists)
- Reverse lookup (child → parent)
- Aggregation query (SUM, COUNT across tables)

### 9. Pagination performance check

If the schema serves list views (programs, projects, revisions), verify that the primary
list queries support **keyset pagination** (not just OFFSET/FETCH):

```sql
-- OFFSET pagination (slow at high page numbers — scans and discards rows):
SELECT * FROM tProjects ORDER BY Id OFFSET 10000 ROWS FETCH NEXT 20 ROWS ONLY;

-- Keyset pagination (fast at any depth — seeks directly to the cursor position):
SELECT TOP 20 * FROM tProjects WHERE Id > @lastSeenId ORDER BY Id;
```

**What to check:**
- Do list-query tables have a **monotonically increasing PK or indexed column** suitable
  as a keyset cursor? (IDENTITY `Id` works; GUID does not — GUIDs are random, not ordered)
- If the list is sorted by a non-PK column (e.g., `CreatedDate`, `StageName`), is there a
  **composite index** on `(SortColumn, Id)` to support keyset pagination on that sort?
- For filtered lists (e.g., "projects in Region X"), is there an index on
  `(Region, Id)` or `(Region, CreatedDate, Id)` to support keyset + filter?

**The rule:** any table that powers a paginated list view must have at least one keyset-
friendly index path. If the only option is OFFSET, flag it — OFFSET degrades linearly with
page depth and will become a performance problem at scale.

### 10. Scale test (when a DB is available)

If a live database is available, extend the drill beyond the 1-entity scenario:

1. **Generate realistic volume:** seed N programs × M projects × 7 stages × detail rows
   using the same INSERT patterns from the drill, parameterized in a loop.
   Suggested minimums: 50 programs × 20 projects = 1,000 projects × 7 stages = 7,000
   project-revision rows × detail multiplier.

2. **Run the top 5 queries** from the process interview (Q5) against the seeded data.

3. **Check execution plans:** `SET STATISTICS IO ON; SET STATISTICS TIME ON;`
   - Look for table scans on fact tables (should be index seeks)
   - Look for key lookups (might need covering indexes)

4. **Check DMVs:**
   ```sql
   -- Missing indexes the optimizer wants:
   SELECT * FROM sys.dm_db_missing_index_details WHERE database_id = DB_ID();
   -- Index usage (are your indexes actually being used?):
   SELECT * FROM sys.dm_db_index_usage_stats WHERE database_id = DB_ID();
   ```

5. **Measure the stage-advance tree-copy** at scale: how long does copying 20 projects'
   detail trees (cost + funding + work + locations) take in one transaction?

This is optional (only when a DB is available), but converts the drill from "logic correct"
to "logic correct at production scale."

---

## Reusable techniques (captured workflows)

### WFC-001 — Transactional routing drill (force → verify → ROLLBACK)
When the schema routes rows by status/state (approval queues, workflow stages, filtered views),
natural seed data rarely covers *every* branch — so branches go untested and a green drill is
misleading. Force each branch explicitly inside a transaction, verify routing, then roll back so
nothing persists:

```sql
BEGIN TRAN;
  -- force the existing rows into each distinct state the router cares about
  UPDATE a SET Status = 0 FROM dbo.tRevisionApprovals a WHERE a.RevisionDetailFK=@r1 AND a.Level='RO'; -- → IO queue
  UPDATE a SET Status = 2 FROM dbo.tRevisionApprovals a WHERE a.RevisionDetailFK=@r2 AND a.Level='RO'; -- → RO queue
  UPDATE a SET Status = 4 FROM dbo.tRevisionApprovals a WHERE a.RevisionDetailFK=@r3 AND a.Level='RO'; -- → CO queue
  -- assert each row lands in the expected bucket
  SELECT 'IO' q, Id FROM dbo.fRevisionQueue('IO') UNION ALL SELECT 'RO', Id FROM dbo.fRevisionQueue('RO') ...;
  -- assert coverage: every row in exactly one bucket, no dupes
ROLLBACK;  -- data restored; verify it's back to baseline
```
Proven across the MYPS revision views (queue routing, effective overlay, one-open guard, stage advance).
Use for any status-routed schema. ROLLBACK keeps the baseline fixture intact for the next assertion.

### WFC-002 — Seed / drill split (reusable fixture + validation gate)
Keep **two** files, not one:
- `*-mock-data.sql` — **persistent** truncate + full-content seed. Run anytime to reset to a known
  good state. No assertions; just realistic data (the full entity graph per SKL-009).
- `drill-*.sql` — **validation**: truncate + seed + assert (completeness gate + functional checks).

Why split: the seed is reusable for manual exploration, demos, and app dev against known data; the
drill is the automated gate. Both share the same seed logic (copy it, don't cross-depend — see
auto-seed rule 5). This separation is what makes the fixture a *reusable asset* instead of drill-only scaffolding.

---

## Output format

The drill produces a **runnable .sql file** with:

```
DRILL: [Entity] Lifecycle
Date: [YYYY-MM-DD]
Schema: [which recommended schema version]
---

STEP 1: [operation]
  [SQL statements]
  [SELECT to show state]
  Expected: [row counts, key values]

STEP 2: [operation]
  ...

STEP N: [final state]
  [Summary: total rows per table]
  [GUID trail (if applicable)]

FAILURE MODES:
  [FM-1]: [description + impact + mitigation]
  [FM-2]: ...

PAGINATION CHECK:
  [keyset-friendly index paths for list tables? Y/N + details]

CLEANUP:
  [DELETE statements, children-first]

ROLLBACK:
  [paired rollback SQL for each CREATE/ALTER in the schema DDL]
```

---

## Pass criteria — TWO levels

### Level 1: SYNTAX-REVIEWED (achievable without a live DB)

The drill reaches this level if:
- [ ] Every lifecycle step produces the expected table operations
- [ ] Row counts match at every milestone (on paper)
- [ ] Historical snapshots are preserved (not overwritten) after advances
- [ ] GUIDs are consistent across all tables at each step
- [ ] Key linkages (FK-style columns) point to real, existing rows
- [ ] All multi-table operations are wrapped in transactions
- [ ] Failure modes are documented with mitigations
- [ ] The SQL is syntactically valid (no obvious parse errors)

**Status after Level 1: `UNVALIDATED`** — the SQL looks right but has never been
executed. This session alone shipped 3 bugs that only appeared on execution
(UTF-16 decode, `%%` in mermaid, Python operator precedence). Paper drills miss
exactly those. **DO NOT report "drill passed" — report "drill syntax-reviewed,
UNVALIDATED until executed."**

### Level 2: EXECUTED (requires a live DB or equivalent)

The drill reaches this level if:
- [ ] Level 1 criteria met
- [ ] Script executed successfully on a real database (or sqlcmd / container / CI)
- [ ] SELECT verification queries return expected row counts
- [ ] No runtime errors (type mismatch, constraint violation, deadlock)
- [ ] Cleanup block runs cleanly

**Status after Level 2: `VALIDATED`** — the schema works. This is the real pass.

### How to reach Level 2 without a live DB

If no SQL Server is available in the dev environment:
- **Option A:** Ask the operator to run the drill script on a dev/test DB and
  report results. Provide the `.sql` file ready to execute.
- **Option B:** Use a local SQL Server container (`docker run -e 'ACCEPT_EULA=Y'
  -e 'SA_PASSWORD=...' -p 1433:1433 mcr.microsoft.com/mssql/server`) if Docker
  is available.
- **Option C:** Use `sqlcmd` with a connection to a dev server if available.
- **Option D:** Stay at Level 1, explicitly label the schema as `UNVALIDATED`,
  and log "drill execution pending" as an open item.

**Never silently report Level 1 as if it were Level 2.**

The drill FAILS if:
- Any step produces unexpected row counts
- A snapshot row is modified after a subsequent stage advance
- A multi-table operation has no transaction boundary
- A key linkage points to a non-existent row
- A known failure mode has no mitigation
- A money column uses `float` instead of `decimal`
- A list-query table has no keyset-pagination-friendly index
- No rollback script exists for the schema DDL
- Referential-completeness assertions fail (hollow fixtures — parent without process-guaranteed children)
- (Level 2 only) Runtime errors occur during execution

---

## Rules

1. **Runnable SQL.** The drill script must be executable against a real database with
   the recommended schema. It is not pseudocode.
2. **Realistic data.** Use plausible business keys, descriptions, and lookup codes —
   mark assumed values with `/*ASSUMED*/`.
3. **Explicit state checks.** After every step, SELECT and show the state. Don't just
   INSERT and move on — prove the state is correct.
4. **Every failure mode gets a mitigation.** "What could go wrong" is not useful
   without "how to prevent it" or "how to detect it after the fact."
5. **Cleanup is mandatory.** The drill must be re-runnable. Provide the DELETE block.

---

## Quality checklist

- [ ] Every lifecycle step from the process interview is covered
- [ ] Every table operation from the data-flow-trace is represented
- [ ] SELECT statements verify state after each step
- [ ] Transactions wrap all multi-table operations
- [ ] GUID consistency checked across tables
- [ ] Historical snapshots verified as read-only after advance
- [ ] Referential-completeness asserts pass (no hollow fixtures — every parent has its process-guaranteed children)
- [ ] At least 5 failure modes documented with mitigations
- [ ] Cleanup block provided (commented out, children-first)
- [ ] Script is syntactically valid T-SQL

## Failure exit

"Cannot run a drill without a completed process interview, schema inventory, and
data-flow trace. Run dba-process-interview → dba-schema-ingest → dba-data-flow-trace
first."
