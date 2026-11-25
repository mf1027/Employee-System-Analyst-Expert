# Test Strategy

## Purpose
Define the testing approach — levels, types, scope, tooling, environment, and acceptance criteria — before implementing tests. Ensure testing is proportionate to risk and covers the right things at the right level.

## When to use
Invoke when asked to create a test plan, define testing strategy, decide what to test, set up test infrastructure, or before implementing tests for a feature or change.

## Prerequisites
- Requirements or acceptance criteria for the system/feature.
- Known architecture and tech stack.
- Risk assessment or knowledge of high-risk areas (if available).

## Procedure

1. **Read context.** Review requirements, architecture, risk register, and existing test infrastructure.
2. **Classify the test scope:**
   - **New feature:** full strategy across unit, integration, and acceptance levels.
   - **Bug fix:** regression test targeting the root cause + boundary cases.
   - **Refactoring:** focused regression ensuring existing behavior is preserved.
3. **Define the test pyramid (or appropriate shape):**
   - **Unit tests:** isolated logic, business rules, calculations, state machines.
   - **Integration tests:** component boundaries, database operations, API contracts.
   - **End-to-end / acceptance tests:** critical user journeys, cross-system flows.
   - Adjust the shape to the tech and risk: data-heavy systems may need more integration; UI-heavy may need more E2E.
4. **For each test level, define:**
   a. What is in scope and what is out of scope.
   b. Critical scenarios (happy path, error cases, boundary conditions, security cases).
   c. Test data requirements (fixtures, seeds, mocks, fakes).
   d. Environment requirements (databases, external services, containers, test doubles).
   e. Tools and frameworks matching the project's existing stack.
5. **Risk-based prioritization:**
   - Identify the highest-risk areas (data integrity, auth, financial calculations, external APIs).
   - These get the most test coverage; low-risk CRUD gets minimal or generated tests.
6. **Define negative and boundary tests:**
   - Invalid input, missing required fields, duplicate submissions.
   - Null, empty, max-length, overflow, special characters.
   - Unauthorized access, privilege escalation, expired sessions.
   - Concurrency, race conditions (where architecture makes them possible).
7. **Automation decision:** which tests run in CI, which are manual/exploratory.
8. **Acceptance criteria mapping:** trace each requirement to at least one test.

## Output contract
- Test strategy summary: scope, risk areas, test levels, and pyramid shape justification.
- Test plan table: ID | Requirement | Test Level | Scenario | Expected Result | Priority | Automated?
- Environment and data requirements.
- Acceptance criteria traceability matrix.

## Safety and approval gates
- Test strategy is planning — do not implement tests without authorization.
- Do not weaken existing assertions or disable tests to achieve green results.
- Do not use production data in tests; define anonymized or synthetic test data.
- Flag any test that requires external service access or privileged credentials.

## Verification
- Every P0 requirement has at least one mapped test scenario.
- Negative and boundary cases are included for high-risk areas.
- Test levels are justified, not just "we'll unit test everything."
