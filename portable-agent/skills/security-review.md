# Security Review

## Purpose
Audit a system, feature, API, or change for security vulnerabilities and compliance risks. Produce evidence-backed findings with severity, impact, and specific fixes — not generic checklists.

## When to use
Invoke when asked to review security, audit an API, assess auth/access control, check for vulnerabilities, review data handling, or when any change touches authentication, authorization, PII, encryption, or external interfaces.

## Prerequisites
- The system/feature/API to review: source code, architecture docs, endpoint definitions, or configuration.
- Known auth model, data classification, and regulatory requirements (if available).

## Procedure

1. **Read existing context.** Review architecture, requirements, security NFRs, and any prior security findings. Identify the threat boundary being assessed.
2. **Identify the attack surface.** Map:
   - External-facing endpoints, APIs, and data flows.
   - Authentication and authorization boundaries.
   - Trust transitions: where data crosses from untrusted to trusted contexts.
   - Data at rest and in transit.
   - Third-party integrations and dependency chain.
3. **Apply STRIDE per element** (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege):
   - For each trust boundary or external interface, check each STRIDE category.
   - Record findings with specific evidence (code line, config setting, API shape).
4. **Check common vulnerability classes:**
   - Input validation: injection (SQL, XSS, command, path traversal), deserialization.
   - Authentication: brute force, credential storage, session management, token lifecycle.
   - Authorization: privilege escalation, IDOR, missing function-level access control.
   - Data protection: PII exposure, logging sensitive data, encryption at rest/transit.
   - Configuration: default credentials, debug mode, verbose errors, CORS, CSP.
   - Dependencies: known CVEs in direct and transitive dependencies.
5. **Score each finding:**
   - Severity: Critical / High / Medium / Low / Informational.
   - Exploitability: how easy to attack (Remote unauthenticated → Local authenticated).
   - Impact: data breach, service disruption, compliance violation, reputation.
   - Evidence: code reference, configuration line, or observable behavior.
6. **Produce remediation recommendations:**
   - Specific fix for each finding (not "follow OWASP guidelines").
   - Priority order: Critical and High findings first.
   - Distinguish quick fixes from architectural changes.
7. **Compliance check** (if applicable): OWASP Top 10, PCI, SOC2, GDPR/privacy requirements.

## Output contract
- Threat model summary: attack surface, trust boundaries, data flows.
- Findings table: ID | Finding | Severity | Evidence | Impact | Remediation | Status
- Summary: total findings by severity, critical risks requiring immediate attention.
- Compliance status (if applicable).

## Safety and approval gates
- Security review is analysis — do not apply fixes without explicit authorization.
- Do not expose actual secrets, credentials, or PII found during review in the report. Reference by location only.
- Do not weaken existing security controls to fix other issues.
- Flag any finding that requires immediate attention (active exploitation, data exposure).

## Verification
- Every finding has specific evidence, not just a category label.
- Remediation recommendations are implementable, not generic.
- Trust boundaries are identified; STRIDE is applied per boundary, not globally.
- No false positives presented as confirmed; unverified findings are labeled as such.
