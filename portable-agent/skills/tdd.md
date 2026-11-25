# TDD (Test-Driven Development)

## Purpose
Implement features and fixes using the Red-Green-Refactor cycle: write a failing test first, then write the minimum code to pass it, then refactor. Ensure tests drive design, not the other way around.

## When to use
Invoke when implementing a feature, fixing a bug, or writing code where the requirement can be expressed as a test before implementation. Especially valuable for: business logic, state machines, calculations, validation rules, data transformations, and API contracts.

## Prerequisites
- A clear requirement or acceptance criterion that can be expressed as a test.
- A working test framework in the project.
- Knowledge of the project's test conventions and structure.

## Procedure

1. **Understand the requirement.** Before writing any test, confirm what the code SHOULD do — from requirements, acceptance criteria, or the defect description.

2. **RED — Write a failing test:**
   a. Write one test for the smallest piece of the requirement.
   b. Name the test to express the behavior: `test_deposit_increases_balance`, not `test_function_1`.
   c. Assert the expected outcome explicitly.
   d. Run the test — confirm it FAILS for the right reason (not a syntax error or import failure, but because the behavior does not exist yet).
   e. If the test passes immediately, you are either testing existing behavior (verify) or your test is tautological (fix it).

3. **GREEN — Write the minimum code to pass:**
   a. Write only enough production code to make the failing test pass.
   b. Do not generalize, optimize, or add features not tested.
   c. Run the test — confirm it PASSES.
   d. Run all related tests — confirm nothing else broke.

4. **REFACTOR — Clean up without changing behavior:**
   a. Remove duplication in both production and test code.
   b. Improve naming, structure, and clarity.
   c. Run all tests after each refactoring step — they must stay green.
   d. Do not add new behavior during refactoring.

5. **Repeat.** Return to RED with the next slice of the requirement.

6. **Test quality checklist:**
   - Each test verifies ONE behavior.
   - Tests are independent — no shared mutable state, no ordering dependency.
   - Tests are fast — no unnecessary I/O, no sleep/wait.
   - Test names describe the scenario, not the implementation.
   - Negative cases are covered: invalid input, missing data, error conditions.
   - Boundary cases are covered: empty, null, zero, max, off-by-one.

7. **When TDD is NOT the right tool:**
   - Exploratory spikes where the design is unknown — spike first, test after, delete the spike.
   - Pure UI layout/styling — visual testing is more appropriate.
   - Configuration and environment wiring — integration tests after the fact.
   In these cases, state why TDD is deferred and write tests after implementation.

## Output contract
- Tests written before implementation, each failing first (RED evidence).
- Minimal production code passing each test (GREEN evidence).
- Clean code after refactoring (REFACTOR evidence).
- All tests green at the end of each cycle.

## Safety and approval gates
- Do not weaken, skip, or disable tests to achieve green status.
- Do not write tests that pass regardless of implementation (tautological tests).
- Do not mock the system under test — mock its dependencies.
- If a test cannot be written without significant infrastructure, flag the design issue.

## Verification
- Every production function/method has at least one test that drove its creation.
- Tests fail when the feature is removed (proving they test real behavior).
- No test depends on another test's side effects.
- All tests pass at the end of the session.
