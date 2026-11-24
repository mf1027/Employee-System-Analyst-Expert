# Routing Matrix

| Intent | Primary workflow | Skill(s) commonly relevant | Exit condition |
|---|---|---|---|
| New project | `new-project.md` | requirements, system, domain, architecture, planning, NFR, risk | approved baseline and ready plan |
| Existing project | `existing-project.md` | system-analysis, context-economy | verified current state and bounded task |
| Resume | `continuation.md` + `continuation-contract.md` | checkpoint reconciled and resumed/blocked |
| Bug | `diagnosis.md` | evidence-backed RCA and approved fix verified or handed off |
| Feature/change | `feature-change.md` | impact/acceptance/baseline delta approved |
| Research/video | `research.md` | evidence-backed synthesis/handover |
| Analysis only | `analysis-only.md` | findings/options/recommendation, no mutation |
| Review | `review-acceptance.md` | findings/verdict and evidence |
| Scope change | `scope-change.md` | impact and decision recorded |
| Blocked | `blocked-task.md` | blocker resolved or safely handed off |
| Skill lifecycle | `skill-lifecycle.md` | skill validated, routed, documented |
| Context optimization | `context-optimization.md` | quality-preserving improvement verified |
| Release/deploy | `release.md` | authorized release with post-checks or explicit stop |
| Multi-agent | `multi-agent.md` | coordinated outputs integrated and verified |
| Status | `project-status.md` | truthful status, risks and next action |

Load the `skills/REGISTRY.md` for skill triggers and canonical filenames. Route cases in `evals/routing-cases.json` are expected routing fixtures; they do not demonstrate live model selection.
