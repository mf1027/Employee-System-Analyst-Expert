# Skill: nfr-review

## Purpose
Run a dedicated Non-Functional Requirements pass — elicit and document performance,
security, compliance, availability, scalability, and maintainability targets before
solution design begins. NFRs are the requirements most often skipped and most expensive
to retrofit into an existing design.

## Trigger
Invoke when the operator says "NFR review", "non-functional requirements",
"what are the quality attributes", "performance requirements", "compliance check",
"what are the system constraints", or at the end of any DISCOVER session when
NFRs haven't been fully covered.

## Minimum context required
- A project name and client
- At least a rough functional scope to reason about NFR relevance
If missing: ask for the project and a one-line scope description.

---

## NFR Categories (probe all 7 every time)

| # | Category | Key questions |
|---|---|---|
| 1 | **Performance** | Response time target (P50/P95/P99)? Throughput (users/TPS/batch)? Processing windows? |
| 2 | **Availability** | Uptime SLA (99.9% / 99.99%)? Maintenance windows acceptable? RTO after failure? |
| 3 | **Scalability** | Expected users at launch vs 1 year? Peak traffic events? Data volume growth rate? |
| 4 | **Security** | Authentication method? Data classification (PII/sensitive)? Encryption at rest/transit? Audit logging required? |
| 5 | **Compliance** | Regulatory frameworks in scope? (GDPR, HIPAA, SOX, PCI-DSS) Data residency requirements? |
| 6 | **Maintainability** | Deployment frequency? Target environment (cloud/on-prem/hybrid)? Who operates it post-launch? |
| 7 | **Usability** | Accessibility standard (WCAG 2.1 AA)? Browser/device targets? Language/locale support? |

---

## Steps

1. Read `memory/clients/[client-name].md` — domain, known constraints, compliance context.
2. Review current canonical Obsidian/project memory and existing project NFR records; do not invoke claude-mem.
3. Read the project's `requirements.md` — scan existing functional requirements for implied NFRs.
4. Work through all 7 categories. Ask the key questions for each.
   Skip a category ONLY if provably irrelevant — state the reason explicitly.
5. Assign each NFR a `REQ-NF` ID (next available from `requirements.md`).
6. Map each NFR to a **concrete, measurable target** — no vague adjectives
   ("fast", "secure", "scalable" are not requirements).
7. Flag any NFR that is **design-forcing** — forces an architecture choice, compliance
   constraint, or platform decision. These are hard constraints for solution-design.
8. Output. Wait for confirmation before writing to `requirements.md`.

---

## Output format

```
NFR REVIEW: [Project Name]
Client: [name] | Date: [YYYY-MM-DD]
---
Context: I read [files]. Implied NFRs from existing requirements: [list or "none"].
Prior NFR entries in canonical project records: [N or source unavailable].

Non-Functional Requirements:
| ID | Category | Requirement | Target | Impact | Source |
|---|---|---|---|---|---|
| REQ-NF01 | Performance | Response time | < 2s P95 | Medium | Sponsor |
| REQ-NF02 | Availability | Uptime SLA | 99.9% (< 8.7h/year) | High | Contract |
| REQ-NF03 | Security | Authentication | MFA required for admin | High | Compliance |
| REQ-NF04 | Compliance | GDPR | PII stored in EU only | Architecture | Legal |
| REQ-NF05 | Scalability | Concurrent users | 500 launch; 2,000 year 1 | Medium | Estimate |
| REQ-NF06 | Maintainability | Deployment | CI/CD; weekly release cadence | Low | DevOps |
| REQ-NF07 | Usability | Accessibility | WCAG 2.1 AA | Low | UX brief |

Skipped categories:
- [Category] — Reason: [why it doesn't apply]

Design-forcing NFRs (hard constraints for solution-design):
- REQ-NF04: GDPR residency → EU cloud region required; affects vendor and platform selection
- REQ-NF02: 99.9% uptime → HA design required (multi-AZ minimum; health checks; failover)

Open questions:
1. [Unanswered NFR question — blocking REQ-NF0X if unresolved]

Next: confirm → write to requirements.md → feed design-forcing NFRs to solution-design as hard constraints
```

---

## Quality checklist

- [ ] Were all 7 categories probed — or explicitly ruled out with a stated reason?
- [ ] Is every target measurable — no vague adjectives?
- [ ] Are design-forcing NFRs flagged and called out separately?
- [ ] Are compliance frameworks confirmed (not assumed)?
- [ ] Does every REQ-NF have a source stakeholder or document?

## Failure exit
"Cannot run an NFR review without a project and scope. Provide the project name
and a one-line description of what is being built."
