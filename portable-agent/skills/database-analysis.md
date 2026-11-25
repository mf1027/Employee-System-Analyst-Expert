# Database Analysis

## Purpose
Analyse database schema, queries, stored procedures, views, and data models for correctness, performance, security, and migration safety. Frame findings in business terms first — what breaks for users, what it costs — then provide technical detail.

## When to use
Invoke when asked about database design, schema review, query performance, migration planning, normalization, data model assessment, stored procedures, or when any change touches database objects, queries, or data integrity.

## Prerequisites
- Access to the schema, queries, or database objects being analysed.
- Knowledge of the database engine (default assumption: SQL Server; adjust for PostgreSQL, MySQL, Oracle if specified).
- Existing ERD, data dictionary, or migration history (if available).

## Procedure

1. **Read existing context.** Review schema documentation, ERD, migration history, known issues, and relevant requirements.
2. **Schema analysis:**
   a. Map tables, columns, types, nullability, defaults, and constraints.
   b. Check primary keys: every table should have one; identify missing PKs.
   c. Check foreign keys: referential integrity, cascade behavior, orphan risk.
   d. Identify indexes: covering indexes for common queries, missing indexes for frequent JOINs/WHEREs.
   e. Check normalization: identify 1NF/2NF/3NF violations with business impact.
   f. Check naming conventions: consistency, clarity, engine-appropriate casing.
3. **Query/procedure analysis:**
   a. Review execution plan (actual, not estimated where possible).
   b. Identify full table scans, implicit conversions, missing index hints.
   c. Check for N+1 patterns, cursor abuse, unnecessary DISTINCT/ORDER BY.
   d. Assess parameter sniffing risks in stored procedures.
   e. Check transaction scope: too wide (blocking), too narrow (inconsistency).
4. **Data integrity assessment:**
   a. Check constraints: NOT NULL, CHECK, UNIQUE, DEFAULT where business rules require them.
   b. Identify columns that allow invalid state (nullable FK, unchecked status values).
   c. Assess temporal consistency: audit columns (created/modified), soft delete patterns.
5. **Migration safety assessment:**
   a. Classify change: additive (safe) vs destructive (requires planning).
   b. Identify locking impact: ALTER TABLE on large tables, index rebuilds.
   c. Assess rollback strategy: can the migration be reversed?
   d. Estimate downtime (if any) and data volume impact.
   e. Check for existing data that violates new constraints.
6. **Security check:**
   a. PII/sensitive data: identified, encrypted at rest, masked in non-production.
   b. Permissions: least privilege, no direct table access from application (use procedures/views).
   c. Dynamic SQL: parameterised or injection-safe.
   d. Audit trail: changes to sensitive data are logged.
7. **Performance baseline:**
   a. Table sizes, row counts, growth projections.
   b. Query frequency and response time expectations.
   c. Index fragmentation and maintenance schedule.

## Output contract
- Schema findings table: Table | Finding | Severity | Business Impact | Recommendation
- Query/procedure findings with execution plan evidence where available.
- Migration risk assessment (if applicable).
- Security findings (if applicable).
- Prioritised recommendations.

## Safety and approval gates
- Database analysis is analysis — do not execute DDL, DML, or schema changes without authorization.
- Never invent schema objects, columns, or relationships that are not in the actual database.
- Never run UPDATE/DELETE/DROP in production without explicit authorization and rollback plan.
- Verify the real schema before recommending changes. Read the actual objects, not memory.

## Verification
- Findings reference actual schema objects (table names, column names, constraint names).
- Performance findings are supported by execution plan evidence or measurable metrics.
- Migration recommendations include rollback strategy.
- Business impact is stated for every finding above Low severity.
