# Skill: data-migration-playbook

## Purpose
A repeatable, safety-first plan for moving **data** from one schema to another — the level below
`conversion-analysis` (which handles application porting and the parity matrix). This is the
table-to-table, column-to-column work: field mapping, transform rules, load order, validation,
and rollback. It exists because this was done by hand for LOCAL-MYPS → myps_db (40 lookup tables,
plus a circular-dependency failure in seed generation), and that grind — and that class of
failure — will recur on every migration unless it's a jig instead of glasswork.

`SKL-001` in the improvement backlog. This is the DBA migration discipline (D3 Migration Safety)
made into a reusable procedure.

## Trigger
Invoke when the operator says "migrate the data", "move data from [old] to [new] schema",
"data migration plan", "ETL the legacy data", "seed the new database from the old one",
"backfill", "ilipat ang data". Chains from `conversion-analysis` (app port) and `database-admin`
(once both schemas exist).

## Minimum context required
- **Both schemas** — source and target DDL (ingest via `dba-schema-ingest` if not already).
- Data volume (drives the lock/downtime strategy) and whether the source stays live during migration.
- Whether this is one-shot (cutover) or ongoing (sync) — they need different plans.

---

## The five stages

### 1. MAP — source → target, field by field
Every target column gets a source: a direct column, a transform, a constant/default, or "new
(no source)". Every source column is either mapped or explicitly dropped. Unmapped columns on
either side are the #1 silent data-loss cause — make them visible.

### 2. TRANSFORM — the rules between source and target
Type changes, unit/format conversion, key remapping (natural → surrogate), splits/merges,
de-duplication, cleansing (the embedded-newline / special-char traps that break naive exports).
Each rule stated explicitly so it's reviewable and re-runnable.

**Profile the source's actual NULL/domain reality against the target's constraints (SKL-023)
before writing a single INSERT.** A column can be nullable in the source with real, current NULL
rows in production even if the design assumes it's always populated. Run, per mapped column that
the target makes `NOT NULL` or narrows the domain of:

```sql
SELECT COUNT(*) AS null_count FROM source.tYourTable WHERE YourColumn IS NULL;
SELECT DISTINCT YourColumn FROM source.tYourTable; -- domain check vs target's enum/FK
```

Any non-zero NULL count against a target `NOT NULL` column needs an explicit default rule in the
mapping (e.g. `ISNULL(CreatedDate, GETDATE())`), decided **before** the load runs — not discovered
mid-script. Caught live (RBAC migration, 2026-07-07): `tGroups.CreatedDate` was nullable in the
as-built source with real NULLs in production, but `NOT NULL` in the new schema — the seed script
died with `Msg 515` partway through, forcing a full children-first delete-and-reseed instead of a
clean single pass.

