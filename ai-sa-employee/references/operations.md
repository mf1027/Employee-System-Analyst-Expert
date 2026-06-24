# Playbook: FinOps, Security & HA/DR

Three operational lenses in one file — read the section you need. These were thin or
missing in the original skill; each now has a concrete procedure.

## Table of contents
1. FinOps — cloud database cost
2. Security hardening & compliance
3. HA/DR design
4. Worked examples

---

## 1. FinOps — cloud database cost

Use when the operator asks about database cost, right-sizing, or platform comparison.

Procedure:
1. **Establish the bill drivers** — instance/compute size, storage volume + tier, IOPS,
   backup storage, data egress, and licensing (SQL Server licensing is often the biggest
   line — consider whether the workload fits a license-included managed tier vs BYOL).
2. **Right-size compute** — compare provisioned vCPU/RAM against actual utilization
   (CPU, memory, connections). Flag chronically <20% utilized instances and burstable
   candidates. Note the risk of right-sizing too aggressively (no headroom for spikes).
3. **Tier storage** — move cold data / old backups to cheaper tiers; check that
   provisioned IOPS aren't over-bought.
4. **Commit where stable** — reserved instances / savings plans / committed-use
   discounts for steady baseline load; keep on-demand only for variable headroom.
5. **Cut waste** — idle dev/test instances left running, orphaned snapshots, over-frequent
   backups beyond the retention NFR, multi-AZ on non-critical environments.
6. **Quantify.** Every cost rec states current $/mo → projected $/mo and the risk traded
   (e.g. "single-AZ on staging saves ~$X/mo, accepts longer staging recovery").

Frame as REC- entries with the dollar delta; frame any availability trade as a RISK-.

---

## 2. Security hardening & compliance

Use for RBAC, encryption, PII handling, audit, and regulatory checks (HIPAA, PCI-DSS,
SOX, GDPR data residency).

Checklist:
- **Least privilege / RBAC** — app accounts scoped to the minimum (no `db_owner`/`sa`
  for app logins); separate accounts for app vs migration vs reporting. Flag any shared
  or over-privileged account as a RISK-DB (type: Security).
- **Encryption in transit** — TLS enforced on connections (`Encrypt=True`); reject
  unencrypted.
- **Encryption at rest** — TDE (SQL Server) or the cloud-managed equivalent; check key
  management and rotation. Required wherever PII/regulated data lives.
- **PII inventory** — identify the columns (cross-ref `schema-design.md` §7); map each to
  its regulation. GDPR adds data-residency and right-to-erasure design implications.
- **Audit trail** — login auditing and DML auditing on sensitive tables (SQL Server
  Audit / temporal tables). SOX/HIPAA need a tamper-evident trail.
- **Secrets** — connection strings/keys in a vault, not in source or config files. A
  hardcoded credential is a RED RISK- on sight.
- **Patch level** — engine on a supported, patched version; flag end-of-life versions.

Map findings to the specific regulation the project's `requirements.md` names — don't
cite a framework the project isn't subject to.

---

## 3. HA/DR design

Use for availability, recovery, replication, and backup strategy.

Procedure:
1. **Get the targets from NFRs.** **RPO** (max acceptable data loss, in time) and **RTO**
   (max acceptable downtime). If the project hasn't stated them, that gap is itself a
   RISK- — you can't design HA/DR to an unstated target.
2. **Assess current posture vs targets:**
   - Backups: frequency, type (full/diff/log), off-site copy, and — critically — whether
     restores are *tested*. An untested backup is not a backup; flag it.
   - PITR: is log backup frequency tight enough to meet RPO?
   - Replication: standalone / Always On AG / read replicas / multi-region — and does the
     failover meet RTO (automatic vs manual, DNS/connection-string cutover time)?
3. **Recommend the minimum pattern** that meets the stated availability NFR — don't
   over-build (multi-region active-active for a back-office app is wasted cost; see
   FinOps).
4. **Flag the gaps** as RISK- with the concrete failure scenario: "single instance, no
   automatic failover → an AZ outage is a full outage until manual restore (~X hr) — RTO
   target is Y hr."

---

## 4. Worked examples

**FinOps:**
```
REC-DB08 — right-size prod from db.r5.2xlarge to db.r5.xlarge — High
30-day avg CPU 14%, peak 41%, memory 38% → one size down keeps headroom.
Impact: ~$X,XXX/mo → ~$X,XXX/mo (~45% compute saving). Risk: re-check after quarter-close peak.
```

**Security:**
```
RISK-DB09 — app login has db_owner on the client database — P3×I5=15 🔴 — Mitigate
A compromised app account could drop/exfiltrate all client data (PII present).
Trigger: any app credential leak. Mitigation: create a scoped role (CRUD on app schema only),
move migrations to a separate elevated account run only by CI. Contingency: rotate + audit on incident.
```

**HA/DR:**
```
RISK-DB10 — no tested restore; backups exist but never recovered — P2×I5=10 🟡 — Mitigate
Backups run nightly but no restore has ever been validated → unknown actual RTO.
Mitigation: quarterly restore drill to a scratch instance; document measured RTO vs the 4h target.
```