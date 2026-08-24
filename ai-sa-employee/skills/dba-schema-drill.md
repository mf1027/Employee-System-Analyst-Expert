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

## Drill-authoring conventions (SKL-014) — write drills that can actually be re-run

A drill suite is only useful if every drill can be executed on demand. Caught live: a whole suite
couldn't be run *as a suite* — two drills shared a program key, targeted-cleanup drills left orphans
that blocked re-runs, one wasn't self-seeding, and two scripts hit **Msg 1934** for a missing SET
option. Every drill MUST follow these to stay runnable:

1. **Header SET options — always.** Start every drill with
   `SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET XACT_ABORT ON;`.
   Project/program tables carry filtered indexes / computed columns — without `QUOTED_IDENTIFIER ON`
   any INSERT/UPDATE/DELETE on them fails with *Msg 1934 (incorrect SET options)*.
2. **Unique business-ID namespace per drill — chosen so a sibling's `LIKE` can never match it (SKL-032).**
   No two drills may share a program/project key (`FP-2026-0001` was claimed by two drills → their
   targeted cleanups collided). A "distinct-looking" prefix is not enough if it's a *substring* of
   another mock's prefix — `LIKE 'MOCK_PRG_%'` still matches `MOCK_PRG_SKIP`/`MOCK_PRG_FULL` once both
   exist, causing FK-violation cleanup crashes and inflated counts in the other drill. Pick a prefix
   where `LIKE 'yourprefix%'` cannot match any sibling's rows even after future mocks are added — a
   numbered series (`MOCK_PRG_0%`) or a fully distinct stem, not a shared root with a suffix tacked on.
3. **Self-seed every FK parent.** A drill creates the programs/projects/lookups its rows reference —
   never depend on data another drill (or a prior era's mock) left behind. A hardcoded surrogate key
   (`ProjectRevisionFK = 18`) is the classic trap; capture real IDs with `SCOPE_IDENTITY()`.
4. **Full-truncate OR clean-slate reset.** Prefer a children-first full truncate (see
   `scripts/reset-transactional.sql`). If a drill uses targeted cleanup instead, run it against a fresh
   reset — targeted-cleanup drills can't safely coexist with foreign residue.
5. **Idempotent + self-cleaning.** Re-runnable from any state: clean the prior run at the top, remove
   what you seeded at the end.

### Drill classification tokens (SKL-038) — a mechanical gate, not a remembered one

Rule 14 below ("the registry tag is a hint, verify by reading before a sweep") is the *correct*
instruction — and it still failed **three times** across four days: a phantom-risk report on
already-retired drills (2026-08-03), a full mock wipe when `drill-revision-full.sql` ran inside a
sweep the very next day (2026-08-04) — the exact failure the rule exists to prevent, repeated less
than 24 hours after being written down — and a third recurrence two days later reporting retired
drills as broken. Three recurrences of a documented rule means the rule's *shape* is wrong, not that
it needs repeating a fourth time. A note that must be remembered before every sweep will keep failing
under exactly the conditions (a long session, many files, working from a list) that sweeps happen in.

**The fix: every drill file declares its own classification in its header, and a sweep is not
allowed to include a file that hasn't declared one.** Three tokens, one per file, in the header
comment block:

```sql
-- @DESTRUCTIVE   -- unqualified DELETE/TRUNCATE across shared tables (e.g. drill-revision-full.sql)
-- @HISTORICAL    -- superseded, self-documents "do not run" — kept for the record only
-- @NEEDS-FIXTURE -- a paired persistent-validator; must run AFTER its *-mock-data.sql seed, never after a reset
```

A file with none of the three tokens is an ordinary self-cleaning drill, safe in the standard
reset-preceded sweep loop (rule 4 above / SKL-014).

**The sweep gate:** before running any bulk `drill-*.sql` sweep, grep every candidate file's header
for these tokens first. `@DESTRUCTIVE` and `@HISTORICAL` files are **excluded from the sweep by
default** — they only run if named explicitly by the operator or by a task that specifically needs
them. `@NEEDS-FIXTURE` files are excluded from the reset-preceded loop and run in their own
reseed-then-validate pass. This turns rule 14's "read it and remember" into "the sweep runner
mechanically cannot include it" — the same shift SKL-013 made for drill *execution* (a doc claiming
a drill is valid isn't evidence; only a run is) applied here to drill *selection*.

Stamping is a one-time pass per file, done once at authoring time or the next time the file is
touched — not a retroactive project to re-open all 40+ existing drills at once.

---

## Steps

### 0. Metadata assert — deployed reality vs. the design doc (SKL-023)

Before writing a single INSERT, query the **live deployed schema's metadata** and diff it against
what the design doc claims — cascade actions, nullability, and uniqueness are exactly the kind of
detail that silently drifts between "what I wrote in the DDL file" and "what actually got created,"
and a drill built on the assumed version will pass while the deployed version is wrong.

```sql
-- Cascade actions: does delete_referential_action_desc match the design doc?
SELECT fk.name, fk.delete_referential_action_desc, fk.update_referential_action_desc
FROM sys.foreign_keys fk WHERE fk.parent_object_id = OBJECT_ID('dbo.tYourTable');

-- Nullability: does IS_NULLABLE match what the drill's INSERTs assume?
SELECT COLUMN_NAME, IS_NULLABLE, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'tYourTable';

-- Uniqueness: are the constraints the design doc promises actually there?
SELECT i.name, i.is_unique, i.is_primary_key
FROM sys.indexes i WHERE i.object_id = OBJECT_ID('dbo.tYourTable');
```

Caught live (RBAC build, 2026-07-07): `tUserGroupMemberships`'s FKs deployed as `NO_ACTION` while
the design doc said `CASCADE` — found only because this query happened to run before the drill was
written; the drill would eventually have caught it too, but as a confusing mid-run failure instead
of a 30-second check. Same session, a seed script died on `Msg 515` because `tGroups.CreatedDate`
was nullable in the as-built source (real NULLs in production data) but NOT NULL in the new schema —
a nullability mismatch a metadata query would have surfaced before the first row was written.

**The rule:** run this against the target table set once, right after deployment and before
authoring step 1's fixtures. Fix any mismatch (or the doc, if the deployed version is actually
correct) before the drill script is written — don't let the drill discover it.

