# Review and acceptance

Review scope compliance, correctness, edge cases, security, data integrity, compatibility, tests, operational readiness and documentation. Separate findings by severity and include evidence. Acceptance checklist: requirements mapped; expected behavior demonstrated; regression checks; no critical/high unresolved issues; risks acknowledged; rollback path; docs/handover; explicit acceptance status. A same-agent review is not independent QA.


## Adversarial second pass

For material or high-risk work, perform a distinct adversarial pass after the normal requirements/specification and technical review. The second pass assumes the current conclusion may be wrong and probes hidden consumers, authority conflicts, injection, authorization bypass, null/empty/duplicate/boundary cases, concurrency, retries, rollback, stale evidence and simpler alternatives. Record the challenge, evidence checked, findings and unresolved uncertainty.

This is a review mode, not a second copy of the code-review skill. Use an independent agent/runtime only when it is actually available and materially useful. If the same model performs both passes, label the second pass **self-adversarial**, not independent. Never claim an independent reviewer ran when no separate reviewer executed the work.
