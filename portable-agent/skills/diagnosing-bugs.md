# Diagnosing Bugs

## Purpose
Systematically diagnose defects through root cause analysis — reproduce, trace, form hypotheses, test them against evidence, and propose the smallest correction that addresses the actual cause, not just the symptom.

## When to use
Invoke when asked to debug, diagnose, fix a bug, investigate an error, root-cause an incident, or when a test fails unexpectedly. Also invoke automatically when any implementation discovery reveals unexpected behavior.

## Prerequisites
- A description of the defect: expected vs actual behavior.
- Access to the code, logs, data, or system showing the problem.
- Reproduction steps (if known) or conditions under which the defect occurs.

## Procedure

1. **Tier the investigation** — depth scales with impact:
   - **FULL:** Schema/DDL, multi-file, auth/data-integrity, financial, cross-system. Full RCA + adversarial review.
   - **ABBREVIATED:** Single-file, scoped, reversible. RCA + one adversarial pass.
   - **SKIP:** Read-only lookups, obvious typos. Fix directly, state the cause.
   State the tier in one line before proceeding.

2. **Establish the facts:**
   a. Expected behavior (from requirements, tests, or documentation).
   b. Actual behavior (observed output, error message, incorrect state).
   c. Conditions: when does it happen? Always, sometimes, under specific input?
   d. Timeline: when did it start? What changed?

3. **Reproduce.** Attempt to reproduce the defect with the smallest possible input. If reproduction is not possible, state what was attempted and work from available evidence (logs, data, error traces).

4. **Trace the execution path.**
   Follow the actual code path from the entry point through validation, business logic, persistence, and output. Read the code — do not rely on memory or assumption about what it does.

5. **Form competing hypotheses.** Identify at least two plausible explanations:
   - For each hypothesis, state: what would we expect to see (or not see) if this were the cause?
   - Check each against the actual evidence.

6. **Test hypotheses.** Use the smallest probe that distinguishes between hypotheses:
   - Add targeted logging or assertions.
   - Inspect intermediate state (variables, database rows, API responses).
   - Modify input to isolate the trigger.
   - Check version history: what changed in the affected code path?

7. **Identify the root cause.** Separate:
   - **Root cause:** the underlying defect in code, data, or design.
   - **Trigger:** the specific input or condition that exposed it.
   - **Contributing factors:** conditions that made the defect possible or hard to detect.

8. **Propose the fix.** The smallest correction that addresses the root cause:
   - Does the fix address the cause, not just the symptom?
   - Does it preserve existing behavior for unaffected cases?
   - Does it introduce new risks?

9. **Define the regression test.** A test that would fail before the fix and pass afterward, targeting the root cause specifically.

## Output contract
- Defect summary: expected vs actual, reproduction status.
- Execution trace: relevant code path with findings.
- Hypothesis list with evidence for/against each.
- Root cause identification (confirmed, probable, or unverified — labeled honestly).
- Proposed fix with scope and risk assessment.
- Regression test specification.

## Safety and approval gates
- Diagnosis is analysis — do not apply fixes without authorization unless the tier is SKIP.
- Do not weaken assertions, disable checks, or suppress errors to eliminate symptoms.
- If the root cause is in a security boundary, flag immediately.
- If evidence is insufficient, label findings as probable or unverified — never claim certainty without evidence.

## Verification
- Root cause is supported by at least one piece of evidence (code trace, log, reproduction).
- Proposed fix addresses the root cause, not just the trigger.
- Regression test targets the specific defect, not just general coverage.
- Contributing factors are noted to prevent recurrence.