**Size-check discriminator/label columns against your OWN planned literal list too, not just
source data (SKL-023 addendum).** If the migration introduces a new discriminator column (a type
tag that didn't exist as a distinct field in the source), profiling the source can't catch a
too-narrow width for it — the value never existed there to profile. Check `MAX(LEN(...))` against
every literal you plan to write, before the column is sized. Caught live (MYPS admin-area,
2026-07-08): a migration-introduced `OrgType NVARCHAR(20)` truncated `'CongressionalDistrict'`
(21 chars, an author-chosen label, not migrated data).

**Precheck CSV code/ID columns for Excel scientific-notation corruption before loading (SKL-030).**
When the source is a spreadsheet export, Excel silently converts any long numeric-looking string
(an ID, a hierarchical code) into scientific notation the moment the column isn't explicitly typed
as text — `104305000` becomes `1.03171E+12`, destroying the exact value a join key depends on. This
is invisible on a quick eyeball of a few rows (short codes survive) and only shows up as a
near-total corruption rate once you check every row. Before mapping any source code/ID column:

```sql
-- or the file-reading equivalent if the source hasn't been staged yet
SELECT COUNT(*) AS corrupted FROM staging.tYourTable WHERE YourCodeColumn LIKE '%E+%' OR YourCodeColumn LIKE '%e+%';
```

Any non-zero count means the column is not usable as a join key or a stored value as-is — the
source must be **re-exported with that column forced to text** (not "fixed" by reformatting the
corrupted value back, which is lossy once precision is lost past ~15 digits). Caught live twice:
74 `CityMunicipality.Code` values in the ADR-029 AAMS backfill (repaired that time), then 1,620 of
1,643 city rows + 46 of 257 district rows (99%/18%) in a *second, independently-supplied* source
CSV set for the same domain — the corruption recurs with every fresh Excel-touched export, so this
is now a standing precheck, not a one-time fix.

### 3. ORDER — load sequence that respects dependencies
Topologically sort by FK dependency: parents/lookups before children. **The circular-dependency
trap:** if generating the target's seed depends on the target already having data, you deadlock —
break it by sourcing from the *origin* (the live source DB) first, then regenerating. Lookups →
core entities → dependent rows → wiring (FKs/constraints) last.

### 4. VALIDATE — prove the move was correct
Row counts per table (source vs target), checksums/aggregates on money and key columns, referential
integrity (no orphans), spot-checks on transformed rows, and the business invariants that must hold
(e.g. every active record has a status). A migration with no validation queries is unverified.

### 5. ROLLBACK — the way back
Backup-before, the reversal plan, the cutover window, and the go/no-go criteria. Reversibility is
assessed *before* running, not discovered during an incident.

---

## Steps
1. Ingest both schemas (`dba-schema-ingest`). Confirm volumes and one-shot vs ongoing.
2. Build the **mapping table** (stage 1) — every target column sourced; every source column mapped or
   dropped-on-purpose. Surface unmapped items.
3. Specify **transform rules** (stage 2), calling out the data-quality traps (newlines, encoding,
   nulls, duplicate keys). **Profile source NULLs/domains against target constraints (SKL-023)**
   for every column the target tightens — a nullable-to-NOT-NULL or widened-to-narrowed domain
   gap needs an explicit default/cleansing rule before the load runs, not a mid-script failure.
   **If the source is a spreadsheet export, precheck every code/ID column for `E+` scientific-
   notation corruption (SKL-030)** before it's trusted as a join key.
4. Determine **load order** (stage 3); explicitly check for and break circular dependencies.
5. Write **validation queries** (stage 4) — counts, checksums, integrity, invariants.
6. Define **rollback + cutover** (stage 5) with go/no-go criteria.
7. Apply the **triple lens**: SA (does the mapped data satisfy the requirements?), PM (cutover window,
   downtime, rollback owned?), DBA (locks, replication lag, data-loss risk → `RISK-` per D3).
8. Save the playbook to the project `deliverables/documents/`. Log migration `RISK-` entries.

---

## Output format
```
DATA MIGRATION PLAYBOOK — [source] → [target] — [YYYY-MM-DD]
Volume: [rows/tables]   Mode: one-shot cutover | ongoing sync   Source live during: yes/no

1. MAPPING                                         (every target col sourced)
   target.col            ← source.col / transform / const / NEW
   ⚠ unmapped source cols: [list or "none"]   ⚠ new target cols: [list]

2. TRANSFORM RULES
   - [rule] (e.g. natural key PAPKey → surrogate FK via lookup)
   - data-quality traps handled: [newlines / encoding / dup keys / nulls]

3. LOAD ORDER  (FK-topological)
   lookups → core entities → dependents → constraints/FKs last
   circular-dependency check: [none / broken by sourcing from origin first]

4. VALIDATION QUERIES
   - row counts src vs tgt per table
   - checksums on [money/key cols]
   - orphan check (referential integrity)
   - business invariants: [e.g. every active row has a status]

5. ROLLBACK & CUTOVER
   Backup: [what/where]   Window: [when]   Reversal: [steps]
   Go/No-Go: [criteria]

RISK-NNN (per D3): [lock / data-loss / downtime risk + mitigation]
```

Close with **Decisions needed / Open questions / Next steps**.

## Reusable techniques (captured workflows)

### WFC-007 — Client-file → embedded-staging reconciliation recipe
When an operator drops a spreadsheet/export as an authoritative correction against already-live
data (not a from-scratch migration — a targeted reconciliation), this sequence has proven itself
twice (MYPS IOMS org-chart, MYPS AAMS geography) and hardened with three corrections each time:

1. **Read the file with a script, not by eye** (`openpyxl`/equivalent) — binary formats aren't
   readable directly, and a script lets you diff systematically instead of skimming.
2. **Diff both directions against the live DB before touching anything**: what's new, what's
   misclassified, what's misparented. Don't assume the file is a pure superset or pure correction —
   check both ways.
3. **Math-check the total BEFORE executing**: `(existing rows) + (net new) = (source file's row
   count)`. If it doesn't reconcile exactly, something is misunderstood — find out what before
   writing DML, not after.
4. **Verify the join key is actually unique in the source before joining on it.** A name that looks
   unique often isn't — 108 town names collided across different Philippine provinces in AAMS; a
   name-only join would have silently cross-wired the wrong `Code`/`Hierarchy` onto rows with zero
   error. Check `GROUP BY key HAVING COUNT(*) > 1` against the *real* source data before trusting
   any join key, and widen to a compound key if collisions exist.
5. **Chunk staging INSERTs to ≤500 rows.** SQL Server's row-constructor VALUES clause caps at 1000
   rows per statement — a large staging table (1,000+ source rows) will fail to parse otherwise.
6. **NULL, don't guess, for source-side corruption — but precheck for it first (SKL-030).** Scan
   every code/ID column for `E+`/`e+` (Excel scientific-notation corruption) before mapping it as a
   join key — this recurs on *every* fresh Excel-touched export, not just once. Where corruption is
   found, leave the target NULL and log it (or, better, get the source re-exported as text) — don't
   reverse-engineer or interpolate a value the source doesn't actually contain.
7. **Self-contained final script**: embed the staging rows directly in the SQL file (generated via
   the same script that read the source) rather than depending on the source file being present at
   run time. Transactional, with inline verification counts.
8. **Extend the drill, run it, then log gaps as `RISK-`/`ASS-` entries** rather than chasing every
   edge case to zero — a reconciliation pass legitimately ends with some rows still NULL because
   the source itself is incomplete; that's a documented gap, not a bug to keep fixing indefinitely.

Distinct from the general MAP→TRANSFORM→ORDER→VALIDATE→ROLLBACK stages above in one way: this
recipe assumes the target schema and most of the target data already exist — it's a *correction*
pass triggered by a client-supplied authoritative file, not a first migration.

---

## Quality checklist
- [ ] Every target column has a source; every source column mapped or dropped-on-purpose (no silent loss)
- [ ] Transform rules explicit, incl. the data-quality traps that break naive exports
- [ ] Source NULLs/domains profiled against every target column that tightens a constraint, with an explicit default/cleansing rule decided up front (SKL-023)
- [ ] Any migration-introduced discriminator/label column sized against your own planned literal list, not just source data (SKL-023)
- [ ] If the source is a spreadsheet export, every code/ID column prechecked for `E+`/`e+` scientific-notation corruption before being trusted as a join key (SKL-030)
- [ ] Load order is FK-topological; circular dependencies checked and broken
- [ ] Validation queries cover counts, checksums, integrity, and business invariants
- [ ] Rollback + cutover defined with go/no-go criteria before any run
- [ ] Migration `RISK-` entries logged (locks, replication, data loss per D3)

## Failure exit
"I can't write a safe migration with only one side of it — I need both the source and target DDL
to map columns and order the load. Point me at both schemas (I'll ingest them), and tell me the
data volume and whether the source stays live."