**This includes discriminator/enum values you write yourself, not just migrated data.** Profiling
source data catches drift *from the source*, but a column sized for labels you're inventing right
now (an `OrgType` discriminator, a status-string enum) needs the same check against your own
longest literal — profiling only the migrated data misses it because the value never existed in
the source to profile. Caught live (MYPS admin-area, 2026-07-08): `OrgType NVARCHAR(20)` was sized
before deciding the actual label set, then `'CongressionalDistrict'` (21 chars, a label I invented,
not migrated) truncated and failed the load. `SELECT MAX(LEN(x)) FROM (VALUES ('Label1'),('Label2'),...) v(x)`
against your own planned literal list costs nothing and would have caught it before the first run.

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

### WFC-009 — Read-only structural-validation drill (for a reference-data lock)
Not every drill validates a mutable entity's lifecycle. Locking a **reference/lookup schema** (no
transactional lifecycle — e.g. an admin-area/geography table set) calls for a different, cheaper
archetype: a **read-only** drill against **live** data, with no fixture seed and nothing to clean up.

Assert, directly against production rows:
- **Structure** — the columns/indexes/constraints the lock was supposed to produce actually exist
  (e.g. a dropped column is really gone, a new UNIQUE index is really unique).
- **Hierarchy/referential integrity** — no orphans in the real data, no cycles in a self-referencing
  `ParentId` walk (bound the recursive CTE depth to catch a cycle instead of an infinite loop).
- **View/function correctness** — a new consumption view returns the right slice, doesn't leak a row
  it shouldn't (wrong type, deprecated row), and per-branch counts sum to the whole.
- **Real-data-untouched** — row counts unchanged by the lock (the DDL touched structure, not data).

```sql
-- example: no cycle in a self-referencing hierarchy (bounded depth catches what an
-- unbounded recursive CTE would spin forever on)
;WITH anc AS (
    SELECT Id, ParentId, 1 AS depth FROM dbo.tYourTable WHERE ParentId IS NOT NULL
    UNION ALL
    SELECT a.Id, o.ParentId, a.depth+1 FROM anc a JOIN dbo.tYourTable o ON o.Id=a.ParentId WHERE a.depth < 50
)
SELECT CASE WHEN ISNULL((SELECT MAX(depth) FROM anc),0) < 50 THEN 'PASS' ELSE 'FAIL — cycle' END;
```

