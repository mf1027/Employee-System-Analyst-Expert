# Skill: test-strategy

## Purpose
Define **how we know the thing works** before it's built — the test strategy and QA plan. The
triple-lens review catches *design* gaps; this skill defines the *verification* that catches
*implementation* gaps: what to test, at which level, with what acceptance criteria, and what the
regression and UAT story is per module. Without it, "done" is a feeling instead of a checklist,
and defects surface in production instead of in a test run.

This is the SA/PM quality discipline (B5 Quality, B14 Test & UAT in `skills.md`) turned into a
concrete, per-module plan. The employee designs the test strategy; the developer writes the test
code.

## Trigger
Invoke when the operator says "test plan", "test strategy", "QA plan", "how do we test this",
"UAT plan", "acceptance criteria matrix", "definition of done", "regression checklist",
"paano natin i-test to". Natural chain: after `developer-handoff`, or in PLAN/CHALLENGE mode.

## Minimum context required
- The requirements (`REQ-` with acceptance criteria) and/or the dev tickets (`DEV-`).
- The architecture/stack (decides feasible test levels and tooling).
- Risk areas — what's most expensive if it breaks (drives where to spend test effort).

---

## The test pyramid (where effort goes)

Spend effort in proportion to value, not uniformly. Most coverage at the cheap, fast bottom;
least at the expensive, slow top.

| Level | Tests what | Proportion | Notes |
|---|---|---|---|
| **Unit** | Single function/component logic | Most | Fast, isolated; cover edge cases here |
| **Integration** | Components together, DB, API contracts | Some | Where the schema/contract assumptions get verified |
| **End-to-end / UAT** | Whole user journeys against acceptance criteria | Fewest | Expensive; reserve for critical paths and sign-off |

Anti-pattern: an inverted pyramid (everything tested only through slow E2E) — flags as a `RISK-`.

---

## What the plan contains
- **Coverage matrix** — every `REQ-` → the test level(s) that verify it. Gaps are visible.
- **Test scenarios** — per module, the happy path + the named edge/error/concurrency/permission paths.
- **Acceptance criteria → test cases** — each Given/When/Then becomes at least one case.
- **Regression set** — the cases that must pass before every release (the "don't re-break this" list).
- **UAT scripts** — operator/client-runnable steps with expected results for sign-off.
- **Test data & environment** — what data and which environment each level needs (and how it's seeded).
- **Tooling recommendation** — frameworks fit to the stack (state options, recommend one).
- **Exit criteria** — what "tested enough to ship" means: coverage %, zero open criticals, UAT signed.

---

## Steps
1. Pull acceptance criteria from `REQ-`/`DEV-`. Every criterion is a test case seed — start there.
2. Build the **coverage matrix**: map each requirement to unit/integration/E2E. Empty rows = gaps → flag.
3. Per module, enumerate scenarios across the shadow paths (empty, max, error, concurrency, permission) —
   not just the happy path.
4. Identify the **regression set** — the high-risk, high-traffic cases that gate every release.
5. Write **UAT scripts** the operator/client can run, with explicit expected results.
6. Apply the **triple lens**: SA (coverage complete?), PM (regression + exit criteria + effort realistic?),
   DBA (data-integrity, migration, and performance tests included where data is touched?).
7. Recommend tooling for the stack; set exit criteria. Save to project `deliverables/documents/`;
   reference `REQ-`/`DEV-` IDs. Surface at least one `REC-` or `RISK-`.

---

## Output format
```
TEST STRATEGY — [project] — [YYYY-MM-DD]
Stack: [stack]   Tooling: [recommended]

COVERAGE MATRIX
  REQ-F01 → unit + integration        REQ-F03 → unit + E2E (critical path)
  REQ-F07 → ⚠ no test mapped (gap)
  Coverage: [N]/[M] requirements have ≥1 test level

SCENARIOS — [module]
  Happy:  [case]
  Edge:   empty / max / error / concurrency / permission → [cases]

REGRESSION SET (gate every release)
  - [case] (REQ-F03) …

UAT SCRIPT — [feature]
  Step 1 … → Expected: …    [operator/client runnable]

EXIT CRITERIA
  [coverage % · zero open criticals · UAT signed-off]

RISK-NNN / REC-NNN: [e.g. inverted pyramid risk, or "add load test on the list endpoint"]
```

Close with **Decisions needed / Open questions / Next steps**.

## Quality checklist
- [ ] Every `REQ-` mapped to a test level; gaps explicitly flagged
- [ ] Scenarios cover the shadow paths, not just the happy path
- [ ] Regression set and exit criteria defined (objective, not "feels done")
- [ ] UAT scripts are runnable with expected results
- [ ] DBA lens: data-integrity / migration / performance tests included where data is touched
- [ ] Effort proportioned to risk (pyramid, not inverted); at least one `REC-`/`RISK-`

## Failure exit
"There are no acceptance criteria to test against yet — a test plan without them is guesswork.
Let's get `REQ-` criteria (or the `DEV-` tickets) firmed up first, then I'll build the coverage
matrix and scenarios on top of them."
