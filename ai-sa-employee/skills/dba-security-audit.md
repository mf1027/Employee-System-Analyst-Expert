---
name: dba-security-audit
description: >-
  Structured database security audit — PII column detection, encryption at rest
  and in transit, permission/role mapping, audit trail completeness, connection
  security, and compliance gap analysis (GDPR, HIPAA, PCI-DSS, DPA 2012).
  Produces a scored findings report with concrete remediation actions. Use this
  skill when the operator mentions database security, PII, encryption, permissions,
  compliance, audit trail, or when onboarding a new client with regulatory requirements.
---

# dba-security-audit

Systematically checks database security across 8 dimensions. The output is a scored
checklist — not a pass/fail — because security is contextual: a development database
has different requirements than a production system handling PII.

Engine-aware: defaults to SQL Server. Adapts to PostgreSQL (pg_hba.conf, row-level
security), MySQL (mysql.user, GRANT), cloud-managed (IAM, VPC, encryption options).

---

## Trigger

Invoke when:
- The operator mentions "security review", "PII", "encryption", "permissions", "compliance"
- Onboarding a new client with regulatory requirements
- Before a production deployment
- After a schema change that adds columns storing personal or sensitive data
- During a periodic security review

---

## Audit dimensions

### 1. PII column detection

Scan the schema for columns that likely contain Personally Identifiable Information:

| PII type | Column name patterns | Risk |
|---|---|---|
| Names | `*Name*`, `*FirstName*`, `*LastName*`, `*FullName*` | Medium — identify individuals |
| Email | `*Email*`, `*EmailAdd*` | High — direct identifier |
| Phone | `*Phone*`, `*Mobile*`, `*Contact*` | High — direct identifier |
| Address | `*Address*`, `*Street*`, `*City*` (in person context) | Medium |
| Government ID | `*SSN*`, `*TIN*`, `*NationalId*`, `*Passport*` | Critical — regulated |
| Financial | `*AccountNo*`, `*CardNumber*`, `*BankAccount*` | Critical — PCI-DSS |
| Auth | `*Password*`, `*Pass*`, `*Hash*`, `*Token*`, `*Secret*` | Critical — credential |
| IP/Device | `*IpAddress*`, `*HostName*`, `*DeviceId*` | Low-Medium |
| Biometric | `*Fingerprint*`, `*FaceId*` | Critical — special category |

**For each PII column found:**
- State the table.column and PII type
- Check: is it encrypted? (column-level encryption, Always Encrypted, TDE)
- Check: is access restricted? (view/SP abstraction, column-level permissions)
- Check: is it logged when accessed? (audit trail)
- Recommend: encrypt, mask, or restrict as appropriate

### 2. Encryption at rest

| Check | SQL Server | PostgreSQL | Cloud managed |
|---|---|---|---|
| TDE enabled? | `SELECT * FROM sys.dm_database_encryption_keys` | `pgcrypto` extension or disk-level | AWS RDS: KMS, Azure: service-managed keys |
| Column-level encryption? | Always Encrypted, `ENCRYPTBYKEY()` | `pgcrypto` functions | Same |
| Backup encryption? | `BACKUP DATABASE ... WITH ENCRYPTION` | `pg_basebackup` + gpg | Managed by cloud provider |
| tempdb encryption? | TDE covers tempdb in SQL Server 2019+ | N/A | N/A |

### 3. Encryption in transit

| Check | What to verify |
|---|---|
| SSL/TLS enabled | Connection string requires `Encrypt=True` / `sslmode=require` |
| Certificate valid | Not self-signed in production |
| Minimum TLS version | TLS 1.2+ (TLS 1.0/1.1 deprecated) |
| Force encryption | Server configured to reject unencrypted connections |

### 4. Permission / role mapping

Audit who has access to what:

```sql
-- SQL Server: database-level permissions
SELECT  dp.name AS Principal, dp.type_desc,
        perm.permission_name, perm.state_desc,
        OBJECT_NAME(perm.major_id) AS ObjectName
FROM    sys.database_permissions perm
JOIN    sys.database_principals dp ON perm.grantee_principal_id = dp.principal_id
WHERE   dp.name NOT IN ('public', 'guest', 'INFORMATION_SCHEMA', 'sys')
ORDER BY dp.name, OBJECT_NAME(perm.major_id);

-- SQL Server: server-level role membership
SELECT  srl.name AS RoleName, spm.name AS MemberName
FROM    sys.server_role_members srm
JOIN    sys.server_principals srl ON srm.role_principal_id = srl.principal_id
JOIN    sys.server_principals spm ON srm.member_principal_id = spm.principal_id;
```

**Check for:**
- `db_owner` or `sysadmin` granted to application accounts (should use least privilege)
- Direct table access from application (should use views/SPs as abstraction layer)
- `sa` account enabled with default password
- Orphaned users (exist in DB but not at server level)
- Guest account enabled

### 5. Audit trail completeness

