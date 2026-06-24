# Playbook: Migration Safety

Use for DDL risk assessment (ALTER/DROP/RENAME), locking, rollback feasibility,
EF Core migrations, and zero-downtime/online DDL. Default engine: SQL Server.

## Steps

1. **Read the migration end-to-end** — list every DDL statement (ALTER, DROP, RENAME,
   constraint add, type change) and every data-moving statement.
2. **Assess locking per statement.** Which take a schema-modification (Sch-M) lock that
   blocks all access? At what row count does that become a user-visible outage? Estimate
   the duration.
3. **Check rollback feasibility.** Is each step reversible *without data loss*? A column
   drop and a narrowing type change are not — they destroy data. An additive change
   usually is.
4. **Assess replication / AG lag** for multi-region or Always On setups — a large
   data-moving migration can blow out the redo queue and the readable-secondary lag.
5. **Identify data-loss risk explicitly** — column drops, type changes (e.g. `NVARCHAR`
   → `INT`, widening→narrowing), and constraint additions that fail on existing rows.
6. **Recommend the execution plan** — window, online/zero-downtime alternative, and the
   validation queries that prove success.

## SQL Server locking notes

- `ALTER TABLE ... ADD column NULL` with no default is metadata-only and fast on modern
  SQL Server. Adding a column **with a non-null default** can rewrite the table on older
  versions / certain types → long Sch-M lock. Check the version.
- Adding a `CHECK`/`FK` constraint scans existing rows to validate → can lock; use
  `WITH NOCHECK` to add untrusted then validate separately if appropriate (note the
  optimizer won't trust an unvalidated constraint).
- Creating an index: `ONLINE = ON` (Enterprise) avoids a long blocking build; on
  Standard, schedule it in a window.
- `DROP`/`RENAME` take Sch-M locks — brief, but they block everything and can deadlock
  with running queries.

## EF Core migrations

- Review the **generated SQL**, not just the C# migration — `Down()` is often
  auto-generated and may not truly restore data (a dropped column's data is gone).
- EF migrations run as one transaction by default; a half-applied migration on failure
  can leave the schema and `__EFMigrationsHistory` out of sync — flag the recovery path.
- For risky restructures, prefer the **expand/contract** pattern (see
  `schema-design.md` §2) split across *several* migrations rather than one destructive
  migration: add new → backfill → switch reads → drop old, each independently
  deployable and reversible.

## Zero-downtime alternatives

- SQL Server: `ALTER ... WITH (ONLINE = ON)`, indexed-view/expand-contract patterns,
  batched backfills (`UPDATE TOP (n) ... loop`) to avoid one giant lock + log blowup.
- Cross-engine (note if relevant): `gh-ost`/`pt-osc` (MySQL), `pg_repack` (PostgreSQL).

## Worked example

```
RISK-DB03 — contract step drops orders.tags after restructure — P4×I5=20 🔴 — Mitigate
At 1.4M rows, the DROP COLUMN takes a Sch-M lock (~Ns) blocking all order access; and
the data is unrecoverable once dropped.
Trigger: running the contract migration. 
Mitigation: confirm nothing reads orders.tags (dual-write window elapsed); take a backup
immediately before; run in the maintenance window; keep the column one release longer.
Contingency: PITR restore to the pre-migration LSN if validation counts don't match.
Validation: SELECT COUNT(*) and per-tag totals from old vs new must match before contract.
```