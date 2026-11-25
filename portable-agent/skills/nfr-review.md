# NFR Review

## Purpose
Identify, classify, and assess non-functional requirements (NFRs) — performance, scalability, security, reliability, maintainability, accessibility, and compliance — and flag design-forcing NFRs that constrain architecture decisions.

## When to use
Invoke when asked to review NFRs, assess quality attributes, check performance/scalability/reliability requirements, or during requirements analysis to separate functional from non-functional concerns. Also invoke when architecture decisions need NFR constraints identified.

## Prerequisites
- Existing requirements or system description.
- Known user base size, SLA targets, or compliance obligations (if available).

## Procedure

1. **Read context.** Review requirements, architecture, and existing NFR documentation.
2. **Extract implicit NFRs.** Scan functional requirements for hidden non-functional expectations:
   - "Fast" / "responsive" → performance requirement (quantify).
   - "Always available" → reliability/availability requirement (define SLA).
   - "Secure" → identify specific security requirements.
   - "Scalable" → define expected growth and capacity needs.
3. **Classify each NFR** using ISO 25010 quality model categories:
   - **Performance:** response time, throughput, resource utilization.
   - **Reliability:** availability, fault tolerance, recoverability, MTBF/MTTR.
   - **Security:** confidentiality, integrity, authentication, authorization, accountability.
   - **Maintainability:** modularity, reusability, analyzability, modifiability, testability.
   - **Compatibility:** interoperability, co-existence.
   - **Usability:** learnability, operability, accessibility, error protection.
   - **Portability:** adaptability, installability, replaceability.
   - **Scalability:** horizontal/vertical capacity, load characteristics.
4. **Quantify each NFR.** Replace vague terms with measurable targets:
   - ❌ "The system should be fast" → ✅ "Page load < 2s at p95 under 500 concurrent users."
   - ❌ "Highly available" → ✅ "99.9% uptime measured monthly, excluding planned maintenance."
5. **Identify design-forcing NFRs** — those that constrain architecture:
   - NFRs that eliminate design options (e.g., sub-100ms response eliminates synchronous external calls).
   - NFRs that require specific capability (e.g., GDPR data residency requires regional deployment).
   - Mark as DESIGN-FORCING in the output.
6. **Assess testability.** For each NFR, define how it will be verified (load test, penetration test, audit, monitoring, code review).
7. **Flag gaps:** NFRs that are mentioned but unquantified, or common categories with no coverage at all.

## Output contract
- NFR register: ID | Category | Description | Measurable Target | Design-Forcing? | Test Method | Status
- Gaps summary: missing categories, unquantified requirements.
- Design-forcing NFR list for architecture decision input.

## Safety and approval gates
- NFR review is analysis — do not modify requirements without authorization.
- Do not fabricate SLA numbers; if targets are unknown, flag as TBD with the question to ask.
- Flag NFRs with compliance implications (GDPR, PCI, SOC2, accessibility standards).

## Verification
- Every NFR has a measurable target or is explicitly flagged as TBD with a follow-up question.
- Design-forcing NFRs are identified with reasoning.
- Common categories (performance, security, reliability) are assessed even if not mentioned.