| Check | What to verify |
|---|---|
| CreatedBy/CreatedDate on all tables | Every user-facing table has audit columns |
| UpdatedBy/UpdatedDate where edits are possible | Tables with UPDATE operations have edit audit |
| Transaction log exists | Centralized log (tTransactionLog or equivalent) captures all changes |
| Log covers all operations | INSERT, UPDATE, DELETE all logged — not just CREATEs |
| Log is append-only | No UPDATE/DELETE on the log table itself |
| Log includes old + new values | For UPDATE operations, both values stored |
| Sensitive access logged | Access to PII columns or views logged |

### 6. SQL injection surface

| Check | What to verify |
|---|---|
| Parameterized queries | Application uses parameterized queries (EF Core, Dapper `@param`) — not string concatenation |
| Dynamic SQL in SPs | Any `EXEC(@sql)` or `sp_executesql` — is input sanitized? |
| QUOTENAME usage | Dynamic object names wrapped in `QUOTENAME()` |
| Input validation | Application validates input before passing to DB |

### 7. Backup and recovery security

| Check | What to verify |
|---|---|
| Backups encrypted | Production backups are encrypted |
| Backup access restricted | Only authorized roles can access backup files |
| Restore tested | Backups have been tested for restorability |
| Point-in-time recovery | Transaction log backups enable PITR |
| Backup retention | Retention policy meets compliance requirements |

### 8. Compliance alignment

For each applicable regulation, check:

| Regulation | Key DB requirements |
|---|---|
| **GDPR / DPA 2012** | Right to erasure (can PII be deleted?), data minimization (only necessary PII stored), consent tracking, breach notification |
| **HIPAA** | PHI encrypted at rest and in transit, access controls, audit logs for PHI access |
| **PCI-DSS** | Cardholder data encrypted, access restricted, audit trail, no storage of CVV/PIN |
| **SOX** | Financial data integrity, change controls, audit trail |
| **PDPA (Philippines)** | Similar to GDPR — PII protection, consent, breach notification, NPC registration |

---

## Output format

```
DATABASE SECURITY AUDIT: [Database]
Client: [name] | Project: [name] | Engine: [engine] | Date: [YYYY-MM-DD]
Regulations: [applicable: GDPR, HIPAA, PCI-DSS, PDPA, or N/A]
---

DIMENSION SCORES:
| # | Dimension | Score | Findings | Critical |
|---|-----------|-------|----------|----------|
| 1 | PII Detection | 🔴/🟡/🟢 | N | N |
| 2 | Encryption at Rest | 🔴/🟡/🟢 | N | N |
| 3 | Encryption in Transit | 🔴/🟡/🟢 | N | N |
| 4 | Permissions | 🔴/🟡/🟢 | N | N |
| 5 | Audit Trail | 🔴/🟡/🟢 | N | N |
| 6 | SQL Injection | 🔴/🟡/🟢 | N | N |
| 7 | Backup Security | 🔴/🟡/🟢 | N | N |
| 8 | Compliance | 🔴/🟡/🟢 | N | N |

PII INVENTORY:
| Table | Column | PII Type | Encrypted | Access Restricted | Logged |
|-------|--------|----------|-----------|-------------------|--------|

FINDINGS:
[SEC-001] [Critical/High/Medium/Low] ...

REMEDIATION PLAN:
| # | Finding | Action | Priority | Effort |
|---|---------|--------|----------|--------|
```

Scoring: 🔴 = critical gaps found, 🟡 = medium gaps or partial implementation,
🟢 = no significant gaps found.

---

## Rules

1. **Context matters.** A dev database doesn't need production-grade encryption.
   State the environment (dev/staging/production) and calibrate findings accordingly.
2. **PII is broader than you think.** IP addresses, login timestamps, and device IDs
   can be PII under GDPR. When in doubt, flag it.
3. **Least privilege.** Application accounts should have minimum necessary permissions.
   `db_owner` for an application is always a finding.
4. **Audit trails are non-negotiable.** Every user-facing data change must be traceable
   to a user and timestamp.
5. **Never store plaintext credentials.** Passwords, API keys, tokens — all must be
   hashed or encrypted. Finding plaintext credentials is always Critical.
6. **Backup = copy of all data.** An unencrypted backup of an encrypted database
   defeats the encryption.

---

## Quality checklist

- [ ] All 8 dimensions checked
- [ ] PII columns inventoried with encryption/access/logging status
- [ ] Permissions mapped (no blind spots)
- [ ] Applicable regulations identified and checked
- [ ] Critical findings have remediation actions with priority
- [ ] Environment stated (dev/staging/production)
- [ ] Engine-specific checks applied (not generic)
- [ ] No plaintext credentials in any finding or recommendation

## Failure exit

"Cannot perform a security audit without access to the database schema and ideally
the live database. Provide the schema files (or a DB connection) and state the
environment (dev/staging/production) and applicable regulations."