This is a **third archetype**, distinct from WFC-001 (transactional force→verify→ROLLBACK, for a
status-routed schema) and WFC-002 (persistent seed + validation-gate split, for a mutable entity) —
both of those assume something changes over time; this one proves a static/reference schema is
sound as-is. Caught live (MYPS admin-area schema lock, ADR-047): `drill-admin-area-v3.sql`, 12/12
PASS first run, zero rework — no fixture needed because the thing being validated (GdbId dropped,
Code re-keyed, 8 per-type views) is a property of the live table/view definitions themselves, not
of any transaction.

### WFC-008 — Dynamic lookup-value selection (avoid hardcoded literal NameIds)
When a drill needs to seed an app-enforced (no-FK) lookup column — `Category`, `Thrust`, `Origin`,
`Agency`, and similar `NameId`-keyed columns — select a **real** value at drill-runtime instead of
hardcoding a literal guessed or copied from a prior drill:

```sql
DECLARE @CatId INT = (SELECT TOP 1 CategoryId FROM dbo.tOptionProjectCategory WHERE IsActive = 1 ORDER BY CategoryId);
DECLARE @ThrustKey INT = (SELECT TOP 1 PAPKey FROM dbo.tOptionProjectThrustList WHERE IsActive = 1 ORDER BY PAPKey);
```

Why: a hardcoded literal silently breaks if the lookup table's numbering ever changes — or worse,
it keeps "working" but resolves to the **wrong** name without the drill failing at all, since
nothing enforces the FK. This is the same "ground in real values, never invent" principle behind
SKL-006/008, applied specifically to drill *authoring* rather than production design. Caught live
2026-07-16 (`drill-project-list-views.sql`, 11 lookup columns) — no rework, 9/9 PASS first run.

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

### Root Cause Analysis on any FAIL (Level 1 or 2) — added 2026-08-24, SKL-050

This skill already has heavy "is the drill itself still accurate" coverage, distributed across
rules 12 (registry regenerated fresh, not from memory), 31/36 (verify a drill's real behavior,
don't trust its registry claim), 38 (mechanical classification-token gate), and 49 (foreign-residue
+ full FK-graph checks before cleanup) — that ground is not being re-covered here. What's missing is
a required structure for reporting *why* a specific run failed. For every FAIL, state:

1. **Mechanism** — the exact table/proc/view/step responsible, not just "step N failed."
2. **Since when** — `git log -1`/mtime on the object's defining script, or `sys.objects.modify_date`
   for a live DB object, to date the regression rather than just asserting it.
3. **New or recurring** — check `memory/improvement-backlog.md` for the same failure shape. This
   file's own history is dense with exactly this: SKL-036 existed and the same trap recurred 3 times
   in 4 days anyway (SKL-038); SKL-031 was resolved and recurred the same session (SKL-049). A
   failure that already has a resolved SKL- number and still recurred is not "log a new RISK," it's
   "the existing fix's shape doesn't hold at this failure's scale" — the same conclusion SKL-038's
   own text reached.

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
6. **After ANY schema change, re-run the WHOLE suite to green (SKL-013).** Editing the one drill you
   touched is not enough — a schema change (dropped column, rename, moved status) can rot *any* drill.
   Execute every drill (clean-slate per drill) and confirm each is green before calling the change done.
   A drill is not "valid" in the docs until an execution proves it — 5 of 6 were silently broken while
   `database.md` listed all 6 as valid with check counts.
7. **SET options in every header (SKL-014).** `QUOTED_IDENTIFIER ON` + `ANSI_NULLS ON` — omitting them
   fails with Msg 1934 on tables with filtered indexes / computed columns.
8. **Assert output CONTENT, not just row/count shape (SKL-019).** A drill (or any generator/tooling
   verification) that only checks row counts, `LEN()`, or pass/fail flags can go green while the
   actual generated text is silently truncated or malformed — a display-layer bug (e.g. a client
   tool eating a line) doesn't change row counts at all. When validating generated SQL/code/config
   output, `SELECT` or `PRINT` the **actual content** and read it — or diff it against a known-good
   sample — not just its length or shape. Caught live: two "green" verification passes both missed a
   silently-dropped output line because they checked `LEN(@Result)` and row counts, never the
   rendered text itself.
