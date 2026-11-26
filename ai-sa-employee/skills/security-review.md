# Skill: security-review

## Purpose
Conduct a structured security requirements review — threat modelling, PII mapping,
compliance gap identification, and control recommendations. Produces a security
requirements set (REQ-S) and a risk register (RISK-SEC) for the project.

## Trigger
Invoke when the operator says "security review", "threat model", "STRIDE", "PII",
"GDPR", "HIPAA", "compliance", "auth review", "what are the security risks",
or any time a system handles user data, payments, or regulated information.
Also invoke proactively from DESIGN mode whenever an auth, PII, or integration
component is identified.

## Minimum context required
- System description or architecture overview (C4 L1/L2 or equivalent)
- The client / project and industry (to determine applicable regulations)
If missing: ask for system description and data types handled.

---

## Mode

Select at session start:
- **Daily** (default) — Confidence gate ≥ 8/10. Report only findings you can substantiate with a quoted evidence path. Zero noise.
- **Comprehensive** — Confidence gate ≥ 2/10. Surface all potential issues. Mark uncertain findings `[TENTATIVE]`.

Default to **Daily** if not specified.

---

## Steps

1. Review current canonical Obsidian/project memory and the relevant client lane for prior security decisions. Do not invoke the disabled claude-mem integration.
2. Read the project's `requirements.md` and `decisions.md`.

3. **Identify the attack surface.** List every entry point:
   - User-facing interfaces (web, mobile, API)
   - Internal services and integrations
   - Data stores and queues
   - Admin / ops access paths

4. **PII and sensitive data map.** For each data entity:
   - What data is collected? (name, email, payment, health, biometric, etc.)
   - Where is it stored? (DB, cache, logs, backups)
   - Who can access it? (roles, services, third parties)
   - What regulation applies? (GDPR, HIPAA, PCI-DSS, PDPA, local law)

   Classify each entity against these tiers:
   | Tier | Definition | Examples |
   |---|---|---|
   | RESTRICTED | Breach = legal liability | Passwords, payment data, PII (name+email+ID), health records, biometrics |
   | CONFIDENTIAL | Breach = business damage | API keys, session tokens, business rules, user behaviour analytics |
   | INTERNAL | Breach = embarrassment | Logs, config, error messages, internal tool access |
   | PUBLIC | No harm if disclosed | Marketing content, public documentation |

5. **STRIDE threat model.** For each major component, evaluate:
   | Threat | Question |
   |---|---|
   | **S**poofing | Can an attacker impersonate a user or service? |
   | **T**ampering | Can data be modified in transit or at rest? |
   | **R**epudiation | Can actions be denied — is there an audit trail? |
   | **I**nformation disclosure | Can sensitive data leak? |
   | **D**enial of service | Can the system be made unavailable? |
   | **E**levation of privilege | Can a low-privilege user gain higher access? |

6. **Compliance gap check.** For each applicable regulation:
   - GDPR: consent, right to erasure, data minimisation, breach notification (72h)
   - HIPAA: PHI encryption at rest + in transit, audit logs, BAA with vendors
   - PCI-DSS: cardholder data scope, tokenisation, network segmentation
   - PDPA / local: identify jurisdiction and document applicable obligations

6a. **LLM/AI security audit** (apply if the system includes any AI/LLM component):
   | Vector | Check |
   |---|---|
   | Prompt injection | Is user input flowing into system prompts without sanitisation? |
   | Unsanitised output | Is LLM-generated text rendered as HTML without encoding? |
   | Tool call validation | Are tool/function call arguments validated before execution? |
   | Output eval | Is any LLM output passed to `eval()` or executed as code? |
   | RAG poisoning | Are external documents indexed for RAG without content validation? |
   | API key exposure | Is the AI model endpoint or key accessible client-side? |
   | Cost amplification | Can an attacker trigger unlimited LLM calls (DoS via cost)? |

