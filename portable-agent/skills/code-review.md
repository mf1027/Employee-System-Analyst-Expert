# Code Review

## Purpose
Review code changes for correctness, safety, maintainability, and alignment with requirements. Identify defects, risks, and improvement opportunities. Distinguish critical issues from suggestions.

## When to use
Invoke when asked to review code, audit a diff, assess code quality, or when validating implementation against requirements and architecture decisions.

## Prerequisites
- The code to review: diff, file(s), or pull request.
- Requirements or acceptance criteria the code is supposed to satisfy.
- Knowledge of the project's conventions, patterns, and architecture.

## Procedure

1. **Read context.** Review the requirements, acceptance criteria, and architecture decisions for this change. Understand what the code SHOULD do before assessing what it DOES.
2. **Assess scope and intent:**
   - Does the change match the stated purpose?
   - Are there unrelated changes mixed in? Flag scope creep.
3. **Correctness check:**
   a. Does the code produce the correct output for normal inputs?
   b. Edge cases: null, empty, boundary values, maximum sizes.
   c. Error handling: are errors caught, logged, and handled appropriately?
   d. Are assumptions about caller behavior validated (input validation)?
   e. State management: race conditions, concurrent access, stale data.
4. **Safety and security check:**
   a. Input validation and sanitization.
   b. Authorization checks at the correct boundary.
   c. Secrets handling (not hardcoded, not logged, not exposed).
   d. SQL injection, XSS, path traversal — where applicable.
   e. Backward compatibility: does this break callers or consumers?
5. **Maintainability assessment:**
   a. Naming: clear, consistent, descriptive.
   b. Complexity: functions/methods of reasonable size, single responsibility.
   c. Duplication: code that should be shared or extracted.
   d. Test coverage: are new paths tested? Are existing tests still valid?
   e. Documentation: are complex decisions explained?
6. **Convention compliance:**
   - Follows project naming, formatting, and structural conventions.
   - Uses established patterns (error handling, logging, configuration).
   - Consistent with existing codebase style.
7. **Classify findings** by severity:
   - 🔴 **Critical:** Defect, security vulnerability, data loss risk. Must fix before merge.
   - 🟡 **Warning:** Logic concern, missing edge case, maintainability risk. Should fix.
   - 🟢 **Suggestion:** Style improvement, minor refactor opportunity. Optional.
   - ℹ️ **Note:** Observation, question, or context for future work.
8. **Produce output** with actionable, specific feedback tied to code locations.

## Output contract
- Review summary: scope assessment, overall verdict (Approve / Request Changes / Reject).
- Findings list: Severity | Location | Finding | Recommendation
- Questions for the author (if intent is unclear).
- Positive observations (what was done well).

## Safety and approval gates
- Code review is analysis — do not modify the code without authorization.
- Do not approve code with Critical findings.
- Do not ignore test failures or suggest weakening assertions to pass.
- Flag any change that touches auth, data integrity, or financial logic for additional review.

## Verification
- Every Critical finding has a specific code reference and recommendation.
- Requirements/acceptance criteria are checked against the implementation.
- Test coverage gaps are identified for new code paths.
- Review covers correctness, safety, maintainability — not just style.