9. **Metadata-assert the deployed schema before authoring fixtures (SKL-023).** Query cascade
   actions, nullability, and uniqueness against the live deployed objects and diff against the
   design doc — don't assume the DDL you wrote is the DDL that landed. Also size-check discriminator/
   enum columns against your OWN planned literal set, not just migrated data — a column sized before
   the label set is finalized will truncate a self-authored value the same way it would a source
   value. Caught live: a cascade deployed as `NO_ACTION` against a documented `CASCADE`, a
   nullable-vs-NOT-NULL mismatch that broke a seed script mid-run, and an `OrgType NVARCHAR(20)`
   truncating `'CongressionalDistrict'` — a label the author invented, not something migrated. See
   Step 0.
10. **Verification SELECTs must be per-table, never UNION'd across tables with different column
    sets (SKL-026).** A UNION spanning tables whose columns don't line up forces a phantom column
    reference somewhere — and that's a *compile* error, which kills the whole batch silently
    (every later `GO`-batch still runs, but on an unseeded fixture) rather than a clean runtime
    FAIL on the one thing that's actually wrong. Caught live: a drill's own STEP 1 verification
    `SELECT` referenced `RegionId` on a table that has no such column (the Region table has no
    parent) — Msg 207 killed the seed insert, and every downstream assertion printed FAIL,
    shadowing the one real bug under nine phantom ones.
11. **Diagnose top-down on a first run, and NEVER through a PASS/FAIL output filter (SKL-026/036).**
    If a compile-level or runtime `Msg` error (not a `PRINT 'FAIL'`) appears anywhere in the output,
    fix that first and re-run before trusting any individual PASS/FAIL below it — a batch-compile
    failure *or a setup-phase FK/constraint violation* can silently skip/void a whole seeding step,
    and everything downstream fails for a reason that has nothing to do with what each assertion
    claims to test. **When you filter the run output to `PASS|FAIL|RESULT` lines, you HIDE these
    `Msg` errors** — so on any *unexpected* FAIL, re-run the drill UNFILTERED and read the raw output
    top-down before diagnosing the assertion itself. Caught live: a fixture hardcoded a component
    type (`CW1`) that an unrelated cleanup (ADR-057) had deleted; the setup `INSERT` failed silently
    with `Msg 547` (FK violation), and two downstream CHKs failed confusingly — the filtered output
    showed only the phantom FAILs, not the real cause. (Root-cause prevention: WFC-008 below —
    select lookup values at runtime instead of hardcoding them.)
12. **A "full suite" run is regenerated from `database.md`'s Drills registry, never from memory
    (SKL-031).** Building the re-run command list by habit/recall silently drops a registered drill
    from the run — it stays *documented* as valid while no longer being *proven* valid, and nothing
    flags the gap because the doc still lists it. Before any "re-run everything" pass, re-open the
    registry and enumerate every row currently marked active; treat any list assembled from memory
    as suspect. Caught live: `drill-revision-views.sql` (21 checks, registered) was silently absent
    from several consecutive "full suite" runs because the run list had been carried forward turn to
    turn instead of re-derived from the registry each time.
13. **Tag every drill self-cleaning vs. persistent-validator, and route the suite run accordingly
    (SKL-031).** A **self-cleaning** drill seeds its own fixture and cleans up after itself — safe to
    run after a full `reset-transactional.sql`. A **persistent-validator** drill checks a fixture that
    lives *outside* the drill (a `*-mock-data.sql` seed meant to persist as a deliverable, per
    WFC-002) — running it after a reset finds nothing and reports a false FAIL, or worse, a reset run
    ahead of it silently wipes a persistent mock the operator was shown as "live data." Persistent-
    validators run **after a reseed**, never after a reset; self-cleaning drills are the only ones
    safe in the reset-preceded loop. Caught live: a persistent-mock validator placed in the
    reset-preceded loop produced a spurious FAIL (0 rows found) when the reset wiped the mock it
    was meant to check; separately, a full-suite reset silently deleted a persistent 15-program/
    35-project deliverable that had already been delivered to the operator as live data that same
    session.
