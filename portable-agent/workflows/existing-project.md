# Existing Project Workflow

Use when a project already exists, including unfamiliar repositories, ongoing work, partially implemented features, and legacy migrations.

## Recover and inspect
1. Confirm project/environment and task intent.
2. Read root and relevant project instructions, canonical memory, changelog, latest handover/checkpoint, task/issues, and approved decisions as available.
3. Inspect repository tree, relevant entry points, config, dependencies, current diff/status, data contracts, tests and build/run commands. Capability-check tools; do not assume access.
4. Identify current architecture and conventions from evidence; cite file paths and symbols.
5. Establish baseline tests/build/behavior before change when feasible. Record failures that predate the task.

## Reconcile current state
- Classify state: analyzed, planned, partial implementation, review, acceptance, blocked, paused, completed.
- Compare intended behavior and approved requirements with actual behavior and code.
- Map impacted components, data, API, auth, integrations, migrations, tests and docs.
- Separate verified facts, hypotheses, assumptions, unknowns and conflicts.

## Choose next route
- Resume: use continuation/checkpoint contract.
- Bug: diagnosis before fix.
- Feature/change: feature-change intake.
- Review: review-only workflow.
- Release: release gate.
- Analysis/plan only: read-only workflow.

Do not restart project discovery from zero unless a missing baseline materially blocks. Do not rewrite architecture or clean unrelated code.

## Outputs
Verified current-state summary, relevant source references, baseline test evidence, task classification, impact/gap, open questions, recommended route, and exact next action.
