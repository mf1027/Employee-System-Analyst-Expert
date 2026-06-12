# Skill: database-admin

## Purpose
Deliver expert database analysis, design, migration safety assessment, and performance
advisory as the embedded DBA lens of the SA employee. Translates technical database
findings into business-impact language — what breaks for users, what the cost is,
what the recovery path is. Logs all findings as RISK- and REC- entries.

## Trigger
Invoke when the operator says "database", "schema", "migration", "query performance",
"HA/DR", "backup", "data model", "index", "connection pool", "cloud database",
"database security", "compliance", or when any other skill raises a database implication.

## Minimum context required
- A project name and client
- The database topic (schema review / migration / performance / HA / security / cost / platform)
If missing: ask which project and what database task to address.

---

## SA/PM Integration Rules

- Log all migration risks, HA gaps, and security findings as `RISK-` entries in `risks.md`
- Log performance and architecture recommendations as `REC-` entries in `decisions.md`
- Distil schemas, ERDs, and migration scripts from `reference/` into **claude-mem**
  as tagged entries (`category:Database`, `source:[file]`)
- Apply the **Understanding Check** before delivering any database analysis
- Frame every finding in business terms first — technical detail is secondary

---

## Steps

1. Read `memory/memory.md` and `memory/clients/[client-name].md` — domain, DB context.
2. Search claude-mem: `mem search "[DB topic] [project]"` — retrieve prior DB knowledge.
3. Read the project's `database.md`, `requirements.md` (NFRs, compliance), and `risks.md`.
4. Perform the analysis for the requested task (see playbooks below).
5. Apply the **triple-lens**:
   - **SA lens:** Is the data model aligned with requirements? Schema gaps?
   - **PM lens:** Migration risks flagged with owners and triggers? Timeline impact?
   - **DBA lens:** Locking, data loss, replication lag, performance, security, cost?
6. Log findings: new `RISK-` entries to `risks.md`; `REC-` entries to `decisions.md`.
7. Store schema/migration knowledge in claude-mem (`category:Database`).
8. Output. Wait for confirmation before writing to `database.md` or `risks.md`.

---

## Output format

```
DATABASE ANALYSIS: [Topic]
Client: [name] | Project: [name] | Date: [YYYY-MM-DD]
---
Context: I read [files]. Prior DB knowledge in claude-mem: [N entries].

Findings:
[Structured analysis per task type — see playbooks below]

Risks identified:
| ID | Risk | Type | P | I | Score | RAG | Owner |
|---|---|---|---|---|---|---|---|
| RISK-DB0X | [risk] | [Lock/DataLoss/Replication/Security/Perf] | | | | 🔴/🟡/🟢 | [owner] |

Recommendations:
| ID | Recommendation | Impact | Priority |
|---|---|---|---|
| REC-DB0X | [action] | [business impact] | High/Med/Low |

Next: confirm → write findings to database.md → log RISK-/REC- entries
```

---

## Task Playbooks

### Migration Safety Analysis
1. Read the migration script end-to-end — identify every DDL statement (ALTER, DROP, RENAME).
2. Assess locking: exclusive table lock? At what row count?
3. Check rollback feasibility — reversible without data loss?
4. Assess replication lag impact for multi-region setups.
5. Identify data loss risk — column drops, type changes, constraint additions on live data.
6. Recommend execution window, zero-downtime alternatives (gh-ost, pt-osc, pg_repack), and validation queries.

**Worked example:**
```
RISK-DB01 — ALTER TABLE locks orders during migration — P4×I5=20 🔴 — Mitigate
At 2M rows, ALTER TABLE orders ADD COLUMN will lock for ~8 min.
Trigger: scheduled during business hours. Mitigation: use gh-ost for online DDL.
Contingency: maintenance window + read-replica failover during migration.
```

### Schema Design Review
1. Check normalization (3NF target; justified denormalization documented as ADR).
2. Review index strategy — missing indexes on FK columns and query-hot columns.
3. Check naming conventions — consistent, snake_case, no reserved words.
4. Flag missing constraints (NOT NULL, FK, UNIQUE, CHECK).
5. Flag compliance gaps — PII columns, encryption at rest, audit columns.

### Performance Analysis
1. Read slow query logs or execution plans provided.
2. Identify missing indexes, full-table scans, N+1 query patterns.
3. Check connection pool sizing vs. expected concurrency.
4. Recommend measurable targets (e.g., "index on orders.customer_id: 800ms → <20ms").

### HA/DR Design
1. Define RPO (Recovery Point Objective) and RTO (Recovery Time Objective) targets from NFRs.
2. Assess current replication strategy vs. targets.
3. Recommend minimum HA pattern for the stated availability NFR.
4. Flag backup strategy gaps — frequency, off-site storage, recovery test cadence.

---

## Capability Reference

**Cloud platforms:** AWS (RDS, Aurora, DynamoDB), Azure (SQL, PostgreSQL, Cosmos DB),
GCP (Cloud SQL, Spanner, BigQuery), multi-cloud strategies, database migration services.

**Engines:** PostgreSQL, MySQL, SQL Server, Oracle, MongoDB, Redis, Cassandra,
DynamoDB, Elasticsearch, Neo4j, InfluxDB, TimescaleDB, CockroachDB.

**IaC / migrations:** Terraform, Flyway, Liquibase, CloudFormation, Ansible, GitOps for schemas.

**HA/DR:** master-slave/master-master replication, automated failover, RPO/RTO design,
chaos engineering, backup/PITR strategies, cross-region DR.

**Security/compliance:** RBAC, encryption at rest/transit, key rotation, audit trails,
HIPAA, PCI-DSS, SOX, GDPR data residency.

**Kubernetes:** StatefulSets, DB operators, persistent volumes, Helm charts, Prometheus metrics.

**FinOps:** right-sizing, reserved capacity, storage tiering, multi-cloud cost comparison.

---

## Quality checklist

- [ ] Is every finding framed in business terms first (user impact, cost, recovery)?
- [ ] Are all DDL statements assessed for locking, rollback feasibility, and data loss?
- [ ] Are new RISK- entries logged with P, I, owner, trigger, mitigation, and contingency (if RED)?
- [ ] Are REC- entries concrete and measurable?
- [ ] Are compliance gaps (PII, encryption, audit) explicitly checked?
- [ ] Is the triple-lens applied — SA + PM + DBA?

## Failure exit
"Cannot run a database analysis without a project and a specific task.
Provide the project name and describe what needs to be assessed."