14. **The registry tag / drill header is a HINT, not truth — verify a drill's real destructiveness
    by reading it before a sweep (SKL-036).** Rule 13 routes by a drill's self-cleaning vs.
    persistent-validator tag — but that tag (in `database.md`'s registry, or the drill's own header
    comment) can be *wrong*, and trusting it blind is how a "safe" regression sweep wipes live data.
    Before including ANY drill in a sweep, open it and confirm what its cleanup and seeding actually
    do — then correct the registry if it lied. Two live catches, same session: (a)
    `drill-project-list-views.sql` was documented "self-cleaning" but has only a *pre*-cleanup (no
    bottom cleanup) — it leaves residue that inflated two other drills' `COUNT(*)` assertions;
    (b) `drill-revision-full.sql`'s header says "leaves data in place" but it full-truncates
    `tPrograms`/`tProjects`/the whole revision domain with no `WHERE` — it silently wiped a
    26/26-PASS standard mock mid-sweep. A drill's actual `DELETE`/`TRUNCATE` footprint is the truth;
    its label is a claim to be checked.
15. **T-SQL variable-scope traps in fixtures (SKL-037).** Two silent-corruption patterns, both of
    which pass a naive drill and fail a later count/content assertion:
    - **Table-type variables do NOT reset per loop iteration.** A `DECLARE @m dbo.SomeTableType;`
      inside a `WHILE` loop is *not* re-initialized each pass (unlike scalar `DECLARE @x = val;`,
      which does reset) — rows accumulate across iterations. Declare the table variable ONCE outside
      the loop and make `DELETE FROM @m;` the first statement inside it. Caught live: a
      `RevisionMapType` var re-declared each hop made `pCopyProjectDetailChain` re-copy an
      ever-growing map, inflating component/work-item counts 3→92 across 6 stage-advance hops.
    - **A shared `SCOPE_IDENTITY()` variable is overwritten by sibling INSERTs.** When a fixture
      inserts several sibling rows through the same capture variable (`SET @cc = SCOPE_IDENTITY();`
      after each of CW→ROW→LS), a later step needing "the FIRST sibling's Id" silently gets the last
      one. Capture a specific sibling's Id into its own uniquely-named variable (`@ccCW`) immediately
      after its own INSERT, before any sibling INSERT can overwrite the shared one. Caught live in 2
      files same session (`drill-revision-full.sql`, `myps-mock-data.sql`).
16. **A bulk sweep may only include files that have declared a classification token, and excludes
    `@DESTRUCTIVE`/`@HISTORICAL` by default (SKL-038 — hardens rule 14 into a mechanical gate).**
    Rule 14's "verify by reading before a sweep" is correct but proved insufficient on its own —
    it failed 3 times in 4 days, including a full mock wipe the day after being written down. Grep
    header tokens (see "Drill classification tokens" above) before assembling any sweep list; a file
    with no token is an ordinary self-cleaning drill, one with `@DESTRUCTIVE`/`@HISTORICAL` is
    excluded unless named explicitly, one with `@NEEDS-FIXTURE` runs in its own reseed-first pass.
    Do not rely on remembering which files are which — grep the tokens every time.
