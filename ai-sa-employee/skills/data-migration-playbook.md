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

## Quality checklist
- [ ] Every target column has a source; every source column mapped or dropped-on-purpose (no silent loss)
- [ ] Transform rules explicit, incl. the data-quality traps that break naive exports
- [ ] Source NULLs/domains profiled against every target column that tightens a constraint, with an explicit default/cleansing rule decided up front (SKL-023)
- [ ] Load order is FK-topological; circular dependencies checked and broken
- [ ] Validation queries cover counts, checksums, integrity, and business invariants
- [ ] Rollback + cutover defined with go/no-go criteria before any run
- [ ] Migration `RISK-` entries logged (locks, replication, data loss per D3)

## Failure exit
"I can't write a safe migration with only one side of it — I need both the source and target DDL
to map columns and order the load. Point me at both schemas (I'll ingest them), and tell me the
data volume and whether the source stays live."
