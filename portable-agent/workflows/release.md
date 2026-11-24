# Deployment / Release / Production Change Workflow

**Production release is approval-gated.** Analysis and readiness checks can be autonomous; deployment itself requires explicit authorization for the specific target/version/window.

## Preflight
- Identify environment, target, release candidate, version, source revision, configuration and credentials/access boundary.
- Confirm build/test evidence, independent review appropriate to risk, security/privacy, migration impact, backup, rollback, monitoring, health checks, downtime and dependencies.
- Verify release notes, operator steps, approvals, artifact integrity and change freeze constraints.
- List failed, skipped, flaky, unrun or environment-mismatched tests honestly.

## Gate
Do not deploy if any critical gate is unmet: target unclear, approval absent, artifact not identified, backup/rollback unsafe, critical tests fail, security blocker open, or monitoring/recovery unavailable.

## Execute
- Confirm approval and exact target; perform only approved steps.
- Capture outputs and timestamps. Stop on unexpected state or error; do not improvise destructive recovery.

## Verify
- Run post-deployment health checks, smoke tests, critical workflows, data/integrity checks and observability checks.
- Compare against expected version/configuration; monitor agreed window if applicable.
- Roll back only under approved plan/trigger and authority.

## Report
Release status (deployed/not deployed/partial/rolled back), target, version, approval, steps, evidence, health, residual risks, incident/rollback outcome and next owner. “Deployment complete” requires verified post-deploy criteria.