17. **Cross-mock table-collision guard — check for another mock's residue before writing to a
    shared core table (SKL-049, closes a gap SKL-031 named but never closed).** Rule 3's own-FK-
    parent seeding and rule 13's self-cleaning/persistent-validator routing both assume a drill owns
    its fixture in isolation — but two drills can share a core table (`tPrograms`, `tProjects`, a
    shared lookup) without either one truncating the other, and a reseed by one can silently
    invalidate an assumption the other was relying on, with no error raised anywhere. Before any
    script writes to a table it does not exclusively own, query for rows OUTSIDE its own business-ID
    namespace (the SKL-032 prefix from rule 2):
    ```sql
    SELECT COUNT(*) AS ForeignResidue FROM dbo.tPrograms
    WHERE ProgramKey NOT LIKE 'yourprefix%' AND ProgramKey NOT LIKE 'expectedsibling%';
    ```
    A non-zero, unexpected count means another mock currently occupies that table — stop and
    reconcile (coordinate a reset, or scope the drill's own assertions to just its own prefix)
    instead of reseeding on top of it silently. Caught live 2026-07-17, the SAME DAY SKL-031 shipped
    to fix the adjacent full-suite-wipe problem: a different, unrelated script sharing core tables
    invalidated a reseed with no error — SKL-031's own text named this exact gap ("no cross-mock
    collision guard") without closing it.
18. **Enumerate the FULL FK-child graph before hand-writing a cleanup DELETE cascade — never
    reconstruct it from memory (SKL-049).** Rule 7's "enumerate the full graph, don't hand-pick a
    subset" (SKL-009) applies to fixture *seeding*; this is the same discipline applied to fixture
    *cleanup*. When residue is discovered and a DELETE cascade has to be hand-written to remove it,
    query `sys.foreign_keys` for every child (and grandchild) of every table in scope — the same
    query already required in rule 7 and echoed in the Phase 1 dependency map of a schema rebuild —
    before writing the cascade, rather than listing tables from memory:
    ```sql
    ;WITH children AS (
      SELECT fk.name, OBJECT_NAME(fk.parent_object_id) AS ChildTable,
             OBJECT_NAME(fk.referenced_object_id) AS ParentTable
      FROM sys.foreign_keys fk
      WHERE fk.referenced_object_id IN (OBJECT_ID('dbo.tYourRootTable') /* , ...every table in scope */)
    )
    SELECT * FROM children;  -- re-run against each ChildTable found until no new rows appear
    ```
    A cascade assembled from memory under-counts silently — the DB won't complain about rows you
    forgot to delete, only about rows you tried to delete out of order. Caught live 2026-07-24:
    a residue-cleanup cascade missed the revision-mirror detail tables + `tRevisionDocuments` on the
    first pass, then missed `tTransactionLog` on a second pass — two rounds of "I think that's
    everything," neither one grounded in the actual FK graph.

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
- [ ] Header sets QUOTED_IDENTIFIER ON + ANSI_NULLS ON (SKL-014 — avoids Msg 1934)
- [ ] Drill self-seeds its FK parents + uses a unique business-ID namespace (SKL-014 — no cross-drill collision)
- [ ] Whole suite re-executed to green after any schema change, clean-slate per drill (SKL-013)
- [ ] Generated/output content verified by reading the actual text, not just counts/LEN (SKL-019)
- [ ] Deployed schema metadata-asserted (cascade actions, nullability, uniqueness) against the design doc before fixtures were authored (SKL-023)
- [ ] Discriminator/enum column widths checked against your own planned literal set, not just migrated data (SKL-023)
- [ ] Verification SELECTs are per-table, never UNION'd across mismatched column sets (SKL-026)
- [ ] On a first run OR any unexpected FAIL, re-run UNFILTERED (not `PASS|FAIL`-grepped) and diagnose setup-phase Msg errors top-down before trusting individual assertions (SKL-026/036)
- [ ] Business-ID prefix chosen so a sibling mock's `LIKE 'prefix%'` cannot match it, now or after future mocks are added (SKL-032)
- [ ] "Full suite" run lists regenerated from `database.md`'s Drills registry each time, not carried forward from memory (SKL-031)
- [ ] Each drill tagged self-cleaning or persistent-validator; persistent-validators run after a reseed, never after `reset-transactional.sql` (SKL-031)
- [ ] Before a sweep, each drill's ACTUAL destructiveness/cleanup verified by reading it — registry tag/header treated as a hint, and corrected if wrong (SKL-036)
- [ ] Loop table-type variables declared once outside the loop + cleared (`DELETE FROM @t;`) each iteration; a needed sibling's Id captured into its own variable right after its INSERT (SKL-037)
- [ ] This drill declares its classification token (`@DESTRUCTIVE` / `@HISTORICAL` / `@NEEDS-FIXTURE` / none = ordinary) in its header (SKL-038)
- [ ] Before assembling ANY sweep list, header tokens grepped fresh — `@DESTRUCTIVE`/`@HISTORICAL` excluded by default, `@NEEDS-FIXTURE` routed to its own reseed-first pass (SKL-038)
- [ ] Before writing to any shared (non-exclusively-owned) core table, checked for foreign residue outside this drill's own business-ID namespace (SKL-049)
- [ ] Any hand-written cleanup DELETE cascade is built from a fresh `sys.foreign_keys` query of the full child/grandchild graph, not reconstructed from memory (SKL-049)
- [ ] Script is syntactically valid T-SQL
- [ ] Any FAIL (Level 1 or 2) reported with mechanism / since-when / new-or-recurring — not just named (SKL-050); `improvement-backlog.md` checked for a 3rd+ occurrence of the same shape before logging another one-off RISK

## Failure exit

"Cannot run a drill without a completed process interview, schema inventory, and
data-flow trace. Run dba-process-interview → dba-schema-ingest → dba-data-flow-trace
first."