7. **Generate security requirements** (REQ-S prefix) for each identified control:
   - Authentication & authorisation (MFA, RBAC, session management)
   - Encryption (at rest, in transit, key management)
   - Input validation and output encoding (prevent injection, XSS)
   - Audit logging and monitoring
   - Incident response and breach notification obligations

8. **Flag RISK-SEC entries** for each unmitigated threat or compliance gap.

8a. **Confidence scoring and FP filtering.** Before including any finding in the report:
   - Assign a confidence score (1–10). You must be able to quote the specific component, data flow, or architecture path that creates the vulnerability.
   - Daily mode: score ≥ 8 → include. Below 8 → discard.
   - Comprehensive mode: score ≥ 2 → include. Score < 8 → mark `[TENTATIVE]`.

   **Hard exclusion rules — never report regardless of mode:**
   - No DoS/rate-limiting findings unless the vector enables LLM cost amplification or data exfiltration
   - No theoretical risks without a realistic exploit path in this specific architecture
   - No findings in test fixtures, seed data, mock files, or example code
   - No findings for framework defaults that are secure by default (React escapes HTML, ORMs parameterise queries, HTTPS-only cookies in production configs)
   - No "upgrade to latest version" findings without a specific CVE applicable to this project's exact version and deployment
   - No missing security headers for internal-only systems with no public exposure
   - No findings whose only remediation is adding a comment to document the risk

9. Output. Wait for confirmation before writing to `requirements.md` or `risks.md`.

---

## Output format

```
SECURITY REVIEW: [Project Name]
Client: [name] | Date: [YYYY-MM-DD] | Mode: [Daily / Comprehensive] | Regulations: [GDPR / HIPAA / PCI / none]
---
Attack surface:
- [Entry point 1] — [description]
- [Entry point 2] — ...

PII / sensitive data map:
| Entity | Data collected | Stored where | Access | Classification | Regulation |
|---|---|---|---|---|---|
| [User] | [email, name] | [users table] | [app + admin] | RESTRICTED | GDPR |

STRIDE findings:
| Component | Threat | Finding | Confidence | Control needed |
|---|---|---|---|---|
| [Auth service] | Spoofing | [No MFA enforced] | 9/10 | Require MFA for admin accounts |

LLM/AI findings: [omit section if no AI components present]
| Vector | Finding | Confidence |
|---|---|---|
| [Prompt injection] | [User input concatenated directly into system prompt at /chat endpoint] | [8/10] |

Compliance gaps:
- GDPR: No right-to-erasure endpoint identified — REQ-S-007
- [Other gaps]

Security requirements:
- REQ-S-001: All API endpoints must require bearer token authentication
- REQ-S-002: PII fields must be encrypted at rest using AES-256
- REQ-S-003: All admin actions must be written to an immutable audit log
- [continue REQ-S-NNN sequence]

Security risks:
- RISK-SEC-001: [Unmitigated threat] — Likelihood: [H/M/L] — Impact: [H/M/L]

Next: confirm → write REQ-S entries to requirements.md + RISK-SEC to risks.md
```

---

## Quality checklist

- [ ] Attack surface fully enumerated — every entry point listed?
- [ ] PII map complete — every entity with sensitive data documented?
- [ ] All 6 STRIDE categories evaluated for each major component?
- [ ] Applicable regulations identified and gaps checked?
- [ ] Every finding has a REQ-S or RISK-SEC ID?
- [ ] Recommendations are specific controls, not generic advice?
- [ ] Triple-lens applied: SA (requirements complete), PM (risk logged), DBA (data exposure flagged)?
- [ ] All data entities classified (RESTRICTED / CONFIDENTIAL / INTERNAL / PUBLIC)?
- [ ] LLM/AI vectors checked if any AI component is present?
- [ ] Every finding has a confidence score meeting the mode threshold?
- [ ] Hard exclusion FP rules applied before reporting?

## Failure exit
"Cannot conduct security review without a system description. Provide a component list,
data flow, or architecture overview (C4 L1/L2 minimum)."
